# R3_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / compatibility contract / shadow-mode entry round
- **Status:** ready for Room 1 review
- **Date:** 2026-04-10
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis for this round:** `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md` 指定的 review basis
- **Direct upstream inputs:**  
  - `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md`  
  - `R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.6 当前轮需要先收口的 6 个问题——`local_serving_candidate_contract_v1`、`review_group_compatibility_posture_v1`、`fact_settlement_ingest_contract_candidate_v1`、`session_entry_and_routing_compat_v1`、`deprecation_markers_and_writeback_plan_v1`、`shadow_parity_test_strategy_v1`——写成可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API 主文档
- 新 UI 主文档
- Room 4 cutover 执行单
- runtime owner shift 完成宣告
- local-serving cutover 方案书
- unified planner / planner merge 最终版

一句话：

> **P3.3.6 是 Phase 1 compatibility contract round，不是 cutover round。**

---

## 1. 输入依据

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.7.md`
- `UI_SPEC_v0.2.7.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v26.md`
- `STATUS_updated_2026-04-10_v24.md`

### 1.4 Cross-room framing input
- `R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md`
- `p3.3.6_user.md`

---

## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

原因不是因为要“直接切换”，而是因为 P3.3.5 已经把：
- future local primary planning owner
- `review_group` compatibility / deprecation path
- backup / restore / cross-device boundary
- staged rollout

推进到 target-state / compatibility-prep 层。  
如果 P3.3.6 还不继续回答：
- local-serving candidate 到底在业务上意味着什么
- `review_group` 现在与未来各处在什么姿态
- local-serving 结果怎样进入 cloud fact / settlement
- 哪些结果只能写成 shadow evidence
- 哪些 contract 该进入 deprecated candidate / compatibility-only

那么后续 owner-shift 方向会继续卡在“方向已经有了，但没有下一层可被实现与测试引用的业务合同”。

### 2.2 本轮不能直接写成什么
Room 3 同时明确：

> **P3.3.6 当前不能直接写成 `runtime owner shift completed`、`ReviewPage local-serving cutover completed`、`review_group 已退出运行态`，也不能写成 auto-routing / unified planner 已成立。**

当前 active BR 已写死：
- `planner_owner_shift_v2` 只到 future target-state candidate
- `review_serving_contract_v2` 当前 runtime 仍是 cloud `review_group`
- `home_word_entry = study_default`
- `preview / explanation` 仍不得写成 committed plan fact
- `backup / restore / sync success` 三层语义继续严格分开

### 2.3 Room 3 的一句话立场
> **Room 3 支持 P3.3.6 进入 Compatibility Contract v1；但这轮只应把 future local-serving 的业务语义、compatibility posture、fact/settlement ingest 边界、routing compat、deprecated candidate 与 shadow/parity 证据边界写硬，不能把 shadow / candidate 误写成 current runtime truth。**

---

## 3. `local_serving_candidate_contract_v1`

## 3.1 Room 3 结论
> **可以正式推进；但只推进到“候选 serving 实体 + truth split + shadow eligibility”的业务层。**

### RF-P3.3.6-001 — `local_due_queue_candidate` 只表示 future local-serving 候选队列，不表示 current ReviewPage truth
- **Status:** Frozen candidate for this round
- **Rule:** `local_due_queue_candidate` 在业务上只表示：未来由本地 FSRS 计算出的可服务复习项集合候选。
- **Current allowed layer:**
  1. shadow candidate
  2. compatibility contract
  3. parity comparison input
- **Current forbidden layer:**
  1. current ReviewPage serving truth
  2. `review_group` 的直接替代物
  3. current runtime completion / settlement trigger
- **Why frozen candidate:** 这是 P3.3.6 第一个必须写硬的边界，否则 local due queue 会被过早包装成当前页面真相。

### RF-P3.3.6-002 — `local_generated_review_session_candidate` 只表示 future session-level packaging candidate
- **Status:** Frozen candidate for this round
- **Rule:** `local_generated_review_session_candidate` 在业务上只表示：future local planner 为一次复习会话生成的 serving 包装候选。
- **Current allowed layer:**
  1. candidate data model
  2. adapter seam
  3. future feature-flag mount point
- **Current forbidden layer:**
  1. current runtime user-visible route
  2. current ReviewPage 主队列
  3. `next review group` 的直接替代物
- **Why frozen candidate:** 它可以进入兼容合同，但不能被写成“现在用户已经走 local-serving 会话”。

