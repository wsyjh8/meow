# R4_P3_3_8_Execution_Plan_v0.1.md

- **Owner:** Room 4（治理层）
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** ready for execution
- **Role basis:** `ROOM04_治理版_v0.2.md`
- **Direct upstream input:** `R1_to_R4_P3_3_8_Execution_Handoff_v0.1.md`

---

## 0. 一句话定位

本稿不是代码实现记录，也不是新的 BR / DB / API / UI 主文档。  
本稿只做一件事：

> **把 Room 1 已经收口完成的 P3.3.8 结论，压成一份可直接交给 Room 4 执行层（Claude Code）的短而硬执行任务单。**

---

## 1. Room 4 当前判断

### 1.1 本轮是否可以开工
> **可以开工。**

### 1.2 本轮开工的性质
> **这是 `Phase 3 / Gate-Driven Candidate Execution + Migration Prep` 的 very narrow landing，不是 runtime owner shift / local-serving cutover。**

### 1.3 Room 4 采用口径
- 继续服从 **Room 1 已 pin / 已指定的 review basis**
- 不自动把 `BR/UI v0.2.9` 写成 runtime active truth
- `DB/API v0.2.1` 继续视为 current active baseline 起点
- 本轮只推进：
  - gate evidence consolidation
  - candidate seam / migration marker / rollback floor prep
  - `review_group` exit gate 前置项显式化
  - fact / settlement cutover boundary evidence-path 固化
  - UI source-neutral migration prep
  - regression / write-back / no-major-change statement
- 不推进：
  - runtime owner shift completed
  - ReviewPage local-serving runtime cutover
  - `review_group` runtime 退场
  - auto-routing runtime
  - unified planner / planner merge
  - DB schema rewrite
  - API core semantics rewrite

### 1.4 本轮是否需要先升级
> **默认不需要先升级。**

但若执行层在实现中发现以下情况，必须立即升级，不得自行补脑推进：

1. 需要改 DB schema  
2. 需要改 API core semantics  
3. 需要改 `review_group` 最小合同  
4. 需要把 local-serving candidate 写成 current ReviewPage truth  
5. 需要让 local 直接改 final fact / settlement / ledger / streak / daily goal  
6. 需要把首页“背单词”做成 silent reroute / auto-routing runtime  
7. 需要把 `review_group` 写成已退场 / 已被 local 替代  
8. 需要把 shadow / candidate / parity evidence 写成用户可依赖事实  
9. 需要把本轮做成 unified planner / planner merge / full cutover  

---

## 2. 本轮目标

完成 **P3.3.8 — Phase 3 Gate / Cutover-Decision + DB/API Candidate Round** 的 **Gate-Driven Candidate Execution + Migration Prep**，具体包括：

1. 固化 `phase3_gate_decision_v1`
2. 固化 `limited_cutover_scope_candidate_v1`
3. 固化 `db_api_candidate_round_v1`
4. 固化 `review_group_exit_gate_v1`
5. 固化 `fact_settlement_cutover_boundary_v1`
6. 固化 `phase3_writeback_and_migration_v1`
7. 交回 patch / sync draft 与 `no-major-change statement`

---

## 3. In Scope

### 3.1 Gate / Decision
本轮纳入：
1. proceed / hold / revise / escalate 的 gate 逻辑与证据归档
2. `shadow_acceptance_gate_v1` 与 `shadow_to_phase3_gate_v1` 的延续吸收
3. must-hold / must-escalate / acceptable mismatch 的继续显式化
4. cutover-decision 所需最低证据集合整理

### 3.2 Candidate Seam / Migration Prep
本轮纳入：
1. candidate seam formalization
2. ingest seam strengthening candidate
3. helper / summary / state contract migration prep
4. migration marker / deprecated marker / rollback floor / hold-note
5. source-neutral copy / helper / CTA / summary prep

### 3.3 `review_group` / fact / routing 下一层判断
本轮纳入：
1. `review_group_exit_gate_v1`
2. `fact_settlement_cutover_boundary_v1`
3. `session_entry_and_routing` 的 source-neutral / shadow-only / candidate 继续显式化
4. current runtime truth 与 future candidate 的边界写硬

### 3.4 DB / API Candidate Round
本轮纳入：
1. DB / API seam candidate
2. migration marker
3. rollback floor
4. hold-note
5. write-back order
6. code-side patch draft / note draft

### 3.5 Regression / Write-back
本轮纳入：
1. runtime truth regression
2. shadow / parity / candidate regression
3. write-back 次序草案
4. no-major-change statement

---

## 4. Out of Scope

1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 接管 current ReviewPage truth
4. `review_group` 退出运行态
5. auto-routing runtime
6. mixed routing runtime
7. unified planner / planner merge
8. unified Study / Review page
9. DB schema rewrite
10. API core semantics rewrite
11. local 直接写 final fact / settlement / ledger / streak / daily goal
12. preview / explanation 升格为 committed plan fact
13. 用户可见 cutover 宣告
14. Phase 4 / true cutover 行为

---

## 5. 必守依据

### 要按需读文档，不需要一次性读完

