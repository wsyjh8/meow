# UI_SPEC_P3_3_14_FinalCutoverProgram_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.14 — Final Cutover Program Round`
- **Direct upstream input:** `R1_P3_3_14_ScopePin_and_Handoff_Pack_v0.1.md`
- **Related inputs:** `BR-OPP-001_v0.2.15.md` + `UI_SPEC_v0.3.5.md` + `背单词喵喵app_DB设计草案_v0.2.1.md` + `背单词喵喵app_API设计草案_v0.2.1.md` + `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` + `P3.3.13_Claude_res.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.14 当前轮需要回答的 Final Cutover Program 问题，翻成可被 Room 1 判断是否 pin 的最小 UI program-preflight contract。**

本稿不是：
- 新 UI 主文档
- 新 PRD / BR / DB / API 主文档
- Room 4 执行单
- full cutover completed 宣告
- `review_group` true exit 生效公告
- active DB / API baseline uplift absorbed 生效稿
- cleanup / old-path purge 已完成宣告

一句话：

> **P3.3.14 在 Room 5 视角，不是“已经切完”的轮，而是“把最后几轮合成 1 个 program round，但内部必须按 A judgment lock → B real execution → C absorb / cleanup 的 checkpoint 推进”的轮。**

---

## 1. 输入依据

### 1.1 Main-thread handoff basis
- `R1_P3_3_14_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.2 Current runtime / review basis
- `BR-OPP-001_v0.2.15.md`
- `UI_SPEC_v0.3.5.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.13_Claude_res.md`
- `Main_updated_2026-04-10_v34.md`
- `STATUS_updated_2026-04-10_v32.md`

### 1.3 Room 5 当前采用口径
1. 当前 runtime truth 仍以 `UI_SPEC_v0.3.5.md` 的已吸收事实为准。
2. `review_group` 当前仍是 ReviewPage 用户可见 serving truth。
3. final fact / settlement truth 当前仍以后端为准。
4. 本轮虽然是 Final Cutover Program Round，但只允许在 **A / B / C 三个 checkpoint** 下讨论 judgment / execution / absorb。
5. 本轮不得把 fuller cutover、`review_group` true exit、DB/API uplift absorbed、cleanup、final fact owner shift 写成一上来就已生效事实。

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持 P3.3.14 正式启动，但只支持进入“Final Cutover Program Preflight”；当前最稳的做法不是把所有 remaining 事项一把梭，而是把 A judgment lock 写硬、把 B 的真实 execution subset 限死在 ReviewPage + 首页 review 承接层、并把 C 的 absorb / cleanup 严格 gated。**

### 2.2 为什么现在可以进入 program round
因为当前已经具备：
1. P3.3.9 的 first-cutover 落地证据
2. P3.3.10 / 11 / 12 / 13 连续几轮关于 judgment / candidate / readiness / execution 的收口结果
3. retained anchor / rollback / hold / observability 的成套护栏
4. `review_group` true-exit-gate 与 true-exit-candidate 的前置条件清单
5. DB/API uplift-absorb judgment / readiness 的 seam families 最小清单
6. BR / UI 主文档已连续吸收 P3.3.9 → P3.3.13 的治理结论

### 2.3 为什么这轮仍不能直接写成“已切完”
因为以下 current runtime truth 仍必须继续保持：
1. 首页默认入口仍是 `study_default`
2. active continuation 继续独立承接，不得 silent reroute
3. ReviewPage 用户可见 serving truth 继续围绕 cloud `review_group`
4. final fact / settlement truth 继续以后端为准
5. DB / API active baseline 仍是 `v0.2.1`
6. `review_group` 仍未进入 true exit
7. uplift-absorb-readiness 仍不是 uplift absorbed

---

## 3. Room 5 的总护栏：A / B / C 必须严格分层

### 3.1 A checkpoint = Final Judgment Lock
A 只做：
- judgment lock
- still-dependent paths inventory
- overclaim 禁区写硬
- UI 层哪些东西当前仍必须保持 current runtime truth

A 不做：
- 真切
- 真退
- 真 absorbed
- cleanup

### 3.2 B checkpoint = Real Cutover Execution
B 只做：
- Room 1 明确批准后的 very narrow real cutover execution
- widened serving-adapter / homepage review acceptance 层的真正切换
- rollback / hold / observability 的成套落地
- true-exit-candidate → true-exit-ready 的 very narrow transition
- uplift-absorb-readiness → uplift-absorb-ready 的 very narrow transition

B 不做：
- true exit absorbed
- uplift absorbed
- old-path cleanup absorbed
- user-visible completed 宣告

