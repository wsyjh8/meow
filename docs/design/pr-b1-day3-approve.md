# v0.3 PR-B1 · Day 3 — `approve` 子命令 + activate gating (v0.2)

## Context

PR-B1 Day 3。Day 1 (orphan-scan) 已合并 `214b4e5`，Day 2 (rollback) 已合并 `68dff82`。
Day 3 做审批工作流：在 `validated → active` 之间加可选的 `approved_by` 关卡，
治理审计完整化。**零 schema 改动**——`approved_by VARCHAR(64)` 字段已在
PR-A migration 007:68 留位。

工作分支：`feat/v0.3-pr-b1-publish-side-completion` @ `68dff82`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b1`

### 评审吸收（v0.1 → v0.2，两份外部评审 12 条改进）

| # | 来源 | 处置 |
|---|---|---|
| R1#1 / R2#1 | smoke `activate ... --yes` 参数不存在（cmd_activate 无 stdin 确认） | ✅ 删除两处 `--yes` |
| R1#2 / R2#3 | smoke step 6 期望 log `>=4` 实际 3（validate+approve+activate） | ✅ 改 `=3` 并列每条 entry from/to |
| R1#3 | e2e gating 3 cases 无法验证 Python subprocess gating（jest 改 process.env 不影响 Python） | ✅ 方案 A：删 3 cases，smoke 端到端兜底 |
| R1#4 | smoke 漏 env=false 默认 + 无 approve activate 通过的向后兼容路径 | ✅ 加独立 fixture `zk-day3-compat` |
| R1#5 / R2#2 | e2e cases 计数自相矛盾（列 6 个 it 写 +5） | ✅ 与 R1#3 一并：删 3 cases 后 +3，与 master plan 重算 |
| R1#6 | activation_log `from=to=validated` 审计 entry 与状态转换 entry 形态相同 | ✅ helper docstring 顶部 + design 要点写明约定；未来 PR-C 可加 `kind` 字段 |
| R1#7 | re-approval e2e case 缺明确 assertions | ✅ case 注释列出 `approved_by==B` + log 末两条具体 |
| R1#8 | 行号 typo `2007:68` 应 `007:68`；`os` import line 37 不是 32 | ✅ 修 |
| R1#9 | env var 解析加 `.strip()` + `"on"` 别名 | ✅ `.strip().lower() in ("true","1","yes","on")` |
| R1#10 | Day 1/2/3 e2e 数加总要在 Day 4 重算 master plan | 🟡 标记 Day 4 处理 |
| R1#11 | `rollback_target_id` 字段 PR-A 留位但未使用 | 🟡 Day 4 README/PR 描述说明（PR-C 启用 or PR-D 删） |
| R1#12 | `approve_release` SQL 与 `transition_status` jsonb 拼接 80% 重复 | 🟡 风险表注脚：future refactor `_append_log_entry` |
| R2#4 | argparse `required=True` 不防 `--approver ""` 或 `"  "` | ✅ helper `approver.strip()` 非空 + `len <= 64` 校验 |

### 核实事实（探索后）

- `content_release.approved_by` `VARCHAR(64)` nullable, 无 default, 无 CHECK（migration 007:68）
- `cmd_activate` status check 在 `pipeline.py:374`；gating 插入位置：**`package_set` check 之后 / `with conn:` 之前**（避免行号漂移）
- 现有 env var 读取仅 `DATABASE_URL` 一处（pipeline.py:67），**无现存布尔解析模式** —— Day 3 引入第一个
- `os` 已在 pipeline.py 顶部 import（line **37**）
- `transition_status` UPDATE 列：`status / activated_at / revoked_at / activation_log`，**不动 approved_by**
- `cmd_activate` **无 stdin 确认 / 无 --yes 参数**（subparser pipeline.py:763-768 仅 positional `release_id`）

## 实施

### Step 1：`content_release_repo.py` 加 helper `approve_release`

文件：`apps/api/scripts/content_pipeline/content_release_repo.py`

加在 `deprecate_release` 之后、`rollback_release` 之前（按 release lifecycle 顺序）：

```python
def approve_release(
    conn,
    release_id: str,
    approver: str,
    note: str | None = None,
) -> None:
    """Mark a validated release as approved by a named approver.

    PR-B1 Day 3. NOT commit'd — caller controls transaction.

    activation_log entry format (R1#6 review-adopted convention):
      This helper appends an entry with ``from == to == 'validated'``.
      That shape signals "audit annotation, NOT a status transition".
      Consumers (list-releases / future PR-B3 UI / PR-C observability)
      should treat such entries differently from real transitions —
      the convention is: ``reason.startswith("approved by ")`` indicates
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
    # Approver validation (R2#4)
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
```

### Step 2：`pipeline.py` 加 `cmd_approve` + subparser + `cmd_activate` gating

#### 2a. cmd_approve（约 35 行，在 cmd_rollback 之后）

```python
def cmd_approve(args: argparse.Namespace) -> int:
    """PR-B1 Day 3 — set approved_by on a validated release.

    Exit codes (PR-A 多数对齐):
      0 = success
      1 = ReleaseError (not found / not validated / approver invalid / race)
      2 = connection error
    """
    conn = _connect_or_die()
    if conn is None:
        return 2

    rid = args.release_id
    approver = args.approver
    note = args.note

    try:
        with conn:
            approve_release(conn, rid, approver, note)
        msg = f"  [OK] release {rid!r} approved by {approver.strip()!r}"
        if note:
            msg += f". note: {note}"
        print(msg)
        return 0
    except ReleaseError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    finally:
        conn.close()
```

注意：approve **不需** stdin 二次确认（无破坏性副作用，仅 UPDATE 一个字段 + log）。

#### 2b. cmd_activate gating（在现有 `package_set` 非空 check 之后，`with conn:` 之前）

定位：`pipeline.py` 现有 `cmd_activate` 内的：
```python
        if not package_set:
            raise ReleaseError(f"release {rid!r} has empty package_set")

        with conn:
```

在这两行之间插入：

```python
        # PR-B1 Day 3: optional approval gate (env-controlled, default off).
        # CONTENT_RELEASE_REQUIRE_APPROVAL forces approve before activate.
        # Truthy aliases (R1#9): "true", "1", "yes", "on" (case-insensitive,
        # whitespace-tolerant).
        require_approval = os.environ.get(
            "CONTENT_RELEASE_REQUIRE_APPROVAL", ""
        ).strip().lower() in ("true", "1", "yes", "on")
        if require_approval and not release["approved_by"]:
            raise ReleaseError(
                f"activate requires prior approval (env "
                f"CONTENT_RELEASE_REQUIRE_APPROVAL is set): run "
                f"'pipeline.py approve {rid} --approver <id>' first"
            )
```

`os` 已在 pipeline.py:37 import（`import os`），无需新增 import。
`release` dict 已通过 `get_release(conn, rid)` 取出，含 `approved_by` 列（PG SELECT * 默认）。

#### 2c. subparser（在 cmd_rollback subparser 之后）

```python
# ── approve (PR-B1 Day 3) ─────────────────────────────────────────────
p_approve = sub.add_parser(
    "approve",
    help="Mark a validated release as approved (gates activate when "
         "CONTENT_RELEASE_REQUIRE_APPROVAL=true)",
)
p_approve.add_argument("release_id")  # positional
p_approve.add_argument(
    "--approver", required=True,
    help="Approver identifier (free-form string, max 64 chars; future "
         "PR-B3 may bind to a user table)",
)
p_approve.add_argument(
    "--note", default=None,
    help="Optional approval note (audit log)",
)
p_approve.set_defaults(func=cmd_approve)
```

#### 2d. 文档头加

```
approve <release_id> --approver <id>    # PR-B1 Day 3 (validated 阶段审批)
```

#### 2e. content_release_repo import

```python
from content_release_repo import (
    ...
    approve_release,  # PR-B1 Day 3
    ...
)
```

### Step 3：e2e 3 cases (R1#3 方案 A：gating 由 smoke 端到端兜底)

文件：`apps/api/test/pg-regression.e2e-spec.ts`

加新 describe 块（在 Day 2 rollback 块之后）：

```typescript
describe('approve subcommand contract (PR-B1 Day 3)', () => {
  // approve sets content_release.approved_by + appends activation_log entry.
  //
  // Note (R1#3 review-adopted): activate's CONTENT_RELEASE_REQUIRE_APPROVAL
  // gating is implemented in cmd_activate (Python). jest setting
  // `process.env` only affects the Node test process, not Python subprocess,
  // so we can't truly test that gating here. Gating end-to-end is verified
  // by the mandatory PowerShell smoke (Step 4 fixtures `zk-day3-approve`
  // for env=true paths and `zk-day3-compat` for env=false PR-A back-compat).
  //
  // The 3 cases below verify approve_release's SQL contract:
  //   - happy: validated → approved_by + audit log entry
  //   - status guard: non-validated states reject (parametrized 4 states)
  //   - re-approval: overwrites approved_by; log preserves prior entries

  const TEST_PREFIX = 'test-approve-';

  // ... cleanup + helpers (seedRelease, simulateApprove)

  it('happy: approve validated → approved_by set + audit log entry shape', async () => {
    // 1. seed validated release
    // 2. simulateApprove(rid, 'wsyjh8', 'first approval')
    // 3. expect approved_by === 'wsyjh8'
    // 4. expect activation_log last entry: from='validated', to='validated',
    //    reason starts with 'approved by wsyjh8: first approval'
  });

  it('approve in non-validated state rejected (draft / active / deprecated / revoked)', async () => {
    // for each state in 4-tuple: seed release in that state, expect throw
    //   /approve only allowed in 'validated' state/
  });

  it('re-approval overwrites approved_by but preserves prior log entries (R1#7)', async () => {
    // 1. seed validated release
    // 2. approve A (note 'first')
    // 3. approve B (note 'second')
    // 4. expect approved_by === 'B'
    // 5. expect log entries (last two):
    //      [-2]: reason === 'approved by A: first'
    //      [-1]: reason === 'approved by B: second'
  });
});
```

期望 e2e 总数：**44 (Day 2 baseline) + 3 = 47 通过**（pre-existing /me/today 1 个不阻塞）。

**Why not test gating in e2e**：cmd_activate 是 Python，gating 通过 `os.environ` 读取。
jest 在 Node 进程里 `process.env.X = 'true'` 不会跨进程传到 Python。要么 spawn Python
（违反 PR-A/B1 一贯方针），要么删除 e2e 这部分让 smoke 兜底。选后者（评审 R1#3 方案 A）。

### Step 4：必跑 PowerShell smoke 9 步（R1#1 / R1#2 / R1#4 修订）

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b1\apps\api
$env:PGPASSWORD="<your-local-password>"

# ── 准备：build + 两个 fixture (compat + approve) ────────────────
# 1. build + rename
python scripts\content_pipeline\pipeline.py build-examples-package --book zk
Copy-Item audio-pipeline-staging\examples-zk.jsonl.gz audio-pipeline-staging\examples-zk@v1.jsonl.gz
Copy-Item audio-pipeline-staging\examples-zk.jsonl.gz audio-pipeline-staging\examples-zk@v2.jsonl.gz

# ── compat 路径：env=false (default) + 无 approve + activate 通过 (R1#4) ──
# 2. zk-day3-compat: 完整跑通到 active，**不调 approve**
python scripts\content_pipeline\pipeline.py create-release zk-day3-compat --title "compat smoke"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release zk-day3-compat --package-name examples-zk --package-kind examples `
  --content-version v1 --file audio-pipeline-staging\examples-zk@v1.jsonl.gz
python scripts\content_pipeline\pipeline.py validate zk-day3-compat
# env CONTENT_RELEASE_REQUIRE_APPROVAL 未设
python scripts\content_pipeline\pipeline.py activate zk-day3-compat
# 期望: 成功；activation_log 含 validate + active 两条；approved_by IS NULL

# ── approve 路径：env=true + activate 拒绝 → approve → activate 成功 ───
# 3. zk-day3-approve: 跑到 validated 停下
python scripts\content_pipeline\pipeline.py create-release zk-day3-approve --title "approve smoke"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release zk-day3-approve --package-name examples-zk --package-kind examples `
  --content-version v2 --file audio-pipeline-staging\examples-zk@v2.jsonl.gz
python scripts\content_pipeline\pipeline.py validate zk-day3-approve

# 4. env=true 后 activate 拒绝（R1#1 修正：无 --yes 参数）
$env:CONTENT_RELEASE_REQUIRE_APPROVAL="true"
python scripts\content_pipeline\pipeline.py activate zk-day3-approve
# 期望: ReleaseError "activate requires prior approval ..."，rc=1

# 5. approver 空字符串拒绝 (R2#4)
python scripts\content_pipeline\pipeline.py approve zk-day3-approve --approver ""
# 期望: ReleaseError "approver must be non-empty / non-whitespace"，rc=1
python scripts\content_pipeline\pipeline.py approve zk-day3-approve --approver "   "
# 期望: 同上，rc=1

# 6. 合法 approve
python scripts\content_pipeline\pipeline.py approve zk-day3-approve `
  --approver wsyjh8 --note "smoke test approve"
# 期望: [OK] release 'zk-day3-approve' approved by 'wsyjh8'. note: smoke test approve

# 7. 现在 activate 通过 (R1#1 修正：无 --yes)
python scripts\content_pipeline\pipeline.py activate zk-day3-approve
# 期望: 成功

# 8. 关 env，approve 在非 validated 状态（active）拒绝 + PG 反查 (R1#2 修正：=3 并列条目)
Remove-Item Env:\CONTENT_RELEASE_REQUIRE_APPROVAL
python scripts\content_pipeline\pipeline.py approve zk-day3-approve --approver wsyjh8
# 期望: ReleaseError "approve only allowed in 'validated' state, got 'active'"，rc=1

psql -h localhost -U postgres -d meow_dev -c `
  "SELECT release_id, status, approved_by, jsonb_array_length(activation_log) AS n FROM content_release WHERE release_id IN ('zk-day3-compat', 'zk-day3-approve') ORDER BY release_id;"
# 期望:
#   zk-day3-approve | active | wsyjh8 | 3   ← validate + approve + activate
#   zk-day3-compat  | active | NULL   | 2   ← validate + activate (no approve)

psql -h localhost -U postgres -d meow_dev -c `
  "SELECT release_id, jsonb_pretty(activation_log) FROM content_release WHERE release_id = 'zk-day3-approve';"
# 期望 3 条 entry（按时间序）：
#   1) from=draft, to=validated, reason='validate cmd'
#   2) from=validated, to=validated, reason='approved by wsyjh8: smoke test approve'  ← audit annotation
#   3) from=validated, to=active, reason='activate cmd'

# 9. cleanup
python scripts\content_pipeline\pipeline.py revoke zk-day3-approve --reason "smoke done"
python scripts\content_pipeline\pipeline.py revoke zk-day3-compat --reason "smoke done"
psql -h localhost -U postgres -d meow_dev -c `
  "DELETE FROM content_manifest WHERE release_id IN ('zk-day3-compat', 'zk-day3-approve');
   DELETE FROM content_release WHERE release_id IN ('zk-day3-compat', 'zk-day3-approve');"
Remove-Item audio-pipeline-staging\examples-zk@v1.jsonl.gz, audio-pipeline-staging\examples-zk@v2.jsonl.gz -ErrorAction SilentlyContinue
```

9 步全过 = Day 3 done。

## 关键文件

### 修改
- `apps/api/scripts/content_pipeline/content_release_repo.py`（+1 helper `approve_release`，约 75 行含 approver 校验）
- `apps/api/scripts/content_pipeline/pipeline.py`（+1 cmd +1 subparser +6 行 gating，约 60 行）
- `apps/api/test/pg-regression.e2e-spec.ts`（+1 describe 块, +3 cases）
- `docs/design/pr-b1-day3-approve.md`（本文 v0.2）

### 不动
- `orphan_scan.py` / `gc_stale.py` / `content-manifest.controller.ts`
- migration / README / mobile
- `VALID_TRANSITIONS`（approve 不是状态转换）

## 设计要点

1. **不改 VALID_TRANSITIONS**——approve 不是状态转换。Helper 内部 SQL 走的是
   "from=to=validated" 的 audit 注释 entry。
2. **activation_log 双形态约定**（R1#6 评审采纳）：
   - 状态转换 entry: `from != to`
   - 审计注释 entry: `from == to`，且 `reason` 以 `"approved by "` 开头
   - 消费方（list-releases / PR-B3 UI / PR-C 观测）必须区分这两类
   - 未来 PR-C 可加 `kind` 字段升级（`'transition'` vs `'audit'`），本 PR 不做
3. **env var 默认 false**——PR-A 操作员的 muscle memory 不被打断
4. **approver 输入兜底**（R2#4）：`strip()` 后非空 + 长度 ≤64
5. **approved_by 不被自动清**——`transition_status` 不动它；rollback 后审计可追溯
6. **approve 无 stdin 确认**——纯 UPDATE 字段，无破坏性副作用
7. **业务错误 rc=1**——与 PR-A create/validate/activate/revoke 对齐

## 评审 pre-set（猜可能被提的）

1. ✅ env var 大小写 / 空格 / 多别名：`.strip().lower() in (true,1,yes,on)`
2. ✅ re-approval 行为：允许覆盖；e2e 明确断言 log tail 两条
3. ✅ approver `VARCHAR(64)` 长度限制：CLI 层校验 + PG schema 兜底
4. 🟡 activate gating 仅靠 env 是否安全：设计如此（操作员协议）；强校验留 PR-B3
5. ✅ e2e 不能跨进程测 Python gating：删 3 cases，smoke 兜底
6. ✅ SQL race（status 在 approve 中途被改）：`WHERE status='validated'` + rowCount 守卫
7. ✅ CLI 不需 stdin 确认：approve 无破坏性副作用

## 验收清单

- [ ] `approve_release` helper 实装：approver strip 非空 + ≤64 校验 + status guard + UPDATE + log
- [ ] `cmd_approve` CLI: positional `release_id`, `--approver` required, `--note` optional, **无 --yes**
- [ ] `cmd_activate` 加 gating: `os.environ.get("CONTENT_RELEASE_REQUIRE_APPROVAL", "").strip().lower() in ("true","1","yes","on")` 且 `approved_by IS NULL` → 拒绝
- [ ] e2e **47/48 通过**（含 happy / 非 validated 4 状态拒绝 / re-approval log tail 断言）
- [ ] PowerShell smoke **9 步全过**（含 zk-day3-compat 向后兼容路径 + approver 空字符串拒绝）
- [ ] design dir `pr-b1-day3-approve.md` 同步 v0.2
- [ ] flutter analyze 可选兜底（不动 mobile）

## 风险

| 风险 | 缓解 |
|---|---|
| env var 漏开导致审批名存实亡 | README + 验收清单写明；PR-B3 加强制开关 |
| approved_by 在状态机移动后语义模糊 | 设计要点 #2 明确 audit entry 形态；UI（PR-B3）展示时可区分 |
| approve 后 deprecate 再 rollback，approved_by 旧值保留 | 设计如此（审计追溯）；UI 层区分 "current vs historical" |
| Day 3 工作量超 1 天 | helper ≤ 75 行 / cmd ≤ 35 行 / gating ≤ 6 行 / e2e 3 cases；预期 ≤ 4 小时 |
| `approve_release` SQL 与 `transition_status` jsonb 拼接 80% 重复 (R1#12) | 不阻塞；future refactor 抽 `_append_log_entry` helper（PR-C 候选） |

## 不做的事

- **不**改 schema（approved_by 字段已在 PR-A migration 007:68 留位）
- **不**改 `VALID_TRANSITIONS`（approve 不是状态转换）
- **不**做多签 / 角色绑定（PR-B3+）
- **不**做 Web UI（PR-B3）
- **不**触碰 mobile / API controller / migration
- **不**清理 approved_by 字段（rollback 后保留为审计）

## Day 4 预告（master plan 收尾任务）

Day 3 完成后 Day 4 工作清单：
- README 子命令表 9 → **12** (rollback / approve + 顺手补 orphan-scan)
- README 状态机图加 rollback 单向箭头（deprecated → active 唯一）
- README troubleshooting +3 条（gating env 配置 / approver 校验失败 / rollback FS missing）
- 完整 PR-B1 端到端 CLI smoke 大流程（覆盖所有 4 个新子命令）
- PR_DESCRIPTION_PR-B1.md 写到 `C:\Users\lenovo\.claude\`（git 视野外）
- **Master plan 总数重算**（R1#10）：34 + Day1(2) + Day2(8) + Day3(3) = **47 cases**
- **`rollback_target_id` 字段 PR-A 留位但未用**（R1#11）：
  - PR-B1 不用此字段（rollback 信息走 activation_log）
  - 在 PR 描述里说明，留 PR-C/PR-D 决定（启用 or 删除 schema）
- Day 4 文件名：`pr-b1-day4-readme-and-pr.md`
