# R4_P3_3_4_Execution_Plan_v0.1.md

- **Owner:** Room 4（治理层）
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** ready for execution
- **Role basis:** `ROOM04_治理版_v0.2.md`
- **Direct upstream input:** `R1_to_R4_P3_3_4_Execution_Handoff_v0.1.md`

---

## 0. 一句话定位

本稿不是代码实现记录，也不是新的 BR / DB / API / UI 主文档。  
本稿只做一件事：

> **把 Room 1 已经收口完成的 P3.3.4 结论，压成一份可直接交给 Room 4 执行层（Claude Code）的短而硬执行任务单。**

---

## 1. Room 4 当前判断

### 1.1 本轮是否可以开工
> **可以开工。**

### 1.2 本轮开工的性质
> **这是“preview 最小回归 + stronger bridge 最小强化”的 very narrow landing，不是完整复习规划产品开工。**

### 1.3 本轮是否需要先升级
> **默认不需要先升级。**

但若执行层在实现中发现以下情况，必须立即升级，不得自行补脑推进：

1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 `review_group` 最小合同
4. 需要把 local FSRS 升格成 serving truth / planner owner shift
5. 需要让 preview 参与 readiness / priority / route decision / settlement
6. 需要把 preview 做进 ReviewPage 或首页
7. 需要把本轮做成 unified planner / planner merge / auto-routing / 完整 explanation system

---

## 2. 本轮目标

完成 **P3.3.4 — Preview Re-entry + Stronger Bridge Round** 的最小 landing，具体包括：

1. 在 **StudyPage** 以最小合同方式引入 `previewDurations`
2. 保持 **ReviewPage / 首页继续不显示 preview**
3. 将 ReviewPage bridge 从 `controlled best-effort` 收紧到 **stronger-but-still-non-blocking**
4. 补齐 preview / bridge 的文案禁区与测试断言
5. 交回 patch / sync draft 与 `no-major-change statement`

---

## 3. In Scope

1. StudyPage preview hint re-entry
2. preview source 只取 **local FSRS preview candidate**
3. preview 只以 **estimated / reference-only secondary hint** 出现
4. ReviewPage 继续不显示 preview
5. 首页继续不显示 preview
6. ReviewPage 的 stronger ensure / init
7. bridge observability floor
8. failure handling floor
9. minimal repair path
10. preview / bridge 的文案禁区收口
11. 最小测试补强
12. BR / UI patch draft
13. 必要时补一份 API / DB `no-contract-change note`

---

## 4. Out of Scope

1. mixed / auto-routing runtime
2. unified planner / planner merge
3. unified Study / Review page
4. exact group size contract
5. full priority scoring
6. 完整 SRS / 完整复习调度产品
7. 完整 preview explanation system
8. 完整 planner explanation product
9. DB schema 重构
10. API core semantics 重构
11. ReviewPage preview re-entry
12. preview 参与 routing / readiness / settlement
13. stronger bridge 升格成 blocking user contract
14. 任何用户可依赖计划事实

---

## 5. 必守依据

### 要按需读文档，不需要一次性读完

### 5.1 推进层 / 主线程
- `Main_updated_2026-04-10_v24.md`
- `STATUS_updated_2026-04-10_v22.md`
- `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`
- `R1_to_R4_P3_3_4_Execution_Handoff_v0.1.md`

### 5.2 规则 / 文案边界
- `BR-OPP-001_v0.2.5.md`
- `R3_P3_3_4_PreviewReentry_and_StrongerBridge_Rules_Note_v0.1.md`

### 5.3 技术边界
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `R2_P3_3_4_PreviewReentry_and_StrongerBridge_Tech_Note_v0.1.md`

### 5.4 UI / UX 表达边界
- `UI_SPEC_v0.2.5.md`
- `UI_SPEC_P3_3_4_PreviewReentry_and_StrongerBridge_UI_Preflight_v0.1.md`

---

## 6. Room 4 执行护栏

