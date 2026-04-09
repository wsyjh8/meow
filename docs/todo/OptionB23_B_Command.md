# Cursor_OptionB23_B_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是继续做 B23-A 的 contract landing，也不是开 Meow Home / Settlement 消费，更不是开 B2-3 的其它候选项，而是：

> **按这里给定的 Room 1 handoff、Room 2 preflight judgment、Room 5 的 change-highlights-only UI absorption，以及 Room 4 的 phased plan，完成 Option B2-3 的 Phase B23-B：Today consumption。**

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
- B23-C（Meow Home + Settlement consumption）
- B23-D（Test & closeout）
- `companion_response` typing
- `source_fact_tags`
- 新 endpoint
- 新状态机
- P3

你这轮只做：

> **B23-B — 把 `change_highlights[]` 稳定接入 Today Companion Card 第二层。**

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
- 未做：
  - `companion_response` typing
  - `source_fact_tags`
  - 新 endpoint
  - 新状态机
  - Today / Meow Home / Settlement UI

### 当前风险提示（来自 B23-A）
- Today 页目前可能主要依赖 `getToday()`，
- 不一定已经加载 `secondarySummary`
- 因此 B23-B 首先要确认 Today 的数据流是否需要新增 `getSecondarySummary()` 调用
- 但这仍属于 B23-B 合法范围，不构成回退到 B23-A 的 blocker

---

## 2. 这轮你到底要做什么

这轮只做：

1. 把 `change_highlights[]` 接到：
   - **Today Companion Card 第二层**
2. 保持 Today 的页面结构不被重写
3. 按 Room 5 absorption 的边界：
   - 默认最多显示 **2 条**
   - 不额外再起一整条平行“大今日变化条”
   - 无 highlights 时退化回普通 Companion Card 第二层文案
   - 不压主学习 CTA
4. hinted / confirmed 继续严格区分
5. 若 Today 当前没有 secondary summary 数据流，做 **最小合法接入**
6. 更新 / 补齐与 Today consumption 相关的 Flutter tests / regression
7. 输出本轮 handoff 文档

这轮**不做**：
- 不接 Meow Home UI
- 不接 Settlement UI
- 不做 `companion_response` typing
- 不做 `source_fact_tags`
- 不新增 endpoint
- 不新增 interaction backend action
- 不新增状态机
- 不做 timeline / activity feed / history page
- 不重排 Today 主结构
- 不把 B2-3 扩成 P3

一句话：

> **B23-B 是 Today 的轻消费接入，不是 Today 重做轮。**

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
- **B23-B — Today consumption**
- B23-C — Meow Home + Settlement consumption
- B23-D — Test & closeout

### 3.3 Room 2 已给出最小 technical proposal
Room 2 已明确：
- 这轮只能是 **very small patch**
- `change_highlights[]` 只是 **read-only response extension**
- 不能重写主 API / DB 结构
- 不能开新状态机
- 不能扩大成新系统

### 3.4 Room 5 已给出的 Today absorption 边界
虽然你看不到原文，但你必须服从以下已定边界：

#### Today 默认定位
`change_highlights[]` 在 Today 默认放在：

> **Today Companion Card 第二层 = “今日变化承接块”**

不是再单独做一整条平行大卡。

#### Today 默认展示规则
- 默认最多显示 **2 条**
- 优先顺序建议：
  1. `confirmed` 的 growth / equip / purchase / streak
  2. `confirmed` 的 post_learning
  3. `hinted` 的可查看线索
- 无 highlights 时：
  - 不做空白区
  - 退化回普通 Companion Card 第二层文案
  - 示例可用：
    - `今天继续学一点，它也许会有新变化。`

#### Today 不允许
- 不把 `hinted` 渲染成“已获得 / 已到账 / 已升级”
- 不把 Companion Card 做成变化历史流
- 不让 highlights 挤掉主学习 CTA

---

## 4. 你必须服从的强断言

### 4.1 这轮只接 Today，不接其它页面
你可以：
- 修改 Today Companion Card / Today 副机制摘要块
- 调整 Today 第二层的显示逻辑
- 最小接入 secondary summary 数据流
- 增加 Today 相关 tests

但你不能：
- 直接接 Meow Home
- 直接接 Settlement
- 提前做 B23-C / B23-D

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

### 4.4 不压主 CTA
Today 页的第一目标仍然是：
- 学习优先
- 主学习 CTA 最强

`change_highlights[]` 的接入必须服从：
- 不重排 Today 主体结构
- 不压主 CTA
- 不让副机制承接块变成视觉主角

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

