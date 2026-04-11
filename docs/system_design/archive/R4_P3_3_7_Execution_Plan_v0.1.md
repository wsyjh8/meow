# R4_P3_3_7_Execution_Plan_v0.1.md

- **Owner:** Room 4（治理层）
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** ready for execution
- **Role basis:** `ROOM04_治理版_v0.2.md`
- **Direct upstream input:** `R1_to_R4_P3_3_7_Execution_Handoff_v0.1.md`

---

## 0. 一句话定位

本稿不是代码实现记录，也不是新的 BR / DB / API / UI 主文档。  
本稿只做一件事：

> **把 Room 1 已经收口完成的 P3.3.7 结论，压成一份可直接交给 Room 4 执行层（Claude Code）的短而硬执行任务单。**

---

## 1. Room 4 当前判断

### 1.1 本轮是否可以开工
> **可以开工。**

### 1.2 本轮开工的性质
> **这是 `Phase 2 / Limited Execution / Shadow Mode` 的 very narrow landing，不是 runtime owner shift / local-serving cutover。**

### 1.3 Room 4 采用口径
- 继续服从 **Room 1 已 pin / 已指定的 review basis**
- 不自动把未被 Room 1 pin 的新候选文档写成 runtime truth
- 本轮只推进 shadow execution、parity、ingest evidence、routing shadow prep、write-back plan
- 不推进 cutover，不推进 unified planner，不推进 auto-routing runtime

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

完成 **P3.3.7 — Local-Serving Limited Execution / Shadow Mode Round** 的 **Phase 2 / Limited Execution / Shadow Mode**，具体包括：

1. 让 `local_due_queue_candidate` 进入 limited execution / shadow run
2. 让 `local_generated_review_session_candidate` 进入 limited execution / shadow run
3. 让 `fact_ingest_shadow_evidence` 真实跑起来，并形成 accept / reject / duplicate evidence
4. 让 `routing_shadow_candidate` 进入 hidden marker / flag-prep / evidence 层
5. 固定 `shadow_acceptance_gate_v1`
6. 固定 `shadow_to_phase3_gate_v1`
7. 交回 patch / sync draft 与 `no-major-change statement`

---

## 3. In Scope

### 3.1 `local_serving_shadow_run_v1`
本轮纳入：
1. `local_due_queue_candidate` 的 shadow run
2. `local_generated_review_session_candidate` 的 shadow run
3. flag / seam / hidden marker 挂载
4. 只进入 dev / QA / evidence 层，不进入用户主路径

### 3.2 `parity_checks_v1`
本轮纳入：
1. local shadow queue vs cloud `review_group` 的对照
2. serving eligibility 对照
3. attempt / progress / completion 对照
4. accept / reject / duplicate 的 evidence 对照

### 3.3 `review_group_shadow_compat_v1`
本轮纳入：
1. `review_group` 继续 current runtime owner
2. `review_group` 同时作为 shadow 对照基准
3. local-serving 继续只做 shadow candidate
4. 不允许把 `review_group` 写成已退场

### 3.4 `fact_ingest_shadow_evidence_v1`
本轮纳入：
1. local evidence → cloud fact layer 的 shadow ingest
2. accept / reject / duplicate 的证据回包与分级
3. final fact 仍以后端为准
4. local 不得直接改 ledger / daily_goal / streak / settlement

### 3.5 `routing_shadow_prep_v1`
本轮纳入：
1. `study_default` 继续保持不变
2. active continuation 继续独立承接
3. planner-aware / shadow-routing 只进 hidden marker / flag-prep / evidence 层
4. 不允许 auto-routing runtime

### 3.6 `shadow_regression_and_writeback_v1`
本轮纳入：
1. runtime truth regression
2. shadow parity evidence tests
3. marker / contract-only tests
4. patch draft / write-back plan
5. no-major-change statement

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
13. 用户可见 shadow-mode 宣告
14. Phase 3 / cutover 行为

---

## 5. 必守依据

### 要按需读文档，不需要一次性读完

### 5.1 推进层 / 主线程
- `R1_to_R4_P3_3_7_Execution_Handoff_v0.1.md`
- `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md`

### 5.2 规则 / 事实边界
- `BR-OPP-001_v0.2.7.md`
- `R3_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_Rules_Note_v0.1.md`

