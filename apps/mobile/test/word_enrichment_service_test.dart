import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/services/word_enrichment_service.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

void main() {
  group('WordEnrichmentService', () {
    late AppDatabase db;
    late WordEnrichmentService svc;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      svc = WordEnrichmentService(driftDb: db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seedAbandon() async {
      await db.batch((b) {
        b.insertAll(db.wordForms, [
          WordFormsCompanion.insert(
            word: 'abandon',
            formText: 'abandoned',
            formType: 'past',
            pos: const Value('verb'),
          ),
          WordFormsCompanion.insert(
            word: 'abandon',
            formText: 'abandoning',
            formType: 'present_participle',
            pos: const Value('verb'),
          ),
        ]);
        b.insertAll(db.wordRelations, [
          WordRelationsCompanion.insert(
            word: 'abandon',
            targetWord: 'desert',
            relationType: 'synonym',
            pos: const Value('verb'),
          ),
          WordRelationsCompanion.insert(
            word: 'abandon',
            targetWord: 'forsake',
            relationType: 'synonym',
            pos: const Value('verb'),
          ),
          // Same target seen in another sense — must dedupe.
          WordRelationsCompanion.insert(
            word: 'abandon',
            targetWord: 'desert',
            relationType: 'synonym',
            pos: const Value('verb'),
          ),
          WordRelationsCompanion.insert(
            word: 'abandon',
            targetWord: 'keep',
            relationType: 'antonym',
            pos: const Value('verb'),
          ),
        ]);
        b.insertAll(db.wordPhrases, [
          WordPhrasesCompanion.insert(
            word: 'abandon',
            phraseText: 'abandon hope',
            score: const Value(500),
          ),
          WordPhrasesCompanion.insert(
            word: 'abandon',
            phraseText: 'abandon a plan',
            score: const Value(900),
          ),
        ]);
      });
    }

    test('returns empty payload for an unknown word — no errors', () async {
      final res = await svc.getFor('nonexistent-word');
      expect(res.isEmpty, isTrue);
      expect(res.hasForms, isFalse);
      expect(res.hasRelations, isFalse);
      expect(res.hasPhrases, isFalse);
    });

    test('returns forms / synonyms+antonyms / phrases for known word', () async {
      await seedAbandon();
      final res = await svc.getFor('abandon');

      expect(res.forms.map((f) => f.formText), containsAll(['abandoned', 'abandoning']));
      expect(res.forms.first.formType, anyOf('past', 'present_participle'));

      // Synonyms deduped, antonyms separate.
      expect(res.synonyms, containsAll(['desert', 'forsake']));
      expect(res.synonyms.where((w) => w == 'desert').length, 1);
      expect(res.antonyms, ['keep']);

      // Phrases sorted by score desc.
      expect(res.phrases.first, 'abandon a plan');
      expect(res.phrases.last, 'abandon hope');
    });

    test('lookup is case-insensitive (lowercases input)', () async {
      await seedAbandon();
      final res = await svc.getFor('ABANDON');
      expect(res.forms, isNotEmpty);
      expect(res.synonyms, isNotEmpty);
      expect(res.phrases, isNotEmpty);
    });

    test('blank input returns the canonical empty payload', () async {
      final res = await svc.getFor('   ');
      expect(identical(res, WordEnrichment.empty), isTrue);
    });

    test('morpheme matches: empty when no rows exist (Need #12)', () async {
      final res = await svc.getFor('xyz-no-matches');
      expect(res.morphemes, isEmpty);
      expect(res.hasMorphemes, isFalse);
    });

    test('morpheme matches: sorted prefix → root → suffix; cap=5 (Need #12)',
        () async {
      // Seed 7 matches in a deliberately wrong order to prove the
      // service re-sorts them.
      Future<void> insert({
        required String morpheme,
        required String type,
        double conf = 0.5,
        String? meanings,
      }) async {
        await db.into(db.wordMorphemeMatches).insert(
              WordMorphemeMatchesCompanion.insert(
                word: 'long-word',
                morpheme: morpheme,
                normalizedMorpheme: morpheme.replaceAll('-', ''),
                morphemeType: type,
                position: type == 'prefix' ? 'prefix' : 'suffix',
                meaningsJson: '["${meanings ?? "x"}"]',
                confidence: Value(conf),
              ),
            );
      }

      // suffixes (low priority)
      await insert(morpheme: '-ing', type: 'suffix', conf: 0.9);
      await insert(morpheme: '-tion', type: 'suffix', conf: 0.7);
      // prefixes (top priority) — within group, higher conf comes first
      await insert(morpheme: 'pre-', type: 'prefix', conf: 0.6);
      await insert(morpheme: 'un-', type: 'prefix', conf: 0.95);
      // root_or_stem (middle)
      await insert(morpheme: 'spect', type: 'root_or_stem', conf: 0.85);
      // 6th + 7th elements should be cut by cap=5
      await insert(morpheme: '-ize', type: 'suffix', conf: 0.5);
      await insert(morpheme: '-ly', type: 'suffix', conf: 0.4);

      final res = await svc.getFor('long-word');
      expect(res.morphemes.length, 5, reason: 'cap = 5');

      // Ordering: un-(prefix,0.95) → pre-(prefix,0.6) →
      // spect(root,0.85) → -ing(suffix,0.9) → -tion(suffix,0.7)
      final ms = res.morphemes;
      expect(ms[0].morpheme, 'un-');
      expect(ms[1].morpheme, 'pre-');
      expect(ms[2].morpheme, 'spect');
      expect(ms[3].morpheme, '-ing');
      expect(ms[4].morpheme, '-tion');
    });

    test('morpheme matches: meanings_json parsed into list (Need #12)',
        () async {
      await db.into(db.wordMorphemeMatches).insert(
            WordMorphemeMatchesCompanion.insert(
              word: 'abandon',
              morpheme: 'ab-',
              normalizedMorpheme: 'ab',
              morphemeType: 'prefix',
              position: 'prefix',
              meaningsJson: '["away from", "off"]',
              confidence: const Value(0.85),
            ),
          );
      final res = await svc.getFor('abandon');
      expect(res.hasMorphemes, isTrue);
      expect(res.morphemes.first.morpheme, 'ab-');
      expect(res.morphemes.first.meanings, ['away from', 'off']);
      expect(res.morphemes.first.confidence, closeTo(0.85, 1e-6));
    });

    test('morpheme matches: malformed JSON falls back to empty meanings',
        () async {
      await db.into(db.wordMorphemeMatches).insert(
            WordMorphemeMatchesCompanion.insert(
              word: 'broken',
              morpheme: 'ab-',
              normalizedMorpheme: 'ab',
              morphemeType: 'prefix',
              position: 'prefix',
              // Not valid JSON.
              meaningsJson: 'this is not json',
            ),
          );
      final res = await svc.getFor('broken');
      expect(res.hasMorphemes, isTrue);
      expect(res.morphemes.first.meanings, isEmpty);
    });

    test('hasRelations is true with only synonyms or only antonyms', () async {
      await db.into(db.wordRelations).insert(WordRelationsCompanion.insert(
            word: 'only-syn',
            targetWord: 'a',
            relationType: 'synonym',
          ));
      final r1 = await svc.getFor('only-syn');
      expect(r1.hasRelations, isTrue);
      expect(r1.synonyms, ['a']);
      expect(r1.antonyms, isEmpty);

      await db.into(db.wordRelations).insert(WordRelationsCompanion.insert(
            word: 'only-ant',
            targetWord: 'b',
            relationType: 'antonym',
          ));
      final r2 = await svc.getFor('only-ant');
      expect(r2.hasRelations, isTrue);
      expect(r2.synonyms, isEmpty);
      expect(r2.antonyms, ['b']);
    });
  });
}
