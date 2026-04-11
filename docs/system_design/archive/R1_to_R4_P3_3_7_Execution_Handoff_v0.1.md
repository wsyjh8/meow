# R1_to_R4_P3_3_7_Execution_Handoff_v0.1.md

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** execution handoff / ready for Room4-治理层
- **Role basis:** `room1_v0.2.0.md`
- **Governance basis:** `ORG_v0.3.1.md`
- **Runtime basis used for this round:** `Main_updated_2026-04-10_v26.md` + `STATUS_updated_2026-04-10_v24.md`
- **Direct upstream inputs:**
  - `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md`
  - `R2_P3_3_7_LimitedExecution_and_ShadowMode_Tech_Note_v0.1.md`
  - `R3_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_UI_Preflight_v0.1.md`
  - `BR-OPP-001_v0.2.8.md`
  - `UI_SPEC_v0.2.8.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3.7 这轮已经完成 cross-room 收口的内容，
正式压成一份可交给 **Room4-治理层** 的统一执行任务单。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- runtime owner shift 完成宣告
- ReviewPage local-serving cutover 方案书
- unified planner / planner merge 落地稿
- P3.3.7 closeout

本文件只做一件事：

> **把 P3.3.7 已被 Room 2 / Room 3 / Room 5 收成一致的 `Phase 2 / Limited Execution / Shadow Mode`，压成一份 very narrow、可执行、可测试、不可误写成 cutover 的执行 handoff。**

---

## 1. Room 1 吸收后的统一结论

### 1.1 本轮允许进入执行，但只允许进入 **Phase 2 / Limited Execution / Shadow Mode**
Room 1 当前接受：

1. **`local_serving_shadow_run_v1` 可进入执行**
   - 但只进入 `dev / flag / QA evidence` 层
   - 不得写成 current ReviewPage truth

2. **`parity_checks_v1` 可进入执行**
   - 但只形成 parity evidence
   - 不得形成 runtime owner shift 事实

3. **`review_group_shadow_compat_v1` 可进入执行**
   - `review_group` 当前继续是 current runtime serving owner
   - 同时作为 shadow compare 的 baseline
   - 不得写成已退场 / 已被 local 替代

4. **`fact_ingest_shadow_evidence_v1` 可进入执行**
   - 但只进入 shadow evidence path
   - final fact / settlement truth 继续以后端为准

5. **`routing_shadow_prep_v1` 可进入执行**
   - 但只进入 hidden marker / feature flag / parity evidence 层
   - current runtime 继续 `home_word_entry = study_default`
   - active continuation 继续独立承接，不得 silent reroute

6. **`shadow_regression_and_writeback_v1` 必须进入执行**
   - 因为这是本轮防止 silent contract drift 的内建件
   - 也是 future Phase 3 gate 的最小证据基础

### 1.2 Room 1 因此给 Room 4 的不是“cutover 单”，而是：
> **Phase 2 / Limited Execution + Shadow Mode Trial 执行单。**

也就是说，本轮允许 Room 4 做：
- shadow run
- parity checks
- shadow evidence
- hidden marker / flag / seam
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

### 2.1 `local_serving_shadow_run_v1`
当前正式 pin 为：

#### A. `local_due_queue_candidate`
允许进入：
- dev / QA evidence run
- parity comparison input
- hidden marker / debug trace
- feature-flag mount point

不允许进入：
- current ReviewPage 主队列
- current completion / settlement trigger
- user-visible current route

#### B. `local_generated_review_session_candidate`
允许进入：
- session-level shadow packaging
- hidden adapter seam
- parity-only queue generation

不允许进入：
- 替代 `next review group`
- current runtime CTA / route
- current ReviewPage user-visible source

### 2.2 `parity_checks_v1`
当前正式 pin 为：

1. local shadow queue vs cloud `review_group` 对照
2. serving eligibility 对照
3. attempt / progress / completion 对照
4. accept / reject / duplicate evidence 对照

注意：
- parity pass 只表示 shadow evidence 通过当前轮最低检查
- 不表示可以对用户宣称已切换
- 也不自动等于可以进入 Phase 3

### 2.3 `review_group_shadow_compat_v1`
当前正式 pin 为：

1. `review_group` 继续是 current runtime serving truth
2. 同时也是 shadow compare 的 baseline
3. local-serving 继续只是 shadow candidate
4. 当前不得写成：
   - `review_group` 已退场
   - `review_group` 已失效
   - local 已接管 ReviewPage

### 2.4 `fact_ingest_shadow_evidence_v1`
当前正式 pin 为：

1. 本轮可比的是：
   - accept / reject / duplicate evidence path
   - attempt / progress / completion candidate evidence
   - parity completeness
2. 本轮继续禁止：
   - local 直接改账本
   - local 直接改今日目标完成
   - local 直接改 streak / learning_day 最终事实
3. final fact / settlement truth 继续以后端为准

### 2.5 `routing_shadow_prep_v1`
当前正式 pin 为：

1. current runtime 继续：
   - `home_word_entry = study_default`
   - active continuation 高优先
   - 但不得 silent reroute
2. 当前只允许进入 shadow / hidden 层的 future candidate：
   - `shadow_routing_candidate`
   - `planner_aware_entry_candidate`
   - `continuation_local_compat_candidate`
3. 当前继续禁止：
   - auto-routing runtime
   - mixed routing runtime
   - planner-aware 默认入口
   - 点击“背单词”按本地规划自动改路由

### 2.6 `shadow_regression_and_writeback_v1`
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
4. write-back 不能只停在单一文档，必须形成 patch draft 清单
5. 必须提交 `no-major-change statement`

---

## 3. 给 Room4-治理层的任务定义

### 3.1 目标
完成 P3.3.7 的 **Phase 2 / Limited Execution + Shadow Mode Trial**，具体包括：

1. 让 local-serving candidate 在 shadow 层真实跑起来
2. 固定 parity checks 与 mismatch bucket
3. 保持 `review_group` current owner + shadow baseline 双重姿态
4. 让 fact ingest compare 在 evidence 层真实跑起来
5. 让 routing shadow candidate 进入 hidden marker / flag-prep / parity evidence 层
6. 交付 regression / write-back / no-major-change 的固定证据包

### 3.2 In Scope
1. `local_due_queue_candidate` shadow run
2. `local_generated_review_session_candidate` shadow run
3. parity compare inputs 与结果记录
4. `review_group` shadow baseline 标记与兼容姿态
5. fact ingest shadow evidence path
6. accept / reject / duplicate 证据分级
7. routing shadow candidate hidden marker / flag-prep / evidence
8. runtime truth regression
9. shadow parity evidence tests
10. marker / contract-only tests
11. patch draft / write-back plan
12. `no-major-change statement`

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
10. full sync / real-time sync / auto merge
11. 任何用户可见“已切到本地规划 / 本地已接管复习 / 已自动安排学习路径”的宣告

---

## 4. 必守依据

### 要按需读文档，不需要一次性读完

Room4-治理层与执行层，本轮必须同时服从以下依据：

### 4.1 推进层 / 主线程
- `Main_updated_2026-04-10_v26.md`
- `STATUS_updated_2026-04-10_v24.md`
- `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md`

### 4.2 规则 / 事实边界
- `BR-OPP-001_v0.2.8.md`
- `R3_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_Rules_Note_v0.1.md`

### 4.3 技术边界
- `R2_P3_3_7_LimitedExecution_and_ShadowMode_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 4.4 UI / UX 边界
- `UI_SPEC_v0.2.8.md`
- `UI_SPEC_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_UI_Preflight_v0.1.md`

