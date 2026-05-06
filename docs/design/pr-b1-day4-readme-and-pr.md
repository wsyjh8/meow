# v0.3 PR-B1 · Day 4 — README 收尾 + PR 描述 + 数字校对 (v0.2)

## Context

PR-B1 收官日。Day 1 (`214b4e5`) / Day 2 (`68dff82`) / Day 3 (`6244d1f`) 三天代码全部合并，
功能闭环完成。Day 4 不写新功能，只做四件事：

1. README 同步——子命令表 + 状态机图 + troubleshooting 把新增 3 个子命令补全
2. master plan 数字校对——e2e 数字 49 → 47（评审 R1#10）+ rollback CLI 形态 + 验收清单 wording
3. PR 描述（沿用 PR-A 风格）写到 user dir 待用
4. **拆分**的 PR-B1 CLI smoke（4 个 sub-smoke：orphan / approver / gating / rollback rejections + env=false compat）

工作分支：`feat/v0.3-pr-b1-publish-side-completion` @ `6244d1f`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b1`

### 评审吸收（v0.1 → v0.2，两份外部评审 16 处改进）

| # | 来源 | 处置 |
|---|---|---|
| R1#1 | smoke rollback happy path 被 legacy active 卡住 | ✅ **拆 sub-smokes**；rollback happy 由 e2e Case 1 兜底，smoke 不重复覆盖 |
| R1#2 / R2#11 | orphan-scan 期望被 build 原产物污染 | ✅ step 1 后 `Remove-Item` 原 `examples-zk.jsonl.gz` |
| R1#3 | master plan rollback 旧 `--to` 形态未同步 | ✅ pr-b1.md 行 53-56 一并修 positional |
| R1#4 / R2#7 | 状态机图 approve 像状态转换 / ASCII 跑偏 | ✅ 拆两图：基础流（不画 approve 进入箭头）+ rollback 旁注图 |
| R2#1 | smoke step 9 v1/v2 log_length 互换 | ✅ 精确 `v1=5 / v2=4` |
| R2#2 | master plan §175 "e2e 覆盖" 与 Day 3 删 gating cases 矛盾 | ✅ 改"CLI smoke 覆盖" |
| R2#3 | smoke 漏 env=false 兼容路径（Day 3 核心承诺）| ✅ Sub-smoke C 加独立 fixture |
| R2#4 | "47/48" 分母无来源 | ✅ 改"47 cases，46 pass + 1 pre-existing /me/today drift" |
| R2#5 | 子命令表抹掉 PR-A Day 5 ⭐ 标记 | ✅ 保留 deprecate / list-releases 的 `⭐ Day 5` |
| R2#6 | approve 位置暗示流程必经 | ✅ 描述列加"**仅 env=true 时为 activate 前置；默认可跳过**" |
| R2#8 | "Day 3: 12 处" 虚指 | ✅ 列 `R1#1-R1#12 + R2#3 R2#4` 具体清单 |
| R2#9 | `rollback_target_id` PR-C/PR-D 与 scope 不对应 | ✅ 改"PR-B3 启用（与审批 UI 一起）/ v0.3.x 后视决议" |
| R2#10 | PR_DESCRIPTION 文件名指代不清 | ✅ §3 顶部明示两份独立路径 |
| R2#12 | 行号 "11-23" 实际 13-23 | ✅ 改"章节内"描述 |

### 核实事实（探索后）

- README 现状：476 行 / 9 子命令表 / 5 troubleshooting
- 当前 README `deprecate` 行 20 / `list-releases` 行 22 含 `⭐ Day 5` 标记，必须保留
- `Subcommand reference` 章节起 `## ` 在行 11，表头在行 13，表内容 13-23
- master plan e2e 数字：行 117 / 131 / 175 / 177 共 4 处需改（不是 v0.1 列的 3 处）
- master plan rollback CLI 形态：pr-b1.md 行 53-56 仍写 `("revoked", "active")` 已修但 §39-44 文字仍说 deprecated/revoked → active
- `rollback_target_id` 字段 PR-A migration 007:66 留位，**0 处代码使用**
- e2e 实跑 47 cases（34+2+8+3），1 个 /me/today drift pre-existing
- legacy-pre-v0.3-pr-a release 永久 `status='active'`，所有 smoke 在 PR-B1 worktree 跑必然 multi-active 并存