### RF-P3.3.6-003 — future queue source 当前只冻结字段组语义，不冻结完整 DTO / schema / API
- **Status:** Frozen candidate for this round
- **Rule:** 本轮只冻结以下字段组的**存在必要性与业务语义边界**：
  1. `source_type`
  2. `source_id`
  3. `owner_layer`
  4. `shadow_only`
  5. `candidate_reason`
  6. `generated_at`
  7. `item_count`
  8. `serving_eligibility_state`
- **Must not do:**
  1. Room 3 不定义具体 DTO 形状、字段名、索引、迁移或 API 示例
  2. 下游不得把“字段组被接受”写成“current API / DB core semantics 已改”
- **Why frozen candidate:** 这符合 Room 2 / Room 4 / Room 3 的职责边界。

### RF-P3.3.6-004 — compatibility contract 与 shadow-only 的边界必须显式分开
- **Status:** Frozen candidate for this round
- **Rule:** 本轮必须明确区分：
  - **进入 compatibility contract 的内容**
  - **只进入 shadow / parity 的内容**
- **可进 compatibility contract：**
  1. local-serving candidate 作为概念实体
  2. `source_type / owner_layer / shadow_only`
  3. serving eligibility 与 current truth 的边界
  4. adapter seam 的存在必要性
- **只进 shadow：**
  1. local due list 的真实 serving 顺序
  2. local generated session 的真实用户承接
  3. local candidate 对 item stream 的直接接管
  4. local candidate 触发 current completion / settlement 的链路
- **Why frozen candidate:** 否则实现层会直接跳到 cutover。

---

## 4. `review_group_compatibility_posture_v1`

## 4.1 Room 3 结论
> **P3.3.6 最稳的写法，不是把 `review_group` 从 current owner 直接降成 compatibility-only；而是继续承认它当前仍是 runtime serving owner，同时把它正式写成 `compatibility anchor + deprecated candidate`。**

### RF-P3.3.6-005 — `review_group` 当前仍是 runtime serving owner
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.6 当前轮，`review_group` 继续是：
  1. ReviewPage current queue source
  2. continuation / completion / settlement 的当前 serving 主链路
- **Must not do:**
  1. 不得把 `review_group` 写成已退出 runtime
  2. 不得把 local due queue 写成 current page truth
  3. 不得把 current readiness / generation / completion 误写成 local-only truth
- **Why frozen candidate:** 这与 current active BR 一致，也是本轮最重要的 guardrail。

### RF-P3.3.6-006 — `review_group` 当前同时进入 `compatibility anchor + deprecated candidate` 姿态
- **Status:** Frozen candidate for this round
- **Rule:** `review_group` 在本轮应被明确写成三层并存：
  1. **runtime serving owner（当前）**
  2. **compatibility anchor（Phase 1）**
  3. **deprecated candidate（仅标记，不退场）**
- **Canonical meaning:**  
  这表示它既未“完全不变”，也未“已经退场”；它处于 current runtime owner + compatibility anchor + future deprecation candidate 的中间态。
- **Why frozen candidate:** 这能防止 DB / API / UI / TEST 各自写出不同版本的“它现在到底是什么”。

### RF-P3.3.6-007 — `review_group` compatibility posture 不得被误写成“已退场完成”
- **Status:** Frozen candidate for this round
- **Rule:** 以下表达在本轮继续属于假事实：
  - `review_group` 已退出运行态
  - `review_group` 已完全由 local-serving 替代
  - current ReviewPage 已不再依赖 `review_group`
- **Why frozen candidate:** 这是 Phase 1 compatibility round，不是 cutover round。

---

## 5. `fact_settlement_ingest_contract_candidate_v1`

## 5.1 Room 3 结论
> **P3.3.6 必须正式推进；因为如果 planner / serving 的 future 方向要往 local 靠，fact / settlement ingest 不写硬，后续 owner-shift 一定卡住。**

### RF-P3.3.6-008 — planner / serving owner shift 不自动带出 fact / settlement owner shift
- **Status:** Frozen candidate for this round
- **Rule:** 即使 future local-serving 方向被接受，以下事实当前仍继续以后端 / cloud fact layer 为准：
  1. 有效复习事实
  2. 今日目标完成
  3. 奖励结算 / 账本到账
  4. `check_in / learning_day / streak`
- **Must not do:** 不得把 local-serving candidate 的“表现看起来更合理”误写成“local 已可裁定最终业务事实”。

### RF-P3.3.6-009 — local-serving candidate 当前只能进入 `fact ingest candidate`，不能直接改事实账本
- **Status:** Frozen candidate for this round
- **Rule:** local-serving candidate 当前只允许进入：
  1. attempt / completion / progress 的 candidate evidence 层
  2. future ingest interface 的候选层
  3. accept / reject / duplicate 语义的 shadow / parity 验证层
