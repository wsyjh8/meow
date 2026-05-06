"""
v0.3 PR-A 内容发布 pipeline 单一 entry。

Subcommands:
  create-release <release_id>             # PR-A Day 3
  build-examples-package --book <slug>    # PR-A Day 2
  publish-manifest --release ... --file ... # PR-A Day 3
  validate <release_id>                   # PR-A Day 3
  activate <release_id>                   # PR-A Day 3
  deprecate <release_id> --reason TXT     # PR-A Day 5 (active → deprecated 软下线)
  revoke <release_id> [--reason TXT]      # PR-A Day 3
                                          #   注意: revoke 是撤销/下线，不是 rollback
  list-releases [--status S] [--limit N]  # PR-A Day 5 (治理可视化)
  gc-stale [--dry-run|--gc]               # PR-A Day 4

Usage (run from apps/api directory):

  python scripts/content_pipeline/pipeline.py create-release rel-2026-05-05-001
  python scripts/content_pipeline/pipeline.py build-examples-package --book book-001 --update-pg
  python scripts/content_pipeline/pipeline.py publish-manifest \\
    --release rel-2026-05-05-001 \\
    --package-name examples-book-001 --package-kind examples \\
    --content-version v1 \\
    --file audio-pipeline-staging/examples-book-001.jsonl.gz
  python scripts/content_pipeline/pipeline.py validate rel-2026-05-05-001
  python scripts/content_pipeline/pipeline.py activate rel-2026-05-05-001

See README.md for full setup + naming convention.
"""
from __future__ import annotations

import argparse
import gzip
import json
import os
import sys
from pathlib import Path

import psycopg2
import psycopg2.extras

HERE = Path(__file__).resolve().parent
# Allow `from build_examples_package import run` (sibling module in same dir)
sys.path.insert(0, str(HERE))

from build_examples_package import file_sha256, run as run_build_examples_package  # noqa: E402
from content_release_repo import (  # noqa: E402
    ReleaseError,
    create_release,
    deprecate_release,
    get_release,
    list_releases,
    transition_status,
)


# =============================================================================
# Helpers
# =============================================================================


def _connect_or_die() -> psycopg2.extensions.connection | None:
    """Returns a connection or None if DATABASE_URL missing (caller exits 2)."""
    db_url = os.environ.get("DATABASE_URL")
    if not db_url:
        print("ERROR: DATABASE_URL not set", file=sys.stderr)
        return None
    return psycopg2.connect(db_url)


PACKAGE_NAME_PREFIX = {
    "examples": "examples-",
    "audio_meta": "audio-meta-",
    "wordbook": "wordbook-",
    "dictionary": "dictionary-",
}


def _validate_package_name(package_name: str, package_kind: str) -> None:
    """Naming convention enforcement (评审采纳 R1.5).

    Prevents activate cascade误伤 (e.g. bare 'examples' would cascade-deactivate
    examples-book-001 / examples-zk / examples-gk together).
    """
    expected_prefix = PACKAGE_NAME_PREFIX.get(package_kind)
    if not expected_prefix:
        raise ReleaseError(
            f"unsupported package_kind {package_kind!r}; "
            f"expected one of {list(PACKAGE_NAME_PREFIX)}"
        )
    if not package_name.startswith(expected_prefix):
        raise ReleaseError(
            f"{package_kind} package_name must start with {expected_prefix!r}, "
            f"got {package_name!r}; see README naming convention"
        )


# =============================================================================
# Subcommand handlers
# =============================================================================


def cmd_build_examples_package(args: argparse.Namespace) -> int:
    return run_build_examples_package(
        book_slug=args.book,
        out_dir=args.out_dir,
        update_pg=args.update_pg,
        assets_dir=args.assets_dir,
    )


def cmd_create_release(args: argparse.Namespace) -> int:
    conn = _connect_or_die()
    if conn is None:
        return 2
    try:
        create_release(
            conn,
            args.release_id,
            title=args.title,
            target_min_app_version=args.target_min_app_version,
        )
        conn.commit()
        print(f"  created draft release {args.release_id}")
        return 0
    except ReleaseError as e:
        conn.rollback()
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    finally:
        conn.close()


