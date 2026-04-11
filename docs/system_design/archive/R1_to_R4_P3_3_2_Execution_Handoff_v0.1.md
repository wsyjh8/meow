# R1_to_R4_P3_3_2_Execution_Handoff_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** execution handoff / ready for Room4-治理层
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v20.md` + `STATUS_updated_2026-04-10_v19.md`
- **Direct upstream inputs:**
  - `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`
  - `R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1.md`
  - `R3_P3_3_2_SessionEntry_PlannerOwner_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_2_SessionEntry_and_PlannerOwner_UI_Preflight_v0.1.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3.2 这轮已经完成 cross-room 收口的内容，
正式转译成一份可交给 **Room4-治理层** 的统一执行 handoff。

本文件不是：
- 新 PRD
- 新 BR 主文档
- 新 DB / API 主文档
- Room 4 的代码实现记录
- P3.3.2 closeout

本文件只做一件事：

> **把 P3.3.2 已经由 Room 2 / Room 3 / Room 5 收口的决定，压成一份短而硬、边界明确、可测试、可回写的执行任务单。**

---

## 1. Room 1 吸收后的统一结论

### 1.1 本轮正式结论
Room 1 现正式吸收三方共识：

> **P3.3.2 可以从 pure preflight 前进一步，进入 `next-layer minimal contract`；但只能进入一层很窄的合同，不进入完整 review planning contract。**

本轮只冻结两件事：
1. **`session_entry_policy_v1`**
2. **`planner_owner_split_v1`**

### 1.2 `session_entry_policy_v1`（本轮正式冻结）
1. `home_word_entry = study_default`
   - 首页“背单词”默认仍进入 `StudyPage`
   - 当前它不是 review dispatcher
   - 当前它不是 mixed / auto-routing dispatcher
2. active `review_group` continuation 继续高优先级
   - 但当前只能通过独立 CTA / helper / priority block 承接
   - **不等于** silent reroute
   - **不等于** 吞掉默认 `/study` 入口
3. mixed / auto-routing / unified planner 继续 pending
   - 本轮不得写成已成立事实
   - 若未来要进入，必须单开新 round pin

### 1.3 `planner_owner_split_v1`（本轮正式冻结）
#### A. Cloud `review_group` owner（ReviewPage serving truth owner）
继续负责：
1. review queue serving
2. active group continuation
3. group completion 判定
4. review path 下 settlement 主链路
5. ReviewPage 主队列真相层

#### B. Local FSRS owner（device-side scheduling owner）
继续负责：
1. local card state
2. rating → interval / stability / difficulty 的设备侧运算
3. review logs
4. local `init / ensure-local-card-state`
5. future preview / local planning 的候选能力来源

#### C. ReviewPage 顺序不变
1. cloud submit first
2. local FSRS side-effect second
3. local failure non-blocking
4. fallback 保持 dev / test 可观察

### 1.4 本轮一句话定义
> **P3.3.2 本轮不是做完整复习规划，而是把“首页入口语义”与“cloud review_group / local FSRS 的 owner split”收成正式可执行的最小合同。**

---

## 2. 给 Room4-治理层的任务定义

### 2.1 目标
完成 P3.3.2 的最小合同落地与补强，具体包括：

1. 把 `session_entry_policy_v1` 落地为稳定页面 / 路由 / 文案 / 测试事实
2. 把 `planner_owner_split_v1` 落地为稳定 ReviewPage / 文案 / 测试事实
3. 清掉会误导为 auto-routing / unified planner / 本地已接管 planner 的假事实表达
4. 在不越界改动核心契约的前提下，补一轮最小 UI / copy / test / guardrail

### 2.2 In Scope
1. 首页“背单词”默认继续进入 `StudyPage`
2. 不允许把首页“背单词”做成 silent reroute
3. 若当前代码需要体现 active `review_group` continuation 高优先级，可通过以下最小承接之一落地：
   - 独立 CTA
   - helper
   - priority block
   - 首页摘要提示
4. 上述承接不得吞掉默认“背单词”入口
5. ReviewPage 的主流程事实继续围绕 cloud `review_group`
6. 页面不得把 local due cards / local scheduler 结果写成 ReviewPage 主队列事实
7. 页面不得把 local FSRS 成功写成“主复习计划已更新 / 已切到最佳路径 / 已统一规划”
8. 若当前实现涉及 local ensure / init / bridge fallback，允许做最小 guardrail / 可观察性 / 测试补强
9. 测试补强
10. 必要时产出 patch draft / doc sync note（仅草案，不代替 owner 正式改主文档）

### 2.3 Out of Scope
1. 不做完整 SRS / 完整复习调度算法
2. 不做 mixed / auto-routing runtime contract
3. 不做 unified planner / planner merge
4. 不做 unified Study / Review page
5. 不重开 `previewDurations`
6. 不改 DB schema
7. 不改 API core semantics
8. 不改 `review_group` 最小合同
9. 不把 local FSRS 升格成唯一 planner owner
10. 不把首页 CTA winner 重写成完整状态驱动系统

---

## 3. 必守依据

Room4-治理层与执行层，本轮必须同时服从以下依据：

### 3.1 推进层 / 主线程
- `Main_updated_2026-04-10_v20.md`
- `STATUS_updated_2026-04-10_v19.md`
- `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`

