# Cursor_OptionB23_D_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是继续做 UI 功能增强，也不是开 B2-3 的其它候选项，而是：

> **按这里给定的 Room 1 handoff、Room 2 preflight judgment、Room 5 的 change-highlights-only UI absorption，以及 Room 4 的 phased plan，完成 Option B2-3 的 Phase B23-D：Test & closeout。**

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
- B23-C（Meow Home + Settlement consumption）
- `companion_response` typing
- `source_fact_tags`
- 新 endpoint
- 新状态机
- P3

你这轮只做：

> **B23-D — Test & closeout**

---

## 1. 当前已完成到哪里

### B23-A 已完成
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
- Today 页已最小新增 `getSecondarySummary()` 并行加载
- `change_highlights[]` 已接入 **Today Companion Card 第二层**
- 默认最多显示 **2 条**
- 空 / 缺失 / 加载失败时退化正常
- hinted / confirmed 区分清楚
- 主 CTA 未被压

### B23-C 已完成
- Meow Home 新增 **今日重点变化区**
- Settlement 新增 **轻摘要 bridge**
- Meow Home 默认最多 **3 条**
- Settlement 默认最多 **2 条**
- 无 highlights 时退化正常
- hinted / confirmed 边界仍守住
- 未触碰后端

### 当前总测试基线
- `flutter test`：67/67 pass
- `flutter analyze`：0 errors
- `npm test`：16/16 pass
- `npm run test:e2e`：72/72 pass
- **Total：155/155 pass**

你现在接的不是：
- 新功能
- 新 contract
- 新 sync candidate

而是：

> **只做 B23-A / B23-B / B23-C 的统一回归、truth-boundary 验证、状态收口与 closeout 交付。**

---

## 2. 这轮你到底要做什么

这轮只做：

1. 对 **B23-A / B23-B / B23-C** 的全部改动做统一回归验证
2. 对照 Room 1 / Room 4 已定义的 **B23 close bar** 做正式 close judgment 输入
3. 确认：
   - `change_highlights[]` contract 仍稳定
   - Today / Meow Home / Settlement 的消费都已真实成立
   - preview / wording / hinted / confirmed 没有越过 truth boundary
   - 未引入未批准的新 API / 新规则 / 新真相字段
   - `companion_response` typing / `source_fact_tags` 未被偷偷拉进同轮
4. 输出 B23 的正式状态文档 / 测试摘要 / handoff summary
5. 如确实需要，单列 very small issue note
6. 最终明确回答：**是否建议 Room 1 close B23**

这轮**不做**：
- 不继续写新功能
- 不扩 `change_highlights[]` shape
- 不引入 `companion_response` typing
- 不引入 `source_fact_tags`
- 不新增 endpoint / payload / rule / state machine
- 不开新 phase
- 不补做 “B23-E”

一句话：

> **B23-D 不是再做功能，而是把 B23 变成一个可被 Room 1 直接判断 close / not-close 的完整交付包。**

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
- B23-A — Read-only extension landing
- B23-B — Today consumption
- B23-C — Meow Home + Settlement consumption
- **B23-D — Test & closeout**

### 3.3 Room 2 已给出最小 technical proposal
Room 2 已明确：
- 这轮只能是 **very small patch**
- `change_highlights[]` 只是 **read-only response extension**
- 不能重写主 API / DB 结构
- 不能开新状态机
- 不能扩大成新系统

### 3.4 Room 5 已给出的硬边界
你必须继续保持：
- `change_highlights[]` 只是 **read-only summary / hint layer**
- 不能替代：
  - ownership
  - equipment
  - reward settlement / reward ledger
  - check_in / learning_day / streak
  - level / balance / purchase truth
- UI 不得只凭 `label` 覆盖现有真相层

---

## 4. 你必须服从的强断言

### 4.1 这轮是 closeout，不是继续开发
任何新增功能，只要不是为了：
- 修正 blocker
- 修正回归失败
- 修正 close bar 未达标

都不应在本轮继续进入。

### 4.2 Close judgment 必须围绕 B23 close bar
你必须明确对照以下 8 项逐项判断：

1. `change_highlights[]` 是否已稳定作为 very small、read-only extension 落地
2. Today consumption 是否已成立
3. Meow Home + Settlement consumption 是否已成立
4. hinted / confirmed 是否继续不越 truth boundary
5. 是否引入未批准的新 API / 新规则 / 新真相字段
6. current contract 是否仍稳定兼容
7. `companion_response` typing / `source_fact_tags` 是否未被偷偷拉进同轮
8. 测试入口与状态回传是否完整