### 3.3 C checkpoint = Same-Round Absorb / Cleanup Closeout
C 只做：
- 只有当 B 的 runtime truth、回归、证据包全部通过后，才允许进入的 absorb / cleanup closeout
- old-path purge 是否可同轮吸收
- same-round closeout 的 write-back order

C 不做：
- 没证据先宣布
- 没回归先清理
- 以 UI 文案先行替代 runtime 证据

---

## 4. Q1 — `final_cutover_judgment_lock_v1`（Room 5 页面版）

## 4.1 Room 5 结论
> **A checkpoint 必须先把“哪些页面仍必须保持 current runtime truth”“哪些 still-dependent paths 仍然挡着”“哪些 overclaim 继续禁止”一次写硬；A 不过，B 不得启动。**

### 4.1.1 A checkpoint 必须先写硬的 UI 条件
1. 首页默认入口继续 `study_default`
2. active continuation 继续独立承接，不得 silent reroute
3. ReviewPage 用户可见 serving truth 继续围绕 cloud `review_group`
4. final fact / settlement 主反馈继续以后端为准
5. Settings / 我的页不得提前出现“已升级 / 已切完 / 已退场 / 已 cleanup”语义
6. rollback / hold / fallback 的中性 copy matrix 必须先齐

### 4.1.2 A checkpoint 必须显式承认的 still-dependent paths
1. ReviewPage 当前主承接路径
2. active continuation identity
3. current completion gating 的解释通路
4. settlement trigger 的用户可见解释通路
5. rollback target = `cloud_review_group_current_runtime_path`
6. compatibility anchor / QA baseline reference
7. 首页 review helper / summary / no-review-state 仍受 retained-anchor 约束

### 4.1.3 A checkpoint 继续禁止的 overclaim
- 本地 serving 已启用
- ReviewPage 已切到本地队列
- `review_group` 已 true exit
- active DB/API baseline 已 uplift absorbed
- 新主链路已生效
- cleanup 已完成
- 现在你正在使用新的复习规划

---

## 5. Q2 — `real_cutover_execution_subset_v1`（Room 5 页面版）

## 5.1 Room 5 结论
> **B checkpoint 真正允许切换的，仍然不是首页主 route，而是 ReviewPage + 首页 review 承接层的 very narrow real execution subset。**

### 5.1.1 Room 5 当前推荐可进入 B 的真实 execution subset
1. **ReviewPage continuity-adjacent serving-adapter family**
   - 可以进入比 P3.3.13 更真实一拍的 execution
   - 但仍不得自动等于 full ReviewPage truth 已整体切走

2. **ReviewPage helper / summary / empty-state / completion 前置说明层**
   - 可以从 retained-anchor-aware / source-neutral prep 进入 real execution
   - 但不得写成 final fact owner 已变

3. **首页 review helper / summary / no-review-state**
   - 可以进入与 ReviewPage 更紧耦合的 review acceptance execution
   - 但不切首页默认 route

4. **rollback / hold / fallback 的中性 copy / state contract**
   - 必须跟着 execution 一起落地
   - 没有这一层，就不允许真实切

### 5.1.2 Room 5 当前不推荐进入 B 的部分
1. 首页默认 route
2. active continuation source switch
3. user-visible auto-routing / planner-aware route
4. final fact / settlement owner
5. `review_group` true exit absorbed
6. active DB/API uplift absorbed
7. cleanup / old-path purge

### 5.1.3 Blast radius 最小化原则
> **B checkpoint 的切换范围，只能落在 ReviewPage + 首页 review 承接层；一旦越过首页主 route、active continuation、final fact owner，就从“real cutover execution”越界成“无门槛 bundling”。**

---

## 6. Q3 — `true_exit_absorb_gate_v1`（Room 5 页面版）

## 6.1 Room 5 结论
> **`review_group` 当前最多只能从 true-exit-candidate 走到 true-exit-ready；B 允许准备，C 才允许吸收。**

### 6.1.1 从 candidate 到 ready，最低还缺的 UI 条件
1. ReviewPage helper / summary / empty-state 已不再依赖 group-only wording 才能解释 current path
2. 首页 review helper / summary / no-review-state 已不再依赖 group-only wording 才能成立
3. rollback / hold 后的中性 fallback copy 已完全齐全，且不依赖“回到 group wording”才能解释
4. completion / settlement 前置说明已 source-neutral，不再把 `review_group` current wording 当唯一解释入口

### 6.1.2 哪些 replacement path / compatibility anchor / completion gating 仍需先被证明
1. replacement path 能稳定承接 ReviewPage 当前主承接路径
2. compatibility anchor 退场后不会让 QA / docs / rollback 失去 reference
3. completion gating 与 settlement trigger 的解释通路不会因为 true exit 而断层
4. active continuation 当前承接路径不会被连带改写

