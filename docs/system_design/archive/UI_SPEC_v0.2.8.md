# 背单词喵喵 App UI SPEC v0.2.8

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.2.8
- **Date:** 2026-04-10
- **Status:** incremental write-back patch / ready for Room 1 runtime-baseline update
- **Purpose:** 在 `UI_SPEC_v0.2.1.md` 已成为当前 runtime active UI baseline 的前提下，按 **P3.3 First Pass Closed** 的已收口结果，对首页“背单词”入口、Study / Review 4 按钮交互、页面承接关系与文案事实边界做 **增量回写**。  
  本稿不是重写整份 UI SPEC，也不是把 P3.3 / P3.3.1 / P3.3.2 / P3.3.3 / P3.3.4 / P3.3.5 / P3.3.6 preflight / candidate 全量升格；它只吸收 **已经被 Room 1 / Room 2 / Room 3 / Room 4 收口到足以影响后续开发、维护与新功能判断** 的 P3.3、P3.3.1、P3.3.2、P3.3.3、P3.3.4、P3.3.5 与 P3.3.6 页面现实。

---

## 0. 文档定位

本稿是 **`UI_SPEC_v0.2.1.md` 的增量回写版**，用于把 **P3.3 First Pass Closed** 中已经足够稳定、且已通过 cross-room 对齐的 UI 现实，并入主 UI 文档。  
它不是：
- P3.3 preflight 原文复制
- Room 2 / Room 4 的实现盘点文档
- 最终高保真视觉稿
- 把所有 pending candidate 一次性升格为 runtime truth 的版本

本稿只做两件事：

- **正式吸收进主 UI SPEC：**
  - 首页新增“背单词”主入口后的页面现实
  - Study / Review 已接入 4 按钮后的页面现实
  - 4 按钮的 UI 层三分法（显示层 / 语义层 / 适配层）
  - 与 P3.3 first-pass 相关的页面状态、提交反馈、防误报边界
  - 已经通过 Room 4 第一拍实现与测试验证的最小 UI 事实

- **正式吸收进主 UI SPEC（P3.3.1 增量）：**
  - Study / Review 4 按钮 final wording：`不认识 / 模糊 / 记得 / 秒答`
  - Study / Review 两页固定顺序与固定映射
  - `previewDurations` 当前继续 deferred，不进入可见 UI
  - ReviewPage FSRS bridge 当前只收口到 `controlled best-effort`
  - bridge fallback 虽不弹用户错误，但必须保留 dev/test 可观测性

- **正式吸收进主 UI SPEC（P3.3.2 增量）：**
  - `session_entry_policy_v1`：`home_word_entry = study_default`
  - active `review_group` continuation 高优先，但当前只通过独立 CTA / helper / priority block 承接
  - `planner_owner_split_v1`：ReviewPage = cloud `review_group` serving truth；local FSRS = device-side scheduling owner
  - ReviewPage 继续 `cloud-first + local side-effect`
  - local fallback 不弹用户错误，但必须保留 dev/test 可观测性
  - 当前页面事实层继续禁止 mixed / auto-routing / unified planner 既成事实表达

- **正式吸收进主 UI SPEC（P3.3.3 增量）：**
  - `review_readiness_policy_v1` 进入页面状态层，但 readiness truth 继续以 cloud review-serving layer 为准
  - `review_priority_policy_v1` 只冻结 hierarchy 的页面承接，不冻结完整排序算法
  - `review_group_generation_policy_v1` 只冻结 eligibility / owner / completion gating，不冻结 exact group size
  - `schedule_source_contract_v1` 进入 UI truth split：cloud `review_group` = serving truth，local FSRS = scheduling candidate
  - `previewDurations` 在 P3.3.3 继续 deferred，不进入当前可见 UI
  - 页面事实层继续禁止 auto-routing / unified planner / exact group generated / preview explanation 等 deeper-contract 假事实

- **正式吸收进主 UI SPEC（P3.3.4 增量）：**
  - `preview_durations_reentry_contract_v1` 当前只允许以 **StudyPage-only + hint-only + estimated-only** 的最小回归候选进入
  - preview source 当前只接受 **local FSRS preview candidate**，不得伪装成 cloud serving truth
  - ReviewPage / 首页 当前继续禁止显示 preview
  - preview 文案必须显式带 **“预计 / 仅供参考”** 语气，且不得写成稳定计划事实
  - `reviewpage_stronger_bridge_contract_v1` 当前只允许进入 **stronger-but-still-non-blocking** 的最小合同层
  - stronger bridge 允许进入：idempotent local ensure / minimal init / observability / non-blocking failure handling / minimal repair path
  - stronger bridge 仍不得产出任何新的用户可依赖计划事实

- **正式吸收进主 UI SPEC（P3.3.5 增量）：**
  - `planner_owner_shift_v2` 当前只进入 **future target-state candidate**，不进入 current runtime truth
  - `review_serving_contract_v2` 当前只进入 **compatibility / deprecation path**，ReviewPage 仍不得把 local due queue 写成当前 serving truth
  - `session_entry_and_routing_v2` 当前只进入 **future routing candidate**，首页 runtime 继续保持 `study_default` + no silent reroute
  - `preview_and_explanation_contract_v2` 当前只允许保留既有 StudyPage preview 最小回归；ReviewPage / 首页 继续禁止 preview
  - `backup_restore_and_cross_device_boundary_v2` 当前正式进入设置页 / 我的页 / 恢复流的文案与状态语义重写层
  - `migration_and_deprecation_plan_v1` 当前正式进入 **staged UI migration / compatibility markers / shadow-prep** 层
  - backup / restore / sync success 三层语义当前必须继续严格分开；backup existence ≠ cross-device consistency

- **正式吸收进主 UI SPEC（P3.3.6 增量）：**
  - `local_serving_candidate_contract_v1` 当前只进入 **shadow-compatible 页面元语义层**，不进入 current runtime truth
  - `review_group_compatibility_posture_v1` 当前进入 **current runtime owner + compatibility anchor + deprecated candidate** 三层姿态
  - `fact_settlement_ingest_contract_candidate_v1` 当前进入页面事实边界层：local evidence ≠ final fact / settlement truth
  - `session_entry_and_routing_compat_v1` 当前只进入 **shadow-aware routing compatibility**；首页 runtime 继续保持 `study_default`
  - `deprecation_markers_and_writeback_plan_v1` 当前进入 **deprecated candidate vs compatibility-only** 的 UI 资产分层
  - `shadow_parity_test_strategy_v1` 当前进入最小固定 UI 测试集；shadow / parity evidence 不得泄漏为用户事实
  - 页面事实层继续禁止 local-serving enabled / review_group runtime-exit / owner shift completed / user-visible shadow-mode 等 overclaim

- **继续保留为 pending / candidate，不直接升格：**
  - 完整 review planning / 完整 SRS / 完整复习调度产品
  - `previewDurations` 在 ReviewPage 的正式 re-entry
  - `previewDurations` 的 future active contract / 更完整 explanation system
  - mixed / auto-routing runtime contract
  - unified planner / planner merge
  - exact group size contract
  - readiness / priority 完整 reason system
  - 更强于当前 minimal stronger bridge 的 blocking user contract
  - ReviewPage local-serving runtime cutover
  - `review_group` runtime 退场
  - 用户可见 shadow-mode 宣告
  - 首页 CTA winner 的最终状态驱动收口

### 0.1 运行时说明
- 当前推进层 SSOT 中，**active UI baseline 仍是 `UI_SPEC_v0.2.6.md`**。
- `UI_SPEC_v0.2.7.md` 是 P3.3.5 write-back candidate。
- 本稿是 **在 `v0.2.7` 基础上继续吸收 P3.3.6 closeout 的 next-step UI baseline candidate / runtime-baseline update candidate**。
- 在 Room 1 将本稿正式吸收到 `Main / STATUS` 前，`v0.2.6` 仍是当前运行态依据。
- 但从 Room 5 视角，后续开发、维护与新功能设计，**应开始优先参考本稿中的 P3.3 + P3.3.1 + P3.3.2 + P3.3.3 + P3.3.4 + P3.3.5 + P3.3.6 增量回写部分**，再向上服从当前 active PRD / BR / DB / API / ORG / Role Cards。
## 1. 输入依据

