# R1_to_R4_P3_3_8_Execution_Handoff_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** execution handoff / ready for Room4-治理层
- **Role basis:** `room1_v0.2.0.md`
- **Governance basis:** `ORG_v0.3.1.md`
- **Runtime basis used for this round:** `Main_updated_2026-04-10_v28.md` + `STATUS_updated_2026-04-10_v26.md`
- **Direct upstream inputs:**
  - `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md`
  - `R2_P3_3_8_Phase3Gate_and_DB_API_Candidate_Tech_Note_v0.1.md`
  - `R3_P3_3_8_Phase3Gate_and_CutoverDecision_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_8_Phase3Gate_and_CutoverDecision_UI_Preflight_v0.1.md`
  - `BR-OPP-001_v0.2.9.md`
  - `UI_SPEC_v0.2.9.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `P3.3.7_Claude_res.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3.8 这轮已经完成 cross-room 收口的内容，
正式压成一份可交给 **Room4-治理层** 的统一执行任务单。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- runtime owner shift 完成宣告
- ReviewPage local-serving cutover 方案书
- unified planner / planner merge 落地稿
- P3.3.8 closeout

本文件只做一件事：

> **把 P3.3.8 已被 Room 2 / Room 3 / Room 5 收成一致的 `Phase 3 Gate / Cutover-Decision + DB/API Candidate Round`，压成一份 very narrow、可执行、可测试、不可误写成 cutover 的执行 handoff。**

---

## 1. Room 1 吸收后的统一结论

### 1.1 本轮允许进入执行，但只允许进入 **Phase 3 / Gate-Driven Candidate Execution Layer**
Room 1 当前接受：

1. **`phase3_gate_decision_v1` 可进入执行**
   - 但只进入 proceed / hold / revise / escalate 的 gate 层
   - 不得写成 cutover completed

2. **`limited_cutover_scope_candidate_v1` 可进入执行**
   - 但只进入 candidate seam / migration subset
   - 不得写成 serving source 已切换

3. **`db_api_candidate_round_v1` 可进入执行**
   - 但只进入 candidate contract / migration / rollback / hold-note 层
   - 不得改 current active DB / API core semantics

4. **`review_group_exit_gate_v1` 可进入执行**
   - 但只进入 “还缺什么才有资格退场” 的 gate 层
   - 不得写成 `review_group` 已退场或可立即退场

5. **`fact_settlement_cutover_boundary_v1` 可进入执行**
   - 但只进入 final-truth guardrails + candidate ingest seam 层
   - final fact / settlement truth 继续以后端为准

6. **`phase3_writeback_and_migration_v1` 必须进入执行**
   - 因为这是当前最直接防 silent contract drift 的手段
   - 也是 future limited cutover round 的前置件

### 1.2 Room 1 因此给 Room 4 的不是“cutover 单”，而是：
> **Phase 3 / Gate-Driven Candidate Execution + Migration Prep 执行单。**

也就是说，本轮允许 Room 4 做：
- gate evidence consolidation
- candidate seam / migration marker / rollback floor prep
- DB/API candidate framing的代码侧落点与 patch draft
- `review_group` exit gate 所需前置项的显式化
- fact / settlement cutover boundary 的 evidence-path 与 guardrails 固化
- UI / helper / summary / CTA 的 source-neutral migration prep
- regression / write-back / no-major-change statement

但**不允许** Room 4 做：
- runtime owner shift completed
- ReviewPage local-serving runtime cutover
- local due queue 接管 current ReviewPage truth
- `review_group` 退出运行态
- auto-routing runtime
- planner merge / unified planner
- DB schema rewrite
- API core semantics rewrite

---

## 2. Room 1 正式 pin 的最小合同集合

### 2.1 `phase3_gate_decision_v1`
当前正式 pin 为：

1. gate 当前只允许得出：
   - `proceed_to_next_layer_candidate_review`
   - `hold`
   - `revise`
   - `escalate`
