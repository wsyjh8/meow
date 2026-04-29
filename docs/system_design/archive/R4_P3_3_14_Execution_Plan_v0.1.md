# R4_P3_3_14_Execution_Plan_v0.1.md

- **Owner:** Room 4（治理层）
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** ready for execution
- **Role basis:** `ROOM04_治理版_v0.2.md`
- **Direct upstream input:** `R1_to_R4_P3_3_14_Execution_Handoff_v0.1.md`

---

## 0. 一句话定位

本稿不是代码实现记录，也不是新的 BR / DB / API / UI 主文档。  
本稿只做一件事：

> **把 Room 1 已经收口完成的 P3.3.14 结论，压成一份可直接交给 Room 4 执行层（Claude Code）的短而硬执行任务单。**

---

## 1. Room 4 当前判断

### 1.1 本轮是否可以开工
> **可以开工。**

### 1.2 本轮开工的性质
> **这是 `Final Cutover Program` 的 1 轮 3 checkpoint 执行单：A = Final Judgment Lock，B = Real Cutover Execution，C = Same-Round Absorb / Cleanup Closeout。**
>
> **它不是 full cutover completed，也不是 `review_group` true exit 或 active DB/API uplift absorbed 的生效宣告。**

### 1.3 Room 4 采用口径
- 继续服从 **Room 1 已 pin / 已指定的 review basis**
- 当前 runtime active truth 继续以：
  - `BR-OPP-001_v0.2.15.md`
  - `UI_SPEC_v0.3.5.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `Main_updated_2026-04-10_v34.md`
  - `STATUS_updated_2026-04-10_v32.md`
  为准
- 本轮只推进：
  - `final_cutover_judgment_lock_v1`
  - `real_cutover_execution_subset_v1`
  - `true_exit_absorb_gate_v1`
  - `db_api_uplift_absorb_gate_v1`
  - `fact_owner_cutover_guardrail_v1`
  - `same_round_cleanup_gate_v1`
  - regression / write-back / no-major-change statement
- 本轮不推进：
  - runtime owner shift completed
  - full cutover completed
  - `review_group` true exit（未过 gate 前）
  - active DB/API baseline uplift absorbed（未过 gate 前）
  - homepage route switch
  - active continuation source switch
  - auto-routing runtime
  - unified planner / planner merge
  - final fact owner shift
  - cleanup / old-path purge（未过 C 前）
  - DB schema rewrite
  - API core semantics rewrite

### 1.4 本轮是否需要先升级
> **默认不需要先升级。**

但若执行层在实现中发现以下情况，必须立即升级，不得自行补脑推进：

1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 `review_group` 最小合同
4. 需要把 execution subset 写成 ReviewPage 全量 current truth
5. 需要把首页“背单词”做成 silent reroute / auto-routing runtime
6. 需要改 active continuation 的承接路径
7. 需要让 local / stronger-ingest 直接改 final fact / settlement / ledger / daily goal / streak / learning day
8. 需要把 `review_group` 写成已退场 / 已不再使用 / 可直接清理 / fallback-only
9. 需要把本轮做成 full cutover / true exit / uplift absorbed / cleanup bundling

---

## 2. 本轮目标

完成 **P3.3.14 — Final Cutover Program Round** 的 **A / B / C 三 checkpoint**，具体包括：

1. 先把 `final_cutover_judgment_lock_v1` 写硬
2. 再把 `real_cutover_execution_subset_v1` 限定在 very narrow real execution
3. 再判断 `true_exit_absorb_gate_v1`
4. 再判断 `db_api_uplift_absorb_gate_v1`
5. 持续守住 `fact_owner_cutover_guardrail_v1`
6. 只有在 A、B 证据都足够时，才允许进入 `same_round_cleanup_gate_v1`
7. 交付 regression / write-back / no-major-change 的固定证据包

---

## 3. In Scope

## 3.1 A checkpoint — Final Judgment Lock
Room 4 本轮必须先落地并交证据的内容：

1. `final_cutover_judgment_lock_v1`
2. `true_exit_absorb_gate_v1`
3. `db_api_uplift_absorb_gate_v1`
4. `fact_owner_cutover_guardrail_v1`
5. `same_round_cleanup_gate_v1` 的进入前提与 stop-at-B 条件
6. current runtime truth / candidate / readiness / absorbed reality 的分层写硬
7. still-dependent paths inventory
8. must-hold / must-escalate / stop-condition 写硬

### A 必须写硬的 6 组前提
1. **Runtime truth immovables**
   - 首页默认入口继续 `study_default`
   - current visible Review serving owner 继续围绕 cloud `review_group`
   - active continuation 当前承接路径不可静默改写
   - final fact / settlement owner 不随 serving seam advancement 一起切换

2. **Rollback immovables**
   - rollback target 继续固定为 `cloud_review_group_current_runtime_path`
   - hold fallback 继续必须能稳定回到 cloud current runtime path
   - rollback / hold copy 不得先写成 historical-only

3. **True-exit preconditions inventory**
   - still-dependent paths 必须列全
   - still-missing preconditions 必须列清
   - `true-exit-candidate ≠ true-exit-started ≠ true-exit-absorbed`

4. **DB/API uplift absorb inventory**
   - uplift seam families 必须区分 absorbed-ready 与 marker-only
   - DB schema rewrite / API core semantics rewrite 继续 out of scope
   - active baseline 继续明确为 `DB/API v0.2.1`

5. **Fact-owner guardrail**
   - serving seam advancement 不得自动带出 review fact / daily completion / settlement / streak / learning_day / reward ledger owner shift
   - stronger-ingest path 只允许进入 candidate / readiness / absorbed-judgment 讨论，不得直接升格为 final owner

6. **Cleanup gating**
   - old-path purge / historical demotion / deprecated candidate 清理 / runtime truth 升级，全部后置到 C
   - A checkpoint 不允许提前消化 cleanup

### A 必须显式承认的 still-dependent paths
1. active continuation identity
2. completion gating
3. settlement trigger
4. rollback target
5. non-cutover / non-upgraded sessions baseline path
6. compatibility anchor / QA baseline reference

### A 的交付目标
Room 4 必须把 A 收成：
- 一组可执行 gate / guard / assert / flag / contract 资产
- 一组可回归的 no-overclaim / no-owner-shift / no-route-switch 证据
- 一份足够让 Room 1 判断“是否准许进入 B”的 closeout 摘要

---

## 3.2 B checkpoint — Real Cutover Execution
**只有在 A 明确通过后，Room 4 才允许进入 B。**

### B 当前唯一允许进入真实执行的 subset
1. **ReviewPage continuity-adjacent serving-adapter family**
2. **ReviewPage helper / summary / empty-state / completion 前置说明层**
3. **首页 review helper / summary / no-review-state 的 retained-anchor-aware 承接层**
4. **rollback / hold / fallback neutral orchestration layer**
5. **与 stronger-ingest absorb-readiness 直接绑定的最小 precondition / binding seam**

### B 必须一起落地的保护层
1. rollback / hold / fallback 的完整中性 copy / state contract
2. observability / evidence capture
3. runtime truth regression
4. stop-condition / hold-condition
5. user-visible overclaim guardrails

### B 当前明确禁止纳入的内容
1. 首页默认主 route 切换
2. active continuation source switch
3. `review_group` current visible owner identity 切换
4. final fact / settlement owner 切换
5. DB schema rewrite
6. API core semantics rewrite
7. cleanup / old-path purge
8. user-visible auto-routing / planner-aware route

### B 的通过门
只有当以下条件都成立时，B 才可视为通过：
1. runtime truth regression 通过
2. rollback / hold / observability 证据包通过
3. `no-major-change statement` 继续成立
4. 无 must-hold mismatch 未清
5. 未触碰首页 route / active continuation / final fact owner

---

## 3.3 C checkpoint — Same-Round Absorb / Cleanup Closeout
**只有在 B 明确通过且证据齐全时，Room 4 才允许进入 C。**

### C 当前允许讨论 / 吸收的内容
1. `review_group` 是否可从 true-exit-ready 进入 true exit absorb
2. DB/API 是否可从 absorbed judgment gate 进入 absorbed decision-ready
3. cleanup / old-path purge 是否具备同轮尾部吸收资格
4. same-round closeout 的 write-back order

### C 只有在以下条件都成立时才允许启动
1. B 的 widened real execution subset 已真实落地
2. regression / observability / stop-condition 证据齐全
3. `review_group` true-exit-ready 的前提已被证明成立
4. uplift-absorb-ready / absorbed judgment gate 的前提已被证明成立
5. rollback target / hold path / fallback copy 仍可解释
6. Room 1 明确同意进入 same-round absorb / cleanup closeout

### 只要出现以下任一情况，必须 stop at B
1. current runtime truth 被偷改
2. active continuation 被切到 local path
3. `review_group` true exit 证据不完整
4. absorbed 证据不完整
5. final fact owner 边界被破坏
6. rollback / hold / fallback copy 不完整
7. 用户侧出现“已切完 / 已退场 / 已 absorbed / 已 cleanup”的 overclaim

---

## 4. Out of Scope

以下内容 **不因 P3.3.14 自动纳入**，Room 4 不得越界：

1. A 未过时的 B 执行
2. B 未过时的 C absorb / cleanup
3. 无证据的 `review_group` true exit
4. 无证据的 active DB/API uplift absorbed
5. 无证据的 final fact owner shift
6. homepage route / planner-aware runtime route
7. active continuation source switch（除非被 Room 1 在后续 checkpoint 明确批准）
8. DB schema 重构
9. API core semantics 重写
10. 用户可见“已切完 / 已退场 / 已 absorbed / 已 cleanup”的宣告

---

## 5. 本轮必须守住的 runtime-truth guardrails

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

## 6. user-visible forbidden claims（Room 4 必须硬禁）

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
25. 学习事实已正式更新
26. 现在你刚刚的结果已写入最终事实

### migration / absorb / cleanup 禁区
27. 已回退到旧方案
28. 新方案暂不可用
29. 已完成兼容切换
30. 现在你正在使用新的复习规划
31. cutover 已完成
32. cleanup 已完成

---

## 7. Room 4 本轮交付要求

### 7.1 A checkpoint 交付
1. A checkpoint 实施说明
2. gate / guard / assert / flag / contract 资产清单
3. still-dependent paths inventory
4. must-hold / must-escalate / stop-condition 清单
5. A checkpoint 通过 / 不通过判断

### 7.2 B checkpoint 交付（仅在 A 通过后）
1. 真实 execution subset 实施说明
2. 受影响文件清单
3. rollback / hold / fallback / observability 证据
4. regression 结果
5. B checkpoint 通过 / 不通过判断

### 7.3 C checkpoint 交付（仅在 B 通过后）
1. true-exit absorb judgment
2. uplift-absorb judgment
3. cleanup / old-path purge judgment
4. same-round closeout 建议
5. C checkpoint 通过 / 不通过判断

### 7.4 全轮固定交付
1. 受影响文件清单
2. 改动摘要
3. 测试结果 / 自测结果
4. 是否触碰核心契约的判断
5. `no-major-change statement`
6. 需要哪些文档回写
7. 是否可 accept / revise / escalate / hold

---

## 8. Room 4 验收判断口径

只有同时满足以下条件，Room 4 才会给出 `accept / 可 closeout` 倾向：

1. A judgment lock 已被写硬
2. B real execution 只落在 very narrow subset
3. `review_group` 没被提前写成 true exit
4. DB/API 没被提前写成 uplift absorbed
5. final fact / settlement owner 未被偷切
6. runtime truth guardrails 继续全绿
7. 未触碰 DB schema / API core semantics / homepage route / active continuation / final fact owner
8. 用户端无 overclaim
9. 已交 regression / write-back / no-major-change 的固定证据包

---

## 9. 给执行层的一句话

> **请按“P3.3.14 Final Cutover Program Round”的 A → B → C 三 checkpoint 推进：A 先把 judgment / gate / guardrail 全部写硬，B 再只切 ReviewPage + 首页 review 承接层的 very narrow real execution，C 只有在证据足够时才允许讨论 true exit / uplift absorbed / cleanup；任何时候都不要把本轮写成 full cutover、`review_group` true exit、active DB/API uplift absorbed 或 final fact owner shift 已生效。**
