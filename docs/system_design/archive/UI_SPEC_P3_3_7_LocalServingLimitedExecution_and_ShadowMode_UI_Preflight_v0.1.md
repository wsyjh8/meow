# UI_SPEC_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.7 — Local-Serving Limited Execution / Shadow Mode Round`
- **Direct upstream input:** `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md`
- **Related inputs:** `R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md` + `R3_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Rules_Note_v0.1.md` + `BR-OPP-001_v0.2.7.md` + `UI_SPEC_v0.2.7.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.7 当前轮需要回答的 4 个 shadow-mode 问题，翻成可被 Room 1 判断是否 pin 的最小 UI shadow contract。**

本稿不是：
- 新 UI 主文档
- 新 BR / DB / API 主文档
- Room 4 cutover 实施单
- runtime owner shift 完成宣告
- ReviewPage local-serving runtime cutover 方案书
- unified planner / planner merge 落地稿

一句话：

> **P3.3.7 在 Room 5 视角，不是“用户开始用新方案”的轮，而是“新方案在 shadow 层真实跑起来，但用户端仍只看 current runtime truth”的轮。**

---

## 1. 输入依据

### 1.1 主线程 handoff basis
- `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md`

### 1.2 当前 review basis
- `BR-OPP-001_v0.2.7.md`
- `UI_SPEC_v0.2.7.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 1.3 Cross-round framing basis
- `R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md`
- `R3_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Rules_Note_v0.1.md`
- `p3.3.7_user.md`

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持 P3.3.7 进入 Phase 2 / Limited Execution / Shadow Mode，但只支持进入 internal-only shadow execution + runtime-truth guardrails + parity evidence contract。**

### 2.2 为什么可以前进一步
因为当前已经具备进入 shadow-mode 的最低前置：
1. `P3.3.5` 已完成 Phase 0 / Compatibility-Prep
2. `P3.3.6` 已完成 Compatibility Contract v1
3. `review_group` 的 current owner + compatibility anchor + deprecated candidate 三层姿态已写硬
4. local-serving candidate / routing candidate / fact ingest candidate 都已进入可被执行引用的层
5. 若继续停在 contract-only，主线程无法产出真正的 shadow evidence

### 2.3 为什么仍不能叫 cutover
因为以下 current runtime truth 仍必须保持：
1. 首页继续 `home_word_entry = study_default`
2. active continuation 继续独立承接，不得 silent reroute
3. ReviewPage current serving truth 继续围绕 cloud `review_group`
4. final fact / settlement truth 继续以后端为准
5. auto-routing runtime / planner merge / unified planner 继续 pending
6. 用户端不得感知“新 serving 已生效”

---

## 3. Room 5 的总护栏：四层必须分开

### 3.1 current runtime truth
当前用户端必须继续只感知：
1. 首页默认入口 = `study_default`
2. ReviewPage 以 cloud `review_group` 为当前 serving truth
3. active continuation 通过独立 CTA / helper / priority block 承接
4. StudyPage 继续维持当前最小 preview re-entry
5. ReviewPage / 首页继续不显示 preview
6. final fact / settlement 以后端为准

### 3.2 shadow execution
本轮允许真实跑起来，但只允许存在于：
- dev / test
- internal debug / log
- QA evidence
- hidden markers / feature flags / adapter seam

### 3.3 patch / write-back record
本轮允许写入：
- patch draft
- test evidence
- no-major-change statement
- compatibility / deprecated candidate 标记

### 3.4 forbidden overclaim
以下内容本轮不得写成用户可见事实：
1. 本地 serving 已启用
2. ReviewPage 已切到本地队列
3. 当前复习队列来自本地 due
4. owner shift 已完成
5. 已升级到新 serving 方案
6. 影子模式已正式生效

---

## 4. Q1 — `shadow_execution_scope_v1`

## 4.1 Room 5 结论
> **本轮允许 4 类 candidate 进入 limited execution，但都只允许进入 internal-only shadow layer，不进入用户主路径。**

### 4.1.1 允许进入 shadow run 的 candidate
1. `local_due_queue_candidate`
2. `local_generated_review_session_candidate`
3. `fact_ingest_shadow_evidence`
4. `routing_shadow_candidate`

### 4.1.2 页面层的最小翻译
#### A. `local_due_queue_candidate`
- 可以在 dev / QA evidence 层真实跑
- 可以作为 ReviewPage future queue source 的 shadow candidate
- 不得出现在用户可见页面 copy 里

#### B. `local_generated_review_session_candidate`
- 可以在 dev / QA evidence 层真实跑
- 可以作为 future session-level serving 包装候选
- 不得出现在用户可见页面 route / CTA / summary 里

