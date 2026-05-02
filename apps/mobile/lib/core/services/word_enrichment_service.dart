import 'dart:convert';

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
  /// Need #12: PRD 6 — "默认最多展示 3–5 条". Pick the upper bound.
  static const int morphemesCap = 5;

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

    // Need #12 — pull all matches; sorting happens in Dart since we
    // need a multi-key order (type bucket → confidence DESC →
    // morpheme length DESC) that's awkward in pure SQL.
    final morphemesFut = (_db.select(_db.wordMorphemeMatches)
          ..where((t) => t.word.equals(key)))
        .get();

    final results = await Future.wait(
      [formsFut, relationsFut, phrasesFut, morphemesFut],
    );

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

    final morphemes = _toMorphemeMatches(
      results[3] as List<WordMorphemeMatche>,
    );

    return WordEnrichment(
      forms: forms,
      synonyms: synonyms,
      antonyms: antonyms,
      phrases: phrases,
      morphemes: morphemes,
    );
  }

  /// Convert raw drift rows into the UI-facing [MorphemeMatch] list,
  /// applying PRD 6 ordering and the [morphemesCap] cap.
  ///
  /// Sort key (high → low priority):
  ///   1. type bucket: prefix → root_or_stem → suffix → other
  ///   2. confidence DESC (null → 0)
  ///   3. len(morpheme) DESC — longer morphemes are more informative
  // Note on type name: drift autogenerates the row class by stripping
  // the trailing 's' from the table name, so [WordMorphemeMatches]
  // table → [WordMorphemeMatche] row class. The awkward spelling is
  // contained to this private helper.
  List<MorphemeMatch> _toMorphemeMatches(List<WordMorphemeMatche> rows) {
    if (rows.isEmpty) return const [];
    final converted = rows.map((r) {
      List<String> meanings;
      try {
        final raw = json.decode(r.meaningsJson);
        meanings = raw is List ? raw.map((e) => e.toString()).toList() : const [];
      } catch (_) {
        meanings = const [];
      }
      return MorphemeMatch(
        morpheme: r.morpheme,
        normalizedMorpheme: r.normalizedMorpheme,
        morphemeType: r.morphemeType,
        position: r.position,
        meanings: meanings,
        confidence: r.confidence ?? 0.0,
      );
    }).toList();

    converted.sort((a, b) {
      final aBucket = _typeBucket(a.morphemeType);
      final bBucket = _typeBucket(b.morphemeType);
      if (aBucket != bBucket) return aBucket.compareTo(bBucket);
      final cConf = b.confidence.compareTo(a.confidence);
      if (cConf != 0) return cConf;
      return b.morpheme.length.compareTo(a.morpheme.length);
    });

    return converted.take(morphemesCap).toList(growable: false);
  }

  static int _typeBucket(String type) {
    switch (type) {
      case 'prefix':
        return 0;
      case 'root_or_stem':
        return 1;
      case 'suffix':
        return 2;
      default:
        return 3;
    }
  }
}

/// One morpheme match for a single word — what UI renders per row.
class MorphemeMatch {
  /// Original surface form, e.g. "ab-" or "-tion".
  final String morpheme;
  /// Lower-case canonical form without affix dashes.
  final String normalizedMorpheme;
  /// One of: prefix / suffix / root_or_stem.
  final String morphemeType;
  /// Where the matcher placed this morpheme in the source word.
  final String position;
  /// Meanings carried by this specific match — distinct from the
  /// catalog's full meaning list, scoped to this hit.
  final List<String> meanings;
  /// 0..1 score from the upstream matcher. Drives sort, not surfaced.
  final double confidence;

  const MorphemeMatch({
    required this.morpheme,
    required this.normalizedMorpheme,
    required this.morphemeType,
    required this.position,
    required this.meanings,
    required this.confidence,
  });
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
  final List<MorphemeMatch> morphemes;

  const WordEnrichment({
    required this.forms,
    required this.synonyms,
    required this.antonyms,
    required this.phrases,
    this.morphemes = const [],
  });

  static const WordEnrichment empty = WordEnrichment(
    forms: [],
    synonyms: [],
    antonyms: [],
    phrases: [],
    morphemes: [],
  );

  bool get isEmpty =>
      forms.isEmpty &&
      synonyms.isEmpty &&
      antonyms.isEmpty &&
      phrases.isEmpty &&
      morphemes.isEmpty;

  bool get hasForms => forms.isNotEmpty;
  bool get hasRelations => synonyms.isNotEmpty || antonyms.isNotEmpty;
  bool get hasPhrases => phrases.isNotEmpty;
  bool get hasMorphemes => morphemes.isNotEmpty;
}
