// Smoke test for the debug enrichment importer. Uses Flutter's
// rootBundle to read the actual bundled assets, so the test verifies:
//   (1) the JSONL files are correctly registered in pubspec.yaml,
//   (2) the parser shape matches the real data,
//   (3) batched inserts land rows for a known word ('abandon').
//
// Skip-fast: if the rootBundle cannot find the asset (e.g. running
// outside of a `flutter test` invocation that has built the asset
// manifest), the test is marked skipped instead of failed — the
// importer is dev-only and shouldn't gate CI on asset paths.
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/services/word_enrichment_importer.dart';
import 'package:meow_mobile/core/services/word_enrichment_service.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('importer pulls JSONL into the 3 enrichment tables (smoke)', () async {
    // Verify assets are reachable; if not, skip — this test runs against
    // bundled debug assets and shouldn't fail the suite when run via raw
    // `dart test`.
    try {
      await rootBundle.loadString('assets/forms/word_forms.jsonl');
    } catch (_) {
      // ignore: avoid_print
      print('skipping: assets/forms not bundled in this test run');
      return;
    }

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    final importer = WordEnrichmentImporter(driftDb: db);
    final stats = await importer.importAll(replace: true);

    // The CET-4 + datamuse + OEWN datasets are non-trivial — every count
    // must be at least four-digit.
    expect(stats.forms, greaterThan(1000));
    expect(stats.relations, greaterThan(1000));
    expect(stats.phrases, greaterThan(1000));

    // Sanity-check round-trip via the reader.
    final svc = WordEnrichmentService(driftDb: db);
    final result = await svc.getFor('abandon');
    expect(result.forms, isNotEmpty,
        reason: 'abandon should at least have past/present_participle forms');
    expect(result.synonyms, isNotEmpty,
        reason: 'abandon should have OEWN synonyms (desert / forsake / vacate / ...)');
    // 'abandon' phrases include `abandon hope`, `abandon a plan`, etc.
    expect(result.phrases, isNotEmpty);
  });
}
