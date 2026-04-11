# R1_to_R4_P3_3_6_Execution_Handoff_v0.1.md

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** execution handoff / ready for Room4-治理层
- **Role basis:** `room1_v0.2.0.md`
- **Governance basis:** `ORG_v0.3.1.md`
- **Runtime basis used for this round:** `Main_updated_2026-04-10_v26.md` + `STATUS_updated_2026-04-10_v24.md`
- **Direct upstream inputs:**
  - `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md`
  - `R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md`
  - `R3_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_UI_Preflight_v0.1.md`
  - `BR-OPP-001_v0.2.7.md`
  - `UI_SPEC_v0.2.7.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3.6 这轮已经完成 cross-room 收口的内容，
正式压成一份可交给 **Room4-治理层** 的统一执行任务单。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- runtime owner shift 完成宣告
- ReviewPage local-serving cutover 方案书
- unified planner / planner merge 直接落地稿
- P3.3.6 closeout

本文件只做一件事：

> **把 P3.3.6 已被 Room 2 / Room 3 / Room 5 收成一致的 `Compatibility Contract v1 + Shadow-Entry Prep`，压成一份 very narrow、可执行、可测试、不可误写成 cutover 的执行 handoff。**

---

## 1. Room 1 吸收后的统一结论

### 1.1 本轮允许进入执行，但只允许进入 **Phase 1 / Compatibility Landing Layer**
Room 1 当前接受：

1. **`local_serving_candidate_contract_v1` 可进入执行**
   - 但只进入 candidate / compatibility / shadow-entry prep
   - 不得写成 current ReviewPage truth

2. **`review_group_compatibility_posture_v1` 可进入执行**
   - 当前仍是 current runtime serving owner
   - 同时进入 compatibility anchor + deprecated candidate 姿态
   - 不得写成已退场或已被 local 替代

3. **`fact_settlement_ingest_contract_candidate_v1` 可进入执行**
   - 但只进入 minimal ingest boundary / evidence path
   - 不得让 local 直接改 final fact / settlement / ledger / streak / daily goal

4. **`session_entry_and_routing_compat_v1` 可进入执行**
   - 但只进入 compatibility / shadow-only marker
   - current runtime 继续 `home_word_entry = study_default`
   - active continuation 继续高优先但不得 silent reroute

5. **`deprecation_markers_and_writeback_plan_v1` 与 `shadow_parity_test_strategy_v1` 必须进入执行**
   - 因为这是当前最直接防 silent contract drift 的手段
   - 也是进入 future Phase 2 前最有价值的准备层

### 1.2 Room 1 因此给 Room 4 的不是“cutover 单”，而是：
> **Phase 1 / Compatibility Landing + Shadow-Entry Prep 执行单。**

也就是说，本轮允许 Room 4 做：
- compatibility marker / deprecated candidate / compatibility-only marker 落地
- local-serving candidate 的 shadow-only seam / adapter / contract anchor
- fact/settlement ingest candidate 的 evidence-path / semantic boundary 准备
- routing compatibility / shadow-only marker 准备
- shadow / parity / regression 测试落地
- patch draft / write-back prep / no-major-change statement

但**不允许** Room 4 做：
- runtime owner shift completed
- ReviewPage local-serving runtime cutover
- local due queue 接管 current ReviewPage truth
- `review_group` 直接退出运行态
- auto-routing runtime
- planner merge / unified planner
- DB schema rewrite
- API core semantics rewrite

---

## 2. Room 1 正式 pin 的最小合同集合

### 2.1 `local_serving_candidate_contract_v1`
当前正式 pin 为：

#### A. `local_due_queue_candidate`
- 表示 future local-serving 候选队列
- 当前只允许进入：
  - shadow candidate
  - compatibility contract
  - parity comparison input
- 当前不允许进入：
  - current ReviewPage serving truth
  - `review_group` 的直接替代物
  - current completion / settlement trigger

#### B. `local_generated_review_session_candidate`
- 表示 future local planner 生成的 session-level serving candidate
- 当前只允许进入：
  - candidate data model
  - adapter seam
  - future feature-flag mount point
- 当前不允许进入：
  - current runtime user-visible route
  - current ReviewPage 主队列
  - `next review group` 的直接替代物

#### C. 最小字段组语义
当前允许进入 compatibility contract 的字段组类别：
1. `source_type`
2. `source_id`
3. `owner_layer`
4. `shadow_only`
5. `candidate_reason`
6. `generated_at`
7. `item_count`
8. `serving_eligibility_state`

注意：
- 当前只冻结“字段组语义 / 存在必要性”
- 不冻结 DTO 形状 / 最终字段名 / 索引 / API 示例 / DB schema

### 2.2 `review_group_compatibility_posture_v1`
当前正式 pin 为：

1. **runtime serving owner（当前仍成立）**
   - ReviewPage current queue source
   - current continuation / completion / settlement 的 serving 主链路

2. **compatibility anchor（Phase 1 允许进入）**
   - 为 future local-serving shadow / parity 提供对照真相层
   - 为 adapter / transition 提供兼容基座

3. **deprecated candidate（仅标记，不退场）**
   - 可以进入文档 / 代码注释 / 测试计划 / patch draft
   - 但不得写成：
     - 已退场
     - 已删除
     - 已切换完成
     - 已由 local 接管

### 2.3 `fact_settlement_ingest_contract_candidate_v1`
当前正式 pin 为：

1. planner / serving owner shift **不自动带出** fact / settlement owner shift
2. 即使 future serving 向 local 靠，以下最终事实当前仍以后端 / cloud fact layer 为准：
   - effective review fact
   - daily goal progress impact
   - reward settlement / ledger final state
   - `check_in / learning_day / streak`
3. local-serving candidate 当前只允许进入：
   - attempt / completion / progress 的 candidate evidence 层
   - future ingest interface 的候选层
   - accept / reject / duplicate 的 shadow / parity 验证层
4. 当前不允许：
   - local 直接改账本
   - local 直接改今日目标最终状态
   - local 直接改 streak / learning_day 最终事实
   - local 绕过 ingest 直接写 final fact

### 2.4 `session_entry_and_routing_compat_v1`
当前正式 pin 为：

1. 当前 runtime 继续：
   - `home_word_entry = study_default`
   - active continuation 高优先
   - 但不得 silent reroute
2. 当前只允许进入 compatibility / shadow-only 的 future candidate：
   - `shadow_routing_candidate`
   - `planner_aware_entry_candidate`
   - `continuation_local_compat_candidate`
3. 当前继续禁止：
   - auto-routing runtime
   - mixed routing runtime
   - planner-aware 默认入口
   - 点击“背单词”按本地规划自动改路由

### 2.5 `deprecation_markers_and_writeback_plan_v1`
当前正式 pin 为：

1. 本轮必须显式区分四层语义：
   - `runtime truth`
   - `compatibility-only`
   - `deprecated candidate`
   - `shadow-only evidence`
2. 可以进入 `deprecated candidate` 的对象：
   - 直接绑定 cloud-group 语义的 helper wording
   - 直接把 `next review group` 写成 current-only 的 copy
   - 只服务 cloud-group explanation 的内部状态命名
   - 未来可能被 local-serving 重写的 continuation 文案
3. 更适合进入 `compatibility-only` 的对象：
   - ReviewPage 当前 group progress 呈现
   - continuation card 现行布局
   - Home review helper 当前 wording
   - ReviewPage current settlement / completion 文案
4. `deprecated candidate` 当前不得被写成：
   - 已退场
   - 已切换
   - 即将不可用
   - 已删除

### 2.6 `shadow_parity_test_strategy_v1`
当前正式 pin 为：

1. 本轮必须至少区分三类测试：
   - runtime truth regression
   - shadow parity evidence
   - marker / contract-only tests
2. flags / seams 当前只允许作为：
   - shadow-entry preparation
   - parity evidence preparation
   - non-runtime feature-off contracts
3. 默认不得打开，更不得改变 current runtime truth
4. parity checks 至少固定以下比较集：
   - queue candidate size / emptiness
   - item identity overlap
   - continuation eligibility judgment
   - submit after-effects 的 evidence 完整性
   - fact ingest accept / reject / duplicate 行为一致性
5. 以下结果只能写成 shadow evidence，不能写成 runtime fact：
   - local candidate 看起来更合理
   - local candidate 与 cloud candidate 大体一致
   - local-routing 影子判断更优
   - local ingest evidence 可被云端接受

---

## 3. 给 Room4-治理层的任务定义

### 3.1 目标
完成 P3.3.6 的 **Phase 1 / Compatibility Landing + Shadow-Entry Prep**，具体包括：

1. 将 local-serving candidate 的最小语义、shadow-only seams、compatibility markers 落地
2. 将 `review_group` 的 current owner + compatibility anchor + deprecated candidate 三层姿态落地
3. 将 fact / settlement ingest candidate 的 evidence-path 与 final-truth boundary 写硬
4. 将 routing compatibility / shadow-only marker 落地，同时保持当前首页与 ReviewPage runtime truth 不变
5. 将 deprecation / compatibility-only / shadow-only 的 write-back 与测试要求落地

### 3.2 In Scope
1. local-serving candidate 的 contract anchor / adapter seam / hidden marker
2. `source_type / owner_layer / shadow_only / candidate_reason / serving_eligibility_state` 等元语义落地
3. `review_group` compatibility anchor + deprecated candidate 标记
4. fact / settlement ingest candidate 的 semantic boundary / evidence-path prep
5. routing compatibility / shadow-only marker
6. deprecated-candidate / compatibility-only 清单落地
7. shadow / parity / regression 的最小固定测试集
8. write-back patch draft 清单
9. no-major-change statement

### 3.3 Out of Scope
1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 接管 current ReviewPage truth
4. `review_group` 直接删出运行态
5. auto-routing runtime
6. unified planner / planner merge
7. unified Study / Review page
8. ReviewPage preview re-entry
9. complete preview / explanation system 升级
10. DB schema 重构
11. API core semantics 重写
12. full sync / real-time sync / auto merge
13. reward / settlement / daily_goal / streak 最终事实 owner shift

---

## 4. 必守依据


Room4-治理层与执行层，本轮必须同时服从以下依据：

### 要按需读文档，不需要一次性读完

### 4.1 推进层 / 主线程
- `Main_updated_2026-04-10_v26.md`
- `STATUS_updated_2026-04-10_v24.md`
- `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md`

### 4.2 规则 / 事实边界
- `BR-OPP-001_v0.2.7.md`
- `R3_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Rules_Note_v0.1.md`

### 4.3 技术边界
- `R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 4.4 UI / UX 边界
- `UI_SPEC_v0.2.7.md`
- `UI_SPEC_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_UI_Preflight_v0.1.md`

