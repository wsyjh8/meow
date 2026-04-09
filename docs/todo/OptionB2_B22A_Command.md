# Cursor_OptionB2_B22A_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接做 B2-2 的完整页面增强，也不是直接扩 catalog UI，而是：

> **按这里给定的 Room 1 handoff、Room 2 preflight 结论、Room 5 的 Option B2 UI 方案，以及 Room 4 的执行边界，完成 Option B2 的 B2-2A：Seed / metadata lock。**

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
- B2-2B（catalog / UI 实现）
- B2-2C（Inventory / Equipment / Customize 内容层增强）
- B2-2D（test & closeout）
- B2-3（sync patch / typed response / change_highlights）

你这轮只做：

> **B2-2A — 把新增 5 个 items 的 seed / metadata 锁死，并判断当前 active DB / API 是否已经足够承接后续 B2-2。**

---

## 1. 当前已完成到哪里

### 已完成且已 close
- P1：主机制闭环
- P2：副机制 MVP 闭环
- Option A：PG 真相层
- Option A.1：hardening
- Option B（B1）：视觉 polish 第一轮
- Option B2（B2-1 first）：A/B/C/D 已完成并建议 close

### 当前进入的新方向
- **Option B2 → B2-2 only**
- Room 1 已正式允许进入
- Room 2 的 preflight 结论为：

> **Go with very small patch**

### Room 2 已给出的核心结论
1. 当前 active DB 主结构足够
2. 当前 active API 主结构基本足够
3. B2-2 不应被理解为新系统，而应理解为：
   - catalog `5 → 10` 的 seed / metadata 扩容
   - inventory / equipment / customize 的内容层增强
   - 若有必要，只允许一个 **very small read-only metadata patch**
4. 明确禁止借机进入：
   - 新 slot
   - 新货币
   - 新规则
   - 新状态机
   - interaction backend 化

---

## 2. 这轮你到底要做什么

这轮只做：

1. **锁定新增 5 个 items 的 seed / metadata**
2. 明确这些 items 是否完全复用当前 active 语义：
   - 现有 `item_type`
   - 现有 `slot_key`
   - 现有 `price_coins`
   - 现有 `level_required`
   - 现有 ownership / equip 语义
3. 检查当前 `/shop/catalog` 返回字段，判断：
   - 是否已经足够支撑 B2-2 的内容层表达
   - 如果不够，缺的到底是不是 **very small read-only metadata**
4. 给出一个清晰的：
   - **locked seed table**
   - **metadata readiness judgment**
   - **very small patch needed / not needed**
5. 为后续 B2-2B / B2-2C 提供稳定输入
6. 更新 / 生成本轮 handoff 文档

这轮**不做**：
- 不开始 catalog `5 → 10` 的完整 UI 落地
- 不开始 Inventory / Equipment / Customize 的页面增强
- 不直接上 B2-2B / B2-2C
- 不新增 endpoint
- 不改购买规则
- 不改装备规则
- 不新增 slot / currency / state machine
- 不进入 B2-3
- 不做“半套新商店系统”

一句话：

> **B2-2A 是 DoR 锁定轮，不是功能实现轮。**

---

## 3. 你必须接受的上游结论

### 3.1 Room 1 已正式拍板：当前做的是 `Option B2 → B2-2 only`
Room 1 已明确：
- **Option B2 下一步 = B2-2 only**
- 且必须按 **`Go with very small patch`** 管理

### 3.2 Room 1 已明确 B2-2 的正式范围
这轮正式 in scope 只包括：

#### A. Catalog `5 → 10`
- 新增 5 个 items
- 必须继续复用当前语义：
  - `item_type`
  - `slot_key`
  - `price_coins`
  - `level_required`
  - ownership / equip 语义

#### B. Inventory / Equipment 内容层增强
- 强化可逛性
- 强化浏览—比较—购买—装备目标感
- 但不新增业务状态

#### C. Customize 内容层增强
- 更强的“买了之后会变什么”
- 更强的“已拥有但未装备”
- 更强的“当前搭配重点”
- 更明确的轻目标感

#### D. 必要时允许一个 very small read-only patch
前提是：
- 当前 `/shop/catalog` 字段不足以稳定支撑 B2-2 内容层表达

### 3.3 Room 2 已给出的 must-have
开始 B2-2 前，必须先确认以下 3 件事：

