# OPP-001_STATUS.md
**Canonical Runtime Name:** `OPP-001_STATUS.md`  
**Project:** 背单词喵喵 App  
**Owner:** Room 1  
**Status:** active  
**Type:** 推进层 SSOT / Current-State Snapshot

---

## 0) Meta

- **Last updated:** 2026-04-09
- **Current Round:** Stage 4 P3.1 Overall Closed / Runtime Baseline Updated
- **Current Focus:** P3.1 的代码与 BR / DB / API / UI 文档已经对齐，Room 1 已完成 runtime-baseline update。当前第一优先级不再是追文档，而是拍板 post-P3.1 的下一产品方向，并决定旧 `v0.1.x` retained references 的清理策略。

---

## 1) Current Stage

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.1 Overall Closed / Runtime Baseline Updated
- **Status:** Active; P1 closed, P2 closed, Option A closed, Option A.1 closed, Option B closed, Option C closed, P3 closed, P3.1 closed

**Rationale**
- 旧的推进层口径仍停在：`P3.1 active / delta round closed / baseline sync pending`。
- 现在 Room 2、Room 3、Room 5 都已把文档追到代码现实：
  - `BR-OPP-001_v0.2.1.md` = full merged BR baseline candidate / ready for Room 1 review
  - `背单词喵喵app_DB设计草案_v0.2.1.md` = reconciled DB baseline candidate / ready for Room 1 review
  - `背单词喵喵app_API设计草案_v0.2.1.md` = reconciled API baseline candidate / ready for Room 1 review
  - `UI_SPEC_v0.2.1.md` = user-approved absorption patch / ready for Room 1 runtime-baseline update
- 因此 Room 1 已完成本轮最主要治理动作：
  1. 将 runtime active BR 从 `v0.1.7` 提升到 `v0.2.1`
  2. 将 runtime active DB / API 从 `v0.1.4 / v0.1.3` 提升到 `v0.2.1 / v0.2.1`
  3. 将 runtime active UI baseline 切到 `UI_SPEC_v0.2.1.md`
  4. 判定 `P3.1 — Local Progress + Cloud Backup` 已整体 close

## 2) Gate Gaps (≤5)

### G-OPP-001-001
- **Gap:** post-P3.1 的下一产品方向尚未由 Room 1 / User 正式命名与拍板。
- **Impact:** 当前 P3.1 已整体 close，但下一阶段尚未进入正式 handoff。
- **Owner:** Room 1 / User
- **Priority:** Critical

### G-OPP-001-002
- **Gap:** `Option C / Option A / P3.1 old retained references` 是否做第二轮 archive / compression，尚未统一处理。
- **Impact:** 旧 reference 仍可作为历史说明，但若长期不整理，会增加阅读噪音。
- **Owner:** Room 1
- **Priority:** Major

### G-OPP-001-003
- **Gap:** `Option B` 是否仍存在专项 write-back / baseline-compression 需求，尚未做 targeted audit。
- **Impact:** 当前不阻塞 P3.1 close，但会影响历史阶段资产清理。
- **Owner:** Room 1 / Room 5
- **Priority:** Minor

### G-OPP-001-004
- **Gap:** `companion_response` typing 与 `source_fact_tags` 仍为 candidate backlog。
- **Impact:** 不阻塞当前 close，但可能影响未来 secondary cleanup / analytics clarity。
- **Owner:** Room 1 / Room 2 / Room 3 / Room 5
- **Priority:** Minor

### G-OPP-001-005
- **Gap:** `learning_days` 历史计数仍可能存在非阻塞完整性风险。
- **Impact:** 不阻塞当前主线程，但会影响未来统计深化阶段可信度。
- **Owner:** Room 4 / Room 2
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
- BR / Rules: `BR-OPP-001_v0.2.1.md` — active BR baseline

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
- `UI_SPEC_v0.2.1.md` — active UI baseline

### PLAN / TEST
- `plan_v0.1.2.md` — retained implementation entry / historical reference

### Latest delivery / review / absorption inputs
- `BR-OPP-001_v0.2.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.1.md`
- `回p3_1_delta_p3.md`
- `回p3_1_p4.md`

## 4) Current Focus

1. Room 1 已确认：当前主线程不再是 “P3.1 文档要不要继续追代码”，因为 **文档已追平代码，runtime baselines 已更新**。
2. 当前真正主线程是：
   - P3.1 已整体 close
   - 当前 active BR / DB / API / UI baseline 已切到 `v0.2.1`
   - 当前治理层 active versions 也已升级到 ORG `v0.3.1` + Room2 `v0.2.1` + Room3 `v0.3.1` + Room4-治理 `v0.2` + Room5 `v0.2.1`
   - 当前最需要的不是再补文档，而是 **决定下一阶段方向**
3. 当前仍保留的后续治理问题：
   - 历史 reference 清理
   - Option B targeted audit
   - minor backlog（`companion_response` / `source_fact_tags` / `learning_days`）

## 5) Current Risks

1. **Direction vacuum risk**：如果 post-P3.1 的下一产品方向不及时拍板，项目会在“已经收口但未开新阶段”的状态悬挂。
2. **Reference clutter risk**：如果旧 `v0.1.x` retained references 长期不清理，会增加 Room 2 / Room 4 / Room 5 的阅读噪音。
3. **Historical audit drift risk**：Option B 若一直不做 targeted audit，历史阶段资产会继续处于“可能还有尾巴但没人确认”的状态。
4. **Analytics clarity risk**：`companion_response` / `source_fact_tags` 若长期不收口，会影响 secondary analytics / logging clarity。
5. **Stats credibility risk**：`learning_days` 历史计数问题若长期搁置，会影响未来统计页可信度。

## 6) Next Actions (≤3; must include Done)

1. **Owner=Room 1 / User | ETA=Next round | Done=拍板 post-P3.1 的下一产品方向命名与范围 | Action=让主线程从“已收口”进入下一阶段 handoff**

2. **Owner=Room 1 | ETA=After next direction pin | Done=更新 archive / retained-reference 处理策略，清理 `v0.1.x` 旧入口噪音 | Action=让 runtime active entry 更干净**

3. **Owner=Room 1 / Room 5 | ETA=Later | Done=决定是否对 Option B 做专项 write-back / compression 审计 | Action=补齐历史阶段资产治理**

## 7) Notes (≤5 lines)

- 当前最重要的新事实是：**P3.1 已整体 close，且 runtime baselines 已提升到 `v0.2.1`。**
- 旧 `v0.1.x` 的 BR / DB / API / retained UI refs 不再是当前 active 入口。
- 本轮 close 仍不等于 full sync / merge / destructive actions 已进入范围。
- 下一治理动作不再是“让文档追代码”，而是 **决定下一产品方向**。
- 旧阶段 reference 仍可保留，但应从 active front-row 退场。

## 8) One-line Working Rule

> **STATUS 只记录当前真实推进状态：现在 P1 / P2 / Option A / Option A.1 / Option B / Option C / P3 / P3.1 均已 close；当前 runtime active baselines 已更新为 BR / DB / API / UI `v0.2.1` 与新治理层版本；下一步不是继续补 P3.1 文档，而是由 Room 1 / User 正式拍板 post-P3.1 的下一产品方向。**
