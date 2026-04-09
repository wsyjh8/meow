# Cursor_OptionB2_B21C_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是继续改 Today，也不是扩 catalog，而是：

> **按这里给定的 Room 1 handoff、Room 5 的 Option B2 UI 方案、以及 Room 4 的 execution planning，完成 Option B2（B2-1 first）的 Phase B2-1C：Meow Home / Customize changes-expression enhancement。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前状态不是 P1 / P2，也不是 Option A / Option A.1，也不是 Option B（B1）。  
这些都已经完成并 close。  
Room 1 已正式拍板下一方向为：

> **Option B2 — Content Expansion**

但当前 Room 1 正式下发给 Room 4 的，不是完整 B2，而是：

> **Option B2（B2-1 first）**

而你这轮接的也不是完整 B2-1，而是：

> **Phase B2-1C — Meow Home / Customize changes-expression enhancement**

---

## 1. 当前已完成到哪里

B2-1A 已完成，且当前结论是：
- companion / response 文案池已完成一轮扩池
- 用户可感知“今天回来不完全一样”
- truth boundary 继续守住
- 无 API / DB / persistence 改动

B2-1B 也已完成，且当前结论是：
- Today Companion Card 已升级为双层结构
- changes chips + goal cue 已落地
- settlement follow-up 承接已更自然
- 主 CTA 层级保持最强
- 无 API / DB / persistence 改动

你现在接的不是：
- B2-1D
- B2-2
- B2-3

而是：

> **只做 Meow Home 和 Customize 的 changes-expression 增强。**

---

## 2. 这轮你到底要做什么

这轮只做：

1. 在**不新增后端字段、不新增 API、不扩 catalog 5→10** 的前提下，增强 Meow Home 和 Customize 中“今天有变化 / 买了之后会变什么 / 已买未装 / 当前搭配重点”的表达层
2. 把 B2-1 的“变化承接”从 Today 扩展到：
   - **Meow Home**
   - **Customize**
3. 让用户更明确感知：
   - 今天学了之后，喵喵侧有什么值得看
   - 当前已装备组合的重点是什么
   - 某个物品买了 / 装了后会带来什么可见差异
   - 已买但未装的东西仍然值得去处理
4. 继续复用 B1 / B2-1A / B2-1B 已有的 theme、shared widgets、copy pools
5. 保持所有业务逻辑不变
6. 更新 / 补齐 Meow Home / Customize 相关 Flutter tests
7. 输出本轮 handoff 文档

这轮**不做**：
- 不扩 catalog 5 → 10（那是 B2-2）
- 不引入 `change_highlights[]`
- 不引入 typed `companion_response`
- 不引入 `source_fact_tags`
- 不新增 endpoint / payload / rule / state machine
- 不开 B2-3 sync patch
- 不改 Today 结构
- 不改主机制规则

一句话：

> **B2-1C 是 Meow Home / Customize 的“变化表达增强”，不是新真相层，不是 catalog 扩容轮。**

---

## 3. 你必须接受的上游结论

### 3.1 Room 1 已正式拍板：当前做的是 `Option B2 (B2-1 first)`
Room 1 已明确：
- post-B1 next direction = **Option B2 — Content Expansion**
- 但当前正式下发给 Room 4 的，不是完整 B2，而是：

> **Option B2（B2-1 first）**

### 3.2 Room 1 已明确给出 B2-1 的推荐执行顺序
你当前只做第三刀：

- B2-1A — Copy pool expansion ✅ 已完成
- B2-1B — Today changes-expression enhancement ✅ 已完成
- **B2-1C — Meow Home / Customize changes-expression enhancement**
- B2-1D — Test & closeout

### 3.3 B2-2 / B2-3 不自动进入当前轮
当前 handoff 已写死：
- **B2-2 不自动进入**
- **B2-3 不自动进入**

也就是说，这轮不能顺手做：
- catalog 5 → 10
- `change_highlights[]`
- typed `companion_response`
- `source_fact_tags`
- richer payload / sync patch

### 3.4 Option B2 继续继承 truth boundary
B2 是 content expansion，不是 truth-layer rewrite。  
继续严格遵守：

- `delayed snapshot ≠ fresh backend truth`
- `pending reward ≠ 到账成功`
- `interaction click ≠ business fact`
- `displayed change ≠ backend-confirmed change`

