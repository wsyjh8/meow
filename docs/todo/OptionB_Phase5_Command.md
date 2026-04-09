# Cursor_OptionB_Phase5_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是扩 catalog，也不是开 B2 内容扩张，而是：

> **按这里给定的 Room 1 handoff、Room 5 的 Option B UI 方案、以及 Room 4 的 execution-side scope，完成 Option B 的 Phase 5：Companion copy 小扩池 + polish closeout。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前状态不是 P1 / P2，也不是 Option A / Option A.1。  
这些都已经完成并 close。  
Room 1 已正式拍板下一方向为：

> **Option B — Visual Polish & Content Expansion**

但 Option B 的**第一轮默认只做 B1，不自动进入 B2**。  
Phase 0、Phase 1、Phase 2、Phase 3、Phase 4 已完成，当前结论是：

- B1 / B2 边界已钉死
- interaction 的 B1 边界已钉死
- catalog 扩容不进首轮已钉死
- 第一轮 Done bar 已钉死
- 全局主题与共享组件已建立
- Meow Home 已重排完成
- Today Companion Card + 承接优化已完成
- Customize / Catalog / Inventory / Equipment 体验升级已完成
- `flutter test` 44/44 passed（Phase 4 回执）
- `flutter analyze` 0 errors

你现在接的不是新的 B2，也不是 next major phase，而是：

> **Phase 5 — Companion copy 小扩池 + polish closeout**

---

## 1. 这轮你到底要做什么

这轮只做：

1. 在**不改变后端真相层、不新增 API、不扩 catalog item 数量**的前提下，补一轮最小但可感知的 companion copy 扩池
2. 让 greeting / post-learning / streak / feed / interaction / equip 等已有反馈更不重复、更有陪伴感
3. 对前 4 个 phases 已完成的 UI polish 做一轮收尾回归
4. 对照 Room 4 已钉死的 **Done bar** 做 close judgment 级别的收口
5. 更新 / 补齐最终 Phase 5 的文档与测试回执
6. 输出本轮 handoff 文档

这轮**不做**：
- 不扩 catalog 到 10–14
- 不新增 item type / slot
- 不新增 typed response / new payload
- 不新增 API
- 不改 DB / API / persistence
- 不做 interaction 业务化
- 不改主机制规则
- 不开 B2
- 不开 P3

一句话：

> **Phase 5 是把 B1 做成“更有内容感且可 close”的最后一刀，不是内容系统大扩写。**

---

## 2. 你必须接受的上游结论

### 2.1 Room 1 已正式拍板 Option B
当前 post-Option-A.1 的下一方向，不再悬置。  
Room 1 已明确：

> **post-Option-A.1 next direction = Option B — Visual Polish & Content Expansion**

### 2.2 当前项目必须继续服从的原则
Room 1 明确要求 Option B 必须继续满足：

- **学习优先**
- **副机制继续服务主机制**
- **温柔、可爱、清楚、顺滑**
- **不制造强负罪、强责备、强压迫体验**

### 2.3 当前 runtime active baseline
当前 repo / 方案层必须继续服从这些 active baseline：
- 主机制 PRD `v0.3`
- 副机制 PRD `v0`
- 项目介绍书 `v0`
- 副机制设计稿 `v0`
- 副机制数值草案 `v0`
- BR `v0.1.5`
- DB `v0.1.4`
- API `v0.1.3`
- 主 UI baseline `UI_SPEC_v0.1.4`

### 2.4 Option B 的性质
Option B 不是：
- 规则改写轮
- DB / API 重构轮
- persistence round
- P3

Option B 是：

> **把已经存在的副机制事实和反馈，做得更容易被用户看见、理解、记住。**

---

## 3. 你必须服从的强断言

### 3.1 第一轮默认只做 B1
当前第一轮默认执行范围 = **B1**。  
B2 仅作为后续候选，不自动进入本轮。

### 3.2 copy 扩池是“小扩池”，不是内容系统扩容
这轮只允许做：

- 更丰富的 greeting 文案
- 更丰富的 post-learning / companion response
- 更丰富的 feed / interaction / equip 轻回应
- 更丰富的 streak 节点回应

但不允许做：

- 大规模 CMS 化
- 新增 remote copy config
- 新增复杂 mood / bond 文案树
- 新增剧情系统
- 新增大量条件分支规则

### 3.3 Option B 继续继承 truth / degraded-state guardrails
Option B 是 polish round，不是 persistence round。  
所以必须继续继承 `UI_SPEC_v0.1.4.md` 中已经写硬的 guardrails：

- `delayed snapshot ≠ fresh backend truth`
- `pending reward / settling reward ≠ 到账成功`
- `maintenance / read_only / temporarily_unavailable` 不能包装成成功
- UI 不能为了“更有变化感”而改写业务状态语义