## 实施

### Step 1：README 同步（约 60 行新增）

文件：`apps/api/scripts/content_pipeline/README.md`

#### 1a. 子命令参考表 9 → 12（替换 `## Subcommand reference` 章节内的现有表，行 13-23）

加 3 行，**保留** PR-A Day 5 的 ⭐ 标记，**注明 approve 为可选**：

```markdown
| 子命令 | 阶段 | 写? | 描述 |
|---|---|---|---|
| `build-examples-package` | 准备 | 写 FS | 生成 examples-{book} package + checksum |
| `create-release` | 治理 | 写 PG | INSERT content_release status='draft' |
| `publish-manifest` | 治理 | 写 PG | UPSERT content_manifest 关联 release（仅 draft）|
| `validate` | 治理 | 写 PG | draft → validated（强制 package_set ↔ manifest.release_id 对齐）|
| `approve` ⭐ B1 Day 3 | 治理 | 写 PG | 写 approved_by + audit log（**仅 env CONTENT_RELEASE_REQUIRE_APPROVAL=true 时为 activate 前置；默认可跳过**） |
| `activate` | 治理 | 写 PG | validated → active + cascade 旧 manifest is_active；env truthy 时校验 approved_by |
| `deprecate` ⭐ Day 5 | 治理 | 写 PG | active → deprecated（软下线，不动 manifest.is_active）|
| `rollback` ⭐ B1 Day 2 | 治理 | 写 PG | deprecated → active（同时把当前 active demote 回 deprecated；revoked 不可恢复）|
| `revoke` | 治理 | 写 PG | active/deprecated → revoked（硬撤回，cascade is_active=false，不可逆）|
| `list-releases` ⭐ Day 5 | 可视化 | 只读 | 表格输出 release 列表 |
| `gc-stale` | 运维 | 写 PG + FS | PG 状态机驱动 GC（cdn-mock 范围）|
| `orphan-scan` ⭐ B1 Day 1 | 运维 | 写 FS | FS 物理孤儿扫描（cdn-mock + audio-pipeline-staging 双根）|
```

#### 1b. 状态机图——拆两图（R1#4 / R2#7）

##### 图 1：基础 release lifecycle（approve 是旁注，不画进入箭头）

```
   create-release
        │
        ▼
     [draft]
        │ validate
        ▼
   [validated]            ←── (approve 写 approved_by 字段；非状态转换)
        │
        │ activate (env CONTENT_RELEASE_REQUIRE_APPROVAL truthy 时校验 approved_by)
        │ + cascade 同 package_name 旧 manifest is_active=false
        ▼
     [active]
        │
        ├─── deprecate ──▶ [deprecated]
        │                       │
        │                       │ revoke
        │ revoke                ▼
        ▼                   [revoked]
    [revoked]
```

##### 图 2：rollback 单独画（强调反向 + 不可恢复）

```
                           rollback
   [deprecated] ──────────────────────────▶ [active]   ✅ 唯一允许
        ▲                                        │
        │ (同时 demote 当前 active)              │
        └────────────────────────────────────────┘

   [revoked] ─────╳─────▶ [active]   ❌ 永远不允许（revoke 是不可逆硬撤回）
```

注：
- approve 不是状态转换，仅写 `approved_by` 字段 + audit log entry（form `from=to=validated`）
- rollback 仅 deprecated → active；revoked 永远不能恢复（操作员要恢复需 `create-release` 起新 release）