所有“今天有变化”“换上之后会更不一样”“已经变成这样了”这类表达，若不是后端已确认事实，只能是：

> **UI 承接文案 / UI 预览态 / UI 比较态**

不能写成业务既成事实。

### 3.5 Preview / compare 的硬边界
这轮最重要的另一条红线是：

> **preview / compare ≠ 当前已装备真相。**

你可以让用户更容易看出：
- 当前搭配重点
- 某个 item 买了之后会怎样
- 已买未装有什么可以试

但不能：
- 把 preview 伪装成 equipped
- 把 compare 伪装成 backend-confirmed change
- 把可买目标写成业务承诺

---

## 4. 你必须服从的强断言

### 4.1 这轮只做 Meow Home / Customize changes-expression
这轮只允许增强：

#### Meow Home
- 今日重点变化区
- 状态泡泡增强
- 最近获得的变化感
- 成长 / 装备 / 陪伴反馈的更细粒度承接

#### Customize
- “买了之后会变什么”
- “已买未装”
- “当前搭配重点”
- 轻目标感标签
- 当前 vs 可换 / 可买 的更明确表达

### 4.2 这些增强只能按三层数据来源理解
Meow Home / Customize 相关增强块，必须继续按以下三层理解：

1. **Direct existing backend field**
2. **Pure front-end static content layer**
3. **Very small sync patch required**（当前默认不进入）

默认禁止：
- 前端自由拼接出“今日 confirmed changes 历史”
- 前端把多个已存在字段拼成新的后端真相块
- 没有后端确认的 equipped / owned / upgraded / unlocked 事实被写成既成事实

### 4.3 不得偷带 B2-2
这轮不允许因为“想让 Customize 更有内容感”而顺手：
- 扩 catalog 5 → 10
- 新增 item
- 新增 slot
- 新增价格体系
- 新增 level-lock 规则

### 4.4 继续优先使用现有结构
你应该优先复用：
- B1 已重排的 Meow Home
- B1 已重排的 Customize
- B2-1A 已扩好的 copy 池
- B2-1B 的 changes-expression 模式
- 现有 secondary summary / inventory / equipment / settlement state
- 现有 shared theme / widget / chip / card

而不是新建复杂的内容系统。

### 4.5 Room 4 不是 UI / UX owner
你不能把实现便利包装成 UI 决策。  
文案风格、页面层级与承接方向，以 Room 5 的 `UI_SPEC_OptionB2_v0.1.1.md` 为准。  
Room 4 / Cursor 只能：
- 增强 Meow Home / Customize 的 changes-expression
- 让 B2-1C 可实现、可测试
- 对做不稳的点记录为 sync candidate
- 不能擅自拍板新内容方向

---

## 5. 这轮的正确目标

根据 Room 1 handoff 与 Room 4 phases，B2-1C 的目标是：

> **把“今天有变化”的表达从 Today 扩展到 Meow Home / Customize，但继续不越过真相边界。**

这轮必须交付的，不是“完整变化历史系统”或“完整搭配推荐引擎”，而是：

1. Meow Home 中更细腻的变化承接块
2. Customize 中更清楚的 preview / compare / 已买未装 / 当前搭配重点表达
3. 所有这些都不越过 truth boundary
4. 所有这些都不引入新 API / 新字段 / B2-2 catalog 扩容

---

## 6. 这轮 in scope

### 6.1 Meow Home：今日重点变化区（必须）
请在 Meow Home 中增加一个轻量的 **今日重点变化区**，让用户能看到：

- 今天喵喵哪里更不一样
- 今天通过学习 / 喂猫 / 装备 / streak 带来的“可看变化线索”
- 最近值得看的变化重点

但默认只能表达成：
- UI 承接
- 或现有已确认字段的可见层增强

不能表达成：
- 后端 confirmed change history
- 新的变化时间线系统

### 6.2 Meow Home：状态泡泡增强（允许）
你这轮可以增强：
- 状态泡泡的文案层次
- 让它更贴近今天的状态
- 把 B2-1A 扩好的 copy 更好接到气泡里

但必须继续满足：
- 不伪造业务事实
- 不把 interaction click 写成成长成立
- 不把展示变化写成后端已确认变化

### 6.3 Meow Home：最近获得的变化感（允许）
你可以增加一个非常轻的“最近变化感”表达，例如：
- 最近多了一点什么
- 今天更像什么样了
- 某个装备 / 成长更值得看

