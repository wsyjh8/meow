# Cursor_OptionB2_B22D_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是继续做内容层增强，也不是开 B2-3 sync patch，而是：

> **按这里给定的 Room 1 handoff、Room 2 preflight 结论、Room 5 的 Option B2 UI 方案，以及 Room 4 的执行边界，完成 Option B2 的 B2-2D：Test & closeout。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前状态不是 P1 / P2，也不是 Option A / Option A.1，也不是 Option B（B1），也不是 Option B2（B2-1 first）。  
这些都已经完成并 close。  
Room 1 已正式拍板当前方向为：

> **Option B2 下一步 = B2-2 only**

而你现在接的不是新实现 slice，而是：

> **B2-2D — Test & closeout**

---

## 1. 当前已完成到哪里

### B2-2A 已完成
- 5 个原始 items 已盘清
- 新增 5 个 items 已锁定
- DevStore / PG seed 已 5 → 10
- `/shop/catalog` contract judged **sufficient as-is**
- **patch not needed**

### B2-2B 已完成
- 前端已真实消费到 **10-item catalog**
- 新增 5 个 items 已真实可见
- display mapping / fallback 完整
- purchase / inventory / equipment 基本链路回归通过
- 三态（unowned / owned / equipped）未混淆
- **contract still sufficient**

### B2-2C 已完成
- Customize 做了 6 项内容层增强
- 新增 `customize_page_test.dart`，14 个 widget tests
- preview / compare / owned-not-equipped / goal cue 已增强
- 继续守住：
  - `preview / compare ≠ 当前已装备真相`
  - 无新 API / 字段 / 规则
  - 无 B2-3 creep

你现在接的不是：
- B2-3
- 新 catalog 扩容轮
- 新 UI 功能轮

而是：

> **只做 B2-2 的统一回归、truth-boundary 验证、状态收口与 closeout 交付。**

---

## 2. 这轮你到底要做什么

这轮只做：

1. 对 **B2-2A / B2-2B / B2-2C** 的全部改动做统一回归验证
2. 对照 Room 1 / Room 4 已定义的 **B2-2 close bar** 做正式 close judgment 输入
3. 确认：
   - catalog 5 → 10 已真实成立
   - Inventory / Equipment / Customize 内容层增强已真实可见
   - preview / compare / owned-not-equipped 没有越过 truth boundary
   - 未引入未批准的新 API / 新规则 / 新真相字段
   - B2-3 未被偷偷拉进同轮
4. 输出 B2-2 的正式状态文档 / 测试摘要 / handoff summary
5. 如确实需要，单列 very small sync patch candidate 文档
6. 最终明确回答：**是否建议 Room 1 close B2-2**

这轮**不做**：
- 不继续写新功能
- 不扩 catalog 超过 10
- 不引入 `change_highlights[]`
- 不引入 typed `companion_response`
- 不引入 `source_fact_tags`
- 不新增 endpoint / payload / rule / state machine
- 不开 B2-3
- 不补做 “B2-2E”

一句话：

> **B2-2D 不是再做功能，而是把 B2-2 变成一个可被 Room 1 直接判断 close / not-close 的完整交付包。**

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
- 当前 B2-2A / B2-2B / B2-2C 结论已经是：
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

### 3.4 B2-3 的硬边界
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

### 4.1 这轮是 closeout，不是继续开发
任何新增功能，只要不是为了：
- 修正 blocker
- 修正回归失败
- 修正 close bar 未达标

都不应在本轮继续进入。

### 4.2 Close judgment 必须围绕 B2-2 close bar
你必须明确对照以下 8 项逐项判断：

1. catalog `5 → 10` 是否已真实成立
2. Inventory / Equipment 内容层是否已增强
3. Customize 的 compare / preview / owned-not-equipped / 当前搭配重点是否已增强
4. preview / compare 是否继续不伪装成 equipped truth
5. 是否引入未批准的新 API / 新规则 / 新真相字段
6. current contract 是否仍 judged sufficient
7. B2-3 是否未被偷偷拉进同轮
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

`docs/R4_OptionB2_B22_sync_candidates_v0.1.md`

但不要为了“显得完整”而默认制造 sync patch。

---

## 5. 这轮的正确目标

根据 Room 1 handoff、Room 2 preflight 与 Room 4 phases，B2-2D 的目标是：

