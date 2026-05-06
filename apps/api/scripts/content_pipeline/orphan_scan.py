"""
Filesystem orphan scanner (PR-B1 Day 1) — counterpart to gc_stale.py.

While gc-stale is PG-driven (PG row + status='eligible_for_gc' → delete FS),
orphan-scan is FS-driven (FS file + no PG row referencing it → delete FS).

Two scan roots, each tied to a different PG table (探索后修正 P1):
  cdn-mock/                  ←→ audio_assets.url       (audio orphans)
  audio-pipeline-staging/    ←→ content_manifest.file_url (package orphans)

Safety semantics:
  - Default --dry-run; --clean to actually delete (mutually exclusive)
  - Whitelist filtering (see _is_safe_to_delete): only files inside the root
    subtree, only known extensions (.mp3 .gz .br .jsonl), no symlinks, no
    hidden / index files
  - Skip http(s):// scheme rows (real CDN, no local equivalent)
  - Skip audio_assets.status='deleted' rows (gc-stale already removed FS)
  - Per-file delete failures (permission, etc.) are logged but don't fail run

NOT covered:
  - Cron / auto schedule (runs on demand)
  - In-flight build files in staging may show as orphan; only run when no
    build is in progress (see Day 4 README troubleshooting)
"""
from __future__ import annotations

import sys
from pathlib import Path

import psycopg2
import psycopg2.extras

# Reuse gc_stale's URL → local path resolver to avoid SSOT drift
from gc_stale import _resolve_local_path  # noqa: E402


# Whitelist of safe-to-delete extensions (case-insensitive)
SAFE_EXTENSIONS = {".mp3", ".gz", ".br", ".jsonl"}

# Names that should never be deleted even if extension matches
PROTECTED_NAMES = {"index.json", "manifest.json"}


def _is_safe_to_delete(path: Path, root: Path) -> bool:
    """Conservative whitelist; reject anything we don't recognize.

    1. Must be under `root` subtree (defends against symlink escape)
    2. Must be a regular file, not a symlink
    3. Extension must be in SAFE_EXTENSIONS
    4. Must not be hidden (starts with '.') or in PROTECTED_NAMES
    """
    try:
        path.resolve().relative_to(root.resolve())
    except ValueError:
        return False
    if not path.is_file() or path.is_symlink():
        return False
    if path.suffix.lower() not in SAFE_EXTENSIONS:
        return False
    if path.name.startswith(".") or path.name in PROTECTED_NAMES:
        return False
    return True


def _walk_files(root: Path, extensions: set[str]) -> set[Path]:
    """Recursively collect absolute paths of files matching extensions.

    Returns empty set if root doesn't exist (caller already validated).
    Lower-case extension comparison.
    """
    out: set[Path] = set()
    if not root.exists():
        return out
    for p in root.rglob("*"):
        if p.is_file() and not p.is_symlink() and p.suffix.lower() in extensions:
            out.add(p.resolve())
    return out


def _scan_audio(conn, cdn_mock_dir: Path) -> tuple[set[Path], set[Path]]:
    """Find audio orphans in cdn-mock/.

    Returns (fs_files, referenced_paths). Caller computes diff.

    SQL:
      SELECT url FROM audio_assets
       WHERE url IS NOT NULL AND status != 'deleted'

    Skips:
      - http(s):// urls (real CDN, no local file)
      - rows where _resolve_local_path returns None
    """
    fs_files = _walk_files(cdn_mock_dir, {".mp3"})

    referenced: set[Path] = set()
    with conn.cursor() as cur:
        cur.execute(
            "SELECT url FROM audio_assets "
            "WHERE url IS NOT NULL AND status != 'deleted'"
        )
        for (url,) in cur.fetchall():
            if not url:
                continue
            if url.startswith("http://") or url.startswith("https://"):
                continue
            local = _resolve_local_path(url, cdn_mock_dir)
            if local is not None:
                referenced.add(local.resolve())

    return fs_files, referenced


def _scan_packages(
    conn, staging_dir: Path, cdn_mock_dir: Path
) -> tuple[set[Path], set[Path]]:
    """Find package orphans in audio-pipeline-staging/.

    Returns (fs_files, referenced_paths).

    SQL:
      SELECT file_url FROM content_manifest WHERE file_url IS NOT NULL

    Skips http(s):// URLs (real CDN, no local file).
    Note: cdn_mock_dir is passed only because _resolve_local_path needs it
    for local://cdn/ scheme; content_manifest URLs are file:// today, but
    the helper signature is fixed.
    """
    fs_files = _walk_files(staging_dir, {".gz", ".br", ".jsonl"})

    referenced: set[Path] = set()
    with conn.cursor() as cur:
        cur.execute(
            "SELECT file_url FROM content_manifest WHERE file_url IS NOT NULL"
        )
        for (url,) in cur.fetchall():
            if not url:
                continue
            if url.startswith("http://") or url.startswith("https://"):
                continue
            local = _resolve_local_path(url, cdn_mock_dir)
            if local is not None:
                referenced.add(local.resolve())

    return fs_files, referenced