---

## 5. Room 4 不得补脑的已收口项

以下点本轮 Room 1 已收口，Room 4 不得二次发明：

1. current runtime truth 继续不变
2. ReviewPage current serving truth 继续围绕 cloud `review_group`
3. `review_group` 当前不是 compatibility-only，也不是已退场；它是 current owner + compatibility anchor + deprecated candidate
4. local-serving candidate 当前只到 candidate / compatibility / shadow 层
5. planner owner shift 不自动带出 serving owner shift
6. serving owner shift 不自动带出 fact / settlement owner shift
7. 首页继续 `study_default`
8. active continuation 继续高优先但不得 silent reroute
9. shadow / parity 结果只能写成 evidence
10. DB / API 仍不进入 core rewrite

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
- shadow-routing 已对用户生效

### 6.3 Fact / Settlement 护栏
当前继续禁止：
- 已记为有效复习
- 今日目标已推进
- 奖励已到账
- streak 已由本地 shadow 续上
- 学习事实已同步到云端
- local evidence 已成为 final fact

除非 cloud fact layer 已明确返回对应 final truth。

### 6.4 Deprecated / Compatibility 护栏
当前继续禁止：
- 已废弃
- 已退场
- 即将不可用
- 已切换新方案
- 已删除旧逻辑

### 6.5 Major 红线
以下任一动作出现，都视为越界到 Phase 2 / Phase 3 或 DB/API Major：
1. 把 local due queue 写成 current ReviewPage truth
2. 把 `review_group` 从 current runtime owner 直接降成已退场
3. 让 local evidence 直接改账本 / 今日目标 / streak
4. 开启用户可见 auto-routing
5. 改 `/me/today`、review-serving、review-attempt 之类核心语义
6. 触发 schema 级重构
7. 把 shadow / parity 结果写成 runtime fact

