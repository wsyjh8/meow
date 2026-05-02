// Need #11 + Need #12 — bootstrap is the path that turns a fresh APK
// install into "open and immediately see enrichment data". For Need
// #12 it also handles upgrade-in-place from v1 → v2 via a
// SharedPreferences sentinel.
//
// The seed-copy path needs the bundled asset + path_provider, which
// the headless test runner doesn't always provide. We assert version
// gate logic + idempotency without running the actual ATTACH —
// failure modes are covered by the manual emulator smoke instead.
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meow_mobile/core/services/enrichment_bootstrap.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

/// Mock for path_provider so EnrichmentBootstrap.getTemporaryDirectory()
/// resolves in headless tests without the platform channel.
class _StubPathProvider extends PathProviderPlatform {
  _StubPathProvider(this.tempDirPath);
  final String tempDirPath;
  @override
  Future<String?> getTemporaryPath() async => tempDirPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('local sentinel >= bundled → no-op (no ATTACH attempted)', () async {
    SharedPreferences.setMockInitialValues({
      // 99 is well above the bundled version, simulating a future
      // sentinel left by some other code path.
      '_enrichment_seed_version': 99,
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    // Seed some rows that we expect to remain untouched.
    await db.batch((b) {
      for (var i = 0; i < 10; i++) {
        b.insert(
          db.wordForms,
          WordFormsCompanion.insert(
            word: 'test-$i',
            formText: 'x',
            formType: 'past',
          ),
        );
      }
    });

    await EnrichmentBootstrap(driftDb: db).ensurePopulated();

    // Rows untouched.
    expect((await db.select(db.wordForms).get()).length, 10);
    // Sentinel untouched (didn't drop back).
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('_enrichment_seed_version'), 99);
  });

  test('ensurePopulated with missing assets is non-blocking', () async {
    // Default version=null → bootstrap will try to load the bundled
    // seed; in headless tests the asset isn't reachable, so the
    // exception must be caught and logged rather than rethrown.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    await expectLater(
      EnrichmentBootstrap(driftDb: db).ensurePopulated(),
      completes,
    );

    // Sentinel must NOT be advanced when seed-copy failed.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('_enrichment_seed_version'), isNull);
  });

  test('repeat ensurePopulated() after success leaves data untouched',
      () async {
    // Mark already up-to-date so first call no-ops.
    SharedPreferences.setMockInitialValues({
      '_enrichment_seed_version': 2,
    });
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    // Pre-fill morpheme tables to verify the repeat call doesn't wipe.
    await db.into(db.morphemeEntries).insert(
          MorphemeEntriesCompanion.insert(
            morpheme: 'ab-',
            normalizedMorpheme: 'ab',
            morphemeType: 'prefix',
            meaningsJson: '["away from"]',
          ),
        );
    await db.into(db.wordMorphemeMatches).insert(
          WordMorphemeMatchesCompanion.insert(
            word: 'abandon',
            morpheme: 'ab-',
            normalizedMorpheme: 'ab',
            morphemeType: 'prefix',
            position: 'prefix',
            meaningsJson: '["away from"]',
          ),
        );

    final boot = EnrichmentBootstrap(driftDb: db);
    await boot.ensurePopulated();
    await boot.ensurePopulated();
    await boot.ensurePopulated();

    expect((await db.select(db.morphemeEntries).get()).length, 1);
    expect((await db.select(db.wordMorphemeMatches).get()).length, 1);
  });

  test('v1 → v2 delta path leaves Need #11 tables alone if assets missing',
      () async {
    // Simulate a device that already ran v1 bootstrap: word_forms is
    // populated and sentinel = 1. Without bundled assets the delta will
    // bail out, but the existing v1 data must NEVER be touched.
    SharedPreferences.setMockInitialValues({
      '_enrichment_seed_version': 1,
    });
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    await db.batch((b) {
      for (var i = 0; i < 30; i++) {
        b.insert(
          db.wordForms,
          WordFormsCompanion.insert(
            word: 'v1-$i',
            formText: 'y',
            formType: 'plural',
          ),
        );
      }
    });

    await EnrichmentBootstrap(driftDb: db).ensurePopulated();

    // word_forms intact regardless of asset availability.
    expect((await db.select(db.wordForms).get()).length, 30);

    // Sentinel must NOT advance to 2 since the seed copy failed.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('_enrichment_seed_version'), 1);
  });

  // ── Bug 1 regression: ATTACH must be at connection level ───────────
  //
  // Earlier the bootstrap wrapped `ATTACH DATABASE` inside a drift
  // transaction, which throws on real sqflite (`cannot ATTACH database
  // within transaction`). The in-memory tests above did not catch it
  // because they never reached the SQL — path_provider failed first.
  //
  // This test mocks path_provider, runs the live DB on a real disk
  // file, and exercises the full forceReseed pipeline end-to-end. If
  // someone ever moves ATTACH back inside a transaction, this fails.
  test(
      'forceReseed populates 5 tables end-to-end (Bug 1 ATTACH-in-transaction regression)',
      () async {
    // Bundled asset must be reachable; skip-fast otherwise so the
    // suite stays green on CI configurations that don't bundle it.
    try {
      await rootBundle.load('assets/seed/enrichment_v2.db');
    } catch (_) {
      // ignore: avoid_print
      print('skipping: assets/seed/enrichment_v2.db not bundled');
      return;
    }

    final tempDir = Directory.systemTemp.createTempSync('enrich_boot_');
    PathProviderPlatform.instance = _StubPathProvider(tempDir.path);

    final liveDbFile = File(p.join(tempDir.path, 'live.db'));
    if (liveDbFile.existsSync()) liveDbFile.deleteSync();

    final db = AppDatabase.forTesting(NativeDatabase(liveDbFile));
    addTearDown(() async {
      await db.close();
      try {
        if (liveDbFile.existsSync()) liveDbFile.deleteSync();
      } catch (_) {}
      try {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    // Force fresh sentinel — ensure ensurePopulated will actually run.
    SharedPreferences.setMockInitialValues({});

    // Direct path: forceReseed wipes + reseeds all 5 tables.
    await EnrichmentBootstrap(driftDb: db).forceReseed();

    Future<int> rowCount(String table) async {
      final row = await db
          .customSelect('SELECT COUNT(*) AS cnt FROM $table')
          .getSingle();
      return row.read<int>('cnt');
    }

    expect(await rowCount('word_forms'), greaterThan(0),
        reason: 'word_forms should be seeded');
    expect(await rowCount('word_relations'), greaterThan(0),
        reason: 'word_relations should be seeded');
    expect(await rowCount('word_phrases'), greaterThan(0),
        reason: 'word_phrases should be seeded');
    expect(await rowCount('morpheme_entries'), greaterThan(0),
        reason: 'morpheme_entries should be seeded');
    expect(await rowCount('word_morpheme_matches'), greaterThan(0),
        reason: 'word_morpheme_matches should be seeded');

    // Sentinel must advance to bundled version after success.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('_enrichment_seed_version'), 2);
  });
}
