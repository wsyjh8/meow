# OPP-001_STATUS.md
**Canonical Runtime Name:** `OPP-001_STATUS.md`  
**Project:** 背单词喵喵 App  
**Owner:** Room 1  
**Status:** active  
**Type:** 推进层 SSOT / Current-State Snapshot

---

## 0) Meta

- **Last updated:** 2026-04-10
- **Current Round:** Stage 4 P3.3.3 Closed / Next-Focus Pending
- **Current Focus:** `P3.3.3` 已按 Room 1 下发的 very narrow minimal-contract 范围完成开发 / 实施，并被吸收进主线程；当前第一优先级不再是“P3.3.3 能不能落地”，而是由 Room 1 / User 正式拍板 `post-P3.3.3` 的下一推进主题。

## 1) Current Stage

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.3 Closed / Next-Focus Pending
- **Status:** Active; P1 closed, P2 closed, Option A closed, Option A.1 closed, Option B closed, Option C closed, P3 closed, P3.1 closed, P3.3 overall closed, P3.3.2 closed, P3.3.3 closed

**Rationale**
- 当前 `Main / STATUS` 已经把 `P3.3.2` 写成 closed / absorbed，因此本轮不再把 `P3.3.2` 作为当前推进主题。
- `BR-OPP-001_v0.2.4.md` 与 `UI_SPEC_v0.2.4.md` 都已经完成主文件级回写，并已被 Room 1 吸收到当前 active baselines。
- Room 1 已按 `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md` 把下一轮正式命名为 `P3.3.3 — Review Planning Contract v1 / SRS Boundary Round`，并通过 `R1_to_R4_P3_3_3_Execution_Handoff_v0.1.md` 将其压成 very narrow execution layer。
- user 现已明确更正：Room 4 实际完成的是 `P3.3.3` 的开发 / 实施。
- 因此 Room 1 现可把当前推进状态正式写成 **P3.3.3 Closed / Next-Focus Pending**。

## 2) Gate Gaps (≤5)

### G-OPP-001-001
- **Gap:** `post-P3.3.3` 的下一轮 focus 尚未被 Room 1 / User 正式拍板。
- **Impact:** 当前可接受 P3.3.3 close，但项目若不及时 pin 新 focus，会再次进入“已关单、未起下一单”的推进真空。
- **Owner:** Room 1 / User
- **Priority:** Critical

### G-OPP-001-002
- **Gap:** 更深一层的 review planning 仍保持 pending：`previewDurations` re-entry、exact group size、full priority scoring、planner merge / unified planner。
- **Impact:** P3.3.3 已把最小合同层跑通，但项目若要继续深化 review planning，必须单开下一轮，不可在当前 closeout 后静默扩写。
- **Owner:** Room 1 / Room 2 / Room 3 / Room 5
- **Priority:** High

### G-OPP-001-003
- **Gap:** ReviewPage residual bridge issue 仍保留为后续技术议题。
- **Impact:** 当前不阻塞 P3.3.3 close，但若未来继续深化 planner convergence，仍需单开技术处理。
- **Owner:** Room 2 / Room 4
- **Priority:** Minor

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
- BR / Rules: `BR-OPP-001_v0.2.4.md` — active BR baseline

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
- `UI_SPEC_v0.2.4.md` — active UI baseline

### PLAN / TEST
- `plan_v0.1.2.md` — retained implementation entry / historical reference

## 4) Latest Accepted Inputs

- `BR-OPP-001_v0.2.4.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.4.md`
- `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md`
- `R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_3_ReviewPlanningContractV1_UI_Preflight_v0.1.md`
- `R1_to_R4_P3_3_3_Execution_Handoff_v0.1.md`
- user 最新更正：Room 4 已完成 `P3.3.3` 的开发 / 实施
- `Main_updated_2026-04-10_v22.md`
- `STATUS_updated_2026-04-10_v21.md`

## 5) Current Main-Thread Judgment

1. `P3.3.2` 继续保持 **closed / absorbed**。  
2. BR / UI 入口已同步追平到 `v0.2.4`，不再继续把 `v0.2.3` 作为当前主入口。  
3. `P3.3.3` 当前已按 very narrow minimal-contract 范围完成开发 / 实施，并被 Room 1 吸收为 **closed / absorbed**。  
4. `previewDurations` 继续保持 deferred，未在本轮被偷偷拉回 active contract / current UI truth。  
5. 当前最合理的推进方式，是由 Room 1 / User 正式拍板 `post-P3.3.3` 的下一推进主题。

## 6) Next Actions (≤3)

1. **Owner:** Room 1 / User  
   **ETA:** next round  
   **Done:** 拍板 `post-P3.3.3` 的下一推进主题。

2. **Owner:** Room 3 / Room 5  
   **ETA:** if needed  
   **Done:** 若本轮代码实现带来新的规则 / 页面现实细节，则补一轮主文档回写；否则维持 `v0.2.4` 不动。

3. **Owner:** Room 1  
   **ETA:** after next focus is pinned  
   **Done:** 按新的 focus 下发下一轮 scope pin / unified handoff。