#### Must-have 1
`B2-2 only` 已被 Room 1 pin 清楚  
当前这一版 handoff 已满足。

#### Must-have 2
新增 5 个 items 的 seed / metadata 已锁定  
至少要锁定：
- `item_code`
- `item_type`
- `slot_key`
- `display_name`
- `price_coins`
- `level_required`
- `sort_order`
- 轻量 preview / 展示 metadata（若前端会消费）

#### Must-have 3
明确当前字段到底够不够  
即：
- 哪些可直接吃现有后端真相
- 哪些只能做前端静态承接
- 哪些若想做稳，才需要 very small read-only patch

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

### 4.1 这轮只锁 seed / metadata，不做完整实现
你可以：
- 写入 / 扩充 seed
- 补 metadata
- 校验现有 catalog contract
- 生成锁定表 / readiness 文档

但你不能：
- 把这轮做成完整 B2-2 实现
- 直接展开大规模 UI 改造
- 顺手进入 B2-2B / B2-2C

### 4.2 所有新增 items 必须复用现有语义
新增 5 个 items **只能**继续使用当前 active 业务语义：

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

### 4.3 “内容扩容”不等于“机制升级”
这轮允许：
- 增加 item 数量
- 增加 display metadata
- 增加 preview / compare 所需的轻量内容字段（仅在当前 item_payload 或现有 metadata 语义内）

这轮不允许：
- 新状态机
- 新购买链路
- 新装备链路
- 新后端动作
- 新事实字段

### 4.4 very small patch 只能是 read-only metadata support
如果你确认当前 `/shop/catalog` 暴露字段不够，请只允许提出：

> **very small read-only metadata exposure patch**

不能借这个名义：
- 加新 endpoint
- 改 purchase / equip 主语义
- 改主结构
- 把 B2-2 变成 B2-3

### 4.5 Room 4 不是 UI / UX owner，也不是规则 owner
你不能自己定义新规则或新视觉方向。  
当前内容方向与表达目标，以 Room 5 的 `UI_SPEC_OptionB2_v0.1.1.md` 为准；  
当前技术与范围边界，以 Room 2 preflight + Room 1 handoff 为准。  
Room 4 / Cursor 只能：
- 锁 seed / metadata
- 判断 contract readiness
- 给后续实现准备稳定输入

---

## 5. 这轮的正确目标

根据 Room 1 handoff 与 Room 2 preflight，B2-2A 的目标是：

> **先把新增 5 个 items 的 seed / metadata 和 contract readiness 一次钉死，再让 Room 4 进入真正的 B2-2B / B2-2C。**

这轮必须交付的，不是“新商店体验”，而是：

1. 5 个新增 items 的 locked seed table
2. 每个 item 的 metadata 完整性判断
3. 当前 `/shop/catalog` 是否已足够支撑 B2-2
4. 若不够，只允许 very small read-only patch 建议
5. 一个可直接给 Room 1 / 下一个 Cursor 接手的稳定输入包

---

## 6. 这轮 in scope

### 6.1 先盘当前 active catalog 真实情况（必须）
请先确认当前 runtime 真实已有的 5 个 items 是什么：

至少盘清：
- `item_code`
- `item_type`
- `slot_key`
- `display_name`
- `price_coins`
- `level_required`
- `sort_order`
- `item_payload`（若存在）
- 当前前端到底消费了哪些字段

### 6.2 生成新增 5 个 items 的 locked seed table（必须）
请新增一组 **只复用现有语义** 的 5 个 items。

每个 item 至少要锁定：
- `item_code`
- `item_type`
- `slot_key`
- `display_name`
- `price_coins`
- `level_required`
- `sort_order`
- 若当前前端需要：用于 preview / compare / 展示的轻量 metadata

### 6.3 做现有语义复用检查（必须）
请逐项检查：
1. 所有新增 item 的 `item_type` 是否落在当前允许集合内
2. 所有新增 item 的 `slot_key` 是否落在当前允许集合内
3. 所有新增 item 是否继续服从当前 purchase / ownership / equip 语义
4. 是否有任何 item 会隐性要求：
   - 新 slot
   - 新规则
   - 新字段
   - 新状态机

### 6.4 做 catalog contract readiness judgment（必须）
请检查当前 `/shop/catalog` 的返回，判断：

