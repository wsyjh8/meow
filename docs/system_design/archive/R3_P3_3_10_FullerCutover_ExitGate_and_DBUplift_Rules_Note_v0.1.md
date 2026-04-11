# R3_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / fuller cutover judgment / exit-gate / DB-API uplift judgment round
- **Status:** ready for Room 1 review
- **Date:** 2026-04-11
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `Main_updated_2026-04-10_v30.md` + `STATUS_updated_2026-04-10_v28.md`
- **Direct upstream input:** `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.10 当前轮需要回答的 fuller cutover / `review_group` exit-gate / DB-API uplift judgment 问题，收成一份可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API 主文档
- 新 UI 主文档
- Room 4 fuller-cutover 执行单
- runtime owner shift 完成宣告
- `review_group` 真退场公告
- active DB/API baseline uplift 生效稿
- cleanup / old-path purge 方案书

一句话：

> **P3.3.10 是 fuller-cutover judgment / exit-gate / uplift judgment round，不是 full cutover completed round。**

---

## 1. 输入依据

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.11.md`
- `UI_SPEC_v0.3.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v30.md`
- `STATUS_updated_2026-04-10_v28.md`

### 1.4 Prior-round evidence basis
- `P3.3.9_Claude_res.md`

---

## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

因为 P3.3.9 已经不只是 gate / candidate，而是已经形成：
1. first very narrow runtime seam 的真实落地证据
2. `review_group` retained fallback anchor + rollback / hold / observability 成套证据
3. local-serving 与 stronger ingest seam 的第一拍边界
4. BR / UI 主文档对 P3.3.9 的 closeout 吸收基础

如果 P3.3.10 还不回答：
- 下一拍 fuller cutover 能扩大到哪一层
- `review_group` 何时才具备真实退场资格
- DB/API seam 何时才有资格进入 uplift judgment
那么主线程会继续停在“第一刀切了，但第二刀永远不敢判断”的状态。

### 2.2 本轮不能直接写成什么
Room 3 同时明确：

> **P3.3.10 当前不能直接写成 `runtime owner shift completed`、`ReviewPage local-serving full runtime cutover completed`、`review_group` 已退出运行态、`auto-routing` 已开启、`planner merge / unified planner` 已成立、`DB/API active baseline uplift absorbed`。**

### 2.3 Room 3 的一句话立场
> **Room 3 支持 P3.3.10 进入 fuller-cutover judgment / exit-gate / uplift judgment；但这轮只应把“下一拍允许扩大到哪一层、`review_group` 何时才有资格进入真实 exit judgment、以及哪些 DB/API seam 只到 uplift-judgment-ready”写硬，不能把 judgment 结论误写成已生效事实。**

---

## 3. `fuller_cutover_rule_set_v1`

## 3.1 Room 3 结论
> **P3.3.10 当前允许 fuller cutover 前进一步，但只允许从 “ReviewPage non-continuation serving seam” 扩大到 “continuity-adjacent、仍不碰首页 route 与 final fact owner”的 very narrow next subset。**

### RF-P3.3.10-001 — fuller cutover 当前允许前进一步的层
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.10 当前最稳的 fuller-cutover 扩大层，只允许前进到：
  1. **ReviewPage continuity-adjacent serving subset**
  2. **与其强绑定的 source-neutral helper / summary / state contract**
  3. **更稳的 retained-anchor fallback / rollback seam**
  4. **更清楚的 stronger ingest candidate handoff**
- **Current forbidden layer:**
  1. 首页 `study_default` route 切换
  2. active continuation path 全量切换到 local
  3. `review_group` 真退场
  4. final fact owner shift
  5. active DB/API baseline uplift 生效
- **Why frozen candidate:** 这比 P3.3.9 前进了一小层，但仍保持在“当前最容易 rollback、最不容易污染 final fact”的判断层。

