"""
Partial publish — convert Codex pipeline's tmp/wav/*.wav files to MP3,
populate the local mock CDN, and emit `audio_assets.jsonl` (+ optionally
`examples.json`) ready for the ingest script.

This is the "宽松模式" path described in DB v0.3.0 §4.6.2: only the WAVs
that exist (Codex has done so far) become `status='ready'` audio assets.
The rest are simply absent from `audio_assets`, so the API's
`/api/v1/{kind}s/:target_id/audio` endpoint returns 404 for them, and the
mobile App correctly grays out the play button.

Two `--kind` modes (P2.2.B adds `word`):

  --kind=example  (default, P2.1)
    Inputs:  apps/mobile/assets/words/{book-001,zk,gk}.json (examples[])
    Outputs: examples.json + audio_assets.jsonl
    CDN:     audio/v1/examples/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3

  --kind=word  (P2.2.B)
    Inputs:  apps/api/audio-pipeline-staging/words.json
             (run scripts/audio_pipeline/generate_words_json.py first)
    Outputs: audio_assets.jsonl ONLY
             (words are already populated in PG `words` table by P1 seed; no
              content table needs reingesting)
    CDN:     audio/v1/words/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3

Workflow (kind=example)
-----------------------
1. Read all examples (with stable_id) from `apps/mobile/assets/words/*.json`.
2. For each example, derive the audio_id deterministically using the same
   `sha256_24(canonical_json([target_kind, target_id, ...]))` formula as the
   Codex pipeline.
3. If the corresponding WAV file exists in the `--wav-dir`, convert it to
   MP3 (mono / 96 kbps / 22050 Hz) per pipeline §4.3.3, place under
   `--cdn-mock-dir` following the CDN path template, and append a row to
   the audio_assets jsonl output.
4. Always emit `examples.json` containing every wordbook example, so that
   ingest fills the `examples` PG table even for entries without audio.

Workflow (kind=word)
--------------------
Same as above, but:
  - Reads canonical word list from `words.json`.
  - target_kind='word', target_id=word_id (canonical lowercase).
  - Source text hash uses target_id directly (already-normalized).
  - QC bounds are tighter (single-word audio is short).
  - No content-table side-output (no equivalent of examples.json).

Outputs
-------
  <staging>/examples.json        — kind=example only
  <staging>/audio_assets.jsonl   — both kinds (entries with WAV → MP3 done)
  <cdn-mock>/audio/v1/{kind}s/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3

Usage
-----
  # Examples (P2.1 path)
  python apps/api/scripts/audio_pipeline/partial_publish.py \
    --kind example \
    --wav-dir D:/code/AI/startUp/meow/temp/tmp/wav

  # Words (P2.2.B path) — requires words.json from generate_words_json.py
  python apps/api/scripts/audio_pipeline/generate_words_json.py
  python apps/api/scripts/audio_pipeline/partial_publish.py \
    --kind word \
    --wav-dir D:/code/AI/startUp/meow/temp/tmp/wav-words

After this completes, run (kind=example):
  cd apps/api
  npx ts-node scripts/ingest-audio-assets.ts \
    --examples-json ../audio-pipeline-staging/examples.json \
    --audio-jsonl  ../audio-pipeline-staging/audio_assets.jsonl

Or (kind=word — examples-json optional):
  npx ts-node scripts/ingest-audio-assets.ts \
    --audio-jsonl ../audio-pipeline-staging/audio_assets.jsonl \
    --manifest-id audio-meta-words@v1 \
    --package-name audio-meta-words
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from reference import (  # noqa: E402
    canonical_json_bytes,
    normalize_text,
    sha256_16,
    sha256_24,
)


# ====== Constants — match Codex pipeline + audio_contract.yaml ======
LOCALE = "en-US"
VOICE = "af_bella"
ACCENT = "us"
GENDER = "f"
FORMAT = "mp3"
AUDIO_VERSION = "v1"
TTS_PROVIDER = "kokoro-local"
TTS_MODEL = "hexgrad/Kokoro-82M"
TTS_MODEL_VERSION = "kokoro-82m-v1"


# ====== QC thresholds (DB §4.8.2) — relaxed for partial publish ======
# (min_ms, max_ms) — examples are full sentences, words are 1-3 syllables.
QC_BOUNDS: dict[str, tuple[int, int]] = {
    "example": (500, 30000),
    "word": (150, 8000),
}


def compute_audio_id(target_kind: str, target_id: str) -> str:
    """Derive audio_id from (target_kind, target_id) using the contract spec.

    audio_version is in the hash so re-renders yield new audio_ids.
    """
    return sha256_24(
        canonical_json_bytes(
            [target_kind, target_id, LOCALE, VOICE, FORMAT, AUDIO_VERSION]
        )
    )


def shard(audio_id: str) -> str:
    """First 2 hex chars of audio_id — file system sharding prefix."""
    return audio_id[:2]


def cdn_relative_path(target_kind: str, audio_id: str) -> Path:
    """CDN path template per DB §4.6 / pipeline §4.3.4."""
    plural = f"{target_kind}s"  # 'example' → 'examples', 'word' → 'words'
    return Path(
        "audio",
        "v1",
        plural,
        LOCALE,
        VOICE,
        AUDIO_VERSION,
        shard(audio_id),
        f"{audio_id}.{FORMAT}",
    )


# ====== Loaders ======


def load_wordbook_examples(assets_dir: Path) -> list[dict]:
    """Read book-001 / zk / gk wordbook JSONs and yield flat example rows.

    Each row: stable_id / word_id / en / cn / sense / book_slug / ordinal.
    """
    examples: list[dict] = []
    for slug in ("book-001", "zk", "gk"):
        asset_file = assets_dir / f"{slug}.json"
        if not asset_file.exists():
            print(f"  [warn] missing asset file: {asset_file}", file=sys.stderr)
            continue
        data = json.loads(asset_file.read_text(encoding="utf-8"))
        for word in data.get("words", []):
            word_id = word.get("wordId")
            for ex in word.get("examples", []) or []:
                stable_id = ex.get("stableId")
                if not stable_id:
                    continue
                examples.append(
                    {
                        "stable_id": stable_id,
                        "word_id": word_id,
                        "en": ex.get("en", ""),
                        "cn": ex.get("cn", ""),
                        "sense": ex.get("sense"),
                        "ordinal": ex.get("sortOrder", 0),
                        "book_slug": slug,
                    }
                )
    return examples


def load_words_for_publish(words_json: Path) -> list[dict]:
    """Read pre-generated words.json (from generate_words_json.py).

    Each row: word_id (canonical) + word_text (raw, sent to TTS).
    """
    if not words_json.exists():
        raise FileNotFoundError(
            f"words.json not found at {words_json}. "
            f"Run scripts/audio_pipeline/generate_words_json.py first."
        )
    data = json.loads(words_json.read_text(encoding="utf-8"))
    items = data.get("items") or []
    out: list[dict] = []
    for it in items:
        wid = it.get("word_id")
        wtext = it.get("word_text") or wid
        if not wid:
            continue
        out.append({"word_id": wid, "word_text": wtext})
    return out


# ====== ffmpeg / ffprobe helpers ======


def convert_wav_to_mp3(wav_path: Path, mp3_path: Path) -> bool:
    """Convert WAV to MP3 (mono / 96kbps / 22050Hz) per pipeline §4.3.3."""
    mp3_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        "ffmpeg",
        "-y",
        "-loglevel",
        "error",
        "-i",
        str(wav_path),
        "-vn",
        "-ac",
        "1",
        "-b:a",
        "96k",
        "-ar",
        "22050",
        str(mp3_path),
    ]
    result = subprocess.run(cmd, capture_output=True)
    if result.returncode != 0:
        return False
    return mp3_path.exists() and mp3_path.stat().st_size > 0


def probe_duration_ms(mp3_path: Path) -> int:
    """ffprobe → duration in milliseconds. Returns 0 on error."""
    cmd = [
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(mp3_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return 0
    try:
        return int(float(result.stdout.strip()) * 1000)
    except (ValueError, IndexError):
        return 0


def file_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


# ====== Per-task processing ======


def process_one(task: dict) -> dict:
    """Worker: convert one WAV → MP3 + compute metadata.

    Runs in a child process so several ffmpeg invocations execute in
    parallel. Returns either an `audio_assets` row dict (success) or
    `{'error': str, ...}` (failure / qc_failed).

    Task fields:
      audio_id, target_kind, target_id, text, wav_path, mp3_path
    """
    audio_id = task["audio_id"]
    target_kind = task["target_kind"]
    target_id = task["target_id"]
    text = task["text"]
    wav_path = Path(task["wav_path"])
    mp3_path = Path(task["mp3_path"])

    if not mp3_path.exists():
        if not convert_wav_to_mp3(wav_path, mp3_path):
            return {"error": "ffmpeg_failed", "audio_id": audio_id}

    duration_ms = probe_duration_ms(mp3_path)
    min_ms, max_ms = QC_BOUNDS[target_kind]
    if duration_ms < min_ms or duration_ms > max_ms:
        return {
            "error": "duration_out_of_range",
            "audio_id": audio_id,
            "duration_ms": duration_ms,
        }

    bytes_size = mp3_path.stat().st_size
    checksum = file_sha256(mp3_path)

    # source_text_hash per reference.compute_source_text_hash:
    #   example → hash(normalize_text(en))
    #   word    → hash(target_id)  [target_id is already normalize_word output]
    if target_kind == "example":
        src_text_hash = sha256_16(normalize_text(text).encode("utf-8"))
    else:  # word
        src_text_hash = sha256_16(target_id.encode("utf-8"))

    return {
        "id": audio_id,
        "target_kind": target_kind,
        "target_id": target_id,
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
        # `local://cdn` placeholder; ingest script rewrites with real CDN_ORIGIN.
        "url": f"local://cdn/{cdn_relative_path(target_kind, audio_id).as_posix()}",
        "status": "ready",
        "composite_label": (
            f"{target_kind}:{target_id}:{LOCALE}:{VOICE}:{AUDIO_VERSION}"
        ),
        "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        ),
    }


# ====== Main ======


def main() -> None:
    repo_root = HERE.parent.parent.parent.parent

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--kind",
        choices=["example", "word"],
        default="example",
        help="Target kind. Default: example (P2.1 path).",
    )
    parser.add_argument(
        "--wav-dir",
        type=Path,
        required=True,
        help="Directory containing Codex pipeline's WAV files (named {audio_id}.wav).",
    )
    parser.add_argument(
        "--assets-dir",
        type=Path,
        default=repo_root / "apps" / "mobile" / "assets" / "words",
        help="(kind=example) wordbook assets dir. Default: apps/mobile/assets/words/",
    )
    parser.add_argument(
        "--words-json",
        type=Path,
        default=repo_root / "apps" / "api" / "audio-pipeline-staging" / "words.json",
        help="(kind=word) words.json from generate_words_json.py. "
             "Default: apps/api/audio-pipeline-staging/words.json",
    )
    parser.add_argument(
        "--cdn-mock-dir",
        type=Path,
        default=repo_root / "apps" / "api" / "cdn-mock",
        help="Mock CDN root. MP3s placed under <cdn-mock-dir>/audio/v1/...",
    )
    parser.add_argument(
        "--staging-dir",
        type=Path,
        default=repo_root / "apps" / "api" / "audio-pipeline-staging",
        help="Output dir for examples.json + audio_assets.jsonl.",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=4,
        help="Parallel ffmpeg workers (default 4).",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Process at most N entries (0 = no limit). Useful for smoke test.",
    )
    args = parser.parse_args()

    # ====== Sanity ======
    if not args.wav_dir.exists():
        print(f"WAV dir not found: {args.wav_dir}", file=sys.stderr)
        sys.exit(1)
    args.cdn_mock_dir.mkdir(parents=True, exist_ok=True)
    args.staging_dir.mkdir(parents=True, exist_ok=True)

    # ====== Load entries (kind-dispatch) ======
    if args.kind == "example":
        if not args.assets_dir.exists():
            print(f"Assets dir not found: {args.assets_dir}", file=sys.stderr)
            sys.exit(1)
        print(f"Loading wordbook examples from {args.assets_dir}...")
        examples = load_wordbook_examples(args.assets_dir)
        print(f"  {len(examples)} examples with stableId")

        if args.limit > 0:
            examples = examples[: args.limit]
            print(f"  --limit {args.limit} → processing first {len(examples)}")

        # Emit examples.json (covers both audio-ready and not-yet rows).
        examples_out = args.staging_dir / "examples.json"
        examples_out.write_text(
            json.dumps(
                {"items": examples, "total": len(examples)},
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
        print(f"  wrote {examples_out}")

        # Build tasks for example processing.
        all_entries = [
            {
                "target_kind": "example",
                "target_id": ex["stable_id"],
                "text": ex["en"],
            }
            for ex in examples
        ]
    else:  # word
        print(f"Loading words from {args.words_json}...")
        words = load_words_for_publish(args.words_json)
        print(f"  {len(words)} canonical word_ids")
        if args.limit > 0:
            words = words[: args.limit]
            print(f"  --limit {args.limit} → processing first {len(words)}")
        all_entries = [
            {
                "target_kind": "word",
                "target_id": w["word_id"],
                "text": w["word_text"],
            }
            for w in words
        ]

    # ====== Match WAVs ======
    print(f"Scanning {args.wav_dir} for WAV files...")
    wav_filenames = {p.stem for p in args.wav_dir.glob("*.wav")}
    print(f"  {len(wav_filenames)} WAV files in {args.wav_dir.name}")

    tasks = []
    missing = 0
    for entry in all_entries:
        audio_id = compute_audio_id(entry["target_kind"], entry["target_id"])
        if audio_id not in wav_filenames:
            missing += 1
            continue
        wav_path = args.wav_dir / f"{audio_id}.wav"
        mp3_path = args.cdn_mock_dir / cdn_relative_path(
            entry["target_kind"], audio_id
        )
        tasks.append(
            {
                "audio_id": audio_id,
                "target_kind": entry["target_kind"],
                "target_id": entry["target_id"],
                "text": entry["text"],
                "wav_path": str(wav_path),
                "mp3_path": str(mp3_path),
            }
        )

    print(
        f"  {len(tasks)} matches → process; "
        f"{missing} entries have no WAV (Codex pending)"
    )
    if not tasks:
        print(
            "  Nothing to process. Check that WAV filenames are 24-hex audio_id."
        )
        # Still emit empty audio_assets.jsonl for downstream stability.
        audio_jsonl = args.staging_dir / "audio_assets.jsonl"
        audio_jsonl.write_text("", encoding="utf-8")
        print(f"  wrote empty {audio_jsonl}")
        return

    # ====== Process in parallel ======
    print(f"Converting (workers={args.workers})...")
    audio_assets_rows: list[dict] = []
    qc_failed = 0
    ffmpeg_failed = 0

    with ProcessPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(process_one, t) for t in tasks]
        done = 0
        for fut in as_completed(futures):
            result = fut.result()
            done += 1
            if "error" in result:
                if result["error"] == "ffmpeg_failed":
                    ffmpeg_failed += 1
                else:
                    qc_failed += 1
            else:
                audio_assets_rows.append(result)
            if done % 100 == 0 or done == len(tasks):
                print(f"  {done}/{len(tasks)} ({len(audio_assets_rows)} ready)")

    # ====== Emit audio_assets.jsonl ======
    audio_jsonl = args.staging_dir / "audio_assets.jsonl"
    with audio_jsonl.open("w", encoding="utf-8") as f:
        for row in audio_assets_rows:
            f.write(json.dumps(row, ensure_ascii=False))
            f.write("\n")
    print(f"  wrote {audio_jsonl}")

    # ====== Summary ======
    total_label = "Wordbook examples" if args.kind == "example" else "Words"
    print()
    print("=" * 60)
    print(f"Partial publish complete (kind={args.kind})")
    print("=" * 60)
    print(f"  {total_label} (all):              {len(all_entries)}")
    print(f"  Have WAV (Codex done):          {len(tasks)}")
    print(f"  No WAV (Codex pending):         {missing}")
    print(f"  Successfully published (MP3):   {len(audio_assets_rows)}")
    print(f"  ffmpeg failed:                  {ffmpeg_failed}")
    print(f"  QC failed (duration OOR):       {qc_failed}")
    print()
    print("Next step (run from apps/api/):")
    if args.kind == "example":
        print(
            f"  npx ts-node scripts/ingest-audio-assets.ts \\\n"
            f"    --examples-json ../audio-pipeline-staging/examples.json \\\n"
            f"    --audio-jsonl   ../audio-pipeline-staging/audio_assets.jsonl"
        )
    else:
        print(
            f"  npx ts-node scripts/ingest-audio-assets.ts \\\n"
            f"    --audio-jsonl   ../audio-pipeline-staging/audio_assets.jsonl \\\n"
            f"    --manifest-id   audio-meta-words@v1 \\\n"
            f"    --package-name  audio-meta-words"
        )


if __name__ == "__main__":
    main()