def cmd_publish_manifest(args: argparse.Namespace) -> int:
    """Register a built package into content_manifest + release.package_set.

    Constraints (v0.2 评审采纳):
      - release.status MUST equal 'draft' (R1.2/R2.1; validated 是冻结态)
      - package_name MUST match naming convention (R1.5)
      - Same manifest_id with different content → error (R1.7/R2.4)
      - Same manifest_id with same content → idempotent no-op
      - file_url 固定 file:// scheme (R1.4/R2.5; --cdn-prefix 已删)
    """
    conn = _connect_or_die()
    if conn is None:
        return 2

    try:
        # Naming convention pre-check (cheap, fail fast)
        _validate_package_name(args.package_name, args.package_kind)

        # File metadata
        file_path = Path(args.file).resolve()
        if not file_path.exists():
            raise ReleaseError(f"file not found: {file_path}")
        sha = file_sha256(file_path)
        size = file_path.stat().st_size
        # Use POSIX path with file:// scheme for cross-platform consistency
        file_url = f"file:///{file_path.as_posix().lstrip('/')}"
        manifest_id = f"{args.package_name}@{args.content_version}"

        with conn:  # auto BEGIN; commit on success; rollback on exception
            with conn.cursor() as cur:
                # 1. Verify release exists + status='draft'
                cur.execute(
                    "SELECT status FROM content_release WHERE release_id=%s",
                    (args.release,),
                )
                row = cur.fetchone()
                if not row:
                    raise ReleaseError(f"release {args.release!r} not found")
                if row[0] != "draft":
                    raise ReleaseError(
                        f"publish-manifest only allowed in 'draft' state, "
                        f"got {row[0]!r}"
                    )

                # 2. Conflict handling
                cur.execute(
                    """SELECT checksum_sha256, size_bytes, file_url, release_id
                       FROM content_manifest WHERE id=%s""",
                    (manifest_id,),
                )
                existing = cur.fetchone()
                if existing:
                    if existing == (sha, size, file_url, args.release):
                        print(
                            f"  manifest {manifest_id} already registered "
                            f"(idempotent, no change)"
                        )
                        return 0
                    raise ReleaseError(
                        f"manifest {manifest_id} exists with different metadata "
                        f"(existing checksum/size/url/release={existing}, "
                        f"new=({sha},{size},{file_url},{args.release})); "
                        f"use a new content_version instead of overwriting"
                    )

                # 3. INSERT manifest (is_active=false until activate)
                cur.execute(
                    """INSERT INTO content_manifest
                       (id, package_name, package_kind, content_version, file_url,
                        checksum_sha256, size_bytes, min_app_version, is_active,
                        generated_at, release_id)
                       VALUES (%s, %s, %s, %s, %s, %s, %s, %s, false, NOW(), %s)""",
                    (
                        manifest_id,
                        args.package_name,
                        args.package_kind,
                        args.content_version,
                        file_url,
                        sha,
                        size,
                        args.min_app_version or "0.0.0",
                        args.release,
                    ),
                )

                # 4. Append to package_set (idempotent dedupe)
                cur.execute(
                    """UPDATE content_release
                          SET package_set = package_set || to_jsonb(%s::text)
                        WHERE release_id = %s
                          AND NOT package_set @> to_jsonb(%s::text)""",
                    (manifest_id, args.release, manifest_id),
                )

        print(f"  registered {manifest_id}")
        print(f"    file_url = {file_url}")
        print(f"    sha256   = {sha}")
        print(f"    size     = {size:,}")
        return 0
    except ReleaseError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    finally:
        conn.close()