### 4.3 若 close bar 有未达标项，必须明确写出
若你发现某一项还不稳：
- 不要模糊写“基本完成”
- 要明确写：
  - 哪一项未达标
  - 差在哪里
  - 是 blocker 还是 non-blocking
  - 是否需要额外 issue note

### 4.4 可单列 issue note，但不要默认制造
只有在你确认：
- Settlement / Today / Meow Home 某处仍有实现歧义
- 或 close judgment 必须依赖 Room 1 / Room 5 / Room 2 再收一口径

时，才允许新增：

`docs/R4_OptionB23_change_highlights_issue_note_v0.1.md`

但不要为了“显得完整”而默认制造 issue。

---

## 5. 这轮的正确目标

根据 Room 1 handoff、Room 2 preflight 与 Room 4 phases，B23-D 的目标是：

> **把 B23 从“字段已落、三处已消费”推进到“Room 1 可以直接做 close judgment”的状态。**

这轮必须交付的，不是“新功能”，而是：

1. 统一 regression 结果
2. 统一 truth-boundary 验证结果
3. 统一 status / test summary
4. 一个可直接给 Room 1 的 close recommendation

---

## 6. 这轮 in scope

### 6.1 统一回归验证（必须）
请对以下范围做统一回归：

#### B23-A
- `change_highlights[]` shape 是否仍一致
- semantic boundary 是否仍成立
- fallback / compatibility 是否仍成立

#### B23-B
- Today Companion Card 第二层消费是否仍成立
- 默认最多 2 条是否仍成立
- fallback / 主 CTA 安全是否仍成立

#### B23-C
- Meow Home 今日重点变化区
- Settlement 轻摘要 bridge
- truth-boundary 文案是否继续不过界
- max 条数 / 隐藏规则 / 截断是否不误导

### 6.2 统一 status 更新（必须）
请更新：

```text
docs/R4_OptionB23_change_highlights_Status_v0.1.md
```

要求至少包含：
1. 当前完成到哪个 phase（必须写 B23-D）
2. 已实现范围
3. 未实现范围
4. 当前 close bar 判断
5. 是否建议 Room 1 close B23
6. 若不建议 close，具体差什么

### 6.3 统一 test summary 更新（必须）
请更新：

```text
docs/R4_OptionB23_change_highlights_Test_Summary_v0.1.md
```

要求至少包含：
1. Flutter / widget / regression / smoke 的完整入口
2. B23-A / B23-B / B23-C 各自触达的 surfaces
3. truth boundary 是否保持
4. 是否触碰现有 API / DB
5. 是否影响 B2-2 / B1 / Option A / A.1 regression

### 6.4 handoff summary（必须）
请新增：

```text
docs/R4_cursor_round_summary_OptionB23_D_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **B23 close bar result**
3. **What was verified**
4. **What truth boundary was kept**
5. **What backend surface did or did not change**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**
11. **Whether Room 1 should close B23**

### 6.5 Optional issue note（仅在确有需要时）
若你确认纯前端表达仍有歧义，才允许新增 / 更新：

```text
docs/R4_OptionB23_change_highlights_issue_note_v0.1.md
```

但不要默认制造 issue。

---

## 7. 这轮明确不做什么

### 7.1 不改后端主结构
- 不改 `/me/secondary-summary`
- 不新增 endpoint
- 不改 purchase / equip / reward / streak API 语义
- 不改 persistence

### 7.2 不扩字段范围
- 不新增 item
- 不新增 `change_highlights[]` 子字段
- 不扩状态集合
- 不扩 kind 集合
- 不扩价格体系 / 规则体系

### 7.3 不做 B2-3 其它候选
- 不新增 `companion_response` typing
- 不新增 `source_fact_tags`

### 7.4 不继续做新页面增强
- 不重改 Today
- 不重改 Meow Home
- 不重改 Settlement
- 除非是为修正 blocker / regression failure / close bar 未达标

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 当前 handoff / preflight / absorption /回传
- `R1_to_R4_OptionB23_change_highlights_only_Implementation_Handoff_v0.1.md`
- `R2_OptionB2_B23_Preflight_v0.1.2.md`
- `UI_SPEC_OptionB23_change_highlights_v0.1.1.md`
- `b3_phases.md`
- `回B23-A.md`
- `回B23-B.md`
- `回B23-C.md`

### 8.2 当前 active runtime basis
- `Main_updated_2026-04-04_v11.md`
- `STATUS_updated_2026-04-04_v10.md`
- `BR-OPP-001_v0.1.5.md`
- `背单词喵喵app_DB设计草案_v0.1.4.md`
- `背单词喵喵app_API设计草案_v0.1.3.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `UI_SPEC_OptionB2_v0.1.1.md`

