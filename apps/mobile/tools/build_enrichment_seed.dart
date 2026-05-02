// One-shot dev tool: turn the three docs/forms/*.jsonl files into a
// pre-populated SQLite database file so the APK can ship the data
// already imported. The bootstrap on first launch then only needs to
// ATTACH this seed and INSERT-SELECT — no JSON parsing on device.
//
// Run from apps/mobile/:
//   dart run tools/build_enrichment_seed.dart
//
// Output:
//   apps/mobile/assets/seed/enrichment_v1.db
//
// The seed schema is intentionally a separate, minimal sqlite file
// (NOT a full drift database). Only the three enrichment tables are
// created, with the same column names + index names drift expects on
// the live device DB. INSERT-SELECT works as long as columns match.
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

// Resolve paths relative to apps/mobile (the cwd `dart run` should
// be invoked from). All inputs ship with the repo (docs/forms/) but
// the output lands under assets/seed/ which is .gitignored.
final _repoRoot = _findRepoRoot();
final _formsDir = Directory(
  '${_repoRoot.path}${Platform.pathSeparator}docs${Platform.pathSeparator}forms',
);
final _outFile = File(
  'assets${Platform.pathSeparator}seed${Platform.pathSeparator}enrichment_v1.db',
);

const _chunkSize = 5000;

Directory _findRepoRoot() {
  // Walk up from cwd until we hit the dir containing docs/forms/.
  var dir = Directory.current.absolute;
  while (true) {
    final candidate = Directory(
      '${dir.path}${Platform.pathSeparator}docs'
      '${Platform.pathSeparator}forms',
    );
    if (candidate.existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Could not locate repo root (looked for docs/forms/ above ${Directory.current.path})',
      );
    }
    dir = parent;
  }
}

void main() {
  if (!_formsDir.existsSync()) {
    stderr.writeln('docs/forms/ not found at ${_formsDir.path}');
    exit(1);
  }

  if (_outFile.existsSync()) {
    stdout.writeln('removing existing ${_outFile.path}');
    _outFile.deleteSync();
  }
  _outFile.parent.createSync(recursive: true);

  final db = sqlite3.open(_outFile.path);
  try {
    db.execute('PRAGMA journal_mode = OFF;');
    db.execute('PRAGMA synchronous = OFF;');
    db.execute('PRAGMA temp_store = MEMORY;');

    _createSchema(db);

    final stopwatch = Stopwatch()..start();
    final formsCount = _importForms(db);
    final relationsCount = _importRelations(db);
    final phrasesCount = _importPhrases(db);
    stopwatch.stop();

    db.execute('VACUUM;');

    final sizeBytes = _outFile.lengthSync();
    final sizeMb = (sizeBytes / 1024 / 1024).toStringAsFixed(2);

    stdout.writeln('—' * 60);
    stdout.writeln('enrichment_v1.db built');
    stdout.writeln('  forms     : $formsCount rows');
    stdout.writeln('  relations : $relationsCount rows');
    stdout.writeln('  phrases   : $phrasesCount rows');
    stdout.writeln('  total time: ${stopwatch.elapsed.inSeconds}s');
    stdout.writeln('  file size : ${sizeMb} MB');
    stdout.writeln('  out path  : ${_outFile.absolute.path}');
  } finally {
    db.dispose();
  }
}

void _createSchema(Database db) {
  db.execute('''
    CREATE TABLE word_forms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word TEXT NOT NULL,
      form_text TEXT NOT NULL,
      form_type TEXT NOT NULL,
      pos TEXT,
      source TEXT
    )
  ''');
  db.execute('CREATE INDEX idx_word_forms_word ON word_forms(word)');

  db.execute('''
    CREATE TABLE word_relations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word TEXT NOT NULL,
      target_word TEXT NOT NULL,
      relation_type TEXT NOT NULL,
      pos TEXT,
      confidence REAL,
      source TEXT
    )
  ''');
  db.execute(
    'CREATE INDEX idx_word_relations_word ON word_relations(word)',
  );

  db.execute('''
    CREATE TABLE word_phrases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word TEXT NOT NULL,
      phrase_text TEXT NOT NULL,
      phrase_type TEXT NOT NULL DEFAULT 'common_phrase',
      score INTEGER,
      source TEXT
    )
  ''');
  db.execute('CREATE INDEX idx_word_phrases_word ON word_phrases(word)');
}

int _importForms(Database db) {
  final file =
      File('${_formsDir.path}${Platform.pathSeparator}word_forms.jsonl');
  final stmt = db.prepare(
    'INSERT INTO word_forms (word, form_text, form_type, pos, source) '
    'VALUES (?, ?, ?, ?, ?)',
  );
  try {
    return _streamInsert(db, file, (m) {
      stmt.execute([
        (m['word'] as String).toLowerCase(),
        m['form_text'],
        m['form_type'],
        m['pos'],
        m['source'],
      ]);
    });
  } finally {
    stmt.dispose();
  }
}

int _importRelations(Database db) {
  final file =
      File('${_formsDir.path}${Platform.pathSeparator}word_relations.jsonl');
  final stmt = db.prepare(
    'INSERT INTO word_relations '
    '(word, target_word, relation_type, pos, confidence, source) '
    'VALUES (?, ?, ?, ?, ?, ?)',
  );
  try {
    return _streamInsert(db, file, (m) {
      stmt.execute([
        (m['word'] as String).toLowerCase(),
        (m['target_word'] as String).toLowerCase(),
        m['relation_type'],
        m['pos'],
        (m['confidence'] as num?)?.toDouble(),
        m['source'],
      ]);
    });
  } finally {
    stmt.dispose();
  }
}

int _importPhrases(Database db) {
  final file =
      File('${_formsDir.path}${Platform.pathSeparator}word_phrases.jsonl');
  final stmt = db.prepare(
    'INSERT INTO word_phrases '
    '(word, phrase_text, phrase_type, score, source) '
    'VALUES (?, ?, ?, ?, ?)',
  );
  try {
    return _streamInsert(db, file, (m) {
      stmt.execute([
        (m['word'] as String).toLowerCase(),
        m['phrase_text'],
        m['phrase_type'] ?? 'common_phrase',
        (m['score'] as num?)?.toInt(),
        m['source'],
      ]);
    });
  } finally {
    stmt.dispose();
  }
}

int _streamInsert(
  Database db,
  File file,
  void Function(Map<String, dynamic>) consume,
) {
  if (!file.existsSync()) {
    stderr.writeln('Missing ${file.path}, skipping');
    return 0;
  }
  stdout.writeln('Importing ${file.path}...');
  final raw = file.readAsLinesSync();
  var inserted = 0;
  db.execute('BEGIN');
  try {
    for (var i = 0; i < raw.length; i++) {
      final line = raw[i].trim();
      if (line.isEmpty) continue;
      try {
        final m = json.decode(line) as Map<String, dynamic>;
        consume(m);
        inserted++;
      } catch (_) {
        // skip malformed
      }
      if (inserted > 0 && inserted % _chunkSize == 0) {
        db.execute('COMMIT');
        db.execute('BEGIN');
      }
    }
    db.execute('COMMIT');
  } catch (e) {
    db.execute('ROLLBACK');
    rethrow;
  }
  return inserted;
}
