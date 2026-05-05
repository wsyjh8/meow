"""
Generate `audio-pipeline-staging/words.json` — the authoritative list of
canonical word_ids needing TTS audio.

Reads the three wordbook asset files (book-001 / zk / gk), flattens their
`words[]` arrays, deduplicates by canonical `wordId`, and emits a single
JSON document consumed by:

  - The Codex audio pipeline (chooses what words to TTS next).
  - `partial_publish.py --kind=word` (matches WAV files → MP3 → audio_assets).

Output shape (mirrors `examples.json`'s `{items, total}` pattern):

  {
    "items": [
      {"word_id": "abandon", "word_text": "abandon", "books": ["book-001"]},
      {"word_id": "abandoned", "word_text": "abandoned", "books": ["book-001", "zk"]},
      ...
    ],
    "total": 5512,
    "generated_at": "2026-05-04T10:00:00Z"
  }

Notes
-----
- `word_id` is the canonical lowercase id; `word_text` is the raw spelling
  passed to TTS. For all current entries they're equal (assets already use
  canonical), but we keep both fields explicit so downstream consumers
  don't have to rediscover the contract.
- `books` is purely diagnostic — if you need to know which book a word
  came from, query `word_book_memberships` in PG, not this file.
- Words that appear in multiple books produce ONE row (deterministic union
  on `books`).

Usage
-----
  python apps/api/scripts/audio_pipeline/generate_words_json.py \
    [--assets-dir apps/mobile/assets/words] \
    [--out apps/api/audio-pipeline-staging/words.json]
"""

from __future__ import annotations

import argparse
import datetime
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from reference import normalize_word  # noqa: E402


def collect_words(assets_dir: Path) -> dict[str, dict]:
    """Read book-001 / zk / gk wordbook JSONs → dict keyed by canonical word_id.

    Each value: `{word_id, word_text, books}`. `books` is the sorted list of
    asset slugs that mention the word.
    """
    by_id: dict[str, dict] = {}
    for slug in ("book-001", "zk", "gk"):
        asset_file = assets_dir / f"{slug}.json"
        if not asset_file.exists():
            print(f"  [warn] missing asset file: {asset_file}", file=sys.stderr)
            continue
        data = json.loads(asset_file.read_text(encoding="utf-8"))
        for word in data.get("words", []):
            raw_text = word.get("wordText") or word.get("wordId") or ""
            canonical = normalize_word(raw_text)
            if not canonical:
                continue
            entry = by_id.setdefault(
                canonical,
                {"word_id": canonical, "word_text": raw_text, "books": []},
            )
            if slug not in entry["books"]:
                entry["books"].append(slug)
    # Sort books inside each entry for stable output.
    for entry in by_id.values():
        entry["books"].sort()
    return by_id


def main() -> None:
    repo_root = HERE.parent.parent.parent.parent

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--assets-dir",
        type=Path,
        default=repo_root / "apps" / "mobile" / "assets" / "words",
        help="Wordbook assets directory (book-001.json, zk.json, gk.json).",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=repo_root / "apps" / "api" / "audio-pipeline-staging" / "words.json",
        help="Output path for words.json.",
    )
    args = parser.parse_args()

    if not args.assets_dir.exists():
        print(f"Assets dir not found: {args.assets_dir}", file=sys.stderr)
        sys.exit(1)
    args.out.parent.mkdir(parents=True, exist_ok=True)

    print(f"Loading wordbook assets from {args.assets_dir}...")
    by_id = collect_words(args.assets_dir)

    items = sorted(by_id.values(), key=lambda r: r["word_id"])
    payload = {
        "items": items,
        "total": len(items),
        "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        ),
    }
    args.out.write_text(
        json.dumps(payload, ensure_ascii=False),
        encoding="utf-8",
    )

    print(f"  {len(items)} unique canonical word_ids")
    print(f"  wrote {args.out}")

    # Cross-book overlap stats — informational only.
    in_multiple = sum(1 for e in items if len(e["books"]) > 1)
    print(f"  {in_multiple} words appear in multiple books")


if __name__ == "__main__":
    main()
