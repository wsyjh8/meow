# UI_SPEC_P3_3_9_FirstVeryNarrowCutover_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.9 — First Very Narrow Cutover Round`
- **Direct upstream input:** `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md`
- **Related inputs:** `BR-OPP-001_v0.2.10.md` + `UI_SPEC_v0.3.0.md` + `背单词喵喵app_DB设计草案_v0.2.1.md` + `背单词喵喵app_API设计草案_v0.2.1.md` + `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` + `P3.3.8_Claude_res.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.9 当前轮需要回答的 6 个 first-cutover 问题，翻成可被 Room 1 判断是否 pin 的最小 UI cutover preflight 合同。**

本稿不是：
- 新 UI 主文档
- 新 PRD / BR / DB / API 主文档
- Room 4 cutover 执行单
- runtime owner shift 完成宣告
- ReviewPage local-serving full runtime cutover 方案书
- `review_group` 退场稿
- active DB / API baseline uplift 稿

一句话：

> **P3.3.9 在 Room 5 视角，不是“大切换轮”，而是“挑一个最小 runtime seam 做 first cutover 候选，同时把 retained anchor、rollback / hold、以及 user-visible overclaim 护栏写硬”的轮。**

---

## 1. 输入依据

### 1.1 Main-thread handoff basis
- `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.2 Current runtime / review basis
- `BR-OPP-001_v0.2.10.md`
- `UI_SPEC_v0.3.0.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.8_Claude_res.md`
- `Main_updated_2026-04-10_v29.md`
- `STATUS_updated_2026-04-10_v27.md`

### 1.3 Room 5 采用口径
1. 当前 runtime truth 仍以 `UI_SPEC_v0.3.0.md` 的已吸收事实为准。
2. `review_group` 当前仍是 ReviewPage 用户可见 serving truth。
3. final fact / settlement truth 当前仍以后端为准。
4. 本轮若讨论 cutover，只能讨论 **一个 very narrow subset**。
5. cleanup / `review_group` 真退场 / active DB-API baseline uplift 当前继续后置。

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持 P3.3.9 正式启动，但只支持进入“first very narrow cutover preflight”，且当前最稳的第一拍不是先改首页 route，也不是先改 final fact，而是先切 ReviewPage 的最小 serving-adapter seam + source-neutral UI contract。**

### 2.2 为什么现在可以前进一步
因为当前已经具备：
1. current runtime truth regression 证据
2. shadow parity / mismatch / stop-condition 证据
3. `review_group` exit gate 仍被清楚 gated
4. UI migration / copy neutralization / forbidden claims 已进入主文档候选
5. DB/API seam candidate / migration / rollback / hold-note 已完成上一轮 framing

### 2.3 为什么这轮仍不能叫 full cutover
因为以下 current runtime truth 仍必须继续保持：
1. 首页默认入口仍是 `study_default`
2. active continuation 继续独立承接，不得 silent reroute
3. ReviewPage 用户可见 serving truth 继续围绕 cloud `review_group`
4. final fact / settlement truth 继续以后端为准
5. 用户端不得看到“本地 serving 已启用 / 已切换到新规划 / `review_group` 已退场”

---

## 3. Room 5 的总护栏：六层必须分开

### 3.1 current runtime truth
当前用户端继续只感知：
- 首页默认入口 = `study_default`
- ReviewPage current serving truth = cloud `review_group`
- active continuation 独立承接
- StudyPage preview 继续保持当前最小边界
- final fact / settlement 以后端为准

### 3.2 first cutover subset candidate
本轮只允许讨论：
- 一个最小 runtime seam
- retained anchor 怎么保留
- rollback / hold / fallback 怎么写
- 哪些 helper / summary / CTA / state contract 需要先中和

### 3.3 retained anchor layer
本轮允许 `review_group` 进入：
- retained fallback anchor
- current visible owner
- rollback target
- compatibility anchor

### 3.4 fact-owner guardrail
本轮不允许：
- serving subset 切换带出 fact owner shift
- reward / streak / daily goal / settlement 跟着一起切

### 3.5 migration / rollback / hold note layer
本轮允许：
- source-neutral copy prep
- source-neutral state contract
- rollback note
- hold note
- fallback wording

