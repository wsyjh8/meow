# v0.3 PR-B1 · Day 2 — `rollback` 子命令 (v0.2)

## Context

PR-B1 Day 2。Day 1 的 orphan-scan 已合并（commit `214b4e5`）。
现在做 `rollback`：把 deprecated 的旧 release 重新激活，同时把当前
active release 自动转 deprecated（不是 revoke）。

工作分支：`feat/v0.3-pr-b1-publish-side-completion` @ `214b4e5`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b1`

### 评审采纳的关键约束（v0.1 → v0.2，吸收两份外部评审 15+ 条）

| # | 来源 | 处置 |
|---|---|---|
| R1#1 / R2#2 | smoke step 9 fixture 撞 revoked guard | 起独立 v3 fixture 测 FS missing |
| R1#2 | LIMIT 1 + multi-active 隐患 | helper 加 sanity check `count(active) > 1 → ReleaseError` |
| R1#3 / R2#4 | CLI `--to` vs positional 三处不一致 | 统一 positional |
| R1#4 | 业务错误退出码 1 vs 2 | 改用 1（与 PR-A 多数对齐） |
| R1#5 | `--cdn-mock-dir` 死参数 | 删除（KISS） |
| R1#6 / R2#5 | e2e 数算账不对 | 修正 PR-B1 总 49 |
| R1#7 | e2e 没覆盖 FS check | describe 块顶 comment + smoke step 10 兜底 |
| R1#8 | helper docstring 没说 reason 前缀化 | docstring 注明 |
| R2#1 | smoke 文件名错 (@v1 不存在) | build + Copy-Item rename 出 v1/v2/v3 |
| R2#3 | NULL file_url 不应允许 rollback | helper / CLI 拒绝 |

### 核实事实（探索后）

- `VALID_TRANSITIONS` 当前 5 条，**不含 (deprecated, active)**
- `transition_status` 已带 `WHERE status = %s` 守卫，race-safe
- `cmd_activate` **不**改其他 release 的 status，仅 manifest.is_active —— **多 active 合法存在**（评审 R1#2 真问题）
- `cmd_revoke` cascade 模式：1 步 UPDATE
- `content_manifest.file_url` nullable（migration 004:84）
- `build-examples-package --book zk` 实际生成 `examples-zk.jsonl.gz`（**无 @v1 后缀**，评审 R2#1 真问题）
- `cmd_create_release / validate / activate / revoke` 业务错误返 **1**；唯 `cmd_deprecate` 返 2
- ContentManifestController（`content-manifest.controller.ts:162-168`）跳过 NULL file_url 行
- e2e helpers (`pg-regression.e2e-spec.ts:890-953`) `seedDraftRelease / seedManifest / transition` 可直接复用

## 实施

### Step 1：`content_release_repo.py` 扩展

#### 1a. VALID_TRANSITIONS 加一条

```python
VALID_TRANSITIONS = {
    ("draft", "validated"),
    ("validated", "active"),
    ("active", "deprecated"),
    ("active", "revoked"),
    ("deprecated", "revoked"),
    ("deprecated", "active"),  # PR-B1 Day 2: rollback 入口（**不加** revoked→active）
}
```

#### 1b. helper `rollback_release()`

```python
def rollback_release(conn, target_id: str, reason: str) -> None:
    """Reactivate a deprecated release; demote current active to deprecated.

    NOT commit'd — caller controls transaction (use `with conn:`).

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
      - count(content_release WHERE status='active') > 1
        (PR-A's cmd_activate doesn't demote prior actives' status,
         only their manifests; multi-active state is a latent bug
         that rollback refuses to silently pick a winner for)

    Returns None — caller doesn't need the side-effect IDs.
    """
```

实装关键：
- `get_release(conn, target_id)` 查 target，None 抛 ReleaseError
- 校验 `target["status"] == "deprecated"`
- `SELECT release_id, package_set FROM content_release WHERE status='active'`，
  count > 1 抛 ReleaseError(`"multiple active releases (count={n}); deprecate
  the unintended ones first then retry rollback"`)
