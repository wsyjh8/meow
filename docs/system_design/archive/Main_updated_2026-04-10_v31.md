# Main.md
**Canonical Runtime Name:** `OPP-001_MAIN.md`  
**Project:** 背单词喵喵 App  
**Owner:** Room 1  
**Status:** active  
**Type:** 推进层 SSOT / SSOT Main Thread

---

## 0) Meta

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.10 Closed / Next-Focus Pending
- **Last updated:** 2026-04-11
- **Incremental update note:** 本版以 `Main_updated_2026-04-10_v30.md` 为 base，仅增量吸收 `P3.3.10 closeout` 与 `BR / UI v0.2.12 / v0.3.2` runtime-baseline update；未被本轮触发的既有主线程内容保持不动。
- **Current versions (runtime active SSOT):**
  - **Governance / Runtime protocol**
    - ORG: `ORG_v0.3.1.md`
    - Project Rules Master: `PROJECT_RULES_MASTER_v0.3.1.md`
    - Room 1: `room1_v0.2.0.md`
    - Room 2: `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
    - Room 3: `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
    - Room 4: `ROOM04_治理版_v0.2`
    - Room 5: `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
    - BR / Rules: `BR-OPP-001_v0.2.12.md` — active BR baseline
  - **Product / PRD**
    - 项目介绍书: `背单词养猫app项目介绍书_v0.1.1_P3.1.md`
    - 主机制 PRD: `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
    - 副机制设计稿: `背单词喵喵app_副机制设计稿_v_0.md`
    - 副机制 PRD: `背单词喵喵app_副机制prd_v_0.md`
  - **Numbers**
    - 副机制数值草案: `背单词喵喵app_副机制数值草案_v_0.md`
  - **DB / API**
    - DB 设计草案: `背单词喵喵app_DB设计草案_v0.2.1.md`
    - API 设计草案: `背单词喵喵app_API设计草案_v0.2.1.md`
  - **UI SPEC**
    - `UI_SPEC_v0.3.2.md` — active UI baseline
  - **PLAN / TEST**
    - `plan_v0.1.2.md` — retained implementation entry / historical reference

- **Latest delivery / review / absorption inputs**
  - `BR-OPP-001_v0.2.11.md`
  - `UI_SPEC_v0.3.1.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`
  - `R2_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Tech_Note_v0.1.md`
  - `R3_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_10_FullerCutover_ExitGate_and_DBUplift_UI_Preflight_v0.1.md`
  - `R1_to_R4_P3_3_10_Execution_Handoff_v0.1.md`
  - `BR-OPP-001_v0.2.12.md` / `UI_SPEC_v0.3.2.md` — ready for Room 1 runtime-baseline update
  - user 最新转述：Room 4 已完成 `P3.3.10` 的开发 / 实施
  - `Main_updated_2026-04-10_v30.md`
  - `STATUS_updated_2026-04-10_v28.md`