2. 当前明确禁止得出：
   - `runtime_owner_shift_completed`
   - `local_serving_cutover_completed`
   - `review_group_exited`
   - `unified_planner_established`

### 2.2 `limited_cutover_scope_candidate_v1`
当前正式 pin 为：

1. 若未来进入下一层，最小切口只允许先讨论：
   - candidate seam formalization
   - ingest seam strengthening candidate
   - helper / summary / state contract migration prep
   - rollback / hold / migration note baseline
2. 当前不允许：
   - ReviewPage current queue source switch
   - runtime routing switch
   - final fact owner switch

### 2.3 `db_api_candidate_round_v1`
当前正式 pin 为：

1. DB / API 当前只允许进入：
   - seam candidate
   - migration marker
   - rollback floor
   - hold-note
   - write-back order
2. 当前不允许：
   - schema rewrite
   - endpoint core semantics rewrite
   - active baseline uplift to new owner-shift reality
3. `DB/API v0.2.1` 继续是 active baseline 起点

### 2.4 `review_group_exit_gate_v1`
当前正式 pin 为：

1. `review_group` 当前继续保持：
   - current runtime serving owner
   - compatibility anchor
   - deprecated candidate
2. 只有当以下 4 类前置条件都具备时，才有资格进入真实退场判断：
   - contract 条件齐
   - test 条件齐
   - doc 条件齐
   - final fact / settlement boundary 条件齐
3. 当前不得写成：
   - 已退场
   - 即将退场
   - 已不再使用
   - 可直接清理旧 path

### 2.5 `fact_settlement_cutover_boundary_v1`
当前正式 pin 为：

1. 即使进入 Phase 3 gate，以下最终事实当前仍必须以后端 / cloud fact layer 为准：
   - 有效复习事实
   - 今日目标完成
   - 奖励结算 / 账本到账
   - `check_in / learning_day / streak`
2. local-serving evidence、parity result、ingest candidate 当前都不得冒充这些最终事实
3. serving source 也不得先于 fact boundary 被偷切

### 2.6 `phase3_writeback_and_migration_v1`
当前正式 pin 为：

1. 本轮必须至少写硬：
   - write-back 次序
   - migration note
   - rollback floor
   - hold note
   - no-major-change statement
2. 回写顺序建议：
   - Room 2：DB / API candidate seams
   - Room 3：BR gate / exit / fact-boundary rules
   - Room 5：UI candidate migration / forbidden claims / source-neutral state contract
   - Room 1：统一吸收为 close-preflight 或 R1→R4 execution handoff
3. 当前不得写成：
   - 本轮已完成迁移
   - 旧 cloud path 可直接清理
   - DB/API 可同步升级为新 active baseline

---

## 3. 给 Room4-治理层的任务定义

### 3.1 目标
完成 P3.3.8 的 **Phase 3 / Gate-Driven Candidate Execution + Migration Prep**，具体包括：

1. 固化 proceed / hold / revise / escalate 的 gate 证据与 stop conditions
2. 把 limited cutover subset 收成 candidate seam / migration subset，而不是 source switch
3. 把 DB / API candidate framing、rollback floor、hold note、write-back order 落地为可执行准备层
4. 写硬 `review_group` 真实退场判断前仍缺的条件
5. 写硬 final fact / settlement 继续以后端为准的边界
6. 固定 UI source-neutral migration path 与 forbidden claims
7. 交付 regression / write-back / no-major-change 的固定证据包

### 3.2 In Scope
1. gate evidence consolidation
2. proceed / hold / revise / escalate 分类固化
3. stop-condition 与 must-hold / must-escalate 条件固化
4. candidate seam / migration subset 明确化
5. DB/API candidate framing 的 patch-draft / seam-map / hold-note / rollback floor
6. `review_group` exit gate 前置条件清单
7. final fact / settlement boundary guardrails
8. UI copy neutralization / source-neutral state prep / forbidden claims 收口
9. regression / write-back / no-major-change statement

