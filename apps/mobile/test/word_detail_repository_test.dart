import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/api/api_client.dart' show Word;
import 'package:meow_mobile/core/services/learning_word_detail.dart';
import 'package:meow_mobile/core/services/word_detail_repository.dart';
import 'package:meow_mobile/core/services/word_enrichment_service.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

/// Test double that lets each test control timing and outcomes per key
/// without touching a real DB. We extend [WordEnrichmentService] only
/// to satisfy the constructor signature; the parent's [_db] is never
/// actually used because we override [getFor].
class _FakeEnrichmentService extends WordEnrichmentService {
  _FakeEnrichmentService(AppDatabase db) : super(driftDb: db);

  final List<String> calls = [];
  final Map<String, Completer<WordEnrichment>> _completers = {};

  @override
  Future<WordEnrichment> getFor(String wordText) {
    calls.add(wordText);
    final completer = Completer<WordEnrichment>();
    _completers[wordText] = completer;
    return completer.future;
  }

  void complete(String key, WordEnrichment value) {
    _completers[key]?.complete(value);
  }

  void fail(String key, Object err) {
    _completers[key]?.completeError(err);
  }
}

WordEnrichment _stub(String key) => WordEnrichment(
      forms: [WordFormItem(formText: '$key-form', formType: 'past')],
      synonyms: const [],
      antonyms: const [],
      phrases: const [],
    );

Word _word(String wordText) => Word(
      wordId: 'id-$wordText',
      wordText: wordText,
      meaning: '',
      bookId: 'book-001',
    );

