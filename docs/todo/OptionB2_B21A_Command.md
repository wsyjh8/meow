# Cursor_OptionB2_B21A_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接改 Today / Meow Home / Customize 页面结构，也不是扩 catalog，而是：

> **按这里给定的 Room 1 handoff、Room 5 的 Option B2 UI 方案、以及 Room 4 的 execution planning，完成 Option B2（B2-1 first）的 Phase B2-1A：Copy pool expansion。**

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

> **Phase B2-1A — Copy pool expansion**

---

## 1. 这轮你到底要做什么

这轮只做：

1. 在**不改后端真相层、不新增 API、不新增字段、不扩 catalog** 的前提下，扩一轮 B2-1 的 companion / response / 承接 copy pool
2. 让 greeting / post-learning / feed / interaction / growth / equip / purchase / streak / status bubble / Today 承接文案更丰富、更不重复
3. 保持所有新增 copy 继续服从：
   - 学习优先
   - 温柔、可爱、清楚、顺滑
   - 不制造强负罪、强责备、强压迫体验
4. 保持 truth boundary 不被削弱
5. 若需要，只允许做**极小 content patch**
6. 更新 / 补齐与 copy expansion 相关的测试
7. 输出本轮 handoff 文档

这轮**不做**：
- 不开始 Today changes-expression enhancement（那是 B2-1B）
- 不开始 Meow Home / Customize changes-expression enhancement（那是 B2-1C）
- 不扩 catalog 5 → 10（那是 B2-2 范围）
- 不引入 `change_highlights[]`
- 不引入 typed `companion_response`
- 不引入 `source_fact_tags`
- 不新增 endpoint / payload / rule / state machine
- 不开 B2-3 sync patch

一句话：

> **B2-1A 是“内容池增强”，不是页面结构增强，也不是 sync patch 轮。**

---

## 2. 你必须接受的上游结论

### 2.1 Room 1 已正式拍板：当前做的是 `Option B2 (B2-1 first)`
Room 1 已明确：
- post-B1 next direction = **Option B2 — Content Expansion**
- 但当前正式下发给 Room 4 的，不是完整 B2，而是：

> **Option B2（B2-1 first）**

### 2.2 Room 1 已明确给出 B2-1 的推荐执行顺序
你当前只做第一刀：

- **B2-1A** — Copy pool expansion
- B2-1B — Today changes-expression enhancement
- B2-1C — Meow Home / Customize changes-expression enhancement
- B2-1D — Test & closeout

你这轮只做 **B2-1A**。

### 2.3 B2-2 / B2-3 不自动进入当前轮
当前 handoff 已写死：
- **B2-2 不自动进入**
- **B2-3 不自动进入**

也就是说，这轮不能顺手做：
- catalog 5 → 10
- `change_highlights[]`
- typed `companion_response`
- `source_fact_tags`
- richer payload / sync patch

### 2.4 Option B2 继续继承 truth boundary
B2 是 content expansion，不是 truth-layer rewrite。  
继续严格遵守：

- `delayed snapshot ≠ fresh backend truth`
- `pending reward ≠ 到账成功`
- `interaction click ≠ business fact`
- `displayed change ≠ backend-confirmed change`

所有“今天有变化”“去看看变化”“喵喵今天不一样了”这类表达，若不是后端已确认事实，只能是：

> **UI 承接文案**

不能写成业务既成事实。

---

## 3. 你必须服从的强断言

### 3.1 这轮只做 copy pool expansion
这轮只允许扩：

- greeting
- post-learning
- feed
- interaction
- growth / level-up
- equip / purchase
- streak node
- status bubble
- Today Companion Card 的轻承接 copy

### 3.2 这轮不是无限加文案
当前目标不是“文案越多越好”，而是：

> **让用户明显感觉“今天回来不完全一样”，但不把系统做成复杂内容树。**

因此：
- 允许小到中等扩池
- 不允许无限扩写
- 不允许新增复杂条件树
- 不允许新增 CMS / remote config / content system

### 3.3 所有新 copy 都不能越过真相边界
这轮最容易出错的是：

> **文案比事实跑得更快。**

因此必须继续保持：
- 没有后端确认的“已到账 / 已解锁 / 已升级 / 已生效”，不能写成既成事实
- interaction 的前端轻反馈不能写成真实成长 / 奖励 / 关系变化
- equip / purchase / preview 文案不能暗示超过后端已确认范围的结果
- Today 的变化承接 copy 不能伪装成 backend-confirmed change history

### 3.4 优先使用现有结构
你应该优先扩：
- 现有 helper
- 现有 mapping
- 现有数组 / 模板
- 现有 UI 承接位

而不是新建复杂内容系统。

### 3.5 Room 4 不是 UI / UX owner
你不能把实现便利包装成 UI 决策。  
文案风格、页面层级与承接方向，以 Room 5 的 `UI_SPEC_OptionB2_v0.1.md` 为准。  
Room 4 / Cursor 只能：
- 扩已有内容池
- 让 B2-1A 可实现、可测试
- 对做不稳的点记录为 sync candidate
- 不能擅自拍板新内容方向

