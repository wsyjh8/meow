# Cursor_OptionB2_B21B_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是改 Meow Home / Customize，也不是扩 catalog，而是：

> **按这里给定的 Room 1 handoff、Room 5 的 Option B2 UI 方案、以及 Room 4 的 execution planning，完成 Option B2（B2-1 first）的 Phase B2-1B：Today changes-expression enhancement。**

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

> **Phase B2-1B — Today changes-expression enhancement**

---

## 1. 当前已完成到哪里

B2-1A 已完成，且当前结论是：

- companion / response 文案池已完成一轮扩池
- copy 总量已明显提升，用户可感知“今天回来不完全一样”
- truth boundary 继续守住
- 没有改 API 契约 / DB / persistence
- 已生成：
  - `docs/R4_OptionB2_B21_Status_v0.1.md`
  - `docs/R4_OptionB2_B21_Test_Summary_v0.1.md`
  - `docs/R4_cursor_round_summary_OptionB2_B21A_v0.1.md`

你现在接的不是：
- B2-1C
- B2-1D
- B2-2
- B2-3

而是：

> **只做 Today 页里的 changes-expression 增强。**

---

## 2. 这轮你到底要做什么

这轮只做：

1. 在**不削弱主学习 CTA、不新增后端字段、不新增 API** 的前提下，增强 Today 页里的“今天有变化 / 今天继续学还会有变化”的表达层
2. 把 Today 页里的副机制承接从 B1 的基础 Companion Card，升级到 **更完整但仍然轻量** 的 changes-expression 层
3. 让用户更明确感知：
   - 今天学了之后，猫猫侧有变化可看
   - 今天若继续学，还会有更具体的变化可期待
   - 但主线仍然是学习，不是看猫
4. 继续复用 B1/B2-1A 已有的 theme、组件和扩好的 copy 池
5. 保持所有业务逻辑不变
6. 更新 / 补齐 Today 页相关 Flutter tests
7. 输出本轮 handoff 文档

这轮**不做**：
- 不开始 Meow Home / Customize 的 changes-expression 增强（那是 B2-1C）
- 不扩 catalog 5 → 10（那是 B2-2）
- 不引入 `change_highlights[]`
- 不引入 typed `companion_response`
- 不引入 `source_fact_tags`
- 不新增 endpoint / payload / rule / state machine
- 不开 B2-3 sync patch

一句话：

> **B2-1B 是 Today 页的“变化承接表达增强”，不是新的真相层，也不是新的内容系统。**

---

## 3. 你必须接受的上游结论

### 3.1 Room 1 已正式拍板：当前做的是 `Option B2 (B2-1 first)`
Room 1 已明确：
- post-B1 next direction = **Option B2 — Content Expansion**
- 但当前正式下发给 Room 4 的，不是完整 B2，而是：

> **Option B2（B2-1 first）**

### 3.2 Room 1 已明确给出 B2-1 的推荐执行顺序
你当前只做第二刀：

- B2-1A — Copy pool expansion ✅ 已完成
- **B2-1B — Today changes-expression enhancement**
- B2-1C — Meow Home / Customize changes-expression enhancement
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

所有“今天有变化”“去看看变化”“喵喵今天不一样了”这类表达，若不是后端已确认事实，只能是：

> **UI 承接文案**

不能写成业务既成事实。

### 3.5 Today 页最重要的红线
这轮最重要的红线是：

> **主学习 CTA 仍然必须是 Today 页最强动作。**

不允许出现：
- Companion Card / changes block 比主任务卡更抢眼
- “去看看喵喵变化”比“开始学习 / 去复习 / 继续本组复习”更强
- 为了变化感，把 Today 做成副机制首页

---

## 4. 你必须服从的强断言

### 4.1 这轮只做 Today changes-expression
这轮只允许增强：

- Companion Card 第二层
- 今日变化条 / changes chips
- 轻目标感提示
- settlement follow-up 承接语
- Today 副机制摘要的层级优化

### 4.2 变化表达只能分三层理解
Today 相关增强块，必须继续按以下三层理解：

1. **Direct existing backend field**
2. **Pure front-end static content layer**
3. **Very small sync patch required**（当前默认不进入）

默认禁止：
- 没有后端确认的 confirmed change 明细
- 前端自由拼接出“今天已确认发生了哪些变化”的历史
- 用多个已有字段拼成像 `change_history` 一样的真相块

### 4.3 主 CTA 层级不可削弱
你可以：
- 让 Companion Card 更完整
- 让变化感更具体
- 让去喵喵页的弱入口更自然

但不能：
- 弱化主任务卡
- 弱化主 CTA
- 把 changes-expression 做成 Today hero 区

### 4.4 继续优先使用现有结构
你应该优先复用：
- B1 的 Today 页面结构
- B2-1A 已扩好的 copy 池
- 现有 secondary summary / companion response / settlement state
- 现有 shared theme / widget / chip / card

而不是新建复杂的 Today 内容系统。

