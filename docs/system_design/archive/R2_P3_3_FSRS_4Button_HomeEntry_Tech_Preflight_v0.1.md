# R2_P3_3_FSRS_4Button_HomeEntry_Tech_Preflight_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Type:** tech preflight / P3.3 scope-pin input
- **Status:** ready for Room 1 review
- **Date:** 2026-04-09
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Runtime basis:** `Main_updated_2026-04-09_v18.md` + `STATUS_updated_2026-04-09_v17.md`
- **Source handoff:** `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`
- **Cross-room input absorbed:**
  - `UI_SPEC_P3_3_HomeEntry_and_4Button_UI_Preflight_v0.1.1.md`
  - `R3_P3_3_FSRS_4Button_ReviewPlanning_Rules_Note_v0.1.md`
  - current active runtime baselines: `BR-OPP-001_v0.2.1.md` / `背单词喵喵app_DB设计草案_v0.2.1.md` / `背单词喵喵app_API设计草案_v0.2.1.md` / `UI_SPEC_v0.2.1.md`

---

## 0. 文档目的

本文件由 **Room 2** 产出，用于把 P3.3 中与：

1. 首页“背单词”主入口的技术落点
2. Study / Review 页 4 按钮接入 FSRS 的技术边界
3. 4 按钮中文词面与内部 rating / grade 的分层合同
4. “开始做复习规划”本轮到底冻结到哪层技术边界
5. Room 4 现在可以做什么、不能补脑什么

相关的 **技术架构 / 主契约 / 核心边界**，先收成一份 `tech preflight`，供 Room 1 后续吸收并决定是否进入 Room 4 执行入口。

本文件不是：
- Room 1 的范围拍板
- Room 3 的业务规则正文
- Room 5 的最终 UI 定稿
- Room 4 的执行单
- 完整 SRS / 完整复习调度引擎的最终技术设计

一句话：

> **先把“现在哪些技术事实已经存在、P3.3 本轮到底接哪一层、跨本地 FSRS 与云端主链路的边界怎么守、哪些 contract 还不能让执行层自己猜”写清楚。**

---

## 1. 输入依据

### 1.1 当前治理层 / 推进层依据
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `Main_updated_2026-04-09_v18.md`
- `STATUS_updated_2026-04-09_v17.md`

### 1.2 当前 active runtime contract basis
- `BR-OPP-001_v0.2.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.1.md`

