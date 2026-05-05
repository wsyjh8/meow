/// Cross-language byte-identity tests for the Dart stable_id reference impl.
///
/// Loads `tests/fixtures/*.yaml` (the SAME files Python's verify_fixtures.py
/// loads) and asserts every Dart output matches the frozen golden value.
///
/// **If this test fails, do NOT update the fixtures to match Dart.**
/// Either the Python reference is the source of truth, or there's a real bug
/// in the Dart impl. Investigate the impl first.
///
/// Run: `flutter test test/util/stable_id_test.dart`

import 'dart:convert' show utf8;
import 'dart:io' show File;

import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/util/stable_id.dart';

// Path from test cwd (apps/mobile) up to repo root + fixtures dir.
const String _fixturesRel = '../../tests/fixtures';

void main() {
  group('canonical_json byte-identity', () {
    final cases = _readCases('$_fixturesRel/canonical_json.yaml');

    for (final c in cases) {
      test('case: ${c['name']}', () {
        final input = _parseYamlFlowArray(c['input']!);
        final actual = canonicalJsonBytes(input);
        final actualHex =
            actual.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        expect(actualHex, equals(c['expected_utf8_bytes_hex']),
            reason: 'canonical_json [${c['name']}] mismatch');
      });
    }
  });

  group('normalize_text', () {
    final cases = _readCases('$_fixturesRel/normalize_text.yaml');
    for (final c in cases) {
      test('case: ${c['name']}', () {
        final actual = normalizeText(c['input']!);
        expect(actual, equals(c['output']),
            reason: 'normalize_text [${c['name']}] mismatch');
      });
    }
  });

  group('normalize_word', () {
    final cases = _readCases('$_fixturesRel/normalize_word.yaml');
    for (final c in cases) {
      test('case: ${c['name']}', () {
        final actual = normalizeWord(c['input']!);
        expect(actual, equals(c['output']),
            reason: 'normalize_word [${c['name']}] mismatch');
      });
    }
  });

  group('stable_id', () {
    final cases = _readCases('$_fixturesRel/stable_id.yaml');
    for (final c in cases) {
      // Skip the diacritic_nfc_collision case (uses en_nfd/en_nfc instead of en).
      if (!c.containsKey('en')) continue;
      test('case: ${c['name']}', () {
        final actual = computeExampleStableId(c['word_id']!, c['en']!);
        expect(actual, equals(c['expected_stable_id']),
            reason: 'stable_id [${c['name']}] mismatch');
      });
    }
  });

  group('audio_id', () {
    final cases = _readCases('$_fixturesRel/audio_id.yaml');
    for (final c in cases) {
      test('case: ${c['name']}', () {
        final actual = computeAudioId(
          targetKind: c['target_kind']!,
          targetId: c['target_id']!,
          locale: c['locale']!,
          voice: c['voice']!,
          format: c['format']!,
          audioVersion: c['audio_version']!,
        );
        expect(actual, equals(c['expected_audio_id']),
            reason: 'audio_id [${c['name']}] mismatch');
      });
    }
  });
}

/// Minimal YAML reader for our specific fixture shape (avoids adding a
/// `yaml` package dep just for tests). Parses `cases:` block of:
/// ```
/// cases:
///   - name: foo
///     key1: "value"
///     key2: "value"
/// ```
List<Map<String, String>> _readCases(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw 'Fixture not found: ${file.absolute.path}';
  }
  final lines = file.readAsStringSync().split('\n');
  final result = <Map<String, String>>[];
  Map<String, String>? current;
  var inCases = false;
  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.startsWith('cases:')) {
      inCases = true;
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ') && inCases) {
      // Top-level key (e.g. negative_cases:, edge_cases:) ends the block.
      inCases = false;
      if (current != null) result.add(current);
      current = null;
    }
    if (!inCases) continue;
    final nameMatch = RegExp(r'^  - name: (.+)$').firstMatch(line);
    if (nameMatch != null) {
      if (current != null) result.add(current);
      current = {'name': _unquote(nameMatch.group(1)!)};
      continue;
    }
    final kvMatch = RegExp(r'^    (\w+): (.+)$').firstMatch(line);
    if (kvMatch != null && current != null) {
      current[kvMatch.group(1)!] = _unquote(kvMatch.group(2)!);
    }
  }
  if (current != null) result.add(current);
  return result;
}

String _unquote(String v) {
  v = v.trim();
  if (v.startsWith('"') && v.endsWith('"')) {
    var inner = v.substring(1, v.length - 1);
    // Reverse the escape sequence used by fill_fixtures.py.
    inner = inner.replaceAll(r'\\', '\x00');
    inner = inner.replaceAll(r'\"', '"');
    inner = inner.replaceAll(r'\t', '\t');
    inner = inner.replaceAll(r'\n', '\n');
    inner = inner.replaceAll(r'\r', '\r');
    inner = inner.replaceAll('\x00', r'\');
    return inner;
  }
  if (v.startsWith("'") && v.endsWith("'")) {
    return v.substring(1, v.length - 1).replaceAll("''", "'");
  }
  return v;
}

/// Parse a YAML flow-style array of single-quoted strings or bare numbers,
/// e.g. `['abandon', 'He had to abandon his car.']`.
List<dynamic> _parseYamlFlowArray(String s) {
  s = s.trim();
  if (!s.startsWith('[') || !s.endsWith(']')) {
    throw 'Not a flow array: $s';
  }
  final inner = s.substring(1, s.length - 1);
  final items = <dynamic>[];
  var i = 0;
  while (i < inner.length) {
    final ch = inner[i];
    if (ch == ' ' || ch == ',') {
      i++;
      continue;
    }
    if (ch == "'") {
      final buf = StringBuffer();
      var j = i + 1;
      while (j < inner.length) {
        if (inner[j] == "'") {
          if (j + 1 < inner.length && inner[j + 1] == "'") {
            buf.write("'");
            j += 2;
            continue;
          }
          break;
        }
        buf.write(inner[j]);
        j++;
      }
      items.add(buf.toString());
      i = j + 1;
    } else {
      var j = i;
      while (j < inner.length && inner[j] != ' ' && inner[j] != ',') {
        j++;
      }
      final tok = inner.substring(i, j);
      items.add(int.tryParse(tok) ?? tok);
      i = j;
    }
  }
  return items;
}
