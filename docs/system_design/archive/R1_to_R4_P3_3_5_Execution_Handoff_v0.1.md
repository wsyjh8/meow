# R1_to_R4_P3_3_5_Execution_Handoff_v0.1.md

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** execution handoff / ready for Room4-治理层
- **Role basis:** `room1_v0.2.0.md`
- **Governance basis:** `ORG_v0.3.1.md`
- **Runtime basis used for this round:** `Main_updated_2026-04-10_v25.md` + `STATUS_updated_2026-04-10_v23.md`
- **Direct upstream inputs:**
  - `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`
  - `R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1.md`
  - `R3_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_UI_Preflight_v0.1.md`
  - `BR-OPP-001_v0.2.6.md`
  - `UI_SPEC_v0.2.6.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3.5 这轮已经完成 cross-room 收口的内容，
正式压成一份可交给 **Room4-治理层** 的统一执行任务单。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- 直接 owner shift 的实施宣告
- 完整复习系统重写稿
- P3.3.5 closeout

本文件只做一件事：

> **把 P3.3.5 当前已经由 Room 2 / Room 3 / Room 5 收成一致的“future target-state + staged migration + backup/restore semantic rewrite + compatibility/deprecation prep”压成一份 very narrow、可执行、可测试、不可误写成 runtime owner shift 的执行 handoff。**

---

## 1. Room 1 吸收后的统一结论

### 1.1 本轮允许进入执行，但只允许进入 **Phase 0 / Compatibility-Prep Layer**
Room 1 当前接受：

1. **`local primary planner owner` 方向可以进入主线程**
   - 但只作为 **future target-state candidate**
   - 不得写成 current runtime truth

2. **`review_group` 可进入 compatibility / deprecation path**
   - 但当前不得直接删出运行态
   - 不得写成已退场

3. **`backup / restore / cross-device boundary` 值得先前进一步**
   - 因为这组最不容易反悔，且最能减少未来误导
   - 但仍必须坚持：
     - manual backup
     - no real-time sync
     - no auto merge

4. **P3.3.5 当前不是 runtime owner shift 实施轮**
   - 不是 local-serving cutover
   - 不是 ReviewPage queue source 改写轮
   - 不是首页 routing / auto-routing 开启轮
   - 不是 unified planner / planner merge 轮

### 1.2 Room 1 因此给 Room 4 的不是“主链路切换单”，而是：
> **Phase 0 / Compatibility-Prep + Semantic Rewrite + Shadow-Prep 执行单。**

也就是说，本轮允许 Room 4 做：
- compatibility / deprecation prep
- backup / restore 语义与 UI copy 改写
- shadow-prep / adapter seam / feature-flag prep
- regression / test strategy landing
- doc patch draft

但**不允许** Room 4 做：
- runtime owner shift
- local-serving cutover
- API / DB core semantics rewrite
- current truth source rewrite

---

## 2. Room 1 正式 pin 的最小合同集合

### 2.1 `planner_owner_shift_v2`
当前正式 pin 为：

- `local FSRS / local scheduler` 可作为 **future primary scheduling owner target-state candidate**
- 当前不自动改写 runtime owner
- owner 必须继续分三层看：
  1. planning owner（future local direction）
  2. serving owner（current runtime = cloud review-serving layer）
  3. fact / settlement owner（current runtime = cloud / backend fact layer）

### 2.2 `review_serving_contract_v2`
当前正式 pin 为：

- future local-serving 方向可以被接受
- 当前 runtime 继续以 cloud `review_group` 作为 ReviewPage serving truth
- `review_group` 当前只进入：
  - compatibility / transition layer
  - staged deprecation candidate
- 当前不得写成：
  - local due queue 已接管
  - `review_group` 已退出 runtime
  - local 已是 current ReviewPage truth owner

### 2.3 `session_entry_and_routing_v2`
当前正式 pin 为：

- future routing 可能会受 owner shift 影响
- 但当前 runtime 继续保持：
  - `home_word_entry = study_default`
  - active continuation 高优先，但不得 silent reroute
  - no auto-routing runtime contract

### 2.4 `preview_and_explanation_contract_v2`
当前正式 pin 为：

- 若 future local planner owner 成立，preview / explanation 未来可以升格为 planner-facing explanation candidate
- 但当前仍不得写成 committed plan fact
- preview 是否进入 ReviewPage / 首页，继续后置到下一层 UI + serving rewrite gate
- 当前 fact-copy 禁区继续有效：
  - 下次将在 X 天后复习
  - 系统已为你安排
  - 已更新你的复习计划
  - 已同步复习安排
  - 计划已统一
  - 已切换到最佳复习模式

### 2.5 `backup_restore_and_cross_device_boundary_v2`
当前正式 pin 为：

- backup / restore / sync success 三层语义必须继续严格分开
- restore 继续：
  - manual only
  - pre-check + warning + confirm
  - restore apply 才改变目标设备 runtime truth
- 在无 real-time sync / auto merge 的前提下：
  - 每台设备自己的本地 planner state = 该设备当下 runtime truth
  - 云端 latest backup = recovery artifact
  - backup existence ≠ cross-device consistency

### 2.6 `migration_and_deprecation_plan_v1`
当前正式 pin 为：

- **必须 staged rollout**
- 当前只允许进入：
  - compatibility / deprecation markers
  - shadow / parity preparation
  - regression scope preparation
- 当前不允许跳过 compatibility / shadow / parity thinking 直接切主链路

---

## 3. 给 Room4-治理层的任务定义

### 3.1 目标
完成 P3.3.5 的 **Phase 0 / Compatibility-Prep**，具体包括：

1. 把 backup / restore / cross-device 的三层语义改写成稳定、不误导的 UI / copy / state reality
2. 把 current runtime truth 与 future target-state candidate 的边界写硬
3. 给 future owner shift 做 compatibility / deprecation / shadow-prep，但不切 runtime 主链路
4. 建立最小测试与回写要求，避免后续 silent contract drift

### 3.2 In Scope
1. Settings / 我的页 / 可能的数据页中的 backup / restore 文案与状态语义改写
2. `backup success / restore success / sync success` 的严格区分
3. restore warning / confirm / result flow 的最小安全表达
4. current runtime truth vs future target-state candidate 的 helper / summary / copy guardrails
5. `review_group` compatibility / deprecation prep
6. future local-serving / local planner owner 的 shadow-prep / adapter seam / flag-prep
7. regression / parity / migration-oriented test prep
8. BR / DB / API / UI patch draft 清单
9. no-major-change statement

### 3.3 Out of Scope
1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 接管当前 ReviewPage truth
4. `review_group` 直接删出运行态
5. auto-routing runtime
6. unified planner / planner merge
7. unified Study / Review page
8. ReviewPage preview re-entry
9. preview 写成 committed plan fact
10. DB schema 重构
11. API core semantics 重写
12. full sync / real-time sync / auto merge
13. 直接对 reward / settlement / daily_goal / streak 最终事实做 owner shift

---

## 4. 必守依据

### 要按需读文档，不需要一次性读完

Room4-治理层与执行层，本轮必须同时服从以下依据：

### 4.1 推进层 / 主线程
- `Main_updated_2026-04-10_v25.md`
- `STATUS_updated_2026-04-10_v23.md`
- `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`

### 4.2 规则 / 事实边界
- `BR-OPP-001_v0.2.6.md`
- `R3_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Rules_Note_v0.1.md`

### 4.3 技术边界
- `R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 4.4 UI / UX 边界
- `UI_SPEC_v0.2.6.md`
- `UI_SPEC_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_UI_Preflight_v0.1.md`