def cmd_validate(args: argparse.Namespace) -> int:
    """Validate a draft release: 8-step bidirectional consistency + checksum check.

    Steps (D6):
      1. release exists + status = 'draft'
      2. package_set non-empty
      3. forward: every package_set id has a content_manifest row
      4. reverse: every manifest with release_id=X is in package_set
      5. all manifest file_url use file:// scheme
      6. file exists at path
      7. file sha256 matches manifest.checksum_sha256
      8. file size matches manifest.size_bytes
    """
    conn = _connect_or_die()
    if conn is None:
        return 2

    rid = args.release_id
    try:
        # Step 1: release + status
        release = get_release(conn, rid)
        if release is None:
            raise ReleaseError(f"release {rid!r} not found")
        if release["status"] != "draft":
            raise ReleaseError(
                f"validate only allowed in 'draft' state, got {release['status']!r}"
            )
        print(f"  [OK]release {rid!r} exists, status='draft'")

        # Step 2: package_set non-empty
        package_set: list[str] = release["package_set"]
        if not package_set:
            raise ReleaseError(f"release {rid!r} has empty package_set")
        print(f"  [OK]package_set has {len(package_set)} item(s)")

        # Step 3: forward — package_set ⊆ content_manifest
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """SELECT id, file_url, checksum_sha256, size_bytes, release_id
                   FROM content_manifest WHERE id = ANY(%s)""",
                (package_set,),
            )
            manifests_by_id = {r["id"]: dict(r) for r in cur.fetchall()}
        missing_forward = [pid for pid in package_set if pid not in manifests_by_id]
        if missing_forward:
            raise ReleaseError(
                f"package_set references manifests not in content_manifest: "
                f"{missing_forward}"
            )
        print(f"  [OK]all package_set items present in content_manifest (forward)")

        # Step 4: reverse — manifest WHERE release_id=X ⊆ package_set
        with conn.cursor() as cur:
            cur.execute(
                """SELECT id FROM content_manifest
                    WHERE release_id = %s
                      AND NOT (id = ANY(%s))""",
                (rid, package_set),
            )
            orphans = [r[0] for r in cur.fetchall()]
        if orphans:
            raise ReleaseError(
                f"orphan manifests with release_id={rid!r} but NOT in package_set: "
                f"{orphans}; package_set and manifest table are out of sync"
            )
        print(f"  [OK]no orphan manifests with this release_id (reverse)")

        # Step 5-8: file_url scheme + file existence + checksum + size
        for mid, m in manifests_by_id.items():
            url: str = m["file_url"]
            if not url.startswith("file://"):
                raise ReleaseError(
                    f"manifest {mid} file_url scheme must be file://, got {url!r}; "
                    f"remote URL validation is PR-B / Day 5+, not Day 3"
                )
            # Strip 'file:///' prefix → posix path
            local_path_str = url[len("file:///") :] if url.startswith("file:///") else url[len("file://") :]
            local_path = Path("/" + local_path_str if not local_path_str.startswith("/") else local_path_str).resolve()
            # Windows: file:///D:/foo → /D:/foo → strip leading / and re-resolve
            if not local_path.exists():
                # Try without leading slash (Windows)
                alt = Path(local_path_str).resolve()
                if alt.exists():
                    local_path = alt
                else:
                    raise ReleaseError(
                        f"manifest {mid} file_url points to missing file: {url}"
                    )
            actual_sha = file_sha256(local_path)
            if actual_sha != m["checksum_sha256"]:
                raise ReleaseError(
                    f"manifest {mid} checksum mismatch: "
                    f"expected {m['checksum_sha256']}, got {actual_sha}"
                )
            actual_size = local_path.stat().st_size
            if actual_size != m["size_bytes"]:
                raise ReleaseError(
                    f"manifest {mid} size mismatch: "
                    f"expected {m['size_bytes']}, got {actual_size}"
                )
        print(f"  [OK]all {len(manifests_by_id)} manifest files exist + checksum/size OK")

        # All checks passed → transition status (caller controls commit)
        with conn:
            transition_status(conn, rid, "validated", reason="validate cmd")
        print(f"  transition: draft → validated")
        return 0
    except ReleaseError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    finally:
        conn.close()


