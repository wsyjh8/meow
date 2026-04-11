# UI_SPEC_P3_3_10_FullerCutover_ExitGate_and_DBUplift_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.10 — Fuller Cutover / review_group Exit-Gate / DB-API Uplift Judgment Round`
- **Direct upstream input:** `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`
- **Related inputs:** `BR-OPP-001_v0.2.11.md` + `UI_SPEC_v0.3.1.md` + `背单词喵喵app_DB设计草案_v0.2.1.md` + `背单词喵喵app_API设计草案_v0.2.1.md` + `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` + `P3.3.9_Claude_res.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.10 当前轮需要回答的 fuller-cutover / exit-gate / uplift-judgment 问题，翻成可被 Room 1 判断是否 pin 的最小 UI judgment contract。**

本稿不是：
- 新 UI 主文档
- 新 PRD / BR / DB / API 主文档
- Room 4 fuller-cutover 执行单
- full cutover 完成宣告
- `review_group` 真退场公告
- active DB / API baseline uplift 生效稿

一句话：

> **P3.3.10 在 Room 5 视角，不是“已经切完”的轮，而是“判断下一拍能扩大切口到哪里、`review_group` 何时才有资格进入真实 exit judgment、以及 DB/API uplift 什么时候才配得上被写进下一层执行判断”的轮。**

---

## 1. 输入依据

### 1.1 Main-thread handoff basis
- `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.2 Current runtime / review basis
- `BR-OPP-001_v0.2.11.md`
- `UI_SPEC_v0.3.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.9_Claude_res.md`
- `Main_updated_2026-04-10_v30.md`
- `STATUS_updated_2026-04-10_v28.md`

### 1.3 Room 5 当前采用口径
1. 当前 runtime truth 仍以 `UI_SPEC_v0.3.1.md` 的已吸收事实为准。
2. `review_group` 当前仍是 ReviewPage 用户可见 serving truth。
3. final fact / settlement truth 当前仍以后端为准。
4. 本轮若讨论 fuller cutover，只能讨论 **next-cutover subset / exit-gate / uplift judgment**。
5. 本轮不得把 fuller cutover judgment、`review_group` exit judgment、DB/API uplift judgment 写成已生效事实。

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持 P3.3.10 正式启动，但只支持进入“fuller cutover judgment preflight”，且当前最稳的推进不是扩大到首页 route，也不是碰 final fact owner，而是：在 ReviewPage 相关承接层继续扩大 source-neutral / anchor-aware UI contract，并把 `review_group` retained-anchor → exit-candidate 的条件写硬。**

### 2.2 为什么现在可以前进一步
因为当前已经具备：
1. first-cutover 的 runtime 落地证据
2. retained anchor / rollback / hold / observability 证据
3. `review_group` exit-gate 的更清楚前置条件
4. BR / UI 已把 P3.3.9 事实吸收到主文档候选
5. 下一层真正难点已经转向：
   - 下一拍 cutover 要不要扩大
   - `review_group` 何时才可进入真实 exit judgment
   - DB / API seam 何时才配得上 uplift judgment

### 2.3 为什么这轮仍不能叫 full cutover
因为以下 current runtime truth 仍必须继续保持：
1. 首页默认入口仍是 `study_default`
2. active continuation 继续独立承接，不得 silent reroute
3. ReviewPage 用户可见 serving truth 继续围绕 cloud `review_group`
4. final fact / settlement truth 继续以后端为准
5. DB / API active baseline 仍是 `v0.2.1`
6. `review_group` 仍未进入真实退场

---

## 3. Room 5 的总护栏：六层必须分开

### 3.1 current runtime truth
当前用户端继续只感知：
- 首页默认入口 = `study_default`
- ReviewPage current serving truth = cloud `review_group`
- active continuation 独立承接
- StudyPage preview 继续保持当前最小边界
- final fact / settlement 以后端为准

### 3.2 fuller-cutover judgment layer
本轮只允许讨论：
- next-cutover subset
- retained anchor 到 exit candidate 的条件
- DB/API uplift judgment readiness
- rollback / hold / migration / fallback 下一层怎么升级