### 4.5 Room 4 不是 UI / UX owner
你不能把实现便利包装成 UI 决策。  
文案风格、页面层级与承接方向，以 Room 5 的 `UI_SPEC_OptionB2_v0.1.1.md` 为准。  
Room 4 / Cursor 只能：
- 增强 Today 的 changes-expression
- 让 B2-1B 可实现、可测试
- 对做不稳的点记录为 sync candidate
- 不能擅自拍板新内容方向

---

## 5. 这轮的正确目标

根据 Room 1 handoff 与 Room 4 phases，B2-1B 的目标是：

> **把 Today 页里的变化承接表达增强，但继续稳稳守住“学习优先、主 CTA 最强”。**

这轮必须交付的，不是“完整变化历史系统”，而是：

1. 一个更完整的 Today Companion Card 第二层
2. 今日变化条 / changes chips / 轻目标感提示
3. 结算返回后的更自然承接
4. 所有这些都不越过 truth boundary

---

## 6. 这轮 in scope

### 6.1 Companion Card 第二层（必须）
请把 Today 页里的副机制摘要区，从 B1 的基础 Companion Card，升级成**双层结构**：

#### 第一层
- 轻陪伴问候
- 现有 companion_response / greeting / post-learning response 的承接

#### 第二层
- 今日变化承接块
- 最多 1–3 条变化线索
- 可以是：
  - 轻变化句
  - changes chips
  - 轻目标感提示
  - 去喵喵页查看的弱入口

### 6.2 今日变化条 / changes chips（允许）
你这轮可以做：
- changes chips
- 今日变化条
- “今天有一点不一样”的轻提示

但这些块默认只能消费：
- **Direct existing backend field**
- **Pure front-end static content layer**

不能做：
- confirmed change history
- 后端未确认的变化明细列表
- 新字段依赖

### 6.3 settlement follow-up 承接（允许）
这轮允许在 Today 中增强：
- 结算返回后的轻承接语
- “去看看今天的小变化”
- “今天又多了一点不一样”

但不允许：
- 厚重手游式结算感
- 重复大动画
- 把结算已触发 / 已展示写成奖励已到账成功

### 6.4 轻目标感提示（允许）
你这轮可以增加一些轻目标感提示，例如：
- 再学一点可以看到更多变化
- 再攒一点更接近某个可见目标
- 今天再完成一步，喵喵会更有回应

但这些默认必须属于：
- **Pure front-end static content layer**
- 或基于现有字段的弱承接

不能：
- 假装系统已经有完整目标推荐引擎
- 写成业务承诺
- 写成排序规则已冻结

### 6.5 数据来源建议
这轮推荐优先用当前已有的：
- Today 聚合接口
- secondary summary
- settlement 返回后的已存在状态
- companion_response
- B2-1A 新扩的文案池

如要做“变化感”，优先：
- 前端弱承接文案
- chip / tag / hint
- 轻比较式提示

不要新增字段。

---

## 7. 这轮明确不做什么

### 7.1 不改后端
- 不改 `/me/today`
- 不改 `/me/secondary-summary`
- 不改 settlement API
- 不改 persistence

### 7.2 不扩内容池主结构
- 不再开大一轮 copy 系统设计
- 不新增 `change_highlights[]`
- 不新增 typed `companion_response`
- 不新增后台变化明细字段

### 7.3 不做其他页面
以下内容留到 **B2-1C**：
- Meow Home 的今日重点变化区
- Meow Home 的状态泡泡结构增强
- Customize 的“买了之后会变什么 / 已买未装 / 当前搭配重点”表达增强

### 7.4 不改变业务事实表达
- 不把 pending 写成到账成功
- 不把 delayed snapshot 写成 fresh truth
- 不把前端比较变化写成后端已确认变化
- 不把 Companion Card 写成主流程 CTA

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 B1 / B2-1A 当前状态
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase5_v0.1.md`
- `docs/R4_OptionB2_B21_Status_v0.1.md`
- `docs/R4_OptionB2_B21_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B21A_v0.1.md`

### 8.2 B2 输入
- `R1_to_R4_OptionB2_B21_Handoff_v0.1.md`
- `UI_SPEC_OptionB2_v0.1.1.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `UI_SPEC_v0.1.4.md`
- `b2_b1_phases.md`

### 8.3 当前 Today 入口
至少盘点这些现有入口：
- `TodayPage` / 今日页相关 widgets
- 主 CTA 所在任务卡
- companion / secondary summary 相关 widget
- 结算返回后的提示入口
- shared theme / components / animations
- B2-1A 已接入的文案来源

### 8.4 当前测试入口
至少盘点：
- Today 页 widget tests
- 主 CTA / summary / streak / check-in 相关前端测试
- 页面 smoke tests
- 若有 settlement return UI tests 也要看

---

## 9. B2-1B 你必须明确回答的问题

### Q1. Today 页最终增强了什么
请明确描述：
- Companion Card 第二层
- 今日变化条 / chips
- 轻目标感提示
- settlement follow-up 承接
- 主 CTA 层级是否保持不变