### 1.3 本轮 handoff basis
- `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.4 本轮 cross-room preflight inputs
- `UI_SPEC_P3_3_HomeEntry_and_4Button_UI_Preflight_v0.1.1.md`
- `R3_P3_3_FSRS_4Button_ReviewPlanning_Rules_Note_v0.1.md`

---

## 2. Room 2 当前判断

### 2.1 为什么需要单独做 P3.3 tech preflight
原因有五点：

1. 当前 P3.1 已整体 close，runtime active baseline 已更新到 `v0.2.1`，P3.3 不能直接越过 active baseline 把 preflight 候选写成已生效事实。
2. 当前 UI / Rules 两侧都已经明确：`StudyPage` / `ReviewPage` 的 runtime reality 仍是 **2 按钮**；4 按钮属于 **P3.3 preflight candidate**。
3. 当前代码现实中，本地 **`FsrsService` / `SessionBuilder` / review logs / local progress** 已存在，云端 **`/me/today` / `review_group` / reward / settlement** 也已存在；如果不先写技术边界，Room 4 很容易把两套 truth layer 粘成一团。
4. 当前 Room 1 handoff 明确要求 Room 2 交付的是：**FSRS 接入技术边界 / 页面接法 / state flow**，不是让 Room 4 直接一边写一边猜。
5. 4 按钮接入表面上像 UI 改动，实际上会牵涉：
   - rating 输入合同
   - 本地 FSRS adapter
   - Session / attempt / progress 刷新链路
   - 幂等 / 节流 / 重复点击保护
   - 首页任务卡是否刷新

### 2.2 Room 2 的一句话立场
> **P3.3 本轮先冻结“首页入口落点 + 4 按钮的内部 rating contract + 本地 FSRS / 云端 review_group 的边界 + 最小提交返回需求 + 防重护栏”，不冻结完整 SRS，不冻结最终复习规划主引擎，也不把 4 按钮写成 runtime 已切换。**

### 2.3 当前 runtime reality vs 本轮候选
#### A. 当前 runtime active reality
1. 当前 active runtime baselines 仍是 `BR / DB / API / UI v0.2.1`。
2. 当前 `StudyPage` / `ReviewPage` 仍应视为 **2 按钮 reality**。
3. 当前首页默认仍以 `UI_SPEC_v0.2.1` 的现实为准；P3.3 只是新一轮 preflight delta。
4. 当前系统已是 **dual-store**：
   - **本地**：FSRS 调度、review logs、local settings、local progress repo
   - **云端**：today 聚合、review_group、奖励、商店、签到、结算

#### B. 本轮 P3.3 candidate
1. 首页新增“背单词”主入口
2. Study / Review 页进入 4 按钮交互 preflight
3. 4 按钮内部语义接入 FSRS 4 档
4. 复习规划进入第一轮 technical preflight，但不切最终 planner owner

#### C. 本轮必须写硬的挡板
1. **不得把 preflight candidate 写成 runtime 已切换事实**
2. **不得把中文词面直接当作跨层 contract**
3. **不得在本轮擅自宣布“本地 FSRS 已成为全局复习最终权威”**
4. **不得在本轮擅自宣布“云端 review_group 已退场”**
5. **不得在 Room 2 未收口前，让 Room 4 自行决定首页点击后启动哪种 session**

---

## 3. 本轮技术范围

## 3.1 In Scope
1. 首页“背单词”主入口的默认技术落点
2. Study / Review 页 4 按钮的内部 canonical rating contract
3. 4 按钮中文显示层与内部 grade 层的分离原则
4. Study / Review 提交后的最小状态刷新需求
5. 高风险点击点的节流、防重、幂等要求
6. 本地 FSRS 与云端 review_group / today 聚合之间的最小桥接边界
7. Room 4 后续进入实现前必须先交回的技术草案清单

## 3.2 Out of Scope
1. 不冻结完整 SRS / interval / difficulty / stability 算法细节
2. 不冻结最终 review planner 的唯一权威层
3. 不冻结 review_group grouping / readiness / priority engine 细节
4. 不冻结最终 4 个中文词面
5. 不直接改 active DB / API baseline
6. 不直接下 Room 4 执行 patch
7. 不重做全局信息架构
8. 不把 P3.3 扩成“全面重做学习系统”

---

## 4. Room 2 建议冻结的技术结论（Frozen for preflight）

## 4.1 TF-P3.3-001 — 首页入口默认落点
- **Status:** Frozen for preflight
- **Rule:** 除非 Room 1 后续另行 pin，本轮“首页”默认指 `SpecHomePage`；首页新增“背单词”主入口的默认落点为 `StudyPage`。
- **Why:** Room 5 已明确本轮首页默认指 `SpecHomePage`；默认点击进入 `StudyPage` 能以最小改动先把学习主线入口做强。
- **Must not do:**
  1. 不得自动改写 `TodayPage` 的历史定位
  2. 不得在本轮直接引入“学习 / 复习二选一中间页”
  3. 不得把首页按钮默认写成自动分流到 mixed session

## 4.2 TF-P3.3-002 — 4 按钮跨层 contract 必须采用“显示层 / 语义层 / 适配层”三层分离
- **Status:** Frozen for preflight
- **Rule:** 4 按钮在技术上必须至少分三层：
  1. **显示层（Display Copy）**：两字中文词面，仅用于 UI 展示
  2. **语义层（Canonical Rating Key）**：`again | hard | good | easy`
  3. **适配层（FSRS Grade Adapter）**：映射到本地 FSRS 所需的 `1 | 2 | 3 | 4`
- **Why:** Room 3 已冻结“4 按钮本质是 rating input，不是结果事实”；若不把中文 copy 与内部 grade 分层，后续一定会出现“按钮文案改了、算法语义也被误改”的 silent drift。
- **Must not do:**
  1. 不得把 `不会 / 模糊 / 记得 / 熟练` 这类中文词面直接写入持久化层
  2. 不得让 API / DB / local repo 直接依赖 UI 中文字符串
  3. 不得跨文件出现多套平行 rating 命名

## 4.3 TF-P3.3-003 — 4 按钮 canonical mapping 顺序固定
- **Status:** Frozen for preflight
- **Canonical mapping:**
  - `again` -> FSRS grade `1`
  - `hard`  -> FSRS grade `2`
  - `good`  -> FSRS grade `3`
  - `easy`  -> FSRS grade `4`
- **Rule:** 无论 UI 最终词面怎么定，只要进入 P3.3 4 按钮方案，语义顺序必须与上述 mapping 保持单调一致。
- **Why:** Room 3 已冻结 Again / Hard / Good / Easy 的语义顺序；Room 2 本轮把它转成跨层技术 contract。
- **Must not do:**
  1. 不得让 StudyPage 与 ReviewPage 使用相反顺序
  2. 不得让 UI slot 顺序与实际提交 grade 值错位
  3. 不得在 Room 4 实现中再临时发明第二套 `0~3` / `A~D` 并行枚举

## 4.4 TF-P3.3-004 — 本地 FSRS 与云端 review_group 的边界先保守桥接，不强合并
- **Status:** Frozen for preflight
- **Rule:** 本轮先采用 **bridge-first**，不采用 **planner merge-first**。
- **当前技术边界：**
  1. **本地 FSRS** 继续承担：rating 适配、调度计算、review logs、本地学习运行态
  2. **云端 review_group / today** 继续承担：主聚合事实、复习批次对象、奖励结算上游、首页任务态
  3. **ReviewPage 若来自云端 review_group**，则必须继续服从 active group continuation / completion / no-duplicate-settlement 边界
  4. **本地 FSRS 的 rating 更新** 可以作为 side-effect / bridge event 写入本地调度，但不自动宣布其成为全局唯一 review planner
- **Why:** 当前 BR 已冻结 `review_group` 最小业务合同；当前 DB / API 已明确本地与云端是 dual-store，不能在 preflight 阶段假装只剩一边。
- **Must not do:**
  1. 不得在本轮删除或绕过 `review_group` 既有最小合同
  2. 不得把本地 due list 直接写成首页唯一复习真相
  3. 不得让前端仅凭本地 FSRS 自己推断今日复习完成

## 4.5 TF-P3.3-005 — 首页入口点击后的 session 合同当前只冻结“页面路由”，不冻结“启动模式”
- **Status:** Frozen for preflight
- **Frozen now:**
  1. 首页“背单词”默认进入 `StudyPage`
  2. 首页“去复习 / 继续复习”默认进入 `ReviewPage`
- **Still pending:**
  1. 是否自动创建新词学习 session
  2. 是否自动创建复习 session
  3. 是否进入 mixed session
  4. 是否按今日计划 / readiness 自动分流
- **Why:** Room 5 已把这点标成当前 gap；Room 1 handoff 也明确这正是不能让 Room 4 自己猜的地方。

## 4.6 TF-P3.3-006 — 4 按钮提交流的最小返回需求必须提前写硬
- **Status:** Frozen for preflight
- **Rule:** 无论最终由本地 service 还是云端接口承接，4 按钮一次提交后，调用方至少需要拿到以下最小结果集合：
  1. `applied_rating_key`
  2. `applied_fsrs_grade`
  3. `card_result_type`（例如：new_word / review_item / review_group_item）
  4. `next_due_at`（若当前来源层可提供）
  5. `session_progress_summary`（至少支持 remaining / completed / current_index 类信息）
  6. `refresh_hints`（至少支持是否需要刷新首页 today card / review summary / local queue）
- **Why:** 首页已经有任务感和进度感表达；如果提交后没有最小刷新合同，Room 4 后续一定会在 UI 层硬写 reload 或局部补脑。
- **Note:** 这是一条 **preflight minimal return contract candidate**，不是说当前 active API 已经拥有上述全部字段。

## 4.7 TF-P3.3-007 — 4 按钮属于高频写操作，必须默认进防重护栏
- **Status:** Frozen for preflight
- **Rule:** 4 按钮点击链路默认纳入防重 / 幂等 / 节流护栏。
- **至少要求：**
  1. 同一卡片同一点击周期内，前端必须防连点
  2. 若存在跨进程 / 跨端提交，关键写链路需保留 request trace
  3. 若写入云端事实层，必须保留幂等语义，避免重复推进 / 重复结算
  4. 失败重试不得造成二次记分 / 二次结算
- **Why:** 这类高频交互一旦没有节流和幂等，最容易把 review_group、奖励、session progress 打乱。

---

## 5. 本轮推荐的技术分层方案

## 5.1 推荐分层

### Layer A — Runtime Active Reality（不改写）
- `UI_SPEC_v0.2.1.md` 仍是 active UI baseline
- `StudyPage` / `ReviewPage` 仍是 2 按钮 runtime reality
- active BR / DB / API 仍是 `v0.2.1`

### Layer B — P3.3 Preflight Delta Candidate（本轮收口）
- 首页新增“背单词”主入口
- Study / Review 进入 4 按钮 candidate
- canonical rating contract 固定为 `again | hard | good | easy`
- UI copy 与 internal grade 分离
- 本地 FSRS 与云端 review_group 先 bridge，不 merge

### Layer C — Pending Technical Decision（继续保留）
- 最终 review planner owner
- 首页主 CTA 是否按 review readiness 自动切换
- 首页点击后是否自动启动 session / 哪种 session
- 4 按钮提交是否需要云端 API contract 扩展
- Study / Review 是否长期共用完全一致的逻辑承接层

---

## 6. Room 2 对 Room 4 的技术挡板

Room 4 在 Room 1 未把本稿进一步吸收前，**不得自行补脑** 以下内容：

1. 不得自行拍板最终 4 个中文词面
2. 不得自行决定首页“背单词”点击后启动哪种 session
3. 不得自行决定本地 FSRS 已成为全局复习唯一 planner
4. 不得自行删除或绕过云端 `review_group` 最小合同
5. 不得自行把 4 按钮 candidate 写成 runtime 已切换事实
6. 不得把 UI 中文词面直接作为 DB / API / repo 持久化值
7. 不得在未定义刷新 hints 的情况下，靠页面硬编码猜首页是否刷新
8. 不得把“按钮点击成功”直接写成“学习结果事实已完成 / 奖励已到账”

---

## 7. Room 4 进入实现前，Room 2 期望收到的草案

若 Room 1 继续推进到 Room 4，本轮 Room 4 至少应先交以下草案，再进入正式实现：

### 7.1 Impact Map
- 哪些页面受影响
- 哪些本地 service 受影响
- 哪些云端 contract 可能受影响
- 哪些测试需要新增 / 回归

### 7.2 Rating Mapping Matrix
至少写清：
- UI slot
- UI candidate copy
- canonical rating key
- FSRS grade int
- page scope（Study / Review / both）
- local write target
- cloud side-effect / refresh target（若有）

### 7.3 Session Entry Draft
至少写清：
- 首页“背单词”进入 `StudyPage` 后是否自动开 session
- ReviewPage 从什么来源进入
- 若继续保留 active `review_group`，如何与本地 FSRS adapter 并存

### 7.4 Submit Flow Draft
至少写清：
- 点击 4 按钮后的顺序：UI disable -> submit -> local fsrs apply -> optional cloud sync / refresh -> next card
- 失败与重试路径
- refresh_hints 从哪一层产生

### 7.5 Test Draft
至少覆盖：
- 4 按钮顺序不反转
- 同卡连点不重复记分
- review_group continuation 不被破坏
- 首页 today card / review summary 刷新不漂移
- 中文 copy 改动不影响内部语义

---

## 8. Room 2 的推荐推进顺序

### Batch A — 低风险入口层
1. `SpecHomePage` 新增“背单词”主入口
2. 路由默认进入 `StudyPage`
3. 不改变 runtime active CTA 规则真相层

### Batch B — 4 按钮 contract 层
1. 建立 `display copy -> canonical rating -> fsrs grade` mapping
2. Study / Review 共用同一 canonical order
3. 不把中文词面下沉到持久化层

### Batch C — 提交流与刷新层
1. 补最小 submit result / refresh hints
2. 补连点保护 / 幂等策略
3. 明确首页是否刷新、刷新什么

### Batch D — review bridge 层
1. 保留云端 review_group 最小合同
2. 把本地 FSRS 作为调度 side-effect / bridge event 接入
3. 不做全局 planner 切换

一句话：

> **先把入口接通，再把 rating contract 写硬，再补提交与刷新，最后才碰 review bridge；不要一上来就把 planner merge 做成大重构。**

---

## 9. Room 2 当前风险判断

### R2-P3.3-001
- **Risk:** UI 中文词面先落代码，内部 grade contract 后补
- **Impact:** 后续 copy 一改，算法语义跟着漂
- **Mitigation:** 先冻结 canonical rating key，再允许 UI copy patch

### R2-P3.3-002
- **Risk:** Room 4 直接把本地 FSRS due 取代云端 review_group
- **Impact:** 破坏 active BR 的 review continuation / completion / settlement 边界
- **Mitigation:** 本轮先 bridge-first，不 merge-first

### R2-P3.3-003
- **Risk:** 首页“背单词”一点击就隐式启动某种 session，但合同未写明
- **Impact:** session_status、today card、review summary 刷新都会漂
- **Mitigation:** 先冻结路由，不冻结 session 启动模式；待 Room 4 草案后再吸收

### R2-P3.3-004
- **Risk:** 4 按钮高频点击无节流 / 幂等保护
- **Impact:** 重复记分、重复推进、重复结算
- **Mitigation:** 提前把防重写成默认硬约束

---

## 10. 对 Room 1 的吸收建议

若 Room 1 接受本稿，建议只吸收以下内容进入主线程：

### 可吸收
1. P3.3 当前进入 **Room 2 tech preflight completed** 状态
2. 首页“背单词”默认技术落点：`SpecHomePage -> StudyPage`
3. 4 按钮跨层 contract 必须分成 `显示层 / canonical rating / FSRS 适配层`
4. 本地 FSRS 与云端 review_group 本轮先按 **bridge-first** 处理，不做 planner merge
5. Room 4 开始前必须先交 `Impact Map + Rating Mapping Matrix + Session Entry Draft + Submit Flow Draft + Test Draft`

### 当前不建议吸收成 runtime active truth
1. 最终 4 个中文词面
2. 首页点击后自动启动哪种 session
3. review planner 的最终唯一权威层
4. 4 按钮提交后的完整 API schema 扩展
5. Study / Review 是否长期收敛为统一学习承接页

---

## 11. 一句话结论

> **Room 2 当前已完成 P3.3 的最小技术 preflight：本轮先把首页入口落点、4 按钮 canonical rating contract、最小提交返回需求与防重护栏写硬；同时明确当前仍是 2 按钮 runtime reality，4 按钮只是 preflight candidate；本地 FSRS 与云端 review_group 本轮只做 bridge，不做 planner merge。**
