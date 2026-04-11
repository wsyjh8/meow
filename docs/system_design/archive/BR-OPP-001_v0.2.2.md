# BR-OPP-001_v0.2.2
**Project:** 背单词喵喵 App  
**Owner:** Room 3  
**Type:** Business Rules / Governance SSOT Candidate / full merged baseline  
**Status:** incremental sync patch / ready for Room 1 review  
**Version:** v0.2.2  
**Last updated:** 2026-04-10  
**Base merge:** `BR-OPP-001_v0.2.1.md` + `P3.3 first-pass closeout inputs`  
**Merge policy:** 保留 `v0.2.1` 的 full BR 结构，并将 P3.3 第一拍已 close 的规则吸收为单文件可读的增量主文档候选

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
- `UI_SPEC_v0.2.1.md`

#### Governance / Runtime SSOT
- `ORG_v0.3.1.md`
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `Main_updated_2026-04-10_v19.md`
- `STATUS_updated_2026-04-10_v18.md`
- `BR-OPP-001_v0.2.1.md`（current runtime active BR baseline）

#### Current active DB / API baseline
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

### 2.2 Sync candidate inputs for this patch
- `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`
- `UI_SPEC_P3_3_HomeEntry_and_4Button_UI_Preflight_v0.1.1.md`
- `R3_P3_3_FSRS_4Button_ReviewPlanning_Rules_Note_v0.1.md`
- `R4_P3_3_Rating_Mapping_Matrix_v0.1.md`
- `R4_P3_3_Session_Entry_Draft_v0.1.md`
- `R4_P3_3_Submit_Flow_Draft_v0.1.md`
- `R4_P3_3_Test_Draft_v0.1.md`
- `R4_P3_3_Impact_Map_v0.1.md`
- `Main_updated_2026-04-10_v19.md`
- `STATUS_updated_2026-04-10_v18.md`

> Note:
> 1. 本稿以上述 current active runtime basis 为准，并以 `P3.3 First Pass Closed / Next-Focus Pending` 的推进层事实作为吸收边界。
> 2. 本稿目标不是重写整份 BR，而是在 `BR-OPP-001_v0.2.1.md` 的 full BR 结构上，增量吸收 P3.3 第一拍已经 close 的规则。
> 3. 本稿只吸收 **已能跨 BR / UI / DB / API / TEST 稳定引用** 的 P3.3 规则；final wording、完整 SRS / planner owner、session 自动分流、previewDurations 等继续保持 pending。
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
当前已足够跨文档一致、且可并入 full BR baseline 的 P3.3 第一拍规则有：
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

### 3.2 仍需保持 Pending
当前不能由 Room 3 擅自拍板、必须保留 `Pending Decision` 的规则有：
1. 熟练度 / 掌握阈值
2. 完整 SRS / review priority / review_group 分组算法细节（包括 group size、详细权重、完整 interval / schedule）
3. CTA winner 完整优先级算法与 `today_primary_action` 是否正式进入 active contract
4. statistics 是否从 `summary-first` 进一步展开为独立 minimal page 或更深统计产品
5. 未来是否把 `streak` 从 `check_in` 改为 `learning_day` 或组合条件、是否引入补签 / 宽限逻辑，以及 basis 切换后的兼容策略
6. P3.3 的最终两字中文词面
7. 首页点击“背单词”后的 session 启动合同（新词 / 复习 / 混合 / 自动分流）
8. 云端 `review_group` 与本地 FSRS 的最终 planner owner / 收敛方向
9. `StudyPage` 与 `ReviewPage` 是否长期共用一套统一学习页
10. `previewDurations` / interval preview 是否进入 active contract

### 3.3 当前已完成的本轮收口
本轮在 `BR-OPP-001_v0.1.7.md` 基线之上，按 Room 1 已接受的 `R3_P3_Rules_Freeze_Note_v0.1.1.md` 收敛结果，新增回写以下规则：
1. CTA winner 从 Option C 的最小仲裁层级，推进到 P3 的“更完整优先级算法阶段”的规则边界，但仍不把 decision-support contract 自动写成 active truth
2. `review_group` 从最小 continuation / readiness 规则，推进到 P3 的 structured deepening 边界：允许 grouping / readiness / progress / priority 进入更深一层规则冻结，但前端仍不得自行补脑
3. statistics 从 Option C 的 `summary-first` 最小规格，推进到 P3 的“独立 minimal page / deeper minimal product 判断”边界；默认 fallback 仍为 `summary-first`
4. `streak` 从 Option C 的 future stance 记录，推进到 P3 的正式决策准备边界；当前 runtime truth 继续保持 `check_in` basis，不切换 active contract
5. 继续保留 post-P2 persistence hardening 的跨层 guardrails 为 **conditional frozen guardrails**：同源一致性、只读 / 维护窗口降级语义、以及 `displayed snapshot ≠ fresh backend truth ≠ success`
6. 新增 P3.1 direct-scope delta 的单文件合并收口：upload / download / restore success 三层语义、restore manual-only + warning/confirm/no silent overwrite、`daily_goal` 当天即时生效但不回溯历史、非法输入显式报错、以及本轮继续 out of scope 的范围

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

