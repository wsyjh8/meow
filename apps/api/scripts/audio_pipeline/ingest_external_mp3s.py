"""
Ingest pre-organized MP3 files (e.g. produced by an external pipeline that
already did WAV→MP3 conversion) into the mock CDN + audio_assets.jsonl,
skipping the ffmpeg stage of partial_publish.py.

Use case (P2.1 mid-flight, 2026-05-04): Codex audio pipeline produced
~9221 MP3s laid out in `mp3/example/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3`
on the host machine. We need to:

  1. Cross-check each MP3's audio_id against the audio_ids derivable from
     the current wordbook assets (Codex content may be stale relative to
     post-edit wordbook state — only matching pairs become audio_assets).
  2. For each match, copy the MP3 into the mock CDN tree at the canonical
     path, ffprobe duration, sha256 the file, and emit an audio_assets.jsonl
     row ready for ingest-audio-assets.ts.

Stale MP3s (audio_id not in current expected set) are left alone in the
source dir — not copied to cdn-mock, not in jsonl. Wordbook examples with
no corresponding MP3 produce no row (App grays out play button per DB §11).

Inputs
------
  --source-dir    Recursive root of pre-organized MP3 files. Files must be
                  named `{audio_id}.mp3`. Directory structure inside is
                  ignored (we walk recursively); only the filename's stem
                  is consulted.
  --assets-dir    Wordbook asset dir (default apps/mobile/assets/words).
  --cdn-mock-dir  Mock CDN root (default apps/api/cdn-mock).
  --staging-dir   Output dir for audio_assets.jsonl (default
                  apps/api/audio-pipeline-staging).
  --workers       Parallel ffprobe + sha256 workers (default 4).

Output
------
  <staging>/audio_assets.jsonl   — only entries with matched audio_ids
  <cdn-mock>/audio/v1/examples/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3
                                  (one MP3 per matched audio_id)

Next step (run from apps/api/):
  npx ts-node scripts/ingest-audio-assets.ts \\
    --examples-json ../audio-pipeline-staging/examples.json \\
    --audio-jsonl   ../audio-pipeline-staging/audio_assets.jsonl

(Run partial_publish.py first if examples.json is stale — this script
does NOT regenerate examples.json.)
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import shutil
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from partial_publish import (  # noqa: E402  (reuse helpers)
    AUDIO_VERSION,
    ACCENT,
    FORMAT,
    GENDER,
    LOCALE,
    QC_BOUNDS,
    TTS_MODEL,
    TTS_MODEL_VERSION,
    TTS_PROVIDER,
    VOICE,
    cdn_relative_path,
    compute_audio_id,
    load_wordbook_examples,
    probe_duration_ms,
)
from reference import normalize_text, sha256_16  # noqa: E402


def file_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def process_one(task: dict) -> dict:
    """Worker: copy one MP3 + compute metadata. Runs in subprocess."""
    audio_id = task["audio_id"]
    src_path = Path(task["src_path"])
    dst_path = Path(task["dst_path"])
    en = task["en"]
    stable_id = task["stable_id"]

    # Copy unless already in place (idempotent re-run).
    if not dst_path.exists():
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            shutil.copy2(src_path, dst_path)
        except OSError as e:
            return {"error": f"copy_failed: {e}", "audio_id": audio_id}

    duration_ms = probe_duration_ms(dst_path)
    min_ms, max_ms = QC_BOUNDS["example"]
    if duration_ms < min_ms or duration_ms > max_ms:
        return {
            "error": "duration_out_of_range",
            "audio_id": audio_id,
            "duration_ms": duration_ms,
        }

    bytes_size = dst_path.stat().st_size
    checksum = file_sha256(dst_path)
    src_text_hash = sha256_16(normalize_text(en).encode("utf-8"))

    return {
        "id": audio_id,
        "target_kind": "example",
        "target_id": stable_id,
        "locale": LOCALE,
        "voice": VOICE,
        "accent": ACCENT,
        "gender": GENDER,
        "format": FORMAT,
        "audio_version": AUDIO_VERSION,
        "checksum_sha256": checksum,
        "source_text_hash": src_text_hash,
        "tts_provider": TTS_PROVIDER,
        "tts_model": TTS_MODEL,
        "tts_model_version": TTS_MODEL_VERSION,
        "bytes": bytes_size,
        "duration_ms": duration_ms,
        "url": f"local://cdn/{cdn_relative_path('example', audio_id).as_posix()}",
        "status": "ready",
        "composite_label": (
            f"example:{stable_id}:{LOCALE}:{VOICE}:{AUDIO_VERSION}"
        ),
        "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        ),
    }


def main() -> None:
    repo_root = HERE.parent.parent.parent.parent

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-dir",
        type=Path,
        required=True,
        help="Recursive root of pre-organized MP3 files (named {audio_id}.mp3).",
    )
    parser.add_argument(
        "--assets-dir",
        type=Path,
        default=repo_root / "apps" / "mobile" / "assets" / "words",
        help="Wordbook assets directory.",
    )
    parser.add_argument(
        "--cdn-mock-dir",
        type=Path,
        default=repo_root / "apps" / "api" / "cdn-mock",
        help="Mock CDN root.",
    )
    parser.add_argument(
        "--staging-dir",
        type=Path,
        default=repo_root / "apps" / "api" / "audio-pipeline-staging",
        help="Output dir for audio_assets.jsonl.",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=4,
        help="Parallel ffprobe + sha256 workers (default 4).",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Process at most N matched entries (0 = no limit). For smoke tests.",
    )
    args = parser.parse_args()

    if not args.source_dir.exists():
        print(f"Source dir not found: {args.source_dir}", file=sys.stderr)
        sys.exit(1)
    args.cdn_mock_dir.mkdir(parents=True, exist_ok=True)
    args.staging_dir.mkdir(parents=True, exist_ok=True)

    # ── Load expected (current wordbook) ────────────────────────────────────
    print(f"Loading wordbook examples from {args.assets_dir}...")
    examples = load_wordbook_examples(args.assets_dir)
    expected_by_aid: dict[str, dict] = {}
    for ex in examples:
        aid = compute_audio_id("example", ex["stable_id"])
        expected_by_aid[aid] = ex
    print(f"  {len(examples)} examples → {len(expected_by_aid)} expected audio_ids")

    # ── Scan source dir ─────────────────────────────────────────────────────
    print(f"Scanning {args.source_dir} for *.mp3...")
    source_files: dict[str, Path] = {}
    for p in args.source_dir.rglob("*.mp3"):
        source_files[p.stem] = p
    print(f"  {len(source_files)} MP3 files in source")

    # ── Match ───────────────────────────────────────────────────────────────
    matched_aids = set(expected_by_aid.keys()) & set(source_files.keys())
    stale = len(source_files) - len(matched_aids)
    no_audio = len(expected_by_aid) - len(matched_aids)
    print(f"  matched (intersection):       {len(matched_aids)}")
    print(f"  stale (mp3 with no example):  {stale}")
    print(f"  no audio (example with no mp3): {no_audio}")

    if not matched_aids:
        print("Nothing to process.", file=sys.stderr)
        sys.exit(0)

    # ── Build task list ─────────────────────────────────────────────────────
    tasks: list[dict] = []
    for aid in sorted(matched_aids):
        ex = expected_by_aid[aid]
        src = source_files[aid]
        dst = args.cdn_mock_dir / cdn_relative_path("example", aid)
        tasks.append(
            {
                "audio_id": aid,
                "stable_id": ex["stable_id"],
                "en": ex["en"],
                "src_path": str(src),
                "dst_path": str(dst),
            }
        )
    if args.limit > 0:
        tasks = tasks[: args.limit]
        print(f"  --limit {args.limit} → processing first {len(tasks)}")

    # ── Process in parallel ─────────────────────────────────────────────────
    print(f"Copying + probing (workers={args.workers})...")
    rows: list[dict] = []
    qc_failed = 0
    copy_failed = 0
    with ProcessPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(process_one, t) for t in tasks]
        done = 0
        for fut in as_completed(futures):
            result = fut.result()
            done += 1
            if "error" in result:
                if result["error"].startswith("copy_failed"):
                    copy_failed += 1
                else:
                    qc_failed += 1
            else:
                rows.append(result)
            if done % 250 == 0 or done == len(tasks):
                print(f"  {done}/{len(tasks)} ({len(rows)} ready)")

    # ── Emit audio_assets.jsonl ─────────────────────────────────────────────
    out = args.staging_dir / "audio_assets.jsonl"
    with out.open("w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False))
            f.write("\n")
    print(f"  wrote {out}")

    # ── Summary ─────────────────────────────────────────────────────────────
    print()
    print("=" * 60)
    print("External MP3 ingest complete")
    print("=" * 60)
    print(f"  Source MP3 files:           {len(source_files)}")
    print(f"  Matched current wordbook:   {len(matched_aids)}")
    print(f"  Stale (left in source):     {stale}")
    print(f"  Examples without audio:     {no_audio}")
    print(f"  Successfully published:     {len(rows)}")
    print(f"  Copy failed:                {copy_failed}")
    print(f"  QC failed (duration OOR):   {qc_failed}")
    print()
    print("Next step (run from apps/api/):")
    print(
        f"  npx ts-node scripts/ingest-audio-assets.ts \\\n"
        f"    --examples-json ../audio-pipeline-staging/examples.json \\\n"
        f"    --audio-jsonl   ../audio-pipeline-staging/audio_assets.jsonl"
    )


if __name__ == "__main__":
    main()
