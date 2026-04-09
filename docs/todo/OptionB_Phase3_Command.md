# Cursor_OptionB_Phase3_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接改 Customize，也不是扩文案池，而是：

> **按这里给定的 Room 1 handoff、Room 5 的 Option B UI 方案、以及 Room 4 的 execution-side scope，完成 Option B 的 Phase 3：Today Companion Card + 承接优化。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前状态不是 P1 / P2，也不是 Option A / Option A.1。  
这些都已经完成并 close。  
Room 1 已正式拍板下一方向为：

> **Option B — Visual Polish & Content Expansion**

但 Option B 的**第一轮默认只做 B1，不自动进入 B2**。  
Phase 0、Phase 1、Phase 2 已完成，当前结论是：

- B1 / B2 边界已钉死
- interaction 的 B1 边界已钉死
- catalog 扩容不进首轮已钉死
- 第一轮 Done bar 已钉死
- 全局主题与共享组件已建立
- Meow Home 已重排完成
- `flutter test` 44/44 passed（Phase 2 回执）
- `flutter analyze` 0 errors

你现在接的不是 Phase 4 / 5，而是：

> **Phase 3 — Today Companion Card + 承接优化**

---

## 1. 这轮你到底要做什么

这轮只做：

1. 在**不改变主学习链路优先级、不新增后端契约**的前提下，优化 Today 页中的副机制承接
2. 把 Today 页里的副机制摘要，从“功能入口”提升成“更温暖、更有吸引力的轻承接卡”
3. 让用户更容易感知：
   - 今天学了之后，猫有回应
   - 有轻变化感
   - 可以自然去看看喵喵变化
4. 同时必须继续保证：
   - 主 CTA 仍然最强
   - 学习优先级不被 Companion Card 抢走
5. 复用 Phase 1 的 theme / shared components
6. 保持现有业务逻辑不变
7. 更新 / 补齐 Today 页相关 Flutter tests
8. 输出本轮 handoff 文档

这轮**不做**：
- 不开始 Customize 结构升级
- 不扩 companion copy 池
- 不扩 catalog
- 不新增 API
- 不改 DB / API / persistence
- 不做 interaction 业务化
- 不改主机制规则 / CTA winner 业务规则
- 不做统计页

一句话：

> **Phase 3 是优化 Today 页里的“副机制承接层”，不是改主机制真相层。**

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

### 3.2 Today 页最容易出错的地方：polish 压过主学习 CTA
这轮最重要的强断言是：

> **主学习 CTA 仍然必须是 Today 页最强按钮。**

不允许出现：
- Companion Card 比主任务卡更抢眼
- “去看看喵喵变化”比“开始学习 / 去复习 / 继续本组复习”更强
- 为了温暖感和变化感，把主线做成次级存在

### 3.3 Option B 继续继承 truth / degraded-state guardrails
Option B 是 polish round，不是 persistence round。  
所以必须继续继承 `UI_SPEC_v0.1.4.md` 中已经写硬的 guardrails：

- `delayed snapshot ≠ fresh backend truth`
- `pending reward / settling reward ≠ 到账成功`
- `maintenance / read_only / temporarily_unavailable` 不能包装成成功
- UI 不能为了“更有变化感”而改写业务状态语义

### 3.4 “今天有变化”只能做承接，不得伪确认
当前后端**没有**直接提供 `change_highlights[]` 这种“今天变化列表”真相字段。  
因此：
- 你可以做 **UI 承接文案**
- 可以做轻变化提示
- 但不能把它写成“后端已经确认发生的业务事实”

### 3.5 Room 4 不是 UI / UX owner
你不能把实现便利包装成 UI 决策。  
视觉方向、页面层级和交互表达，以 Room 5 的 `UI_SPEC_OptionB_v0.1.2.md` 为准。  
Room 4 / Cursor 只能：
- 实现 Today 页 Companion Card 与承接优化
- 对缺口提 sync patch 需求
- 不能擅自拍板最终视觉方案

---

## 4. 这轮的正确目标

根据 Room 4 当前已经固定的 `optionB_phases`，Phase 3 的目标是：

> **优化 Today 页里的副机制承接，但不压主学习链路。**

这轮必须交付的，不是“Today 变成副机制首页”，而是：

1. 一个更温暖、更有层级的 Companion Card
2. 更自然的“今天学了之后，猫有回应”的感觉
3. 更好的签到 / streak 区块视觉整合（仅表现层）
4. 结算返回后的轻承接提示优化
5. 所有这些都服从：**学习优先**

