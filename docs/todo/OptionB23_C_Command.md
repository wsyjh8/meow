# Cursor_OptionB23_C_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是继续做 Today consumption，也不是直接做 B23-D closeout，更不是开 B2-3 的其它候选项，而是：

> **按这里给定的 Room 1 handoff、Room 2 preflight judgment、Room 5 的 change-highlights-only UI absorption，以及 Room 4 的 phased plan，完成 Option B2-3 的 Phase B23-C：Meow Home + Settlement consumption。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前状态不是 P1 / P2，也不是 Option A / A.1，也不是 Option B（B1），也不是 Option B2-1 / B2-2。  
这些都已经完成并 close。  
Room 1 已正式拍板当前下一方向为：

> **Option B2-3**

但 Room 1 同时明确写死：

> **本轮 B2-3 只进入 `change_highlights[]`。**

也就是说：

- 本轮**只 pin**：`change_highlights[]`
- 本轮**暂不进入**：
  - `companion_response` typing
  - `source_fact_tags`

你这轮接的不是：
- B23-A（Read-only extension landing）
- B23-B（Today consumption）
- B23-D（Test & closeout）
- `companion_response` typing
- `source_fact_tags`
- 新 endpoint
- 新状态机
- P3

你这轮只做：

> **B23-C — 把 `change_highlights[]` 稳定接入 Meow Home + Settlement bridge。**

---

## 1. 当前已完成到哪里

### B23-A 已完成
当前结论是：
- `change_highlights[]` 已作为 **very small、read-only extension** 落到：
  - `GET /me/secondary-summary`
- 最小 shape 已落地：
  - `kind`
  - `status`
  - `label`
  - `related_item_code`
- 当前 contract 兼容性已成立：
  - 字段缺失时 Flutter 默认 `[]`
  - 字段存在时不破坏现有页面

### B23-B 已完成
当前结论是：
- Today 页已最小新增 `getSecondarySummary()` 并行加载
- `change_highlights[]` 已接入 **Today Companion Card 第二层**
- 默认最多显示 **2 条**
- 空 / 缺失 / 加载失败时退化正常
- hinted / confirmed 区分清楚
- 主 CTA 未被压
- **未碰 Meow Home / Settlement / 后端**
- 总测试：
  - `flutter test` 64/64
  - `flutter analyze` 0 errors
  - `npm test` 16/16
  - `npm run test:e2e` 72/72

### 来自 B23-B 的当前风险提示
- Cursor 已明确写出：
  - **Settlement bridge 的具体接入位置仍需确认**
- 同时 Cursor 也确认：
  - **Meow Home 已加载 secondarySummary（.changeHighlights 已可用）**
  - 所以 B23-C 可以直接开始

你现在接的不是：
- B23-D
- 其它 sync candidate
- 新 contract patch

而是：

> **只做 Meow Home + Settlement 的 change_highlights[] 消费接入。**

---

## 2. 这轮你到底要做什么

这轮只做：

1. 把 `change_highlights[]` 接到：
   - **Meow Home 的“今日重点变化区”**
   - **Settlement 的“轻摘要 bridge 区”**
2. 保持 Meow Home / Settlement 主结构不被重写
3. 按 Room 5 absorption 的边界：
   - Meow Home 默认最多显示 **3 条**
   - Settlement 默认 **1 条**，最多 **2 条**
   - Meow Home 是“今日重点变化区”，**不是最近变化 feed**
   - Settlement 只是“去看看今天变化”的轻桥接，**不是厚重结算页**
4. hinted / confirmed 继续严格区分
5. 若 Settlement 当前接入位不清楚，选择**最小合法接入点**
6. 更新 / 补齐与 Meow Home / Settlement consumption 相关的 Flutter tests / regression
7. 输出本轮 handoff 文档

这轮**不做**：
- 不改 B23-A contract
- 不再改 Today 主结构
- 不做 `companion_response` typing
- 不做 `source_fact_tags`
- 不新增 endpoint
- 不新增 interaction backend action
- 不新增状态机
- 不做 timeline / activity feed / history page
- 不把 B2-3 扩成 P3

一句话：

> **B23-C 是 Meow Home + Settlement 的轻消费接入，不是新变化系统。**

---

## 3. 你必须接受的上游结论

### 3.1 Room 1 已正式拍板：`change_highlights[] only`
本轮不是三项候选一起进。  
Room 1 已正式 pin：

- enter: `change_highlights[]`
- not in this round:
  - `companion_response` typing
  - `source_fact_tags`

### 3.2 Room 1 已明确推荐顺序
Room 1 handoff 已明确：
- B23-A — Read-only extension landing
- B23-B — Today consumption
- **B23-C — Meow Home + Settlement consumption**
- B23-D — Test & closeout