但默认必须属于：
- **Direct existing backend field**
- 或 **Pure front-end static content layer**

不能：
- 自行拼装 confirmed change list
- 让用户误以为有后端变化日志

### 6.4 Customize：买了之后会变什么（必须）
请把 Customize 中“买了之后会变什么”做得更明确，但必须遵守：

- 这是 **preview / compare / hint**
- 不是当前已装备真相
- 不是后端承诺

推荐做法：
- 轻 compare 区
- 购买前后的视觉差异 hint
- 物品带来的“更适合当前搭配 / 更接近目标”的轻提示

### 6.5 Customize：已买未装（必须）
请让用户能更直观看到：
- 什么已经买了
- 但还没装
- 是否值得去试一下

可以做：
- owned-not-equipped 的更明显表达
- 更自然的 CTA / chips / tags

但不能：
- 把 owned 写成 equipped
- 把 preview 写成 equipped

### 6.6 Customize：当前搭配重点（允许）
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

### 6.7 数据来源建议
这轮推荐优先用当前已有的：
- secondary summary
- companion_response
- inventory / equipment
- equipped preview
- B2-1A 扩好的文案池
- B2-1B 已建立的 changes-expression 组件模式

不要新增字段。

---

## 7. 这轮明确不做什么

### 7.1 不改后端
- 不改 `/me/secondary-summary`
- 不改 `/me/feed`
- 不改 `/shop/catalog`
- 不改 `/shop/purchases`
- 不改 `/me/inventory`
- 不改 `/me/equipment`
- 不改 equip / unequip API
- 不改 persistence

### 7.2 不扩 catalog
- 不新增 item
- 不新增 item type / slot
- 不扩价格体系
- 不扩 level-lock 规则

### 7.3 不做 B2-3
- 不新增 `change_highlights[]`
- 不新增 typed `companion_response`
- 不新增 `source_fact_tags`
- 不新增 richer payload / new helper contract

### 7.4 不改变业务事实表达
- 不把 pending 写成到账成功
- 不把 preview 写成已装备
- 不把前端比较变化写成后端已确认变化
- 不把 Meow Home 今日重点变化写成 confirmed history

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 B1 / B2-1A / B2-1B 当前状态
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase5_v0.1.md`
- `docs/R4_OptionB2_B21_Status_v0.1.md`
- `docs/R4_OptionB2_B21_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B21A_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B21B_v0.1.md`

### 8.2 B2 输入
- `R1_to_R4_OptionB2_B21_Handoff_v0.1.md`
- `UI_SPEC_OptionB2_v0.1.1.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `UI_SPEC_v0.1.4.md`
- `b2_b1_phases.md`

### 8.3 当前 Meow Home / Customize 入口
至少盘点这些现有入口：
- `MeowHomePage`
- `CustomizePage`
- companion / summary / equipped preview 相关 widgets
- inventory / equipment / purchase / equip 的 UI 展示入口
- shared theme / components / animations
- B2-1A 已接入的文案来源

### 8.4 当前测试入口
至少盘点：
- `meow_home_page_test.dart`
- `customize_page_test.dart`（若有）
- purchase / equip / equipped preview / owned state 相关前端测试
- 页面 smoke tests
- B1 / B2-1A / B2-1B 回归入口

---

## 9. B2-1C 你必须明确回答的问题

### Q1. Meow Home 最终增强了什么
请明确描述：
- 今日重点变化区
- 状态泡泡增强
- 最近获得的变化感
- 哪些属于 Direct existing backend field
- 哪些属于 Pure front-end static content layer

### Q2. Customize 最终增强了什么
请明确描述：
- 买了之后会变什么
- 已买未装
- 当前搭配重点
- compare / preview 是如何表达的
- 为什么不会被误读为 equipped truth

### Q3. 这些变化表达分别属于哪一层数据来源
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

### Q5. 这轮如何保证没越界到 B2-1D / B2-2 / B2-3
请明确：
- 没有扩 catalog
- 没有新增字段
- 没有新增 sync patch
- 没有改业务规则
- 没有重改 Today

### Q6. B2-1D 最自然的开工点是什么
请给出最小建议：
- 哪些 regression 要先收
- 哪些 truth-boundary case 最容易漏
- 当前 close bar 哪几项最值得重点复核

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 增强 Meow Home 的 changes-expression
2. 增强 Customize 的 preview / compare / owned-not-equipped 表达
3. 调整 Meow Home / Customize 中变化承接层的视觉层级
4. 复用 B2-1A / B2-1B 的 copy 与 changes-expression 模式
5. 更新 / 新增 widget tests
6. 做 very small docs sync（只记录 B2-1C 新事实）

