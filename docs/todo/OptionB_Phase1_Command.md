# Cursor_OptionB_Phase1_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接重排 Meow Home / Today / Customize 页面，而是：

> **按这里给定的 Room 1 handoff、Room 5 的 Option B UI 方案、以及 Room 4 的 execution-side scope，完成 Option B 的 Phase 1：全局主题与共享组件。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前状态不是 P1 / P2，也不是 Option A / Option A.1。  
这些都已经完成并 close。  
Room 1 已正式拍板下一方向为：

> **Option B — Visual Polish & Content Expansion**

但 Option B 的**第一轮默认只做 B1，不自动进入 B2**。  
Phase 0 已完成，当前结论是：

- B1 / B2 边界已钉死
- interaction 的 B1 边界已钉死
- catalog 扩容不进首轮已钉死
- 第一轮 Done bar 已钉死
- 代码影响面与测试入口已盘清

你现在接的不是 Phase 2 / 3 / 4 / 5，而是：

> **Phase 1 — 全局主题与共享组件**

---

## 1. 这轮你到底要做什么

这轮只做：

1. 把全局 Flutter theme 从当前默认 / 偏朴素状态，升级到 Option B 的“温柔、轻柔、偏萌、适合 demo”的视觉基础
2. 建立后续三页可复用的共享 UI 组件
3. 让 Meow Home / Today / Customize 在不改主结构的前提下，先拥有统一的视觉语言
4. 保持当前功能链路不破
5. 更新 / 补齐与主题和共享组件有关的 Flutter tests
6. 输出本轮 handoff 文档

这轮**不做**：
- 不开始 Meow Home 重排
- 不开始 Today Companion Card 改版
- 不开始 Customize 顶部预览区重排
- 不扩 companion copy
- 不扩 catalog
- 不做 interaction 的页面级增强
- 不改任何 DB / API
- 不写任何会改变业务语义的实现

一句话：

> **Phase 1 是打“视觉基础层”，不是改页面业务结构。**

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
虽然这轮不做 interaction 页面级增强，但你必须继续尊重：
- interaction 在 B1 默认是纯前端轻反馈
- 不新增 API
- 不推进业务事实

### 3.3 catalog 扩容仍然不进本轮
这轮不要为了“顺手统一视觉卡片”而把 catalog 从 5 项扩容。  
可统一 item card 风格，但**不能新增 item**。

### 3.4 Option B 继续继承 truth / degraded-state guardrails
Option B 是 polish round，不是 persistence round。  
所以必须继续继承 `UI_SPEC_v0.1.4.md` 中已经写硬的 guardrails：

- `delayed snapshot ≠ fresh backend truth`
- `pending reward / settling reward ≠ 到账成功`
- `maintenance / read_only / temporarily_unavailable` 不能包装成成功
- UI 不能为了“更好看”而改写业务状态语义

### 3.5 Room 4 不是 UI / UX owner
你不能把实现便利包装成 UI 决策。  
视觉方向、页面层级和交互表达，以 Room 5 的 `UI_SPEC_OptionB_v0.1.2.md` 为准。  
Room 4 / Cursor 只能：
- 落主题与共享组件
- 对实现缝隙提 sync patch 需求
- 不能擅自拍板页面结构方案

---

## 4. 这轮的正确目标

根据 Room 4 当前已经固定的 `optionB_phases`，Phase 1 的目标是：

> **先把 Option B 的视觉基础搭起来，减少后续每页单独返工。**

这轮必须交付的，不是“看起来已经像最终产品”，而是：

1. 一套新的全局 ThemeData / design tokens
2. 一组跨页面复用的基础卡片 / chip / badge / button / container 组件
3. 不破坏现有功能、现有测试主链路
4. 为 Phase 2 / 3 / 4 提供稳定复用层

---

## 5. 这轮 in scope