---

## 5. 这轮 in scope

### 5.1 Companion Card（必须）
请把 Today 页里的副机制摘要区，升级成更温暖的 **Companion Card**：

至少应包含：
1. 一句猫猫回应 / greeting / companion_response
2. 轻视觉层级：比普通摘要卡更柔和，但弱于主任务卡
3. 可承接“今天有变化 / 去看看喵喵变化”的弱动作
4. 若有合适位置，可展示轻量 secondary summary 片段（不要做厚 HUD）

### 5.2 主 CTA 层级强化（必须）
Today 页主 CTA 必须更明确，且始终强于 Companion Card。  
你可以在视觉上：
- 提升主任务卡聚焦
- 提高主 CTA 对比度与层级
- 让 Companion Card 更柔和、更偏辅助

但禁止：
- 弱化主 CTA
- 让 Companion Card 像 hero 区
- 让用户第一眼更想点“看猫”而不是“开始学习”

### 5.3 签到 / streak 区块轻优化（允许）
在不改业务语义的前提下，可以优化：
- 签到区块视觉层级
- streak 显示更友好
- 日常温暖感更自然

但不允许：
- 改 `check_in / learning_day / streak` 规则
- 把签到成功写成有效学习完成
- 把 streak 写成别的口径

### 5.4 结算返回的轻承接提示（允许）
你这轮可以优化：
- 从主机制结算层返回 Today 后的轻提示
- 如：`去看看喵喵今天的小变化`
- 或更自然的承接文案 / 小条幅 / 小卡片

但不允许：
- 做成厚重手游结算页
- 重复大动画
- 把结算已触发 / 已展示写成奖励已到账成功

### 5.5 今日变化感（允许，但有边界）
这轮可以做一种**弱变化感承接**，例如：
- 小文案提示
- Companion Card 中的变化句
- UI 比较式小提示

但必须满足：
- 默认属于 **UI 承接文案**
- 不表达成已确认业务事实
- 不假装后台已经返回了 `change_highlights[]`

### 5.6 数据来源建议
这轮推荐优先用当前已有的：
- Today 聚合接口
- secondary summary
- settlement 返回后的已存在状态
- companion_response

如要做“变化感”，优先：
- 以前端比较前后 snapshot 的**轻提示**
- 或直接使用静态承接 copy
- 不新增字段

---

## 6. 这轮明确不做什么

### 6.1 不改后端
- 不改 `/me/today`
- 不改 `/me/secondary-summary`
- 不改 settlement API
- 不改 persistence

### 6.2 不扩内容池
- 不新增 companion copy pool
- 不新增“今日变化”真相字段
- 不新增 catalog item

### 6.3 不做其他页面
以下都留到后续 phase：
- Customize 顶部预览区
- tabs / segmented control
- 商店 / 我的物品页结构升级
- companion copy 小扩池与 closeout

### 6.4 不改变业务事实表达
- 不把 pending 写成到账成功
- 不把 delayed snapshot 写成 fresh truth
- 不把前端比较变化写成后端已确认变化
- 不把签到写成学习完成
- 不把 Companion Card 写成主流程 CTA

---

## 7. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 7.1 Phase 0 / 1 / 2 产物
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase0_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase1_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase2_v0.1.md`

### 7.2 产品 / UI 输入
- `message7_R1toR4.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `OptionB_scope_v0.1.1.md`
- `optionB_phases.md`
- `UI_SPEC_v0.1.4.md`
- `R4_OptionB_Analysis_and_Execution_Plan_v0.1.md`

### 7.3 Flutter 入口与页面
至少盘点这些现有入口：
- `TodayPage` / 今日页相关 widgets
- 主 CTA 所在任务卡
- companion / secondary summary 相关 widget
- 签到 / streak 区块
- 结算返回后的提示入口
- shared theme / components / animations

### 7.4 当前测试入口
至少盘点：
- Today 页 widget tests
- 主 CTA / summary / streak / check-in 相关前端测试
- 页面 smoke tests
- 若有 settlement return UI tests 也要看

---

## 8. Phase 3 你必须明确回答的问题

### Q1. Today 页最终的层级是什么
请明确描述：
- 主任务卡
- 主 CTA
- Companion Card
- 签到 / streak 区块
- 次级入口