### 3.3 Room 2 已给出最小 technical proposal
Room 2 已明确：
- 这轮只能是 **very small patch**
- `change_highlights[]` 只是 **read-only response extension**
- 不能重写主 API / DB 结构
- 不能开新状态机
- 不能扩大成新系统

### 3.4 Room 5 已给出的 Meow Home / Settlement absorption 边界
虽然你看不到原文，但你必须服从以下已定边界：

#### Meow Home 默认定位
`change_highlights[]` 在 Meow Home 默认放在：

> **今日重点变化区**

不是最近变化 feed，不是 timeline，不是历史页。

#### Meow Home 默认展示规则
- 默认最多显示 **3 条**
- 应放在猫猫主体区下方、状态泡泡上方，或与状态泡泡同层但次一级
- 以单行 highlight item 为主，不做长卡片
- 无 highlights 时：
  - 可以直接隐藏该区
  - 或退化成一句轻承接文案
  - 不要做空大块占位

#### Settlement 默认定位
Settlement 只允许做：

> **1 条默认、最多 2 条的轻摘要 bridge**

作用是：
- 更具体地告诉用户“去看看今天有什么变化”
- 帮助用户自然跳向 Meow Home / Customize

不是：
- 新结算主层
- 新变化主叙事层
- 手游式厚重奖励堆叠

#### Settlement 默认展示规则
- 默认 1 条，最多 2 条
- 放在结算奖励摘要下方、弱 CTA 上方，或与弱 CTA 同层
- 文气更轻，更像 bridge
- 无 highlights 时可直接不显示

---

## 4. 你必须服从的强断言

### 4.1 这轮只接 Meow Home + Settlement，不改 Today
你可以：
- 修改 Meow Home 页面中 secondary summary 的渲染位
- 在 Settlement bridge 区接入 `change_highlights[]`
- 做最小显示逻辑 / fallback / 截断 / priority
- 增加 Meow Home / Settlement 相关 tests

但你不能：
- 回头重写 Today 主结构
- 提前做 B23-D closeout

### 4.2 `change_highlights[]` 不是新真相层
它只能是：

> **read-only summary / hint layer**

它不能替代：
- ownership
- equipment
- reward settlement / reward ledger
- check_in / learning_day / streak
- level / balance / purchase truth

### 4.3 hinted ≠ confirmed
任何实现与测试都必须继续严格区分：
- hinted：只能是去看看 / 好像 / 可查看变化线索
- confirmed：也只是可承接摘要，仍然不自动替代现有真相层

### 4.4 Meow Home 不能长成 feed，Settlement 不能做厚
你必须继续守住：
- Meow Home = 今日重点变化区
- 不是最近变化 feed / timeline
- Settlement = 轻 bridge
- 不是新主结算层

### 4.5 不能顺手带入其它候选
以下这轮绝对不能带进去：
- `companion_response.response_type`
- `source_fact_tags`
- 新 endpoint
- interaction backend action
- timeline / feed / audit history
- 新业务规则
- 新状态机

---

## 5. 这轮的正确目标

根据 Room 1 handoff、Room 2 preflight、Room 5 absorption 与 Room 4 phases，B23-C 的目标是：

> **把 `change_highlights[]` 以最小、轻量、不越真相边界的方式接到 Meow Home + Settlement。**

这轮必须交付的，不是“更大的变化系统”，而是：

1. Meow Home 已稳定消费 `change_highlights[]`
2. Settlement 已有更具体的“去看看今天变化” bridge
3. 无 highlights 时退化正常
4. hinted / confirmed 边界保持
5. 不越权到其它候选项或新系统

---

## 6. 这轮 in scope

### 6.1 先确认 Meow Home 当前数据流（必须）
请先确认：
- Meow Home 当前是否已经读 `secondarySummary`
- `changeHighlights` 当前是否已在模型中可用
- 现有页面最自然的接入位置在哪

优先采用：
- 最小 UI 增量
- 最小模型改动
- 最小布局改动

### 6.2 接入 Meow Home“今日重点变化区”（必须）
请把 `change_highlights[]` 接到：

> **Meow Home 的今日重点变化区**

要求：
- 默认最多 **3 条**
- 单行 / 小块为主
- 不做大卡片 feed
- 不抢猫猫主体区主视觉

### 6.3 无 highlights 时 Meow Home 退化（必须）
如果：
- `change_highlights[]` 字段缺失
- `change_highlights[] = []`
- 当前 secondary summary 暂不可得

则必须：
- 可直接隐藏该区
- 或使用一句轻承接文案
- 不留空大块骨架

### 6.4 接入 Settlement 轻 bridge（必须）
请把 `change_highlights[]` 接到：

> **Settlement 的轻摘要 bridge 区**