audio_assets GC 状态机图保持不变（PR-A 已稳定）。orphan-scan 加一行说明：

> `orphan-scan` 与 `gc-stale` 互补：gc-stale 由 PG 状态机驱动（PG 有行 + status='eligible_for_gc' → 删 FS），
> orphan-scan 由 FS 驱动（FS 有文件 + PG 无引用 → 删 FS）。两者目录不同：
> gc-stale 仅扫 cdn-mock；orphan-scan 同时扫 cdn-mock 和 audio-pipeline-staging。

#### 1c. Troubleshooting +3 条 = 8 条

在现有 5 条之后加：

```markdown
### activate 报 "activate requires prior approval (env CONTENT_RELEASE_REQUIRE_APPROVAL is set)"
含义：环境变量 `CONTENT_RELEASE_REQUIRE_APPROVAL` 为 truthy（true/1/yes/on，大小写不敏感、空格容忍），
但 release 的 `approved_by` 字段为空。
处置：先 `pipeline.py approve <release_id> --approver <id>` 写入 approver，再 activate。
临时关闭审批（不推荐）：`unset CONTENT_RELEASE_REQUIRE_APPROVAL` 或设为 false。

### approve 报 "approver must be non-empty / non-whitespace"
含义：CLI 收到 `--approver ""` 或 `"   "`（纯空格）。
处置：传非空字符串，长度 ≤ 64（与 schema VARCHAR(64) 对齐）。

### rollback 报 "manifest ... file missing on FS"
含义：rollback target release 的某个 manifest 文件已被 gc-stale 或手动删除。
处置：要么找回文件（从备份），要么放弃此次 rollback，用 `create-release` 起新 release 重发布。
**不要**手动 INSERT 假文件——content_hash 校验在 manifest API 路径里依赖文件真实性。
```

#### 1d. PR-B1 已实装章节（README 末尾加）

```markdown
## v0.3 PR-B1 实装总览

PR-B1 "发布侧补全" 4 天交付，基于 PR-A 已建立的 release 状态机基座扩展：

| Day | 子命令 / 改动 | 影响 |
|---|---|---|
| 1 | `orphan-scan` | 双根 FS 扫描（cdn-mock + audio-pipeline-staging）+ 白名单 4 条防误删 |
| 2 | `rollback` | 状态机加 deprecated → active 一条；不允许 revoked → active |
| 3 | `approve` + activate gating | 治理审批（默认 false 向后兼容；approved_by 字段已在 PR-A 留位） |
| 4 | README + PR 描述 + smoke | 文档收尾 + 拆分 sub-smoke 验证 |

详见 `docs/design/v0.3_PR-B_scope_v0.1.md` / `docs/design/pr-b1.md` /
`docs/design/pr-b1-day{1,2,3,4}-*.md`。
```

### Step 2：master plan (pr-b1.md) 全面校对

文件：`docs/design/pr-b1.md`

修订点（共 5 处，比 v0.1 多 2 处）：

1. 行 117：`Day1(2) + Day2(8) + Day3(5) = 49` → `Day1(2) + Day2(8) + Day3(3) = 47`
2. 行 131：`+15 cases: Day1=2 / Day2=8 / Day3=5` → `+13 cases: Day1=2 / Day2=8 / Day3=3`
3. 行 175：`activate gating 双路径（env on/off）e2e 覆盖` → `activate gating 双路径（env on/off）**CLI smoke 覆盖**`（R2#2，与 Day 3 删 gating cases 一致）
4. 行 177：`e2e 49/50 通过` → `e2e 47 cases，46 pass + 1 pre-existing /me/today drift`（R2#4）
5. **行 53-56 区域** rollback CLI 形态如有 `--to` 残留同步改 positional（R1#3）

加修订标记 v0.2 → v0.3："评审吸收 R1#10 / R2#2 / R2#4 / R1#3：Day 3 e2e 收紧到 3 + smoke 覆盖 gating + 数字精确化 + CLI 形态统一"