### RF-P3.3.10-002 — fuller cutover 仍不得越过 `cutover_vs_fact_owner_boundary_v2`
- **Status:** Frozen candidate for this round
- **Rule:** fuller cutover 允许扩大 serving subset，但不得顺手扩大到：
  - 有效复习事实 owner
  - 今日目标完成 owner
  - 奖励结算 / 账本到账 owner
  - `check_in / learning_day / streak` owner
- **Canonical meaning:**  
  cutover 扩大层级 ≠ final fact owner 扩大层级。
- **Why frozen candidate:** 这是当前 round 最核心的防误伤边界。

### RF-P3.3.10-003 — fuller cutover judgment 不等于 fuller cutover execution-ready
- **Status:** Frozen candidate for this round
- **Rule:** 即使本轮给出“下一拍可扩大到某个 subset”的判断，也只代表：
  - **具备进入下一层 execution judgment 的资格**
  - 不代表本轮已经足够下发 Room 4 执行单
- **Why frozen candidate:** P3.3.10 当前仍属于 judgment / gate / candidate 收口层。

---

## 4. `review_group_exit_gate_v2`

## 4.1 Room 3 结论
> **`review_group` 当前仍不能进入真实退场；P3.3.10 最多只允许把它从 retained-anchor 进一步推进到 “exit-candidate judgment-ready” 的条件层。**

### RF-P3.3.10-004 — `review_group` 当前仍必须保持 current owner + retained anchor
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.10 当前轮，`review_group` 仍必须继续保持：
  1. **current runtime serving owner**
  2. **retained fallback anchor**
  3. **compatibility anchor**
  4. **deprecated candidate**
- **Must not do:** 不得把 retained anchor 提前写成 fallback-only，更不得写成“现在可退场”。
- **Why frozen candidate:** 当前仍缺少真实退场所需的完整合同、测试、文档与运行态证据。

### RF-P3.3.10-005 — 进入真实 exit judgment 前，至少还要满足 5 类前置条件
- **Status:** Frozen candidate for this round
- **Rule:** `review_group` 只有在以下 5 类条件同时具备时，才有资格从 retained anchor 进入真实 exit judgment：
  1. **contract 条件**：fuller-cutover subset、fact-owner boundary、retained-anchor transition、uplift judgment 与 write-back order 都已被 Room 1 pin 成下一层最小合同
  2. **test 条件**：continuity-adjacent subset 的 regression / rollback / hold / observability 长期稳定，无 must-hold mismatch 未清
  3. **doc 条件**：BR / UI / DB / API / TEST 的 exit 影响范围、rollback 目标、hold note 与 no-overclaim 文案已同步齐
  4. **runtime 条件**：active continuation、completion gating、settlement trigger 与 rollback target 都已有非模糊替代路径
  5. **boundary 条件**：final fact / settlement owner 仍清楚写在后端，且无 silent owner shift
- **Canonical meaning:** 只有条件齐了，才“可以讨论 exit”；不是“现在可退”。

### RF-P3.3.10-006 — retained anchor → exit candidate 的过渡，只能先缩窄 fallback，不得先删 current owner
- **Status:** Frozen candidate for this round
- **Rule:** 若未来进入 transition，允许优先讨论：
  - fallback / rollback 何时可以缩窄
  - 哪些路径仍保留 `review_group`
  - 哪些路径已不再需要 `review_group`

  但当前 **不允许**：
  - 先删掉 current owner 身份
  - 先把 `review_group` 降成 purely historical object
- **Why frozen candidate:** 退场顺序不能倒置。

### RF-P3.3.10-007 — 以下路径当前仍必须继续显式依赖 `review_group`
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.10 当前轮，以下路径仍必须继续显式依赖 `review_group`：
  1. active continuation identity
  2. completion gating
  3. settlement trigger
  4. rollback target
  5. non-cutover / non-upgraded sessions baseline path
- **Why frozen candidate:** 这些路径一旦抽空，exit-gate judgment 就会变成假问题。

