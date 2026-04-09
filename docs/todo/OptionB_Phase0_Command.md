# Cursor_OptionB_Phase0_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接开始做视觉重排代码，而是：

> **按这里给定的 Room 1 handoff、Room 5 的 Option B UI 方案、以及 Room 4 的 execution-side scope，把 Option B 的 Phase 0（Preflight / guardrails 对齐）做成一个清晰、可执行、可测试的开工前基线。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前状态不是 P1 / P2，也不是 Option A / Option A.1。  
这些都已经完成并 close。  
Room 1 已正式拍板下一方向为：

> **Option B — Visual Polish & Content Expansion**

但 Option B 的**第一轮默认只做 B1，不自动进入 B2**。  
你这轮接的也不是 Phase 1 开发，而是：

> **Phase 0 — Preflight / guardrails 对齐**

---

## 1. 这轮你到底要做什么

这轮只做：

1. 盘点当前 repo 中与 Option B 第一轮直接相关的代码入口
2. 明确当前第一轮默认只做 **B1**
3. 明确 `UI_SPEC_OptionB_v0.1.2.md` 是 UI / UX 方案输入
4. 明确 `OptionB_scope_v0.1.1.md` 是 Room 4 execution-side scope
5. 把 interaction 的 B1 边界写死：
   - **纯前端轻反馈**
   - **不新增 API**
   - **不推进业务事实**
6. 把 catalog 扩容写死为：
   - **B2 candidate**
   - **不自动进入第一轮**
7. 把第一轮 Done bar / close bar整理清楚
8. 盘出：
   - 哪些代码模块会在 Phase 1–5 被改到
   - 哪些测试需要更新
   - 哪些地方如果动到就会越界
9. 输出一套给后续 Cursor 接力的 handoff 文档

这轮**不做**：
- 不开始全局 theme 重写
- 不开始 Meow Home 重排
- 不开始 Today 改版
- 不开始 Customize 改版
- 不扩 companion copy
- 不扩 catalog
- 不做新 API
- 不做 DB / API sync patch
- 不写任何“看起来像已经开始 Phase 1 代码实现”的大改动

一句话：

> **Phase 0 是把 Option B 第一轮的执行边界钉死，而不是抢先写页面。**

---

## 2. 你必须接受的上游结论

### 2.1 Room 1 已正式拍板 Option B
当前 post-Option-A.1 的下一方向，不再悬置。  
Room 1 已明确：

> **post-Option-A.1 next direction = Option B — Visual Polish & Content Expansion**

你现在接的不是：
- Option A.2 技术补强
- Option C 主机制增强
- P3 新阶段

而是：

> **以现有 active baseline 为基础，做一轮 UI / UX + content polish。**

### 2.2 当前项目必须继续服从的原则
Room 1 明确要求 Option B 必须继续满足：

- **学习优先**
- **副机制继续服务主机制**
- **温柔、可爱、清楚、顺滑**
- **不得制造强负罪、强责备、强压迫体验**

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

也就是说：
- 本轮不能顺手把 catalog 扩到 10–14
- 不能顺手扩大 copy 池到完整版本
- 不能顺手引入 typed payload / new fields / cooldown state

### 3.2 interaction 的 B1 边界必须写死
B1 阶段的 interaction 只允许是：

> **纯前端本地可感知反馈**

也就是只允许：
- 更具体的按钮文案
- 按钮样式增强
- 点击微反馈
- companion response 的前端展示增强

默认**不允许**：
- 新 endpoint
- cooldown state
- typed payload
- response typing
- mood / bond 新逻辑
- interaction 奖励
- interaction 结果分类状态机

### 3.3 catalog 扩容不是第一轮默认项
catalog 扩容是 **B2 candidate**。  
即使第一轮以后少量扩容，也只能：

> **复用当前 DB / API 已有 item type / slot / currency / price ladder / level-lock 语义**

任何超出当前 DB / API 模型的扩容，都不算“直接可做”，而算：
- very small sync patch 申请
- Room 2 / Room 3 review 事项

