# R2_P3_3_9_FirstVeryNarrowCutover_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** first-cutover preflight / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.9 — First Very Narrow Cutover Round`

---

## 0. 文档定位

本稿不是：
- Room 4 cutover 执行单
- DB 主文档重写稿
- API 主文档重写稿
- runtime owner shift 完成宣告
- `review_group` 退场公告
- full cutover / cleanup / baseline uplift 方案书

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.9 收成一轮“第一拍 very narrow cutover preflight”：给出最小 first-cutover subset、runtime truth switch boundary、`review_group` retained-anchor 姿态、DB/API first-cutover-ready seams、rollback / hold / observability floor，以及本轮绝不能越界成 full cutover / DB-API major / cleanup bundling 的红线。**

一句话：

> **P3.3.9 应进入 first very narrow cutover preflight；但只适合切一个极窄的 Review serving subset，不适合把 fact owner、`review_group` 退场、cleanup 与 active DB/API uplift 一起拉进来。**

---

## 1. 输入依据与采用口径

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md`
- `Main_updated_2026-04-10_v29.md`
- `STATUS_updated_2026-04-10_v27.md`

### 1.3 Review basis for this round
- `BR-OPP-001_v0.2.10.md`
- `UI_SPEC_v0.3.0.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.8_Claude_res.md`

### 1.4 Room 2 采用口径
1. **本轮服从 Room 1 handoff 指定的 review basis。**
2. **当前 runtime active reality 仍以 Main / STATUS 已 pin 的 active versions 为准。**
3. `BR v0.2.10` 与 `UI v0.3.0` 当前按 review / write-back candidate basis 使用，不自动冒充已切成 runtime active truth。
4. `DB/API v0.2.1` 当前仍是 active baseline，同时也是本轮 first-cutover preflight 的起点。
5. No silent contract drift。

---

## 2. Room 2 总判断

### 2.1 本轮是否应该前进一步
Room 2 结论：

> **应该前进一步。**

但推进方式必须是：

> **First Very Narrow Cutover Preflight**

而不是：

> **runtime owner shift completed / ReviewPage local-serving runtime cutover completed / `review_group` exit / DB schema rewrite / API core semantics rewrite / cleanup bundling / active DB/API baseline uplift**

### 2.2 为什么现在值得进入 first-cutover preflight
因为当前已经具备：
1. Phase 2 / Phase 3 的 shadow evidence、parity compare、mismatch 与 stop-condition 桶
2. `review_group` exit gate 已被明确 gated
3. fact / settlement boundary 已继续写硬
4. UI migration / copy neutralization / forbidden claims 已进入主文档候选
5. DB/API seam candidate / migration / rollback / hold-note 已完成上一轮 framing

### 2.3 为什么仍不能直接 full cutover
因为当前仍同时成立：
1. ReviewPage current serving truth 继续是 cloud `review_group`
2. 首页 runtime 继续是 `home_word_entry = study_default`
3. final fact / settlement truth 继续以后端为准
4. DB / API active baseline 仍停留在 `v0.2.1`
5. `review_group` 仍是 current runtime owner + compatibility anchor + deprecated candidate，而不是可直接清理对象

### 2.4 Room 2 一句话立场
> **P3.3.9 该收成“第一拍只切一个极窄 serving subset 的 preflight”；不该收成“现在可以一口气完成 owner shift / exit / cleanup / uplift”。**

---

## 3. Q1 — `first_cutover_subset_v1`

### 3.1 Room 2 结论
> **最值得先切的 first-cutover subset，不是 helper / copy，也不是 final fact ingest，而是：**
>
> **ReviewPage 中“非 continuation 的 very narrow serving subset”，在严格 retained-anchor 与 rollback 条件下，允许 local-serving candidate 局部接管“候选队列提供”，但不接管 final fact / settlement。**

### 3.2 Room 2 推荐的最小切口
Room 2 推荐的 first-cutover subset 只包含以下 4 点：

#### A. 切换对象
只考虑：
- **ReviewPage 的 non-continuation serving subset**
- 仅限 “当前不存在 active `review_group` continuation，且满足更窄 eligibility / stop-condition / hold-note 的情形”

#### B. 允许切的层
允许 very narrow 切换的，仅是：
- queue source selection 的一小段 runtime seam
- local-serving candidate 对 item stream / next-review payload 的 very narrow 提供能力
- retained-anchor + rollback hooks + observability

#### C. 暂时不切的层
当前仍不切：
- final fact owner
- settlement owner
- reward ledger owner
- daily-goal final state owner
- streak / learning_day final fact owner
- 首页入口 route
- active continuation route

#### D. 为什么这个切口最稳
因为它同时满足：
1. 它是真正的 runtime seam，不只是 copy / state neutralization
2. 它又没有一脚踩进 final fact owner shift
3. 它允许 `review_group` 继续保留 fallback anchor 身份
4. 回滚目标明确：回到 current cloud-serving truth
5. 它最不容易把 serving cutover 被误解成 reward / streak / daily goal 也跟着切了

### 3.3 当前不推荐的 first-cutover 切口
以下都不建议作为第一拍：
1. 首页 route / planner-aware entry
2. active continuation source switch
3. final fact ingest stronger-path 直接升成写最终事实
4. `review_group` exit / cleanup
5. DB schema rewrite / endpoint semantics rewrite

---

## 4. Q2 — `runtime_truth_switch_boundary_v1`

### 4.1 Room 2 结论
> **本轮若允许真的切 runtime truth，只允许 very narrow 地切“ReviewPage 某个 non-continuation serving subset 的 queue-source seam”；其它 runtime truths 继续保持不变。**

### 4.2 Room 2 推荐“允许切”的唯一真相层
当前只建议考虑切：
- `review_queue_serving_source` 的 very narrow subset

并且必须满足：
1. 只发生在 ReviewPage
2. 只发生在非 continuation 路径
3. 只发生在满足 local-serving candidate readiness 的 very narrow subset
4. 只发生在 fallback / rollback / hold-note / observability 都已具备时

### 4.3 Room 2 推荐“继续不切”的 runtime truths
以下全部继续保持 current runtime truth：
1. 首页 `home_word_entry = study_default`
2. active continuation 独立承接
3. `review_group` 作为 current runtime owner 的主路径事实
4. Review summary / completion / settlement final fact
5. reward / ledger / daily_goal / streak / learning_day 的最终事实
6. 用户可见的 owner-shift / local-serving enabled / cutover completed 类模式声明

### 4.4 Room 2 的硬句
> **serving truth 可以 very narrow 局部切，但 current route truth、continuation truth、final fact truth 当前都不能一起切。**

---

## 5. Q3 — `review_group_retained_anchor_v1`

### 5.1 Room 2 结论
> **在第一轮 very narrow cutover 里，`review_group` 不应继续被写成“所有情况都是 current owner”，但也绝不能被写成“已退场”；最稳的姿态是：**
>
> **`retained fallback anchor + continuation owner + rollback target`**

### 5.2 Room 2 推荐的 retained-anchor 姿态
在 P3.3.9 第一拍，`review_group` 建议同时承担三层角色：

#### A. continuation owner
- 只要存在 active continuation，仍继续走 `review_group`
- 不允许被 local-serving subset 接管

#### B. retained fallback anchor
- first-cutover subset 一旦进入 hold / rollback / stop-condition，就立即回到 `review_group`
- `review_group` 继续是 current cloud-serving truth 的保底锚点

#### C. compatibility anchor
- 所有 migration / hold-note / rollback-note / QA evidence 仍以 `review_group` 为兼容参考基线

### 5.3 当前明确不接受的 `review_group` 写法
1. `review_group` 已退场
2. `review_group` 已经只剩历史兼容引用
3. `review_group` 已不再是 runtime truth 任何部分的 owner
4. 本轮可以清理旧 cloud path

---

## 6. Q4 — `fact_owner_guardrail_v1`

### 6.1 Room 2 结论
> **serving subset 的 first cutover 当前只允许把 local-serving 结果推进到“stronger ingest candidate / pre-final-fact seam”，不允许推进到 final fact owner switch。**

### 6.2 Room 2 推荐的 stronger ingest 路径
本轮若要前进一步，只建议写硬到：
1. accept / reject / duplicate 的 candidate result 标准化
2. attempt / progress / completion candidate event 的命名与分层
3. ingest precondition / postcondition / hold reason
4. idempotency / de-dup / retry 的 seam floor
5. local-serving subset 与 backend fact layer 的 stronger ingest handoff 条件

### 6.3 继续保持 cloud final truth 的 final facts
以下最终事实当前继续必须以后端 / cloud fact layer 为准：
1. 有效复习事实
2. 今日目标完成
3. 奖励结算 / 账本到账
4. `check_in / learning_day / streak`
5. completion 是否进入 final settlement
6. 任何会触发对外主奖励或主状态变化的最终结果

### 6.4 Room 2 的硬句
> **first cutover 可以切 very narrow serving subset，但 local-serving 产出当前仍只能走 stronger ingest candidate，不得越权成 final fact owner。**

---

## 7. Q5 — `db_api_cutover_candidate_v2`

### 7.1 Room 2 结论
> **本轮允许把少数 DB/API seam 从“candidate framing”提升到“first-cutover-ready seam”，但仍不允许改 active baseline、schema、或 current endpoint core semantics。**

### 7.2 Room 2 推荐可升到 first-cutover-ready 的 seam 类型
当前只建议提升以下 4 类：

#### A. queue-source seam descriptor
- source type
- source owner layer
- candidate / retained-anchor / rollback-target 标记
- eligibility / hold reason / stop-condition bucket

#### B. local-serving item-stream handoff seam
- very narrow subset 下 local item stream 如何被 ReviewPage 消费
- 但不改 current public endpoint semantics

#### C. stronger ingest candidate seam
- accept / reject / duplicate
- attempt / progress / completion candidate event
- ingest failure classification
- idempotency / de-dup hooks

#### D. rollback / hold / observability seam
- rollback trigger
- rollback target
- hold note payload
- compare evidence / QA evidence / debug evidence fields

### 7.3 本轮继续只允许停留在 candidate / migration note 的内容
1. DB schema rewrite
2. endpoint core semantics rewrite
3. active DB/API baseline uplift
4. `review_group` 真实 exit 对应的删除 / 清理动作
5. planner-aware 首页 route 对应的 API/DB contract 扩张

### 7.4 Room 2 的硬句
> **P3.3.9 可以让少数 seam 进入 first-cutover-ready，但当前仍不允许把 `DB/API v0.2.1` 升成 owner-shift reality baseline。**

---

## 8. Q6 — `rollback_holdnote_and_observability_v1`

### 8.1 Room 2 结论
> **本轮若要进入真正 first-cutover execution，rollback floor、hold note、stop conditions 与 observability 不是附属件，而是进入执行层的硬前置。**

### 8.2 Room 2 推荐的 rollback floor
至少必须有：
1. rollback trigger
2. rollback target（回到 `review_group` cloud-serving truth）
3. rollback owner
4. rollback evidence
5. rollback 完成后的 runtime truth 明示语句
6. “本轮未切 final fact owner” 的明示语句

### 8.3 Room 2 推荐的 hold note 最低结构
至少要有：
1. hold reason
2. affected subset
3. current fallback path
4. user-visible truth remains unchanged 说明
5. next action / owner

### 8.4 Room 2 推荐的 stop conditions
出现以下任一项，默认必须 hold 或 rollback：
1. local subset 被写成 current ReviewPage full truth
2. active continuation 被误切到 local path
3. local evidence 直接改 final ledger / daily_goal / streak / learning_day / settlement
4. 首页 route 被 silent 改成 planner-aware / auto-routing
5. 用户端出现 local-serving enabled / owner shift completed / review_group exited / cutover completed 类 overclaim
6. 需要改 DB schema 或 API core semantics 才能让本轮 subset 成立
7. 回滚路径不存在或不可验证
8. compare / QA / debug evidence 无法稳定复现

### 8.5 Room 2 推荐的 observability floor
至少要补：
1. subset hit / miss evidence
2. retained-anchor engaged evidence
3. rollback engaged evidence
4. hold engaged evidence
5. compare mismatch bucket evidence
6. no-final-fact-owner-switch assertion evidence

---

## 9. 哪些动作一旦出现就越界成 full cutover / DB-API Major / cleanup bundling

以下任一出现，都视为越界：
1. 把 local-serving subset 写成 ReviewPage 全量 current truth
2. 把 `review_group` 写成已退场或可直接清理
3. 一轮内同时做 serving cutover + fact owner shift
4. 一轮内同时做 cutover + cleanup
5. 一轮内同时做 cutover + active DB/API baseline uplift
6. 改 DB schema
7. 改 current endpoint core semantics
8. 开启首页 planner-aware / auto-routing runtime
9. 引入用户可见 cutover-completed / owner-shift-completed 宣告
10. 没有 rollback floor 就要求 Room 4 进入 cutover execution

---

## 10. Room 2 推荐进入层 / 不进入层

### 10.1 推荐进入层（Room 1 当前可 pin）
1. **`first_cutover_subset_v1`**
   - 只 pin ReviewPage non-continuation serving subset 的 very narrow candidate cutover
   - 不 pin全量 ReviewPage serving switch

2. **`runtime_truth_switch_boundary_v1`**
   - 只 pin queue-source seam 的局部切换
   - 不 pin首页 route / continuation / final fact switch

3. **`review_group_retained_anchor_v1`**
   - 只 pin retained fallback anchor + continuation owner + rollback target
   - 不 pin exit / cleanup

4. **`fact_owner_guardrail_v1`**
   - 只 pin stronger ingest candidate seam 与 cloud final truth guardrails
   - 不 pinfinal fact owner shift

5. **`db_api_cutover_candidate_v2`**
   - 只 pin first-cutover-ready seam families
   - 不 pin schema / endpoint rewrite / active baseline uplift

6. **`rollback_holdnote_and_observability_v1`**
   - 只 pin rollback floor / hold note / stop conditions / observability floor
   - 不 pin execution completed

### 10.2 明确不进入层
1. full cutover
2. `review_group` 真实退场
3. cleanup bundling
4. active DB/API baseline uplift
5. final fact owner shift
6. planner-aware 首页 runtime
7. unified planner / planner merge
8. 用户可见 owner-shift / cutover 宣告

---

## 11. Room 2 正式建议给 Room 1 的最小 pin 集合

若 Room 1 要 pin，本轮 Room 2 建议只 pin：

1. **一个 very narrow first-cutover subset**
   - ReviewPage non-continuation serving subset

2. **一个局部 runtime truth switch boundary**
   - 只切 queue-source seam

3. **一个 retained-anchor posture**
   - `review_group` = retained fallback anchor + continuation owner + rollback target

4. **一套 fact-owner guardrails**
   - final fact / settlement truth 继续写死 cloud owner

5. **一组 first-cutover-ready DB/API seam families**
   - 只到 seam / marker / evidence / rollback floor 层

6. **一套 rollback / hold / stop-condition / observability floor**
   - 作为 first execution 的进入门

---

## 12. Room 2 一句话结论

> **P3.3.9 现在应该启动，但它只能启动 first very narrow cutover preflight。Room 2 支持把一个极窄的 ReviewPage non-continuation serving subset 推进到 first-cutover-ready；但 current 首页 route、active continuation、`review_group` 退场、final fact / settlement truth、以及 active DB/API baseline，当前都不能跟着一起切。**
