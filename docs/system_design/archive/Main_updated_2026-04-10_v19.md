# Main.md
**Canonical Runtime Name:** `OPP-001_MAIN.md`  
**Project:** 背单词喵喵 App  
**Owner:** Room 1  
**Status:** active  
**Type:** 推进层 SSOT / SSOT Main Thread

---

## 0) Meta

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3 First Pass Closed / Next-Focus Pending
- **Last updated:** 2026-04-10
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

面向**容易半途放弃背单词、但对可爱陪伴与轻养成有偏好的学习用户**，在**日常背词、复习、签到和碎片时间学习**场景下，解决**难开始、难坚持、反馈弱、长期留存低**的问题，通过**学习主机制 + 喵喵副机制承接**，带来**更高的打开率、完成率、复习率与长期陪伴式学习体验**；当前 `P3.1 — Local Progress + Cloud Backup` 的代码与 BR / DB / API / UI 文档已完成本轮对齐，Room 1 已将 runtime baseline 从旧 `v0.1.x` 正式提升到 `v0.2.1`；在此基础上，`P3.3` 已完成第一拍：首页“背单词”主入口 + Study/Review 4 按钮接入 + 最小 submit / throttle / FSRS bridge 已通过 Room4-治理验收。

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
10. **P3.3 — Home Entry + FSRS 4-Button + Review Planning（First Pass）**
   - 首页“背单词”主入口已接入
   - Study / Review 已接入 4 按钮 rating input
   - 最小 submit / throttle / bridge 已接入
   - 未触碰 DB schema / API 核心语义 / 奖励结算主链路 / `review_group` 最小合同
   - 第一拍已通过 Room4-治理验收，可作为本轮 closeout 被吸收

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

### E-OPP-001-079
- **Finding:** `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md` 已把 post-P3.1 的下一方向正式命名为 `P3.3 Preflight / Scope Pin`，并将 user 直接拍板的 3 项内容收进主线程：首页“背单词”入口、FSRS 4 按钮接入、复习规划进入第一轮 preflight。
- **Source:** Room 1 P3.3 scope pin handoff
- **Date:** 2026-04-09

### E-OPP-001-080
- **Finding:** `UI_SPEC_P3_3_HomeEntry_and_4Button_UI_Preflight_v0.1.1.md` 已把首页“背单词”主入口、学习/复习页 4 按钮布局、两字中文候选与页面承接关系收成 UI preflight，并明确当前仍不得把最终词面或最终业务语义写死。
- **Source:** Room 5 P3.3 UI preflight
- **Date:** 2026-04-09

### E-OPP-001-081
- **Finding:** `R3_P3_3_FSRS_4Button_ReviewPlanning_Rules_Note_v0.1.md` 已冻结 P3.3 本轮最小规则边界：4 按钮本质是 rating input、必须与 FSRS 四档保持单调映射；“两字中文要求”冻结，但最终词面仍保持 candidate；“开始做复习规划”只冻结到 preflight 边界。
- **Source:** Room 3 P3.3 rules note
- **Date:** 2026-04-09

### E-OPP-001-082
- **Finding:** Room 4 的 P3.3 第一拍材料已证明：本轮实现只触碰首页主入口、Study/Review 4 按钮接入、最小 submit / throttle / bridge；并明确 **API schema 不扩展、`review_group` 仍是 ReviewPage 云端 truth layer、云端 binary mapping 保持不变**。
- **Source:** `R4_P3_3_Impact_Map_v0.1.md` + `R4_P3_3_Submit_Flow_Draft_v0.1.md`
- **Date:** 2026-04-10

### E-OPP-001-083
- **Finding:** Room 4 的 P3.3 测试草案已覆盖：首页入口可见与跳转、Study/Review 4 按钮顺序、submit throttle、review_group continuation、FSRS bridge failure non-blocking、以及“不误报已掌握 / 已完成 / 奖励到账”等 false-success 边界。
- **Source:** `R4_P3_3_Test_Draft_v0.1.md`
- **Date:** 2026-04-10


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

### D-OPP-001-065
- **Decision:** Room 1 接受 `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`，并正式将 post-P3.1 的下一推进主题命名为 `P3.3 — Home Entry + FSRS 4-Button + Review Planning`。
- **Why:** `G-OPP-001-001` 所对应的“下一产品方向真空”已被 user 直接拍板关闭；需要把该决定写入主线程并作为 P3.3 的正式入口。
- **Approver:** Room 1 / User

### D-OPP-001-066
- **Decision:** Room 1 接受 P3.3 第一拍 closeout：首页“背单词”主入口 + Study/Review 4 按钮接入 + 最小 submit / throttle / bridge 已完成并通过 Room4-治理验收。
- **Why:** 本轮未触碰 DB schema / API 核心语义 / 奖励结算主链路 / `review_group` 最小合同；测试覆盖已证明入口、顺序、throttle、bridge 与 false-success 边界均已通过。
- **Approver:** Room 1

### D-OPP-001-067
- **Decision:** Room 1 判定 P3.3 当前阶段状态为 **First Pass Closed / Next-Focus Pending**，而非整体 fully closed。
- **Why:** 虽然第一拍实现与测试已通过，但最终两字中文词面、`previewDurations`、以及 ReviewPage FSRS bridge 是否继续保持 best-effort 仍需下一轮 focus 决策。
- **Approver:** Room 1


## 6) Gate Gaps (for MAIN reference)

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

---

## 7) Next Actions (must include owner + done)

1. **Owner=Room 1 / User | ETA=Next round | Done=拍板 P3.3 第二拍 focus（中文词面 / previewDurations / stronger bridge 三选一或组合） | Action=让 P3.3 从 first-pass close 进入第二拍**

2. **Owner=Room 3 / Room 5 | ETA=After next focus pin | Done=若 focus 包含词面冻结，则提交 4 按钮最终两字中文定稿与 UI/BR sync patch | Action=关闭当前 candidate wording 悬挂**

3. **Owner=Room 1 | ETA=Later | Done=更新 archive / retained-reference 处理策略，清理 `v0.1.x` 旧入口噪音 | Action=让 runtime active entry 更干净**

---

## 8) Notes (≤5 lines)

- 当前最重要的新事实是：**P3.3 第一拍已通过 Room4-治理验收，并被 Room 1 接受收口。**
- 本轮只吸收：首页“背单词”入口 + Study/Review 4 按钮 + 最小 submit / throttle / bridge。
- 本轮没有触碰 DB schema / API 核心语义 / 奖励结算主链路 / `review_group` 最小合同。
- P3.3 当前状态是 **First Pass Closed / Next-Focus Pending**，不是整体 fully closed。
- 下一治理动作是 **拍板 P3.3 第二拍 focus**，不是回退到 P3.1 文档追更。

---

## 9) Working Rule

> **Main 现在必须反映真实主线程：P1 / P2 / Option A / Option A.1 / Option B / Option C / P3 / P3.1 均已 close；P3.3 已完成第一拍收口，但当前只关闭到“首页背单词入口 + Study/Review 4 按钮 + 最小 submit / throttle / bridge”这一层。下一步不是重写 baseline，而是由 Room 1 / User 正式拍板 P3.3 第二拍 focus。**
