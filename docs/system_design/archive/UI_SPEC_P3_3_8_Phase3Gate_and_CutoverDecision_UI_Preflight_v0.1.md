# UI_SPEC_P3_3_8_Phase3Gate_and_CutoverDecision_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.8 — Phase 3 Gate / Cutover-Decision + DB/API Candidate Round`
- **Direct upstream input:** `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md`
- **Related inputs:** `BR-OPP-001_v0.2.9.md` + `UI_SPEC_v0.2.9.md` + `背单词喵喵app_DB设计草案_v0.2.1.md` + `背单词喵喵app_API设计草案_v0.2.1.md` + `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` + `P3.3.7_Claude_res.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.8 当前轮需要回答的 6 个 Phase 3 gate / cutover-decision 问题，翻成可被 Room 1 判断是否 pin 的最小 UI gate contract。**

本稿不是：
- 新 UI 主文档
- 新 PRD / BR / DB / API 主文档
- Room 4 cutover 执行单
- runtime owner shift 完成宣告
- ReviewPage local-serving runtime cutover 方案书
- unified planner / planner merge 落地稿

一句话：

> **P3.3.8 在 Room 5 视角，不是“开始切新 UI runtime truth”的轮，而是“判断现在够不够资格进入 very narrow limited cutover candidate，并把 UI migration / write-back / hold-note 边界写硬”的轮。**

---

## 1. 输入依据

### 1.1 Main-thread handoff basis
- `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.2 当前治理层 / 运行层 basis
- `ORG_v0.3.1.md`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- `Main_updated_2026-04-10_v28.md`
- `STATUS_updated_2026-04-10_v26.md`

### 1.3 当前 round review basis
- `BR-OPP-001_v0.2.9.md`
- `UI_SPEC_v0.2.9.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.7_Claude_res.md`

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持 P3.3.8 进入 `Phase 3 Gate / Cutover-Decision + DB/API Candidate Round`，但只支持进入 very narrow 的 cutover-decision / candidate-migration 层；当前仍不支持把 local-serving、owner shift、auto-routing、或 `review_group` 退场写成已生效事实。**

### 2.2 为什么现在应该进入 Gate / Decision
因为当前已经具备：
1. current runtime truth regression 证据
2. shadow parity evidence
3. mismatch / stop-condition 分级
4. local-serving / routing / fact-ingest shadow 已真实跑过
5. BR / UI 已完成 `v0.2.9` 候选主文档回写

如果现在还停在“只是 shadow 存在”，不把这些证据转成下一层决策，主线程会继续空转。

### 2.3 为什么仍然不能叫 cutover
因为当前 runtime truth 仍必须保持：
1. 首页 `home_word_entry = study_default`
2. active continuation 继续独立承接，不得 silent reroute
3. ReviewPage current serving truth 继续围绕 cloud `review_group`
4. final fact / settlement truth 继续以后端为准
5. 用户端不得出现 “已切到本地规划 / 已升级到新 serving / 已自动安排学习路径”
6. DB / API active baselines 仍是 `v0.2.1`

---

## 3. Room 5 的总护栏：五层必须分开

### 3.1 current runtime truth
当前用户端必须继续只感知：
- 首页默认入口 = `study_default`
- ReviewPage current serving truth = cloud `review_group`
- active continuation 独立承接
- StudyPage 继续承担当前最小 preview re-entry
- ReviewPage / 首页继续不显示 preview
- final fact / settlement 以后端为准

### 3.2 phase-3 gate evidence
当前只允许进入：
- parity 证据
- mismatch 分级
- proceed / hold / escalate / revise 建议
- cutover subset 候选
- migration / rollback / hold-note 候选

### 3.3 limited cutover candidate
当前只允许写成：
- 哪些页面最先受影响
- 哪些 helper / summary / CTA / empty-state 要先重写
- 哪些 seam 可以升到 candidate contract
- 哪些仍必须保持 runtime truth 不变

### 3.4 candidate migration layer
当前允许进入：
- UI candidate migration sequence
- deprecated / compatibility / runtime truth 切换条件
- write-back 顺序
- rollback / hold note 的最小模板要求

### 3.5 forbidden overclaim
以下内容本轮不得写成用户可见事实：
- 本地 serving 已启用
- ReviewPage 已切到本地队列
- owner shift 已完成
- `review_group` 已退场
- auto-routing 已开启
- planner-aware 首页已生效
- 本地 evidence 已直接成为 final fact
- 当前已完成兼容切换 / cutover

---

## 4. `phase3_gate_decision_v1`（Room 5 页面版）

