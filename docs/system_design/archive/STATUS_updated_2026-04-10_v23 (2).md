# OPP-001_STATUS.md
**Canonical Runtime Name:** `OPP-001_STATUS.md`  
**Project:** 背单词喵喵 App  
**Owner:** Room 1  
**Status:** active  
**Type:** 推进层 SSOT / Current-State Snapshot

---

## 0) Meta

- **Last updated:** 2026-04-10
- **Current Round:** Stage 4 P3.3.4 Closed / Next-Focus Pending
- **Current Focus:** `P3.3.4` 已按 Room 1 下发的 very narrow minimal-contract 范围完成开发 / 实施，并被吸收进主线程；当前第一优先级不再是“P3.3.4 能不能落地”，而是先补 BR / UI 主文档 write-back，并由 Room 1 / User 正式拍板 `post-P3.3.4` 的下一推进主题。

## 1) Current Stage

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.4 Closed / Next-Focus Pending
- **Status:** Active; P1 closed, P2 closed, Option A closed, Option A.1 closed, Option B closed, Option C closed, P3 closed, P3.1 closed, P3.3 overall closed, P3.3.2 closed, P3.3.3 closed, P3.3.4 closed

**Rationale**
- 当前 `Main / STATUS` 已经把 `P3.3.3` 写成 closed / absorbed，因此本轮不再把 `P3.3.3` 作为当前推进主题。
- `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md` 已把下一轮正式命名为 `P3.3.4 — Preview Re-entry + Stronger Bridge Round`，并通过 `R1_to_R4_P3_3_4_Execution_Handoff_v0.1.md` 将其压成 very narrow execution layer。
- user 现已向 Room 1 转述：Room 4 已完成 `P3.3.4` 的开发 / 实施。
- 因此 Room 1 现可把当前推进状态正式写成 **P3.3.4 Closed / Next-Focus Pending**。
- 但由于本轮尚未收到新的 BR / UI 主文档 merged baseline，当前 active BR / UI 入口继续保持 `v0.2.5`。

## 2) Gate Gaps (≤5)

### G-OPP-001-001
- **Gap:** `post-P3.3.4` 的下一轮 focus 尚未被 Room 1 / User 正式拍板。
- **Impact:** 当前可接受 P3.3.4 close，但项目若不及时 pin 新 focus，会再次进入“已关单、未起下一单”的推进真空。
- **Owner:** Room 1 / User
- **Priority:** Critical

### G-OPP-001-002
- **Gap:** `P3.3.4` 的 BR / UI 主文档 write-back 仍未进入新的 runtime baseline。
- **Impact:** 当前主线程已吸收 P3.3.4 closeout，但 active BR / UI 仍停在 `v0.2.5`；若不补 write-back，会出现“实现已前进、主文档未追平”的治理层滞后。
- **Owner:** Room 3 / Room 5 / Room 1
- **Priority:** High

### G-OPP-001-003
- **Gap:** 更深一层的 review planning 仍保持 pending：ReviewPage preview re-entry、完整 preview explanation system、full priority scoring、exact group size、planner merge / unified planner。
- **Impact:** P3.3.4 已把 preview 与 stronger bridge 往前推一拍，但项目若要继续深化，必须单开下一轮，不可在当前 closeout 后静默扩写。
- **Owner:** Room 1 / Room 2 / Room 3 / Room 5
- **Priority:** High

### G-OPP-001-004
- **Gap:** `Option C / Option A / P3.1 old retained references` 的第二轮 archive / compression 仍未统一处理。
- **Impact:** 旧 reference 仍可作为历史说明，但若长期不整理，会继续增加阅读噪音。
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
- BR / Rules: `BR-OPP-001_v0.2.5.md` — active BR baseline

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
- `UI_SPEC_v0.2.5.md` — active UI baseline

### PLAN / TEST
- `plan_v0.1.2.md` — retained implementation entry / historical reference

## 4) Latest Accepted Inputs

- `BR-OPP-001_v0.2.5.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.5.md`
- `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_4_PreviewReentry_and_StrongerBridge_Tech_Note_v0.1.md`
- `R3_P3_3_4_PreviewReentry_and_StrongerBridge_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_4_PreviewReentry_and_StrongerBridge_UI_Preflight_v0.1.md`
- `R1_to_R4_P3_3_4_Execution_Handoff_v0.1.md`
- user 最新转述：Room 4 已完成 `P3.3.4` 的开发 / 实施
- `Main_updated_2026-04-10_v24.md`
- `STATUS_updated_2026-04-10_v22.md`

## 5) Current Main-Thread Judgment

1. `P3.3.3` 继续保持 **closed / absorbed**。  
2. `P3.3.4` 当前已按 very narrow minimal-contract 范围完成开发 / 实施，并被 Room 1 吸收为 **closed / absorbed**。  
3. 本轮真正落地的是：StudyPage only 的 preview estimated hint，以及 stronger-but-still-non-blocking 的 ReviewPage bridge。  
4. ReviewPage / 首页继续不显示 preview；preview 仍不是计划事实，也不进入 active API / DB contract。  
5. 当前 active BR / UI baseline 继续保持 `BR-OPP-001_v0.2.5.md` 与 `UI_SPEC_v0.2.5.md`；下一治理动作应先补 P3.3.4 主文档 write-back，再拍板 `post-P3.3.4` 下一主题。

## 6) Next Actions (≤3)

1. **Owner:** Room 3 / Room 5  
   **ETA:** next round  
   **Done:** 将 `P3.3.4` 的已收口事实回写进新的 BR / UI 主文档候选。

2. **Owner:** Room 1 / User  
   **ETA:** after BR/UI write-back or next planning round  
   **Done:** 拍板 `post-P3.3.4` 的下一推进主题。

3. **Owner:** Room 1  
   **ETA:** after new BR/UI candidate arrives  
   **Done:** 视 write-back 结果决定是否升级 runtime active BR / UI baseline，并同步更新 Main / STATUS。
