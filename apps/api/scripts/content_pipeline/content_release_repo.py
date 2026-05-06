"""CRUD + state machine + activation_log helpers for content_release.

设计原则:
  - 所有写函数 **不 commit**（评审采纳 R1.1/R2.3）
  - 调用方用 `with conn:` 或显式 try/conn.commit/rollback 控制事务边界
  - raise ReleaseError 描述业务约束失败（与 psycopg2 异常区分）

State machine (v0.3 §B.4.5 + PR-B1 Day 2 rollback):
  draft → validated → active → deprecated → revoked
                              └─→ revoked
                              ↑   (rollback)
                              └── deprecated  ← PR-B1 Day 2

CLI 入口覆盖：draft / validated / active / deprecated / revoked / rollback
"""
from __future__ import annotations

import psycopg2
import psycopg2.extras


VALID_STATUSES = {"draft", "validated", "active", "deprecated", "revoked"}

VALID_TRANSITIONS = {
    ("draft", "validated"),
    ("validated", "active"),
    ("active", "deprecated"),
    ("active", "revoked"),
    ("deprecated", "revoked"),
    # PR-B1 Day 2: rollback 入口。**不加 ("revoked", "active")** —— revoke
    # 是不可逆硬撤回（v0.3 PR-B scope 术语表 + e2e 反例 case 双重护栏）。
    ("deprecated", "active"),
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


def list_releases(
    conn,
    *,
    status: str | None = None,
    limit: int = 50,
) -> list[dict]:
    """Governance overview list — release_id, title, status, key timestamps.

    Sorted by created_at DESC, release_id DESC (二级键防同秒抖动 R2.11).
    --limit clamping responsibility lives at the CLI layer (pipeline.py).

    Returns: list of dict rows; empty list if none match.
    """
    if status is not None and status not in VALID_STATUSES:
        raise ReleaseError(f"invalid status filter: {status!r}")

    sql = """
        SELECT release_id, title, status, created_at, activated_at, revoked_at
          FROM content_release
    """
    params: list = []
    if status is not None:
        sql += " WHERE status = %s"
        params.append(status)
    sql += " ORDER BY created_at DESC, release_id DESC LIMIT %s"
    params.append(limit)

    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute(sql, params)
        return [dict(r) for r in cur.fetchall()]


def deprecate_release(conn, release_id: str, reason: str) -> None:
    """active → deprecated 软下线（评审采纳 R2.3 副作用契约写死）.

    NOT commit'd — caller controls transaction.

    Side-effect contract:
      - 仅 UPDATE content_release.status (+ activation_log entry)
      - **不动 content_manifest.is_active** —— 留给 PR-B rollback 余地
      - manifest API 自然不返回（dual-condition 卡 release.status='active'）

    Use revoke if you want hard takedown.
    """
    transition_status(conn, release_id, "deprecated", reason=reason)


def approve_release(
    conn,
    release_id: str,
    approver: str,
    note: str | None = None,
) -> None:
    """Mark a validated release as approved by a named approver.

    PR-B1 Day 3. NOT commit'd — caller controls transaction.

    activation_log entry format (R1#6 review-adopted convention):
      This helper appends an entry with `from == to == 'validated'`.
      That shape signals "audit annotation, NOT a status transition".
      Consumers (list-releases / future PR-B3 UI / PR-C observability)
      should treat such entries differently from real transitions —
      the convention is: `reason.startswith("approved by ")` indicates
      an approval audit entry. Future schema may add a `kind` field.

    Side-effects (atomic within caller's transaction):
      - UPDATE content_release.approved_by = approver
      - Append activation_log entry:
          { "from": "validated", "to": "validated",
            "at": ISO8601_UTC,
            "reason": "approved by {approver}" + (": {note}" if note else "") }

    Sanity guards (raise ReleaseError):
      - approver is empty / whitespace-only after strip (R2#4)
      - approver length > 64 (matches schema VARCHAR(64))
      - release not found
      - release.status != 'validated'

    Re-approval semantics:
      Allowed (overwrites approved_by). Caller should be aware approved_by
      reflects the most recent approver; activation_log preserves the full
      sequence for audit. e2e covers this with explicit log-tail assertions.
    """
    # Approver validation (R2#4 review-adopted)
    approver_clean = (approver or "").strip()
    if not approver_clean:
        raise ReleaseError("approver must be non-empty / non-whitespace")
    if len(approver_clean) > 64:
        raise ReleaseError(
            f"approver too long ({len(approver_clean)} > 64); "
            f"matches schema VARCHAR(64) limit"
        )

    release = get_release(conn, release_id)
    if release is None:
        raise ReleaseError(f"release {release_id!r} not found")
    if release["status"] != "validated":
        raise ReleaseError(
            f"approve only allowed in 'validated' state, "
            f"got {release['status']!r} for {release_id!r}"
        )

    log_reason = f"approved by {approver_clean}"
    if note:
        log_reason += f": {note}"

    with conn.cursor() as cur:
        cur.execute(
            """
            UPDATE content_release
               SET approved_by = %s,
                   activation_log = activation_log || jsonb_build_array(
                     jsonb_build_object(
                       'from', 'validated',
                       'to', 'validated',
                       'at', to_char(NOW() AT TIME ZONE 'UTC',
                                     'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
                       'reason', %s
                     )
                   )
             WHERE release_id = %s AND status = 'validated'
            """,
            (approver_clean, log_reason, release_id),
        )
        if cur.rowcount != 1:
            raise ReleaseError(
                f"approve_release race: {release_id!r} status moved during update"
            )


def rollback_release(conn, target_id: str, reason: str) -> None:
    """Reactivate a deprecated release; demote current active to deprecated.

    PR-B1 Day 2. NOT commit'd — caller controls transaction (use `with conn:`).

    Side-effects (atomic within caller's transaction):
      1. If exactly ONE other release is currently 'active':
         - cascade is_active=false on its package_set
         - transition that release to 'deprecated'
           Note: its activation_log entry's reason is **prefixed** to
           "rollback to {target_id}: {reason}" for audit traceability.
      2. cascade is_active=true on target.package_set
      3. transition target to 'active'
         (target's reason is the unprefixed input reason.)

    Sanity guards (raise ReleaseError):
      - target not found
      - target.status != 'deprecated'
        (revoked → active is forbidden; revoke is irreversible)
      - count(content_release WHERE status='active') > 1
        (PR-A's cmd_activate doesn't demote prior actives' status,
         only their manifests; multi-active state is a latent bug
         that rollback refuses to silently pick a winner for —
         operator must manually deprecate the unintended active(s)
         to disambiguate)

    Returns None — caller doesn't need the side-effect IDs.
    """
    target = get_release(conn, target_id)
    if target is None:
        raise ReleaseError(f"target release {target_id!r} not found")
    if target["status"] != "deprecated":
        raise ReleaseError(
            f"rollback only allowed from 'deprecated', "
            f"got {target['status']!r} for {target_id!r}"
        )

    # Multi-active sanity check (R1#2 review-adopted)
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute(
            "SELECT release_id, package_set FROM content_release "
            "WHERE status = 'active'"
        )
        actives = cur.fetchall()
    if len(actives) > 1:
        ids = ", ".join(repr(a["release_id"]) for a in actives)
        raise ReleaseError(
            f"multiple active releases (count={len(actives)}: {ids}); "
            f"deprecate the unintended ones first then retry rollback"
        )

    # 1. demote current active (if exactly one and not the target itself)
    if len(actives) == 1:
        current = actives[0]
        if current["release_id"] == target_id:
            # target is somehow already active — shouldn't happen given
            # status='deprecated' check above, but defensive
            raise ReleaseError(
                f"target {target_id!r} is currently the active release; "
                f"nothing to rollback to"
            )
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE content_manifest SET is_active = false "
                "WHERE id = ANY(%s)",
                (current["package_set"],),
            )
        transition_status(
            conn,
            current["release_id"],
            "deprecated",
            reason=f"rollback to {target_id}: {reason}",
        )

    # 2. promote target
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE content_manifest SET is_active = true "
            "WHERE id = ANY(%s)",
            (target["package_set"],),
        )
    transition_status(conn, target_id, "active", reason=reason)