### 5.1 全局主题
你需要做：
1. 柔和、偏暖的色板
2. 更明显的圆角
3. 更柔和的卡片背景与阴影层级
4. 更适合“可爱但不低幼”的全局按钮风格
5. 文本层级更清楚，但不能太花

### 5.2 共享组件（必须）
请优先抽或建立以下可复用组件 / 风格层（命名可按 repo 现有习惯调整）：

1. **MeowCard**
   - 统一圆角、padding、卡片底色、阴影
   - 可用于 Meow Home / Today / Customize

2. **MeowChip**
   - 轻状态标签 / 小胶囊标签
   - 用于 level / mood / owned / equipped / locked / coins / fish_treats 等轻标识

3. **ResourceBadge / ResourcePill**
   - 轻量资源展示组件
   - 为后续资源轻栏打基础

4. **SoftPrimaryButton / SecondaryButton style**
   - 柔和按钮样式
   - 但不能让主 CTA 视觉不清楚

5. **PreviewContainer**
   - 顶部预览区容器
   - Phase 4 的 Customize 顶部预览会复用

6. **GrowthCard base style**
   - 只做基础风格层
   - 这轮不做真正的 Growth Card 页面结构植入

### 5.3 资产策略
当前没有高保真美术资产，因此本轮允许并建议：
- 使用 emoji
- 使用 icon
- 使用柔和色块
- 使用文字标签 + icon 映射
- 使用占位插画风格块

不要等待真实美术素材，也不要因为没素材就停工。

### 5.4 可以碰到的页面面
你可以为了接入 theme / shared components 做**最小接线**，但不要真正重排：
- Today
- Meow Home
- Customize

也就是说：
- 可以替换部分原有 Card / Button / Chip 的基础样式
- 但不要在这轮改变页面信息层级或业务布局

---

## 6. 这轮明确不做什么

### 6.1 页面结构不改
以下内容都留到后续 phase：
- Meow Home 主体区重排
- Today Companion Card 改版
- Customize 顶部预览区结构重做
- tabs / segmented control 重排

### 6.2 内容不扩
- 不新增 companion copy
- 不新增 catalog item
- 不新增状态泡泡文案池
- 不新增成长文案池

### 6.3 交互不加业务
- 不做 interaction 业务化
- 不做 cooldown
- 不做 mood / bond 新逻辑
- 不做 typed response

### 6.4 不改后端
- 不改 DB
- 不改 API
- 不改 controller / service
- 不改 persistence

---

## 7. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 7.1 Phase 0 产物
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase0_v0.1.md`

### 7.2 产品 / UI 输入
- `message7_R1toR4.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `OptionB_scope_v0.1.1.md`
- `optionB_phases.md`
- `UI_SPEC_v0.1.4.md`

### 7.3 Flutter 主题 / UI 入口
至少盘点这些现有入口：
- `app.dart`
- ThemeData / MaterialApp 相关入口
- 当前共用 widgets 目录
- Today 页面
- Meow Home 页面
- Customize 页面
- 当前 button / card / chip 相关封装

### 7.4 当前测试入口
至少盘点：
- Flutter widget tests
- 与 Meow Home / Today / Customize 相关页面测试
- 共享组件测试（若已有）
- golden / screenshot / smoke 类测试（若有）

---

## 8. Phase 1 你必须明确回答的问题

### Q1. 你最终建立了哪些 design tokens / theme 规则
请明确：
- 主色 / 辅色 / 背景色
- 卡片风格
- 圆角等级
- 阴影等级
- 按钮层级
- 文本层级

### Q2. 你新建或收束了哪些共享组件
请明确列出：
- 组件名
- 用途
- 会在哪些 phase 复用

### Q3. 这轮最小接线碰到了哪些页面
请明确：
- 哪些页面只做样式接线
- 哪些页面完全没动
- 有没有误触页面结构改动