根据 Room 1 handoff、Room 2 preflight、Room 5 absorption 与 Room 4 phases，B23-B 的目标是：

> **把 `change_highlights[]` 以最小、温和、不压主 CTA 的方式接到 Today Companion Card 第二层。**

这轮必须交付的，不是“Today 变化感大改版”，而是：

1. Today 已稳定消费 `change_highlights[]`
2. 无 highlights 时退化正常
3. hinted / confirmed 边界保持
4. 主学习 CTA 不被压
5. 不越权到其它页面和其它候选项

---

## 6. 这轮 in scope

### 6.1 先确认 Today 当前数据流（必须）
请先确认：
- Today 页当前到底读哪些数据
- 是否已有 `secondarySummary`
- 如果没有，最小合法接入点在哪里

优先采用：
- 最小新调用
- 最小状态接入
- 最小模型改动

不要顺手重构 Today 全部数据流。

### 6.2 接入 Companion Card 第二层（必须）
请把 `change_highlights[]` 接到：

> **Today Companion Card 第二层**

要求：
- 第二层承接“今天有变化可看”
- 不新增一整条平行大变化卡
- 仍保留当前 Companion Card 的陪伴感

### 6.3 默认最多 2 条（必须）
Today 默认最多展示：
- **2 条**

不要在 Today 堆更多。

### 6.4 无 highlights 时退化（必须）
如果：
- `change_highlights[]` 字段缺失
- `change_highlights[] = []`
- 当前 secondary summary 暂不可得

则必须：
- 退化回普通 Companion Card 第二层文案
- 不留空白骨架坑
- 不假装有变化

### 6.5 hinted / confirmed 的 Today 呈现（必须）
请在 Today 保持：

#### `hinted`
- 中性
- 引导去看
- 不能写成已确认获得

#### `confirmed`
- 可作为轻摘要
- 但仍不能替代现有真相层

### 6.6 如果需要新的 secondarySummary 加载（允许）
如果 Today 当前没有 secondary summary 数据流，你可以：
- 最小新增 `getSecondarySummary()` 调用
- 最小整合到 Today 页面状态中

但前提是：
- 不重构 Today 整体架构
- 不扩大成 B23-C / B23-D 范围
- 不制造新的 contract patch

---

## 7. 这轮明确不做什么

### 7.1 不做 B23-C
以下内容留给下一轮：
- Meow Home 今日重点变化区
- Settlement 承接区 1–2 条轻摘要桥接

### 7.2 不做 B23-D
以下内容留给最后一轮：
- 全量 regression closeout
- close bar judgment
- final recommendation to Room 1

### 7.3 不做 B2-3 其它候选
- 不做 `companion_response` typing
- 不做 `source_fact_tags`

### 7.4 不改主结构
- 不改 DB 主结构
- 不改 API 主结构
- 不改 purchase / equip / reward / streak 主语义
- 不改 persistence 主结构

### 7.5 不重排 Today 主结构
- 不重做 Today 核心任务卡
- 不动主 CTA winner 规则
- 不动 Session / check-in / daily goal 主结构

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 当前 handoff / preflight / UI absorption
- `R1_to_R4_OptionB23_change_highlights_only_Implementation_Handoff_v0.1.md`
- `R2_OptionB2_B23_Preflight_v0.1.2.md`
- `UI_SPEC_OptionB23_change_highlights_v0.1.1.md`
- `b3_phases.md`
- `回B23-A.md`

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
- Today 页当前 widget / card 结构
- Today 当前是否读 `secondarySummary`
- 当前 Companion Card 第二层在哪里
- secondary summary model / parsing / client
- `change_highlights[]` 当前前端模型位置
- 任何 Today regression tests 入口

### 8.4 当前测试入口
至少盘点：
- Flutter Today page widget tests
- backend e2e（作为 contract 已落地基线）
- B23-A regression 入口
- B2-2 / Option B regression 入口（确保不误伤）

---

## 9. B23-B 你必须明确回答的问题

### Q1. Today 最终怎么接了 `change_highlights[]`
请明确：
- 接在哪个 widget / card
- 是否保持在 Companion Card 第二层
- 是否避免了额外大变化卡

### Q2. 无 highlights 时如何退化
请明确：
- 字段缺失
- 空数组
- secondarySummary 暂不可得
这三种情况下分别怎么稳定处理

### Q3. 这轮如何保证不压主 CTA
请明确：
- 页面层级有没有变
- 为什么不会把副机制承接块做成 Today 主角

