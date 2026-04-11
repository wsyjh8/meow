# UI_SPEC_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.12 — Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment Round`
- **Direct upstream input:** `R1_P3_3_12_ScopePin_and_Handoff_Pack_v0.1.md`
- **Related inputs:** `BR-OPP-001_v0.2.13.md` + `UI_SPEC_v0.3.3.md` + `背单词喵喵app_DB设计草案_v0.2.1.md` + `背单词喵喵app_API设计草案_v0.2.1.md` + `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` + `P3.3.11_Claude_res.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.12 当前轮需要回答的 fuller-cutover / true-exit-gate / uplift-absorb judgment 问题，翻成可被 Room 1 判断是否 pin 的最小 UI judgment-preflight contract。**

本稿不是：
- 新 UI 主文档
- 新 PRD / BR / DB / API 主文档
- Room 4 fuller-cutover 执行单
- full cutover 完成宣告
- `review_group` true exit 生效公告
- active DB / API baseline uplift absorbed 生效稿

一句话：

> **P3.3.12 在 Room 5 视角，不是“已经切完”的轮，而是“在 P3.3.11 execution-ready subset 的基础上，判断哪些 widened subset 已够资格进入更完整一拍 cutover、`review_group` 何时才配得上进入 true-exit gate、以及 DB/API 何时才配得上进入 uplift-absorb judgment”的轮。**

---

## 1. 输入依据

### 1.1 Main-thread handoff basis
- `R1_P3_3_12_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.2 Current runtime / review basis
- `BR-OPP-001_v0.2.13.md`
- `UI_SPEC_v0.3.3.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.11_Claude_res.md`
- `Main_updated_2026-04-10_v32.md`
- `STATUS_updated_2026-04-10_v30.md`

### 1.3 Room 5 当前采用口径
1. 当前 runtime truth 仍以 `UI_SPEC_v0.3.3.md` 的已吸收事实为准。
2. `review_group` 当前仍是 ReviewPage 用户可见 serving truth。
3. final fact / settlement truth 当前仍以后端为准。
4. 本轮若讨论 fuller-cutover / true-exit / uplift-absorb，只能讨论 **judgment / gate / candidate**。
5. 本轮不得把 fuller cutover、`review_group` true exit、DB/API uplift absorbed、cleanup、final fact owner shift 写成已生效事实。

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持 P3.3.12 正式启动，但只支持进入“fuller-cutover / true-exit-gate / uplift-absorb judgment preflight”；当前最稳的判断方向仍然不是首页主 route，也不是 final fact owner，而是：继续判断 ReviewPage 与首页 review 承接层哪些 widened subset 已经足够接近 absorber-level candidate，以及 `review_group` 哪些 still-dependent paths 仍阻止 true-exit gate。**

### 2.2 为什么现在可以前进一步
因为当前已经具备：
1. P3.3.9 的 first very narrow cutover 落地证据
2. P3.3.10 的 fuller-cutover judgment / exit-gate / uplift judgment 结果
3. P3.3.11 的 execution-ready subset / exit-candidate / uplift-readiness 结果
4. retained anchor / rollback / hold / observability 的成套护栏
5. BR / UI 主文档已经吸收到 `v0.2.13 / v0.3.3`
6. 下一层真正难点已经变成：哪些条件还没齐，为什么还不能写成 true exit / uplift absorbed / fuller cutover completed

### 2.3 为什么这轮仍不能叫已生效
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

### 3.2 fuller-cutover judgment layer
本轮只允许讨论：
- 哪些 widened subset 已足够进入更完整一拍 fuller-cutover judgment
- 这些 subset 若继续扩大，页面 blast radius / rollback complexity 如何变化
- 哪些 UI 承接层会先扛不住

### 3.3 true-exit-gate layer
本轮只允许讨论：
- `review_group` 距离 true exit 还缺哪些 contract / runtime / test / doc / fallback 条件
- 哪些 still-dependent paths 当前仍阻止它进入 true-exit gate
- 哪些 retained-anchor 依赖未来才允许继续缩窄