### 8.3 当前测试入口
至少盘点：
- Today widget tests
- Meow Home widget tests
- Settlement / today page related tests
- B23-A / B23-B / B23-C regression 入口
- 若有 backend / e2e 相关守护入口，也请标明

---

## 9. B23-D 你必须明确回答的问题

### Q1. B23 close bar 的 8 项是否全部满足
请逐项写：
1. `change_highlights[]` 是否已稳定作为 read-only extension 落地
2. Today consumption 是否已成立
3. Meow Home + Settlement consumption 是否已成立
4. hinted / confirmed 是否继续不伪装成真相
5. 是否引入未批准的新 API / 新规则 / 新真相字段
6. current contract 是否仍稳定兼容
7. 其它候选项是否未被偷偷拉进同轮
8. 测试入口与状态回传是否完整

### Q2. 当前真实触达了哪些 surfaces
请明确：
- Today Companion Card Layer 2
- Meow Home 今日重点变化区
- Settlement bridge
- empty / fallback / max-item handling
- hinted / confirmed rendering

### Q3. 你如何证明 truth boundary 继续守住
请明确：
- 哪些块是 Direct existing backend field
- 哪些块是 Pure front-end static content layer
- 哪些没有引入 sync patch
- 为什么不会伪确认

### Q4. 这轮是否需要 issue note
请明确：
- 是否需要 `R4_OptionB23_change_highlights_issue_note_v0.1.md`
- 若需要，为什么
- 若不需要，也请明确说明“当前 contract + 当前 UI 消费已足够支撑 B23 close judgment”

### Q5. Room 1 现在是否应该 close B23
请明确：
- 建议 close / not close
- 若建议 close，给出一句最核心理由
- 若不建议 close，给出 blocker 列表

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 统一回归 B23-A / B23-B / B23-C
2. 更新 status / test summary / handoff summary
3. 修复 very small regression 或 blocker
4. 若确有必要，单列 issue note
5. 做 very small docs sync（只记录 B23-D 新事实）

### 不允许做的
1. 不开新功能
2. 不扩字段
3. 不新增业务字段
4. 不默认制造 issue
5. 不改业务规则
6. 不改 DB / API / persistence
7. 不把其它候选项混进来

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
如果你只是为回归修正碰了 parsing / e2e 入口，请补 / 跑：
```bash
npm test
npm run test:e2e
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.3 B23-D 专项验证
至少完成这些验证：
1. B23-A / B23-B / B23-C 的改动都仍然成立
2. hinted / confirmed 不会被误读成现有真相层
3. truth boundary 不越界
4. 其它候选项没有被带进来
5. 现有功能链路不破
6. close bar 可以被明确判断

### 11.4 建议额外覆盖
如果范围允许，建议补：
- 全量 widget / smoke summary
- 关键 wording boundary 检查
- empty / missing / max-item / delayed handling 抽样检查
- B2-2 / Option B regression 抽样检查

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — 状态文件更新
请更新：

```text
docs/R4_OptionB23_change_highlights_Status_v0.1.md
```

### Deliverable B — 测试摘要更新
请更新：

```text
docs/R4_OptionB23_change_highlights_Test_Summary_v0.1.md
```

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB23_D_v0.1.md
```

### Optional
仅在确有需要时新增 / 更新：

```text
docs/R4_OptionB23_change_highlights_issue_note_v0.1.md
```

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B23-D 完成：

1. B23-A / B23-B / B23-C 已统一回归验证
2. B23 close bar 已逐项判断
3. truth boundary 继续守住，无伪确认
4. 没有改后端契约
5. `docs/R4_OptionB23_change_highlights_Status_v0.1.md` 已更新
6. `docs/R4_OptionB23_change_highlights_Test_Summary_v0.1.md` 已更新
7. `docs/R4_cursor_round_summary_OptionB23_D_v0.1.md` 已生成
8. 最终能明确回答：是否建议 **Room 1 close B23**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 **Option B2-3 / B23-D / Test & closeout**
- 明确不是新功能轮

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 B23 closeout 结果
请按这几项写清楚：
1. close bar result
2. touched surfaces
3. truth boundary
4. backend touched or not
5. issue note needed or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- `npm test` / `npm run test:e2e` 结果（若被影响）
- B23-D 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB23_change_highlights_Status_v0.1.md`
- `docs/R4_OptionB23_change_highlights_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB23_D_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B23-D**
2. 是否建议 **Room 1 close B23**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你继续堆功能，也不是让你开其它候选项。

这轮唯一要做好的事情是：

> **把 B23 收成一个 Room 1 可以直接做 close judgment 的完整交付包。**

不要扩 scope。  
不要偷拍板。  
不要把其它候选项混进来。  
现在开始执行。