- 取出 0 / 1 个 current_active：
  - 1 个：UPDATE manifests is_active=false → transition_status('deprecated', reason=f"rollback to {target_id}: {reason}")
  - 0 个：跳过 demote
- target promote：UPDATE manifests is_active=true → transition_status('active', reason=reason)
- 全部在 caller 的 with conn 下，单事务原子

### Step 2：`pipeline.py` 加 `cmd_rollback` + subparser

#### 2a. cmd_rollback（约 60 行）

```python
def cmd_rollback(args: argparse.Namespace) -> int:
    """PR-B1 Day 2 — rollback to a deprecated release."""
    conn = _connect_or_die()
    if conn is None:
        return 2  # connection error → 2

    rid = args.release_id
    reason = args.reason

    try:
        target = get_release(conn, rid)
        if target is None:
            raise ReleaseError(f"target release {rid!r} not found")
        if target["status"] != "deprecated":
            raise ReleaseError(
                f"rollback only allowed from 'deprecated', "
                f"got {target['status']!r} for {rid!r}"
            )

        # FS pre-check (R2#3: NULL file_url 拒绝)
        from gc_stale import _resolve_local_path
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, file_url FROM content_manifest WHERE id = ANY(%s)",
                (target["package_set"],),
            )
            for mid, url in cur.fetchall():
                if not url:
                    raise ReleaseError(
                        f"manifest {mid!r} has NULL file_url; rollback would activate "
                        f"a release whose package the API can't serve. Fix data or "
                        f"create a fresh release."
                    )
                if url.startswith("http://") or url.startswith("https://"):
                    continue  # real CDN: can't verify locally
                local = _resolve_local_path(url, Path.cwd())
                if local is None:
                    raise ReleaseError(
                        f"manifest {mid!r} has unresolvable file_url: {url!r}"
                    )
                if not local.exists():
                    raise ReleaseError(
                        f"manifest {mid!r} file missing on FS: {local} "
                        f"(possibly removed by gc-stale; rollback aborted)"
                    )

        if not args.yes:
            sys.stderr.write(
                f"About to rollback release {rid!r} (currently 'deprecated'):\n"
                f"  - target {rid!r} → 'active' (manifests is_active=true)\n"
                f"  - any current active release → 'deprecated' "
                f"(manifests is_active=false)\n"
                f"  reason: {reason}\n"
                f"Type 'y' to confirm: "
            )
            sys.stderr.flush()
            line = sys.stdin.readline().strip().lower()
            if line != "y":
                print("aborted", file=sys.stderr)
                return 1

        with conn:
            rollback_release(conn, rid, reason)

        print(f"  [OK] rollback to {rid!r}. reason: {reason}")
        return 0
    except ReleaseError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1   # business error → 1（与 PR-A create/validate/activate/revoke 对齐）
    finally:
        conn.close()
```

#### 2b. subparser

```python
p_rollback = sub.add_parser(
    "rollback",
    help="Rollback to a deprecated release (deprecated → active; "
         "current active → deprecated)",
)
p_rollback.add_argument("release_id")  # positional
p_rollback.add_argument("--reason", required=True,
                        help="Audit log reason (required for governance trail)")
p_rollback.add_argument("--yes", action="store_true",
                        help="Skip stdin confirmation (CI use)")
p_rollback.set_defaults(func=cmd_rollback)
```

文档头加：
```
rollback <release_id> --reason TXT     # PR-B1 Day 2 (deprecated → active)
```

### Step 3：e2e 8 cases

文件：`apps/api/test/pg-regression.e2e-spec.ts`

