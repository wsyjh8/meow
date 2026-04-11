# OPP-001_STATUS.md
**Canonical Runtime Name:** `OPP-001_STATUS.md`  
**Project:** 背单词喵喵 App  
**Owner:** Room 1  
**Status:** active  
**Type:** 推进层 SSOT / Current-State Snapshot

---

## 0) Meta

- **Last updated:** 2026-04-10
- **Current Round:** Stage 4 P3.3.2 Closed / Next-Focus Pending
- **Current Focus:** `P3.3.2` 已按 Room 1 定义的 minimal-contract 范围完成实施并被吸收进主线程。当前第一优先级不再是“P3.3.2 能不能落地”，而是由 Room 1 / User 正式拍板 `post-P3.3.2` 的下一推进主题，并决定是否同步做 BR / UI 主文档回写。

## 1) Current Stage

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.2 Closed / Next-Focus Pending
- **Status:** Active; P1 closed, P2 closed, Option A closed, Option A.1 closed, Option B closed, Option C closed, P3 closed, P3.1 closed, P3.3 overall closed, P3.3.2 closed

**Rationale**
- P3.3 已整体 close，且 Room 1 已把 BR / UI 主文件入口更新到 `BR-OPP-001_v0.2.3.md` 与 `UI_SPEC_v0.2.3.md`，不再继续依赖 `v0.2.2 + P3.3.1 delta reference` 作为运行态双入口。
- Room 1 已通过 `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md` 把 post-P3.3 的下一轮正式命名为 `P3.3.2 — Review Planning Deepening / Contract Gate`，并明确本轮只进入 next-layer minimal contract。
- Room 1 又通过 `R1_to_R4_P3_3_2_Execution_Handoff_v0.1.md` 正式冻结本轮核心结论：`session_entry_policy_v1` + `planner_owner_split_v1`。
- 当前用户已向 Room 1 转述：Room 4 已完成 P3.3.2 实施；而该轮 handoff 的 Done 本身只要求最小合同落地、假事实清理与“不越核心合同边界”，不要求进入完整 review planning product。
- 因此，Room 1 现在可以把 P3.3.2 当前状态写为：**Closed / Next-Focus Pending**。

## 2) Gate Gaps (≤5)

### G-OPP-001-001
- **Gap:** `post-P3.3.2` 的下一轮 focus 尚未被 Room 1 / User 正式拍板。
- **Impact:** 当前可接受 P3.3.2 close，但项目若不及时 pin 新 focus，会再次进入“已关单、未起下一单”的推进真空。
- **Owner:** Room 1 / User
- **Priority:** Critical

### G-OPP-001-002
- **Gap:** `P3.3.2` 的 minimal-contract 事实尚未写回下一版 BR / UI 主文档。
- **Impact:** Main / STATUS 已前进，但若 BR / UI 主文档不补回，会造成治理层阅读入口与运行态事实短期不同步。
- **Owner:** Room 1 / Room 3 / Room 5
- **Priority:** High

### G-OPP-001-003
- **Gap:** ReviewPage 的 residual bridge issue 仍保留为后续技术议题。
- **Impact:** 当前不阻塞 P3.3.2 close，但若未来继续深化 planner convergence，仍需单开一轮技术处理。
- **Owner:** Room 2 / Room 4
- **Priority:** Minor

### G-OPP-001-004
- **Gap:** `Option C / Option A / P3.1 old retained references` 的第二轮 archive / compression 仍未统一处理。
- **Impact:** 旧 reference 仍可作为历史说明，但若长期不整理，会增加阅读噪音。
- **Owner:** Room 1
- **Priority:** Minor

## 3) Current Active Versions

### Governance / Runtime protocol
- ORG: `ORG_v0.3.1.md` — active
- Project Rules Master: `PROJECT_RULES_MASTER_v0.3.1.md` — active
- Room 1: `room1_v0.2.0.md` — active
- Room 2: `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1` — active
- Room 3: `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1` — active
- Room 4: `ROOM04_治理版_v0.2` — active
- Room 5: `ROOM05_ROLE_CARD_UI_UX_v0.2.1` — active
- BR / Rules: `BR-OPP-001_v0.2.3.md` — active BR baseline

### Product / PRD
- 项目介绍书: `背单词养猫app项目介绍书_v0.1.1_P3.1.md` — active
- 主机制 PRD: `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` — active
- 副机制设计稿: `背单词喵喵app_副机制设计稿_v_0.md` — active
- 副机制 PRD: `背单词喵喵app_副机制prd_v_0.md` — active

