// Need #11 follow-up: example_sentences should resolve by lowercased
// word_text via a cross-wordbook join, so CET-4 'ability' (cet4-…)
// inherits ZK 'ability' (zk-…) examples.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/storage/drift/app_database.dart';

void main() {
  group('AppDatabase.getExamplesForWordText', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });
    tearDown(() async => db.close());

    test('returns empty list when no examples exist', () async {
      final res = await db.getExamplesForWordText('abandon');
      expect(res, isEmpty);
    });

    test('joins examples across wordbooks by lowercase word_text', () async {
      // Two wordbooks each carry 'ability' under different word_ids.
      // Only the ZK book ships with examples; CET-4's word_id is in
      // word_entries with no example_sentences row of its own.
      await db.into(db.wordEntries).insert(WordEntriesCompanion.insert(
            wordId: 'zk-001',
            wordText: 'ability',
            meaning: '能力',
            importedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ));
      await db.into(db.wordEntries).insert(WordEntriesCompanion.insert(
            wordId: 'cet4-7',
            wordText: 'ability',
            meaning: '能力',
            importedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ));
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'zk-001',
              sense: 'n.',
              en: 'She has the ability to learn fast.',
              cn: '她学得很快。',
              sortOrder: const Value(0),
            ),
          );

      // Look up by lowercase word_text — ZK example must surface,
      // even though we never asked for zk-001.
      final res = await db.getExamplesForWordText('ability');
      expect(res.length, 1);
      expect(res.first.wordId, 'zk-001');
      expect(res.first.en, contains('She has the ability'));
    });

    test('case-insensitive lookup', () async {
      await db.into(db.wordEntries).insert(WordEntriesCompanion.insert(
            wordId: 'zk-2',
            wordText: 'Quick',
            meaning: '快的',
            importedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ));
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'zk-2',
              sense: 'adj.',
              en: 'Quick fox.',
              cn: '敏捷的狐狸。',
              sortOrder: const Value(0),
            ),
          );

      expect((await db.getExamplesForWordText('quick')).length, 1);
      expect((await db.getExamplesForWordText('QUICK')).length, 1);
      expect((await db.getExamplesForWordText('  Quick  ')).length, 1);
    });

    test('respects limit + sort_order', () async {
      await db.into(db.wordEntries).insert(WordEntriesCompanion.insert(
            wordId: 'zk-3',
            wordText: 'run',
            meaning: '跑',
            importedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ));
      for (var i = 0; i < 5; i++) {
        await db.into(db.exampleSentences).insert(
              ExampleSentencesCompanion.insert(
                wordId: 'zk-3',
                sense: 'v.',
                en: 'Run sentence #$i',
                cn: '跑 #$i',
                sortOrder: Value(i),
              ),
            );
      }
      final res = await db.getExamplesForWordText('run', limit: 2);
      expect(res.length, 2);
      expect(res[0].sortOrder, 0);
      expect(res[1].sortOrder, 1);
    });

    test('blank input returns empty without hitting DB', () async {
      expect(await db.getExamplesForWordText(''), isEmpty);
      expect(await db.getExamplesForWordText('   '), isEmpty);
    });
  });
}