---

## 5. `cutover_vs_fact_owner_boundary_v2`

## 5.1 Room 3 结论
> **本轮允许 stronger ingest candidate 再前进一步，但仍然只到“uplift judgment-ready / stronger-path judgment-ready”，不允许进入 active fact owner。**

### RF-P3.3.10-008 — 哪些 final fact 继续必须以后端为准
- **Status:** Frozen candidate for this round
- **Rule:** 即使 fuller cutover judgment 前进一步，以下 final fact 当前仍必须继续以后端 / cloud fact layer 为准：
  1. 有效复习事实
  2. 今日目标完成
  3. 奖励结算 / 账本到账
  4. `check_in / learning_day / streak`
- **Must not do:** 不得把 local stronger ingest candidate 写成这些最终事实可由本地裁定。

### RF-P3.3.10-009 — stronger ingest candidate 当前允许前进一步的层
- **Status:** Frozen candidate for this round
- **Rule:** 本轮若要前进一步，stronger ingest candidate 最多只允许进入：
  1. **uplift-judgment-ready seam**
  2. **更清楚的 accept / reject / duplicate 规则**
  3. **更明确的 rollback / hold / evidence ownership**
  4. **与 first/fuller serving subset 直接绑定的最小 ingest contract**
- **Current forbidden layer:**
  1. 直接改 reward ledger
  2. 直接改 daily-goal completion
  3. 直接改 streak / learning_day 最终事实
  4. 直接替代 settlement owner
- **Why frozen candidate:** 这是“更强 candidate”，不是“已切 fact owner”。

### RF-P3.3.10-010 — overclaim 禁区继续保持
- **Status:** Frozen candidate for this round
- **Forbidden claims:**
  1. 本地已接管复习事实
  2. 本地已接管今日完成判定
  3. 本地结果已写回最终事实
  4. 奖励已按新主链路正式结算
  5. streak / learning day 已按新路径主导
- **Why frozen candidate:** 这些仍属于 fact-owner shift overclaim。

---

## 6. `db_api_uplift_judgment_v1`

## 6.1 Room 3 结论
> **从规则层看，本轮可以开始判断哪些 seam 已 uplift-judgment-ready；但 uplift judgment 仍不得写成 active uplift、生效 uplift、或 core semantics rewrite。**

### RF-P3.3.10-011 — candidate seam 与 uplift-ready seam 必须继续分层
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.10 当前必须继续显式区分：
  1. **candidate seam**
  2. **uplift-judgment-ready seam**
  3. **active uplift absorbed**
- **Canonical meaning:**  
  uplift-ready 只表示“有资格讨论是否升级 active baseline”，  
  不表示“已经升级”。

### RF-P3.3.10-012 — 哪些 seam 当前最多可升到 uplift-judgment-ready
- **Status:** Frozen candidate for this round
- **Rule:** 当前最多只允许与 fuller cutover 直接绑定的以下 seam 进入 uplift-judgment-ready 判断：
  1. serving source descriptor seam
  2. retained-anchor / fallback posture seam
  3. stronger ingest path minimal seam
  4. rollback / hold / observability seam
  5. source-neutral state / helper / summary contract seam
- **Current forbidden layer:**
  1. DB schema rewrite
  2. API core semantics rewrite
  3. active baseline uplift 生效
  4. “以新主链路现实重写整个 DB/API 主文档”
- **Why frozen candidate:** 本轮是 uplift judgment，不是 uplift absorbed。

### RF-P3.3.10-013 — 以下结论当前只能算 uplift judgment，不得升格为 runtime truth
- **Status:** Frozen candidate for this round
- **Rule:** 以下结论当前只能停在 judgment 层：
  1. 某个 seam 已足够讨论 uplift
  2. 某个 rollback floor 已足够支撑下一轮
  3. 某个 helper / state contract 已 source-neutral enough
  4. 某个 stronger ingest seam 已更清楚