要求：
- 默认 **1 条**，最多 **2 条**
- 更像“去看看今天变化”的引导
- 不新增厚重奖励层
- 不重写结算主结构

### 6.5 Settlement 接入位选择（必须）
Cursor 上轮已明确指出：
- **Settlement bridge 的具体接入位置需确认**

你这轮必须做这个选择，但必须遵守：
- 选**最小合法接入点**
- 不重构 Settlement 页面
- 不做新卡片体系

### 6.6 hinted / confirmed 的 Meow Home / Settlement 呈现（必须）
请在这两个页面继续保持：

#### `hinted`
- 中性
- 引导去看
- 不能写成已确认获得

#### `confirmed`
- 可作为轻摘要
- 但仍不能替代现有真相层

### 6.7 若需要 very small layout repair（允许）
如果接入后出现：
- 变化区与现有组件层级冲突
- 文案过长挤坏布局
- highlight item 显著不清楚

你可以做：
- very small layout repair
- very small truncation / priority / chip 样式微调

但前提是：
- 不重排页面主结构
- 不扩大为 B23-D / 大 polish
- 不做新组件体系

---

## 7. 这轮明确不做什么

### 7.1 不做 B23-D
以下内容留给最后一轮：
- 全量 regression closeout
- close bar judgment
- final recommendation to Room 1

### 7.2 不做 B2-3 其它候选
- 不做 `companion_response` typing
- 不做 `source_fact_tags`

### 7.3 不改主结构
- 不改 DB 主结构
- 不改 API 主结构
- 不改 purchase / equip / reward / streak 主语义
- 不改 persistence 主结构

### 7.4 不重做 Meow Home / Settlement 主结构
- 不重写 Meow Home 主体布局
- 不重写结算主层
- 不新增 timeline / history / activity feed

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 当前 handoff / preflight / UI absorption
- `R1_to_R4_OptionB23_change_highlights_only_Implementation_Handoff_v0.1.md`
- `R2_OptionB2_B23_Preflight_v0.1.2.md`
- `UI_SPEC_OptionB23_change_highlights_v0.1.1.md`
- `b3_phases.md`
- `回B23-A.md`
- `回B23-B.md`

### 8.2 当前 active runtime basis
- `Main_updated_2026-04-04_v11.md`
- `STATUS_updated_2026-04-04_v10.md`
- `BR-OPP-001_v0.1.5.md`
- `背单词喵喵app_DB设计草案_v0.1.4.md`
- `背单词喵喵app_API设计草案_v0.1.3.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `UI_SPEC_OptionB2_v0.1.1.md`

### 8.3 代码真实入口
至少盘点这些真实代码位置：
- Meow Home 页面当前 widget / section 结构
- Settlement 当前 bridge / weak CTA 附近的结构
- secondary summary model / parsing / client
- `change_highlights[]` 当前前端模型位置
- Meow Home / Settlement regression tests 入口

### 8.4 当前测试入口
至少盘点：
- Flutter Meow Home widget tests
- Settlement 相关 widget / integration tests（若无，需记录）
- B23-A / B23-B regression 入口
- B2-2 / Option B regression 入口（确保不误伤）

---

## 9. B23-C 你必须明确回答的问题

### Q1. Meow Home 最终怎么接了 `change_highlights[]`
请明确：
- 接在哪个 section / 区块
- 是否保持为“今日重点变化区”
- 是否避免了 feed / timeline 化

### Q2. Settlement 最终怎么接了 `change_highlights[]`
请明确：
- 接在哪个 bridge 区 / 弱 CTA 邻近区
- 默认几条
- 为什么没有把结算层做厚

### Q3. 无 highlights 时如何退化
请明确：
- 字段缺失
- 空数组
- secondarySummary 暂不可得
这三种情况下，Meow Home / Settlement 分别怎么稳定处理

### Q4. hinted / confirmed 在 Meow Home / Settlement 如何呈现
请明确：
- hinted 用了什么语气
- confirmed 用了什么语气
- 为什么不会被误读成新真相层

### Q5. 这轮如何保证没越界
请明确：
- 没有做 `companion_response` typing
- 没有做 `source_fact_tags`
- 没有新增 endpoint / 新状态机 / 新规则
- 没有做 timeline / history / feed
- 没有重构主结构

### Q6. B23-D 最自然的开工点是什么
请给出最小建议：
- 哪些 regression 要先收
- 哪些 truth-boundary case 最该先补
- 哪些 fallback / degraded cases 最该先补

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. Meow Home 今日重点变化区接入 `change_highlights[]`
2. Settlement 轻 bridge 接入 `change_highlights[]`
3. 最小 display / fallback / rendering / truncation 逻辑
4. 增加 Meow Home / Settlement 相关 widget / regression tests
5. 做 very small docs sync（只记录 B23-C 新事实）

### 不允许做的
1. 不新增 endpoint
2. 不新增业务字段
3. 不改业务规则
4. 不改 DB / API 主结构
5. 不把 `companion_response` typing / `source_fact_tags` 混进来
6. 不做 feed / timeline / history UI
7. 不把这轮做成 Meow Home / Settlement 大改版

如果你做了任何超出 B23-C 的事，必须解释为什么仍算 Meow Home + Settlement consumption，而不是 scope creep。

---

## 11. 这轮最小测试 / 验证要求

### 11.1 Flutter / front-end
至少执行：
```bash
flutter pub get
flutter test
flutter analyze
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.2 Node / backend
如果你只是动了前端消费，backend 不一定要改；  
若你因测试入口或 minor parsing 触碰了 backend / e2e，请至少执行：
```bash
npm test
npm run test:e2e
```