```typescript
describe('rollback subcommand contract (PR-B1 Day 2)', () => {
  // Note: cmd_rollback's FS file-existence pre-check is NOT covered by these
  // e2e cases — seed manifests use http://localhost:3000/cdn/... URLs which
  // the rollback FS check explicitly skips (real-CDN scheme). The FS missing
  // path is verified by the mandatory PowerShell smoke (Step 4) which
  // generates real files in audio-pipeline-staging/ and removes them.
  const TEST_PREFIX = 'test-rollback-';

  // ... cleanup + reuse seedDraftRelease/seedManifest/transition

  it('happy: deprecated v1 + active v2 → rollback v1 → v1 active, v2 deprecated', ...);
  it('rollback to draft target rejected', ...);
  it('rollback to validated target rejected', ...);
  it('rollback to revoked target rejected (P2 关键 case)', ...);
  it('rollback to active target rejected', ...);
  it('rollback when no active release exists: target promotes directly', ...);
  it('multiple active releases → ReleaseError sanity check (R1#2)', ...);
  it('chained rollback v1→v2→v3→rollback v2→rollback v1 健壮性', ...);
});
```

期望 e2e 总数：**36 (Day 1 baseline) + 8 = 44 通过**（pre-existing /me/today 1 个不阻塞）。

### Step 4：必跑 PowerShell smoke 11 步

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b1\apps\api
$env:PGPASSWORD="<your-local-password>"

# 1. build (产出 examples-zk.jsonl.gz, 无 @v1 后缀)
python scripts\content_pipeline\pipeline.py build-examples-package --book zk
Copy-Item audio-pipeline-staging\examples-zk.jsonl.gz audio-pipeline-staging\examples-zk@v1.jsonl.gz
Copy-Item audio-pipeline-staging\examples-zk.jsonl.gz audio-pipeline-staging\examples-zk@v2.jsonl.gz
Copy-Item audio-pipeline-staging\examples-zk.jsonl.gz audio-pipeline-staging\examples-zk@v3.jsonl.gz

# 2. v1 上 active
python scripts\content_pipeline\pipeline.py create-release zk-rollback-v1 --title "v1"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release zk-rollback-v1 --package-name examples-zk --package-kind examples `
  --content-version v1 --file audio-pipeline-staging\examples-zk@v1.jsonl.gz
python scripts\content_pipeline\pipeline.py validate zk-rollback-v1
python scripts\content_pipeline\pipeline.py activate zk-rollback-v1 --yes

# 3. v2 上 active（cascade 关 v1 manifests，但 v1.status 仍 active）
python scripts\content_pipeline\pipeline.py create-release zk-rollback-v2 --title "v2"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release zk-rollback-v2 --package-name examples-zk --package-kind examples `
  --content-version v2 --file audio-pipeline-staging\examples-zk@v2.jsonl.gz
python scripts\content_pipeline\pipeline.py validate zk-rollback-v2
python scripts\content_pipeline\pipeline.py activate zk-rollback-v2 --yes

# 4. multi-active sanity check
python scripts\content_pipeline\pipeline.py rollback zk-rollback-v1 --reason "test multi-active guard" --yes
# 期望: ReleaseError "multiple active releases (count=2)"，退出码 1

# 5. deprecate v1 解除 multi-active
python scripts\content_pipeline\pipeline.py deprecate zk-rollback-v1 --reason "manual demote" --yes

# 6. happy rollback v1
python scripts\content_pipeline\pipeline.py rollback zk-rollback-v1 --reason "v2 has critical bug" --yes
# 期望: [OK] rollback to 'zk-rollback-v1'

# 7. manifest API 反查现在返 v1
curl http://localhost:3000/api/v1/content/manifest