---

## 5. Room 4 不得补脑的已收口项

以下点本轮 Room 1 已收口，Room 4 不得二次发明：

1. **current runtime truth 仍未 owner shift**
2. **future target-state candidate ≠ current runtime truth**
3. **ReviewPage current serving truth 仍围绕 cloud `review_group`**
4. **`review_group` 当前进入 compatibility / deprecation path，不是已删除**
5. **首页当前仍 `study_default`，不得 silent reroute**
6. **preview / explanation 当前不得写成 committed plan fact**
7. **backup / restore / sync 三层语义必须继续严格分开**
8. **current round 必须 staged rollout，不得直接切主链路**

---

## 6. Room 4 执行护栏

### 6.1 Owner / Serving 护栏
当前继续禁止：
- local 已是 ReviewPage primary truth owner
- cloud 不再裁定复习事实
- `review_group` 已退出运行态
- 本地已完全接管复习主链路
- owner shift 已完成
- 当前 ReviewPage 队列来自 local due / local generated review session

### 6.2 Routing 护栏
当前继续禁止：
- 系统已自动决定今天先学什么
- 当前点“背单词”会自动跳去复习
- 已切换到本地规划入口
- auto-routing 已开启
- mixed session 已成为当前默认路径

### 6.3 Preview / Explanation 护栏
当前继续禁止：
- 下次将在 X 天后复习
- 系统已为你安排
- 已更新你的复习计划
- 已同步复习安排
- 计划已统一
- 已切换到最佳复习模式
- preview / explanation 已成为 committed plan fact

### 6.4 Backup / Restore 护栏
当前继续禁止：
- 已同步
- 云端与本地已统一
- 跨设备已保持一致
- 无需担心冲突
- 恢复后所有设备自动一致
- backup 成功 = 其他设备已更新
- restore success = sync success