### Q2. Companion Card 具体怎么做
请明确：
- 展示了哪些字段 / 文案
- 视觉层级如何弱于主 CTA
- 变化感如何表达
- 哪些地方只是 UI 承接，不是业务事实

### Q3. 结算返回承接现在如何更自然
请明确：
- 有没有增加轻承接提示
- 是怎样的 UI 形式
- 为什么它不算“重手游结算感”

### Q4. 这轮如何保证没越界到 Phase 4–5
请明确：
- 没有改 Customize
- 没有扩 catalog
- 没有扩 companion copy 池
- 没有新增 API
- 没有改业务规则

### Q5. Phase 4 最自然的开工点是什么
请给出最小建议：
- Customize 哪个 widget 最适合先拆
- 顶部预览区怎么最稳
- 哪些测试最该先跟进

---

## 9. 这轮允许做什么，不允许做什么

### 允许做的
1. 重排 Today 页中的副机制承接层
2. 强化主 CTA 层级
3. 做 Companion Card
4. 做结算返回轻承接优化
5. 轻优化签到 / streak 视觉层
6. 更新 / 新增 widget tests
7. 做 very small docs sync（只记录 Phase 3 新事实）

### 不允许做的
1. 不改后端 API
2. 不扩 catalog
3. 不扩文案池
4. 不新增业务字段
5. 不改 Customize
6. 不改业务规则
7. 不改 DB / API / persistence

如果你做了任何超出 Phase 3 的事，必须解释为什么仍算 Today 承接层优化，而不是 scope creep。

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

### 10.2 Phase 3 专项验证
至少完成这些验证：
1. Companion Card 已更温暖、更有层级
2. 主 CTA 仍然是 Today 页最强动作
3. 副机制承接不压主线
4. 结算返回提示更自然
5. truth / degraded-state 表达不越界
6. 没有越界进入 Customize / B2

### 10.3 建议额外覆盖
如果范围允许，建议补：
- Today 页 widget tests
- 主 CTA 层级检查
- Companion Card 可见性 / 文案正确性
- degraded-state / delayed snapshot 表达检查
- settlement return UI smoke

---

## 11. 本轮必须产出的文件（硬要求）

### Deliverable A — Option B status 更新
请更新：

```text
docs/R4_OptionB_Status_v0.1.md
```

至少补：
1. 当前完成到哪个 phase（必须写 Phase 3）
2. 已实现范围
3. 未实现范围
4. assumptions
5. blockers
6. risks
7. 当前是否允许进入 Phase 4

### Deliverable B — Option B test entry 更新
请更新：

```text
docs/R4_OptionB_Test_Entry_v0.1.md
```

至少补：
- Phase 3 影响到的 widget / page / smoke tests
- 哪些 Today 页 tests 已更新
- 哪些回归要带到 Phase 4

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB_Phase3_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **How Today is now structured**
3. **What Companion Card now does**
4. **What truth boundary was kept**
5. **What pages were not touched**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**

---

## 12. 这轮完成标准（严格）

以下全部满足，才算 Phase 3 完成：

1. Today 页的 Companion Card 已落地
2. 主 CTA 仍然是 Today 页最强层级
3. 结算返回承接已更自然
4. 没有把“变化感”写成后端已确认事实
5. 没有改后端契约
6. `docs/R4_OptionB_Status_v0.1.md` 已更新
7. `docs/R4_OptionB_Test_Entry_v0.1.md` 已更新
8. `docs/R4_cursor_round_summary_OptionB_Phase3_v0.1.md` 已生成
9. 最终能明确回答：是否 ready for **Phase 4**

---

## 13. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B Phase 3（Today Companion Card + 承接优化），不是 Phase 4 Customize 改版

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 Today 结果
请按这几项写清楚：
1. main task card
2. main CTA hierarchy
3. companion card
4. streak / check-in visual
5. truth boundary
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 是否跑了后端命令（如果没跑请说明为什么）
- Phase 3 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase3_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **Option B Phase 3**
2. 是否 ready for **Phase 4**
3. 当前最大的剩余风险是什么

---

## 14. 最后提醒

这轮不是让你开始改 Customize 或扩内容池。

这轮唯一要做好的事情是：

> **把 Today 页里的副机制承接做得更温暖、更自然，但继续让学习主线站在最前面。**

不要扩 scope。  
不要偷拍板。  
不要把 B2 混进来。  
现在开始执行。
