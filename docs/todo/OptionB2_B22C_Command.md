# Cursor_OptionB2_B22C_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是继续做 catalog 扩容落地，也不是开 B2-3 sync patch，而是：

> **按这里给定的 Room 1 handoff、Room 2 preflight 结论、Room 5 的 Option B2 UI 方案，以及 Room 4 的执行边界，完成 Option B2 的 B2-2C：Inventory / Equipment / Customize 内容层增强。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前状态不是 P1 / P2，也不是 Option A / Option A.1，也不是 Option B（B1），也不是 Option B2（B2-1 first）。  
这些都已经完成并 close。  
Room 1 已正式拍板下一方向为：

> **Option B2 下一步 = B2-2 only**

但 Room 1 同时也明确要求：

> **B2-2 必须按 `Go with very small patch` 管理，而不是做成大包新系统。**

你这轮接的不是：
- B2-2A（seed / metadata lock）
- B2-2B（catalog expansion support）
- B2-2D（test & closeout）
- B2-3（sync patch / typed response / change_highlights）

你这轮只做：

> **B2-2C — Inventory / Equipment / Customize 内容层增强。**

---

## 1. 当前已完成到哪里

### 已完成且已 close
- P1：主机制闭环
- P2：副机制 MVP 闭环
- Option A：PG 真相层
- Option A.1：hardening
- Option B（B1）：视觉 polish 第一轮
- Option B2（B2-1 first）：A/B/C/D 已完成并建议 close

### B2-2A 已完成
当前结论是：
- 当前已有 5 个 items 已盘清
- 新增 5 个 items 已锁定
- 所有新增 items 均复用现有语义
- DevStore catalog 已 5 → 10
- PG seed 已 5 → 10
- `/shop/catalog` contract 判断为 **sufficient as-is**
- **No very small patch needed**

### B2-2B 已完成
当前结论是：
- 前端已真实消费到 **10-item catalog**
- 新增 5 个 items 已真实可见
- display mapping / name / emoji / fallback 完整
- 购买 / inventory / equipment 基本链路回归通过
- 三态（unowned / owned / equipped）未混淆
- **current contract 仍 judged sufficient**
- **patch still not needed**

你现在接的不是：
- B2-2D
- B2-3

而是：

> **只做 inventory / equipment / customize 的内容层增强。**

---

## 2. 这轮你到底要做什么

这轮只做：

1. 在**不新增后端字段、不新增 API、不改 purchase / equip 规则** 的前提下，增强：
   - Inventory 的可逛性
   - Equipment 的可见性
   - Customize 的 compare / preview / owned-not-equipped / 当前搭配重点 / 轻目标感
2. 让 10-item catalog 不只是“多 5 个 item”，而是真的带来：
   - 更清楚的浏览目标
   - 更清楚的已拥有 / 已装备 / 还可以攒什么
   - 更清楚的“买了之后会变什么”
3. 继续复用 B1 / B2-1 / B2-2A / B2-2B 已有的：
   - theme
   - shared widgets
   - tabs / cards / chips
   - copy pools
4. 保持所有业务逻辑不变
5. 更新 / 补齐 Inventory / Equipment / Customize 相关 Flutter tests
6. 输出本轮 handoff 文档

这轮**不做**：
- 不新增 endpoint
- 不新增字段
- 不改 DB / API / persistence 主结构
- 不新增 slot / currency / state machine
- 不重做 catalog 主结构
- 不做 `change_highlights[]`
- 不做 typed `companion_response`
- 不做 `source_fact_tags`
- 不开 B2-3 sync patch
- 不改 Today / Meow Home 主结构

一句话：

> **B2-2C 是把“浏览—比较—购买—装备”的内容层做完整，不是做新商店系统。**

---

## 3. 你必须接受的上游结论

### 3.1 Room 1 已正式拍板：当前做的是 `Option B2 → B2-2 only`
Room 1 已明确：
- **Option B2 下一步 = B2-2 only**
- 且必须按 **`Go with very small patch`** 管理

### 3.2 Room 2 preflight 已明确
Room 2 当前判断：
- active DB 主结构足够
- active API 主结构基本足够
- B2-2 默认理解为：
  - catalog `5 → 10`
  - inventory / equipment / customize 内容层增强
  - 如有必要才允许 very small read-only metadata patch
- 当前 B2-2A / B2-2B 结论已经是：
  - **contract enough as-is**
  - **patch not needed**

### 3.3 Room 5 已明确 B2-2 的内容层方向
Room 5 的 B2 稿已经写清楚：
- B2-2 是 **catalog / inventory / equipment / customize 的内容层增强**
- 重点是：
  - “买了之后会变什么”
  - “已拥有但未装备”
  - “当前搭配重点”
  - “推荐攒钱目标”
  - “更可逛、更有轻目标感”
