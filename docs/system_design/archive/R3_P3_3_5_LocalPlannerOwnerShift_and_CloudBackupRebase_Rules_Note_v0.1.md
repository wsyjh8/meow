# R3_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / contract-gate / local planner owner shift + cloud backup rebase
- **Status:** ready for Room 1 review
- **Date:** 2026-04-10
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md` 指定的 round review basis
- **Direct upstream input:** `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.5 当前轮需要回答的 “local planner owner shift + cloud backup rebase” 问题，收成一份可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API 主文档
- 新 UI 主文档
- Room 4 执行单
- 直接宣布 owner shift 已完成
- 完整复习系统重写稿
- unified planner / planner merge 最终版

一句话：

> **P3.3.5 是合同改制轮，不是直接把本地 planner 已接管复习主链路写成当前事实。**

---

## 1. 输入依据

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.6.md`
- `UI_SPEC_v0.2.6.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v25.md`
- `STATUS_updated_2026-04-10_v23.md`

### 1.4 Cross-room framing input
- `p3.3.5_user.md`
- `R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1.md`

---

## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

原因不是为了“把系统做满”，而是因为 P3.3.2 / P3.3.3 / P3.3.4 已连续把 review planning 的 owner split、truth split、preview、stronger bridge 往前推进；如果 P3.3.5 仍完全不回答 “未来到底谁是 planner owner、cloud 以后还剩什么角色、backup / restore 如何定义”，后续所有 review 深化都会继续卡在同一组规则空洞上。

### 2.2 本轮不能直接写成什么
Room 3 同时明确：

> **P3.3.5 当前不能直接写成 `local 已经成为 runtime primary planner / serving truth owner`。**

当前 active BR / UI / DB / API / PRD 仍共同绑定以下现实：
1. 页面级 readiness truth 仍在 cloud review-serving layer
2. ReviewPage serving truth owner 仍是 cloud `review_group`
3. `review_group` / today aggregate / review attempts 仍是当前 review-serving reality
4. 主机制 PRD 仍把有效学习 / 有效复习 / 今日目标完成 / Session / streak 的最终事实收口在后端
5. P3.1 仍坚持 local-first + manual backup，但不是实时 sync / auto merge / cloud merge platform

### 2.3 Room 3 的一句话立场
> **Room 3 支持 P3.3.5 进入 “target-state + staged migration + backup-rebase” 的合同层；但不支持把 local owner shift 直接写成 current runtime truth。**

---

## 3. `planner_owner_shift_v2`（Room 3 规则立场）

## 3.1 Room 3 结论
> **Room 3 接受 “local FSRS / local scheduler 未来可成为 primary planning owner” 这一方向；但当前只能冻结成 future target-state candidate，不能冻结成 runtime 已完成事实。**

### RF-P3.3.5-001 — local primary planner owner 只冻结为 future target-state candidate
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.5 当前若接受 owner shift 方向，只能冻结到：
  - local FSRS / local scheduler 被接受为 **future primary planning owner** 的目标方向
  - 不冻结为 **current runtime truth**
- **Applies to:** BR / UI / DB / API / TEST / migration framing
- **Checkable:**
  1. 文档不得把 “方向被接受” 写成 “当前已切换完成”
  2. UI / 文案 / 测试不得把 local 直接写成当前 ReviewPage serving truth
  3. Room 4 不得在没有下一轮 execution gate 时提前实现 owner shift

### RF-P3.3.5-002 — owner 必须拆成 planning / serving / fact-settlement 三层，不得一刀切
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.5 当前讨论 owner shift，必须至少区分三层：
  1. **planning owner**：future 方向可转向 local
  2. **serving owner**：当前 runtime 仍是 cloud review-serving layer
  3. **fact / settlement owner**：当前继续留在 cloud / backend fact layer
- **Why frozen candidate:** 如果不先分层，后续很容易把 “planner candidate 上位”误写成“所有最终事实一起改由本地裁定”。

### RF-P3.3.5-003 — local owner shift 不自动带出 fact owner shift
- **Status:** Frozen candidate for this round
- **Rule:** 即使未来 local 成为 primary planning owner，也不自动等于：
  - 有效复习事实改由本地裁定
  - 今日目标完成事实改由本地裁定
  - 奖励结算 / 账本 / 签到 / streak 最终事实改由本地裁定
- **Must not do:** 不得把 planner owner shift 包装成 “后端以后不再裁定主机制事实”。

---

## 4. `review_serving_contract_v2`

## 4.1 Room 3 结论
> **本轮可以讨论未来的 local-serving 目标，但当前只建议冻结 “target-state + compatibility reality + deprecation path”，不建议把 local due queue 直接写成 current serving truth。**

### RF-P3.3.5-004 — ReviewPage current serving truth 仍不得被偷切
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.5 当前轮，若还没有下一轮专门 execution gate，ReviewPage current serving truth 仍不得被静默改成 local due queue / local generated review session。
- **Checkable:**
  1. `review_group` 当前仍不得在规则层被写成“已退出 runtime”
  2. `ready_now` / `next_group_eligible` 当前仍不得被 local-only 结果冒充
  3. Room 5 / Room 4 不得把 local due cards 写成当前页面唯一真相源

### RF-P3.3.5-005 — future local-serving 只能作为 v2 target-state candidate
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.5 当前可以接受未来 v2 的目标形态：
  - ReviewPage 队列来自 local due cards / local generated review session
  - `review_group` 退出 primary serving path
  - cloud 降级为 backup / restore / optional aggregate support / 非复习规划域
- **But:** 这当前只是 target-state candidate，不是本轮 runtime truth。

### RF-P3.3.5-006 — `review_group` 当前应进入 compatibility / deprecation path，而不是“直接全废弃”
- **Status:** Frozen candidate for this round
- **Rule:** 若进入 owner shift 方向，`review_group` 的业务语义当前最稳的处理方式不是“立刻删除”，而是：
  1. current runtime owner（现在）
  2. compatibility / transition layer（过渡）
  3. staged deprecation target（未来）
- **Why frozen candidate:** 这能避免 UI / DB / API / TEST 一次性断裂。

---

## 5. `session_entry_and_routing_v2`

## 5.1 Room 3 结论
> **若 local 未来成为 primary planner owner，`home_word_entry = study_default` 就不再一定是最终长期真相；但当前轮仍不能直接升格为 auto-routing / mixed routing runtime contract。**

### RF-P3.3.5-007 — `study_default` 当前继续是 runtime reality，future routing v2 只作为 target-state candidate
- **Status:** Frozen candidate for this round
- **Rule:** 当前首页“背单词”默认仍按 `study_default` 作为 runtime reality；若 P3.3.5 要讨论 local planner 主导的 routing，当前只能把它写成 future routing candidate，不得写成已经生效。
- **Must not do:**
  1. 不得把 local planner 决定“先复习 / 先新学 / 混合 session”写成已开启
  2. 不得把 auto-routing 写成当前既成事实
  3. 不得把 active continuation 自动吞掉 `/study` 入口写成已完成逻辑

### RF-P3.3.5-008 — continuation 高优先未来仍可保留，但表达方式必须重写
- **Status:** Frozen candidate for this round
- **Rule:** 即便 future serving owner 发生变化，active review continuation 的高优先语义未来仍可保留；但其承接方式、helper、CTA 与 priority block 必须在 v2 中重写，不能继续直接借用 current cloud-group wording。
- **Why frozen candidate:** owner shift 不是把“continuation”删除，而是要求其新的 truth source 和 UI 表达重新定义。

---

## 6. `preview_and_explanation_contract_v2`

## 6.1 Room 3 结论
> **若 local planner 成为 future primary owner，preview / explanation 的业务级别可以上升，但当前仍不得被写成 committed plan fact。**

### RF-P3.3.5-009 — preview 可从 “estimated hint” 升到 “planner-facing explanation candidate”，但仍不是 committed plan fact
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.5 当前若接受 local planner 主导方向，`previewDurations` 与 explanation system 在 future v2 中可以从：
  - `estimated hint / candidate explanation`
  进一步升级为：
  - `planner-facing explanation candidate`
- **But:** 当前仍不得写成 committed plan fact / cloud-confirmed schedule fact / cross-device stable truth。

### RF-P3.3.5-010 — Preview / explanation 的 fact-copy 禁区继续保留
- **Status:** Frozen candidate for this round
- **Rule:** 无论 owner shift 方向是否被接受，以下表达当前轮继续禁止：
  - 下次将在 X 天后复习
  - 系统已为你安排
  - 已更新你的复习计划
  - 已同步复习安排
  - 计划已统一
  - 已切换到最佳复习模式
- **Why frozen candidate:** 否则会把 preview 或 explanation 从“候选解释”直接误写成“已承诺计划”。

### RF-P3.3.5-011 — ReviewPage / HomePage 是否引入 preview，必须后置到下一层 UI / serving rewrite gate
- **Status:** Frozen as pending-boundary
- **Rule:** 即使 local primary planner direction 被接受，preview 是否进入 ReviewPage / 首页，也必须后置到下一层 UI + serving rewrite gate，不在当前轮直接写死。
- **Why frozen:** 这会直接碰到 truth source、serving owner、route contract 与 copy boundary 的联动重写。

---

## 7. `backup_restore_and_cross_device_boundary_v2`

## 7.1 Room 3 结论
> **若 P3.3.5 进入 cloud backup rebase，则本轮必须把 backup / restore / sync 三层语义、cross-device boundary 与 manual-only 边界重新写硬；但仍不进入 real-time sync / auto merge。**

### RF-P3.3.5-012 — cloud backup rebase 只改变 cloud 在“复习规划域”的角色，不改变 manual-only / no-real-time-sync 原则
- **Status:** Frozen candidate for this round
- **Rule:** 即使 cloud 从 review serving truth 降级为 backup / restore / optional aggregate support layer，P3.1 已冻结的：
  - manual backup
  - no real-time sync
  - no auto merge
  - no delta sync
  继续有效，不得被静默打开。
- **Why frozen candidate:** owner shift ≠ sync strategy shift。

### RF-P3.3.5-013 — `backup success / restore success / sync success` 三层语义必须继续分开，且本轮不得用 “sync success” 冒充真实状态
- **Status:** Frozen candidate for this round
- **Rule:** 当前若进入 backup-rebase round，必须继续严格区分：
  1. backup success
  2. restore success
  3. sync success
- **Current stance:** 在无 real-time sync / auto merge 的前提下，本轮不得把任何状态文案写成 “sync success” 的既成事实。

### RF-P3.3.5-014 — 多设备不一致当前继续不是自动裁定问题，而是 manual restore boundary 问题
- **Status:** Frozen candidate for this round
- **Rule:** 在当前 local-first + manual backup / restore 边界下，多设备 planner 状态不一致，继续不由云端自动裁定；它仍属于 manual restore / explicit overwrite / user-driven recovery 的边界问题。
- **Must not do:**
  1. 不得把 cloud snapshot 写成当前跨设备统一真相
  2. 不得把 backup existence 写成“多设备已一致”
  3. 不得引入 silent overwrite / auto resolve 叙述

---

## 8. `migration_and_deprecation_plan_v1`

## 8.1 Room 3 结论
> **若 P3.3.5 接受 owner shift 方向，本轮必须同时冻结一个 migration / deprecation 最小边界；否则所有人都会把 target-state 当成已切完。**

### RF-P3.3.5-015 — `review_group` / cloud readiness / generation 当前必须进入 staged deprecation 语义，而不是“已消失”
- **Status:** Frozen candidate for this round
- **Rule:** 若 local planner owner 方向被接受，则当前必须明确：
  - `review_group` 不是“已被删除”
  - cloud readiness / generation 不是“已立即失效”
  - 它们当前只进入 staged deprecation / compatibility path
- **Why frozen candidate:** 避免 code / UI / DB / API / test 不同步时各自脑补。

### RF-P3.3.5-016 — deprecated 不得被写成 active truth，也不得被假装已经完全迁移完
- **Status:** Frozen candidate for this round
- **Rule:** 进入 deprecated / compatibility 的旧 contract：
  1. 不得继续被主文案写成 active truth
  2. 也不得被写成“已全部迁移完成”
- **Canonical meaning:** 兼容层是兼容层，不是 current owner，也不是已经被彻底删掉。

### RF-P3.3.5-017 — patch / test / write-back 必须和 migration decision 绑定
- **Status:** Frozen candidate for this round
- **Rule:** 若 Room 1 接受 owner shift 方向，则 patch / test / write-back 不能只改一层，必须至少联动：
  - BR
  - DB / API candidate
  - UI fact-copy / state contract
  - test strategy / regression scope
- **Why frozen candidate:** 这轮本质上就是 Major Change candidate，不能只改一篇 note。

---

## 9. 哪些内容必须继续 Pending

### 9.1 当前继续 Pending
1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. auto-routing runtime behavior
4. unified planner / planner merge
5. complete planner explanation system
6. must-succeed bridge
7. exact review queue algorithm
8. full sync / real-time sync / auto merge
9. unified Study / Review page
10. complete SRS / complete review planning product rewrite

### 9.2 Room 3 一句话原则
> **本轮只回答“未来方向与迁移边界是什么”，不回答“今天就已经切完了”。**

---

## 10. 对 Room 4 / Room 5 的禁止补脑项（Room 3 版）

### 10.1 给 Room 4
Room 4 在 Room 1 未正式 pin staged migration contract 前，不得自行决定：
1. 把 local planner 直接接成 current serving truth
2. 把 `review_group` 直接删出运行态
3. 把 preview / explanation 写成 committed plan fact
4. 把 backup 容器写成 sync truth
5. 把 owner shift 写成已完成迁移

### 10.2 给 Room 5
Room 5 在 Room 1 未正式 pin staged migration contract 前，不得自行决定：
1. 把首页 / ReviewPage 文案写成“系统已自动安排”
2. 把 preview 写成稳定复习计划
3. 把 cloud rebase 写成“多设备已统一”
4. 把 deprecated / compatibility layer 当成已经消失

---

## 11. Room 3 可直接给 Room 1 的决策句

### 11.1 Planner owner decision sentence
> **Room 3 judgment：P3.3.5 当前可以接受 “local FSRS / local scheduler 成为 future primary planning owner” 的方向，但只应冻结为 target-state candidate；current runtime truth 仍不得被写成 owner shift 已完成。**

### 11.2 Serving contract decision sentence
> **Room 3 judgment：P3.3.5 当前可以把 ReviewPage local-serving 作为 v2 目标方向讨论，但 current runtime 只适合冻结 “compatibility reality + staged deprecation path”，不适合直接把 local due queue 写成现行 serving truth。**

### 11.3 Backup rebase decision sentence
> **Room 3 judgment：若 cloud 在复习规划域降级为 backup / restore / optional aggregate support layer，则 manual backup / no real-time sync / no auto merge / no delta sync 必须继续保持冻结；backup success / restore success / sync success 三层语义也必须继续分开。**

### 11.4 Migration decision sentence
> **Room 3 judgment：P3.3.5 若要接受 owner shift 方向，就必须同步 pin 一个 staged migration / deprecation 最小边界；否则 local future target-state 很容易被误写成 current runtime truth。**

---

## 12. Room 3 最终一句话

> **P3.3.5 这轮，Room 3 支持把 “local planner owner shift / cloud backup rebase” 推进到 `target-state + staged migration + compatibility/deprecation` 的规则层；但不支持把它直接写成当前 runtime 已切换完成的事实，更不支持借此静默打开 sync / merge / auto-routing / unified planner。**