### 1.1 当前治理层 / 运行层依据
- `ORG_v0.3.1.md`
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `room5_v0.2.1.md`
- `Main_updated_2026-04-10_v26.md`
- `STATUS_updated_2026-04-10_v24.md`

### 1.2 当前 active runtime basis
- `背单词养猫app项目介绍书_v0.1.1_P3.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `BR-OPP-001_v0.2.6.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.6.md`

### 1.3 本轮增量吸收输入（P3.3）
- `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`
- `UI_SPEC_P3_3_HomeEntry_and_4Button_UI_Preflight_v0.1.1.md`
- `R3_P3_3_FSRS_4Button_ReviewPlanning_Rules_Note_v0.1.md`
- `R4_P3_3_Rating_Mapping_Matrix_v0.1.md`
- `R4_P3_3_Session_Entry_Draft_v0.1.md`
- `R4_P3_3_Submit_Flow_Draft_v0.1.md`
- `R4_P3_3_Test_Draft_v0.1.md`
- `R4_P3_3_Impact_Map_v0.1.md`

### 1.4 本轮增量吸收输入（P3.3.1）
- `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md`
- `R2_P3_3_1_PreviewDurations_and_FSRS_Bridge_Tech_Note_v0.1.md`
- `R3_P3_3_1_Final_Wording_and_Bridge_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_1_Copy_Polish_and_PreviewDurations_Delta_v0.1.1.md`
- `R1_to_R4_P3_3_1_Execution_Handoff_v0.1.md`

### 1.5 本轮增量吸收输入（P3.3.2）
- `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1.md`
- `R3_P3_3_2_SessionEntry_PlannerOwner_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_2_SessionEntry_and_PlannerOwner_UI_Preflight_v0.1.md`
- `R1_to_R4_P3_3_2_Execution_Handoff_v0.1.md`

### 1.6 本轮增量吸收输入（P3.3.3）
- `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md`
- `R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_3_ReviewPlanningContractV1_UI_Preflight_v0.1.md`
- `R1_to_R4_P3_3_3_Execution_Handoff_v0.1.md`

### 1.7 本轮增量吸收输入（P3.3.4）
- `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_4_PreviewReentry_and_StrongerBridge_Tech_Note_v0.1.md`
- `R3_P3_3_4_PreviewReentry_and_StrongerBridge_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_4_PreviewReentry_and_StrongerBridge_UI_Preflight_v0.1.md`
- `R1_to_R4_P3_3_4_Execution_Handoff_v0.1.md`

### 1.8 本轮增量吸收输入（P3.3.5）
- `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1.md`
- `R3_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_UI_Preflight_v0.1.md`
- `R1_to_R4_P3_3_5_Execution_Handoff_v0.1.md`

### 1.9 本轮增量吸收输入（P3.3.6）
- `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md`
- `R3_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_UI_Preflight_v0.1.md`

### 1.4 吸收边界
1. 只吸收 **P3.3 / P3.3.1 / P3.3.2 / P3.3.3 / P3.3.4 / P3.3.5 / P3.3.6 已形成页面现实或已被 Room 1 正式冻结为最小合同** 的内容
2. 不把 preflight 中仍 pending 的 candidate 直接写成 frozen runtime truth
3. 不让 Room 2 / Room 4 的实现级说明反向替代 UI owner 结论
4. No silent UI drift
## 2. Room 5 吸收原则

### 2.1 可以正式吸收的内容
1. 已经进入代码现实、并通过 Room 4 第一拍实现与测试验证的页面结构变化
2. 已经影响后续开发与维护判断的入口、路由、按钮层级、页面承接关系
3. 已经足以影响文案事实边界的交互变化（例如 4 按钮是 rating input，不是结果事实）
4. 已经形成跨 Room 一致最小合同的 UI 层三分法（显示层 / 语义层 / 适配层）
5. 已经完成 Room 1 正式吸收的 final wording / preview defer / bridge controlled-best-effort 边界
6. 已经完成 Room 1 正式吸收的 target-state candidate / compatibility / semantic rewrite 边界
7. 已经能稳定复现、且会影响新功能判断的页面状态与防误报边界

### 2.2 不能直接升格成正式 UI 事实的内容
1. 尚未被 Room 1 pin 的产品结构变化
2. Room 2 / Room 4 负责的技术实现细节与性能折中
3. 完整 SRS / 完整 review planning / 完整 CTA winner 算法
4. `previewDurations` 的 future active contract / 解释增强
5. 高于 `controlled best-effort` 的 ReviewPage stronger bridge contract
6. runtime owner shift completed / local-serving cutover
7. auto-routing runtime / unified planner runtime

### 2.3 一句话原则
> **把 P3.3 First Pass、P3.3.1 closeout、P3.3.2 最小合同层、P3.3.3 的 review-planning very narrow UI contract、P3.3.4 的 preview re-entry / stronger bridge 最小 UI 合同、P3.3.5 的 target-state / compatibility / semantic rewrite 边界，以及 P3.3.6 的 shadow-compatible local-serving / review-group compatibility / fact-boundary contract 吸收进主 UI SPEC；把完整 review planning、`previewDurations` 的更深 explanation contract、mixed / auto-routing runtime contract、以及更深 planner / bridge contract 继续留在 Pending。**
## 3. 总体信息架构（吸收后口径）

### 3.1 当前推荐壳层结构
应用当前推荐以 `SpecShell` 作为主壳，采用 **6-Tab 底部导航** 作为新的主入口结构：

| Tab | 页面 | 定位 | 状态 |
|---|---|---|---|
| 首页 | `SpecHomePage` | 新默认首页 / 精简主入口 | 已实现 |
| 词书 | placeholder | 词书域保留位 | 占位 |
| Mochi | `SpecMochiPage` | 副机制聚合入口 | 已实现 |
| 统计 | `SpecStatsPage` | 统计独立入口 | 已实现（数据仍有 mock） |
| 我的 | `SpecProfilePage` | 设置 / 账号 / 数据入口 | 已实现 |
| 原版 | `TodayPage` | Legacy 合约驱动页 / 开发参考 | 保留 |

### 3.2 Room 5 对这套结构的正式表述
- **本稿接受 `SpecShell 6-Tab` 作为当前代码现实下的主 UI 结构。**
- 但 `TodayPage` 不视为废弃；它仍承载合约驱动、状态驱动更完整的主机制事实表达。
- `SpecHomePage` 代表更轻、更新、更面向后续演进的首页方向，但当前仍存在 `主 CTA 静态跳转` 等未决项。
- `SpecStatsPage` 与 `词书 Tab` 已进入正式信息架构，但各自状态不同：
  - `Stats`: 结构存在，数据未 fully trustworthy
  - `Books`: 位置存在，页面仍为 placeholder

### 3.3 命名路由（正式吸收）
| 路由 | 页面 | 作用 |
|---|---|---|
| `/` | `TodayPage` | Legacy 今日概览 |
| `/study` | `StudyPage` | 新词学习 |
| `/review` | `ReviewPage` | 复习 |
| `/session` | `SessionPage` | 专注 Session |
| `/check-in` | `CheckInPage` | 签到 |
| `/settlement` | `SettlementPage` | 结算（当前仍为占位） |
| `/meow-home` | `MeowHomePage` | 猫咪主页 |
| `/inventory` | `InventoryPage` | 收藏与商店 |
| `/customize` | `CustomizePage` | 装扮与小窝 |
| `/settings` | `SettingsPage` | 设置 |

---

## 4. 设计系统结论（吸收后口径）

### 4.1 当前并存现状
当前代码现实中，UI 已存在三套系统并行：

1. **SPEC 系统**  
   适用于：`SpecHomePage / SpecMochiPage / SpecStatsPage / SpecProfilePage / SpecTabBar`

2. **Legacy 系统**  
   适用于：`TodayPage / MeowHomePage / CustomizePage / InventoryPage / SettingsPage`

3. **原生 Material 极简系统**  
   适用于：`StudyPage / ReviewPage / SessionPage / CheckInPage / SettlementPage`

### 4.2 Room 5 正式判断
- **这三套系统并存的现实，现在被正式记录为 UI baseline 现状。**
- 后续新功能与维护开发，默认优先原则为：
  1. 不制造第四套系统
  2. 新页面优先向 **SPEC** 收敛
  3. 仍在 Legacy 轨道上的页，优先保持低风险一致性，不做强行重皮
  4. Material 极简页后续可逐步被更完整设计系统吸收，但不应因样式升级打断主学习低阻力

### 4.3 SPEC Token 结论
`SpecBg / SpecText / SpecBrand / SpecTypo / SpecRadius / SpecSpacing / SpecShadow` 体系已可视为当前新版 UI 的设计系统种子。  
后续 Room 5 / Room 4 在新功能页上可直接复用，不需要再重新定义一套命名系统。

---

## 5. 页面级正式吸收结果

## 5.1 SpecHomePage
**定位：** 新首页 / 精简主入口 / P3.3 学习主线入口承接页  
**正式吸收结论：**
- 作为当前代码现实中的默认首页方向，继续保留为首页主容器。
- P3.3 First Pass 已正式把 **独立“背单词”主入口** 接入到 `SpecHomePage`。
- 当前首页关键信息层级更新为：
  - 问候区
  - 猫咪承接卡片
  - **背单词主入口**
  - 既有 `继续学习 / 今日任务` hero card
  - 关键数字块
  - `5 分钟快速复习` 入口
- 当前页面承接现实：
  - 点击 **“背单词”** → `/study`
  - 既有 hero card 仍可 → `/study`
  - `5 分钟快速复习` 仍可 → `/review`
- P3.3.2 最小合同层进一步正式吸收：
  - `home_word_entry = study_default`
  - 当前首页“背单词”入口 **不是** review dispatcher
  - 当前首页“背单词”入口 **不是** mixed / auto-routing dispatcher
  - 若存在 active `review_group` continuation，高优先级承接应通过 **独立 CTA / helper / priority block** 出现，而不是吞掉默认 `/study` 入口
- 当前保留问题：
  - 首页最终 **CTA winner** 仍未完成状态驱动化收口
  - “背单词”主入口已是当前实现现实，但其是否长期保持最强主 CTA，仍需服从后续 Room 1 / Room 3 / Room 2 吸收
- 因此，后续开发维护时：
  - 可把 `SpecHomePage` 视为当前学习主线的首页承接基线
  - 但**不能把当前首页存在两个都可进入 `/study` 的入口，误写成已冻结的长期 CTA 业务规则**
  - 也**不能把 active `review_group` 的存在误写成“点击背单词就会自动改路由”**
## 5.2 SpecMochiPage
**定位：** 副机制聚合入口  
**正式吸收结论：**
- 正式吸收为独立一级入口
- 负责承接陪伴感、轻互动、弱收集欲，不反向主导主学习链路
- `学单词，赚小鱼干` CTA 可以存在，但始终属于“引回主线”而不是“副线主导主线”

## 5.3 SpecStatsPage
**定位：** 统计独立入口  
**正式吸收结论：**
- 结构正式吸收，视为当前 IA 中真实存在的一级入口
- 但页面数据可信度仍受限制：
  - 当前存在 mock / 硬编码部分
  - 不得把其中所有指标都当作 backend-confirmed truth
- 后续开发维护可在此页继续做真实数据替换与 minimal stats deepening
- 但 Room 5 口径仍是：**页面结构已吸收，数据事实仍需向 BR / DB / API / runtime 对齐**

## 5.4 SpecProfilePage
**定位：** 我的 / 设置 / 数据入口  
**正式吸收结论：**
- 正式吸收
- 视为当前设置、同步与备份、个人/词书入口的上层容器
- 与 `/settings` 的关系：`Profile` 是导航入口，`Settings` 是具体操作页

## 5.5 TodayPage（Legacy）
**定位：** 合约驱动更完整的今日页 / 保留参考页  
**正式吸收结论：**
- 不视为废弃
- 继续保留为“主机制状态表达最完整”的参考基线之一
- 后续如需迁移其合约驱动能力到 SpecHomePage，应明确做 sync patch，而不是默认认为两页已经等价

## 5.6 StudyPage
**定位：** 新词学习主页 / P3.3 FSRS 4 按钮接入页 / P3.3.4 preview 最小回归承接页  
**正式吸收结论：**
- P3.3 First Pass 后，`StudyPage` 已不再以 2 按钮作为当前页面现实；**4 按钮 rating input 已进入本页当前代码现实**。
- 当前页面应按以下三层理解：
  1. **Display Layer**：`不认识 / 模糊 / 记得 / 秒答`
  2. **Semantic Layer**：`again / hard / good / easy`
  3. **Adapter Layer**：FSRS `1 / 2 / 3 / 4`
- Room 5 当前正式吸收的是：
  - **StudyPage 采用 4 按钮交互框架**
  - 按钮顺序保持单调、稳定、与 ReviewPage 一致
  - 按钮本质是 **rating input**
  - 不得被页面文案写成“已掌握 / 已完成 / 已升级 / 已到账”
- 当前页面交互现实：
  - 4 按钮点击时进入 submitting 态
  - 提交中按钮应 disable，不允许重复记分
  - 不再展示旧的“已掌握 ✓”式 false-success snackbar
  - 失败时应停留在当前卡片并给出错误反馈，而不是静默跳到下一词
- P3.3.4 最小合同层进一步正式吸收：
  - `previewDurations` 当前若回归，**只允许以 StudyPage-only 的 secondary hint 形态出现**
  - preview source 当前只接受 **local FSRS preview candidate**
  - preview 只能是 **hint / estimated / reference-only**
  - preview 必须显式带 **“预计 / 仅供参考”** 语气
  - preview 当前不得参与 readiness / priority / generation / route / settlement / reward / group completion 判断
- 当前页面数据 / 交互边界：
  - 本地 FSRS 写入已进入当前现实
  - 同时仍保留 StudyService 的本地优先提交与后台同步路径
  - 页面层**不直接展示 FSRS grade int**
  - 页面层若显示 preview，也只能作为极轻 secondary hint，不得变成主反馈或主 CTA
- 因此，后续开发维护时：
  - 应把 `StudyPage` 视为 **4 按钮 rating input 已落地、且允许承接 preview 最小回归候选** 的页面
  - 但**不能把 preview 写成稳定计划事实，也不能让某一按钮点击自动变成结果事实或路由事实**
## 5.7 ReviewPage
**定位：** 复习页 / P3.3 review-group 承接页  
**正式吸收结论：**
- P3.3 First Pass 后，`ReviewPage` 已接入与 `StudyPage` 同构的 **4 按钮 rating input** 交互框架。
- 当前页面必须继续保留以下强边界：
  - `review_group` 仍是 **ReviewPage 的云端 truth layer**
  - 本地 FSRS 在本页只是 **bridge-first / side-effect**，不替代 `review_group`
  - 本页不得用本地 FSRS due 列表取代当前 review queue
- 当前页面已正式吸收的现实：
  - 4 按钮顺序与 `StudyPage` 一致
  - 评分提交仍先以云端 `submitReviewAttempt` 为主
  - 本地 FSRS bridge 当前已从 `controlled best-effort` 前进到 **stronger-but-still-non-blocking** 的最小 stronger bridge 合同
  - `group completion` 与既有 settlement 承接逻辑继续保留
- P3.3.2 / P3.3.4 最小合同层进一步正式吸收：
  - ReviewPage 的 serving truth owner 继续是 cloud `review_group`
  - local FSRS 继续只是 device-side scheduling owner
  - 页面继续只表现 `cloud-first + local side-effect`
  - stronger bridge 允许进入：idempotent local ensure / minimal init / observability / non-blocking failure handling / minimal repair path
  - local fallback 不弹用户错误，但必须保留 dev/test 可观测性
  - stronger bridge 当前不得改变 cloud truth owner，不得写成 planner merge / unified planner / planner owner shift
  - **ReviewPage 当前继续禁止显示 preview**
- 当前页面文案边界：
  - `本组完成 != 今日复习完成`
  - 任意一个 4 按钮点击都只是 rating input，不得直接写成“已掌握 / 今日已完成 / 奖励已到账”
  - 不得写“复习规划已更新 / 已自动调整 / 本地计划已同步 / 已切到最佳学习路径 / 下次将在 X 天后复习 / 系统已安排”
  - 只有实际 `groupCompleted` / settlement 条件满足时，才允许展示相应结果层反馈
- 因此，后续开发维护时：
  - 可把 `ReviewPage` 视为 **4 按钮已接入，review_group 仍是主真相源，local FSRS 只是 side-effect owner，bridge 已进入最小 stronger contract** 的页面
  - 但**不能把 stronger bridge 误写成用户可依赖的新计划事实，也不能把 planner owner split 写成 planner merge 已成立**
## 5.8 SessionPage
**定位：** 专注 Session  
**正式吸收结论：**
- 正式吸收三态结构：无 session / 进行中 / 已结束反馈
- `valid / invalid / pending` 的最终展示必须继续以后端 `session_validation_status` 为准

## 5.9 CheckInPage
**定位：** 签到页  
**正式吸收结论：**
- 正式吸收当前精简版
- 月历、节点奖励列表、节点奖励预告继续保持 Pending
- 当前已吸收的强边界：
  - `check_in != learning_day`
  - `learning_day != streak`

## 5.10 SettlementPage
**定位：** 结算页  
**正式吸收结论：**
- 正式吸收它目前是 **占位页**
- 不再假装已有完整结算体验
- 后续所有结算相关开发，应以“当前未实现”作为依据，而不是沿用旧稿中的完整五区结算假设

## 5.11 MeowHomePage
**定位：** 猫咪主页  
**正式吸收结论：**
- 正式吸收
- 当前已具备：
  - 资源栏
  - 成长区
  - 亮点区
  - companion 区
  - 跳转 Customize / Inventory
- 后续副机制维护和增强应以此页为真实基线，而不是回到最初仅摘要卡的抽象状态

## 5.12 CustomizePage
**定位：** 装扮与小窝  
**正式吸收结论：**
- 正式吸收
- 当前“预览区 + 资源栏 + 攒钱目标 + 已拥有未装备提示 + tab + 物品卡片 + 槽位”结构可作为后续装扮维护基线

## 5.13 InventoryPage
**定位：** 收藏与商店  
**正式吸收结论：**
- 正式吸收
- 当前已具备“余额卡片 + 收藏列表 + 商店列表 + 购买反馈”主结构
- 后续开发可在此页继续扩商店与收藏，但不应引入超出当前主副机制边界的复杂运营逻辑

## 5.14 SettingsPage
**定位：** 设置 / 本地数据 / 备份恢复  
**正式吸收结论：**
- 正式吸收
- 当前它已经是：
  - daily goal 设置页
  - desired retention 设置入口
  - backup 上传入口
  - restore gated 入口
- 后续与 P3.1 相关的开发维护，默认以本页为入口基线，而不是重新发明一条数据设置路径

## 5.15 词书 Tab
**定位：** IA 保留位  
**正式吸收结论：**
- 正式记录“位置存在，但页面未设计”
- 后续新功能若涉及词书域，可直接以此保留位继续展开
- 但在当前版本，不应把它误写成已完成页面

---

## 6. 关键状态与文案边界（正式保留）

以下边界继续作为正式 UI 口径保留，并适用于后续开发、维护、新功能：

1. **部分完成 != 已完成**
2. **本轮完成 / 本组完成 != 今日完成**
3. **签到成功 != learning_day**
4. **learning_day != streak 自动成立**
5. **Session started / ended != valid session completed**
6. **奖励展示 != 奖励到账**
7. **displayed snapshot != fresh backend truth**
8. **upload success != download success != restore success**
9. **副机制反馈不得反向宣告主机制事实**
10. **未 pin 的 candidate contract，前端不得自行补脑为已存在事实**
11. **4 按钮 = rating input，不是结果事实**
12. **两字中文按钮当前可显示，但仍属于 candidate wording，不自动等于 frozen business copy**
13. **Study / Review 的 4 按钮显示层、语义层、适配层必须分开理解，不得把显示词面直接当作系统内部真相键**
14. **ReviewPage 中本地 FSRS bridge != review_group 主真相源**
15. **download / submit / rating completed 本身 != 已恢复 / 已掌握 / 已到账 / 今日已完成**
## 7. 当前可直接作为下一步依据的内容

以下内容现在就可以作为后续开发、维护、新功能的直接 UI 依据：

### 7.1 IA / 导航层
- `SpecShell 6-Tab`
- `Profile -> Settings`
- `Legacy Today` 保留
- `MeowHome / Customize / Inventory` 作为真实副机制链路
- `SpecHomePage` 当前已存在独立 **“背单词”** 入口
- `SpecHomePage -> /study`、`快速复习 -> /review` 是当前已落地页面承接关系

### 7.2 设计系统层
- 新功能页优先向 SPEC 收敛
- 旧页短期保持 Legacy，不强行重皮
- 不再新增第四套视觉体系
- Study / Review 当前虽仍属 Material 极简轨道，但其 4 按钮交互已成为必须维持的一致体验点

### 7.3 页面事实层
- `SettlementPage` 当前仍是占位
- `Stats` 结构存在但数据未 fully trustworthy
- `Study / Review` 当前已进入 **4 按钮 first-pass reality**
- 两字中文按钮当前已冻结为：**不认识 / 模糊 / 记得 / 秒答**
- `StudyPage` 当前允许承接 `previewDurations` 的 **StudyPage-only / secondary hint / estimated-only** 最小回归候选
- `Settings` 已是数据设置与备份入口
- `ReviewPage` 当前仍以 `review_group` 为主真相源，本地 FSRS 为 stronger-but-still-non-blocking bridge
- `ReviewPage / 首页` 当前继续禁止显示 preview

### 7.4 新功能开发层
- 若新增首页学习入口相关能力，默认加在 `SpecHomePage`
- 若新增 FSRS / rating 相关 UI，默认以 `StudyPage / ReviewPage` 的 4 按钮框架为基线
- 若新增副机制承接，默认看 `SpecMochiPage` 与 `MeowHomePage`
- 若新增统计能力，默认加在 `SpecStatsPage`
- 若新增账号/设置/备份项，默认加在 `SpecProfilePage -> SettingsPage`
## 8. Pending / 风险（吸收后保留）

### Critical
1. Settlement 真正实现
2. SpecHomePage 主 CTA / CTA winner 状态驱动化
3. P3.3.4 后续更深 focus 尚未由 Room 1 / User 正式拍板

### Major
4. `previewDurations` 当前只完成 StudyPage first-shot 候选；ReviewPage re-entry 仍 pending
5. `previewDurations` 的 future active contract / 更完整 explanation system 仍 pending
6. ReviewPage stronger bridge 当前只到最小 stronger contract；更深 bridge / planner 合同仍 pending
7. `review_group` 与本地 FSRS 的长期权威边界 / planner merge 仍 pending
8. exact group size / 完整 priority scoring / 完整 review planning product 仍 pending
9. Stats 真实数据接入与可信度对齐
10. SPEC 设计系统进一步统一

### Minor
11. Mochi 页主 CTA 是否过强
12. Stats Tab 与 feature guard 可见性一致性
13. 词书页完整设计
14. `StudyPage / ReviewPage` 是否长期收敛为统一学习承接页
## 9. Appendix A — 代码现状附录（降级信息）

以下内容保留为附录参考，不作为 Room 5 主结论：
- 具体代码文件路径
- 具体 route 注册方式
- drift / SQLite / SharedPreferences / service 编排细节
- 仅用于解释“为什么页面现在是这样”，不用于替代 PRD / BR / DB / API / UI 的正式层级

---

## 10. 下一步建议（Room 5）

1. 由 Room 1 将本稿作为 **`UI_SPEC_v0.2.6.md` runtime-baseline update candidate** 吸收到 `Main / STATUS`
2. Room 4 后续开发、维护、新功能默认优先参考本稿中的 **P3.3 + P3.3.1 + P3.3.2 + P3.3.3 + P3.3.4 增量回写部分**
3. 若 Room 1 确认继续深化 preview，应优先判断：
   - ReviewPage preview 是否仍保持禁止
   - `previewDurations` 是否继续只停留在 StudyPage hint
   - 是否允许进入更完整 explanation system
4. 若 Room 1 确认继续深化 stronger bridge，应优先判断：
   - 是否仍保持 non-blocking
   - 是否会触碰 planner merge / API / DB core semantics
   - 是否会产生新的用户可依赖计划事实

---

## 11. P3.3.1 增量回写（本轮新增）

### 11.1 本轮正式吸收的结论
P3.3.1 在 `v0.2.2` 的基础上，继续把以下 UI 事实并回主文档：

1. **Study / Review 4 按钮 final wording 已冻结为：**
   - 不认识
   - 模糊
   - 记得
   - 秒答

2. **固定映射保持为：**
   - `Again` → 不认识
   - `Hard` → 模糊
   - `Good` → 记得
   - `Easy` → 秒答

3. **固定顺序保持为：**
   - 左上：不认识
   - 右上：模糊
   - 左下：记得
   - 右下：秒答

4. **`previewDurations` 当前继续 deferred**
   - 不进入 active UI
   - 不在按钮下方展示稳定预估文案
   - 不写成系统已确认的下次安排

5. **ReviewPage FSRS bridge 当前只收口到 `controlled best-effort`**
   - cloud-first 继续为硬边界
   - bridge 只允许作为 side-effect / defensive cleanup
   - 不升格为 must-succeed / stronger contract
   - 不改 `review_group` 主队列 / 主真相层地位

6. **bridge fallback 虽不弹用户错误，但必须保留 dev/test 可观测性**
   - 例如 debug log
   - diagnostic counter
   - 可断言的 fallback branch
   - 不得做成完全无痕、不可测试的静默吞掉

### 11.2 StudyPage（P3.3.1 后口径）
#### 按钮区
- 4 按钮文案正式更新为：不认识 / 模糊 / 记得 / 秒答
- 继续采用 2×2 网格
- 顺序必须与 ReviewPage 完全一致

#### 反馈边界
- 点击后继续以“提交中 disable + 进入下一词”为主
- 不新增“已掌握 / 已学会 / 奖励到账 / 今日完成”之类结果型文案
- 正常成功不依赖 toast 强提示

### 11.3 ReviewPage（P3.3.1 后口径）
#### 按钮区
- 4 按钮文案正式更新为：不认识 / 模糊 / 记得 / 秒答
- 顺序固定，与 StudyPage 一致

#### 云端主链路
- `review_group` 继续是主队列 / 主真相层
- cloud submit 成功后，页面正常继续下一题 / 下一组
- `groupCompleted=true` 时，可展示“本组复习完成”
- 但不得把本组完成扩写成“今日完成 / 已掌握 / 奖励到账”

#### bridge 边界
- bridge 失败不弹用户错误
- bridge 成功 / 失败都不应产生：
  - 已更新你的复习计划
  - 已同步复习安排
  - 下次将在 X 天后复习
  - 学习模型已更新

### 11.4 Fact Copy 禁区（P3.3.1 补强）
以下词在 P3.3.1 后继续列为按钮区与点击后主反馈的禁区：

- 掌握
- 已会
- 会了
- 完成
- 熟练
- 记住了
- 奖励到账
- 已更新计划
- 已同步复习安排
- 下次将在 X 天后复习
- 学习模型已更新

### 11.5 保留为 Pending 的内容
以下内容在 P3.3.1 后仍不直接升格：

1. `previewDurations` 的 future active contract
2. 更强的 ReviewPage bridge contract
3. planner owner 的最终收口
4. 完整 review planning / 完整 SRS / 完整复习调度产品
5. 首页 CTA winner 的完整状态驱动收口

### 11.6 Room 5 一句话结论
> **P3.3.1 回写后，主 UI 文档对 Study / Review 的正式口径应更新为：按钮词面已冻结、`previewDurations` 当前不显示、ReviewPage bridge 只保持 `controlled best-effort` 且必须可观测；本轮重点是消除假事实与补强低阻力体验，而不是扩主契约。**

---

## 12. P3.3.2 增量回写（本轮新增）

### 12.1 本轮正式吸收的结论
P3.3.2 在 `v0.2.3` 的基础上，继续把以下 UI 事实并回主文档：

1. **`session_entry_policy_v1` 已进入最小合同层**
   - `home_word_entry = study_default`
   - 首页“背单词”默认仍进入 `StudyPage`
   - 当前它不是 review dispatcher
   - 当前它不是 mixed / auto-routing dispatcher

2. **active `review_group` continuation 继续高优先级**
   - 但当前只能通过独立 CTA / helper / priority block 承接
   - 不等于 silent reroute
   - 不等于吞掉默认 `/study` 入口

3. **`planner_owner_split_v1` 已进入最小合同层**
   - ReviewPage = cloud `review_group` serving truth owner
   - local FSRS = device-side scheduling owner
   - ReviewPage 继续 `cloud-first + local side-effect`

4. **本轮继续禁止 mixed / auto-routing / unified planner 既成事实表达**
   - 不把首页入口写成“系统已自动分流”
   - 不把页面写成“统一学习页 / 统一规划已成立”
   - 不把 local FSRS 写成“主复习计划已接管”

### 12.2 SpecHomePage（P3.3.2 后口径）
#### 主入口
- 首页“背单词”继续是当前默认学习入口
- 点击后默认进入 `StudyPage`
- 当前不得把这个入口解释成 review dispatcher 或 mixed planner dispatcher

#### active review continuation 承接
若存在 active `review_group` continuation，可增加：
- 独立次强 CTA：继续复习
- helper：你有一组复习未完成
- priority block / summary block

但必须满足：
- 不吞掉默认“背单词”入口
- 不把 continuation 写成“系统已自动替你改路由”
- 不把首页包装成“今天学习模式已由系统安排完成”

### 12.3 StudyPage（P3.3.2 后口径）
- 继续作为默认学习承接页
- 不承担 review planner dispatcher 职责
- 不新增“系统根据规划把你送到这里”之类解释文案
- 继续保持 P3.3 / P3.3.1 已冻结的 4 按钮、final wording 与低阻力提交节奏

### 12.4 ReviewPage（P3.3.2 后口径）
#### 主真相层
- ReviewPage 的主进度、remaining、group completion、settlement 承接，继续围绕 cloud `review_group`
- 不得把本地 due cards / 本地 scheduler 结果写成主队列事实

#### local FSRS 层
- local FSRS 继续存在，但只作为 device-side scheduling / side-effect owner
- 不得把 local FSRS 写成：
  - 主队列 owner
  - group continuation owner
  - group completion owner
  - settlement owner
  - 统一 planner owner

#### fallback 与表现层
- local fallback 不弹用户错误
- 但必须保留 dev/test 可观测性
- 页面不得新增：
  - 复习规划已更新
  - 已自动调整复习路径
  - 本地计划已同步
  - 已切换到最佳学习路径
  - 统一学习模式已启用

### 12.5 Fact Copy 禁区（P3.3.2 补强）
以下表达在 P3.3.2 后继续列为页面事实层禁区：

- 系统已自动为你分流
- 已为你安排今天复习模式
- 已切换到最佳学习路径
- 已整合你的学习计划
- 复习规划已更新
- 本地计划已同步
- 统一学习模式已启用
- 自动分流
- 混合学习已开启
- 统一规划已完成
- 复习路径已重排
- 本地规划已接管
- 已根据 FSRS 自动切换入口

### 12.6 保留为 Pending 的内容
以下内容在 P3.3.2 后仍不直接升格：

1. mixed / auto-routing runtime contract
2. unified planner / planner merge
3. unified Study / Review page
4. 完整 review planning / 完整 SRS / 完整复习调度产品
5. `previewDurations` 重开
6. planner explanation / next interval UI
7. 首页 CTA winner 的完整状态驱动收口

### 12.7 Room 5 一句话结论
> **P3.3.2 回写后，主 UI 文档对首页入口与 ReviewPage owner split 的正式口径应更新为：`home_word_entry = study_default`，active `review_group` continuation 通过独立承接而不吞掉默认入口，ReviewPage 继续只表现 `cloud-first + local side-effect`；本轮重点是把入口语义与 owner split 写硬，而不是扩成完整复习规划产品。**

---

## 13. P3.3.3 增量回写（本轮新增）

### 13.1 本轮正式吸收的结论
P3.3.3 在 `v0.2.4` 的基础上，继续把以下 UI 事实并回主文档：

1. **`review_readiness_policy_v1` 已进入页面状态层**
   - 页面级 readiness truth 继续以后端 review-serving layer 为准
   - local FSRS 不直接上位为页面 readiness truth

2. **页面可承接的最小 readiness 状态冻结为：**
   - `ready_now`
   - `not_ready_now`
   - `next_group_eligible`
   - `temporarily_unservable`

3. **`review_priority_policy_v1` 当前只冻结 hierarchy 的页面承接**
   - active `review_group` continuation
   - due review（仅 cloud-confirmed / serving-confirmed）
   - high-priority review（仅 cloud-confirmed）
   - new words
   - session

4. **`review_group_generation_policy_v1` 当前只冻结 entry boundary**
   - generation owner = cloud review-serving layer
   - 同一用户同一时刻最多一个 active `review_group`
   - active group 未完成前，不进入 next-group path
   - `next_group_eligible` ≠ `next_group_generated`
   - generation 当前允许 on-demand / lazy generation，不强制 pre-generation

5. **`schedule_source_contract_v1` 的 UI truth split 已进入主文档**
   - cloud `review_group` = serving truth
   - local FSRS = scheduling candidate / device-side scheduling owner
   - 两边当前只允许存在 minimal planning-facing conceptual interface
   - 这不等于 unified planner / planner merge 已成立

6. **`previewDurations` 在 P3.3.3 继续 deferred**
   - 当前不进入首页 / StudyPage / ReviewPage
   - 不作为页面事实文案来源
   - 不作为本轮通过标准
   - 不得写成系统已确认的下次安排

### 13.2 SpecHomePage（P3.3.3 后口径）
#### 默认主线
- 首页“背单词”继续保持 `study_default`
- 默认仍进入 `StudyPage`

#### review-ready 最小承接
首页当前可承接以下最小状态层：
- `ready_now`：
  - 次强 CTA：继续复习
  - helper：现在可继续复习
  - summary block：你有一组复习可继续
- `not_ready_now`：
  - 不展示 review-ready 强提示
  - 保持“背单词”作为默认主入口
- `next_group_eligible`：
  - 最多作为轻量 helper / future-ready 候选说明
  - 当前不单独升为主 CTA
- `temporarily_unservable`：
  - 不显示“现在就去复习”的强引导
  - 可用中性 helper 表达“当前暂不可立即进入复习”

#### 优先级页面表达
- active `review_group` continuation 最高优先
- due / high-priority review 只有在 cloud-confirmed 时才允许进入页面承接
- `new words` 继续是默认 fallback 主线
- `session` 当前继续保守，不进入本轮首页 winner

#### 当前不允许
- 不把首页写成 auto-routing dispatcher
- 不把首页写成 unified planner 入口
- 不写“系统已自动为你决定今天先学什么”
- 不把 `next_group_eligible` 写成“下一组已就绪 / 已生成”

### 13.3 StudyPage（P3.3.3 后口径）
- 继续作为默认学习入口页
- 不承担 planner dispatcher 解释职责
- 不新增“系统根据规划把你送到这里”的说明
- 不新增 readiness 解释层
- 继续保持 P3.3 / P3.3.1 已冻结的 4 按钮、final wording 与低阻力提交节奏

### 13.4 ReviewPage（P3.3.3 后口径）
#### 主真相层
- ReviewPage 继续围绕 cloud `review_group` 展示：
  - queue / continuation
  - remaining
  - group completion
  - settlement 承接
- 不得把本地 due cards / 本地 scheduler 结果写成主队列事实

#### 最小 readiness / generation 承接
- 有 active group 时，可展示 group progress / remaining / completion
- `temporarily_unservable` 只能写成阶段性不可服务，不得写成永久否定
- `next_group_eligible` 只能写成资格态，不得写成生成完成态
- 不得写：
  - 下一组已生成
  - 已下发到设备
  - 现在一定能拿到下一组内容

#### truth split
- local FSRS 继续存在，但只作为 scheduling candidate / local scheduling side 的能力来源
- 不得把 local FSRS 写成：
  - 主复习路径 truth owner
  - planner merge owner
  - unified planner owner
  - serving queue owner

### 13.5 Fact Copy 禁区（P3.3.3 补强）
以下表达在 P3.3.3 后继续列为页面事实层禁区：

- 系统已自动为你决定今天先学什么
- 已切换到最佳复习模式
- 已根据 FSRS 自动重排你的学习路径
- 已为你生成完整复习计划
- 云端与本地已统一为同一 planner
- 下次将在 X 天后复习
- 预计 X 天后再次出现
- 本地计划已接管复习路径
- 自动分流已开启
- 统一学习模式已启用
- 下一组已生成（若当前只有 `next_group_eligible`）
- 今天没有复习资格
- 系统已判定你不需要复习

### 13.6 保留为 Pending 的内容
以下内容在 P3.3.3 后仍不直接升格：

1. 完整 SRS
2. 完整 priority scoring
3. auto-routing runtime UI
4. unified planner / planner merge
5. unified Study / Review page
6. stronger ReviewPage bridge contract
7. `previewDurations` re-entry / explanation UI
8. exact group size 的页面表达
9. readiness / priority 完整 reason system

### 13.7 Room 5 一句话结论
> **P3.3.3 回写后，主 UI 文档对 review planning 的正式口径应更新为：页面可以承接 very narrow 的 readiness / priority / eligibility / truth split；页面级 readiness truth 继续以后端 review-serving layer 为准；首页只承接最小状态层与独立 review continuation 承接；`previewDurations` 继续 deferred；所有 deeper-contract 仍不得写成当前 UI 既成事实。**

---

## 14. P3.3.4 增量回写（本轮新增）

### 14.1 本轮正式吸收的结论
P3.3.4 在 `v0.2.5` 的基础上，继续把以下 UI 事实并回主文档：

1. **`preview_durations_reentry_contract_v1` 已进入最小回归候选层**
   - source = local FSRS preview candidate
   - 当前不是 cloud serving truth
   - 当前不是稳定计划事实
   - 当前不得进入 active API / DB contract

2. **preview 当前只允许 StudyPage-only**
   - ReviewPage 当前继续禁止显示 preview
   - 首页当前继续禁止显示 preview
   - preview 当前不得参与 routing / readiness / priority / generation / settlement / reward / group completion

3. **preview 当前只允许 hint / estimated / reference-only 形态**
   - 只能作为 4 按钮区下方的极轻 secondary hint
   - 必须显式带 “预计 / 仅供参考” 语气
   - 不得写成 “下次将在 X 天后复习 / 系统已安排 / 已更新计划 / 已同步复习安排”

4. **`reviewpage_stronger_bridge_contract_v1` 已进入最小 stronger contract 层**
   - ReviewPage 继续 `cloud-first`
   - 允许进入 stronger ensure / init floor
   - 允许进入 observability floor
   - 允许进入 non-blocking failure handling floor
   - 允许进入 minimal repair path
   - stronger bridge 当前仍不得产生新的用户可依赖计划事实

5. **P3.3.4 继续明确不进入的内容**
   - ReviewPage preview re-entry
   - 首页 preview
   - preview explanation system
   - mixed / auto-routing runtime
   - unified planner / planner merge
   - DB schema 重构
   - API core semantics 重构

### 14.2 StudyPage（P3.3.4 后口径）
#### 4 按钮区
- 继续保持：
  - 不认识 / 模糊 / 记得 / 秒答
  - 2×2 网格
  - rating input 本质不变

#### preview 最小回归候选
- 若 contract 满足，可在 **4 按钮区下方一行极轻 secondary hint** 显示 preview
- preview 当前只允许以 estimated / reference-only 方式出现
- 推荐文案范式：
  - `预计间隔：1 天（仅供参考）`
  - `预计间隔：3 天（仅供参考）`
  - `预计间隔：7 天（仅供参考）`

#### 当前明确禁止
- 不得把 preview 写成：
  - 下次将在 X 天后复习
  - 系统已安排
  - 已更新计划
  - 已同步复习安排
  - 云端与本地已统一
- 不得把 preview 变成主反馈 / 主 CTA / route switch 理由

### 14.3 ReviewPage（P3.3.4 后口径）
#### preview 边界
- ReviewPage 当前继续禁止显示 preview
- 原因不是“以后永远不能显示”，而是当前仍需守住：
  - cloud `review_group` = serving truth
  - local FSRS = scheduling candidate / side-effect owner
  - stronger bridge ≠ planner merge

#### stronger bridge 最小合同
- stronger bridge 当前允许进入：
  - ReviewPage 进入或提交前的 idempotent local ensure
  - local card state 缺失时的 minimal init / ensure-local-card-state
  - bridge miss / ensure fail / local apply fail 的 dev/test 可观察事件
  - non-blocking failure handling
  - internal observable fallback + future idempotent re-ensure / local repair 消化
- stronger bridge 当前继续不得：
  - 回滚 cloud submit success
  - 阻断 next item / group completion / settlement 主链路
  - 把 local FSRS 写成 ReviewPage truth owner
  - 写成 planner owner shift / planner merge / unified planner
  - 产生任何用户可依赖计划事实

#### 文案与事实边界
- stronger bridge failure 仍不弹用户错误
- 不新增结果型用户文案
- 不把内部 repair / fallback 写成成功计划事实

### 14.4 Fact Copy 禁区（P3.3.4 补强）
以下表达在 P3.3.4 后继续列为页面事实层禁区：

- 下次将在 X 天后复习
- 系统已安排
- 已更新计划
- 已同步复习安排
- 已根据 FSRS 自动调整路径
- 本地计划已接管
- 统一规划已完成
- 已切换到最佳复习模式
- 已为你确认最佳复习路径
- 云端与本地已统一
- ReviewPage 显示 preview（当前合同层）
- 首页显示 preview（当前合同层）

### 14.5 最小测试与回写要求（Room 5 口径）
若 P3.3.4 进入执行并真实 landing，UI 文档当前至少要求：

1. StudyPage 在 contract 满足时，preview 可显示
2. StudyPage 在 contract 不满足时，preview 不显示
3. ReviewPage 始终不显示 preview
4. 首页不显示 preview
5. preview 必须包含“预计 / 仅供参考”语气
6. preview 不得出现“下次将在 X 天后复习 / 系统已安排 / 已更新计划 / 已同步复习安排”
7. stronger bridge failure 仍不弹用户错误
8. stronger bridge 不得改变 cloud-first 主链路
9. stronger bridge 不得引入新的结果型用户文案
10. stronger bridge 的 dev/test 可观测性必须保留

### 14.6 Room 5 一句话结论
> **P3.3.4 回写后，主 UI 文档对 preview 与 stronger bridge 的正式口径应更新为：preview 当前只允许以 StudyPage-only、hint-only、estimated-only 的最小候选回归；ReviewPage 当前继续禁止 preview；stronger bridge 当前只允许进入更稳的后台合同层与更硬的文案禁区，不进入新的用户计划事实层。**

---

## 15. P3.3.5 增量回写（本轮新增）

### 15.1 本轮正式吸收的结论
P3.3.5 在 `v0.2.6` 的基础上，继续把以下 UI 事实并回主文档：

1. **`planner_owner_shift_v2` 当前只进入 future target-state candidate**
   - local FSRS / local scheduler 可被接受为 future primary planning owner 方向
   - 当前不自动改写 runtime owner
   - 当前不得写成“本地已接管复习主链路 / ReviewPage 已由本地 planner 驱动”

2. **`review_serving_contract_v2` 当前只进入 compatibility / deprecation path**
   - ReviewPage current serving truth 继续围绕 cloud `review_group`
   - `review_group` 当前只进入 compatibility / transition / staged deprecation candidate
   - 当前不得把 local due queue / local generated review session 写成 current serving truth

3. **`session_entry_and_routing_v2` 当前只进入 future routing candidate**
   - 首页 runtime 继续保持 `home_word_entry = study_default`
   - active review continuation 继续高优先，但不得 silent reroute
   - auto-routing / mixed routing 当前继续保持 pending

4. **`preview_and_explanation_contract_v2` 当前不改 current visible boundary**
   - StudyPage 继续保留既有 preview 最小回归：StudyPage-only / hint-only / estimated-only
   - ReviewPage / 首页 当前继续禁止 preview
   - preview / explanation 当前仍不得写成 committed plan fact

5. **`backup_restore_and_cross_device_boundary_v2` 当前正式进入设置页 / 我的页的语义重写层**
   - `backup success`
   - `restore success`
   - `sync success`
   三层语义必须继续严格分开
   - restore 继续 manual only
   - restore apply 之后，目标设备本地状态才成为新的 runtime truth
   - backup existence ≠ cross-device consistency

6. **`migration_and_deprecation_plan_v1` 当前正式进入 staged UI migration / compatibility markers / shadow-prep 层**
   - 当前只能进入 compatibility / deprecation markers
   - 当前只能进入 shadow / parity preparation
   - 当前不得跳过 compatibility / shadow thinking 直接切主链路

### 15.2 SpecHomePage（P3.3.5 后口径）
#### 当前 runtime reality
- 首页“背单词”默认仍是 `study_default`
- active review continuation 继续只能通过独立 CTA / helper / priority block 承接
- 当前不得 silent reroute / auto-routing
- 当前不得把 local planner 写成首页当前路由 truth owner

#### future target-state candidate
若后续 owner shift 被继续 pin，首页未来可能进入：
- planner-aware entry candidate
- due-first / mixed-session candidate
- continuation helper / summary block 重写

但当前这些都仍只是 future candidate，不得写成 current runtime truth。

### 15.3 StudyPage（P3.3.5 后口径）
#### 当前 runtime reality
- 继续作为默认学习入口页
- 继续维持 P3.3 / P3.3.1 / P3.3.4 已冻结的 4 按钮、preview 最小回归与低阻力提交节奏
- 不承担 planner dispatcher 解释职责

#### future candidate
若 future local planner owner 成立，StudyPage 未来可能承接更强的 local planning explanation / preview 升级；
但当前不得写：
- 系统根据本地规划把你送到这里
- 当前规划已确定先学新词
- 当前页面已是 unified learning page

### 15.4 ReviewPage（P3.3.5 后口径）
#### 当前 runtime reality
- 继续围绕 cloud `review_group` 展示：
  - queue / continuation
  - remaining
  - group completion
  - settlement 承接
- local FSRS 当前仍只作为 scheduling candidate / side-effect owner
- stronger bridge 只提升幕后合同，不产出新的用户计划事实

#### compatibility / deprecation path
- `review_group` 当前不得被写成“已退出 runtime”
- current serving truth 当前不得被偷切到 local due queue / local generated review session
- future local-serving 方向只允许被记录为 target-state candidate

#### 当前继续禁止
- ReviewPage 显示 preview
- ReviewPage 文案写成“本地 planner 已接管”
- 把 current queue 写成来自 local due
- 把 planner owner split 写成 planner merge / unified planner 已成立

### 15.5 SpecProfilePage / SettingsPage（P3.3.5 后口径）
#### 当前正式吸收的语义重写方向
- `Profile / Settings / data flows` 当前应开始以 **backup / restore / cross-device 三层成功语义重写** 为后续维护口径
- 允许出现：
  - 立即备份
  - 最近一次备份时间
  - 最近一次备份状态
  - 从备份恢复
  - 恢复将覆盖本机当前本地进度

#### 当前禁止
- 已同步
- 云端与本地已统一
- 跨设备已一致
- 无冲突
- 恢复后所有设备自动一致

#### 当前解释边界
- backup success = 当前设备本地 runtime truth 已成功导出并上传为云端 snapshot artifact
- restore success = 目标设备已成功应用某份 snapshot，并以此重写本地 planner / local runtime state
- sync success = 当前仍不建议作为真实用户状态出现

### 15.6 Fact Copy 禁区（P3.3.5 补强）
以下表达在 P3.3.5 后继续列为页面事实层禁区：

#### Owner shift / planner truth 禁区
- 本地 planner 已接管复习主链路
- ReviewPage 已由本地 planner 驱动
- 当前复习主真相源已切换到本地
- `review_group` 已退出运行态
- 云端不再参与复习主链路
- 系统已自动为你决定今天先学什么
- 已切换到最佳学习路径
- auto-routing 已开启
- mixed learning 已启用
- unified planner 已成立

#### Preview / explanation 禁区
- 下次将在 X 天后复习
- 系统已为你安排
- 已更新你的复习计划
- 已同步复习安排
- 计划已统一
- 已根据 FSRS 自动重排你的学习路径

#### Backup / restore / cross-device 禁区
- 已同步
- 云端与本地已统一
- 跨设备已一致
- 无冲突
- 恢复后所有设备自动更新
- 现在所有设备的学习计划都一样

### 15.7 保留为 Pending 的内容
以下内容在 P3.3.5 后仍不直接升格：

1. current runtime owner shift
2. ReviewPage local-serving runtime cutover
3. auto-routing runtime / mixed-session runtime
4. unified planner / planner merge
5. ReviewPage preview re-entry
6. 首页 preview / planning summary runtime
7. preview explanation system 主层
8. full sync / real-time sync / auto merge
9. unified Study / Review page
10. 完整 review planning / 完整 SRS / 完整复习调度产品重写

### 15.8 Room 5 一句话结论
> **P3.3.5 回写后，主 UI 文档对 owner shift / cloud backup rebase 的正式口径应更新为：当前 runtime 继续保持 `study_default`、cloud review-serving truth、Study-only preview；本轮只正式吸收 future target-state candidate、staged UI migration、以及 backup / restore / sync 三层语义重写，不把 local owner shift / local-serving cutover / unified planner 写成当前已完成事实。**

---

## 16. P3.3.6 增量回写（本轮新增）

### 16.1 本轮正式吸收的结论
P3.3.6 在 `v0.2.7` 的基础上，继续把以下 UI 事实并回主文档：

1. **`local_serving_candidate_contract_v1` 当前只进入页面元语义层**
   - 允许进入：`source_type / owner_layer / shadow_only / serving_eligibility_state / candidate_reason`
   - 当前只作为 shadow-compatible candidate
   - 当前不得写成 current runtime serving truth

2. **`review_group_compatibility_posture_v1` 当前进入三层姿态**
   - current runtime serving owner
   - compatibility anchor
   - deprecated candidate
   - 当前不得把 deprecated candidate 翻译成“旧方案已退出”

3. **`fact_settlement_ingest_contract_candidate_v1` 当前进入页面事实边界层**
   - local-serving candidate 可以产出 evidence
   - 但 local evidence ≠ final fact
   - effective review / daily goal progress / reward settlement / streak 等最终事实当前继续以后端为准

4. **`session_entry_and_routing_compat_v1` 当前只进入 shadow-aware compatibility**
   - 首页 runtime 继续保持 `home_word_entry = study_default`
   - active continuation 继续高优先，但仍独立承接
   - 当前不得 silent reroute / auto-routing runtime

5. **`deprecation_markers_and_writeback_plan_v1` 当前进入 UI 资产分层**
   - 可以进入 `deprecated candidate` 的项目，应只进注释 / 测试 / patch draft
   - 当前继续真实服务的页面资产，应进入 `compatibility-only`
   - 这两层不得混写成用户事实

6. **`shadow_parity_test_strategy_v1` 当前进入最小固定 UI 测试集**
   - shadow / parity evidence 可以存在
   - 但不得泄漏成用户事实
   - parity success / mismatch 都不得变成用户端“已升级 / 已切换”提示

### 16.2 SpecHomePage（P3.3.6 后口径）
#### 当前 runtime reality
- 首页继续保持 `home_word_entry = study_default`
- active continuation 继续高优先，但通过独立 CTA / helper / priority block 承接
- 当前不得 silent reroute
- 当前不得把 planner-aware entry 写成 runtime truth

#### shadow-compatible candidate
- 允许进入：
  - `shadow_routing_candidate`
  - `planner_aware_entry_candidate`
  - `continuation_local_compat_candidate`
- 这些当前只用于：
  - future contract naming
  - parity / shadow planning
  - hidden decision evidence
- 当前不得写成：
  - 默认入口已改为 planner-aware
  - 系统已自动判断今天先复习
  - mixed routing 已启用

### 16.3 StudyPage（P3.3.6 后口径）
- 继续作为默认学习入口页
- 继续维持 P3.3 / P3.3.1 / P3.3.4 已冻结的 4 按钮、preview 最小回归与低阻力提交节奏
- 继续不承担 planner dispatcher 解释职责
- 当前不新增“shadow / parity / local-serving candidate 已生效”之类提示
- 当前 StudyPage preview 继续维持既有边界：StudyPage-only / hint-only / estimated-only

### 16.4 ReviewPage（P3.3.6 后口径）
#### current runtime truth
- ReviewPage 当前继续围绕 cloud `review_group` 展示：
  - queue / continuation
  - remaining
  - group completion
  - settlement 承接

#### compatibility / shadow contract
- future queue source 当前只允许以以下来源标签进入 shadow-compatible 页面合同层：
  - `cloud_group`
  - `local_due_shadow`
  - `local_generated_shadow`
- 但当前用户端只允许看到 `cloud_group` 的 serving reality
- `local_due_shadow` / `local_generated_shadow` 当前只可存在于：
  - debug / dev / test 观察层
  - hidden adapter seam
  - parity evidence layer

#### current forbidden overclaim
- 当前队列来源：本地
- 当前复习由本地规划提供
- Shadow 模式已开启
- 已切换到本地 serving
- `review_group` 已退出运行态

### 16.5 Fact / Settlement 边界（P3.3.6 后口径）
即使 future serving 向 local 靠，当前页面仍必须继续服从：

1. **effective review fact** 继续以后端为准
2. **daily goal progress impact** 继续以后端为准
3. **reward settlement impact** 继续以后端为准
4. **streak / learning_day / check-in 最终影响** 继续以后端为准

因此当前继续禁止：
- 已记为有效复习
- 今日目标已推进
- 奖励已到账
- streak 已由本地 shadow 续上
- 学习事实已同步到云端

除非 cloud fact layer 已明确返回对应 final truth。

### 16.6 Deprecated candidate vs Compatibility-only（P3.3.6 吸收）
#### 建议进入 deprecated candidate 的 UI 资产
- 直接绑定 cloud-group 语义的 helper wording
- 直接把 `next review group` 写成 current-only 的 copy
- 只服务 cloud-group explanation 的内部状态命名
- future 极可能被 local-serving 重写的 continuation 文案

#### 建议进入 compatibility-only 的 UI 资产
- ReviewPage 当前 group progress 呈现
- continuation card 的现行布局
- Home review helper 的 current wording
- ReviewPage current settlement / completion 状态文案

### 16.7 Fact Copy 禁区（P3.3.6 补强）
以下表达在 P3.3.6 后继续列为页面事实层禁区：

#### local-serving / owner-shift 禁区
- 本地 serving 已启用
- ReviewPage 已切到本地队列
- 当前复习队列来自本地 due
- `review_group` 已退出运行态
- owner shift 已完成
- 当前 serving truth 已切换

#### routing / planner 禁区
- 系统已自动为你选择更优入口
- auto-routing 已开启
- mixed session 已启用
- planner-aware 首页已生效

#### fact / settlement 禁区
- 本地已直接记为有效复习
- 今日进度已因本地 shadow 更新
- 奖励已因本地队列到账
- streak 已由本地 shadow 续上

#### shadow / parity 禁区
- 影子模式已正式生效
- parity 已通过，现已切换新模式
- 当前已升级到新 serving 方案

### 16.8 保留为 Pending 的内容
以下内容在 P3.3.6 后仍不直接升格：

1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 接管 current ReviewPage truth
4. `review_group` runtime 退场
5. auto-routing runtime
6. unified planner / planner merge
7. DB / API core rewrite
8. 用户可见 shadow-mode 宣告
9. ReviewPage preview re-entry
10. 首页 planner-aware runtime route

### 16.9 Room 5 一句话结论
> **P3.3.6 回写后，主 UI 文档对 local-serving / shadow 的正式口径应更新为：当前 runtime truth 继续保持 `study_default`、cloud `review_group` serving truth、以及 local evidence 不等于 final fact；本轮只正式吸收 shadow-compatible 的页面元语义、`review_group` 的兼容姿态、deprecated / compatibility-only 资产分层、以及 shadow/parity 不得泄漏为用户事实的硬护栏。**

