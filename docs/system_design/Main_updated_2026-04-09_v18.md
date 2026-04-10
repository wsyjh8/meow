# Main.md
**Canonical Runtime Name:** `OPP-001_MAIN.md`  
**Project:** 背单词喵喵 App  
**Owner:** Room 1  
**Status:** active  
**Type:** 推进层 SSOT / SSOT Main Thread

---

## 0) Meta

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.1 Overall Closed / Runtime Baseline Updated
- **Last updated:** 2026-04-09
- **Current versions (runtime active SSOT):**
  - **Governance / Runtime protocol**
    - ORG: `ORG_v0.3.1.md`
    - Project Rules Master: `PROJECT_RULES_MASTER_v0.3.1.md`
    - Room 1: `room1_v0.2.0.md`
    - Room 2: `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
    - Room 3: `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
    - Room 4: `ROOM04_治理版_v0.2`
    - Room 5: `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
    - BR / Rules: `BR-OPP-001_v0.2.1.md`
  - **Product / PRD**
    - 项目介绍书: `背单词养猫app项目介绍书_v0.1.1_P3.1.md`
    - 主机制 PRD: `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
    - 副机制设计稿: `背单词喵喵app_副机制设计稿_v_0.md`
    - 副机制 PRD: `背单词喵喵app_副机制prd_v_0.md`
  - **Numbers**
    - 副机制数值草案: `背单词喵喵app_副机制数值草案_v_0.md`
  - **DB / API**
    - DB 设计草案: `背单词喵喵app_DB设计草案_v0.2.1.md`
    - API 设计草案: `背单词喵喵app_API设计草案_v0.2.1.md`
  - **UI SPEC**
    - `UI_SPEC_v0.2.1.md` — current active UI baseline
  - **PLAN / TEST**
    - `plan_v0.1.2.md` — retained implementation entry / historical reference

- **Latest delivery / review / absorption inputs**
  - `BR-OPP-001_v0.2.1.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `UI_SPEC_v0.2.1.md`
  - `回p3_1_delta_p3.md`
  - `回p3_1_p4.md`
  - `Main_updated_2026-04-07_v17.md`
  - `STATUS_updated_2026-04-07_v16.md`

- **Links / Entrances**
  - ORG: `ORG_v0.3.1.md`
  - Room 1: `room1_v0.2.0.md`
  - Room 2: `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
  - Room 3: `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
  - Room 4: `ROOM04_治理版_v0.2`
  - Room 5: `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
  - BR: `BR-OPP-001_v0.2.1.md`
  - DB: `背单词喵喵app_DB设计草案_v0.2.1.md`
  - API: `背单词喵喵app_API设计草案_v0.2.1.md`
  - UI: `UI_SPEC_v0.2.1.md`

---

## 1) One-liner

面向**容易半途放弃背单词、但对可爱陪伴与轻养成有偏好的学习用户**，在**日常背词、复习、签到和碎片时间学习**场景下，解决**难开始、难坚持、反馈弱、长期留存低**的问题，通过**学习主机制 + 喵喵副机制承接**，带来**更高的打开率、完成率、复习率与长期陪伴式学习体验**；当前 `P3.1 — Local Progress + Cloud Backup` 的代码与 BR / DB / API / UI 文档已完成本轮对齐，Room 1 已将 runtime baseline 从旧 `v0.1.x` 正式提升到 `v0.2.1`。

---

## 2) Scope Snapshot

### 当前已完成
1. **P1：主机制最小可运行闭环**
2. **P2：副机制 MVP 承接闭环**
3. **Option A：Production Persistence Hardening**
4. **Option A.1：Post-Option-A Hardening**
5. **Option B（B1）：Visual Polish & Content Polish 第一轮**
6. **Option B2（B2-1 / B2-2 / B2-3）**
7. **Option C — Main Mechanism Enhancement**
8. **P3 — Main Mechanism Deepening**
9. **P3.1 — Local Progress + Cloud Backup**
   - local-first + manual backup / restore 边界已收口
   - `daily goal` 设置、手动上传、手动下载到本机三功能已交付
   - BR / DB / API / UI 文档已追平当前代码现实
   - Room 1 已完成 runtime-baseline update