def _print_orphans(label: str, root: Path, orphans: set[Path]) -> None:
    """Print count + total size + first 30 paths."""
    if not orphans:
        print(f"  [{label}] 0 orphan(s) under {root}")
        return
    total_bytes = 0
    for p in orphans:
        try:
            total_bytes += p.stat().st_size
        except OSError:
            pass
    total_kb = total_bytes / 1024
    print(f"  [{label}] {len(orphans)} orphan(s) under {root} (~{total_kb:.1f} KB total)")
    sample = sorted(orphans)[:30]
    for p in sample:
        try:
            rel = p.relative_to(root.resolve())
            print(f"    - {rel}")
        except ValueError:
            print(f"    - {p}")
    if len(orphans) > 30:
        print(f"    ... ({len(orphans) - 30} more)")


def _delete_orphans(orphans: set[Path], root: Path) -> tuple[int, int]:
    """Delete orphans that pass the whitelist; return (deleted, skipped)."""
    deleted = 0
    skipped = 0
    for p in sorted(orphans):
        if not _is_safe_to_delete(p, root):
            print(f"  [skip] {p} (failed whitelist)")
            skipped += 1
            continue
        try:
            p.unlink()
            try:
                rel = p.relative_to(root.resolve())
                print(f"  [del]  {rel}")
            except ValueError:
                print(f"  [del]  {p}")
            deleted += 1
        except OSError as e:
            print(f"  [skip] {p} (unlink failed: {e})")
            skipped += 1
    return deleted, skipped


def run(
    *,
    cdn_mock_dir: Path,
    staging_dir: Path,
    dry_run: bool,
    clean: bool,
    scope: str = "all",
) -> int:
    """Main entry. Returns exit code:
      0 = success (dry-run or clean done)
      1 = scan failure (PG / dir issues)
      2 = invalid args (mutex / scope / dirs not found)
    """
    # Mutex
    if dry_run and clean:
        print(
            "ERROR: --dry-run and --clean are mutually exclusive",
            file=sys.stderr,
        )
        return 2

    # Validate scope
    if scope not in ("audio", "packages", "all"):
        print(
            f"ERROR: --scope must be one of {{audio,packages,all}}, got {scope!r}",
            file=sys.stderr,
        )
        return 2

    # Validate roots when their scope is requested
    if scope in ("audio", "all") and not cdn_mock_dir.exists():
        print(
            f"ERROR: cdn-mock dir does not exist: {cdn_mock_dir}",
            file=sys.stderr,
        )
        return 2
    if scope in ("packages", "all") and not staging_dir.exists():
        print(
            f"ERROR: staging dir does not exist: {staging_dir}",
            file=sys.stderr,
        )
        return 2

    import os
    db_url = os.environ.get("DATABASE_URL")
    if not db_url:
        print("ERROR: DATABASE_URL not set", file=sys.stderr)
        return 2

    mode_label = "[DRY-RUN]" if not clean else "[CLEAN]"
    print(f"{mode_label} orphan-scan starting: scope={scope}")
    print(f"  cdn_mock_dir = {cdn_mock_dir}")
    print(f"  staging_dir  = {staging_dir}")

    audio_orphans: set[Path] = set()
    pkg_orphans: set[Path] = set()

    try:
        conn = psycopg2.connect(db_url)
    except psycopg2.Error as e:
        print(f"ERROR: PG connection failed: {e}", file=sys.stderr)
        return 1

    try:
        if scope in ("audio", "all"):
            try:
                fs, referenced = _scan_audio(conn, cdn_mock_dir)
            except psycopg2.Error as e:
                print(f"ERROR: audio scan PG query failed: {e}", file=sys.stderr)
                return 1
            audio_orphans = fs - referenced

        if scope in ("packages", "all"):
            try:
                fs, referenced = _scan_packages(conn, staging_dir, cdn_mock_dir)
            except psycopg2.Error as e:
                print(f"ERROR: package scan PG query failed: {e}", file=sys.stderr)
                return 1
            pkg_orphans = fs - referenced
    finally:
        conn.close()

    # Report
    if scope in ("audio", "all"):
        _print_orphans("audio", cdn_mock_dir, audio_orphans)
    if scope in ("packages", "all"):
        _print_orphans("package", staging_dir, pkg_orphans)

    if not clean:
        # dry-run, done
        return 0

    # clean mode: delete with whitelist guard
    deleted_total = 0
    skipped_total = 0
    if scope in ("audio", "all") and audio_orphans:
        d, s = _delete_orphans(audio_orphans, cdn_mock_dir)
        deleted_total += d
        skipped_total += s
    if scope in ("packages", "all") and pkg_orphans:
        d, s = _delete_orphans(pkg_orphans, staging_dir)
        deleted_total += d
        skipped_total += s

    print(f"  [OK] deleted={deleted_total}, skipped={skipped_total}")
    return 0
