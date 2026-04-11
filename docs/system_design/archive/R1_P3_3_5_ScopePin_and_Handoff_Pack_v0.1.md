# R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** active / scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v25.md` + `STATUS_updated_2026-04-10_v23.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.5.md`
  - `UI_SPEC_v0.2.5.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `p3.3.5_user.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.5 — Local Planner Owner Shift / Cloud Backup Rebase Round**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 在同一范围、同一问题集、同一交付口径下推进。

本文件不是：
- 新 PRD
- 新 BR 主文档
- 新 DB / API 主文档
- Room 4 执行任务单
- P3.3.5 closeout

本文件只做一件事：

> **把 “是否将 local FSRS / local scheduler 升格为复习规划 primary owner，并把 cloud 从 review serving truth 降级为 backup / restore / optional aggregate support layer” 收成一轮 dedicated contract / architecture round。**

---

## 1. 背景

当前推进层 SSOT 已明确：
- `P3.3.3` 已 closed，并已冻结 `review_readiness_policy_v1`、`review_priority_policy_v1`、`review_group_generation_policy_v1`、`schedule_source_contract_v1`
- `P3.3.4` 已完成 `previewDurations` 最小 re-entry 与 `stronger bridge` 最小强化
- 当前 active BR / UI baseline 已提升到 `BR-OPP-001_v0.2.5.md` 与 `UI_SPEC_v0.2.5.md`
- 当前 dual-store 现实仍成立：
  - **cloud**：today aggregate / `review_group` / 奖励 / 结算 / 商店 / 签到等 serving truth 域
  - **local**：FSRS scheduling / review logs / local settings / 设备侧运行态
- 当前主机制 PRD 继续明确：
  - **本地优先**
  - **手动全量备份**
  - **不做实时双向同步 / auto merge / delta sync**

与此同时，`p3.3.5_user.md` 已直接给出本轮建议主题与风险提示：

> **这不是普通 feature round，而是一次架构 / 合同改制轮。**

因此，Room 1 现将 user 直接拍板的下一方向正式命名为：

> **P3.3.5 — Local Planner Owner Shift / Cloud Backup Rebase Round**

一句话：

> **单开一轮 dedicated contract / architecture round，评估并收口：是否将 local FSRS / local scheduler 升格为复习规划 primary owner，并将 cloud 从 review serving truth 降级为 backup / restore / optional aggregate support layer。**

---

## 2. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.5 Scope Pin / Local Planner Owner Shift Preflight

### 一句话定义

> **P3.3.5 不是“再加一个复习功能”，而是评估复习规划 owner 是否从 cloud serving layer 切到 local planner。**

---

## 3. Room 1 当前判断

## 3.1 总结论
> **P3.3.5 当前必须先走 contract / architecture round。**

原因很简单：
1. 当前 BR 仍把 readiness / generation / serving truth owner 冻在 cloud review-serving layer。
2. 当前 UI 仍以 cloud truth split 为页面事实基线。
3. 当前 DB / API 仍明确保留 `review_group`、today aggregate、review_attempts 等 cloud review-serving 现实。
4. 一旦进入 “local primary planner + cloud backup rebase”，就不再是普通 feature delta，而是跨 BR / DB / API / UI / TEST 的 **Major Change candidate**。

## 3.2 Room 1 当前不直接做的事
本轮 **不直接** 给 Room 4 下实现单。  
先由 Room 2 / Room 3 / Room 5 做一轮专项输入，再由 Room 1 判断：
- 是否值得进入 owner shift
- 若进入，进入到哪一层
- 哪些必须分阶段迁移
- 哪些必须保持兼容 / deprecated / manual-only

---

## 4. 本轮核心问题（Room 1 统一问题集）

本轮必须回答的不是零散讨论，而是以下 6 个主线程问题：

### Q1. `planner_owner_shift_v2`
当前轮要不要正式推进：
- 谁是 review planning / serving 的 **primary owner**
- local FSRS / local scheduler 是否升级为 primary planner owner
- cloud 是否从 ReviewPage serving truth 降级
- 哪些能力以后端不再裁定
- 哪些非复习规划域仍可留在云端

