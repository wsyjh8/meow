# BR-OPP-001_v0.2.14
**Project:** 背单词喵喵 App  
**Owner:** Room 3  
**Type:** Business Rules / Governance SSOT Candidate / full merged baseline  
**Status:** incremental sync patch / ready for Room 1 review  
**Version:** v0.2.14  
**Last updated:** 2026-04-11  
**Base merge:** `BR-OPP-001_v0.2.13.md` + `P3.3.12 closeout inputs`  
**Merge policy:** 保留 `v0.2.13` 的 full BR 结构，并将 P3.3.12 已收口的规则吸收为单文件可读的增量主文档候选

---

## 0. 文档目标

本文件不是 PRD 摘抄，也不是 UI / DB / API 的替代品。  
本文件的目标只有一个：

> **把当前项目里已经跨产品、数值、DB / API、UI、测试同时引用的业务规则，收口为可版本化、可检查、可回写的 BR 资产。**

本稿重点处理：
1. 已可冻结的跨文档业务规则
2. 仍需保持 `Pending Decision` 的关键规则
3. 高风险边界用例
4. 术语 / 命名映射
5. 冲突优先级与回写要求

---

## 1. 规则范围

本 BR 只覆盖当前 MVP / 主机制优先阶段最需要统一的业务规则，不覆盖完整产品细节。

### 1.1 本稿覆盖
1. 产品定位与主副机制边界
2. 主机制事实的真相源规则
3. 今日目标 / 部分完成 / 全部完成规则
4. Session / check-in / streak / learning day 相关规则
5. 奖励来源、结算、到账、防重规则
6. 高风险文案与状态表达边界
7. 命名与术语映射
8. 冲突优先级与 pending 收口方式

### 1.2 本稿不覆盖
1. 完整熟练度算法
2. 完整 SRS / 复习调度算法
3. 具体 UI 结构与视觉方案
4. 具体 DB 字段设计细节
5. 具体 API 请求/响应全文
6. 完整副机制宠物域、商店域、装扮域规则

---

## 2. 输入依据（active runtime basis + sync candidate basis）