### 11.3 B23-C 专项验证
至少完成这些验证：
1. Meow Home 已稳定消费 `change_highlights[]`
2. Settlement 已有轻 bridge
3. Meow Home 最多 3 条
4. Settlement 默认 1 条、最多 2 条
5. 无 highlights 时退化正常
6. hinted ≠ confirmed
7. 没有越界进入 B23-D
8. 没有带入 `companion_response` typing / `source_fact_tags`

### 11.4 建议额外覆盖
- Meow Home widget tests
- Settlement bridge tests（若现有无直接入口，可在 page-level test 覆盖）
- 缺失字段 / 空数组 / 有 1 条 / 超上限 的分支
- B23-A / B23-B contract parsing regression

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — 状态文件更新
请更新：

```text
docs/R4_OptionB23_change_highlights_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 B23-C）
2. 实现范围
3. 未实现范围
4. 是否出现 scope creep
5. truth boundary 是否保持
6. 当前是否建议继续进入 B23-D

### Deliverable B — 测试摘要更新
请更新：

```text
docs/R4_OptionB23_change_highlights_Test_Summary_v0.1.md
```

至少包含：
1. Flutter / widget / regression 入口
2. 哪些页面块已接入
3. hinted vs confirmed 是否测试
4. 无字段 / 空数组 / fallback 是否覆盖
5. 是否触碰现有 API / DB 主结构
6. 是否有 B2-3 越界

### Deliverable C — Round summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB23_C_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **How Meow Home consumed `change_highlights[]`**
3. **How Settlement consumed `change_highlights[]`**
4. **What fallback behavior is**
5. **What truth boundary was kept**
6. **What backend surface did or did not change**
7. **What is still not done**
8. **What must be done next**
9. **What not to touch**
10. **Files / modules to read first**
11. **Current risks**
12. **Whether ready for B23-D**

### Optional
若你认为必须，才允许新增：

```text
docs/R4_OptionB23_change_highlights_issue_note_v0.1.md
```

但只有在你发现：
- Settlement bridge 没有清晰可落点
- 或 Room 2 proposal / Room 5 absorption 仍有实现歧义

时才交，不要默认制造新 patch。

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B23-C 完成：

1. Meow Home 今日重点变化区已稳定消费 `change_highlights[]`
2. Settlement 轻 bridge 已稳定消费 `change_highlights[]`
3. Meow Home 默认最多 3 条
4. Settlement 默认 1 条、最多 2 条
5. 无 highlights 时退化正常
6. hinted vs confirmed 边界仍清楚
7. 没有改主 endpoint 语义
8. 没有新增 endpoint / 状态机 / interaction backend action
9. `companion_response` typing / `source_fact_tags` 未被带入
10. `docs/R4_OptionB23_change_highlights_Status_v0.1.md` 已更新
11. `docs/R4_OptionB23_change_highlights_Test_Summary_v0.1.md` 已更新
12. `docs/R4_cursor_round_summary_OptionB23_C_v0.1.md` 已生成
13. 最终能明确回答：是否 ready for **B23-D**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 **Option B2-3 / B23-C / Meow Home + Settlement consumption**
- 明确不是 B23-D

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 B23-C 结果
请按这几项写清楚：
1. Meow Home landing point
2. Settlement landing point
3. fallback behavior
4. truth boundary
5. backend touched or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 若 backend / e2e 被影响：`npm test` / `npm run test:e2e`
- B23-C 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB23_change_highlights_Status_v0.1.md`
- `docs/R4_OptionB23_change_highlights_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB23_C_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B23-C**
2. 是否 ready for **B23-D**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你做 closeout，也不是让你把 B2-3 扩成新系统。

这轮唯一要做好的事情是：

> **把 `change_highlights[]` 以最小、轻量、不越真相边界的方式接到 Meow Home + Settlement。**

不要扩 scope。  
不要偷拍板。  
不要把 B23-D 或其它候选项混进来。  
现在开始执行。