---

## 7. 推荐执行方式（Room 4 本轮）

### Track A — Compatibility Markers / Contract Anchors
做：
1. local-serving candidate 的 contract anchor / seam / marker
2. `review_group` 的 compatibility anchor / deprecated candidate 标记
3. `runtime truth / compatibility-only / deprecated candidate / shadow-only evidence` 四层语义在代码与 patch-draft 中的显式区分

不做：
- current runtime owner 改写
- local-serving cutover

### Track B — Fact / Settlement Ingest Boundary Prep
做：
1. local evidence → cloud fact ingest 的语义边界
2. accept / reject / duplicate 的 shadow/parity 语义
3. final fact 仍以后端为准的 guardrails

不做：
- local 直接裁定 final fact
- local 改写 settlement / ledger / daily_goal / streak

### Track C — Routing Compatibility / Shadow Prep
做：
1. `study_default` 继续保持不变的断言
2. active continuation 继续独立承接的断言
3. shadow-routing / planner-aware candidate 的 hidden marker / flag-prep
4. no-user-visible-shadow-claim 的 helper / copy / state guardrails

不做：
- auto-routing runtime
- mixed routing runtime
- planner-aware 默认入口

### Track D — Shadow / Parity / Regression
做：
1. runtime truth regression
2. shadow parity evidence tests
3. marker / contract-only tests
4. write-back patch draft 清单
5. no-major-change statement