### 3.6 forbidden overclaim
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

## 4. Q1 — `first_cutover_subset_v1`（Room 5 页面版）

## 4.1 Room 5 结论
> **Room 5 推荐第一轮 first cutover 先切“ReviewPage 的最小 serving-adapter seam”，不先切首页 route，不先切 final fact，不先切 `review_group` 退场。**

### 4.1.1 Room 5 推荐的 first cutover subset
当前最稳的 subset 是：

1. **ReviewPage source-neutral state contract**
   - 让 ReviewPage 的内部状态层不再只会表达 `cloud_group wording`
   - 但当前用户可见 truth 仍先保持 `review_group`

2. **ReviewPage serving-adapter seam**
   - 允许极窄的一段 local-serving candidate 进入更强一层 cutover 候选
   - 但必须带 retained anchor 与 rollback floor

3. **与 ReviewPage 强绑定的 helper / summary / empty-state / continuation copy neutralization**
   - 先中和“只能解释 cloud-group” 的文案
   - 不提前宣称 local-serving 已生效

### 4.1.2 Room 5 当前不推荐的 first cutover subset
本轮不推荐先切：
1. 首页默认 route
2. 首页主 CTA 逻辑
3. 用户可见 auto-routing
4. ReviewPage 用户可见 preview
5. final fact / settlement owner
6. `review_group` 真实退场

### 4.1.3 Room 5 一句话判断
> **第一拍应该先切“ReviewPage 内部 source adapter + source-neutral UI 契约”，而不是先切“用户看到的主路由与最终事实”。**

---

## 5. Q2 — `runtime_truth_switch_boundary_v1`（Room 5 页面版）

## 5.1 Room 5 结论
> **若本轮真的做 first cutover，允许最小范围内被切换的，只能是 ReviewPage 某条内部 serving seam；用户可见的 current runtime truth 仍大面积保持不变。**

### 5.1.1 当前仍必须保持不变的 runtime truth
以下状态本轮继续必须保持：

#### 首页
1. `home_word_entry = study_default`
2. active continuation 独立承接
3. 不得 silent reroute
4. 不得 planner-aware 主路径生效

#### ReviewPage（用户可见层）
5. 当前主队列 truth 仍围绕 `review_group`
6. completion / settlement / progress 主表达继续围绕 current runtime truth
7. 当前不得把用户可见 queue source 写成本地

#### StudyPage
8. preview 继续保持 StudyPage-only / hint-only / estimated-only
9. 当前不新增 cutover / local-planner explanation

#### Fact / Settlement
10. final fact / settlement / reward / streak / daily goal / learning_day 继续以后端为准

### 5.1.2 本轮最有可能允许被 very-narrow 切换的 seam
只有以下层级值得讨论：
- ReviewPage 内部 source adapter seam
- source-neutral state naming seam
- helper / empty-state 的 source-neutral wording seam

不是：
- 用户可见主 truth
- 用户可见 route
- final fact owner

---

## 6. Q3 — `review_group_retained_anchor_v1`（Room 5 页面版）

## 6.1 Room 5 结论
> **P3.3.9 第一轮 cutover 中，`review_group` 不应继续只被理解成“current owner”，也还不能被写成“已退场”；最稳的 UI 姿态是：用户可见层继续是 current owner，同时在治理层与实现层进入 retained fallback anchor。**

### 6.1.1 retained anchor 的页面含义
Room 5 当前建议：

#### A. 对用户可见层
- `review_group` 继续作为当前 ReviewPage 主承接对象
- 当前 helper / summary / CTA 仍不得写成“你现在已经不再使用 group”

#### B. 对 cutover / fallback 设计层
- `review_group` 必须继续是 fallback anchor
- 一旦 first cutover subset 出现 must-hold / rollback 条件，应能回落到 `review_group` 路径
- rollback 后的用户侧文案必须仍然说得通，不能暴露“刚刚切失败了”

#### C. 对 retained-anchor 文案层
- 不新增“兼容模式 / 旧方案 / 新方案”这类模式文案
- 不让用户知道当前有两条 serving path 在角力