- **Must not do:** 不得把这些写成 active DB/API baseline 已改变、endpoint meaning 已更新、或 runtime truth 已同步替换。

---

## 7. `retained_anchor_to_exit_transition_v1`

## 7.1 Room 3 结论
> **本轮允许推进 retained anchor → exit candidate 的 transition judgment，但只允许写“何时才能转”，不允许写“现在开始转”。**

### RF-P3.3.10-014 — rollback target 当前仍必须继续指向 `review_group`
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.10 当前轮，rollback target 仍必须继续明确指向：
  - **cloud `review_group` current runtime path**
- **Why frozen candidate:** 当前尚无第二个同等级 runtime truth owner 可以安全兜底。

### RF-P3.3.10-015 — 只有当 retained-anchor 依赖路径被逐条替代后，rollback / fallback 才允许缩窄
- **Status:** Frozen candidate for this round
- **Rule:** fallback / rollback 只有在以下事情逐条完成后，才有资格讨论缩窄：
  1. active continuation 的替代 contract 已明示
  2. completion gating 的替代 contract 已明示
  3. settlement trigger 的替代 contract 已明示
  4. non-cutover baseline path 已明示
  5. rollback 仍有可用 target
- **Canonical meaning:**  
  先替代，再缩窄；不能先缩窄再补路径。

### RF-P3.3.10-016 — 以下 stop-condition 继续必须保持
- **Status:** Frozen candidate for this round
- **Rule:** 即使 fuller cutover judgment 前进一步，以下 stop-condition 当前仍必须继续保持：
  1. 首页 `study_default` 被触碰
  2. active continuation 被 silent reroute
  3. `review_group` 被写成已退场 / fallback-only / 可清理
  4. local stronger path 影响 final fact / settlement
  5. DB schema / API core semantics 被要求改动
  6. 用户可见 overclaim 出现
- **Why frozen candidate:** 这些仍然是当前轮的硬刹车。

---

## 8. `phase4_writeback_order_v1`

## 8.1 Room 3 结论
> **本轮若要继续推进，必须先把 judgment、candidate、runtime truth 三层回写顺序写硬；否则极易再次发生 silent contract drift。**

### RF-P3.3.10-017 — 本轮推荐 write-back 顺序
- **Status:** Frozen candidate for this round
- **Rule:** Room 3 当前推荐的最小 write-back 顺序为：
  1. **Room 2 tech judgment note**
  2. **Room 3 rules note**
  3. **Room 5 UI preflight**
  4. **Room 1 absorb / pin**
  5. 如获准，再进入 Room 4 fuller-cutover execution handoff
- **Why frozen candidate:** 先把 judgment 边界写硬，再让 execution judgment 成为可能。

### RF-P3.3.10-018 — 哪些只能写成 judgment，哪些可以写成 execution-ready candidate
- **Status:** Frozen candidate for this round
- **Rule:** 当前只能写成 **judgment** 的包括：
  1. fuller cutover 是否值得扩大
  2. `review_group` 是否具备真实 exit 资格
  3. DB/API seam 是否够资格讨论 uplift
  4. stronger ingest path 是否值得再前进一步

  当前最多只允许写成 **execution-ready candidate** 的包括：
  1. very narrow next subset 候选
  2. rollback / hold / observability floor
  3. source-neutral helper / summary / state migration prep
- **Current forbidden layer:** 不得写成 runtime truth 已更改、`review_group` 已真退场、或 active DB/API uplift 已 absorbed。

### RF-P3.3.10-019 — migration / rollback / hold-note 继续必须成套存在
- **Status:** Frozen candidate for this round
- **Rule:** 本轮若继续推进，至少必须继续补齐：
  1. **migration note**
  2. **rollback note**
  3. **hold note**
  4. **no-overclaim statement**