### 3.4 uplift-absorb judgment layer
本轮只允许讨论：
- 哪些 DB/API seam 已经从 uplift-readiness 升到 uplift-absorb judgment-ready
- 哪些仍只能停留在 marker / migration / rollback / hold 层
- 哪些仍绝不能进入 active baseline

### 3.5 fact-owner boundary layer
本轮继续写死：
- serving seam 再前进一步 ≠ final fact owner 前进一步
- stronger ingest candidate 更强 ≠ fact owner 已切
- fuller-cutover judgment 通过 ≠ reward / streak / daily goal / settlement 已改由新链路裁定

### 3.6 rollback / hold / observability layer
本轮允许：
- retained-anchor-aware fallback wording
- hold / rollback / stop-condition 继续升级
- internal observability / QA evidence / judgment note
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

## 4. Q1 — `fuller_cutover_absorb_candidate_v1`（Room 5 页面版）

## 4.1 Room 5 结论
> **P3.3.12 当前最值得推进的，不是直接扩大执行，而是判断哪些 widened subset 已接近 absorb-candidate 的门槛。Room 5 认为，最接近这个门槛的仍是 ReviewPage 与首页 review 承接层，不是首页主 route。**

### 4.1.1 当前最接近 absorb-candidate 的 widened subset
Room 5 当前认为，最接近下一层 fuller-cutover absorb-candidate 的，仍只限于：

1. **ReviewPage continuity-adjacent serving-adapter family**
   - 当前已经具备从 judgment → execution-ready 的前提
   - 下一层最该判断的是：这组 seam 是否已经足够稳定、足够 source-neutral、足够 retained-anchor-aware
   - 但仍不能据此写成“ReviewPage 主 truth 已全面切走”

2. **ReviewPage helper / summary / empty-state / completion 前置说明层**
   - 当前最值得判断的是：这些层是否已足够脱离 group-only wording
   - 但仍不能写成 completion / settlement owner 已切

3. **首页 review helper / summary / no-review-state**
   - 当前最值得判断的是：这些承接层是否已足够从 group-only wording 过渡到 retained-anchor-aware / source-neutral wording
   - 但仍不得推进到首页默认 route 或 planner-aware runtime

4. **rollback / hold / fallback 的中性 copy matrix**
   - 当前最值得判断的是：是否已足够覆盖 widened subset 的最小 blast radius
   - 但仍不得让用户感知“模式切换失败 / 已回退旧方案”

### 4.1.2 当前仍不配进入 absorb-candidate 的部分
本轮不建议写成 absorb-candidate 的包括：
1. 首页默认 route
2. active continuation source switch
3. user-visible auto-routing
4. `review_group` true exit
5. final fact / settlement owner
6. active DB/API baseline uplift absorbed
7. cleanup / old-path purge

### 4.1.3 Room 5 的判断句
> **P3.3.12 最该判断的，不是“切更多”，而是“ReviewPage 与首页 review 承接层哪些 widened subset 已经稳到值得进入下一层 absorb-candidate 判断”。**

---

## 5. Q2 — `review_group_true_exit_gate_v1`（Room 5 页面版）

## 5.1 Room 5 结论
> **`review_group` 当前仍不具备进入 true-exit gate 的页面条件；P3.3.12 最多只能把“还缺哪些条件”与“哪些 still-dependent paths 仍然挡路”写硬。**

### 5.1.1 当前还缺的最关键页面条件
Room 5 当前判断，`review_group` 距离 true-exit gate 至少还缺：

1. **ReviewPage helper / summary / empty-state / completion 前置说明层更稳定的 source-neutral 化**
   - 目前仍不能证明这些层已经完全不再依赖 group-only wording 来解释 current truth 与 fallback

2. **首页 review helper / summary / no-review-state 脱离 group-only wording 的稳定性**
   - 目前还不足以证明首页在 `review_group` future-narrowable 之后不会出现解释断层