> **把 B2-2 从“catalog 扩了、内容层增强了”推进到“Room 1 可以直接做 close judgment”的状态。**

这轮必须交付的，不是“新功能”，而是：

1. 统一 regression 结果
2. 统一 truth-boundary 验证结果
3. 统一 status / test summary
4. 一个可直接给 Room 1 的 close recommendation

---

## 6. 这轮 in scope

### 6.1 统一回归验证（必须）
请对以下范围做统一回归：

#### B2-2A
- 10-item seed / metadata 是否仍一致
- semantic reuse 是否仍成立
- patch not needed 是否仍成立

#### B2-2B
- 10-item catalog 是否真实可见
- display mapping / name / emoji / price / level_required 是否稳定
- purchase / inventory / equipment 基本链路是否仍成立
- 三态是否仍清楚

#### B2-2C
- Inventory / Equipment 内容层增强
- Customize compare / preview / owned-not-equipped / current style focus / goal cue
- truth-boundary 文案是否继续不过界
- compare hints 在边界条件下是否不误导

### 6.2 统一 status 更新（必须）
请更新：

```text
docs/R4_OptionB2_B22_Status_v0.1.md
```

要求至少包含：
1. 当前完成到哪个 phase（必须写 B2-2D）
2. 已实现范围
3. 未实现范围
4. 当前 close bar 判断
5. 是否建议 Room 1 close B2-2
6. 若不建议 close，具体差什么

### 6.3 统一 test summary 更新（必须）
请更新：

```text
docs/R4_OptionB2_B22_Test_Summary_v0.1.md
```

要求至少包含：
1. Flutter / widget / regression / smoke 的完整入口
2. B2-2A / B2-2B / B2-2C 各自触达的 surfaces
3. truth boundary 是否保持
4. 是否触碰现有 API / DB
5. 是否影响 B2-1 / B1 / Option A / A.1 regression

### 6.4 handoff summary（必须）
请新增：

```text
docs/R4_cursor_round_summary_OptionB2_B22D_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **B2-2 close bar result**
3. **What was verified**
4. **What truth boundary was kept**
5. **What backend surface did or did not change**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**
11. **Whether Room 1 should close B2-2**

### 6.5 Optional sync candidates（仅在确有需要时）
若你确认纯前端做不稳，才允许新增 / 更新：

```text
docs/R4_OptionB2_B22_sync_candidates_v0.1.md
```

但不要默认制造 sync patch。

---

## 7. 这轮明确不做什么

### 7.1 不改后端主结构
- 不改 `/shop/catalog`
- 不改 `/shop/purchases`
- 不改 `/me/inventory`
- 不改 `/me/equipment`
- 不改 purchase / equip API 语义
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
- 不重改 Customize
- 不重改 Today
- 不重改 Meow Home
- 除非是为修正 blocker / regression failure / close bar 未达标

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 当前 runtime / handoff / preflight
- `R1_to_R4_OptionB2_B22_Handoff_v0.1.md`
- `R2_OptionB2_B22_Preflight_v0.1.md`
- `回p2_B2_B2.md`
- `回p2_B2_2B.md`
- `回p2_B2_2C.md`
- `Main_updated_2026-04-04_v11.md`
- `STATUS_updated_2026-04-04_v10.md`

### 8.2 当前 active DB / API / UI / rules
- `背单词喵喵app_DB设计草案_v0.1.4.md`
- `背单词喵喵app_API设计草案_v0.1.3.md`
- `UI_SPEC_OptionB2_v0.1.1.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `BR-OPP-001_v0.1.5.md`

### 8.3 当前测试入口
至少盘点：
- customize page widget tests
- shop / purchase / inventory / equipment e2e tests
- catalog model / mapper tests
- B2-1 / B2-2A / B2-2B / B2-2C 回归入口
- 若有 PG-path 特殊入口，也请标明

---

## 9. B2-2D 你必须明确回答的问题

### Q1. B2-2 close bar 的 8 项是否全部满足
请逐项写：
1. catalog `5 → 10` 是否已真实成立
2. Inventory / Equipment 内容层是否已增强
3. Customize 表达是否已增强
4. preview / compare 是否继续不伪装成 equipped truth
5. 是否引入未批准的新 API / 新规则 / 新真相字段
6. current contract 是否仍 sufficient
7. B2-3 是否未被偷偷拉进同轮
8. 测试入口与状态回传是否完整