### Numbers
- `背单词喵喵app_副机制数值草案_v_0.md` — active

### DB / API
- `背单词喵喵app_DB设计草案_v0.2.1.md` — active DB baseline
- `背单词喵喵app_API设计草案_v0.2.1.md` — active API baseline

### UI SPEC
- `UI_SPEC_v0.2.3.md` — active UI baseline

### PLAN / TEST
- `plan_v0.1.2.md` — retained implementation entry / historical reference

### Latest delivery / review / absorption inputs
- `BR-OPP-001_v0.2.3.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.3.md`
- `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1.md`
- `R3_P3_3_2_SessionEntry_PlannerOwner_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_2_SessionEntry_and_PlannerOwner_UI_Preflight_v0.1.md`
- `R1_to_R4_P3_3_2_Execution_Handoff_v0.1.md`

## 4) Current Focus

1. Room 1 已确认：当前主线程不再是 “P3.3.2 能不能落地”，因为 **P3.3.2 已完成并被吸收进 Main / STATUS**。
2. 当前真正主线程是：
   - P3.1 已整体 close
   - P3.3 已整体 close
   - P3.3.2 已把 review planning 继续深化收口到 **minimal contract**
   - 当前 runtime 真实口径新增：
     - `home_word_entry = study_default`
     - active `review_group` continuation 高优先但只能独立承接，不得 silent reroute
     - ReviewPage 继续 `cloud review_group serving truth + local FSRS device-side scheduling`
   - 当前最需要的不是继续补 P3.3.2，而是 **拍板 `post-P3.3.2` 的下一推进主题**
3. 当前仍保留的后续治理问题：
   - 是否需要把 P3.3.2 的 minimal-contract 回写到下一版 BR / UI 主文档
   - 是否将 residual bridge issue 升级为未来技术 round
   - 历史 reference 清理

## 5) Current Risks

1. **Focus vacuum risk**：如果 `post-P3.3.2` 的下一轮 focus 不及时拍板，项目会停在“当前 round 已关单，但下一 round 未定义”的悬挂状态。
2. **Doc-sync lag risk**：若 P3.3.2 的 minimal-contract 长期只存在于 Main / STATUS 与专项 handoff，而不写回 BR / UI 主文档，后续引用会出现短期分裂。
3. **Residual bridge issue risk**：ReviewPage residual bridge issue 若长期不追踪，未来继续深化本地 FSRS 与云端 review_group 收敛时，仍可能再次放大解释成本。
4. **Reference clutter risk**：旧 `v0.1.x` retained references 若不清理，会继续增加阅读噪音。

## 6) Next Actions (≤3; must include Done)

1. **Owner=Room 1 / User | ETA=Next round | Done=拍板 `post-P3.3.2` 的下一轮 focus，并明确是否进入新的产品 / 技术 / 文档治理 round | Action=让项目从 “P3.3.2 已 close” 平滑切到下一推进主题**

2. **Owner=Room 1 / Room 3 / Room 5 | ETA=Later | Done=产出 BR / UI 的下一版主文档，吸收 `P3.3.2` 的 minimal-contract 口径 | Action=让治理层主文档与推进层运行态重新同轨**

3. **Owner=Room 1 | ETA=Later | Done=更新 archive / retained-reference 处理策略，清理 `v0.1.x` 旧入口噪音 | Action=让 runtime active entry 更干净**

## 7) Notes (≤5 lines)

- 当前最重要的新事实是：**`P3.3.2` 已按 minimal-contract 范围实施完成，并被 Room 1 吸收进主线程。**
- 当前新增的 runtime 真实口径是：`study_default` 入口语义 + `planner_owner_split_v1`。
- 当前并未进入 auto-routing / unified planner / 完整 review planning product。
- 本轮仍未触碰 DB schema / API 核心语义 / `review_group` 最小合同 / planner owner 基线。
- 下一治理动作是 **拍板 `post-P3.3.2` 下一轮 focus，并决定是否做 BR / UI 主文档回写。**

## 8) One-line Working Rule

> **STATUS 只记录当前真实推进状态：现在 P1 / P2 / Option A / Option A.1 / Option B / Option C / P3 / P3.1 / P3.3 / P3.3.2 均已 close；其中 P3.3.2 只把入口语义与 owner split 收成最小合同，并未把完整复习规划做厚。下一步不是继续补 P3.3.2，而是由 Room 1 / User 明确 pin `post-P3.3.2` 的下一推进主题。**
