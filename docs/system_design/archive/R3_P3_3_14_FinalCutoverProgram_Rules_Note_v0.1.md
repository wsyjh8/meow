# R3_P3_3_14_FinalCutoverProgram_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / Final Cutover Program / A-B-C checkpoint round
- **Status:** ready for Room 1 review
- **Date:** 2026-04-11
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `Main_updated_2026-04-10_v34.md` + `STATUS_updated_2026-04-10_v32.md`
- **Direct upstream input:** `R1_P3_3_14_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.14 当前轮需要回答的 Final Cutover Program 问题，收成一份可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API 主文档
- 新 UI 主文档
- Room 4 执行单
- runtime owner shift completed 宣告
- `review_group` true exit 生效公告
- active DB/API uplift absorbed 生效稿
- cleanup / old-path purge 完成稿

一句话：

> **P3.3.14 是 1 个合并轮次，但内部必须按 A = Final Judgment Lock → B = Real Cutover Execution → C = Same-Round Absorb / Cleanup Closeout 三个 checkpoint 推进；它不是“一上来就切完 / 退完 / 升完 / 清完”的轮。**

---

## 1. 输入依据

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_14_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.15.md`
- `UI_SPEC_v0.3.5.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v34.md`
- `STATUS_updated_2026-04-10_v32.md`
- `P3.3.13_Claude_res.md`

---

## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

但推进方式不是继续拆成很多正式编号轮，而是：

> **在同一轮内部，用 A / B / C 三个 checkpoint 收口最后几拍。**

### 2.2 本轮不能直接写成什么
Room 3 同时明确：

> **P3.3.14 当前不能直接写成 `runtime owner shift completed`、`ReviewPage local-serving full runtime cutover completed`、`review_group` true exit 已生效、`active DB/API baseline uplift absorbed`、`cleanup`、`final fact owner shift`。**

### 2.3 Room 3 一句话立场
> **Room 3 支持 P3.3.14 进入 Final Cutover Program；但这轮必须先把 A checkpoint 的 judgment lock 写硬，再决定 B checkpoint 哪些 subset 可真切，最后才讨论 C checkpoint 的 absorb / cleanup。A 不过，不得进 B；B 不过，不得进 C。**

---

## 3. `final_cutover_judgment_lock_v1`（A checkpoint）

## 3.1 Room 3 结论
> **A checkpoint 的任务，不是“开始切”，而是把“什么情况下才配切、什么情况下绝不能夸大、哪些 still-dependent paths 必须先承认”一次写硬。**

### RF-P3.3.14-001 — A checkpoint 必须先写硬的生效前提
- **Status:** Frozen candidate for this round
- **Rule:** 在进入 B 之前，至少必须显式写硬以下前提：
  1. current runtime truth 仍大面积围绕 cloud `review_group`
  2. 首页 runtime 仍是 `home_word_entry = study_default`
  3. active continuation 仍未切到 local path
  4. final fact / settlement truth 仍以后端为准
  5. DB / API active baseline 仍是 `v0.2.1`
  6. `review_group` 当前仍未进入 true exit
  7. uplift-absorb-readiness 当前仍不是 uplift absorbed

### RF-P3.3.14-002 — still-dependent paths 必须先被显式承认
- **Status:** Frozen candidate for this round
- **Rule:** 进入 A 时，以下路径必须被继续显式承认为 still-dependent paths：
  1. active continuation identity
  2. completion gating
  3. settlement trigger
  4. rollback target
  5. non-cutover / non-upgraded sessions baseline path
  6. compatibility anchor / QA baseline reference

### RF-P3.3.14-003 — A checkpoint 的 overclaim 禁区
- **Status:** Frozen candidate for this round
- **Forbidden claims:**
  1. runtime owner shift 已完成
  2. `review_group` 已 true exit
  3. active DB/API baseline 已 uplift absorbed
  4. full cutover 已完成
  5. cleanup 已开始或已完成
  6. final fact owner 已切换

### RF-P3.3.14-004 — A checkpoint 通过门
- **Status:** Frozen candidate for this round
- **Rule:** A 只有在以下条件都成立时才可判定通过：
  1. no-overclaim
  2. still-dependent paths 已列全
  3. current runtime truth / candidate / readiness / absorbed reality 已分层
  4. must-hold / must-escalate 已写硬
  5. Room 1 可直接 pin 的最小 program contract 已成文

---

## 4. `real_cutover_execution_subset_v1`（B checkpoint）