### 3.3 exit-gate layer
本轮只允许讨论：
- `review_group` 什么时候具备真实 exit judgment 资格
- rollback target 何时可以缩窄
- 哪些 helper / summary / CTA / empty-state 先要脱离 group-only wording

### 3.4 uplift-judgment layer
本轮只允许讨论：
- 哪些 seam 现在只是 candidate
- 哪些 seam 已 uplift-judgment-ready
- 哪些仍必须留在 `v0.2.1` active baseline 外

### 3.5 migration / hold / rollback layer
本轮允许：
- source-neutral copy / state contract 继续前推
- retained-anchor-aware fallback wording
- hold note / rollback note / proceed note / uplift-candidate note
- internal observability / QA evidence

### 3.6 forbidden overclaim
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

---

## 4. Q1 — `fuller_cutover_subset_v1`（Room 5 页面版）

## 4.1 Room 5 结论
> **若 fuller cutover 前进一步，最先扩大的不应是首页 route，而应是：ReviewPage 中与 non-continuation serving seam 强绑定、但还未 fully source-neutral 的那一圈页面承接层。**

### 4.1.1 Room 5 推荐的 fuller-cutover subset
当前最稳的下一拍只建议扩大到以下 4 类：

1. **ReviewPage source-neutral state contract 的下一层**
   - 从“极小 serving seam”前进一步
   - 继续不把用户可见主 truth 直接写成本地

2. **ReviewPage helper / summary / empty-state / completion 前置说明层**
   - 先把仍然强绑定 `review_group` current-only wording 的部分继续中和
   - 但不把它写成“当前主队列已改为 local-serving”

3. **首页 review helper / summary block / no-review-state 的 retained-anchor-aware rewrite**
   - 不是切 route
   - 而是让首页的 review 提示层能承受下一拍 fuller cutover 判断

4. **fallback / rollback / hold 对应的中性说明层**
   - 让页面在下一拍即使发生 hold / rollback，也仍然自洽
   - 用户不感知“模式切换失败”

### 4.1.2 Room 5 当前不推荐纳入 fuller subset 的部分
本轮不建议先扩大到：
1. 首页默认 route
2. active continuation route 切换
3. 用户可见 auto-routing
4. ReviewPage 用户可见 preview re-entry
5. final fact / settlement owner
6. `review_group` 真退场文案
7. 设置页直接宣告 uplift / 新基线

### 4.1.3 一句话判断
> **Room 5 认为 fuller cutover 下一拍应先扩大“ReviewPage / 首页 review 承接层的 source-neutral 与 retained-anchor-aware 表达”，而不是先扩大“用户主路径与最终事实”。**

---

## 5. Q2 — `review_group_exit_gate_v2`（Room 5 页面版）

## 5.1 Room 5 结论
> **`review_group` 当前还不能进入真实退场；P3.3.10 最多只能把“什么时候才有资格从 retained anchor 进入 exit candidate”写硬。**

### 5.1.1 当前 UI 视角下仍缺的前置条件
在 Room 5 看来，`review_group` 要从 retained anchor 走到真实 exit judgment，至少还缺：

1. **ReviewPage source-neutral helper / summary / empty-state 已能稳定承接**
   - 不能再只会说 cloud-group 语
   - 但也不能提前写成本地 truth

2. **首页 review helper / summary block 已脱离 group-only current wording**
   - 否则一旦 `review_group` 想退，首页就会出现解释断层

3. **rollback / fallback 后用户文案仍完全自洽**
   - 只要 rollback target 仍是 `review_group`
   - 用户端就不应看到任何“旧方案即将退场”的暗示

4. **completion / settlement 前置解释已 source-neutral**
   - 否则 `review_group` 退场讨论会直接撞上 final fact owner 误解

### 5.1.2 retained anchor → exit candidate 的页面判断
Room 5 当前认为，`review_group` 最多只适合进入：
- current visible owner
- retained fallback anchor
- compatibility anchor
- exit candidate judgment pending

