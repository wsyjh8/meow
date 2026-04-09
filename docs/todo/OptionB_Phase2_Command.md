# Cursor_OptionB_Phase2_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接改 Today / Customize，也不是扩文案池，而是：

> **按这里给定的 Room 1 handoff、Room 5 的 Option B UI 方案、以及 Room 4 的 execution-side scope，完成 Option B 的 Phase 2：Meow Home 重排。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前状态不是 P1 / P2，也不是 Option A / Option A.1。  
这些都已经完成并 close。  
Room 1 已正式拍板下一方向为：

> **Option B — Visual Polish & Content Expansion**

但 Option B 的**第一轮默认只做 B1，不自动进入 B2**。  
Phase 0 和 Phase 1 已完成，当前结论是：

- B1 / B2 边界已钉死
- interaction 的 B1 边界已钉死
- catalog 扩容不进首轮已钉死
- 第一轮 Done bar 已钉死
- 全局主题与共享组件已建立
- 44/44 Flutter tests passed，`flutter analyze` 0 errors

你现在接的不是 Phase 3 / 4 / 5，而是：

> **Phase 2 — Meow Home 重排**

---

## 1. 这轮你到底要做什么

这轮只做：

1. 在**不改变业务语义、不新增后端契约**的前提下，重排 `/meow-home` 页面
2. 把它从“扁平信息列表页”提升成“有角色焦点的承接页”
3. 让用户更容易感知：
   - 猫猫主体
   - 当前资源
   - 成长进度
   - 已装备状态
   - feed 行为
   - interaction 的前端轻反馈
4. 复用 Phase 1 已建立的 theme / shared components / animation utilities
5. 保持现有业务逻辑不变
6. 更新 / 补齐 Meow Home 相关 Flutter tests
7. 输出本轮 handoff 文档

这轮**不做**：
- 不开始 Today Companion Card 改版
- 不开始 Customize 结构升级
- 不扩 companion copy 池
- 不扩 catalog
- 不新增 API
- 不改 DB / API / persistence
- 不做 interaction 业务化
- 不改 feed / equip / purchase 的后端规则

一句话：

> **Phase 2 是重排 Meow Home 的表现层，不是改动副机制真相层。**

---

## 2. 你必须接受的上游结论

### 2.1 Room 1 已正式拍板 Option B
当前 post-Option-A.1 的下一方向，不再悬置。  
Room 1 已明确：

> **post-Option-A.1 next direction = Option B — Visual Polish & Content Expansion**

### 2.2 当前项目必须继续服从的原则
Room 1 明确要求 Option B 必须继续满足：

- **学习优先**
- **副机制继续服务主机制**
- **温柔、可爱、清楚、顺滑**
- **不制造强负罪、强责备、强压迫体验**

### 2.3 当前 runtime active baseline
当前 repo / 方案层必须继续服从这些 active baseline：
- 主机制 PRD `v0.3`
- 副机制 PRD `v0`
- 项目介绍书 `v0`
- 副机制设计稿 `v0`
- 副机制数值草案 `v0`
- BR `v0.1.5`
- DB `v0.1.4`
- API `v0.1.3`
- 主 UI baseline `UI_SPEC_v0.1.4`

### 2.4 Option B 的性质
Option B 不是：
- 规则改写轮
- DB / API 重构轮
- persistence round
- P3

Option B 是：

> **把已经存在的副机制事实和反馈，做得更容易被用户看见、理解、记住。**

---

## 3. 你必须服从的强断言

### 3.1 第一轮默认只做 B1
当前第一轮默认执行范围 = **B1**。  
B2 仅作为后续候选，不自动进入本轮。

### 3.2 interaction 的 B1 边界仍然成立
这轮虽然要让 interaction 按钮不再像 placeholder，但你必须继续尊重：
- interaction 在 B1 默认是纯前端轻反馈
- 不新增 API
- 不推进业务事实
- 不新增奖励
- 不做 cooldown state
- 不做 mood / bond 新逻辑

### 3.3 catalog 扩容仍然不进本轮
这轮不要为了让 Meow Home “更丰富”而扩 catalog。  
可以优化已装备展示的表现，但**不能新增 item**。

### 3.4 Option B 继续继承 truth / degraded-state guardrails
Option B 是 polish round，不是 persistence round。  
所以必须继续继承 `UI_SPEC_v0.1.4.md` 中已经写硬的 guardrails：

- `delayed snapshot ≠ fresh backend truth`
- `pending reward / settling reward ≠ 到账成功`
- `maintenance / read_only / temporarily_unavailable` 不能包装成成功
- UI 不能为了“更有变化感”而改写业务状态语义