## 4.1 Room 5 结论
> **Room 5 支持进入 Phase 3 gate，但当前只支持 “gate / candidate / migration” 三层，不支持 runtime fact 升格。**

## 4.2 从 UI 视角，什么证据足以支持“可继续考虑下一层”
Room 5 认为至少要同时满足以下条件，才值得进入 **limited cutover candidate** 讨论：

### A. current runtime truth 未漂移
1. 首页仍 `study_default`
2. active continuation 仍独立承接
3. ReviewPage 仍以 cloud `review_group` 作为用户可见 serving truth
4. 用户端未出现 local-serving / shadow / cutover 宣告
5. StudyPage preview 边界未扩大

### B. shadow evidence 稳定且可解释
1. shadow 结果可以稳定记录
2. parity / mismatch 分类可复现
3. 内部 evidence 足够说明“新路径在候选层面可比较”
4. 没有出现一批过、一批不过但无法解释的噪声

### C. fact / settlement 边界未被偷切
1. local evidence 未被写成 final fact
2. completion / reward / streak 等结果文案未被 shadow 污染
3. deprecated candidate 未误写成“旧方案已退出”

## 4.3 Room 5 视角的 hold / escalate 触发器
### Must-hold
以下一旦出现，至少进入 hold：
1. 首页 helper / CTA 已开始依赖 local-serving shadow 结果
2. ReviewPage 用户可见文案写成“当前队列来自本地”
3. `review_group` 被用户端写成“即将失效 / 已退场”
4. local evidence 被用户端写成“已完成有效复习 / 奖励已到账”

### Must-escalate
以下一旦出现，必须升级：
1. 用户可见 runtime truth 被静默切换
2. helper / summary / CTA 出现新旧真相层混写
3. local-serving candidate 已开始影响用户真实路由
4. UI 已无法用单一 copy 解释 current runtime truth

## 4.4 Room 5 给 Room 1 的 gate 规则句
> **只有当 current runtime truth 完整守住、shadow evidence 可解释且稳定、并且 UI 层未发生任何 user-visible owner-shift / cutover 假事实时，Room 5 才支持从 P3.3.8 进入下一层 limited cutover candidate 判断。**

---

## 5. `limited_cutover_scope_candidate_v1`（Room 5 页面版）

## 5.1 Room 5 结论
> **如果进入下一层 limited cutover candidate，最先受影响的不是“所有页面一起切”，而是 ReviewPage 的内部 truth adapter、首页 helper / summary / CTA 层，以及与 `review_group` 强绑定的文案层。**

## 5.2 哪些页面最先受影响
### 第一优先：ReviewPage
最先受影响，因为：
1. current serving truth 还在 cloud `review_group`
2. future serving owner shift 若发生，最先改的必然是 queue / continuation / remaining / completion 的来源解释
3. 这里最容易把 compatibility candidate 误写成 runtime cutover

### 第二优先：SpecHomePage / 首页摘要层
最先受影响的不是整个首页架构，而是：
- review helper
- summary block
- continuation CTA
- empty-state
- no-review-state 文案

因为一旦 local-serving candidate 进入下一层，首页“今天该先做什么”的解释会先受影响。

### 第三优先：Settings / 我的页中的 migration / backup / restore 说明层
如果进入下一层 gate，设置页 / 我的页会首先需要更明确区分：
- current runtime truth
- compatibility / deprecated candidate
- backup / restore 与 cutover 并不是一回事

### 第四优先：StudyPage 的 explanation 候选层
StudyPage 主体暂不先切，但它的 preview / explanation 候选层可能被要求重新确认边界。

## 5.3 最小 cutover subset（Room 5 倾向）
Room 5 倾向：
1. **先动 ReviewPage 的 source-neutral state contract**
2. **再动首页 helper / summary / CTA 的 source-neutral wording**
3. **最后才考虑 route / primary entry / helper winner 的变化**

### Room 5 不倾向先动
- 首页默认 route
- 用户可见 auto-routing
- ReviewPage 用户可见 preview
- “本地已接管”类模式宣告

## 5.4 当前仍必须保持 current runtime truth 不变的状态
1. 首页默认入口
2. active continuation 的承接方式
3. ReviewPage 当前主队列来源
4. completion / settlement / reward 最终事实
5. preview 显示范围

---

## 6. `db_api_candidate_round_v1`（Room 5 页面版）

## 6.1 Room 5 结论
> **Room 5 支持本轮正式开启 DB / API candidate round，但 UI 只承接“哪些 seam 需要升到 candidate contract”，不承接 schema / payload 直接重写。**

## 6.2 从 UI 视角，哪些 seam 值得升级到 candidate contract
Room 5 当前最关心以下 seam：