当前**不适合**进入：
- retired wording
- legacy mode wording
- soon-to-be-removed wording
- user-facing migration banner

### 5.1.3 Room 5 的 gate 规则句
> **只要用户端还需要依赖 `review_group` current wording 来理解 ReviewPage queue / continuation / completion / rollback，Room 5 就不支持 `review_group` 进入真实 exit judgment。**

---

## 6. Q3 — `db_api_uplift_judgment_v1`（Room 5 页面版）

## 6.1 Room 5 结论
> **Room 5 支持本轮正式进入 DB/API uplift judgment，但 UI 只承接“哪些 seam 现在看起来值得 uplift 判断”，不承接 active baseline uplift。**

### 6.1.1 从 UI 视角，哪些 seam 现在最值得进入 uplift judgment
Room 5 当前最关心的 uplift-judgment-ready seam 是：

#### A. ReviewPage source seam
至少需要能稳定表达：
- current visible source
- retained fallback anchor
- next-cutover candidate source
- hold / rollback target

#### B. Continuation / helper / summary seam
至少需要能表达：
- current continuation
- retained-anchor-aware continuation
- source-neutral continuation
- hold / fallback 后仍不误导的 continuation

#### C. Completion / settlement pre-display seam
至少需要能表达：
- evidence only
- candidate stronger-path
- backend-confirmed final fact
- final settlement result

#### D. Migration posture seam
至少需要能表达：
- current runtime owner
- retained fallback anchor
- compatibility-only
- deprecated candidate
- exit candidate pending
- uplift judgment pending

### 6.1.2 哪些继续只能停留在 candidate
以下当前仍只应停留在 candidate：
1. local queue source 的用户可见命名
2. ReviewPage source 切换后的结果型文案
3. route 选择结果字段的用户展示
4. `review_group` 退出状态的用户 copy
5. uplift absorbed / new active baseline 的任何用户表述

### 6.1.3 Room 5 的一句话判断
> **UI 现在可以帮助判断“哪些 seam 值得被 uplift judgment”，但还不能帮助宣布“uplift 已经吸收进 active baseline”。**

---

## 7. Q4 — `cutover_vs_fact_owner_boundary_v2`（Room 5 页面版）

## 7.1 Room 5 结论
> **fuller cutover 这一拍最危险的，不是页面长得不一样，而是让用户误以为 serving 扩大一点，就代表 final fact owner 也已经改了。**

### 7.1.1 当前仍必须以后端为准的最终事实
1. effective review fact
2. daily goal progress / completion
3. reward settlement / ledger arrival
4. streak / learning_day / check-in 最终事实
5. completion /到账 类主反馈

### 7.1.2 fuller cutover 下一拍绝不能顺手带出的 UI 结果
1. 已记为有效复习
2. 今日目标已推进 / 已完成
3. 奖励已到账
4. streak 已续上
5. 学习事实已正式更新
6. 计划已按新主链路生效

### 7.1.3 Room 5 对 UI 层的硬限制
即使 fuller cutover 比 first-cutover 多切一层，当前页面也只能保持：
- 当前可继续复习
- 当前暂无可继续内容
- 当前暂不可继续，请稍后再试

仍然不能写：
- 你刚刚的复习已正式记入最终结果
- 新队列已写回最终学习事实
- 奖励已因新主链路到账

---

## 8. Q5 — `retained_anchor_to_exit_transition_v1`（Room 5 页面版）

## 8.1 Room 5 结论
> **P3.3.10 最值得推进的，不是“宣布 `review_group` 可以退”，而是把 retained anchor 到 exit candidate 的 UI 过渡条件写硬。**

### 8.1.1 retained anchor 何时才算不再必须
Room 5 当前认为，只有当以下 4 点都成立时，`review_group` 才可能不再是强 retained anchor：

1. ReviewPage 的 source-neutral helper / summary / empty-state 已可单独成立
2. completion / settlement 的前置解释不再依赖 group-only wording
3. 首页 review helper / summary 已可不靠 group-only wording 支撑
4. rollback / hold 后的中性 fallback copy 已齐全，且不再依赖“回到 group wording 才解释得通”