### 3.2 规则 / 语义边界
- `BR-OPP-001_v0.2.3.md`
- `R3_P3_3_2_SessionEntry_PlannerOwner_Rules_Note_v0.1.md`

### 3.3 技术边界
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1.md`

### 3.4 UI / UX 表达边界
- `UI_SPEC_v0.2.3.md`
- `UI_SPEC_P3_3_2_SessionEntry_and_PlannerOwner_UI_Preflight_v0.1.md`

---

## 4. 待决项（本轮已收口，Room 4 不得补脑）

以下点本轮 Room 1 已收口，Room 4 不得再二次发明：

1. **首页“背单词”继续是 `study_default`**
   - 不是自动分流入口
   - 不是 review dispatcher
   - 不是 mixed dispatcher

2. **active `review_group` continuation 高优先**
   - 但当前必须通过独立承接表达
   - 不是 silent reroute
   - 不是吞掉默认入口

3. **ReviewPage 的 serving truth owner = cloud `review_group`**
   - 本地 FSRS 不是 ReviewPage 主队列 owner
   - 不是 completion owner
   - 不是 settlement owner

4. **Local FSRS = device-side scheduling owner**
   - 可继续增强 local scheduling / ensure / init / side-effect
   - 但不得改写 planner owner

5. **mixed / auto-routing / unified planner 继续 pending**
   - 当前不得落地
   - 当前不得写成既成事实

---

## 5. Room 4 执行护栏

### 5.1 首页入口护栏
1. “背单词”主入口仍保留为默认 Study 入口
2. 不得因 active `review_group` 存在而静默改成 `/review`
3. 不得把 continuation 高优先实现成“点击背单词后自动换路由”
4. 若要体现 continuation，应通过独立 CTA / helper / priority block 承接

### 5.2 ReviewPage 事实护栏
1. ReviewPage 主进度、remaining、组完成提示，继续围绕 cloud `review_group`
2. 不得把 local due cards / local scheduler 结果包装成主队列事实
3. 不得把 local FSRS side-effect 写成“复习规划已更新 / 已自动切换最佳路径 / 已统一规划”
4. local failure 继续 non-blocking，但 dev / test 必须可观察

### 5.3 文案 / Fact Copy 护栏
以下表达本轮不得进入页面事实层、成功反馈、helper、hint、toast：
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

### 5.4 合同越界护栏
本轮不得：
1. 新增 DB 字段 / 改表关系 / 改 schema
2. 修改 API 核心语义
3. 改写 `review_group` 最小合同
4. 把 local FSRS 升格成唯一 planner owner
5. 把首页 CTA winner 写成完整状态机仲裁系统
6. 顺手重开 `previewDurations`

---

## 6. 必测项

Room 4 本轮至少覆盖以下测试 / 自测：

### 6.1 首页入口
1. 首页“背单词”仍默认进入 `StudyPage`
2. active `review_group` 存在时，“背单词”默认入口不被吞掉
3. 若存在 continuation 承接，表现为独立 CTA / helper / priority block，而非 silent reroute
4. 页面不出现 mixed / auto-routing / unified planner 既成事实文案

### 6.2 ReviewPage owner split
1. ReviewPage 主流程事实继续围绕 cloud `review_group`
2. local FSRS 结果不被渲染成主队列事实
3. local FSRS side-effect 成功，不出现“已更新复习规划”类误导文案
4. local failure non-blocking，且 fallback 对 dev / test 可观察

### 6.3 文案 / 假事实清理
1. 不出现“自动分流 / 已安排 / 已整合 / 已统一规划 / 本地已接管”类文案
2. 不出现“已根据 FSRS 自动切换入口”类文案
3. 不把 local planner side-effect 写成用户可依赖事实

### 6.4 回归保护
1. 现有 `/study` 与 `/review` 入口不被静默破坏
2. continuation 承接若新增，不破坏当前首页主入口层级
3. 不触碰 DB / API / `review_group` 合同 / planner owner 的既有基线

---

## 7. 交付物要求

Room4-治理层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **是否发生任何合同越界**
5. **若未实现某个承接态，原因是什么**
6. **仍未解决的问题**
7. **需要哪些文档回写**
   - BR / UI / Main / Status / 其他
8. **是否可 close / 是否需 revise / 是否需 escalate**

---

## 8. Room 1 预期完成定义（Done）

当 Room4-治理层交回结果，且满足以下条件时，Room 1 认为 P3.3.2 本轮可以进入吸收 / closeout 判断：

1. `session_entry_policy_v1` 已落地成稳定页面 / 路由 / 测试事实
2. 首页“背单词”仍保持 `study_default`
3. active `review_group` continuation 若被承接，方式符合“独立承接、不吞入口”边界
4. `planner_owner_split_v1` 已落地成稳定 ReviewPage / 文案 / 测试事实
5. ReviewPage 继续表现 `cloud-first + local side-effect`
6. 页面假事实文案已清理
7. 未触碰 DB / API / `review_group` 最小合同 / planner owner 基线

---

## 9. 一句话 handoff

> **请 Room4-治理层按“冻结 `session_entry_policy_v1` + `planner_owner_split_v1`、不做 auto-routing、不做 unified planner、不改核心契约”的边界推进 P3.3.2；本轮重点是把入口语义与 owner split 变成稳定可执行事实，而不是把完整复习规划做厚。**