### 当前仍不做
- full sync / real-time sync / multi-master merge
- background sync
- partial restore / snapshot picker
- delete backup / clear local / destructive actions bundle
- 多猫系统
- 好友互访 / 社交分享 / 排行榜
- 抽卡
- 强社交 Widget
- 复杂剧情任务
- 重 RPG / 重游戏玩法
- 复杂词书市场
- AI 教学 / AI 个性化主路径
- 高级桌面管理端

### 推进层 SSOT
- `Main.md`
- `STATUS.md`

---

## 3) Assumption Log

### A-OPP-001-001
- **Hypothesis:** 当前 MVP 采用“主机制优先，副机制承接”的推进顺序，能以更低复杂度跑通产品核心闭环。
- **Status:** active

### A-OPP-001-016
- **Hypothesis:** P3 可以在 contract-first deepening 的方式下完成当前轮主机制深化，并在不把 candidate contracts 偷写成 active truth、也不引入大重构的前提下正式 close。
- **Status:** passed on 2026-04-05

### A-OPP-001-017
- **Hypothesis:** 在不引入复杂实时同步、不把云端升级为运行态真相源的前提下，P3.1 可以先用 `local-first + simple backup` 的方式补齐本地进度与手动云备份能力。
- **Status:** passed on 2026-04-06

### A-OPP-001-018
- **Hypothesis:** P3.1 第一拍默认只做到 Phase 0–3（local truth + snapshot export + upload + latest backup status + 最小入口）即可形成可关单范围；Phase 4 restore 应保持 gated，只有 Room 1 单独 pin 后才可吸收到 active 范围。
- **Status:** superseded by direct-scope user decision on 2026-04-07

### A-OPP-001-019
- **Hypothesis:** User 直接拍板加入的三按钮 / 三功能，可以按一轮独立的 P3.1 delta round 收口，而不需要把 P3.1 整体扩写成 full sync platform。
- **Pass criteria:** Room 1 能正式接受 delta round close，同时守住 manual only / warning first / no fake sync / no history rewrite / no destructive bundle
- **Status:** passed on 2026-04-07

### A-OPP-001-020
- **Hypothesis:** 当 BR / DB / API / UI 都完成 reconciled baseline 并明确达到“ready for Room 1 review / runtime-baseline update”后，Room 1 可以把 P3.1 从“delta closed / baseline sync pending”推进到“overall closed / baseline updated”。
- **Pass criteria:** Room 1 能统一 pin 新 active versions，且不再需要以旧 `v0.1.x` 作为 runtime reference 继续推进
- **Status:** passed on 2026-04-09

---

## 4) Evidence Log

### E-OPP-001-061
- **Finding:** `R2_P3_1_LocalProgress_CloudBackup_Preflight_v0.1.1.md` 已明确结论：P3.1 当前应先新建 technical preflight，暂不直接改 active DB / API baseline。
- **Source:** P3.1 technical preflight
- **Date:** 2026-04-06

### E-OPP-001-062
- **Finding:** `R3_P3_1_LocalProgress_CloudBackup_Rules_Freeze_Note_v0.1.1.md` 已把 P3.1 收成 rules freeze input / review basis，并明确当前 active BR 仍然是 `BR-OPP-001_v0.1.7.md`。
- **Source:** P3.1 rules freeze note
- **Date:** 2026-04-06

### E-OPP-001-063
- **Finding:** `UI_SPEC_P3_1_LocalProgress_CloudBackup_v0.1.1.md` 已把 P3.1 的设置页 / 我的页 backup 能力翻译成 UI / UX 输入，并明确在 Room 1 吸收到 Main / STATUS 前不会自动替代 runtime baseline。
- **Source:** P3.1 UI / UX input
- **Date:** 2026-04-06