### 8.1.2 rollback target 如何变化
当前：
- rollback target 仍必须回到 `review_group` current runtime path

未来若再前进一步，Room 5 最多支持进入：
- rollback target shrink judgment
- fallback copy shrink judgment

但当前不支持：
- 直接移除 `review_group` fallback target
- 直接写“回不回去已经不重要”

### 8.1.3 哪些 stop-condition 仍必须保持
以下 stop-condition 在 P3.3.10 当前轮继续必须保持：
1. 用户端出现 owner-shift / cutover / exit overclaim
2. 首页 route 被静默影响
3. active continuation 主路径被改写
4. final fact / settlement truth 被误写成新路径结果
5. rollback 后页面主路径解释不通
6. `review_group` retained anchor 被提前拔掉

---

## 9. Q6 — `phase4_writeback_order_v1`（Room 5 页面版）

## 9.1 Room 5 结论
> **本轮必须把 judgment / candidate / runtime truth / uplift absorbed 四层回写顺序写硬，否则下一轮极容易出现“治理层还在 judgment，页面却先写成已生效”的漂移。**

### 9.1.1 Room 5 推荐的 UI 回写顺序
#### Layer A — judgment absorb
先吸收：
- fuller-cutover judgment
- exit-gate judgment
- uplift judgment
- hold / rollback / proceed / escalate 条件

#### Layer B — candidate migration absorb
再吸收：
- source-neutral helper / summary / empty-state
- retained-anchor-aware state contract
- uplift-ready seam families
- exit-candidate pending markers

#### Layer C — execution-ready candidate absorb
只有当 Room 1 明确 pin 进入下一轮 execution-ready layer，才吸收：
- very narrow fuller-cutover execution-ready subset
- stronger rollback / fallback floor
- next-step state contract matrix

#### Layer D — runtime truth absorb
只有 true execution closeout 后，才允许把：
- fuller cutover 已生效
- exit gate 已满足
- uplift 已 absorbed
写进主 UI 文档的 runtime-truth 层

### 9.1.2 哪些只能写成 judgment
当前只允许写成 judgment：
1. `review_group` 是否已具备 exit 资格
2. 哪些 seam 值得 uplift judgment
3. 下一拍 fuller cutover 能扩大到哪
4. rollback target 是否将来可缩窄

### 9.1.3 哪些可以写成 execution-ready candidate
当前最多只允许写成 execution-ready candidate：
1. source-neutral helper / summary / CTA 迁移准备
2. retained-anchor-aware fallback copy
3. uplift-ready seam families
4. hold / rollback / fallback copy matrix

### 9.1.4 哪些绝不能写成 runtime truth
1. `review_group` 已退场
2. fuller cutover 已完成
3. active DB/API baseline 已 uplift
4. 现在用户已使用新主链路
5. final fact owner 已切换

---

## 10. 页面承接建议（Room 5 交付项）

### 10.1 若 fuller cutover 前进一步，最先受影响的页面
1. **ReviewPage**
   - helper / summary / queue-source-adapter / empty-state / completion 前置说明
2. **首页 review helper / summary / no-review-state**
   - 因为 retained-anchor → exit-candidate 会先冲击这里的解释层
3. **Settings / 我的页的 migration 说明层**
   - 仅在需要补 hold / rollback / not-yet-uplift note 时才触碰
4. **StudyPage explanation 边界**
   - 当前只需重新确认不扩张，不是优先新增

### 10.2 当前仍必须保持 current runtime truth 的页面 / 状态
1. 首页默认入口
2. active continuation 的当前承接方式
3. ReviewPage 用户可见主队列来源
4. final fact / settlement 主反馈
5. preview 可见范围

### 10.3 exit-gate UI guidance
1. `review_group` 当前继续保持 current visible owner
2. 同时继续作为 retained fallback anchor
3. 当前只允许出现 exit-candidate judgment，不允许出现 retired / removed / switched wording
4. 任何 helper / summary / CTA / empty-state 都不得提前出现“旧方案将退场”的暗示