### 5.1 推进层 / 主线程
- `R1_to_R4_P3_3_8_Execution_Handoff_v0.1.md`
- `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md`
- `Main_updated_2026-04-10_v28.md`
- `STATUS_updated_2026-04-10_v26.md`

### 5.2 规则 / 事实边界
- `BR-OPP-001_v0.2.9.md`
- `R3_P3_3_8_Phase3Gate_and_CutoverDecision_Rules_Note_v0.1.md`

### 5.3 技术边界
- `R2_P3_3_8_Phase3Gate_and_DB_API_Candidate_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 5.4 UI / UX 边界
- `UI_SPEC_v0.2.9.md`
- `UI_SPEC_P3_3_8_Phase3Gate_and_CutoverDecision_UI_Preflight_v0.1.md`

### 5.5 治理依据
- `ORG_v0.3.1.md`
- `ROOM04_治理版_v0.2.md`

---

## 6. Room 4 不得补脑的已收口项

以下点本轮已被 Room 1 收口，Room 4 不得二次发明：

1. **P3.3.8 是 Gate / Candidate / Migration Round，不是 cutover round**
2. **current runtime truth 仍在 cloud review-serving layer**
3. **`review_group` 当前仍是 current runtime serving owner**
4. **`review_group` 当前同时是 compatibility anchor + deprecated candidate，但不是已退场**
5. **首页继续 `home_word_entry = study_default`**
6. **active continuation 继续高优先，但不得 silent reroute**
7. **planner / serving owner shift 不自动带出 fact / settlement owner shift**
8. **shadow / candidate / parity evidence 不得被写成用户当前可依赖事实**
9. **当前 DB / API active baselines 仍是 `v0.2.1`，本轮只许 candidate framing**
10. **本轮必须有 write-back 次序、migration note、rollback floor、hold note、no-major-change statement**

---

## 7. Room 4 执行护栏

### 7.1 `phase3_gate_decision_v1` 护栏
当前允许输出：
- `proceed_to_next_layer_candidate_review`
- `hold`
- `revise`
- `escalate`

当前禁止输出：
- `runtime_owner_shift_completed`
- `local_serving_cutover_completed`
- `review_group_exited`
- `unified_planner_established`

### 7.2 `limited_cutover_scope_candidate_v1` 护栏
当前允许进入：
- candidate seam formalization
- ingest seam strengthening candidate
- helper / summary / state contract migration prep
- rollback / hold / migration note baseline

当前禁止进入：
- ReviewPage current queue source switch
- runtime routing switch
- final fact owner switch

### 7.3 `db_api_candidate_round_v1` 护栏
当前允许进入：
- seam candidate
- migration marker
- rollback floor
- hold-note
- write-back order

当前禁止进入：
- schema rewrite
- endpoint core semantics rewrite
- active baseline uplift to new owner-shift reality
- 把 candidate 写成 current API/DB runtime truth

### 7.4 `review_group_exit_gate_v1` 护栏
当前必须继续同时保持：
1. **current runtime serving owner**
2. **compatibility anchor**
3. **deprecated candidate**

当前只允许回答：
- 还缺什么才有资格进入真实退场判断

当前禁止写成：
- 已退场
- 即将退场
- 已不再使用
- 可直接清理旧 path

### 7.5 `fact_settlement_cutover_boundary_v1` 护栏
当前以下最终事实继续必须以后端 / cloud fact layer 为准：
- 有效复习事实
- 今日目标完成
- 奖励结算 / 账本到账
- `check_in / learning_day / streak`

当前 local-serving evidence / parity result / ingest candidate：
- 只允许进入 evidence / candidate ingest path 讨论
- 不得冒充这些最终事实
- serving source 也不得先于 fact boundary 被偷切

### 7.6 UI / Copy / Overclaim 护栏
以下表达本轮不得出现于用户侧：
- 本地已接管复习
- 当前复习来自本地队列
- 已切换到本地复习模式
- `review_group` 已退场
- 系统已自动分流
- 已为你安排最佳入口
- 已自动完成规划切换
- 当前已使用新方案
- 已切到本地规划
- 已接管奖励结算
- shadow / candidate / parity 已对你生效

### 7.7 Routing / Entry 护栏
当前继续保持：
- `home_word_entry = study_default`
- active continuation 独立承接
- 不得 silent reroute

当前只允许进入：
- source-neutral helper / summary / CTA migration prep
- shadow-only / compatibility-only routing markers

当前禁止：
- auto-routing runtime
- planner-aware 默认入口
- 任何会改变用户主路径的 candidate 决策

### 7.8 Stop-condition 护栏
以下任一出现，本轮不应继续扩大 execution：
1. runtime truth leakage
2. feature flag 非预期开启
3. shadow / candidate evidence 影响 final fact / settlement
4. ReviewPage 行为偏离 cloud-first runtime
5. auto-routing 以任何形式进入用户路径
6. `review_group` posture 被破坏
7. candidate framing 必须先改 DB schema / API core semantics 才能成立

---

## 8. Gate / Migration 最低要求（本轮必须写硬）

### A. Proceed 条件
满足以下条件时，才允许记为 `proceed_to_next_layer_candidate_review`：
1. current runtime truth guardrails 继续全绿
2. P3.3.7 shadow evidence 可重复、可归类、可回归
3. DB/API candidate round 只动 seam framing，不动 current active core semantics
4. `review_group` exit 仍明确 gated
5. write-back / migration / rollback / hold-note 可形成最小完整包

### B. Hold 条件
出现以下任一项，至少记为 hold：
1. candidate framing 需要立即改 schema / core semantics
2. helper / summary / CTA 已开始依赖 local-serving candidate 结果
3. `review_group` posture 表达不再稳定
4. fact-boundary 写不硬
5. rollback floor 无法成立

### C. Escalate 条件
出现以下任一项，必须升级给 Room 1 / User / Room 2：
1. limited cutover subset 会改变版本范围
2. 需要新的用户可见状态 / 模式声明
3. 需要 destructive restore / sync / cleanup bundle
4. 需要提前改掉 `review_group` current owner 身份
5. 需要改 DB schema / API core semantics

### D. Revise 条件
出现以下情况，可要求执行层 revise：
1. migration / rollback / hold-note 结构不完整
2. write-back 次序不清
3. source-neutral copy 仍有 overclaim
4. candidate 与 current truth 混写
5. evidence 存在但不可解释

---

## 9. 本轮最小执行策略（Room 4 默认采用）

执行层本轮如果要做 Gate-Driven Candidate Execution，只允许：

1. **先做 gate evidence consolidation，不切 runtime truth**
2. **先做 candidate seam / migration marker / rollback floor / hold-note**
3. **先把 `review_group` exit gate 的前置项显式化**
4. **先把 fact / settlement guardrails 写硬**
5. **先把 helper / summary / CTA 做 source-neutral migration prep**
6. **先交 patch / sync draft 与 no-major-change statement**
7. **不做任何 runtime cutover 行为**

---

## 10. 必测项

### 10.1 Gate / Proceed / Hold / Escalate
1. gate 只会输出 proceed / hold / revise / escalate
2. 不会输出 cutover completed 级结论
3. hold / escalate 触发器可被明确引用
4. proceed 证据条件可被测试或证据包引用

### 10.2 `review_group_exit_gate_v1`
1. `review_group` current runtime owner 仍成立
2. compatibility anchor marker 仍成立
3. deprecated candidate marker 仍成立
4. 不会被写成已退场 / 已删除 / 已被 local 替代
5. exit gate 的 contract/test/doc/boundary 四类前置项被显式列出

### 10.3 Fact / Settlement Boundary
1. local candidate / parity / ingest evidence 不会直写 final fact / settlement / ledger
2. 不会直写 `daily_goal_status`
3. 不会直写 `check_in / learning_day / streak`
4. 不会把 stronger ingest path 写成当前 active truth

### 10.4 Routing / UI Migration
1. 首页“背单词”默认继续进入 `StudyPage`
2. active continuation 仍独立承接
3. 没有 silent reroute
4. helper / summary / CTA 只做 source-neutral migration prep
5. 不出现 local-serving / owner shift / cutover overclaim

### 10.5 No-major-change 验证
1. 未改 DB schema
2. 未改 API core semantics
3. 未改 `review_group` 最小合同
4. 未发生 runtime owner shift
5. 未发生 local-serving cutover
6. 未引入 auto-routing / unified planner
7. 已给出 rollback floor / hold-note / migration note / no-major-change statement

---

## 11. 执行层交付物要求

执行层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **gate / candidate / migration / rollback / hold-note 是否都守住了边界**
5. **是否触碰核心契约的判断**
6. **是否需要升级**
7. **需要哪些文档回写**
   - BR / UI / DB / API / Main / Status / 其他
8. **是否可 accept / revise / escalate / hold**
9. **`no-major-change statement`**

---

## 12. Room 4 验收判断口径

只有同时满足以下条件，Room 4 才会给出 `accept / 可 closeout` 倾向：

1. `phase3_gate_decision_v1` 已以 proceed / hold / revise / escalate 的最小 gate 层落地
2. `limited_cutover_scope_candidate_v1` 已以 candidate seam / migration subset 方式落地
3. `db_api_candidate_round_v1` 已以 seam candidate / migration marker / rollback floor / hold-note 方式落地
4. `review_group_exit_gate_v1` 已把“还缺什么”写硬，但未把 `review_group` 写成已退场
5. `fact_settlement_cutover_boundary_v1` 已把 final-truth guardrails 写硬
6. `phase3_writeback_and_migration_v1` 已形成最小 write-back / migration / rollback / hold-note / no-major-change 包
7. 未越界触碰 DB / API / `review_group` / planner owner / final fact owner
8. 未把 shadow / candidate / compatibility 写成 current runtime truth
9. 已交 patch / sync draft 与 `no-major-change statement`

---

## 13. 给执行层的一句话

> **请按“Phase 3 / Gate-Driven Candidate Execution + Migration Prep”的边界推进 P3.3.8；把 shadow evidence 转成 gate / candidate / migration / rollback / hold-note 的可执行包，但不要把任何 candidate 或 migration 结果写成 cutover 已成立，更不要改当前 runtime truth。**