### E-OPP-001-064
- **Finding:** `背单词养猫app项目介绍书_v0.1.1_P3.1.md` 与 `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` 已把 P3.1 的 `local-first + simple cloud backup` 立场回写到产品入口与主机制 PRD。
- **Source:** 项目介绍书 / 主机制 PRD P3.1 sync patch
- **Date:** 2026-04-06

### E-OPP-001-065
- **Finding:** `R4_P3_1_LocalProgress_CloudBackup_Implementation_Plan_v0.1.1.md` 已把 P3.1 的默认执行路径写成 `local-first + backup-first + contract-gated execution`。
- **Source:** P3.1 implementation planning
- **Date:** 2026-04-06

### E-OPP-001-068
- **Finding:** `R1_P3_1_DirectScopePin_3Buttons_Handoff_Pack_v0.1.md` 已把“上传进度到云端 / 从云端下载进度到本机 / 设置每日学习单词数量”三功能正式拉进当前 P3.1 范围。
- **Source:** Room 1 direct-scope pin handoff
- **Date:** 2026-04-06

### E-OPP-001-069
- **Finding:** `R2_P3_1_DirectScopePin_Delta_Tech_Note_v0.1.1.md` 已把三功能收成最小技术 delta，明确 manual upload / manual download、latest snapshot apply first-shot、daily_goal 当天即时生效但不回溯历史日。
- **Source:** Room 2 delta tech note
- **Date:** 2026-04-06

### E-OPP-001-070
- **Finding:** `R3_P3_1_DirectScopePin_Delta_Rules_Note_v0.1.1.md` 已写硬 upload success / download success / restore success 三层语义边界、restore warning、daily_goal 当天生效与历史不回溯、destructive actions 不进本轮。
- **Source:** Room 3 delta rules note
- **Date:** 2026-04-06

### E-OPP-001-071
- **Finding:** `UI_SPEC_P3_1_DirectScopePin_Delta_v0.1.1.md` 已把三按钮 direct-scope delta 翻译成专项 UI / UX 输入，强调设置页 / 我的页承接、warning / confirm / success / failure / retry 状态矩阵，以及不把本轮做成同步系统。
- **Source:** Room 5 delta UI spec
- **Date:** 2026-04-07

### E-OPP-001-072
- **Finding:** `R4_P3_1_DirectScopePin_Delta_Execution_Note_v0.1.1.md` 已把三功能收成专项 delta execution note，并按 C→B→A（daily goal → upload → download）顺序组织实现与验证。
- **Source:** Room 4 delta execution note
- **Date:** 2026-04-07

### E-OPP-001-073
- **Finding:** `回p3_1_delta_p3.md` 已明确回传：P3.1 Delta Phase 3 完成，330 Flutter tests pass（25 new），0 analyze errors，且三功能均 enabled。
- **Source:** Room 4 delta close input
- **Date:** 2026-04-07

### E-OPP-001-074
- **Finding:** `BR-OPP-001_v0.2.1.md` 已形成 full merged BR baseline candidate，状态为 ready for Room 1 review / runtime-baseline update。
- **Source:** Room 3 reconciled BR baseline
- **Date:** 2026-04-08

### E-OPP-001-075
- **Finding:** `背单词喵喵app_DB设计草案_v0.2.1.md` 已形成 reconciled DB baseline candidate，明确吸收 code-truth reality + candidate contracts，并 ready for Room 1 review。
- **Source:** Room 2 reconciled DB baseline
- **Date:** 2026-04-08

### E-OPP-001-076
- **Finding:** `背单词喵喵app_API设计草案_v0.2.1.md` 已形成 reconciled API baseline candidate，明确吸收 code-truth reality + candidate contracts，并 ready for Room 1 review。
- **Source:** Room 2 reconciled API baseline
- **Date:** 2026-04-08

