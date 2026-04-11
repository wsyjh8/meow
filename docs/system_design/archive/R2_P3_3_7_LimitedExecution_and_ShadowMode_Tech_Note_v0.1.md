# R2_P3_3_7_LimitedExecution_and_ShadowMode_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Type:** tech note / limited-execution framing / shadow-mode round
- **Status:** ready for Room 1 review
- **Version:** v0.1
- **Date:** 2026-04-10
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.7 — Local-Serving Limited Execution / Shadow Mode Round`

---

## 0. 文档定位

本稿不是：
- 新 DB 主文档
- 新 API 主文档
- Room 4 cutover 执行单
- runtime owner shift 完成宣告
- local-serving cutover 方案书
- unified planner / planner merge 直接落地稿
- Phase 3 gate 通过证明

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.7 收成 Phase 2 limited execution / shadow mode：让 local-serving candidate、fact/settlement ingest candidate、routing shadow candidate 在 dev / flag / QA evidence 层开始真实跑起来，并与 current cloud `review_group` 路径做 parity 对照；但 current runtime truth 仍不切到 local。**

一句话：

> **P3.3.7 应该启动，但只能启动“影子层真实运行”，不能启动 runtime owner shift。**

---

## 1. 输入依据与采用口径

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md`
- `p3.3.7_user.md`

### 1.3 Review basis for this round
- `BR-OPP-001_v0.2.7.md`
- `UI_SPEC_v0.2.7.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.5_Claude_res.md`
- `P3.3.6_Claude_res.md`

### 1.4 Runtime truth note
- 当前 Room 1 已把 `P3.3.5` absorbed / closed，并把 `P3.3.6` 视为可 close / 可进入下一轮判断。
- 当前 P3.3.7 的 round review basis 已提升到 `BR / UI v0.2.7`。
- 但 current runtime truth 仍必须继续服从：
  - `home_word_entry = study_default`
  - active continuation 不得 silent reroute
  - ReviewPage current serving truth 继续围绕 cloud `review_group`
  - final fact / settlement truth 继续以后端为准
- 因此，本轮 Room 2 的任务是给 Room 1 一个 **可 pin / 可不 pin 的 Phase 2 shadow-execution contract 候选集合**，而不是直接改写 runtime owner。

---

## 2. Room 2 总判断

### 2.1 一句话结论
> **应该前进一步；但只建议进入 `Limited Execution / Shadow Mode v1`，不建议直接进入 Phase 3 cutover 判断，更不建议提前触发 runtime owner shift completed。**

### 2.2 为什么现在值得进入 Phase 2
因为以下前置已经满足：
1. `P3.3.5` 已完成 Phase 0 / compatibility-prep；
2. `P3.3.6` 已完成 Compatibility Contract v1；
3. local-serving candidate、fact ingest candidate、routing shadow candidate、write-back plan、parity test strategy 都已进入可执行引用层；
4. 若继续停在 contract-only，主线程会缺少真正的 shadow evidence，后续无法判断 Phase 3 是否值得开启。

### 2.3 为什么当前仍不能叫 cutover
因为以下硬边界仍成立：
1. current runtime truth 仍在 cloud review-serving layer；
2. `review_group` 当前仍是 current runtime owner + compatibility anchor + deprecated candidate；
3. planner owner shift 从来不自动带出 fact owner shift；
4. DB / API active baselines 仍是 `v0.2.1`；
5. 本轮 handoff 明确写死：P3.3.7 是 limited execution / shadow mode，不是 runtime rewrite。

---

## 3. Room 2 正式推荐进入层

### 3.1 推荐进入：`Limited Execution / Shadow Mode v1`
Room 2 当前建议 Room 1 若要 pin，本轮只 pin 到以下层级：

1. **local-serving shadow run 的最小执行层**
2. **parity checks 的最小对照层**
3. **`review_group` 作为 runtime owner + shadow baseline 的并存层**
4. **fact / settlement ingest 的 shadow evidence 层**
5. **routing shadow prep 的最小挂载层**
6. **shadow regression / write-back / no-major-change 的固定交付层**