### 6.1.2 会受 retained anchor 影响的 UI 资产
1. ReviewPage helper
2. continuation 文案
3. progress summary
4. empty-state / no-review-state
5. completion / settlement 的解释层
6. 首页 review helper / summary block

### 6.1.3 Room 5 的最强判断句
> **只要 `review_group` 还承担 rollback anchor 角色，用户端就不应看到任何“`review_group` 已退场 / 已失效 / 即将不可用”的表达。**

---

## 7. Q4 — `fact_owner_guardrail_v1`（Room 5 页面版）

## 7.1 Room 5 结论
> **本轮如果切 serving subset，页面层最需要守的不是“哪个队列更合理”，而是“用户绝不能因此误以为 final fact owner 也已经切了”。**

### 7.1.1 当前仍必须以后端为准的最终事实
1. effective review fact
2. daily goal progress / completion
3. reward settlement / ledger arrival
4. streak / learning_day / check-in 最终事实
5. completion /到账 类主反馈

### 7.1.2 本轮绝不能跟着 serving cutover 一起切的页面结果
1. 已记为有效复习
2. 今日目标已推进 / 已完成
3. 奖励已到账
4. streak 已续上
5. 学习事实已更新到最终结果
6. 学习记录已正式生效

### 7.1.3 Room 5 的硬限制
即使 future local-serving subset 真被切一小段，当前也只能写：
- 继续复习
- 当前可继续
- 当前暂不可继续
- 当前暂无可继续内容

不能写：
- 已完成有效复习
- 奖励已到账
- 计划已更新为最终结果

除非 backend fact layer 明确确认。

---

## 8. Q5 — `db_api_cutover_candidate_v2`（Room 5 页面版）

## 8.1 Room 5 结论
> **Room 5 支持 DB / API 进入 first-cutover-ready candidate round，但 UI 只承接“哪些 seam 现在值得升到 first-cutover-ready”，不承接 active baseline uplift。**

### 8.1.1 Room 5 当前最关心的 first-cutover-ready seam
#### A. ReviewPage source seam
至少需要能表达：
- current visible source
- retained fallback anchor
- active candidate seam
- rollback target

#### B. Continuation / helper seam
至少需要能表达：
- current continuation
- source-neutral continuation
- retained-anchor-compatible continuation
- hold / fallback 后仍不误导的 continuation

#### C. Fact / settlement seam
至少需要能表达：
- evidence only
- stronger ingest candidate
- backend-confirmed final fact
- final settlement result

#### D. Migration posture seam
至少需要能表达：
- current runtime owner
- retained fallback anchor
- compatibility-only
- deprecated candidate
- not-yet-exited

### 8.1.2 本轮继续禁止 UI 承接的变化
1. schema rewrite 的用户含义
2. endpoint core semantics rewrite 的用户 copy
3. new active baseline uplift 宣告
4. `review_group` exit wording
5. route 切换结果字段的用户展示

---

## 9. Q6 — `rollback_holdnote_and_observability_v1`（Room 5 页面版）

## 9.1 Room 5 结论
> **P3.3.9 真正变难的地方不是“能不能切一小段”，而是“切了之后，用户看起来仍然像没被误导”。所以 rollback / hold / fallback 的 UI 说明必须先写硬。**

### 9.1.1 Room 5 建议的最小 fallback / hold UI notes
#### A. 用户侧最小原则
- 不暴露 “切换失败 / rollback / shadow mismatch / local candidate failed” 这类内部术语
- 用户继续只看到 current runtime truth 可解释的文案
- 必要时只允许使用中性、短句、当前态可自洽的提示

#### B. 推荐的中性说明风格
可接受：
- 当前暂无法继续复习，请稍后再试
- 当前没有可继续的复习内容
- 请稍后重试

不接受：
- 已回退到旧方案
- 本地 serving 失败，已切回云端
- 新规划暂不可用
- 因 candidate mismatch 已停止切换

#### C. Hold note / rollback note 的 UI 最低要求
1. 必须有一份 **user-visible copy 禁区清单**
2. 必须有一份 **中性 fallback copy 候选清单**
3. 必须有一份 **哪些页面保持静默、哪些页面允许短句提示** 的表
4. 必须保证 rollback 后页面主路径仍然解释得通

