# Cursor_OptionB2_B21D_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是继续做页面增强，也不是扩 catalog，而是：

> **按这里给定的 Room 1 handoff、Room 5 的 Option B2 UI 方案、以及 Room 4 的 execution planning，完成 Option B2（B2-1 first）的 Phase B2-1D：Test & closeout。**

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

而你这轮接的也不是新的实现 slice，而是：

> **Phase B2-1D — Test & closeout**

---

## 1. 当前已完成到哪里

### B2-1A 已完成
- companion / response 文案池已完成一轮扩池
- 用户可感知“今天回来不完全一样”
- truth boundary 继续守住
- 无 API / DB / persistence 改动

### B2-1B 已完成
- Today Companion Card 已升级为双层结构
- changes chips + goal cue 已落地
- settlement follow-up 承接已更自然
- 主 CTA 层级保持最强
- 无 API / DB / persistence 改动

### B2-1C 已完成
- Meow Home 新增“今天的小成就 / today highlights”
- Customize 新增 owned-not-equipped hint + style hint / compare 表达
- preview / compare 不会被误读成 equipped truth
- 无 API / DB / persistence 改动

你现在接的不是：
- B2-2
- B2-3
- 新页面增强轮

而是：

> **只做 B2-1 的统一验证、回归、状态收口与 closeout 交付。**

---

## 2. 这轮你到底要做什么

这轮只做：

1. 对 **B2-1A / B2-1B / B2-1C** 的全部改动做统一回归验证
2. 对照 Room 1 / Room 4 已定义的 **B2-1 close bar** 做正式 close judgment 输入
3. 确认：
   - companion copy 扩池已用户可见
   - Today 变化承接更完整但不压主 CTA
   - Meow Home 变化表达更细但不伪造真相
   - Customize 的“买了之后会变什么 / 已买未装 / 当前搭配重点”表达增强
   - 未引入未批准的新 API / 新规则 / 新真相字段
   - truth boundary 保持
   - B2-2 / B2-3 未被偷偷拉进同轮
4. 输出 B2-1 的正式状态文档 / 测试摘要 / handoff summary
5. 如确实需要，单列 very small sync patch candidate 文档
6. 最终明确回答：**是否建议 Room 1 close B2-1**

这轮**不做**：
- 不继续写页面功能
- 不扩 catalog 5 → 10
- 不引入 `change_highlights[]`
- 不引入 typed `companion_response`
- 不引入 `source_fact_tags`
- 不新增 endpoint / payload / rule / state machine
- 不开 B2-2 / B2-3
- 不补做“Phase B2-1E”

一句话：

> **B2-1D 不是再做功能，而是把 B2-1 变成一个可被 Room 1 直接判断 close / not-close 的完整交付包。**

---

## 3. 你必须接受的上游结论

### 3.1 Room 1 已正式拍板：当前做的是 `Option B2 (B2-1 first)`
Room 1 已明确：
- post-B1 next direction = **Option B2 — Content Expansion**
- 但当前正式下发给 Room 4 的，不是完整 B2，而是：

> **Option B2（B2-1 first）**

### 3.2 Room 1 已明确给出 B2-1 的推荐执行顺序
你当前只做第四刀：

- B2-1A — Copy pool expansion ✅ 已完成
- B2-1B — Today changes-expression enhancement ✅ 已完成
- B2-1C — Meow Home / Customize changes-expression enhancement ✅ 已完成
- **B2-1D — Test & closeout**

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

B2-1D 的责任不是再创造新表达，而是证明前面三轮都**没有**越过这些边界。

---

## 4. 你必须服从的强断言

### 4.1 这轮是 closeout，不是继续开发
任何新增功能，只要不是为了：
- 修正 blocker
- 修正回归失败
- 修正 close bar 未达标

都不应在本轮继续进入。

### 4.2 Close judgment 必须围绕 B2-1 close bar
你必须明确对照以下 8 项逐项判断：

1. companion copy 扩池是否已用户可见
2. Today 是否更完整但不压主 CTA
3. Meow Home 是否更细但不伪造真相
4. Customize 表达是否增强
5. 是否引入未批准的新 API / 新规则 / 新真相字段
6. truth boundary 是否完整
7. B2-2 / B2-3 是否未被偷偷拉进同轮
8. 测试入口与状态回传是否完整