3. **rollback / fallback 后仍完全自洽的用户侧中性 copy**
   - 只要 rollback target 仍是 `cloud_review_group_current_runtime_path`
   - 用户端就仍不应看到任何“旧方案将退场”的暗示

4. **completion / settlement 前置说明不再依赖 group-only wording**
   - 目前这层如果没完全 source-neutral，就仍会把 true-exit gate 与 final fact owner 误混

### 5.1.2 当前仍阻止 true-exit gate 的 still-dependent paths
Room 5 当前明确，以下路径仍阻止 `review_group` 进入 true-exit gate：
1. ReviewPage 用户可见主承接路径
2. active continuation identity
3. current completion gating 的解释通路
4. settlement trigger 的用户可见解释通路
5. rollback target
6. no-major-change fallback 解释路径
7. compatibility anchor / QA baseline reference

### 5.1.3 当前仍不得出现的 true-exit overclaim
- `review_group` 已退场
- 当前已不再使用 `review_group`
- retained anchor 已不再需要
- 旧方案即将不可用
- 现在完全按新主链路运行

### 5.1.4 Room 5 的 gate 规则句
> **只要用户端仍需要依赖 `review_group` current wording 来解释 ReviewPage queue / continuation / completion / rollback，Room 5 就不支持它进入 true-exit gate。**

---

## 6. Q3 — `db_api_uplift_absorb_judgment_v1`（Room 5 页面版）

## 6.1 Room 5 结论
> **Room 5 支持本轮正式进入 DB/API uplift-absorb judgment，但 UI 只承接“哪些 seam 现在看起来够资格被判断”，不承接 absorbed runtime-baseline change。**

### 6.1.1 从 UI 视角，哪些 seam 现在最接近 uplift-absorb judgment-ready
Room 5 当前最关心的，仍是以下 seam families：

1. **ReviewPage source seam**
   - 能否稳定表达：
     - current visible source
     - retained fallback anchor
     - widened candidate source
     - rollback target

2. **Continuation / helper / summary seam**
   - 能否稳定表达：
     - current continuation
     - retained-anchor-aware continuation
     - source-neutral continuation
     - fallback 后仍不误导的 continuation

3. **Completion / settlement pre-display seam**
   - 能否稳定表达：
     - evidence only
     - stronger candidate
     - backend-confirmed final fact
     - final settlement result

4. **Migration posture seam**
   - 能否稳定表达：
     - current runtime owner
     - retained fallback anchor
     - compatibility-only
     - deprecated candidate
     - exit-candidate
     - uplift-absorb judgment pending

### 6.1.2 哪些仍只能停留在 marker / migration / rollback / hold 层
以下当前仍只适合停留在 note / floor 层：
1. 用户可见 local source naming
2. `review_group` true-exit wording
3. route 选择结果字段的用户展示
4. “已升级到新基线”的任何 copy
5. 设置页 / 我的页里与 uplift absorbed 有关的表述

### 6.1.3 哪些仍绝不能进入 active baseline
1. active DB / API baseline 已升级
2. 新基线已吸收进运行态
3. 现在已按新契约运行
4. uplift 已完成
5. DB schema rewrite 已生效
6. API core semantics rewrite 已生效

### 6.1.4 Room 5 的一句话判断
> **UI 现在可以帮助判断“哪些 seam 已够资格进入 uplift-absorb judgment”，但还不能帮助宣布“uplift 已吸收进 active baseline”。**

---

## 7. Q4 — `cutover_vs_fact_owner_boundary_v4`（Room 5 页面版）

## 7.1 Room 5 结论
> **P3.3.12 这一轮最危险的，仍然不是页面长得不一样，而是让用户误以为 widened subset 再前进一步，就代表 final fact owner 也已经改了。**

### 7.1.1 当前仍必须以后端为准的最终事实
1. effective review fact
2. daily goal progress / completion
3. reward settlement / ledger arrival
4. `check_in / learning_day / streak`
5. completion /到账类主反馈

