"""
Fill PLACEHOLDER values in tests/fixtures/*.yaml using the Python reference
implementation.

Run:
  python apps/api/scripts/audio_pipeline/fill_fixtures.py

Output: rewrites these files in place (idempotent — running again yields no diff):
  tests/fixtures/canonical_json.yaml
  tests/fixtures/normalize_text.yaml
  tests/fixtures/normalize_word.yaml
  tests/fixtures/stable_id.yaml
  tests/fixtures/audio_id.yaml

After this script runs, the fixtures hold the FROZEN golden truth — TS and
Dart ports must produce byte-identical results to pass their golden tests.

Note: this uses Python's `yaml` package via a manual pretty-emitter to avoid
adding PyYAML as a hard dep. We literally rewrite each fixture file by string
substitution on PLACEHOLDER tokens.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# Make the reference module importable when run from any cwd
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from reference import (  # noqa: E402
    canonical_json_bytes,
    compute_audio_id,
    compute_example_stable_id,
    normalize_text,
    normalize_word,
    sha256_16,
    sha256_24,
)

REPO_ROOT = HERE.parent.parent.parent.parent  # …/<worktree>
FIXTURES_DIR = REPO_ROOT / "tests" / "fixtures"


# =============================================================================
# Helpers
# =============================================================================


def _to_hex_bytes(b: bytes) -> str:
    return b.hex()


# =============================================================================
# canonical_json fixture
# =============================================================================

CANONICAL_JSON_CASES = [
    # (name, input_array)
    ("simple_two_string", ["abandon", "He had to abandon his car."]),
    ("with_chinese_content", ["放弃", "中文测试句"]),
    ("with_brackets", ["abandon", "[abandon] his plans"]),
    ("with_apostrophe", ["it's", "it's a test"]),
    ("with_diacritic_nfc", ["naïve", "she is naïve"]),
    ("audio_id_input_word", ["word", "abandon", "en-US", "af_bella", "mp3", "v1"]),
    (
        "audio_id_input_example",
        [
            "example",
            "a3f9c1e4b8d720568f12c4d7",
            "en-US",
            "af_bella",
            "mp3",
            "v1",
        ],
    ),
]


def write_canonical_json_fixture() -> None:
    out = FIXTURES_DIR / "canonical_json.yaml"
    lines = [
        "# canonical_json golden fixtures",
        "# Auto-filled by apps/api/scripts/audio_pipeline/fill_fixtures.py",
        "# Verifies cross-language byte-identical JSON serialization",
        "# per audio_contract.yaml §hash.",
        "#",
        "# Each port (Python / Dart / TypeScript) must produce the SAME",
        "# `expected_utf8_bytes_hex`. Frozen reference: Python `json.dumps` with",
        "# ensure_ascii=False, separators=(',',':').",
        "",
        "cases:",
    ]
    for name, arr in CANONICAL_JSON_CASES:
        b = canonical_json_bytes(arr)
        # Format the input as a YAML flow sequence with quoted strings.
        items = ", ".join(_yaml_quote(x) for x in arr)
        lines.append(f"  - name: {name}")
        lines.append(f"    input: [{items}]")
        lines.append(f"    expected_utf8_bytes_hex: {_to_hex_bytes(b)!r}")

    lines.append("")
    lines.append("# Negative cases (must throw / reject)")
    lines.append("negative_cases:")
    lines.append("  - name: reject_null_in_array")
    lines.append('    input: ["word", null, "en-US"]')
    lines.append('    expected_error: "no_null_in_array"')
    lines.append("  - name: reject_nested_structure")
    lines.append('    input: ["word", ["nested"]]')
    lines.append('    expected_error: "no_nested_structures"')
    lines.append("  - name: reject_non_string_non_int")
    lines.append('    input: ["word", 1.5]')
    lines.append('    expected_error: "type_not_allowed"')
    lines.append("")
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"  wrote {out.name} ({len(CANONICAL_JSON_CASES)} cases)")


def _yaml_quote(v) -> str:
    if isinstance(v, str):
        # Single-quoted YAML scalar; escape internal single quotes by doubling.
        escaped = v.replace("'", "''")
        return f"'{escaped}'"
    return str(v)


# =============================================================================
# normalize_text fixture (no compute needed — values are written by hand;
# we only verify the reference impl matches the documented expected output).
# =============================================================================

NORMALIZE_TEXT_CASES = [
    ("simple", "He had to abandon his car.", "He had to abandon his car."),
    ("leading_trailing_whitespace", "  He had to abandon his car.  ", "He had to abandon his car."),
    ("tab_newline_collapse", "He\thad\nto\rabandon.", "He had to abandon."),
    ("multiple_spaces_collapse", "He    had   to    abandon.", "He had to abandon."),
    ("case_preserved", "ABANDON, said the captain.", "ABANDON, said the captain."),
    ("brackets_preserved", "[abandon] his plans", "[abandon] his plans"),
    ("apostrophe_preserved", "it's a tough decision.", "it's a tough decision."),
    ("hyphen_preserved", "It is a fire-proof building.", "It is a fire-proof building."),
    # NFD source (decomposed) → NFC (composed). Both should produce same output bytes.
    ("diacritic_nfc_normalized", "she is naïve", "she is naïve"),
    ("chinese_punctuation_preserved", "他不得不放弃他的车。", "他不得不放弃他的车。"),
    ("emoji_preserved", "I love it 😊", "I love it 😊"),
    ("unicode_quote_preserved", '"abandon" he said.', '"abandon" he said.'),
    ("non_breaking_space_collapsed", "He had to abandon his car.", "He had to abandon his car."),
]


def write_normalize_text_fixture() -> None:
    out = FIXTURES_DIR / "normalize_text.yaml"
    # Verify each case actually matches (catch regressions in reference)
    for name, inp, expected in NORMALIZE_TEXT_CASES:
        actual = normalize_text(inp)
        assert actual == expected, (
            f"normalize_text({inp!r}) = {actual!r}, expected {expected!r}"
        )

    lines = [
        "# normalize_text golden fixtures",
        "# Auto-filled by apps/api/scripts/audio_pipeline/fill_fixtures.py",
        "# Per DB_TARGET_ARCHITECTURE_v0.3.0 §3.2.2.",
        "",
        "cases:",
    ]
    for name, inp, expected in NORMALIZE_TEXT_CASES:
        lines.append(f"  - name: {name}")
        lines.append(f"    input: {_yaml_quote_double(inp)}")
        lines.append(f"    output: {_yaml_quote_double(expected)}")

    lines.append("")
    lines.append("edge_cases:")
    lines.append("  - name: only_whitespace")
    lines.append('    input: "   \\t\\n\\r  "')
    lines.append('    output: ""')
    lines.append("  - name: empty")
    lines.append('    input: ""')
    lines.append('    output: ""')
    lines.append("")
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"  wrote {out.name} ({len(NORMALIZE_TEXT_CASES)} cases)")


def _yaml_quote_double(v: str) -> str:
    """Double-quote scalar with proper YAML escaping for non-printable bytes."""
    # Escape backslashes first, then quotes, then control chars.
    out = (
        v.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\t", "\\t")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
    )
    return f'"{out}"'


# =============================================================================
# normalize_word fixture
# =============================================================================

NORMALIZE_WORD_CASES = [
    ("simple", "abandon", "abandon"),
    ("trailing_space", "abandon  ", "abandon"),
    ("csv_newline", "abandon\r\n", "abandon"),
    ("lowercase_folded", "Abandon", "abandon"),
    ("all_caps", "ABANDON", "abandon"),
    ("hyphen_preserved", "fire-proof", "fire-proof"),
    ("apostrophe_preserved", "it's", "it's"),
    ("diacritic_preserved_nfc", "naïve", "naïve"),
    ("us_uk_distinct", "colour", "colour"),
    ("capital_proper_noun", "Polish", "polish"),
    ("leading_uppercase_diacritic", "Übergang", "übergang"),
]


def write_normalize_word_fixture() -> None:
    out = FIXTURES_DIR / "normalize_word.yaml"
    for name, inp, expected in NORMALIZE_WORD_CASES:
        actual = normalize_word(inp)
        assert actual == expected, (
            f"normalize_word({inp!r}) = {actual!r}, expected {expected!r}"
        )

    lines = [
        "# normalize_word golden fixtures",
        "# Auto-filled by apps/api/scripts/audio_pipeline/fill_fixtures.py",
        "# Per DB_TARGET_ARCHITECTURE_v0.3.0 §3.2.1.",
        "",
        "cases:",
    ]
    for name, inp, expected in NORMALIZE_WORD_CASES:
        lines.append(f"  - name: {name}")
        lines.append(f"    input: {_yaml_quote_double(inp)}")
        lines.append(f"    output: {_yaml_quote_double(expected)}")
    lines.append("")
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"  wrote {out.name} ({len(NORMALIZE_WORD_CASES)} cases)")


# =============================================================================
# stable_id fixture
# =============================================================================

STABLE_ID_CASES = [
    # (name, word_id, en)
    # NOTE: word_id here is the v0.3.0 *canonical* form (lowercase normalized),
    # NOT a book-prefixed v0.2.x form. The same `abandon` belongs to CET-4,
    # CET-6, ZK, GK simultaneously via word_book_memberships — there is no
    # such thing as "cet4-abandon" in v0.3.0.
    ("abandon_basic", "abandon", "He had to abandon his car in the snow."),
    ("abandon_with_brackets", "abandon", "[abandon] his plans"),
    (
        "leading_whitespace_irrelevant",
        "abandon",
        "  He had to abandon his car in the snow.  ",
    ),
    (
        "tab_in_middle_irrelevant",
        "abandon",
        "He\thad\nto abandon his car in the snow.",
    ),
    (
        "case_change_produces_different_id",
        "abandon",
        "He had to ABANDON his car in the snow.",
    ),
    ("chinese_word_with_chinese_text", "放弃", "他不得不放弃他的车。"),
]


def write_stable_id_fixture() -> None:
    out = FIXTURES_DIR / "stable_id.yaml"
    lines = [
        "# stable_id golden fixtures",
        "# Auto-filled by apps/api/scripts/audio_pipeline/fill_fixtures.py",
        "# Formula: sha256(canonical_json([word_id, normalize_text(en)])).hexdigest()[:24]",
        "",
        "cases:",
    ]
    for name, word_id, en in STABLE_ID_CASES:
        sid = compute_example_stable_id(word_id, en)
        lines.append(f"  - name: {name}")
        lines.append(f"    word_id: {_yaml_quote_double(word_id)}")
        lines.append(f"    en: {_yaml_quote_double(en)}")
        lines.append(f"    expected_stable_id: {sid!r}")

    # Diacritic NFD ↔ NFC equivalence: same logical text → same stable_id.
    nfd_en = "she is naïve"
    nfc_en = "she is naïve"
    sid_nfd = compute_example_stable_id("abandon", nfd_en)
    sid_nfc = compute_example_stable_id("abandon", nfc_en)
    assert sid_nfd == sid_nfc, "NFD vs NFC must produce same stable_id"
    lines.append("  - name: diacritic_nfc_collision")
    lines.append('    word_id: "abandon"')
    lines.append(f"    en_nfd: {_yaml_quote_double(nfd_en)}")
    lines.append(f"    en_nfc: {_yaml_quote_double(nfc_en)}")
    lines.append(f"    expected_stable_id_both: {sid_nfd!r}")
    lines.append("")
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"  wrote {out.name} ({len(STABLE_ID_CASES) + 1} cases)")


# =============================================================================
# audio_id fixture
# =============================================================================

AUDIO_ID_CASES = [
    (
        "word_abandon_us_female_v1",
        dict(target_kind="word", target_id="abandon", locale="en-US",
             voice="af_bella", fmt="mp3", audio_version="v1"),
    ),
    (
        "word_abandon_us_female_v2_differs_from_v1",
        dict(target_kind="word", target_id="abandon", locale="en-US",
             voice="af_bella", fmt="mp3", audio_version="v2"),
    ),
    (
        "word_abandon_uk_male_v1",
        dict(target_kind="word", target_id="abandon", locale="en-GB",
             voice="bm_george", fmt="mp3", audio_version="v1"),
    ),
    (
        "example_basic",
        dict(target_kind="example", target_id="a3f9c1e4b8d720568f12c4d7",
             locale="en-US", voice="af_bella", fmt="mp3", audio_version="v1"),
    ),
    (
        "example_format_change",
        dict(target_kind="example", target_id="a3f9c1e4b8d720568f12c4d7",
             locale="en-US", voice="af_bella", fmt="opus", audio_version="v1"),
    ),
]


def write_audio_id_fixture() -> None:
    out = FIXTURES_DIR / "audio_id.yaml"
    lines = [
        "# audio_id golden fixtures",
        "# Auto-filled by apps/api/scripts/audio_pipeline/fill_fixtures.py",
        "# Formula:",
        "#   sha256(canonical_json([target_kind, target_id, locale, voice,",
        "#                          format, audio_version])).hexdigest()[:24]",
        "",
        "cases:",
    ]
    for name, params in AUDIO_ID_CASES:
        aid = compute_audio_id(**params)
        lines.append(f"  - name: {name}")
        lines.append(f"    target_kind: {_yaml_quote_double(params['target_kind'])}")
        lines.append(f"    target_id: {_yaml_quote_double(params['target_id'])}")
        lines.append(f"    locale: {_yaml_quote_double(params['locale'])}")
        lines.append(f"    voice: {_yaml_quote_double(params['voice'])}")
        lines.append(f"    format: {_yaml_quote_double(params['fmt'])}")
        lines.append(
            f"    audio_version: {_yaml_quote_double(params['audio_version'])}"
        )
        lines.append(f"    expected_audio_id: {aid!r}")
    lines.append("")
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"  wrote {out.name} ({len(AUDIO_ID_CASES)} cases)")


# =============================================================================
# Main
# =============================================================================


def main() -> None:
    if not FIXTURES_DIR.exists():
        FIXTURES_DIR.mkdir(parents=True)
    print(f"Filling fixtures in {FIXTURES_DIR}")
    write_canonical_json_fixture()
    write_normalize_text_fixture()
    write_normalize_word_fixture()
    write_stable_id_fixture()
    write_audio_id_fixture()
    print("Done.")


if __name__ == "__main__":
    main()