- **Current forbidden layer:**
  1. 直接改账本
  2. 直接改今日目标完成状态
  3. 直接改 streak / learning day 最终事实
- **Why frozen candidate:** 这条是主机制事实真相源规则在 P3.3.6 的继续延伸。

### RF-P3.3.6-010 — fact / settlement ingest 本轮只冻结“最小接口语义”，不冻结最终 API / DB 改写
- **Status:** Frozen candidate for this round
- **Rule:** 本轮可以冻结：
  1. local-serving evidence 进入 cloud fact layer 的存在必要性
  2. accept / reject / duplicate 三类结果语义
  3. evidence 与 current runtime truth 的边界
- **但当前不冻结：**
  1. API core semantics 改写
  2. DB schema rewrite
  3. reward / settlement owner 改写
- **Why frozen candidate:** 这符合 Room 1 handoff 中“contract / architecture round”的定位。

---

## 6. `session_entry_and_routing_compat_v1`

## 6.1 Room 3 结论
> **本轮要推进的是“routing 未来会受 local-serving 影响的兼容边界”，不是当前直接开 auto-routing。**

### RF-P3.3.6-011 — 当前 runtime 继续保持 `home_word_entry = study_default`
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.6 当前轮：
  - 首页“背单词”继续保持 `study_default`
  - active continuation 继续高优先
  - 但不得 silent reroute
- **Must not do:**
  1. 不得把 current 首页入口写成 auto-routing
  2. 不得把 active continuation 自动吞掉 `/study` 默认入口
  3. 不得把 future planner-aware routing 写成当前 runtime truth
- **Why frozen candidate:** 这是 P3.3.2 已冻结 runtime truth 的继续保持。

### RF-P3.3.6-012 — future routing compatibility 只允许进入 shadow / candidate / helper rewrite 边界
- **Status:** Frozen candidate for this round
- **Rule:** 本轮可推进的 only-compat 内容包括：
  1. future routing 可能受 local-serving candidate 影响
  2. active continuation 的 future 承接方式可能重写
  3. helper / CTA / priority block 未来可能随 serving owner 改写
- **Current forbidden layer:**
  1. auto-routing runtime
  2. mixed routing runtime
  3. silent reroute runtime
- **Why frozen candidate:** Room 1 已明确把这些放在 out of scope。

---

## 7. `deprecation_markers_and_writeback_plan_v1`

## 7.1 Room 3 结论
> **P3.3.6 必须推进；否则 compatibility / deprecated candidate / shadow-only marker 会继续在不同文档里各写一套。**

### RF-P3.3.6-013 — 本轮必须显式标记四层语义
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.6 若要 pin，所有下游 write-back / patch / test / helper 至少应显式标记：
  1. `runtime truth`
  2. `compatibility-only`
  3. `deprecated candidate`
  4. `shadow-only evidence`
- **Why frozen candidate:** 这是当前最直接防 silent contract drift 的方式。

### RF-P3.3.6-014 — deprecated candidate 不等于 current truth，也不等于已删掉
- **Status:** Frozen candidate for this round
- **Rule:** 进入 deprecated candidate 的对象：
  - 不能继续被写成 current active truth
  - 也不能被写成“已退场完成 / 已删除 / 已迁移完”
- **Canonical meaning:** 它是“未来可能退场”的 compatibility object，不是 current owner，也不是已消失对象。

### RF-P3.3.6-015 — write-back 不能只停在单一文档
- **Status:** Frozen candidate for this round
- **Rule:** 若 Room 1 接受 Compatibility Contract v1，本轮 write-back / patch 至少要联动：
  1. BR
  2. UI fact-copy / state contract
  3. TEST strategy / regression scope
  4. DB / API candidate 影响标记
- **Why frozen candidate:** 本轮核心不是代码，而是 contract / semantics / write-back 对齐。

---

## 8. `shadow_parity_test_strategy_v1`

## 8.1 Room 3 结论
> **可以正式推进；而且这是 P3.3.6 最值钱的“准备动作”之一。**

### RF-P3.3.6-016 — shadow / parity 结果只能写成 evidence，不能写成 owner shift 已完成
- **Status:** Frozen candidate for this round
- **Rule:** 以下结果当前只允许写成 shadow evidence / parity evidence：
  1. local candidate 看起来更合理
  2. local candidate 与 cloud candidate 大体一致
  3. local-routing 影子判断更优
  4. local ingest evidence 可被云端接受