- 但继续服从：
  - `displayed change ≠ backend-confirmed change`
  - `preview / compare ≠ 当前已装备真相`
  - 不默认开新 API / 新字段 / 新状态机

### 3.4 B2-2 / B2-3 的硬边界
本轮继续明确不做：
- 不推进 `change_highlights[]`
- 不推进 typed `companion_response`
- 不推进 `source_fact_tags`
- 不推进 interaction backend 化
- 不新增新 slot
- 不新增新货币
- 不开新状态机
- 不做 P3

---

## 4. 你必须服从的强断言

### 4.1 这轮只做内容层增强，不做新机制
你可以：
- 强化 inventory / equipment / customize 的信息表达
- 强化 compare / preview / style hint / goal cue
- 强化 owned-not-equipped 的可见性
- 强化 “买了之后会变什么” 的前端承接

但你不能：
- 把这轮做成新商店系统
- 新增真正的推荐引擎
- 新增真正的变化历史系统
- 直接进入 B2-3

### 4.2 preview / compare 的硬边界
这轮最重要的红线是：

> **preview / compare ≠ 当前已装备真相。**

你可以让用户更容易看出：
- 当前搭配重点
- 某个 item 买了之后会怎样
- 已拥有但未装备的东西值得去试

但不能：
- 把 preview 伪装成 equipped
- 把 compare 伪装成 backend-confirmed change
- 把推荐攒钱目标写成业务承诺

### 4.3 所有新表达都必须复用现有语义
你现在只能继续使用当前 active 业务语义：
- 现有 `item_type`
- 现有 `slot_key`
- 现有 `price_coins`
- 现有 `level_required`
- 现有 ownership / equip 规则

任何以下行为都禁止：
- 发明新 slot
- 发明新 item_type
- 发明新 price tier 规则体系
- 发明新 equip 语义
- 发明新货币

### 4.4 Room 4 不是 UI / UX owner，也不是规则 owner
你不能自己定义新规则或新视觉方向。  
当前内容方向与表达目标，以 Room 5 的 `UI_SPEC_OptionB2_v0.1.1.md` 为准；  
当前技术与范围边界，以 Room 2 preflight + Room 1 handoff 为准。  
Room 4 / Cursor 只能：
- 把 inventory / equipment / customize 内容层做稳
- 证明 current contract 足够支撑 B2-2C
- 给后续 B2-2D 提供 closeout 输入

---

## 5. 这轮的正确目标

根据 Room 1 handoff、Room 2 preflight、B2-2A 与 B2-2B 结果，B2-2C 的目标是：

> **把 10-item catalog 从“能显示、能买、能装”推进到“更可逛、更容易理解、轻目标感更明确”。**

这轮必须交付的，不是“完整新商店体验”，而是：

1. Inventory / Equipment 的内容层更可见
2. Customize 的 compare / preview / owned-not-equipped / 当前搭配重点表达更完整
3. 当前 contract 的 sufficiency 被更高一层 UI 消费再次验证
4. 不越界进入 B2-3

---

## 6. 这轮 in scope

### 6.1 Inventory / Equipment 内容层增强（必须）
请让用户更容易看懂：

- 自己已经拥有什么
- 当前装备了什么
- 哪些 item 只是 owned，但还没 equipped
- 哪个 slot 当前最值得继续换

可以通过：
- 更清楚的分组
- 更清楚的 chips / tags
- 更清楚的 slot label
- 更清楚的 owned-not-equipped 提示

但不能：
- 新增业务状态
- 新增后台排序规则
- 新增复杂推荐算法

### 6.2 Customize：买了之后会变什么（必须）
请把 Customize 中“买了之后会变什么”做得更明确，但必须遵守：

- 这是 **preview / compare / hint**
- 不是当前已装备真相
- 不是后端承诺

推荐做法：
- 轻 compare 区
- 购买前后的视觉差异 hint
- 物品带来的“更适合当前搭配 / 更接近目标”的轻提示

### 6.3 Customize：已拥有但未装备（必须）
请让用户能更直观看到：
- 什么已经买了
- 但还没装
- 是否值得去试一下

可以做：
- owned-not-equipped 的更明显表达
- 更自然的 CTA / chips / tags
- 更明确的“去试试看”引导

但不能：
- 把 owned 写成 equipped
- 把 preview 写成 equipped

### 6.4 Customize：当前搭配重点（允许）
你可以补一个“当前搭配重点”表达，比如：
- 现在最突出的搭配点
- 当前主要风格是什么
- 哪个 slot 最值得继续换