### 3.5 Room 4 不是 UI / UX owner
你不能把实现便利包装成 UI 决策。  
视觉方向、页面层级和交互表达，以 Room 5 的 `UI_SPEC_OptionB_v0.1.2.md` 为准。  
Room 4 / Cursor 只能：
- 实现 Meow Home 页面结构与表现
- 对缺口提 sync patch 需求
- 不能擅自拍板最终视觉方案

---

## 4. 这轮的正确目标

根据 Room 4 当前已经固定的 `optionB_phases`，Phase 2 的目标是：

> **先把“最能感知产品变化”的页面做出来。**

为什么先做 Meow Home：
- 最适合 demo
- 最容易体现“陪伴感 / 成长感 / 装扮反馈”
- 当前 UI 提升收益最高
- 也是当前风险最高、最需要单独收口的一页

---

## 5. 这轮 in scope

### 5.1 页面结构重排（必须）
请把 Meow Home 从当前较扁平的卡片堆叠，重排成以下更有层级的结构：

1. **猫猫主体区（hero area）**
   - 猫猫主体更大、更聚焦
   - 可用 emoji / icon / 占位插画风块，不等待高保真素材
   - 可有轻呼吸感 / 轻进入动画，但不要厚重表演

2. **资源轻栏**
   - `coins / fish_treats / exp` 更清楚地横向显示
   - 视觉上比主体区弱，但比普通正文强
   - 复用 `ResourceBadge / ResourcePill`

3. **Growth Card**
   - 显示 Level / EXP / 进度条 / 下一级提示
   - 这轮只做页面中真正可见的 Growth Card，不改后端成长规则

4. **状态泡泡 / companion response 区**
   - 让猫猫“像活着”
   - 展示当前 companion response / 情绪性回应
   - 但不能把 UI 文案写成后端未确认业务事实

5. **已装备展示优化**
   - 从 raw slot 名 / 原始 code，变成更友好的名称 + icon / emoji + tag
   - 复用 `MeowChip`

6. **核心按钮区**
   - `feed` 按钮视觉更强
   - `interaction` 按钮从 placeholder 观感升级为可感知按钮
   - `customize` 入口更自然

### 5.2 interaction 在本 phase 的正确做法
你这轮要让 interaction button **看起来不再只是占位**，但边界必须非常硬：

#### 允许做的
- 更具体的按钮文案
- 更有存在感的按钮样式
- 点击微反馈
- 前端本地随机回应文案
- 局部动效 / 高亮 / 猫猫状态泡泡变化

#### 不允许做的
- 新 endpoint
- cooldown state
- typed payload
- response typing
- mood / bond 真业务逻辑扩展
- interaction 奖励
- interaction 结果分类状态机

### 5.3 已装备展示的正确做法
当前 repo 里已装备显示可能偏 raw。  
你这轮允许：
- 做 code → 友好显示名映射
- 做 slot → icon / emoji / tag 映射
- 做更温和的视觉层级

但不允许：
- 改 equipment 语义
- 改 slot 定义
- 新增 slot
- 新增 item type

### 5.4 资产策略
当前没有高保真美术资产，因此本轮允许并建议：
- 使用 emoji
- 使用 icon
- 使用柔和色块
- 使用占位插画风块
- 使用友好文字标签

不要等待真实美术素材，也不要因为没素材就停工。

---

## 6. 这轮明确不做什么

### 6.1 不改后端
- 不改 feed API
- 不改 secondary summary API
- 不改 equipment API
- 不改 purchase API
- 不改 persistence

### 6.2 不扩内容池
- 不新增 companion copy pool
- 不新增 feed / interaction / equip 响应池
- 不新增 catalog item

### 6.3 不做其他页面
以下都留到后续 phase：
- Today Companion Card 重做
- Customize 顶部预览区
- tabs / segmented control
- 商店 / 我的物品页结构升级
- copy 小扩池与 closeout

### 6.4 不改变业务事实表达
- 不把 pending 写成到账成功
- 不把展示变化写成已确认变化
- 不把 interaction 的前端反馈写成真实成长 / 奖励 / 关系变化

---

## 7. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 7.1 Phase 0 / 1 产物
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase0_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase1_v0.1.md`

### 7.2 产品 / UI 输入
- `message7_R1toR4.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `OptionB_scope_v0.1.1.md`
- `optionB_phases.md`
- `UI_SPEC_v0.1.4.md`
- `R4_OptionB_Analysis_and_Execution_Plan_v0.1.md`

### 7.3 Flutter 入口与页面
至少盘点这些现有入口：
- `app.dart`
- 当前 theme 入口
- `MeowHomePage`
- shared widgets / animations / theme
- 现有 companion / summary / equipment display 相关 widget
- feed button / level-up dialog / customize 入口

### 7.4 当前测试入口
至少盘点：
- `meow_home_page_test.dart`
- 共享组件测试（若已有）
- feed / level-up / companion response / equipped display 的前端测试
- 页面 smoke tests

---

## 8. Phase 2 你必须明确回答的问题

