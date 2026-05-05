/// Stable ID reference implementation (Dart).
///
/// SSOT: docs/design/DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md §3.4
/// Contract: docs/design/audio_contract.yaml
///
/// **Critical:** This implementation MUST produce byte-identical output to:
///   - Python reference (apps/api/scripts/audio_pipeline/reference.py)
///   - TypeScript reference (apps/api/src/lib/stable-id.ts)
///
/// Verified by golden tests in `test/util/stable_id_test.dart` against the
/// shared fixtures in `tests/fixtures/`.
///
/// **Where this is used:**
///   - WordbookLoader: at import time (one-time per content_version), to
///     verify that `assets/words/*.json` ships with correct stable_id, OR
///     to compute it as fallback if the asset hasn't been re-exported yet.
///   - **Never at runtime** — DB §3.5 forbids App from computing hashes
///     during normal operation; that's the whole point of the contract.

import 'dart:convert' show utf8;

import 'package:crypto/crypto.dart' show sha256;
import 'package:unorm_dart/unorm_dart.dart' as unorm;

// ============================================================================
// Normalization (per DB §3.2)
// ============================================================================

/// Trailing whitespace + tab + newline + CR collapse to single ASCII space.
final RegExp _whitespaceRun = RegExp(r'\s+');

/// `normalize_word(s)` — used to derive `words.id` from raw word_text.
///
/// Algorithm (DB §3.2.1):
///   1. NFC unicode normalization
///   2. trim() leading/trailing whitespace
///   3. lowercase()
///   4. Collapse internal whitespace to single ASCII space
///   5. Preserve hyphens, apostrophes, diacritics
String normalizeWord(String s) {
  return unorm
      .nfc(s)
      .trim()
      .toLowerCase()
      .replaceAll(_whitespaceRun, ' ');
}

/// `normalize_text(s)` — used for example sentences before hashing.
///
/// Algorithm (DB §3.2.2):
///   1. NFC unicode normalization
///   2. trim()
///   3. Collapse all whitespace to single ASCII space
///   4. Preserve case
///   5. Preserve [bracket] highlight markers
String normalizeText(String s) {
  return unorm.nfc(s).trim().replaceAll(_whitespaceRun, ' ');
}

// ============================================================================
// Canonical JSON (per DB §3.4.1)
// ============================================================================

/// Serialize a flat array to byte-identical canonical JSON for hashing.
///
/// Strict rules (audio_contract.yaml §hash):
///   - separators: (",", ":") — compact, no whitespace
///   - ensure_ascii: false — non-ASCII NOT escaped
///   - no null in array
///   - no nested structures
///
/// **Why not `dart:convert`'s `jsonEncode`?**
/// Dart's `jsonEncode` produces compact output by default (no whitespace),
/// AND it does NOT escape non-ASCII (matches Python's ensure_ascii=False).
/// So the standard library actually IS canonical for our input shape, which
/// is great. We delegate but enforce the strict-input contract here.
List<int> canonicalJsonBytes(List<dynamic> arr) {
  for (final v in arr) {
    if (v == null) {
      throw ArgumentError('canonical JSON array must not contain null');
    }
    if (v is List || v is Map) {
      throw ArgumentError(
          'canonical JSON array must not contain nested structures');
    }
    if (v is! String && v is! int) {
      throw ArgumentError(
          'canonical JSON array element must be String or int, got ${v.runtimeType}');
    }
  }
  // Manual encoder mirrors Python's json.dumps(arr, ensure_ascii=False,
  // separators=(',', ':')) byte-for-byte. We bypass dart:convert because:
  //   1. We only support flat array of String|int
  //   2. We need precise control over escape semantics
  //
  // String escaping: matches RFC 8259 minimal escapes that Python's json
  // module also uses (\", \\, \b, \f, \n, \r, \t, \uXXXX for control chars).
  final buf = StringBuffer('[');
  for (var i = 0; i < arr.length; i++) {
    if (i > 0) buf.write(',');
    final v = arr[i];
    if (v is String) {
      buf.write('"');
      _appendJsonStringEscaped(buf, v);
      buf.write('"');
    } else if (v is int) {
      buf.write(v.toString());
    }
  }
  buf.write(']');
  return utf8.encode(buf.toString());
}

void _appendJsonStringEscaped(StringBuffer buf, String s) {
  for (final codeUnit in s.runes) {
    switch (codeUnit) {
      case 0x22: // "
        buf.write(r'\"');
        break;
      case 0x5C: // \
        buf.write(r'\\');
        break;
      case 0x08:
        buf.write(r'\b');
        break;
      case 0x09:
        buf.write(r'\t');
        break;
      case 0x0A:
        buf.write(r'\n');
        break;
      case 0x0C:
        buf.write(r'\f');
        break;
      case 0x0D:
        buf.write(r'\r');
        break;
      default:
        if (codeUnit < 0x20) {
          // Other control char → \uXXXX
          buf.write('\\u');
          buf.write(codeUnit.toRadixString(16).padLeft(4, '0'));
        } else {
          // All printable + non-ASCII → emit raw (ensure_ascii=False)
          buf.writeCharCode(codeUnit);
        }
    }
  }
}

// ============================================================================
// SHA-256 truncation (per DB §3.4.2)
// ============================================================================

/// SHA-256 hex digest, truncated to 24 lowercase hex chars (96-bit output).
String sha256Hex24(List<int> data) {
  return sha256.convert(data).toString().substring(0, 24);
}

/// SHA-256 hex digest, truncated to 16 lowercase hex chars (64-bit output).
String sha256Hex16(List<int> data) {
  return sha256.convert(data).toString().substring(0, 16);
}

// ============================================================================
// Stable ID computation (per DB §3.1)
// ============================================================================

/// Compute `examples.stable_id` from word_id and raw English sentence.
///
/// Formula:
///   stable_id = sha256_24(canonical_json([word_id, normalize_text(en)]))
///
/// `wordId` should already be normalized; this function does NOT re-normalize.
String computeExampleStableId(String wordId, String rawEn) {
  return sha256Hex24(canonicalJsonBytes([wordId, normalizeText(rawEn)]));
}

/// Compute `audio_assets.id` from the 6-tuple identifying a unique audio binary.
String computeAudioId({
  required String targetKind, // 'word' | 'example'
  required String targetId,
  required String locale,
  required String voice,
  required String format, // 'mp3' | 'opus'
  required String audioVersion,
}) {
  return sha256Hex24(canonicalJsonBytes([
    targetKind,
    targetId,
    locale,
    voice,
    format,
    audioVersion,
  ]));
}