- **Links / Entrances**
  - ORG: `ORG_v0.3.1.md`
  - Room 1: `room1_v0.2.0.md`
  - Room 2: `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
  - Room 3: `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
  - Room 4: `ROOM04_治理版_v0.2`
  - Room 5: `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
  - BR: `BR-OPP-001_v0.2.12.md`
  - DB: `背单词喵喵app_DB设计草案_v0.2.1.md`
  - API: `背单词喵喵app_API设计草案_v0.2.1.md`
  - UI: `UI_SPEC_v0.3.2.md`

## 1) One-liner

面向**容易半途放弃背单词、但对可爱陪伴与轻养成有偏好的学习用户**，在**日常背词、复习、签到和碎片时间学习**场景下，解决**难开始、难坚持、反馈弱、长期留存低**的问题，通过**学习主机制 + 喵喵副机制承接**，带来**更高的打开率、完成率、复习率与长期陪伴式学习体验**；当前 `P3.1 — Local Progress + Cloud Backup` 的代码与 BR / DB / API / UI 文档已完成本轮对齐，Room 1 已将 runtime baseline 从旧 `v0.1.x` 正式提升到 `v0.2.1`；在此基础上，`P3.3` 已整体关单，`P3.3.2`、`P3.3.3`、`P3.3.4` 已分别把复习规划、preview 与 stronger bridge 推进到当前 very narrow minimal-contract 层。进一步地，`P3.3.5` 已完成 **Phase 0 / Compatibility-Prep**，`P3.3.6` 已完成 **Compatibility Contract v1 / Shadow-Entry Prep**，`P3.3.7` 已完成 **Phase 2 / Limited Execution / Shadow Mode**，`P3.3.8` 已完成 **Phase 3 / Gate-Driven Candidate Execution + Migration Prep**，而 `P3.3.9` 则把 owner-shift 方向推进到 **First Very Narrow Cutover**：第一拍只在 ReviewPage 的 **non-continuation serving subset** 上切入极窄 source seam，同时继续保留 `review_group` 作为 current runtime owner + retained fallback anchor，首页继续保持 `study_default`，active continuation 继续独立承接且不得 silent reroute，final fact / settlement truth 继续以后端为准；在此基础上，`P3.3.10` 已进一步把这条线推进到 **Fuller Cutover / review_group Exit-Gate / DB-API Uplift Judgment** 的 very narrow subset：允许把扩大方向判断到 ReviewPage continuity-adjacent serving-adapter family，并把 `review_group` retained-anchor → exit-candidate 的条件、DB/API uplift-judgment-ready seam families、以及 judgment / candidate / runtime-truth 的分层回写顺序写硬，但本轮仍未把 full cutover completed、`review_group` 真退场、active DB/API baseline uplift absorbed、final fact owner shift 或 cleanup 写成当前事实。当前 Room 1 可将 `P3.3.10` 判定为 **current-round closed**，并将 active BR / UI runtime baselines 正式升级到 `BR-OPP-001_v0.2.12.md` 与 `UI_SPEC_v0.3.2.md`。

## 2) Scope Snapshot

### 当前已完成
1. **P1：主机制最小可运行闭环**
2. **P2：副机制 MVP 承接闭环**
3. **Option A：Production Persistence Hardening**
4. **Option A.1：Post-Option-A Hardening**
5. **Option B（B1）：Visual Polish & Content Polish 第一轮**
6. **Option B2（B2-1 / B2-2 / B2-3）**
7. **Option C — Main Mechanism Enhancement**
8. **P3 — Main Mechanism Deepening**
9. **P3.1 — Local Progress + Cloud Backup**
   - local-first + manual backup / restore 边界已收口
   - `daily goal` 设置、手动上传、手动下载到本机三功能已交付
   - BR / DB / API / UI 文档已追平当前代码现实
   - Room 1 已完成 runtime-baseline update
10. **P3.3 — Home Entry + FSRS 4-Button + Review Planning（Overall Closed）**
   - 首页“背单词”主入口已接入
   - Study / Review 已接入 4 按钮 rating input
   - `P3.3.1` 已冻结最终两字中文词面：不认识 / 模糊 / 记得 / 秒答
   - `previewDurations` 已明确 deferred，不进入当前 active contract
   - ReviewPage FSRS bridge 已收口到 controlled best-effort，并具备 dev / test 可观察性
   - 一轮 UI / 文案 / 测试补强已完成
11. **P3.3.2 — Review Planning Minimal Contract（Closed）**
   - `session_entry_policy_v1` 已冻结：`home_word_entry = study_default`
   - active `review_group` continuation 继续高优先，但只能独立承接，不得 silent reroute / 吞掉默认 `/study` 入口
   - `planner_owner_split_v1` 已冻结：ReviewPage 继续以 cloud `review_group` 作为 serving truth owner，本地 FSRS 继续作为 device-side scheduling owner
   - ReviewPage 顺序继续保持 `cloud submit first → local side-effect second → local failure non-blocking`
   - 本轮未进入 auto-routing / unified planner / 完整 review planning contract
   - 本轮未触碰 DB schema / API 核心语义 / `review_group` 最小合同 / planner owner 基线
12. **P3.3.3 — Review Planning Contract v1 / SRS Boundary Round（Closed）**
   - `review_readiness_policy_v1` 已按最小状态层落地：`ready_now / not_ready_now / next_group_eligible / temporarily_unservable`
   - 页面级 readiness truth 继续以 cloud aggregate / review-serving layer 为准；local FSRS 继续只作为 scheduling candidate input / device-side scheduling owner
   - `review_priority_policy_v1` 已冻结 hierarchy-only：continuation > cloud-confirmed due review > cloud-confirmed high-priority review > new words > session
   - `review_group_generation_policy_v1` 已冻结最小边界：generation owner 在 cloud review-serving layer；active group 未完成前不进入 next-group 可服务路径；`next_group_eligible` ≠ `next_group_generated`
   - `schedule_source_contract_v1` 已冻结最小 truth split：cloud `review_group` = serving outputs；local FSRS = scheduling candidate signals
   - `previewDurations` 在 P3.3.3 继续 deferred；本轮未进入 full priority scoring / exact group size / unified planner / auto-routing / 完整 review planning product
   - Room 4 closeout 已明确本轮 accept / closeout 倾向，且未触碰 DB schema / API core semantics / `review_group` 最小合同 / `planner_owner_split_v1`
13. **P3.3.4 — Preview Re-entry + Stronger Bridge Round（Closed）**
   - `preview_durations_reentry_contract_v1` 已按 very narrow minimal contract 落地：source = local FSRS preview candidate；只允许 StudyPage 显示；只作为 estimated / reference-only secondary hint；必须带“预计 / 仅供参考”语气
   - ReviewPage / 首页继续不显示 preview；preview 不进入 readiness / priority / generation / route decision / settlement / reward / group completion truth，也不进入 active API / DB contract
   - `reviewpage_stronger_bridge_contract_v1` 已按最小 stronger contract 落地：pre-submit ensure、post-cloud-submit local ensure + apply、observable fallback、minimal repair path
   - ReviewPage bridge 继续保持 `cloud submit first + local failure non-blocking`；不得回滚 cloud submit、不得阻断 next item / group completion / settlement、不得改变 cloud truth owner、不得升格为 planner merge / unified planner
   - 本轮未触碰 DB schema / API core semantics / planner owner；也未将 preview explanation system、ReviewPage preview re-entry、mixed / auto-routing 拉入当前合同
14. **P3.3.5 — Local Planner Owner Shift / Cloud Backup Rebase Round（Closed）**
   - 本轮完成的是 **Phase 0 / Compatibility-Prep**，不是 runtime owner shift；current runtime truth 继续保持 cloud review-serving layer，未发生 local-serving cutover
   - `local primary planner owner` 已被接受为 **future target-state candidate**，但只冻结在 target-state / staged migration 合同层，未被写成 current runtime truth
   - `review_group` 已进入 compatibility / deprecation path 候选；当前仍不得被写成“已退出运行态”或“已由 local due queue 接管”
   - `backup / restore / sync success` 三层语义已按最小安全边界收口：manual backup / restore、no real-time sync、no auto merge、restore apply 才改变目标设备 runtime truth
   - shadow / parity / regression prep、adapter seam / feature-flag prep、以及 future target-state candidate 与 current runtime truth 的 fact-copy guardrails 已进入本轮实施吸收范围
   - 本轮未触碰 DB schema / API core semantics / reward-settlement owner / routing runtime；也未把 local planner / preview / explanation 写成 committed plan fact

15. **P3.3.6 — Local-Serving Compatibility Contract / Shadow-Mode Entry Round（Closed）**
   - 本轮完成的是 **Compatibility Contract v1 + Shadow-Entry Prep**，不是 runtime owner shift；current runtime truth 继续保持 cloud `review_group` 为 ReviewPage serving truth，首页继续保持 `study_default`
   - `local_serving_candidate_contract_v1` 已冻结到 candidate / compatibility / shadow parity 层；`review_group` 已被写硬为 current owner + compatibility anchor + deprecated candidate
   - `fact_settlement_ingest_contract_candidate_v1` 已冻结到 ingest candidate / evidence 边界；planner / serving owner shift 不自动带出 fact / settlement owner shift
   - `session_entry_and_routing_compat_v1`、`deprecation_markers_and_writeback_plan_v1` 与 `shadow_parity_test_strategy_v1` 已收成可被开发、维护与测试引用的最小合同
   - 本轮未发生 ReviewPage local-serving cutover、`review_group` 退场、auto-routing runtime、planner merge / unified planner，也未触碰 DB schema / API core semantics

16. **P3.3.7 — Local-Serving Limited Execution / Shadow Mode Round（Closed）**
   - 本轮完成的是 **Phase 2 / Limited Execution / Shadow Mode**，不是 cutover；local-serving candidate、fact/settlement ingest candidate、routing shadow candidate 已进入 dev / flag / QA evidence 层真实运行
   - `local_due_queue_candidate`、`local_generated_review_session_candidate`、fact ingest compare 与 routing shadow compare 已开始与 current cloud `review_group` 路径做 parity 对照，但结果只形成 shadow evidence，不升格为 runtime fact
   - `review_group` 当前继续是 current runtime serving owner，同时也是 shadow baseline；final fact / settlement truth 继续以后端为准
   - current runtime truth 继续保持：首页仍 `study_default`，active continuation 继续独立承接且不得 silent reroute，ReviewPage current serving truth 继续围绕 cloud `review_group`
   - 本轮未发生 runtime owner shift completed、ReviewPage local-serving runtime cutover、`review_group` 退出运行态、auto-routing runtime、planner merge / unified planner，也未触碰 DB schema / API core semantics


17. **P3.3.8 — Phase 3 Gate / Cutover-Decision + DB/API Candidate Round（Closed）**
   - 本轮完成的是 **Phase 3 / Gate-Driven Candidate Execution + Migration Prep**，不是 cutover；它把 `P3.3.7` 的 shadow evidence 收成了 proceed / hold / revise / escalate 的 gate 层，以及 candidate seam / migration / rollback / hold-note 的 very narrow subset
   - `phase3_gate_decision_v1`、`limited_cutover_scope_candidate_v1`、`db_api_candidate_round_v1`、`review_group_exit_gate_v1`、`fact_settlement_cutover_boundary_v1` 与 `phase3_writeback_and_migration_v1` 已进入当前轮实施与吸收范围
   - `review_group` 当前继续保持 current runtime serving owner + compatibility anchor + deprecated candidate；它仍未进入真实退场判断，更未退出运行态
   - DB / API 当前只进入 candidate seam / migration marker / rollback floor / hold-note / write-back order 层；active DB / API baseline 继续保持 `v0.2.1`
   - final fact / settlement truth 继续以后端为准；local-serving / routing / ingest 继续只到 candidate / migration / gate 层，不得被写成 current runtime truth
   - 本轮未发生 runtime owner shift completed、ReviewPage local-serving runtime cutover、`review_group` 退场、auto-routing runtime、planner merge / unified planner，也未触碰 DB schema / API core semantics


18. **P3.3.9 — First Very Narrow Cutover Round（Closed）**
   - 本轮完成的是 **First Very Narrow Cutover**，不是 full cutover；第一拍只允许切 **ReviewPage 的 non-continuation serving subset**
   - 真正进入切换的只是一小段 `queue-source / serving-adapter seam`；首页 `study_default`、active continuation 承接方式、`review_group` 真退场、final fact / settlement owner 与 active DB/API baseline uplift 都继续保持不变
   - `review_group` 当前继续保持 **current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate** 的复合姿态；本轮任何 fallback / rollback 目标仍回到 cloud `review_group` truth
   - stronger ingest candidate 只进入最小 evidence path；reward / ledger / daily_goal / streak / learning_day 等最终事实继续以后端为准
   - rollback / hold / stop-condition / observability floor 已作为 first cutover 的必备配套被一并吸收；本轮未发生 runtime owner shift completed、ReviewPage local-serving full cutover、`review_group` 退场、cleanup bundling、active DB/API uplift、DB schema rewrite 或 API core semantics rewrite

19. **P3.3.10 — Fuller Cutover / `review_group` Exit-Gate / DB-API Uplift Judgment Round（Closed）**
   - 本轮完成的是 **judgment-driven candidate execution**，不是 full cutover；允许讨论并固化的扩大方向只到 **ReviewPage continuity-adjacent serving-adapter family**，不进入 full ReviewPage serving switch
   - `review_group` 当前继续保持 **current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate**；本轮只把 retained-anchor → exit-candidate 的资格条件、rollback target、fallback scope 与 still-dependent paths 写硬，不进入真实退场
   - DB / API 当前只进入 **uplift-judgment-ready seam families / seam map / marker / migration note / rollback floor / hold note** 层；active DB/API baseline 继续保持 `v0.2.1`，不进入 schema rewrite / endpoint core semantics rewrite
   - final fact / settlement truth 继续以后端为准；stronger-ingest candidate 继续只到 boundary assertion / stronger-path-ready 层，不得冒充 fact owner
   - 本轮未发生 runtime owner shift completed、ReviewPage local-serving full runtime cutover、`review_group` 真退场、active DB/API uplift absorbed、homepage route switch、active continuation source switch、final fact owner shift 或 cleanup / old-path purge；Room 1 当前只吸收其 judgment / candidate / migration very narrow subset，并将 active BR / UI baseline 提升到 `v0.2.12 / v0.3.2`

### 当前仍不做
- runtime owner shift completed
- ReviewPage local-serving runtime cutover
- `review_group` 直接删出运行态
- full sync / real-time sync / multi-master merge
- background sync
- partial restore / snapshot picker
- delete backup / clear local / destructive actions bundle
- 多猫系统
- 好友互访 / 社交分享 / 排行榜
- 抽卡
- 强社交 Widget
- 复杂剧情任务
- 重 RPG / 重游戏玩法
- 复杂词书市场
- AI 教学 / AI 个性化主路径
- 高级桌面管理端
- mixed / auto-routing runtime contract
- unified planner / planner merge
- unified Study / Review page
- 完整 SRS / 完整复习调度算法
- ReviewPage preview re-entry
- 完整 preview explanation system

### 推进层 SSOT
- `Main.md`
- `STATUS.md`

## 3) Assumption Log

### A-OPP-001-001
- **Hypothesis:** 当前 MVP 采用“主机制优先，副机制承接”的推进顺序，能以更低复杂度跑通产品核心闭环。
- **Status:** active

### A-OPP-001-016
- **Hypothesis:** P3 可以在 contract-first deepening 的方式下完成当前轮主机制深化，并在不把 candidate contracts 偷写成 active truth、也不引入大重构的前提下正式 close。
- **Status:** passed on 2026-04-05

### A-OPP-001-017
- **Hypothesis:** 在不引入复杂实时同步、不把云端升级为运行态真相源的前提下，P3.1 可以先用 `local-first + simple backup` 的方式补齐本地进度与手动云备份能力。
- **Status:** passed on 2026-04-06

### A-OPP-001-018
- **Hypothesis:** P3.1 第一拍默认只做到 Phase 0–3（local truth + snapshot export + upload + latest backup status + 最小入口）即可形成可关单范围；Phase 4 restore 应保持 gated，只有 Room 1 单独 pin 后才可吸收到 active 范围。
- **Status:** superseded by direct-scope user decision on 2026-04-07

### A-OPP-001-019
- **Hypothesis:** User 直接拍板加入的三按钮 / 三功能，可以按一轮独立的 P3.1 delta round 收口，而不需要把 P3.1 整体扩写成 full sync platform。
- **Pass criteria:** Room 1 能正式接受 delta round close，同时守住 manual only / warning first / no fake sync / no history rewrite / no destructive bundle
- **Status:** passed on 2026-04-07

### A-OPP-001-020
- **Hypothesis:** 当 BR / DB / API / UI 都完成 reconciled baseline 并明确达到“ready for Room 1 review / runtime-baseline update”后，Room 1 可以把 P3.1 从“delta closed / baseline sync pending”推进到“overall closed / baseline updated”。
- **Pass criteria:** Room 1 能统一 pin 新 active versions，且不再需要以旧 `v0.1.x` 作为 runtime reference 继续推进
- **Status:** passed on 2026-04-09

### A-OPP-001-021
- **Hypothesis:** `P3.3.1` 可以在不扩主契约、不改 DB / API 核心语义、不改 `review_group` 最小合同与 planner owner 的前提下，完成 P3.3 的收尾 / 体验补强并把 P3.3 整体推进到 overall closed。
- **Pass criteria:** 最终词面冻结；`previewDurations` 正式 deferred；ReviewPage bridge 收口到 controlled best-effort；UI / copy / test polish 完成；Room 4 明确未触碰核心契约。
- **Status:** passed on 2026-04-10

---


### A-OPP-001-022
- **Hypothesis:** `P3.3.2` 可以在不进入 auto-routing / unified planner、不改 DB / API 核心语义、不改 `review_group` 最小合同与 planner owner 基线的前提下，把 `session_entry_policy_v1` 与 `planner_owner_split_v1` 收成稳定可执行事实。
- **Pass criteria:** 首页“背单词”仍保持 `study_default`；active `review_group` continuation 若被承接也不吞默认入口；ReviewPage 继续表现 `cloud-first + local side-effect`；页面假事实文案被清理；Room 4 未发生核心合同越界。
- **Status:** passed on 2026-04-10


### A-OPP-001-023
- **Hypothesis:** `P3.3.3` 可以在不进入完整 SRS / full priority scoring / exact group size contract / unified planner / auto-routing 的前提下，把 `review_readiness_policy_v1`、`review_priority_policy_v1`、`review_group_generation_policy_v1` 与 `schedule_source_contract_v1` 收成稳定可引用的 very narrow minimal contract。
- **Pass criteria:** 页面级 readiness truth 继续以后端 serving layer 为准；priority 只冻结 hierarchy；generation 只冻结 owner + gating + non-overclaim；local FSRS 继续只作为 scheduling candidate input；`previewDurations` 继续 deferred；Room 4 未发生核心合同越界。
- **Status:** passed on 2026-04-10

### A-OPP-001-024
- **Hypothesis:** `P3.3.4` 可以在不进入 planner merge / unified planner、不改 DB / API core semantics、不改变 cloud truth owner 的前提下，把 `preview_durations_reentry_contract_v1` 与 `reviewpage_stronger_bridge_contract_v1` 收成 very narrow, user-visible but non-overclaiming contract。
- **Pass criteria:** StudyPage only preview 以 estimated hint 形态落地；ReviewPage / 首页不显示 preview；preview 不升格为计划事实；ReviewPage bridge 收紧到 stronger-but-still-non-blocking；Room 4 未发生核心合同越界。
- **Status:** passed on 2026-04-10


### A-OPP-001-025
- **Hypothesis:** `P3.3.5` 可以在不发生 runtime owner shift、不改 DB / API core semantics、且不把 future target-state candidate 写成 current runtime truth 的前提下，先完成 `backup / restore / cross-device semantics rewrite + compatibility / deprecation prep + shadow / parity / regression prep` 这一 very narrow Phase 0 / Compatibility-Prep。
- **Pass criteria:** current runtime truth 保持不变；backup / restore / sync success 三层语义被正确区分；`review_group` 进入 compatibility / deprecation path 候选而未被误删；文案禁区未越界；Room 4 未发生 Major contract drift。
- **Status:** passed on 2026-04-10



### A-OPP-001-026
- **Hypothesis:** `P3.3.6` 可以在不进入 runtime owner shift / ReviewPage local-serving cutover / `review_group` 退场 / DB-API core rewrite 的前提下，把 `local_serving_candidate_contract_v1`、`review_group_compatibility_posture_v1`、`fact_settlement_ingest_contract_candidate_v1`、`session_entry_and_routing_compat_v1`、`deprecation_markers_and_writeback_plan_v1` 与 `shadow_parity_test_strategy_v1` 收成稳定可引用的 `Compatibility Contract v1`。
- **Pass criteria:** current runtime truth 保持不变；`review_group` 三层姿态写硬；local-serving candidate 只停留在 candidate / compatibility / shadow 层；fact / settlement ingest 只停留在 evidence candidate；routing compatibility 与 shadow marker 落地；Room 4 未发生核心合同越界。
- **Status:** passed on 2026-04-10

### A-OPP-001-027
- **Hypothesis:** `P3.3.7` 可以在不进入 runtime owner shift / local-serving cutover / `review_group` runtime-exit / auto-routing runtime / DB-API core rewrite 的前提下，完成 `Phase 2 / Limited Execution / Shadow Mode` 的 very narrow subset，并产出可供未来 Phase 3 判断使用的 shadow evidence。
- **Pass criteria:** local-serving candidate、fact ingest candidate、routing shadow candidate 进入 dev / flag / QA evidence 层真实运行；`review_group` 继续作为 current runtime owner + shadow baseline；final fact / settlement truth 继续以后端为准；mismatch / stop-condition / parity evidence 集固定；Room 4 未发生核心合同越界。
- **Status:** passed on 2026-04-10


### A-OPP-001-028
- **Hypothesis:** `P3.3.8` 可以在不进入 runtime owner shift / local-serving cutover / `review_group` 退场 / DB-API core rewrite 的前提下，把 `Phase 3 gate / cutover-decision + DB/API candidate round` 收成可吸收的 very narrow candidate-execution + migration-prep subset。
- **Pass criteria:** gate 结果只停在 proceed / hold / revise / escalate；`review_group` current owner + compatibility anchor + deprecated candidate 姿态保持不变；DB / API 只进入 candidate seam / migration / rollback / hold-note 层；final fact / settlement truth 继续以后端为准；Room 4 未发生核心合同越界。
- **Status:** passed on 2026-04-10


### A-OPP-001-029
- **Hypothesis:** `P3.3.9` 可以在不触碰首页 `study_default`、不改 active continuation 承接方式、不切 final fact / settlement owner、不让 `review_group` 退场、且不做 cleanup / active DB-API baseline uplift 的前提下，完成第一拍 **very narrow cutover**。
- **Pass criteria:** first-cutover subset 只落在 ReviewPage non-continuation serving seam；`review_group` 继续保持 current owner + retained fallback anchor；rollback / hold / stop-condition / observability 成套存在；local evidence 不直接改 reward / ledger / daily_goal / streak / learning_day 最终事实；Room 4 未发生核心合同越界。
- **Status:** passed on 2026-04-10


## 4) Evidence Log

### E-OPP-001-061
- **Finding:** `R2_P3_1_LocalProgress_CloudBackup_Preflight_v0.1.1.md` 已明确结论：P3.1 当前应先新建 technical preflight，暂不直接改 active DB / API baseline。
- **Source:** P3.1 technical preflight
- **Date:** 2026-04-06

### E-OPP-001-062
- **Finding:** `R3_P3_1_LocalProgress_CloudBackup_Rules_Freeze_Note_v0.1.1.md` 已把 P3.1 收成 rules freeze input / review basis，并明确当前 active BR 仍然是 `BR-OPP-001_v0.1.7.md`。
- **Source:** P3.1 rules freeze note
- **Date:** 2026-04-06

### E-OPP-001-063
- **Finding:** `UI_SPEC_P3_1_LocalProgress_CloudBackup_v0.1.1.md` 已把 P3.1 的设置页 / 我的页 backup 能力翻译成 UI / UX 输入，并明确在 Room 1 吸收到 Main / STATUS 前不会自动替代 runtime baseline。
- **Source:** P3.1 UI / UX input
- **Date:** 2026-04-06

### E-OPP-001-064
- **Finding:** `背单词养猫app项目介绍书_v0.1.1_P3.1.md` 与 `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` 已把 P3.1 的 `local-first + simple cloud backup` 立场回写到产品入口与主机制 PRD。
- **Source:** 项目介绍书 / 主机制 PRD P3.1 sync patch
- **Date:** 2026-04-06

### E-OPP-001-065
- **Finding:** `R4_P3_1_LocalProgress_CloudBackup_Implementation_Plan_v0.1.1.md` 已把 P3.1 的默认执行路径写成 `local-first + backup-first + contract-gated execution`。
- **Source:** P3.1 implementation planning
- **Date:** 2026-04-06

### E-OPP-001-068
- **Finding:** `R1_P3_1_DirectScopePin_3Buttons_Handoff_Pack_v0.1.md` 已把“上传进度到云端 / 从云端下载进度到本机 / 设置每日学习单词数量”三功能正式拉进当前 P3.1 范围。
- **Source:** Room 1 direct-scope pin handoff
- **Date:** 2026-04-06

### E-OPP-001-069
- **Finding:** `R2_P3_1_DirectScopePin_Delta_Tech_Note_v0.1.1.md` 已把三功能收成最小技术 delta，明确 manual upload / manual download、latest snapshot apply first-shot、daily_goal 当天即时生效但不回溯历史日。
- **Source:** Room 2 delta tech note
- **Date:** 2026-04-06

### E-OPP-001-070
- **Finding:** `R3_P3_1_DirectScopePin_Delta_Rules_Note_v0.1.1.md` 已写硬 upload success / download success / restore success 三层语义边界、restore warning、daily_goal 当天生效与历史不回溯、destructive actions 不进本轮。
- **Source:** Room 3 delta rules note
- **Date:** 2026-04-06

### E-OPP-001-071
- **Finding:** `UI_SPEC_P3_1_DirectScopePin_Delta_v0.1.1.md` 已把三按钮 direct-scope delta 翻译成专项 UI / UX 输入，强调设置页 / 我的页承接、warning / confirm / success / failure / retry 状态矩阵，以及不把本轮做成同步系统。
- **Source:** Room 5 delta UI spec
- **Date:** 2026-04-07

### E-OPP-001-072
- **Finding:** `R4_P3_1_DirectScopePin_Delta_Execution_Note_v0.1.1.md` 已把三功能收成专项 delta execution note，并按 C→B→A（daily goal → upload → download）顺序组织实现与验证。
- **Source:** Room 4 delta execution note
- **Date:** 2026-04-07

### E-OPP-001-073
- **Finding:** `回p3_1_delta_p3.md` 已明确回传：P3.1 Delta Phase 3 完成，330 Flutter tests pass（25 new），0 analyze errors，且三功能均 enabled。
- **Source:** Room 4 delta close input
- **Date:** 2026-04-07

### E-OPP-001-074
- **Finding:** `BR-OPP-001_v0.2.1.md` 已形成 full merged BR baseline candidate，状态为 ready for Room 1 review / runtime-baseline update。
- **Source:** Room 3 reconciled BR baseline
- **Date:** 2026-04-08

### E-OPP-001-075
- **Finding:** `背单词喵喵app_DB设计草案_v0.2.1.md` 已形成 reconciled DB baseline candidate，明确吸收 code-truth reality + candidate contracts，并 ready for Room 1 review。
- **Source:** Room 2 reconciled DB baseline
- **Date:** 2026-04-08

### E-OPP-001-076
- **Finding:** `背单词喵喵app_API设计草案_v0.2.1.md` 已形成 reconciled API baseline candidate，明确吸收 code-truth reality + candidate contracts，并 ready for Room 1 review。
- **Source:** Room 2 reconciled API baseline
- **Date:** 2026-04-08

### E-OPP-001-077
- **Finding:** `UI_SPEC_v0.2.1.md` 已作为 user-approved absorption patch / ready for Room 1 runtime-baseline update，能作为新的 UI baseline candidate。
- **Source:** Room 5 absorbed UI baseline
- **Date:** 2026-04-09

### E-OPP-001-078
- **Finding:** 新一轮治理层文件已齐：`ORG_v0.3.1.md`、`ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`、`ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`、`ROOM04_治理版_v0.2`、`ROOM05_ROLE_CARD_UI_UX_v0.2.1`，足够支撑 runtime active versions 升级。
- **Source:** Governance file set
- **Date:** 2026-04-09

---

### E-OPP-001-079
- **Finding:** `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md` 已把 post-P3.1 的下一方向正式命名为 `P3.3 Preflight / Scope Pin`，并将 user 直接拍板的 3 项内容收进主线程：首页“背单词”入口、FSRS 4 按钮接入、复习规划进入第一轮 preflight。
- **Source:** Room 1 P3.3 scope pin handoff
- **Date:** 2026-04-09

### E-OPP-001-080
- **Finding:** `UI_SPEC_P3_3_HomeEntry_and_4Button_UI_Preflight_v0.1.1.md` 已把首页“背单词”主入口、学习/复习页 4 按钮布局、两字中文候选与页面承接关系收成 UI preflight，并明确当前仍不得把最终词面或最终业务语义写死。
- **Source:** Room 5 P3.3 UI preflight
- **Date:** 2026-04-09

### E-OPP-001-081
- **Finding:** `R3_P3_3_FSRS_4Button_ReviewPlanning_Rules_Note_v0.1.md` 已冻结 P3.3 本轮最小规则边界：4 按钮本质是 rating input、必须与 FSRS 四档保持单调映射；“两字中文要求”冻结，但最终词面仍保持 candidate；“开始做复习规划”只冻结到 preflight 边界。
- **Source:** Room 3 P3.3 rules note
- **Date:** 2026-04-09

### E-OPP-001-082
- **Finding:** Room 4 的 P3.3 第一拍材料已证明：本轮实现只触碰首页主入口、Study/Review 4 按钮接入、最小 submit / throttle / bridge；并明确 **API schema 不扩展、`review_group` 仍是 ReviewPage 云端 truth layer、云端 binary mapping 保持不变**。
- **Source:** `R4_P3_3_Impact_Map_v0.1.md` + `R4_P3_3_Submit_Flow_Draft_v0.1.md`
- **Date:** 2026-04-10

### E-OPP-001-083
- **Finding:** Room 4 的 P3.3 测试草案已覆盖：首页入口可见与跳转、Study/Review 4 按钮顺序、submit throttle、review_group continuation、FSRS bridge failure non-blocking、以及“不误报已掌握 / 已完成 / 奖励到账”等 false-success 边界。
- **Source:** `R4_P3_3_Test_Draft_v0.1.md`
- **Date:** 2026-04-10




### E-OPP-001-084
- **Finding:** `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md` 已将 P3.3 第二拍正式命名为 `P3.3.1 — 收尾 / 体验补强`，并把最终词面 freeze、`previewDurations` 是否纳入、ReviewPage FSRS bridge 风险清理、以及 UI / 文案 / 测试补强收成统一执行入口。
- **Source:** Room 1 P3.3.1 scope pin
- **Date:** 2026-04-10

### E-OPP-001-085
- **Finding:** `R1_to_R4_P3_3_1_Execution_Handoff_v0.1.md` 已将 P3.3.1 执行边界写硬：最终词面冻结为“不认识 / 模糊 / 记得 / 秒答”；`previewDurations` deferred；ReviewPage bridge 只清到 controlled best-effort；本轮重点是 UI / copy / test polish，而不是扩主契约。
- **Source:** Room 1 → Room 4 P3.3.1 execution handoff
- **Date:** 2026-04-10

### E-OPP-001-086
- **Finding:** `R2_P3_3_1_PreviewDurations_and_FSRS_Bridge_Tech_Note_v0.1.md` 与 `R3_P3_3_1_Final_Wording_and_Bridge_Rules_Note_v0.1.md` 已共同收口：`previewDurations` 当前继续 deferred；ReviewPage 继续 cloud-first；本地 ensure / init 只允许作为 idempotent 补强；bridge failure 继续 non-blocking，但必须对 dev / test 可观察。
- **Source:** Room 2 / Room 3 P3.3.1 closeout inputs
- **Date:** 2026-04-10

### E-OPP-001-087
- **Finding:** `P3.3.1_Claude_res.md` 已回传 Room 4 的 closeout delivery：`FsrsRatingButtons` 已统一为 2×2 布局与固定顺序；ReviewPage bridge 已从 silent best-effort 提升为 controlled best-effort（含 `initCardForWord()` 与 debug fallback）；CANDIDATE 注释已清；未触碰 DB schema / API schema / `review_group` 合同 / planner owner，且 `flutter analyze lib/` 为 0 errors / 0 warnings（仅保留既有 `_summary` unused warning 说明）。
- **Source:** Room 4 P3.3.1 delivery pack
- **Date:** 2026-04-10


### E-OPP-001-088
- **Finding:** `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md` 已把 post-P3.3.2 的下一推进主题正式命名为 `P3.3.3 — Review Planning Contract v1 / SRS Boundary Round`，并明确本轮先走 contract gate，再由 Room 1 判断是否进入 very narrow execution layer。
- **Source:** P3.3.3 scope pin / unified handoff entry
- **Date:** 2026-04-10

### E-OPP-001-089
- **Finding:** `R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md` 明确建议本轮只进入 `review_readiness_policy_v1` / `review_priority_policy_v1` / `review_group_generation_policy_v1` / `schedule_source_contract_v1` 的 very narrow minimal contract，并继续保持 `previewDurations` deferred。
- **Source:** P3.3.3 Room 2 tech note
- **Date:** 2026-04-10

### E-OPP-001-090
- **Finding:** `R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1.md` 已把 P3.3.3 的最小业务合同收口为：cloud serving truth 优先、4 个最小 readiness 语义、hierarchy-only priority、generation owner + gating 边界，以及 `previewDurations` continued defer。
- **Source:** P3.3.3 Room 3 rules note
- **Date:** 2026-04-10

### E-OPP-001-091
- **Finding:** `UI_SPEC_P3_3_3_ReviewPlanningContractV1_UI_Preflight_v0.1.md` 已把 P3.3.3 的页面承接边界翻译为最小 UI contract：首页与 ReviewPage 只承接 readiness / priority / generation / source split 的窄层表达，不把完整 planner / auto-routing / preview explanation 写成既成事实。
- **Source:** P3.3.3 Room 5 UI preflight
- **Date:** 2026-04-10

### E-OPP-001-092
- **Finding:** `R1_to_R4_P3_3_3_Execution_Handoff_v0.1.md` 已把 P3.3.3 统一收口为可执行的 very narrow delivery：最小合同落地 + 假事实清理 + 测试补强 + 不越界回写草案。
- **Source:** P3.3.3 unified execution handoff
- **Date:** 2026-04-10

### E-OPP-001-093
- **Finding:** `P3.3.3_Claude_res.md` 明确回传 P3.3.3 本轮交付已完成：4 组最小合同已落地，`previewDurations` 继续 deferred，`flutter test` 19/19 与联跑 58/58 通过，`flutter analyze` 无 issue，且 accept / closeout 倾向成立。
- **Source:** P3.3.3 Room 4 delivery package
- **Date:** 2026-04-10

### E-OPP-001-094
- **Finding:** `BR-OPP-001_v0.2.5.md` 与 `UI_SPEC_v0.2.5.md` 均已把 P3.3.3 closeout 作为增量主文档候选吸收完成，并明确标注 ready for Room 1 runtime-baseline update。
- **Source:** BR/UI merged write-back candidates
- **Date:** 2026-04-10

### E-OPP-001-095
- **Finding:** `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md` 已将 post-P3.3.3 的下一推进主题正式命名为 `P3.3.4 — Preview Re-entry + Stronger Bridge Round`，并明确本轮先走 contract gate，再由 Room 1 判断是否进入 very narrow execution layer。
- **Source:** P3.3.4 scope pin / unified handoff entry
- **Date:** 2026-04-10

### E-OPP-001-096
- **Finding:** `R2_P3_3_4_PreviewReentry_and_StrongerBridge_Tech_Note_v0.1.md` 明确建议：preview 若回归，source 只能是 local FSRS preview candidate，且当前最稳只允许 StudyPage only；ReviewPage stronger bridge 只允许收紧到 stronger ensure / observability / failure handling floor / minimal repair path。
- **Source:** Room 2 P3.3.4 technical framing
- **Date:** 2026-04-10

### E-OPP-001-097
- **Finding:** `R3_P3_3_4_PreviewReentry_and_StrongerBridge_Rules_Note_v0.1.md` 已将 P3.3.4 的业务语义写硬：preview 只能作为 estimated hint / candidate explanation 回归，不得升格为计划事实；stronger bridge 只能收紧为更强的非阻断技术语义。
- **Source:** Room 3 P3.3.4 rules note
- **Date:** 2026-04-10

### E-OPP-001-098
- **Finding:** `UI_SPEC_P3_3_4_PreviewReentry_and_StrongerBridge_UI_Preflight_v0.1.md` 已将 UI 侧最小合同收口为：preview 当前只建议 StudyPage only，落在 4 按钮区下方极轻 secondary hint，并必须显式带“预计 / 仅供参考”语气。
- **Source:** Room 5 P3.3.4 UI preflight
- **Date:** 2026-04-10

### E-OPP-001-099
- **Finding:** `R1_to_R4_P3_3_4_Execution_Handoff_v0.1.md` 已把本轮执行边界写硬：StudyPage only 的 preview hint + stronger-but-still-non-blocking bridge；ReviewPage / 首页不显示 preview；不改 DB schema / API core semantics / planner owner / planner merge。
- **Source:** Room 1 → Room 4 P3.3.4 execution handoff
- **Date:** 2026-04-10


### E-OPP-001-100
- **Finding:** `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md` 已将 post-P3.3.4 的下一推进主题正式命名为 `P3.3.5 — Local Planner Owner Shift / Cloud Backup Rebase Round`，并明确这不是普通 feature round，而是一轮 dedicated contract / architecture round。
- **Source:** P3.3.5 scope pin / unified handoff entry
- **Date:** 2026-04-10

### E-OPP-001-101
- **Finding:** `R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1.md` 明确建议：当前不宜直接 pin runtime owner shift，更稳的推进方式是先 pin `target-state + staged migration + compatibility / deprecation + backup/restore boundary` 的 staged architecture contract。
- **Source:** Room 2 P3.3.5 technical framing
- **Date:** 2026-04-10

### E-OPP-001-102
- **Finding:** `R3_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Rules_Note_v0.1.md` 已将规则层立场写硬：local primary planner owner 当前只能冻结为 future target-state candidate；current runtime truth 仍不得被写成 owner shift 已完成。
- **Source:** Room 3 P3.3.5 rules note
- **Date:** 2026-04-10

### E-OPP-001-103
- **Finding:** `UI_SPEC_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_UI_Preflight_v0.1.md` 已将 UI 侧最小合同收口为：当前 runtime reality 不变、future target-state candidate 不得写成当前界面事实，且 backup / restore / cross-device 三层成功语义是本轮最值得先前进一步的 UI 合同之一。
- **Source:** Room 5 P3.3.5 UI preflight
- **Date:** 2026-04-10

### E-OPP-001-104
- **Finding:** `R1_to_R4_P3_3_5_Execution_Handoff_v0.1.md` 已把本轮执行边界写硬为 `Phase 0 / Compatibility-Prep + Semantic Rewrite + Shadow-Prep`：current runtime truth 必须保持不变，backup / restore 语义重写、`review_group` compatibility / deprecation prep 与 shadow / parity / regression prep 可以进入执行；runtime owner shift、local-serving cutover 与 API / DB core semantics rewrite 继续禁止。
- **Source:** Room 1 → Room 4 P3.3.5 execution handoff
- **Date:** 2026-04-10


### E-OPP-001-105
- **Finding:** `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md` 已将 post-P3.3.5 的下一推进主题正式命名为 `P3.3.6 — Local-Serving Compatibility Contract / Shadow-Mode Entry Round`，并明确本轮只进入 Phase 1 compatibility / shadow-entry 层，不进入 cutover。
- **Source:** P3.3.6 scope pin / unified handoff entry
- **Date:** 2026-04-10

### E-OPP-001-106
- **Finding:** `R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md` 已将技术侧立场写硬：当前只应推进 compatibility contract / shadow-entry，不应直接触发 runtime owner shift、local-serving cutover、`review_group` 退场或 DB / API core rewrite。
- **Source:** Room 2 P3.3.6 technical framing
- **Date:** 2026-04-10

### E-OPP-001-107
- **Finding:** `R3_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Rules_Note_v0.1.md` 已将规则层立场写硬：`review_group` 当前继续是 current runtime owner，同时进入 compatibility anchor + deprecated candidate；local-serving candidate 只停留在 candidate / compatibility / shadow parity 层。
- **Source:** Room 3 P3.3.6 rules note
- **Date:** 2026-04-10

### E-OPP-001-108
- **Finding:** `UI_SPEC_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_UI_Preflight_v0.1.md` 已将 UI 侧最小合同收口为：current runtime truth 继续不变，local-serving / routing / fact-ingest 只进入 shadow-compatible 页面元语义层与最小测试层，不得形成用户可见 overclaim。
- **Source:** Room 5 P3.3.6 UI preflight
- **Date:** 2026-04-10

### E-OPP-001-109
- **Finding:** `R1_to_R4_P3_3_6_Execution_Handoff_v0.1.md` 已把本轮执行边界写硬为 `Compatibility Contract v1 + Shadow-Entry Prep` 的 very narrow subset：local-serving candidate contract anchors、`review_group` 三层姿态、fact/settlement ingest candidate、routing compatibility、write-back 与 shadow/parity 固定集。
- **Source:** Room 1 → Room 4 P3.3.6 execution handoff
- **Date:** 2026-04-10

### E-OPP-001-110
- **Finding:** `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md` 已将 staged rollout 的下一自然层正式命名为 `P3.3.7 — Local-Serving Limited Execution / Shadow Mode Round`，并明确这轮不是 cutover，而是让 local-serving candidate 在 shadow 层真实跑起来。
- **Source:** P3.3.7 scope pin / unified handoff entry
- **Date:** 2026-04-10

### E-OPP-001-111
- **Finding:** `R2_P3_3_7_LimitedExecution_and_ShadowMode_Tech_Note_v0.1.md`、`R3_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_Rules_Note_v0.1.md` 与 `UI_SPEC_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_UI_Preflight_v0.1.md` 对本轮形成一致结论：P3.3.7 可以前进一步，但只能进入 internal-only limited execution / shadow mode，不能进入 runtime owner shift / local-serving cutover / `review_group` 退场 / auto-routing runtime。
- **Source:** Room 2 / Room 3 / Room 5 P3.3.7 inputs
- **Date:** 2026-04-10

### E-OPP-001-112
- **Finding:** `R1_to_R4_P3_3_7_Execution_Handoff_v0.1.md` 已把本轮执行边界写硬为 `Phase 2 / Limited Execution / Shadow Mode`：local-serving shadow run、parity checks、`review_group` shadow baseline、fact-ingest shadow evidence、routing shadow prep、以及 regression / write-back / no-major-change statement。
- **Source:** Room 1 → Room 4 P3.3.7 execution handoff
- **Date:** 2026-04-10

### E-OPP-001-113
- **Finding:** `BR-OPP-001_v0.2.8.md` 与 `UI_SPEC_v0.2.8.md` 已将 P3.3.6 已收口的规则与页面现实增量回写进单文件 merged baseline，且都已明确标注 *ready for Room 1 runtime-baseline update*。
- **Source:** BR / UI v0.2.8 write-back candidates
- **Date:** 2026-04-10


### E-OPP-001-114
- **Finding:** `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md` 已把 post-P3.3.7 的下一方向正式命名为 `P3.3.8 — Phase 3 Gate / Cutover-Decision + DB/API Candidate Round`，并明确本轮只进入 gate / candidate / migration round，而不是 cutover。
- **Source:** Room 1 P3.3.8 provisional scope pin
- **Date:** 2026-04-11

### E-OPP-001-115
- **Finding:** `R2_P3_3_8_Phase3Gate_and_DB_API_Candidate_Tech_Note_v0.1.md`、`R3_P3_3_8_Phase3Gate_and_CutoverDecision_Rules_Note_v0.1.md` 与 `UI_SPEC_P3_3_8_Phase3Gate_and_CutoverDecision_UI_Preflight_v0.1.md` 已共同收口：P3.3.8 可以前进一步，但只应进入 `Phase 3 / Gate-Driven Candidate Execution + Migration Prep` 的 very narrow subset，不得写成 runtime owner shift、local-serving cutover、`review_group` 退场或 DB / API core rewrite。
- **Source:** Room 2 / Room 3 / Room 5 P3.3.8 gate inputs
- **Date:** 2026-04-11

### E-OPP-001-116
- **Finding:** `R1_to_R4_P3_3_8_Execution_Handoff_v0.1_refreshed.md` 已把本轮执行边界写硬为：gate evidence consolidation、candidate seam / migration marker / rollback floor prep、`review_group` exit gate 前置项、fact / settlement boundary guardrails、UI migration prep 与 regression / write-back / no-major-change statement。
- **Source:** Room 1 → Room 4 P3.3.8 execution handoff
- **Date:** 2026-04-11

### E-OPP-001-117
- **Finding:** `BR-OPP-001_v0.2.9.md` 与 `UI_SPEC_v0.2.9.md` 已将 P3.3.7 closeout 与 P3.3.8 review-basis 所需的规则、页面现实与 gate / migration 边界增量回写进单文件 merged baseline，且都已明确标注 *ready for Room 1 runtime-baseline update*。
- **Source:** BR / UI v0.2.9 write-back candidates
- **Date:** 2026-04-11



### E-OPP-001-118
- **Finding:** `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md` 已把 post-P3.3.8 的下一方向正式命名为 `P3.3.9 — First Very Narrow Cutover Round`，并明确本轮不把 cleanup / `review_group` 退场 / active DB/API baseline uplift 绑入同一轮。
- **Source:** Room 1 P3.3.9 scope pin handoff
- **Date:** 2026-04-11

### E-OPP-001-119
- **Finding:** `R2_P3_3_9_FirstVeryNarrowCutover_Tech_Note_v0.1.md`、`R3_P3_3_9_FirstVeryNarrowCutover_Rules_Note_v0.1.md` 与 `UI_SPEC_P3_3_9_FirstVeryNarrowCutover_UI_Preflight_v0.1.md` 已共同收口：第一拍最稳的切口是 ReviewPage 的 non-continuation serving subset；首页 route、active continuation、final fact owner、`review_group` 退场与 active DB/API uplift 均继续后置。
- **Source:** Room 2 / Room 3 / Room 5 P3.3.9 cutover inputs
- **Date:** 2026-04-11

### E-OPP-001-120
- **Finding:** `R1_to_R4_P3_3_9_Execution_Handoff_v0.1.md` 已把本轮执行边界写硬为：只切 ReviewPage non-continuation serving seam，保留 `review_group` 为 current owner + retained fallback anchor，守住 final fact / settlement cloud-owner 边界，并把 rollback / hold / observability 成套落地。
- **Source:** Room 1 → Room 4 P3.3.9 execution handoff
- **Date:** 2026-04-11

### E-OPP-001-121
- **Finding:** `BR-OPP-001_v0.2.11.md` 与 `UI_SPEC_v0.3.1.md` 已将 P3.3.9 已收口的规则与页面现实增量回写进单文件 merged baseline，且都已明确标注 *ready for Room 1 runtime-baseline update*。
- **Source:** BR / UI v0.2.11 / v0.3.1 write-back candidates
- **Date:** 2026-04-11


### E-OPP-001-122
- **Finding:** `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md` 已把 post-P3.3.9 的下一方向正式命名为 `P3.3.10 — Fuller Cutover / review_group Exit-Gate / DB-API Uplift Judgment Round`，并明确本轮只做 judgment / candidate / migration 收口，不把 fuller cutover、`review_group` 真退场或 active DB/API uplift 写成已生效事实。
- **Source:** Room 1 P3.3.10 scope pin handoff
- **Date:** 2026-04-11

### E-OPP-001-123
- **Finding:** `R1_to_R4_P3_3_10_Execution_Handoff_v0.1.md` 已把本轮执行边界写硬为：只在 ReviewPage continuity-adjacent serving-adapter family 扩大一小层，继续把 `review_group` 保留为 current owner + retained fallback anchor，继续把 DB/API uplift 停留在 seam-readiness judgment，并继续守住 final fact / settlement cloud-owner 边界。
- **Source:** Room 1 → Room 4 P3.3.10 execution handoff
- **Date:** 2026-04-11

### E-OPP-001-124
- **Finding:** `BR-OPP-001_v0.2.12.md` 与 `UI_SPEC_v0.3.2.md` 已将 P3.3.10 已收口的规则与页面现实增量回写进单文件 merged baseline，且都已明确标注 *ready for Room 1 runtime-baseline update*。
- **Source:** BR / UI v0.2.12 / v0.3.2 write-back candidates
- **Date:** 2026-04-11

## 5) Decision Log

### D-OPP-001-049
- **Decision:** 在 P3 与 P4 之间临时插入一个中间阶段：`P3.1 — Local Progress + Cloud Backup`。
- **Approver:** Room 1

### D-OPP-001-050
- **Decision:** 将 `背单词养猫app项目介绍书_v0.1.1_P3.1.md` 与 `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` pin 为当前 P3.1 产品 / PRD 基线。
- **Approver:** Room 1

### D-OPP-001-051
- **Decision:** 将 `ORG_v0.3.0.md`、`room1_v0.2.0.md`、`room2_v0.2.0.md`、`ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.0.md`、`room4_v0.2.0.md`、`room5_v0.2.0.md` pin 为当前 active governance / role-card baseline。
- **Approver:** Room 1

### D-OPP-001-052
- **Decision:** Room 1 接受 `R2_P3_1_LocalProgress_CloudBackup_Preflight_v0.1.1.md` 作为当前 P3.1 的技术入口依据，但不直接改 active DB / API baseline。
- **Approver:** Room 1

### D-OPP-001-053
- **Decision:** Room 1 接受 `R3_P3_1_LocalProgress_CloudBackup_Rules_Freeze_Note_v0.1.1.md` 作为当前 P3.1 的 rules freeze input / review basis，但不直接改 active BR baseline。
- **Approver:** Room 1

### D-OPP-001-054
- **Decision:** Room 1 接受 `UI_SPEC_P3_1_LocalProgress_CloudBackup_v0.1.1.md` 并将其 pin 为当前 P3.1 backup lane 的 UI / UX baseline reference。
- **Approver:** Room 1

### D-OPP-001-055
- **Decision:** Room 1 接受 `R4_P3_1_LocalProgress_CloudBackup_Implementation_Plan_v0.1.1.md` 与 `p3.1_phases.md` 作为当前 P3.1 的实施参考。
- **Approver:** Room 1

### D-OPP-001-056
- **Decision:** `回p3_1_p4.md` 只作为“Room 4 已交付 Phase 4 restore candidate”被吸收进主线程；不自动等同于 P3.1 close accepted。
- **Approver:** Room 1

### D-OPP-001-057
- **Decision:** User 直接拍板新增三按钮 / 三功能，Room 1 正式将其写为 `P3.1 direct-scope pin delta` 当前范围：
  1. 从云端下载进度到本机
  2. 上传进度到云端
  3. 设置每日学习单词数量
- **Approver:** User via Room 1

### D-OPP-001-058
- **Decision:** Room 1 接受 `R2_P3_1_DirectScopePin_Delta_Tech_Note_v0.1.1.md`、`R3_P3_1_DirectScopePin_Delta_Rules_Note_v0.1.1.md`、`UI_SPEC_P3_1_DirectScopePin_Delta_v0.1.1.md`、`R4_P3_1_DirectScopePin_Delta_Execution_Note_v0.1.1.md` 作为当前 delta round 的技术 / 规则 / UI / 执行参考。
- **Approver:** Room 1

### D-OPP-001-059
- **Decision:** Room 1 接受 `回p3_1_delta_p3.md` 的 close 结论，确认 **P3.1 direct-scope delta round** 已正式完成并可 close。
- **Why:** Room 4 已完成三功能交付；330 Flutter tests pass（25 new）；0 analyze errors；manual only / warning first / no fake sync / no destructive bundle / no history rewrite 边界守住。
- **Approver:** Room 1

### D-OPP-001-060
- **Decision:** Room 1 接受 `BR-OPP-001_v0.2.1.md` 作为新的 BR full merged baseline，并将其 pin 为 runtime active BR baseline。
- **Why:** BR 已从旧 `v0.1.7` 的 direct-patch / retained-reference 形态收敛为 single-file merged baseline candidate，足够支撑运行态更新。
- **Approver:** Room 1

### D-OPP-001-061
- **Decision:** Room 1 接受 `背单词喵喵app_DB设计草案_v0.2.1.md` 与 `背单词喵喵app_API设计草案_v0.2.1.md`，并将其 pin 为新的 runtime active DB / API baselines。
- **Why:** Room 2 已把 code-truth implemented reality 与 candidate contracts 做 reconciled baseline 收口，足以替代旧 `v0.1.4 / v0.1.3` 作为当前开发维护入口。
- **Approver:** Room 1

### D-OPP-001-062
- **Decision:** Room 1 接受 `UI_SPEC_v0.2.1.md` 作为新的 runtime active UI baseline。
- **Why:** Room 5 已把代码现实、旧版 retained references 与当前 UI 事实压缩成单文件 absorbed baseline candidate，并明确 ready for runtime-baseline update。
- **Approver:** Room 1

### D-OPP-001-063
- **Decision:** Room 1 将治理层 active versions 升级为 `ORG_v0.3.1` + Room2 `v0.2.1` + Room3 `v0.3.1` + Room4-治理 `v0.2` + Room5 `v0.2.1`。
- **Why:** 现有治理层文件集已经完成本轮升级，足以替代旧治理版本作为当前项目协作依据。
- **Approver:** Room 1

### D-OPP-001-064
- **Decision:** Room 1 判定：在 BR / DB / API / UI 完成 runtime-baseline update 后，`P3.1 — Local Progress + Cloud Backup` 整体达到 **overall closed**。
- **Why:** 当前轮最主要的 gate gap 是“文档未追上代码 / baseline 未更新”；该问题现已完成治理层与推进层收口。
- **Approver:** Room 1

---

### D-OPP-001-065
- **Decision:** Room 1 接受 `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`，并正式将 post-P3.1 的下一推进主题命名为 `P3.3 — Home Entry + FSRS 4-Button + Review Planning`。
- **Why:** `G-OPP-001-001` 所对应的“下一产品方向真空”已被 user 直接拍板关闭；需要把该决定写入主线程并作为 P3.3 的正式入口。
- **Approver:** Room 1 / User

### D-OPP-001-066
- **Decision:** Room 1 接受 P3.3 第一拍 closeout：首页“背单词”主入口 + Study/Review 4 按钮接入 + 最小 submit / throttle / bridge 已完成并通过 Room4-治理验收。
- **Why:** 本轮未触碰 DB schema / API 核心语义 / 奖励结算主链路 / `review_group` 最小合同；测试覆盖已证明入口、顺序、throttle、bridge 与 false-success 边界均已通过。
- **Approver:** Room 1

### D-OPP-001-067
- **Decision:** Room 1 判定 P3.3 当前阶段状态为 **First Pass Closed / Next-Focus Pending**，而非整体 fully closed。
- **Why:** 虽然第一拍实现与测试已通过，但最终两字中文词面、`previewDurations`、以及 ReviewPage FSRS bridge 是否继续保持 best-effort 仍需下一轮 focus 决策。
- **Approver:** Room 1

### D-OPP-001-068
- **Decision:** Room 1 接受 `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md`，并正式将 P3.3 第二拍命名为 `P3.3.1 — 收尾 / 体验补强`。
- **Why:** user 已直接拍板第二拍方向；Room 1 需要把该方向收入口线程，并用统一执行入口替代“各 Room 自行理解补强范围”的推进方式。
- **Approver:** Room 1 / User

### D-OPP-001-069
- **Decision:** Room 1 接受 `R1_to_R4_P3_3_1_Execution_Handoff_v0.1.md` 所定义的 P3.3.1 核心收口结论：最终词面冻结为“不认识 / 模糊 / 记得 / 秒答”；`previewDurations` 本轮 deferred；ReviewPage FSRS bridge 仅清到 controlled best-effort；本轮重点为 UI / copy / test polish。
- **Why:** Room 2 / Room 3 / Room 5 的专项输入已被统一收口为一份短而硬的执行单，足够支撑 Room 4 在不扩主契约的前提下完成收尾补强。
- **Approver:** Room 1

### D-OPP-001-070
- **Decision:** Room 1 接受 `P3.3.1_Claude_res.md` 的 closeout delivery，确认 P3.3.1 本轮 in-scope 实施已完成并可 close。
- **Why:** Room 4 已完成最终词面落地、2×2 固定顺序、ReviewPage bridge 从 silent 提升到 controlled best-effort、可观察 fallback、文案禁区清理与测试 / analyze 验证；同时明确未触碰 DB schema / API 核心语义 / `review_group` 最小合同 / planner owner。
- **Approver:** Room 1

### D-OPP-001-071
- **Decision:** Room 1 将 P3.3 的运行态 BR / UI 入口更新为：`BR-OPP-001_v0.2.2.md` + `R3_P3_3_1_Final_Wording_and_Bridge_Rules_Note_v0.1.md`，以及 `UI_SPEC_v0.2.2.md` + `UI_SPEC_P3_3_1_Copy_Polish_and_PreviewDurations_Delta_v0.1.1.md`。
- **Why:** P3.3 第一拍已被 BR / UI v0.2.2 吸收；P3.3.1 的最终词面、preview defer 与 bridge 语义则继续由专项 delta reference 承担，足以支撑当前 runtime 真实口径，而不必等待下一轮 full merged 主文档。
- **Approver:** Room 1

### D-OPP-001-072
- **Decision:** Room 1 判定 `P3.3 — Home Entry + FSRS 4-Button + Review Planning` 已达到 **overall closed**。
- **Why:** P3.3 第一拍已完成功能接入；P3.3.1 已完成收尾 / 体验补强；当前 remaining items 已降为 post-P3.3 的下一轮方向选择、delta 合并清理与历史 reference 压缩，不再构成 P3.3 本身的 close blocker。
- **Approver:** Room 1


### D-OPP-001-073
- **Decision:** Room 1 接受 `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`，并正式将 post-P3.3 的下一推进主题命名为 `P3.3.2 — Review Planning Deepening / Contract Gate`。
- **Why:** User 已直接拍板下一方向；Room 1 需要把该方向收入口线程，并明确本轮先做 contract preflight / gate，而不是直接进入完整复习规划实现。
- **Approver:** Room 1 / User

### D-OPP-001-074
- **Decision:** Room 1 接受 `R1_to_R4_P3_3_2_Execution_Handoff_v0.1.md` 所定义的本轮最小合同：冻结 `session_entry_policy_v1` 与 `planner_owner_split_v1`，且不进入 auto-routing / unified planner / 完整 review planning contract。
- **Why:** Room 2 / Room 3 / Room 5 的专项输入已被统一收口为一份短而硬的执行单，足以支撑 Room 4 在不扩主契约的前提下完成本轮实现。
- **Approver:** Room 1

### D-OPP-001-075
- **Decision:** Room 1 将运行态 BR / UI 主文件入口更新为 `BR-OPP-001_v0.2.3.md` 与 `UI_SPEC_v0.2.3.md`。
- **Why:** User 已明确告知 BR / UI 主文件完成回写；`v0.2.3` 已具备 single-file 主文档形态，足以替代此前 `v0.2.2 + P3.3.1 delta reference` 的双入口运行态口径。
- **Approver:** Room 1

### D-OPP-001-076
- **Decision:** Room 1 按当前项目状态吸收 `P3.3.2` 为 **current-round closed**，并将其写入推进层 SSOT。
- **Why:** User 已向 Room 1 转述：Room 4 已完成 P3.3.2 实施；而本轮 handoff 的完成定义本身只要求最小合同落地、假事实清理与“不越核心合同边界”，不要求进入更深一层 review planning product。
- **Approver:** Room 1 / User relay


### D-OPP-001-077
- **Decision:** Room 1 接受 `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`，并正式将 post-P3.3.2 的下一推进主题命名为 `P3.3.3 — Review Planning Contract v1 / SRS Boundary Round`。
- **Why:** User 已直接拍板下一方向；Room 1 需要把该方向收入口线程，并明确本轮先做 deeper-contract 的 contract gate / preflight，而不是直接进入完整 planner 产品实现。
- **Approver:** Room 1 / User

### D-OPP-001-078
- **Decision:** Room 1 接受 `R1_to_R4_P3_3_3_Execution_Handoff_v0.1.md` 所定义的 very narrow execution layer：冻结 `review_readiness_policy_v1`、`review_priority_policy_v1`（hierarchy only）、`review_group_generation_policy_v1`（entry boundary only）与 `schedule_source_contract_v1`，并继续保持 `previewDurations` deferred。
- **Why:** Room 2 / Room 3 / Room 5 的专项输入已被统一收口为一份短而硬的执行单，足以支撑 Room 4 在不扩主契约的前提下完成 P3.3.3 实施。
- **Approver:** Room 1

### D-OPP-001-079
- **Decision:** Room 1 将运行态 BR / UI 主文件入口更新为 `BR-OPP-001_v0.2.5.md` 与 `UI_SPEC_v0.2.5.md`。
- **Why:** User 已明确告知 BR / UI 主文件完成回写更新；`v0.2.5` 已以 single-file merged baseline 形态吸收 P3.3.3 closeout，足以替代此前 `v0.2.3` 作为当前运行态 BR / UI 入口。
- **Approver:** Room 1

### D-OPP-001-080
- **Decision:** Room 1 按当前项目状态吸收 `P3.3.3` 为 **current-round closed**，并将其写入推进层 SSOT。
- **Why:** Room 4 已完成 P3.3.3 本轮实施；closeout package 已明确 4 组最小合同落地、`previewDurations` 继续 deferred、测试 / analyze 通过，且未触碰 DB schema / API core semantics / `review_group` 最小合同 / `planner_owner_split_v1`。
- **Approver:** Room 1 / User relay

### D-OPP-001-081
- **Decision:** Room 1 接受 `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`，并正式将 post-P3.3.3 的下一推进主题命名为 `P3.3.4 — Preview Re-entry + Stronger Bridge Round`。
- **Why:** User 已直接拍板下一方向；Room 1 需要把该方向收入口线程，并明确本轮先做 `preview` 回归与 stronger bridge 的最小合同，而不是直接进入更深 planner 产品。
- **Approver:** Room 1 / User

### D-OPP-001-082
- **Decision:** Room 1 接受 `R1_to_R4_P3_3_4_Execution_Handoff_v0.1.md` 所定义的 very narrow execution layer：preview 只允许 StudyPage only、只作为 estimated hint；ReviewPage bridge 只允许收紧到 stronger-but-still-non-blocking 的最小技术合同。
- **Why:** Room 2 / Room 3 / Room 5 的专项输入已被统一收口为一份短而硬的执行单，足以支撑 Room 4 在不扩主契约的前提下完成 P3.3.4 实施。
- **Approver:** Room 1

### D-OPP-001-083
- **Decision:** Room 1 在当前主线程中吸收 `P3.3.4` 为 **current-round closed**，并保持 BR / UI runtime baselines 继续为 `v0.2.5`，等待后续主文档 write-back 再做 baseline 升级。
- **Why:** User 已向 Room 1 转述：Room 4 已完成 P3.3.4 的开发 / 实施；而本轮 handoff 的完成定义本身只要求 StudyPage only preview 最小回归与 stronger bridge 最小强化，不要求进入 planner merge / unified planner / deeper review planning product。
- **Approver:** Room 1 / User relay


### D-OPP-001-084
- **Decision:** Room 1 接受 `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`，并正式将 post-P3.3.4 的下一推进主题命名为 `P3.3.5 — Local Planner Owner Shift / Cloud Backup Rebase Round`。
- **Why:** User 已直接拍板下一方向；Room 1 需要把该方向收入口线程，并明确本轮先做 dedicated contract / architecture round，而不是直接进入 runtime owner shift 实施。
- **Approver:** Room 1 / User

### D-OPP-001-085
- **Decision:** Room 1 接受 `R1_to_R4_P3_3_5_Execution_Handoff_v0.1.md` 所定义的本轮 very narrow execution layer：只进入 `Phase 0 / Compatibility-Prep + Semantic Rewrite + Shadow-Prep`，保持 current runtime truth 不变，并只推进 backup / restore 语义重写、`review_group` compatibility / deprecation prep 与 future target-state candidate 的边界写硬。
- **Why:** Room 2 / Room 3 / Room 5 的专项输入已被统一收口为一份短而硬的执行单，足以支撑 Room 4 在不触碰 runtime owner shift、DB / API core semantics、routing runtime 与 reward-settlement owner 的前提下完成本轮实施。
- **Approver:** Room 1

### D-OPP-001-086
- **Decision:** Room 1 将运行态 BR / UI 主文件入口更新为 `BR-OPP-001_v0.2.8.md` 与 `UI_SPEC_v0.2.8.md`。
- **Why:** User 已明确告知 BR / UI 主文件完成回写；`v0.2.6` 已以单文件 merged baseline 形态吸收 P3.3.4 closeout 与 P3.3.5 的 target-state / compatibility / fact-copy write-back，足以替代此前 `v0.2.5` 作为当前运行态 BR / UI 入口。
- **Approver:** Room 1

### D-OPP-001-087
- **Decision:** Room 1 在当前主线程中吸收 `P3.3.5` 为 **current-round closed**。
- **Why:** User 已向 Room 1 转述：Room 4 已完成 P3.3.5 的开发 / 实施；而本轮 handoff 的完成定义本身只要求 current runtime truth 保持不变、future target-state candidate 边界写硬、backup / restore / sync 三层语义改写、`review_group` compatibility / deprecation prep 与 shadow / parity / regression prep 落地，不要求发生 runtime owner shift。
- **Approver:** Room 1 / User relay


### D-OPP-001-088
- **Decision:** Room 1 接受 `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md`，并正式将 post-P3.3.5 的下一推进主题命名为 `P3.3.6 — Local-Serving Compatibility Contract / Shadow-Mode Entry Round`。
- **Why:** User 已直接拍板下一方向；Room 1 需要把该方向收入口线程，并明确本轮先做 `Compatibility Contract v1 + Shadow-Entry Prep`，而不是直接进入 runtime owner shift 或 local-serving cutover。
- **Approver:** Room 1 / User

### D-OPP-001-089
- **Decision:** Room 1 接受 `R1_to_R4_P3_3_6_Execution_Handoff_v0.1.md` 所定义的本轮 very narrow execution layer：只进入 `Compatibility Contract v1 + Shadow-Entry Prep`，保持 current runtime truth 不变，并只推进 local-serving candidate contract、`review_group` compatibility posture、fact/settlement ingest candidate、routing compatibility、write-back 与 shadow/parity 固定集。
- **Why:** Room 2 / Room 3 / Room 5 的专项输入已被统一收口为一份短而硬的执行单，足以支撑 Room 4 在不触碰 runtime owner shift、`review_group` 退场、DB / API core semantics 与 runtime routing 的前提下完成本轮实施。
- **Approver:** Room 1

### D-OPP-001-090
- **Decision:** Room 1 在当前主线程中吸收 `P3.3.6` 为 **current-round closed**。
- **Why:** User 已向 Room 1 转述：Room 4 已完成 `P3.3.6` 的开发 / 实施；而本轮 handoff 的完成定义本身只要求 Compatibility Contract v1 / Shadow-Entry Prep 落地，不要求发生 runtime owner shift 或 local-serving cutover。
- **Approver:** Room 1 / User relay

### D-OPP-001-091
- **Decision:** Room 1 接受 `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md`，并正式将 post-P3.3.6 的下一推进主题命名为 `P3.3.7 — Local-Serving Limited Execution / Shadow Mode Round`。
- **Why:** User 已直接拍板下一方向；Room 1 需要把该方向收入口线程，并明确这轮是 staged rollout 的 Phase 2 / Limited Execution / Shadow Mode，而不是 cutover。
- **Approver:** Room 1 / User

### D-OPP-001-092
- **Decision:** Room 1 接受 `R1_to_R4_P3_3_7_Execution_Handoff_v0.1.md` 所定义的本轮 very narrow execution layer：只进入 local-serving shadow run、parity checks、`review_group` shadow baseline、fact-ingest shadow evidence、routing shadow prep 与 regression / write-back / no-major-change。
- **Why:** Room 2 / Room 3 / Room 5 的专项输入已被统一收口为一份短而硬的执行单，足以支撑 Room 4 在不触碰 runtime owner shift、`review_group` 退场、DB / API core semantics、runtime routing 与 fact / settlement owner 的前提下完成本轮实施。
- **Approver:** Room 1

### D-OPP-001-093
- **Decision:** Room 1 将运行态 BR / UI 主文件入口更新为 `BR-OPP-001_v0.2.8.md` 与 `UI_SPEC_v0.2.8.md`。
- **Why:** User 已明确告知 BR / UI 主文件完成回写；`v0.2.8` 已以单文件 merged baseline 形态吸收 P3.3.6 closeout 与 P3.3.7 review-basis 所需的 shadow-compatible / compatibility / fact-boundary write-back，足以替代此前 `v0.2.6` 作为当前运行态 BR / UI 入口。
- **Approver:** Room 1

### D-OPP-001-094
- **Decision:** Room 1 在当前主线程中吸收 `P3.3.7` 为 **current-round closed**。
- **Why:** User 已向 Room 1 转述：Room 4 已完成 `P3.3.7` 的开发 / 实施；而本轮 handoff 的完成定义本身只要求 limited execution / shadow mode 的 very narrow subset 跑通，不要求发生 runtime owner shift、local-serving cutover 或 `review_group` 退场。
- **Approver:** Room 1 / User relay


### D-OPP-001-095
- **Decision:** Room 1 接受 `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md`，并正式将 post-P3.3.7 的下一推进主题命名为 `P3.3.8 — Phase 3 Gate / Cutover-Decision + DB/API Candidate Round`。
- **Why:** 当前 staged rollout 已从 Phase 0 / 1 / 2 连续推进到需要把 shadow evidence 转成下一层 gate / candidate / migration 判断；但这轮仍不是 cutover。
- **Approver:** Room 1

### D-OPP-001-096
- **Decision:** Room 1 接受 `R1_to_R4_P3_3_8_Execution_Handoff_v0.1_refreshed.md` 所定义的本轮 very narrow execution layer：只进入 gate evidence consolidation、candidate seam / migration prep、`review_group` exit gate 前置项、fact / settlement boundary guardrails、UI migration prep 与 regression / write-back / no-major-change。
- **Why:** Room 2 / Room 3 / Room 5 的专项输入已被统一收口为一份短而硬的执行单，足以支撑 Room 4 在不触碰 runtime owner shift、local-serving cutover、`review_group` 退场、DB / API core semantics 与 runtime routing 的前提下完成本轮实施。
- **Approver:** Room 1

### D-OPP-001-097
- **Decision:** Room 1 将运行态 BR / UI 主文件入口更新为 `BR-OPP-001_v0.2.9.md` 与 `UI_SPEC_v0.2.9.md`。
- **Why:** User 已明确告知 BR / UI 主文件完成回写；`v0.2.9` 已以单文件 merged baseline 形态吸收 P3.3.7 closeout 与 P3.3.8 gate / migration review-basis 所需的规则与页面现实，足以替代此前 `v0.2.8` 作为当前运行态 BR / UI 入口。
- **Approver:** Room 1

### D-OPP-001-098
- **Decision:** Room 1 在当前主线程中吸收 `P3.3.8` 为 **current-round closed**。
- **Why:** User 已向 Room 1 转述：Room 4 已完成 `P3.3.8` 的开发 / 实施；而本轮 handoff 的完成定义本身只要求 Phase 3 gate / candidate / migration 的 very narrow subset 落地，不要求发生 runtime owner shift、local-serving cutover、`review_group` 退场或 DB / API baseline uplift。
- **Approver:** Room 1 / User relay



### D-OPP-001-099
- **Decision:** Room 1 接受 `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md`，并正式将 post-P3.3.8 的下一推进主题命名为 `P3.3.9 — First Very Narrow Cutover Round`。
- **Why:** P3.3.8 已把 gate / candidate / migration prep 收硬；若继续 owner-shift 方向，下一步不再是继续 gate-only，而是必须选择一个最小 runtime seam 进入第一拍 very narrow cutover。
- **Approver:** Room 1

### D-OPP-001-100
- **Decision:** Room 1 接受 `R1_to_R4_P3_3_9_Execution_Handoff_v0.1.md` 所定义的本轮 very narrow execution layer：只进入 ReviewPage non-continuation serving subset 的极窄 source seam 切换，并成套要求 retained-anchor / rollback / hold / stop-condition / observability。
- **Why:** Room 2 / Room 3 / Room 5 的专项输入已被统一收口为一份短而硬的执行单，足以支撑 Room 4 在不触碰首页 route、active continuation、final fact owner、`review_group` 退场、cleanup bundling 与 active DB/API uplift 的前提下完成本轮实施。
- **Approver:** Room 1

### D-OPP-001-101
- **Decision:** Room 1 将运行态 BR / UI 主文件入口更新为 `BR-OPP-001_v0.2.11.md` 与 `UI_SPEC_v0.3.1.md`，并在当前主线程中吸收 `P3.3.9` 为 **current-round closed**。
- **Why:** User 已明确告知 BR / UI 主文件完成回写，且已转述 Room 4 完成 `P3.3.9` 的开发 / 实施；而本轮 handoff 的完成定义本身只要求 first very narrow cutover 的 very narrow subset 落地，不要求发生 runtime owner shift completed、`review_group` 退场、cleanup 或 active DB/API baseline uplift。
- **Approver:** Room 1 / User relay


### D-OPP-001-102
- **Decision:** Room 1 接受 `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`，并正式将 post-P3.3.9 的下一推进主题命名为 `P3.3.10 — Fuller Cutover / review_group Exit-Gate / DB-API Uplift Judgment Round`。
- **Why:** P3.3.9 已完成第一拍 very narrow cutover；若继续 owner-shift 方向，下一步应先判断 fuller cutover 可以扩大到哪一层、`review_group` 何时才有资格进入真实 exit judgment，以及哪些 DB/API seam 只到 uplift-judgment-ready。
- **Approver:** Room 1

### D-OPP-001-103
- **Decision:** Room 1 接受 `R1_to_R4_P3_3_10_Execution_Handoff_v0.1.md` 所定义的本轮 very narrow execution layer：只进入 fuller-cutover / exit-gate / uplift-judgment 的 judgment-driven candidate execution，不得把 full cutover、`review_group` 真退场、active DB/API uplift 或 cleanup 写成当前事实。
- **Why:** Room 2 / Room 3 / Room 5 的专项输入已被统一收口为一份短而硬的执行单，足以支撑 Room 4 在不触碰 homepage route、active continuation、final fact owner、`review_group` 真实退场、DB/API core rewrite 与 cleanup bundling 的前提下完成本轮实施。
- **Approver:** Room 1

### D-OPP-001-104
- **Decision:** Room 1 将运行态 BR / UI 主文件入口更新为 `BR-OPP-001_v0.2.12.md` 与 `UI_SPEC_v0.3.2.md`，并在当前主线程中吸收 `P3.3.10` 为 **current-round closed**。
- **Why:** User 已明确告知 BR / UI 主文件完成回写，且已转述 Room 4 完成 `P3.3.10` 的开发 / 实施；而本轮 handoff 的完成定义本身只要求 judgment / candidate / migration 的 very narrow subset 落地，不要求发生 full cutover completed、`review_group` 真退场或 active DB/API uplift absorbed。
- **Approver:** Room 1 / User relay


## 6) Gate Gaps (for MAIN reference)

### G-OPP-001-001
- **Gap:** `post-P3.3.10` 的下一轮产品 / 技术 focus 尚未被 Room 1 / User 正式拍板。
- **Impact:** 当前可接受 P3.3.10 close，但项目若不尽快 pin 新 focus，会再次进入“当前轮已关单、下一轮未起单”的推进真空。
- **Owner:** Room 1 / User
- **Priority:** Critical

### G-OPP-001-002
- **Gap:** 更深一层的 **更完整 cutover execution / `review_group` 真实退场 / active DB-API baseline uplift** 仍保持 pending。
- **Impact:** P3.3.10 已把 fuller cutover / exit-gate / uplift judgment 往前推了一拍；若项目继续深化，下一轮必须单开更完整的 cutover execution 或 exit 相关 round，不可在当前 closeout 后静默把 `review_group` 退场、baseline uplift 与 cleanup 一并拉满。
- **Owner:** Room 1 / Room 2 / Room 3 / Room 5
- **Priority:** High

### G-OPP-001-003
- **Gap:** DB / API active baselines 仍停留在 `v0.2.1`，尚未进入与 P3.3.10 的 uplift-judgment-ready seam families / hold-note / rollback floor / migration note 现实对齐的下一层候选吸收。
- **Impact:** 当前 P3.3.10 允许 close，因为本轮明确未触碰 DB schema / API core semantics；但若下一轮继续 owner-shift 方向，Room 2 必须单开新的 DB / API uplift-ready / execution-judgment / migration round，避免治理层与运行态再次脱节。
- **Owner:** Room 2 / Room 1
- **Priority:** High

### G-OPP-001-004
- **Gap:** `Option C / Option A / P3.1 / early P3.3 retained references` 的第二轮 archive / compression 仍未统一处理。
- **Impact:** 旧 reference 仍可作为历史说明，但若长期不整理，会继续增加阅读噪音。
- **Owner:** Room 1
- **Priority:** Minor


## 7) Next Actions (must include owner + done)

1. **Owner=Room 1 / User | ETA=Next round | Done=拍板 `post-P3.3.10` 的下一推进主题，并明确是继续进入“更完整 cutover execution / exit-candidate / uplift-readiness”方向，还是切到别的产品主题 | Action=让项目从 “P3.3.10 已 close” 平滑切到下一推进主题**

2. **Owner=Room 2 | ETA=If owner-shift direction continues | Done=给出下一轮 `fuller cutover execution subset / review_group exit-candidate refinement / DB-API uplift-readiness / migration / rollback` 的范围、红线与 staged rollout 建议 | Action=为可能的 P3.3.11 / next-step fuller-cutover execution round 准备技术入口**

3. **Owner=Room 1 | ETA=After next-focus pin | Done=按 user 拍板结果下发新的 scope pin / handoff，并同步更新 STATUS / Main 的 gate gaps 与 active focus | Action=保持推进层与治理层 SSOT 同轨**


## 8) Notes (≤5 lines)

- 当前最重要的新事实是：**`P3.3.10` 已按 fuller cutover / exit-gate / uplift judgment 的 very narrow subset 实施完成，并被 Room 1 吸收到主线程。**
- 本轮真正落地的是：继续把扩大方向压在 ReviewPage 的 **continuity-adjacent serving-adapter family**，继续保留 `review_group` 作为 current owner + retained fallback anchor，并继续把 rollback / hold / stop-condition / observability 与 stronger-ingest boundary 写硬。
- `local primary planner owner` 当前仍只是 **future target-state candidate**；首页仍保持 `study_default`，active continuation 继续独立承接，final fact / settlement truth 继续以后端为准，`review_group` 当前仍是 current owner + retained fallback anchor + compatibility anchor + deprecated candidate。
- 当前 active BR / UI baseline 已升级为 `BR-OPP-001_v0.2.12.md` 与 `UI_SPEC_v0.3.2.md`；DB / API baseline 继续保持 `v0.2.1`。
- 下一治理动作不是在 P3.3.10 内静默继续 owner shift，而是 **由 Room 1 / User 拍板 post-P3.3.10 下一轮主题；若继续此方向，则单开下一轮 fuller-cutover execution / exit-candidate / DB-API uplift-readiness round。**


## 9) Working Rule

> **Main 现在必须反映真实主线程：P1 / P2 / Option A / Option A.1 / Option B / Option C / P3 / P3.1 / P3.3 / P3.3.2 / P3.3.3 / P3.3.4 / P3.3.5 / P3.3.6 / P3.3.7 / P3.3.8 / P3.3.9 / P3.3.10 均已完成当前轮关单；其中 P3.3.6 只把 owner-shift 方向推进到 `Compatibility Contract v1 + Shadow-Entry Prep`，P3.3.7 只把该方向推进到 `Phase 2 / Limited Execution / Shadow Mode` 的 very narrow subset，P3.3.8 只把该方向推进到 `Phase 3 / Gate-Driven Candidate Execution + Migration Prep` 的 very narrow subset，P3.3.9 只把该方向推进到 `First Very Narrow Cutover` 的第一拍，而 P3.3.10 则只把该方向推进到 `fuller cutover / review_group exit-gate / DB-API uplift judgment` 的 very narrow subset：继续只在 ReviewPage continuity-adjacent serving-adapter family 扩大一小层，继续保留 `review_group` 为 current owner + retained fallback anchor，继续守住首页 `study_default`、active continuation 独立承接、final fact / settlement 以后端为准、DB/API 不做 core rewrite、`review_group` 真退场 / active DB-API uplift / cleanup 后置。下一步不是在 P3.3.10 内继续补脑，而是由 Room 1 / User 明确 pin `post-P3.3.10` 的下一推进主题；若继续 owner-shift 方向，则必须单开下一轮 fuller-cutover execution / exit-candidate / DB-API uplift-readiness round。**