### 10.4 uplift-judgment UI guidance
1. 只讨论 seam readiness，不讨论 user-visible baseline change
2. 只讨论 source-neutral / retained-anchor-aware state contract 是否够稳
3. 不把 uplift judgment 写成 uplift absorbed
4. 设置页 / 我的页不得出现“已升级到新主链路”提示

### 10.5 最小 UI candidate subset 层
Room 5 推荐本轮最多只进入：
1. ReviewPage helper / summary / empty-state / completion 前置说明 的 fuller source-neutral prep
2. 首页 review helper / no-review-state 的 retained-anchor-aware prep
3. rollback / hold / fallback 的中性 copy matrix
4. uplift-ready seam 的 UI 承接判断

---

## 11. runtime-truth guardrails（Room 5 交付项）

### 首页
当前必须继续保护：
1. `home_word_entry = study_default`
2. active continuation 独立承接
3. 不得 silent reroute
4. 不得让 planner-aware / fuller-cutover candidate 改变用户主路径

### ReviewPage
当前必须继续保护：
1. current serving truth = cloud `review_group`
2. queue / continuation / remaining / completion / settlement 的主表达仍围绕 current truth
3. fuller cutover judgment 不能把用户可见主来源提前写成本地
4. retained anchor 当前不可被用户感知为“已降级成旧方案”

### StudyPage
当前必须继续保护：
1. 继续承担最小 preview re-entry
2. preview 继续保持 StudyPage-only / hint-only / estimated-only
3. 当前不新增 fuller-cutover explanation
4. 当前不新增“本地规划已进入更高优先级”提示

### Settings / 我的页
当前必须继续保护：
1. backup / restore 不得被误写成 uplift / cutover
2. 不得出现“你现在已接入新主链路”
3. 不得出现“旧方案已停用”

---

## 12. user-visible forbidden claims（P3.3.10 补强）

以下表达在 P3.3.10 当前轮继续列为用户端禁区：

### fuller cutover / local-serving 禁区
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
11. retained anchor 已不再需要

### uplift 禁区
12. active DB/API baseline 已升级
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
23. streak 已因 fuller cutover 续上

### migration / hold / rollback 禁区
24. 已回退到旧方案
25. 新方案暂不可用
26. 已完成兼容切换
27. 现在你正在使用新的复习规划

---

## 13. Room 5 对 Room 1 的建议

### 13.1 建议 Room 1 可吸收的最小 UI judgment 合同层
Room 1 若要 pin，本轮建议只吸收以下 6 条：

1. **fuller cutover 下一拍最先受影响的，仍应是 ReviewPage 与首页 review 承接层，而不是首页主 route 或 final fact owner**
2. **`review_group` 当前还只能进入 exit-candidate judgment，不进入真实退场；它仍必须保留为 current visible owner + retained fallback anchor**
3. **DB/API uplift 当前只应进入 seam readiness judgment，不应进入 user-visible baseline change**
4. **当前 runtime truth 仍必须大面积保持不变**
5. **rollback / hold / fallback 的 UI 说明必须先于 fuller cutover 扩张写硬**
6. **任何会把 fuller cutover / exit / uplift judgment 写成已生效事实的表述继续禁止**

### 13.2 当前仍不建议吸收成 runtime truth 的内容
1. full cutover completed
2. `review_group` 真退场
3. active DB/API baseline uplift absorbed
4. 首页默认 route 切换
5. auto-routing runtime
6. final fact owner shift
7. 用户可见模式切换宣告

---

## 14. Room 5 一句话结论

> **P3.3.10 在 Room 5 视角，可以进入 Fuller Cutover / review_group Exit-Gate / DB-API Uplift Judgment Preflight，但当前最稳的推进仍是：继续扩大 ReviewPage 与首页 review 承接层的 source-neutral / retained-anchor-aware UI 契约，继续把 `review_group` 保留在 current visible owner + retained fallback anchor 的双姿态里，继续把 uplift 只写成 seam readiness judgment，并继续禁止一切会让用户误以为 fuller cutover、`review_group` 退场或 baseline uplift 已经生效的表达。**