### E-OPP-001-077
- **Finding:** `UI_SPEC_v0.2.1.md` 已作为 user-approved absorption patch / ready for Room 1 runtime-baseline update，能作为新的 UI baseline candidate。
- **Source:** Room 5 absorbed UI baseline
- **Date:** 2026-04-09

### E-OPP-001-078
- **Finding:** 新一轮治理层文件已齐：`ORG_v0.3.1.md`、`ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`、`ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`、`ROOM04_治理版_v0.2`、`ROOM05_ROLE_CARD_UI_UX_v0.2.1`，足够支撑 runtime active versions 升级。
- **Source:** Governance file set
- **Date:** 2026-04-09

---

## 5) Decision Log

### D-OPP-001-049
- **Decision:** 在 P3 与 P4 之间临时插入一个中间阶段：`P3.1 — Local Progress + Cloud Backup`。
- **Approver:** Room 1

### D-OPP-001-050
- **Decision:** 将 `背单词养猫app项目介绍书_v0.1.1_P3.1.md` 与 `背单词喵喵app_主机制prd_v0.3.1_P3.1.md` pin 为当前 P3.1 产品 / PRD 基线。
- **Approver:** Room 1

### D-OPP-001-051
- **Decision:** 将 `ORG_v0.3.0.md`、`room1_v0.2.0.md`、`room2_v0.2.0.md`、`ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.0.md`、`room4_v0.2.0.md`、`room5_v0.2.0.md` pin 为当前 active governance / role-card baseline。
- **Approver:** Room 1

### D-OPP-001-052
- **Decision:** Room 1 接受 `R2_P3_1_LocalProgress_CloudBackup_Preflight_v0.1.1.md` 作为当前 P3.1 的技术入口依据，但不直接改 active DB / API baseline。
- **Approver:** Room 1

### D-OPP-001-053
- **Decision:** Room 1 接受 `R3_P3_1_LocalProgress_CloudBackup_Rules_Freeze_Note_v0.1.1.md` 作为当前 P3.1 的 rules freeze input / review basis，但不直接改 active BR baseline。
- **Approver:** Room 1

### D-OPP-001-054
- **Decision:** Room 1 接受 `UI_SPEC_P3_1_LocalProgress_CloudBackup_v0.1.1.md` 并将其 pin 为当前 P3.1 backup lane 的 UI / UX baseline reference。
- **Approver:** Room 1

### D-OPP-001-055
- **Decision:** Room 1 接受 `R4_P3_1_LocalProgress_CloudBackup_Implementation_Plan_v0.1.1.md` 与 `p3.1_phases.md` 作为当前 P3.1 的实施参考。
- **Approver:** Room 1

### D-OPP-001-056
- **Decision:** `回p3_1_p4.md` 只作为“Room 4 已交付 Phase 4 restore candidate”被吸收进主线程；不自动等同于 P3.1 close accepted。
- **Approver:** Room 1

### D-OPP-001-057
- **Decision:** User 直接拍板新增三按钮 / 三功能，Room 1 正式将其写为 `P3.1 direct-scope pin delta` 当前范围：
  1. 从云端下载进度到本机
  2. 上传进度到云端
  3. 设置每日学习单词数量
- **Approver:** User via Room 1

### D-OPP-001-058
- **Decision:** Room 1 接受 `R2_P3_1_DirectScopePin_Delta_Tech_Note_v0.1.1.md`、`R3_P3_1_DirectScopePin_Delta_Rules_Note_v0.1.1.md`、`UI_SPEC_P3_1_DirectScopePin_Delta_v0.1.1.md`、`R4_P3_1_DirectScopePin_Delta_Execution_Note_v0.1.1.md` 作为当前 delta round 的技术 / 规则 / UI / 执行参考。
- **Approver:** Room 1