---

## 4. 这轮的正确目标

根据 Room 1 handoff 与 Room 4 phases，B2-1A 的目标是：

> **先把 B2-1 中最纯的“内容层增强”收掉，不碰页面结构大改，不碰新 API / 新字段。**

这轮必须交付的，不是“完整内容系统”，而是：

1. 一轮明确可见的 copy 池扩充
2. 让 Meow Home / Today / Customize / interaction / feed / equip / purchase 的承接更丰富
3. 保持所有这些仍然：
   - 不越权
   - 不伪造真相
   - 不引入未批准的技术依赖

---

## 5. 这轮 in scope

### 5.1 必须优先扩的 copy pools
请优先扩这些**当前已经存在、且已有 UI 承接位**的内容池：

1. **greeting pool**
2. **post-learning response pool**
3. **feed response pool**
4. **interaction response pool**
5. **growth / level-up response pool**
6. **equip / purchase response pool**
7. **streak node / milestone copy**
8. **status bubble copy**
9. **Today Companion Card 的轻承接文案**

### 5.2 扩池策略（必须）
请采用：

> **小到中等扩池、低风险、直接可见、复用现有结构。**

推荐原则：
- 每类只补到“明显不那么重复”的程度
- 优先扩现有条件分支里的文案数组 / 模板
- 不新增深条件树
- 不要求每个状态都覆盖很多条
- 不追求 content volume，追求 **visible freshness**

### 5.3 若需要极小后端 content patch
如果当前 repo 的 companion / response 文案源在后端 helper / DevStore / content helper 中，这轮允许做**极小后端 content patch**，例如：
- 扩 `getCompanionResponse()` 或等价 helper 的文案池
- 扩 feed / equip / purchase / streak / bubble 相关 response mapping

但必须满足：
- 不新增 API 字段
- 不改响应结构
- 不改业务规则
- 不改持久化结构

### 5.4 前端承接（允许）
这轮也允许在前端：
- 调整现有 copy 的显示位
- 更柔和地承接已存在的 response
- 对 snack / toast / chip 文案做轻优化

但必须满足：
- 不新增真相字段依赖
- 不伪造业务状态
- 不把 preview / weak hint 写成已确认事实

---

## 6. 这轮明确不做什么

### 6.1 不做 B2-1B 页面表达增强
以下内容留到 **B2-1B**：
- Today Companion Card 第二层结构增强
- 今日变化条 / changes chips
- settlement follow-up 的更完整承接块
- Today 的轻目标感结构增强

### 6.2 不做 B2-1C 页面表达增强
以下内容留到 **B2-1C**：
- Meow Home 的今日重点变化区
- Meow Home 的状态泡泡结构增强
- Customize 的“买了之后会变什么 / 已买未装 / 当前搭配重点”表达增强

### 6.3 不做 B2-2
- 不扩 catalog 5 → 10
- 不新增主题 item / room item
- 不做 inventory / equipment 内容层大扩展

### 6.4 不做 B2-3
- 不新增 `change_highlights[]`
- 不新增 typed `companion_response`
- 不新增 `source_fact_tags`
- 不新增 richer payload / new helper contract

### 6.5 不改变业务事实表达
- 不把 pending 写成到账成功
- 不把 interaction 文案写成成长已成立
- 不把 equip / purchase 的承接文案写成超越后端确认范围的事实
- 不把“今天有变化”写成后台已确认的 change history

---

## 7. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 7.1 当前 B1 closeout / runtime 状态
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase5_v0.1.md`

### 7.2 B2 输入
- `R1_to_R4_OptionB2_B21_Handoff_v0.1.md`
- `UI_SPEC_OptionB2_v0.1.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `UI_SPEC_v0.1.4.md`
- `b2_b1_phases.md`

### 7.3 当前 copy / response 入口
至少盘点这些现有入口：
- companion response 生成函数 / helper / DevStore
- feed 成功后的反馈文案
- purchase / equip 的反馈文案
- Today Companion Card 的文案来源
- interaction 的本地前端文案来源
- Meow Home status bubble 的文案来源
- streak node / milestone 文案来源

### 7.4 当前测试入口
至少盘点：
- companion response / Meow Home / Today / Customize 相关 widget tests
- any copy helper tests / state tests
- 页面 smoke tests
- 既有 B1 regression 入口

---

## 8. B2-1A 你必须明确回答的问题

### Q1. 这轮到底扩了哪些 copy pools
请明确列出：
- greeting
- post-learning
- feed
- interaction
- growth / level-up
- equip / purchase
- streak node
- status bubble
- Today 承接文案

### Q2. 你如何保证这些 copy 没越过真相边界
请明确：
- 哪些只是 UI 承接
- 哪些基于现有后端字段
- 哪些没有改业务语义
- 为什么不会伪确认

### Q3. 这轮如果改了后端，具体改了什么
请明确：
- 是否只是扩文案数组 / mapping / helper
- 是否保持响应结构不变
- 是否无 DB / API 变更

