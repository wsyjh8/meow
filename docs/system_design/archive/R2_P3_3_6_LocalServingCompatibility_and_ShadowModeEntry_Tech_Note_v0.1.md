# R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Type:** tech note / compatibility-contract framing / shadow-mode entry round
- **Status:** ready for Room 1 review
- **Version:** v0.1
- **Date:** 2026-04-10
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.6 — Local-Serving Compatibility Contract / Shadow-Mode Entry Round`

---

## 0. 文档定位

本稿不是：
- 新 DB 主文档
- 新 API 主文档
- Room 4 执行单
- runtime owner shift 完成宣告
- local-serving cutover 方案书
- unified planner / planner merge 直接落地稿

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.6 收成 Phase 1 compatibility contract：明确 local-serving 候选合同、`review_group` 兼容姿态、fact / settlement ingest 候选、routing 兼容边界、deprecation / write-back 技术落点，以及 shadow / parity 测试策略；但当前仍不宣告 runtime owner shift 完成。**

一句话：

> **P3.3.6 值得推进，但只应推进到“更近执行、仍不 cutover”的 compatibility-contract 层。**

---

## 1. 输入依据与采用口径

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md`
- `p3.3.6_user.md`

### 1.3 Review basis for this round
- `BR-OPP-001_v0.2.7.md`
- `UI_SPEC_v0.2.7.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 1.4 Runtime truth note
- 当前 runtime 主线程刚完成 `P3.3.5 closed / absorbed`。
- 当前运行态不要把 `review basis = v0.2.7` 误写成 “已由 Room 1 pin 成新的 runtime truth”。
- 当前这轮 Room 2 的任务是给 Room 1 一个 **可 pin / 可不 pin** 的 Phase 1 compatibility contract 候选集合，而不是直接改写 current runtime owner。

---

## 2. Room 2 总判断

### 2.1 一句话结论
> **应该前进一步；但只建议进入 `Compatibility Contract v1`，不建议直接进入 Phase 2 shadow execution，更不建议提前触发 Phase 3 cutover。**

### 2.2 为什么值得继续推进
因为如果 P3.3.6 仍停在 P3.3.5 的 target-state candidate，不回答以下问题，后续 owner-shift 会继续卡住：
1. ReviewPage future local-serving 到底以什么最小队列模型出现
2. `review_group` 在 Phase 1 之后究竟是 current runtime owner 还是 compatibility-only owner
3. local-serving 产生的 attempt / completion / progress 如何进入 cloud fact layer
4. routing 如何 shadow 化，而不是直接 auto-routing 化
5. deprecation / write-back / parity 不先写硬，后面一定出现 silent contract drift

### 2.3 为什么当前不能走更深
因为当前仍存在以下硬边界：
1. current runtime truth 仍在 cloud review-serving layer
2. DB / API active baselines 仍是 `v0.2.1`
3. `review_group` 最小合同仍在运行态承担 serving truth
4. planner owner shift 从来不自动带出 fact owner shift
5. 本轮 handoff 明确写死：P3.3.6 是 contract / architecture round，不是 cutover round

---

## 3. Room 2 正式推荐进入层

### 3.1 推荐进入：`Compatibility Contract v1`
Room 2 当前建议 Room 1 若要 pin，本轮只 pin 到以下层级：

1. **local-serving 候选模型的最小接口层**
2. **`review_group` compatibility posture 的最小分层**
3. **fact / settlement ingest 的最小接口层**
4. **routing compatibility / shadow-only marker 层**
5. **deprecated-candidate / compatibility-only / write-back plan 层**
6. **shadow / parity test strategy 的最小固定集**

### 3.2 推荐不进入：`Cutover / Runtime Rewrite`
本轮不建议进入：
1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 接管当前页面真相
4. `review_group` 退出运行态
5. auto-routing runtime
6. unified planner / planner merge
7. API core semantics rewrite
8. DB schema rewrite

---

## 4. Q1 — `local_serving_candidate_contract_v1`

### 4.1 Room 2 结论
> **可以正式推进，但只推进到“最小 serving interface + truth split + shadow eligibility”层。**

### 4.2 最小技术合同建议
当前建议 local-serving candidate 至少拆成两类：

#### A. `local_due_queue_candidate`
表示未来由本地 FSRS 计算得出的可服务复习项集合，但当前只允许进入：
- shadow candidate
- compatibility contract
- parity comparison input

不允许当前直接进入：
- ReviewPage current serving truth
- 直接替代 `review_group`
- current runtime completion / settlement trigger

#### B. `local_generated_review_session_candidate`
表示未来 local planner 为一次复习会话生成的候选 serving 包装，当前只允许进入：
- candidate data model
- adapter seam
- future feature-flag mount point

不允许当前直接进入：
- 用户可见 current runtime route
- current ReviewPage 主队列
- `next review group` 的直接替代物

### 4.3 ReviewPage future queue source 最小字段层
本轮建议只冻结“字段组类别”，不冻结完整 DTO：
1. `source_type`：cloud_group / local_due_shadow / local_generated_shadow
2. `source_id`
3. `owner_layer`：planning / serving / factSettlement
4. `shadow_only`
5. `candidate_reason`
6. `generated_at`
7. `item_count`
8. `serving_eligibility_state`

说明：
- 当前只冻结这些字段组的**存在必要性与语义边界**。
- 具体字段名、DTO 形状、索引、迁移与接口示例，按 role card 继续由 Room 4 在执行前先起草，Room 2 再做收口。

### 4.4 进入 compatibility contract vs 只进 shadow 的分界
**可进 compatibility contract：**
- local-serving candidate 的概念实体
- source_type / owner_layer / shadow_only 这类元语义
- serving eligibility 与 current truth 的边界
- future adapter seam

**只进 shadow，不进 runtime：**
- local due list 的真实 serving 顺序
- local generated session 的真实用户承接
- local candidate 对 ReviewPage item stream 的直接接管
- local candidate 触发 completion / settlement 的链路

---

## 5. Q2 — `review_group_compatibility_posture_v1`

### 5.1 Room 2 结论
> **P3.3.6 最稳的写法，不是把 `review_group` 从 current owner 直接降成 compatibility-only；而是明确它现在仍是 current runtime serving owner，同时正式进入 `deprecated candidate + compatibility anchor` 姿态。**

### 5.2 推荐 posture
当前建议将 `review_group` 定义成三层并存：

1. **runtime serving owner（当前仍成立）**
   - ReviewPage current queue source
   - continuation / completion / settlement 的当前 serving 主链路

2. **compatibility anchor（Phase 1 建立）**
   - 为 Phase 2 shadow / parity 提供对照真相层
   - 为 future local-serving adapter 提供兼容基座

3. **deprecated candidate（仅标记，不退场）**
   - 可以开始在文档 / helper / code comments / adapter seams 中标记 future deprecation candidate
   - 但当前不删除，不降级 current runtime owner 身份

### 5.3 当前仍依赖 `review_group` 的范围
本轮建议 Room 1 若要 pin，应明确以下仍依赖 `review_group`：
1. ReviewPage current serving list
2. active continuation 判断
3. group completion gating
4. current progress / settlement 关联承接
5. current cloud-first submit flow

### 5.4 哪些点可正式标成 deprecated candidate
可以标，但只标到“候选层”：
1. `get next review group` 这类 future serving entry 的命名中心性
2. 页面 helper 中把 `review_group` 包装成长期唯一 serving owner 的表达
3. 任何把 cloud generation 写成未来长期唯一生成器的隐含假设

不能当前就标成已退场：
- current ReviewPage runtime
- completion / settlement 主链路
- 页面 current truth 文案

---

## 6. Q3 — `fact_settlement_ingest_contract_candidate_v1`

### 6.1 Room 2 结论
> **这是 P3.3.6 最应该先收硬的一层。当前建议正式推进，并冻结成 `Phase 1 minimal ingest boundary`。**

### 6.2 为什么必须先写
因为 future serving 往 local 靠以后，最危险的误判就是：
- 以为 local 既可以出队列，也可以顺手裁定有效复习事实
- 以为 local completion 自动等于今日目标推进、奖励到账、streak / learning_day 变化

这会直接撞穿当前 cloud fact layer。

### 6.3 最小 ingest 合同建议
Room 2 当前建议只冻结到以下接口语义层：

#### A. `local_attempt_evidence`
由 local-serving candidate 产出的最小尝试证据包，进入 cloud fact layer ingest 前，只是 evidence，不是 final fact。
建议至少包含：
- local source id
- card / item id
- rating input
- attempt timestamp
- planner metadata snapshot（极小）
- shadow flag
- runtime source marker

#### B. `cloud_fact_ingest_result`
cloud fact layer 接收 local evidence 后，返回的仍应是：
- accepted / rejected / ignored / duplicate
- fact impact summary
- settlement impact summary
- reason code

#### C. `fact_owner_boundary`
本轮应继续明确以下仍以后端为准：
- effective review fact
- daily goal progress impact
- reward settlement impact
- streak / learning_day / check-in final effect
- current ledger /账本最终状态

### 6.4 当前不能推进的内容
1. local 直接写最终结算结果
2. local 直接裁定 `valid review`
3. local 直接改写今日目标最终状态
4. local 直接绕过 ingest 调云端账本

---

## 7. Q4 — `session_entry_and_routing_compat_v1`

### 7.1 Room 2 结论
> **可推进，但只推进到“shadow-aware compatibility”层；当前 runtime 继续保持 `study_default`。**

### 7.2 当前建议
1. 首页 runtime 继续保持 `home_word_entry = study_default`
2. active continuation 继续高优先，但仍以当前独立承接方式存在
3. 可以开始定义 `shadow_routing_candidate`，用于 future local-serving 与 current runtime 的对照
4. auto-routing 继续 pending

### 7.3 哪些能进 shadow
1. local-serving 若成为更优候选时的影子 routing judgment
2. continuation 与 local due candidate 并列时的 shadow winner calculation
3. future planner-aware entry 的 hidden decision evidence

### 7.4 哪些必须继续 pending
1. 用户可见 auto-routing
2. 默认入口从 `study_default` 直接切为 planner-aware
3. ReviewPage 自动接管 local due
4. mixed routing runtime

---

## 8. Q5 — `deprecation_markers_and_writeback_plan_v1`

### 8.1 Room 2 结论
> **应该正式推进，而且必须跨 BR / DB / API / UI / TEST 一起推进；否则这轮没有治理价值。**

### 8.2 技术落点建议

#### A. API 层
当前只允许进入：
- deprecated candidate markers
- compatibility comments / annotations
- future adapter seam 说明

当前不允许进入：
- core semantics 改写
- endpoint 删除
- 返回结构破坏性调整

#### B. DB / Data Plan 层
当前只允许进入：
- candidate entity / field-group planning
- compatibility mapping note
- migration placeholder

当前不允许进入：
- schema rewrite
- destructive migration
- current active store owner rewrite

#### C. UI / Helper / State Contract 层
当前允许：
- current truth vs future candidate 文案隔离
- deprecated candidate 标记
- compatibility-only helper 定义
- shadow marker 语义

#### D. TEST 层
当前必须开始固定：
- 哪些测试是 runtime truth regression
- 哪些测试是 shadow parity evidence
- 哪些测试只验证 marker / contract，不验证 cutover

### 8.3 防止 silent contract drift 的最小做法
本轮建议 Room 1 若要 pin，应要求所有下游后续执行都显式标记：
1. `runtime truth`
2. `compatibility-only`
3. `deprecated candidate`
4. `shadow-only evidence`

任何一个 patch 若同时跨过两层以上，都应视为 Major。

---

## 9. Q6 — `shadow_parity_test_strategy_v1`

### 9.1 Room 2 结论
> **可正式推进；而且这是 P3.3.6 最值钱的“准备动作”。**

### 9.2 最小 flags / seams 建议
本轮只建议冻结 flags / seams 的类别，不建议直接启用：
1. `localServingShadowEnabled`
2. `localServingParityCompareEnabled`
3. `localServingShadowRoutingEnabled`
4. `reviewGroupCompatibilityMode`
5. `localFactIngestShadowEnabled`

要求：
- 默认全关
- 不得改变 runtime truth
- 只产生 shadow evidence / parity evidence

### 9.3 parity checks 至少比什么
1. queue candidate size / emptiness
2. item identity overlap
3. continuation eligibility judgment
4. submit after-effects 的 evidence 完整性
5. fact ingest accept / reject / duplicate 行为一致性

### 9.4 哪些结果只能写成 shadow evidence
1. local candidate 看起来更合理
2. local candidate 与 cloud candidate 大体一致
3. local-routing 影子判断更优
4. local ingest evidence 可被云端接受

这些都 **不能** 写成：
- owner shift 已完成
- local 已接管 ReviewPage
- `review_group` 已退场
- auto-routing 已上线

### 9.5 Phase 1 应先固定的回归集
建议至少固定 4 组：
1. current cloud-first ReviewPage regression
2. continuation / completion / settlement regression
3. backup / restore / sync semantics regression
4. shadow marker / parity evidence non-user-visible regression

---

## 10. Room 2 推荐不进入层

以下内容当前明确建议不进入 P3.3.6：
1. runtime owner shift completed
2. local-serving runtime cutover
3. `review_group` removal
4. auto-routing runtime
5. planner merge / unified planner
6. ReviewPage preview re-entry
7. explanation system 升格为 committed plan fact
8. DB schema rewrite
9. API core semantics rewrite
10. 任何会让 current runtime truth 漂移的 feature-on 行为

---

## 11. Major 红线

以下任一动作出现，都应视为越界到 Phase 2 / Phase 3 或 DB/API Major：

1. 把 local due queue 写成 current ReviewPage truth
2. 把 `review_group` 从 current runtime owner 直接降成已退场
3. 让 local evidence 直接改账本 / 改今日目标 / 改 streak
4. 开启用户可见 auto-routing
5. 改 `/me/today`、review-serving、review-attempt 之类核心语义
6. 触发 schema 级重构
7. 把 shadow / parity 结果写成 runtime fact

---

## 12. Phase 1 compatibility contract 候选集合

Room 2 当前建议，若 Room 1 要 pin，最稳的集合是：

1. `local_serving_candidate_contract_v1`
2. `review_group_compatibility_posture_v1`
3. `fact_settlement_ingest_contract_candidate_v1`
4. `session_entry_and_routing_compat_v1`
5. `deprecation_markers_and_writeback_plan_v1`
6. `shadow_parity_test_strategy_v1`

但 pin 时应附带统一注记：
- **current runtime truth 不变**
- **shadow / compatibility ≠ owner shift completed**
- **DB / API 仍不进入 core rewrite**

---

## 13. future Phase 2 shadow-entry 前置条件

Room 2 当前建议，只有在以下条件都满足后，才值得讨论进入 future Phase 2：

1. `Compatibility Contract v1` 已被 Room 1 正式 pin
2. BR / UI / TEST 至少完成一轮 write-back / 同边界吸收
3. `review_group` compatibility posture 已被 cross-room 统一，不再各写一套
4. fact / settlement ingest boundary 已有最小可测试接口
5. shadow flags / parity checks / regression buckets 已形成统一入口
6. user / Room 1 明确接受“进入 shadow 但不等于 cutover”的推进口径

---

## 14. Room 2 一句话结论

> **P3.3.6 应推进，但只应推进到 `Compatibility Contract v1`：先把 local-serving candidate、`review_group` compatibility、fact ingest、routing compat、deprecation/write-back 与 shadow/parity 六层写硬；当前不进入 runtime owner shift，不进入 local-serving cutover，不进入 DB / API core rewrite。**