### A. ReviewPage source seam
至少需要能区分：
- current serving source
- compatibility source
- candidate source
- shadow-only source

### B. Continuation / summary seam
至少需要能区分：
- current runtime continuation
- local-serving compatibility continuation candidate
- candidate-not-active
- deprecated-but-still-serving

### C. Fact / settlement seam
至少需要能区分：
- evidence only
- accepted fact candidate
- final backend-confirmed fact
- final settlement result

### D. Migration / posture seam
至少需要能区分：
- current runtime owner
- compatibility anchor
- deprecated candidate
- pending exit gate

## 6.3 哪些只应写成 candidate，不应立刻进 active baseline
1. local queue source 的用户可见命名
2. ReviewPage source 切换后的用户 copy
3. route 选择结果字段
4. `review_group` exit 状态的用户文案
5. fact ingest 强化后可能带来的 completion / reward helper

## 6.4 哪些核心语义继续禁止重写
1. current runtime truth
2. final fact / settlement owner
3. StudyPage preview 当前边界
4. auto-routing current status
5. `review_group` 当前 runtime owner 身份

---

## 7. `review_group_exit_gate_v1`（Room 5 页面版）

## 7.1 Room 5 结论
> **`review_group` 当前还不具备进入真实退场判断的页面条件；P3.3.8 最多只能把“退场 gate 的前置条件”写硬。**

## 7.2 在进入真实退场判断前，哪些 contract / tests / docs 必须先齐
### Contract 必须先齐
1. ReviewPage source-neutral state contract
2. continuation / summary / helper 的 source-neutral wording contract
3. fact / settlement ingest boundary contract
4. migration / rollback / hold-note contract
5. deprecated candidate 与 compatibility-only 的明确资产清单

### Tests 必须先齐
1. current runtime truth regression
2. user-visible forbidden claims regression
3. shadow / parity evidence classification regression
4. `review_group` still-serving / still-visible / not-yet-exited regression
5. cutover-candidate no-leak regression

### Docs 必须先齐
1. BR 的 exit gate 条件
2. UI 的 source-neutral rewrite / migration 路径
3. DB / API 的 candidate seam 文档
4. rollback / hold note 最小模板

## 7.3 Room 5 的 gate 规则句
> **在 ReviewPage 还不能用 source-neutral 文案完整承接队列、continuation、completion 与 settlement 之前，Room 5 不支持 `review_group` 进入真实退场判断。**

---

## 8. `fact_settlement_cutover_boundary_v1`（Room 5 页面版）

## 8.1 Room 5 结论
> **Room 5 支持本轮把 local evidence 何时才可能进入更强 active ingest path 的边界写硬，但当前仍不支持把 owner shift 写成 fact owner shift。**

## 8.2 哪些最终事实仍必须继续以后端为准
当前继续必须以后端为准：
1. effective review fact
2. daily goal progress / completion
3. reward settlement impact
4. streak / learning_day / check-in 最终事实
5. completion /到账 类主反馈

## 8.3 哪些 owner shift 绝不能被误写成 fact owner shift
以下当前都绝不能被翻译成“最终事实已由本地决定”：
1. local-serving queue candidate
2. local-generated session candidate
3. routing shadow candidate
4. ingest shadow evidence
5. parity pass

## 8.4 Room 5 对页面层的最小硬限制
即使未来进入 stronger active ingest candidate，当前也不得出现：
- 已记为有效复习
- 今日目标已推进
- 奖励已到账
- streak 已续上
- 学习事实已更新到最终结果

除非 backend fact layer 已明确确认。

---

## 9. `phase3_writeback_and_migration_v1`（Room 5 页面版）

## 9.1 Room 5 结论
> **P3.3.8 值得正式推进 write-back / migration 次序，但 UI 只推进到“最小 UI candidate migration 层”，不推进 runtime cutover 写回。**

## 9.2 Room 5 推荐的最小 UI candidate migration 层
### Layer A — Truth-neutral copy prep
先重写最容易误导的文案：
- ReviewPage helper
- continuation 文案
- empty-state
- no-review-state
- summary block

目标：
- 去掉只适配 cloud-group 的强绑定表述
- 但不提前宣称 local-serving 已生效

### Layer B — Source-neutral state contract
再建立：
- queue source-neutral state names
- continuation source-neutral state names
- completion / settlement source-neutral display rules

目标：
- 让页面 future 能切 source
- 但 current runtime truth 不漂移

### Layer C — Compatibility / deprecated marker absorb
再吸收：
- 哪些 UI 资产进入 deprecated candidate
- 哪些仍保留 compatibility-only
- 哪些可被 future cutover 替换