不做：
- 把 shadow evidence 写成 cutover 完成
- 把 parity 结果写成 current runtime truth 已切换

---

## 8. 必测项

Room 4 本轮至少覆盖以下测试 / 自测：

### 8.1 Runtime Truth Regression
1. 首页继续 `study_default`
2. active continuation 继续独立承接
3. ReviewPage 继续以 cloud `review_group` 为当前 serving truth
4. current ReviewPage 主队列未被 local due 接管
5. ReviewPage / 首页继续不出现 preview deeper re-entry
6. StudyPage 继续保持当前 preview 最小边界

### 8.2 Local-Serving Candidate / Compatibility
1. `local_due_queue_candidate` 只出现在 candidate / compatibility / shadow 层
2. `local_generated_review_session_candidate` 只出现在 candidate / seam / future flag 层
3. `source_type / owner_layer / shadow_only / serving_eligibility_state / candidate_reason` 的语义不泄漏成用户事实
4. `review_group` 仍是 current runtime owner，同时具备 compatibility anchor / deprecated candidate 标记

### 8.3 Fact / Settlement Boundary
1. local evidence 不直接改 ledger
2. local evidence 不直接改 daily goal final state
3. local evidence 不直接改 streak / learning day final fact
4. accept / reject / duplicate 语义只进入 shadow/parity/evidence 层
5. final fact 仍以后端为准的断言存在

### 8.4 Routing Compatibility
1. 当前 runtime 不发生 auto-routing
2. 当前 runtime 不发生 silent reroute
3. `planner_aware_entry_candidate` / `shadow_routing_candidate` / `continuation_local_compat_candidate` 只存在于 hidden / test / debug / patch-draft 层
4. 不出现“系统已自动判断今天先复习”等用户文案

### 8.5 Deprecated / Write-back / Shadow Evidence
1. 四层语义被显式标记：
   - runtime truth
   - compatibility-only
   - deprecated candidate
   - shadow-only evidence
2. `deprecated candidate` 未被误写成已退场 / 已删除
3. shadow / parity 结果未被误写成 owner shift completed
4. write-back patch draft 清单齐全
5. no-major-change statement 存在

---

## 9. 交付物要求

Room4-治理层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **current runtime truth 是否保持不变**
5. **`review_group` current owner + compatibility anchor + deprecated candidate 是否被正确区分**
6. **local-serving candidate 是否仍停留在 candidate / compatibility / shadow 层**
7. **fact / settlement ingest boundary 是否守住**
8. **routing compatibility / shadow marker 是否无用户可见漂移**
9. **是否触碰核心契约的判断**
10. **no-major-change statement**
11. **需要哪些文档回写**
    - BR / UI / Main / Status / DB / API / TEST / 其他
12. **是否可 close / 是否需 revise / 是否需 escalate**

---

## 10. Room 1 预期完成定义（Done）

当 Room4-治理层交回结果，且满足以下条件时，Room 1 认为 P3.3.6 本轮可以进入 absorb / close 判断：

1. `Compatibility Contract v1` 的 very narrow subset 已落地
2. current runtime truth 未被偷切
3. `review_group` 的 current owner + compatibility anchor + deprecated candidate 三层姿态已被写硬
4. local-serving candidate 仍停留在 candidate / compatibility / shadow 层
5. fact / settlement ingest boundary 已被写硬
6. routing compatibility / shadow marker 已落地，且首页 / ReviewPage runtime 行为不变
7. shadow / parity / regression 集已固定
8. 未触碰 DB schema / API core semantics / reward-settlement owner / runtime routing

---

## 11. 一句话 handoff

> **请 Room4-治理层按“Compatibility Contract v1 的 very narrow landing”推进 P3.3.6：把 local-serving candidate、`review_group` compatibility posture、fact/settlement ingest boundary、routing compatibility、deprecation markers 与 shadow/parity 测试策略落地为可执行、可测试、可回写的准备层；不要把本轮做成 local-serving cutover，更不要把 shadow / candidate / deprecated-candidate 写成 current runtime truth。**
