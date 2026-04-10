# R1_to_R4_P3_3_Execution_Handoff_v0.1

- **Owner:** Room 1  
- **Project:** 背单词喵喵 App  
- **Type:** unified execution handoff / Room 4 entry pack  
- **Status:** ready for Room4-治理层  
- **Date:** 2026-04-09  
- **Role basis:** `room1_v0.2.0.md`  
- **Runtime basis:** `Main_updated_2026-04-09_v18.md` + `STATUS_updated_2026-04-09_v17.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3 的 cross-room preflight 输入，收成一份 **Room 4 可执行的统一入口**。

本文件不是：
- 新 PRD
- Room 2 技术正文
- Room 3 规则正文
- Room 5 UI SPEC 正文
- 直接宣布 runtime 已切换

一句话：

> **Room 4 现在可以进入 P3.3 执行阶段，但必须按已冻结边界先交草案、再做最小实现切片，不得自行补脑把 preflight candidate 写成 runtime 已切换事实。**

---

## 1. 上游吸收结果

Room 1 已吸收以下输入：
- `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`
- `UI_SPEC_P3_3_HomeEntry_and_4Button_UI_Preflight_v0.1.1.md`
- `R3_P3_3_FSRS_4Button_ReviewPlanning_Rules_Note_v0.1.md`
- `R2_P3_3_FSRS_4Button_HomeEntry_Tech_Preflight_v0.1.md`

### 1.1 当前推进判断
- **P3.1**：closed
- **P3.3**：进入 **Room 4 execution entry**
- 当前 active runtime baseline 仍是 `BR / DB / API / UI v0.2.1`
- P3.3 本轮是 **execution entry for delta**, 不是整体 baseline 切换

### 1.2 当前 Room 4 可执行的核心主题
1. 首页新增“背单词”主入口
2. `StudyPage / ReviewPage` 接入 4 按钮交互的最小实现入口
3. 4 按钮内部按 `again / hard / good / easy` 语义链路接入 FSRS
4. 复习规划只做到 **bridge-first** 的第一轮实现，不做完整 planner 重构

---

## 2. 本轮执行范围

## 2.1 In Scope
1. 在 **`SpecHomePage`** 增加“背单词”主入口
2. 首页“背单词”默认落点到 **`StudyPage`**
3. 为 `StudyPage / ReviewPage` 准备 4 按钮交互接入
4. 建立 4 按钮的跨层映射：
   - display copy
   - canonical rating key
   - FSRS grade int
5. 补齐点击后的最小提交流程草案
6. 补齐最小防重 / 节流 / 失败重试路径
7. 明确首页、学习页、复习页、本地 FSRS、云端 review_group / today 的影响面
8. 在不突破现有 active contracts 的前提下，完成 **最小可验证实现切片**

## 2.2 Out of Scope
1. 不冻结完整 SRS / 全量复习调度算法
2. 不重做全局 IA / 不重做 `SpecShell`
3. 不把 `StudyPage / ReviewPage` 直接宣布为 runtime 4 按钮已完全切换
4. 不自行决定最终 4 个中文词面
5. 不自行决定首页点击后自动进入哪种 session
6. 不自行宣布本地 FSRS 已成为全局唯一 review planner
7. 不删除或绕过云端 `review_group` 最小合同
8. 不扩写统计深化、商店、装扮、P3.1 backup/restore
9. 不重写 active BR / DB / API / UI baseline

---

## 3. 当前必须服从的执行边界

## 3.1 Runtime reality vs candidate
Room 4 必须写死以下认知：

### A. 当前 runtime active reality
- active BR / DB / API / UI 仍是 `v0.2.1`
- `StudyPage / ReviewPage` 当前仍是 **2 按钮 reality**
- P3.3 当前只是 **execution-entry delta**，不是 runtime baseline 已切换

### B. 本轮 candidate
- 首页新增“背单词”主入口
- 4 按钮进入实现入口
- canonical rating contract 固定为 `again | hard | good | easy`
- UI 中文词面与内部 grade 分层
- 本地 FSRS 与云端 review_group 采用 **bridge-first**，不是 merge-first

## 3.2 Room 4 不得补脑的点
1. 不得自行拍板最终 4 个中文词面
2. 不得自行决定首页“背单词”点击后启动哪种 session
3. 不得自行把本地 FSRS 写成全局唯一 review planner
4. 不得自行删除或绕过云端 `review_group` 最小合同
5. 不得自行把 4 按钮 candidate 写成 runtime 已切换事实
6. 不得把 UI 中文词面直接作为 DB / API / repo 持久化值
7. 不得在未定义 refresh hints 的情况下，硬编码猜首页是否刷新
8. 不得把按钮点击成功直接写成“学习事实已完成 / 奖励已到账”
9. 不得把“复习规划第一轮接入”写成“完整复习规划已完成”

---

## 4. 本轮冻结给 Room 4 的最小执行结论

## 4.1 首页入口
1. 本轮“首页”默认指 **`SpecHomePage`**
2. 首页新增“背单词”主入口
3. 默认落点：**`StudyPage`**
4. 不自动改写 `TodayPage` 的历史定位
5. 不引入“学习 / 复习二选一中间页”

## 4.2 4 按钮 contract
### 必须采用三层分离
1. **显示层（Display Copy）**：两字中文，仅 UI 展示
2. **语义层（Canonical Rating Key）**：`again | hard | good | easy`
3. **适配层（FSRS Grade Adapter）**：`1 | 2 | 3 | 4`

### canonical mapping 固定为
- `again -> 1`
- `hard -> 2`
- `good -> 3`
- `easy -> 4`

### 业务语义边界
- 4 按钮本质是 **rating input**，不是结果事实
- 不得把按钮文案写成“已掌握 / 已完成 / 已升级 / 已到账”
- 两字中文要求已冻结，但 **final wording 仍 pending**

## 4.3 Planner 边界
1. 本地 FSRS 继续承担：rating 适配、调度计算、review logs、本地学习运行态
2. 云端 `review_group / today` 继续承担：主聚合事实、复习批次对象、奖励结算上游、首页任务态
3. 若 `ReviewPage` 来自云端 `review_group`，必须继续服从 active group continuation / completion / no-duplicate-settlement 边界
4. 本地 FSRS rating 更新可以写入本地调度，但不自动宣布其成为全局唯一 review planner

---

## 5. Room 4 本轮执行方式

Room 4 本轮按 **两段式** 执行：

### Phase A — 先交草案，后进代码
Room 4 先交以下 4 份草案，Room4-治理层审核后，再进正式实现：

#### A1. Impact Map
至少写清：
- 受影响页面
- 受影响本地 service / repo / FSRS adapter
- 可能受影响的云端 contract / refresh path
- 需要新增与回归的测试面

#### A2. Rating Mapping Matrix
至少写清：
- UI slot
- UI candidate copy
- canonical rating key
- FSRS grade int
- page scope（Study / Review / both）
- local write target
- cloud side-effect / refresh target（若有）

#### A3. Session Entry Draft
至少写清：
- 首页“背单词”进入 `StudyPage` 后是否自动开 session
- `ReviewPage` 从什么来源进入
- 若继续保留 active `review_group`，如何与本地 FSRS adapter 并存

#### A4. Submit Flow Draft
至少写清：
- `UI disable -> submit -> local fsrs apply -> optional cloud sync / refresh -> next card`
- 失败与重试路径
- 是否需要 `refresh_hints`
- 首页任务卡 / 进度卡是否刷新

### Phase B — 最小实现切片
在 Phase A 无 blocker 后，Room 4 允许进入本轮最小实现切片：
1. `SpecHomePage` 增加“背单词”入口并可跳转 `StudyPage`
2. 为 `StudyPage / ReviewPage` 接入 4 按钮结构入口
3. 4 按钮内部按 canonical mapping 进入本地 FSRS adapter
4. 补上最小防重 / 节流 / disable 态
5. 不突破当前云端 `review_group` 最小合同
6. 不把未冻结项 hardcode 成长期事实

---

## 6. 必测项

Room 4 至少覆盖以下验证：

### 6.1 入口与页面承接
1. 首页“背单词”入口显示正确
2. 点击后正确进入 `StudyPage`
3. 不影响 `TodayPage` 既有历史定位

### 6.2 4 按钮映射
1. UI slot 顺序与 `again / hard / good / easy` 一致
2. `StudyPage` 与 `ReviewPage` 不得出现顺序相反
3. UI copy 改动不影响 canonical key 与 grade int

### 6.3 提交流程
1. 点击按钮后正确 disable
2. 重复点击不重复记分 / 不重复推进
3. 提交失败时不产生假成功
4. 成功后 next card / refresh path 符合草案

### 6.4 边界保护
1. 不把按钮点击写成“已掌握 / 已完成 / 奖励到账”
2. 不让本地 FSRS 绕过云端 `review_group` continuation / completion 规则
3. 不让首页靠硬编码本地猜测今日复习是否完成

### 6.5 回归
1. 现有 2 按钮 runtime reality 不被 silent break
2. `today / reward / settlement / session_validation_status` 既有主链路不被误伤
3. 与 P3.1 local-first + manual backup/restore 边界无冲突

---

## 7. 交付物

Room 4 本轮至少交付：
1. `R4_P3_3_Impact_Map_v0.1.md`
2. `R4_P3_3_Rating_Mapping_Matrix_v0.1.md`
3. `R4_P3_3_Session_Entry_Draft_v0.1.md`
4. `R4_P3_3_Submit_Flow_Draft_v0.1.md`
5. 实现 patch / diff 摘要
6. 测试与自测结果
7. 若触碰核心契约，显式标出 escalation 点
8. 若需要文档回写，附受影响文档清单

---

## 8. Done 定义

本轮对 Room 4 的 Done，不是“完整复习系统做完”，而是以下条件同时成立：

1. 已交回 Phase A 四份草案
2. 已完成最小实现切片
3. 首页主入口已进入学习主线
4. 4 按钮已按 canonical contract 接入最小链路
5. 未冻结项未被 Room 4 擅自拍板
6. 现有 active runtime baseline 未被 silent break
7. 测试 / 自测 / 风险 / 回写清单齐全

---

## 9. Room 1 最终说明

Room 4 现在**可以开工**，但本轮授权方式是：

> **先按本 handoff 进入 P3.3 execution entry；先交草案，再做最小实现切片；任何超出本文件边界的点，一律升级，不得自行补脑。**