### Q2. `review_serving_contract_v2`
当前轮要不要正式重写：
- ReviewPage 以后谁给队列
- `review_group` 还留不留
- 以后 `ready_now` / `next_group_eligible` 还要不要沿用 group 语义
- local due cards / local generated review session 是否进入 serving truth

### Q3. `session_entry_and_routing_v2`
当前轮要不要正式重写：
- 首页默认还是 `study_default` 吗
- active review continuation 以后怎么表达
- 是否进入 local planner 决定：先复习 / 先新学 / 混合 session
- `auto-routing` 是否进入候选合同

### Q4. `preview_and_explanation_contract_v2`
若 local 成为 primary planner，本轮要不要同步推进：
- `previewDurations` 是否还只是 hint
- 能否进入 ReviewPage
- explanation system 是否需要升格
- 哪些文案会被用户理解成计划事实

### Q5. `backup_restore_and_cross_device_boundary_v2`
当前轮要不要正式重写：
- backup 上传内容是什么
- restore 覆盖哪些 planner 状态
- 多设备不一致时谁为准
- `backup success / restore success / sync success` 三层语义如何定义
- 是否继续坚持 manual backup / no real-time sync / no auto merge

### Q6. `migration_and_deprecation_plan_v1`
当前轮至少要回答：
- 现有 `review_group` 是继续保留 / 兼容一段时间 / 逐步废弃
- cloud aggregate / readiness / generation 逻辑如何降级
- 哪些旧 API / DB 字段进入 deprecated
- patch / 测试 / 回写如何做

---

## 5. 本轮范围（In Scope）

### 5.1 Owner Shift / Serving Rewrite
本轮纳入：
1. `planner_owner_shift_v2`
2. `review_serving_contract_v2`
3. `session_entry_and_routing_v2`

### 5.2 Explanation / Preview / Planner Truth
本轮纳入：
1. `preview_and_explanation_contract_v2`
2. local planner becoming primary 后的文案事实边界
3. 页面 truth source 重写边界

### 5.3 Backup / Restore / Migration
本轮纳入：
1. `backup_restore_and_cross_device_boundary_v2`
2. `migration_and_deprecation_plan_v1`
3. 兼容期、deprecated、回写与测试要求

### 5.4 只做 contract / architecture round
本轮纳入的是：
- owner
- truth source
- serving contract
- route contract
- backup / restore boundary
- migration / deprecation strategy
- 风险与 staged rollout

本轮**不直接纳入** Room 4 实现。

---

## 6. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.5 自动纳入**：

1. 完整 AI 个性化学习系统
2. full sync / real-time sync / auto merge
3. 复杂多端冲突解决
4. 统一 Study / Review page 的大重构
5. 重做整套商店 / 装扮 / 猫咪状态链路
6. 复杂统计产品化重做
7. 完整 SRS / 完整复习调度产品一次性重写
8. 直接重做所有 today aggregate 非复习域
9. 非复习规划域的 cloud owner 大迁移
10. Room 4 提前实现试错式 owner shift

---

## 7. 各 Room 任务分配

## 7.1 Room 2 — 技术 / 架构 framing 先行
### 任务
产出：
`R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1.md`

### 必答
1. `planner_owner_shift_v2` 在技术上是否值得做、代价有多大
2. 若 local 成 primary planner owner，哪些现有 cloud contracts 必须退场
3. `review_serving_contract_v2` 最小可行形态是什么
4. `session_entry_and_routing_v2` 哪些能先冻结，哪些会越界成大重构
5. `backup_restore_and_cross_device_boundary_v2` 最小安全边界是什么
6. `migration_and_deprecation_plan_v1` 是否必须 staged rollout
7. 哪些动作一旦出现就越界成 Major implementation / architecture rewrite

### Done
给出：
- 推荐进入层
- 推荐不进入层
- Major 红线
- staged rollout 建议
- Room 1 可 pin 的最小合同集合

---

## 7.2 Room 3 — 业务规则语义收口
### 任务
产出：
`R3_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Rules_Note_v0.1.md`