### 3.3 Out of Scope
1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 接管 current ReviewPage truth
4. `review_group` 退出运行态
5. auto-routing runtime
6. unified planner / planner merge
7. unified Study / Review page
8. DB schema 重构
9. API core semantics 重写
10. 用户可见“已切到本地规划 / 已接管复习 / 已自动安排路径”的宣告

---

## 4. 必守依据

Room4-治理层与执行层，本轮必须同时服从以下依据：

### 4.1 推进层 / 主线程
- `Main_updated_2026-04-10_v28.md`
- `STATUS_updated_2026-04-10_v26.md`
- `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md`

### 4.2 规则 / 事实边界
- `BR-OPP-001_v0.2.9.md`
- `R3_P3_3_8_Phase3Gate_and_CutoverDecision_Rules_Note_v0.1.md`

### 4.3 技术边界
- `R2_P3_3_8_Phase3Gate_and_DB_API_Candidate_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 4.4 UI / UX 边界
- `UI_SPEC_v0.2.9.md`
- `UI_SPEC_P3_3_8_Phase3Gate_and_CutoverDecision_UI_Preflight_v0.1.md`

---

## 5. Room 4 不得补脑的已收口项

以下点本轮 Room 1 已收口，Room 4 不得二次发明：

1. current runtime truth 继续不变
2. ReviewPage current serving truth 继续围绕 cloud `review_group`
3. `review_group` 当前仍是 current owner + compatibility anchor + deprecated candidate
4. local-serving / routing / ingest 当前只到 candidate / migration / gate 层
5. final fact / settlement truth 继续以后端为准
6. 首页继续 `study_default`
7. active continuation 继续高优先但不得 silent reroute
8. DB / API 仍不进入 core rewrite
9. 一切 gate 结果都不得冒充 cutover 已完成
10. 用户端不得感知“新 serving 已生效”

---

## 6. Room 4 执行护栏

### 6.1 Serving / Owner 护栏
当前继续禁止：
- local 已接管 ReviewPage
- 当前复习队列来自 local due
- `review_group` 已退出运行态
- current ReviewPage 已不再依赖 `review_group`
- owner shift 已完成
- local-serving cutover 已完成

### 6.2 Routing 护栏
当前继续禁止：
- 系统已自动判断今天先复习
- 默认入口已改为 planner-aware
- mixed routing 已启用
- 点击背单词会按本地规划自动改路由
- candidate routing 已对用户生效

### 6.3 Fact / Settlement 护栏
当前继续禁止：
- 已记为有效复习
- 今日目标已推进
- 奖励已到账
- streak 已续上
- 学习事实已更新到最终结果
- local evidence 已成为 final fact

除非 backend fact layer 已明确返回对应 final truth。

### 6.4 Migration / Exit 护栏
当前继续禁止：
- `review_group` 已退场
- 旧方案即将不可用
- 当前已不再使用 `review_group`
- 当前已完成兼容切换
- 本轮已完成迁移
- 可直接清理旧 cloud path

### 6.5 Major 红线
以下任一动作出现，都视为越界：
1. 把 local candidate 写成 current ReviewPage truth
2. 把 `review_group` 写成已退出运行态
3. 让 local evidence 直接改 final fact / settlement
4. 开启用户可见 auto-routing
5. 改 DB schema
6. 改 API core semantics
7. 把 gate / candidate 结果写成用户承诺事实
8. 把 Phase 3 delivery 写成 owner shift completed

---

## 7. 推荐执行方式（Room 4 本轮）

### Track A — Gate Consolidation
做：
1. proceed / hold / revise / escalate 证据固化
2. must-hold / must-escalate / stop-condition 固化
3. parity / mismatch / rollback-floor 的证据包整理

不做：
- cutover proceed
- runtime truth 切换

### Track B — Candidate Seam / DB-API Prep
做：
1. candidate seam map
2. ingest seam stronger-path candidate map
3. DB/API hold-note / rollback floor / migration note
4. no-major-change statement

不做：
- schema rewrite
- endpoint semantics rewrite
- new active baseline 宣告

### Track C — `review_group` Exit Gate Prep
做：
1. `review_group` 退场前置条件清单
2. current owner + compatibility anchor + deprecated candidate 三层姿态固化
3. 与 write-back 次序、测试条件、boundary 条件联动

不做：
- 宣告“可退场”
- 清理旧 cloud path

### Track D — UI Migration Prep
做：
1. helper / summary / CTA / empty-state 的 source-neutral copy prep
2. state contract neutralization
3. forbidden claims 清单固化
4. hold / rollback / migration note 的 UI 说明模板

不做：
- 用户可见 owner shift / cutover / auto-routing 宣告
- 把 candidate migration 写成已生效

---

## 8. 必测项

Room 4 本轮至少覆盖以下测试 / 自测：

### 8.1 Runtime Truth Regression
1. 首页继续 `study_default`
2. active continuation 继续独立承接
3. ReviewPage 继续以 cloud `review_group` 为当前 serving truth
4. current ReviewPage 主队列未被 local due 接管
5. 用户端继续不出现“local serving enabled / owner shift completed / cutover completed”类事实

### 8.2 Gate / Candidate 层
1. proceed / hold / revise / escalate 分级存在
2. must-hold / must-escalate / stop-condition 可断言
3. candidate seam map 存在
4. rollback floor / hold note / migration note 存在
5. no-major-change statement 存在

### 8.3 `review_group` Exit Gate
1. `review_group` 仍是 current runtime owner
2. `review_group` 同时具备 compatibility anchor / deprecated candidate 标记
3. 未出现 “已退场 / 已可退场 / 可清理旧 path” 的实现或文案
4. exit 前置条件清单完整

### 8.4 Fact / Settlement Boundary
1. local evidence 不直接改 ledger
2. local evidence 不直接改 daily goal final state
3. local evidence 不直接改 streak / learning day final fact
4. final fact 仍以后端为准的断言存在
5. UI / helper 不出现 overclaim

### 8.5 UI Migration Prep
1. source-neutral copy prep 完成
2. state contract neutralization 不漂移 current runtime truth
3. forbidden claims 清单完整
4. migration / rollback / hold UI note 模板存在

---

## 9. 交付物要求

Room4-治理层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **current runtime truth 是否保持不变**
5. **gate / candidate / migration / rollback / hold 证据包**
6. **`review_group` exit gate 前置条件是否完整**
7. **fact / settlement boundary 是否守住**
8. **UI migration prep 是否无用户可见漂移**
9. **是否触碰核心契约的判断**
10. **no-major-change statement**
11. **需要哪些文档回写**
    - BR / UI / Main / Status / DB / API / TEST / 其他
12. **是否可 close / 是否需 revise / 是否需 escalate**

---

## 10. Room 1 预期完成定义（Done）

当 Room4-治理层交回结果，且满足以下条件时，Room 1 认为 P3.3.8 本轮可以进入 absorb / close 判断：

1. Phase 3 gate / candidate / migration 的 very narrow subset 已落地
2. current runtime truth 未被偷切
3. `review_group` current owner + compatibility anchor + deprecated candidate 姿态被守住
4. local-serving / routing / ingest 仍停留在 candidate / migration / gate 层
5. final fact / settlement boundary 已被继续写硬
6. UI migration prep 已完成且无用户可见 overclaim
7. rollback / hold / migration note 与 no-major-change statement 齐备
8. 未触碰 DB schema / API core semantics / runtime routing / final fact owner

---

## 11. 一句话 handoff

> **请 Room4-治理层按“Phase 3 / Gate-Driven Candidate Execution + Migration Prep”的 very narrow subset 推进 P3.3.8：把 gate 证据、candidate seams、`review_group` exit gate、fact/settlement boundary、UI migration prep 与 rollback/hold/write-back 真实写硬，但 current runtime truth 继续不变；不要把本轮做成 cutover，更不要把 gate / candidate / migration 结果写成用户可依赖事实。**