### 4.3 若 close bar 有未达标项，必须明确写出
若你发现某一项还不稳：
- 不要模糊写“基本完成”
- 要明确写：
  - 哪一项未达标
  - 差在哪里
  - 是 blocker 还是 non-blocking
  - 是否需要额外 very small patch

### 4.4 可单列 sync candidate，但不要默认制造
只有在你确认：
- 纯前端表达仍然不稳
- 或 close judgment 必须依赖一个极小 sync patch
时，才允许新增 / 更新：

`docs/R4_OptionB2_B21_sync_candidates_v0.1.md`

但不要为了“显得完整”而默认制造 sync patch。

---

## 5. 这轮的正确目标

根据 Room 1 handoff 与 Room 4 phases，B2-1D 的目标是：

> **把 B2-1 从“内容和表达已经做了”推进到“Room 1 可以直接做 close judgment”的状态。**

这轮必须交付的，不是“新功能”，而是：

1. 统一 regression 结果
2. 统一 truth-boundary 验证结果
3. 统一 status / test summary
4. 一个可直接给 Room 1 的 close recommendation

---

## 6. 这轮 in scope

### 6.1 回归验证（必须）
请对以下范围做统一回归：

#### B2-1A
- expanded copy pools 是否可见
- feed / interaction / equip / purchase / bubble / Today 承接 copy 是否稳定
- truth boundary 文案是否不过界

#### B2-1B
- Today Companion Card 第二层
- changes chips / weak goal cues
- settlement follow-up
- 主 CTA 是否仍为最强

#### B2-1C
- Meow Home today highlights
- Customize owned-not-equipped
- Customize preview / compare / style hint
- preview / compare 是否不会被误读成 equipped truth

### 6.2 统一 status 更新（必须）
请更新：

```text
docs/R4_OptionB2_B21_Status_v0.1.md
```

要求至少包含：
1. 当前完成到哪个 phase（必须写 B2-1D）
2. 已实现范围
3. 未实现范围
4. 当前 close bar 判断
5. 是否建议 Room 1 close B2-1
6. 若不建议 close，具体差什么

### 6.3 统一 test summary 更新（必须）
请更新：

```text
docs/R4_OptionB2_B21_Test_Summary_v0.1.md
```

要求至少包含：
1. Flutter / widget / regression / smoke 的完整入口
2. B2-1A / B2-1B / B2-1C 各自触达的 surfaces
3. truth boundary 是否保持
4. 是否触碰现有 API / DB
5. 是否影响 B1 / Option A / A.1 / P2 regression

### 6.4 handoff summary（必须）
请新增：

```text
docs/R4_cursor_round_summary_OptionB2_B21D_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **B2-1 close bar result**
3. **What was verified**
4. **What truth boundary was kept**
5. **What backend surface did or did not change**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**
11. **Whether Room 1 should close B2-1**

### 6.5 Optional sync candidates（仅在确有需要时）
若你确认纯前端做不稳，才允许新增 / 更新：

```text
docs/R4_OptionB2_B21_sync_candidates_v0.1.md
```

但不要默认制造 sync patch。

---

## 7. 这轮明确不做什么

### 7.1 不改后端
- 不改 `/me/today`
- 不改 `/me/secondary-summary`
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

### 7.4 不继续做新页面增强
- 不重改 Today
- 不重改 Meow Home
- 不重改 Customize
- 除非是为修正 blocker / regression failure / close bar 未达标

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 B1 / B2-1A / B2-1B / B2-1C 当前状态
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase5_v0.1.md`
- `docs/R4_OptionB2_B21_Status_v0.1.md`
- `docs/R4_OptionB2_B21_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B21A_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B21B_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B21C_v0.1.md`

