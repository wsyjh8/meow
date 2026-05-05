"""CRUD + state machine + activation_log helpers for content_release.

设计原则:
  - 所有写函数 **不 commit**（评审采纳 R1.1/R2.3）
  - 调用方用 `with conn:` 或显式 try/conn.commit/rollback 控制事务边界
  - raise ReleaseError 描述业务约束失败（与 psycopg2 异常区分）

State machine (v0.3 §B.4.5):
  draft → validated → active → deprecated → revoked
                              ↓
                            revoked

Day 3 CLI 入口覆盖: draft / validated / active / revoked
deprecated 状态保留在 VALID_TRANSITIONS 但 Day 3 无 CLI 入口（留 Day 5/PR-B）
"""
from __future__ import annotations

import psycopg2
import psycopg2.extras


VALID_STATUSES = {"draft", "validated", "active", "deprecated", "revoked"}

VALID_TRANSITIONS = {
    ("draft", "validated"),
    ("validated", "active"),
    ("active", "deprecated"),  # Day 3 无 CLI 入口
    ("active", "revoked"),
    ("deprecated", "revoked"),
}


class ReleaseError(Exception):
    """Raised on invalid state transitions or constraint violations."""


def get_release(conn, release_id: str) -> dict | None:
    """SELECT * FROM content_release WHERE release_id = ?, returns None if absent."""
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute(
            "SELECT * FROM content_release WHERE release_id = %s", (release_id,)
        )
        row = cur.fetchone()
    return dict(row) if row else None


def create_release(
    conn,
    release_id: str,
    *,
    title: str | None = None,
    target_min_app_version: str | None = None,
    generated_by: str = "pipeline.py",
) -> None:
    """INSERT a draft release.

    NOT commit'd — caller controls transaction.
    Raises ReleaseError if release_id already exists.
    """
    with conn.cursor() as cur:
        try:
            cur.execute(
                """
                INSERT INTO content_release
                  (release_id, title, package_set, target_min_app_version,
                   status, generated_by, created_at)
                VALUES (%s, %s, '[]'::jsonb, %s, 'draft', %s, NOW())
                """,
                (release_id, title, target_min_app_version, generated_by),
            )
        except psycopg2.errors.UniqueViolation as e:
            raise ReleaseError(
                f"release_id {release_id!r} already exists"
            ) from e


def transition_status(
    conn,
    release_id: str,
    to_status: str,
    *,
    reason: str,
) -> None:
    """Atomic status transition + activation_log append.

    NOT commit'd — caller controls transaction boundary.
    Raises ReleaseError on illegal transition / not-found / race.

    activation_log entry shape (v0.3 review采纳 R1.10 ISO UTC):
      { from, to, at: ISO 8601 UTC, reason }
    """
    if to_status not in VALID_STATUSES:
        raise ReleaseError(f"invalid target status: {to_status!r}")

    release = get_release(conn, release_id)
    if release is None:
        raise ReleaseError(f"release {release_id!r} not found")
    from_status = release["status"]
    if (from_status, to_status) not in VALID_TRANSITIONS:
        raise ReleaseError(
            f"illegal transition {from_status!r} → {to_status!r} for {release_id!r}"
        )

    extra_set = ""
    if to_status == "active":
        extra_set = ", activated_at = NOW()"
    elif to_status == "revoked":
        extra_set = ", revoked_at = NOW()"

    with conn.cursor() as cur:
        cur.execute(
            f"""
            UPDATE content_release
               SET status = %s{extra_set},
                   activation_log = activation_log || jsonb_build_array(
                     jsonb_build_object(
                       'from', %s,
                       'to', %s,
                       'at', to_char(NOW() AT TIME ZONE 'UTC',
                                     'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
                       'reason', %s
                     )
                   )
             WHERE release_id = %s AND status = %s
            """,
            (to_status, from_status, to_status, reason, release_id, from_status),
        )
        if cur.rowcount != 1:
            raise ReleaseError(
                f"transition_status race: {release_id!r} status moved during update"
            )