### Step 3：PR 描述（user dir，git 视野外）

**文件名约定**（R2#10）：
- PR-A 的 PR 描述：`C:\Users\lenovo\.claude\PR_DESCRIPTION.md`（已存在）
- PR-B1 的 PR 描述：`C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-B1.md`（本次新建）
- 两份独立保留，不互相覆盖

PR 描述沿用 PR-A 11 章风格，重点章节：

#### 3a. 目标

> PR-B1 "发布侧补全" 4 天 server 端工作，把 PR-A 留下的状态机所有合法路径都补上 CLI 入口、
> 把所有运维场景都补上工具支持。**不动 mobile，不接真 CDN，不做 Web UI**——
> 留给 PR-B2 / PR-B3。

#### 3b. 4 天交付（表格）

| Day | 提交 | 内容 |
|---|---|---|
| 1 | `214b4e5` | orphan-scan 子命令（双根 FS 扫描 + 白名单）+ PR-B 设计文档 |
| 2 | `68dff82` | rollback 子命令（deprecated → active；含 multi-active sanity check）|
| 3 | `6244d1f` | approve 子命令 + activate 审批 gating（env=CONTENT_RELEASE_REQUIRE_APPROVAL）|
| 4 | (本 PR) | README 同步 / PR 描述 / sub-smoke 验证 |

#### 3c. 核心契约扩展

```
状态机扩展（PR-B1）：
  [deprecated] ── rollback ──▶ [active]   (新加；同时 demote current active → deprecated)
  approve gates activate when env CONTENT_RELEASE_REQUIRE_APPROVAL is truthy

PR-A 既有契约不破坏：
  - dual-condition manifest API ✓
  - publish-manifest draft-only ✓
  - canonical_json content_hash ✓
  - repo helpers 不调 conn.commit/rollback ✓
```

#### 3d. 测试

- e2e: **47 cases**（PR-A 34 + Day1=2 + Day2=8 + Day3=3），46 pass + 1 pre-existing /me/today drift
- CLI smoke: 4 sub-smokes（orphan-scan / approver 校验 / activate gating env true+false / rollback rejection paths）
- 不在 smoke 测的：rollback happy path（被 legacy-pre-v0.3-pr-a 永久 active 卡住，由 e2e Day 2 Case 1 覆盖）

#### 3e. 范围外（PR-B 拆分明示）

- PR-B2: App 端 manifest 消费（download manager / cache invalidation）
- PR-B3: 真 CDN 接入 + 审批 Web UI（待买服务器或多人协作触发）
- 永远不做：multi-approver 双签 / RBAC（独立开发者无需）

#### 3f. PR-A 留下的字段未启用（评审 R1#11，更新为 R2#9 修正去向）

> `content_release.rollback_target_id VARCHAR(64) REFERENCES content_release(release_id)`
> 字段在 PR-A migration 007:66 留位但 PR-B1 **不使用**——本次 rollback 信息全部
> 走 `activation_log` JSONB（按 reason 字符串前缀识别）。
>
> **未来决议**（修正 v0.3_PR-B_scope §5 PR-C/D 不对应问题）：
> - **PR-B3 启用**：与审批 Web UI 一起做（"governance 完整化"主题），rollback_release helper 同时写 `rollback_target_id` 便于 SQL 直查 + UI 展示
> - **v0.3.x 后视决议**：如审批 UI 决定不需此字段，迁移删除
> - **现阶段保留**：兼容未来选择，不阻塞 PR-B1 合并

#### 3g. 评审改进吸收（精确清单，R2#8）