## 4.1 Room 3 结论
> **B checkpoint 可以进入真实 cutover 执行，但只能切更接近 full cutover 的 very narrow 真实子集，不能把整个主链路一把梭。**

### RF-P3.3.14-005 — B checkpoint 当前唯一允许的真实切换方向
- **Status:** Frozen candidate for this round
- **Rule:** 当前最稳的真实切换方向，只允许继续停在：
  1. **ReviewPage continuity-adjacent serving-adapter family**
  2. **与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层**
  3. **首页 review helper / summary / no-review-state 的 retained-anchor-aware acceptance 层**
  4. **rollback / hold / fallback 的中性 copy / state contract**
  5. **stronger-ingest absorb-readiness binding prep 的 very narrow execution**

### RF-P3.3.14-006 — B checkpoint 当前明确禁止纳入
- **Status:** Frozen candidate for this round
- **Forbidden layer:**
  1. 首页默认主 route 切换
  2. active continuation source switch
  3. user-visible planner-aware route / auto-routing runtime
  4. `review_group` true exit
  5. final fact owner shift
  6. active DB/API baseline uplift absorbed
  7. cleanup / old-path purge

### RF-P3.3.14-007 — B checkpoint 的 blast radius / rollback complexity 约束
- **Status:** Frozen candidate for this round
- **Rule:** B 只有在以下约束继续成立时才允许推进：
  1. blast radius 继续主要局限在 ReviewPage + 首页 review 承接层
  2. rollback complexity 仍可由 retained anchor / fallback / hold 结构承受
  3. 切换后不得误伤首页主路由、active continuation、final fact owner

### RF-P3.3.14-008 — B checkpoint 通过门
- **Status:** Frozen candidate for this round
- **Rule:** B 只有在以下条件都成立时才可视为通过：
  1. runtime truth regression 通过
  2. rollback / hold / observability 证据包通过
  3. no-major-change statement 继续成立
  4. 无 must-hold mismatch 未清
  5. 未触碰首页 route / active continuation / final fact owner

---

## 5. `true_exit_absorb_gate_v1`

## 5.1 Room 3 结论
> **`review_group` 当前最多只能从 true-exit-candidate 往 true-exit absorb gate 靠近；只有证明 replacement path 与 retained-anchor 替代条件都齐，才有资格在 C checkpoint 被吸收。**

### RF-P3.3.14-009 — `review_group` 当前仍必须保持四层并存
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.14 当前轮，`review_group` 仍必须继续保持：
  1. **current runtime serving owner**
  2. **retained fallback anchor**
  3. **compatibility anchor**
  4. **deprecated candidate**

### RF-P3.3.14-010 — `review_group` 进入 true-exit absorb gate 的最低条件
- **Status:** Frozen candidate for this round
- **Rule:** 只有当以下条件都成立时，`review_group` 才有资格在 C checkpoint 被吸收：
  1. active continuation 已有稳定 replacement path
  2. completion gating 已有清晰 replacement path
  3. settlement trigger 已有清晰 replacement path
  4. rollback target 已有 future-safe replacement proof
  5. non-cutover / non-upgraded sessions baseline path 已有替代解释
  6. compatibility anchor / QA baseline reference 可迁移
  7. BR / UI / DB / API / TEST 的 exit 影响范围已同步

### RF-P3.3.14-011 — 哪些条件不满足时必须停在 B，不得进入 C
- **Status:** Frozen candidate for this round
- **Rule:** 只要以下任一不满足，就必须 stop at B：
  1. rollback target 仍无法替代
  2. active continuation 仍无法替代
  3. completion gating / settlement trigger 仍依赖 `review_group`
  4. compatibility anchor / QA baseline 仍无法迁移
  5. any no-overclaim boundary 被触碰

---

## 6. `db_api_uplift_absorb_gate_v1`

## 6.1 Room 3 结论
> **DB/API 本轮可以进入 uplift-absorb gate 判断，但 absorbed 只允许发生在 C，且必须以 seam families 被证明 ready 为前提。**

### RF-P3.3.14-012 — 哪些 seam 当前可以进入 absorbed gate 判断
- **Status:** Frozen candidate for this round
- **Rule:** 当前最多只允许以下 seam families 进入 absorbed gate 判断：
  1. serving source descriptor seam
  2. retained-anchor / fallback posture seam
  3. stronger-ingest path minimal seam
  4. rollback / hold / observability seam
  5. source-neutral state / helper / summary contract seam