### 8.2 B2 输入
- `R1_to_R4_OptionB2_B21_Handoff_v0.1.md`
- `UI_SPEC_OptionB2_v0.1.1.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `UI_SPEC_v0.1.4.md`
- `b2_b1_phases.md`

### 8.3 当前测试入口
至少盘点：
- `test/meow_home_page_test.dart`
- `test/today_page_test.dart`
- `test/customize_page_test.dart`（若有）
- copy helper tests / state tests
- 页面 smoke tests
- B1 / B2-1A / B2-1B / B2-1C 回归入口

---

## 9. B2-1D 你必须明确回答的问题

### Q1. B2-1 close bar 的 8 项是否全部满足
请逐项写：
1. companion copy 扩池是否已用户可见
2. Today 是否更完整但不压主 CTA
3. Meow Home 是否更细但不伪造真相
4. Customize 表达是否增强
5. 是否引入未批准的新 API / 新规则 / 新真相字段
6. truth boundary 是否完整
7. B2-2 / B2-3 是否未被偷偷拉进同轮
8. 测试入口与状态回传是否完整

### Q2. 当前真实触达了哪些 surfaces
请明确：
- Meow Home
- Today
- Customize
- interaction
- feed
- equip / purchase
- status bubble / streak / growth

### Q3. 你如何证明 truth boundary 继续守住
请明确：
- 哪些块是 Direct existing backend field
- 哪些块是 Pure front-end static content layer
- 哪些没有引入 sync patch
- 为什么不会伪确认

### Q4. 这轮是否需要 sync candidate
请明确：
- 是否需要 `R4_OptionB2_B21_sync_candidates_v0.1.md`
- 若需要，为什么
- 若不需要，也请明确说明“纯前端 + 现有 contract 已足够支撑 B2-1 close judgment”

### Q5. Room 1 现在是否应该 close B2-1
请明确：
- 建议 close / not close
- 若建议 close，给出一句最核心理由
- 若不建议 close，给出 blocker 列表

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 统一回归 B2-1A / B2-1B / B2-1C
2. 更新 status / test summary / handoff summary
3. 修复 very small regression 或 blocker
4. 若确有必要，单列 sync candidates
5. 做 very small docs sync（只记录 B2-1D 新事实）

### 不允许做的
1. 不开新功能
2. 不扩 catalog
3. 不新增业务字段
4. 不默认制造 sync patch
5. 不改业务规则
6. 不改 DB / API / persistence
7. 不把 B2-2 / B2-3 混进来

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

### 11.2 若你触碰极小后端 content helper
若你只是为回归修正碰了后端文案源，请补 / 跑：
```bash
npm test
npm run test:e2e
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.3 B2-1D 专项验证
至少完成这些验证：
1. B2-1A/B/C 的改动都仍然成立
2. 主 CTA 仍然是 Today 页最强动作
3. preview / compare 不会被误读成 equipped truth
4. truth boundary 不越界
5. 没有越界进入 B2-2 / B2-3
6. 现有功能链路不破
7. close bar 可以被明确判断

### 11.4 建议额外覆盖
如果范围允许，建议补：
- 全量 widget / smoke summary
- 关键 truth-boundary 文案检查
- B1 regression 抽样检查
- 交互 / 装备 / 购买 / changes-expression 的跨页检查

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — B2-1 status 更新
请更新：

```text
docs/R4_OptionB2_B21_Status_v0.1.md
```

### Deliverable B — B2-1 test summary 更新
请更新：

```text
docs/R4_OptionB2_B21_Test_Summary_v0.1.md
```

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB2_B21D_v0.1.md
```

### Optional
仅在确有需要时新增 / 更新：

```text
docs/R4_OptionB2_B21_sync_candidates_v0.1.md
```

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B2-1D 完成：

1. B2-1A / B2-1B / B2-1C 已统一回归验证
2. B2-1 close bar 已逐项判断
3. truth boundary 继续守住，无伪确认
4. 没有改后端契约
5. `docs/R4_OptionB2_B21_Status_v0.1.md` 已更新
6. `docs/R4_OptionB2_B21_Test_Summary_v0.1.md` 已更新
7. `docs/R4_cursor_round_summary_OptionB2_B21D_v0.1.md` 已生成
8. 最终能明确回答：是否建议 **Room 1 close B2-1**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B2（B2-1 first）里的 **B2-1D / Test & closeout**
- 明确不是 B2-2 / B2-3

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 B2-1 closeout 结果
请按这几项写清楚：
1. close bar result
2. touched surfaces
3. truth boundary
4. backend touched or not
5. sync candidate needed or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 若改了后端：`npm test` / `npm run test:e2e` 结果
- B2-1D 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB2_B21_Status_v0.1.md`
- `docs/R4_OptionB2_B21_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B21D_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B2-1D**
2. 是否建议 **Room 1 close B2-1**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你扩 catalog，也不是让你开 sync patch。

这轮唯一要做好的事情是：

> **把 B2-1 收成一个 Room 1 可以直接做 close judgment 的完整交付包。**

不要扩 scope。  
不要偷拍板。  
不要把 B2-2 / B2-3 混进来。  
现在开始执行。