#### C. `fact_ingest_shadow_evidence`
- 可以在 internal evidence 层真实跑
- 可以比较 accept / reject / duplicate
- 不得直接驱动用户端 completion / reward / streak 文案

#### D. `routing_shadow_candidate`
- 可以在 hidden marker / flag-prep / evidence 层真实跑
- 不得改变当前首页 runtime route

### 4.1.3 Room 5 当前不接受的页面影响
本轮不接受：
- 首页主 CTA 文案变化
- ReviewPage 主队列来源文案变化
- 用户可见的新 badge / 新标签 / 新模式说明
- 任何“你现在正在使用新规划”的提示

---

## 5. Q2 — `shadow_result_visibility_v1`

## 5.1 Room 5 结论
> **shadow 结果可以被 internal 层看到，但不能被用户看到。**

### 5.1.1 可以被谁看到
#### A. dev / test 可见
- shadow queue source
- parity result
- ingest action
- mismatch classification
- candidate reason
- owner layer / semantic layer markers

#### B. internal debug / log / QA evidence 可见
- shadow 执行是否成功
- local vs cloud 对照结果
- accept / reject / duplicate evidence
- routing shadow candidate 命中情况
- stop condition 命中情况

#### C. patch draft / write-back 可记录
- current runtime truth 未变化
- 哪些 shadow candidate 已真实跑过
- 哪些 mismatch 被归类为 acceptable / must-hold / escalate
- 哪些用户端 copy 必须继续受限

### 5.1.2 绝不能给用户看见
以下 shadow 结果本轮绝不能给用户看见：
1. 当前队列来源：本地
2. 本地 serving 已启用
3. 已切换到新 serving 方案
4. 已升级到新模式
5. 影子模式已开启
6. 当前已使用本地规划
7. parity 已通过，系统已切换
8. local shadow 已更新你的计划

---

## 6. Q3 — `shadow_acceptance_gate_v1`

## 6.1 Room 5 结论
> **本轮必须把 mismatch 严重度写硬，但 UI 只承接“哪些结果不能泄漏为用户事实”。**

### 6.1.1 Room 5 建议的 4 级判断
#### A. parity pass
表示：
- shadow evidence 与 current cloud path 在当前 round 的关键检查项一致
- 但不表示可以对用户宣称已切换
- 也不自动等于可以进入 Phase 3

#### B. acceptable mismatch
表示：
- 允许存在差异
- 但差异不影响 current runtime truth
- 差异只进入 internal evidence / follow-up list
- 不得出现在用户端

#### C. must-hold mismatch
表示：
- 差异已经触碰 current runtime truth 护栏
- 或触碰 fact / settlement 边界
- 仍不得泄漏给用户，但必须阻止“继续乐观推进”

#### D. escalate-required mismatch
表示：
- 差异已经足以影响 Room 1 是否继续 shadow phase
- 或可能诱发 DB / API / BR / UI 的 silent drift
- 必须升级给 Room 1 / Room 2 / Room 3

### 6.1.2 Room 5 视角的 must-hold / escalate 触发器
以下一旦出现，Room 5 认为至少进入 must-hold mismatch，严重时直接 escalate：
1. 用户端出现 owner shift / local-serving / shadow 已生效的文案
2. ReviewPage current serving truth 被用户可见地写成本地
3. 首页出现 auto-routing runtime 感知
4. local evidence 被用户端写成 final fact / reward / streak 结果
5. deprecated candidate 被用户端写成“旧方案即将失效 / 已退场”

### 6.1.3 Room 5 一句话 gate 原则
> **只要用户能看出来“系统已经切到新方案”，本轮就算 shadow 没守住。**

---

## 7. Q4 — `shadow_to_phase3_gate_v1`

## 7.1 Room 5 结论
> **本轮最多产出“可供 Room 1 判断是否值得考虑 Phase 3”的 evidence，不产出任何 runtime fact 升格。**

### 7.1.1 Room 5 认为至少需要的证据
若未来要支持 Room 1 进入 Phase 3 判断，Room 5 至少希望看到：
1. local shadow queue 与 cloud `review_group` 的稳定 parity evidence
2. fact ingest shadow evidence 的稳定 accept / reject / duplicate 分级
3. routing shadow candidate 没有污染用户主路径
4. 所有用户端 copy / helper / CTA 仍守住 current runtime truth
5. no-major-change statement 成立
6. write-back plan 与 patch draft 可被清楚吸收