### 3.2 推荐不进入：`Phase 3 / Cutover Decision`
本轮不建议进入：
1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 接管 current ReviewPage truth
4. `review_group` 退出运行态
5. auto-routing runtime
6. unified planner / planner merge
7. API core semantics rewrite
8. DB schema rewrite

---

## 4. Q1 — `shadow_execution_scope_v1`

### 4.1 Room 2 结论
> **可以正式进入 limited execution，但只允许“hidden / flag / evidence-run”，不允许进入用户可见主路径。**

### 4.2 当前允许进入 shadow run 的对象
#### A. `local_due_queue_candidate`
允许进入：
- dev / QA evidence run
- parity comparison input
- hidden marker / debug trace
- feature-flag mount point

不允许进入：
- current ReviewPage 主队列
- current completion / settlement trigger
- 用户可见 current route

#### B. `local_generated_review_session_candidate`
允许进入：
- session-level shadow packaging
- hidden adapter seam
- parity-only queue generation

不允许进入：
- 替代 `next review group`
- current runtime CTA / route
- current ReviewPage user-visible source

#### C. `fact_ingest_shadow_evidence`
允许进入：
- evidence submit / compare
- accept / reject / duplicate shadow result
- cloud fact-layer shadow validation

不允许进入：
- final ledger write
- final daily-goal write
- final streak / learning-day write

#### D. `routing_shadow_candidate`
允许进入：
- hidden marker
- debug / QA evidence
- parity-only decision record

不允许进入：
- user-visible auto-routing
- 覆盖 `study_default`
- 吞掉 active continuation 的独立承接

### 4.3 技术实现层最小要求
本轮若进入执行，Room 4 应至少做到：
1. 所有 shadow run 都必须走 **disabled-by-default feature flag**；
2. 所有 shadow outputs 都必须进入 **evidence / debug / QA layer**，不能漏进 normal user copy；
3. 所有 shadow candidate 都必须保留 **source_type / owner_layer / shadow_only / candidate_reason** 等已冻结语义；
4. 不得因为 shadow run 引入任何对 runtime truth 的隐式覆写。

---

## 5. Q2 — `shadow_result_visibility_v1`

### 5.1 Room 2 结论
> **shadow 结果当前只允许进入 dev / test / QA evidence / patch draft；不允许进入任何用户可依赖事实层。**

### 5.2 可见性四层
#### Layer A — runtime user-visible
当前禁止进入：
- local shadow queue
- local shadow serving source
- local shadow completion result
- parity pass / mismatch 提示
- “本地已接管”“影子验证通过”等任何完成式文案

#### Layer B — internal debug / QA evidence
当前允许进入：
- source comparison
- eligibility comparison
- attempt / progress / completion comparison
- accept / reject / duplicate evidence
- mismatch reason

#### Layer C — patch draft / write-back evidence
当前允许进入：
- no-major-change statement
- runtime truth unchanged statement
- shadow result summary
- parity pass / mismatch buckets
- stop-condition record

#### Layer D — future contract candidate memory
当前允许进入：
- 哪些 mismatch 已知可接受
- 哪些 mismatch 触发 escalate
- 哪些 future DTO / API / DB seam 需要下一轮再讨论

### 5.3 文案硬禁区
本轮继续禁止：
1. “本地已接管复习”
2. “当前复习队列来自本地”
3. “影子结果已生效”
4. “已切换到本地更优路径”
5. “系统已自动改用本地规划”
6. “review_group 已退场 / 已失效”

---

## 6. Q3 — `shadow_acceptance_gate_v1`

### 6.1 Room 2 结论
> **本轮必须先把 parity / mismatch / stop-condition 写硬；没有 gate，就不应该开 Phase 2。**

### 6.2 建议的四类结果
#### A. `parity_pass`
满足以下条件时可记为 pass：
1. local shadow queue 生成成功；
2. 与 cloud `review_group` 的来源、eligibility、attempt / progress / completion 对照在允许误差内；
3. 未产生 runtime truth leakage；
4. 未触碰 final fact / settlement write。

#### B. `acceptable_mismatch`
允许存在，但必须记录原因：
1. local planner 与 cloud group 的排序差异，但不影响 current runtime truth；
2. generated timestamp / candidate metadata 差异；
3. candidate_reason 差异；
4. shadow-only packaging 差异。