### 7.1.2 当前绝不能跟着 widened subset 一起切的页面结果
1. 已记为有效复习
2. 今日目标已推进 / 已完成
3. 奖励已到账
4. streak 已续上
5. 学习事实已正式更新
6. 新主链路已生效
7. 现在你刚刚的结果已写入最终事实

### 7.1.3 Room 5 的硬限制
即使 stronger ingest candidate 比 P3.3.11 再前进一步，当前页面也只能保持：
- 当前可继续复习
- 当前暂无可继续内容
- 当前暂不可继续，请稍后再试

仍然不能写：
- 你刚刚的复习已正式记入最终结果
- 新队列已写回最终学习事实
- 奖励已因新主链路到账

---

## 8. Q5 — `exit_candidate_to_true_exit_transition_v1`（Room 5 页面版）

## 8.1 Room 5 结论
> **P3.3.12 最值得推进的，不是宣布 `review_group` 可以 true exit，而是把“从 exit-candidate 走到 true-exit gate 还缺什么”写硬。**

### 8.1.1 true-exit gate 的最小页面条件
Room 5 当前认为，只有当以下 4 点都成立时，`review_group` 才可能进入 true-exit gate：

1. ReviewPage 的 source-neutral helper / summary / empty-state 已可单独成立
2. completion / settlement 前置解释不再依赖 group-only wording
3. 首页 review helper / summary 已可不靠 group-only wording 支撑
4. rollback / hold 后的中性 fallback copy 已齐全，且不再依赖“回到 group wording 才解释得通”

### 8.1.2 retained anchor 哪些范围未来才允许继续缩窄
当前只可能 future-narrowable 的仍然是：
1. group-only wording 的依赖范围
2. source-neutral helper / summary / empty-state 对 group-only wording 的依赖
3. retained-anchor-aware fallback copy 的覆盖范围
4. QA / docs 中对哪些 UI 资产已不再必须 group-only 的判断

### 8.1.3 当前仍不得变动的部分
以下当前仍不得变动：
1. current visible owner 身份
2. retained fallback anchor 身份
3. rollback target = `cloud_review_group_current_runtime_path`
4. active continuation 当前承接路径
5. current completion gating / settlement trigger 的解释通路
6. compatibility anchor / QA baseline reference

### 8.1.4 Room 5 的 transition 规则句
> **只要 rollback target 仍固定在 `cloud_review_group_current_runtime_path`，且用户侧 explanation 仍需依赖 group-only wording 兜底，Room 5 就不支持 `review_group` 进入 true-exit gate。**

---

## 9. Q6 — `phase6_writeback_order_v1`（Room 5 页面版）

## 9.1 Room 5 结论
> **这轮必须把 fuller-cutover judgment / true-exit-gate / uplift-absorb judgment 的回写顺序写硬，否则最容易出现“治理层还在 judgment，页面先写成已切换”的漂移。**

### 9.1.1 Room 5 推荐的 phase6 回写顺序
#### Layer A — judgment absorb
先吸收：
- fuller-cutover judgment
- true-exit-gate judgment
- uplift-absorb judgment
- rollback / hold / proceed / escalate 条件

#### Layer B — execution-ready candidate absorb
再吸收：
- widened subset 的 UI candidate
- exit-candidate 前置条件与 still-dependent paths
- uplift-readiness / uplift-absorb judgment-ready seam families
- retained-anchor-aware fallback copy matrix

#### Layer C — execution handoff absorb
只有当 Room 1 明确 pin 更完整一拍 `R1 → R4` handoff 后，才吸收：
- fuller-cutover execution subset
- true-exit-gate execution-prep subset
- uplift-absorb execution-prep subset

#### Layer D — runtime truth absorb
只有 true closeout 后，才允许把：
- fuller cutover 已生效
- `review_group` 已进入 true exit
- active DB/API baseline 已 uplift absorbed
写进主 UI 文档 runtime truth 层

### 9.1.2 哪些只能写成 judgment
1. 哪些 widened subset 值得继续扩大
2. `review_group` 是否已具备 true-exit gate 最低资格
3. 哪些 seam 已够资格进入 uplift-absorb judgment
4. retained anchor 哪些范围未来才允许继续缩窄

