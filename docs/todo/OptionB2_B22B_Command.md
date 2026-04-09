# Cursor_OptionB2_B22B_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是继续做 seed / metadata lock，也不是直接做 Customize 深增强，而是：

> **按这里给定的 Room 1 handoff、Room 2 preflight 结论、Room 5 的 Option B2 UI 方案，以及 Room 4 的执行边界，完成 Option B2 的 B2-2B：Catalog expansion（5 → 10）前端落地。**

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
- B2-2C（Inventory / Equipment / Customize 内容层增强）
- B2-2D（test & closeout）
- B2-3（sync patch / typed response / change_highlights）

你这轮只做：

> **B2-2B — 把 catalog 从 5 → 10 的扩容真正落到前端可消费、可浏览、可购买入口上。**

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
- 测试通过：
  - `npm test` 16/16
  - `npm run test:e2e` 67/67
  - `flutter test` 44/44
  - `flutter analyze` 0 errors（只有 info hints）

你现在接的不是：
- B2-2C
- B2-2D
- B2-3

而是：

> **只做 catalog 扩容在前端的真实落地与浏览可用性验证。**

---

## 2. 这轮你到底要做什么

这轮只做：

1. 让 **Customize / Catalog 浏览层** 真正吃到从 5 → 10 的扩容结果
2. 让用户在当前 UI 中能看见新增 5 个 items
3. 确保新 items 在当前 contract 下能：
   - 正常展示
   - 正常购买
   - 正常进入 inventory
   - 若属于可装备类，能正常装备
4. 在不新增新 slot / 新货币 / 新规则 / 新 API 的前提下，提升 catalog 的浏览完整性
5. 保持 B2-2 仍然是 **内容扩容**，不是机制升级
6. 更新 / 补齐 catalog 相关测试
7. 输出本轮 handoff 文档

这轮**不做**：
- 不重做 Customize 的 compare / preview 深增强（那是 B2-2C）
- 不新增 `change_highlights[]`
- 不新增 typed `companion_response`
- 不新增 `source_fact_tags`
- 不新增 endpoint / payload / rule / state machine
- 不开 B2-3 sync patch
- 不新增 slot / currency
- 不发明新购买 / 装备规则

一句话：

> **B2-2B 是把 10-item catalog 真正落地到可见前端层，不是做新系统。**

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
- 当前 B2-2A 结论已经是：
  - **contract enough as-is**
  - **patch not needed**

### 3.3 B2-2 / B2-3 的硬边界
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

### 4.1 这轮只做 catalog expansion 的前端落地
你可以：
- 确认 10 个 items 都能在当前 catalog UI 中显示
- 确认排序、展示名、emoji / display map 正常
- 确认购买 / inventory / equipment 的基本链路仍成立
- 做 very small UI polish 以避免 10-item 后明显坏掉

但你不能：
- 把这轮做成完整 B2-2C
- 提前重做 compare / preview / owned-not-equipped 的内容层增强
- 顺手重排整个 Customize 架构

### 4.2 所有新增 items 必须继续复用现有语义
新增 5 个 items 仍然只能使用当前 active 业务语义：

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

### 4.3 catalog 扩容不等于新商店系统
这轮允许：
- item 数量从 5 → 10
- 现有 UI 中更完整地展示 10 个 items
- 让分类 / 排序 / 购买入口对 10 个 items 仍然清楚

这轮不允许：
- 新过滤系统
- 新推荐系统
- 新稀有度系统
- 新商城活动机制
- 新业务状态字段

### 4.4 Room 4 不是 UI / UX owner，也不是规则 owner
你不能自己定义新规则或新视觉方向。  
当前内容方向与表达目标，以 Room 5 的 `UI_SPEC_OptionB2_v0.1.1.md` 为准；  
当前技术与范围边界，以 Room 2 preflight + Room 1 handoff 为准。  
Room 4 / Cursor 只能：
- 把 10-item catalog 稳定落地
- 证明 current contract 足够支撑 B2-2B
- 给后续 B2-2C 提供更稳定的前端基础

---

## 5. 这轮的正确目标

根据 Room 1 handoff、Room 2 preflight 与 B2-2A 结果，B2-2B 的目标是：

> **先把 10 个 items 在当前前端入口中稳稳显示出来、买得通、装得通，再进入 B2-2C 的内容层增强。**