### Layer D — Cutover-decision note / hold note / rollback note
最后才补：
- hold note
- rollback note
- migration note
- no-major-change statement

## 9.3 Room 5 推荐的回写顺序
1. **Room 2：DB / API candidate seams**
2. **Room 3：BR gate / exit / fact-boundary rules**
3. **Room 5：UI candidate migration / forbidden claims / source-neutral state contract**
4. **Room 1：统一吸收为 close-preflight 或 R1→R4 execution handoff**
5. **Room 4：只在 Room 1 正式下发执行单后实施**

## 9.4 Room 5 对 migration 最小路径的判断
> **最小路径不是“先切 route”，而是“先中和 copy，再中和 state，再写清 hold/rollback，再决定是否值得切 source”。**

---

## 10. runtime-truth guardrails（Room 5 交付项）

### 首页
当前必须继续保护：
1. `home_word_entry = study_default`
2. active continuation 独立承接
3. 不得 silent reroute
4. 不得让 planner-aware / cutover-candidate 命中改变用户主路径

### ReviewPage
当前必须继续保护：
1. current serving truth = cloud `review_group`
2. queue / continuation / remaining / completion / settlement 文案继续围绕 current truth
3. local-serving candidate 不得改写用户主队列来源
4. 当前 ReviewPage 不得出现“已切到本地 serving”的用户标签

### StudyPage
当前必须继续保护：
1. 继续承担最小 preview re-entry
2. preview 继续保持 StudyPage-only / hint-only / estimated-only
3. 当前不新增 cutover explanation
4. 当前不新增“本地规划已生效”提示

### Settings / 我的页
当前必须继续保护：
1. backup / restore 不得被误写成 sync / cutover
2. 不得出现“现在所有设备学习计划都一致”
3. 不得出现“恢复后将自动接入新规划”

---

## 11. user-visible forbidden claims（Room 5 交付项）

以下表达在 P3.3.8 当前轮继续列为用户端禁区：

### local-serving / cutover 禁区
1. 本地 serving 已启用
2. ReviewPage 已切到本地队列
3. 当前复习队列来自本地 due
4. owner shift 已完成
5. 当前 serving truth 已切换
6. 已升级到新 serving 方案

### review_group exit 禁区
7. `review_group` 已退场
8. 旧方案即将不可用
9. 当前已不再使用 `review_group`
10. 已完成旧方案迁移

### routing / planner 禁区
11. 系统已自动为你选择更优入口
12. auto-routing 已开启
13. mixed session 已启用
14. planner-aware 首页已生效

### fact / settlement 禁区
15. 本地已直接记为有效复习
16. 今日进度已因本地方案更新
17. 奖励已因本地队列到账
18. streak 已因本地 serving 续上

### migration / shadow / parity 禁区
19. 影子模式已正式生效
20. parity 已通过，现已切换新模式
21. 当前已完成兼容切换
22. 现在你正在使用新的复习规划

---

## 12. 最小 UI candidate migration 层（Room 5 交付项）

Room 5 建议 Room 1 若要 pin，本轮只 pin 以下最小 UI candidate migration 层：

1. **哪些页面最先受影响**
   - ReviewPage
   - 首页 helper / summary / CTA
   - Settings / 我的页的 migration 说明层

2. **哪些状态仍必须保持 current runtime truth**
   - 首页默认入口
   - active continuation 现行承接方式
   - ReviewPage current serving truth
   - final fact / settlement truth
   - preview 当前可见范围

3. **哪些 helper / summary / CTA / empty-state 会首先出问题**
   - ReviewPage 绑定 `review_group` 的 helper / completion copy
   - 首页 review helper / summary block / no-review-state
   - 任何把 source、owner、fact、settlement 混成一句话的 CTA

4. **哪些表述绝不能提前出现**
   - 一切 owner shift / cutover / review_group exit / local fact-owner 化 / auto-routing 宣告

5. **回写顺序与 UI migration 最小路径**
   - 先中和 copy
   - 再中和 state contract
   - 再分层 deprecated / compatibility-only
   - 最后才讨论是否值得切 source

---

## 13. Room 5 一句话结论

> **P3.3.8 在 Room 5 视角，可以进入 Phase 3 gate / cutover-decision + DB/API candidate round，但只能前进到“gate evidence + limited cutover subset candidate + source-neutral UI migration path”的 very narrow 层；当前仍必须完整保护 `study_default` 首页入口、cloud `review_group` serving truth、后端 final fact / settlement truth，并继续禁止一切会让用户误以为已经 cutover / owner shift / review_group 退场 / auto-routing 生效的表达。**