### RF-P3.3.14-013 — 哪些仍只能停留在 marker / migration / rollback / hold 层
- **Status:** Frozen candidate for this round
- **Rule:** 当前以下内容仍只能停留在 marker / migration / rollback / hold 层：
  1. `review_group` true-exit 相关 seam
  2. active continuation source switch 相关 seam
  3. final fact owner shift 相关 seam
  4. homepage route / planner-aware route 相关 seam
  5. DB schema rewrite / API core semantics rewrite 相关 seam

### RF-P3.3.14-014 — uplift absorbed 进入 C 的最低条件
- **Status:** Frozen candidate for this round
- **Rule:** 只有当以下条件都成立时，active DB/API baseline uplift 才有资格在 C checkpoint 被吸收：
  1. seam families 的 readiness 证据完整
  2. marker / migration / rollback / hold note 已成套
  3. 不触碰 DB schema rewrite / API core semantics rewrite
  4. 不把 candidate / readiness 当成 active truth
  5. Room 1 显式 pin absorbed decision

---

## 7. `fact_owner_cutover_guardrail_v1`

## 7.1 Room 3 结论
> **无论 B 真实执行还是 C 吸收收口，final fact owner 当前都不能被 serving seam 带着一起切。**

### RF-P3.3.14-015 — 哪些 final fact 当前仍必须以后端为准
- **Status:** Frozen candidate for this round
- **Rule:** 即使 P3.3.14 进入 B / C，以下 final fact 当前仍必须继续以后端 / cloud fact layer 为准：
  1. 有效复习事实
  2. 今日目标完成
  3. 奖励结算 / 账本到账
  4. `check_in / learning_day / streak`
  5. completion / 到账类主反馈

### RF-P3.3.14-016 — 哪些 stronger-ingest path 只允许留在 candidate / readiness
- **Status:** Frozen candidate for this round
- **Rule:** 当前 stronger-ingest path 最多只允许进入：
  1. absorb-readiness-level stronger candidate
  2. 更清楚的 accept / reject / duplicate / progress-candidate / completion-candidate 规则
  3. 更明确的 precondition / postcondition / hold-reason / evidence ownership
  4. 与 widened execution subset 直接绑定的最小 ingest contract
- **Current forbidden layer:**
  1. 直接改 ledger
  2. 直接改 daily goal final state
  3. 直接改 streak / learning_day 最终事实
  4. 直接替代 settlement owner

### RF-P3.3.14-017 — fact-owner overclaim 禁区
- **Status:** Frozen candidate for this round
- **Forbidden claims:**
  1. 本地已接管复习事实
  2. 本地已接管今日完成判定
  3. 本地结果已写回最终事实
  4. 奖励已按新主链路正式结算
  5. streak / learning day 已按新路径主导
  6. completion 已改由本地 stronger path 裁定

---

## 8. `same_round_cleanup_gate_v1`（C checkpoint）

## 8.1 Room 3 结论
> **cleanup 可以被纳入同一轮，但只能作为 C checkpoint 的尾部吸收；它既不是顺手附带，也不是因为合并成 1 轮就自动获得资格。**

### RF-P3.3.14-018 — cleanup 何时才允许在 C checkpoint 被吸收
- **Status:** Frozen candidate for this round
- **Rule:** cleanup / old-path purge 只有当以下条件都成立时，才允许在 C checkpoint 被吸收：
  1. A 已通过
  2. B 的 runtime truth regression / rollback / evidence 包已通过
  3. `review_group` true-exit absorb gate 已通过
  4. DB/API uplift absorbed gate 已通过
  5. no-overclaim / no-major-change / no-fact-owner-shift 仍成立
  6. Room 1 明确 pin “same-round cleanup allowed”

### RF-P3.3.14-019 — 哪些条件不满足时必须 stop at B，不得进入 C
- **Status:** Frozen candidate for this round
- **Rule:** 只要以下任一出现，必须 stop at B：
  1. `review_group` 仍未达到 true-exit absorb gate
  2. uplift absorbed 仍未达到 absorbed gate
  3. rollback / hold / observability 证据包不完整
  4. runtime truth regression 未通过
  5. final fact owner boundary 被触碰
  6. 任一 cleanup 需要靠 DB schema rewrite / API core semantics rewrite 才能成立

### RF-P3.3.14-020 — same-round absorb / cleanup 的回写顺序
- **Status:** Frozen candidate for this round
- **Rule:** 若 C 允许启动，当前推荐的最小回写顺序为：
  1. Room 2 tech note
  2. Room 3 rules note
  3. Room 5 UI preflight
  4. Room 1 pin A/B/C checkpoint judgment
  5. Room 4 执行 + 证据包
  6. Room 1 closeout absorb / cleanup write-back