def cmd_activate(args: argparse.Namespace) -> int:
    """Activate a validated release: cascade manifest is_active + transition.

    Transactional logic (D7):
      1. Set release.package_set manifests is_active=true
      2. Set OTHER manifests with same package_name is_active=false
      3. transition_status('validated' → 'active')
    """
    conn = _connect_or_die()
    if conn is None:
        return 2

    rid = args.release_id
    try:
        release = get_release(conn, rid)
        if release is None:
            raise ReleaseError(f"release {rid!r} not found")
        if release["status"] != "validated":
            raise ReleaseError(
                f"activate only allowed in 'validated' state, got {release['status']!r}"
            )
        package_set: list[str] = release["package_set"]
        if not package_set:
            raise ReleaseError(f"release {rid!r} has empty package_set")

        with conn:
            with conn.cursor() as cur:
                # 1. Activate this release's manifests
                cur.execute(
                    "UPDATE content_manifest SET is_active = true WHERE id = ANY(%s)",
                    (package_set,),
                )
                activated = cur.rowcount

                # 2. Deactivate other manifests with same package_name
                cur.execute(
                    """UPDATE content_manifest SET is_active = false
                        WHERE package_name IN (
                            SELECT DISTINCT package_name FROM content_manifest
                             WHERE id = ANY(%s)
                          )
                          AND id <> ALL(%s)
                          AND is_active = true""",
                    (package_set, package_set),
                )
                deactivated = cur.rowcount

            # 3. Transition release status (using shared helper, no inner commit)
            transition_status(conn, rid, "active", reason="activate cmd")

        print(f"  activated {activated} manifest(s) in {rid!r}")
        if deactivated > 0:
            print(
                f"  deactivated {deactivated} prior manifest(s) "
                f"with overlapping package_name"
            )
        print(f"  transition: validated → active")
        return 0
    except ReleaseError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    finally:
        conn.close()


def cmd_revoke(args: argparse.Namespace) -> int:
    """Revoke (撤销/下线，不是 rollback) an active or deprecated release.

    Note: 不会自动恢复任何旧版本到 active。如需恢复旧版本，操作员需
    publish 一个新 release 或 PR-B 之后加 rollback 子命令。
    """
    conn = _connect_or_die()
    if conn is None:
        return 2

    rid = args.release_id
    reason = args.reason or "revoke cmd"
    try:
        release = get_release(conn, rid)
        if release is None:
            raise ReleaseError(f"release {rid!r} not found")
        if release["status"] not in ("active", "deprecated"):
            raise ReleaseError(
                f"revoke only allowed in 'active' or 'deprecated' state, "
                f"got {release['status']!r}"
            )
        package_set: list[str] = release["package_set"]

        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE content_manifest SET is_active = false WHERE id = ANY(%s)",
                    (package_set,),
                )
                deactivated = cur.rowcount
            transition_status(conn, rid, "revoked", reason=reason)

        print(f"  deactivated {deactivated} manifest(s)")
        print(f"  transition: {release['status']} → revoked")
        print(f"  reason: {reason}")
        return 0
    except ReleaseError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    finally:
        conn.close()


def cmd_list_releases(args: argparse.Namespace) -> int:
    """Read-only governance overview (PR-A Day 5).

    --limit clamped to [1, 500] (R2.12 review-adopted).
    """
    if args.limit < 1 or args.limit > 500:
        print(
            f"ERROR: --limit must be in [1, 500], got {args.limit}",
            file=sys.stderr,
        )
        return 2

    conn = _connect_or_die()
    if conn is None:
        return 2

    try:
        rows = list_releases(conn, status=args.status, limit=args.limit)
    except ReleaseError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    finally:
        conn.close()

    if not rows:
        filter_desc = f" (status={args.status!r})" if args.status else ""
        print(f"  no releases found{filter_desc}")
        return 0

    # Plain-text table; columns sized for typical data + truncation
    def _fmt_ts(ts) -> str:
        return ts.strftime("%Y-%m-%d %H:%M:%S") if ts else "—"

    def _trunc(s, n):
        if s is None:
            return ""
        return s if len(s) <= n else s[: n - 1] + "…"

    print(
        f"{'release_id':<32}  {'status':<10}  "
        f"{'created_at':<19}  {'activated_at':<19}  title"
    )
    print("-" * 100)
    for r in rows:
        print(
            f"{_trunc(r['release_id'], 32):<32}  "
            f"{r['status']:<10}  "
            f"{_fmt_ts(r['created_at']):<19}  "
            f"{_fmt_ts(r['activated_at']):<19}  "
            f"{_trunc(r['title'], 40)}"
        )
    print(f"  ({len(rows)} row(s))")
    return 0