### 7.1.2 哪些证据仍然不够
以下“看起来可行”的结果仍然不够支持进入 runtime fact：
1. dev 环境里 local queue 跑通了
2. parity 大多数情况下通过
3. debug panel 能看到 shadow source
4. 某几组 test 过了
5. internal logs 很好看

因为这些都不能自动说明：
- 用户端不会误解
- fact / settlement 边界不会被偷切
- auto-routing / unified planner 不会被静默带出

### 7.1.3 当前继续禁止升格的内容
本轮继续禁止把以下内容升格为 runtime fact：
1. local-serving 已成为 ReviewPage current truth
2. `review_group` 已退出运行态
3. auto-routing 已启用
4. unified planner / planner merge 已成立
5. local evidence 已等同 final fact
6. parity pass = 已切换成功

---

## 8. internal-only marker guidance（Room 5 交付项）

## 8.1 Room 5 建议只允许 internal-only 的标记
以下标记 / 指示器当前只允许存在于 internal-only 层：
- `shadow_only`
- `shadow_run`
- `parity_check`
- `candidate_reason`
- `owner_layer`
- `source_type`
- `serving_eligibility_state`
- `deprecated_candidate`
- `compatibility_anchor`
- `parity_mismatch_level`

### 8.1.1 推荐出现位置
- debug panel
- dev-only overlay
- internal logs
- QA evidence pack
- patch draft / test notes

### 8.1.2 当前不推荐出现位置
- 普通用户首页
- ReviewPage 用户可见正文
- StudyPage 用户可见正文
- 设置页 / 我的页
- toast / snackbar / modal / helper 文案

---

## 9. runtime-truth guardrails（Room 5 交付项）

## 9.1 首页
当前必须继续保护：
1. `home_word_entry = study_default`
2. active continuation 独立承接
3. 不得 silent reroute
4. 不得让 planner-aware / shadow-routing 命中改变用户主路径

## 9.2 ReviewPage
当前必须继续保护：
1. current serving truth = cloud `review_group`
2. queue / continuation / remaining / completion / settlement 文案继续围绕 group 语义
3. local-serving shadow 不得改写用户主队列来源
4. current ReviewPage 不得出现 shadow source 标签

## 9.3 StudyPage
当前必须继续保护：
1. 继续承担最小 preview re-entry
2. preview 继续保持 StudyPage-only / hint-only / estimated-only
3. 当前不新增 shadow-mode explanation
4. 当前不新增“本地规划正在运行”提示

## 9.4 fact / settlement 边界
当前必须继续保护：
1. final fact 以后端为准
2. local evidence 不能被用户端翻译成：
   - 已完成有效复习
   - 今日进度已更新
   - 奖励已到账
   - streak 已续上

---

## 10. user-visible forbidden claims（Room 5 交付项）

以下表达在 P3.3.7 当前轮继续列为用户端禁区：

### local-serving / cutover 禁区
1. 本地 serving 已启用
2. ReviewPage 已切到本地队列
3. 当前复习队列来自本地 due
4. owner shift 已完成
5. 当前 serving truth 已切换
6. 已升级到新 serving 方案

### routing / planner 禁区
7. 系统已自动为你选择更优入口
8. auto-routing 已开启
9. mixed session 已启用
10. planner-aware 首页已生效

### shadow / parity 禁区
11. 影子模式已正式生效
12. parity 已通过，现已切换新模式
13. 当前已使用新方案
14. 当前系统已完成兼容切换

### fact / settlement 禁区
15. 本地已直接记为有效复习
16. 今日进度已因本地 shadow 更新
17. 奖励已因本地队列到账
18. streak 已由本地 shadow 续上

---

## 11. 最小 UI shadow contract 层（Room 5 交付项）

Room 5 建议 Room 1 若要 pin，本轮只 pin 以下最小 UI shadow contract：

1. **shadow execution 允许真实跑，但只限 internal-only**
2. **current runtime truth 继续完全保护**
3. **shadow result visibility 只分 internal-visible 与 user-forbidden 两层**
4. **parity / mismatch 结果只作为 evidence，不作为 runtime fact**
5. **current helper / summary / CTA 继续服从 cloud `review_group` truth**
6. **任何会把 shadow 误写成 cutover 的 copy 继续禁止**

---

## 12. Room 5 一句话结论

> **P3.3.7 在 Room 5 视角，可以进入 Limited Execution / Shadow Mode，但只应前进到“internal-only shadow execution + runtime-truth guardrails + user-visible forbidden claims”的 very narrow UI contract：让新方案在影子层真实跑起来，但用户端仍只能看到旧真相层，不得感知本地 serving、shadow mode、owner shift 或 runtime cutover 已生效。**
