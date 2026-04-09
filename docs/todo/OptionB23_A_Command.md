# Cursor_OptionB23_A_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接做 Today / Meow Home / 结算承接区 UI 消费，也不是开 B2-3 的其它候选项，而是：

> **按这里给定的 Room 1 handoff、Room 2 preflight judgment、Room 5 的 change-highlights-only UI absorption，以及 Room 4 的 phased plan，完成 Option B2-3 的 Phase B23-A：Read-only extension landing。**

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
- B23-B（Today consumption）
- B23-C（Meow Home + Settlement consumption）
- B23-D（Test & closeout）
- `companion_response` typing
- `source_fact_tags`
- 新 endpoint
- 新状态机
- P3

你这轮只做：

> **B23-A — 把 `change_highlights[]` 以 very small、read-only extension 的方式落到当前 response contract 上。**

---

## 1. 当前已完成到哪里

### 已完成并已 close
- P1：主机制闭环
- P2：副机制 MVP 闭环
- Option A：PG 真相层
- Option A.1：hardening
- Option B（B1）：visual polish first
- Option B2-1：copy / Today / Meow Home / Customize 内容增强
- Option B2-2：catalog 5→10 + inventory / equipment / customize 内容增强并 close

### 当前正式进入的新方向
- **Option B2-3**
- 但不是三项候选一起进
- 只进入：**`change_highlights[] only`**

### 已有上游结论
#### Room 1
- post-B2-2 next direction = **Option B2-3**
- 本轮只进入 `change_highlights[]`
- 推荐执行顺序是：
  - B23-A — Read-only extension landing
  - B23-B — Today consumption
  - B23-C — Meow Home + Settlement consumption
  - B23-D — Test & closeout

#### Room 2
- 结论：**Go with very small patch**
- `change_highlights[]` 是 **preferred candidate**
- 这轮只能是：
  - read-only extension
  - 不改主 endpoint 语义
  - 不改主结构
  - 不新增新状态机
  - 不新增 interaction backend action
  - 不扩大成新系统

#### Room 5
- 已完成 `change_highlights[] only` absorption proposal
- 页面吸收位已定义清楚，但这轮**先不接 UI**
- Room 5 已明确：
  - `change_highlights[]` 只是 **read-only summary / hint layer**
  - 不能替代 ownership / equipment / reward / streak 等现有真相层

---

## 2. 这轮你到底要做什么

这轮只做：

1. 在**不改主 API / DB 结构、不新开 endpoint、不改业务规则**的前提下，把 `change_highlights[]` 落为当前某个**现有聚合响应**上的 **very small read-only extension**
2. 保证：
   - 未返回 `change_highlights[]` 时前端仍稳定
   - 返回 `change_highlights[]` 时不破坏现有页面
3. 让后续 B23-B / B23-C 可以直接消费这个字段，而不需要前端再从多来源手拼
4. 继续守住：
   - `change_highlights[]` 只是 summary / hint layer
   - 不是新的业务真相层
5. 更新 / 补齐与 response extension landing 相关的 tests
6. 输出本轮 handoff 文档

这轮**不做**：
- 不接 Today UI
- 不接 Meow Home UI
- 不接 Settlement UI
- 不做 `companion_response` typing
- 不做 `source_fact_tags`
- 不新增 endpoint
- 不新增 interaction backend action
- 不新增状态机
- 不做 timeline / activity feed / history page
- 不把 B2-3 扩成 P3

一句话：

> **B23-A 是 contract landing，不是 UI 落地轮。**

---

## 3. 你必须接受的上游结论

### 3.1 Room 1 已正式拍板：`change_highlights[] only`
本轮不是三项候选一起进。  
Room 1 已正式 pin：

- enter: `change_highlights[]`
- not in this round:
  - `companion_response` typing
  - `source_fact_tags`

### 3.2 Room 2 已给出最小 technical proposal
Room 2 已明确：

#### 类型
- **read-only response extension**

#### 推荐挂载位置
默认只允许挂到**现有聚合响应**上，不新增 endpoint。  
推荐优先挂到：
- `GET /me/secondary-summary`
- 或主机制结算承接时已存在的聚合返回对象

#### Room 2 给出的最小形态
```json
{
  "change_highlights": [
    {
      "kind": "purchase|equip|growth|streak|post_learning",
      "status": "confirmed|hinted",
      "label": "string",
      "related_item_code": "nullable string"
    }
  ]
}
```