PR-B1 共吸收 4 份外部评审：
- Day 1: 4 处（R1 R2 各 2 条，详 `pr-b1-day1.md` 评审表）
- Day 2: 15 处（R1#1-R1#15 + R2#1-R2#5，详 `pr-b1-day2-rollback.md`）
- Day 3: 12 处（R1#1-R1#12 + R2#1-R2#4，详 `pr-b1-day3-approve.md`）
- Day 4: 16 处（R1 4 条 + R2 12 条，详 `pr-b1-day4-readme-and-pr.md`）

#### 3h. 文档

- `docs/design/v0.3_PR-B_scope_v0.1.md` — PR-B1+B2+B3 整体范围
- `docs/design/pr-b1.md` — PR-B1 4 天工作分解
- `docs/design/pr-b1-day{1,2,3,4}-*.md` — 每日详细 plan

#### 3i. 关键文件

**新建**：
- `apps/api/scripts/content_pipeline/orphan_scan.py`
- `docs/design/v0.3_PR-B_scope_v0.1.md` / `pr-b1.md` / `pr-b1-day{1,2,3,4}-*.md`

**修改**：
- `apps/api/scripts/content_pipeline/pipeline.py`（+3 子命令 + activate gating）
- `apps/api/scripts/content_pipeline/content_release_repo.py`（+1 VALID_TRANSITIONS + 2 helpers）
- `apps/api/scripts/content_pipeline/README.md`（子命令表 / 状态机图 / troubleshooting / 总览）
- `apps/api/test/pg-regression.e2e-spec.ts`（+13 cases）

### Step 4：拆分的 PR-B1 CLI smoke（4 个 sub-smoke + 1 cleanup）

**关键设计变更**（R1#1 fix）：原 11 步串行 smoke 因 legacy-pre-v0.3-pr-a 永久 active 而导致
rollback happy path 必然撞 multi-active sanity check。重构为 4 个独立 sub-smoke，每个测一个
关注点；rollback happy path 由 e2e Day 2 Case 1 兜底覆盖（已通过）。

#### Sub-smoke 准备（共用）

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b1\apps\api
$env:PGPASSWORD="<your-local-password>"

# build 一次，立刻删原产物（R1#2 / R2#11）+ 复制出多版本 fixture
python scripts\content_pipeline\pipeline.py build-examples-package --book zk
Copy-Item audio-pipeline-staging\examples-zk.jsonl.gz audio-pipeline-staging\examples-zk@v1.jsonl.gz
Copy-Item audio-pipeline-staging\examples-zk.jsonl.gz audio-pipeline-staging\examples-zk@v2.jsonl.gz
Copy-Item audio-pipeline-staging\examples-zk.jsonl.gz audio-pipeline-staging\examples-zk@v3.jsonl.gz
Remove-Item audio-pipeline-staging\examples-zk.jsonl.gz   # ← 关键：避免变 orphan
```

#### Sub-smoke A：orphan-scan（验证 dry/clean + 白名单）

```powershell
# A.1 fresh state, expect 0/0
python scripts\content_pipeline\pipeline.py orphan-scan
# 期望: audio_orphans=0, pkg_orphans=0

# A.2 制造 package orphan
$pkgOrphan = "audio-pipeline-staging\examples-test-orphan@v999.jsonl.gz"
[System.IO.File]::WriteAllBytes($pkgOrphan, [byte[]](0x1F,0x8B,0x08,0x00))
python scripts\content_pipeline\pipeline.py orphan-scan
# 期望: pkg_orphans=1，列出 examples-test-orphan@v999.jsonl.gz

