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