### 3.3 Room 5 已给出的 UI 边界
虽然这轮不接 UI，但你必须按 UI absorption 的边界来落 contract：

- Today：后续默认最多 2 条
- Meow Home：后续默认最多 3 条
- Settlement：后续默认 1 条，最多 2 条
- 必须支持：
  - 字段整体缺失时退化
  - 空数组时退化
  - delayed / maintenance / read_only / temporarily_unavailable 时退化

### 3.4 Room 4 当前 phase 切法已固定
Room 4 已把本轮固定成 4 phases：
- B23-A — Read-only extension landing
- B23-B — Today consumption
- B23-C — Meow Home + Settlement consumption
- B23-D — Test & closeout

所以这轮**只能做 A**，别提前做 B / C / D。

---

## 4. 你必须服从的强断言

### 4.1 这轮只落 extension，不落 UI
你可以：
- 落 `change_highlights[]` 字段
- 写 mapper / DTO / serializer / response extension
- 写 compatibility tests
- 写最小生成逻辑（如果当前服务端已能根据现有真相拼出摘要）

但你不能：
- 直接改 Today / Meow Home / Settlement 组件树
- 直接做 B23-B / B23-C

### 4.2 `change_highlights[]` 不是新真相层
它只能是：

> **read-only summary / hint layer**

它不能替代：
- ownership
- equipment
- reward settlement / reward ledger
- check_in / learning_day / streak
- level / balance / purchase truth

### 4.3 `label` 不是新事实字段
Room 2 已明确写过：

> `label` 只是承接展示文案，不是新的真相字段；UI 不得只凭 `label` 覆盖 ownership / equipment / reward / streak 等现有真相层。

你落地时必须继续保持这个语义，不得把 `label` 当成结构化真相输出。

### 4.4 hinted ≠ confirmed
你落地字段时必须继续明确支持：
- `status = hinted`
- `status = confirmed`

但注意：
- `hinted` 不能被下游自然误解成“已获得 / 已到账 / 已生效”
- `confirmed` 也不能替代现有真相层详情页 / 真相字段

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

根据 Room 1 handoff、Room 2 preflight、Room 5 absorption 与 Room 4 phases，B23-A 的目标是：

> **先把 `change_highlights[]` 作为一个 very small、read-only、兼容旧前端的字段稳定落下，为后续 B23-B / B23-C 提供稳定 contract。**

这轮必须交付的，不是“变化感更强的页面”，而是：

1. `change_highlights[]` 已落到现有聚合响应
2. 返回时不破坏当前页面
3. 不返回时前端仍完全兼容
4. 不越权到新系统 / 新真相层

---

## 6. 这轮 in scope

### 6.1 先确认当前最合适的挂载位置（必须）
请在 repo 中先确认：

- 当前最适合挂载 `change_highlights[]` 的**现有聚合响应**到底是哪一个
- 默认优先看：
  - `GET /me/secondary-summary`
  - 主机制结算承接时已存在的聚合返回对象

请选择**一个最合理的 primary landing point**。  
如果两个都合理，也请只先落一个主入口，另一个只记录为 follow-up consumption dependency，不要双处同时铺开。

### 6.2 按最小形态落字段（必须）
请按以下最小形态落地：

```json
{
  "change_highlights": [
    {
      "kind": "purchase|equip|growth|streak|post_learning",
      "status": "confirmed|hinted",
      "label": "string",
      "related_item_code": "nullable string"
    }
  ]
}
```

要求：
- `change_highlights` 可缺失
- 可为空数组
- item 不可再默认扩字段
- 不做时间戳
- 不做长正文
- 不做可展开 body
- 不做历史追溯
- 不做二级按钮

### 6.3 生成逻辑必须只基于现有真相层（必须）
如果你需要在后端生成 `change_highlights[]`，必须只基于当前**已有真相层**和**已有聚合信息**来做极小拼装。

允许使用的来源应该是当前已有的：
- purchase truth
- equipment truth
- growth / level truth
- streak / post-learning 已有聚合 truth
- 现有 settlement / summary 对象中已存在的可确认信息

不允许：
- 新建变化判定状态机
- 新建变化历史表
- 新建复杂事件编排
- 新建复杂排序系统

### 6.4 兼容性必须优先（必须）
你必须保证：