### D-OPP-001-059
- **Decision:** Room 1 接受 `回p3_1_delta_p3.md` 的 close 结论，确认 **P3.1 direct-scope delta round** 已正式完成并可 close。
- **Why:** Room 4 已完成三功能交付；330 Flutter tests pass（25 new）；0 analyze errors；manual only / warning first / no fake sync / no destructive bundle / no history rewrite 边界守住。
- **Approver:** Room 1

### D-OPP-001-060
- **Decision:** Room 1 接受 `BR-OPP-001_v0.2.1.md` 作为新的 BR full merged baseline，并将其 pin 为 runtime active BR baseline。
- **Why:** BR 已从旧 `v0.1.7` 的 direct-patch / retained-reference 形态收敛为 single-file merged baseline candidate，足够支撑运行态更新。
- **Approver:** Room 1

### D-OPP-001-061
- **Decision:** Room 1 接受 `背单词喵喵app_DB设计草案_v0.2.1.md` 与 `背单词喵喵app_API设计草案_v0.2.1.md`，并将其 pin 为新的 runtime active DB / API baselines。
- **Why:** Room 2 已把 code-truth implemented reality 与 candidate contracts 做 reconciled baseline 收口，足以替代旧 `v0.1.4 / v0.1.3` 作为当前开发维护入口。
- **Approver:** Room 1

### D-OPP-001-062
- **Decision:** Room 1 接受 `UI_SPEC_v0.2.1.md` 作为新的 runtime active UI baseline。
- **Why:** Room 5 已把代码现实、旧版 retained references 与当前 UI 事实压缩成单文件 absorbed baseline candidate，并明确 ready for runtime-baseline update。
- **Approver:** Room 1

### D-OPP-001-063
- **Decision:** Room 1 将治理层 active versions 升级为 `ORG_v0.3.1` + Room2 `v0.2.1` + Room3 `v0.3.1` + Room4-治理 `v0.2` + Room5 `v0.2.1`。
- **Why:** 现有治理层文件集已经完成本轮升级，足以替代旧治理版本作为当前项目协作依据。
- **Approver:** Room 1

### D-OPP-001-064
- **Decision:** Room 1 判定：在 BR / DB / API / UI 完成 runtime-baseline update 后，`P3.1 — Local Progress + Cloud Backup` 整体达到 **overall closed**。
- **Why:** 当前轮最主要的 gate gap 是“文档未追上代码 / baseline 未更新”；该问题现已完成治理层与推进层收口。
- **Approver:** Room 1

---

## 6) Gate Gaps (for MAIN reference)

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

---

## 7) Next Actions (must include owner + done)

1. **Owner=Room 1 / User | ETA=Next round | Done=拍板 post-P3.1 的下一产品方向命名与范围 | Action=让主线程从“已收口”进入下一阶段 handoff**

2. **Owner=Room 1 | ETA=After next direction pin | Done=更新 archive / retained-reference 处理策略，清理 `v0.1.x` 旧入口噪音 | Action=让 runtime active entry 更干净**

3. **Owner=Room 1 / Room 5 | ETA=Later | Done=决定是否对 Option B 做专项 write-back / compression 审计 | Action=补齐历史阶段资产治理**

---

## 8) Notes (≤5 lines)

- 当前最重要的新事实是：**P3.1 已整体 close，且 runtime baselines 已提升到 `v0.2.1`。**
- 旧 `v0.1.x` 的 BR / DB / API / retained UI refs 不再是当前 active 入口。
- 本轮 close 仍不等于 full sync / merge / destructive actions 已进入范围。
- 下一治理动作不再是“让文档追代码”，而是 **决定下一产品方向**。
- 旧阶段 reference 仍可保留，但应从 active front-row 退场。

---

## 9) Working Rule

> **Main 现在必须反映真实主线程：P1 / P2 / Option A / Option A.1 / Option B / Option C / P3 / P3.1 均已 close；当前 runtime active baselines 已更新为 BR / DB / API / UI `v0.2.1` 与新治理层版本。下一步不是继续补 P3.1 文档，而是由 Room 1 / User 正式拍板 post-P3.1 的下一产品方向。**
