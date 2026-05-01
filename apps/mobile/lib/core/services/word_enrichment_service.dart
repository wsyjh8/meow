import 'package:drift/drift.dart';

import '../storage/drift/app_database.dart';

/// Need #11 — Local-only word enrichment reader.
///
/// Joins three tables on the lowercase word text:
/// - word_forms       → "其他形式"
/// - word_relations   → "近反义词"  (synonym + antonym分区)
/// - word_phrases     → "常见词组"
///
/// FSRS / rewards / settlement / sessions / examples are not consulted.
/// All queries return empty lists when there is no data — the UI uses
/// emptiness as the "hide module" signal (no error, no empty title).
class WordEnrichmentService {
  WordEnrichmentService({AppDatabase? driftDb}) : _db = driftDb ?? AppDatabase();

  final AppDatabase _db;

  /// Display caps. Picked to fit the study card without scrolling
  /// dominating the page. Tweaked freely later — they are pure UI
  /// concerns and not part of any frozen contract.
  static const int formsCap = 8;
  static const int synonymsCap = 8;
  static const int antonymsCap = 8;
  static const int phrasesCap = 6;

  Future<WordEnrichment> getFor(String wordText) async {
    final key = wordText.trim().toLowerCase();
    if (key.isEmpty) return WordEnrichment.empty;

    final formsFut = (_db.select(_db.wordForms)
          ..where((t) => t.word.equals(key))
          ..limit(formsCap))
        .get();

    final relationsFut = (_db.select(_db.wordRelations)
          ..where((t) => t.word.equals(key))
          ..limit(synonymsCap + antonymsCap + 16))
        .get();

    final phrasesFut = (_db.select(_db.wordPhrases)
          ..where((t) => t.word.equals(key))
          ..orderBy([
            (t) => OrderingTerm(expression: t.score, mode: OrderingMode.desc),
          ])
          ..limit(phrasesCap))
        .get();

    final results = await Future.wait([formsFut, relationsFut, phrasesFut]);

    final forms = (results[0] as List<WordForm>)
        .map((r) => WordFormItem(
              formText: r.formText,
              formType: r.formType,
              pos: r.pos,
            ))
        .toList();

    // Split synonyms / antonyms; keep first occurrence per target_word
    // to deduplicate (the OEWN dataset can repeat the same target across
    // multiple senses).
    final relationRows = results[1] as List<WordRelation>;
    final seenSyn = <String>{};
    final seenAnt = <String>{};
    final synonyms = <String>[];
    final antonyms = <String>[];
    for (final r in relationRows) {
      final tgt = r.targetWord;
      if (r.relationType == 'synonym') {
        if (seenSyn.add(tgt) && synonyms.length < synonymsCap) {
          synonyms.add(tgt);
        }
      } else if (r.relationType == 'antonym') {
        if (seenAnt.add(tgt) && antonyms.length < antonymsCap) {
          antonyms.add(tgt);
        }
      }
    }

    final phrases = (results[2] as List<WordPhrase>)
        .map((r) => r.phraseText)
        .toList();

    return WordEnrichment(
      forms: forms,
      synonyms: synonyms,
      antonyms: antonyms,
      phrases: phrases,
    );
  }
}

/// One inflected form / variant of a word.
class WordFormItem {
  final String formText;
  final String formType; // past / past_participle / plural / ...
  final String? pos;

  const WordFormItem({
    required this.formText,
    required this.formType,
    this.pos,
  });
}

/// Aggregated enrichment payload for one word. Empty lists mean
/// "hide that module".
class WordEnrichment {
  final List<WordFormItem> forms;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> phrases;

  const WordEnrichment({
    required this.forms,
    required this.synonyms,
    required this.antonyms,
    required this.phrases,
  });

  static const WordEnrichment empty = WordEnrichment(
    forms: [],
    synonyms: [],
    antonyms: [],
    phrases: [],
  );

  bool get isEmpty =>
      forms.isEmpty && synonyms.isEmpty && antonyms.isEmpty && phrases.isEmpty;

  bool get hasForms => forms.isNotEmpty;
  bool get hasRelations => synonyms.isNotEmpty || antonyms.isNotEmpty;
  bool get hasPhrases => phrases.isNotEmpty;
}
