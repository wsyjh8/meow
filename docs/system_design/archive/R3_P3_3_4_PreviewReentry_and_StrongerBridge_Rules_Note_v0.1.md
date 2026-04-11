# R3_P3_3_4_PreviewReentry_and_StrongerBridge_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / preview re-entry + stronger bridge semantics
- **Status:** ready for Room 1 review
- **Date:** 2026-04-10
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis for this round:** `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md` 指定的 review basis
- **Direct upstream input:** `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.4 当前轮需要先收口的两个主题——`preview_durations_reentry_contract_v1` 与 `reviewpage_stronger_bridge_contract_v1`——写成可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API / UI 主文档
- 完整 SRS / 完整复习调度产品规则正文
- Room 4 执行单
- planner merge / unified planner 最终方案

一句话：

> **P3.3.4 不是把复习系统“做满”，而是决定：preview 以什么业务语义重新出现、以及 ReviewPage bridge 要收紧到哪一层但仍不越界。**

---

## 1. 输入依据

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.5.md`
- `UI_SPEC_v0.2.5.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `Main_updated_2026-04-10_v24.md`
- `STATUS_updated_2026-04-10_v22.md`
- `p3.3.4_user.md`

---

## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

原因不是因为要“做更多”，而是因为 P3.3.3 结束后，项目已经明确冻结了：
- `review_readiness_policy_v1`
- `review_priority_policy_v1`
- `review_group_generation_policy_v1`
- `schedule_source_contract_v1`
- `previewDurations` 当前继续 deferred

如果 P3.3.4 仍然完全停在“继续 deferred，不再讨论”，会出现两个持续性的规则空洞：

1. preview 的 future re-entry 会一直停留在“大家都知道以后要做，但谁也不知道业务上意味着什么”
2. ReviewPage bridge 会继续停在“现在先这样”，但 stronger bridge 需要收紧到哪一层没有唯一规则来源

### 2.2 本轮不能走多深
Room 3 同时明确：

> **P3.3.4 当前仍然只是 contract-gate / preflight，不是完整复习规划产品轮。**

所以本轮不能越界到：
- auto-routing runtime 行为
- unified planner / planner merge
- unified Study / Review page
- exact group size contract
- full priority scoring
- 完整 SRS / 完整复习调度产品
- 完整 preview explanation system

### 2.3 Room 3 的一句话立场
> **Room 3 支持 P3.3.4 推进 `preview re-entry` 与 `stronger bridge` 的最小合同候选；但 preview 只能先作为“estimated hint / candidate explanation”，bridge 只能收紧成“更强的非阻断技术语义”，两者都不得被写成用户可依赖的计划事实。**

---

## 3. `preview_durations_reentry_contract_v1`

## 3.1 Room 3 结论
> **若 P3.3.4 要推进 `previewDurations` re-entry，Room 3 只支持它以 `estimated hint / candidate explanation` 的身份回归，不支持它在本轮升格为计划事实。**

### 3.1.1 这在业务上是什么意思
`previewDurations` 在业务上只能表示：

- 系统基于当前 scheduling candidate 给出的**预计性提示**
- 它服务的是“帮助用户理解下一步节奏”的轻解释
- 它不是：
  - 已经由系统正式承诺的下次安排
  - 已经写入云端主计划的事实
  - 已经稳定跨端同步的计划事实
  - 已经由 ReviewPage 主 serving truth 确认的 schedule fact

### 3.1.2 Preview 的业务级别
Room 3 当前建议将 preview 定位为：

- **Hint**
- **Estimated**
- **Candidate explanation**

而不是：
- final plan fact
- committed schedule fact
- unified planner output

---

## 4. `preview_durations_reentry_contract_v1` 的最小冻结候选

### RF-P3.3.4-001 — preview 只能是 estimated hint
- **Status:** Frozen candidate for this round
- **Rule:** 若 P3.3.4 允许 `previewDurations` re-entry，则它在业务上只能作为 **estimated hint / candidate explanation** 出现，不得升格为稳定计划事实。
- **Applies to:** BR / UI / TEST / implementation framing
- **Checkable:**
  1. 任何 preview 文案必须体现“预计 / 仅供参考 / 候选提示”语气
  2. 不得以确定式语气表达下次安排
  3. 不得作为当前轮通过标准中的“稳定计划承诺”
- **Why frozen candidate:** 这是 Room 3 本轮最核心的事实边界，不写硬就会立刻越界成假计划事实

### RF-P3.3.4-002 — source of truth 只能来自 local FSRS scheduling candidate，不得伪装成 cloud serving truth
- **Status:** Frozen candidate for this round
- **Rule:** 若 preview 回归，当前最稳的 source 只能是 **local FSRS 的 scheduling candidate layer**，不得伪装成 cloud `review_group` 的 serving truth 输出。
- **Canonical meaning:**
  1. 它是本地调度候选层的解释性提示
  2. 它不是 cloud-confirmed next review work fact
  3. 它不是 unified planner truth
- **Must not do:**
  1. 不得写成“云端已为你安排”
  2. 不得写成“系统已同步你的下次复习时间”
  3. 不得写成“下一组已根据该时间生成”
- **Why frozen candidate:** 当前 owner split / truth split 仍然成立；preview 若重回，必须服从 split

### RF-P3.3.4-003 — preview 当前只支持 StudyPage 优先，不建议直接进入 ReviewPage
- **Status:** Frozen candidate for this round
- **Rule:** 若 P3.3.4 要推进 preview 最小回归，Room 3 当前只支持 **StudyPage 优先 / Study only first-shot**，不建议本轮直接进入 ReviewPage。
- **Reason:**
  1. ReviewPage 当前仍以 cloud `review_group` 作为主 serving truth
  2. stronger bridge 尚未冻结前，把 local preview 放进 ReviewPage 极易制造 serving truth 混淆
  3. StudyPage 更适合作为“解释性 hint”的 first safe landing zone
- **Must not do:** 不得把 ReviewPage 先行显示 preview 写成“当前复习路径的稳定安排事实”

### RF-P3.3.4-004 — preview 回归不改变任何既有 serving / completion / settlement truth
- **Status:** Frozen candidate for this round
- **Rule:** preview 的回归只影响解释层，不改变任何已有的：
  - serving truth
  - readiness truth
  - group completion truth
  - settlement truth
- **Must not do:**
  1. 不得把 preview 的存在当成 readiness 成立证据
  2. 不得把 preview 的变化当成 group 已更新 / 计划已写回
  3. 不得把 preview 与奖励、完成态、今日目标完成挂钩

---

## 5. Preview 的文案事实边界（硬禁区）

## 5.1 Room 3 一句话判断
> **只要一句话会让用户以为“系统已经正式安排好了”，那它在本轮就是禁区。**

### 5.2 继续列为硬禁区的表达
以下表达在 P3.3.4 当前轮继续列为 **Fact Copy 禁区**：

1. **下次将在 X 天后复习**
2. **系统已为你安排下次复习**
3. **已更新你的复习计划**
4. **已同步复习安排**
5. **系统已根据你的表现重排计划**
6. **你的复习路线已更新**
7. **已进入最佳复习模式**
8. **学习模型已更新**
9. **系统已确认你 X 天后再看**
10. **本地 / 云端计划已统一**

### 5.3 本轮允许的表达方向
当前若要出现 preview 文案，只允许朝以下方向靠近：

- **预计**
- **大约**
- **仅供参考**
- **可能**
- **参考节奏**
- **候选提示**

例如允许的语义层级是：
- “预计约 X 天后再见”
- “仅供参考：大约 X 天后”
- “按当前学习节奏，可能在 X 天后再复习”

但这些都只表示 **候选解释层**，不是承诺。

---

## 6. `reviewpage_stronger_bridge_contract_v1`

## 6.1 Room 3 结论
> **Room 3 支持本轮把 ReviewPage bridge 从 `controlled best-effort` 收紧到“更强但仍 non-blocking 的安全合同候选”；但不支持把它写成 must-succeed、planner owner 迁移、或用户可见计划事实来源。**

### 6.1.1 stronger bridge 在业务上是什么意思
从 Room 3 视角，stronger bridge 的本质不是“更像主真相源”，而是：

- 更少 miss
- 更少 silent drift
- 更强 ensure / init 保障
- 更强 dev / test 可观察性
- 更清楚的 fallback / repair path

它不意味着：
- local FSRS 成为 ReviewPage 主真相层
- bridge success 等于计划已更新
- stronger bridge = unified planner 已成立

---

## 7. `reviewpage_stronger_bridge_contract_v1` 的最小冻结候选

### RF-P3.3.4-005 — stronger bridge 仍然必须保持 non-blocking
- **Status:** Frozen candidate for this round
- **Rule:** 即使 stronger bridge 进入本轮候选，ReviewPage 也必须继续保持：
  - cloud submit first
  - local bridge second
  - local failure non-blocking
- **Must not do:**
  1. 不得要求 bridge must-succeed 才算本轮 review 成功
  2. 不得因 bridge failure 回滚 cloud submit
  3. 不得阻断 next item / group completion / settlement 主链路

### RF-P3.3.4-006 — stronger bridge 可以冻结到 stronger ensure / init，但不能越界成 planner owner shift
- **Status:** Frozen candidate for this round
- **Rule:** 本轮若要收紧 bridge，Room 3 只支持收紧到：
  1. stronger `ensure-local-card-state / init`
  2. stronger observability
  3. bridge miss 的最小 repair path
  4. 更清楚的 fallback semantic boundary
- **Must not do:**
  1. 不得把 stronger ensure 写成 planner owner shift
  2. 不得把 local state ensure 写成 ReviewPage 主真相层切换
  3. 不得把 stronger bridge 写成 planner merge 先行成立

### RF-P3.3.4-007 — stronger bridge 完成后，仍不得产生任何用户可依赖计划事实
- **Status:** Frozen candidate for this round
- **Rule:** 即使 stronger bridge 完成，也仍不得因此新增以下用户可依赖事实：
  - 已更新你的复习计划
  - 已同步复习安排
  - 下次将在 X 天后复习
  - 系统已根据你的表现重排计划
  - 已为你确认最佳复习路径
- **Why frozen candidate:** stronger bridge 只收紧技术现实，不改变业务 truth hierarchy

### RF-P3.3.4-008 — stronger bridge 必须提升 dev/test 可观察性，但不要求 user-facing error
- **Status:** Frozen candidate for this round
- **Rule:** stronger bridge 若进入本轮候选，至少必须让 failure / miss / fallback：
  1. 在 dev/test 侧可观测
  2. 可被断言
  3. 可被最小 repair path 覆盖
- **Current stance:** 仍不要求把 bridge failure 直接弹成 user-facing error
- **Why frozen candidate:** Room 3 本轮接受“对用户温柔、对治理层可见”的收紧方向

---

## 8. 哪些内容必须继续 Pending

### 8.1 Preview 侧继续 Pending
1. Study + Review 同时展示 preview
2. preview 进入首页 / helper / summary block
3. preview 成为 readiness / priority / generation 判断输入
4. preview 成为 API / DB / active review contract 一部分
5. preview 变成稳定承诺式 explanation system

### 8.2 Bridge 侧继续 Pending
1. must-succeed bridge
2. planner owner shift
3. planner merge / unified planner
4. stronger bridge 导致 ReviewPage contract rewrite
5. 任何跨 API / DB core semantics 的变更
6. 把 stronger bridge 写成完整复习规划产品完成

### 8.3 更深产品层继续 Pending
1. auto-routing runtime
2. unified Study / Review page
3. exact group size contract
4. full priority scoring
5. 完整 SRS / 完整复习调度产品
6. 完整 planner explanation product

---

## 9. 对 Room 4 / Room 5 的禁止补脑项（Room 3 版）

### 9.1 给 Room 4
Room 4 在 Room 1 未正式 pin 前，不得自行决定：
1. 把 preview 放进 ReviewPage
2. 把 preview 写成确定式计划事实
3. 把 stronger bridge 写成 must-succeed
4. 把 stronger bridge 写成 unified planner 先行成立
5. 把 bridge success 显示成“已更新计划 / 已同步安排”

### 9.2 给 Room 5
Room 5 在 Room 1 未正式 pin 前，不得自行决定：
1. 在 UI 上把 preview 设计成稳定 schedule fact
2. 在 ReviewPage 加 preview explanation
3. 把 stronger bridge 文案写成“系统已安排 / 已更新 / 已确认”
4. 用任何暗示“计划已写回云端”的表达

---

## 10. Room 3 可直接给 Room 1 的决策句

### 10.1 Preview decision sentence
> **Room 3 judgment：若 P3.3.4 要推进 `preview_durations_reentry_contract_v1`，当前只建议以 `estimated hint / candidate explanation` 的形式 first-shot 回归，并优先限定在 StudyPage；它不应被写成计划事实，不应伪装成 cloud serving truth，也不应在当前轮进入 ReviewPage。**

### 10.2 Stronger bridge decision sentence
> **Room 3 judgment：P3.3.4 可以把 ReviewPage bridge 从 `controlled best-effort` 收紧到“更强但仍 non-blocking 的安全合同候选”，包括更强的 ensure / init、observability 与 minimal repair path；但不得因此把 local FSRS 升格为 planner owner，不得把 stronger bridge 写成 unified planner，更不得写成任何用户可依赖的计划事实。**

### 10.3 Pending boundary sentence
> **Room 3 judgment：P3.3.4 当前只适合收 preview re-entry 与 stronger bridge 的最小合同候选；Study + Review preview、preview 解释系统、must-succeed bridge、planner merge、auto-routing、unified planner 与完整复习规划产品继续保持 pending。**

---

## 11. Room 3 最终一句话

> **P3.3.4 这轮，Room 3 支持把 `previewDurations` 从“完全 deferred”推进到“StudyPage first-shot 的 estimated hint / candidate explanation 候选”，同时把 ReviewPage bridge 从 `controlled best-effort` 推进到“更强但仍 non-blocking 的安全合同候选”；但两者都不能被写成计划事实，也不能被借机升级为 planner merge / unified planner。**