### 6.5 Major 红线
以下动作一旦出现，视为越界：
1. 把 local FSRS 直接写成 current ReviewPage truth owner
2. 删除或绕空 `review_group` 但不提供兼容 / 迁移方案
3. 改写 `/me/today`、`GET /me/review-groups/next`、`POST /review-attempts` 的核心语义
4. 让本地 planner 直接决定 reward / settlement / daily_goal 最终事实
5. 把 backup / restore 写成 real-time sync / auto merge / auto recovery
6. 修改 DB schema / API core semantics 但不先写 deprecation 与 staged rollout
7. 把 preview / explanation 写成 owner shift 已完成的页面事实
8. 把首页默认入口与 routing 一并重写成 planner-driven runtime 行为

---

## 7. 推荐执行方式（Room 4 本轮）

### Track A — Semantic Rewrite / UI Copy Safety
做：
1. Settings / Profile / 数据相关页面中的 backup / restore / sync 文案重写
2. restore warning / confirm / result flow 文案与状态分层
3. 当前 runtime truth 与 future target-state 的 helper / summary / empty-state / result-copy 护栏加固

不做：
- 宣称 owner shift 已完成
- 宣称多设备已统一
- 宣称 preview / explanation 已是稳定计划事实

### Track B — Compatibility / Deprecation Prep
做：
1. `review_group` compatibility posture 的代码侧 / patch-draft 侧准备
2. deprecated candidate 清单与受影响路径清单
3. future local-serving 目标所需 adapter seam / flag / hook / telemetry / shadow-prep

不做：
- local-serving runtime cutover
- 直接删除 cloud review-serving path

### Track C — Test / Shadow / Parity Prep
做：
1. current runtime truth 不变的断言
2. backup / restore 三层语义断言
3. compatibility / deprecation path 断言
4. no-user-facing owner-shift-claim 断言
5. shadow / parity prep 说明

不做：
- 把 shadow mode 写成生产已启用
- 把 parity 结果写成 owner shift 已完成

---

## 8. 必测项

Room 4 本轮至少覆盖以下测试 / 自测：

### 8.1 Runtime Truth Guardrails
1. 首页继续 `study_default`
2. active continuation 继续不吞 `/study`
3. ReviewPage current serving truth 继续围绕 cloud `review_group`
4. current runtime 未被误切到 local-serving

### 8.2 Backup / Restore 语义
1. `backup success` ≠ `restore success`
2. `restore success` ≠ `sync success`
3. restore apply 才改变目标设备 runtime truth
4. backup existence 不代表多设备已一致
5. 无 real-time sync / auto merge 假事实出现

### 8.3 Preview / Explanation 护栏
1. 不出现 committed plan fact 文案
2. ReviewPage / 首页不因本轮被偷偷引入 deeper preview / explanation truth
3. 不出现“系统已安排 / 已更新计划 / 已同步复习安排”等假事实

### 8.4 Compatibility / Deprecation
1. `review_group` 当前未被误删
2. deprecated candidate 被正确标记为候选 / 过渡层
3. compatibility path / shadow-prep 存在但不冒充已切换完成

### 8.5 No Major Contract Drift
1. DB schema 未被偷改
2. API core semantics 未被偷改
3. reward / settlement / daily_goal / streak 最终事实 owner 未被偷切
4. routing 未被偷切到 auto-routing runtime

---

## 9. 交付物要求

Room4-治理层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **当前 runtime truth 是否保持不变**
5. **future target-state candidate 是否被正确限制在非运行态层**
6. **`review_group` compatibility / deprecation prep 做了什么**
7. **backup / restore copy / state semantics 如何重写**
8. **是否触碰核心契约的判断**
9. **no-major-change statement**
10. **需要哪些文档回写**
    - BR / UI / Main / Status / DB / API / TEST / 其他
11. **是否可 close / 是否需 revise / 是否需 escalate**

---

## 10. Room 1 预期完成定义（Done）

当 Room4-治理层交回结果，且满足以下条件时，Room 1 认为 P3.3.5 本轮可以进入 absorb / close 判断：

1. current runtime truth 未被偷切
2. future target-state candidate 与 current runtime truth 的边界被写硬
3. backup / restore / sync 三层语义在页面与状态层被正确区分
4. `review_group` compatibility / deprecation prep 已形成最小可引用事实
5. shadow / parity / regression prep 已交付
6. 未触碰 DB schema / API core semantics / reward-settlement owner / routing runtime
7. 所有文案禁区均未越界

---

## 11. 一句话 handoff

> **请 Room4-治理层按“current runtime truth 不变 + future target-state candidate 写硬 + backup/restore 语义重写 + compatibility/deprecation/shadow-prep”这一 very narrow execution layer 推进 P3.3.5；不要把本轮做成 runtime owner shift，更不要把 local 已接管复习主链路写成当前事实。**
