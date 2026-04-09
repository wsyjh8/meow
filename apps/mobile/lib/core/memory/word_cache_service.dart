import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../storage/drift/app_database.dart';

/// Service to download and cache word lists from backend into local SQLite.
///
/// The cached_words table enables offline word selection by SessionBuilder.
/// Typical flow:
///   1. App startup or book switch → check if cache is populated
///   2. If empty → download in pages from GET /api/v1/books/:bookId/words
///   3. SessionBuilder queries cached_words for new-word candidates
class WordCacheService {
  final AppDatabase _db;
  final String _baseUrl;

  WordCacheService({
    required AppDatabase db,
    String baseUrl = 'http://10.0.2.2:3000/api/v1',
  })  : _db = db,
        _baseUrl = baseUrl;

  /// Check how many words are cached for a given book.
  Future<int> getCachedCount(String bookId) async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM cached_words WHERE book_id = ?',
      variables: [Variable.withString(bookId)],
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Download all words for a book from backend and cache locally.
  ///
  /// Uses pagination (500 per page) to avoid huge single responses.
  /// Idempotent: uses INSERT OR REPLACE on word_id PK.
  ///
  /// Returns the total number of words cached.
  Future<int> downloadAndCacheBook(String bookId) async {
    int offset = 0;
    const pageSize = 500;
    int totalCached = 0;
    final client = http.Client();
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    try {
      while (true) {
        final uri = Uri.parse(
            '$_baseUrl/books/$bookId/words?offset=$offset&limit=$pageSize');
        final response = await client.get(uri);

        if (response.statusCode != 200) {
          throw Exception(
              'Failed to fetch words: ${response.statusCode}');
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        final words = data['words'] as List;
        final total = data['total'] as int;

        if (words.isEmpty) break;

        // Batch insert into cached_words
        await _db.batch((batch) {
          for (final w in words) {
            batch.insert(
              _db.cachedWords,
              CachedWordsCompanion.insert(
                wordId: (w['word_id'] ?? w['wordId'] ?? '') as String,
                bookId: (w['book_id'] ?? w['bookId'] ?? bookId) as String,
                wordText:
                    (w['word_text'] ?? w['wordText'] ?? '') as String,
                meaning: (w['meaning'] ?? '') as String,
                phonetic: Value((w['phonetic'] as String?)),
                translation: Value((w['translation'] as String?)),
                frequencyRank: Value(
                    (w['frequency_rank'] ?? w['frequencyRank'] ?? 0) as int),
                sortOrder: Value(
                    (w['sort_order'] ?? w['sortOrder'] ?? 0) as int),
                cachedAt: nowMs,
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });

        totalCached += words.length;
        offset += pageSize;

        // If we got less than a full page, we're done
        if (words.length < pageSize || offset >= total) break;
      }
    } finally {
      client.close();
    }

    return totalCached;
  }

  /// Ensure the book's word cache is populated.
  /// If already cached, returns immediately. Otherwise downloads.
  Future<int> ensureCached(String bookId) async {
    final count = await getCachedCount(bookId);
    if (count > 0) return count;
    return await downloadAndCacheBook(bookId);
  }
}