### BR-029 P3.3 两字中文 requirement 与文案事实边界
- **Status:** Frozen + Pending copy
- **Rule:** P3.3 第一拍允许冻结“两字中文 requirement”，但不冻结最终四个词面。当前冻结的是：按钮必须为两个字、必须表达 rating input、不得写成结果事实；四个最终词面继续保持 candidate。
- **Applies to:** BR / UI / 文案 / TEST
- **Checkable:**
  1. 本轮 Study / Review 的 4 个按钮应以两个字的中文展示
  2. 不得使用“掌握 / 完成 / 到账 / 升级 / 解锁”等结果事实词作为已冻结主文案
  3. 若 final wording 尚未由 Room 1 / Room 3 / Room 5 正式 pin，则实现层不得把 candidate 词面写成长期 frozen business copy

### BR-030 P3.3 第一拍的复习规划边界与双层 owner split
- **Status:** Frozen with pending planner decisions
- **Rule:** P3.3 第一拍只冻结到“首页学习入口 + Study/Review 4 按钮 rating input + 最小 submit / throttle / bridge + 复习规划 preflight 边界”；当前 `review_group` 继续是 ReviewPage 的云端 truth layer，本地 FSRS 只允许作为本地调度 / side-effect bridge，不替代云端 `review_group` 的队列、continuation、结算或 readiness 真相。
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. ReviewPage 当前继续以后端 `review_group` 获取队列，不得改由本地 due cards 直接接管
  2. 本地 FSRS bridge 不得被写成“完整复习规划已完成”或“已替代云端 planner”
  3. 第一拍不得被下游吸收为“完整 SRS / 完整 review planner / 完整 session auto-routing 已冻结”


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

### E-037 candidate 两字中文被写成长期 frozen 词面
- **Expected:** 禁止；在 Room 1 / Room 3 / Room 5 未正式 pin final wording 前，candidate 词面只能视为当前显示候选，不得作为长期 frozen business copy 回写到 DB / API / BR 主契约。

### E-038 4 按钮提交成功后出现 false-success 文案
- **Expected:** 禁止；除非后端真实返回 groupCompleted、奖励到账等已成立事实，否则 UI 不得在提交后显示“已完成 / 奖励到账 / 已掌握”。

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

### 6.1A P3.1 direct-scope delta 术语补充
1. `upload success`：当前本地 snapshot 成功上传到云端 backup container
2. `download completed / snapshot fetched`：云端 snapshot 已成功取回到本机，但尚未自动 apply
3. `restore success / apply success`：只有在 pre-check + warning + confirm + apply 全部成功后，才允许作为本机恢复成功的业务事实
4. `daily_goal`：当前 direct-scope delta 中的显式用户设置动作；local-first 生效，snapshot 只承接最小设置层

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

### PD-009 P3.3 最终两字中文词面
- **Question:** 4 个按钮最终采用哪 4 个两字中文词面？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结“两字 requirement + fact-boundary”，不冻结 final wording；需 Room 3 + Room 5 对齐后，再由 Room 1 pin。

### PD-010 首页“背单词”点击后的 session 启动合同
- **Question:** 点击首页“背单词”后，是否默认进入新词 session、复习 session、混合 session，或基于 readiness 自动分流？
- **Current state:** Pending
- **Room 3 default:** 当前只冻结页面入口与路由，不冻结 session 启动合同；Room 4 不得自行补脑。

### PD-011 云端 `review_group` 与本地 FSRS 的最终 planner owner / 收敛方向
- **Question:** 长期看 Review planner 由谁作为主 owner？云端 `review_group`、本地 FSRS，还是双层协调？
- **Current state:** Pending
- **Room 3 default:** P3.3 第一拍中 `review_group` 仍是 ReviewPage 的云端 truth layer；本地 FSRS 只作为 local scheduling reality / side-effect bridge，不等于最终 planner owner 已被拍板。