### 9.1.3 哪些仍不能升格为 runtime truth
1. `review_group` 已退场
2. fuller cutover 已完成
3. active DB/API baseline 已 uplift
4. 现在用户已使用新主链路
5. final fact owner 已切换

---

## 10. 页面承接建议（Room 5 交付项）

### 10.1 如果 fuller-cutover judgment 再前进一步，哪些页面最先受影响
1. **ReviewPage**
   - helper / summary / empty-state / completion 前置说明
2. **首页 review helper / summary / no-review-state**
   - retained-anchor-aware rewrite 会先冲击这里
3. **Settings / 我的页 migration 说明层**
   - 仅在需要补 uplift-absorb judgment / hold note 时触碰
4. **StudyPage explanation 边界**
   - 当前优先级仍低，只需继续守住不扩张

### 10.2 哪些 UI 状态仍必须保持 current runtime truth
1. 首页默认入口
2. active continuation 当前承接方式
3. ReviewPage 用户可见主队列来源
4. final fact / settlement 主反馈
5. preview 当前可见范围

### 10.3 true-exit-gate UI guidance
1. `review_group` 当前继续保持 current visible owner
2. 同时继续保持 retained fallback anchor
3. 当前只允许出现 true-exit-gate judgment，不允许出现 retired / removed / switched wording
4. 任何 helper / summary / CTA / empty-state 都不得提前出现“旧方案将退场”的暗示

### 10.4 uplift-absorb judgment UI guidance
1. 只讨论 seam readiness / judgment，不讨论 user-visible baseline change
2. 只讨论 source-neutral / retained-anchor-aware contract 是否够稳
3. 不把 uplift-absorb judgment 写成 uplift absorbed
4. 设置页 / 我的页不得出现“已升级到新主链路”提示

### 10.5 最小 UI judgment subset 层
Room 5 推荐本轮最多只进入：
1. ReviewPage helper / summary / empty-state / completion 前置说明 的 fuller source-neutral judgment
2. 首页 review helper / no-review-state 的 retained-anchor-aware judgment
3. rollback / hold / fallback 的中性 copy matrix
4. uplift-absorb judgment-ready seam 的 UI 承接判断

---

## 11. user-visible forbidden claims（P3.3.12 补强）

以下表达在 P3.3.12 当前轮继续列为用户端禁区：

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
23. streak 已因 fuller-cutover judgment 续上

### migration / hold / rollback 禁区
24. 已回退到旧方案
25. 新方案暂不可用
26. 已完成兼容切换
27. 现在你正在使用新的复习规划

---

## 12. Room 5 对 Room 1 的建议

### 12.1 建议 Room 1 可吸收的最小 UI judgment-preflight 合同层
Room 1 若要 pin，本轮建议只吸收以下 6 条：

1. **fuller-cutover judgment 下一拍最先受影响的，仍应是 ReviewPage 与首页 review 承接层，而不是首页主 route 或 final fact owner**
2. **`review_group` 当前还只能进入 true-exit-gate judgment，不进入 true exit；它继续保持 current visible owner + retained fallback anchor**
3. **DB/API uplift 当前只应进入 uplift-absorb judgment，不应进入 user-visible baseline change**
4. **current runtime truth 仍必须大面积保持不变**
5. **rollback / hold / fallback 的中性 copy matrix 必须先于更深一层 cutover / true-exit / uplift judgment 写硬**
6. **任何会把 fuller cutover / true exit / uplift absorbed 写成已生效事实的表述继续禁止**

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

> **P3.3.12 在 Room 5 视角，可以进入 Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment Preflight，但当前最稳的推进仍是：继续把判断重心留在 ReviewPage 与首页 review 承接层，继续把 `review_group` 保留在 current visible owner + retained fallback anchor 的双姿态里，继续把 uplift 只写成 absorb-judgment 而不是 absorbed，并继续禁止一切会让用户误以为 fuller cutover、`review_group` true exit 或 baseline uplift 已经生效的表达。**