---

## 9. must-hold / must-escalate

### 9.1 must-hold
以下任一出现，Room 3 判断必须 hold：
1. 首页 `study_default` 被改动
2. active continuation 被 silent reroute
3. `review_group` 被写成 true exit / 已退场 / 可清理 / fallback-only
4. local stronger path 影响 final fact / settlement truth
5. 用户端出现“已切到本地规划 / 新主链路已生效 / `review_group` 已退场 / cutover 已完成 / uplift 已完成 / cleanup 已完成”
6. A / B / C 任一 checkpoint 被误写成 runtime truth
7. 需要改 DB schema / API core semantics 才能继续

### 9.2 must-escalate
以下任一出现，Room 3 判断必须 escalate 给 Room 1 / Room 2 / User：
1. 需要把 `review_group` 从 current owner + retained anchor 改成非 current owner
2. 需要把 active continuation 改到 local path
3. 需要把 active DB/API baseline uplift 写成当前生效
4. 需要把 cleanup / old-path purge 绑成无门槛 bundling
5. 需要用户可见模式切换 / true exit / uplift absorbed / cleanup 宣告
6. 需要修改核心学习链路的业务定义

---

## 10. fact-copy / state guardrails

### 10.1 当前允许的表达方向
当前治理层允许的表达方向：
- final judgment lock
- real cutover execution subset
- true-exit absorb gate
- uplift-absorb gate
- same-round cleanup gate
- retained anchor
- still backend-owned final facts
- not current runtime truth
- not active uplift
- not true exit
- not cleanup completed

### 10.2 当前禁止的 overclaim
以下表达当前轮继续禁止：
1. 已切到本地规划
2. 本地已接管复习
3. `review_group` 已退场
4. 新主链路已生效
5. cutover 已完成
6. 本地结果已写回最终事实
7. active DB/API baseline 已升级
8. uplift 已 absorbed
9. true exit 已开始或已完成
10. 现在已经可以清理旧 path
11. cleanup 已完成
12. 这轮因为合并，所以中间 gate 可省略

---

## 11. Room 1 可直接吸收的判定句

### 11.1 A checkpoint 判定句
> **Room 3 judgment：P3.3.14 当前可以正式启动，但必须先过 A = Final Judgment Lock；在 A 通过之前，fuller-cutover、true-exit、uplift absorbed、cleanup 仍全部只能停留在 judgment / gate / candidate 层，不得写成已生效事实。**

### 11.2 B checkpoint 判定句
> **Room 3 judgment：P3.3.14 的 B = Real Cutover Execution 当前只允许把真实切换继续压在 ReviewPage + 首页 review 承接层的 widened execution subset；首页默认主 route、active continuation source、final fact owner、`review_group` true exit、active DB/API uplift absorbed 与 cleanup 继续不得进入当前真实切换层。**

### 11.3 C checkpoint 判定句
> **Room 3 judgment：P3.3.14 的 C = Same-Round Absorb / Cleanup Closeout 只有在 A 已通过、B 的 runtime truth / regression / rollback / evidence 包也都通过后，才有资格被开启；若 `review_group` true-exit absorb gate、DB/API uplift absorbed gate、或 final fact owner boundary 任何一项未满足，必须 stop at B，不得进入 C。**

### 11.4 fact-boundary 判定句
> **Room 3 judgment：无论 P3.3.14 在 A / B / C 推进到哪一层，有效复习、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端为准；任何 serving seam 或 stronger-ingest 的前进，都不得被写成 final fact owner 已切换。**

### 11.5 cleanup 判定句
> **Room 3 judgment：cleanup 可以被纳入 P3.3.14 同轮尾部，但它必须是 C checkpoint 的最后吸收动作，而不是顺手附带；没有 A/B 两层完整通过与 Room 1 明确 pin，同轮 cleanup 不得启动。**

---

## 12. Room 3 最终一句话

> **P3.3.14 这轮，Room 3 支持把最后几轮合并成 1 个 Final Cutover Program，但这个“合并”只能发生在项目编号层，不能发生在 checkpoint 边界层：A 先锁 judgment，B 再做真实执行，C 最后才允许 absorb / cleanup；任何跳过 A/B 直接宣告切完 / 退完 / 升完 / 清完的做法，都不属于本轮允许范围。**
