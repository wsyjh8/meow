"""
audio_assets state-machine GC (v0.3 §B.4.3 / §B.7.3) — best-effort, NOT atomic.

Two stages:
  superseded     → eligible_for_gc  (after grace_days_promote)
  eligible_for_gc → deleted          (after grace_days_delete + 文件删除尝试)

Failure handling (Day 4 review-driven):
  - URL resolve fails OR unlink permission errors → keep row at eligible_for_gc;
    next gc-stale call can retry (NOT marked deleted)
  - File doesn't exist (already removed externally) → mark deleted (success
    semantically equivalent to "the file is gone")
  - Default --dry-run; --gc actually executes
  - Negative grace_days → reject early
  - transitioned_at IS NULL anomalies → log warn, don't auto-process

NOT covered (留 Day 5 / orphan-scan cmd):
  - Filesystem orphan scan (cdn-mock files with no audio_assets row referencing them)
"""
from __future__ import annotations

import os
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

import psycopg2
import psycopg2.extras


def _resolve_local_path(url: str, cdn_mock_dir: Path) -> Path | None:
    """Map audio_assets.url to local cdn-mock or absolute filesystem path.

    Three URL schemes (handle each correctly, NOT generically):
      file:///D:/...    → absolute path (NOT prefixed with cdn_mock_dir)
      local://cdn/...   → relative to cdn_mock_dir
      http(s)://.../cdn/  → relative path after /cdn/, prefixed with cdn_mock_dir
    """
    parsed = urlparse(url)

    if parsed.scheme == "file":
        path_str = unquote(parsed.path)
        # Windows: file:///D:/foo → parsed.path == '/D:/foo' → strip leading /
        if len(path_str) >= 3 and path_str[0] == "/" and path_str[2] == ":":
            path_str = path_str[1:]
        return Path(path_str)

    if parsed.scheme == "local" and parsed.netloc == "cdn":
        return cdn_mock_dir / unquote(parsed.path.lstrip("/"))

    # http://.../cdn/audio/v1/... or https://.../cdn/...
    if "/cdn/" in url:
        rel = url.split("/cdn/", 1)[1]
        return cdn_mock_dir / unquote(rel)

    return None


def _print_anomaly_count(cur) -> None:
    """Warn about superseded/eligible_for_gc rows with NULL transitioned_at.

    These rows are unreachable by the normal grace_days filter; gc-stale will
    never act on them. Day 1 backfill set transitioned_at for all existing rows,
    so this should be 0; future bad writes would surface here.
    """
    cur.execute(
        """
        SELECT COUNT(*) FROM audio_assets
        WHERE status IN ('superseded', 'eligible_for_gc')
          AND transitioned_at IS NULL
        """
    )
    count = cur.fetchone()[0]
    if count > 0:
        print(
            f"  WARN: {count} row(s) in superseded/eligible_for_gc have "
            f"transitioned_at IS NULL; they will NOT be auto-processed. "
            f"Investigate: SELECT id, status FROM audio_assets WHERE status IN "
            f"('superseded','eligible_for_gc') AND transitioned_at IS NULL;"
        )


