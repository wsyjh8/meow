# OPP-001_STATUS.md
**Canonical Runtime Name:** `OPP-001_STATUS.md`  
**Project:** 背单词喵喵 App  
**Owner:** Room 1  
**Status:** active  
**Type:** 推进层 SSOT / Current-State Snapshot

---

## 0) Meta

- **Last updated:** 2026-04-10
- **Current Round:** Stage 4 P3.3.5 Closed / Next-Focus Pending
- **Current Focus:** `P3.3.5` 已按 Room 1 下发的 very narrow Phase 0 / Compatibility-Prep 范围完成开发 / 实施，并被吸收进主线程；当前第一优先级不再是“P3.3.5 能不能落地”，而是由 Room 1 / User 正式拍板 `post-P3.3.5` 的下一推进主题，并决定是否继续 owner-shift 方向的下一层 compatibility / migration / DB-API candidate round。

## 1) Current Stage

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.5 Closed / Next-Focus Pending
- **Status:** Active; P1 closed, P2 closed, Option A closed, Option A.1 closed, Option B closed, Option C closed, P3 closed, P3.1 closed, P3.3 overall closed, P3.3.2 closed, P3.3.3 closed, P3.3.4 closed, P3.3.5 closed

**Rationale**
- 当前 `Main / STATUS` 已经把 `P3.3.4` 写成 closed / absorbed，因此本轮不再把 `P3.3.4` 作为当前推进主题。
- `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md` 已把下一轮正式命名为 `P3.3.5 — Local Planner Owner Shift / Cloud Backup Rebase Round`，并通过 `R1_to_R4_P3_3_5_Execution_Handoff_v0.1.md` 将其压成 very narrow 的 `Phase 0 / Compatibility-Prep` execution layer。
- user 现已向 Room 1 转述：Room 4 已完成 `P3.3.5` 的开发 / 实施。
- 因此 Room 1 现可把当前推进状态正式写成 **P3.3.5 Closed / Next-Focus Pending**。
- 同时，BR / UI 主文档 write-back 已完成，当前 active BR / UI 入口应升级为 `BR-OPP-001_v0.2.6.md` 与 `UI_SPEC_v0.2.6.md`。
- 但本轮 closeout 只代表 `target-state + staged migration + backup/restore semantic rewrite + compatibility/deprecation/shadow-prep` 已完成当前轮吸收，不代表 runtime owner shift 已完成。

## 2) Gate Gaps (≤5)

### G-OPP-001-001
- **Gap:** `post-P3.3.5` 的下一轮 focus 尚未被 Room 1 / User 正式拍板。
- **Impact:** 当前可接受 P3.3.5 close，但项目若不及时 pin 新 focus，会再次进入“已关单、未起下一单”的推进真空。
- **Owner:** Room 1 / User
- **Priority:** Critical

### G-OPP-001-002
- **Gap:** 更深一层的 owner-shift / serving rewrite 仍保持 pending：runtime owner shift completed、ReviewPage local-serving cutover、`review_group` 真正退场、auto-routing runtime、unified planner / planner merge。
- **Impact:** P3.3.5 已把方向、边界、兼容 / 弃用、backup-rebase 与 shadow-prep 往前推一拍；若项目继续深化，必须单开下一轮，不可在当前 closeout 后静默扩写。
- **Owner:** Room 1 / Room 2 / Room 3 / Room 5
- **Priority:** High

### G-OPP-001-003
- **Gap:** DB / API active baselines 仍停留在 `v0.2.1`，尚未进入与 P3.3.5 staged migration / compatibility rewrite 对齐的下一层候选吸收。
- **Impact:** 当前 P3.3.5 允许 close，因为本轮明确未触碰 DB schema / API core semantics；但若下一轮继续 owner-shift 方向，Room 2 必须单开新的 DB / API candidate round，避免治理层与运行态再度脱节。
- **Owner:** Room 2 / Room 1
- **Priority:** High

### G-OPP-001-004
- **Gap:** `Option C / Option A / P3.1 / early P3.3 retained references` 的第二轮 archive / compression 仍未统一处理。
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
- BR / Rules: `BR-OPP-001_v0.2.6.md` — active BR baseline

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
- `UI_SPEC_v0.2.6.md` — active UI baseline

### PLAN / TEST
- `plan_v0.1.2.md` — retained implementation entry / historical reference

## 4) Latest Accepted Inputs

- `BR-OPP-001_v0.2.6.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.6.md`
- `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1.md`
- `R3_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_UI_Preflight_v0.1.md`
- `R1_to_R4_P3_3_5_Execution_Handoff_v0.1.md`
- `BR-OPP-001_v0.2.6.md` / `UI_SPEC_v0.2.6.md` — ready for Room 1 runtime-baseline update
- user 最新转述：Room 4 已完成 `P3.3.5` 的开发 / 实施
- `Main_updated_2026-04-10_v25.md`
- `STATUS_updated_2026-04-10_v23.md`

## 5) Current Main-Thread Judgment

1. `P3.3.4` 继续保持 **closed / absorbed**。  
2. `P3.3.5` 当前已按 very narrow `Phase 0 / Compatibility-Prep` 范围完成开发 / 实施，并被 Room 1 吸收为 **closed / absorbed**。  
3. 本轮真正落地的是：current runtime truth 保持不变、future target-state candidate 边界写硬、backup / restore / sync 三层语义重写、以及 `review_group` compatibility / deprecation + shadow / parity / regression prep。  
4. `local primary planner owner` 当前仍只是 **future target-state candidate**；ReviewPage current serving truth 仍围绕 cloud `review_group`，首页仍保持 `study_default`。  
5. 当前 active BR / UI baseline 已升级为 `BR-OPP-001_v0.2.6.md` 与 `UI_SPEC_v0.2.6.md`；DB / API baseline 继续保持 `v0.2.1`。  
6. 下一治理动作不是在 P3.3.5 内静默继续 owner shift，而是由 Room 1 / User 拍板 `post-P3.3.5` 下一轮主题；若继续此方向，则单开下一轮 compatibility / migration / DB-API candidate round。

## 6) Next Actions (≤3)

1. **Owner:** Room 1 / User  
   **ETA:** next round  
   **Done:** 拍板 `post-P3.3.5` 的下一推进主题，并明确是继续 owner-shift 方向的下一层 compatibility / migration / DB-API candidate round，还是切到别的产品主题。

2. **Owner:** Room 2  
   **ETA:** if owner-shift direction continues  
   **Done:** 给出下一轮 `DB / API compatibility + deprecation + migration candidate` 的范围、红线与 staged rollout 建议。

3. **Owner:** Room 1  
   **ETA:** after next-focus pin  
   **Done:** 按 user 拍板结果下发新的 scope pin / handoff，并同步更新 Main / STATUS 的 active focus 与 gate gaps。