#### 情况 A：字段未返回
- 前端仍稳定工作
- 不得因为字段不存在而崩

#### 情况 B：字段返回空数组
- 前端仍稳定工作
- 不得误解为“今天没有变化”这个业务事实

#### 情况 C：字段返回一组 items
- 当前页面仍稳定
- 即使还没接 UI，也不得破坏当前 response parsing

### 6.5 若有歧义，只能写 issue note（允许）
如果你在实现时发现：
- Room 2 proposal 仍有实现歧义
- 或 Room 5 absorption 仍存在无法落地点

你可以新增：
`R4_OptionB23_change_highlights_issue_note_v0.1.md`

但不要默认制造新 patch。

---

## 7. 这轮明确不做什么

### 7.1 不做 B23-B
以下内容留给下一轮：
- Today Companion Card 第二层接入
- 最多 2 条 Today highlights
- 无 highlights 时回退文案
- 不压主 CTA 的实际 UI 验证

### 7.2 不做 B23-C
以下内容留给下一轮：
- Meow Home 今日重点变化区
- Settlement 承接区 1–2 条轻摘要桥接

### 7.3 不做 B23-D
以下内容留给最后一轮：
- 全量 regression closeout
- close bar judgment
- final recommendation to Room 1

### 7.4 不做 B2-3 其它候选
- 不做 `companion_response` typing
- 不做 `source_fact_tags`

### 7.5 不改主结构
- 不改 DB 主结构
- 不改 API 主结构
- 不改 purchase / equip / reward / streak 主语义
- 不改 persistence 主结构

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 当前 handoff / preflight / UI absorption
- `R1_to_R4_OptionB23_change_highlights_only_Implementation_Handoff_v0.1.md`
- `R2_OptionB2_B23_Preflight_v0.1.2.md`
- `UI_SPEC_OptionB23_change_highlights_v0.1.1.md`
- `b3_phases.md`

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
- 当前 `GET /me/secondary-summary` controller / service / serializer / DTO / model
- 当前主机制结算承接返回对象（若存在聚合对象）
- 当前前端对 secondary summary / settlement response 的 parsing 位置
- 当前兼容旧字段时的解析路径

### 8.4 当前测试入口
至少盘点：
- backend unit tests
- backend e2e tests
- Flutter parsing / model tests（若当前前端已消费该聚合）
- B2-2 closeout 的 regression 入口（确保不误伤）

---

## 9. B23-A 你必须明确回答的问题

### Q1. `change_highlights[]` 最终挂在哪个现有响应上
请明确：
- primary landing point 是什么
- 为什么选它
- 为什么没有新增 endpoint

### Q2. 最终落下的最小结构是什么
请明确列出：
- `kind`
- `status`
- `label`
- `related_item_code`
- 是否允许缺失
- 是否允许空数组

### Q3. 生成逻辑基于哪些现有真相层
请明确：
- purchase
- equip
- growth
- streak
- post_learning
等分别如何映射 / 是否当前已支持

### Q4. 这轮如何保证没越界
请明确：
- 没有做 `companion_response` typing
- 没有做 `source_fact_tags`
- 没有新增 endpoint
- 没有新增状态机
- 没有改主业务规则

### Q5. 当前兼容性如何保证
请明确：
- 字段缺失时如何稳定
- 空数组时如何稳定
- 返回新字段时如何不破坏现有页面

### Q6. B23-B 最自然的开工点是什么
请给出最小建议：
- Today consumption 先接哪个 widget / card
- 哪些前端 tests 最该先跟进
- 哪些 truth-boundary case 最该先补

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 在现有聚合响应上新增 `change_highlights[]`
2. 写最小 mapper / serializer / DTO / model 改动
3. 写最小生成逻辑（仅基于现有真相层）
4. 补 compatibility tests
5. 若前端模型需要，补只读解析兼容
6. 做 very small docs sync（只记录 B23-A 新事实）

### 不允许做的
1. 不新增 endpoint
2. 不新增业务字段族
3. 不改业务规则
4. 不改 DB / API 主结构
5. 不把 `companion_response` typing / `source_fact_tags` 混进来
6. 不做 UI consumption
7. 不把这轮做成完整变化系统

如果你做了任何超出 B23-A 的事，必须解释为什么仍算 read-only extension landing，而不是 scope creep。

---

## 11. 这轮最小测试 / 验证要求

