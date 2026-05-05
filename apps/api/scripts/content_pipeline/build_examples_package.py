"""
build-examples-package implementation (v0.3 PR-A Day 2).

Pipeline:

  apps/mobile/assets/words/{book}.json   ── word→book mapping (canonical SSOT)
       ↓ (extract list of word_ids)
  PG examples WHERE word_id IN (...) AND status='active'
       ↓ (compute content_hash per row)
  {out_dir}/examples-{book}.jsonl.gz     ── distributable package
       (optional) PG UPDATE examples.content_hash for changed rows

Why source word_id list comes from JSON, not word_book_memberships:
  Current dev DB only has 29 rows in word_book_memberships (dev-seed scope),
  but bundled JSON assets carry the full ~5361 word list. The semantic SSOT
  for "what words are in book X" is the asset JSON; word_book_memberships
  is the eventual cloud mirror that will catch up via a separate dev-seed
  enhancement (out of scope for PR-A).

This pattern also future-proofs PR-B: when examples themselves move to
CDN packages, the build's input becomes "source content" — same contract.
"""
from __future__ import annotations

import gzip
import hashlib
import json
import os
import sys
from pathlib import Path

import psycopg2

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "audio_pipeline"))

from reference import compute_example_content_hash  # noqa: E402


def _load_word_ids_from_asset(assets_dir: Path, book_slug: str) -> dict[str, int]:
    """Read {book_slug}.json → {word_id: sort_order} mapping."""
    asset_file = assets_dir / f"{book_slug}.json"
    if not asset_file.exists():
        raise FileNotFoundError(f"Wordbook asset not found: {asset_file}")
    data = json.loads(asset_file.read_text(encoding="utf-8"))
    word_to_sort: dict[str, int] = {}
    for w in data.get("words", []):
        word_id = w.get("wordId")
        sort_order = int(w.get("sortOrder", 0))
        if word_id:
            word_to_sort[word_id] = sort_order
    return word_to_sort


def file_sha256(path: Path) -> str:
    """SHA-256 hex of file content. Used by Day 3 publish-manifest too.

    Renamed from `_file_sha256` to public API in PR-A Day 3 — pipeline.py
    publish-manifest reuses this for manifest.checksum_sha256.
    """
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


# Backward-compat alias (in case any external code referenced the underscored name)
_file_sha256 = file_sha256


def run(book_slug: str, out_dir: str, update_pg: bool, assets_dir: str) -> int:
    """
    Returns process exit code (0 success, non-zero failure).
    """
    db_url = os.environ.get("DATABASE_URL")
    if not db_url:
        print("ERROR: DATABASE_URL not set", file=sys.stderr)
        return 2

    # ── Step 1: word_ids + sort_order from JSON asset ────────────────────────
    assets_path = Path(assets_dir).resolve()
    print(f"Loading word_ids from {assets_path / (book_slug + '.json')} ...")
    word_to_sort = _load_word_ids_from_asset(assets_path, book_slug)
    print(f"  {len(word_to_sort)} word_ids in book '{book_slug}'")

    if not word_to_sort:
        print(f"ERROR: empty word list for book '{book_slug}'", file=sys.stderr)
        return 3

    # ── Step 2: fetch examples from PG + compute new content_hash ────────────
    conn = psycopg2.connect(db_url)
    try:
        rows: list[dict] = []
        word_ids = list(word_to_sort.keys())
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT stable_id, word_id, sense_label, en, cn,
                       difficulty, ordinal, status,
                       content_hash AS old_content_hash
                FROM examples
                WHERE word_id = ANY(%s) AND status = 'active'
                ORDER BY word_id, ordinal, stable_id
                """,
                (word_ids,),
            )
            cols = [d.name for d in cur.description]
            for row in cur.fetchall():
                r = dict(zip(cols, row))
                new_hash = compute_example_content_hash(
                    stable_id=r["stable_id"],
                    word_id=r["word_id"],
                    sense_label=r["sense_label"],
                    en=r["en"],
                    cn=r["cn"],
                    difficulty=r["difficulty"],
                    ordinal=r["ordinal"],
                    status=r["status"],
                )
                old_hash = r.pop("old_content_hash")
                r["content_hash"] = new_hash
                r["_changed"] = old_hash != new_hash
                # Sort key: book-level word position, then word's intra-ordinal
                r["_book_sort"] = word_to_sort.get(r["word_id"], 1 << 30)
                rows.append(r)

        # Sort: book sortOrder → ordinal → stable_id (deterministic)
        rows.sort(key=lambda r: (r["_book_sort"], r["ordinal"], r["stable_id"]))
        print(f"  fetched {len(rows)} active examples from PG")

        if not rows:
            print(
                "  WARN: 0 active examples matched; "
                "check whether PG examples table is populated for these word_ids",
                file=sys.stderr,
            )

        # ── Step 3: write jsonl.gz ────────────────────────────────────────────
        out_path = Path(out_dir) / f"examples-{book_slug}.jsonl.gz"
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with gzip.open(out_path, "wt", encoding="utf-8", compresslevel=6) as f:
            for r in rows:
                payload = {
                    "stable_id": r["stable_id"],
                    "word_id": r["word_id"],
                    "sense_label": r["sense_label"],
                    "en": r["en"],
                    "cn": r["cn"],
                    "difficulty": r["difficulty"],
                    "ordinal": r["ordinal"],
                    "status": r["status"],
                    "content_hash": r["content_hash"],
                }
                f.write(
                    json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
                    + "\n"
                )

        size_bytes = out_path.stat().st_size
        sha256 = file_sha256(out_path)
        print(f"  wrote {out_path}")
        print(f"  rows={len(rows)} bytes={size_bytes:,} sha256={sha256}")

        # ── Step 4: PG content_hash backfill (optional) ──────────────────────
        if update_pg:
            changed = [r for r in rows if r["_changed"]]
            if changed:
                with conn.cursor() as cur:
                    cur.executemany(
                        "UPDATE examples SET content_hash = %s WHERE stable_id = %s",
                        [(r["content_hash"], r["stable_id"]) for r in changed],
                    )
                conn.commit()
                print(f"  updated {len(changed)} content_hash values in PG")
            else:
                print("  no PG updates (all content_hash already current)")

        return 0
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