### 5.3 技术边界
- `R2_P3_3_7_LimitedExecution_and_ShadowMode_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 5.4 UI / UX 边界
- `UI_SPEC_v0.2.7.md`
- `UI_SPEC_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_UI_Preflight_v0.1.md`

### 5.5 治理依据
- `ORG_v0.3.1.md`
- `ROOM04_治理版_v0.2.md`

---

## 6. Room 4 不得补脑的已收口项

以下点本轮已被 Room 1 收口，Room 4 不得二次发明：

1. **P3.3.7 是 Phase 2 / Limited Execution / Shadow Mode，不是 cutover**
2. **current runtime truth 仍在 cloud review-serving layer**
3. **`review_group` 当前仍是 current runtime serving owner**
4. **`review_group` 同时进入 compatibility anchor + deprecated candidate，但不是已退场**
5. **首页继续 `home_word_entry = study_default`**
6. **active continuation 继续高优先，但不得 silent reroute**
7. **planner / serving owner shift 不自动带出 fact / settlement owner shift**
8. **shadow / candidate / parity evidence 不得被写成用户当前可依赖事实**

---

## 7. Room 4 执行护栏

### 7.1 Local-serving shadow 护栏
当前允许：
- `local_due_queue_candidate`
- `local_generated_review_session_candidate`
- shadow candidate
- compatibility contract
- parity comparison input
- adapter seam
- future feature-flag mount point

当前禁止：
- current ReviewPage serving truth
- `review_group` 的直接替代物
- current completion / settlement trigger
- current runtime user-visible route

### 7.2 `review_group` posture 护栏
当前必须继续同时保持：
1. **runtime serving owner**
2. **compatibility anchor**
3. **deprecated candidate**

当前禁止写成：
- 已退场
- 已删除
- 已被 local 替代
- current ReviewPage 已不再依赖 `review_group`
- 不再承担 current serving truth

### 7.3 Fact / Settlement ingest 护栏
当前允许进入：
- attempt / completion / progress 的 candidate evidence layer
- future ingest interface 的 candidate layer
- accept / reject / duplicate 的 shadow / parity 验证层

当前禁止进入：
- local 直接改 final fact
- local 直接改 reward settlement / ledger
- local 直接改 `daily_goal_status`
- local 直接改 `check_in / learning_day / streak`
- 绕过 cloud ingest 直接写最终业务事实

### 7.4 Routing shadow 护栏
当前继续保持：
- `home_word_entry = study_default`
- active continuation 高优先
- 但不得 silent reroute

当前只允许进入：
- `shadow_routing_candidate`
- `planner_aware_entry_candidate`
- `continuation_local_compat_candidate`

当前禁止：
- auto-routing runtime
- mixed routing runtime
- planner-aware 默认入口
- 点击“背单词”直接按 local-serving decision 改路由

### 7.5 Shadow 可见性护栏
当前允许可见给：
1. dev / test
2. internal debug panel / log
3. QA evidence 包
4. patch draft / closeout 摘要
5. Room 1 / Room 2 / Room 3 / Room 5 的治理层文档

当前禁止露出给用户：
1. local queue compare 结果
2. parity mismatch 结果
3. accept / reject / duplicate shadow 证据
4. shadow routing 判断
5. “本地更合理 / 本地更优 / 本地已准备接管”的内部判断
6. shadow-mode 已正式生效 的任何表达

### 7.6 Copy / overclaim 护栏
以下表达本轮不得出现于用户侧：
- 本地已接管复习
- 当前复习来自本地队列
- 已切换到本地复习模式
- `review_group` 已退场
- 系统已自动分流
- 已为你安排最佳入口
- 已自动完成规划切换
- shadow 模式已对你生效
- 当前已使用新方案
- parity 已通过，现已切换新模式
- 你的计划已由本地接管

### 7.7 Stop-condition 护栏
以下任一出现，本轮不应继续扩大 execution：
1. runtime truth leakage
2. feature flag 非预期开启
3. shadow evidence 影响 final fact / settlement
4. ReviewPage 行为偏离 cloud-first runtime
5. auto-routing 以任何形式进入用户路径

---

## 8. Shadow acceptance gate（本轮必须写硬）

### A. `parity_pass`
满足以下条件时可记为 pass：
1. local shadow queue 生成成功
2. 与 cloud `review_group` 的来源、eligibility、attempt / progress / completion 对照在允许误差内
3. 未产生 runtime truth leakage
4. 未触碰 final fact / settlement write

### B. `acceptable_mismatch`
允许存在，但必须记录原因：
1. local planner 与 cloud group 的排序差异，但不影响 current runtime truth
2. generated timestamp / candidate metadata 差异
3. candidate_reason 差异
4. shadow-only packaging 差异

### C. `must_hold_mismatch`
一旦出现，必须阻断继续扩大 shadow scope：
1. local shadow result 被用户可见
2. current ReviewPage truth 被 local 覆写
3. `study_default` 被 shadow 路径偷改
4. local evidence 触发 final ledger / daily_goal / streak write
5. `review_group` 被写成已退场或已失效

### D. `must_escalate`
出现以下情况必须升级给 Room 1 / Room 2：
1. parity mismatch 指向 API core semantics 缺口
2. parity mismatch 指向 DB schema / ingest seam 缺口
3. shadow run 需要新增用户可见状态才能继续
4. shadow run 暗示当前 BR / UI / DB / API 对 owner split 的定义不够用

---

## 9. Shadow-to-Phase3 gate（本轮至少要回答）

未来若要进入 Phase 3 判断，至少需要：
1. shadow queue 生成与 parity 对照可稳定复现
2. fact ingest shadow evidence 可稳定返回 accept / reject / duplicate
3. routing shadow markers 可挂载，但 runtime `study_default` 不变
4. `review_group` 继续保持 current runtime owner，不发生 truth conflict
5. 所有 mismatch 已被分桶为 acceptable / must-hold / must-escalate
6. write-back 能明确说明“做了什么、没做什么、runtime truth 是否保持不变”

并且要明确：
- shadow run 可行 ≠ runtime owner shift 安全
- parity pass ≠ cutover 许可
- internal evidence ≠ user-visible runtime fact

---

## 10. 必测项

### 10.1 Local-serving candidate
1. `local_due_queue_candidate` 只作为 shadow / compatibility / parity input 存在
2. `local_generated_review_session_candidate` 只作为 candidate / seam / flag mount 存在
3. 不会被写成 current ReviewPage truth
4. 不会触发 current completion / settlement

### 10.2 `review_group` compatibility posture
1. current runtime serving owner 仍成立
2. compatibility anchor marker 已存在
3. deprecated candidate marker 已存在
4. 不会被写成已退场 / 已删除 / 已被 local 替代

### 10.3 Fact / Settlement ingest
1. local candidate 结果只进入 evidence / candidate ingest 层
2. 不会直写 final fact / settlement / ledger
3. 不会直写 `daily_goal_status`
4. 不会直写 `check_in / learning_day / streak`

### 10.4 Routing shadow
1. 首页“背单词”默认继续进入 `StudyPage`
2. active continuation 仍独立承接
3. 没有 silent reroute
4. 没有 auto-routing runtime
5. routing candidate 只进入 shadow / compatibility 层

### 10.5 Shadow visibility / copy
1. 不出现“本地已接管”“已自动分流”“已切换到本地复习模式”
2. 不出现“`review_group` 已退场”
3. 不出现“shadow 模式已对用户生效”
4. 不把 candidate / shadow / compatibility 写成 current runtime truth

### 10.6 No-major-change 验证
1. 未改 DB schema
2. 未改 API core semantics
3. 未改 `review_group` 最小合同
4. 未发生 runtime owner shift
5. 未发生 local-serving cutover
6. 未引入 auto-routing / unified planner

---

## 11. 执行层交付物要求

执行层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **`local_serving_candidate` / `review_group` / ingest / routing shadow 是否都守住了边界**
5. **是否触碰核心契约的判断**
6. **是否需要升级**
7. **需要哪些文档回写**
   - BR / UI / Main / Status / 其他
8. **是否可 accept / revise / escalate / hold**
9. **`no-major-change statement`**

---

## 12. Room 4 验收判断口径

只有同时满足以下条件，Room 4 才会给出 `accept / 可 closeout` 倾向：

1. `local_serving_shadow_run_v1` 已以 hidden / flag / evidence 方式落地
2. `parity_checks_v1` 已真实产出对照证据
3. `review_group_shadow_compat_v1` 已保持 current owner + shadow baseline 双身份
4. `fact_ingest_shadow_evidence_v1` 已真实产出 accept / reject / duplicate evidence
5. `routing_shadow_prep_v1` 已挂载，但 runtime `study_default` 保持不变
6. `shadow_acceptance_gate_v1` 已写硬并可被测试引用
7. `shadow_to_phase3_gate_v1` 已形成最低证据集合
8. 未越界触碰 DB / API / `review_group` / planner owner / final fact owner
9. 未把 shadow / candidate / compatibility 写成 current runtime truth
10. 已交 patch / sync draft 与 `no-major-change statement`

---

## 13. 给执行层的一句话

> **请按“Limited Execution / Shadow Mode”的边界推进 P3.3.7；让 local-serving、fact ingest、routing 的影子链路真实跑起来，但不要把任何 shadow / candidate / parity 结果写成用户当前可依赖事实，也不要把本轮做成 cutover。**