### 不允许做的
1. 不改后端 API 契约
2. 不扩 catalog
3. 不新增业务字段
4. 不新增 sync patch
5. 不改 Today 结构
6. 不改业务规则
7. 不把 B2-1D / B2-2 / B2-3 混进来

如果你做了任何超出 B2-1C 的事，必须解释为什么仍算 Meow Home / Customize changes-expression enhancement，而不是 scope creep。

---

## 11. 这轮最小测试 / 验证要求

### 11.1 Flutter
至少要执行：
```bash
flutter pub get
flutter test
flutter analyze
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.2 若你碰了极小后端 content helper
若你只是为了复用文案源做了极小 helper 改动，请补 / 跑：
```bash
npm test
npm run test:e2e
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.3 B2-1C 专项验证
至少完成这些验证：
1. Meow Home changes-expression 已更细腻
2. Customize 的 preview / compare / 已买未装表达已更清楚
3. preview / compare 不会被误读成 equipped truth
4. truth boundary 不越界
5. 没有越界进入 B2-2 / B2-3
6. 现有功能链路不破

### 11.4 建议额外覆盖
如果范围允许，建议补：
- Meow Home widget tests
- Customize widget tests
- equipped preview / owned-not-equipped smoke
- 关键 truth-boundary 文案检查
- B2-1A / B2-1B 回归检查

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — B2-1 status 更新
请更新：

```text
docs/R4_OptionB2_B21_Status_v0.1.md
```

至少补：
1. 当前完成到哪个 phase（必须写 B2-1C）
2. 已实现范围
3. 未实现范围
4. 仍待处理问题
5. 是否触发 very small sync patch candidate
6. 当前是否建议进入 B2-1D

### Deliverable B — B2-1 test summary 更新
请更新：

```text
docs/R4_OptionB2_B21_Test_Summary_v0.1.md
```

至少包含：
1. Meow Home / Customize 相关 widget / regression / smoke 入口
2. changes-expression 触达的 surfaces
3. truth boundary 是否保持
4. 是否触碰现有 API / DB
5. 是否影响现有 B1 / B2-1A / B2-1B 回归

### Optional
若你确认纯前端做不稳，才允许新增 / 更新：

```text
docs/R4_OptionB2_B21_sync_candidates_v0.1.md
```

但不要默认制造 sync patch。

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB2_B21C_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **What Meow Home changes-expression now includes**
3. **What Customize compare / preview now includes**
4. **What truth boundary was kept**
5. **What backend surface did or did not change**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**
11. **Whether ready for B2-1D**

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B2-1C 完成：

1. Meow Home changes-expression 已增强
2. Customize 的 preview / compare / 已买未装表达已增强
3. truth boundary 继续守住，无伪确认
4. 没有改后端契约
5. `docs/R4_OptionB2_B21_Status_v0.1.md` 已更新
6. `docs/R4_OptionB2_B21_Test_Summary_v0.1.md` 已更新
7. `docs/R4_cursor_round_summary_OptionB2_B21C_v0.1.md` 已生成
8. 最终能明确回答：是否 ready for **B2-1D**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B2（B2-1 first）里的 **B2-1C / Meow Home + Customize changes-expression enhancement**
- 明确不是 B2-1D / B2-2 / B2-3

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 Meow Home / Customize 结果
请按这几项写清楚：
1. meow home changes-expression
2. customize preview / compare
3. owned-not-equipped expression
4. truth boundary
5. backend touched or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 若改了后端：`npm test` / `npm run test:e2e` 结果
- B2-1C 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB2_B21_Status_v0.1.md`
- `docs/R4_OptionB2_B21_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B21C_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B2-1C**
2. 是否 ready for **B2-1D**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你扩 catalog，也不是让你开 sync patch。

这轮唯一要做好的事情是：

> **把 Meow Home / Customize 里的“今天有变化、买了之后会变什么、已买未装、当前搭配重点”做得更完整，但继续不越过真相边界。**

不要扩 scope。  
不要偷拍板。  
不要把 B2-1D / B2-2 / B2-3 混进来。  
现在开始执行。