### Q4. 这轮如何保证没越界到 B2-1B / B2-1C / B2-2 / B2-3
请明确：
- 没有改 Today 页面结构
- 没有改 Meow Home / Customize 的结构增强块
- 没有扩 catalog
- 没有新增字段
- 没有新增 sync patch
- 没有改业务规则

### Q5. B2-1B 最自然的开工点是什么
请给出最小建议：
- Today 页哪个 widget 最适合先拆
- 哪类 changes-expression 最容易稳落
- 哪些测试最该先跟进

---

## 9. 这轮允许做什么，不允许做什么

### 允许做的
1. 扩现有 companion / response 文案池
2. 扩前端 interaction 本地反馈文案
3. 扩 feed / equip / purchase / streak / bubble 轻回应
4. 做极小后端 content patch（若仅为扩文案源）
5. 调整前端 copy 承接位
6. 更新 / 新增 helper / widget tests
7. 做 very small docs sync（只记录 B2-1A 新事实）

### 不允许做的
1. 不改后端 API 契约
2. 不扩 catalog
3. 不新增业务字段
4. 不新增复杂内容系统
5. 不改业务规则
6. 不改 DB / API / persistence
7. 不把 B2-1B / B2-1C / B2-2 / B2-3 混进来

如果你做了任何超出 B2-1A 的事，必须解释为什么仍算 copy pool expansion，而不是 scope creep。

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

### 10.2 若做了极小后端文案 patch
若你碰了后端文案源，请至少补 / 跑：
```bash
npm test
npm run test:e2e
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 10.3 B2-1A 专项验证
至少完成这些验证：
1. companion / response 文案明显不再那么重复
2. 文案风格仍温柔、可爱、不过界
3. Meow Home / Today / Customize / interaction / feed / equip 至少有一部分新 copy 被用户可见
4. 现有功能链路不破
5. 没有越界进入 B2-1B / B2-1C / B2-2 / B2-3

### 10.4 建议额外覆盖
如果范围允许，建议补：
- copy helper tests
- Meow Home / Today / Customize 文案 smoke
- feed / equip / purchase / interaction 反馈 smoke
- 关键 truth-boundary 文案检查

---

## 11. 本轮必须产出的文件（硬要求）

### Deliverable A — B2-1 status 起始文件
请新增：

```text
docs/R4_OptionB2_B21_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 B2-1A）
2. 已实现范围
3. 未实现范围
4. 仍待处理问题
5. 是否触发 very small sync patch candidate
6. 当前是否建议进入 B2-1B

### Deliverable B — B2-1 test summary 起始文件
请新增：

```text
docs/R4_OptionB2_B21_Test_Summary_v0.1.md
```

至少包含：
1. Flutter / widget / regression 入口
2. 哪些 surfaces 已被 copy enhancement 触达
3. truth boundary 是否保持
4. 是否触碰现有 API / DB
5. 是否影响现有 Option A / A.1 / B1 回归

### Optional
若你确认纯前端做不稳，才允许新增：

```text
docs/R4_OptionB2_B21_sync_candidates_v0.1.md
```

但不要默认制造 sync patch。

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB2_B21A_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **What copy pools were expanded**
3. **What truth boundary was kept**
4. **What backend surface did or did not change**
5. **What is still not done**
6. **What must be done next**
7. **What not to touch**
8. **Files / modules to read first**
9. **Current risks**
10. **Whether ready for B2-1B**

---

## 12. 这轮完成标准（严格）

以下全部满足，才算 B2-1A 完成：

1. 至少一轮明确的 copy pool expansion 已完成
2. Meow Home / Today / Customize / interaction / feed / equip 至少有一部分新 copy 可见
3. truth boundary 继续守住，无伪确认
4. 没有改后端契约
5. `docs/R4_OptionB2_B21_Status_v0.1.md` 已生成
6. `docs/R4_OptionB2_B21_Test_Summary_v0.1.md` 已生成
7. `docs/R4_cursor_round_summary_OptionB2_B21A_v0.1.md` 已生成
8. 最终能明确回答：是否 ready for **B2-1B**

---

## 13. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B2（B2-1 first）里的 **B2-1A / Copy pool expansion**
- 明确不是 B2-1B / B2-1C / B2-2 / B2-3

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 copy expansion 结果
请按这几项写清楚：
1. expanded copy pools
2. visible surfaces
3. truth boundary
4. backend touched or not
5. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 若改了后端：`npm test` / `npm run test:e2e` 结果
- B2-1A 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB2_B21_Status_v0.1.md`
- `docs/R4_OptionB2_B21_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B21A_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B2-1A**
2. 是否 ready for **B2-1B**
3. 当前最大的剩余风险是什么

---

## 14. 最后提醒

这轮不是让你扩 catalog，也不是让你开 sync patch。

这轮唯一要做好的事情是：

> **先把 B2-1 里最纯的内容层增强收掉，让用户明显感觉“今天回来不完全一样”，但又不越过真相边界。**

不要扩 scope。  
不要偷拍板。  
不要把 B2-1B / B2-1C / B2-2 / B2-3 混进来。  
现在开始执行。