def cmd_deprecate(args: argparse.Namespace) -> int:
    """active → deprecated 软下线 (PR-A Day 5).

    副作用契约:
      - 仅改 release.status，不动 content_manifest.is_active
      - manifest API 自然不返回（dual-condition 卡 status='active'）
    """
    rid = args.release_id
    reason = args.reason

    if not args.yes:
        sys.stderr.write(
            f"About to deprecate release {rid!r}.\n"
            f"  reason: {reason}\n"
            f"  effect: release.status → 'deprecated'; "
            f"content_manifest.is_active 不变\n"
            f"Type 'y' to confirm: "
        )
        sys.stderr.flush()
        line = sys.stdin.readline().strip().lower()
        if line != "y":
            print("aborted", file=sys.stderr)
            return 1

    conn = _connect_or_die()
    if conn is None:
        return 2

    try:
        with conn:
            deprecate_release(conn, rid, reason)
        print(f"  [OK] release {rid!r} deprecated. reason: {reason}")
        return 0
    except ReleaseError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2
    finally:
        conn.close()


def cmd_gc_stale(args: argparse.Namespace) -> int:
    # Negative grace days early fail (review-driven safety)
    if args.grace_days_promote < 0 or args.grace_days_delete < 0:
        print("ERROR: grace days must be >= 0", file=sys.stderr)
        return 2
    from gc_stale import run as run_gc_stale

    return run_gc_stale(
        grace_days_promote=args.grace_days_promote,
        grace_days_delete=args.grace_days_delete,
        dry_run=args.dry_run,
        gc=args.gc,
        cdn_mock_dir=Path(args.cdn_mock_dir).resolve(),
    )


