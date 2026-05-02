import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/drift/app_database.dart';

/// Need #11 + #12 — first-run / upgrade population of the local
/// enrichment + morpheme tables from a pre-built SQLite seed shipped
/// in the APK (`assets/seed/enrichment_v2.db`).
///
/// Versioning (Need #12 follow-up)
/// -------------------------------
/// We track the seed version the device has installed in
/// SharedPreferences key `_enrichment_seed_version`. The bundled seed
/// declares its version in the [_bundledSeedVersion] constant below.
///
/// On every launch:
///   * If `local >= bundled` → no-op.
///   * If `local == 0` (fresh install or pre-sentinel install) → full
///     5-table seed: word_forms, word_relations, word_phrases,
///     morpheme_entries, word_morpheme_matches.
///   * If `0 < local < bundled` → delta: only the tables introduced in
///     versions strictly after `local`. v1→v2 means morpheme_entries +
///     word_morpheme_matches; the existing 3 tables are left as-is so
///     the user keeps their data.
///
/// Failure handling: any exception (asset missing, file copy, SQL
/// error) leaves the sentinel un-bumped. Next launch retries. The user
/// can also fall back to Settings → 调试 →「重新导入增强数据」 which
/// performs a full reseed regardless of version.
class EnrichmentBootstrap {
  EnrichmentBootstrap({AppDatabase? driftDb}) : _db = driftDb ?? AppDatabase();
  final AppDatabase _db;

  /// Bundled seed asset path. Bumped together with [_bundledSeedVersion]
  /// whenever new tables / new content lands in the seed builder.
  static const String _seedAssetPath = 'assets/seed/enrichment_v2.db';

  /// Increment when the seed introduces new tables or refreshed data.
  /// Steps to land a new version:
  ///   1. Add tables / change schema; bump drift schemaVersion.
  ///   2. Update tools/build_enrichment_seed.dart to emit new tables.
  ///   3. Bump [_bundledSeedVersion] AND the asset filename below.
  ///   4. Add a delta branch in [_applyDelta] for the new version.
  static const int _bundledSeedVersion = 2;

  static const String _versionPrefsKey = '_enrichment_seed_version';

  /// Migrate the local enrichment store to the bundled seed version,
  /// applying only the delta needed. Safe to call on every launch.
  Future<void> ensurePopulated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getInt(_versionPrefsKey) ?? 0;

      if (localVersion >= _bundledSeedVersion) {
        debugPrint(
          '[EnrichmentBootstrap] local=$localVersion >= bundled='
          '$_bundledSeedVersion — skip',
        );
        return;
      }

      debugPrint(
        '[EnrichmentBootstrap] local=$localVersion < bundled='
        '$_bundledSeedVersion — applying delta',
      );

      final stopwatch = Stopwatch()..start();
      await _applyDelta(localVersion, _bundledSeedVersion);
      stopwatch.stop();