# A.3 clean
python scripts\content_pipeline\pipeline.py orphan-scan --clean
Test-Path $pkgOrphan
# 期望: False
```

#### Sub-smoke B：approver 校验（empty / whitespace / 长度）

```powershell
# B.1 setup validated release
psql -h localhost -U postgres -d meow_dev -c `
  "INSERT INTO content_release (release_id, status, package_set, generated_by) VALUES ('pr-b1-smoke-approver', 'validated', '[]'::jsonb, 'smoke');"

# B.2 empty / whitespace 拒绝
python scripts\content_pipeline\pipeline.py approve pr-b1-smoke-approver --approver ""
# 期望: ReleaseError "approver must be non-empty / non-whitespace"，rc=1

python scripts\content_pipeline\pipeline.py approve pr-b1-smoke-approver --approver "   "
# 期望: 同上，rc=1

# B.3 长度超限拒绝（VARCHAR(64) 边界）
$long = "a" * 65
python scripts\content_pipeline\pipeline.py approve pr-b1-smoke-approver --approver $long
# 期望: ReleaseError "approver too long (65 > 64)"，rc=1

# B.4 合法 approve
python scripts\content_pipeline\pipeline.py approve pr-b1-smoke-approver `
  --approver wsyjh8 --note "smoke B"
# 期望: [OK] approved by 'wsyjh8'

# B.5 cleanup
psql -h localhost -U postgres -d meow_dev -c `
  "DELETE FROM content_release WHERE release_id='pr-b1-smoke-approver';"
```

#### Sub-smoke C：activate gating 双路径（env=true 拒绝/通过 + env=false 兼容，R2#3 fix）

```powershell
# C.1 准备：完整 publish + validate（不 approve）
python scripts\content_pipeline\pipeline.py create-release pr-b1-smoke-gate --title "gate"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release pr-b1-smoke-gate --package-name examples-zk --package-kind examples `
  --content-version v1 --file audio-pipeline-staging\examples-zk@v1.jsonl.gz
python scripts\content_pipeline\pipeline.py validate pr-b1-smoke-gate

# C.2 env=true → activate 拒绝
$env:CONTENT_RELEASE_REQUIRE_APPROVAL="true"
python scripts\content_pipeline\pipeline.py activate pr-b1-smoke-gate
# 期望: ReleaseError "activate requires prior approval (env ... is set)"，rc=1

# C.3 approve → activate 通过
python scripts\content_pipeline\pipeline.py approve pr-b1-smoke-gate --approver wsyjh8
python scripts\content_pipeline\pipeline.py activate pr-b1-smoke-gate
# 期望: [OK] activated

# C.4 env=false (unset) + 新 fixture 不 approve + activate 通过（PR-A 兼容路径，R2#3 关键）
Remove-Item Env:\CONTENT_RELEASE_REQUIRE_APPROVAL
python scripts\content_pipeline\pipeline.py create-release pr-b1-smoke-compat --title "compat"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release pr-b1-smoke-compat --package-name examples-zk-compat --package-kind examples `
  --content-version v1 --file audio-pipeline-staging\examples-zk@v2.jsonl.gz
python scripts\content_pipeline\pipeline.py validate pr-b1-smoke-compat
python scripts\content_pipeline\pipeline.py activate pr-b1-smoke-compat
# 期望: [OK] activated（无 approve 也通过；PR-A 操作员零迁移）

psql -h localhost -U postgres -d meow_dev -c `
  "SELECT release_id, status, approved_by FROM content_release WHERE release_id LIKE 'pr-b1-smoke-%' ORDER BY release_id;"
# 期望:
#   pr-b1-smoke-compat | active | NULL    ← env=false 通过，approved_by 留空
#   pr-b1-smoke-gate   | active | wsyjh8

# C.5 cleanup
python scripts\content_pipeline\pipeline.py revoke pr-b1-smoke-gate --reason "smoke C done"
python scripts\content_pipeline\pipeline.py revoke pr-b1-smoke-compat --reason "smoke C done"
psql -h localhost -U postgres -d meow_dev -c `
  "DELETE FROM content_manifest WHERE release_id LIKE 'pr-b1-smoke-%';
   DELETE FROM content_release WHERE release_id LIKE 'pr-b1-smoke-%';"
```

#### Sub-smoke D：rollback rejection paths（status guard / multi-active / FS missing）