#### 已足够的内容
哪些字段已经够支撑 B2-2：
- catalog 扩容
- inventory / equipment 内容层增强
- customize 轻量 preview / compare / 目标感表达

#### 不足的内容
若不够，请非常克制地判断：
- 到底缺的是不是 **very small read-only metadata**
- 缺什么字段
- 为何没有它就无法稳定实现 B2-2 内容层
- 为何这仍然不是 B2-3

### 6.5 可做 very small patch candidate，但不要默认需要
只有在你确认当前字段确实不够时，才允许提出：
- 一个 **read-only metadata exposure candidate**

但不能默认写“需要 patch 才能继续”。  
先尽力证明：
> **纯 seed + 现有 contract 已足够。**

---

## 7. 这轮明确不做什么

### 7.1 不做 B2-2B
以下留给下一轮：
- catalog 页真正扩到 10 的前端落地
- Inventory / Equipment 可逛性增强
- item card 内容层真正展开

### 7.2 不做 B2-2C
以下留给下一轮：
- Customize 的“买了之后会变什么”
- Customize 的“已拥有未装备”
- Customize 的“当前搭配重点”
- 更强 compare / preview 体验

### 7.3 不做 B2-3
- 不做 `change_highlights[]`
- 不做 typed `companion_response`
- 不做 `source_fact_tags`

### 7.4 不改主结构
- 不改 DB 主结构
- 不改 API 主结构
- 不改 purchase / equip 主规则
- 不改 ownership 语义
- 不改 persistence

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 当前 runtime / handoff / preflight
- `R1_to_R4_OptionB2_B22_Handoff_v0.1.md`
- `R2_OptionB2_B22_Preflight_v0.1.md`
- `回B2_B21D.md`
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
- 当前 catalog seed / dev-store / fake data / PG seed 所在位置
- `/shop/catalog` controller / service / mapper
- inventory / equipment 相关 model / mapper
- Customize 页当前实际消费的 catalog fields
- item card / preview / compare 当前真实使用了哪些字段

### 8.4 当前测试入口
至少盘点：
- shop / purchase / inventory / equipment e2e tests
- customize page widget tests
- catalog model / mapper tests
- B2-1 回归入口（确保不误伤）

---

## 9. B2-2A 你必须明确回答的问题

### Q1. 当前已有 5 个 items 的真实结构是什么
请明确列出：
- code
- type
- slot
- price
- level_required
- display metadata 使用情况

### Q2. 新增 5 个 items 的 locked seed table 是什么
请逐项列出：
- item_code
- item_type
- slot_key
- display_name
- price_coins
- level_required
- sort_order
- 轻量 preview / 展示 metadata（若需要）

### Q3. 新增 5 个 items 是否完全复用现有语义
请明确回答：
- 是否引入新 slot：yes/no
- 是否引入新 currency：yes/no
- 是否引入新 state machine：yes/no
- 是否引入新 purchase / equip 规则：yes/no

### Q4. 当前 `/shop/catalog` 是否已经足够支撑 B2-2
请明确分成：
- **Enough as-is**
- **Missing but optional**
- **Missing and blocks stable implementation**

如果有 blocker，必须说明：
- 缺的具体字段是什么
- 为何它只是 read-only metadata
- 为何这仍然不是 B2-3

### Q5. 是否需要 very small read-only patch
请明确：
- needed / not needed
- 如果 needed，写出最小字段级别提案
- 如果 not needed，也要明确说：
  > 当前 contract + seed 已足够进入 B2-2B

### Q6. B2-2B 最自然的开工点是什么
请给出最小建议：
- catalog `5 → 10` 应先在哪层落地
- 哪些 UI / tests 最先受影响
- 哪些 regression 最该先跟进

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 盘当前 5 个 items 的真实结构
2. 锁新增 5 个 items 的 seed / metadata
3. 更新 seed / fake data / PG seed（若这就是 runtime 真相来源）
4. 判断 current contract readiness
5. 必要时提出 very small read-only patch candidate
6. 更新 / 新增与 seed / metadata lock 相关测试
7. 做 very small docs sync（只记录 B2-2A 新事实）

