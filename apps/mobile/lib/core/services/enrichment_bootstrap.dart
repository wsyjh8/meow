import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../storage/drift/app_database.dart';

/// Need #11 (build-time bootstrap, v2) — first-run population of the
/// enrichment tables from a pre-built SQLite seed file shipped in the
/// APK.
///
/// Why a seed file instead of streaming JSONL on device:
/// - JSONL parse + drift insert took 30–60s on emulator. The user sees
///   empty modules during that gap on every fresh install. Bad UX.
/// - The seed.db is generated once on dev machine
///   (tools/build_enrichment_seed.dart), shipped under
///   assets/seed/enrichment_v1.db (~9MB), and copied + ATTACH-ed at
///   first launch. Total on-device cost: a file copy + 3 INSERT…SELECT
///   queries inside one transaction — well under a second on real
///   hardware.
///
/// Idempotency
/// - Skips if word_forms already has ≥ [_populatedThreshold] rows.
/// - Manual Settings → 调试 → 导入增强数据 (which does
///   `replace=true` from JSONL) still works as a force-reseed; it just
///   pushes the row count well above threshold so this bootstrap
///   continues to skip on next launch.
///
/// Failure
/// - Asset missing / file copy failure / SQL error → logged and
///   swallowed. Modules stay empty, app keeps working. User can fall
///   back to the Settings debug import path.
class EnrichmentBootstrap {
  EnrichmentBootstrap({AppDatabase? driftDb}) : _db = driftDb ?? AppDatabase();
  final AppDatabase _db;

  /// Bundled seed asset path. Bumped to `_v2`-style suffix when the
  /// schema or upstream JSONL changes — bootstrap will then re-seed
  /// because the live tables are still considered "old empty".
  static const String _seedAssetPath = 'assets/seed/enrichment_v1.db';

  /// Threshold below which the live store is "essentially empty".
  static const int _populatedThreshold = 1000;

  /// Force a fresh reseed: wipe the three enrichment tables and copy
  /// from the bundled seed file. Used by Settings → 调试 →
  /// 「重新导入增强数据」 to recover from a partial / stale state.
  ///
  /// Throws on copy or SQL failure so the calling UI can surface an
  /// error message — this is an explicit user action, not a silent
  /// bootstrap.
  Future<void> forceReseed({
    void Function(String label, int? total)? onProgress,
  }) async {
    onProgress?.call('清理旧数据', null);
    await _db.transaction(() async {
      await _db.customStatement('DELETE FROM word_forms');
      await _db.customStatement('DELETE FROM word_relations');
      await _db.customStatement('DELETE FROM word_phrases');
    });
    onProgress?.call('从内置数据导入', null);
    await _seedFromBundledDb();
  }

  /// Run the seed copy iff word_forms has fewer than [_populatedThreshold]
  /// rows. Safe to call on every launch.
  Future<void> ensurePopulated() async {
    try {
      final cnt = (await _db.customSelect(
        'SELECT COUNT(*) AS cnt FROM word_forms',
      ).getSingle()).read<int>('cnt');
      if (cnt >= _populatedThreshold) {
        debugPrint('[EnrichmentBootstrap] populated (forms=$cnt) — skip');
        return;
      }

      debugPrint(
        '[EnrichmentBootstrap] forms=$cnt below $_populatedThreshold — '
        'seeding from $_seedAssetPath',
      );

      final stopwatch = Stopwatch()..start();
      final stats = await _seedFromBundledDb();
      stopwatch.stop();

      debugPrint(
        '[EnrichmentBootstrap] seed copy done in '
        '${stopwatch.elapsedMilliseconds}ms — $stats',
      );
    } catch (e, st) {
      debugPrint('[EnrichmentBootstrap] failed (non-blocking): $e\n$st');
    }
  }

  /// Copy the bundled seed SQLite into a temp file on the device, then
  /// ATTACH it to the live drift DB and INSERT…SELECT each table inside
  /// one transaction. Sub-second on real hardware (no Dart-side
  /// iteration, no JSON parse).
  Future<_SeedStats> _seedFromBundledDb() async {
    // 1. Materialize the bundled asset into a real file. ATTACH needs
    //    a filesystem path; rootBundle gives us bytes.
    final bytes = await rootBundle.load(_seedAssetPath);
    final tmpDir = await getTemporaryDirectory();
    final tmpFile =
        File(p.join(tmpDir.path, 'enrichment_seed_${DateTime.now().millisecondsSinceEpoch}.db'));
    await tmpFile.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );

    try {
      // 2. ATTACH and bulk-copy. The seed file uses the same column
      //    names as the live drift schema, so bare INSERT … SELECT
      //    works without column lists.
      //
      //    Wrap in a single transaction so a mid-flight crash leaves
      //    the live tables untouched (the threshold guard will pick
      //    things up on next launch).
      await _db.transaction(() async {
        await _db.customStatement(
          "ATTACH DATABASE '${tmpFile.path}' AS seed",
        );
        try {
          await _db.customStatement(
            'INSERT INTO word_forms '
            '(word, form_text, form_type, pos, source) '
            'SELECT word, form_text, form_type, pos, source '
            'FROM seed.word_forms',
          );
          await _db.customStatement(
            'INSERT INTO word_relations '
            '(word, target_word, relation_type, pos, confidence, source) '
            'SELECT word, target_word, relation_type, pos, confidence, source '
            'FROM seed.word_relations',
          );
          await _db.customStatement(
            'INSERT INTO word_phrases '
            '(word, phrase_text, phrase_type, score, source) '
            'SELECT word, phrase_text, phrase_type, score, source '
            'FROM seed.word_phrases',
          );
        } finally {
          await _db.customStatement('DETACH DATABASE seed');
        }
      });

      final formsCnt = (await _db.customSelect(
        'SELECT COUNT(*) AS cnt FROM word_forms',
      ).getSingle()).read<int>('cnt');
      final relCnt = (await _db.customSelect(
        'SELECT COUNT(*) AS cnt FROM word_relations',
      ).getSingle()).read<int>('cnt');
      final phrCnt = (await _db.customSelect(
        'SELECT COUNT(*) AS cnt FROM word_phrases',
      ).getSingle()).read<int>('cnt');
      return _SeedStats(formsCnt, relCnt, phrCnt);
    } finally {
      // 3. Clean up the temp file. Errors swallowed — we don't care
      //    about leaking 9 MB to the OS temp dir if it goes wrong.
      try {
        if (tmpFile.existsSync()) await tmpFile.delete();
      } catch (_) {}
    }
  }
}

class _SeedStats {
  final int forms;
  final int relations;
  final int phrases;
  const _SeedStats(this.forms, this.relations, this.phrases);
  @override
  String toString() =>
      '其他形式 $forms · 近反义词 $relations · 常见词组 $phrases';
}
