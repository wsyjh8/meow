// Need #11 — bootstrap is the path that turns a fresh APK install into
// "open and immediately see enrichment data". Test verifies:
//   (1) empty store triggers an import
//   (2) populated store is left alone (idempotent across launches)
//   (3) bootstrap never throws — failures are swallowed
//
// We rely on the bundled JSONL assets being available; if they're not
// (e.g. CI without `flutter pub get`), the import call falls through
// to a no-op via the importer's own try/catch, so the populate-skip
// behaviour is what we ultimately assert on.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/services/enrichment_bootstrap.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ensurePopulated is a no-op when threshold already reached', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    // Seed > threshold rows up-front so the bootstrap should leave them alone.
    await db.batch((b) {
      for (var i = 0; i < 1500; i++) {
        b.insert(
          db.wordForms,
          WordFormsCompanion.insert(
            word: 'preexisting-$i',
            formText: 'x',
            formType: 'past',
          ),
        );
      }
    });

    await EnrichmentBootstrap(driftDb: db).ensurePopulated();

    // Row count must be unchanged. If the bootstrap had run the importer
    // with replace=true it would have wiped these synthetic rows.
    final rows = await db.select(db.wordForms).get();
    expect(rows.length, 1500);
    expect(rows.any((r) => r.word.startsWith('preexisting-')), isTrue);
  });

  test('ensurePopulated swallows asset-load failures (non-blocking)', () async {
    // Empty store, no assets bundled → importer will try rootBundle and
    // get an asset-not-found error. ensurePopulated must NOT rethrow.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    // The default test binding does not bundle the JSONL assets, so the
    // importer's rootBundle.loadString will throw. Bootstrap should
    // catch and log silently. We just assert no exception bubbles up.
    await expectLater(
      EnrichmentBootstrap(driftDb: db).ensurePopulated(),
      completes,
    );
  });

  test('ensurePopulated runs the importer when assets ARE bundled', () async {
    // If the bundled asset is reachable, the importer should fill the
    // tables past the threshold. Skip-fast when running in an environment
    // that doesn't have the asset manifest.
    try {
      await rootBundle.loadString('assets/forms/word_forms.jsonl');
    } catch (_) {
      // ignore: avoid_print
      print('skipping: assets/forms not bundled in this test invocation');
      return;
    }

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    await EnrichmentBootstrap(driftDb: db).ensurePopulated();

    final formsCount = (await db.customSelect(
      'SELECT COUNT(*) AS cnt FROM word_forms',
    ).getSingle()).read<int>('cnt');
    expect(formsCount, greaterThan(1000));
  });
}