### 不允许做的
1. 不开始完整 B2-2 UI 实现
2. 不扩到 B2-2B / B2-2C
3. 不新增 endpoint
4. 不新增业务字段（除非只是 read-only metadata candidate，且不要直接落）
5. 不改业务规则
6. 不改 DB / API / persistence 主结构
7. 不把 B2-3 混进来

如果你做了任何超出 B2-2A 的事，必须解释为什么仍算 seed / metadata lock，而不是 scope creep。

---

## 11. 这轮最小测试 / 验证要求

### 11.1 Flutter
如果你动到了前端 seed 消费或 model，请至少执行：
```bash
flutter pub get
flutter test
flutter analyze
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.2 Node / backend
如果你动到了 seed / catalog / mapper / fake data / PG seed，请至少执行：
```bash
npm test
npm run test:e2e
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.3 B2-2A 专项验证
至少完成这些验证：
1. 新增 5 个 items 全部锁定
2. 没有引入新 slot / 新 currency / 新 state machine
3. 当前 contract readiness 已有明确判断
4. 若有 patch candidate，它是 very small + read-only
5. 没有越界进入 B2-2B / B2-2C / B2-3

### 11.4 建议额外覆盖
如果范围允许，建议补：
- catalog seed loading / mapping tests
- customize page field dependency check
- inventory / equipment compatibility regression
- B2-1 regression 抽样检查

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — B2-2 status 起始文件
请新增：

```text
docs/R4_OptionB2_B22_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 B2-2A）
2. 已实现范围
3. 未实现范围
4. 当前 seed / metadata lock 结果
5. 当前 contract readiness judgment
6. 是否建议进入 B2-2B

### Deliverable B — B2-2 metadata lock 文件
请新增：

```text
docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md
```

至少包含：
1. 当前已有 5 个 items 的真实表
2. 新增 5 个 items 的 locked table
3. 现有语义复用检查
4. 是否需要 very small read-only patch
5. 若需要，最小 patch candidate 是什么

### Deliverable C — B2-2 test summary 起始文件
请新增：

```text
docs/R4_OptionB2_B22_Test_Summary_v0.1.md
```

至少包含：
1. 涉及的 seed / mapper / widget / e2e 入口
2. 哪些验证已跑
3. 哪些验证留到 B2-2B / B2-2C
4. 是否影响 B2-1 / B1 回归

### Deliverable D — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB2_B22A_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **What current 5 items are**
3. **What the new 5 locked items are**
4. **What contract readiness judgment is**
5. **Whether a read-only patch is needed**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**
11. **Whether ready for B2-2B**

### Optional
若你确认确实需要 very small read-only patch，才允许新增：

```text
docs/R4_OptionB2_B22_sync_candidates_v0.1.md
```

但不要默认制造 patch。

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B2-2A 完成：

1. 当前已有 5 个 items 已盘清
2. 新增 5 个 items 已锁定
3. 所有新增 items 均复用现有语义
4. 当前 contract readiness 已被明确判断
5. 若有 patch candidate，只能是 very small read-only
6. `docs/R4_OptionB2_B22_Status_v0.1.md` 已生成
7. `docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md` 已生成
8. `docs/R4_OptionB2_B22_Test_Summary_v0.1.md` 已生成
9. `docs/R4_cursor_round_summary_OptionB2_B22A_v0.1.md` 已生成
10. 最终能明确回答：是否 ready for **B2-2B**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B2 里的 **B2-2A / Seed + metadata lock**
- 明确不是 B2-2B / B2-2C / B2-3

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 B2-2A 结果
请按这几项写清楚：
1. current 5 items
2. new 5 locked items
3. semantic reuse check
4. contract readiness
5. patch needed or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果（若前端被影响）
- `flutter analyze` 结果（若前端被影响）
- `npm test` / `npm run test:e2e` 结果（若后端 / seed 被影响）
- B2-2A 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB2_B22_Status_v0.1.md`
- `docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md`
- `docs/R4_OptionB2_B22_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B22A_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B2-2A**
2. 是否 ready for **B2-2B**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你开始做完整 B2-2，更不是让你开 B2-3。

这轮唯一要做好的事情是：

> **先把新增 5 个 items 的 seed / metadata 和 contract readiness 一次钉死。**

不要扩 scope。  
不要偷拍板。  
不要把 B2-2B / B2-2C / B2-3 混进来。  
现在开始执行。