### Q1. Meow Home 最终被重排成什么层级
请明确描述：
- hero area
- resource bar
- growth card
- companion/status bubble
- equipped display
- actions row

### Q2. 这轮 interaction 具体是怎么做的
请明确：
- 哪些是纯前端反馈
- 用了哪些文案 / 动效 / 组件
- 为什么它仍然不算新业务动作

### Q3. 已装备显示现在如何更友好了
请明确：
- raw code 如何映射成友好展示
- 用了什么 chip / icon / emoji / tag
- 有没有误触业务语义

### Q4. 这轮如何保证没越界到 Phase 3–5
请明确：
- 没有改 Today
- 没有改 Customize 结构
- 没有扩 catalog
- 没有扩文案池
- 没有新增 API

### Q5. Phase 3 最自然的开工点是什么
请给出最小建议：
- Today 页哪个 widget 最适合先拆
- 主 CTA 层级怎么最稳
- 哪些测试最该先跟进

---

## 9. 这轮允许做什么，不允许做什么

### 允许做的
1. 重排 Meow Home 页面结构
2. 接入 shared theme / components / animations
3. 做最小友好名称映射 / icon 映射
4. 让 interaction button 有纯前端轻反馈
5. 更新 / 新增 widget tests
6. 做 very small docs sync（只记录 Phase 2 新事实）

### 不允许做的
1. 不改后端 API
2. 不扩 catalog
3. 不扩文案池
4. 不新增 interaction 业务逻辑
5. 不改 Today
6. 不改 Customize
7. 不改业务规则
8. 不改 DB / API / persistence

如果你做了任何超出 Phase 2 的事，必须解释为什么仍算 Meow Home 表现层重排，而不是 scope creep。

---

## 10. 这轮最小测试 / 验证要求

### 10.1 Flutter
至少要执行：
```bash
flutter pub get
flutter test
flutter analyze
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 10.2 Phase 2 专项验证
至少完成这些验证：
1. Meow Home 页面层级已明显变化
2. 猫猫主体区已成为视觉中心
3. feed 按钮视觉更明显
4. interaction 按钮不再像纯 placeholder
5. 已装备显示更友好
6. 现有功能链路不破
7. 没有越界进入 Today / Customize / B2

### 10.3 建议额外覆盖
如果范围允许，建议补：
- Meow Home widget tests
- feed 按钮视觉回归
- interaction 本地反馈 smoke
- level-up dialog 与 growth display 回归
- equipped preview / equipped chips 回归

---

## 11. 本轮必须产出的文件（硬要求）

### Deliverable A — Option B status 更新
请更新：

```text
docs/R4_OptionB_Status_v0.1.md
```

至少补：
1. 当前完成到哪个 phase（必须写 Phase 2）
2. 已实现范围
3. 未实现范围
4. assumptions
5. blockers
6. risks
7. 当前是否允许进入 Phase 3

### Deliverable B — Option B test entry 更新
请更新：

```text
docs/R4_OptionB_Test_Entry_v0.1.md
```

至少补：
- Phase 2 影响到的 widget / page / smoke tests
- 哪些 Meow Home tests 已更新
- 哪些回归要带到 Phase 3

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB_Phase2_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **How Meow Home is now structured**
3. **What interaction boundary was kept**
4. **What pages were not touched**
5. **What is still not done**
6. **What must be done next**
7. **What not to touch**
8. **Files / modules to read first**
9. **Current risks**

---

## 12. 这轮完成标准（严格）

以下全部满足，才算 Phase 2 完成：

1. Meow Home 页面结构已重排
2. 猫猫主体区已成为视觉中心
3. Growth / resources / equipped / actions 的层级已更清楚
4. interaction 已有纯前端可感知反馈，但无业务越界
5. 没有改后端契约
6. `docs/R4_OptionB_Status_v0.1.md` 已更新
7. `docs/R4_OptionB_Test_Entry_v0.1.md` 已更新
8. `docs/R4_cursor_round_summary_OptionB_Phase2_v0.1.md` 已生成
9. 最终能明确回答：是否 ready for **Phase 3**

---

## 13. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B Phase 2（Meow Home 重排），不是 Phase 3 Today 改版

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 Meow Home 结果
请按这几项写清楚：
1. hero area
2. resource bar
3. growth card
4. equipped display
5. interaction boundary
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 是否跑了后端命令（如果没跑请说明为什么）
- Phase 2 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase2_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **Option B Phase 2**
2. 是否 ready for **Phase 3**
3. 当前最大的剩余风险是什么

---

## 14. 最后提醒

这轮不是让你开始改 Today 或 Customize。

这轮唯一要做好的事情是：

> **把 Meow Home 做成真正有角色焦点、资源层级、成长感和轻互动承接的页面。**

不要扩 scope。  
不要偷拍板。  
不要把 B2 混进来。  
现在开始执行。
