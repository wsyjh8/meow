# v0.3 PR-B1 · 发布侧补全（4 天工作分解）

## Context

PR-A 已 merge（main @ `b072eb3`）。PR-B 范围已写到
`docs/design/v0.3_PR-B_scope_v0.1.md`（在 PR-B1 worktree 内，本 PR-B1 PR 一起提）。

PR-B1 = "发布侧补全"，**server only**，让 PR-A 留下的状态机所有合法路径都有
CLI 入口、所有运维场景都有工具支持。

工作分支：`feat/v0.3-pr-b1-publish-side-completion`
工作 worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b1`

### 三个交付物（详见 design doc §1.2）

1. **`orphan-scan` 子命令** —— FS 物理孤儿扫描（与 gc-stale 反向：FS 驱动）
2. **`rollback` 子命令** —— `deprecated → active` reactivate（**只允许从 deprecated 恢复**）
3. **审批工作流 CLI** —— `approve` 子命令 + activate gating + env 开关

### 边界（明示延后）

- 审批 Web UI → PR-B3
- App 端消费 manifest → PR-B2（独立 PR）
- 真 CDN → PR-B3
- 多签 / RBAC → 永远不做（独立开发者）
- `revoked → active` rollback → **永远不允许**（revoke 是硬撤回；要恢复就起新 release）

## 4 天工作分解

### Day 1：`orphan-scan` 子命令（1 天）

**目标**：扫两个 FS 根目录（cdn-mock + audio-pipeline-staging）找 PG 没指向的孤儿，可 dry-run / 可删。

**两个扫描根目录**（评审采纳 P1 修正）：

| 类别 | FS 根 | 对应 PG 字段 |
|---|---|---|
| audio orphan | `apps/api/cdn-mock/` | `audio_assets.url`（**不是 file_path**） |
| package orphan | `apps/api/audio-pipeline-staging/` | `content_manifest.file_url` |

主要工作：
- 新文件 `apps/api/scripts/content_pipeline/orphan_scan.py`
- pipeline.py 加 `cmd_orphan_scan` + subparser
- 扫描算法：
  1. 各自 `os.walk` 拿全部物理文件路径
  2. SELECT `audio_assets.url` + `content_manifest.file_url`
     用 `gc_stale._resolve_local_path` 转成绝对路径（复用，避免 SSOT 漂）
  3. 跳过 url scheme=http(s):// 类（真 CDN 无本地对应）
  4. 跳过 audio_assets.status='deleted' 行（gc-stale 已删，不应被视作引用）
  5. set 差：FS - PG_referenced = 孤儿候选
  6. 白名单过滤（只删 root 子树内、特定后缀、非 symlink、非隐藏文件）
- `--dry-run`（默认）/ `--clean`（互斥）/ `--scope {audio|packages|all}`
- e2e + smoke：覆盖 audio + package 两类孤儿（评审采纳 P1）

详细 plan：`pr-b1-day1.md`。

### Day 2：`rollback` 子命令（1.5 天）

**目标**：active release 出问题 → reactivate 上一个 deprecated 版本。

主要工作：
- `content_release_repo.py` 扩展 `VALID_TRANSITIONS`（**只加一条**）：
  ```python
  ("deprecated", "active"),  # rollback 入口（评审采纳 P2：不加 revoked → active）
  ```
- 新 helper `rollback_release(conn, target_id, reason)`：
  1. 校验 target 状态 == `deprecated`（拒绝 revoked / draft / validated / active）
  2. 校验 target.package_set 中所有 manifest 的 file_url 文件存在（防 gc 过的）
  3. 当前 active release（如有）→ `deprecated` + cascade is_active=false
  4. target → `active` + cascade is_active=true
  5. 写双方 activation_log
  6. 整个 with conn: 包事务
- `pipeline.py rollback <release_id> --reason TXT [--yes]` (positional, 与 validate/activate/revoke/deprecate 一致)
- e2e（6+ cases）：
  - 完整 rollback 链：active(v2) + deprecated(v1) → rollback v1 → v2 deprecated, v1 active → API 反查
  - rollback 到 draft 拒绝
  - rollback 到 validated 拒绝
  - **rollback 到 revoked 拒绝**（评审采纳 P2 关键 case）
  - rollback target 文件丢失拒绝
  - 无 active 时 rollback（target 直接 active 不需要前置 deprecate）

### Day 3：审批工作流 CLI（1 天）

**目标**：validated → active 之间加可选 `approved_by` 必填关卡。

主要工作：
- `content_release_repo.py` 新 helper `approve_release(conn, release_id, approver, note)`
  - 校验 status='validated'
  - UPDATE approved_by + activation_log push entry `{approve, by, note}`
- `pipeline.py approve <release_id> --approver <id> [--note TXT]`
- `pipeline.py activate` 加 gating：
  - 读 env `CONTENT_RELEASE_REQUIRE_APPROVAL`（默认 false 兼容 PR-A）
  - 若 true + approved_by IS NULL → 拒绝 + 提示先 approve
- e2e（5 cases）：
  - approve happy path
  - activate without approve when env=true 拒绝
  - activate without approve when env=false 通过（向后兼容）
  - activate after approve when env=true 通过
  - approve 在非 validated 状态拒绝

### Day 4：README + smoke + PR 描述（1 天）

**目标**：文档收尾 + 端到端 CLI smoke + PR 提交。

主要工作：
- README 更新：
  - 子命令参考表 9 → 12（加 orphan-scan / rollback / approve）
  - 状态机图加 rollback 单向箭头（**仅 deprecated → active**）
  - troubleshooting 加 3 条新 entry
  - "PR-B1 已实装" 章节
- 端到端 CLI smoke（PowerShell 命令清单）：
  - 完整流程：build → create → publish → validate → approve → activate → deprecate → rollback → API 反查
  - orphan-scan dry-run + clean 验证（audio + package 两类）
- PR_DESCRIPTION.md 写到 `C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-B1.md`
- 总 commit + push

期望 e2e 总数：34 (PR-A baseline) + Day1(2) + Day2(8) + Day3(3) = **47 cases**（v0.3 评审采纳 R1#10 修正：Day 3 e2e 从 +5 收紧到 +3，gating 由 CLI smoke 兜底）。

## 关键文件

### 新建（B1 内）
- `apps/api/scripts/content_pipeline/orphan_scan.py`
- `docs/design/v0.3_PR-B_scope_v0.1.md` ✅ 已就绪
- `docs/design/pr-b1.md` 本文档（执行 SSOT）
- `docs/design/pr-b1-day1.md`（Day 1 详细 plan）

### 修改（B1 内）
- `apps/api/scripts/content_pipeline/pipeline.py` (+3 子命令)
- `apps/api/scripts/content_pipeline/content_release_repo.py` (+1 VALID_TRANSITIONS 条目 / +2 helper)
- `apps/api/scripts/content_pipeline/README.md` (子命令表 / 状态机图 / troubleshooting)
- `apps/api/test/pg-regression.e2e-spec.ts` (+13 cases: Day1=2 / Day2=8 / Day3=3)

### 不动
- `apps/api/src/controllers/content-manifest.controller.ts`（PR-A 已稳定）
- `gc_stale.py`（PR-A 已稳定，仅消费其 `_resolve_local_path`）
- migration 007（不再改 schema —— approved_by 字段已存在）
- 任何 mobile 代码

## 风险

| 风险 | 缓解 |
|---|---|
| rollback 状态机扩展破坏 PR-A 既有 VALID_TRANSITIONS | 仅加 1 条转换；e2e 覆盖原有所有路径 |
| orphan-scan 误删两根之外文件 | 白名单 `path.relative_to(root.resolve())` + dry-run 默认 |
| audio-pipeline-staging 里 in-flight build 文件被误判孤儿 | 文档化：orphan-scan 仅在"无 build 在跑时"运行 |
| 审批开关默认 false 让人忘开 | README + commit message + Day 4 smoke 显式提示 |
| Day 2 rollback 跨多文件改动复杂 | 先写 helper + 单测，再接 CLI；ensure 单事务 |
| 4 天预算超 | Day 4 README + smoke 砍重做（用 Day 3 写完即停，PR 描述事后补） |

## 评审吸收（v0.1 → v0.2）

| # | 评审建议 | 处置 |
|---|---|---|
| P1 | orphan-scan 表述只扫 cdn-mock 错误 | ✅ 拆两根，更新 §1.2.1 + Day 1 算法 + smoke |
| P1 | pr-b1.md 写 audio_assets.file_path 字段名错 | ✅ 改为 audio_assets.url（migration 004:66 核实） |
| P1 | Day 1 smoke 缺 package orphan 真 FS 验证 | ✅ Day 1 plan 加 staging 目录 4 个 smoke 步 |
| P2 | rollback 允许 revoked → active 与术语表冲突 | ✅ 收紧只允许 deprecated → active；术语表 + 状态机扩展同步 |
| P2 | pr-b1.md / pr-b1-day1.md 混入 PR-A 历史 | ✅ 截断到当前 PR 范围，不带 PR-A 历史 |

## 评审节奏（沿用 PR-A 模式）

每个 Day 起手前单独写一个 day-plan，外部 review 后再开工：
- Day 1 plan → review → 实装 → commit
- Day 2 plan → review → 实装 → commit
- ...

本 master plan 的意义：让 PR-B1 整体可见，避免 4 天分别看不到全貌。

## 验收清单（PR-B1 总）

- [ ] 3 个子命令实装（orphan-scan / rollback / approve）
- [ ] 状态机扩展（**仅 deprecated → active** 一条）e2e 完整覆盖
- [ ] **revoked → active rollback 被拒绝**（关键 case，防退化）
- [ ] orphan-scan 两根目录都覆盖（audio + package）
- [ ] activate gating 双路径（env on/off）**CLI smoke 覆盖**（e2e 不能跨进程测 Python gating，方案 A）
- [ ] README 9 → 12 子命令表 + rollback 状态机图
- [ ] e2e **47 cases，46 pass + 1 pre-existing /me/today drift**（不阻塞）
- [ ] 端到端 CLI smoke 全过（在 Day 4 列详细命令）
- [ ] PR 描述 ready，可手工开 PR
- [ ] PR-A 既有契约零破坏（dual-condition / canonical_json / publish-manifest draft-only / repo helper 不 commit）

## 不做的事

- **不**改 schema（migration 008 等留 PR-C+）
- **不**写真 CDN 上传逻辑（PR-B3）
- **不**碰 mobile（PR-B2）
- **不**写 Web UI（PR-B3）
- **不**做多签 / RBAC（永远不做）
- **不**允许 revoked → active rollback（治理硬约束）
