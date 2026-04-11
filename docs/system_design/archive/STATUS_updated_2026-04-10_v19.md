# OPP-001_STATUS.md
**Canonical Runtime Name:** `OPP-001_STATUS.md`  
**Project:** 背单词喵喵 App  
**Owner:** Room 1  
**Status:** active  
**Type:** 推进层 SSOT / Current-State Snapshot

---

## 0) Meta

- **Last updated:** 2026-04-10
- **Current Round:** Stage 4 P3.3 Overall Closed / Next-Focus Pending
- **Current Focus:** `P3.3.1` 已完成收尾 / 体验补强并被 Room 1 接受 closeout。当前第一优先级不再是“P3.3.1 能不能过”，而是由 Room 1 / User 正式拍板 `post-P3.3` 的下一推进主题。

---

## 1) Current Stage

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3 Overall Closed / Next-Focus Pending
- **Status:** Active; P1 closed, P2 closed, Option A closed, Option A.1 closed, Option B closed, Option C closed, P3 closed, P3.1 closed, P3.3 overall closed

**Rationale**
- P3.1 已整体 close，且 BR / DB / API runtime baselines 继续保持在 `v0.2.1`；P3.3 第一拍 closeout 已由 `BR-OPP-001_v0.2.2.md` 与 `UI_SPEC_v0.2.2.md` 吸收。
- Room 1 已通过 `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md` 把第二拍正式命名为 `P3.3.1 — 收尾 / 体验补强`，并将最终词面、`previewDurations`、ReviewPage bridge 与 UI / 文案 / 测试补强收成统一入口。
- Room 1 又通过 `R1_to_R4_P3_3_1_Execution_Handoff_v0.1.md` 正式冻结本轮核心结论：最终词面 = 不认识 / 模糊 / 记得 / 秒答；`previewDurations` = deferred；ReviewPage bridge = controlled best-effort。
- Room 4 最新交付已证明：2×2 固定顺序已落地，ReviewPage bridge 已从 silent 提升到 controlled best-effort，fallback 对 dev / test 可观察，且未触碰 DB schema / API 核心语义 / 奖励结算主链路 / `review_group` 最小合同 / planner owner。
- 因此，Room 1 现在可以把 P3.3 当前状态写为：**Overall Closed / Next-Focus Pending**。

## 2) Gate Gaps (≤5)

### G-OPP-001-001
- **Gap:** `post-P3.3` 的下一轮 focus 尚未被 Room 1 / User 正式拍板。
- **Impact:** 当前可接受 P3.3 overall close，但项目若不及时 pin 新 focus，会进入“已关单、未起下一单”的推进真空。
- **Owner:** Room 1 / User
- **Priority:** Critical

### G-OPP-001-002
- **Gap:** 当前 P3.3 closeout 的 BR / UI 运行态口径，仍由 `v0.2.2` 主文档 + `P3.3.1 delta reference` 共同承载，尚未合并成 single-file merged baseline。
- **Impact:** 不阻塞当前开发与维护，但会增加后续阅读与引用成本。
- **Owner:** Room 1 / Room 3 / Room 5
- **Priority:** Minor

### G-OPP-001-003
- **Gap:** ReviewPage 本地 card 初始化路径仍存在 residual technical reality：未先经过 StudyPage 时，bridge miss 已减少但未被彻底消除。
- **Impact:** 当前已被 controlled best-effort 吸收，不阻塞 close；但若未来继续深化本地 FSRS 与云端 review_group 收敛，仍需作为后续技术议题处理。
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
- BR / Rules: `BR-OPP-001_v0.2.2.md` — active BR baseline
- BR delta reference: `R3_P3_3_1_Final_Wording_and_Bridge_Rules_Note_v0.1.md` — active wording / bridge delta reference

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
- `UI_SPEC_v0.2.2.md` — active UI baseline
- `UI_SPEC_P3_3_1_Copy_Polish_and_PreviewDurations_Delta_v0.1.1.md` — active UI delta reference