### 6.1.3 当前结论
- **A：** 只能写清前提与 still-dependent paths
- **B：** 最多进入 true-exit-ready 的 very narrow transition
- **C：** 只有证据齐全时，才允许吸收到 true exit / cleanup closeout

---

## 7. Q4 — `db_api_uplift_absorb_gate_v1`（Room 5 页面版）

## 7.1 Room 5 结论
> **DB/API 在 P3.3.14 当前只允许从 readiness 走到 absorbed judgment gate，不允许直接写成 active baseline change。**

### 7.1.1 Room 5 当前最关心的 absorbed-gate seam families
1. ReviewPage source seam
2. continuation / helper / summary seam
3. completion / settlement pre-display seam
4. migration posture seam
5. retained-anchor / fallback posture seam

### 7.1.2 哪些仍只能停留在 marker / migration / rollback / hold 层
1. 用户可见 local source naming
2. `review_group` true-exit wording
3. route 选择结果字段的用户展示
4. “已升级到新基线”的任何 copy
5. Settings / 我的页里与 absorbed 有关的表述

### 7.1.3 Room 5 当前不支持直接 absorbed 的原因
1. active DB/API baseline 仍是 `v0.2.1`
2. 当前 review basis 仍把 schema rewrite / API core semantics rewrite 放在 out of scope
3. 页面层当前没有足够证据支撑 absorbed 级用户事实
4. absorbed 不能只靠 candidate / readiness artifacts 升格

---

## 8. Q5 — `fact_owner_cutover_guardrail_v1`（Room 5 页面版）

## 8.1 Room 5 结论
> **无论 B checkpoint 的 serving seam 走多远，final fact / settlement owner 当前都继续锁在后端。**

### 8.1.1 当前仍必须以后端为准的最终事实
1. effective review fact
2. daily goal progress / completion
3. reward settlement / ledger arrival
4. `check_in / learning_day / streak`
5. completion / 到账类主反馈

### 8.1.2 哪些 stronger-ingest path 继续只能停在 candidate / readiness
1. accept / reject / duplicate 的 stronger-ingest path
2. progress-candidate / completion-candidate 的更强绑定
3. absorb-readiness binding prep
4. local evidence / candidate stronger path

### 8.1.3 当前继续禁止的表达
- 已记为有效复习
- 今日目标已推进 / 已完成
- 奖励已到账
- streak 已续上
- 学习事实已正式更新
- 新主链路已生效
- 现在你刚刚的结果已写入最终事实

---

## 9. Q6 — `same_round_cleanup_gate_v1`（Room 5 页面版）

## 9.1 Room 5 结论
> **cleanup 只能在 C checkpoint 被吸收，而且必须建立在 B 的 runtime truth、回归、证据包都通过之后。**

### 9.1.1 何时才允许在 C 被吸收
1. B 的 widened real execution subset 已真实落地
2. regression / observability / stop-condition 证据齐全
3. `review_group` true-exit-ready 的前提已被证明成立
4. uplift-absorb-ready 的前提已被证明成立
5. rollback target / hold path / fallback copy 仍可解释
6. Room 1 明确同意进入 same-round absorb / cleanup closeout

### 9.1.2 哪些条件不满足时，必须 stop at B
1. current runtime truth 被偷改
2. active continuation 被切到 local path
3. `review_group` true exit 证据不完整
4. absorbed 证据不完整
5. final fact owner 边界被破坏
6. rollback / hold / fallback copy 不完整
7. 用户侧出现已切完 / 已退场 / 已 absorbed / 已 cleanup 的 overclaim

### 9.1.3 Room 5 的 cleanup 最小 UI 风险控制
1. cleanup 先改 internal label / deprecated marker，不先改用户可见成就式 copy
2. 不做“庆祝切换完成”式文案
3. 不让用户看到“旧方案被删除”这种实现层叙事
4. 保持失败时可解释、回滚时不穿帮

---

## 10. A / B / C 的页面承接建议（Room 5 交付项）

### 10.1 A checkpoint — 页面怎么表达
- 页面继续保持 current runtime truth
- 允许出现的，只是更完整的 internal judgment / preflight 边界
- 用户侧不感知“program round 已启动”
- 所有 overclaim 继续硬禁

### 10.2 B checkpoint — 页面怎么表达
- 允许 ReviewPage + 首页 review 承接层进入更真实一拍 execution
- 允许 helper / summary / CTA / fallback 扩大
- 允许 true-exit-candidate → true-exit-ready 的 very narrow preparation
- 允许 uplift-absorb-readiness → absorbed-ready 的 very narrow preparation
- 但用户侧仍不看到 true exit / absorbed / cleanup completed