### 3.4 Option B 继续继承 truth / degraded-state guardrails
Option B 是 polish round，不是 persistence round。  
所以必须继续继承 `UI_SPEC_v0.1.4.md` 中已经写硬的 guardrails：

- `delayed snapshot ≠ fresh backend truth`
- `pending reward / settling reward ≠ 到账成功`
- `maintenance / read_only / temporarily_unavailable` 不能包装成成功
- UI 不能为了“更有变化感”而把候选变化、展示变化或推测变化写成已确认业务事实

### 3.5 Room 4 不是 UI / UX owner
你不能把实现便利包装成 UI 决策。  
页面结构、状态表达、交互节奏，以 Room 5 的 `UI_SPEC_OptionB_v0.1.2.md` 为准。  
Room 4 / Cursor 只能：
- 按它实现
- 对缺口提 sync patch / review 要求
- 不能擅自拍板视觉方案

---

## 4. Option B 第一轮的正确切法

你必须按 Room 4 当前已经确定的 6-phase 结构理解后续执行：

1. **Phase 0 — Preflight / guardrails 对齐**
2. **Phase 1 — 全局主题与共享组件**
3. **Phase 2 — Meow Home 重排**
4. **Phase 3 — Today Companion Card + 承接优化**
5. **Phase 4 — Customize / Catalog / Inventory / Equipment 体验升级**
6. **Phase 5 — Companion copy 小扩池 + polish closeout**

你现在只做 **Phase 0**。

---

## 5. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 5.1 产品 / 规则 / UI 输入
- `message7_R1toR4.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `OptionB_scope_v0.1.1.md`
- `optionB_phases.md`
- `UI_SPEC_v0.1.4.md`
- `BR-OPP-001_v0.1.5.md`

### 5.2 当前 Flutter 入口与页面
至少盘点这些现有页面与组件入口：
- `app.dart`
- Theme 入口
- Today 页面
- Meow Home 页面
- Customize 页面
- companion card / summary widgets
- inventory / equipment / catalog 相关 widgets
- feed / equip / purchase 的 UI 调用点

### 5.3 当前后端契约入口
至少确认这些 API / truth 还在当前 baseline 下可直接复用：
- `/me/secondary-summary`
- `/me/feed`
- `/shop/catalog`
- `/shop/purchases`
- `/me/inventory`
- `/me/equipment`
- `/me/equipment/equip`
- `/me/equipment/unequip`

### 5.4 当前测试入口
至少盘点：
- Flutter widget tests
- 页面 smoke tests
- 与 Meow Home / Customize / Today 相关测试
- 与 equip / purchase / feed 相关的前后端回归

---

## 6. Phase 0 你必须明确回答的问题

### Q1. 当前第一轮 B1 的直接实现范围到底是什么
请明确列出：
- 全局主题与共享组件
- Meow Home 重排
- Today Companion Card + 承接优化
- Customize 三态与顶部预览
- interaction 前端轻反馈
- companion copy 小扩池

### Q2. 当前第一轮明确不做什么
请明确列出：
- catalog 扩容
- typed response / new payload
- new API
- DB / API sync patch
- 新业务规则
- 新 major phase 内容

### Q3. 哪些点若要继续往前，就必须先 sync patch
至少明确：
- typed `companion_response`
- `change_highlights[]`
- stable preview / thumbnail key
- interaction cooldown / richer payload
- 任何超出当前 item / slot / currency / level-lock 语义的 catalog 扩容

### Q4. 哪些点要 Room 2 / Room 3 review
请明确：
- 新字段 / 新 payload / typed response → Room 2
- 新状态语义 / 容易写成既成事实的表达 → Room 3

### Q5. 第一轮 Done bar 是什么
请明确写成可检查标准：
1. Today Companion Card 已落地，且不压主 CTA
2. Meow Home 主体区 / 资源轻栏 / Growth Card / 状态泡泡已落地
3. Customize 三态与顶部预览已落地
4. interaction button 已有前端可感知回应
5. 至少一小批 companion copy 扩充已用户可见

### Q6. 当前 repo 的真实代码影响面是什么
请明确：
- Phase 1 最可能改哪些文件
- Phase 2 最可能改哪些文件
- Phase 3 最可能改哪些文件
- Phase 4 最可能改哪些文件
- Phase 5 最可能改哪些文件
- 哪些 shared widgets / tests 会被波及

---

## 7. 这轮允许做什么，不允许做什么

### 允许做的
1. 盘点 Flutter / API / 测试影响面
2. 输出 Phase 0 preflight 文档
3. 输出第一轮 B1 implementation checklist
4. 输出 risk list
5. 输出 test entry list
6. 如有必要，新增 very small docs-only note

### 不允许做的
1. 不开始 Phase 1 代码实现
2. 不开始 theme overhaul
3. 不开始页面结构重排
4. 不改 DB / API
5. 不新增 endpoint
6. 不新增 typed payload
7. 不扩 catalog
8. 不顺手扩 content pool 到 B2 规模
9. 不做任何会改变业务语义的实现

如果你做了任何超出 Phase 0 的事，必须解释为什么仍算 preflight，而不是 scope creep。

---

## 8. 这轮最小测试 / 验证要求

### 8.1 后端
如果这轮后端没改，不要求新增后端实现；  
但你至少应确认当前可复用 API 面是否与 Option B Phase 1–5 对得上。

### 8.2 Flutter
至少要执行：
```bash
flutter pub get
flutter test
flutter analyze
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 8.3 Phase 0 专项验证
至少完成这些验证型输出：
1. B1 / B2 边界是否清楚
2. interaction 边界是否清楚
3. catalog 扩容边界是否清楚
4. done bar 是否清楚
5. 受影响文件清单是否清楚
6. 测试入口是否清楚