void main() {
  late AppDatabase db;
  late _FakeEnrichmentService service;

  setUp(() {
    // Real in-memory DB satisfies the parent constructor; never queried.
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = _FakeEnrichmentService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WordDetailRepository', () {
    test('cache hit: second attachEnrichment for same key reuses cached entry', () async {
      final repo = WordDetailRepository(service);

      final fut1 = repo.attachEnrichment(_word('alpha'));
      service.complete('alpha', _stub('alpha'));
      final detail1 = await fut1;
      expect(detail1.enrichment.forms.first.formText, 'alpha-form');
      expect(service.calls, ['alpha']);

      final detail2 = await repo.attachEnrichment(_word('alpha'));
      expect(detail2.enrichment.forms.first.formText, 'alpha-form');
      expect(service.calls, ['alpha'], reason: 'cache hit must not re-query');
    });

    test('cache key is normalized: "Abandon  " and "abandon" hit same entry', () async {
      final repo = WordDetailRepository(service);

      final fut = repo.attachEnrichment(_word('Abandon  '));
      service.complete('abandon', _stub('abandon'));
      await fut;
      expect(service.calls, ['abandon']);

      await repo.attachEnrichment(_word('ABANDON'));
      expect(service.calls, ['abandon'], reason: 'second variant should hit cache');
    });

    test('LRU eviction: oldest entry drops when capacity exceeded', () async {
      final repo = WordDetailRepository(service, cacheSize: 2);

      for (final key in ['a', 'b', 'c']) {
        final fut = repo.attachEnrichment(_word(key));
        service.complete(key, _stub(key));
        await fut;
      }
      expect(service.calls, ['a', 'b', 'c']);

      // 'a' should have been evicted (oldest of 3 with capacity 2);
      // 'b' and 'c' should still hit cache.
      final fut = repo.attachEnrichment(_word('a'));
      service.complete('a', _stub('a'));
      await fut;
      expect(service.calls, ['a', 'b', 'c', 'a'], reason: 'a was evicted, re-queried');

      await repo.attachEnrichment(_word('c'));
      expect(service.calls.length, 4, reason: 'c still cached, no extra call');
    });

    test('LRU recency: read promotes entry, preventing premature eviction', () async {
      final repo = WordDetailRepository(service, cacheSize: 2);

      // Fill with a, b.
      for (final key in ['a', 'b']) {
        final fut = repo.attachEnrichment(_word(key));
        service.complete(key, _stub(key));
        await fut;
      }
      // Touch 'a' — should promote it to most-recent.
      await repo.attachEnrichment(_word('a'));
      // Insert 'c' — should evict 'b' (LRU), not 'a'.
      final fut = repo.attachEnrichment(_word('c'));
      service.complete('c', _stub('c'));
      await fut;

      // 'a' should still be cached (no extra call), 'b' should miss.
      await repo.attachEnrichment(_word('a'));
      expect(service.calls, ['a', 'b', 'c'], reason: 'a still cached after touch');

      final fut2 = repo.attachEnrichment(_word('b'));
      service.complete('b', _stub('b'));
      await fut2;
      expect(service.calls, ['a', 'b', 'c', 'b'], reason: 'b was evicted, re-queried');
    });

    test('warmUpWordTexts skips keys already in cache', () async {
      final repo = WordDetailRepository(service);

      final fut = repo.attachEnrichment(_word('alpha'));
      service.complete('alpha', _stub('alpha'));
      await fut;
      expect(service.calls, ['alpha']);

      // 'alpha' is cached; 'beta' is fresh.
      final warm = repo.warmUpWordTexts(['alpha', 'beta']);
      service.complete('beta', _stub('beta'));
      await warm;

      expect(service.calls, ['alpha', 'beta'], reason: 'alpha skipped, beta loaded');
    });

    test('in-flight de-dup: warmUp + attachEnrichment for same key share one query', () async {
      final repo = WordDetailRepository(service);

      // Kick off a warm-up but do not complete the future yet.
      final warm = repo.warmUpWordTexts(['gamma']);
      // Concurrent attachEnrichment for the same key should join the
      // pending Future rather than launching a second query.
      final attach = repo.attachEnrichment(_word('gamma'));

      // Yield so warmUp's await actually subscribes.
      await Future.delayed(Duration.zero);
      expect(service.calls, ['gamma'], reason: 'only one underlying call');

      service.complete('gamma', _stub('gamma'));
      await warm;
      final detail = await attach;
      expect(detail.enrichment.forms.first.formText, 'gamma-form');
      expect(service.calls, ['gamma'], reason: 'still exactly one call after settle');
    });

    test('failure returns empty enrichment and does NOT poison cache', () async {
      final repo = WordDetailRepository(service);

      final fut = repo.attachEnrichment(_word('flaky'));
      service.fail('flaky', Exception('boom'));
      final detail = await fut;
      expect(detail.enrichment.isEmpty, isTrue);

      // Next call must retry — empty result must not have been cached.
      final fut2 = repo.attachEnrichment(_word('flaky'));
      service.complete('flaky', _stub('flaky'));
      final detail2 = await fut2;
      expect(detail2.enrichment.forms.first.formText, 'flaky-form');
      expect(service.calls, ['flaky', 'flaky'], reason: 'failure did not pollute cache');
    });

    test('warmUpWordTexts swallows failures so callers can fire-and-forget', () async {
      final repo = WordDetailRepository(service);

      final warm = repo.warmUpWordTexts(['kaboom']);
      service.fail('kaboom', Exception('boom'));
      // Must complete normally, not throw.
      await warm;
      expect(service.calls, ['kaboom']);
    });

    test('detail returned by attachEnrichment carries the original word', () async {
      final repo = WordDetailRepository(service);
      final word = _word('delta');

      final fut = repo.attachEnrichment(word);
      service.complete('delta', _stub('delta'));
      final detail = await fut;
      expect(detail, isA<LearningWordDetail>());
      expect(detail.wordId, 'id-delta');
      expect(detail.wordText, 'delta');
      expect(identical(detail.word, word), isTrue);
    });

    test('empty wordTexts list in warmUpWordTexts is a no-op', () async {
      final repo = WordDetailRepository(service);
      await repo.warmUpWordTexts([]);
      expect(service.calls, isEmpty);
    });

    test('blank string in warmUpWordTexts is skipped', () async {
      final repo = WordDetailRepository(service);
      final warm = repo.warmUpWordTexts(['   ']);
      // Should not have started any query.
      await Future.delayed(Duration.zero);
      expect(service.calls, isEmpty);
      await warm;
    });
  });
}