但这些默认必须属于：
- **Pure front-end static content layer**
- 或现有 equipped data 的 UI 总结

不能：
- 写成系统已确认的风格分析真相
- 写成业务排序规则已冻结

### 6.5 推荐攒钱目标（允许，但必须轻）
你可以增加一些轻目标感提示，例如：
- “再攒一点可换下一个”
- “离这个 item 还差多少 coins”
- “当前更接近哪种搭配方向”

但这些默认必须属于：
- **Pure front-end static content layer**
- 或基于现有 catalog + balance 的弱承接

不能：
- 假装系统已经有完整推荐引擎
- 写成业务承诺
- 写成冻结的排序规则

### 6.6 数据来源建议
这轮推荐优先用当前已有：
- `GET /shop/catalog`
- `GET /me/inventory`
- `GET /me/equipment`
- `POST /shop/purchases`
- `POST /me/equipment/equip`
- B2-2A 锁定的 metadata
- B2-1A 扩好的 copy 池
- B2-1C 已建立的 compare / preview 表达模式

不要新增字段。

---

## 7. 这轮明确不做什么

### 7.1 不做 B2-2D
以下留给下一轮：
- 全量 regression closeout
- close bar judgment
- final recommendation to Room 1

### 7.2 不做 B2-3
- 不做 `change_highlights[]`
- 不做 typed `companion_response`
- 不做 `source_fact_tags`
- 不做 richer payload / new helper contract

### 7.3 不改主结构
- 不改 DB 主结构
- 不改 API 主结构
- 不改 purchase / equip 主规则
- 不改 ownership 语义
- 不改 persistence

### 7.4 不改 Today / Meow Home 主结构
- 不重改 Today
- 不重改 Meow Home
- 不碰学习页 / 复习页 / 结算页

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 当前 runtime / handoff / preflight
- `R1_to_R4_OptionB2_B22_Handoff_v0.1.md`
- `R2_OptionB2_B22_Preflight_v0.1.md`
- `回p2_B2_2B.md`
- `Main_updated_2026-04-04_v11.md`
- `STATUS_updated_2026-04-04_v10.md`

### 8.2 当前 active DB / API / UI / rules
- `背单词喵喵app_DB设计草案_v0.1.4.md`
- `背单词喵喵app_API设计草案_v0.1.3.md`
- `UI_SPEC_OptionB2_v0.1.1.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `BR-OPP-001_v0.1.5.md`

### 8.3 代码真实入口
至少盘点这些真实代码位置：
- Customize 页面当前结构
- item card / tabs / list / purchase button / equip button 当前真实用法
- inventory / equipment / equipped preview 相关 model / mapper
- 当前 compare / preview / owned-not-equipped 相关已有表达入口
- B2-2A 新增 5 个 items 的 metadata 消费位置

### 8.4 当前测试入口
至少盘点：
- shop / purchase / inventory / equipment e2e tests
- customize page widget tests（若无，需记录缺口）
- catalog model / mapper tests
- B2-1 与 B2-2A / B2-2B 回归入口（确保不误伤）

---

## 9. B2-2C 你必须明确回答的问题

### Q1. Inventory / Equipment 最终增强了什么
请明确描述：
- owned / equipped / owned-not-equipped 的表达增强
- slot / grouping / chips / tags 是否更清楚
- 哪些属于 direct existing backend fields
- 哪些属于 pure front-end content layer

### Q2. Customize 最终增强了什么
请明确描述：
- 买了之后会变什么
- 已拥有但未装备
- 当前搭配重点
- compare / preview 是如何表达的
- 为什么不会被误读为 equipped truth

### Q3. 这些内容层增强分别属于哪一层数据来源
请逐类标出：
- Direct existing backend field
- Pure front-end static content layer
- Very small sync patch required（若出现必须说明为什么仍未进入）

### Q4. 你如何保证这些表达没越过真相边界
请明确：
- 哪些只是 UI 承接
- 哪些基于现有后端字段
- 为什么不会伪确认
- 为什么 preview / compare 不会被误读成 backend truth

### Q5. 这轮如何保证没越界到 B2-2D / B2-3
请明确：
- 没有新增字段
- 没有新增 sync patch
- 没有改业务规则
- 没有重改 Today / Meow Home
- 没有开新系统

### Q6. B2-2D 最自然的开工点是什么
请给出最小建议：
- 哪些 regression 要先收
- 哪些 truth-boundary case 最容易漏
- 当前 close bar 哪几项最值得重点复核

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 增强 Inventory / Equipment 的内容层表达
2. 增强 Customize 的 compare / preview / owned-not-equipped / goal cue
3. 调整 Customize 中内容层的视觉层级
4. 复用 B2-1 / B2-2A / B2-2B 的 copy 与组件模式
5. 更新 / 新增 widget tests
6. 做 very small docs sync（只记录 B2-2C 新事实）

### 不允许做的
1. 不新增 endpoint
2. 不新增业务字段
3. 不改业务规则
4. 不改 DB / API / persistence 主结构
5. 不把 B2-3 混进来
6. 不把这轮做成完整新商店系统

如果你做了任何超出 B2-2C 的事，必须解释为什么仍算 inventory / equipment / customize content enhancement，而不是 scope creep。

---

## 11. 这轮最小测试 / 验证要求

### 11.1 Flutter
至少执行：
```bash
flutter pub get
flutter test
flutter analyze
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.2 Node / backend
如果你动到了 purchase / inventory / equipment 消费逻辑、model / mapper 或 e2e 入口，请至少执行：
```bash
npm test
npm run test:e2e
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.3 B2-2C 专项验证
至少完成这些验证：
1. Inventory / Equipment 内容层更清楚
2. Customize 的 preview / compare / owned-not-equipped 表达更完整
3. preview / compare 不会被误读成 equipped truth
4. truth boundary 不越界
5. 没有越界进入 B2-3
6. 现有功能链路不破

### 11.4 建议额外覆盖
如果范围允许，建议补：
- customize page widget tests
- purchase + inventory + equipment regression
- preview / compare truth-boundary checks
- B2-1 / B2-2A / B2-2B 抽样回归检查

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — B2-2 status 更新
请更新：

```text
docs/R4_OptionB2_B22_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 B2-2C）
2. 已实现范围
3. 未实现范围
4. 当前 inventory / equipment / customize 增强结果
5. 当前 contract 是否仍 judged sufficient
6. 是否建议进入 B2-2D