### PLAN / TEST
- `plan_v0.1.2.md` — retained implementation entry / historical reference

### Latest delivery / review / absorption inputs
- `BR-OPP-001_v0.2.2.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.2.md`
- `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md`
- `R2_P3_3_1_PreviewDurations_and_FSRS_Bridge_Tech_Note_v0.1.md`
- `R3_P3_3_1_Final_Wording_and_Bridge_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_1_Copy_Polish_and_PreviewDurations_Delta_v0.1.1.md`
- `R1_to_R4_P3_3_1_Execution_Handoff_v0.1.md`
- `P3.3.1_Claude_res.md`

## 4) Current Focus

1. Room 1 已确认：当前主线程不再是 “P3.3.1 能不能过”，因为 **P3.3.1 已完成并被接受 closeout**。
2. 当前真正主线程是：
   - P3.1 已整体 close
   - P3.3 已通过 P3.3.1 完成整体收口
   - 最终词面 freeze、`previewDurations` defer、ReviewPage bridge = controlled best-effort 已进入当前 runtime 真实口径
   - 当前最需要的不是继续补 P3.3.1，而是 **拍板 `post-P3.3` 的下一推进主题**
3. 当前仍保留的后续治理问题：
   - 是否需要把 BR / UI 的 `v0.2.2 + delta reference` 合并为 single-file merged baselines
   - 是否将 residual bridge issue 升级为未来技术 round
   - 历史 reference 清理

## 5) Current Risks

1. **Focus vacuum risk**：如果 `post-P3.3` 的下一轮 focus 不及时拍板，项目会停在“当前 round 已关单，但下一 round 未定义”的悬挂状态。
2. **Delta-reference split risk**：若长期保持 `BR/UI 主文档 + P3.3.1 delta reference` 双入口而不做合并，后续引用成本会上升。
3. **Residual bridge issue risk**：ReviewPage 本地 card 初始化路径的 residual issue 若长期不追踪，未来深化本地 FSRS 与云端 review_group 收敛时，仍可能再次放大解释成本。
4. **Reference clutter risk**：旧 `v0.1.x` retained references 若不清理，会继续增加阅读噪音。

## 6) Next Actions (≤3; must include Done)

1. **Owner=Room 1 / User | ETA=Next round | Done=拍板 `post-P3.3` 的下一轮 focus，并明确是否进入新的产品 / 技术 / 文档治理 round | Action=让项目从 “P3.3 已 overall close” 平滑切到下一推进主题**

2. **Owner=Room 1 / Room 3 / Room 5 | ETA=Later | Done=若需要更干净 runtime 入口，则产出 BR / UI 的下一版 single-file merged baselines，吸收当前 `v0.2.2 + P3.3.1 delta` 口径 | Action=降低后续引用成本**

3. **Owner=Room 1 | ETA=Later | Done=更新 archive / retained-reference 处理策略，清理 `v0.1.x` 旧入口噪音 | Action=让 runtime active entry 更干净**

## 7) Notes (≤5 lines)

- 当前最重要的新事实是：**`P3.3.1` 已实施完成，且 Room 1 已接受 closeout。**
- P3.3 当前状态已从 **First Pass Closed / Next-Focus Pending** 升级为 **overall closed**。
- 当前 runtime 真实口径包括：最终词面 freeze、`previewDurations` deferred、ReviewPage bridge = controlled best-effort。
- 本轮仍未触碰 DB schema / API 核心语义 / 奖励结算主链路 / `review_group` 最小合同 / planner owner。
- 下一治理动作是 **拍板 `post-P3.3` 下一轮 focus**，不是继续在 P3.3.1 内打补丁。

## 8) One-line Working Rule

> **STATUS 只记录当前真实推进状态：现在 P1 / P2 / Option A / Option A.1 / Option B / Option C / P3 / P3.1 / P3.3 均已 close；其中 P3.3 已通过 `P3.3.1` 完成收尾补强并整体关单。下一步不是继续补 P3.3.1，而是由 Room 1 / User 明确 pin `post-P3.3` 的下一推进主题。**