### 2.1 Current active runtime basis
#### Runtime / Product / Design
- `背单词养猫app项目介绍书_v0.1.1_P3.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `背单词喵喵app_副机制prd_v_0.md`
- `背单词喵喵app_副机制数值草案_v_0.md`
- `UI_SPEC_v0.3.3.md`

#### Governance / Runtime SSOT
- `ORG_v0.3.1.md`
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `Main_updated_2026-04-10_v32.md`
- `STATUS_updated_2026-04-10_v30.md`
- `BR-OPP-001_v0.2.13.md`（latest BR review basis / patch base for this round）

#### Current active DB / API baseline
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

### 2.2 Sync candidate inputs for this patch
- `R1_P3_3_12_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_Tech_Note_v0.1.md`
- `R3_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_UI_Preflight_v0.1.md`
- `Main_updated_2026-04-10_v32.md`
- `STATUS_updated_2026-04-10_v30.md`

> Note:
> 1. 本稿以上述 current review basis 为准，并以 `P3.3.12 — Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment Round` 的推进层事实作为吸收边界。
> 2. 本稿目标不是重写整份 BR，而是在 `BR-OPP-001_v0.2.13.md` 的 full BR 结构上，增量吸收 P3.3.12 已收口、且已被 Room 1 同意进入主 BR 回写的规则。
> 3. 本稿只吸收 **已能跨 BR / UI / DB / API / TEST 稳定引用** 的 P3.3.12 规则；fuller-cutover absorb judgment / true-exit-gate judgment / uplift-absorb judgment 的结果仍不得被写成 runtime owner shift completed、ReviewPage local-serving full runtime cutover、`review_group` true exit 已生效、active DB/API baseline uplift absorbed、cleanup / old-path purge、final fact owner shift、auto-routing runtime、unified planner / planner merge、DB schema rewrite、API core semantics rewrite 等既成事实。
> 4. 当前 runtime active baseline 仍以后续被 Room 1 pin 的版本为准；本稿只是供 Room 1 review / pin 的增量主文档候选。

## 3. 当前结论总览（Room 3 judgment）

### 3.1 已冻结（Frozen now）
当前已足够跨文档一致、且按 Room 1 已接受的 P3 rules freeze 收敛结果，可进入本轮 BR 增量回写的规则有：
1. **学习优先，副机制承接，不得反向主导主学习链路**
2. **主机制事实以后端为准；副机制只能消费主机制事件，不得自造学习事实**
3. **奖励展示 ≠ 奖励到账；必须区分来源事件结算状态与账本到账状态**
4. **部分完成 ≠ 全部完成；本轮完成 ≠ 今日完成**
5. **所有会推进进度或发奖的关键写操作必须幂等，且不得重复发奖**
6. **统一主命名：`daily_goal_status` / `session_validation_status` / `reward_settlement_status`**
7. **`daily_goal_status` 已冻结为“今日新词目标 + 今日复习要求”双因素口径；不包含 Session、也不包含签到；当日无待复习内容时，复习要求自然满足**
8. **`session_validation_status` 已冻结 MVP 阈值：正常启动 + 正常结束 + 达到当前配置时长（MVP 默认 15 分钟）+ Session 内至少 5 次 `effective learning / effective review attempts` 总和，才记为 `valid`；否则校验完成后记为 `invalid`**
9. **主机制结算浮层与副机制承接页边界已冻结：结算浮层只承接本轮学习结果、展示 `daily_goal_status` / `session_validation_status` / `reward_settlement_status` 与奖励摘要，并给出弱次级 CTA；不得在该层做副机制深操作，也不得把“结算已触发 / 已展示”写成“奖励已到账成功”**
10. **`review_group` 最小业务契约已冻结：它是后端生成、后端持有的一次有限复习批次对象；同一用户同一时刻只允许一个 active group；允许同一 active group 跨 Session 延续完成；同一 group 只能唯一完成、唯一结算、不得重复发奖**
11. **“本组复习完成”只推进“今日复习进度”，不自动等于“今日复习完成”或 `daily_goal_status=completed`**
12. **当前 MVP 下，`check_in` / `learning_day` / `streak` 是三类独立事实；`streak` 当前 basis = `check_in`**
13. **`check_in` 成功不自动等于 `learning_day` 成立；`learning_day` 成立也不自动等于 `streak` 延续**
14. **主副机制边界的 UI / API / DB 表达必须服从同一状态语义，不得各自发明平行叫法**
15. **P3 本轮允许 CTA winner 进入“更完整优先级算法”阶段，但当前只冻结到规则层的判定层级 + decision-support 边界：Today 仍永远只有一个最强主 CTA；active `review_group` continuation 继续保持最高优先级；无 active group 但存在后端确认的待复习 / 高优先复习任务时，允许 `go_review` 高于 `go_new_words`；Session 在 P3 可进入更完整优先级仲裁，但默认仍不是自动最高优先级**
16. **P3 本轮允许 review system 进入 structured deepening，但只冻结到“最小合同继续成立 + grouping / readiness / progress / priority 的进入边界”：`next_group_readiness` / progress summary 若未来进入，必须以后端聚合结果为准，前端不得凭 remaining count、自身计数或页面状态自行推断；review priority 最多深化到“有限可检查的优先级组合”，不自动等于完整评分引擎**
17. **P3 本轮允许 statistics 从 `summary-first` 进入“独立 minimal page / deeper minimal product 判断”阶段，但当前只冻结进入判断边界：默认保守基线仍为 `summary-first`，未获得 Room 1 进一步 pin 前，不自动新增 route / 一级导航 / 页面级回归范围；“学习天数”继续必须基于 `learning_day`**
18. **P3 本轮允许 `streak` 进入 future basis 的正式决策准备阶段，但当前 runtime truth 继续保持 `streak_basis_type = check_in`；本轮只允许冻结决策与兼容策略边界，不自动实施 basis switch，不自动修改 active contract，不自动引入补签 / 宽限逻辑**

### 3.1B 已冻结（P3.1 direct-scope delta）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.1 direct-scope delta 规则有：
1. **`upload success` / `download success` / `restore success` 是三层不同成功语义，必须严格分开**
2. **`download completed / snapshot fetched` 本身不改变本地 runtime state；只有 `apply success / restore success` 才允许改变本地持久化结果**
3. **restore / download-to-local 当前仍属 manual-only 边界，不得写成 full sync / real-time sync / merge / auto restore**
4. **restore 必须具备 `pre-check + warning + confirm`，且不得 silent overwrite**
5. **restore warning 至少必须覆盖：作用对象、覆盖风险、非自动同步系统定位；覆盖风险需显式包含最小设置层（例如 `daily_goal`）可能被覆盖**
6. **`daily_goal` 修改后本地保存成功即当天即时生效；新值只影响当前设置生效后的今日 / 后续目标判断**
7. **`daily_goal` 不回溯重算历史 `daily_goal_status`、历史统计、或 `check_in / learning_day / streak` 事实**
8. **非法输入不得静默失败；至少需覆盖空值、非数字、小数、负数、0、超过上限、过长字符串、粘贴异常字符**
9. **`1–500` 当前仅是 Room 2 recommended validation range，可作为实现 / 测试参考，但未自动升格为长期 frozen business rule**
10. **当前继续明确 out of scope：full sync、background sync、multi-device merge、partial restore、snapshot picker、delete backup、clear local、destructive actions bundle**

### 3.1C 已冻结（P3.3 first-pass closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3 / P3.3.1规则有：
1. **首页可以新增“背单词”主入口，且它属于学习主线强入口；但它不自动改写当前 active BR 中与 Today / CTA winner / review continuation 相关的既有规则**
2. **Study / Review 的 4 按钮本质是 `rating input`，不是“已掌握 / 已完成 / 已到账”这类结果事实**
3. **4 按钮的内部语义顺序必须与 FSRS 四档保持单调一致：`again -> hard -> good -> easy`，并且 Study / Review 两页不得出现顺序错位**
4. **本轮“两字中文要求”可以冻结到 requirement 层：按钮必须是两个字、必须表达 rating input、不得夸大成结果事实；但四个最终词面继续保持 candidate，不自动升格为 active copy**
5. **P3.3 第一拍只冻结到“首页学习入口 + Study/Review 4 按钮 rating input + 最小 submit / throttle / bridge + 复习规划 preflight 边界”**
6. **ReviewPage 当前继续以云端 `review_group` 作为主队列 / 主真相层；本地 FSRS 在第一拍只允许作为本地调度 / side-effect bridge，不替代 `review_group` 的队列、continuation 或结算真相**
7. **P3.3 第一拍未触碰 DB schema / API 核心语义 / 奖励结算主链路 / `review_group` 最小合同；任何下游实现、UI 或测试都不得把本轮写成“完整 FSRS 产品 / 完整复习规划已完成”**

### 3.1A 条件冻结（Conditional frozen guardrails; not evidence that Option A is already active）
以下 3 条规则内容可作为 **post-P2 persistence cutover** 的 guardrails 候选；**仅当 Room 1 正式 pin Option A，并进入 migration / cutover / degraded-state 实施窗口后，才作为实现与测试强断言执行**：
19. **若进入 post-P2 persistence cutover，Today / Secondary / Customize 相关关键链路不得出现 PostgreSQL / JSON 混源真相层**
20. **若迁移窗口进入 maintenance / read_only / temporarily_unavailable，写操作必须返回可识别的降级语义，不得用 generic error 或假成功替代**
21. **`displayed snapshot` / 只读快照 ≠ `fresh backend truth` ≠ success；迁移窗口内不得把快照展示写成“刚刚已完成 / 已到账 / 已刷新成功”**

### 3.1D 已冻结（P3.3.1 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.1 收口规则有：
1. **Study / Review 4 按钮最终两字中文词面已冻结为：`不认识 / 模糊 / 记得 / 秒答`，并固定映射到 `Again / Hard / Good / Easy`**
2. **上述 final wording 继续服从 `rating input` 边界：不得被解释成 mastery / result fact；`掌握 / 已会 / 会了 / 完成 / 熟练 / 记住了 / 奖励到账 / 已更新计划 / 已同步复习安排` 等词不得作为本轮 final wording 或点击后的主反馈**
3. **ReviewPage FSRS bridge 在 P3.3.1 本轮正式收口到 `controlled best-effort`：继续 `cloud-first`、允许 `idempotent init / ensure`、bridge failure 继续 non-blocking，但 fallback 必须在 dev/test 侧可观察**
4. **`previewDurations` 在 P3.3.1 当前轮正式保持 deferred：不进入 active contract、不进入当前 UI 稳定可见事实、不进入当前 DB / API / review contract**
5. **P3.3.1 本轮仍不是主契约扩张：不改 DB schema / API core semantics / `review_group` 最小合同 / planner owner；任何下游实现都不得把本轮写成“完整 FSRS 产品 / 完整复习规划已完成”**


### 3.1E 已冻结（P3.3.2 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.2 收口规则有：
1. **`session_entry_policy_v1` 已冻结：`home_word_entry = study_default`；首页“背单词”当前继续默认进入 `StudyPage`，不是 review dispatcher，也不是 mixed / auto-routing dispatcher**
2. **active `review_group` continuation 继续高优先，但当前只允许通过独立 CTA / helper / priority block 承接；它不等于 silent reroute，也不等于吞掉默认 `/study` 入口**
3. **`planner_owner_split_v1` 已冻结：ReviewPage 的 queue / continuation / completion / settlement truth owner 继续是 cloud `review_group`**
4. **local FSRS 当前继续是 device-side scheduling owner：负责 local card state、rating → interval / stability / difficulty 的设备侧运算、review logs、`init / ensure-local-card-state` 与 future preview / local planning 的候选能力来源**
5. **ReviewPage 当前继续保持 `cloud-first + local side-effect`：cloud submit first、local FSRS side-effect second、local failure non-blocking、fallback 保持 dev / test 可观察**
6. **P3.3.2 当前只进入“默认入口语义 + owner split 的窄合同层”，不进入 mixed / auto-routing / unified planner / planner merge / stronger planner explanation / `previewDurations` future re-entry 等更深合同**


### 3.1F 已冻结（P3.3.3 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.3 收口规则有：
1. **`review_readiness_policy_v1` 已冻结：页面级 readiness truth 继续以 cloud aggregate / review-serving layer 为准；local FSRS 只作为 scheduling candidate input，不直接升格为页面 readiness truth**
2. **P3.3.3 当前正式接受 4 个最小 readiness 语义：`ready_now` / `not_ready_now` / `next_group_eligible` / `temporarily_unservable`；它们都属于 serving-layer 语义，不得被 local-only 推断冒充**
3. **`review_priority_policy_v1` 已冻结最小层级顺序：active `review_group` continuation > cloud-confirmed due review > cloud-confirmed high-priority review > new words > session；只冻结 hierarchy，不冻结完整 scoring**
4. **`review_group_generation_policy_v1` 已冻结最小边界：generation owner 继续在 cloud review-serving layer；active group completion 是 next-group 进入前提之一；`next_group_eligible` ≠ `next_group_generated`；exact group size 继续 pending**
5. **`schedule_source_contract_v1` 已冻结最小 truth split：local FSRS 继续输出 scheduling candidate signals，cloud `review_group` 继续承担 serving outputs；owner split 不等于 planner merge / unified planner**
6. **`previewDurations` 在 P3.3.3 当前轮继续保持 deferred：不进入 active contract、不进入当前 UI 稳定事实、不作为当前执行 winner，也不得写成“下次将在 X 天后复习”这类稳定计划事实**



### 3.1G 已冻结（P3.3.4 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.4 收口规则有：
1. **`preview_durations_reentry_contract_v1` 已冻结到最小 re-entry 合同：`previewDurations` 当前若回归，source 只能是 local FSRS preview candidate；它不是 cloud serving truth，也不是稳定计划事实**
2. **preview 当前只允许进入 StudyPage，且只允许以 `hint / estimated / reference-only` 的极轻 secondary hint 形态出现；ReviewPage 与首页继续禁止显示 preview**
3. **preview 必须显式带“预计 / 仅供参考”语气，且不得参与 readiness truth、priority truth、generation truth、route decision、settlement / reward / group completion**
4. **当前继续明确的 preview fact-copy 禁区包括：`下次将在 X 天后复习`、`系统已安排`、`已更新计划`、`已同步复习安排`、`云端与本地已统一` 等会把候选提示误写成计划事实的表达**
5. **`reviewpage_stronger_bridge_contract_v1` 已冻结到 stronger-but-still-non-blocking 的最小合同：cloud submit success 不因 local bridge fail 回滚；local failure 继续 non-blocking；允许 stronger `ensure-local-card-state / init`、precondition gating、observability floor 与 minimal repair path**
6. **stronger bridge 当前仍不得引起 planner owner shift / planner merge / unified planner，也不得改 DB schema / API core semantics，更不得产生任何用户可依赖计划事实**

### 3.1H 已冻结（P3.3.5 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.5 收口规则有：
1. **`planner_owner_shift_v2` 当前只冻结到 target-state candidate 层：future local FSRS / local scheduler 可接受为 primary planning owner 方向，但不得被写成 current runtime owner shift 已完成**
2. **owner 必须继续拆成 planning owner / serving owner / fact-settlement owner 三层；local planner owner shift 不自动带出 serving owner shift，更不自动带出 fact / settlement owner shift**
3. **`review_serving_contract_v2` 当前只冻结到 current runtime truth + compatibility / deprecation path：ReviewPage current serving truth 继续是 cloud `review_group`；future local-serving 只作为 target-state candidate，不得写成现行页面真相**
4. **`session_entry_and_routing_v2` 当前只冻结“future routing 会受 owner shift 影响”的边界；runtime 继续保持 `home_word_entry = study_default` + active continuation 高优先但不得 silent reroute**
5. **`preview_and_explanation_contract_v2` 当前只冻结到 future planner-facing explanation candidate 边界：preview / explanation 未来可升格，但当前仍不得写成 committed plan fact；ReviewPage / 首页 preview 进入仍继续后置到下一层 gate**
6. **`backup_restore_and_cross_device_boundary_v2` 已冻结最小安全合同：`backup success / restore success / sync success` 三层语义继续严格分开；restore 继续 manual only + pre-check / warning / confirm；restore apply 之后目标设备本地 planner state 才成为该设备新的 runtime truth；cloud latest backup 只是 recovery artifact，不等于 cross-device consistency**
7. **`migration_and_deprecation_plan_v1` 已冻结 staged rollout 边界：当前只允许进入 compatibility / deprecation markers、shadow / parity preparation、regression scope preparation；不得跳过兼容层直接切主链路**

### 3.1I 已冻结（P3.3.6 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.6 收口规则有：
1. **`local_serving_candidate_contract_v1` 已冻结最小兼容边界：`local_due_queue_candidate` / `local_generated_review_session_candidate` 当前都只表示 future local-serving 候选实体；它们只允许进入 compatibility contract / shadow parity / adapter seam，不得被写成 current ReviewPage truth**
2. **future queue source 当前只冻结字段组语义：`source_type / source_id / owner_layer / shadow_only / candidate_reason / generated_at / item_count / serving_eligibility_state`；它们当前只表示存在必要性与语义边界，不自动等于 current DB / API core semantics 已改**
3. **compatibility contract 与 shadow-only 必须显式分开：local-serving candidate 概念实体、元语义字段组、serving eligibility 边界与 adapter seam 可进 compatibility contract；真实 serving 顺序、真实用户承接、直接接管 item stream、直接触发 completion / settlement 只进 shadow / parity**
4. **`review_group_compatibility_posture_v1` 已冻结为三层并存：`review_group` 当前仍是 runtime serving owner，同时也是 compatibility anchor 与 deprecated candidate；它既不是“完全不变”，也不是“已退场完成”**
5. **`fact_settlement_ingest_contract_candidate_v1` 已冻结最小边界：planner / serving owner shift 不自动带出 fact / settlement owner shift；local-serving candidate 当前只允许进入 fact ingest candidate / shadow evidence 层，不得直接改账本、今日目标完成、streak / learning_day 等最终事实**
6. **`session_entry_and_routing_compat_v1` 已冻结 current runtime truth 不变：首页继续 `home_word_entry = study_default`，active continuation 继续高优先但不得 silent reroute；future routing 只允许进入 shadow / candidate / helper rewrite 边界**
7. **`deprecation_markers_and_writeback_plan_v1` 已冻结最小写法：本轮至少显式区分 `runtime truth / compatibility-only / deprecated candidate / shadow-only evidence` 四层；write-back 不能只停在单一文档**
8. **`shadow_parity_test_strategy_v1` 已冻结最小测试分层：当前至少区分 `runtime truth regression / shadow parity evidence / marker-contract-only tests`；flags / seams 当前只允许作为 shadow-entry preparation，默认不得打开，更不得改变 current runtime truth**

### 3.1J 已冻结（P3.3.7 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.7 收口规则有：
1. **`shadow_execution_scope_v1` 已冻结最小边界：`local_due_queue_candidate`、`local_generated_review_session_candidate`、`fact_ingest_shadow_evidence` 与 `routing_shadow_candidate` 当前都只允许进入 limited execution / dev / flag / QA evidence 层，不得进入用户主路径或 current runtime truth**
2. **`shadow_result_visibility_v1` 已冻结可见性边界：shadow 结果当前只允许被 dev / test、internal debug / log、QA evidence、patch draft / closeout 摘要以及治理层文档看见；绝不允许进入用户可见层**
3. **`review_group_shadow_compat_v1` 已冻结当前姿态：`review_group` 继续是 ReviewPage current runtime owner，同时也是 shadow compare baseline；local-serving 继续只做 shadow candidate，不得被写成 current serving truth**
4. **`fact_ingest_shadow_evidence_v1` 已冻结最小 evidence 边界：local fact ingest 当前只比较 accept / reject / duplicate、attempt / progress / completion candidate evidence 与 parity completeness；不得直接改 ledger / daily_goal / streak / learning_day / settlement 最终事实**
5. **`mismatch_severity_rule_set_v1` 已冻结四层分级：`info_only_mismatch`、`warning_mismatch`、`must_hold_mismatch`、`must_escalate_mismatch`；凡触碰 current runtime truth、`review_group` current owner posture、final fact owner、或用户可见 overclaim 的 mismatch，都不得按可带着走的 warning 处理**
6. **`shadow_acceptance_gate_v1` 已冻结最小通过门：pass 先看 guardrails 是否守住——current runtime truth 未被偷切、shadow 结果未漏到用户端、`review_group` posture 未被破坏、final fact / settlement truth 未被 shadow 改写、parity compare / evidence path 可被稳定记录——再看 parity 是否逐步稳定**
7. **`fact_copy_guardrails_v1` 已冻结 shadow 文案边界：`shadow / candidate / internal-only / parity evidence / compare result / debug only / not current runtime truth` 只允许存在于 internal docs / debug panel / QA evidence / patch 附件；`已切换到本地规划 / 本地已接管复习 / review_group 已退场 / 已自动安排学习路径 / shadow compare 已通过因此已完成切换` 等表达继续是禁区**
8. **`shadow_to_phase3_gate_v1` 已冻结当前结论：Phase 2 的任务是收集可解释、可复现、可回归的 shadow evidence；即使影子结果看起来更合理、与 cloud baseline 大体一致，也不自动升格为 runtime fact，更不自动支持 cutover**


### 3.1K 已冻结（P3.3.8 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.8 收口规则有：
1. **`phase3_gate_decision_v1` 已冻结最小 gate 结论层：当前只允许产生 `proceed_to_next_layer_candidate_review / hold / revise / escalate` 四类结论；不得把 gate 结论写成 runtime owner shift completed、local-serving cutover completed、`review_group` 已正式退场、或 unified planner 已成立**
2. **进入 Phase 3 gate 的最低门槛已冻结：shadow evidence 必须同时满足 current runtime truth 未被偷切、shadow 结果未漏到用户端、`review_group` current owner posture 未被破坏、final fact / settlement truth 未被 shadow 改写、mismatch 分级稳定可回归、且证据可被明确解释；“看起来更合理”本身不足以进入下一层**
3. **`limited_cutover_scope_candidate_v1` 已冻结 very narrow candidate subset 边界：下一层最小切口只允许先讨论 `review_group` exit 条件判断准备、fact ingest stronger-path candidate、helper / summary / state contract migration prep、DB / API seam candidate formalization、rollback / hold / migration note baseline；不得把其写成 ReviewPage local-serving runtime cutover、auto-routing runtime、unified planner / planner merge、或 final fact owner shift**
4. **serving source 不得先于 fact boundary 被偷切：即使 future serving source 要变化，也不得在 final fact / settlement / daily_goal / streak 的最终事实边界未写硬前先把 serving source 切成 runtime truth**
5. **`review_group_exit_gate_v1` 已冻结最小退场判断边界：`review_group` 当前继续保持 current runtime serving owner + compatibility anchor + deprecated candidate；只有当 contract / test / doc / boundary 四类前置条件都具备时，才有资格进入真实退场判断；“可讨论 exit gate” ≠ “当前轮立刻退场”**
6. **`fact_settlement_cutover_boundary_v1` 已冻结当前最终事实护栏：即使进入 Phase 3 gate，有效复习事实、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准；local evidence 最多只允许进入更强的 ingest path candidate，不允许越权成 fact owner**
7. **`phase3_writeback_and_migration_v1` 已冻结最小治理要求：write-back 顺序必须先规则护栏，再技术候选，再 UI 迁移，再由 Room 1 统一吸收；migration note / rollback note / hold note 必须成套出现；`runtime truth / compatibility-only / deprecated candidate` 三层切换条件必须继续显式分开**
8. **P3.3.8 当前继续明确：这是 gate / candidate / migration round，不是 cutover round；任何“已切到本地规划 / `review_group` 已退场 / 本地已接管复习 / 已自动安排学习路径 / cutover 已完成 / 本地结果已写回最终事实”的表达，继续属于 overclaim 禁区**

### 3.1L 已冻结（P3.3.9 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.9 收口规则有：
1. **`first_cutover_rule_set_v1` 已冻结最小 first-cutover 边界：第一轮 cutover 当前只允许切 ReviewPage 内部 serving seam 的 very narrow subset；首页 `study_default`、active continuation、`review_group` 真退场、final fact owner 与 DB/API baseline uplift 都不进入当前切口**
2. **本轮若叫 first cutover，就必须真的切一个 runtime seam；只改 helper / 文案 / state contract 而完全不触碰 seam，不算 first cutover；同理，也不接受“先切 final fact stronger-path，再补 serving seam”的倒序**
3. **`runtime_truth_switch_boundary_v1` 已冻结：当前唯一允许进入 first-cutover 讨论的 runtime-truth switch 候选，是 ReviewPage 内部“当前一组复习项从哪里来”的极小 serving seam；首页入口 truth、completion truth、reward / settlement truth、planning / unified planner truth 当前都不得跟着切**
4. **P3.3.9 当前继续写死 5 条 runtime truth 不变：`home_word_entry = study_default`、active continuation 独立承接且不得 silent reroute、`review_group` 当前继续是 current runtime serving owner、final fact / settlement truth 继续以后端为准、preview / explanation 不得借本轮升级成 committed plan fact**
5. **`review_group_retained_anchor_v1` 已冻结 dual posture：`review_group` 在本轮既不是“继续只做 current owner”，也不是“立即退场”，而是 `current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate`；active continuation identity、current completion gating、current settlement trigger、rollback target 与 non-cutover baseline path 当前仍必须继续走 `review_group`**
6. **`fact_owner_guardrail_v1` 已冻结当前红线：即使 ReviewPage 内部 serving seam 进入 first cutover，有效复习事实、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准；local-serving 结果最多只允许进入更强的 ingest path candidate，不允许带出 final fact owner shift**
7. **`db_api_cutover_candidate_v2` 已冻结最小技术边界：当前只允许与 first-cutover seam 直接相关的 serving source descriptor seam、retained-anchor / fallback marker seam、stronger ingest path minimal seam、rollback / hold / observability seam 升到 first-cutover-ready；DB schema rewrite、endpoint core semantics rewrite 与 active baseline uplift 继续禁止**
8. **`rollback_holdnote_and_observability_v1` 已冻结 first-cutover 的最低前置条件：rollback target 必须明确指向 `review_group` current runtime path；必须有明确的 hold / rollback 触发条件、回退后用户可见 truth 不变声明，以及 seam hit / fallback hit / stronger ingest candidate accept-reject-duplicate / hold trigger / overclaim guard check 等最小 observability 证据位**
9. **P3.3.9 当前继续明确：这是 first very narrow cutover preflight，不是 full cutover，也不是 cleanup / exit / baseline uplift 合并轮；任何“已切到本地规划 / 本地已接管复习 / `review_group` 已退场 / cutover 已完成 / 本地结果已写回最终事实 / 新主链路已生效”的表达，继续属于 overclaim 禁区**

### 3.1M 已冻结（P3.3.10 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.10 收口规则有：
1. **`fuller_cutover_rule_set_v1` 已冻结 judgment 边界：下一拍 fuller cutover 当前只允许从 P3.3.9 的 ReviewPage non-continuation serving seam，扩大到 continuity-adjacent、仍不碰首页 `study_default` route / active continuation path / final fact owner 的 very narrow next subset**
2. **fuller cutover 扩大 serving subset ≠ final fact owner 扩大层级：有效复习事实、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准；local stronger ingest path 当前最多只允许进入 uplift-judgment-ready / stronger-path-ready，不得升格为 fact owner**
3. **`review_group_exit_gate_v2` 已冻结最小退场判断边界：`review_group` 当前仍必须继续保持 `current runtime serving owner + retained fallback anchor + compatibility anchor + deprecated candidate`；只有 contract / test / doc / runtime / boundary 五类前置条件都齐，才有资格进入真实 exit judgment**
4. **`retained_anchor_to_exit_transition_v1` 已冻结顺序边界：retained anchor → exit candidate 的过渡，当前只允许先讨论哪些 fallback / rollback 可以缩窄、哪些路径仍保留 `review_group`、哪些路径已不再需要 `review_group`；不允许先删 current owner 身份，也不允许先把 `review_group` 降成 purely historical object**
5. **`db_api_uplift_judgment_v1` 已冻结最小判断层：当前只允许把与 fuller cutover 直接绑定的 serving source descriptor seam、retained-anchor / fallback marker seam、stronger ingest path minimal seam、rollback / hold / observability seam、以及 source-neutral helper / summary / state contract seam 升到 uplift-judgment-ready；不允许 active DB/API baseline uplift absorbed，更不允许 DB schema rewrite / API core semantics rewrite**
6. **`phase4_writeback_order_v1` 已冻结最小治理顺序：write-back 必须先写 Room 2 judgment note，再写 Room 3 rules note，再写 Room 5 UI preflight，再由 Room 1 absorb / pin；当前只能把 fuller cutover / exit-gate / uplift 写成 judgment，最多只允许 very narrow next subset、rollback / hold / observability floor、source-neutral helper / summary / state migration prep 进入 execution-ready candidate**
7. **P3.3.10 当前继续明确：这是 fuller-cutover judgment / exit-gate / uplift judgment round，不是 full cutover completed round；任何“已切到本地规划 / 本地已接管复习 / `review_group` 已退场 / 新主链路已生效 / cutover 已完成 / active DB/API baseline 已升级 / uplift 已 absorbed / 本地结果已写回最终事实”的表达，继续属于 overclaim 禁区**

### 3.1N 已冻结（P3.3.11 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.11 收口规则有：
1. **`fuller_cutover_execution_rule_set_v1` 已冻结 execution-ready 边界：当前只允许把 wider subset 扩大到 `ReviewPage continuity-adjacent serving-adapter family`、与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层、首页 review helper / summary / no-review-state 的 retained-anchor-aware prep，以及 rollback / hold / fallback 的中性 copy / state contract prep**
2. **P3.3.11 当前明确禁止扩大到：首页默认主 route 切换、active continuation source switch、user-visible planner-aware route / auto-routing runtime、`review_group` true exit、final fact owner shift、以及 active DB/API baseline uplift absorbed；execution-ready subset 只表示具备进入更完整但仍 very narrow 的执行准备层，不表示 full cutover execution 已完成**
3. **`review_group_exit_candidate_v1` 已冻结当前边界：`review_group` 仍必须继续保持 `current runtime serving owner + retained fallback anchor + compatibility anchor + deprecated candidate`；本轮只允许进入 exit-candidate 前置条件判断、retained-anchor 依赖路径 future-narrowable 判断、rollback / fallback scope future-narrowable 判断，以及 helper / summary / CTA / empty-state 先脱离 group-only wording 的准备**
4. **在 P3.3.11 当前轮，以下路径仍必须继续显式依赖 `review_group`：active continuation identity、completion gating、settlement trigger、rollback target、以及 non-cutover / non-upgraded sessions baseline path；retained anchor 当前只允许缩窄 source-neutral helper / summary wording、首页 review helper / empty-state / no-review-state 的 retained-anchor-aware 表达，以及 rollback / fallback 说明中的历史性冗余 wording**
5. **`db_api_uplift_readiness_v1` 已冻结最小 readiness 边界：当前最多只允许 serving source descriptor seam、retained-anchor / fallback posture seam、stronger ingest path minimal seam、rollback / hold / observability seam、以及 source-neutral state / helper / summary contract seam 进入 uplift-readiness；`review_group` true-exit、active continuation source switch、final fact owner shift、homepage route / planner-aware route 相关 seam 当前仍只能停留在 migration / hold / rollback 层**
6. **`cutover_vs_fact_owner_boundary_v3` 已冻结当前红线：即使 fuller-cutover execution 前进一步，有效复习事实、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准；local stronger ingest candidate 最多只允许进入 validated stronger-ingest candidate execution layer，不允许升格为 final fact owner**
7. **P3.3.11 当前继续明确：这是 fuller-cutover execution / exit-candidate / uplift-readiness round，不是 full cutover completed / true exit / uplift absorbed round；任何“已切到本地规划 / 本地已接管复习 / `review_group` 已退场 / 新主链路已生效 / cutover 已完成 / 本地结果已写回最终事实 / active DB/API baseline 已升级 / uplift 已 absorbed / 现在已经可以清理旧 path”的表达，继续属于 overclaim 禁区**

### 3.1O 已冻结（P3.3.12 closeout）
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3.12 收口规则有：
1. **`fuller_cutover_absorb_candidate_v1` 已冻结 absorb-candidate judgment 边界：当前只允许把 P3.3.11 的 widened execution-ready subset 提升到 fuller-cutover absorb judgment；允许进入判断的 widened family 仍只限于 `ReviewPage continuity-adjacent serving-adapter family`、与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层、首页 review helper / summary / no-review-state 的 retained-anchor-aware contract、rollback / hold / fallback 的中性 copy / state contract，以及 stronger-ingest execution-ready binding prep**
2. **P3.3.12 当前明确禁止扩大到：首页默认主 route 切换、active continuation source switch、user-visible planner-aware route / auto-routing runtime、`review_group` true exit、final fact owner shift、active DB/API baseline uplift absorbed、以及 cleanup / old-path purge；absorb-candidate judgment 只表示“已具备进入下一层 fuller-cutover absorb 审查的资格”，不表示当前已经 absorbed into runtime truth**
3. **`review_group_true_exit_gate_v1` 已冻结最小 true-exit-gate judgment 边界：`review_group` 当前仍必须继续保持 `current runtime serving owner + retained fallback anchor + compatibility anchor + deprecated candidate`；当前只允许判断 contract / runtime / test / doc / fallback 五类条件是否已足够进入 true-exit gate，不允许把它写成 true exit、fallback-only、historical-only、或可直接清理**
4. **在 P3.3.12 当前轮，只要以下 still-dependent paths 任一仍未被清晰替代，`review_group` 就不得进入 true exit：active continuation identity、completion gating、settlement trigger、rollback target、non-cutover / non-upgraded sessions baseline path、以及 compatibility anchor / QA baseline reference；即使条件逐步齐备，也只代表“可讨论是否进入 true-exit gate”，不代表当前轮已开始 true exit 或 cleanup**
5. **`db_api_uplift_absorb_judgment_v1` 已冻结最小 absorb-judgment 边界：当前最多只允许 serving source descriptor seam、retained-anchor / fallback posture seam、stronger-ingest path minimal seam、rollback / hold / observability seam、以及 source-neutral state / helper / summary contract seam 进入 uplift-absorb judgment；`review_group` true-exit、active continuation source switch、final fact owner shift、homepage route / planner-aware route、以及 DB schema rewrite / API core semantics rewrite 相关 seam 当前仍只能停留在 marker / migration / rollback / hold 层**
6. **`cutover_vs_fact_owner_boundary_v4` 已冻结当前红线：即使 fuller-cutover judgment 前进一步，有效复习、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 与 completion / 到账类主反馈当前仍必须以后端 / cloud fact layer 为准；local stronger-ingest path 最多只允许进入 absorb-judgment-level candidate，不允许升格为 final fact owner**
7. **`exit_candidate_to_true_exit_transition_v1` 已冻结当前不可动骨架：rollback target 仍必须继续固定为 `cloud_review_group_current_runtime_path`；current visible owner 身份、retained fallback anchor 身份、active continuation 当前承接路径、以及 completion gating / settlement trigger 的解释通路当前都不得提前改动；本轮只允许讨论这些 future change 的触发条件，不允许写成已经发生**
8. **`phase6_writeback_order_v1` 已冻结最小治理顺序：write-back 仍必须先 Room 2 tech note，再 Room 3 rules note，再 Room 5 UI preflight，再由 Room 1 absorb / pin；当前只能把 fuller-cutover absorb candidate、true-exit-gate、uplift-absorb judgment、以及 exit-candidate → true-exit transition 条件写成 judgment；最多只允许 widened subset 的延续层、stronger-ingest absorb-candidate binding prep、source-neutral / retained-anchor-aware UI migration prep、以及 rollback / hold / observability floor 写成 execution-ready candidate**
9. **P3.3.12 当前继续明确：这是 fuller-cutover / true-exit-gate / uplift-absorb judgment round，不是 full cutover completed / true exit / uplift absorbed round；任何“已切到本地规划 / 本地已接管复习 / `review_group` 已退场 / 新主链路已生效 / cutover 已完成 / 本地结果已写回最终事实 / active DB/API baseline 已升级 / uplift 已 absorbed / true exit 已开始 / 现在已经可以清理旧 path”的表达，继续属于 overclaim 禁区**

### 3.2 仍需保持 Pending
当前不能由 Room 3 擅自拍板、必须保留 `Pending Decision` 的规则有：
1. 熟练度 / 掌握阈值
2. 完整 SRS / review priority / review_group 分组算法细节（包括 exact group size、详细权重、完整 interval / schedule）
3. CTA winner 完整优先级算法与 `today_primary_action` 是否正式进入 active contract
4. statistics 是否从 `summary-first` 进一步展开为独立 minimal page 或更深统计产品
5. 未来是否把 `streak` 从 `check_in` 改为 `learning_day` 或组合条件、是否引入补签 / 宽限逻辑，以及 basis 切换后的兼容策略
6. 首页点击“背单词”后的 mixed / auto-routing deeper session contract（是否进入复习 / 混合 / 自动分流）
7. 云端 `review_group` 与本地 FSRS 的最终 planner merge / unified planner 收敛方向
8. `StudyPage` 与 `ReviewPage` 是否长期共用一套统一学习页
9. readiness 的完整 reason enum、时间窗 / 阈值算法，以及 local-only readiness mode
10. `previewDurations` / interval preview 是否在未来进入 active contract，以及 future re-entry 的 source-of-truth / explanation 边界
11. runtime owner shift completed / ReviewPage local-serving runtime cutover
12. preview / explanation system 的完整升级范围（包括 ReviewPage / 首页是否进入）
13. full sync / real-time sync / auto merge / delta sync 是否未来重开
14. local due queue 何时允许接管 current ReviewPage truth
15. `review_group` 何时允许从 compatibility anchor / deprecated candidate 进入真正退场
16. local-serving evidence 何时允许从 ingest candidate 升格为 active fact / settlement path input
17. 第一轮 very narrow cutover 真正执行时，ReviewPage non-continuation subset 的 eligibility / stop-condition / hold-note 细粒度判定口径
18. `review_group` 何时允许从 dual posture 进一步降到 fallback-only，再进一步进入真实退场
19. stronger ingest candidate 何时允许从 pre-final-fact seam 升格到更强 active ingest path，而不构成 fact owner shift
20. first-cutover 后的 cleanup / old path purge / active DB-API baseline uplift 应拆到哪一轮、按什么前置条件进入
21. 用户可见 owner-shift / mode-switch / cutover 宣告何时才允许出现
22. fuller cutover 下一拍真正执行时，ReviewPage continuity-adjacent serving-adapter family 的最小执行子集到底先切哪一段
23. `review_group` 何时允许从 retained anchor 进入 exit candidate，再进一步进入真实 exit judgment
24. uplift-judgment-ready seam 何时才允许进入 active DB/API baseline uplift 审查，且不构成 active baseline 已升级
25. retained anchor 的 rollback / fallback 何时才允许缩窄，而仍不破坏 current runtime truth 与 rollback target
26. fuller cutover judgment 何时才允许真正升级为 Room 4 的 execution-ready handoff
27. fuller-cutover execution-ready subset 真正落地时，ReviewPage continuity-adjacent serving-adapter family 的最小执行顺序应先开哪一段
28. `review_group` 何时才允许从 exit-candidate 进入 true exit 审查，并开始缩窄 current owner / rollback target 之外的路径级依赖
29. uplift-readiness seam 何时才允许进入 active DB/API baseline uplift 审查前的 absorbed-candidate 层，而不被误写成已生效 baseline
30. validated stronger-ingest candidate execution layer 何时才允许进入更强的 active ingest path，而仍不构成 final fact owner shift
31. source-neutral / retained-anchor-aware helper、summary、empty-state 与 completion 前置说明层何时才允许被正式 pin 为 runtime-baseline UI / BR 合同

### 3.3 当前已完成的本轮收口
本轮在 `BR-OPP-001_v0.1.7.md` 基线之上，按 Room 1 已接受的 `R3_P3_Rules_Freeze_Note_v0.1.1.md` 收敛结果，新增回写以下规则：
1. CTA winner 从 Option C 的最小仲裁层级，推进到 P3 的“更完整优先级算法阶段”的规则边界，但仍不把 decision-support contract 自动写成 active truth
2. `review_group` 从最小 continuation / readiness 规则，推进到 P3 的 structured deepening 边界：允许 grouping / readiness / progress / priority 进入更深一层规则冻结，但前端仍不得自行补脑
3. statistics 从 Option C 的 `summary-first` 最小规格，推进到 P3 的“独立 minimal page / deeper minimal product 判断”边界；默认 fallback 仍为 `summary-first`
4. `streak` 从 Option C 的 future stance 记录，推进到 P3 的正式决策准备边界；当前 runtime truth 继续保持 `check_in` basis，不切换 active contract
5. 继续保留 post-P2 persistence hardening 的跨层 guardrails 为 **conditional frozen guardrails**：同源一致性、只读 / 维护窗口降级语义、以及 `displayed snapshot ≠ fresh backend truth ≠ success`
6. 新增 P3.1 direct-scope delta 的单文件合并收口：upload / download / restore success 三层语义、restore manual-only + warning/confirm/no silent overwrite、`daily_goal` 当天即时生效但不回溯历史、非法输入显式报错、以及本轮继续 out of scope 的范围
7. 新增 P3.3.1 的单文件增量收口：final wording freeze（`不认识 / 模糊 / 记得 / 秒答`）、forbidden fact-copy 边界、ReviewPage bridge 的 `controlled best-effort` 语义、以及 `previewDurations` 当前继续 deferred / 不进入 active contract
8. 新增 P3.3.2 的单文件增量收口：`session_entry_policy_v1`（`home_word_entry = study_default` + active `review_group` continuation 高优先但不等于 silent reroute）、`planner_owner_split_v1`（cloud `review_group` = ReviewPage serving truth owner；local FSRS = device-side scheduling owner）、以及 `cloud-first + local side-effect` 的最小合同边界
9. 新增 P3.3.3 的单文件增量收口：`review_readiness_policy_v1`（cloud aggregate / review-serving layer = readiness truth；local FSRS = scheduling candidate input）、`review_priority_policy_v1`（hierarchy only）、`review_group_generation_policy_v1`（generation owner + completion gating + `next_group_eligible` ≠ `next_group_generated`）、`schedule_source_contract_v1`（serving truth vs scheduling candidate split）、以及 `previewDurations` 当前轮继续 deferred / 不进入 active contract
10. 新增 P3.3.5 的单文件增量收口：`planner_owner_shift_v2` 当前只冻结到 future target-state candidate + 三层 owner split、`review_serving_contract_v2` 当前只冻结到 compatibility / deprecation path、`session_entry_and_routing_v2` 仍保持 `study_default` runtime、`backup_restore_and_cross_device_boundary_v2` 继续 strict semantic split + manual-only restore、以及 `migration_and_deprecation_plan_v1` 的 staged rollout 边界；不把 runtime owner shift / local-serving cutover / planner merge / full sync 偷升格为 frozen
11. 新增 P3.3.6 的单文件增量收口：`local_serving_candidate_contract_v1` 只冻结到 candidate / compatibility / shadow parity 层、`review_group_compatibility_posture_v1` 冻结为 current runtime owner + compatibility anchor + deprecated candidate、`fact_settlement_ingest_contract_candidate_v1` 只冻结到 ingest candidate / evidence 边界、`session_entry_and_routing_compat_v1` 继续保持 `study_default` runtime + no silent reroute、以及 `deprecation_markers_and_writeback_plan_v1` / `shadow_parity_test_strategy_v1` 的最小分层与写回要求；不把 shadow / candidate / deprecated-candidate 偷升格为 current runtime truth
12. 新增 P3.3.7 的单文件增量收口：`shadow_execution_scope_v1` 只允许 local-serving / fact-ingest / routing candidate 进入 limited execution 的 internal evidence 层、`shadow_result_visibility_v1` 固定 internal-only 可见性、`mismatch_severity_rule_set_v1` 固定四层分级、`shadow_acceptance_gate_v1` 固定 pass / acceptable mismatch / stop conditions、`fact_copy_guardrails_v1` 固定 shadow wording 禁区、`shadow_to_phase3_gate_v1` 固定“收证据 ≠ 已切换”的最小 gate；不把 shadow pass / parity evidence 偷升格为 current runtime truth
13. 新增 P3.3.8 的单文件增量收口：`phase3_gate_decision_v1` 只允许产生 proceed / hold / revise / escalate 四类 gate 结论、`limited_cutover_scope_candidate_v1` 只允许 very narrow candidate / migration subset、`review_group_exit_gate_v1` 只冻结“何时才有资格进入真实退场判断”、`fact_settlement_cutover_boundary_v1` 继续写死 backend final truth、以及 `phase3_writeback_and_migration_v1` 的 write-back 顺序 / migration note / rollback floor / hold note；不把 gate / candidate / migration 结果偷升格为 runtime cutover
14. 新增 P3.3.9 的单文件增量收口：`first_cutover_rule_set_v1` 只允许第一刀切 ReviewPage 内部 serving seam 的 very narrow subset、`runtime_truth_switch_boundary_v1` 继续写死首页 route / active continuation / final fact owner / preview explanation 不变、`review_group_retained_anchor_v1` 冻结 dual posture、`fact_owner_guardrail_v1` 继续写死 backend final truth、`db_api_cutover_candidate_v2` 只允许 seam / marker / observability / rollback floor 升到 first-cutover-ready、`rollback_holdnote_and_observability_v1` 作为 first-cutover 合同前置条件；不把 first-cutover preflight、retained anchor、或 stronger ingest candidate 偷升格成 full cutover / review_group 真退场 / baseline uplift
15. 新增 P3.3.10 的单文件增量收口：`fuller_cutover_rule_set_v1` 只允许 fuller cutover 停在 judgment 层、`review_group_exit_gate_v2` 只允许进入真实 exit judgment 的前置条件判断、`cutover_vs_fact_owner_boundary_v2` 继续写死 backend final truth、`db_api_uplift_judgment_v1` 只允许进入 uplift-judgment-ready、`retained_anchor_to_exit_transition_v1` 只允许 retained-anchor → exit-candidate 的资格条件、以及 `phase4_writeback_order_v1` 的 judgment → execution-ready candidate → runtime truth 分层顺序；不把 fuller cutover / exit / uplift judgment 偷升格为已生效事实
16. 新增 P3.3.11 的单文件增量收口：`fuller_cutover_execution_rule_set_v1` 只允许扩大到 ReviewPage continuity-adjacent serving-adapter family 与首页 review 承接层的 retained-anchor-aware execution-ready subset、`review_group_exit_candidate_v1` 只允许进入 exit-candidate 而不进入 true exit、`db_api_uplift_readiness_v1` 只允许进入 uplift-readiness seam families、`cutover_vs_fact_owner_boundary_v3` 继续写死 backend final truth、`retained_anchor_narrowing_guardrail_v1` 只允许 very narrow 缩窄 wording / helper 依赖、以及 `phase5_writeback_order_v1` 的 execution-ready / exit-candidate / uplift-readiness / runtime truth 分层顺序；不把 execution-ready、true exit、active uplift、cleanup 或 final fact owner shift 偷升格为 current runtime truth

---



## 4. 规则条目列表

> 说明：
> - `Status=Frozen`：当前可直接作为业务规则共用。
> - `Status=Pending`：必须保留待决，不得在下游实现/UI里脑补冻结。
> - `Status=Unresolved`：当前存在命名漂移或口径冲突，需要显式收口。

### BR-001 产品定位与主副机制边界
- **Status:** Frozen
- **Rule:** 本项目是**学习驱动型轻养成产品**；主机制是产品主线，副机制是承接学习结果的陪伴与成长层，不得反向干扰主学习流程。
- **Applies to:** PRD / UI / DB / API / TEST
- **Checkable:**
  1. 今日页、学习页、复习页必须以学习任务和进度为第一优先级
  2. 副机制入口在主机制页只能为弱入口
  3. 不允许通过副机制页面直接创建学习完成事实或绕开发奖上游
- **Why it is frozen:** 项目介绍书、主机制 PRD、副机制 PRD、UI review 口径一致

### BR-002 主机制事实的真相源
- **Status:** Frozen
- **Rule:** 有效学习、有效复习、今日目标完成、Session 是否有效、streak 是否成立、奖励是否到账，均以后端为准；前端只能展示，不得自行判定最终业务事实。
- **Applies to:** API / DB / UI / TEST
- **Checkable:**
  1. 前端不得仅用本地计数展示最终完成态
  2. `daily_goal_status` / `session_validation_status` / `reward_settlement_status` 必须来自后端状态
  3. 测试必须覆盖“前端有动作但后端未确认”的情况

### BR-003 副机制不得自造学习收益
- **Status:** Frozen
- **Rule:** 副机制只能消费主机制来源事件，不得自行制造学习事实、完成事实或学习收益。
- **Applies to:** 产品 / DB / API / 实现 / 测试
- **Checkable:**
  1. 奖励来源必须可追到主机制 source event
  2. 喂猫、装扮、互动不会触发“有效学习”或“今日完成”
  3. 奖励链路需保留 source event 与 ledger 的关联

### BR-004 奖励两段式规则
- **Status:** Frozen
- **Rule:** 奖励链路必须至少分成两段：
  1. **来源事件成立**（可进入结算）
  2. **奖励账本到账**（最终发放）
  UI 不得把第一段误写成第二段。
- **Applies to:** DB / API / UI / TEST
- **Checkable:**
  1. 存在来源事件状态（`reward_settlement_status`）
  2. 存在账本级奖励项状态（`reward_items[].reward_status` 或等价账本状态）
  3. UI 文案禁止把“展示成功”写成“到账成功”

### BR-005 奖励防重与幂等
- **Status:** Frozen
- **Rule:** 所有会推进进度、创建来源事件、产生账本奖励的关键写操作必须幂等；重复请求不得重复发奖。
- **Applies to:** DB / API / 实现 / TEST
- **Checkable:**
  1. 学习提交有幂等键
  2. 签到同一天不可重复成功
  3. 来源事件不可重复创建
  4. 账本不可对同一来源重复发同类奖励

### BR-006 今日完成与部分完成表达边界
- **Status:** Frozen
- **Rule:** `部分完成` 必须与 `已完成` 严格区分；`本轮完成`、`本组完成`、`签到成功`、`Session started/ended` 都不能自动等同为 `今日完成`。
- **Applies to:** UI / API / TEST / 文案
- **Checkable:**
  1. 新词完成但复习未完成时，不得展示“今日任务完成”
  2. 本组复习完成但今日复习未达口径时，不得展示“今日复习完成”
  3. Session 开始或结束但未 valid 时，不得展示“有效 Session 完成”

### BR-007 `check_in` / `learning_day` / `streak` 的当前 MVP 关系、current truth 与 P3 future-basis decision boundary
- **Status:** Frozen with pending future-basis switch
- **Rule:** 当前 MVP 下，`check_in`、`learning_day`、`streak` 是三类独立事实；P3 允许 future streak basis 进入正式决策准备阶段，但当前 runtime truth 不变。
  1. `check_in` 表示用户在当前自然日完成签到动作
  2. `learning_day` 表示用户在当前自然日完成了满足后端口径的有效学习行为
  3. `streak` 当前阶段按 `check_in` 延续
- **Decision source:** `D-OPP-001-011`（Room 1 / `R1_Decision_Pack_D-OPP-001-010_011.md`） + Room 1 已接受的 `R3_P3_Rules_Freeze_Note_v0.1.1.md`
- **Applies to:** 产品 / DB / API / UI / TEST / 统计
- **Frozen part:**
  1. 当前运行态继续保持 `streak_basis_type = check_in`
  2. `check_in=true` 只代表签到事实成立；不得自动推出 `learning_day=true`、`daily_goal_status=completed` 或“完成有效学习”
  3. `learning_day=true` 时，若 `check_in=false`，仍可成立有效学习日；但当前 MVP 下 `streak` 不延续
  4. `check_in=true` 且 `learning_day=false` 时，当前 MVP 下 `streak` 仍可按签到口径延续
  5. 三类自然日口径统一按用户时区折算后的 `local_date` 处理，并以后端为最终真相源
  6. P3 只允许把 future basis 的**决策与兼容策略边界**写硬；不自动实施切换、不自动修改 active contract
  7. P3 若未来进入 decision-support / migration-support 字段，也只表示“决策准备”，不表示 basis switch 已发生
- **Checkable:**
  1. 当前实现、文案、统计、UI 表达，都不得在本轮私自切到 `learning_day` 或组合条件
  2. 统计中“学习天数”若进入展示，必须基于 `learning_day`，不得把 `check_in` 或 `streak` 混写成学习天数
  3. Room 4 / Room 5 不得把 future decision / compatibility boundary 写成“当前已经按学习日算”
  4. 未经 Room 1 单独 pin，任何 future streak decision-support / migration-support 字段都不得被当作 current runtime truth
- **Must not do:**
  1. UI 不得把“签到成功”写成“完成有效学习日”
  2. API / DB 不得把三者混成一个布尔结果
  3. 下游实现不得把“学了就一定连签”或“连签就一定学了”写死
  4. 不得在本轮私自引入补签 / 宽限逻辑或 basis 切换
- **Pending Part:**
  1. 是否由签到驱动转向学习驱动
  2. 是否引入补签 / 宽限逻辑
  3. 切 basis 后对既有用户口径的兼容策略
  4. 是否需要定义进入下一轮 basis switch 的触发条件

### BR-008 当前主命名统一规则
- **Status:** Frozen
- **Rule:** 当前主命名统一为：
  - `daily_goal_status`
  - `session_validation_status`
  - `reward_settlement_status`
  平行旧叫法不得继续作为正式主命名保留。
- **Applies to:** UI / API / DB / handoff / TEST
- **Checkable:**
  1. UI 不再保留 `session_reward_status`、`reward_settlement_last_status` 作为主名
  2. API / DB / UI 映射必须明确写出
  3. 若存在局部 alias，必须在 glossary / mapping 表说明

### BR-009 今日页主 CTA 单一强按钮与 P3 CTA deepening 边界
- **Status:** Frozen with pending algorithm details
- **Rule:** 今日页必须永远只有一个最强主 CTA；P3 允许 CTA winner 进入更完整优先级算法阶段，但当前只冻结到规则层的判定层级 + decision-support 边界。
- **Decision source:** Room 1 已接受的 `R3_P3_Rules_Freeze_Note_v0.1.1.md`
- **Applies to:** UI / API / 实现 / TEST
- **Frozen part:**
  1. 页面不可同时出现多个同级强主 CTA
  2. 若存在 active `review_group`，则“继续本组复习”继续保持最高优先级
  3. 若不存在 active `review_group`，但存在后端确认的待复习 / 高优先复习任务，则允许“先去复习”高于“去学新词”
  4. Session 在 P3 可进入更完整优先级仲裁，但默认仍不是自动最高优先级
  5. `today_primary_action` 若未来进入，只能是 decision-support block；**本轮冻结的是 CTA winner 的规则层级与决策输出边界，不代表 `today_primary_action` 或等价聚合块已进入 active API baseline，也不代表完整 CTA 算法已冻结完成**
  6. UI 不得仅凭本地计数、页面状态、按钮点击、前端剩余数或本地 selector 自行推断 CTA winner 最终归属
  7. active `review_group` 的存在只表示 continuation 优先级前提成立；**continuation 的具体可用性 / readiness 不得只凭 `active_review_group_id` 存在就被前端自行补脑推断**。若 Room 1 后续接受 contract deepening，应以后端 decision-support / readiness summary 为准
  8. 若 Room 1 未明确选择“同步接受 Room 2 的 contract deepening”，则 P3 当前冻结的是规则层，不代表 `today_primary_action`、`reason_line`、`priority_band`、`blocking_helper` 已进入 active contract
- **Checkable:**
  1. Today 页任何时刻只有一个最强主 CTA
  2. active `review_group` 存在时，默认先承接 continuation，而不是默认优先新开新词
  3. 若 Room 1 未进一步 pin contract clarification，Room 5 / Room 4 不得假设 `today_primary_action`、`reason_line`、`priority_band`、`blocking_helper` 已存在
  4. 若 Room 1 未进一步 pin contract clarification，Room 5 / Room 4 也不得假设 continuation / readiness 的聚合摘要 contract 已存在
- **Must not do:**
  1. 不得把签到成功写成今天最该做的学习主动作完成
  2. 不得把 Session started / ended 直接当成优先完成态
  3. 不得把本组完成自动写成今日完成
  4. 不得因为 UI 完整性而由前端本地生成 CTA winner 决策块
- **Pending Part:**
  1. `go_review` / `go_new_words` / `go_session` / `continue_review_group` 的完整优先级算法
  2. `reason` / `priority_band` / `blocking_condition` 的最终枚举全集
  3. loading / empty / error / fallback 下完整 CTA 文案策略
  4. `today_primary_action` 是否正式进入 active contract

### BR-010 `daily_goal_status` 严格判定口径
- **Status:** Frozen
- **Rule:** `daily_goal_status` 只由“今日新词目标 + 今日复习要求”共同决定；它**不包含** Session 是否完成，也**不包含**签到是否成功；当日无待复习内容时，复习要求视为自然满足。
- **Decision source:** `D-OPP-001-007`（Room 1 / `Main_updated_2026-04-02_v3.md`）
- **Applies to:** DB / API / UI / TEST
- **Canonical states:** `not_started` / `in_progress` / `partially_completed` / `completed`
- **Checkable:**
  1. 新词与复习都满足时，才允许进入 `completed`
  2. 新词或复习仅满足其一时，只能进入 `in_progress` 或 `partially_completed`，不得写成 `completed`
  3. Session 完成与签到成功都不得单独把 `daily_goal_status` 推成 `completed`
  4. 当日 `today_review_pending=0` 或无待复习内容时，复习部分按自然满足处理，不再额外阻塞 `completed`
- **Must not do:**
  1. UI 不得自行按前端计数推断最终状态
  2. Room 4 不得在实现里把“新词满额”写死成 `completed`
  3. 不得把“签到成功”或“有效 Session 完成”映射成 `daily_goal_status=completed`

### BR-011 `session_validation_status` MVP 阈值
- **Status:** Frozen
- **Rule:** `session_validation_status` 的 MVP 阈值冻结如下：Session 必须**正常启动**、**正常结束**、**达到当前配置时长**（MVP 默认 15 分钟），并在该 Session 内产生**至少 5 次** `effective learning / effective review attempts` 总和，才记为 `valid`；否则在校验完成后记为 `invalid`。
- **Decision source:** `D-OPP-001-008`（Room 1 / `Main_updated_2026-04-02_v3.md`）
- **Canonical definition (for this rule only):** `effective attempts` 指同一 `session_id` 下、被后端最终计入有效事实的原子学习提交总数，由 `effective learning attempts + effective review attempts` 构成；以服务端最终判定为准，不按前端翻页数、点击数或仅 started / ended 计时推断。
- **Applies to:** DB / API / UI / TEST
- **Canonical states:** `pending` / `valid` / `invalid`
- **Checkable:**
  1. 只开始倒计时、不满足时长、或 attempts 总和不足 5，都不得记为 `valid`
  2. 倒计时结束但后端尚未校验完成时，状态应保持 `pending` / `validating` 语义，不得前端先跳 `valid`
  3. 正常结束且满足时长与 attempts 阈值后，才允许进入 `valid`
- **Must not do:**
  1. 倒计时结束不得直接等于 `valid`
  2. UI 不得仅按 started / ended 推断 `valid`
  3. 无效 Session 不得展示 Session 奖励已成功到账

### BR-012 主机制结算浮层与副机制承接页边界
- **Status:** Frozen
- **Rule:** 主机制结算浮层只负责**承接本轮学习结果**、展示 `daily_goal_status` / `session_validation_status` / `reward_settlement_status` 与奖励摘要，并给出**弱次级 CTA**；不得在该层执行喂猫、装扮、商店购买等副机制深操作，也不得把“结算已触发 / 已展示”写成“奖励已到账成功”。
- **Decision source:** `D-OPP-001-009`（Room 1 / `Main_updated_2026-04-02_v3.md`）
- **Applies to:** UI / API / 产品 / TEST
- **Frozen part:**
  1. 结算层可以展示奖励摘要与状态摘要
  2. 结算层可以给出进入喵喵主页 / 返回今日页等弱次级 CTA
  3. 结算层不做副机制深操作
  4. 今日页内副机制仍为弱入口
  5. 若展示成长相关承接，只能是轻承接语义，不得越权宣告未被后端确认的最终业务结果
- **Checkable:**
  1. 结算层不可直接出现喂猫、装扮、商店购买主操作
  2. `reward_settlement_status != succeeded` 时，不得写“奖励已到账成功”
  3. “已升级 / 已解锁”类表达，必须以后端已确认可展示为前提；否则只能使用中性承接语
  4. 关闭结算层后，应回到更靠近主学习的位置或进入弱承接页，不得把用户丢进复杂副机制深流

### BR-013 熟练度 / 掌握阈值
- **Status:** Pending
- **Rule:** 熟练度模型相关字段可以存在，但“什么叫已掌握”的算法与阈值当前未冻结。
- **Applies to:** DB / API / 主机制 / 统计 / 奖励里程碑
- **Must not do:**
  1. 单次 `认识` 点击不得直接等于掌握
  2. 不得在 UI 文案中把单次学习写成“已掌握”

### BR-014 `review_group` 最小业务契约与 P3 review system structured deepening 边界
- **Status:** Frozen with pending algorithm details
- **Rule:** `review_group` 冻结为：**后端生成、后端持有的一次有限复习批次对象**。P3 允许 review system 从最小合同进入 structured deepening，但仍不等于完整智能学习平台或完整评分引擎。
- **Decision source:** `D-OPP-001-010`（Room 1 / `R1_Decision_Pack_D-OPP-001-010_011.md`） + Room 1 已接受的 `R3_P3_Rules_Freeze_Note_v0.1.1.md`
- **Applies to:** API / DB / UI / TEST
- **Frozen part:**
  1. `review_group` 是最小复习批次合同，不是完整调度算法本身
  2. 同一用户同一时刻只允许一个 active group；不允许并行存在多个 active group
  3. 同一 active group 允许跨 Session 继续完成
  4. 同一 group 只能产生一次 `review_group_completed` 结果、一次组级推进、一次组级结算；不得重复发奖
  5. “本组完成”只推进“今日复习进度”，不自动等于“今日复习完成”或 `daily_goal_status=completed`
  6. 若存在 active `review_group`，Today / Review 表达默认先承接 continuation，而不是优先新开 next group
  7. `next_group_readiness` 与 progress summary 只能由后端聚合结果判定；UI 不得凭 remaining count、自身计数、本地排序或页面状态自行推断
  8. P3 本轮允许 review priority 从“主因子层”深化到“有限可检查的优先级组合”，例如 due / overdue、unresolved / wrong-history、active-group continuation first；但不自动进入完整多因子评分引擎
  9. P3 本轮允许 grouping / readiness / progress summary 进入更深一层规则冻结与 contract discussion；但 **Frozen rule 不自动等于 summary contract 已存在**
  10. 若 Room 1 未 pin Room 2 的 contract deepening，Room 5 / Room 4 不得假设更细 `review_summary`、`next_group_readiness`、`progress_summary` 等聚合块已存在
- **Checkable:**
  1. API / DB 必须能稳定表达 `review_group_id`、当前 group 状态与 group completed 结果
  2. 同组刷新、重试、重新进入时，不得并行生成多个 active group
  3. 同组重复提交不得重复推进今日复习进度，不得重复生成 `review_group_completed` 来源事件，不得重复发奖
  4. UI 允许写“本组完成”“继续本组复习”，但禁止写“本组完成 = 今日复习完成”
  5. 在 Room 1 未 pin相关 contract deepening 前，Room 5 / Room 4 不得用本地计数或前端推导补出 readiness / next-group availability / 今日复习已够格
- **Pending Part:**
  1. group size 具体数值
  2. 分组算法
  3. review priority 详细权重与完整算法
  4. 完整 SRS 调度逻辑
  5. 题型比例与更细拆组策略
  6. 更细 `review_summary` contract 是否正式进入 active baseline

### BR-015 statistics 的 `summary-first` 基线与 P3 deeper minimal product 判断边界
- **Status:** Frozen with pending page-depth details
- **Rule:** P3 允许 statistics 从 `summary-first` 正式进入“独立 minimal page / deeper minimal product 判断”阶段；但当前冻结的是进入判断边界，不是默认整页落地或完整统计产品。
- **Decision source:** Room 1 已接受的 `R3_P3_Rules_Freeze_Note_v0.1.1.md`
- **Applies to:** Room 1 / Room 2 / Room 5 / Room 4 / UI / TEST
- **Frozen part:**
  1. statistics minimal spec 继续处于 Frozen 范围
  2. P3 允许正式讨论是否进入独立 minimal page / deeper minimal product
  3. 默认保守实现基线仍为 `summary-first`；**进入判断边界不自动等于独立统计页已进入当前实现范围**
  4. 在 Room 1 未进一步 pin 独立 minimal page 前，不自动新增 route、不自动新增一级导航、不自动新增页面级回归范围
  5. 若 Room 1 最终未 pin 独立 minimal page，Room 5 / Room 4 的默认表达与实现必须回退到当前 active baseline 的 `summary-first`
  6. 最小 summary 默认围绕：今日 / 近 7 天学习天数、新词数、复习组数、有效 Session 数、当前 streak
  7. “学习天数”必须基于 `learning_day`
  8. 不得把 `check_in` 或 `streak` 混写成“学习天数”
  9. “当前 streak”仍按当前 frozen basis 返回，不得在统计表达中偷切 future basis
- **Checkable:**
  1. 即使进入独立 minimal page 判断，summary-first 仍是当前保守 fallback
  2. 未 pin 独立 minimal page 前，UI / TEST 只能先按 `summary-first` 落地，不得默认扩厚成分析产品
  3. 未 pin 独立 minimal page 前，不得因为“还没有完整独立统计页”而阻塞主机制关键链路推进
- **Pending Part:**
  1. 是否正式进入独立完整 minimal page
  2. 独立页需要展示到多少历史周期
  3. 是否展示 mastery / retention / accuracy 等更深指标
  4. 是否扩成完整学习分析产品层

### BR-016 业务规则回写义务
- **Status:** Frozen
- **Rule:** 任何会影响产品状态、奖励触发、DB/API 状态机、UI 页面状态或测试通过标准的结论，不得只停留在聊天、代码或局部页面说明中，必须回写到 BR / RULES / 对应 SSOT。
- **Applies to:** 全项目
- **Checkable:**
  1. 新的状态规则变更必须更新 BR
  2. Room 1 pin 的 active 版本必须吸收本轮已收口结论

### BR-017 post-P2 持久化切流的同源一致性
- **Status:** Conditional Frozen（effective only if Room 1 pins Option A and implementation enters migration / cutover / degraded-state window）
- **Rule:** 若项目进入 post-P2 persistence cutover，Today / Secondary / Customize 相关关键链路在同一业务窗口内必须保持同源一致性；不得出现 Today 读 PostgreSQL 而 Secondary 仍读 JSON，或 Inventory / Equipment / Shop purchase 在同一业务链路中混用不同真相层。
- **Decision source:** `R2_OptionA_Persistence_Hardening_Plan_v0.1.2.md`
- **Applies to:** DB / API / UI / TEST / migration rollout
- **Activation condition:** 仅当 Room 1 正式 pin Option A，且项目进入 migration / cutover / degraded-state 实施窗口后，本条作为实现与测试强断言执行；在此之前，它是 cutover guardrail 候选，不等于 Option A 已进入 runtime active implementation。
- **Checkable:**
  1. `/me/today`、`/me/secondary-summary`、`/me/inventory`、`/me/equipment`、`/shop/purchases` 切流后必须能证明同源
  2. 若不能保证同源一致，则接口必须显式返回 `sync_status=delayed`、`maintenance=true`、`read_only=true`、`temporarily_unavailable=true` 或等价语义
  3. Room 4 regression / parity 测试必须覆盖 Today / Secondary / Customize 关键接口
  4. **最小可观察结果：** Today 至少需要出现页面级或核心摘要级的 `delayed / read_only / maintenance` 等价提示；不得静默保持“正常态”
- **Must not do:**
  1. 不得长期形成“主机制真库 / 副机制文件态”或“奖励在 SQL / 物品在 JSON”的双真相层
  2. 不得让 UI 在混源情况下继续表达“当前数据已完整刷新”

### BR-018 迁移窗口写操作降级语义
- **Status:** Conditional Frozen（effective only if Room 1 pins Option A and implementation enters migration / cutover / degraded-state window）
- **Rule:** 在 migration window、maintenance window、read-only window 或 read-model rebuild window 内，若写操作被暂停，系统必须返回可识别的降级语义，而不是 generic error，也不得返回假成功。
- **Decision source:** `R2_OptionA_Persistence_Hardening_Plan_v0.1.2.md`
- **Applies to:** API / UI / TEST / rollout
- **Activation condition:** 仅当 Room 1 正式 pin Option A，且项目进入 migration / cutover / degraded-state 实施窗口后，本条作为实现与测试强断言执行；在此之前，它是 cutover guardrail 候选，不等于 Option A 已进入 runtime active implementation。
- **Typical write paths:**
  1. `feed`
  2. `purchase`
  3. `equip / unequip`
  4. `check-in`
  5. `session finish`
- **Checkable:**
  1. 对应接口必须能表达“暂不可用 / 稍后再试 / 当前只读 / 维护中”
  2. UI 按钮必须进入可理解的禁用或降级态，不得假装可提交
  3. 测试必须覆盖 maintenance / read_only / temporarily_unavailable 的 user-facing behavior
  4. **最小可观察结果：** Customize / Meow Home 内被暂停的购买、喂猫、装备按钮，至少应表现为禁用态或只读态，并给出中性原因提示；不得保留“可点击提交但无结果”的假交互
- **Must not do:**
  1. 不得用 500 / generic error 代替已知的维护窗口语义
  2. 不得返回 `ok=true` 但实际未执行写操作
  3. 不得把“暂时不可写”默默吞掉，让用户误以为写成功

### BR-019 快照展示 vs 新鲜真相 vs 成功
### BR-019A P3.1 local-first / backup-container 总定位
- **Status:** Frozen
- **Rule:** 在 P3.1 当前阶段，系统采取 **local-first + simple backup** 总定位：
  1. 本地运行态是真相源（current runtime truth）
  2. 云端当前只是 **backup container / backup snapshot holder**
  3. 云端当前**不是** runtime truth
  4. 云端当前**不是** sync truth
- **Applies to:** BR / DB / API / UI / TEST
- **Checkable:**
  1. 任何 upload success / cloud backup success 文案，不得外推为“云端已成为当前主真相”
  2. 任何下载、恢复、备份存在态，不得写成“当前设备运行态已被云端接管”
  3. DB / API / UI / TEST 都不得把 P3.1 写成 cloud-first、full sync 或 auto-sync system
- **Why it is frozen:** `R3_P3_1_LocalProgress_CloudBackup_Rules_Freeze_Note_v0.1.1.md` 已明确冻结“当前运行态真相仍然在本地；云端当前只是 backup container，不是 runtime truth，也不是 sync truth”；`R2_P3_1_DirectScopePin_Delta_Tech_Note_v0.1.1.md` 也继续保持相同技术边界。

- **Status:** Conditional Frozen（effective only if Room 1 pins Option A and implementation enters migration / cutover / degraded-state window）
- **Rule:** `displayed snapshot` / 只读快照、`fresh backend truth`、以及“成功完成 / 已到账 / 已刷新成功”是三类不同语义；在迁移窗口、重建窗口或只读窗口内，三者必须严格区分。
- **Decision source:** `R2_OptionA_Persistence_Hardening_Plan_v0.1.2.md`
- **Applies to:** UI / API / TEST / copy
- **Activation condition:** 仅当 Room 1 正式 pin Option A，且项目进入 migration / cutover / degraded-state 实施窗口后，本条作为实现与测试强断言执行；在此之前，它是 cutover guardrail 候选，不等于 Option A 已进入 runtime active implementation。
- **Checkable:**
  1. Today 页只读展示最后可信聚合时，不得写成“刚刚已完成 / 已到账 / 已刷新成功”
  2. Meow Home 显示最后可信 secondary summary 时，若余额 / 装备 / companion summary 正在 rebuild，必须有中性同步提示
  3. Customize 页若购买 / 装备被暂停，允许浏览快照，但不得把浏览态写成“购买成功 / 装备成功”
  4. 测试必须覆盖 `displayed snapshot ≠ fresh backend truth` 与 “迁移中 / rebuild 中 / 只读降级 ≠ 成功”
  5. **最小可观察结果：** 在 snapshot / rebuild / read_only 场景下，禁止出现“已到账成功 / 购买成功 / 装备成功 / 已刷新完成”这类成功语义，除非 fresh backend truth 已被明确确认
- **Must not do:**
  1. 不得把旧快照展示成实时成功
  2. 不得把“迁移中 / rebuild 中 / 只读降级”写成“已完成 / 已到账 / 已升级”
  3. 不得把显示成功当作结算成功或到账成功

---

### BR-020 P3.1 direct-scope delta 的三层成功语义
- **Status:** Frozen
- **Rule:** `upload success`、`download success`、`restore/apply success` 是三层不同业务语义，必须严格分开。
- **Applies to:** BR / DB / API / UI / TEST
- **Checkable:**
  1. `upload success` 只能表示本地 snapshot 成功上传到云端 backup container，不得写成“已同步 / 所有设备已一致”
  2. `download completed / snapshot fetched` 只能表示 snapshot 已成功下载到本机，不自动等于已恢复
  3. 只有 `apply success / restore success` 才允许把“本机数据已恢复”作为业务事实表达

### BR-021 P3.1 restore / apply 的 manual-only 与安全边界
- **Status:** Frozen
- **Rule:** P3.1 direct-scope delta 中的 restore / download-to-local 当前仍是 manual-only，必须具备 `pre-check + warning + confirm`，且不得 silent overwrite。
- **Applies to:** BR / DB / API / UI / TEST
- **Checkable:**
  1. 当前不允许把 restore 写成 full sync / real-time sync / merge / auto restore
  2. 未 `confirm_overwrite=true` 不得执行 apply
  3. `download success` 不得自动推进成 `restore success`
  4. warning 至少需提示：作用对象、覆盖风险、非自动同步定位

### BR-022 P3.1 restore warning 的最小业务要求
- **Status:** Frozen
- **Rule:** restore warning 至少必须说明：这是把云端备份恢复到当前本机；可能覆盖当前本机相关学习进度；也可能覆盖已进入 snapshot 范围的最小设置项（例如 `daily_goal`）；当前不是自动同步。
- **Applies to:** UI / API / TEST / 文案
- **Checkable:**
  1. 不得把 restore 写成“无风险恢复”
  2. 不得只提示学习进度覆盖，而忽略最小设置层覆盖风险
  3. 页面必须具备 confirm 动作，不得一击即执行

### BR-023 P3.1 `daily_goal` 设置生效边界
- **Status:** Frozen
- **Rule:** `daily_goal` 修改后，本地保存成功即当天即时生效；只影响当前设置生效后的今日 / 后续目标判断；不回溯重算历史 `daily_goal_status`、历史统计、或 `check_in / learning_day / streak` 事实。
- **Applies to:** BR / DB / API / UI / TEST
- **Checkable:**
  1. Today 页 / 学习入口读取最新本地值
  2. 历史日完成状态不得按新值翻案
  3. `daily_goal` 改动不影响 `streak_basis_type = check_in` 当前真相

### BR-024 P3.1 `daily_goal` 输入校验与 recommendation 边界
- **Status:** Frozen + Pending edge
- **Rule:** 非法输入必须显式报错；当前 `1–500` 仅作为 Room 2 recommended validation range，可用于实现与测试参考，但未自动升格为长期 frozen business rule。
- **Applies to:** BR / API / UI / TEST
- **Checkable:**
  1. 至少覆盖：空值、非数字、小数、负数、0、超过上限、过长字符串、粘贴异常字符
  2. 不得静默失败
  3. UI / API 若使用 `1–500`，必须理解为当前 recommendation，而不是长期冻结数值规则

### BR-025 P3.1 direct-scope delta 的 out-of-scope reaffirmation
- **Status:** Frozen
- **Rule:** 本轮 direct-scope delta 明确继续不做：full sync、background sync、multi-device merge、partial restore、snapshot picker、delete backup、clear local、destructive actions bundle。
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. 不得在接口、页面、测试中把这些能力写成已进入本轮
  2. 若界面需要占位，只能作为 pending / not enabled，不得作为常规主操作

### BR-026 P3.3 首页“背单词”主入口的规则边界
- **Status:** Frozen
- **Rule:** P3.3 第一拍允许在首页增加“背单词”主入口，并将其作为学习主线强入口接入 `StudyPage`；但该入口不自动改写当前 active BR 中与 Today / CTA winner / review continuation 相关的既有规则。
- **Applies to:** BR / UI / TEST / 实现
- **Checkable:**
  1. 首页可以存在明确可点击的“背单词”入口，且点击后直接进入 `StudyPage`
  2. 不得因为首页新增入口，就宣告 Today / CTA winner 规则已正式切换
  3. 不得把首页入口扩写成“自动选择复习 / 新词 / 混合 session”的已冻结事实

### BR-027 P3.3 4 按钮的本质是 rating input，不是结果事实
- **Status:** Frozen
- **Rule:** Study / Review 页的 4 按钮，本质上是用户对当前卡片回忆质量 / 难度感受的 `rating input`；它们不是“已掌握 / 已完成 / 奖励到账 / 学习事实已成立”的结果事实。
- **Applies to:** BR / UI / API / TEST / 文案
- **Checkable:**
  1. 任何按钮点击都不得直接展示“已掌握 / 已完成 / 已到账 / 已升级”等结果文案
  2. 按钮词面与按钮点击后的即时反馈，只能表达 rating input 或下一步调度信号，不得夸大为最终业务结果
  3. Study / Review 页的 false-success 测试必须覆盖“不误报已掌握 / 已完成 / 奖励到账”

### BR-028 P3.3 4 按钮与 FSRS 四档的单调映射要求
- **Status:** Frozen
- **Rule:** 若采用 4 按钮方案，其内部语义顺序必须与 FSRS 四档保持单调一致：`again -> hard -> good -> easy`，并且 Study / Review 两页不得出现顺序错位或反向映射。
- **Applies to:** BR / UI / 本地调度 / TEST
- **Checkable:**
  1. StudyPage 与 ReviewPage 必须使用相同的 4 档顺序
  2. 4 档内部语义只允许从“最强回退”到“最强正向推进”单调变化
  3. 中文词面可以变化，但不得改变 canonical order，也不得把顺序和 FSRS grade 语义反着用

### BR-029 P3.3.1 最终两字中文词面与文案事实边界
- **Status:** Frozen
- **Rule:** P3.3.1 已正式冻结 Study / Review 4 按钮最终两字中文词面为：**不认识 / 模糊 / 记得 / 秒答**。这四个词继续只代表 `rating input`，不得被写成 mastery / result fact。
- **Applies to:** BR / UI / 文案 / TEST / 实现
- **Checkable:**
  1. Study / Review 两页的 final wording 必须统一为：`不认识 / 模糊 / 记得 / 秒答`
  2. 其 canonical mapping 必须保持：`Again -> 不认识`、`Hard -> 模糊`、`Good -> 记得`、`Easy -> 秒答`
  3. 不得使用 `掌握 / 已会 / 会了 / 完成 / 熟练 / 记住了` 作为 final wording
  4. 按钮本体与点击后的即时反馈，不得写成“已掌握 / 已完成 / 奖励到账 / 已更新计划 / 已同步复习安排”等结果事实

### BR-030 
### BR-030 P3.3 / P3.3.1 的复习规划边界与双层 owner split
- **Status:** Frozen with pending planner decisions
- **Rule:** P3.3 第一拍与 P3.3.1 收尾轮，只冻结到“首页学习入口 + Study/Review 4 按钮 rating input + 最小 submit / throttle / bridge + 复习规划 preflight 边界”；当前 `review_group` 继续是 ReviewPage 的云端 truth layer，本地 FSRS 只允许作为本地调度 / side-effect bridge，不替代云端 `review_group` 的队列、continuation、结算或 readiness 真相。
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. ReviewPage 当前继续以后端 `review_group` 获取队列，不得改由本地 due cards 直接接管
  2. 本地 FSRS bridge 不得被写成“完整复习规划已完成”或“已替代云端 planner”
  3. P3.3.1 不改 DB schema / API core semantics / `review_group` 最小合同 / planner owner
  4. 首页“背单词”点击后的新词 / 复习 / 混合 session 自动分流仍属 pending，不得由执行层自行拍板

### BR-031 P3.3.1 ReviewPage FSRS bridge 的 controlled best-effort 语义
- **Status:** Frozen
- **Rule:** P3.3.1 当前允许 ReviewPage FSRS bridge 继续保留为 `controlled best-effort`；它必须保持 `cloud-first`，且 bridge failure 继续 non-blocking，但不允许继续是“无边界、无语义约束的 silent drift”。
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. 云端 `submitReviewAttempt()` 仍是主写入，本地 bridge 不得先于 cloud submit
  2. 允许在 bridge 前增加本地 `init / ensure-local-card-state`，但只能是 idempotent 补强，不得改变 planner owner
  3. 若 cloud submit 已成功而本地 bridge 失败，不得回滚 cloud submit，不得阻断 next item / group completion / settlement 主链路
  4. fallback 至少必须在 dev / test 侧可调试、可观察、可验证存在
  5. 不得把 bridge side-effect 写成“已更新计划 / 已同步复习安排 / 下次将在 X 天后复习 / 学习模型已更新”等用户可依赖事实

### BR-032 P3.3.1 `previewDurations` deferred 边界
- **Status:** Frozen
- **Rule:** `previewDurations` / interval preview 在 P3.3.1 当前轮正式保持 deferred；它当前是 candidate experience enhancement，不是 active DB / API / review contract，也不是用户可依赖的稳定事实。
- **Applies to:** BR / UI / API / TEST / 实现
- **Checkable:**
  1. 当前轮不得在 Study / Review 页将 `previewDurations` 作为稳定可见 UI 事实显示
  2. 当前轮不得把 `previewDurations` 写进 active DB / API / review contract
  3. 不得把 preview 文案写成“系统已确认的下次安排 / X 天后复习”
  4. 若未来要进入 active contract，必须单独开新一轮 scope pin / BR 升版，不得在实现层静默升格


### BR-033 P3.3.2 `session_entry_policy_v1`
- **Status:** Frozen
- **Rule:** P3.3.2 当前正式冻结 `session_entry_policy_v1`：首页“背单词”入口继续保持 `home_word_entry = study_default`；它默认进入 `StudyPage`，不是 review dispatcher，也不是 mixed / auto-routing dispatcher。active `review_group` continuation 继续高优先，但当前只能通过独立 CTA / helper / priority block 承接，不等于 silent reroute，也不等于吞掉默认 `/study` 入口。
- **Applies to:** BR / UI / TEST / 实现
- **Checkable:**
  1. 首页点击“背单词”后的默认路径继续承接到 `StudyPage`
  2. 若存在 active `review_group` continuation，当前只能通过独立 CTA / helper / priority block 承接，不得把默认“背单词”入口静默改造成 review dispatcher
  3. 当前不得把首页入口文案、helper 或 UI 结构解释成“系统已自动帮你决定走复习 / 混合”
  4. mixed / auto-routing / unified planner 继续 pending，不得由实现层自行补脑写成已成立事实

### BR-034 P3.3.2 `planner_owner_split_v1`
- **Status:** Frozen
- **Rule:** P3.3.2 当前正式冻结 `planner_owner_split_v1`：ReviewPage 继续保持 `cloud-first + local side-effect`。其中，cloud `review_group` 是 ReviewPage 的 serving truth owner，继续负责 review queue、active group continuation、group completion、review path settlement 主链路与主队列真相层；local FSRS 是 device-side scheduling owner，继续负责 local card state、rating → interval / stability / difficulty 的设备侧运算、review logs、`init / ensure-local-card-state` 与 future preview / local planning 的候选能力来源。
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. ReviewPage 不得由本地 due cards 直接接管主队列
  2. group completion / settlement gating 不得被本地 FSRS 接管
  3. ReviewPage 当前继续保持 cloud submit first、local FSRS side-effect second、local failure non-blocking、fallback dev / test 可观察
  4. 不得把 owner split 写成 planner merge / unified planner，也不得把本地 FSRS side-effect 写成“主复习计划已更新 / 已切到最佳路径 / 已统一规划”


### BR-035 P3.3.3 `review_readiness_policy_v1`
- **Status:** Frozen
- **Rule:** P3.3.3 当前正式冻结 `review_readiness_policy_v1`：页面级 readiness truth 继续以 cloud aggregate / review-serving layer 为准；local FSRS 只作为 scheduling candidate input / device-side scheduling owner，不直接升格为页面 readiness truth。当前轮正式接受 4 个最小 readiness 语义：`ready_now`、`not_ready_now`、`next_group_eligible`、`temporarily_unservable`。
- **Applies to:** BR / UI / DB / API / TEST / 实现
- **Checkable:**
  1. `ready_now` 只在 cloud review-serving layer 可立即服务时成立
  2. `not_ready_now` 不得被 local due count / local scheduler 结果自动翻成 `ready_now`
  3. `next_group_eligible` 只表示具备进入下一组的资格，不自动等于“下一组已生成 / 已可见 / 已下发”
  4. `temporarily_unservable` 只表示当前阶段性不可服务，不得被写成“以后都不需要复习 / 今天没有复习资格”
  5. 前端 / UI / TEST 不得仅凭 local due count、local overdue、remaining 或 local card state 自行推导 readiness 最终事实

### BR-036 P3.3.3 `review_priority_policy_v1`
- **Status:** Frozen
- **Rule:** P3.3.3 当前正式冻结 `review_priority_policy_v1` 的最小层级顺序：active `review_group` continuation > cloud-confirmed due review > cloud-confirmed high-priority review > new words > session。当前只冻结 hierarchy，不冻结完整评分算法。
- **Applies to:** BR / UI / TEST / 实现
- **Checkable:**
  1. 若存在 active `review_group` continuation，则它继续拥有最高优先级
  2. due review 与 high-priority review 只有在 cloud-confirmed / serving-confirmed 时，才可进入页面级优先层级
  3. 在没有 continuation、没有 cloud-confirmed due / high-priority review 时，`study_default` 继续是默认 fallback 主线
  4. Session 当前继续保守，不自动升为最高优先
  5. continuation 高优先不等于 silent reroute，不等于 mixed / auto-routing 已成立

### BR-037 P3.3.3 `review_group_generation_policy_v1`
- **Status:** Frozen
- **Rule:** P3.3.3 当前正式冻结 `review_group_generation_policy_v1` 的最小边界：generation / issuance owner 继续在 cloud review-serving layer；同一用户同一时刻最多一个 active `review_group`；active group 未完成前，不进入 next-group 可服务路径；`next_group_eligible` ≠ `next_group_generated`；generation 当前允许 on-demand / lazy generation，不强制 pre-generation。
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. active group completion 是 next-group 进入前提之一
  2. next-group decision 至少依赖 cloud-confirmed readiness，而不是 local-only readiness
  3. 不得把本地 FSRS 直接写成 group producer
  4. exact group size 当前继续保持 pending，不得被当前实现或页面写成长期规则事实

### BR-038 P3.3.3 `schedule_source_contract_v1`
- **Status:** Frozen
- **Rule:** P3.3.3 当前正式冻结 `schedule_source_contract_v1`：local FSRS 继续输出 scheduling candidate signals（如 local card state、local due / next_due candidate、interval / stability / difficulty、review logs、future preview / explanation 的候选原料）；cloud `review_group` 继续承担 serving outputs（如 review queue serving、active group continuation、next review work serving、completion / settlement truth）。当前只允许存在 minimal planning-facing conceptual interface；owner split 不等于 unified planner / planner merge。
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. `serving truth` 与 `scheduling truth` 必须分层表达，不得混写成“planner 已统一”
  2. local FSRS 结果不得直接写成“系统已经为你确认的复习安排 / 复习计划已更新”
  3. UI / 文案 / 测试 / 实现不得把 current split 写成 unified planner 或 planner merge 已成立

### BR-039 P3.3.3 `previewDurations` continued defer + future re-entry boundary
- **Status:** Frozen with pending future re-entry
- **Rule:** `previewDurations` 在 P3.3.3 当前轮继续保持 deferred：不进入 active contract，不进入当前稳定可见 UI，不作为当前执行 winner，也不得写成“下次将在 X 天后复习 / 预计 X 天后再次出现”这类稳定计划事实。若未来要重新进入 contract，至少先单独 pin：source of truth、explanation layer、Study-only 还是 Study+Review scope、以及是否受 bridge / truth split 状态影响。
- **Applies to:** BR / UI / TEST / 实现
- **Checkable:**
  1. 本轮不得把 `previewDurations` 拉回首页 / StudyPage / ReviewPage
  2. 本轮不得把它写成 schedule explanation
  3. 本轮不得借由 preview 暗示 unified planner 已成立
  4. future re-entry 前，必须单独冻结 false-fact 禁区与来源单一性




### BR-040 P3.3.4 `preview_durations_reentry_contract_v1`
- **Status:** Frozen
- **Rule:** P3.3.4 当前正式冻结 `preview_durations_reentry_contract_v1` 的最小回归合同：`previewDurations` 若回归，source 只能是 local FSRS preview candidate；它不是 cloud serving truth，也不是稳定计划事实。当前只允许进入 StudyPage，并且只允许以 `hint / estimated / reference-only` 的极轻 secondary hint 形态出现。
- **Applies to:** BR / UI / TEST / 实现
- **Checkable:**
  1. preview 当前只允许显示在 StudyPage，不得进入 ReviewPage / 首页
  2. preview 必须显式带“预计 / 仅供参考”语气，不得以确定式语气表达下次安排
  3. preview 不得参与 readiness truth、priority truth、generation truth、route decision、settlement / reward / group completion
  4. preview 不得被写成 `cloud-confirmed next review work fact`、统一规划事实、或已同步计划事实
  5. preview 的存在只影响解释层，不改变任何既有 serving / completion / settlement truth

### BR-041 P3.3.4 `reviewpage_stronger_bridge_contract_v1`
- **Status:** Frozen
- **Rule:** P3.3.4 当前正式冻结 `reviewpage_stronger_bridge_contract_v1` 的最小强化边界：ReviewPage bridge 可以从 `controlled best-effort` 收紧到 stronger-but-still-non-blocking 的安全合同，允许更强的 `ensure-local-card-state / init`、precondition gating、observability floor 与 minimal repair path；但 cloud submit first、local second、local failure non-blocking 仍是硬规则。
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. cloud submit success 不得因 local bridge fail 回滚
  2. local bridge failure 不得阻断 next item / group completion / settlement 主链路
  3. stronger bridge 至少应让 ensure fail / local apply fail / fallback 在 dev/test 侧可观测、可断言、可追踪
  4. stronger bridge 不得把 local FSRS 升格为 ReviewPage truth owner，不得写成 planner owner shift / planner merge / unified planner
  5. stronger bridge 完成后，仍不得新增“已更新计划 / 已同步安排 / 下次将在 X 天后复习 / 已确认最佳复习路径”这类用户可依赖计划事实
  6. stronger bridge 当前不得触碰 DB schema / API core semantics 的改写


### BR-042 P3.3.5 `planner_owner_shift_v2`
- **Status:** Frozen
- **Rule:** P3.3.5 当前正式冻结 `planner_owner_shift_v2` 的最小合同边界：future local FSRS / local scheduler 可接受为 **primary planning owner 的 target-state candidate**；但这当前不是 runtime owner shift completed。owner 必须继续拆成三层：planning owner（future local direction）/ serving owner（current runtime = cloud review-serving layer）/ fact-settlement owner（current runtime = cloud / backend fact layer）。
- **Applies to:** BR / UI / DB / API / TEST / migration framing
- **Checkable:**
  1. 文档、UI、测试与实现不得把“方向被接受”写成“当前已切换完成”
  2. local planner owner shift 不自动带出 serving owner shift，更不自动带出 fact / settlement owner shift
  3. 不得把后端主机制事实（有效复习、今日目标完成、奖励结算、签到 / streak 等）写成当前已改由本地最终裁定

### BR-043 P3.3.5 `review_serving_contract_v2`
- **Status:** Frozen
- **Rule:** P3.3.5 当前正式冻结 `review_serving_contract_v2` 的最小合同边界：ReviewPage current serving truth 继续是 cloud `review_group`；future local-serving 方向可以被接受，但当前只进入 compatibility / transition / staged deprecation path，不得被写成 local due queue 已接管当前页面真相。
- **Applies to:** BR / UI / DB / API / TEST / migration framing
- **Checkable:**
  1. `review_group` 当前不得被写成“已退出 runtime”或“已退场完成”
  2. `ready_now` / `next_group_eligible` 当前不得被 local-only 结果冒充
  3. future local-serving 只允许作为 v2 target-state candidate，不是 current ReviewPage truth owner
  4. compatibility / deprecation 层不是 current owner，也不是已经被彻底删除

### BR-044 P3.3.5 `session_entry_and_routing_v2`
- **Status:** Frozen
- **Rule:** P3.3.5 当前正式冻结 `session_entry_and_routing_v2` 的最小边界：future routing 会受 owner shift 方向影响，但当前 runtime 继续保持 `home_word_entry = study_default`，active continuation 继续高优先但不得 silent reroute；任何 local planner 决定“先复习 / 先新学 / 混合 session”的 routing 只允许作为 future candidate，不得写成既成事实。
- **Applies to:** BR / UI / TEST / implementation framing
- **Checkable:**
  1. 首页“背单词”当前仍不得被静默改成 auto-routing / mixed routing 入口
  2. active continuation 仍不得自动吞掉 `/study` 默认入口
  3. future continuation 高优先语义即便保留，也必须在 v2 中重写其 truth source 与 UI 表达，当前不得沿用 current cloud-group wording 假装已完成切换

### BR-045 P3.3.5 `preview_and_explanation_contract_v2`
- **Status:** Frozen
- **Rule:** P3.3.5 当前正式冻结 `preview_and_explanation_contract_v2` 的最小边界：若 future local planner owner 方向成立，preview / explanation 未来可从 `estimated hint` 升到 `planner-facing explanation candidate`；但当前仍不得写成 committed plan fact，ReviewPage / 首页是否引入 preview 继续后置到下一层 UI + serving rewrite gate。
- **Applies to:** BR / UI / TEST / copy boundary
- **Checkable:**
  1. 当前不得把 preview / explanation 写成“系统已安排 / 已更新计划 / 已同步复习安排 / 计划已统一”
  2. 当前不得借 P3.3.5 把 ReviewPage / 首页 preview 写成已开放现实
  3. preview / explanation 的升级只表示 future explanation candidate，不表示 cloud-confirmed schedule fact 或 unified planner 已成立

### BR-046 P3.3.5 `backup_restore_and_cross_device_boundary_v2`
- **Status:** Frozen
- **Rule:** P3.3.5 当前正式冻结 `backup_restore_and_cross_device_boundary_v2` 的最小安全合同：`backup success / restore success / sync success` 三层语义必须继续严格分开；restore 继续 `manual only + pre-check + warning + confirm`；只有 restore apply 成功后，目标设备本地 planner state 才成为该设备新的 runtime truth；在无 real-time sync / auto merge 的前提下，cloud latest backup 只是 recovery artifact，不等于 cross-device consistency。
- **Applies to:** BR / UI / DB / API / TEST / implementation framing
- **Checkable:**
  1. 不得把 backup existence 写成“多设备已一致”或“已同步成功”
  2. 不得把 cloud snapshot 写成 live serving truth
  3. 多设备不一致当前继续不是自动裁定问题，而是 manual restore / explicit overwrite / user-driven recovery boundary
  4. owner shift / cloud backup rebase 不得静默打开 real-time sync / auto merge / delta sync

### BR-047 P3.3.5 `migration_and_deprecation_plan_v1`
- **Status:** Frozen
- **Rule:** P3.3.5 当前正式冻结 `migration_and_deprecation_plan_v1` 的 staged rollout 边界：当前只允许进入 compatibility / deprecation markers、shadow / parity preparation、regression scope preparation；不得跳过 compatibility / shadow / parity thinking 直接切主链路。
- **Applies to:** BR / DB / API / UI / TEST / rollout governance
- **Checkable:**
  1. `review_group` / cloud readiness / generation 当前只能进入 staged deprecation / compatibility path，不得被写成已完全失效或已全部迁移完
  2. current runtime truth 必须保持不变；future target-state candidate 必须被明确限制在非运行态层
  3. patch / test / write-back 不能只改一层；至少要联动 BR / UI fact-copy / test strategy，并对 DB / API candidate 影响做显式标记
  4. 当前不得把本轮写成 runtime owner shift、local-serving cutover、planner merge / unified planner 或完整复习系统已完成


### BR-048 P3.3.6 `local_serving_candidate_contract_v1`
- **Status:** Frozen
- **Rule:** P3.3.6 当前正式冻结 `local_serving_candidate_contract_v1` 的最小兼容边界：`local_due_queue_candidate` 与 `local_generated_review_session_candidate` 当前都只表示 future local-serving 候选实体；它们只允许进入 compatibility contract / shadow parity / adapter seam，不得被写成 current ReviewPage truth。
- **Applies to:** BR / UI / DB / API / TEST / compatibility framing
- **Checkable:**
  1. `local_due_queue_candidate` 不得被写成 current ReviewPage serving truth、不得直接替代 `review_group`、不得触发 current completion / settlement
  2. `local_generated_review_session_candidate` 不得被写成 current runtime user-visible route、不得变成 current ReviewPage 主队列、不得替代 `next review group`
  3. 当前只冻结 `source_type / source_id / owner_layer / shadow_only / candidate_reason / generated_at / item_count / serving_eligibility_state` 这组字段语义，不冻结完整 DTO / schema / API 改写
  4. compatibility contract 与 shadow-only 必须显式分开；真实 serving 顺序、真实用户承接、直接接管 item stream 与直接触发 completion / settlement 只进 shadow / parity

### BR-049 P3.3.6 `review_group_compatibility_posture_v1`
- **Status:** Frozen
- **Rule:** P3.3.6 当前正式冻结 `review_group_compatibility_posture_v1`：`review_group` 当前仍是 ReviewPage runtime serving owner，同时进入 `compatibility anchor + deprecated candidate` 三层姿态；它既不是“完全不变”，也不是“已退场完成”。
- **Applies to:** BR / UI / DB / API / TEST / migration framing
- **Checkable:**
  1. `review_group` 当前仍承担 ReviewPage queue / continuation / completion / settlement 的 current serving 主链路
  2. `review_group` 当前不得被写成“已退出 runtime”“已退场完成”或“已被 local due queue 接管”
  3. local-only 结果当前不得冒充 `ready_now` / `next_group_eligible` / current completion truth
  4. compatibility anchor / deprecated candidate 只表示 Phase 1 兼容与未来退场方向，不表示 current owner 改写

### BR-050 P3.3.6 `fact_settlement_ingest_contract_candidate_v1`
- **Status:** Frozen
- **Rule:** P3.3.6 当前正式冻结 `fact_settlement_ingest_contract_candidate_v1` 的最小边界：planner / serving owner shift 不自动带出 fact / settlement owner shift；local-serving candidate 当前只允许进入 fact ingest candidate / shadow evidence 层，不得直接改账本、今日目标完成、`check_in / learning_day / streak` 等最终事实。
- **Applies to:** BR / UI / DB / API / TEST / ingest framing
- **Checkable:**
  1. 有效复习、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前继续以后端 / cloud fact layer 为准
  2. local-serving candidate 当前只允许进入 attempt / completion / progress 的 candidate evidence 层、future ingest interface 候选层、accept / reject / duplicate 的 shadow / parity 验证层
  3. 不得把 local-serving candidate 的“表现更合理”写成“local 已可裁定最终业务事实”
  4. 本轮只冻结最小接口语义，不冻结 API core semantics / DB schema rewrite / reward-settlement owner rewrite

### BR-051 P3.3.6 `session_entry_and_routing_compat_v1`
- **Status:** Frozen
- **Rule:** P3.3.6 当前正式冻结 `session_entry_and_routing_compat_v1`：首页 runtime 继续保持 `home_word_entry = study_default`，active continuation 继续高优先但不得 silent reroute；future routing 只允许进入 shadow / candidate / helper rewrite 边界。
- **Applies to:** BR / UI / TEST / routing compatibility
- **Checkable:**
  1. 当前不得把首页“背单词”写成 auto-routing / mixed routing 入口
  2. 当前不得把 active continuation 自动吞掉 `/study` 默认入口
  3. 当前不得把 future planner-aware routing 写成既成事实
  4. local-serving candidate 对入口判断、continuation 承接、helper / CTA / priority block 的影响当前只允许进入 compatibility / shadow 讨论层

### BR-052 P3.3.6 `deprecation_markers_and_writeback_plan_v1`
- **Status:** Frozen
- **Rule:** P3.3.6 当前正式冻结 `deprecation_markers_and_writeback_plan_v1`：所有下游 write-back / patch / test / helper 至少必须显式区分 `runtime truth / compatibility-only / deprecated candidate / shadow-only evidence` 四层；write-back 不能只停在单一文档。
- **Applies to:** BR / DB / API / UI / TEST / governance write-back
- **Checkable:**
  1. `deprecated candidate` 不能继续被写成 current active truth，也不能被写成“已退场完成 / 已删除 / 已迁移完”
  2. `compatibility-only` 资产仍应维持当前页面 / 当前合同可用性
  3. 若 Room 1 接受 Compatibility Contract v1，本轮 write-back / patch 至少要联动 BR、UI fact-copy / state contract、TEST strategy / regression scope，并对 DB / API candidate 影响做显式标记
  4. 不得放任 silent contract drift

### BR-053 P3.3.6 `shadow_parity_test_strategy_v1`
- **Status:** Frozen
- **Rule:** P3.3.6 当前正式冻结 `shadow_parity_test_strategy_v1`：shadow / parity 结果当前只能写成 evidence，不能写成 owner shift 已完成、local 已接管 ReviewPage、`review_group` 已退出运行态或 auto-routing 已上线；同时本轮至少必须区分 `runtime truth regression / shadow parity evidence / marker-contract-only tests` 三类测试。
- **Applies to:** BR / UI / TEST / feature-flag seam governance
- **Checkable:**
  1. shadow / parity success / mismatch 当前都不得变成用户端 current runtime fact
  2. `localServingShadowEnabled / localServingParityCompareEnabled / localServingShadowRoutingEnabled / reviewGroupCompatibilityMode / localFactIngestShadowEnabled` 这类 flags / seams 当前只允许作为 shadow-entry preparation，默认不得打开
  3. flags / seams 不得改变 current runtime truth
  4. 若未来进入 Phase 2，shadow / parity evidence 仍应优先停留在 debug / dev / QA 证据层，而不是用户事实层


### BR-054 P3.3.7 `shadow_execution_scope_v1`
- **Status:** Frozen
- **Rule:** P3.3.7 当前正式冻结 `shadow_execution_scope_v1`：`local_due_queue_candidate`、`local_generated_review_session_candidate`、`fact_ingest_shadow_evidence` 与 `routing_shadow_candidate` 当前只允许进入 limited execution / dev / flag / QA evidence 层；不得进入用户主路径，不得变成 current runtime truth。
- **Applies to:** BR / UI / TEST / feature-flag / write-back framing
- **Checkable:**
  1. 以上 candidate 当前只能进入 debug / QA / patch evidence 层
  2. 不得替代 current ReviewPage queue source、current CTA / helper / summary truth、或 final fact / settlement truth
  3. shadow run 能跑起来，不等于 runtime owner shift 已成立

### BR-055 P3.3.7 `shadow_result_visibility_v1`
- **Status:** Frozen
- **Rule:** P3.3.7 当前正式冻结 `shadow_result_visibility_v1`：shadow 结果只允许被 dev / test、internal debug / log、QA evidence、patch draft / closeout 摘要与治理层文档看见；绝不允许进入用户可见层。
- **Applies to:** UI / TEST / write-back / debug instrumentation
- **Checkable:**
  1. local queue compare / parity mismatch / accept-reject-duplicate shadow 证据 / routing shadow 判断 / “本地更合理” 等内部判断当前都不得被用户看见
  2. internal-only marker、debug badge、parity label、shadow status 不得出现在 Home / Study / Review 的用户态文案中
  3. patch / closeout 允许记录，但用户态不允许承诺

### BR-056 P3.3.7 `mismatch_severity_rule_set_v1`
- **Status:** Frozen
- **Rule:** P3.3.7 当前正式冻结 `mismatch_severity_rule_set_v1`：所有 shadow mismatch 至少分为 `info_only_mismatch`、`warning_mismatch`、`must_hold_mismatch`、`must_escalate_mismatch` 四层；凡触碰 current runtime truth、`review_group` current owner posture、final fact owner、或用户可见 overclaim 的 mismatch，都不得按 warning 放行。
- **Applies to:** TEST / QA / write-back / escalation protocol
- **Checkable:**
  1. `must_hold_mismatch` 至少覆盖：shadow 结果被用户看见、current ReviewPage truth 被 local 覆写、`study_default` 被 shadow routing 偷改、local evidence 改 final ledger / daily_goal / streak write、`review_group` 被写成已退场
  2. `must_escalate_mismatch` 至少覆盖：需要改 DB schema / API core semantics / reward-settlement owner / `review_group` current runtime owner posture / auto-routing runtime / planner merge
  3. mismatch 分桶结果必须可记录、可追溯、可用于 stop-condition 判断

### BR-057 P3.3.7 `shadow_acceptance_gate_v1`
- **Status:** Frozen
- **Rule:** P3.3.7 当前正式冻结 `shadow_acceptance_gate_v1`：本轮 parity pass 的最低要求不是“影子逻辑能跑”，而是 guardrails 先守住——current runtime truth 未被偷切、shadow 结果未漏到用户端、`review_group` posture 未被破坏、final fact / settlement truth 未被 shadow 改写、且 parity compare / evidence path 可被稳定记录。
- **Applies to:** QA / regression / closeout / Room 1 gate judgment
- **Checkable:**
  1. acceptable mismatch 只允许停留在 evidence 层、不可见给用户、不可改 current runtime truth、可解释且可回归
  2. stop conditions 至少包括：runtime truth leakage、shadow 影响 final fact / settlement、routing shadow 进入 runtime、`review_group` 被误写成已退场、需要改 DB / API core semantics
  3. “看起来更合理”本身不足以记为 pass

### BR-058 P3.3.7 `fact_copy_guardrails_v1`
- **Status:** Frozen
- **Rule:** P3.3.7 当前正式冻结 `fact_copy_guardrails_v1`：`shadow / candidate / internal-only / parity evidence / compare result / debug only / not current runtime truth` 这类 wording 只允许用于 internal docs / debug panel / QA evidence / patch draft；`已切换到本地规划`、`本地已接管复习`、`review_group 已退场`、`已自动安排学习路径`、`系统已按本地规划正式运行`、`shadow compare 已通过，因此已完成切换` 等表达继续是禁区。
- **Applies to:** UI copy / debug labels / closeout wording / governance docs
- **Checkable:**
  1. helper / label / debug wording 不得出现在用户可见 toast / summary / completion 文案中
  2. internal-only 结果不得被包装成用户可依赖事实
  3. shadow evidence 再充分，也不允许越权改成 runtime cutover 口径

### BR-059 P3.3.7 `shadow_to_phase3_gate_v1`
- **Status:** Frozen
- **Rule:** P3.3.7 当前正式冻结 `shadow_to_phase3_gate_v1`：Phase 2 的目标是收集可解释、可复现、可回归的 shadow evidence，而不是证明 cutover 已成立；只有 queue compare、continuation / completion / eligibility 解释、fact ingest evidence、routing shadow 与 `review_group` posture 的长期稳定证据逐步齐备，Room 1 才有资格讨论 Phase 3。
- **Applies to:** Room 1 stage-gate / QA evidence / future cutover discussion
- **Checkable:**
  1. “看起来更合理”“大多数 compare 通过”“与 cloud baseline 大体一致”都不足以自动升格为 runtime fact
  2. future Phase 3 讨论前，至少要有稳定 queue compare、稳定 fact ingest evidence、routing shadow 不冲突、`review_group` posture 不被破坏、mismatch 已被持续分桶
  3. 本轮 closeout 只允许得出“是否值得进入下一轮判断”，不允许得出“现在就可以切过去”


### BR-060 P3.3.8 `phase3_gate_decision_v1`
- **Status:** Frozen
- **Rule:** P3.3.8 当前正式冻结 `phase3_gate_decision_v1`：当前只允许得出 `proceed_to_next_layer_candidate_review / hold / revise / escalate` 四类 gate 结论；不得把 gate 结论写成 `runtime owner shift completed`、`local-serving cutover completed`、`review_group` 已正式退场、或 `unified planner` 已成立。
- **Applies to:** BR / UI / DB / API / TEST / migration governance
- **Checkable:**
  1. gate 结论当前只能说明“是否具备进入下一层 candidate / migration review 的资格”
  2. shadow evidence 若未同时满足 current runtime truth 未被偷切、shadow 未漏到用户端、`review_group` current owner posture 未被破坏、final fact / settlement truth 未被 shadow 改写、mismatch 分级稳定可回归、且证据可明确解释，则不得进入 proceed
  3. “看起来更合理”本身不足以自动进入下一层 cutover 准备

### BR-061 P3.3.8 `limited_cutover_scope_candidate_v1`
- **Status:** Frozen
- **Rule:** P3.3.8 当前正式冻结 `limited_cutover_scope_candidate_v1`：若未来进入下一层，最小切口只允许先讨论 `review_group` exit 条件判断准备、fact ingest stronger-path candidate、helper / summary / state contract migration prep、DB / API seam candidate formalization、rollback / hold / migration note baseline。
- **Applies to:** BR / UI / DB / API / TEST / migration framing
- **Checkable:**
  1. 当前不得把上述 candidate subset 写成 ReviewPage local-serving runtime cutover
  2. 当前不得把 runtime routing switch、auto-routing、unified planner / planner merge、或 final fact owner shift 写成已进入执行
  3. serving source 不得先于 fact-settlement boundary 被偷切

### BR-062 P3.3.8 `review_group_exit_gate_v1`
- **Status:** Frozen
- **Rule:** P3.3.8 当前正式冻结 `review_group_exit_gate_v1`：`review_group` 继续保持 current runtime serving owner + compatibility anchor + deprecated candidate；只有当 contract / test / doc / boundary 四类前置条件都具备时，才有资格进入真实退场判断。
- **Applies to:** BR / UI / DB / API / TEST / migration governance
- **Checkable:**
  1. 当前不得把 `review_group` 写成“现在只是兼容层”“已退场完成”“可立即退场”“已不再使用”
  2. 即使前置条件逐步接近，也只代表“可讨论 exit gate”，不代表当前轮直接退场
  3. `review_group` 的 current owner posture 在 gate 阶段仍必须保持不变

### BR-063 P3.3.8 `fact_settlement_cutover_boundary_v1`
- **Status:** Frozen
- **Rule:** P3.3.8 当前正式冻结 `fact_settlement_cutover_boundary_v1`：即使进入 Phase 3 gate，有效复习事实、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准；local evidence 最多只允许讨论更强的 ingest path candidate，不允许越权成 fact owner。
- **Applies to:** BR / UI / DB / API / TEST / settlement governance
- **Checkable:**
  1. local-serving evidence、parity result、ingest candidate 当前都不得冒充上述最终事实
  2. 当前不得把 local evidence 写成“已记为有效复习”“今日目标已推进”“奖励已到账”“streak 已续上”
  3. candidate stronger-path ≠ fact owner shift

### BR-064 P3.3.8 `phase3_writeback_and_migration_v1`
- **Status:** Frozen
- **Rule:** P3.3.8 当前正式冻结 `phase3_writeback_and_migration_v1`：write-back 顺序必须先规则护栏，再技术候选，再 UI migration，最后由 Room 1 统一吸收；migration note / rollback note / hold note 必须成套出现；`runtime truth / compatibility-only / deprecated candidate` 三层切换条件必须继续显式分开。
- **Applies to:** BR / DB / API / UI / TEST / rollout governance
- **Checkable:**
  1. 当前不得只写“建议继续推进”，不写何时 hold、何时 rollback、何时 escalate
  2. 当前不得把 deprecated candidate 写成已消失，也不得把 compatibility-only 写成 current owner
  3. 当前不得把 DB / API candidate seam、migration note、rollback floor 或 hold note 写成“已完成迁移”



### BR-065 P3.3.9 `first_cutover_rule_set_v1`
- **Status:** Frozen
- **Rule:** P3.3.9 当前正式冻结 `first_cutover_rule_set_v1`：第一轮 first cutover 只允许切 ReviewPage 内部 serving seam 的 very narrow subset；首页 `study_default`、active continuation、`review_group` 真退场、final fact owner 与 DB/API baseline uplift 都不进入当前切口。
- **Applies to:** BR / UI / DB / API / TEST / migration governance
- **Checkable:**
  1. 若本轮叫 first cutover，就必须真的切一个 runtime seam；只改 helper / 文案 / state contract 而完全不触碰 seam，不算 first cutover
  2. 当前不接受“先切 final fact stronger-path，再补 serving seam”的倒序
  3. 当前允许的 first-cutover subset 只包括 ReviewPage 内部 serving seam 的 source switch candidate、local-serving 结果进入 stronger ingest path 的最小接缝、与该 seam 直接相关的极小 helper / summary / state contract 迁移，以及 rollback / hold / observability 最小配套

### BR-066 P3.3.9 `runtime_truth_switch_boundary_v1`
- **Status:** Frozen
- **Rule:** P3.3.9 当前正式冻结 `runtime_truth_switch_boundary_v1`：当前唯一允许进入 first-cutover 讨论的 runtime-truth switch 候选，是 ReviewPage 内部“当前一组复习项从哪里来”的极小 serving seam。
- **Applies to:** BR / UI / DB / API / TEST / runtime truth framing
- **Checkable:**
  1. 首页继续 `home_word_entry = study_default`
  2. active continuation 继续独立承接，不得 silent reroute
  3. `review_group` 当前继续是 current runtime serving owner
  4. final fact / settlement truth 继续以后端为准
  5. preview / explanation 不得借本轮升级成 committed plan fact
  6. 即使 serving seam 局部切换，首页 summary truth、continuation 高优先语义、group completion / settlement truth、reward / daily goal / streak / learning day 结果表达都不得被顺手改写

### BR-067 P3.3.9 `review_group_retained_anchor_v1`
- **Status:** Frozen
- **Rule:** P3.3.9 当前正式冻结 `review_group_retained_anchor_v1`：`review_group` 在本轮应被明确写成 `current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate` 的 dual posture。
- **Applies to:** BR / UI / DB / API / TEST / rollback governance
- **Checkable:**
  1. active continuation identity、current completion gating、current settlement trigger、rollback target 与 non-cutover baseline path 当前仍必须继续走 `review_group`
  2. 触发 rollback 时必须回到 cloud `review_group` current runtime path
  3. 当前继续禁止把 `review_group` 写成“已退场”“已不再是 runtime owner”“仅剩历史兼容意义”“可以直接清理旧 path”

### BR-068 P3.3.9 `fact_owner_guardrail_v1`
- **Status:** Frozen
- **Rule:** P3.3.9 当前正式冻结 `fact_owner_guardrail_v1`：first-cutover 当前只允许切 serving seam，不允许切 final fact owner；即使 ReviewPage 内部 serving seam 进入 first cutover，有效复习事实、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准。
- **Applies to:** BR / UI / DB / API / TEST / settlement governance
- **Checkable:**
  1. local-serving 的 first-cutover 结果不得被写成上述最终事实已经跟着切换
  2. stronger ingest path 当前最多只允许更强的 evidence ingestion、accept / reject / duplicate 规则更明确、以及与 first-cutover seam 直接相关的最小传递
  3. 当前不得把 local 直接写成 ledger / daily-goal / streak / learning-day / settlement owner

### BR-069 P3.3.9 `db_api_cutover_candidate_v2`
- **Status:** Frozen
- **Rule:** P3.3.9 当前正式冻结 `db_api_cutover_candidate_v2`：从规则层看，本轮只允许与 first-cutover seam 直接相关的 serving source descriptor seam、retained-anchor / fallback marker seam、stronger ingest path minimal seam、rollback / hold / observability seam 从 candidate 升到 first-cutover-ready；不允许任何 DB schema rewrite、endpoint core semantics rewrite 或 active DB/API baseline uplift。
- **Applies to:** BR / DB / API / TEST / migration framing
- **Checkable:**
  1. 当前 active DB/API baseline 继续保持 `v0.2.1`
  2. 当前不得改 `review_group` 为非 current owner 语义
  3. 当前不得改 settlement / reward owner
  4. 当前不得把 candidate seam / marker / observability 写成 active baseline uplift

### BR-070 P3.3.9 `rollback_holdnote_and_observability_v1`
- **Status:** Frozen
- **Rule:** P3.3.9 当前正式冻结 `rollback_holdnote_and_observability_v1`：rollback / hold / observability 不是附属项，而是 first-cutover 合同的一部分。rollback target 必须明确指向 `review_group` current runtime path；必须有明确的回退触发条件、回退后用户可见 truth 不变声明，以及 seam hit / fallback hit / stronger ingest candidate accept-reject-duplicate / hold trigger / overclaim guard check 等最小 observability 证据位。
- **Applies to:** BR / UI / DB / API / TEST / rollout governance
- **Checkable:**
  1. 出现以下任一情况必须 hold：first-cutover seam 影响首页 `study_default`、active continuation 被 silent reroute、`review_group` 被误写成已退场 / 不再是 current owner、local-serving 结果影响 final fact / settlement truth、用户端出现“已切到本地规划 / 已接管复习 / cutover 已完成”、或需要改 DB schema / API core semantics 才能继续
  2. 出现以下任一情况必须 escalate：需要把 `review_group` 从 dual posture 提前改成 fallback-only、需要把 stronger ingest seam 升格成 active fact path、需要把 auto-routing / planner merge / unified planner 拉进当前轮、需要用户可见模式切换说明、或需要把 cleanup / exit / baseline uplift 绑进来
  3. 当前不得把 rollback / hold / observability note 省略成“以后再补”


### BR-071 P3.3.10 `fuller_cutover_rule_set_v1`
- **Status:** Frozen
- **Rule:** P3.3.10 当前正式冻结 `fuller_cutover_rule_set_v1`：下一拍 fuller cutover 当前只允许从 ReviewPage non-continuation serving seam，扩大到 continuity-adjacent、仍不碰首页 `study_default` route / active continuation path / final fact owner 的 very narrow next subset。
- **Applies to:** BR / UI / DB / API / TEST / migration governance
- **Checkable:**
  1. 当前只允许扩大到 ReviewPage continuity-adjacent serving subset、与其强绑定的 source-neutral helper / summary / state contract、更稳的 retained-anchor fallback / rollback seam、以及更清楚的 stronger ingest candidate handoff
  2. 当前不得把 fuller cutover 扩大到首页 route、active continuation path 全量切换、`review_group` 真退场、final fact owner shift、或 active DB/API baseline uplift 生效
  3. fuller cutover judgment 只代表具备进入下一层 execution judgment 的资格，不代表当前已足以下发 fuller-cutover 执行单

### BR-072 P3.3.10 `review_group_exit_gate_v2`
- **Status:** Frozen
- **Rule:** P3.3.10 当前正式冻结 `review_group_exit_gate_v2`：`review_group` 当前仍必须继续保持 `current runtime serving owner + retained fallback anchor + compatibility anchor + deprecated candidate`；只有当 contract / test / doc / runtime / boundary 五类前置条件都齐，才有资格进入真实 exit judgment。
- **Applies to:** BR / UI / DB / API / TEST / exit governance
- **Checkable:**
  1. 当前不得把 `review_group` 写成 fallback-only、已退场、可清理、或已不再是 current runtime owner
  2. active continuation identity、completion gating、settlement trigger、rollback target 与 non-cutover baseline path 当前仍必须继续显式依赖 `review_group`
  3. “可以讨论 exit gate” ≠ “当前轮立刻退场”

### BR-073 P3.3.10 `cutover_vs_fact_owner_boundary_v2`
- **Status:** Frozen
- **Rule:** P3.3.10 当前正式冻结 `cutover_vs_fact_owner_boundary_v2`：fuller cutover 可以扩大 serving subset，但不得顺手扩大到 final fact owner 层；有效复习事实、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准。
- **Applies to:** BR / UI / DB / API / TEST / settlement governance
- **Checkable:**
  1. local stronger ingest candidate 当前最多只允许进入 uplift-judgment-ready / stronger-path-ready seam，不允许越权成 fact owner
  2. 当前不得把 local evidence / stronger path 写成 ledger、daily-goal completion、streak / learning-day、或 settlement owner 已切换
  3. cutover 扩大层级 ≠ final fact owner 扩大层级

### BR-074 P3.3.10 `db_api_uplift_judgment_v1`
- **Status:** Frozen
- **Rule:** P3.3.10 当前正式冻结 `db_api_uplift_judgment_v1`：当前只允许把与 fuller cutover 直接绑定的 serving source descriptor seam、retained-anchor / fallback marker seam、stronger ingest path minimal seam、rollback / hold / observability seam、以及 source-neutral helper / summary / state contract seam 升到 uplift-judgment-ready；不允许 active DB/API baseline uplift absorbed。
- **Applies to:** BR / DB / API / UI / TEST / migration framing
- **Checkable:**
  1. candidate seam 与 uplift-judgment-ready seam、以及 active uplift absorbed 必须继续显式分层
  2. 当前不得写成 DB schema rewrite、API core semantics rewrite、active baseline uplift 生效、或“以新主链路现实重写整个 DB/API 主文档”
  3. 当前 active DB/API baseline 继续保持 `v0.2.1`

### BR-075 P3.3.10 `retained_anchor_to_exit_transition_v1`
- **Status:** Frozen
- **Rule:** P3.3.10 当前正式冻结 `retained_anchor_to_exit_transition_v1`：retained anchor → exit candidate 的过渡，只允许先讨论 fallback / rollback 何时可以缩窄、哪些路径仍保留 `review_group`、以及哪些路径已不再需要 `review_group`；不允许先删 current owner 身份，也不允许先把 `review_group` 降成 purely historical object。
- **Applies to:** BR / UI / DB / API / TEST / rollback governance
- **Checkable:**
  1. rollback target 当前仍必须明确指向 cloud `review_group` current runtime path
  2. fallback / rollback 只有在 active continuation、completion gating、settlement trigger、non-cutover baseline path 与 rollback target 都有非模糊替代路径后，才有资格讨论缩窄
  3. 首页 `study_default`、active continuation、`review_group` current owner posture、final fact / settlement truth、以及用户可见 overclaim 继续是 stop-condition

### BR-076 P3.3.10 `phase4_writeback_order_v1`
- **Status:** Frozen
- **Rule:** P3.3.10 当前正式冻结 `phase4_writeback_order_v1`：write-back 顺序必须先 Room 2 tech judgment note，再 Room 3 rules note，再 Room 5 UI preflight，再由 Room 1 absorb / pin；当前只能把 fuller cutover、exit-gate、uplift 写成 judgment，最多只允许 very narrow next subset、rollback / hold / observability floor、以及 source-neutral helper / summary / state migration prep 进入 execution-ready candidate。
- **Applies to:** BR / DB / API / UI / TEST / rollout governance
- **Checkable:**
  1. 当前不得把 runtime truth 已更改、`review_group` 已真退场、或 active DB/API uplift 已 absorbed 写入主 BR
  2. migration / rollback / hold note 与 no-overclaim statement 当前仍必须成套存在
  3. fuller cutover judgment、exit-gate judgment 与 uplift judgment 都不得被误写成当前运行态事实


### BR-077 P3.3.11 `fuller_cutover_execution_rule_set_v1`
- **Status:** Frozen
- **Rule:** P3.3.11 当前正式冻结 `fuller_cutover_execution_rule_set_v1`：当前最稳的 execution-ready subset，只允许扩大到 `ReviewPage continuity-adjacent serving-adapter family`、与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层、首页 review helper / summary / no-review-state 的 retained-anchor-aware prep，以及 rollback / hold / fallback 的中性 copy / state contract prep。
- **Applies to:** BR / UI / DB / API / TEST / execution governance
- **Checkable:**
  1. 当前不得把 execution-ready subset 扩大到首页默认主 route、active continuation source switch、user-visible planner-aware route / auto-routing runtime、`review_group` true exit、final fact owner shift、或 active DB/API baseline uplift absorbed
  2. execution-ready subset 只代表具备进入更完整但仍 very narrow 的执行准备层，不代表已经完成 full cutover execution
  3. 任何用户可见 overclaim 都不得因 widened subset 被默认放开

### BR-078 P3.3.11 `review_group_exit_candidate_v1`
- **Status:** Frozen
- **Rule:** P3.3.11 当前正式冻结 `review_group_exit_candidate_v1`：`review_group` 仍必须继续保持 `current runtime serving owner + retained fallback anchor + compatibility anchor + deprecated candidate`；本轮只允许进入 exit-candidate 前置条件判断、retained-anchor 依赖路径 future-narrowable 判断、rollback / fallback scope future-narrowable 判断，以及 helper / summary / CTA / empty-state 脱离 group-only wording 的准备。
- **Applies to:** BR / UI / DB / API / TEST / migration governance
- **Checkable:**
  1. 当前不得把 `review_group` 写成 true exit、fallback-only、historical-only、已不再使用、或可直接清理
  2. 当前以下路径仍必须继续显式依赖 `review_group`：active continuation identity、completion gating、settlement trigger、rollback target、non-cutover / non-upgraded sessions baseline path
  3. retained anchor 当前只允许缩窄 wording / helper 依赖，不允许缩窄 rollback target、active continuation identity、completion gating、settlement trigger、或 baseline path

### BR-079 P3.3.11 `db_api_uplift_readiness_v1`
- **Status:** Frozen
- **Rule:** P3.3.11 当前正式冻结 `db_api_uplift_readiness_v1`：当前最多只允许 serving source descriptor seam、retained-anchor / fallback posture seam、stronger ingest path minimal seam、rollback / hold / observability seam、以及 source-neutral state / helper / summary contract seam 进入 uplift-readiness。
- **Applies to:** BR / DB / API / UI / TEST / baseline governance
- **Checkable:**
  1. 当前 `review_group` true-exit、active continuation source switch、final fact owner shift、homepage route / planner-aware route 相关 seam 仍只能停留在 migration / hold / rollback 层
  2. uplift-readiness 不得写成 active DB/API baseline 已更新、endpoint meaning 已重写、或 runtime truth 已同步替换
  3. 当前不得借 uplift-readiness 重写整个 DB/API 主文档或宣称 active baseline uplift absorbed

### BR-080 P3.3.11 `cutover_vs_fact_owner_boundary_v3`
- **Status:** Frozen
- **Rule:** P3.3.11 当前正式冻结 `cutover_vs_fact_owner_boundary_v3`：即使 fuller-cutover execution 前进一步，有效复习事实、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准；local stronger ingest candidate 最多只允许进入 validated stronger-ingest candidate execution layer，不允许升格为 final fact owner。
- **Applies to:** BR / UI / DB / API / TEST / settlement governance
- **Checkable:**
  1. 当前不得把 local stronger-ingest candidate 写成上述最终事实已可由本地裁定
  2. stronger-ingest candidate 当前最多只允许进入更清楚的 accept / reject / duplicate、precondition / postcondition / hold-reason / evidence ownership，以及与 fuller-cutover execution subset 直接绑定的最小 ingest contract
  3. `本地已接管复习事实 / 今日完成判定 / 奖励到账 / streak续上 / completion由本地裁定` 继续属于 overclaim

### BR-081 P3.3.11 `retained_anchor_narrowing_guardrail_v1`
- **Status:** Frozen
- **Rule:** P3.3.11 当前正式冻结 `retained_anchor_narrowing_guardrail_v1`：rollback target 仍必须继续固定为 `cloud_review_group_current_runtime_path`；retained anchor 当前只允许 very narrow 缩窄 source-neutral helper / summary wording 的 group-only 耦合、首页 review helper / empty-state / no-review-state 的 retained-anchor-aware 表达，以及 rollback / fallback 说明中的历史性冗余 wording。
- **Applies to:** BR / UI / TEST / rollback governance
- **Checkable:**
  1. 当前不得缩窄 rollback target、active continuation identity、completion gating、settlement trigger、或 non-cutover baseline path
  2. 首页 `study_default` 被触碰、active continuation 被 silent reroute、`review_group` 被写成 fallback-only / 已退场 / 可清理、local stronger path 影响 final fact / settlement truth、用户端出现 cutover / uplift overclaim、或需要改 DB schema / API core semantics 时，必须 hold
  3. 若需要把 `review_group` 从 current owner + retained anchor 改成非 current owner、把 active continuation 改到 local path、把 active DB/API baseline uplift 写成当前生效、或把 cleanup / old-path purge 绑进当前轮，必须 escalate

### BR-082 P3.3.11 `phase5_writeback_order_v1`
- **Status:** Frozen
- **Rule:** P3.3.11 当前正式冻结 `phase5_writeback_order_v1`：回写顺序必须先 Room 2 tech note，再 Room 3 rules note，再 Room 5 UI preflight，再由 Room 1 absorb / pin；当前只能把 widened subset、exit-candidate、uplift-readiness、validated stronger-ingest candidate 与 source-neutral / retained-anchor-aware UI migration prep 写成 execution-ready candidate / readiness 层，不得写成 runtime truth。
- **Applies to:** BR / DB / API / UI / TEST / rollout governance
- **Checkable:**
  1. 当前不得把 runtime truth 已更改、`review_group` true exit、active DB/API baseline uplift absorbed、或 final fact owner 已切换写入主 BR
  2. rollback / hold / fallback / observability 与 no-overclaim statement 当前仍必须成套存在
  3. 当前若要被 Room 1 吸收到下一轮 `R1 → R4` handoff，至少必须满足：不触碰首页 route / active continuation / final fact owner，`review_group` 仍保持 current owner + retained anchor，不把 uplift-readiness 写成 active uplift



### BR-083 P3.3.12 `fuller_cutover_absorb_candidate_v1`
- **Status:** Frozen
- **Rule:** P3.3.12 当前正式冻结 `fuller_cutover_absorb_candidate_v1`：当前只允许把 P3.3.11 的 widened execution-ready subset 提升到 fuller-cutover absorb judgment；允许进入判断的 widened family 仍只限于 `ReviewPage continuity-adjacent serving-adapter family`、与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层、首页 review helper / summary / no-review-state 的 retained-anchor-aware contract、rollback / hold / fallback 的中性 copy / state contract，以及 stronger-ingest execution-ready binding prep。
- **Applies to:** BR / UI / DB / API / TEST / cutover governance
- **Checkable:**
  1. 当前不得把 absorb-candidate judgment 扩大到首页默认主 route、active continuation source switch、user-visible planner-aware route / auto-routing runtime、`review_group` true exit、final fact owner shift、active DB/API baseline uplift absorbed、或 cleanup / old-path purge
  2. absorb-candidate judgment 只表示“具备进入下一层 fuller-cutover absorb 审查的资格”，不代表 widened family 已 absorbed into runtime truth
  3. blast radius 与 rollback complexity 当前必须继续显式纳入判断，不得静默放大到非 ReviewPage + 首页 review 承接层

### BR-084 P3.3.12 `review_group_true_exit_gate_v1`
- **Status:** Frozen
- **Rule:** P3.3.12 当前正式冻结 `review_group_true_exit_gate_v1`：`review_group` 仍必须继续保持 `current runtime serving owner + retained fallback anchor + compatibility anchor + deprecated candidate`；当前只允许把 true-exit gate 所需的 contract / runtime / test / doc / fallback 条件推进到 judgment 层，不允许把它写成 true exit、fallback-only、historical-only、或可直接清理。
- **Applies to:** BR / UI / DB / API / TEST / migration governance
- **Checkable:**
  1. 只要 active continuation identity、completion gating、settlement trigger、rollback target、non-cutover / non-upgraded sessions baseline path、或 compatibility anchor / QA baseline reference 仍未被清晰替代，`review_group` 就不得进入 true exit
  2. true-exit gate judgment ≠ true exit；当前不得把条件逐步齐备写成已开始 true exit 或 cleanup
  3. retained anchor 当前只允许判断 future-narrowable scope，不允许提前改 rollback target 或 current owner posture

### BR-085 P3.3.12 `db_api_uplift_absorb_judgment_v1`
- **Status:** Frozen
- **Rule:** P3.3.12 当前正式冻结 `db_api_uplift_absorb_judgment_v1`：当前最多只允许 serving source descriptor seam、retained-anchor / fallback posture seam、stronger-ingest path minimal seam、rollback / hold / observability seam、以及 source-neutral state / helper / summary contract seam 进入 uplift-absorb judgment。
- **Applies to:** BR / DB / API / UI / TEST / baseline governance
- **Checkable:**
  1. `review_group` true-exit、active continuation source switch、final fact owner shift、homepage route / planner-aware route、以及 DB schema rewrite / API core semantics rewrite 相关 seam 当前仍只能停留在 marker / migration / rollback / hold 层
  2. uplift-absorb judgment 不得写成 active DB/API baseline 已升级、endpoint meaning 已重写、或 runtime truth 已同步替换
  3. 当前不得借 uplift-absorb judgment 宣称 active baseline 已 absorbed 或重写整个 DB/API 主文档

### BR-086 P3.3.12 `cutover_vs_fact_owner_boundary_v4`
- **Status:** Frozen
- **Rule:** P3.3.12 当前正式冻结 `cutover_vs_fact_owner_boundary_v4`：即使 fuller-cutover judgment 前进一步，有效复习事实、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 与 completion / 到账类主反馈当前仍必须以后端 / cloud fact layer 为准；local stronger-ingest path 最多只允许进入 absorb-judgment-level candidate，不允许升格为 final fact owner。
- **Applies to:** BR / UI / DB / API / TEST / settlement governance
- **Checkable:**
  1. 当前不得把 local stronger-ingest absorb-candidate 写成上述最终事实已可由本地裁定
  2. stronger-ingest candidate 当前最多只允许进入更清楚的 accept / reject / duplicate / progress-candidate / completion-candidate 规则、更明确的 precondition / postcondition / hold-reason / evidence ownership、以及与 widened subset 直接绑定的最小 ingest contract
  3. `本地已接管复习事实 / 今日完成判定 / 奖励到账 / streak主导 / completion由本地裁定 / review_group已退场 / active DBAPI已升级 / uplift已absorbed` 继续属于 overclaim

### BR-087 P3.3.12 `exit_candidate_to_true_exit_transition_v1`
- **Status:** Frozen
- **Rule:** P3.3.12 当前正式冻结 `exit_candidate_to_true_exit_transition_v1`：当前只允许判断 exit-candidate → true-exit-gate 的最小条件，不允许进入 true exit transition；rollback target 仍必须继续固定为 `cloud_review_group_current_runtime_path`，current visible owner 身份、retained fallback anchor 身份、active continuation 当前承接路径、以及 completion gating / settlement trigger 的解释通路当前都不得提前改动。
- **Applies to:** BR / UI / DB / API / TEST / rollback governance
- **Checkable:**
  1. 当前只允许讨论 rollback target / fallback scope 何时才可能变动、`review_group` 何时才可能从 current owner + retained anchor 过渡到非 current owner、以及哪些 docs / QA / UI copy 需要先脱离 group-only dependency
  2. 本轮不得把上述 future change 写成已经发生
  3. true-exit transition 相关判断仍必须后置于 no-overclaim / no-cleanup / still-backend-owned-final-facts 护栏之内

### BR-088 P3.3.12 `phase6_writeback_order_v1`
- **Status:** Frozen
- **Rule:** P3.3.12 当前正式冻结 `phase6_writeback_order_v1`：回写顺序必须先 Room 2 tech note，再 Room 3 rules note，再 Room 5 UI preflight，再由 Room 1 absorb / pin；当前只能把 fuller-cutover absorb candidate、true-exit-gate、uplift-absorb judgment、以及 exit-candidate → true-exit transition 条件写成 judgment，最多只允许 widened subset 的延续层、stronger-ingest absorb-candidate binding prep、source-neutral / retained-anchor-aware UI migration prep、以及 rollback / hold / observability floor 写成 execution-ready candidate。
- **Applies to:** BR / DB / API / UI / TEST / rollout governance
- **Checkable:**
  1. 当前不得把 full cutover completed、`review_group` true exit、active DB/API uplift absorbed、final fact owner shift、或 cleanup 已生效写入主 BR
  2. rollback / hold / fallback / observability 与 no-overclaim statement 当前仍必须成套存在
  3. 当前若要被 Room 1 吸收到下一轮 `R1 → R4` handoff，至少必须满足：不触碰首页 route / active continuation / final fact owner，`review_group` 仍保持 current owner + retained anchor，不把 uplift-absorb judgment 写成 active uplift


## 5. 高风险边界用例

## 5. 高风险边界用例（必须统一口径）

### E-001 只打开 App / 只进入学习页
- **Expected:** 不得表达为“今天开始学习了”或“已完成今日任务”

### E-002 新词目标已满，但复习未满
- **Expected:** 只能表达“部分完成”；不得表达“今日任务完成”

### E-003 完成一组复习，但今日复习总量未达口径
- **Expected:** 只能表达“本组完成”或“已完成一部分”，不得表达“今日复习完成”

### E-004 Session 已 started
- **Expected:** 只能表达 Session 已开始，不得表达 valid session completed

### E-005 Session 已 ended，但 validation 仍 pending
- **Expected:** 只能表达“待校验 / 正在确认”，不得表达 valid 或到账成功

### E-006 签到成功
- **Expected:** 只代表签到事实成立；不得自动表达为有效学习日成立、streak 成立或今日已学完

### E-007 奖励浮层已展示
- **Expected:** 只代表结算结果已展示或已进入结算链路；若 `reward_settlement_status` 非 `succeeded`，不得默认到账成功

### E-008 奖励来源事件已创建，但账本未落
- **Expected:** 允许 UI 表达“结算中 / 稍后刷新补齐”，不得把余额已增加写死

### E-009 用户连续点击学习提交 / 结算按钮
- **Expected:** 不得重复记录、不重复发奖、不重复推进状态

### E-010 `check_in` 与 `learning_day` 后续被证明需要强关联
- **Expected:** 当前版本仍按分离处理；若要收紧关系，必须作为下一版 BR 变更，而不是在实现/UI里偷偷绑定

### E-011 Session 达到 15 分钟，但有效 attempts 总和 < 5
- **Expected:** 只能在校验完成后记为 `invalid`；不得仅因计时达标就记为 `valid`

### E-012 当日无待复习内容
- **Expected:** 复习要求自然满足；`daily_goal_status` 是否进入 `completed` 只再取决于新词目标是否满足，而不应因“无复习可做”被卡死

### E-013 结算浮层展示成长承接语
- **Expected:** 可使用中性承接语，如“可去看看今天的变化”；但若后端未确认，不得直接写成“已升级 / 已解锁”

### E-014 同一 `review_group_id` 下重复提交 / 重试 / 刷新
- **Expected:** 同一用户同一时刻不得并行存在多个 active group；同组重复提交、刷新、重试时，不得重复生成“本组完成”结果，不得重复推进今日复习进度，不得重复产生 `review_group_completed` 来源事件或重复发奖

### E-015 active review group 未完成时中途退出或跨 Session 返回
- **Expected:** 已被接受的 attempts 必须保留；未完成 group 允许在后续 Session 中继续完成；不得因中断被静默清空，也不得被自动算作完成

### E-016 当日签到成功，但当日没有任何有效学习
- **Expected:** 当前 MVP 下应表达为 `check_in=true`、`learning_day=false`；`streak` 可按签到口径延续；不得自动表达 `daily_goal_status=completed`、`learning_day=true` 或“今天已完成有效学习”

### E-017 同一自然日重复签到
- **Expected:** 第二次签到只能失败或返回已存在结果；不得重复增加 `current_streak`、不得重复触发节点奖励、不得重复产生 `check_in` 来源事件

### E-018 当日发生有效学习，但用户未签到
- **Expected:** 当前 MVP 下应表达为 `check_in=false`、`learning_day=true`；不得自动补写当日签到成功；`streak` 不延续

### E-019 `check_in` / `learning_day` / `streak` 的 local_date 跨天边界
- **Expected:** 三类自然日口径统一按用户时区折算后的 `local_date` 处理；跨天、时区切换或临界时间点由后端作为最终真相源，前端不得本地补脑重算

### E-020 post-P2 persistence 切流时 Today / Secondary / Customize 混源
- **Expected:** 不允许 `/me/today` 读 PostgreSQL、而 `/me/secondary-summary` 仍读 JSON；也不允许 Inventory / Equipment / Shop purchase 在同一业务链路中混用不同真相层。若暂不能同源，必须显式降级，而不是继续假装实时一致。

### E-021 migration / maintenance / read_only 窗口下的写操作
- **Expected:** `feed`、`purchase`、`equip / unequip`、`check-in`、`session finish` 若被暂停，接口必须返回可识别的“暂不可用 / 稍后再试 / 当前只读 / 维护中”语义；不得返回 generic error，也不得假成功。

### E-022 Today / Meow Home / Customize 只读快照展示
- **Expected:** 允许展示最后可信快照，但必须与 fresh backend truth 严格区分；不得把只读快照写成“刚刚已完成 / 已到账 / 已刷新成功”。

### E-023 rewards / summary rebuild 中的中性提示
- **Expected:** 若奖励摘要、余额、装备或 companion summary 正在 rebuild，允许使用中性同步提示；不得把 rebuild 中 / delayed / settling 写成 succeeded、已到账或已升级。

### E-024 active `review_group` 存在且今日新词仍未完成
- **Expected:** Today 主 CTA 默认先承接“继续本组复习”；不得因为新词还未完成，就自动改写为“先学新词”。

### E-025 无 active `review_group`，但后端确认存在待复习 / 高优先复习任务
- **Expected:** 允许“先去复习”高于“去学新词”；但“更高”只能以后端确认或后续冻结规则为准，UI 不得自行猜评分。

### E-026 统计 summary 中的“学习天数”表达
- **Expected:** 若进入 statistics minimal spec，“学习天数”必须基于 `learning_day`；不得写成“签到天数”或“当前 streak 天数”。

### E-027 future streak stance 已被记录，但当前 basis 未切换
- **Expected:** 允许产品 / 文档记录未来可能转向 `learning_day` 或组合条件；但当前实现、UI、统计与测试仍必须按 `streak_basis_type = check_in` 执行。

---

### E-028 上传成功但用户误以为已同步
- **Expected:** 只能表达“上传成功 / 备份成功”，不得表达“已同步 / 所有设备已一致”。

### E-029 下载成功但 apply 未执行
- **Expected:** 只能表达“下载完成 / 已取回 snapshot”，不得表达“已恢复”。

### E-030 restore warning 未提示 `daily_goal` 等最小设置层覆盖风险
- **Expected:** 若 snapshot 包含最小设置层，warning 必须显式包含设置项可能被覆盖的提示。

### E-031 `daily_goal` 修改后历史日被重算
- **Expected:** 禁止；历史 `daily_goal_status` 与历史统计保持原样，新值只影响当前设置生效后的今日 / 后续判断。

### E-032 UI / API 把 `1–500` 当长期 frozen business rule
- **Expected:** 禁止；当前只能按 recommendation / validation range 理解，是否升格需 Room 1 单独 pin。

### E-033 Study / Review 任一 4 按钮被点击
- **Expected:** 只能表达为 rating input 已提交；不得自动表达“已掌握 / 已完成 / 奖励到账 / 已升级”。

### E-034 StudyPage 与 ReviewPage 的 4 按钮顺序不一致
- **Expected:** 禁止；两页必须保持 `again -> hard -> good -> easy` 的同一顺序，不得页面级重排或反向。

### E-035 首页“背单词”入口点击后被实现层自动分流
- **Expected:** 当前只允许默认进入 `StudyPage`；新词 / 复习 / 混合 session 自动分流仍属 pending，不得由执行层自行拍板。

### E-036 ReviewPage 以本地 FSRS due cards 替代云端 `review_group`
- **Expected:** 禁止；P3.3 第一拍中 `review_group` 仍是 ReviewPage 的云端 truth layer，本地 FSRS 只能作为 side-effect bridge / local scheduling reality。

### E-037 P3.3.1 最终 wording 未统一或被替换成 forbidden wording
- **Expected:** 禁止；P3.3.1 当前 frozen wording 只能是 `不认识 / 模糊 / 记得 / 秒答`。不得替换成 `掌握 / 已会 / 会了 / 完成 / 熟练 / 记住了` 等越界词，也不得在 Study / Review 两页各用一套。

### E-038 4 按钮提交成功后出现 false-success 文案
- **Expected:** 禁止；除非后端真实返回 groupCompleted、奖励到账等已成立事实，否则 UI 不得在提交后显示“已完成 / 奖励到账 / 已掌握 / 已更新计划 / 已同步复习安排”。

### E-039 当前轮显示 `previewDurations` / interval preview
- **Expected:** 禁止；P3.3.1 当前 `previewDurations` 继续 deferred，不得在 Study / Review 按钮下方或提交反馈中显示“下次将在 X 天后复习”等稳定预估文案。

### E-040 ReviewPage bridge failure 阻断云端主链路
- **Expected:** 禁止；若 cloud submit 已成功而本地 bridge 失败，当前轮必须继续保持 non-blocking，不得阻断 next item / group completion / settlement 主链路，也不得把 bridge failure 回滚成主链路失败。


### E-041 首页存在 active `review_group` continuation 时点击“背单词”
- **Expected:** 默认仍进入 `StudyPage`；若需要强调 continuation，高优先承接只能通过独立 CTA / helper / priority block 实现，不得 silent reroute，不得吞掉默认 `/study` 入口

### E-042 首页展示“继续复习”提示
- **Expected:** 可表达“继续复习 / 你有一组复习未完成”，但不得写成“系统已自动为你切换到复习模式”或“背单词入口已自动改为复习入口”

### E-043 ReviewPage 本地 FSRS side-effect 成功或失败
- **Expected:** cloud `review_group` 继续作为主队列 / completion / settlement truth；local FSRS side-effect 成功不得写成“主复习计划已更新”，失败也不得回滚 cloud submit 或阻断 next item / group completion / settlement 主链路

### E-044 当前 dual-store owner split 被误写成 unified planner
- **Expected:** 文案、UI、测试、实现不得把 `cloud-first + local side-effect` 写成“云端与本地已统一为同一 planner”或“本地 FSRS 已正式接管复习规划”

### E-045 local due cards 存在，但 cloud serving layer 当前不给出 review-ready
- **Expected:** 不得仅凭 local due count / local overdue / local scheduler 结果表达“现在就该复习”；页面级 readiness truth 仍以后端 review-serving layer 为准

### E-046 active `review_group` continuation 存在，且同时有 due / high-priority / new words
- **Expected:** continuation 继续最高优先；首页若承接 review continuation，只能通过独立 CTA / helper / priority block 承接，不得 silent reroute，也不得吞掉默认 `study_default` 入口

### E-047 `next_group_eligible` 已成立，但下一组尚未生成
- **Expected:** 只能表达“具备进入下一组的资格 / 当前可进入下一层 review-serving path”；不得写成“下一组已生成 / 已在页面上就绪 / 已下发到客户端”

### E-048 current owner split 被误写成 local FSRS 已主导页面规划
- **Expected:** local FSRS 只继续作为 scheduling candidate / device-side scheduling owner；不得被写成页面 readiness truth、priority winner、group producer 或 unified planner 已成立

### E-049 `previewDurations` 被顺手拉回 UI / 文案 / 测试
- **Expected:** 本轮不得出现在首页、StudyPage、ReviewPage、CTA helper、review explanation 或测试通过标准里；不得写成“下次将在 X 天后复习 / 预计 X 天后再次出现”




### E-050 StudyPage first-shot 显示 preview hint
- **Expected:** 只允许以极轻 secondary hint 形式显示在 StudyPage 4 按钮区下方；必须带“预计 / 仅供参考”语气；不得抢主反馈、不得写成稳定计划承诺

### E-051 ReviewPage / 首页误显示 preview
- **Expected:** 当前轮 ReviewPage 与首页继续禁止 preview；不得通过 helper、summary block、CTA 下方或 continuation 卡片顺手展示 preview

### E-052 cloud submit success 后 local stronger bridge fail
- **Expected:** cloud submit success 继续成立；local failure 继续 non-blocking；不得回滚 cloud submit、不得阻断 next item / group completion / settlement；必须进入 dev/test 可观察 fallback

### E-053 stronger bridge / preview 被误写成计划事实
- **Expected:** 无论 stronger bridge 成功或 preview 出现，都不得写成“系统已安排 / 已更新计划 / 已同步复习安排 / 下次将在 X 天后复习 / 已确认最佳复习路径 / 云端与本地已统一”


### E-054 future local planner owner 方向被接受，但页面 / helper / summary 被写成当前已切换
- **Expected:** 禁止；只能表达 future target-state candidate / migration direction，不得写成“本地已接管当前复习主链路”或“当前已切到本地规划”

### E-055 `backup success` 被误写成 `sync success` 或多设备已一致
- **Expected:** 禁止；只能表达“备份成功 / 上传成功”；不得表达“已同步 / 多设备已统一 / 云端与本地已一致”

### E-056 restore apply 前后被混写成同一层成功语义
- **Expected:** 下载 / 获取 snapshot、restore apply success、sync success 必须继续严格分层；只有 restore apply 成功后，目标设备本地 planner state 才成为该设备新的 runtime truth

### E-057 `review_group` compatibility / deprecation path 被误写成已退场
- **Expected:** 禁止；当前只能表达“兼容层 / 过渡层 / staged deprecation candidate”，不得写成“已退出 runtime / 已全部迁移完成 / 本地已完全替代”

### E-058 current runtime 首页入口与 future planner-aware routing 被混写
- **Expected:** 当前仍只能表达 `home_word_entry = study_default` + continuation 高优先但不得 silent reroute；不得把 future planner-aware entry、mixed / auto-routing 写成当前既成事实

### E-059 preview / explanation 借 owner shift 方向被偷升格为 committed plan fact
- **Expected:** 禁止；即使 future local planner 方向被接受，当前也不得写成“系统已安排 / 已更新你的复习计划 / 计划已统一 / 下次将在 X 天后复习”


### E-060 local-serving candidate 被误写成 current ReviewPage 队列来源
- **Expected:** 禁止；`local_due_queue_candidate` / `local_generated_review_session_candidate` 当前只能作为 compatibility / shadow / parity 实体，不得写成“当前复习队列来自本地”

### E-061 `review_group` 被误写成已退出运行态
- **Expected:** 禁止；当前只能表达 `review_group = runtime serving owner + compatibility anchor + deprecated candidate`，不得写成“已退场完成 / 已完全由本地替代”

### E-062 local-serving evidence 直接推进今日目标 / 奖励 / streak 最终事实
- **Expected:** 禁止；local-serving candidate 当前最多只能作为 fact ingest candidate / shadow evidence，不能直接改账本、今日目标完成、`check_in / learning_day / streak`

### E-063 future routing compatibility 被误写成 auto-routing 已生效
- **Expected:** 禁止；当前仍只能表达 `home_word_entry = study_default` + continuation 高优先但不 silent reroute，不得写成“系统已自动为你选入口 / mixed session 已启用”

### E-064 shadow / parity 结果泄漏成用户事实
- **Expected:** 禁止；shadow / parity success、mismatch、flag 开启都只能停留在 debug / dev / QA 证据层，不得写成“已升级新模式 / 本地 serving 已启用 / owner shift 已完成”

### E-065 deprecated / compatibility-only 标记误伤用户
- **Expected:** deprecated candidate 只进注释 / contract / 测试清单；compatibility-only 资产仍维持当前页面可用性；页面不得出现“旧方案即将失效”类惊扰文案

### E-066 shadow-entry flags 被默认打开或改变 current runtime truth
- **Expected:** 禁止；`localServingShadowEnabled` 等 flags 当前默认关闭，只允许作为 shadow-entry preparation；不得直接改变 ReviewPage truth、首页入口或 completion / settlement 主链路


### E-067 local shadow queue / parity mismatch 被用户看见
- **Expected:** 禁止；shadow queue compare、parity mismatch、accept / reject / duplicate shadow 证据、routing shadow 判断与任何 “本地更优 / 已准备接管” 的 internal 结论都只能停留在 internal-only 层

### E-068 shadow compare 结果“看起来更合理”就被写成已切换
- **Expected:** 禁止；最多只能表达为 shadow evidence / parity evidence / compare result，不得写成 owner shift 已完成、本地已接管 ReviewPage 或当前复习路径已由本地正式主导

### E-069 `review_group` baseline 被 shadow mode 误写成已退场
- **Expected:** 禁止；P3.3.7 当前 `review_group` 仍是 current runtime owner + shadow compare baseline，不得因为 local shadow run 已开启就写成“已失效 / 已退出运行态”

### E-070 `study_default` 被 routing shadow 偷改成 runtime auto-routing
- **Expected:** 禁止；routing shadow 当前只能进 hidden marker / flag-prep / evidence 层，首页 runtime 继续保持 `home_word_entry = study_default` + continuation 独立承接

### E-071 local fact ingest shadow evidence 改动最终账本 / 今日目标 / streak
- **Expected:** 禁止；local fact ingest 当前只能比较 accept / reject / duplicate 与 candidate evidence，不得直接改 ledger / daily_goal / learning_day / streak / settlement 最终事实

### E-072 shadow-entry flags 默认开启或越权改变 current runtime truth
- **Expected:** 禁止；flags / seams 当前只允许作为 hidden / feature-off / evidence-run preparation，默认不得打开；即使打开 internal-only 试验，也不得影响用户路径、ReviewPage current truth 或 final fact owner


### E-073 first-cutover 被误写成 full cutover
- **Expected:** 禁止；当前只允许写成 first very narrow cutover preflight / ReviewPage 内部 serving seam 的极小切口，不得写成 owner shift completed / 新主链路已生效

### E-074 `review_group` dual posture 被误写成已退场或 fallback-only
- **Expected:** 禁止；当前必须继续写成 `current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate`，不得提前降成 fallback-only，更不得写成可直接清理

### E-075 serving seam 切换顺手改写首页 route / active continuation
- **Expected:** 禁止；首页 `study_default`、active continuation 独立承接、以及 no-silent-reroute 当前都必须继续保持不变

### E-076 local-serving 结果被写成 final fact 已跟着切换
- **Expected:** 禁止；有效复习、今日目标完成、奖励到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准

### E-077 candidate seam / stronger ingest 被误写成 active DB/API baseline uplift
- **Expected:** 禁止；本轮只允许 seam / marker / evidence / rollback floor 升到 first-cutover-ready，不允许 schema rewrite、endpoint core semantics rewrite、或 active baseline uplift

### E-078 rollback / hold / observability 缺失却仍宣称 first-cutover-ready
- **Expected:** 不合格；若无明确 rollback target、hold trigger、fallback path 与最小 observability 证据位，本轮不得被写成 ready for first cutover execution


### E-079 fuller cutover judgment 被误写成 full cutover completed
- **Expected:** 禁止；当前只允许写成 fuller-cutover judgment / next-layer candidate review，不得写成主链路已切完、owner shift 已完成、或当前已进入新主 serving

### E-080 `review_group` retained anchor 被误写成 fallback-only / 已退场 / 可清理
- **Expected:** 禁止；当前必须继续写成 `current runtime serving owner + retained fallback anchor + compatibility anchor + deprecated candidate`，不得提前降成 fallback-only，更不得写成可直接清理

### E-081 continuity-adjacent subset 扩大顺手改写首页 route / active continuation
- **Expected:** 禁止；首页 `study_default`、active continuation 独立承接、以及 no-silent-reroute 当前都必须继续保持不变

### E-082 stronger ingest candidate 被误写成 final fact owner 已前进
- **Expected:** 禁止；有效复习、今日目标完成、奖励到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准；stronger ingest candidate 只到 uplift-judgment-ready

### E-083 uplift-judgment-ready seam 被误写成 active DB/API baseline uplift
- **Expected:** 禁止；当前只允许写成 uplift judgment / uplift-ready，不允许写成 active baseline 已升级、生效 uplift、或 DB/API 主文档已按新主链路改写

### E-084 exit-gate / uplift judgment 缺少 migration / rollback / hold note 却仍宣称下一层 ready
- **Expected:** 不合格；若无 migration note、rollback note、hold note 与 no-overclaim statement，本轮不得被写成 ready for fuller-cutover execution judgment


### E-085 fuller-cutover execution-ready subset 被误写成 full cutover execution
- **Expected:** 禁止；当前只允许写成 execution-ready subset，不得写成主链路已切完、owner shift 已完成、或 ReviewPage 已全面切到 local-serving

### E-086 `review_group` exit-candidate 被误写成 true exit / fallback-only / 可清理
- **Expected:** 禁止；当前必须继续写成 `current runtime serving owner + retained fallback anchor + compatibility anchor + deprecated candidate`，不得降成 fallback-only，更不得写成 old path 可清理

### E-087 continuity-adjacent execution-ready subset 顺手改写首页 route / active continuation
- **Expected:** 禁止；首页默认主 route、active continuation source 与 no-silent-reroute 当前都必须继续保持不变

### E-088 uplift-readiness seam 被误写成 active DB/API baseline uplift absorbed
- **Expected:** 禁止；当前只允许写成 uplift-readiness / readiness seam family，不得写成 active baseline 已升级、endpoint meaning 已改、或 runtime truth 已同步替换

### E-089 validated stronger-ingest candidate 被误写成 final fact owner 已前进
- **Expected:** 禁止；有效复习、今日目标完成、奖励到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准；validated stronger-ingest candidate 只到 execution-ready candidate，不得写成 fact owner shift

### E-090 retained-anchor narrowing 超过 wording / helper 范围
- **Expected:** 禁止；当前只允许 very narrow 缩窄 wording / helper / empty-state / fallback copy 的 group-only 耦合，不得提前缩窄 rollback target、completion gating、settlement trigger、active continuation identity 或 non-cutover baseline path



### E-091 fuller-cutover absorb-candidate judgment 被误写成 fuller cutover 已 absorbed
- **Expected:** 禁止；当前 widened family 只允许进入 absorb-candidate judgment，不得写成 ReviewPage / 首页 review 承接层已 absorbed into runtime truth

### E-092 `review_group` true-exit gate judgment 被误写成 true exit / cleanup 已开始
- **Expected:** 禁止；当前最多只允许判断是否够资格进入 true-exit gate，`review_group` 仍必须保持 current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate，不得写成已退场、fallback-only、historical-only、或可直接清理

### E-093 uplift-absorb judgment 被误写成 active DB/API baseline uplift absorbed
- **Expected:** 禁止；少数 seam 只允许进入 uplift-absorb judgment，不得写成 active DB/API baseline 已升级、endpoint meaning 已重写、或 runtime truth 已同步替换

### E-094 stronger-ingest absorb-candidate 被误写成 final fact owner 已前进
- **Expected:** 禁止；有效复习、今日目标完成、奖励到账、`check_in / learning_day / streak` 与 completion / 到账类主反馈当前仍必须以后端 / cloud fact layer 为准；stronger-ingest 只到 absorb-judgment-level candidate，不得越权成 final fact owner

### E-095 true-exit transition 条件被误写成 rollback target / current owner posture 已可变动
- **Expected:** 禁止；rollback target 仍必须固定为 `cloud_review_group_current_runtime_path`，current visible owner 身份、retained fallback anchor 身份、active continuation 当前承接路径、以及 completion gating / settlement trigger 解释通路当前都不得提前改动

### E-096 judgment / candidate / runtime truth 三层被静默混写
- **Expected:** 不合格；P3.3.12 当前必须继续把 fuller-cutover absorb candidate、true-exit-gate、uplift-absorb judgment、execution-ready candidate 与 runtime truth 显式分层；凡把 judgment 直接写成 absorbed / true exit / cleanup / runtime owner shift 的，都属于 overclaim


## 6. 术语表 / Glossary / Naming Mapping

### 6.1 业务术语
- **主机制 / Main mechanism**：新词学习、复习、今日目标、Session、签到 / streak、学习结果结算、主机制事件输出
- **副机制 / Secondary mechanism**：喵喵主页、货币 / EXP、喂猫、装扮、欢迎语、签到奖励、Session 奖励等承接层
- **有效学习 / effective learning**：由后端判定、可计入主机制事实与后续奖励的学习行为
- **有效复习 / effective review**：由后端判定、可计入主机制事实与后续奖励的复习行为
- **今日目标 / daily goal**：当日新词与复习任务的聚合口径
- **签到事实 / check-in fact**：用户在当日完成签到动作的事实；当前 MVP 下可用于签到展示、签到奖励与 streak 延续
- **学习日事实 / learning day fact**：用户在当日达到有效学习条件的事实；它独立于签到事实存在
- **连续事实 / streak fact**：当前 MVP 下按 `check_in` 延续的连续天数相关事实；不默认等同 `learning_day`
- **复习组 / review_group**：后端生成、后端持有的一次有限复习批次对象，是“本组完成”的最小业务单位
- **组级完成 / review_group_completed**：当前 `review_group_id` 下要求完成的 item 已全部有效提交并被服务端唯一确认的组级事实
- **CTA winner**：Today 页当前时刻唯一最强主 CTA 的最终归属；本轮只冻结最小仲裁层级，不冻结完整评分算法
- **`today_primary_action`**：可能用于 Today 页 decision-support 的 future candidate / clarification example；在 Room 1 未进一步 pin 前，不自动等于 active API contract
- **`next_group_readiness`**：是否已可进入下一组复习的后端聚合判断；UI 不得凭 remaining count 自行推断
- **statistics minimal spec / summary-first**：本轮允许进入的最小统计规格；优先只做到 summary / minimal summary，而不是完整统计页
- **future stance**：对未来规则演进方向的明确记录；它不自动等于当前实施切换或 active contract 变化
- **来源事件 / reward source event**：可触发奖励结算的主机制事件
- **奖励账本 / reward ledger**：最终的 Coins / Fish Treats / EXP 发放记录
- **同源一致性 / same-source consistency**：同一业务窗口内，Today / Secondary / Customize 相关关键链路都从同一真相层读取，不允许一部分读 PostgreSQL、一部分读 JSON
- **只读窗口 / read-only window**：系统允许浏览最后可信数据，但暂停关键写操作的受控窗口
- **维护窗口 / maintenance window**：系统为切流、重建或校验进入的受控窗口；必须映射到明确的 user-facing behavior
- **展示快照 / displayed snapshot**：为了可用性而展示的最后可信快照；它不自动等于 fresh backend truth，更不自动等于成功完成
- **新鲜后端真相 / fresh backend truth**：当前时刻以后端确认、且可作为最终业务状态引用的最新事实

### 6.1E P3.3.7 术语补充
1. `limited execution / shadow mode`：只让 candidate 在 dev / flag / QA evidence 层真实跑起来的阶段；它不自动等于 runtime owner shift、也不自动等于 cutover 开始
2. `shadow evidence`：影子运行产生的 compare / parity / ingest / routing 证据；当前只能证明“候选方案在影子层发生了什么”，不能证明 runtime truth 已变
3. `parity pass`：先守住 current runtime truth 与 fact-copy guardrails，再满足最小 compare 稳定性的通过状态；它不是 cutover pass
4. `acceptable mismatch`：当前允许存在、但必须持续记录的 mismatch；它只能停留在 evidence 层，不能影响用户路径或 final fact owner
5. `must-hold mismatch`：一旦出现就说明 shadow 已越过 compatibility / evidence 边界，必须立即 hold 的 mismatch
6. `must-escalate mismatch`：一旦出现就触碰 DB / API core semantics、reward-settlement owner、`review_group` owner posture 或 runtime routing 等跨模块核心契约，必须升级给 Room 1 / Room 2
7. `runtime truth leakage`：任何 shadow / candidate / parity 结果被用户感知、或实际改变了 current runtime truth / final fact owner 的情况；这是本轮最关键的 stop-condition

### 6.1D P3.3.6 术语补充
1. `local_due_queue_candidate`：未来可能由本地 FSRS 提供的复习队列候选；当前只允许进入 compatibility / shadow / parity 层，不表示 current ReviewPage truth
2. `local_generated_review_session_candidate`：未来 local planner 为一次复习会话生成的 serving 包装候选；当前只表示 session-level packaging candidate，不表示当前用户已走本地 serving 会话
3. `compatibility anchor`：当前仍承担 runtime 合同职责、同时被明确纳入兼容与未来退场准备的对象；它既不是 current owner 之外的旁路说明，也不是已退场对象
4. `deprecated candidate`：未来可能退场的对象；当前只表示进入标记与 write-back 管理层，不表示已删除 / 已迁移完
5. `fact ingest candidate`：local-serving candidate 未来进入 cloud fact / settlement layer 的候选接口语义；当前只表示 evidence / candidate 层，不表示 active fact owner 改写
6. `shadow-only evidence`：仅供 debug / dev / QA / parity 使用的影子证据层；当前不应泄漏到用户事实层
7. `marker / contract-only tests`：用于验证 runtime truth / compatibility-only / deprecated candidate / shadow-only evidence 四层标记不漂移的测试集合

### 6.1C P3.3.5 术语补充
### 6.1D P3.3.8 术语补充
1. `phase3_gate_decision`：只回答“是否具备进入下一层 candidate / migration review 的资格”的 gate 结论，不等于 cutover 已完成
2. `proceed_to_next_layer_candidate_review`：允许进入下一层 very narrow candidate / migration 审查，不等于进入 runtime execution
3. `limited_cutover_scope_candidate`：未来可能讨论的最小切口候选；当前只允许停留在 seam / migration / rollback / hold / note 层
4. `review_group_exit_gate`：判断 `review_group` 是否具备进入真实退场讨论资格的 gate；不等于当前轮直接退场
5. `fact_settlement_cutover_boundary`：限定哪些最终事实当前仍以后端为准，以及 local evidence 当前最多能进入哪一层 ingest candidate
6. `migration note / rollback note / hold note`：用于说明候选迁移如何推进、何时回退、何时停止的三类最小治理文档；三者缺一不可
7. `gate / candidate / migration round`：只做下一层资格判断与候选收口，不做 runtime owner shift 或主链路切换

1. `future primary planning owner`：未来可成为主规划 owner 的目标方向；当前只表示方向被接受，不表示 runtime 已切换
2. `serving owner`：当前页面真正用于提供复习队列 / continuation / completion / settlement 主链路的真相层 owner；P3.3.5 当前 runtime 仍是 cloud review-serving layer
3. `fact / settlement owner`：用于裁定有效复习、今日目标完成、奖励结算、签到 / streak 等最终业务事实的 owner；P3.3.5 当前 runtime 继续在 cloud / backend fact layer
4. `compatibility / deprecation path`：旧 contract 进入过渡与退场准备阶段；它既不是 current owner，也不是已经被彻底删除
5. `recovery artifact`：云端 latest backup 当前只是恢复用载体；它不自动等于 live serving truth，更不自动等于多设备已一致
6. `planner-facing explanation candidate`：未来可能进入的规划解释层候选；当前只表示 explanation 方向可讨论，不表示 committed plan fact
7. `staged rollout`：按 Phase 0（contract gate）→ Phase 1（compatibility contract）→ Phase 2（shadow / parity）→ Phase 3（cutover / cleanup）逐阶段推进；本轮仍只到 compatibility-prep / semantic rewrite / shadow-prep 边界

### 6.1A P3.1 direct-scope delta 术语补充
1. `upload success`：当前本地 snapshot 成功上传到云端 backup container
2. `download completed / snapshot fetched`：云端 snapshot 已成功取回到本机，但尚未自动 apply
3. `restore success / apply success`：只有在 pre-check + warning + confirm + apply 全部成功后，才允许作为本机恢复成功的业务事实
4. `daily_goal`：当前 direct-scope delta 中的显式用户设置动作；local-first 生效，snapshot 只承接最小设置层

### 6.1B P3.3 / P3.3.1 术语补充
1. `rating input`：用户对当前卡片回忆质量 / 难度感受的输入，不等于 mastery 或结果事实
2. `controlled best-effort`：cloud-first 前提下，本地 bridge 允许 non-blocking failure，但 fallback 必须在 dev / test 侧可观察，且不得产生用户可见假事实
3. `previewDurations` / `interval preview`：候选解释性增强；P3.3.1 当前轮正式 deferred，不等于 active DB / API / review contract
4. `final wording freeze`：当前轮已由 Room 1 吸收并冻结的最终两字中文词面；若未来重开，必须再次经过 scope pin / BR 升版

### 6.1F P3.3.9 术语补充
1. `first very narrow cutover`：第一轮只切一个极窄 runtime seam 的 cutover preflight；它不等于 full cutover，更不等于 owner shift completed
2. `serving seam`：ReviewPage 内部“当前一组复习项从哪里来”的局部 runtime 接缝；当前允许讨论的 first-cutover 只限这一小段
3. `retained fallback anchor`：新切 very narrow seam 一旦进入 hold / rollback 时，继续由 `review_group` 承担的保底锚点；它不等于 `review_group` 已退场
4. `dual posture`：`review_group` 在本轮同时承担 current runtime owner 与 retained fallback anchor 的并存姿态；它也继续是 compatibility anchor 与 deprecated candidate
5. `stronger ingest candidate`：比纯 evidence 更靠近 active ingest path 的候选接缝；当前仍不是 final fact owner，也不自动构成 settlement owner shift
6. `first-cutover-ready seam`：已具备 retained-anchor、rollback / hold / observability floor 的 seam-candidate；只表示“可进入下一层执行审查”，不表示已切换生效
7. `baseline uplift`：把 DB/API candidate seam、marker、或 migration note 正式提升为 active baseline 的动作；当前仍不属于 P3.3.9 范围

### 6.2 命名映射
| Canonical term | UI / API / DB 说明 | 禁止继续作为主命名的平行叫法 |
|---|---|---|
| `daily_goal_status` | 今日目标聚合状态 | 无 |
| `session_validation_status` | Session 是否有效的最终校验状态 | `session_valid_status`（若未映射说明） |
| `reward_settlement_status` | 来源事件层面的结算状态 | `session_reward_status`, `reward_settlement_last_status` |
| `reward_items[].reward_status` | 单条奖励项到账状态 | 不得替代 `reward_settlement_status` |
| `check_in` | 签到事实 | 不得默认等同 `learning_day` 或今日完成 |
| `streak` | 连续天数相关事实 | 当前 MVP 下按 `check_in` 延续；不得默认等同 `learning_day` |
| `learning_day` | 有效学习日事实 | 不得默认由签到推出；成立也不自动等于 `streak` 延续 |

### 6.3 命名治理规则
1. UI / API / DB 可以有路径差异，但必须只有一套 canonical term
2. 若存在 alias，必须在映射表说明
3. 同一业务状态不得同时保留多个无映射平行主名

---

### 6.1E P3.3.3 review planning contract v1 术语补充
- **`ready_now`**：当前存在可被 review-serving layer 立即服务的复习工作单元；页面级 readiness truth 以后端 aggregate / review-serving summary 为准
- **`not_ready_now`**：当前 review-serving layer 无法立即提供可做的 review work；不等于“本地没有 due cards”，也不等于“以后都不需要复习”
- **`next_group_eligible`**：当前没有 active group，且已满足生成 / 发放下一组 review work 的最小前提；不自动等于“下一组已生成 / 已可见 / 已下发”
- **`temporarily_unservable`**：当前轮 review-serving layer 暂时无法稳定提供可服务结果；它是阶段性不可服务，不是永久否定
- **review readiness truth**：页面当前能否进入复习、是否可服务的最终业务判断；当前继续以后端 review-serving layer 为准
- **scheduling candidate signals**：local FSRS 在设备侧输出的调度候选信号，如 local due / next_due candidate、interval、stability、difficulty、review logs 等；它不自动等于 serving truth
- **serving outputs / serving truth**：cloud `review_group` 当前继续承担的 review queue serving、continuation、next review work serving、completion / settlement 等页面级可服务真相层
- **owner split**：cloud `review_group` = serving truth owner；local FSRS = device-side scheduling owner；当前 owner split 不等于 planner merge / unified planner


## 7. 冲突优先级（当前项目默认）

当出现规则冲突时，默认按以下优先级处理：
1. 当前 active ORG
2. 当前 active PROJECT_RULES_MASTER
3. 当前 active PRD
4. 当前 active BR / RULES / GLOSSARY / CONFLICT_MATRIX
5. 当前 active DB / API 设计
6. 当前 active 数值草案
7. 当前 active UI SPEC / 页面结构稿
8. 当前 active plan / TEST / BUG 记录
9. 当前 active Role Cards
10. 临时聊天理解 / 临时口头说明

### 7.1 冲突处理规则
1. 上层已有定义，下层不得擅自重定义
2. 发现缺失，必须补文档，不得默默在实现里替代
3. 发现冲突，必须冻结冲突点，不允许平行推进
4. 冲突点必须回写到对应 SSOT，不能只停在聊天

### 7.2 当前已识别的冲突 / 漂移
1. **命名漂移已部分修补**：UI 已从旧命名收口到 `reward_settlement_status` / `session_validation_status`，但下游实现与测试仍必须遵循本映射表，避免 alias 回流
2. **`check_in` / `learning_day` / `streak` 关系已完成本轮冻结**：当前不是“继续 pending”，而是“当前 MVP 下三者分离、`streak` 按 `check_in` 延续”；未来若要改 basis，必须走下一版 BR 变更
3. **`review_group` 当前不是“完全未冻结”**：最小业务契约已冻结，且本轮已把 continuation / readiness 最小规则与主因子层写硬；但 group size、分组算法、review priority 详细权重与完整 SRS 仍保持 pending；Room 4 不得补脑扩写这些算法细节
4. **CTA winner 当前不是“完全未定”**：单一强按钮与最小仲裁层级已冻结，但完整优先级算法与 `today_primary_action` 是否正式进入 active contract 仍保持 pending
5. **statistics 这轮不是“统计页未定所以完全不管”**：summary-first 已进入 Frozen；但是否展开为独立 minimal page 或更深统计产品仍保持 pending

---

## 8. Pending Decisions（需 Room 1 决策 / pin）

### 6.1G P3.3.10 术语补充
1. `fuller cutover judgment`：只判断下一拍是否具备扩大 cutover subset 的资格；不等于 fuller cutover 已执行、更不等于 full cutover 已完成
2. `continuity-adjacent serving subset`：仍留在 ReviewPage 边界内、与 continuation 共边但不改 continuation owner 的下一层 very narrow subset
3. `exit-candidate judgment-ready`：`review_group` 已具备进入真实 exit judgment 讨论资格的状态；它不等于当前轮直接退场
4. `uplift-judgment-ready seam`：已经足够讨论 active baseline uplift 的 seam；它不等于 active uplift 已 absorbed
5. `retained anchor`：当前仍承担 rollback / fallback 兜底职责的 `review_group` 运行态锚点；在本轮既不是 purely historical object，也不是可直接清理对象
6. `cutover vs fact-owner boundary`：限定 serving subset 可以如何前进，以及哪些最终事实仍必须继续以后端为准的边界
7. `judgment / candidate / runtime truth` 三层：本轮只能把 fuller cutover、exit-gate、uplift 写成 judgment；最多只允许极窄 subset、rollback / hold / observability floor、以及 source-neutral helper / summary / state migration prep 写成 execution-ready candidate；不得把它们写成 current runtime truth



### 6.1H P3.3.11 术语补充
1. `fuller-cutover execution-ready subset`：在 fuller-cutover judgment 基础上，允许前进一步但仍 very narrow 的执行准备层；它不等于 full cutover execution，更不等于 runtime owner shift completed
2. `exit-candidate`：`review_group` 已具备进入真实 exit 审查前的资格判断层；它不等于 true exit、fallback-only、或 old path 可清理
3. `uplift-readiness`：某些 seam 已足够进入 active baseline uplift 审查前的 readiness 层；它不等于 active DB/API baseline uplift absorbed
4. `validated stronger-ingest candidate execution layer`：比 judgment-ready 更前进一步的 stronger ingest candidate 执行准备层；它不等于 final fact owner
5. `retained-anchor narrowing`：仅对 group-only wording / helper / empty-state / fallback copy 的 very narrow 缩窄；它不等于 rollback target、completion gating、settlement trigger、或 active continuation identity 的路径级缩窄
6. `execution-ready / exit-candidate / uplift-readiness / runtime truth` 四层：本轮只能把 widened subset、exit-candidate、uplift-readiness 与 stronger-ingest candidate 写成准备层；不得写成 runtime truth
7. `not active uplift / not true exit / not current runtime truth`：本轮对任何 overclaim 的最小护栏标签；若没有这些边界，当前就不应被写成 execution-ready candidate


### 6.1I P3.3.12 术语补充
1. `fuller-cutover absorb candidate`：比 execution-ready 更前进一步、可被判断是否值得进入 fuller-cutover absorb 审查的 widened family；它不等于已 absorbed into runtime truth
2. `true-exit-gate judgment`：判断 `review_group` 是否已具备进入 true exit 审查资格的门；它不等于 true exit、fallback-only、或 cleanup
3. `uplift-absorb judgment`：判断某些 seam 是否已具备进入 active baseline uplift absorbed 审查资格的层；它不等于 active DB/API baseline 已升级
4. `absorb-judgment-level stronger candidate`：比 validated stronger-ingest candidate 更接近 absorbed 审查的一层 stronger-ingest 候选；它仍不等于 final fact owner
5. `still-dependent paths`：当前仍阻止 `review_group` 进入 true exit 的关键依赖路径，包括 active continuation identity、completion gating、settlement trigger、rollback target、baseline path 与 compatibility anchor
6. `judgment / execution-ready candidate / runtime truth` 三层：P3.3.12 当前只能把 fuller-cutover absorb candidate、true-exit-gate、uplift-absorb 与 exit-candidate → true-exit transition 写成 judgment；execution-ready 只限 widened subset 的延续层、UI migration prep、stronger-ingest absorb-candidate binding prep、rollback / hold / observability floor；不得写成 runtime truth
7. `not active uplift / not true exit / not absorbed / still backend-owned final facts`：本轮任何 overclaim 都必须被这些边界硬锁住；否则当前就不应被吸收到主 BR


### PD-001 `streak` 后续演进方向
- **Why pending:** 当前已冻结“keep current frozen + record future stance”；未来是否真的改为 `learning_day` 或组合条件、何时进入下一轮评估、是否引入补签 / 宽限逻辑，仍未冻结。
- **建议收口问题：**
  1. 是否在后续版本把 `streak` 从 `check_in` 改为 `learning_day`
  2. 是否允许并存多种 streak 类型
  3. 是否引入更复杂的补签 / 宽限机制
  4. 若进入下一轮评估，最小触发条件是什么

### PD-002 `review_group` 分组算法细节
- **Why pending:** 当前已冻结最小业务契约、continuation / readiness 最小规则与主因子层；但 group size、分组算法、题型比例、review priority 详细权重与完整 SRS 仍未冻结。
- **建议收口问题：**
  1. 一组的具体大小
  2. 分组算法与题型比例
  3. review priority 与 SRS 的后续衔接方式
  4. 是否需要 very small summary contract clarification 以减少 Room 5 / Room 4 补脑

### PD-003 熟练度 / 掌握阈值
- **Why pending:** 主机制 PRD / Main / DB 都将其列为开放问题
- **建议收口问题：**
  1. `is_mastered` 的判定公式
  2. 是否与里程碑奖励直接绑定
  3. 是否允许 MVP 先用简化阈值

### PD-004 CTA winner 详细算法 / contract 深度
- **Why pending:** 当前已冻结最小仲裁层级，但“何谓更高优先级”、`reason` 枚举、`session_pending` 是否进入统一仲裁，以及 `today_primary_action` 是否正式进入 active contract，仍未冻结。
- **建议收口问题：**
  1. 是按 due / overdue、pending review、还是由后端返回推荐动作为准
  2. 当新词、复习、Session 都可进入时如何确定主 CTA
  3. `today_primary_action` 是否进入 very small contract clarification

### PD-005 统计页后续展开深度
- **Why pending:** 当前已冻结 summary-first minimal spec，但是否进一步展开为独立 minimal page、是否加长周期曲线与更深指标，仍由 Room 1 管范围 pin。
- **建议收口问题：**
  1. 是否从 summary-first 进入独立 minimal page
  2. 若进入，最小字段与最小图表范围是什么
  3. 是否允许后续进入 retention / mastery / accuracy 等更深统计

### PD-006 `daily_goal` 最终上下限
- **Question:** `1–500` 是否从当前 recommendation 升格为 frozen business rule？
- **Current state:** Pending
- **Room 3 default:** 继续保持 recommendation，待 Room 1 单独 pin。

### PD-007 `latest snapshot apply first-shot` 的规则级别
- **Question:** latest-only restore 是否要从当前推荐路径升格为 frozen business rule？
- **Current state:** Pending
- **Room 3 default:** 当前可作为推荐实现路径，但未升格为 frozen。

### PD-008 destructive actions 的未来开放策略
- **Question:** `delete backup` / `clear local` 是否未来开放、若开放优先哪一个？
- **Current state:** Pending
- **Room 3 default:** 继续不进本轮。

### PD-010 首页“背单词”点击后的 mixed / auto-routing deeper session contract
- **Question:** 在已冻结 `home_word_entry = study_default` 的前提下，未来是否要进入基于 readiness / active `review_group` / mixed mode 的更深 session 自动分流合同？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 default entry 与 continuation 高优先但不等于 silent reroute；mixed / auto-routing deeper contract 仍未拍板，Room 4 不得自行补脑。

### PD-011 云端 `review_group` 与本地 FSRS 的最终 planner merge / unified planner 收敛方向
- **Question:** 在已冻结 owner split 的前提下，长期看是否需要进入 planner merge / unified planner？若需要，谁是最终主 owner、何时进入、以什么 contract 进入？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 `cloud review_group = serving truth owner` 与 `local FSRS = device-side scheduling owner`；owner split 不等于 planner merge，不等于 unified planner 已成立。

### PD-012 `StudyPage` 与 `ReviewPage` 是否长期共用统一学习页
- **Question:** 后续是否收敛为一套统一学习页 / 统一交互承接层？
- **Current state:** Pending
- **Room 3 default:** 第一拍不拍板；当前仍保留 Study / Review 两页现实，不得把“未来可能统一”写成 active truth。

### PD-013 `previewDurations` 的后续扩展范围与进入层级
- **Question:** 在已冻结 `StudyPage only + estimated hint / reference-only + local FSRS preview candidate` 的前提下，未来是否要进一步扩展到 ReviewPage、首页、helper / summary block，或进入更完整的 preview explanation system？
- **Current state:** Pending（P3.3.4 当前只冻结最小 re-entry 合同）
- **Room 3 default:** 当前只冻结 StudyPage first-shot 的最小 hint 合同；ReviewPage / 首页落位、完整 explanation system、以及任何会被误读为稳定计划事实的扩展继续保持 pending。

### PD-014 readiness 的完整 reason enum / threshold algorithm / local-only mode
- **Question:** readiness 未来是否需要进入完整 reason enum、时间窗 / 阈值算法、或 local-only readiness mode？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 4 个最小 readiness 语义与 truth-source hierarchy；完整 reason / threshold / local-only mode 继续保持 pending。

### PD-015 `review_group_generation` 的 exact group size / full generation algorithm
- **Question:** generation 未来是否要把 exact group size、regeneration 细则、next-group issuance 时间窗等写进硬合同？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 generation owner + completion gating + `next_group_eligible` 边界；exact group size 与 full generation algorithm 继续 pending。

### PD-016 stronger bridge 的上限与更深收口方向
- **Question:** 在已冻结 stronger-but-still-non-blocking 的最小 bridge 合同后，未来是否需要进入 must-succeed bridge、planner owner shift、planner merge / unified planner，或跨 API / DB core semantics 的更深收口？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 stronger ensure / init、observability、failure handling floor 与 minimal repair path；must-succeed bridge、owner shift、planner merge、以及任何跨 API / DB core semantics 的更深改写继续保持 pending。

### PD-017 planner owner shift / local-serving cutover 的进入条件
- **Question:** 在 P3.3.5 已接受 target-state candidate + staged migration 边界的前提下，何时才允许从“方向被接受”进入真正的 runtime owner shift / local-serving cutover？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 future target-state candidate、compatibility / deprecation path、backup/restore semantic rewrite 与 shadow / parity prep；runtime owner shift completed / local-serving cutover 继续等待下一轮专门 execution gate。

### PD-018 backup rebase 后的 sync / merge 策略是否未来重开
- **Question:** 在 cloud 已降到 backup / restore / optional aggregate support 的方向被接受后，未来是否要重新评估 real-time sync / auto merge / delta sync？
- **Current state:** Pending
- **Room 3 default:** 当前仍坚持 manual backup / no real-time sync / no auto merge / no delta sync；若未来重开，必须单独 scope pin，不得借 P3.3.5 静默打开。

### PD-019 P3.3.8 gate 通过后先开哪一段 candidate cutover
- **Question:** 若 `phase3_gate_decision_v1` 通过，下一轮 very narrow candidate execution 应先从 `review_group` exit 条件准备、fact ingest stronger-path、helper / summary / state contract migration、还是 DB / API seam formalization 开始？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结“最小切口集合”，不冻结具体先后顺序；先后顺序必须由 Room 1 结合 Room 2 / Room 5 的 migration / rollback / hold note 再次 pin。

### PD-020 `review_group` 何时具备真实退场资格
- **Question:** 在 contract / test / doc / boundary 四类前置条件逐步齐备后，`review_group` 何时才允许从 current runtime owner + compatibility anchor + deprecated candidate 进入真正的退场判断？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 exit gate 条件，不冻结真实退场时点；若未来要退场，必须单开下一轮 scope pin，且不得绕开 final fact / settlement truth 边界。

### PD-021 local evidence 何时允许从 stronger ingest candidate 升格为 active fact path input
- **Question:** 若 future stronger-path candidate 逐步稳定，何时才允许 local evidence 进入更强的 active ingest path，且不构成 fact owner shift？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 stronger ingest candidate 与 final fact-owner guardrails；active ingest path 升格仍需 Room 2 / Room 1 再次单独 pin。


### PD-019 Compatibility Contract v1 何时允许进入 Phase 2 shadow-entry
- **Question:** 在 P3.3.6 已冻结 Compatibility Contract v1 的前提下，何时才允许从“compatibility / shadow-prep”进入真正的 shadow run / parity compare / limited execution？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 candidate entities、compatibility posture、fact ingest candidate、routing compat、write-back markers 与 shadow/parity 证据边界；flags / seams 默认仍 feature-off，进入 Phase 2 前必须再过一轮 execution gate。

### PD-020 `review_group` compatibility anchor 何时允许进入真正退场
- **Question:** 在 P3.3.6 已把 `review_group` 冻结为 current runtime owner + compatibility anchor + deprecated candidate 的前提下，何时才允许进入真实退场 / local-serving cutover？
- **Current state:** Pending
- **Room 3 default:** 当前只接受 staged deprecation / compatibility 管理；`review_group` 退出运行态、local due queue 接管 current ReviewPage truth、以及相关 DB / API rewrite 继续等待下一轮专门 cutover / runtime-shift gate。




### PD-021 Phase 2 shadow evidence 何时足以支持进入 Phase 3 判断
- **Question:** 在 P3.3.7 已冻结 shadow execution / visibility / mismatch / gate 边界的前提下，何时才算证据足够，可以正式进入 Phase 3 / cutover 判断？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结“先守 guardrails，再累计可解释、可复现、可回归 evidence”的最小 gate；是否足以进入 Phase 3，必须等 shadow queue compare、fact ingest evidence、routing shadow 与 `review_group` posture 的长期稳定性被进一步证明后，再由 Room 1 单独 scope pin。

### PD-022 shadow / parity internal-only 结果是否未来允许转成用户可见迁移说明
- **Question:** 在 future owner shift / cutover 真的临近时，当前 internal-only 的 shadow / parity / migration wording 是否需要转成用户可见的 migration messaging / mode declaration？
- **Current state:** Pending
- **Room 3 default:** P3.3.7 当前一律禁止用户可见 overclaim；若未来需要用户可见迁移说明，必须在专门的 cutover / rollout communication round 中重新定义，不得借本轮静默打开。



## 9. 回写建议（给 Room 1 / Room 2 / Room 4 / Room 5）

### 9.1 给 Room 1
1. 将本文件作为 `BR-OPP-001_v0.2.9.md` 的增量升版候选，供下一轮治理层 SSOT 吸收 / pin
2. 在 Main / Status 中吸收以下新增已冻结结论：
   - `shadow_execution_scope_v1`：local-serving / fact-ingest / routing candidate 当前只允许进入 limited execution 的 internal evidence 层
   - `shadow_result_visibility_v1`：shadow 结果当前只允许 dev / test / internal debug / QA evidence / patch draft 可见，禁止用户可见
   - `mismatch_severity_rule_set_v1`：`info_only / warning / must_hold / must_escalate` 四层必须显式分开
   - `shadow_acceptance_gate_v1`：pass 先看 current runtime truth / `review_group` posture / final fact owner guardrails 是否守住，再看 parity 是否逐步稳定
   - `fact_copy_guardrails_v1`：shadow wording 只允许 internal-only，不得过度承诺为 runtime cutover
   - `shadow_to_phase3_gate_v1`：Phase 2 的任务是收集 evidence，不是证明“现在就能切过去”
3. 继续保持 pending / future-focus item 不被偷升格：
   - runtime owner shift completed / local-serving runtime cutover
   - `review_group` 退出运行态
   - auto-routing runtime
   - planner merge / unified planner
   - DB schema rewrite / API core semantics rewrite
   - 用户可见 owner-shift / migration 宣告

### 9.2 给 Room 2
1. 在下一轮 technical closeout / execution handoff 中继续把以下内容保持为技术待决项，不要静默写成 active truth：
   - shadow evidence 是否足以支持 Phase 3
   - 哪些 mismatch 仍属 acceptable，哪些必须 hold / escalate
   - future DB / API seam 是否真的需要进入 Phase 3
   - local fact ingest evidence 何时才允许触碰 active fact / settlement path
2. 继续守住当前 P3.3.7 frozen 边界：
   - 不把 local shadow source 写成 current ReviewPage truth
   - 不把 `review_group` 写成已退场
   - 不把 shadow run 写成 runtime owner shift completed
   - 不让 flags / seams 影响 current runtime truth 或 final fact owner

### 9.3 给 Room 5
1. 在下一轮 UI sync 中继续守住：
   - shadow 结果全部 internal-only
   - 当前 Home / Study / Review 的 user-visible truth 保持不变
   - helper / label / debug wording 不得越权进入用户文案
   - 不得出现“本地已接管 / 新 serving 已生效 / 影子结果已通过因此已切换”类 overclaim
2. 若未来要把 migration / mode-change 信息做成用户可见说明，必须由 Room 1 单独开新 round pin，不得借 P3.3.7 静默升格

### 9.4 给 Room 4
1. 把新增的 BR-054 ~ BR-059 纳入最小回归集
2. 测试至少覆盖：
   - `local_due_queue_candidate / local_generated_review_session_candidate / fact_ingest_shadow_evidence / routing_shadow_candidate` 的 limited execution 范围
   - current runtime truth 不变、`review_group` current owner posture 不变、final fact / settlement truth 不变
   - `info_only / warning / must_hold / must_escalate` 四层 mismatch 分桶
   - stop conditions：shadow 进入用户可见层、影响 current ReviewPage truth、影响 final fact owner、routing shadow 进入 runtime、需要改 DB / API core semantics
   - fact-copy guardrails：所有 shadow wording 均保持 internal-only，不进入用户文案


### PD-023 first-cutover 的真实执行入口何时允许从 preflight 进入 execution handoff
- **Question:** 在 P3.3.9 已把 first very narrow cutover 的 subset、retained-anchor、fact-owner guardrails 与 rollback / hold / observability 写硬后，何时才允许进入 `R1 → R4` 的真实 first-cutover execution handoff？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 preflight；进入 execution 仍需 Room 1 结合 Room 2 / Room 5 的 seam、migration、rollback 与 overclaim 审查再次单独 pin。

### PD-024 `review_group` 何时允许从 dual posture 进入 fallback-only
- **Question:** 在 first-cutover 真正执行后，`review_group` 何时才允许从 `current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate` 进一步降到 fallback-only？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 dual posture；fallback-only 及其后的真实退场都必须后置到下一轮，不得在 P3.3.9 预先吸收。

### PD-025 stronger ingest candidate 何时允许进入更强 active ingest path
- **Question:** 若 first-cutover seam 稳定，local-serving 结果何时才允许从 stronger ingest candidate 进入更强的 active ingest path，而仍不构成 fact owner shift？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 stronger ingest candidate 与 final fact-owner guardrails；更强 active ingest path 仍需 Room 2 / Room 1 在后续轮次单独 pin。

### PD-026 fuller cutover 下一拍真正先开哪一段 subset
- **Question:** 若 P3.3.10 judgment 通过，ReviewPage continuity-adjacent serving-adapter family 中，真正 first execution-ready 的 very narrow next subset 应该先开哪一段？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结“可扩大到哪一层”，不冻结具体执行顺序；真正顺序仍需 Room 1 结合 Room 2 / Room 5 的 rollback / hold / UI source-neutral 化结论再次单独 pin。

### PD-027 `review_group` 何时允许从 retained anchor 进入真实 exit judgment
- **Question:** 在 contract / test / doc / runtime / boundary 五类前置条件逐步齐备后，`review_group` 何时才允许从 retained anchor 进入真实 exit judgment，再进一步讨论 fallback-only 或真实退场？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 exit-gate 条件，不冻结真实进入时点；fallback-only、真实退场与 cleanup 仍必须后置到下一轮，不得在 P3.3.10 预先吸收。

### PD-028 uplift-judgment-ready seam 何时允许进入 active baseline uplift 审查
- **Question:** 若某些 seam 已足够 uplift-judgment-ready，何时才允许把它们带入 active DB/API baseline uplift 审查，而不构成“active baseline 已升级”的 overclaim？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 uplift judgment；active uplift absorbed、DB schema rewrite、API core semantics rewrite 仍需 Room 2 / Room 1 在后续轮次单独 pin。



### PD-029 fuller-cutover execution-ready subset 真正先开哪一段
- **Question:** 若 P3.3.11 execution-ready subset 被接受，ReviewPage continuity-adjacent serving-adapter family 中真正 first execution-ready 的 very narrow widening 应先开哪一段？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结“可扩大到哪一层”，不冻结 widened subset 的具体执行顺序；真正顺序仍需 Room 1 结合 Room 2 / Room 5 的 rollback / hold / retained-anchor-aware UI 结论再次单独 pin。

### PD-030 `review_group` 何时允许从 exit-candidate 进入 true exit 审查
- **Question:** 在 exit-candidate 前置条件逐步齐备后，`review_group` 何时才允许从 current owner + retained anchor 进入 true exit 审查，再进一步讨论 fallback-only、true exit 与 cleanup？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 exit-candidate，不冻结 true exit 时点；任何 fallback-only、true exit、old-path cleanup 仍必须后置到下一轮，不得在 P3.3.11 预先吸收。

### PD-031 uplift-readiness seam 何时允许进入 absorbed-candidate 审查
- **Question:** 若某些 seam 已足够 uplift-readiness，何时才允许把它们带入 active DB/API baseline uplift absorbed 的前置审查，而不构成“baseline 已生效”的 overclaim？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 readiness，不冻结 absorbed；absorbed-candidate 必须后置到下一轮，并与 no-overclaim、rollback floor、hold note、retained anchor 与 final fact owner 边界一起审。

### PD-032 validated stronger-ingest candidate 何时允许进入更强 active ingest path
- **Question:** 若 stronger-ingest candidate execution layer 逐步稳定，何时才允许它进入更强的 active ingest path，而仍不构成 final fact owner shift？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 validated stronger-ingest candidate execution layer 与 final fact-owner guardrails；active ingest path 升格仍需 Room 2 / Room 1 再次单独 pin。


### PD-033 fuller-cutover absorb-candidate 哪一段真正先进入 absorbed 审查
- **Question:** 若 P3.3.12 的 fuller-cutover absorb-candidate judgment 被接受，ReviewPage + 首页 review 承接层 widened family 中，真正 first absorbed-candidate 审查应先开哪一段？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结“哪些 widened family 已够资格进入 absorb-candidate judgment”，不冻结具体 absorbed 审查顺序；真正顺序仍需 Room 1 结合 Room 2 / Room 5 的 blast-radius / rollback-complexity / retained-anchor-aware UI 结论再次单独 pin。

### PD-034 `review_group` 何时允许从 true-exit-gate judgment 进入 true exit 审查
- **Question:** 在 still-dependent paths、replacement readiness、rollback target 替代、安全 fallback scope、与 no-cleanup assertions 逐步齐备后，`review_group` 何时才允许从 true-exit-gate judgment 进入 true exit 审查，再进一步讨论 fallback-only、true exit 与 cleanup？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 true-exit-gate judgment，不冻结 true exit 审查时点；任何 fallback-only、true exit、old-path purge 仍必须后置到下一轮，不得在 P3.3.12 预先吸收。

### PD-035 uplift-absorb judgment 何时允许进入 active baseline uplift absorbed 审查
- **Question:** 若某些 seam 已足够进入 uplift-absorb judgment，何时才允许把它们带入 active DB/API baseline uplift absorbed 的前置审查，而不构成“baseline 已生效”的 overclaim？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结 uplift-absorb judgment，不冻结 absorbed；active uplift absorbed、DB schema rewrite、API core semantics rewrite 仍需 Room 2 / Room 1 在后续轮次单独 pin，并与 no-overclaim、rollback floor、hold note、retained anchor 与 final fact owner 边界一起审。


## 10. 变更记录

### v0.2.14 (2026-04-11)
- 以 `BR-OPP-001_v0.2.13.md` 为 base，吸收 P3.3.12 已收口、且已被 Room 1 同意进入主 BR 回写的规则边界，形成 `P3.3.12 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_12_ScopePin_and_Handoff_Pack_v0.1.md`、`R2_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_Tech_Note_v0.1.md`、`R3_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_UI_Preflight_v0.1.md`、`Main_updated_2026-04-10_v32.md`、`STATUS_updated_2026-04-10_v30.md`
- 新增 BR-083 ~ BR-088：`fuller_cutover_absorb_candidate_v1`、`review_group_true_exit_gate_v1`、`db_api_uplift_absorb_judgment_v1`、`cutover_vs_fact_owner_boundary_v4`、`exit_candidate_to_true_exit_transition_v1`、`phase6_writeback_order_v1`
- 更新 E-091 ~ E-096，补齐 absorb-candidate judgment 被误写成 absorbed、`review_group` true-exit gate 被误写成 true exit / cleanup、uplift-absorb judgment 被误写成 active baseline uplift absorbed、stronger-ingest absorb-candidate 被误写成 final fact owner 前进、true-exit transition 条件被误写成 rollback target / current owner posture 已可变动、以及 judgment / candidate / runtime truth 三层被静默混写的高风险边界用例
- 新增 6.1I glossary 补充，并新增 PD-033 ~ PD-035，保留 widened family 的 absorbed 审查顺序、`review_group` 从 true-exit-gate judgment 进入 true exit 审查的时点、以及 uplift-absorb judgment 进入 active baseline uplift absorbed 审查的时点为 pending
- 不吸收 full cutover completed、runtime owner shift completed、`review_group` true exit 已生效、active DB/API baseline uplift absorbed、cleanup / old-path purge、homepage route / planner-aware runtime route、active continuation source switch、auto-routing runtime、unified planner / planner merge、final fact owner shift、DB schema rewrite、API core semantics rewrite、以及任何用户可见 cutover / exit / uplift 宣告

### v0.2.13 (2026-04-11)
- 以 `BR-OPP-001_v0.2.12.md` 为 base，吸收 P3.3.11 已收口、且已被 Room 1 同意进入主 BR 回写的规则边界，形成 `P3.3.11 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_11_ScopePin_and_Handoff_Pack_v0.2.md`、`R2_P3_3_11_FullerCutoverExecution_ExitCandidate_and_DBUpliftReadiness_Tech_Note_v0.1.md`、`R3_P3_3_11_FullerCutoverExecution_ExitCandidate_and_DBUpliftReadiness_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_11_FullerCutoverExecution_ExitCandidate_and_DBUpliftReadiness_UI_Preflight_v0.1.md`、`R1_to_R4_P3_3_11_Execution_Handoff_v0.1.md`、`Main_updated_2026-04-10_v31.md`、`STATUS_updated_2026-04-10_v29.md`
- 新增 BR-077 ~ BR-082：`fuller_cutover_execution_rule_set_v1`、`review_group_exit_candidate_v1`、`db_api_uplift_readiness_v1`、`cutover_vs_fact_owner_boundary_v3`、`retained_anchor_narrowing_guardrail_v1`、`phase5_writeback_order_v1`
- 更新 E-085 ~ E-090，补齐 execution-ready subset 被误写成 full cutover、`review_group` exit-candidate 被误写成 true exit / fallback-only / 可清理、continuity-adjacent execution-ready subset 顺手改写首页 route / continuation、uplift-readiness seam 被误写成 active baseline uplift、validated stronger-ingest candidate 被误写成 final fact owner 前进、以及 retained-anchor narrowing 超过 wording / helper 范围的高风险边界用例
- 新增 6.1H glossary 补充，并新增 PD-029 ~ PD-032，保留 widened subset 具体执行顺序、`review_group` 从 exit-candidate 进入 true exit 审查的时点、uplift-readiness seam 进入 absorbed-candidate 审查的时点、以及 validated stronger-ingest candidate 进入更强 active ingest path 的时点为 pending
- 不吸收 full cutover completed、runtime owner shift completed、`review_group` true exit、active DB/API baseline uplift absorbed、cleanup / old-path purge、homepage route / planner-aware runtime route、active continuation source switch、auto-routing runtime、unified planner / planner merge、final fact owner shift、DB schema rewrite、API core semantics rewrite、以及任何用户可见 cutover / exit / uplift 宣告

### v0.2.12 (2026-04-11)
- 以 `BR-OPP-001_v0.2.11.md` 为 base，吸收 P3.3.10 已收口、且已被 Room 1 同意进入主 BR 回写的规则边界，形成 `P3.3.10 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`、`R2_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Tech_Note_v0.1.md`、`R3_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_10_FullerCutover_ExitGate_and_DBUplift_UI_Preflight_v0.1.md`、`Main_updated_2026-04-10_v30.md`、`STATUS_updated_2026-04-10_v28.md`
- 新增 BR-071 ~ BR-076：`fuller_cutover_rule_set_v1`、`review_group_exit_gate_v2`、`cutover_vs_fact_owner_boundary_v2`、`db_api_uplift_judgment_v1`、`retained_anchor_to_exit_transition_v1`、`phase4_writeback_order_v1`
- 更新 E-079 ~ E-084，补齐 fuller-cutover judgment 被误写成 full cutover、`review_group` retained anchor 被误写成 fallback-only / 退场、continuity-adjacent subset 顺手改写首页 route / continuation、stronger ingest candidate 误写成 final fact owner 前进、uplift-judgment-ready seam 误写成 active baseline uplift、以及 migration / rollback / hold note 缺失却仍宣称 ready 的高风险边界用例
- 新增 6.1G glossary 补充，并新增 PD-026 ~ PD-028，保留 fuller cutover 下一拍具体执行顺序、`review_group` 从 retained anchor 进入真实 exit judgment 的时点、以及 uplift-judgment-ready seam 进入 active baseline uplift 审查的时点为 pending
- 不吸收 full cutover completed、runtime owner shift completed、`review_group` 真退场、active DB/API baseline uplift 生效、cleanup / old path purge、auto-routing runtime、unified planner / planner merge、final fact owner shift、DB schema rewrite、API core semantics rewrite、以及任何用户可见 owner-shift / cutover / exit 宣告

### v0.2.11 (2026-04-11)
- 以 `BR-OPP-001_v0.2.10.md` 为 base，吸收 P3.3.9 已收口、且已被 Room 1 同意进入主 BR 回写的规则边界，形成 `P3.3.9 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md`、`R2_P3_3_9_FirstVeryNarrowCutover_Tech_Note_v0.1.md`、`R3_P3_3_9_FirstVeryNarrowCutover_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_9_FirstVeryNarrowCutover_UI_Preflight_v0.1.md`、`Main_updated_2026-04-10_v29.md`、`STATUS_updated_2026-04-10_v27.md`
- 新增 BR-065 ~ BR-070：`first_cutover_rule_set_v1`、`runtime_truth_switch_boundary_v1`、`review_group_retained_anchor_v1`、`fact_owner_guardrail_v1`、`db_api_cutover_candidate_v2`、`rollback_holdnote_and_observability_v1`
- 更新 E-073 ~ E-078，补齐 first-cutover 被误写成 full cutover、`review_group` dual posture 被误写为退场、serving seam 偷改首页 route / active continuation、local-serving 误触 final fact、candidate seam 被误写成 baseline uplift、以及 rollback / hold / observability 缺失却仍宣称 ready 的高风险边界用例
- 新增 6.1F glossary 补充，并新增 PD-023 ~ PD-025，保留 first-cutover execution handoff 时点、`review_group` 从 dual posture 进入 fallback-only 的时点、以及 stronger ingest candidate 升格条件为 pending
- 不吸收 runtime owner shift completed、ReviewPage local-serving full runtime cutover、`review_group` 真退场、cleanup / old path purge、active DB/API baseline uplift、DB schema rewrite、API core semantics rewrite、auto-routing runtime、planner merge / unified planner、以及任何用户可见 owner-shift / cutover 宣告

### v0.2.10 (2026-04-11)
- 以 `BR-OPP-001_v0.2.9.md` 为 base，吸收 P3.3.8 已收口、且已被 Room 1 接受进入主 BR 回写的规则边界，形成 `P3.3.8 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md`、`R2_P3_3_8_Phase3Gate_and_DB_API_Candidate_Tech_Note_v0.1.md`、`R3_P3_3_8_Phase3Gate_and_CutoverDecision_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_8_Phase3Gate_and_CutoverDecision_UI_Preflight_v0.1.md`、`R1_to_R4_P3_3_8_Execution_Handoff_v0.1_refreshed.md`
- 新增 BR-060 ~ BR-064：`phase3_gate_decision_v1`、`limited_cutover_scope_candidate_v1`、`review_group_exit_gate_v1`、`fact_settlement_cutover_boundary_v1`、`phase3_writeback_and_migration_v1`
- 更新 E-060 ~ E-065，补齐 gate 结论被误写成 cutover、`review_group` 退场 overclaim、candidate seam 被误写成 serving switch、local evidence 被误写成 final fact、以及 migration / rollback / hold note 缺失的高风险边界用例
- 新增 6.1D glossary 补充，并新增 PD-019 ~ PD-021，保留下一层 candidate cutover 顺序、`review_group` 真正退场时点、以及 stronger ingest candidate 升格条件为 pending
- 不吸收 runtime owner shift completed、ReviewPage local-serving runtime cutover、`review_group` 退出运行态、DB schema rewrite、API core semantics rewrite、auto-routing runtime、planner merge / unified planner、以及任何用户可见 cutover 宣告

### v0.2.9 (2026-04-10)
- 以 `BR-OPP-001_v0.2.8.md` 为 base，吸收 P3.3.7 已收口、且已被 Room 1 同意进入主 BR 回写的规则边界，形成 `P3.3.7 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md`、`R2_P3_3_7_LimitedExecution_and_ShadowMode_Tech_Note_v0.1.md`、`R3_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_UI_Preflight_v0.1.md`
- 新增 BR-054 ~ BR-059：`shadow_execution_scope_v1`、`shadow_result_visibility_v1`、`mismatch_severity_rule_set_v1`、`shadow_acceptance_gate_v1`、`fact_copy_guardrails_v1`、`shadow_to_phase3_gate_v1`
- 更新 E-067 ~ E-072，补齐 shadow result 泄漏、parity 结果 overclaim、`review_group` baseline 被误写为退场、routing shadow 偷改 runtime、local fact ingest evidence 触碰最终事实、flags 默认开启等高风险边界用例
- 新增 6.1E glossary 补充，并新增 PD-021 / PD-022，保留 Phase 3 / cutover 判断、用户可见 migration messaging、runtime owner shift completed 等更深问题为 pending
- 不吸收 runtime owner shift completed、ReviewPage local-serving runtime cutover、`review_group` 退出运行态、auto-routing runtime、planner merge / unified planner、DB schema rewrite、API core semantics rewrite 与用户可见 owner-shift 宣告等仍属 pending 的内容

### v0.2.8 (2026-04-10)
- 以 `BR-OPP-001_v0.2.7.md` 为 base，吸收 P3.3.6 已收口、且已被 Room 1 同意进入主 BR 回写的规则边界，形成 `P3.3.6 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md`、`R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md`、`R3_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_UI_Preflight_v0.1.md`、`Main_updated_2026-04-10_v26.md`、`STATUS_updated_2026-04-10_v24.md`
- 新增 BR-048 ~ BR-053：`local_serving_candidate_contract_v1`、`review_group_compatibility_posture_v1`、`fact_settlement_ingest_contract_candidate_v1`、`session_entry_and_routing_compat_v1`、`deprecation_markers_and_writeback_plan_v1`、`shadow_parity_test_strategy_v1`
- 更新 E-060 ~ E-066，补齐 local-serving candidate overclaim、`review_group` 退场误写、fact/settlement overclaim、routing overclaim、shadow/parity 泄漏与 flags 默认开启等高风险边界用例
- 新增 6.1D glossary 补充，并新增 PD-019 / PD-020，保留 Phase 2 shadow-entry、`review_group` 真正退场 / local-serving cutover、DB/API rewrite 等更深问题为 pending
- 不吸收 runtime owner shift completed、ReviewPage local-serving runtime cutover、local due queue 接管当前页面真相、`review_group` 退出运行态、auto-routing runtime、unified planner / planner merge、DB schema rewrite、API core semantics rewrite 与 full sync / real-time sync / auto merge 等仍属 pending 的内容

### v0.2.7 (2026-04-10)
- 以 `BR-OPP-001_v0.2.6.md` 为 base，吸收 P3.3.5 已收口、且已被 Room 1 pin 为最小合同的规则边界，形成 `P3.3.5 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`、`R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1.md`、`R3_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_UI_Preflight_v0.1.md`、`R1_to_R4_P3_3_5_Execution_Handoff_v0.1.md`
- 新增 BR-042 ~ BR-047：`planner_owner_shift_v2`、`review_serving_contract_v2`、`session_entry_and_routing_v2`、`preview_and_explanation_contract_v2`、`backup_restore_and_cross_device_boundary_v2`、`migration_and_deprecation_plan_v1`
- 更新 E-054 ~ E-059，补齐 future target-state candidate vs current runtime truth、backup / restore / sync 三层语义、`review_group` compatibility / deprecation、routing future candidate 与 preview / explanation fact-copy 禁区的高风险边界用例
- 新增 6.1C glossary 补充，并新增 PD-017 / PD-018，保留 runtime owner shift completed / local-serving cutover、sync / merge future reopening 等更深问题为 pending
- 不吸收 runtime owner shift completed、ReviewPage local-serving cutover、auto-routing runtime、unified planner / planner merge、preview / explanation system 全量升级、full sync / real-time sync / auto merge 等仍属 pending 的内容

### v0.2.6 (2026-04-10)
- 以 `BR-OPP-001_v0.2.5.md` 为 base，吸收 P3.3.4 已收口的规则边界，形成 `P3.3.4 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`、`R2_P3_3_4_PreviewReentry_and_StrongerBridge_Tech_Note_v0.1.md`、`R3_P3_3_4_PreviewReentry_and_StrongerBridge_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_4_PreviewReentry_and_StrongerBridge_UI_Preflight_v0.1.md`、`R1_to_R4_P3_3_4_Execution_Handoff_v0.1.md`
- 新增 BR-040 ~ BR-041：`preview_durations_reentry_contract_v1` 与 `reviewpage_stronger_bridge_contract_v1`
- 更新 E-050 ~ E-053，补齐 StudyPage preview hint、ReviewPage / 首页禁显 preview、stronger bridge failure non-blocking 与 preview / bridge 计划事实禁区的高风险边界用例
- 重写 PD-013，并新增 PD-016，保留 preview 扩展范围、must-succeed bridge / owner shift / planner merge 等更深合同为 pending
- 不吸收 Study + Review preview、preview explanation system、must-succeed bridge、planner owner shift、planner merge / unified planner、auto-routing、DB / API core change 与完整复习规划等仍属 pending 的内容

### v0.2.5 (2026-04-10)
- 以 `BR-OPP-001_v0.2.4.md` 为 base，吸收 P3.3.3 已收口的规则边界，形成 `P3.3.3 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`、`R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md`、`R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_3_ReviewPlanningContractV1_UI_Preflight_v0.1.md`、`R1_to_R4_P3_3_3_Execution_Handoff_v0.1.md`
- 新增 BR-035 ~ BR-039：`review_readiness_policy_v1`、`review_priority_policy_v1`、`review_group_generation_policy_v1`、`schedule_source_contract_v1`、以及 `previewDurations` continued defer + future re-entry boundary
- 更新 E-045 ~ E-049，补齐 readiness truth、priority hierarchy、generation gating、truth split 与 preview defer 的高风险边界用例
- 新增 6.1E glossary 补充，并新增 PD-014 / PD-015，保留 readiness 完整 reason / threshold 与 exact group size / full generation algorithm 为 pending
- 不吸收完整 SRS / full priority scoring / exact group size contract / planner merge / auto-routing / preview explanation 等仍属 pending 的内容


### v0.2.4 (2026-04-10)
- 以 `BR-OPP-001_v0.2.3.md` 为 base，吸收 P3.3.2 已收口的规则边界，形成 `P3.3.2 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`、`R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1.md`、`R3_P3_3_2_SessionEntry_PlannerOwner_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_2_SessionEntry_and_PlannerOwner_UI_Preflight_v0.1.md`、`R1_to_R4_P3_3_2_Execution_Handoff_v0.1.md`
- 新增 BR-033 ~ BR-034：`session_entry_policy_v1` 与 `planner_owner_split_v1`
- 更新 E-041 ~ E-044，补齐 default study entry、active review continuation、owner split 与 non-merge 的高风险边界用例
- 将 `PD-010` 改写为 mixed / auto-routing deeper session contract；将 `PD-011` 改写为 planner merge / unified planner 收敛方向
- 不吸收完整 SRS / auto-routing runtime contract / unified planner / unified Study-Review page / `previewDurations` future re-entry 等仍属 pending 的内容

### v0.2.3 (2026-04-10)
- 以 `BR-OPP-001_v0.2.2.md` 为 base，吸收 P3.3.1 已收口的规则边界，形成 `P3.3.1 closeout` 的 BR 增量主文档候选
- 同步输入依据到 `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md`、`R2_P3_3_1_PreviewDurations_and_FSRS_Bridge_Tech_Note_v0.1.md`、`R3_P3_3_1_Final_Wording_and_Bridge_Rules_Note_v0.1.md`、`UI_SPEC_P3_3_1_Copy_Polish_and_PreviewDurations_Delta_v0.1.1.md`、`R1_to_R4_P3_3_1_Execution_Handoff_v0.1.md`
- 将 P3.3.1 final wording freeze 正式回写为 Frozen：`不认识 / 模糊 / 记得 / 秒答`
- 新增 BR-031 ~ BR-032：ReviewPage bridge 的 `controlled best-effort` 语义、以及 `previewDurations` 当前轮继续 deferred / 不进入 active contract 的边界
- 更新 E-037 ~ E-040，补齐 final wording forbidden-copy、false-success、preview defer 与 bridge non-blocking 的高风险边界用例
- 将 `PD-009` 从 pending 移出（已由 Room 1 完成 final wording freeze）；将 `PD-013` 改写为 future re-entry 条件，不再把当前轮是否 deferred 保持为未决
- 不吸收完整 SRS / planner owner / session 自动分流 / 统一学习页等仍属 pending 的内容

### v0.2.2 (2026-04-10)
- 以 `BR-OPP-001_v0.2.1.md` 为 base，吸收 P3.3 第一拍已 close 的规则边界，形成 `P3.3 first-pass closeout` 的 BR 增量主文档候选
- 同步输入依据到当前推进层 SSOT：`Main_updated_2026-04-10_v19.md` / `STATUS_updated_2026-04-10_v18.md`
- 新增 BR-026 ~ BR-030：首页“背单词”主入口边界、4 按钮作为 rating input、与 FSRS 四档的单调映射、两字中文 requirement 与 fact-boundary、以及 P3.3 第一拍的复习规划边界 / owner split
- 新增 E-033 ~ E-038，补齐 P3.3 第一拍的 false-success、顺序一致性、session 自动分流、planner owner 与 candidate wording 边界用例
- 新增 PD-009 ~ PD-013，显式保留 P3.3 final wording、session 启动合同、planner owner / 收敛方向、统一学习页、previewDurations 的待决项
- 不吸收 P3.3 第二拍 focus，不把 candidate wording、完整 SRS / planner、session 自动分流、previewDurations 偷升格为 frozen

### v0.1.9-full.2 (2026-04-08)
- 作为 very small absorption patch，仅新增 2 条 Pending / Reconciliation 级条目：
  - `PD-009` 云端 `review_group` vs 本地 FSRS 双轨并存收敛方向
  - `PD-010` StudyPage 评分按钮最终方案（2 按钮 vs 4 按钮）
- 不新增 Frozen 规则，不改既有 BR-019A / BR-020 ~ BR-025，不重排其它条目编号

### v0.1.9-full.1 (2026-04-08)
- 作为 very small BR patch，只新增 `BR-019A`：
  - 明确 P3.1 当前总定位为 `local-first + simple backup`
  - 明确云端当前只是 `backup container`，不是 runtime truth，也不是 sync truth
- 不重排既有 BR-020 ~ BR-025，不改其它条目编号或 pending 项

### v0.1.9-full (2026-04-08)
- 以 `BR-OPP-001_v0.1.8.md` 为 full BR base，吸收 `BR-OPP-001_v0.1.9.md` 的 P3.1 direct-scope delta write-back 内容，重组成单文件可读的完整 BR baseline candidate
- 同步输入依据到当前推进层 SSOT：`Main_updated_2026-04-07_v17.md` / `STATUS_updated_2026-04-07_v16.md`
- 新增 BR-020 ~ BR-025：upload / download / restore 三层语义、restore manual-only + warning/confirm/no silent overwrite、`daily_goal` 生效边界、输入校验 recommendation 边界、以及本轮继续 out-of-scope 的显式 reaffirmation
- 新增 E-028 ~ E-032，补齐 P3.1 direct-scope delta 的高风险边界用例
- 新增 PD-006 ~ PD-008，显式保留 `daily_goal` 上下限、latest-only restore、destructive actions 的待决项


### v0.1.8 (2026-04-06)
- 以上一版 `BR-OPP-001_v0.1.7.md` 为 base，按用户明确说明“Room 1 已接受 `R3_P3_Rules_Freeze_Note_v0.1.1.md`、仅尚未更新 Main / STATUS”的前提，做 P3 rules sync patch
- 同步输入依据到当前 runtime active baseline：`Main_updated_2026-04-05_v15.md` / `STATUS_updated_2026-04-05_v14.md` / `BR-OPP-001_v0.1.7.md`
- 将 BR-009 从 Option C 最小 CTA winner 仲裁，推进为 P3 的“更完整优先级算法阶段”规则边界，并继续写硬 `decision-support contract ≠ active truth`
- 将 BR-014 从最小 `review_group` continuation / readiness 规则，推进为 P3 review system structured deepening 边界，写硬 `next_group_readiness / progress summary` 只能以后端聚合结果为准
- 将 BR-015 从 Option C 的 `summary-first` 最小规格，推进为 P3 的“独立 minimal page / deeper minimal product 判断”边界，并写硬默认 fallback 仍为 `summary-first`
- 将 BR-007 从 Option C 的 future stance 记录，推进为 P3 future streak basis 的正式决策准备边界，并继续写硬当前 runtime truth 仍保持 `streak_basis_type = check_in`
- 保留 BR-017 / BR-018 / BR-019 为 conditional frozen guardrails，不把 Option A 的条件冻结规则误写成 P3 active truth

### v0.1.7 (2026-04-05)
- 吸收 `review9.md` 中 Room 3 认可的 very small wording / governance patch
- 在 BR-009 再写硬：**CTA winner 规则冻结 ≠ `today_primary_action` 或等价聚合块已进入 active API baseline**
- 在 BR-009 增补：**continuation 的具体可用性 / readiness 不得只凭 `active_review_group_id` 存在就由前端自行补脑推断**
- 在 BR-015 再写硬：**summary-first 冻结的是统计规则边界与最小口径，不自动等于独立统计页已进入本轮实现范围**
- 在 9.3 给 Room 5 的回写建议中补一句：在 Room 1 未 pin Option C UI 输入前，本文件只作为 Option C UI 收口依据，不自动替代当前 runtime active UI baseline

### v0.1.6 (2026-04-05)
- 以上一版 `BR-OPP-001_v0.1.5.md` 为 base，按 Room 1 已同意的 `R3_OptionC_Rules_Freeze_Note_v0.1.1.md` 收敛结果，做 Option C very small rules sync patch
- 更新输入依据到当前 runtime active baseline：`Main_updated_2026-04-05_v13.md` / `STATUS_updated_2026-04-05_v12.md` / `BR-OPP-001_v0.1.5.md` / `背单词喵喵app_DB设计草案_v0.1.4.md` / `背单词喵喵app_API设计草案_v0.1.3.md`
- 将 CTA winner 最小仲裁层级正式回写到 BR-009：只冻结单一强 CTA + continuation 优先 + 后端确认的高优先复习可胜出；完整算法继续 Pending
- 将 `review_group` continuation / readiness 最小规则与主因子层回写到 BR-014，并显式写硬“Frozen rule ≠ summary contract 已存在”
- 将 statistics minimal spec 以 `summary-first` 形式正式回写到 BR-015，并写硬“学习天数 = learning_day”
- 将 `streak` 的 Option C 收敛结果回写到 BR-007：保持 current frozen 不动，只记录 future stance，不在本轮切换 basis
- 新增与上述 Option C 规则相关的高风险边界用例、术语与 Room 1 / Room 4 / Room 5 回写建议

### v0.1.5 (2026-04-03)
- 吸收 `Review4.md` 中 Room 3 认可的 very small patch 意见：把 persistence guardrails 从“已冻结”调整为 **conditional frozen guardrails**
- 将输入依据拆成 `current active runtime basis` 与 `sync candidate inputs for this patch`，避免把 DB v0.1.4 / API v0.1.3 误读成已被 Room 1 pin
- 为 BR-017 / BR-018 / BR-019 增补 `Activation condition` 与“最小可观察结果”，方便 Room 4 后续写 regression case
- 明确本稿仍是 `ready for Room 1 review` 的 candidate sync patch，不等于 Option A 已进入 runtime active implementation

### v0.1.4 (2026-04-03)
- 作为 persistence sync patch，以 `BR-OPP-001_v0.1.3.md` 为 base，吸收 `R2_OptionA_Persistence_Hardening_Plan_v0.1.2.md` 中会跨 API / UI / TEST / rollout 的 guardrails
- 同步输入依据到当前运行态：`Main_updated_2026-04-03_v7.md` / `STATUS_updated_2026-04-03_v6.md` / `UI_SPEC_v0.1.2.md` / `背单词喵喵app_DB设计草案_v0.1.4.md` / `背单词喵喵app_API设计草案_v0.1.3.md`
- 新增 post-P2 持久化切流的三类规则候选：同源一致性、写操作降级语义、`displayed snapshot ≠ fresh backend truth ≠ success`
- 为迁移窗口补充对应的高风险边界用例、术语表与 Room 1 / Room 2 / Room 4 回写建议
- 保持技术选型、repository 分层、A1–A5 implementation slices、DDL / import 工具等实现细节仍归 Room 2 / Room 1 决策层，不写入 BR 冻结业务规则

### v0.1.3 (2026-04-02)
- 吸收 `R1_Decision_Pack_D-OPP-001-010_011.md`，将 `review_group` 最小业务契约正式回写到 BR
- 正式冻结“本组完成只推进今日复习进度，不自动等于今日复习完成”
- 正式冻结 `check_in / learning_day / streak` 为三类独立事实，并明确当前 MVP 下 `streak` basis = `check_in`
- 将旧的“签到事实与 learning day / streak 的最终强关联关系”从 Pending 移出，改写为当前冻结版口径
- 将旧的 `review_group` 合同从 Pending 改写为“最小合同已冻结、算法细节继续 Pending”
- 同步输入依据到 `Main_updated_2026-04-02_v4.md` / `STATUS_updated_2026-04-02_v3.md` / `BR-OPP-001_v0.1.2.md` / `R1_Decision_Pack_D-OPP-001-010_011.md`
- 增补与上述冻结口径对应的高风险边界用例、术语表与回写建议


### v0.1.2 (2026-04-02)
- 作为极小 sync patch，同步输入依据到当前 active versions：`Main_updated_2026-04-02_v3.md` / `STATUS_updated_2026-04-02_v2.md` / `背单词喵喵app_DB设计草案_v0.1.2.md` / `API设计草案_v0.1.1.md`
- 将 `D-OPP-001-007 / 008 / 009` 显式挂到 BR-010 / BR-011 / BR-012，对齐 Room 1 冻结决策来源
- 为 `effective attempts` 补充 canonical 定义，限定其仅作为 BR-011 的 Session 校验口径解释使用
- 为 `review_group` 增加最小可执行边界，避免 Room 4 在实现 / 测试中补脑扩写
- 为 `check_in / learning day / streak` 增加更可执行的高风险边界用例
- 将本文档状态调整为 `alignment sync patch / ready for Room 1 review`；当前运行态 active BR 仍为 `BR-OPP-001_v0.1.1.md`，待 Room 1 再决定是否 pin 本版

### v0.1.1 (2026-04-02)
- 按 Room 1 冻结决策，正式把 `daily_goal_status` 严格判定口径从 pending 改为 frozen
- 正式把 `session_validation_status` MVP 阈值从 pending 改为 frozen
- 正式把“主机制结算浮层 vs 副机制承接页边界”从 pending 改为 frozen
- 新增与上述 3 项冻结口径对应的边界用例
- 重写 Pending Decisions，只保留当前轮真正尚未冻结的事项
- 将本稿状态更新为 `draft / ready for Room 1 pin`

### v0.1 (2026-04-02)
- 首次建立 `BR-OPP-001`
- 从项目 active 文档中收口主机制优先阶段的核心业务规则
- 明确区分 Frozen / Pending / Unresolved
- 首次建立当前项目的业务术语与命名映射
- 首次把签到、学习日、结算、到账、防重等规则从局部文档说明提升为 BR 资产

---

## 11. 当前版本信息

- **This file:** `BR-OPP-001_v0.2.14.md`
- **Owner:** Room 3
- **Suggested next state after review:** active after Room 1 runtime-baseline update（当前运行态 active BR baseline 继续以后续被 Main / STATUS pin 的版本为准）
- **Runtime note:** 本稿以 `BR-OPP-001_v0.2.13.md` 为 base，并吸收 P3.3.12 已收口的 `fuller_cutover_absorb_candidate_v1`、`review_group_true_exit_gate_v1`、`db_api_uplift_absorb_judgment_v1`、`cutover_vs_fact_owner_boundary_v4`、`exit_candidate_to_true_exit_transition_v1` 与 `phase6_writeback_order_v1` 的最小合同；**current runtime active baseline remains the version pinned by Main / STATUS until Room 1 updates active versions**.
- **P3.3.12 note:** 本版继续在 P3.3 / P3.3.1 / P3.3.2 / P3.3.3 / P3.3.4 / P3.3.5 / P3.3.6 / P3.3.7 / P3.3.8 / P3.3.9 / P3.3.10 / P3.3.11 基础上，吸收 P3.3.12 已收口的规则：fuller-cutover 当前只允许把 widened execution-ready subset 提升到 absorb-candidate judgment；`review_group` 当前只进入 true-exit-gate judgment，继续保持 current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate；DB/API 当前只进入 uplift-absorb judgment seam families；absorb-judgment-level stronger candidate 当前仍不越过 backend final fact owner 边界；full cutover completed、`review_group` true exit 已生效、active DB/API baseline uplift absorbed、cleanup / old-path purge、homepage route switch、active continuation source switch、auto-routing runtime、final fact owner shift 与任何用户可见 cutover / exit / uplift absorbed 宣告继续保持 pending。
- **Maintenance rule:**
  1. 未来凡涉及 4 按钮业务语义、session entry / auto-routing、review readiness / priority / generation / schedule-source、review planner owner / planner merge、preview / schedule explanation 的结论变更，必须更新本文件
  2. BR 变更必须写 change log
  3. 未写入 BR 的跨层业务规则，不应视为 frozen
