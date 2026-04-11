# R2_P3_3_8_Phase3Gate_and_DB_API_Candidate_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** tech gate / DB-API candidate framing / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.8 — Phase 3 Gate / Cutover-Decision + DB/API Candidate Round`

---

## 0. 文档定位

本稿不是：
- Room 4 cutover 执行单
- DB 主文档重写稿
- API 主文档重写稿
- runtime owner shift completed 宣告
- `review_group` 退场公告
- auto-routing / unified planner 上线稿

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.7 的 shadow evidence 收成一轮可被 Room 1 判断是否进入下一层的 Phase 3 gate，并同步给出 DB/API candidate、migration boundary、rollback boundary 与 Major 红线。**

一句话：

> **P3.3.8 应进入 gate / candidate / migration round；不应直接进入 cutover implementation。**

---

## 1. 输入依据与采用口径

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md`
- `Main_updated_2026-04-10_v28.md`
- `STATUS_updated_2026-04-10_v26.md`

### 1.3 Review basis for this round
- `BR-OPP-001_v0.2.9.md`
- `UI_SPEC_v0.2.9.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.7_Claude_res.md`

### 1.4 Room 2 采用口径
1. **本轮服从 Room 1 handoff 指定的 review basis。**
2. **当前 runtime active reality 仍以 Main / STATUS 已 pin 的 active versions 为准。**
3. `BR/UI v0.2.9` 当前按 **review / write-back candidate basis** 使用，不自动冒充已切成 runtime active truth。
4. `DB/API v0.2.1` 当前仍是 active baseline，同时也是本轮 DB/API candidate round 的起点。
5. No silent contract drift。

---

## 2. Room 2 总判断

### 2.1 本轮是否应该前进一步
Room 2 结论：

> **应该前进一步。**

但推进方式必须是：

> **Phase 3 gate / cutover-decision + DB/API candidate round**

而不是：

> **runtime owner shift / ReviewPage local-serving cutover / DB schema 与 API core semantics 直接落地。**

### 2.2 为什么可以前进一步
因为当前已经具备：
1. current runtime truth regression 证据
2. shadow parity evidence
3. mismatch / stop-condition buckets
4. local-serving / routing / fact-ingest 的真实 shadow execution 证据
5. BR / UI 已进入 `v0.2.9` 候选回写层

### 2.3 为什么仍不能直接 cutover
因为当前仍同时成立：
1. ReviewPage current serving truth 继续是 cloud `review_group`
2. 首页 runtime 继续是 `home_word_entry = study_default`
3. final fact / settlement truth 继续以后端为准
4. DB / API active baseline 仍停留在 `v0.2.1`
5. `review_group` 仍是 current runtime owner + compatibility anchor + deprecated candidate，而不是已退场对象

### 2.4 Room 2 一句话立场
> **P3.3.8 该收成“是否足以进入 limited cutover 准备”的 gate；不该收成“现在就切主链路”。**

---

## 3. Q1 — `phase3_gate_decision_v1`

### 3.1 Room 2 结论
> **本轮只建议 Room 1 进入“proceed to Phase-3 candidate framing”，不建议进入 cutover proceed。**

### 3.2 最低通过条件（Minimum proceed conditions）
要让 Room 1 继续往下一层 very narrow gate-driven candidate round 推进，至少要同时满足：

1. **runtime truth guardrails 继续全绿**
   - ReviewPage current serving truth 未被 local 覆写
   - 首页仍保持 `study_default`
   - shadow 结果未泄漏到用户可见层
   - final fact / settlement 未被 local shadow 改写

2. **P3.3.7 shadow evidence 可重复、可归类、可回归**
   - parity compare 可稳定运行
   - mismatch 已能分成 acceptable / hold / escalate
   - stop conditions 已写硬

3. **DB/API candidate round 可以只动 seam framing，不动 current active core semantics**
   - 不要求当前轮立刻改 schema
   - 不要求当前轮立刻改 current endpoint semantics
   - 只要求把下一层 candidate seam 写清楚

4. **`review_group` exit 仍明确 gated**
   - 不能因为 shadow 跑通，就直接写成“可退场”
   - 必须先补 contract / tests / migration / rollback

### 3.3 必须 hold 的情形
出现以下任一项，本轮不得进入下一层：
1. local shadow source 被写成 current ReviewPage truth
2. `review_group` 被写成已退出运行态
3. shadow evidence 进入用户可见层
4. local evidence 直接改 final ledger / daily_goal / streak / learning_day / settlement
5. candidate framing 需要马上改 DB schema 或 API core semantics 才能成立

### 3.4 必须 escalate 的情形
出现以下任一项，默认升级给 Room 1 / User：
1. limited cutover subset 会改变版本范围
2. 需要新的用户可见状态 / 模式声明
3. 需要引入 destructive restore / sync / cleanup bundle
4. 需要把 `review_group` 的 current runtime owner 身份提前改掉

---

## 4. Q2 — `limited_cutover_scope_candidate_v1`

### 4.1 Room 2 结论
> **若未来进入 limited cutover candidate，最小可行切口不该先动 serving source 本身，而应先动“候选 contract + ingest seam + migration markers + rollback hooks”。**

### 4.2 Room 2 推荐的最小切口
Room 2 只建议先讨论以下 4 类：

#### A. local-serving candidate descriptor
把 local-serving 相关对象从“shadow evidence 名字”提升到 **candidate seam 名字**，但仍不变成 current truth：
- `local_due_queue_candidate`
- `local_generated_review_session_candidate`
- `queue_source_candidate_type`
- `serving_eligibility_state`

#### B. fact-ingest candidate seam
把 local evidence 如何进入更强一层 ingest path 的边界写清楚，但仍不直接落地 final fact write：
- accept / reject / duplicate candidate result
- attempt / progress / completion candidate event
- idempotency / de-dup seam
- ingest failure classification

#### C. routing candidate seam
只允许把 future routing 所需的 candidate state / helper naming 写清，不改 runtime route：
- planner-aware entry candidate
- continuation gate candidate
- review-first suggestion candidate
- route-decision provenance marker

#### D. migration / rollback markers
必须先把：
- current runtime truth
- compatibility-only
- deprecated candidate
- shadow-only evidence
- hold / rollback required

这 5 层分清，后面才有 cutover 讨论基础。

### 4.3 本轮不建议作为最小切口的内容
1. 直接让 ReviewPage 改吃 local due queue
2. 直接移除 `GET /me/review-groups/next`
3. 直接让 `POST /review-attempts` 改成本地主写
4. 直接让首页改成 planner-aware / auto-routing
5. 直接把 preview / explanation 升为 committed plan fact

---

## 5. Q3 — `db_api_candidate_round_v1`

### 5.1 Room 2 结论
> **本轮 DB/API 只该冻结到“candidate contract / seam framing / migration note”层，不该冻结到“new active core contract”层。**

### 5.2 DB candidate 清单（建议进入 candidate contract 层）
#### A. 允许进入 candidate contract 的对象
1. `review_queue`
2. `learning_stat_daily`
3. `user_backup_snapshots`
4. `backup_restore_operations`
5. local planner / local queue 的 candidate metadata 语义组
6. fact-ingest candidate event / operation marker
7. migration marker / rollback marker / deprecation marker

#### B. 允许进入 candidate wording 的对象
1. `review_groups` → current runtime owner + compatibility anchor
2. `review_group_items` → current serving payload reality
3. `review_attempts` → current runtime-backed fact input
4. `settlements` / `reward_ledger` → current backend final truth chain

#### C. 当前禁止升格为新 active DB truth 的动作
1. 新增 / 删除核心表并要求本轮落地
2. 改 `review_groups` 与 `review_group_items` 的 current runtime role
3. 让本地表成为 current final fact owner
4. 在没有 migration / rollback 计划时要求 Room 4 实施 schema rewrite

### 5.3 API candidate 清单（建议进入 candidate contract 层）
#### A. 允许进入 candidate contract 的 seam
1. local-serving compare / candidate DTO（internal only / not user contract）
2. fact-ingest candidate payload shape
3. migration / compatibility metadata
4. rollback / hold reason shape
5. debug / QA evidence envelope（internal only）

#### B. 继续保持 current runtime API truth 的端点
1. `GET /me/review-groups/next`
2. `POST /review-attempts`
3. `GET /me/today`
4. `POST /settlements/learning-rounds`
5. `GET /settlements/:sourceEventId`
6. `POST /me/backup`
7. `GET /me/backup/latest`
8. `GET /me/backup/latest/snapshot`

#### C. 当前禁止升格为 active API 变更的动作
1. 改 current endpoint 用途
2. 改 current request / response 核心语义
3. 改 current cloud-first submit chain
4. 引入用户可见 cutover mode API
5. 把 internal shadow / candidate DTO 冒充 public contract

### 5.4 Room 2 当前建议冻结层级
- **DB：candidate contract / migration note / compatibility framing**
- **API：candidate seam / internal DTO / migration note / hold note**
- **不进入：active schema rewrite / active endpoint rewrite**

---

## 6. Q4 — `review_group_exit_gate_v1`

### 6.1 Room 2 结论
> **`review_group` 当前只能进入“exit gate definition”，不能进入“exit approved”。**

### 6.2 进入真实退场判断前，至少还缺 5 组东西
1. **serving parity 足够稳定**
   - local queue candidate 不只“能跑”
   - 还要证明对 continuation / progress / completion / settlement 的影响可控

2. **fact-ingest stronger path 写清**
   - local candidate 如何进入 attempt / progress / completion 的更强路径
   - 哪些仍必须以后端为准

3. **routing candidate 不再依赖 cloud wording**
   - 现在 continuation / helper / CTA 仍围绕 cloud-group 话语体系
   - 未重写前，不适合退 `review_group`

4. **DB/API migration 与 rollback note 成文**
   - 不只是技术想法
   - 需要 write-back 次序、切换条件、回滚条件

5. **Room 1 单独 pin 下一轮 execution gate**
   - 没有新的 `R1 → R4` execution handoff，就不能退 current runtime owner

### 6.3 Room 2 的 gate 句
> **在 serving parity、fact-ingest stronger path、routing rewrite、DB/API migration note、rollback note 与下一轮 execution gate 未齐之前，`review_group` 只能保持 current runtime owner + compatibility anchor，不得进入真实退场。**

---

## 7. Q5 — `fact_settlement_cutover_boundary_v1`

### 7.1 Room 2 结论
> **这一组是 P3.3.8 最不能误切的边界。**

### 7.2 当前绝不能动的东西
1. `daily_goal_status` 最终事实 owner
2. `session_validation_status` 最终事实 owner
3. `reward_settlement_status` 最终事实 owner
4. `learning_day` / `streak` 最终事实 owner
5. `reward_source_events` / `reward_ledger` / `settlements` 后端最终写入链

### 7.3 可以前进一步讨论、但仍只到 candidate 的内容
1. local evidence 的 accept / reject / duplicate 结果如何标准化
2. attempt / progress / completion candidate event 的命名与分层
3. ingest compare 与 stronger ingest path 的衔接条件
4. fact-write precondition / postcondition / hold reason

### 7.4 Room 2 的硬句
> **planner owner shift、serving owner shift、fact / settlement owner shift 必须继续分三层看；P3.3.8 当前只允许讨论前两层的 gate，不允许把第三层误写成一起切。**

---

## 8. Q6 — 哪些动作一旦出现就越界成 DB/API Major 或错误 cutover

以下任一出现，都视为越界：
1. 新增或删除核心表并要求本轮落地
2. 改 current API endpoint 的核心语义
3. 把 `review_group` 写成已退出 current runtime
4. 把 local due queue 写成 current ReviewPage truth
5. 把 local evidence 写成 final fact / settlement write
6. 让首页 runtime route 变成 planner-aware / auto-routing
7. 引入用户可见“已切到本地规划 / 本地已接管复习 / 已自动安排学习路径”的表达
8. 没有 rollback note 就要求 Room 4 执行 cutover

---

## 9. Migration / Rollback Boundary

### 9.1 Room 2 推荐的最小 migration 次序
1. **先写 gate decision 与 hold / escalate 句**
2. **再写 DB/API candidate seam 与 migration note**
3. **再写 BR / UI 对应 guardrails**
4. **最后若 Room 1 单独 pin，再下发 very narrow execution handoff**

### 9.2 Room 2 推荐的 rollback floor
至少要有：
1. rollback trigger
2. rollback target（回到 current cloud-serving truth）
3. rollback owner
4. rollback evidence
5. “本轮未切 runtime truth”的明示语句

### 9.3 本轮不该出现的 migration 写法
1. “本轮已完成迁移”
2. “可直接清理旧 cloud path”
3. “`review_group` 可直接退场”
4. “DB/API 可同步升级为新 active baseline”

---

## 10. Room 2 正式建议给 Room 1 的最小 pin 集合

若 Room 1 要 pin，本轮 Room 2 建议只 pin：

1. **`phase3_gate_decision_v1`**
   - 只 pin proceed / hold / escalate 条件
   - 不 pin cutover 完成

2. **`limited_cutover_scope_candidate_v1`**
   - 只 pin 最小切口：candidate seam / ingest seam / routing seam / migration markers
   - 不 pin serving switch

3. **`db_api_candidate_round_v1`**
   - 只 pin candidate contract 层级与禁止改写项
   - 不 pin schema / endpoint rewrite

4. **`review_group_exit_gate_v1`**
   - 只 pin“还缺什么”
   - 不 pin“现在可退”

5. **`fact_settlement_cutover_boundary_v1`**
   - 只 pin哪些 final facts 绝不能动
   - 继续写死 backend final truth

6. **`phase3_writeback_and_migration_v1`**
   - 只 pin write-back 次序、migration note、rollback floor、hold note
   - 不 pin执行实现

---

## 11. Room 2 一句话结论

> **P3.3.8 现在应该启动，但它只能启动 Phase 3 gate / cutover-decision + DB/API candidate round，不能启动 runtime cutover。Room 2 支持把 shadow evidence 转成 proceed / hold / escalate 与 candidate seam / migration framing；但 current runtime truth、`review_group` 的 current owner 身份、以及 backend final fact / settlement truth，当前都不能动。**