      // Only commit the new version after every step succeeded.
      await prefs.setInt(_versionPrefsKey, _bundledSeedVersion);
      debugPrint(
        '[EnrichmentBootstrap] seed delta done in '
        '${stopwatch.elapsedMilliseconds}ms — sentinel = $_bundledSeedVersion',
      );
    } catch (e, st) {
      debugPrint('[EnrichmentBootstrap] failed (non-blocking): $e\n$st');
    }
  }

  /// Force a full reseed of every enrichment + morpheme table from the
  /// bundled seed. Used by Settings → 调试 →「重新导入增强数据」 as a
  /// developer / recovery fallback. Throws on failure so the calling
  /// UI can surface an error message.
  Future<void> forceReseed() async {
    await _runSeedTransaction(
      includeForms: true,
      includeRelations: true,
      includePhrases: true,
      includeMorphemeEntries: true,
      includeWordMorphemeMatches: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_versionPrefsKey, _bundledSeedVersion);
  }

  /// Decide which subset of tables to wipe + reinsert based on the
  /// version gap between the device and the bundled seed.
  Future<void> _applyDelta(int localVersion, int bundledVersion) async {
    if (localVersion == 0) {
      // Fresh install or pre-sentinel install. Best treated as "no
      // trustworthy state" — wipe and reseed everything from v2.
      await _runSeedTransaction(
        includeForms: true,
        includeRelations: true,
        includePhrases: true,
        includeMorphemeEntries: true,
        includeWordMorphemeMatches: true,
      );
      return;
    }

    // localVersion >= 1 path. Each version introduces specific tables.
    // Run only the deltas above localVersion.
    final needV2 = localVersion < 2;
    if (needV2) {
      // v2 added morpheme_entries + word_morpheme_matches. Touch
      // ONLY those — keep word_forms / relations / phrases as-is so
      // upgraders don't lose anything they manually re-imported.
      await _runSeedTransaction(
        includeForms: false,
        includeRelations: false,
        includePhrases: false,
        includeMorphemeEntries: true,
        includeWordMorphemeMatches: true,
      );
    }
  }

  /// Materialise the bundled seed into a temp file, ATTACH it, and run
  /// DELETE + INSERT-SELECT for the tables flagged true. Wraps the
  /// SQL in a single transaction so a mid-flight crash leaves
  /// affected tables untouched.
  Future<void> _runSeedTransaction({
    required bool includeForms,
    required bool includeRelations,
    required bool includePhrases,
    required bool includeMorphemeEntries,
    required bool includeWordMorphemeMatches,
  }) async {
    final bytes = await rootBundle.load(_seedAssetPath);
    final tmpDir = await getTemporaryDirectory();
    final tmpFile = File(
      p.join(
        tmpDir.path,
        'enrichment_seed_${DateTime.now().millisecondsSinceEpoch}.db',
      ),
    );
    await tmpFile.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );

    // ── SQLite hard rule ────────────────────────────────────────────
    // ATTACH DATABASE / DETACH DATABASE MUST run at the connection
    // level — not inside an open transaction. Running them inside a
    // transaction throws `SQL logic error: cannot ATTACH database
    // within transaction` on real devices (sqflite errors with that
    // shape; previous in-memory tests didn't catch it because they
    // never reached this codepath — see enrichment_bootstrap_test.dart
    // for the new disk-backed regression).
    //
    // Sequence:
    //   1. ATTACH outside any transaction
    //   2. transaction() → DELETE + INSERT-SELECT for the chosen
    //      tables (atomic; rollback on any failure)
    //   3. DETACH in finally, also outside the transaction
    try {
      await _db.customStatement("ATTACH DATABASE '${tmpFile.path}' AS seed");
      try {
        await _db.transaction(() async {
          if (includeForms) {
            await _db.customStatement('DELETE FROM word_forms');
            await _db.customStatement(
              'INSERT INTO word_forms '
              '(word, form_text, form_type, pos, source) '
              'SELECT word, form_text, form_type, pos, source '
              'FROM seed.word_forms',
            );
          }
          if (includeRelations) {
            await _db.customStatement('DELETE FROM word_relations');
            await _db.customStatement(
              'INSERT INTO word_relations '
              '(word, target_word, relation_type, pos, confidence, source) '
              'SELECT word, target_word, relation_type, pos, confidence, source '
              'FROM seed.word_relations',
            );
          }
          if (includePhrases) {
            await _db.customStatement('DELETE FROM word_phrases');
            await _db.customStatement(
              'INSERT INTO word_phrases '
              '(word, phrase_text, phrase_type, score, source) '
              'SELECT word, phrase_text, phrase_type, score, source '
              'FROM seed.word_phrases',
            );
          }
          if (includeMorphemeEntries) {
            await _db.customStatement('DELETE FROM morpheme_entries');
            await _db.customStatement(
              'INSERT INTO morpheme_entries '
              '(morpheme, normalized_morpheme, morpheme_type, meanings_json, '
              'examples_json, source, license) '
              'SELECT morpheme, normalized_morpheme, morpheme_type, '
              'meanings_json, examples_json, source, license '
              'FROM seed.morpheme_entries',
            );
          }
          if (includeWordMorphemeMatches) {
            await _db.customStatement('DELETE FROM word_morpheme_matches');
            await _db.customStatement(
              'INSERT INTO word_morpheme_matches '
              '(word, morpheme, normalized_morpheme, morpheme_type, position, '
              'meanings_json, match_method, confidence, source) '
              'SELECT word, morpheme, normalized_morpheme, morpheme_type, '
              'position, meanings_json, match_method, confidence, source '
              'FROM seed.word_morpheme_matches',
            );
          }
        });
      } finally {
        // DETACH must also run outside the transaction.
        try {
          await _db.customStatement('DETACH DATABASE seed');
        } catch (_) {/* swallow — detach failure is non-fatal */}
      }
    } finally {
      try {
        if (tmpFile.existsSync()) await tmpFile.delete();
      } catch (_) {}
    }
  }
}