def run(
    *,
    grace_days_promote: int,
    grace_days_delete: int,
    dry_run: bool,
    gc: bool,
    cdn_mock_dir: Path,
) -> int:
    # Mutual exclusion early fail
    if dry_run and gc:
        print(
            "ERROR: --dry-run and --gc are mutually exclusive",
            file=sys.stderr,
        )
        return 2
    if not dry_run and not gc:
        # Default: dry-run
        dry_run = True

    db_url = os.environ.get("DATABASE_URL")
    if not db_url:
        print("ERROR: DATABASE_URL not set", file=sys.stderr)
        return 2

    conn = psycopg2.connect(db_url)
    try:
        # ── Anomaly detection (always shown, even in dry-run) ────────────
        with conn.cursor() as cur:
            _print_anomaly_count(cur)

        # ── Stage 1 candidates: superseded → eligible_for_gc ─────────────
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, target_kind, target_id, voice, audio_version,
                       transitioned_at, url
                FROM audio_assets
                WHERE status = 'superseded'
                  AND transitioned_at IS NOT NULL
                  AND transitioned_at < NOW() - (%s || ' days')::interval
                """,
                (grace_days_promote,),
            )
            promote_candidates = cur.fetchall()

        # ── Stage 2 candidates: eligible_for_gc → deleted ────────────────
        # Note: this SELECT runs BEFORE any promote UPDATE, so rows just
        # promoted IN this call won't be subject to delete IN this call.
        # Don't refactor to "promote then re-select delete candidates" without
        # re-thinking the grace window semantics.
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, url, transitioned_at
                FROM audio_assets
                WHERE status = 'eligible_for_gc'
                  AND transitioned_at IS NOT NULL
                  AND transitioned_at < NOW() - (%s || ' days')::interval
                """,
                (grace_days_delete,),
            )
            delete_candidates = cur.fetchall()

        print(
            f"  promote candidates (superseded > {grace_days_promote}d):     "
            f"{len(promote_candidates)}"
        )
        print(
            f"  delete  candidates (eligible_for_gc > {grace_days_delete}d): "
            f"{len(delete_candidates)}"
        )
        # Sample print first 3 of each (helpful for dry-run debugging)
        for row in promote_candidates[:3]:
            print(
                f"    promote: {row[0]} kind={row[1]} target={row[2]} "
                f"voice={row[3]} v={row[4]} @{row[5]}"
            )
        for row in delete_candidates[:3]:
            print(f"    delete:  {row[0]} url={row[1]} @{row[2]}")

        if dry_run:
            print("  (dry-run: no changes)")
            return 0

        # ── --gc execution ───────────────────────────────────────────────

        # Stage 1: promote (own short transaction; race-safe via status guard)
        if promote_candidates:
            ids_p = [r[0] for r in promote_candidates]
            with conn:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        UPDATE audio_assets
                           SET status = 'eligible_for_gc',
                               transitioned_at = NOW(),
                               transition_reason = 'gc-stale --promote'
                         WHERE id = ANY(%s)
                           AND status = 'superseded'
                        """,
                        (ids_p,),
                    )
                    promoted = cur.rowcount
            print(f"  promoted {promoted} row(s) → eligible_for_gc")

        # Stage 2: delete files + mark deleted (best-effort, NOT atomic)
        if delete_candidates:
            deleted_ids: list[str] = []
            skipped_ids: list[tuple[str, str]] = []  # (id, reason)

            for aid, url, _ in delete_candidates:
                local_path = _resolve_local_path(url, cdn_mock_dir)
                if local_path is None:
                    skipped_ids.append((aid, f"url_resolve_failed: {url!r}"))
                    continue
                try:
                    if local_path.exists():
                        local_path.unlink()
                    # File missing = success semantically (already gone)
                    deleted_ids.append(aid)
                except FileNotFoundError:
                    # Race: someone deleted between exists() and unlink()
                    deleted_ids.append(aid)
                except OSError as e:
                    skipped_ids.append((aid, f"unlink_error: {e}"))

            # UPDATE only successful ones; status guard prevents race
            if deleted_ids:
                with conn:
                    with conn.cursor() as cur:
                        cur.execute(
                            """
                            UPDATE audio_assets
                               SET status = 'deleted',
                                   transitioned_at = NOW(),
                                   transition_reason = 'gc-stale --delete'
                             WHERE id = ANY(%s)
                               AND status = 'eligible_for_gc'
                            """,
                            (deleted_ids,),
                        )
                        deleted_count = cur.rowcount
                print(f"  deleted {deleted_count} file+row → deleted")

            if skipped_ids:
                print(f"  skipped {len(skipped_ids)} row(s) — kept eligible_for_gc, will retry next time:")
                for aid, reason in skipped_ids[:5]:
                    print(f"    skip: {aid} ({reason})")
                if len(skipped_ids) > 5:
                    print(f"    ... ({len(skipped_ids) - 5} more)")

        return 0
    finally:
        conn.close()