### 11.1 Node / backend
如果你动到了 response contract / mapper / service / e2e，请至少执行：
```bash
npm test
npm run test:e2e
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.2 Flutter / front-end
如果你动到了 model parsing / response consumption，请至少执行：
```bash
flutter pub get
flutter test
flutter analyze
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.3 B23-A 专项验证
至少完成这些验证：
1. `change_highlights[]` 已落地为 read-only extension
2. 未返回字段时前端仍稳定
3. 返回字段时不破坏现有页面
4. `label` 没被结构化成新真相层
5. 没有越界进入 B23-B / B23-C / B23-D
6. 没有带入 `companion_response` typing / `source_fact_tags`

### 11.4 必补测试类型
按照 Room 2 preflight，这轮至少要补：

#### A. truth-boundary cases
- `hinted ≠ confirmed`
- `displayed change ≠ backend-confirmed change`
- `change_highlights[].status=hinted` 不得自然导向“已获得 / 已生效 / 已到账”
- `change_highlights[].status=confirmed` 也不得替代 ownership / equipment / reward ledger 等现有真相层

#### B. response extension compatibility cases
- 未返回新增字段时前端仍可稳定工作
- 返回新增字段时不破坏现有页面

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — 状态文件
请新增：

```text
R4_OptionB23_change_highlights_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 B23-A）
2. 实现范围
3. 未实现范围
4. 是否出现 scope creep
5. truth boundary 是否保持
6. 当前是否建议继续进入 B23-B

### Deliverable B — 测试摘要
请新增：

```text
R4_OptionB23_change_highlights_Test_Summary_v0.1.md
```

至少包含：
1. Node / Flutter / widget / regression 入口
2. `change_highlights[]` 当前落到哪个响应上
3. hinted vs confirmed 是否测试
4. 字段缺失 / 空数组 / compatibility 是否覆盖
5. 是否触碰现有 API / DB 主结构
6. 是否有 B2-3 越界

### Deliverable C — Round summary（硬要求）
请新增：

```text
R4_cursor_round_summary_OptionB23_A_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **Where `change_highlights[]` landed**
3. **What the final minimal shape is**
4. **What truth boundary was kept**
5. **What backend surface did or did not change**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**
11. **Whether ready for B23-B**

### Optional
若你认为必须，才允许新增：

```text
R4_OptionB23_change_highlights_issue_note_v0.1.md
```

但只有在你发现：
- Room 2 proposal 仍有实现歧义
- 或 Room 5 absorption 仍存在无法落地点

时才交，不要默认制造新 patch。

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 B23-A 完成：

1. `change_highlights[]` 已以 very small、read-only extension 方式落地
2. 未返回字段时前端仍稳定
3. 返回字段时不破坏现有页面
4. 没有改主 endpoint 语义
5. 没有新增 endpoint / 状态机 / interaction backend action
6. `companion_response` typing / `source_fact_tags` 未被带入
7. `R4_OptionB23_change_highlights_Status_v0.1.md` 已生成
8. `R4_OptionB23_change_highlights_Test_Summary_v0.1.md` 已生成
9. `R4_cursor_round_summary_OptionB23_A_v0.1.md` 已生成
10. 最终能明确回答：是否 ready for **B23-B**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 **Option B2-3 / B23-A / Read-only extension landing**
- 明确不是 B23-B / B23-C / B23-D

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 B23-A 结果
请按这几项写清楚：
1. landing point
2. minimal shape
3. truth boundary
4. compatibility
5. backend touched or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `npm test` 结果
- `npm run test:e2e` 结果
- 如前端被影响：`flutter test` / `flutter analyze`
- B23-A 的专项验证做了哪些

### E. 交付物清单
- `R4_OptionB23_change_highlights_Status_v0.1.md`
- `R4_OptionB23_change_highlights_Test_Summary_v0.1.md`
- `R4_cursor_round_summary_OptionB23_A_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **B23-A**
2. 是否 ready for **B23-B**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你接 Today / Meow Home / Settlement UI，也不是让你把 B2-3 扩成新系统。

这轮唯一要做好的事情是：

> **先把 `change_highlights[]` 作为 very small、read-only、兼容旧前端的 extension 稳稳落下。**

不要扩 scope。  
不要偷拍板。  
不要把 B23-B / B23-C / B23-D 或其它候选项混进来。  
现在开始执行。
