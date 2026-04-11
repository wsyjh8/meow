# OPP-001_STATUS.md
**Canonical Runtime Name:** `OPP-001_STATUS.md`  
**Project:** 背单词喵喵 App  
**Owner:** Room 1  
**Status:** active  
**Type:** 推进层 SSOT / Current-State Snapshot

---

## 0) Meta

- **Last updated:** 2026-04-10
- **Current Round:** Stage 4 P3.3 First Pass Closed / Next-Focus Pending
- **Current Focus:** P3.3 第一拍已完成收口并通过 Room4-治理验收。当前第一优先级不再是让文档追代码，也不是回退到 P3.1，而是由 Room 1 / User 正式拍板 P3.3 第二拍 focus。

---

## 1) Current Stage

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3 First Pass Closed / Next-Focus Pending
- **Status:** Active; P1 closed, P2 closed, Option A closed, Option A.1 closed, Option B closed, Option C closed, P3 closed, P3.1 closed, P3.3 first pass closed

**Rationale**
- P3.1 已整体 close，且 BR / DB / API / UI runtime baselines 已切到 `v0.2.1`。
- 在此基础上，Room 1 已通过 `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md` 正式将下一方向命名为 `P3.3 — Home Entry + FSRS 4-Button + Review Planning`。
- Room 5 已把首页“背单词”入口、学习/复习页 4 按钮布局、两字中文候选与页面承接关系收成 preflight UI input。
- Room 3 已冻结本轮最小规则边界：4 按钮本质是 rating input、必须与 FSRS 四档保持单调映射；两字中文要求冻结，但最终词面仍是 candidate。
- Room 4 已完成第一拍实现与测试：首页“背单词”入口、Study/Review 4 按钮接入、最小 submit / throttle / bridge 已通过；同时明确 **未触碰 DB schema / API 核心语义 / 奖励结算主链路 / review_group 最小合同**。
- 因此，Room 1 现在可以把 P3.3 当前状态写为：**First Pass Closed / Next-Focus Pending**。

## 2) Gate Gaps (≤5)

### G-OPP-001-001
- **Gap:** P3.3 第一拍虽然已收口，但 **下一轮 focus** 尚未被 Room 1 / User 正式拍板。
- **Impact:** 当前能吸收 first-pass closeout，但不能直接进入第二拍执行。
- **Owner:** Room 1 / User
- **Priority:** Critical

### G-OPP-001-002
- **Gap:** P3.3 的最终两字中文词面仍为 candidate，尚未完成 Room 3 + Room 5 + Room 1 的最终 freeze。
- **Impact:** 当前 4 按钮可继续以 candidate wording 运行，但不适合立即回写成新的 active BR / UI copy baseline。
- **Owner:** Room 1 / Room 3 / Room 5
- **Priority:** Major

### G-OPP-001-003
- **Gap:** `previewDurations` 仍为 deferred，尚未进入当前轮实现。
- **Impact:** 不阻塞第一拍 close，但会影响 4 按钮与 FSRS 间的即时可解释性。
- **Owner:** Room 4 / Room 2 / Room 5
- **Priority:** Major

### G-OPP-001-004
- **Gap:** ReviewPage FSRS bridge 当前仍为 best-effort，尚未由 Room 2 / Room 3 / Room 1 决定是否需要更强 contract。
- **Impact:** 当前不阻塞 review_group 主链路，但会影响后续本地 FSRS 与云端 review_group 的长期一致性策略。
- **Owner:** Room 1 / Room 2 / Room 3
- **Priority:** Major

### G-OPP-001-005
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

1. Room 1 已确认：当前主线程不再是 “P3.1 文档要不要继续追代码”，也不是“P3.3 第一拍能不能过”，因为 **第一拍已经收口并被接受**。
2. 当前真正主线程是：
   - P3.1 已整体 close
   - P3.3 第一拍已 close
   - 首页“背单词”入口、Study/Review 4 按钮、最小 submit / throttle / bridge 已进入当前代码现实
   - 当前最需要的不是继续补第一拍材料，而是 **拍板 P3.3 第二拍 focus**
3. 当前仍保留的后续治理问题：
   - 最终两字中文词面 freeze
   - `previewDurations` 是否进入第二拍
   - ReviewPage FSRS bridge 是否继续 best-effort 或需要更强 contract
   - 历史 reference 清理

## 5) Current Risks

1. **Focus vacuum risk**：如果 P3.3 第二拍 focus 不及时拍板，项目会停在“第一拍已通过，但第二拍没人定”的悬挂状态。
2. **Candidate wording drift risk**：若最终两字中文词面长期不冻结，UI / 规则 / 实现会继续以 candidate wording 并存。
3. **Bridge ambiguity risk**：ReviewPage FSRS bridge 若长期保持 best-effort 而不进一步裁定，会影响未来本地 FSRS 与云端 review_group 的一致性解释。
4. **Deferred clarity risk**：`previewDurations` 长期 deferred，会让 4 按钮输入与“为什么这样排程”之间的解释链仍偏弱。
5. **Reference clutter risk**：旧 `v0.1.x` retained references 若不清理，会继续增加阅读噪音。

## 6) Next Actions (≤3; must include Done)

1. **Owner=Room 1 / User | ETA=Next round | Done=拍板 P3.3 第二拍 focus（中文词面 / previewDurations / stronger bridge 三选一或组合） | Action=让 P3.3 从 first-pass close 进入第二拍**

2. **Owner=Room 3 / Room 5 | ETA=After next focus pin | Done=若 focus 包含词面冻结，则提交 4 按钮最终两字中文定稿与 UI/BR sync patch | Action=关闭当前 candidate wording 悬挂**

3. **Owner=Room 1 | ETA=Later | Done=更新 archive / retained-reference 处理策略，清理 `v0.1.x` 旧入口噪音 | Action=让 runtime active entry 更干净**

## 7) Notes (≤5 lines)

- 当前最重要的新事实是：**P3.3 第一拍已通过 Room4-治理验收，并被 Room 1 接受收口。**
- 本轮只吸收：首页“背单词”入口 + Study/Review 4 按钮 + 最小 submit / throttle / bridge。
- 本轮没有触碰 DB schema / API 核心语义 / 奖励结算主链路 / `review_group` 最小合同。
- P3.3 当前状态是 **First Pass Closed / Next-Focus Pending**，不是整体 fully closed。
- 下一治理动作是 **拍板 P3.3 第二拍 focus**。

## 8) One-line Working Rule

> **STATUS 只记录当前真实推进状态：现在 P1 / P2 / Option A / Option A.1 / Option B / Option C / P3 / P3.1 均已 close；P3.3 已完成第一拍收口，但当前只关闭到“首页背单词入口 + Study/Review 4 按钮 + 最小 submit / throttle / bridge”这一层；下一步不是回退到 P3.1，而是由 Room 1 / User 正式拍板 P3.3 第二拍 focus。**