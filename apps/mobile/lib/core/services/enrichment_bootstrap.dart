import 'package:flutter/foundation.dart';

import '../storage/drift/app_database.dart';
import 'word_enrichment_importer.dart';

/// Need #11 (build-time bootstrap) — first-run auto-import of the bundled
/// `assets/forms/*.jsonl` enrichment data into the local SQLite tables.
///
/// Why a separate service instead of folding into the importer:
/// - Importer stays user-driven (Settings debug button) and idempotent on
///   demand.
/// - Bootstrap encodes the "first install" lifecycle: skip if data is
///   already present, never overwrite, never block startup, never throw
///   into the UI.
///
/// The bootstrap is fire-and-forget: callers run it via `unawaited(...)`
/// so the first frame can paint while the import streams in the
/// background. UI gracefully shows empty enrichment modules until the
/// rows land — that is exactly the state Need #11's PRD specifies for
/// "no data yet".
class EnrichmentBootstrap {
  EnrichmentBootstrap({AppDatabase? driftDb}) : _db = driftDb ?? AppDatabase();
  final AppDatabase _db;

  /// Threshold below which we treat the local enrichment store as
  /// "essentially empty" and trigger a fresh import. Catches the
  /// pathological case where a previous bootstrap was killed mid-flight
  /// after writing only a tiny prefix of rows.
  static const int _populatedThreshold = 1000;

  /// Run the import iff word_forms has fewer than [_populatedThreshold]
  /// rows. Safe to call on every launch.
  ///
  /// Failures are swallowed and logged — a missing asset (e.g. someone
  /// built a debug APK without copying the JSONL) must not crash the app
  /// or block its other features. The user can still tap the Settings
  /// debug button to retry.
  Future<void> ensurePopulated() async {
    try {
      final row = await _db.customSelect(
        'SELECT COUNT(*) AS cnt FROM word_forms',
      ).getSingle();
      final cnt = row.read<int>('cnt');
      if (cnt >= _populatedThreshold) {
        debugPrint('[EnrichmentBootstrap] populated (forms=$cnt) — skip');
        return;
      }
      debugPrint(
        '[EnrichmentBootstrap] forms=$cnt below $_populatedThreshold — '
        'starting first-run import',
      );
      final stats = await WordEnrichmentImporter(driftDb: _db).importAll(
        replace: true, // wipe partial state if any
      );
      debugPrint('[EnrichmentBootstrap] done: $stats');
    } catch (e, st) {
      // Non-fatal: enrichment is optional content. Log & move on.
      debugPrint('[EnrichmentBootstrap] failed (non-blocking): $e\n$st');
    }
  }
}