### 3.4 所有新 copy 都不能越过事实边界
这轮最容易出错的是文案比事实跑得更快。

必须继续保持：
- 没有后端确认的“已到账 / 已解锁 / 已升级 / 已生效”，不能写成既成事实
- interaction 的前端轻反馈不能写成真实成长 / 奖励 / 关系变化
- equip / purchase / preview 文案不能暗示超过后端已确认范围的结果

### 3.5 Room 4 不是 UI / UX owner
你不能把实现便利包装成 UI 决策。  
文案风格、页面层级和交互表达，以 Room 5 的 `UI_SPEC_OptionB_v0.1.2.md` 为准。  
Room 4 / Cursor 只能：
- 扩当前已有反馈池
- 完成 B1 closeout
- 对缺口提 sync patch 需求
- 不能擅自拍板新的内容方向

---

## 4. 这轮的正确目标

根据 Room 4 当前已经固定的 `optionB_phases`，Phase 5 的目标是：

> **在不把范围做重的前提下，补出“最小内容可见增强”，并完成第一轮 closeout。**

这轮必须交付的，不是“完整内容系统”，而是：

1. 一轮最小但可感知的 companion copy 扩池
2. 让前四个 phase 的 polish 有更稳定的内容承接
3. 对照 Done bar，明确 B1 是否可以 close
4. 留下清楚的 remaining technical debt / next step 建议

---

## 5. 这轮 in scope

### 5.1 可扩的 copy 类别（必须）
请优先扩充当前已有、并且已经有 UI 承接位的这些文案池：

1. **daily greeting**
2. **post-learning response**
3. **streak node response**
4. **feed response / feed feedback**
5. **interaction 本地前端回应**
6. **equip / purchase 轻回应**
7. **Today Companion Card 的轻承接文案**

### 5.2 扩池策略（必须）
请采用：

> **小扩池、低风险、直接可见、复用现有结构**

建议：
- 每类只补到“明显不那么重复”的程度
- 优先扩现有条件分支里的文案数组 / 模板
- 不新增复杂规则，不新增深条件树
- 不要求每种状态都覆盖很多条

### 5.3 后端改动边界（允许但必须极小）
如果当前 repo 的 companion response 是硬编码在 DevStore / content helper 中，这轮允许做**极小后端 content patch**，例如：
- 扩 `getCompanionResponse()` / 等价 helper 的文案池
- 扩 feed / equip / purchase 相关 response mapping

但必须满足：
- 不新增 API 字段
- 不改响应结构
- 不改业务规则
- 不改持久化结构

### 5.4 前端 copy 承接（允许）
这轮也允许在前端：
- 调整现有 copy 的显示位
- 更柔和地承接 Phase 2–4 已完成的 UI
- 对 snack / toast / chip 文案做轻优化

但必须满足：
- 不新增真相字段依赖
- 不伪造业务状态
- 不把 preview / weak hint 写成已确认事实

### 5.5 B1 closeout（必须）
你这轮必须按 Room 4 已定义的第一轮 Done bar，明确回答：

1. **Today Companion Card 已落地，且不压主 CTA**
2. **Meow Home 主体区 / 资源轻栏 / Growth Card / 状态泡泡已落地**
3. **Customize 三态与顶部预览已落地**
4. **interaction button 已有前端可感知回应**
5. **至少一小批 companion copy 扩充已用户可见**

并给出：
- 是否全部满足
- 是否 ready for Option B B1 close judgment

---

## 6. 这轮明确不做什么

### 6.1 不改后端契约
- 不改 `/me/secondary-summary`
- 不改 `/me/feed`
- 不改 `/shop/catalog`
- 不改 `/shop/purchases`
- 不改 `/me/inventory`
- 不改 `/me/equipment`
- 不改 equip / unequip API
- 不改 persistence

### 6.2 不扩 catalog
- 不新增 item
- 不新增 item type / slot
- 不扩价格体系
- 不扩 level-lock 规则

### 6.3 不开 B2
- 不做 catalog 5 → 10–14
- 不做更大规模 copy pool
- 不做 typed `companion_response`
- 不做 `change_highlights[]`
- 不做 stable preview / thumbnail key
- 不做 interaction cooldown / richer payload

### 6.4 不改变业务事实表达
- 不把 pending 写成到账成功
- 不把 preview 写成已装备
- 不把交互文案写成后端已确认成长
- 不把“今天有变化”写成后台已确认的 change history

---

## 7. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 7.1 Phase 0–4 产物
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase0_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase1_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase2_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase3_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase4_v0.1.md`

### 7.2 产品 / UI 输入
- `message7_R1toR4.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `OptionB_scope_v0.1.1.md`
- `optionB_phases.md`
- `UI_SPEC_v0.1.4.md`
- `R4_OptionB_Analysis_and_Execution_Plan_v0.1.md`