### Deliverable B — B2-2 metadata lock 文件更新
请更新：

```text
docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md
```

至少补：
1. 当前 10-item catalog 在内容层增强中的消费结果
2. 是否发现前端字段依赖缺口
3. 是否仍为 patch not needed

### Deliverable C — B2-2 test summary 更新
请更新：

```text
docs/R4_OptionB2_B22_Test_Summary_v0.1.md
```

至少包含：
1. inventory / equipment / customize / purchase 相关入口
2. 哪些验证已跑
3. 哪些验证留到 B2-2D
4. 是否影响 B2-1 / B2-2A / B2-2B 回归

### Deliverable D — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB2_B22C_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **What inventory / equipment content layer now includes**
3. **What customize compare / preview now includes**
4. **What contract sufficiency judgment remains**
5. **Whether patch is still not needed**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**
11. **Whether ready for B2-2D**

### Optional
若你确认确实需要 very small read-only patch，才允许新增 / 更新：

```text
docs/R4_OptionB2_B22_sync_candidates_v0.1.md
```

但不要默认制造 patch。

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B2-2C 完成：

1. Inventory / Equipment 内容层已增强
2. Customize 的 preview / compare / owned-not-equipped 表达已增强
3. truth boundary 继续守住，无伪确认
4. 当前 contract 仍 judged sufficient
5. 若有 patch candidate，只能是 very small read-only
6. `docs/R4_OptionB2_B22_Status_v0.1.md` 已更新
7. `docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md` 已更新
8. `docs/R4_OptionB2_B22_Test_Summary_v0.1.md` 已更新
9. `docs/R4_cursor_round_summary_OptionB2_B22C_v0.1.md` 已生成
10. 最终能明确回答：是否 ready for **B2-2D**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B2 里的 **B2-2C / Inventory + Equipment + Customize content enhancement**
- 明确不是 B2-2D / B2-3

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 B2-2C 结果
请按这几项写清楚：
1. inventory / equipment content layer
2. customize preview / compare
3. owned-not-equipped expression
4. contract sufficiency
5. patch needed or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- `npm test` / `npm run test:e2e` 结果（若被影响）
- B2-2C 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB2_B22_Status_v0.1.md`
- `docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md`
- `docs/R4_OptionB2_B22_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B22C_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B2-2C**
2. 是否 ready for **B2-2D**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你开 B2-3，也不是让你重做商店系统。

这轮唯一要做好的事情是：

> **把 inventory / equipment / customize 的内容层做完整，让 10-item catalog 真正变得更可逛、更容易理解。**

不要扩 scope。  
不要偷拍板。  
不要把 B2-2D / B2-3 混进来。  
现在开始执行。