### 必答
1. local 成 primary planner owner 后，业务上“ready / due / queue / generation”分别是什么意思
2. `review_group` 业务上是废弃、兼容容器，还是保留在部分场景
3. `session_entry_and_routing_v2` 在业务上如何解释，哪些表达会误导
4. `preview_and_explanation_contract_v2` 哪些可以升格，哪些必须继续禁止
5. `backup / restore / sync` 三层成功语义如何重新写硬
6. `migration_and_deprecation_plan_v1` 在规则层需要怎样的兼容期 / 禁区

### Done
给出：
- Frozen candidate
- Pending items
- Fact-copy / rule-boundary 护栏
- 可直接给 Room 1 吸收的决策句

---

## 7.3 Room 5 — UI / state contract 影响判断
### 任务
产出：
`UI_SPEC_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_UI_Preflight_v0.1.md`

### 必答
1. 如果 local 成 primary planner owner，首页 CTA / Study / Review / helper / summary 要怎么变
2. `review_serving_contract_v2` 会怎样改页面 state truth
3. `session_entry_and_routing_v2` 会如何影响首页默认入口、continuation、自动分流表达
4. `preview_and_explanation_contract_v2` 若升格，哪些页面可显示，哪些继续禁入
5. `backup_restore_and_cross_device_boundary_v2` 会影响哪些设置页 / 我的页 / 提示文案
6. 哪些表达会把“owner shift / backup rebase”误写成已同步、已统一、无冲突

### Done
给出：
- 页面承接建议
- state contract risk
- fact-copy 禁区
- 最小 UI 合同层
- staged UI migration 建议

---

## 8. 执行顺序（固定）

### 顺序
1. **Room 2**
2. **Room 3**
3. **Room 5**
4. **Room 1**
5. **Room 4（仅在 Room 1 正式下发执行单后）**

### 为什么这样排
1. **Room 2 先行**
   - 这轮本质上先是 owner / serving / backup 架构切刀，不先看技术边界，后面都会飘。
2. **Room 3 第二**
   - 在 Room 2 的技术 framing 上，把规则语义、兼容期、事实边界写硬。
3. **Room 5 第三**
   - 基于 Room 2 + Room 3 的共同边界，判断 UI / state / 文案影响，不提前把 pending 架构写成既成事实。
4. **Room 1 第四**
   - 统一吸收并决定：继续 preflight / pin 最小合同 / 或升级给 user 做更明确的范围拍板。
5. **Room 4 最后**
   - 只有当 Room 1 明确下发 `R1 → R4` 执行单后，才允许进入实现治理 / 执行层。

---

## 9. 风险 / Blockers

1. **这是 Major Change candidate，不是普通 feature round**
   - 直接影响 BR / DB / API / UI / TEST 的复习主链路。
2. **当前 active truth 仍在 cloud review-serving layer**
   - 任何“local 已经是主 owner”的表述，在本轮前都属于假事实。
3. **若不写 migration / deprecation，后续一定出现 silent contract drift**
   - 特别是 `review_group`、today aggregate、review_attempts、backup/restore 语义。

---

## 10. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 下一步只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_5_Close_Preflight_Note_v0.1.md`
- 若当前仍不适合进入 owner shift
- 保持 pending，并记录 why / what next

### 方案 B
`R1_to_R2_R3_R5_P3_3_5_Decision_Gate_v0.1.md`
或
`R1_to_R4_P3_3_5_Execution_Handoff_v0.1.md`
- 若当前已足够 pin 一层更窄的 owner-shift minimal contract
- 先决定是否需要二次 user escalation，再决定是否给 Room 4

---

## 11. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `planner_owner_shift_v2`、`review_serving_contract_v2`、`session_entry_and_routing_v2`、`preview_and_explanation_contract_v2`、`backup_restore_and_cross_device_boundary_v2` 与 `migration_and_deprecation_plan_v1` 六个问题，先完成一轮同边界、同问题集、同口径的 contract / architecture round 输入；P3.3.5 当前不直接进入实现。**