### 9.1.2 Room 5 对 observability 的要求
可以增强：
- internal logs
- QA evidence
- debug markers
- hold / rollback evidence pack

但不能增强到：
- 用户看见“模式切换中 / 已切回旧方案 / 新方案不可用”

---

## 10. first-cutover 的页面承接建议（Room 5 交付项）

### 10.1 第一优先受影响页面
1. **ReviewPage**
2. **首页 review helper / summary / continuation CTA 层**
3. **ReviewPage completion / empty-state / no-review-state 层**
4. **Settings / 我的页中的 migration 说明层（如本轮真的需要补 note）**

### 10.2 当前必须继续保持 current runtime truth 的页面 / 状态
1. 首页默认入口
2. active continuation 的当前承接方式
3. ReviewPage 用户可见主队列来源
4. final fact / settlement 主反馈
5. StudyPage preview 可见范围

### 10.3 `review_group` retained anchor UI guidance
1. 当前继续保留 current-visible owner 身份
2. 同时作为 fallback / rollback anchor
3. 当前不新增“兼容模式 / 新旧方案”的用户文案
4. 任何新 cutover subset 都必须在 `review_group` 仍可回退的前提下设计 UI 状态

### 10.4 fallback / hold UI notes
1. 用户侧只允许中性短句
2. 内部切换 / hold / rollback 信息只进 QA / debug / logs
3. rollback 后页面必须仍能被解释为 current runtime truth
4. 页面不出现“已切换 / 已回退 / 已升级”类术语

### 10.5 最小 UI cutover subset 层
Room 5 推荐本轮 first cutover 最多只到：
1. ReviewPage source-neutral state contract
2. ReviewPage serving-adapter seam
3. 与其强绑定的 helper / summary / CTA / empty-state copy neutralization

不建议本轮先到：
- 首页 route 切换
- auto-routing
- ReviewPage preview re-entry
- user-visible local source naming
- `review_group` 退场 copy

---

## 11. user-visible forbidden claims（P3.3.9 补强）

以下表达在 P3.3.9 当前轮继续列为用户端禁区：

### local-serving / cutover 禁区
1. 本地 serving 已启用
2. ReviewPage 已切到本地队列
3. 当前复习队列来自本地 due
4. owner shift 已完成
5. 当前 serving truth 已切换
6. 已升级到新 serving 方案

### `review_group` exit 禁区
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

### migration / rollback / hold 禁区
19. 已回退到旧方案
20. 新方案暂不可用
21. 已完成兼容切换
22. 现在你正在使用新的复习规划

---

## 12. Room 5 对 Room 1 的建议

### 12.1 建议 Room 1 可吸收的最小 UI cutover 合同层
Room 1 若要 pin，本轮建议只吸收以下 6 条：

1. **first cutover 最稳的 subset 是 ReviewPage 内部 serving-adapter seam，而不是首页 route 或 final fact owner**
2. **用户可见 current runtime truth 本轮继续大面积保持不变**
3. **`review_group` 在 first cutover 中应保留为 retained fallback anchor，且用户端不得感知它已退场**
4. **local-serving subset 切换不得带出 fact owner shift**
5. **rollback / hold / fallback 的 UI 必须先写硬，且用户侧只允许中性短句**
6. **任何会把 first cutover 写成 owner shift / cutover completed / `review_group` exited / local fact-owner 化的文案继续禁止**

### 12.2 当前仍不建议吸收成 runtime truth 的内容
1. 首页默认 route 切换
2. auto-routing runtime
3. ReviewPage 用户可见 local source naming
4. `review_group` 真退场
5. final fact owner shift
6. active DB/API baseline uplift
7. 用户可见模式切换宣告

---

## 13. Room 5 一句话结论

> **P3.3.9 在 Room 5 视角，可以进入 First Very Narrow Cutover Preflight，但当前最稳的第一拍只应切 ReviewPage 的最小 serving-adapter seam 与 source-neutral UI contract：用户可见 current runtime truth 继续大面积不变，`review_group` 继续保留为 retained fallback anchor，final fact / settlement truth 继续以后端为准，而所有会让用户误以为已经 owner shift / cutover / `review_group` 退场的表达，都必须继续禁止。**