# =============================================================================
# Argument parser
# =============================================================================


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="pipeline.py",
        description="v0.3 PR-A content release pipeline (entry).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    # ── create-release (Day 3) ────────────────────────────────────────────
    p_create = sub.add_parser(
        "create-release", help="Create a new draft release"
    )
    p_create.add_argument("release_id")
    p_create.add_argument("--title", default=None)
    p_create.add_argument("--target-min-app-version", default=None)
    p_create.set_defaults(func=cmd_create_release)

    # ── build-examples-package (Day 2) ────────────────────────────────────
    p_build = sub.add_parser(
        "build-examples-package",
        help="Build examples-{book}.jsonl.gz from PG examples + backfill content_hash",
    )
    p_build.add_argument(
        "--book", required=True, choices=["book-001", "zk", "gk"],
    )
    p_build.add_argument(
        "--out-dir", default="audio-pipeline-staging",
        help="Output directory for jsonl.gz (relative to cwd)",
    )
    p_build.add_argument(
        "--assets-dir", default="../mobile/assets/words",
        help="Path to wordbook JSON assets (relative to cwd)",
    )
    p_build.add_argument(
        "--update-pg", action="store_true",
        help="Also UPDATE examples.content_hash in PG",
    )
    p_build.set_defaults(func=cmd_build_examples_package)

    # ── publish-manifest (Day 3) ──────────────────────────────────────────
    p_publish = sub.add_parser(
        "publish-manifest",
        help="Register a built package file to content_manifest + release.package_set",
    )
    p_publish.add_argument("--release", required=True, help="release_id")
    p_publish.add_argument("--package-name", required=True,
                           help="must match naming convention (see README)")
    p_publish.add_argument("--package-kind", required=True,
                           choices=["examples", "audio_meta", "wordbook", "dictionary"])
    p_publish.add_argument("--content-version", required=True, help="e.g. 'v1', 'v5'")
    p_publish.add_argument("--file", required=True,
                           help="Path to the built package file (e.g. jsonl.gz)")
    p_publish.add_argument("--min-app-version", default=None,
                           help="Optional, defaults to '0.0.0'")
    p_publish.set_defaults(func=cmd_publish_manifest)

    # ── validate (Day 3) ──────────────────────────────────────────────────
    p_validate = sub.add_parser(
        "validate",
        help="Validate a draft release (8-step bidirectional + checksum)",
    )
    p_validate.add_argument("release_id")
    p_validate.set_defaults(func=cmd_validate)

    # ── activate (Day 3) ──────────────────────────────────────────────────
    p_activate = sub.add_parser(
        "activate", help="Activate a validated release (cascade manifest is_active)",
    )
    p_activate.add_argument("release_id")
    p_activate.set_defaults(func=cmd_activate)

    # ── revoke (Day 3) ────────────────────────────────────────────────────
    p_revoke = sub.add_parser(
        "revoke",
        help="Revoke (撤销/下线，不是 rollback) an active or deprecated release",
    )
    p_revoke.add_argument("release_id")
    p_revoke.add_argument("--reason", default=None,
                          help="Audit log reason (default 'revoke cmd')")
    p_revoke.set_defaults(func=cmd_revoke)

    # ── deprecate (Day 5) ─────────────────────────────────────────────────
    p_deprecate = sub.add_parser(
        "deprecate",
        help="Soft-retire an active release (active → deprecated; manifests untouched)",
    )
    p_deprecate.add_argument("release_id")
    p_deprecate.add_argument(
        "--reason", required=True,
        help="Audit log reason (required for governance trail)",
    )
    p_deprecate.add_argument(
        "--yes", action="store_true",
        help="Skip stdin confirmation (CI use)",
    )
    p_deprecate.set_defaults(func=cmd_deprecate)

    # ── list-releases (Day 5) ─────────────────────────────────────────────
    p_list = sub.add_parser(
        "list-releases",
        help="Governance overview — table of releases (read-only)",
    )
    p_list.add_argument(
        "--status", default=None,
        choices=["draft", "validated", "active", "deprecated", "revoked"],
        help="Filter by status; default returns all",
    )
    p_list.add_argument(
        "--limit", type=int, default=50,
        help="Max rows to return; clamped to [1, 500] (default 50)",
    )
    p_list.set_defaults(func=cmd_list_releases)

    # ── gc-stale (Day 4) ──────────────────────────────────────────────────
    p_gc = sub.add_parser(
        "gc-stale",
        help="audio_assets state-machine GC (best-effort, two-stage)",
    )
    p_gc.add_argument(
        "--dry-run", action="store_true",
        help="(default) print candidates only, no changes",
    )
    p_gc.add_argument(
        "--gc", action="store_true",
        help="actually promote + delete (mutually exclusive with --dry-run)",
    )
    p_gc.add_argument(
        "--grace-days-promote", type=int, default=30,
        help="superseded → eligible_for_gc grace days (default 30)",
    )
    p_gc.add_argument(
        "--grace-days-delete", type=int, default=30,
        help="eligible_for_gc → deleted grace days (default 30)",
    )
    p_gc.add_argument(
        "--cdn-mock-dir", default="cdn-mock",
        help="CDN mock root (relative to cwd, default 'cdn-mock')",
    )
    p_gc.set_defaults(func=cmd_gc_stale)

    return parser


def main() -> int:
    parser = _build_parser()
    args = parser.parse_args()
    return args.func(args) or 0


if __name__ == "__main__":
    sys.exit(main())