# 8. PG 反查 activation_log
psql -h localhost -U postgres -d meow_dev -c `
  "SELECT release_id, status, jsonb_array_length(activation_log) FROM content_release WHERE release_id LIKE 'zk-rollback-%';"

# 9. revoke v2 → rollback v2 拒绝
python scripts\content_pipeline\pipeline.py revoke zk-rollback-v2 --reason "test" --yes
python scripts\content_pipeline\pipeline.py rollback zk-rollback-v2 --reason "should fail" --yes
# 期望: ReleaseError "rollback only allowed from 'deprecated', got 'revoked'"，退出码 1

# 10. FS missing (独立 v3 fixture, 避开 status guard)
python scripts\content_pipeline\pipeline.py create-release zk-rollback-v3 --title "v3 FS missing test"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release zk-rollback-v3 --package-name examples-zk --package-kind examples `
  --content-version v3 --file audio-pipeline-staging\examples-zk@v3.jsonl.gz
python scripts\content_pipeline\pipeline.py validate zk-rollback-v3
python scripts\content_pipeline\pipeline.py activate zk-rollback-v3 --yes
# 此时 v1 active + v3 active 多 active —— 先 deprecate 双方
python scripts\content_pipeline\pipeline.py deprecate zk-rollback-v1 --reason "make way for v3 test" --yes
python scripts\content_pipeline\pipeline.py deprecate zk-rollback-v3 --reason "test FS missing" --yes
Remove-Item audio-pipeline-staging\examples-zk@v3.jsonl.gz
python scripts\content_pipeline\pipeline.py rollback zk-rollback-v3 --reason "should fail FS" --yes
# 期望: ReleaseError "manifest 'examples-zk@v3' file missing on FS"，退出码 1

# 11. cleanup
psql -h localhost -U postgres -d meow_dev -c `
  "DELETE FROM content_manifest WHERE release_id LIKE 'zk-rollback-%';
   DELETE FROM content_release WHERE release_id LIKE 'zk-rollback-%';"
Remove-Item audio-pipeline-staging\examples-zk@v1.jsonl.gz, audio-pipeline-staging\examples-zk@v2.jsonl.gz -ErrorAction SilentlyContinue
```

11 步全过 = Day 2 done。

## 关键文件

### 修改
- `apps/api/scripts/content_pipeline/content_release_repo.py`（+1 VALID_TRANSITIONS 条目 +1 helper，约 70 行）
- `apps/api/scripts/content_pipeline/pipeline.py`（+1 cmd +1 subparser，约 90 行）
- `apps/api/test/pg-regression.e2e-spec.ts`（+1 describe 块, +8 cases）

### 不动
- `orphan_scan.py`（Day 1 已稳定）
- `gc_stale.py`（仅 import `_resolve_local_path`）
- migration / README / mobile

## 验收清单

- [ ] `VALID_TRANSITIONS` 仅加 `("deprecated", "active")` 一条
- [ ] `rollback_release` 含 multi-active sanity check (count > 1 → ReleaseError)
- [ ] `rollback_release` docstring 注明 demote reason 前缀化
- [ ] `cmd_rollback` 拒绝 NULL file_url
- [ ] `cmd_rollback` 业务错误退出码 = 1
- [ ] `cmd_rollback` 不接 `--cdn-mock-dir` 参数
- [ ] `cmd_rollback` release_id 是 positional
- [ ] e2e **44/45 通过**
- [ ] PowerShell smoke 11 步全过

## 风险

| 风险 | 缓解 |
|---|---|
| 误加 `("revoked", "active")` 让 revoke 形同 deprecate | e2e 关键反例 case 卡死 |
| rollback target 文件已被 gc-stale 删除 | CLI 层 FS 校验拒绝 |
| state machine race | with conn 单事务 + transition_status WHERE status=%s 守卫 |
| multi-active 历史遗留 | sanity check 显式拒绝 |
| Day 2 工作量超 1.5 天 | helper ≤ 70 行 / cmd ≤ 90 行；预期 ≤ 6 小时 |

## 不做的事

- **不**改 schema
- **不**加 `("revoked", "active")` 转换
- **不**触碰 mobile / API controller / migration
- **不**把 NULL file_url 当合法