- **Must not do:** 不得把这些 evidence 写成：
  - owner shift 已完成
  - local 已接管 ReviewPage
  - `review_group` 已退场
  - auto-routing 已上线

### RF-P3.3.6-017 — 本轮必须开始区分三类测试
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.6 当前应至少区分：
  1. **runtime truth regression**
  2. **shadow parity evidence**
  3. **marker / contract-only tests**
- **Why frozen candidate:** 不这样分，测试会继续把 shadow 结果误写成 runtime fact。

### RF-P3.3.6-018 — flags / seams 当前只允许作为 shadow-entry preparation
- **Status:** Frozen candidate for this round
- **Rule:** 诸如：
  - `localServingShadowEnabled`
  - `localServingParityCompareEnabled`
  - `localServingShadowRoutingEnabled`
  - `reviewGroupCompatibilityMode`
  - `localFactIngestShadowEnabled`

  这类 flags / seams 在本轮只允许作为：
  1. shadow-entry preparation
  2. parity evidence preparation
  3. non-runtime feature-off contracts
- **Must not do:** 默认不得打开，更不得改变 current runtime truth。
- **Why frozen candidate:** Room 2 已明确建议“只冻结类别，不直接启用”。

---

## 9. 哪些内容必须继续 Pending

### 9.1 当前继续 Pending
1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 接管当前页面真相
4. `review_group` 退出运行态
5. auto-routing runtime
6. unified planner / planner merge
7. ReviewPage preview re-entry
8. explanation system 升格为 committed plan fact
9. DB schema rewrite
10. API core semantics rewrite
11. complete planner explanation system
12. unified Study / Review page

### 9.2 Room 3 一句话原则
> **本轮只回答“如何进入 compatibility / shadow 层”，不回答“今天就已经切完了”。**

---

## 10. 对 Room 4 / Room 5 的禁止补脑项（Room 3 版）

### 10.1 给 Room 4
Room 4 在 Room 1 未正式 pin Compatibility Contract v1 前，不得自行决定：
1. 把 local-serving candidate 接成 current ReviewPage truth
2. 把 local evidence 直接改账本 / 今日目标 / streak
3. 把 `review_group` 写成已退场
4. 把 shadow result 写成 runtime fact
5. 开启 auto-routing runtime
6. 改 API core semantics / DB schema

### 10.2 给 Room 5
Room 5 在 Room 1 未正式 pin Compatibility Contract v1 前，不得自行决定：
1. 把页面文案写成“系统已自动切到本地规划”
2. 把 local candidate / parity 结果写成已接管事实
3. 把 `review_group` compatibility posture 写成“已退场”
4. 把 preview / explanation 借机升级成 committed plan fact
5. 把 shadow / compatibility-only marker 写成用户可依赖状态

---

## 11. Room 3 可直接给 Room 1 的决策句

### 11.1 Compatibility Contract v1 decision sentence
> **Room 3 judgment：P3.3.6 当前可以进入 `Compatibility Contract v1`；但只应把 `local_serving_candidate_contract_v1`、`review_group_compatibility_posture_v1`、`fact_settlement_ingest_contract_candidate_v1`、`session_entry_and_routing_compat_v1`、`deprecation_markers_and_writeback_plan_v1` 与 `shadow_parity_test_strategy_v1` 收成下一层规则合同，不应把 shadow / candidate / deprecated-candidate 写成 current runtime truth。**

### 11.2 Current runtime truth guard sentence
> **Room 3 judgment：P3.3.6 当前必须继续写死 `current runtime truth 不变`：ReviewPage serving truth 仍是 cloud `review_group`，首页入口仍是 `study_default`，事实与结算 truth 仍在 cloud / backend fact layer；planner owner shift 不自动带出 serving owner shift，更不自动带出 fact owner shift。**

### 11.3 Shadow evidence sentence
> **Room 3 judgment：shadow / parity 结果当前只能写成 evidence，不能写成 owner shift 已完成、local 已接管 ReviewPage、`review_group` 已退出运行态或 auto-routing 已上线。**

---

## 12. Room 3 最终一句话

> **P3.3.6 这轮，Room 3 支持把项目从 P3.3.5 的 target-state / compatibility-prep，推进到 `Compatibility Contract v1`：把 local-serving candidate、`review_group` compatibility posture、fact/settlement ingest、routing compat、deprecated markers 与 shadow/parity 证据边界写硬；但当前绝不把 shadow / candidate / compatibility-only 误写成 current runtime truth。**