- **Why frozen candidate:** 这是 fuller-cutover judgment 能否进入下一层执行判断的最低治理门槛。

---

## 9. must-hold / must-escalate

### 9.1 must-hold
以下任一出现，Room 3 判断必须 hold：
1. 首页 `study_default` 被改动
2. active continuation 被 silent reroute
3. `review_group` 被写成 fallback-only / 已退场 / 可清理
4. local stronger path 影响 final fact / settlement truth
5. 用户端出现“已切到本地规划 / 新主链路已生效 / review_group 已退场 / cutover 已完成”
6. fuller cutover judgment 被误写成 full cutover completed

### 9.2 must-escalate
以下任一出现，Room 3 判断必须 escalate 给 Room 1 / Room 2：
1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 reward / settlement owner
4. 需要把 `review_group` 从 retained anchor 改成非 current owner
5. 需要把 active continuation 改到 local path
6. 需要把 active DB/API baseline uplift 写成当前生效
7. 需要用户可见模式切换 / cutover 宣告
8. 需要把 cleanup / old-path purge 绑进当前轮

---

## 10. fact-copy / helper / state guardrails

### 10.1 当前允许的表达方向
当前治理层允许的表达方向：
- fuller-cutover judgment
- exit-gate judgment
- uplift judgment
- retained anchor
- exit candidate
- uplift-ready seam
- not current runtime truth
- still backend-owned final facts

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

---

## 11. 当前继续保持 Pending

1. full cutover completed
2. runtime owner shift completed
3. `review_group` 真退场
4. active DB/API baseline uplift 生效
5. cleanup / old-path purge
6. auto-routing runtime
7. unified planner / planner merge
8. final fact owner shift
9. DB schema rewrite
10. API core semantics rewrite
11. 用户可见 owner-shift / cutover / exit 宣告

---

## 12. 可直接给 Room 1 的判定句

### 12.1 fuller-cutover 判定句
> **Room 3 judgment：P3.3.10 当前允许 fuller cutover 前进一步，但只允许从 ReviewPage non-continuation serving seam 扩大到 continuity-adjacent、仍不碰首页 route / active continuation path / final fact owner 的 very narrow next subset；本轮仍属于 judgment / candidate 收口，不属于 full cutover execution。**

### 12.2 exit-gate 判定句
> **Room 3 judgment：`review_group` 当前仍必须继续保持 current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate；只有 contract / test / doc / runtime / boundary 五类前置条件都齐，才有资格从 retained anchor 进入真实 exit judgment。**

### 12.3 fact-owner 判定句
> **Room 3 judgment：即使 fuller cutover judgment 前进一步，有效复习、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端为准；local stronger ingest path 最多只允许进入 uplift-judgment-ready / stronger-path-ready，不得升格为 fact owner。**

### 12.4 uplift-judgment 判定句
> **Room 3 judgment：P3.3.10 当前可以判断哪些 seam 已 uplift-judgment-ready，但 uplift judgment 只说明“有资格讨论 active baseline uplift”，不说明“active DB/API baseline 已升级”。**

### 12.5 must-hold / must-escalate 判定句
> **Room 3 judgment：凡触碰首页 `study_default`、active continuation、`review_group` current owner posture、final fact / settlement truth、active DB/API baseline、或用户可见 overclaim 的情况，一律不得按“可带着走的 fuller-cutover judgement 差异”处理；其中涉及 DB schema / API core semantics / settlement owner / cleanup / 用户可见 cutover 宣告的，必须升级，不得在本轮内自行吸收。**

---

## 13. Room 3 最终一句话

> **P3.3.10 这轮，Room 3 支持把 P3.3.9 的 first-cutover 再推进一小层，但这层仍然只能是 fuller-cutover / exit-gate / uplift 的 judgment；它回答的是“下一拍能扩大到哪、退场资格何时成立、哪些 seam 只够 uplift judgment”，不是“现在已经切完 / 退完 / 升完”。**