### Q4. hinted / confirmed 在 Today 如何呈现
请明确：
- hinted 用了什么语气
- confirmed 用了什么语气
- 为什么不会被误读成新真相层

### Q5. 这轮如何保证没越界
请明确：
- 没有做 `companion_response` typing
- 没有做 `source_fact_tags`
- 没有接 Meow Home / Settlement
- 没有新增 endpoint / 新状态机 / 新规则

### Q6. B23-C 最自然的开工点是什么
请给出最小建议：
- Meow Home 应先接哪个区块
- Settlement 应先接哪个 bridge 区
- 哪些 tests 最该先跟进

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. Today Companion Card 第二层接入 `change_highlights[]`
2. 最小新增 secondary summary 数据流（若需要）
3. Today 相关最小 display / fallback / rendering 逻辑
4. 增加 Today 相关 widget / regression tests
5. 做 very small docs sync（只记录 B23-B 新事实）

### 不允许做的
1. 不新增 endpoint
2. 不新增业务字段
3. 不改业务规则
4. 不改 DB / API 主结构
5. 不把 `companion_response` typing / `source_fact_tags` 混进来
6. 不接 Meow Home / Settlement UI
7. 不把这轮做成 Today 大改版

如果你做了任何超出 B23-B 的事，必须解释为什么仍算 Today consumption，而不是 scope creep。

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
若你因数据流接入或测试入口触碰了 backend / e2e，请至少执行：
```bash
npm test
npm run test:e2e
```

### 11.3 B23-B 专项验证
至少完成这些验证：
1. Today 已稳定消费 `change_highlights[]`
2. 默认最多 2 条
3. 无 highlights 时退化正常
4. hinted ≠ confirmed
5. 主 CTA 没被压
6. 没有越界进入 B23-C / B23-D
7. 没有带入 `companion_response` typing / `source_fact_tags`

### 11.4 建议额外覆盖
- Today Companion Card widget tests
- 缺失字段 / 空数组 / 有 1 条 / 有 2+ 条 的分支
- 主 CTA 仍存在且层级不变
- B23-A contract parsing regression

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — 状态文件更新
请更新：

```text
docs/R4_OptionB23_change_highlights_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 B23-B）
2. 实现范围
3. 未实现范围
4. 是否出现 scope creep
5. truth boundary 是否保持
6. 当前是否建议继续进入 B23-C

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
docs/R4_cursor_round_summary_OptionB23_B_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **How Today consumed `change_highlights[]`**
3. **What fallback behavior is**
4. **What truth boundary was kept**
5. **What backend surface did or did not change**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**
11. **Whether ready for B23-C**

### Optional
若你认为必须，才允许新增：

```text
docs/R4_OptionB23_change_highlights_issue_note_v0.1.md
```

但只有在你发现：
- Room 2 proposal 仍有实现歧义
- 或 Room 5 absorption 仍存在无法落地点

时才交，不要默认制造新 patch。

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B23-B 完成：

1. Today Companion Card 第二层已稳定消费 `change_highlights[]`
2. 默认最多 2 条
3. 无 highlights 时退化正常
4. hinted vs confirmed 边界仍清楚
5. 主 CTA 未被压
6. 没有改主 endpoint 语义
7. 没有新增 endpoint / 状态机 / interaction backend action
8. `companion_response` typing / `source_fact_tags` 未被带入
9. `docs/R4_OptionB23_change_highlights_Status_v0.1.md` 已更新
10. `docs/R4_OptionB23_change_highlights_Test_Summary_v0.1.md` 已更新
11. `docs/R4_cursor_round_summary_OptionB23_B_v0.1.md` 已生成
12. 最终能明确回答：是否 ready for **B23-C**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 **Option B2-3 / B23-B / Today consumption**
- 明确不是 B23-C / B23-D

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 B23-B 结果
请按这几项写清楚：
1. Today landing point
2. fallback behavior
3. truth boundary
4. CTA safety
5. backend touched or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 若 backend / e2e 被影响：`npm test` / `npm run test:e2e`
- B23-B 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB23_change_highlights_Status_v0.1.md`
- `docs/R4_OptionB23_change_highlights_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB23_B_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B23-B**
2. 是否 ready for **B23-C**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你接 Meow Home / Settlement，也不是让你把 B2-3 扩成新系统。

这轮唯一要做好的事情是：

> **把 `change_highlights[]` 以最小、温和、不压主 CTA 的方式接到 Today Companion Card 第二层。**

不要扩 scope。  
不要偷拍板。  
不要把 B23-C / B23-D 或其它候选项混进来。  
现在开始执行。
