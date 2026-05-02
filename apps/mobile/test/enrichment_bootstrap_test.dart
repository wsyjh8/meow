// Need #11 — bootstrap is the path that turns a fresh APK install into
// "open and immediately see enrichment data". Tests verify:
//   (1) populated store stays untouched (idempotent across launches)
//   (2) bootstrap never throws — failures are swallowed
//
// The seed-copy path requires the bundled asset + path_provider, which
// the headless test runner does not provide. We therefore only assert
// the no-op + non-throwing behaviour here; the actual seed copy is
// covered by manual verification on the emulator (data wipe → first
// open → modules visible immediately).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/services/enrichment_bootstrap.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ensurePopulated is a no-op when threshold already reached', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    // Seed > threshold rows so the bootstrap should leave them alone.
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

    final rows = await db.select(db.wordForms).get();
    expect(rows.length, 1500);
    expect(rows.any((r) => r.word.startsWith('preexisting-')), isTrue);
  });

  test('ensurePopulated swallows asset/path failures (non-blocking)', () async {
    // Empty store; in headless tests path_provider.getTemporaryDirectory
    // throws, and rootBundle.load fails to find the seed asset. Bootstrap
    // must catch + log silently. We assert no exception bubbles up.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    await expectLater(
      EnrichmentBootstrap(driftDb: db).ensurePopulated(),
      completes,
    );
  });
}