---

## 5. Room 4 不得补脑的已收口项

以下点本轮 Room 1 已收口，Room 4 不得二次发明：

1. current runtime truth 继续不变
2. ReviewPage current serving truth 继续围绕 cloud `review_group`
3. `review_group` 当前继续是 current runtime owner，同时也是 shadow baseline
4. local-serving candidate 当前只到 shadow / evidence 层
5. fact / settlement truth 继续以后端为准
6. 首页继续 `study_default`
7. active continuation 继续高优先但不得 silent reroute
8. shadow / parity 结果只能写成 evidence
9. DB / API 仍不进入 core rewrite
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

### 6.4 Shadow 可见性护栏
当前继续禁止：
- 本地 serving 已启用
- ReviewPage 已切到本地队列
- 当前复习队列来自本地 due
- owner shift 已完成
- 已升级到新 serving 方案
- 影子模式已正式生效

### 6.5 Major 红线
以下任一动作出现，都视为越界：
1. 把 local shadow source 写成 current ReviewPage truth
2. 把 `review_group` 写成已退出运行态
3. 把 auto-routing 写成 runtime reality
4. 让 local shadow evidence 直接改 final fact / settlement
5. 改 DB schema
6. 改 API core semantics
7. 把 shadow pass 写成用户承诺事实
8. 把 Phase 2 delivery 写成 owner shift completed

---

## 7. 推荐执行方式（Room 4 本轮）

### Track A — Shadow Run
做：
1. `local_due_queue_candidate` shadow run
2. `local_generated_review_session_candidate` shadow run
3. disabled-by-default flag / seam / hidden marker
4. evidence-only source comparison

不做：
- current ReviewPage user-visible source 改写
- 替代 `next review group`