> rollback happy path 由 e2e Day 2 Case 1 覆盖；smoke 仅测 3 种拒绝路径。

```powershell
# D.1 setup: deprecated v3 + (legacy + 新 active = 2 actives)
python scripts\content_pipeline\pipeline.py create-release pr-b1-smoke-rb-target --title "rb target"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release pr-b1-smoke-rb-target --package-name examples-zk-rb --package-kind examples `
  --content-version v3 --file audio-pipeline-staging\examples-zk@v3.jsonl.gz
python scripts\content_pipeline\pipeline.py validate pr-b1-smoke-rb-target
python scripts\content_pipeline\pipeline.py activate pr-b1-smoke-rb-target
python scripts\content_pipeline\pipeline.py deprecate pr-b1-smoke-rb-target --reason "for smoke" --yes

# D.2 status guard: rollback 到 draft 拒绝
psql -h localhost -U postgres -d meow_dev -c `
  "INSERT INTO content_release (release_id, status, package_set, generated_by) VALUES ('pr-b1-smoke-rb-draft', 'draft', '[]'::jsonb, 'smoke');"
python scripts\content_pipeline\pipeline.py rollback pr-b1-smoke-rb-draft --reason "should fail" --yes
# 期望: ReleaseError "rollback only allowed from 'deprecated', got 'draft'"，rc=1

# D.3 status guard: rollback 到 revoked 拒绝（P2 关键 case）
psql -h localhost -U postgres -d meow_dev -c `
  "INSERT INTO content_release (release_id, status, package_set, generated_by, revoked_at) VALUES ('pr-b1-smoke-rb-revoked', 'revoked', '[]'::jsonb, 'smoke', NOW());"
python scripts\content_pipeline\pipeline.py rollback pr-b1-smoke-rb-revoked --reason "should fail" --yes
# 期望: ReleaseError "rollback only allowed from 'deprecated', got 'revoked'"，rc=1

# D.4 multi-active sanity（legacy + 故意造一个 active = 2）
psql -h localhost -U postgres -d meow_dev -c `
  "INSERT INTO content_release (release_id, status, package_set, generated_by, activated_at) VALUES ('pr-b1-smoke-rb-second-active', 'active', '[]'::jsonb, 'smoke', NOW());"
python scripts\content_pipeline\pipeline.py rollback pr-b1-smoke-rb-target --reason "test multi-active" --yes
# 期望: ReleaseError "multiple active releases (count=2: 'legacy-pre-v0.3-pr-a', 'pr-b1-smoke-rb-second-active')"，rc=1

# D.5 FS missing：把 target 文件删掉再 rollback
# 先解除 multi-active（删一个 active）
psql -h localhost -U postgres -d meow_dev -c `
  "DELETE FROM content_release WHERE release_id='pr-b1-smoke-rb-second-active';"
Remove-Item audio-pipeline-staging\examples-zk@v3.jsonl.gz
python scripts\content_pipeline\pipeline.py rollback pr-b1-smoke-rb-target --reason "test FS missing" --yes
# 期望: ReleaseError "manifest 'examples-zk-rb@v3' file missing on FS"，rc=1
# (注意：legacy 仍 active 但 multi-active sanity 在 FS pre-check 之后才触发，
#  这里 FS pre-check 先 fire；如果实装顺序反了这个 case 会暴露)

# D.6 cleanup
psql -h localhost -U postgres -d meow_dev -c `
  "DELETE FROM content_manifest WHERE release_id LIKE 'pr-b1-smoke-rb%';
   DELETE FROM content_release WHERE release_id LIKE 'pr-b1-smoke-rb%';"
Copy-Item audio-pipeline-staging\examples-zk@v1.jsonl.gz audio-pipeline-staging\examples-zk@v3.jsonl.gz  # 恢复供后续
```

#### Sub-smoke 收尾 cleanup（R2#11 完整版）

