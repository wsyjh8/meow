# UI_SPEC_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.5 — Local Planner Owner Shift / Cloud Backup Rebase Round`
- **Direct upstream input:** `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`
- **Related inputs:** `R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1.md` + `R3_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Rules_Note_v0.1.md` + `UI_SPEC_v0.2.6.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.5 当前轮需要回答的 “local planner owner shift + cloud backup rebase” 问题，翻成可被 Room 1 判断是否 pin 的最小 UI 合同层。**

本稿不是：
- 新 UI 主文档
- 新 BR / DB / API 主文档
- Room 4 执行单
- 直接宣布 owner shift 已完成
- 完整复习系统重写稿
- unified planner / planner merge 最终版

一句话：

> **P3.3.5 在 Room 5 视角，是一轮“target-state + staged UI migration + fact-copy 护栏”合同轮，不是把本地 planner 已接管复习主链路写成当前界面事实。**

---

## 1. 输入依据

### 1.1 主线程 handoff basis
- `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.2 Room 2 / Room 3 本轮输入
- `R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1.md`
- `R3_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Rules_Note_v0.1.md`

### 1.3 当前 runtime / review basis
- `BR-OPP-001_v0.2.6.md`
- `UI_SPEC_v0.2.6.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `p3.3.5_user.md`

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持本轮前进一步，但只支持进入“future target-state + staged UI migration + backup/restore 文案重写”的 very narrow UI contract。**

### 2.2 为什么应该前进一步
如果这轮仍完全不回答 owner shift / backup rebase，UI 侧会继续悬空以下问题：
1. 未来首页到底还按 `study_default`，还是会改成 planner-aware entry
2. ReviewPage 未来谁是页面 serving truth source
3. continuation 的 UI 表达未来是否仍可保留，以及如何重写
4. preview / explanation 若未来升级，哪些页面能进、哪些仍绝不能进
5. backup / restore / cross-device 三层成功语义在设置页与我的页怎么写
6. 哪些文案一出现，就会把 “方向被接受” 误写成 “当前已经切换完成”

### 2.3 为什么不能走更深
本轮仍不能越界到：
- current runtime owner shift
- auto-routing runtime
- unified planner / planner merge
- ReviewPage preview re-entry
- 首页 preview
- 完整 preview explanation system
- unified Study / Review page
- 完整 review planning 产品重写
- full sync / real-time sync / auto merge

---

## 3. 当前运行态 vs 未来目标态（Room 5 必须先分层）

## 3.1 当前 runtime reality（不能偷改）
当前 UI 仍必须继续服从以下事实：
1. 首页“背单词”默认仍是 `study_default`
2. ReviewPage current serving truth 仍围绕 cloud `review_group`
3. active review continuation 继续只能独立承接，不得 silent reroute
4. `previewDurations` 当前只允许 StudyPage-only、hint-only、estimated-only
5. ReviewPage / 首页继续不显示 preview
6. backup / restore 当前继续 manual-only，不得写成 sync / auto merge / cross-device 已统一

## 3.2 未来 target-state candidate（本轮只讨论方向）
本轮只允许把以下内容写成 **future target-state candidate**：
1. local FSRS / local scheduler 未来可成为 **primary planning owner**
2. ReviewPage future serving 可逐步转向 local due / local generated review session
3. 首页 future 可进入 planner-aware entry 候选
4. preview / explanation future 可从 estimated hint 升到 planner-facing explanation candidate
5. `review_group` future 可进入 compatibility / deprecation path
6. cloud future 可降级为 backup / restore / optional aggregate support / 非复习规划域

## 3.3 Room 5 的强约束
> **本轮任何页面、文案、测试、helper、summary block，都不得把 future target-state candidate 写成 current runtime truth。**

---

## 4. Q1 — 如果 local 成 primary planner owner，首页 / Study / Review / helper / summary 要怎么变

## 4.1 SpecHomePage
### 当前 runtime reality（继续保持）
- 主 CTA：**背单词**
- 默认进入：`StudyPage`
- active review continuation：继续通过独立 CTA / helper / priority block 承接
- 当前不得自动吞掉 `/study`

### future target-state candidate（仅方向）
若未来 local planner 成为 primary planning owner，Room 5 认为首页会进入以下重写方向：
1. **主 CTA 仍可能保留“背单词”**，但它不再一定是纯 `study_default`
2. 首页可能出现更强的 planner-aware helper / summary block
3. continuation 高优先语义未来仍可保留，但 CTA / helper / priority block 需要重写
4. 首页 future 可能进入：
   - 先复习
   - 先新学
   - 混合 session
   的候选表达层

### 本轮不允许写成的事实
- 系统已自动为你决定今天先学什么
- 已切换到本地规划入口
- 现在点“背单词”会自动跳去复习
- 本地 planner 已接管首页路由

## 4.2 StudyPage
### 当前 runtime reality（继续保持）
- 继续是默认学习入口页
- 不承担 planner dispatcher 解释职责
- 保持 P3.3 / P3.3.1 / P3.3.4 已冻结的 4 按钮、preview 最小回归候选与低阻力提交节奏

### future target-state candidate
若 local planner 方向被接受，StudyPage 未来可能：
1. 成为更明确的 local planning explanation 入口
2. 承接更强的 preview / explanation candidate
3. 在 session-aware 模式下承接“当前为什么先学新词”的解释层

### 本轮不允许写成的事实
- 系统根据本地规划把你送到这里
- 当前页面已是 unified learning page
- 当前规划已确定先学新词

## 4.3 ReviewPage
### 当前 runtime reality（继续保持）
- 继续围绕 cloud `review_group` 展示 queue / continuation / remaining / completion / settlement
- local FSRS 当前仍只作为 scheduling candidate / side-effect owner
- stronger bridge 只提升幕后合同，不产出新的用户计划事实

### future target-state candidate
若进入 future local-serving 方向，ReviewPage 未来可能：
1. 改由 local due cards / local generated review session 提供主要队列
2. continuation / progress summary / readiness helper 全部重写
3. `review_group` 从 primary serving path 退到 compatibility / transition layer

### 本轮不允许写成的事实
- ReviewPage 已由本地 planner 接管
- 当前复习队列来自本地 due
- `review_group` 已退出 runtime
- 当前 ReviewPage 已是 local-serving truth

---

## 5. Q2 — `review_serving_contract_v2` 会怎样改页面 state truth

## 5.1 Room 5 结论
> **如果 future local-serving 方向被接受，页面 state truth 会重写；但本轮只允许写“会重写到哪”，不允许写“已经重写完成”。**

## 5.2 当前页面 state truth（继续有效）
### Home
- readiness / continuation / due review 的页面 truth 继续以后端 review-serving layer 为准

### ReviewPage
- queue / continuation / remaining / completion / settlement 继续围绕 cloud `review_group`

### StudyPage
- 保持默认学习入口页，不承担当前 serving truth 解释职责

## 5.3 future target-state candidate（仅描述方向）
未来若 `review_serving_contract_v2` 被进一步 pin，Room 5 认为 UI state truth 会发生三类变化：

1. **Review truth source 重写**
   - 从 cloud `review_group`
   - 转向 local due / local review session

2. **continuation 表达重写**
   - 未来 continuation 不再直接复用 cloud-group wording
   - helper / CTA / summary block 需整体改写

3. **generation 资格态 / 服务态重写**
   - `ready_now`
   - `next_group_eligible`
   - `temporarily_unservable`
   在 future v2 中都可能转向 local planner truth source

## 5.4 本轮 UI 风险判断
本轮最大的风险不是“功能没想清楚”，而是：
> **把 future truth source 重写，误写成 current truth source 已切换。**

---

## 6. Q3 — `session_entry_and_routing_v2` 会如何影响首页默认入口、continuation、自动分流表达

## 6.1 Room 5 结论
> **本轮只允许把 routing 改写记成 future candidate，不允许进入当前 runtime 路由事实。**

## 6.2 首页默认入口
### 当前 runtime reality
- 继续 `study_default`

### future candidate
若 future local planner owner 成立，首页默认入口未来可能进入：
1. planner-aware entry
2. due-first candidate
3. mixed-session candidate

但本轮只允许写成“未来可能进入”的方向。

## 6.3 continuation 表达
### 当前 runtime reality
- active review continuation 继续高优先
- 但仍通过独立 CTA / helper / priority block 承接
- 不得 silent reroute

### future candidate
- continuation 高优先语义未来仍可保留
- 但其 truth source、helper wording、CTA 形式必须整体重写
- 不能继续直接借用 cloud-group wording

## 6.4 auto-routing 表达
### 当前继续禁止
- 自动分流已开启
- 当前系统会自动决定先复习还是先新学
- 已切换到最佳学习路径

### Room 5 一句话判断
> **P3.3.5 可以承认 routing future 会受 owner shift 影响，但本轮 UI 仍必须继续把 auto-routing 视为 pending。**

---

## 7. Q4 — `preview_and_explanation_contract_v2` 若升格，哪些页面可显示，哪些继续禁入

## 7.1 Room 5 结论
> **若 local planner 未来成为 primary owner，preview / explanation 的 UI 级别可以上升；但本轮只允许把它写成 future candidate，不允许改 current visible boundary。**

## 7.2 当前继续允许的页面
### StudyPage
- 继续允许最小 preview re-entry：
  - StudyPage-only
  - hint-only
  - estimated-only
  - 必须带“预计 / 仅供参考”

## 7.3 当前继续禁入的页面
### ReviewPage
- 当前继续禁止 preview

### 首页
- 当前继续禁止 preview

### Settings / 我的页
- 当前不应显示面向用户的 planner interval explanation

## 7.4 future candidate（仅方向）
若未来 owner shift 被进一步 pin，Room 5 认为 preview / explanation 的可见范围未来可能讨论：
1. StudyPage explanation 升级
2. ReviewPage 进入 planner-facing explanation candidate
3. 首页出现更强 planning summary candidate

但这三项当前统统不升格。

## 7.5 本轮最重要的 fact-copy 护栏
无论 future candidate 怎么讨论，当前仍继续禁止：
- 下次将在 X 天后复习
- 系统已为你安排
- 已更新你的复习计划
- 已同步复习安排
- 计划已统一
- 已切换到最佳复习模式

---

## 8. Q5 — `backup_restore_and_cross_device_boundary_v2` 会影响哪些设置页 / 我的页 / 提示文案

## 8.1 Room 5 结论
> **这组是本轮最值得前进一步的 UI 合同之一。**

因为一旦 local planner owner 方向被接受，设置页 / 我的页 / 数据页的文案与状态语义必须先重写，否则用户会被“备份 / 恢复 / 同步”三类概念误导。

## 8.2 受影响页面
1. **SettingsPage**
2. **SpecProfilePage / 我的页**
3. **可能的 backup / restore flow sheet / dialog**
4. **手动备份入口、最近备份状态区块**
5. **restore warning / confirm / result toast / result page**

## 8.3 Room 5 建议冻结的最小 UI 语义
### A. backup success
表示：
- 当前设备本地 runtime truth 已成功导出并上传为云端 snapshot artifact

不表示：
- 另一台设备已更新
- 云端已成为 runtime truth
- 当前计划已跨设备统一

### B. restore success
表示：
- 某个目标设备已成功应用某份 snapshot，并以此重写本地 planner / local runtime state

不表示：
- 所有设备都已一致
- 云端与本地无冲突
- 以后会自动保持一致

### C. sync success
当前轮继续不建议作为真实用户状态出现。
因为本项目当前仍坚持：
- manual backup
- no real-time sync
- no auto merge

## 8.4 Room 5 推荐页面表达
### 设置页 / 我的页可出现
- 立即备份
- 最近一次备份时间
- 最近一次备份状态
- 从备份恢复
- 恢复将覆盖本机当前本地进度

### 当前继续禁止
- 已同步
- 云端与本地已统一
- 跨设备已保持一致
- 无需担心冲突
- 恢复后所有设备自动一致

---

## 9. Q6 — 哪些表达会把“owner shift / backup rebase”误写成已同步、已统一、无冲突

## 9.1 Room 5 当前正式结论
> **本轮最大的 UI 风险，不是页面长得不对，而是把“target-state / migration contract”写成“当前已完成事实”。**

## 9.2 Fact Copy 禁区（本轮新增）
以下表达在 P3.3.5 当前轮继续列为页面事实禁区：

### Owner shift / planner truth 禁区
1. 本地 planner 已接管复习主链路
2. ReviewPage 已由本地 planner 驱动
3. 当前复习主真相源已切换到本地
4. `review_group` 已退出运行态
5. 云端不再参与复习主链路
6. 系统已自动为你决定今天先学什么
7. 已切换到最佳学习路径
8. auto-routing 已开启
9. mixed learning 已启用
10. unified planner 已成立

### Preview / explanation 禁区
11. 下次将在 X 天后复习
12. 系统已为你安排
13. 已更新你的复习计划
14. 已同步复习安排
15. 计划已统一
16. 已根据 FSRS 自动重排你的学习路径

### Backup / restore / cross-device 禁区
17. 已同步
18. 云端与本地已统一
19. 跨设备已一致
20. 无冲突
21. 恢复后所有设备自动更新
22. 现在所有设备的学习计划都一样

---

## 10. State Contract Risk（Room 5 给 Room 1 的风险摘要）

## 10.1 当前可被 Room 1 pin 的最小 UI 合同层
Room 5 建议 Room 1 若要 pin，本轮只 pin 以下内容：

1. **local primary planner owner 只进入 future target-state candidate，不进入 current runtime truth**
2. **ReviewPage current serving truth 仍不切，future local-serving 只进入 compatibility / deprecation path 候选**
3. **首页默认入口当前继续 `study_default`；routing v2 只进入 future candidate**
4. **StudyPage 继续维持当前 preview 最小回归；ReviewPage / 首页 继续禁止 preview**
5. **backup success / restore success / sync success 三层语义必须在页面文案层严格分开**
6. **Settings / 我的页必须显式避免“已同步 / 已统一 / 无冲突”这类假事实**
7. **任何 staged migration / deprecation wording 都必须显式带“方向 / 候选 / 未来迁移”语气，而不是“已切换完成”语气**

## 10.2 当前仍不建议 pin 的 UI 合同
1. ReviewPage preview re-entry
2. 首页 preview
3. preview explanation system 主层
4. auto-routing runtime UI
5. unified planner UI
6. ReviewPage truth source 直接切 local
7. cloud aggregate 非复习域大迁移
8. “本地已经接管”的结果型文案

---

## 11. Staged UI Migration 建议

## 11.1 Stage A — Contract freeze only
本轮只冻结：
- target-state candidate
- fact-copy guardrails
- backup / restore / cross-device 三层语义
- future UI migration 方向

## 11.2 Stage B — Compatibility UI layer
未来若 Room 1 接受下一轮更窄 execution gate，Room 5 建议先做：
1. Settings / 我的页 文案与 warning 重写
2. restore / backup flow 的结果层区分
3. continuation / helper / summary block 的 cloud-wording 去耦
4. future local-serving UI 影子态 / shadow wording

## 11.3 Stage C — True UI contract rewrite
只有当 Room 1 + Room 2 + Room 3 再次共同 pin：
- serving owner shift
- route contract v2
- backup / restore boundary v2
后，Room 5 才建议真正改：
- 首页默认入口
- ReviewPage truth source
- preview 可见范围
- explanation 主层

---

## 12. Room 5 一句话结论

> **P3.3.5 在 Room 5 视角，可以前进一步，但只能前进到“future target-state + staged UI migration + backup/restore 语义重写”的 very narrow UI contract：当前 runtime 继续保持 `study_default`、cloud review-serving truth、Study-only preview；本轮最该冻结的是页面 truth source 不得偷切、backup/restore/sync 三层语义必须分开，以及所有会把 owner shift / cloud rebase 误写成“已同步 / 已统一 / 已切换完成”的文案继续禁止。**