### Track B — Parity / Mismatch
做：
1. queue compare
2. eligibility compare
3. attempt / progress / completion compare
4. accept / reject / duplicate evidence compare
5. `parity pass / acceptable mismatch / must-hold mismatch / must-escalate` 分类

不做：
- 把 shadow 结果写成 runtime fact
- 把 acceptable mismatch 包装成“已验证安全切换”

### Track C — Routing Shadow
做：
1. `shadow_routing_candidate` hidden marker / flag-prep / evidence
2. `planner_aware_entry_candidate` hidden marker / evidence
3. `continuation_local_compat_candidate` hidden marker / evidence
4. `study_default` 与 active continuation 不变的断言

不做：
- auto-routing runtime
- planner-aware 默认入口
- silent reroute

### Track D — Regression / Write-back
做：
1. runtime truth regression
2. shadow parity evidence tests
3. marker / contract-only tests
4. patch draft / write-back plan
5. `no-major-change statement`

不做：
- 把 shadow evidence 写成 cutover 完成
- 跳过 closeout 直接要求 Room 1 absorb 到更深阶段

---

## 8. 必测项

Room 4 本轮至少覆盖以下测试 / 自测：

### 8.1 Runtime Truth Regression
1. 首页继续 `study_default`
2. active continuation 继续独立承接
3. ReviewPage 继续以 cloud `review_group` 为当前 serving truth
4. current ReviewPage 主队列未被 local due 接管
5. 用户端继续不出现“local serving enabled / owner shift completed / shadow mode enabled”类事实

### 8.2 Shadow Run / Candidate 层
1. `local_due_queue_candidate` 只出现在 candidate / shadow / evidence 层
2. `local_generated_review_session_candidate` 只出现在 candidate / seam / future flag 层
3. `source_type / owner_layer / shadow_only / candidate_reason / generated_at / item_count / serving_eligibility_state` 等元语义不泄漏为用户事实
4. `review_group` 仍是 current runtime owner，同时具备 shadow baseline 标记

### 8.3 Fact / Settlement Evidence
1. local evidence 不直接改 ledger
2. local evidence 不直接改 daily goal final state
3. local evidence 不直接改 streak / learning day final fact
4. accept / reject / duplicate 语义只进入 shadow/parity/evidence 层
5. final fact 仍以后端为准的断言存在

### 8.4 Routing Shadow
1. 当前 runtime 不发生 auto-routing
2. 当前 runtime 不发生 silent reroute
3. `shadow_routing_candidate` / `planner_aware_entry_candidate` / `continuation_local_compat_candidate` 只存在于 hidden / test / debug / patch-draft 层
4. 不出现“系统已自动判断今天先复习”等用户文案

### 8.5 Mismatch / Gate / Write-back
1. `parity pass / acceptable mismatch / must-hold mismatch / must-escalate` 分级存在
2. stop conditions 被明确定义并可断言
3. patch draft / write-back plan 清单齐全
4. `no-major-change statement` 存在
5. shadow / parity 结果未被误写成 current runtime truth

---

## 9. 交付物要求

Room4-治理层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **current runtime truth 是否保持不变**
5. **哪些 shadow candidate 已真实跑起来**
6. **parity / mismatch / stop-condition 分类结果**
7. **fact / settlement evidence 边界是否守住**
8. **routing shadow 是否无用户可见漂移**
9. **是否触碰核心契约的判断**
10. **no-major-change statement**
11. **需要哪些文档回写**
    - BR / UI / Main / Status / DB / API / TEST / 其他
12. **是否可 close / 是否需 revise / 是否需 escalate**

---

## 10. Room 1 预期完成定义（Done）

当 Room4-治理层交回结果，且满足以下条件时，Room 1 认为 P3.3.7 本轮可以进入 absorb / close 判断：

1. limited execution / shadow mode 的 very narrow subset 已落地
2. current runtime truth 未被偷切
3. `review_group` current owner + shadow baseline 双重姿态被守住
4. local-serving candidate 仍停留在 shadow / evidence 层
5. fact / settlement ingest shadow evidence 已真实跑通但未越界
6. routing shadow candidate 已挂起但首页 / ReviewPage runtime 行为不变
7. mismatch / stop-condition / parity evidence 集已固定
8. 未触碰 DB schema / API core semantics / reward-settlement owner / runtime routing

---

## 11. 一句话 handoff

> **请 Room4-治理层按“Phase 2 / Limited Execution / Shadow Mode”的 very narrow subset 推进 P3.3.7：让 local-serving candidate、parity checks、`review_group` shadow baseline、fact ingest shadow evidence、routing shadow prep 与 regression / write-back 真实跑起来，但 current runtime truth 继续不变；不要把本轮做成 runtime owner shift，更不要把 shadow evidence 写成用户可依赖事实。**