### Q2. 当前真实触达了哪些 surfaces
请明确：
- catalog
- customize
- inventory
- equipment
- purchase flow
- owned / equipped / owned-not-equipped
- preview / compare / goal cue

### Q3. 你如何证明 truth boundary 继续守住
请明确：
- 哪些块是 Direct existing backend field
- 哪些块是 Pure front-end static content layer
- 哪些没有引入 sync patch
- 为什么不会伪确认

### Q4. 这轮是否需要 sync candidate
请明确：
- 是否需要 `R4_OptionB2_B22_sync_candidates_v0.1.md`
- 若需要，为什么
- 若不需要，也请明确说明“纯前端 + 现有 contract 已足够支撑 B2-2 close judgment”

### Q5. Room 1 现在是否应该 close B2-2
请明确：
- 建议 close / not close
- 若建议 close，给出一句最核心理由
- 若不建议 close，给出 blocker 列表

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 统一回归 B2-2A / B2-2B / B2-2C
2. 更新 status / test summary / handoff summary
3. 修复 very small regression 或 blocker
4. 若确有必要，单列 sync candidates
5. 做 very small docs sync（只记录 B2-2D 新事实）

### 不允许做的
1. 不开新功能
2. 不扩 catalog
3. 不新增业务字段
4. 不默认制造 sync patch
5. 不改业务规则
6. 不改 DB / API / persistence
7. 不把 B2-3 混进来

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

### 11.2 Node / backend
如果你只是为回归修正碰了后端显示消费 / model / mapper / e2e 入口，请补 / 跑：
```bash
npm test
npm run test:e2e
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.3 B2-2D 专项验证
至少完成这些验证：
1. B2-2A/B/C 的改动都仍然成立
2. preview / compare 不会被误读成 equipped truth
3. truth boundary 不越界
4. 没有越界进入 B2-3
5. 现有功能链路不破
6. close bar 可以被明确判断

### 11.4 建议额外覆盖
如果范围允许，建议补：
- 全量 widget / smoke summary
- 关键 truth-boundary 文案检查
- B2-1 regression 抽样检查
- purchase / inventory / equipment / compare / owned-not-equipped 的跨态检查

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — B2-2 status 更新
请更新：

```text
docs/R4_OptionB2_B22_Status_v0.1.md
```

### Deliverable B — B2-2 metadata lock 文件更新
请更新：

```text
docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md
```

### Deliverable C — B2-2 test summary 更新
请更新：

```text
docs/R4_OptionB2_B22_Test_Summary_v0.1.md
```

### Deliverable D — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB2_B22D_v0.1.md
```

### Optional
仅在确有需要时新增 / 更新：

```text
docs/R4_OptionB2_B22_sync_candidates_v0.1.md
```

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B2-2D 完成：

1. B2-2A / B2-2B / B2-2C 已统一回归验证
2. B2-2 close bar 已逐项判断
3. truth boundary 继续守住，无伪确认
4. 没有改后端契约
5. `docs/R4_OptionB2_B22_Status_v0.1.md` 已更新
6. `docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md` 已更新
7. `docs/R4_OptionB2_B22_Test_Summary_v0.1.md` 已更新
8. `docs/R4_cursor_round_summary_OptionB2_B22D_v0.1.md` 已生成
9. 最终能明确回答：是否建议 **Room 1 close B2-2**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B2 里的 **B2-2D / Test & closeout**
- 明确不是 B2-3

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 B2-2 closeout 结果
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
- `npm test` / `npm run test:e2e` 结果（若被影响）
- B2-2D 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB2_B22_Status_v0.1.md`
- `docs/R4_OptionB2_B22_Metadata_Lock_v0.1.md`
- `docs/R4_OptionB2_B22_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB2_B22D_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B2-2D**
2. 是否建议 **Room 1 close B2-2**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你开 B2-3，也不是让你继续堆新功能。

这轮唯一要做好的事情是：

> **把 B2-2 收成一个 Room 1 可以直接做 close judgment 的完整交付包。**

不要扩 scope。  
不要偷拍板。  
不要把 B2-3 混进来。  
现在开始执行。
