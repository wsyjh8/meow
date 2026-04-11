# UI_SPEC_P3_3_11_FullerCutoverExecution_ExitCandidate_and_DBUpliftReadiness_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.11 — Fuller-Cutover Execution / review_group Exit-Candidate / DB-API Uplift-Readiness Round`
- **Direct upstream input:** `R1_P3_3_11_ScopePin_and_Handoff_Pack_v0.2.md`
- **Related inputs:** `BR-OPP-001_v0.2.12.md` + `UI_SPEC_v0.3.2.md` + `背单词喵喵app_DB设计草案_v0.2.1.md` + `背单词喵喵app_API设计草案_v0.2.1.md` + `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` + `P3.3.10_Claude_res.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.11 当前轮需要回答的 fuller-cutover execution / exit-candidate / uplift-readiness 问题，翻成可被 Room 1 判断是否 pin 的最小 UI execution-preflight contract。**

本稿不是：
- 新 UI 主文档
- 新 PRD / BR / DB / API 主文档
- Room 4 fuller-cutover 执行单
- full cutover 完成宣告
- `review_group` 真退场公告
- active DB / API baseline uplift absorbed 生效稿

一句话：

> **P3.3.11 在 Room 5 视角，不是“已经切完”的轮，而是“在 P3.3.10 judgment 基础上，把更完整一拍的 execution subset 扩大一小层，同时继续守住 current runtime truth、retained anchor、fact-owner boundary 与 uplift-readiness 不越界”的轮。**

---

## 1. 输入依据

### 1.1 Main-thread handoff basis
- `R1_P3_3_11_ScopePin_and_Handoff_Pack_v0.2.md`

### 1.2 Current runtime / review basis
- `BR-OPP-001_v0.2.12.md`
- `UI_SPEC_v0.3.2.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.10_Claude_res.md`
- `Main_updated_2026-04-10_v31.md`
- `STATUS_updated_2026-04-10_v29.md`

### 1.3 Room 5 当前采用口径
1. 当前 runtime truth 仍以 `UI_SPEC_v0.3.2.md` 的已吸收事实为准。
2. `review_group` 当前仍是 ReviewPage 用户可见 serving truth。
3. final fact / settlement truth 当前仍以后端为准。
4. 本轮若讨论 fuller-cutover execution，只能讨论 **更完整一拍的 execution-ready subset**。
5. 本轮不得把 fuller-cutover execution、`review_group` true exit、DB/API uplift absorbed、cleanup、final fact owner shift 写成已生效事实。

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持 P3.3.11 正式启动，但只支持进入“fuller-cutover execution preflight”；当前最稳的扩大方向仍然不是首页主 route，也不是 final fact owner，而是：继续扩大 ReviewPage 与首页 review 承接层的 source-neutral / retained-anchor-aware execution-ready subset。**

### 2.2 为什么现在可以前进一步
因为当前已经具备：
1. P3.3.9 的 first very narrow cutover 落地证据
2. P3.3.10 的 fuller-cutover / exit-gate / uplift judgment 结果
3. retained anchor / rollback / hold / observability 的一整套护栏
4. `review_group` exit-candidate 的前置条件清单
5. DB/API uplift-readiness seam families 的最小清单
6. UI 主文档已经吸收到了 `UI_SPEC_v0.3.2.md`

### 2.3 为什么这轮仍不能叫 full cutover completed
因为以下 current runtime truth 仍必须继续保持：
1. 首页默认入口仍是 `study_default`
2. active continuation 继续独立承接，不得 silent reroute
3. ReviewPage 用户可见 serving truth 继续围绕 cloud `review_group`
4. final fact / settlement truth 继续以后端为准
5. DB / API active baseline 仍是 `v0.2.1`
6. `review_group` 仍未进入 true exit
7. uplift-readiness 仍不是 uplift absorbed

---

## 3. Room 5 的总护栏：七层必须分开

### 3.1 current runtime truth
当前用户端继续只感知：
- 首页默认入口 = `study_default`
- ReviewPage current serving truth = cloud `review_group`
- active continuation 独立承接
- StudyPage preview 继续保持当前最小边界
- final fact / settlement 以后端为准

### 3.2 fuller-cutover execution-ready layer
本轮只允许讨论：
- 更完整一拍的 execution-ready subset
- continuity-adjacent serving-adapter family 的很窄扩大
- retained-anchor-aware helper / summary / CTA / empty-state prep
- rollback / hold / fallback 的更稳 UI 承接

### 3.3 exit-candidate layer
本轮只允许讨论：
- `review_group` 哪些内容可进入 exit-candidate
- 哪些内容仍必须继续保持 current visible owner + retained fallback anchor
- 哪些路径仍继续依赖 `review_group`

### 3.4 uplift-readiness layer
本轮只允许讨论：
- 哪些 seam 已 uplift-readiness-ready
- 哪些仍只能停留在 migration note / hold note / rollback floor
- 哪些仍绝不能进入 active baseline

### 3.5 fact-owner boundary layer
本轮继续写死：
- serving seam 扩大一小层 ≠ final fact owner 前进一步
- stronger ingest candidate 更强 ≠ fact owner 已切

### 3.6 rollback / hold / observability layer
本轮允许：
- retained-anchor-aware fallback wording
- hold / rollback / stop-condition 继续升级
- internal observability / QA evidence / execution note
- 用户可见层的中性短句 fallback

### 3.7 forbidden overclaim
以下内容本轮不得写成用户可见事实：
- 本地 serving 已启用
- ReviewPage 已切到本地队列
- owner shift 已完成
- `review_group` 已退场
- active DB / API baseline 已升级
- auto-routing 已开启
- planner-aware 首页已生效
- 本地 evidence 已直接成为 final fact
- 当前已完成 fuller cutover
- 当前已完成 uplift

---

## 4. Q1 — `fuller_cutover_execution_subset_v1`（Room 5 页面版）

## 4.1 Room 5 结论
> **这轮如果前进一步，最先受影响的页面仍然是 ReviewPage 与首页 review 承接层；但比 P3.3.10 judgment 更往前一拍，当前可以讨论“更完整一小层的 execution-ready subset”，而不是只停在 judgment。**

### 4.1.1 当前推荐的 execution-ready subset
Room 5 当前最稳的扩大方向，只建议扩大到以下 5 类：

1. **ReviewPage continuity-adjacent serving-adapter family**
   - 比 P3.3.9 的 non-continuation seam 更完整
   - 但仍不等于 ReviewPage full local-serving cutover
   - 继续不把用户可见主 truth 直接写成本地

2. **ReviewPage helper / summary / empty-state / completion 前置说明层**
   - 从 judgement-ready 提升到 execution-ready prep
   - 继续做 source-neutral 化
   - 但不写成“当前主队列已改为 local-serving”

3. **首页 review helper / summary / no-review-state 的 retained-anchor-aware prep**
   - 允许更完整一拍的改写准备
   - 但不切首页主 route
   - 不让用户感知“今天主入口已改成新主链路”

4. **rollback / hold / fallback 的中性 copy / state contract**
   - 允许从 note 层前进一步到 execution-ready copy matrix
   - 但继续禁止暴露内部切换状态

5. **与 stronger-ingest candidate 强绑定的前置承接层**
   - 只允许更清楚地承接“当前可继续 / 当前暂不可继续 / 当前暂无可继续内容”
   - 不允许把 stronger ingest 写成到账 / 完成 / streak 已续上

### 4.1.2 当前不推荐纳入 execution-ready subset 的部分
本轮不推荐先扩大到：
1. 首页默认 route
2. active continuation source switch
3. 用户可见 auto-routing
4. ReviewPage 用户可见 preview re-entry
5. final fact / settlement owner
6. `review_group` true exit
7. active DB/API baseline uplift absorbed
8. cleanup / old-path purge
9. 用户可见 mode switch 宣告

### 4.1.3 Room 5 一句话判断
> **P3.3.11 允许从 judgement 前进一步，但这“一小层 execution-ready subset”仍应该留在 ReviewPage 与首页 review 承接层，不应越过到首页主路由与最终事实。**

---

## 5. Q2 — `review_group_exit_candidate_v1`（Room 5 页面版）

## 5.1 Room 5 结论
> **本轮可以把 `review_group` 从“exit-candidate judgment”前推到“exit-candidate 并存姿态”，但仍不能写成 true exit。**

### 5.1.1 哪些内容现在允许进入 exit-candidate 层
Room 5 当前认为，以下内容可以进入 **exit-candidate** 层：

1. **ReviewPage helper / summary / empty-state 的 source-neutral rewrite 目标**
   - 即：它们不再只会说 cloud-group wording
   - 但当前仍不能让用户读出“你已经不再使用 group”

2. **首页 review helper / summary / no-review-state 的 group-only wording 去依赖**
   - 当前只允许作为 exit-candidate prep
   - 不等于首页已经脱离 `review_group`

3. **rollback / hold / fallback 文案对 `review_group` 的依赖清单**
   - 当前可以明确哪些地方还依赖 `review_group`
   - 也可以明确哪些地方未来可能缩窄
   - 但 rollback target 仍不能移除

4. **completion / settlement 前置说明层**
   - 当前可以进入 source-neutral / retained-anchor-aware prep
   - 但不得让用户以为 “group-based completion gating” 已被替换

### 5.1.2 哪些内容仍必须继续保持 current owner + retained fallback anchor
以下内容当前仍必须继续保持：
1. ReviewPage 用户可见主队列来源
2. active continuation identity
3. current completion gating 的解释通路
4. settlement trigger 的用户可见解释通路
5. rollback target = `cloud_review_group_current_runtime_path`
6. compatibility anchor 与 QA baseline reference

### 5.1.3 哪些路径仍必须依赖 `review_group`
本轮 Room 5 明确：以下路径仍继续必须依赖 `review_group`：
1. ReviewPage 当前主承接路径
2. active continuation 的当前承接路径
3. current completion / settlement 用户可见解释层
4. rollback path
5. no-major-change fallback 解释路径

### 5.1.4 当前继续禁止的 exit overclaim
- `review_group` 已退场
- 当前已不再使用 `review_group`
- retained anchor 已不再需要
- 旧方案即将不可用
- 现在完全按新主链路运行

---

## 6. Q3 — `db_api_uplift_readiness_v1`（Room 5 页面版）

## 6.1 Room 5 结论
> **本轮可以正式进入 uplift-readiness，但 UI 只承接“哪些 seam 已经 readiness-ready”，不承接 active baseline change。**

### 6.1.1 哪些 seam 现在已 uplift-readiness-ready
从 UI 视角看，当前最值得进入 uplift-readiness 的 seam families 是：

1. **ReviewPage source seam**
   - current visible source
   - retained fallback anchor
   - execution-ready candidate source
   - rollback target

2. **Continuation / helper / summary seam**
   - current continuation
   - retained-anchor-aware continuation
   - source-neutral continuation
   - fallback 后仍不误导的 continuation

3. **Completion / settlement pre-display seam**
   - evidence only
   - stronger candidate
   - backend-confirmed final fact
   - final settlement result

4. **Migration posture seam**
   - current runtime owner
   - retained fallback anchor
   - compatibility-only
   - deprecated candidate
   - exit-candidate
   - uplift-readiness pending

### 6.1.2 哪些仍只能停留在 migration note / hold note / rollback floor
以下当前仍更适合停留在 note / floor 层：
1. 用户可见 local source naming
2. `review_group` exit wording
3. route 选择结果字段的用户展示
4. “已升级到新基线”的任何 copy
5. Settings / 我的页里与 uplift absorbed 有关的表述

### 6.1.3 哪些仍绝不能进入 active baseline
1. active DB / API baseline 已升级
2. 新基线已吸收进运行态
3. 现在已按新契约运行
4. uplift 已完成
5. DB schema rewrite 已生效
6. API core semantics rewrite 已生效

---

## 7. Q4 — `cutover_vs_fact_owner_boundary_v3`（Room 5 页面版）

## 7.1 Room 5 结论
> **fuller-cutover execution 扩大一小层后，stronger ingest candidate 最多只能更清楚地进入 execution-ready 承接层，仍绝不能跟着 serving seam 一起变成 final fact owner。**

### 7.1.1 stronger ingest candidate 最大能走到哪
Room 5 当前只接受走到：
1. accept / reject / duplicate 的更清楚前置说明
2. progress-candidate / completion-candidate 的更清楚命名
3. hold-reason / fallback-reason 的更明确承接
4. source-neutral / retained-anchor-aware 的说明层
5. execution-ready copy matrix

### 7.1.2 哪些结果仍绝不能跟着 serving seam 一起切
以下仍继续必须以后端为准：
1. effective review fact
2. daily goal progress / completion
3. reward settlement / ledger arrival
4. `check_in / learning_day / streak`
5. completion /到账类主反馈

### 7.1.3 哪些表达必须继续禁止
- 已记为有效复习
- 今日目标已推进 / 已完成
- 奖励已到账
- streak 已续上
- 学习事实已正式更新
- 新主链路已生效
- 现在你刚刚的结果已写入最终事实

---

## 8. Q5 — `retained_anchor_narrowing_guardrail_v1`（Room 5 页面版）

## 8.1 Room 5 结论
> **retained anchor 本轮可以 very narrow 缩窄“依赖清单”，但不能缩窄“身份与回退职责”。**

### 8.1.1 哪些范围允许缩窄
当前只允许 very narrow 缩窄的是：
1. group-only wording 的依赖范围
2. source-neutral helper / summary / empty-state 对 group-only wording 的依赖
3. retained-anchor-aware fallback copy 的覆盖范围优化
4. QA / docs 中对哪些 UI 资产已不再必须 group-only 的判断

### 8.1.2 哪些仍不得缩窄
以下当前仍不得缩窄：
1. current visible owner 身份
2. retained fallback anchor 身份
3. rollback target = `cloud_review_group_current_runtime_path`
4. active continuation 当前承接路径
5. current completion gating / settlement trigger 的解释通路
6. compatibility anchor / QA baseline reference

### 8.1.3 rollback target 是否继续固定
> **是。当前继续固定为 `cloud_review_group_current_runtime_path`。**

### 8.1.4 哪些 stop-condition 必须继续保持
1. 用户可见 owner-shift / cutover overclaim
2. 用户可见 `review_group` true-exit overclaim
3. active continuation 被静默改写
4. final fact / settlement truth 被误写成新路径结果
5. rollback 后页面主路径解释不通
6. uplift-readiness 被误写成 uplift absorbed

---

## 9. Q6 — `phase5_writeback_order_v1`（Room 5 页面版）

## 9.1 Room 5 结论
> **这轮必须把 execution-ready candidate / exit-candidate / uplift-readiness 的回写顺序写硬，否则最容易出现“治理层还在 preflight，页面先写成已切换”的漂移。**

### 9.1.1 fuller-cutover execution / exit-candidate / uplift-readiness 的回写顺序
Room 5 推荐：

#### Layer A — execution-preflight absorb
先吸收：
- fuller-cutover execution judgment
- exit-candidate judgment
- uplift-readiness judgment
- rollback / hold / proceed / escalate 条件

#### Layer B — execution-ready candidate absorb
再吸收：
- ReviewPage continuity-adjacent serving-adapter family
- source-neutral helper / summary / empty-state prep
- retained-anchor-aware fallback copy matrix
- uplift-ready seam families 的 UI 承接判断

#### Layer C — R1→R4 execution handoff absorb
只有当 Room 1 明确下发执行单后，才吸收：
- very narrow fuller-cutover execution subset
- exit-candidate execution-prep subset
- uplift-readiness execution-prep subset

#### Layer D — runtime truth absorb
只有 true closeout 后，才允许把：
- fuller cutover 已生效
- `review_group` 已进入 true exit
- active DB/API baseline 已 uplift
写进主 UI 文档 runtime truth 层

### 9.1.2 哪些只能写成 execution-ready candidate
1. continuity-adjacent serving-adapter family 的 UI prep
2. retained-anchor-aware helper / summary / CTA / empty-state prep
3. uplift-ready seam families 的 UI prep
4. rollback / hold / fallback copy matrix

### 9.1.3 哪些仍不能升格为 runtime truth
1. `review_group` 已退场
2. fuller cutover 已完成
3. active DB/API baseline 已 uplift
4. 现在用户已使用新主链路
5. final fact owner 已切换

---

## 10. 页面承接建议（Room 5 交付项）

### 10.1 如果 fuller-cutover execution 前进一步，哪些页面最先受影响
1. **ReviewPage**
   - continuity-adjacent helper / summary / empty-state / completion 前置说明
2. **首页 review helper / summary / no-review-state**
   - retained-anchor-aware rewrite 会先冲击这里
3. **Settings / 我的页 migration 说明层**
   - 仅在需要补 uplift-readiness / hold note 时触碰
4. **StudyPage explanation 边界**
   - 当前优先级仍低，只需继续守住不扩张

### 10.2 哪些 UI 状态仍必须保持 current runtime truth
1. 首页默认入口
2. active continuation 当前承接方式
3. ReviewPage 用户可见主队列来源
4. final fact / settlement 主反馈
5. preview 当前可见范围

### 10.3 exit-candidate UI guidance
1. `review_group` 当前继续保持 current visible owner
2. 同时继续保持 retained fallback anchor
3. 当前只允许出现 exit-candidate judgment，不允许出现 retired / removed / switched wording
4. 任何 helper / summary / CTA / empty-state 都不得提前出现“旧方案将退场”的暗示

### 10.4 uplift-readiness UI guidance
1. 只讨论 seam readiness，不讨论 user-visible baseline change
2. 只讨论 source-neutral / retained-anchor-aware contract 是否够稳
3. 不把 uplift-readiness 写成 uplift absorbed
4. 设置页 / 我的页不得出现“已升级到新主链路”提示

### 10.5 最小 UI execution-ready subset 层
Room 5 推荐本轮最多只进入：
1. ReviewPage continuity-adjacent serving-adapter family 的 execution-ready prep
2. ReviewPage helper / summary / empty-state / completion 前置说明层的 fuller source-neutral prep
3. 首页 review helper / no-review-state / summary 的 retained-anchor-aware prep
4. rollback / hold / fallback 的中性 copy matrix
5. uplift-ready seam 的 UI 承接判断

---

## 11. user-visible forbidden claims（P3.3.11 补强）

以下表达在 P3.3.11 当前轮继续列为用户端禁区：

### fuller cutover / local-serving 禁区
1. 本地 serving 已启用
2. ReviewPage 已切到本地队列
3. 当前复习队列来自本地 due
4. owner shift 已完成
5. 当前 serving truth 已切换
6. 已升级到新 serving 方案

### `review_group` true-exit 禁区
7. `review_group` 已退场
8. 旧方案即将不可用
9. 当前已不再使用 `review_group`
10. retained anchor 已不再需要
11. 已完成旧方案迁移

### uplift 禁区
12. active DB / API baseline 已升级
13. 新基线已吸收进运行态
14. 现在已按新契约运行
15. uplift 已完成

### routing / planner 禁区
16. 系统已自动为你选择更优入口
17. auto-routing 已开启
18. mixed session 已启用
19. planner-aware 首页已生效

### fact / settlement 禁区
20. 本地已直接记为有效复习
21. 今日进度已因本地方案更新
22. 奖励已因新主链路到账
23. streak 已因 fuller-cutover execution 续上

### migration / hold / rollback 禁区
24. 已回退到旧方案
25. 新方案暂不可用
26. 已完成兼容切换
27. 现在你正在使用新的复习规划

---

## 12. Room 5 对 Room 1 的建议

### 12.1 建议 Room 1 可吸收的最小 UI execution-preflight 合同层
Room 1 若要 pin，本轮建议只吸收以下 6 条：

1. **fuller-cutover execution 下一拍最先受影响的，仍应是 ReviewPage 与首页 review 承接层，而不是首页主 route 或 final fact owner**
2. **`review_group` 当前仍只能进入 exit-candidate，不进入 true exit；它继续保持 current visible owner + retained fallback anchor**
3. **DB/API uplift 当前只应进入 uplift-readiness，不应进入 user-visible baseline change**
4. **current runtime truth 仍必须大面积保持不变**
5. **rollback / hold / fallback 的中性 copy matrix 必须先于更宽一层 execution-ready subset 写硬**
6. **任何会把 fuller-cutover execution / true exit / uplift absorbed 写成已生效事实的表述继续禁止**

### 12.2 当前仍不建议吸收成 runtime truth 的内容
1. full cutover completed
2. `review_group` true exit
3. active DB/API baseline uplift absorbed
4. 首页默认 route 切换
5. active continuation source switch
6. auto-routing runtime
7. final fact owner shift
8. 用户可见模式切换宣告

---

## 13. Room 5 一句话结论

> **P3.3.11 在 Room 5 视角，可以进入 Fuller-Cutover Execution / `review_group` Exit-Candidate / DB-API Uplift-Readiness Preflight，但当前最稳的推进仍是：继续扩大 ReviewPage 与首页 review 承接层的 source-neutral / retained-anchor-aware execution-ready subset，继续把 `review_group` 保留在 current visible owner + retained fallback anchor 的双姿态里，继续把 uplift 只写成 readiness，不写成 absorbed，并继续禁止一切会让用户误以为 fuller cutover、`review_group` true exit 或 baseline uplift 已经生效的表达。**
