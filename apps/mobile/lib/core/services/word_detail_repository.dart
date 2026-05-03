import 'dart:collection';

import 'package:flutter/foundation.dart' show debugPrint;

import '../api/api_client.dart' show Word;
import 'learning_word_detail.dart';
import 'word_enrichment_service.dart';

/// LRU cache + in-flight Future de-duplication on top of
/// [WordEnrichmentService]. Backs [StudyService.attachEnrichment] /
/// [StudyService.warmUpWordTexts] for the study page.
///
/// Why this layer exists: the underlying 4-table drift query takes
/// 170-240ms steady-state and 330ms cold (drift runs them serially on
/// a single isolate). Without a cache, each word switch incurs that
/// latency as a visible second render. With predictive prefetch and
/// LRU re-use (incl. requeue cycles), steady-state cache hits make
/// `attachEnrichment` synchronous-ish.
///
/// Behaviour contract (see study performance plan):
///   * cache key   = wordText.trim().toLowerCase() — same form
///                   [WordEnrichmentService.getFor] uses internally.
///   * LRU semantics: hit moves the entry to most-recently-used.
///                   FIFO behaviour would be wrong (would evict the
///                   currently displayed word).
///   * In-flight de-dupe: if a key is being loaded (e.g. by
///                   [warmUpWordTexts]) and [attachEnrichment] is
///                   called for the same key, both await the same
///                   Future. Cleanup is in try/finally so a failure
///                   never leaks an in-flight entry.
///   * Failure handling: a failed query returns
///                   [WordEnrichment.empty] to the caller (so the UI
///                   simply hides the modules) but the empty value is
///                   NOT written to the cache — next call retries.
class WordDetailRepository {
  WordDetailRepository(this._enrichment, {int cacheSize = 24})
      : _cacheSize = cacheSize;

  final WordEnrichmentService _enrichment;
  final int _cacheSize;

  // LinkedHashMap keeps insertion order; we re-insert on read to
  // promote LRU recency.
  final LinkedHashMap<String, WordEnrichment> _cache = LinkedHashMap();
  final Map<String, Future<WordEnrichment>> _inFlight = {};

  String _normalize(String wordText) => wordText.trim().toLowerCase();

  /// Resolve enrichment for [word] and return a [LearningWordDetail].
  /// Three-level fallback: cache → in-flight Future → fresh query.
  Future<LearningWordDetail> attachEnrichment(Word word) async {
    final key = _normalize(word.wordText);

    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      debugPrint('[perf] detail.cacheHit=true key=$key');
      return LearningWordDetail(word: word, enrichment: cached);
    }
    debugPrint('[perf] detail.cacheHit=false key=$key');

    final enrichment = await _loadOrJoin(key);
    return LearningWordDetail(word: word, enrichment: enrichment);
  }

  /// Fire-and-forget batch warm: ensure every word in [wordTexts] is
  /// either already cached, or has a query in flight. Always returns
  /// successfully — internal failures are silent (the next
  /// [attachEnrichment] for the same key will retry).
  Future<void> warmUpWordTexts(List<String> wordTexts) async {
    for (final wt in wordTexts) {
      final key = _normalize(wt);
      if (key.isEmpty) continue;
      if (_cache.containsKey(key)) continue;
      if (_inFlight.containsKey(key)) continue;
      // Kick off load; await each so the method's Future completes
      // when all warm-ups finish (caller wraps with `unawaited`).
      try {
        await _loadOrJoin(key);
      } catch (_) {
        // already swallowed by _loadOrJoin → cache untouched on failure
      }
    }
  }

  /// Returns the cached value if present, otherwise joins/starts the
  /// in-flight query. Successful results are inserted into the cache;
  /// failures return [WordEnrichment.empty] without polluting cache.
  Future<WordEnrichment> _loadOrJoin(String key) async {
    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;

    final fut = _enrichment.getFor(key);
    _inFlight[key] = fut;
    try {
      final result = await fut;
      _put(key, result);
      return result;
    } catch (_) {
      // Don't cache failures — next call retries.
      return WordEnrichment.empty;
    } finally {
      _inFlight.remove(key);
    }
  }

  void _put(String key, WordEnrichment value) {
    _cache.remove(key);
    _cache[key] = value;
    while (_cache.length > _cacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }
}