这轮必须交付的，不是“完整新商店体验”，而是：

1. 10-item catalog 在当前前端中真实可见
2. 新增 items 的展示、购买、inventory / equipment 基本链路成立
3. 当前 contract 的 sufficiency 被前端消费层再次验证
4. 不越界进入 B2-2C / B2-3

---

## 6. 这轮 in scope

### 6.1 Customize / Catalog 列表吃到 10-item 数据（必须）
请确认当前 catalog UI 不是只在 seed 层 10 条，而是真的在前端列表里显示 10 条。

至少明确：
- 排序是否正确
- 新增 5 个 items 是否可见
- 新 item 是否有正确 display name / emoji / tag / price / level lock 信息
- 当前 tabs / 分组是否仍可用

### 6.2 购买链路回归（必须）
请确认新增 5 个 items 在当前链路下可正常：
- 购买成功
- 余额扣减正确
- inventory 出现
- 若属于可装备类，装备后 equipment 变化正确

### 6.3 三态正确性回归（必须）
请至少确认 10-item catalog 下：
- unowned
- owned
- equipped

这三态在当前页面里仍然不混淆。

### 6.4 very small UI 修正（允许）
如果 10-item 后当前页面出现以下明显问题，你可以做 very small 修正：
- 列表明显溢出 / 排序错乱
- 某些新 item display map 缺失
- 某些状态 tag 在 10-item 下不清楚
- 当前滚动 / 分组在 10-item 下明显不可用

但这类修正必须保持为：
> **catalog expansion support patch**
而不是 B2-2C 的深增强。

### 6.5 数据来源与 contract 边界
这轮默认继续只消费当前已有：
- `GET /shop/catalog`
- `POST /shop/purchases`
- `GET /me/inventory`
- `GET /me/equipment`

不要新增字段。

---

## 7. 这轮明确不做什么

### 7.1 不做 B2-2C
以下留给下一轮：
- Customize 的“买了之后会变什么”
- Customize 的“已拥有但未装备”强化
- Customize 的“当前搭配重点”
- 更强 compare / preview 体验
- inventory / equipment 的更深内容层表达

### 7.2 不做 B2-3
- 不做 `change_highlights[]`
- 不做 typed `companion_response`
- 不做 `source_fact_tags`

### 7.3 不改主结构
- 不改 DB 主结构
- 不改 API 主结构
- 不改 purchase / equip 主规则
- 不改 ownership 语义
- 不改 persistence

### 7.4 不改主机制或 Today / Meow Home
- 不重改 Today
- 不重改 Meow Home
- 不碰学习页 / 复习页 / 结算页

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 当前 runtime / handoff / preflight
- `R1_to_R4_OptionB2_B22_Handoff_v0.1.md`
- `R2_OptionB2_B22_Preflight_v0.1.md`
- `回p2_B2_B2.md`
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
- 当前 catalog seed / dev-store / PG seed
- `/shop/catalog` controller / service / mapper
- inventory / equipment 相关 model / mapper
- Customize 页当前实际消费的 catalog fields
- item card / tabs / list / purchase button / equip button 当前真实用法

### 8.4 当前测试入口
至少盘点：
- shop / purchase / inventory / equipment e2e tests
- customize page widget tests
- catalog model / mapper tests
- B2-1 与 B2-2A 回归入口（确保不误伤）

---

## 9. B2-2B 你必须明确回答的问题

### Q1. 当前 catalog 前端是否真的已经从 5 → 10
请明确：
- 当前可见 item 总数
- 哪些页面 / 组件已显示 10 items
- 是否仍有任何 5-item hardcode 遗留

### Q2. 新增 5 个 items 的显示是否稳定
请逐项说明：
- display name
- emoji / icon / label
- price
- level_required
- sort_order
- type / slot 相关显示

### Q3. 10-item 下购买 / inventory / equipment 基本链路是否仍然成立
请明确：
- 是否能正常购买
- 是否能正常进入 inventory
- 是否能正常装备
- 三态是否清楚

### Q4. 这轮如何保证没越界到 B2-2C / B2-3
请明确：
- 没有做 compare / preview 深增强
- 没有做 owned-not-equipped 深增强
- 没有新增字段
- 没有新增 sync patch
- 没有改业务规则

