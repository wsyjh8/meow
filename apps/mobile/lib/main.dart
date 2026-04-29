import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/memory/asset_word_loader.dart';
import 'core/memory/wordbook_loader.dart';
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

  runApp(const MeowApp());
}