### Q2. 这些 changes-expression 分别属于哪一层数据来源
请逐类标出：
- Direct existing backend field
- Pure front-end static content layer
- Very small sync patch required（若出现必须说明为什么仍未进入）

### Q3. 你如何保证这些表达没越过真相边界
请明确：
- 哪些只是 UI 承接
- 哪些基于现有后端字段
- 为什么不会伪确认
- 为什么不会被误读成 confirmed change history

### Q4. 这轮如何保证没越界到 B2-1C / B2-2 / B2-3
请明确：
- 没有改 Meow Home / Customize 结构增强块
- 没有扩 catalog
- 没有新增字段
- 没有新增 sync patch
- 没有改业务规则

### Q5. B2-1C 最自然的开工点是什么
请给出最小建议：
- Meow Home 哪个变化块最适合先拆
- Customize 哪个 compare / preview 区最适合先做
- 哪些测试最该先跟进

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 增强 Today 页里的 changes-expression
2. 做 Companion Card 第二层
3. 做 changes chips / hint / weak goal cues
4. 做 settlement follow-up 轻承接
5. 调整 Today 中副机制承接层的视觉层级
6. 更新 / 新增 widget tests
7. 做 very small docs sync（只记录 B2-1B 新事实）

### 不允许做的
1. 不改后端 API 契约
2. 不扩 catalog
3. 不新增业务字段
4. 不新增 sync patch
5. 不改 Meow Home / Customize 的变化表达块
6. 不改业务规则
7. 不把 B2-1C / B2-2 / B2-3 混进来

如果你做了任何超出 B2-1B 的事，必须解释为什么仍算 Today changes-expression enhancement，而不是 scope creep。

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

### 11.3 B2-1B 专项验证
至少完成这些验证：
1. Today 的 changes-expression 已更完整
2. 主 CTA 仍然是 Today 页最强动作
3. Companion Card / changes block 没压主线
4. 结算返回承接更自然
5. truth boundary 不越界
6. 没有越界进入 B2-1C / B2-2 / B2-3

### 11.4 建议额外覆盖
如果范围允许，建议补：
- Today 页 widget tests
- 主 CTA 层级检查
- Companion Card 可见性 / 文案正确性
- degraded-state / delayed snapshot 表达检查
- settlement return UI smoke

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — B2-1 status 更新
请更新：

```text
docs/R4_OptionB2_B21_Status_v0.1.md
```

至少补：
1. 当前完成到哪个 phase（必须写 B2-1B）
2. 已实现范围
3. 未实现范围
4. 仍待处理问题
5. 是否触发 very small sync patch candidate
6. 当前是否建议进入 B2-1C

### Deliverable B — B2-1 test summary 更新
请更新：

```text
docs/R4_OptionB2_B21_Test_Summary_v0.1.md
```

至少包含：
1. Today 页相关 widget / regression / smoke 入口
2. changes-expression 触达的 surfaces
3. truth boundary 是否保持
4. 是否触碰现有 API / DB
5. 是否影响现有 B1 / B2-1A 回归

### Optional
若你确认纯前端做不稳，才允许新增 / 更新：

```text
docs/R4_OptionB2_B21_sync_candidates_v0.1.md
```

但不要默认制造 sync patch。

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB2_B21B_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **What Today changes-expression now includes**
3. **What truth boundary was kept**
4. **What backend surface did or did not change**
5. **What is still not done**
6. **What must be done next**
7. **What not to touch**
8. **Files / modules to read first**
9. **Current risks**
10. **Whether ready for B2-1C**

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B2-1B 完成：

1. Today changes-expression 已增强
2. 主 CTA 仍然是 Today 页最强动作
3. Companion Card 第二层 / changes chips / 轻目标感至少落地一部分
4. truth boundary 继续守住，无伪确认
5. 没有改后端契约
6. `docs/R4_OptionB2_B21_Status_v0.1.md` 已更新
7. `docs/R4_OptionB2_B21_Test_Summary_v0.1.md` 已更新
8. `docs/R4_cursor_round_summary_OptionB2_B21B_v0.1.md` 已生成
9. 最终能明确回答：是否 ready for **B2-1C**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B2（B2-1 first）里的 **B2-1B / Today changes-expression enhancement**
- 明确不是 B2-1C / B2-2 / B2-3

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 Today changes-expression 结果
请按这几项写清楚：
1. companion card second layer
2. changes chips / hint
3. weak goal cues
4. truth boundary
5. backend touched or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 若改了后端：`npm test` / `npm run test:e2e` 结果
- B2-1B 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB2_B21_Status_v0.1.md`
- `docs/R4_OptionB2_B21_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B21B_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B2-1B**
2. 是否 ready for **B2-1C**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你改 Meow Home / Customize，也不是让你扩 catalog。

这轮唯一要做好的事情是：

> **把 Today 页里的“今天有变化”表达做得更完整，但继续让学习主线站在最前面。**

不要扩 scope。  
不要偷拍板。  
不要把 B2-1C / B2-2 / B2-3 混进来。  
现在开始执行。
