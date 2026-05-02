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

// ── Need #12: word root / affix layer (v8) ─────────────────────────────
//
// Two tables to mirror the source JSONLs and keep the catalog separate
// from per-word matches (PRD: "不要混成一张大表").
//
// `morpheme_entries` is the catalog (≈5k rows). NOT keyed UNIQUE on
// normalized_morpheme — same form may carry multiple meaning entries
// (e.g. "a-" prefix has two distinct meaning sets in the source data).
//
// `word_morpheme_matches` is what StudyPage actually reads. Joins by
// lowercase `word` text (consistent with the other Need #11 tables).
// Redundant fields (morpheme/type/meanings_json/source/confidence) are
// kept on purpose so the read path needs no JOIN — also matches the
// PRD recommendation in section 5.

@TableIndex(name: 'idx_morpheme_entries_norm', columns: {#normalizedMorpheme})
class MorphemeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get morpheme => text()();
  TextColumn get normalizedMorpheme => text().named('normalized_morpheme')();
  // 'prefix' | 'suffix' | 'root_or_stem'
  TextColumn get morphemeType => text().named('morpheme_type')();
  // JSON-serialised List<String>
  TextColumn get meaningsJson => text().named('meanings_json')();
  TextColumn get examplesJson => text().named('examples_json').nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get license => text().nullable()();
}

@TableIndex(name: 'idx_word_morpheme_matches_word', columns: {#word})
class WordMorphemeMatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get morpheme => text()();
  TextColumn get normalizedMorpheme => text().named('normalized_morpheme')();
  TextColumn get morphemeType => text().named('morpheme_type')();
  // 'prefix' | 'suffix' | 'example_exact'
  TextColumn get position => text()();
  TextColumn get meaningsJson => text().named('meanings_json')();
  TextColumn get matchMethod => text().named('match_method').nullable()();
  // 0..1 confidence — drives sort ordering, not surfaced to the user.
  RealColumn get confidence => real().nullable()();
  TextColumn get source => text().nullable()();
}
