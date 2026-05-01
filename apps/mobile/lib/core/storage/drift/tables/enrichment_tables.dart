/// Need #11 — local-only enrichment layer (other forms / synonyms +
/// antonyms / common phrases).
///
/// Each table is keyed on the lowercase [word] text so it joins
/// directly against [cached_words.word_text] and
/// [word_entries.word_text]. The columns mirror the JSONL files in
/// `docs/forms/` so the future importer can land rows 1:1.
///
/// FSRS / rewards / settlement / sessions are untouched.
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_word_forms_word', columns: {#word})
class WordForms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get formText => text().named('form_text')();
  TextColumn get formType => text().named('form_type')();
  TextColumn get pos => text().nullable()();
  TextColumn get source => text().nullable()();
}

@TableIndex(name: 'idx_word_relations_word', columns: {#word})
class WordRelations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get targetWord => text().named('target_word')();
  TextColumn get relationType => text().named('relation_type')();
  TextColumn get pos => text().nullable()();
  RealColumn get confidence => real().nullable()();
  TextColumn get source => text().nullable()();
}

@TableIndex(name: 'idx_word_phrases_word', columns: {#word})
class WordPhrases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get phraseText => text().named('phrase_text')();
  TextColumn get phraseType =>
      text().named('phrase_type').withDefault(const Constant('common_phrase'))();
  IntColumn get score => integer().nullable()();
  TextColumn get source => text().nullable()();
}
