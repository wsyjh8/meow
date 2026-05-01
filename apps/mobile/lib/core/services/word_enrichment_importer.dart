import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../storage/drift/app_database.dart';

/// Need #11 — Debug-only importer for the local enrichment layer.
///
/// Loads the bundled JSONL files (`assets/forms/word_*.jsonl`) and writes
/// rows into [WordForms] / [WordRelations] / [WordPhrases]. Touch nothing
/// else — no FSRS, no rewards, no sessions. The importer is idempotent
/// when [replace] = true (default): existing enrichment rows are wiped
/// before inserting.
///
/// This is a development convenience: production behaviour, when the
/// real importer ships, will land via a different path. Keep this
/// detached from any user-facing rollout flag.
class WordEnrichmentImporter {
  WordEnrichmentImporter({AppDatabase? driftDb})
      : _db = driftDb ?? AppDatabase();

  final AppDatabase _db;

  /// Insert chunk size. Drift's [batch] holds inserts in memory until
  /// commit, so chunking keeps RSS bounded for the relations / phrases
  /// files (~50–70K rows, multi-MB JSON).
  static const int _chunkSize = 2000;

  /// Run all 3 imports. [onProgress] fires as `(label, done, total?)`
  /// after each chunk so the UI can show progress.
  /// `total` is null while the file is still being parsed.
  Future<ImportStats> importAll({
    bool replace = true,
    void Function(String label, int done, int? total)? onProgress,
  }) async {
    final stats = ImportStats();

    if (replace) {
      onProgress?.call('清理旧增强数据', 0, null);
      await _db.delete(_db.wordForms).go();
      await _db.delete(_db.wordRelations).go();
      await _db.delete(_db.wordPhrases).go();
    }

    stats.forms = await _importForms(onProgress);
    stats.relations = await _importRelations(onProgress);
    stats.phrases = await _importPhrases(onProgress);

    return stats;
  }

  Future<int> _importForms(
    void Function(String, int, int?)? onProgress,
  ) async {
    return _streamImport(
      assetPath: 'assets/forms/word_forms.jsonl',
      label: '其他形式',
      onProgress: onProgress,
      makeRow: (m) => WordFormsCompanion.insert(
        word: (m['word'] as String).toLowerCase(),
        formText: m['form_text'] as String,
        formType: m['form_type'] as String,
        pos: Value(m['pos'] as String?),
        source: Value(m['source'] as String?),
      ),
      table: _db.wordForms,
    );
  }

  Future<int> _importRelations(
    void Function(String, int, int?)? onProgress,
  ) async {
    return _streamImport(
      assetPath: 'assets/forms/word_relations.jsonl',
      label: '近反义词',
      onProgress: onProgress,
      makeRow: (m) => WordRelationsCompanion.insert(
        word: (m['word'] as String).toLowerCase(),
        targetWord: (m['target_word'] as String).toLowerCase(),
        relationType: m['relation_type'] as String,
        pos: Value(m['pos'] as String?),
        confidence: Value((m['confidence'] as num?)?.toDouble()),
        source: Value(m['source'] as String?),
      ),
      table: _db.wordRelations,
    );
  }

  Future<int> _importPhrases(
    void Function(String, int, int?)? onProgress,
  ) async {
    return _streamImport(
      assetPath: 'assets/forms/word_phrases.jsonl',
      label: '常见词组',
      onProgress: onProgress,
      makeRow: (m) => WordPhrasesCompanion.insert(
        word: (m['word'] as String).toLowerCase(),
        phraseText: m['phrase_text'] as String,
        phraseType: Value(m['phrase_type'] as String? ?? 'common_phrase'),
        score: Value((m['score'] as num?)?.toInt()),
        source: Value(m['source'] as String?),
      ),
      table: _db.wordPhrases,
    );
  }

  /// Generic per-file streaming import. Counts and skips malformed lines
  /// silently — debug-flow data may have stragglers and we don't want
  /// one bad line to abort 60K good rows.
  Future<int> _streamImport<T extends Table, R>({
    required String assetPath,
    required String label,
    required Insertable<R> Function(Map<String, dynamic>) makeRow,
    required TableInfo<T, R> table,
    void Function(String, int, int?)? onProgress,
  }) async {
    onProgress?.call(label, 0, null);
    final raw = await rootBundle.loadString(assetPath);
    final lines =
        raw.split('\n').where((l) => l.trim().isNotEmpty).toList(growable: false);
    final total = lines.length;
    var inserted = 0;

    for (var i = 0; i < total; i += _chunkSize) {
      final end = (i + _chunkSize) < total ? (i + _chunkSize) : total;
      final batchInserts = <Insertable<R>>[];
      for (var j = i; j < end; j++) {
        try {
          final m = json.decode(lines[j]) as Map<String, dynamic>;
          batchInserts.add(makeRow(m));
        } catch (_) {
          // skip malformed line
        }
      }
      if (batchInserts.isNotEmpty) {
        await _db.batch((b) => b.insertAll(table, batchInserts));
        inserted += batchInserts.length;
      }
      onProgress?.call(label, end, total);
    }
    return inserted;
  }
}

class ImportStats {
  int forms = 0;
  int relations = 0;
  int phrases = 0;

  int get total => forms + relations + phrases;

  @override
  String toString() =>
      '其他形式 $forms · 近反义词 $relations · 常见词组 $phrases';
}