### Q5. B2-2C 最自然的开工点是什么
请给出最小建议：
- compare / preview 应先在哪个 widget 落地
- owned-not-equipped 哪个位置最适合先增强
- 哪些测试最该先跟进

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 让 10-item catalog 真正在前端可见
2. 修正 10-item 下的 display map / list / tabs / purchase flow 小问题
3. 回归购买 / inventory / equipment 基本链路
4. 更新 / 新增与 catalog expansion support 相关测试
5. 做 very small docs sync（只记录 B2-2B 新事实）

### 不允许做的
1. 不开始完整 B2-2C
2. 不新增 endpoint
3. 不新增业务字段
4. 不改业务规则
5. 不改 DB / API / persistence 主结构
6. 不把 B2-3 混进来

如果你做了任何超出 B2-2B 的事，必须解释为什么仍算 catalog expansion support，而不是 scope creep。

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
如果你动到了 catalog / purchase / mapper / seed 消费或 e2e 入口，请至少执行：
```bash
npm test
npm run test:e2e
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.3 B2-2B 专项验证
至少完成这些验证：
1. 前端已真实显示 10 items
2. 新增 5 个 items 可购买 / 可展示
3. 三态未混淆
4. 当前 contract 足够支撑前端消费
5. 没有越界进入 B2-2C / B2-3

### 11.4 建议额外覆盖
如果范围允许，建议补：
- customize page item count / display tests
- purchase + inventory + equipment regression
- display mapping completeness check
- B2-1 / B2-2A 抽样回归检查

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — B2-2 status 更新
请更新：

```text
docs/R4_OptionB2_B22_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 B2-2B）
2. 已实现范围
3. 未实现范围
4. 当前 catalog expansion 落地结果
5. 当前 contract 是否仍 judged sufficient
6. 是否建议进入 B2-2C

### Deliverable B — B2-2 metadata lock 文件更新
请更新：

```text
docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md
```

至少补：
1. 当前 10-item catalog 的消费结果
2. 是否发现前端字段依赖缺口
3. 是否仍为 patch not needed

### Deliverable C — B2-2 test summary 更新
请更新：

```text
docs/R4_OptionB2_B22_Test_Summary_v0.1.md
```

至少包含：
1. catalog / purchase / inventory / equipment / customize 相关入口
2. 哪些验证已跑
3. 哪些验证留到 B2-2C / B2-2D
4. 是否影响 B2-1 / B2-2A 回归

### Deliverable D — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB2_B22B_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **Whether 10 items are now truly visible**
3. **What catalog flow was verified**
4. **What contract sufficiency judgment remains**
5. **Whether patch is still not needed**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**
11. **Whether ready for B2-2C**

### Optional
若你确认确实需要 very small read-only patch，才允许新增 / 更新：

```text
docs/R4_OptionB2_B22_sync_candidates_v0.1.md
```

但不要默认制造 patch。

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B2-2B 完成：

1. 前端真实消费到了 10-item catalog
2. 新增 5 个 items 可见且可购买
3. 三态未混淆
4. 当前 contract 仍 judged sufficient
5. 若有 patch candidate，只能是 very small read-only
6. `docs/R4_OptionB2_B22_Status_v0.1.md` 已更新
7. `docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md` 已更新
8. `docs/R4_OptionB2_B22_Test_Summary_v0.1.md` 已更新
9. `docs/R4_cursor_round_summary_OptionB2_B22B_v0.1.md` 已生成
10. 最终能明确回答：是否 ready for **B2-2C**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B2 里的 **B2-2B / Catalog expansion support**
- 明确不是 B2-2C / B2-3

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 B2-2B 结果
请按这几项写清楚：
1. visible item count
2. new item display stability
3. purchase / inventory / equipment regression
4. contract sufficiency
5. patch needed or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- `npm test` / `npm run test:e2e` 结果（若被影响）
- B2-2B 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB2_B22_Status_v0.1.md`
- `docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md`
- `docs/R4_OptionB2_B22_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B22B_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B2-2B**
2. 是否 ready for **B2-2C**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你开始做完整 B2-2，更不是让你开 B2-3。

这轮唯一要做好的事情是：

> **把 10-item catalog 真正在前端稳稳落下来，并证明 current contract 足够支撑它。**

不要扩 scope。  
不要偷拍板。  
不要把 B2-2C / B2-3 混进来。  
现在开始执行。