---

## 9. 本轮必须产出的文件（硬要求）

### Deliverable A — Option B status 起始文件
请新增：

```text
docs/R4_OptionB_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 Phase 0）
2. 当前第一轮范围（B1）
3. 当前明确 out of scope（B2 and beyond）
4. assumptions
5. blockers
6. risks
7. 当前是否允许进入 Phase 1

### Deliverable B — Option B test entry note
请新增：

```text
docs/R4_OptionB_Test_Entry_v0.1.md
```

至少包含：
- 哪些页面 / 组件 / flows 会被测
- Phase 1–5 各自的测试入口
- 哪些 guardrails 需要持续回归
- 哪些 truth boundary 不能被 UI 越界表达

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB_Phase0_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **What B1 includes**
3. **What B2 explicitly does not include for this round**
4. **What interaction boundary now is**
5. **What catalog boundary now is**
6. **What must be done next**
7. **What not to touch**
8. **Files / modules to read first**
9. **Current risks**

---

## 10. 这轮完成标准（严格）

以下全部满足，才算 Phase 0 完成：

1. 第一轮默认只做 **B1** 已被清楚写死
2. interaction 的 B1 边界已被清楚写死
3. catalog 扩容的边界已被清楚写死
4. 第一轮 Done bar 已被清楚写出
5. 受影响代码面 / 测试入口已被盘清
6. `docs/R4_OptionB_Status_v0.1.md` 已生成
7. `docs/R4_OptionB_Test_Entry_v0.1.md` 已生成
8. `docs/R4_cursor_round_summary_OptionB_Phase0_v0.1.md` 已生成
9. 最终能明确回答：是否 ready for **Phase 1**

---

## 11. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B Phase 0（Preflight / guardrails 对齐），不是 Phase 1 开发

### B. 新增 / 改动文件清单
只列路径即可。  
若没有代码改动，要明确写。

### C. 当前边界结论
请按这几项写清楚：
1. B1 includes
2. B2 excluded this round
3. interaction boundary
4. catalog boundary
5. done bar

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 是否跑了后端命令（如果没跑请说明为什么）
- Phase 0 的盘点验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase0_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **Option B Phase 0**
2. 是否 ready for **Phase 1**
3. 当前最大的剩余风险是什么

---

## 12. 最后提醒

这轮不是让你开始做视觉重构。

这轮唯一要做好的事情是：

> **把 Option B 第一轮的执行边界、影响面、测试入口、done bar 一次钉死。**

不要扩 scope。  
不要偷拍板。  
不要把 B2 混进第一轮。  
现在开始执行。