```powershell
Remove-Item audio-pipeline-staging\examples-zk.jsonl.gz `
            audio-pipeline-staging\examples-zk@v1.jsonl.gz `
            audio-pipeline-staging\examples-zk@v2.jsonl.gz `
            audio-pipeline-staging\examples-zk@v3.jsonl.gz `
            -ErrorAction SilentlyContinue
# 期望: 所有 build / copy 产物清干净
```

**4 个 sub-smoke 全过 + cleanup 干净 = PR-B1 真正闭环**。

## 关键文件

### 新建
- `C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-B1.md`（user dir，git 视野外，与 PR-A 的 `PR_DESCRIPTION.md` 并存）
- `docs/design/pr-b1-day4-readme-and-pr.md`（本文 v0.2）

### 修改
- `apps/api/scripts/content_pipeline/README.md`（+3 子命令表行 + 双状态机图 + 3 troubleshooting + PR-B1 总览，约 70 新行）
- `docs/design/pr-b1.md`（5 处修订：4 处 e2e 数字 + 1 处 rollback CLI 形态）

### 不动
- 任何 Python / TypeScript 代码（Day 4 不写新功能）
- migration / mobile / API controller

## 验收清单

- [ ] README 子命令表 9 → 12，⭐ Day 5 标记保留 + approve 行加可选注（R2#5 / R2#6）
- [ ] README 状态机图拆两图（基础流 + rollback 旁注），不画 approve 进入箭头（R1#4 / R2#7）
- [ ] README troubleshooting 5 → 8（gating env / approver 校验 / rollback FS missing）
- [ ] README 末加 PR-B1 总览章节
- [ ] master plan (pr-b1.md) 5 处修订（行 117 / 131 / 175 / 177 + rollback CLI 形态）
- [ ] `PR_DESCRIPTION_PR-B1.md` 写到 user dir，含 11 章 + rollback_target_id PR-B3 决议（R2#9）
- [ ] PowerShell sub-smoke A/B/C/D 全过（不串行，互独立）
- [ ] e2e **47 cases，46 pass + 1 pre-existing /me/today drift**（R2#4 精确写法）
- [ ] flutter analyze 可选兜底（不动 mobile）
- [ ] git log 4 个 PR-B1 commits 完整（Day1+2+3+4 各一）

## 风险

| 风险 | 缓解 |
|---|---|
| README 状态机图 ASCII 渲染不直观（R2#7）| 拆两图 + 文字说明所有箭头；mermaid 升级留 PR-C |
| sub-smoke 跨机器结果飘移（cdn-mock 环境差异）| 各 sub-smoke 独立 fixture + 完整 cleanup；不依赖前一 smoke 状态 |
| PR_DESCRIPTION 误入 repo | user dir `.claude\` 在 git 视野外（沿用 PR-A 已验证模式）|
| `rollback_target_id` 决议拖延（R2#9）| PR 描述明示 PR-B3 启用 / v0.3.x 后视，不阻塞 PR-B1 |
| Day 4 工作量超 1 天 | README ≤ 70 行 + PR 描述模板复用 + 4 sub-smoke 各 ≤ 5 步；预期 ≤ 5 小时 |
| sub-smoke D.5 触发顺序假设（FS pre-check vs multi-active）| Day 2 实装实际是 FS pre-check 在 helper 进入前，multi-active 在 helper 内部第一步——不同函数层级，不会错位 |

## 不做的事

- **不**写新代码（Day 4 仅文档 + 验证）
- **不**改 schema（rollback_target_id 决议留 PR-B3）
- **不**触碰 mobile / API controller / migration
- **不**改 e2e 测试
- **不**做 mermaid 图升级（留 PR-C 美化时再做）
- **不**自己开 PR（最后一步是 push 后用户手动开 PR via GitHub web UI）
- **不**在 smoke 测 rollback happy path（被 legacy active 卡住，由 e2e Day 2 Case 1 兜底）