### Q4. 这轮如何保证没越界到 Phase 2–5
请明确：
- 没有改页面结构
- 没有扩 catalog
- 没有扩文案池
- 没有新增后端契约
- 没有做 interaction 业务逻辑

### Q5. Phase 2 最自然的开工点是什么
请给出最小建议：
- Meow Home 哪些 widget 最适合先拆
- 哪个大文件风险最高
- 哪些测试最该先跟进

---

## 9. 这轮允许做什么，不允许做什么

### 允许做的
1. 改 Flutter 全局 theme
2. 新增共享 UI 组件
3. 替换基础样式层
4. 对页面做最小 theme 接线
5. 调整 / 新增 widget tests
6. 做 very small docs sync（只记录 Phase 1 新事实）

### 不允许做的
1. 不开始 Meow Home 重排
2. 不开始 Today Companion Card 改版
3. 不开始 Customize 结构升级
4. 不扩文案池
5. 不扩 catalog
6. 不新增 API
7. 不改业务规则
8. 不改 DB / API / persistence

如果你做了任何超出 Phase 1 的事，必须解释为什么仍算 theme/component layer，而不是 scope creep。

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

### 10.2 Phase 1 专项验证
至少完成这些验证：
1. 新 theme 已接入 app 根入口
2. 新共享组件已能被后续页面复用
3. Today / Meow Home / Customize 的基础样式不再完全是旧默认风格
4. 现有功能链路不破
5. 没有越界进入页面结构改版

### 10.3 建议额外覆盖
如果范围允许，建议补：
- 共享组件 widget tests
- 关键页面 smoke tests
- 主题变化后的截图 / 对比说明（若 repo 流程允许）

---

## 11. 本轮必须产出的文件（硬要求）

### Deliverable A — Option B status 更新
请更新：

```text
docs/R4_OptionB_Status_v0.1.md
```

至少补：
1. 当前完成到哪个 phase（必须写 Phase 1）
2. 已实现范围
3. 未实现范围
4. assumptions
5. blockers
6. risks
7. 当前是否允许进入 Phase 2

### Deliverable B — Option B test entry 更新
请更新：

```text
docs/R4_OptionB_Test_Entry_v0.1.md
```

至少补：
- Phase 1 影响到的 widget / page / smoke tests
- 哪些 shared components 需要后续复用测试
- 哪些回归要带到 Phase 2

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB_Phase1_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **What theme / design tokens now exist**
3. **What shared components now exist**
4. **What pages were lightly touched**
5. **What is still not touched**
6. **What must be done next**
7. **What not to touch**
8. **Files / modules to read first**
9. **Current risks**

---

## 12. 这轮完成标准（严格）

以下全部满足，才算 Phase 1 完成：

1. 新全局 theme 已落到 app 入口
2. 至少一组共享组件已建立并可复用
3. Today / Meow Home / Customize 已有最小样式层升级
4. 没有越界进入页面结构重排
5. `docs/R4_OptionB_Status_v0.1.md` 已更新
6. `docs/R4_OptionB_Test_Entry_v0.1.md` 已更新
7. `docs/R4_cursor_round_summary_OptionB_Phase1_v0.1.md` 已生成
8. 最终能明确回答：是否 ready for **Phase 2**

---

## 13. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B Phase 1（全局主题与共享组件），不是 Phase 2 页面重排

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前主题 / 组件结果
请按这几项写清楚：
1. theme / design tokens
2. shared components
3. lightly touched pages
4. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 是否跑了后端命令（如果没跑请说明为什么）
- Phase 1 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase1_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **Option B Phase 1**
2. 是否 ready for **Phase 2**
3. 当前最大的剩余风险是什么

---

## 14. 最后提醒

这轮不是让你开始重排页面。

这轮唯一要做好的事情是：

> **把 Option B 的视觉基础层搭起来，为后续 Meow Home / Today / Customize 真正重排减返工。**

不要扩 scope。  
不要偷拍板。  
不要把 B2 混进来。  
现在开始执行。
