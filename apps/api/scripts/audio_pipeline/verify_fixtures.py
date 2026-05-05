"""
Verify that the Python reference implementation matches the frozen fixture
values in tests/fixtures/.

This is the Python-side golden test. Dart and TypeScript ports run their
own equivalent tests (apps/mobile/test/util/stable_id_test.dart, etc.).
All three MUST pass with the SAME fixture file.

Run:
  python apps/api/scripts/audio_pipeline/verify_fixtures.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from reference import (  # noqa: E402
    canonical_json_bytes,
    compute_audio_id,
    compute_example_stable_id,
    normalize_text,
    normalize_word,
)

REPO_ROOT = HERE.parent.parent.parent.parent
FIXTURES_DIR = REPO_ROOT / "tests" / "fixtures"


# Tiny YAML reader — we only need to extract scalar values that match a
# known shape (key: value with optional escapes). Avoids PyYAML dep.
def _unquote_yaml(value: str) -> str:
    value = value.strip()
    if value.startswith('"') and value.endswith('"'):
        # Double-quoted: unescape \\, \", \t, \n, \r
        v = value[1:-1]
        v = v.replace(r"\\", "\x00")  # placeholder for literal backslash
        v = v.replace(r"\"", '"')
        v = v.replace(r"\t", "\t")
        v = v.replace(r"\n", "\n")
        v = v.replace(r"\r", "\r")
        v = v.replace("\x00", "\\")
        return v
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1].replace("''", "'")
    return value


def _read_blocks(path: Path) -> list[dict]:
    """Parse minimal YAML: list of `- name: ...` blocks under `cases:`."""
    if not path.exists():
        raise FileNotFoundError(path)
    text = path.read_text(encoding="utf-8")
    # Split into blocks at lines starting with `  - name:`
    blocks = []
    current: dict | None = None
    in_cases = False
    for line in text.splitlines():
        stripped = line.rstrip()
        if stripped.startswith("cases:"):
            in_cases = True
            continue
        if stripped and not stripped.startswith(" ") and in_cases:
            # Top-level key encountered → end of `cases:` block
            in_cases = False
        if not in_cases:
            continue
        m = re.match(r"^  - name: (.+)$", line)
        if m:
            if current is not None:
                blocks.append(current)
            current = {"name": _unquote_yaml(m.group(1))}
            continue
        m = re.match(r"^    (\w+): (.+)$", line)
        if m and current is not None:
            current[m.group(1)] = _unquote_yaml(m.group(2))
    if current is not None:
        blocks.append(current)
    return blocks


def verify_normalize_text() -> int:
    blocks = _read_blocks(FIXTURES_DIR / "normalize_text.yaml")
    fail = 0
    for b in blocks:
        actual = normalize_text(b["input"])
        if actual != b["output"]:
            print(
                f"  FAIL normalize_text [{b['name']}]: got {actual!r}, want {b['output']!r}"
            )
            fail += 1
    print(f"  normalize_text: {len(blocks) - fail}/{len(blocks)} pass")
    return fail


def verify_normalize_word() -> int:
    blocks = _read_blocks(FIXTURES_DIR / "normalize_word.yaml")
    fail = 0
    for b in blocks:
        actual = normalize_word(b["input"])
        if actual != b["output"]:
            print(
                f"  FAIL normalize_word [{b['name']}]: got {actual!r}, want {b['output']!r}"
            )
            fail += 1
    print(f"  normalize_word: {len(blocks) - fail}/{len(blocks)} pass")
    return fail


def verify_stable_id() -> int:
    blocks = _read_blocks(FIXTURES_DIR / "stable_id.yaml")
    fail = 0
    for b in blocks:
        # Skip the "diacritic_nfc_collision" case (uses en_nfd/en_nfc instead of en)
        if "en" not in b:
            continue
        actual = compute_example_stable_id(b["word_id"], b["en"])
        if actual != b["expected_stable_id"]:
            print(
                f"  FAIL stable_id [{b['name']}]: got {actual}, want {b['expected_stable_id']}"
            )
            fail += 1
    print(f"  stable_id: {sum(1 for b in blocks if 'en' in b) - fail}/"
          f"{sum(1 for b in blocks if 'en' in b)} pass")
    return fail


def verify_audio_id() -> int:
    blocks = _read_blocks(FIXTURES_DIR / "audio_id.yaml")
    fail = 0
    for b in blocks:
        actual = compute_audio_id(
            target_kind=b["target_kind"],
            target_id=b["target_id"],
            locale=b["locale"],
            voice=b["voice"],
            fmt=b["format"],
            audio_version=b["audio_version"],
        )
        if actual != b["expected_audio_id"]:
            print(
                f"  FAIL audio_id [{b['name']}]: got {actual}, want {b['expected_audio_id']}"
            )
            fail += 1
    print(f"  audio_id: {len(blocks) - fail}/{len(blocks)} pass")
    return fail


def verify_canonical_json() -> int:
    blocks = _read_blocks(FIXTURES_DIR / "canonical_json.yaml")
    fail = 0
    for b in blocks:
        # `input` is a flow array literal in YAML; we evaluate it carefully.
        raw = b["input"].strip()
        if not (raw.startswith("[") and raw.endswith("]")):
            continue
        # Use Python literal eval on the bracketed string after substituting
        # YAML single-quoted '' → \' for Python parsing.
        inner = raw[1:-1]
        # YAML: 'it''s' → Python "it's"
        # Manual split respecting single-quoted strings.
        items: list[str] = []
        i = 0
        while i < len(inner):
            ch = inner[i]
            if ch == " " or ch == ",":
                i += 1
                continue
            if ch == "'":
                # consume single-quoted string with '' as escaped quote
                j = i + 1
                buf = ""
                while j < len(inner):
                    if inner[j] == "'":
                        if j + 1 < len(inner) and inner[j + 1] == "'":
                            buf += "'"
                            j += 2
                            continue
                        break
                    buf += inner[j]
                    j += 1
                items.append(buf)
                i = j + 1
            else:
                # bare token (number)
                j = i
                while j < len(inner) and inner[j] not in " ,":
                    j += 1
                tok = inner[i:j]
                items.append(int(tok) if tok.lstrip("-").isdigit() else tok)
                i = j
        actual = canonical_json_bytes(items).hex()
        expected = b["expected_utf8_bytes_hex"]
        if actual != expected:
            print(f"  FAIL canonical_json [{b['name']}]:")
            print(f"      got  {actual}")
            print(f"      want {expected}")
            fail += 1
    print(f"  canonical_json: {len(blocks) - fail}/{len(blocks)} pass")
    return fail


def main() -> None:
    print(f"Verifying fixtures in {FIXTURES_DIR}")
    total_fail = 0
    total_fail += verify_canonical_json()
    total_fail += verify_normalize_text()
    total_fail += verify_normalize_word()
    total_fail += verify_stable_id()
    total_fail += verify_audio_id()
    if total_fail > 0:
        print(f"\n{total_fail} test(s) FAILED")
        sys.exit(1)
    print("\nAll fixtures pass.")


if __name__ == "__main__":
    main()
