import 'dart:async';

import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/memory/asset_word_loader.dart';
import 'core/memory/wordbook_loader.dart';
import 'core/services/enrichment_bootstrap.dart';
import 'core/storage/drift/app_database.dart';
import 'core/storage/local_database.dart';

/// App entry point with local database initialization.
///
/// P3.3.17: On first launch, AssetWordLoader populates cached_words from
/// the bundled CET-4 word list (assets/words/book-001.json, 3849 words).
/// Subsequent launches detect count > 0 and return immediately (~1ms).
///
/// v3: WordbookLoader additionally populates word_entries / word_book_assignments
/// / example_sentences for ZK (中考) and GK (高考) wordbooks.
/// All loaders are idempotent — safe to call every launch.
///
/// Need #11 (build-time): EnrichmentBootstrap runs in the BACKGROUND
/// (fire-and-forget) after the first frame paints. It checks word_forms
/// count and, if essentially empty, streams `assets/forms/*.jsonl` into
/// the 3 enrichment tables. The user sees the app load instantly; the
/// 其他形式 / 近反义词 / 常见词组 modules light up as soon as the import
/// catches up. Failures are silent — UI just shows empty modules.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.initialize();

  final appDb = AppDatabase();

  // CET-4 word pool (legacy cached_words table).
  await AssetWordLoader(db: appDb).loadIfNeeded('book-001');

  // ZK (中考) and GK (高考) content layer (word_entries + examples).
  final wordbookLoader = WordbookLoader(db: appDb);
  await wordbookLoader.loadIfNeeded('zk');
  await wordbookLoader.loadIfNeeded('gk');

  // Need #11/#12 (Bug 1 follow-up) — bootstrap is now AWAITED, not
  // fire-and-forget. The seed is a tiny, fast SQLite copy (~9 MB →
  // ATTACH + INSERT-SELECT) and finishes in well under a second on
  // real hardware. Awaiting guarantees the very first frame of
  // StudyPage already has the 4 enrichment modules' data — users
  // never have to manually trigger anything.
  //
  // We bound the wait at 5s with a timeout so a corrupted seed file
  // can't lock the app at splash; on timeout we fall through to
  // launching the UI and the catch-all inside ensurePopulated already
  // logs the failure for diagnosis.
  try {
    await EnrichmentBootstrap(driftDb: appDb)
        .ensurePopulated()
        .timeout(const Duration(seconds: 5));
  } on TimeoutException {
    debugPrint('[main] enrichment bootstrap timed out after 5s — '
        'launching UI anyway; check for slow disk / corrupt seed.');
  } catch (e, st) {
    debugPrint('[main] enrichment bootstrap threw: $e\n$st');
  }

  runApp(const MeowApp());
}