### 6.1 Preview 护栏
- source = **local FSRS preview candidate**
- preview 不是 cloud serving truth
- preview 不是稳定计划事实
- 当前只允许 **StudyPage**
- 当前继续禁止 **ReviewPage / 首页**
- 只允许作为 **secondary hint**
- 必须显式带 **“预计 / 仅供参考”**
- 不允许参与：
  - readiness truth
  - priority truth
  - generation truth
  - route decision
  - settlement / reward / group completion

### 6.2 Preview 文案禁区
以下表达本轮不得出现：
- 下次将在 X 天后复习
- 系统已安排
- 已更新计划
- 已同步复习安排
- 已为你生成复习计划
- 学习模型已更新
- 当前计划已确认
- 云端与本地已统一
- 已根据你的表现自动重排学习路径

### 6.3 Stronger bridge 护栏
ReviewPage 继续保持：
1. cloud submit first
2. local bridge second
3. local failure non-blocking

本轮允许增强到：
- stronger `ensure-local-card-state / init`
- stronger observability
- bridge miss 的 minimal repair path
- 更清楚的 fallback semantic boundary

本轮禁止增强到：
- must-succeed bridge
- 因 local bridge fail 回滚 cloud submit
- 阻断 next item / group completion / settlement
- planner owner shift
- planner merge / unified planner
- 任何新的用户可依赖计划事实

### 6.4 Minimal repair path（执行层默认采用）
1. **pre-submit ensure**
2. **post-cloud-submit local ensure + apply**
3. 若仍失败，则进入 **internal observable fallback**
4. fallback 允许未来再次被 **idempotent re-ensure / local repair** 消化

### 6.5 升级护栏
若执行层发现必须触碰以下任一项，立即停下并回报：
- DB schema
- API core semantics
- `review_group` 最小合同
- planner owner 升格
- unified planner / planner merge
- ReviewPage preview re-entry
- preview 进入 route / readiness / settlement
- blocking bridge
- user-facing stronger bridge error contract

---

## 7. 必测项

### 7.1 Preview 显示 / 不显示
1. StudyPage 在合同满足时，preview 可显示
2. StudyPage 在合同不满足时，preview 不显示
3. ReviewPage 始终不显示 preview
4. 首页始终不显示 preview

### 7.2 Preview 文案
1. preview 必须包含“预计 / 仅供参考”
2. preview 不得出现“下次将在 X 天后复习”
3. preview 不得出现“系统已安排 / 已更新计划 / 已同步复习安排”
4. preview 不能成为主反馈

### 7.3 Stronger bridge 行为
1. stronger bridge 仍不弹用户错误
2. stronger bridge 不改变 cloud-first 主链路
3. stronger bridge 不得引入新的结果型用户文案
4. dev/test 可观察性保留
5. bridge miss / ensure fail / local apply fail 至少有可断言事件或日志钩子

### 7.4 No-major-change 验证
1. 未改 DB schema
2. 未改 API core semantics
3. 未改 `review_group` 最小合同
4. 未发生 planner owner shift
5. 未进入 unified planner / auto-routing / ReviewPage preview

---

## 8. 执行层交付物要求

执行层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **preview 的 source / page scope / copy 边界是否被守住**
5. **stronger bridge 是否仍然 non-blocking**
6. **是否触碰核心契约的判断**
7. **是否需要升级**
8. **需要哪些文档回写**
   - BR / UI / Main / Status / 其他
9. **是否可 accept / revise / escalate / hold**
10. **`no-major-change statement`**

---

## 9. Room 4 验收判断口径

只有同时满足以下条件，Room 4 才会给出 `accept / 可 closeout` 倾向：

1. StudyPage preview hint 已以最小合同方式回归
2. preview 只来自 local FSRS preview candidate
3. preview 只表现为 estimated / reference-only secondary hint
4. ReviewPage / 首页继续不显示 preview
5. stronger bridge 已收紧到最小 stronger contract
6. bridge 仍保持 non-blocking
7. preview / bridge 的假事实文案已清理
8. 未越界触碰 DB / API / `review_group` / planner owner
9. 最小测试补强已交付
10. 已给出 patch / sync draft 与 `no-major-change statement`

---

## 10. 给执行层的一句话

> **请按“StudyPage-only preview hint + stronger-but-still-non-blocking bridge”的边界推进 P3.3.4；不要把本轮做成完整复习规划产品扩张。**