### PD-012 `StudyPage` 与 `ReviewPage` 是否长期共用统一学习页
- **Question:** 后续是否收敛为一套统一学习页 / 统一交互承接层？
- **Current state:** Pending
- **Room 3 default:** 第一拍不拍板；当前仍保留 Study / Review 两页现实，不得把“未来可能统一”写成 active truth。

### PD-013 `previewDurations` / interval preview 是否进入 active contract
- **Question:** 4 按钮下方的即时间隔预览、schedule preview 是否进入下一轮 active contract？
- **Current state:** Pending
- **Room 3 default:** 当前 deferred；若未来进入，应单独冻结“解释性 preview”边界，避免把 preview 写成后端已确认事实。


## 9. 回写建议（给 Room 1 / Room 2 / Room 4 / Room 5）

### 9.1 给 Room 1
1. 将本文件作为 `BR-OPP-001_v0.2.2.md` 的增量升版候选，供下一轮治理层 SSOT 吸收 / pin
2. 在 Main / Status 中吸收以下新增已冻结结论：
   - 首页“背单词”主入口已进入 P3.3 第一拍 frozen 边界
   - Study / Review 4 按钮当前属于 `rating input`，不是结果事实
   - 4 按钮与 FSRS 四档的单调映射与顺序一致性进入 frozen 边界
   - 两字中文 requirement 已冻结，但 final wording 继续保持 candidate / pending
   - P3.3 第一拍只冻结到 home entry + 4-button submit/throttle/bridge + review planning preflight 边界
3. 继续保持 pending / second-focus item 不被偷升格：
   - 最终两字中文词面
   - 首页点击后的 session 启动合同
   - 云端 `review_group` 与本地 FSRS 的最终 planner owner
   - `StudyPage` / `ReviewPage` 是否长期统一
   - `previewDurations` 是否进入 active contract

### 9.2 给 Room 2
1. 在下一轮 technical preflight / closeout 中，继续把以下内容保持为技术待决项，不要静默写成 active truth：
   - session 启动合同
   - planner owner / 收敛方向
   - previewDurations / interval preview
2. 继续守住当前第一拍 frozen 边界：
   - 不扩 API schema
   - 不改 `review_group` 最小合同
   - 不把 local FSRS 写成云端 planner 替代者

### 9.3 给 Room 5
1. 在下一轮 UI sync 中继续守住：
   - 4 按钮文案不得写成结果事实
   - 两字中文 requirement 已冻结，但 final wording 仍 pending
   - 首页“背单词”为学习主线强入口，但不自动改写既有 CTA winner active rules
2. 若 Room 1 下一轮 focus 选择“词面冻结”，则以本文件 BR-027 / BR-028 / BR-029 为事实边界，提交 final wording sync patch

### 9.4 给 Room 4
1. 把新增的 BR-026 / BR-027 / BR-028 / BR-029 / BR-030 纳入最小回归集
2. 测试至少覆盖：
   - 首页“背单词”入口存在并直达 `StudyPage`
   - Study / Review 两页 4 按钮顺序一致
   - 任何按钮点击不误报“已掌握 / 已完成 / 奖励到账”
   - ReviewPage 仍以 `review_group` 作为云端 truth layer
   - 本地 FSRS bridge 不被实现层误写成完整 planner 已完成
   - 首页点击后不自行补脑 session 自动分流

## 10. 变更记录

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

- **This file:** `BR-OPP-001_v0.2.2.md`
- **Owner:** Room 3
- **Suggested next state after review:** active after Room 1 runtime-baseline update（当前运行态 active BR baseline 仍为 `BR-OPP-001_v0.2.1.md`，待 Main / STATUS 更新）
- **Runtime note:** 本稿以上一版 active BR `BR-OPP-001_v0.2.1.md` 为 base，并吸收 P3.3 第一拍已 close 的 rules note / UI preflight / execution evidence；**current runtime active baseline remains the version pinned by Main / STATUS until Room 1 updates active versions**.
- **P3.3 note:** 本版只吸收 P3.3 第一拍已 close 的规则：首页学习入口、4 按钮 rating input、FSRS 四档顺序映射、两字中文 requirement、以及复习规划 preflight 边界；final wording、session 启动合同、planner owner、previewDurations、完整 SRS / planner 继续保持 pending。
- **Maintenance rule:**
  1. 未来凡涉及 4 按钮业务语义、session 启动合同、review planner owner、candidate wording freeze、preview / schedule explanation 的结论变更，必须更新本文件
  2. BR 变更必须写 change log
  3. 未写入 BR 的跨层业务规则，不应视为 frozen