#### C. `must_hold_mismatch`
一旦出现，必须阻断继续扩大 shadow scope：
1. local shadow result 被用户可见；
2. current ReviewPage truth 被 local 覆写；
3. `study_default` 被 shadow 路径偷改；
4. local evidence 触发 final ledger / daily_goal / streak write；
5. `review_group` 被写成已退场或已失效。

#### D. `must_escalate`
出现以下情况必须升级给 Room 1 / Room 2：
1. parity mismatch 指向 API core semantics 缺口；
2. parity mismatch 指向 DB schema / ingest seam 缺口；
3. shadow run 需要新增用户可见状态才能继续；
4. shadow run 暗示当前 BR / UI / DB / API 对 owner split 的定义不够用。

### 6.3 Stop conditions
以下任一出现，本轮不应继续扩大 execution：
1. runtime truth leakage
2. feature flag 非预期开启
3. shadow evidence 影响 final fact / settlement
4. ReviewPage 行为偏离 cloud-first runtime
5. auto-routing 以任何形式进入用户路径

---

## 7. Q4 — `shadow_to_phase3_gate_v1`

### 7.1 Room 2 结论
> **P3.3.7 的目标不是证明“可以 cutover”，而是证明“是否值得进入 Phase 3 判断”。**

### 7.2 最低证据集合
未来若要进入 Phase 3 判断，至少需要：
1. shadow queue 生成与 parity 对照可稳定复现；
2. fact ingest shadow evidence 可稳定返回 accept / reject / duplicate；
3. routing shadow markers 可挂载，但 runtime `study_default` 不变；
4. `review_group` 继续保持 current runtime owner，不发生 truth conflict；
5. 所有 mismatch 已被分桶为 acceptable / must-hold / must-escalate；
6. write-back 能明确说明“做了什么、没做什么、runtime truth 是否保持不变”。

### 7.3 仍不足以支持 Phase 3 的证据
以下结果即使看起来“效果不错”，也仍不足以支持 cutover：
1. local shadow queue 在少量样例上与 cloud 很像；
2. debug 面板可见 shadow source；
3. parity tests 全通过，但没有 fact ingest evidence；
4. hidden routing candidate 已存在；
5. Room 4 能在本地跑通一条影子链路。

原因：
- 这些结果最多说明 **shadow run 可行**；
- 还不能说明 **runtime owner shift 安全**。

---

## 8. Major 红线（本轮继续有效）

以下任一动作，都视为越界：
1. 把 local shadow source 写成 current ReviewPage truth
2. 把 `review_group` 写成已退出运行态
3. 把 auto-routing 写成 runtime reality
4. 让 local shadow evidence 直接改 final fact / settlement
5. 改 DB schema
6. 改 API core semantics
7. 把 shadow pass 写成用户承诺事实
8. 把 Phase 2 delivery 写成 owner shift completed

---

## 9. Room 2 正式建议给 Room 1 的最小 pin 集合

若 Room 1 要 pin，本轮 Room 2 建议只 pin：

1. `shadow_execution_scope_v1`
   - 允许 `local_due_queue_candidate` / `local_generated_review_session_candidate` / `fact_ingest_shadow_evidence` / `routing_shadow_candidate` 进入 limited execution
   - 但只在 hidden / flag / QA evidence 层

2. `shadow_result_visibility_v1`
   - 只允许 dev / test / QA evidence / patch draft 可见
   - 禁止用户可见

3. `shadow_acceptance_gate_v1`
   - 固定 parity pass / acceptable mismatch / must-hold mismatch / must-escalate / stop conditions

4. `shadow_to_phase3_gate_v1`
   - 固定下一轮所需最低证据集合
   - 明确哪些结果仍不足以支持 Phase 3

---

## 10. Room 2 一句话结论

> **P3.3.7 现在应该启动；但它只能启动“limited execution / shadow mode”，不能启动 runtime cutover。Room 2 支持本轮把影子链路真正跑起来，并把 mismatch / parity / stop-condition 写硬；但 current runtime truth、`review_group` 当前 serving owner 地位、以及 cloud final fact / settlement owner，当前都不能动。**