### 7.3 当前 copy / response 入口
至少盘点这些现有入口：
- companion response 生成函数 / helper / DevStore
- feed 成功后的反馈文案
- purchase / equip 的反馈文案
- Today Companion Card 的文案来源
- interaction 的本地前端文案来源

### 7.4 当前测试入口
至少盘点：
- Companion response / Meow Home / Today / Customize 相关 widget tests
- any copy helper tests / state tests
- 页面 smoke tests

---

## 8. Phase 5 你必须明确回答的问题

### Q1. 这轮到底扩了哪些 copy
请明确列出：
- greeting
- post-learning
- streak
- feed
- interaction
- equip / purchase
- Today 承接文案

### Q2. 你如何保证这些 copy 没越过真相边界
请明确：
- 哪些只是 UI 承接
- 哪些基于现有后端字段
- 哪些没有改业务语义
- 为什么不会伪确认

### Q3. 这轮如果改了后端，具体改了什么
请明确：
- 是否只是扩文案数组 / mapping
- 是否保持响应结构不变
- 是否无 DB / API 变更

### Q4. 这轮如何保证没越界到 B2
请明确：
- 没有扩 catalog
- 没有新增 API
- 没有新增字段
- 没有新增复杂条件树
- 没有改业务规则

### Q5. Option B 第一轮是否 ready for close judgment
请明确：
- Done bar 哪几项满足
- 哪几项若仍有不足，具体差什么
- 当前是否建议 Room 1 close B1

---

## 9. 这轮允许做什么，不允许做什么

### 允许做的
1. 扩现有 companion / response 文案池
2. 扩前端 interaction 本地反馈文案
3. 扩 feed / equip / purchase 轻回应
4. 做极小后端 content patch（若仅为扩文案源）
5. 调整前端 copy 承接位
6. 更新 / 新增 widget tests
7. 做 very small docs sync（只记录 Phase 5 新事实）

### 不允许做的
1. 不改后端 API 契约
2. 不扩 catalog
3. 不新增业务字段
4. 不新增复杂内容系统
5. 不改业务规则
6. 不改 DB / API / persistence
7. 不把 B2 混进来

如果你做了任何超出 Phase 5 的事，必须解释为什么仍算 companion copy 小扩池 + closeout，而不是 scope creep。

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

### 10.3 Phase 5 专项验证
至少完成这些验证：
1. companion / response 文案明显不再那么重复
2. 文案风格仍温柔、可爱、不过界
3. Meow Home / Today / Customize 上都至少有一部分新 copy 被用户可见
4. 现有功能链路不破
5. 没有越界进入 B2
6. 可以对照 Done bar 进行 close 判断

### 10.4 建议额外覆盖
如果范围允许，建议补：
- copy helper tests
- Meow Home / Today / Customize 文案 smoke
- feed / equip / purchase 反馈 smoke
- 关键 truth-boundary 文案检查

---

## 11. 本轮必须产出的文件（硬要求）

### Deliverable A — Option B status 更新
请更新：

```text
docs/R4_OptionB_Status_v0.1.md
```

至少补：
1. 当前完成到哪个 phase（必须写 Phase 5）
2. 已实现范围
3. 未实现范围
4. assumptions
5. blockers
6. risks
7. 当前是否建议 Option B 第一轮 close

### Deliverable B — Option B test entry 更新
请更新：

```text
docs/R4_OptionB_Test_Entry_v0.1.md
```

至少补：
- Phase 5 影响到的 widget / helper / smoke tests
- 哪些 copy / response tests 已更新
- 哪些回归要保留给后续 B2 / next phase

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB_Phase5_v0.1.md
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
10. **Whether B1 is ready for close judgment**

---

## 12. 这轮完成标准（严格）

以下全部满足，才算 Phase 5 完成：

1. 至少一轮 companion copy 小扩池已完成
2. Meow Home / Today / Customize 上有可见的新 copy 承接
3. truth boundary 继续守住，无伪确认
4. 没有改后端契约
5. `docs/R4_OptionB_Status_v0.1.md` 已更新
6. `docs/R4_OptionB_Test_Entry_v0.1.md` 已更新
7. `docs/R4_cursor_round_summary_OptionB_Phase5_v0.1.md` 已生成
8. 最终能明确回答：是否建议 **Option B 第一轮 close**

---

## 13. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B Phase 5（Companion copy 小扩池 + polish closeout），不是 B2

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 copy / closeout 结果
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
- Phase 5 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase5_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **Option B Phase 5**
2. 是否建议 **Option B 第一轮 close**
3. 当前最大的剩余风险是什么

---

## 14. 最后提醒

这轮不是让你扩 catalog 或开 B2。

这轮唯一要做好的事情是：

> **用最小的内容扩池，把 B1 收成一个更有陪伴感、且可判断 close 的版本。**

不要扩 scope。  
不要偷拍板。  
不要把 B2 混进来。  
现在开始执行。