### 10.3 C checkpoint — 页面怎么表达
- 只有当 Room 1 放行时，才允许进入 absorb / cleanup closeout
- 允许把一部分 deprecated / compatibility marker 从运行态事实层移除
- 允许主文档 / runtime-baseline 进入真正 absorb 后的写回
- 但仍不建议做强宣告型用户文案；以“状态自然消失”优先

---

## 11. runtime-truth guardrails（Room 5 交付项）

### 首页
当前必须继续保护：
1. `home_word_entry = study_default`
2. active continuation 独立承接
3. 不得 silent reroute
4. 不得让 planner-aware / final program candidate 改变用户主路径

### ReviewPage
当前必须继续保护：
1. current serving truth = cloud `review_group`
2. queue / continuation / remaining / completion / settlement 的主表达仍围绕 current truth
3. B 允许切 subset，但不得先把 full truth 偷切
4. `review_group` 当前不可被用户感知为“已退场”

### StudyPage
当前必须继续保护：
1. preview 继续保持 StudyPage-only / hint-only / estimated-only
2. 当前不新增 full cutover explanation
3. 当前不新增“本地规划已成为主真相”提示

### Settings / 我的页
当前必须继续保护：
1. backup / restore 不得被误写成 uplift / cutover
2. 不得出现“你现在已接入新主链路”
3. 不得出现“旧方案已停用”
4. cleanup 吸收前，不得出现“已完成迁移 / 已删除旧路径”提示

---

## 12. user-visible forbidden claims（P3.3.14 program round 补强）

以下表达在 P3.3.14 当前轮继续列为用户端禁区：

### fuller cutover / local-serving 禁区
1. 本地 serving 已启用
2. ReviewPage 已切到本地队列
3. 当前复习队列来自本地 due
4. owner shift 已完成
5. 当前 serving truth 已切换
6. 已升级到新 serving 方案

### `review_group` true-exit / cleanup 禁区
7. `review_group` 已退场
8. 旧方案即将不可用
9. 当前已不再使用 `review_group`
10. retained anchor 已不再需要
11. 已完成旧方案迁移
12. old path 已清理完成

### uplift 禁区
13. active DB / API baseline 已升级
14. 新基线已吸收进运行态
15. 现在已按新契约运行
16. uplift 已完成

### routing / planner 禁区
17. 系统已自动为你选择更优入口
18. auto-routing 已开启
19. mixed session 已启用
20. planner-aware 首页已生效

### fact / settlement 禁区
21. 本地已直接记为有效复习
22. 今日进度已因本地方案更新
23. 奖励已因新主链路到账
24. streak 已因 final cutover 续上

### migration / absorb / cleanup 禁区
25. 已回退到旧方案
26. 新方案暂不可用
27. 已完成兼容切换
28. 现在你正在使用新的复习规划
29. cutover 已完成
30. cleanup 已完成

---

## 13. Room 5 对 Room 1 的建议

### 13.1 建议 Room 1 可 pin 的最小 UI program contract
Room 1 若要 pin，本轮建议只吸收以下 6 条：

1. **P3.3.14 必须按 A / B / C 三个 checkpoint 推进，Room 5 不支持省略 gate**
2. **A checkpoint 必须先把 current runtime truth、still-dependent paths、overclaim 禁区一次写硬**
3. **B checkpoint 真正可切的，仍只限于 ReviewPage + 首页 review 承接层，不含首页默认 route / active continuation / final fact owner**
4. **`review_group` 当前最多只应进入 true-exit-ready 的 very narrow transition，不得提前写成 true exit**
5. **DB/API 当前最多只应进入 uplift-absorb-ready 的 very narrow transition，不得提前写成 absorbed**
6. **cleanup 只能在 C checkpoint 被吸收；若 A 不够硬或 B 证据不全，必须 stop at B**

### 13.2 当前仍不建议吸收成 runtime truth 的内容
1. full cutover completed
2. runtime owner shift completed
3. `review_group` true exit
4. active DB/API baseline uplift absorbed
5. homepage route / planner-aware runtime route
6. active continuation source switch
7. auto-routing runtime
8. final fact owner shift
9. cleanup / old-path purge 已生效
10. 用户可见“已切完 / 已退场 / 已 absorbed / 已 cleanup”宣告

---

## 14. Room 5 一句话结论

> **P3.3.14 在 Room 5 视角，可以进入 Final Cutover Program Preflight，但当前最稳的推进方式仍然是：A 先写硬 judgment lock，B 再把 ReviewPage 与首页 review 承接层推进到更真实一拍 cutover execution，C 最后才允许 absorb / cleanup；在此之前，`review_group` 继续保持 current visible owner + retained fallback anchor，DB/API 继续只到 absorbed-gate 前一层，final fact / settlement truth 继续以后端为准，且一切“已切完 / 已退场 / 已 absorbed / 已 cleanup”的表达继续禁止。**
