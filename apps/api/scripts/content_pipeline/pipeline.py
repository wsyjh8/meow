"""
v0.3 PR-A 内容发布 pipeline 单一 entry。

Subcommands:
  build-examples-package  --book <slug>   # PR-A Day 2 (implemented)
  validate <release_id>                   # PR-A Day 3 (stub)
  activate <release_id>                   # PR-A Day 3 (stub)
  revoke <release_id>                     # PR-A Day 3 (stub)
  publish-manifest <release_id>           # PR-A Day 3 (stub)
  gc-stale [--dry-run|--gc]               # PR-A Day 4 (stub)

Usage (run from apps/api directory):

  python scripts/content_pipeline/pipeline.py build-examples-package \\
    --book book-001 --update-pg

See README.md for full setup + usage.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
# Allow `from build_examples_package import run` (sibling module in same dir)
sys.path.insert(0, str(HERE))

from build_examples_package import run as run_build_examples_package  # noqa: E402


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


def cmd_validate(args: argparse.Namespace) -> int:
    raise NotImplementedError("validate: PR-A Day 3")


def cmd_activate(args: argparse.Namespace) -> int:
    raise NotImplementedError("activate: PR-A Day 3")


def cmd_revoke(args: argparse.Namespace) -> int:
    raise NotImplementedError("revoke: PR-A Day 3")


def cmd_publish_manifest(args: argparse.Namespace) -> int:
    raise NotImplementedError("publish-manifest: PR-A Day 3")


def cmd_gc_stale(args: argparse.Namespace) -> int:
    raise NotImplementedError("gc-stale: PR-A Day 4")


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

    # ── build-examples-package (Day 2 implementation) ─────────────────────
    p_build = sub.add_parser(
        "build-examples-package",
        help="Build examples-{book}.jsonl.gz from PG examples + backfill content_hash",
    )
    p_build.add_argument(
        "--book",
        required=True,
        choices=["book-001", "zk", "gk"],
    )
    # Defaults are RELATIVE to current working directory (cwd=apps/api).
    # Avoids the cwd=apps/api → apps/api/apps/api/... double-nest trap.
    p_build.add_argument(
        "--out-dir",
        default="audio-pipeline-staging",
        help="Output directory for jsonl.gz (relative to cwd)",
    )
    p_build.add_argument(
        "--assets-dir",
        default="../mobile/assets/words",
        help="Path to wordbook JSON assets (relative to cwd)",
    )
    p_build.add_argument(
        "--update-pg",
        action="store_true",
        help="Also UPDATE examples.content_hash in PG (recommended for full backfill)",
    )
    p_build.set_defaults(func=cmd_build_examples_package)

    # ── stub subcommands (Day 3+) ─────────────────────────────────────────
    p_validate = sub.add_parser("validate", help="[PR-A Day 3 stub]")
    p_validate.add_argument("release_id")
    p_validate.set_defaults(func=cmd_validate)

    p_activate = sub.add_parser("activate", help="[PR-A Day 3 stub]")
    p_activate.add_argument("release_id")
    p_activate.set_defaults(func=cmd_activate)

    p_revoke = sub.add_parser("revoke", help="[PR-A Day 3 stub]")
    p_revoke.add_argument("release_id")
    p_revoke.set_defaults(func=cmd_revoke)

    p_publish = sub.add_parser("publish-manifest", help="[PR-A Day 3 stub]")
    p_publish.add_argument("release_id")
    p_publish.set_defaults(func=cmd_publish_manifest)

    p_gc = sub.add_parser("gc-stale", help="[PR-A Day 4 stub]")
    p_gc.add_argument("--dry-run", action="store_true")
    p_gc.add_argument("--gc", action="store_true")
    p_gc.set_defaults(func=cmd_gc_stale)

    return parser


def main() -> int:
    parser = _build_parser()
    args = parser.parse_args()
    return args.func(args) or 0


# Ensure CLI entry actually runs main() — prevents "script ran but did nothing"
if __name__ == "__main__":
    sys.exit(main())
