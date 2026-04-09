# Cursor_OptionB_Phase4_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是扩文案池，也不是开 B2 catalog 扩容，而是：

> **按这里给定的 Room 1 handoff、Room 5 的 Option B UI 方案、以及 Room 4 的 execution-side scope，完成 Option B 的 Phase 4：Customize / Catalog / Inventory / Equipment 体验升级。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前状态不是 P1 / P2，也不是 Option A / Option A.1。  
这些都已经完成并 close。  
Room 1 已正式拍板下一方向为：

> **Option B — Visual Polish & Content Expansion**

但 Option B 的**第一轮默认只做 B1，不自动进入 B2**。  
Phase 0、Phase 1、Phase 2、Phase 3 已完成，当前结论是：

- B1 / B2 边界已钉死
- interaction 的 B1 边界已钉死
- catalog 扩容不进首轮已钉死
- 第一轮 Done bar 已钉死
- 全局主题与共享组件已建立
- Meow Home 已重排完成
- Today Companion Card + 承接优化已完成
- `flutter test` 44/44 passed（Phase 3 回执）
- `flutter analyze` 0 errors

你现在接的不是 Phase 5，而是：

> **Phase 4 — Customize / Catalog / Inventory / Equipment 体验升级**

---

## 1. 这轮你到底要做什么

这轮只做：

1. 在**不改变后端契约、不扩 catalog item 数量、不新增业务状态**的前提下，升级 `/customize` 页和相关展示体验
2. 让用户更容易一眼看清：
   - 我现在长什么样 / 房间什么样
   - 我拥有什么
   - 什么能买
   - 什么已拥有
   - 什么已装备
3. 把购买 / 装备后的反馈做得更顺手、更有“我真的变了”的感觉
4. 复用 Phase 1 的 theme / shared components / animation utilities
5. 保持当前业务逻辑不变
6. 更新 / 补齐 Customize 相关 Flutter tests
7. 输出本轮 handoff 文档

这轮**不做**：
- 不扩 companion copy 池
- 不扩 catalog 到 10–14
- 不新增 item type / slot
- 不新增 API
- 不改 DB / API / persistence
- 不做 interaction 业务化
- 不改购买 / 装备的后端规则
- 不改主机制规则
- 不做统计页

一句话：

> **Phase 4 是升级 Customize 的可见层与操作体验，不是扩写商品系统或改动副机制真相层。**

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

### 3.2 catalog 扩容仍然不进本轮
这轮不要为了让 Customize 看起来更丰富而扩 catalog 到 10–14。  
你这轮可以：
- 升级 item card 的视觉
- 优化已有 5 个 item 的浏览 / 购买 / 已拥有 / 已装备状态
- 做顶部预览区

但不能：
- 新增 item
- 新增 slot
- 新增价格体系
- 新增 level-lock 规则

### 3.3 Option B 继续继承 truth / degraded-state guardrails
Option B 是 polish round，不是 persistence round。  
所以必须继续继承 `UI_SPEC_v0.1.4.md` 中已经写硬的 guardrails：

- `delayed snapshot ≠ fresh backend truth`
- `pending reward / settling reward ≠ 到账成功`
- `maintenance / read_only / temporarily_unavailable` 不能包装成成功
- UI 不能为了“更有变化感”而改写业务状态语义

### 3.4 “已拥有 / 已装备 / 已到账 / 已解锁”必须严格服从后端真相
这轮最容易出错的地方就是三态表达。

必须继续保持：
- `purchasable` ≠ `owned`
- `owned` ≠ `equipped`
- 购买动作提交成功 ≠ 视觉上自动写成“装备成功”
- 预览变化 ≠ 后端已确认变化

### 3.5 Room 4 不是 UI / UX owner
你不能把实现便利包装成 UI 决策。  
视觉方向、页面层级和交互表达，以 Room 5 的 `UI_SPEC_OptionB_v0.1.2.md` 为准。  
Room 4 / Cursor 只能：
- 实现 Customize 页的结构与表现
- 对缺口提 sync patch 需求
- 不能擅自拍板最终视觉方案

---

## 4. 这轮的正确目标

根据 Room 4 当前已经固定的 `optionB_phases`，Phase 4 的目标是：

> **把“买了什么、拥有什么、装了什么”做得更清楚、更顺手。**

这轮必须交付的，不是“完整商业版商城”，而是：

1. 顶部预览区
2. 更清楚的 Catalog / Inventory / Equipment 浏览切换
3. 更明确的三态表达
4. 更有感知的 equip / purchase 视觉反馈
5. 所有这些都继续服从：**后端真相优先**

---

## 5. 这轮 in scope

### 5.1 Customize 顶部预览区（必须）
请在 `/customize` 增加一个顶部预览区，让用户进入后能第一眼看到：

- 当前猫猫样貌 / 猫猫主体占位
- 当前已装备的外观组合（可用 emoji / icon / 友好标签）
- 房间 / 装饰的当前组合（若 room item 已装备）
- 一个整体“现在看起来是什么样”的感觉

### 5.1A 预览区的正确做法
当前 repo 没有高保真美术资产，因此这轮允许并建议：
- 使用 emoji
- 使用 icon
- 使用柔和色块
- 使用友好标签
- 使用 slot 到 icon 的映射
- 使用已装备 item display name 的组合展示

但不允许：
- 伪造不存在的资产
- 把“可购买但未拥有”的 item 预览成当前已装备态
- 把预览态写成业务真相态

### 5.2 Catalog / Inventory / Equipment 浏览切换（必须）
请把当前 Customize 中较朴素的 section 切换，升级成更清楚的浏览模式。  
推荐采用：
- tabs
- segmented control
- 或等价轻量分段切换

至少让用户能更直观地区分：

1. **Catalog**
   - 能买但未拥有
2. **Inventory**
   - 已拥有但未装备
3. **Equipment**
   - 当前已装备

### 5.3 item card 三态增强（必须）
当前所有 item card 必须更清楚地表达以下三态：

1. **可购买（purchasable）**
2. **已拥有（owned）**
3. **已装备（equipped）**

你可以通过以下手段增强：
- 颜色层级
- `MeowChip`
- icon / emoji
- tag 文案
- button 形式变化
- 边框 / 高亮 / 勾选 / slot 提示

但必须保证：
- 三态互斥且清楚
- 不制造“好像买了 / 好像穿上了”的错觉

### 5.4 equip / purchase 反馈增强（允许）
这轮允许增强：

#### 购买后
- 卡片状态即时变为 `owned`
- 温和 toast / snack / badge 更新
- 顶部预览区同步刷新（若逻辑允许）

#### 装备后
- 装备成功轻高亮
- 顶部预览区局部变化
- `equipped` tag 更明显
- slot 被替换时旧物品回到 `owned`

但不允许：
- 做成厚重弹层连击
- 做成重游戏式爆闪
- 写出超越后端真相的表达

### 5.5 友好名称 / 图标映射（允许）
当前 repo 里 item 可能仍偏 raw code。  
这轮允许并建议：
- code → 友好展示名映射
- slot → icon / emoji / tag 映射
- item category → 轻视觉分组

但不允许：
- 改 item 真正业务语义
- 引入新 category / slot / state
- 让前端映射覆盖后端事实

---

## 6. 这轮明确不做什么

### 6.1 不改后端
- 不改 `/shop/catalog`
- 不改 `/shop/purchases`
- 不改 `/me/inventory`
- 不改 `/me/equipment`
- 不改 equip / unequip API
- 不改 persistence

### 6.2 不扩内容
- 不新增 catalog item
- 不扩 companion copy 池
- 不新增 room themes
- 不新增 item type / slot

### 6.3 不做其他页面
以下都留到后续 phase：
- Phase 5 的 companion copy 小扩池
- closeout 文档收口之外的 B2
- 更大规模 content expansion

### 6.4 不改变业务事实表达
- 不把 pending 写成到账成功
- 不把 preview 写成已装备
- 不把购买提交写成已生效
- 不把 UI 局部变化写成后端已确认事实

---

## 7. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 7.1 Phase 0 / 1 / 2 / 3 产物
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase0_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase1_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase2_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase3_v0.1.md`

### 7.2 产品 / UI 输入
- `message7_R1toR4.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `OptionB_scope_v0.1.1.md`
- `optionB_phases.md`
- `UI_SPEC_v0.1.4.md`
- `R4_OptionB_Analysis_and_Execution_Plan_v0.1.md`

### 7.3 Flutter 入口与页面
至少盘点这些现有入口：
- `CustomizePage`
- item card / item list / section widgets
- 当前 purchase / equip / unequip UI 调用点
- shared theme / components / animations
- 当前 inventory / equipment / catalog 数据展示 widgets

### 7.4 当前测试入口
至少盘点：
- Customize 页 widget tests
- purchase / equip / three-state 相关前端测试
- 页面 smoke tests
- 若有 preview / dialog / snack tests 也要看

---

## 8. Phase 4 你必须明确回答的问题

### Q1. Customize 最终被重排成什么结构
请明确描述：
- 顶部预览区
- tabs / segmented control
- item list 区
- action 区
- 状态标签区

### Q2. 三态现在如何被表达
请明确：
- purchasable
- owned
- equipped
- 它们如何在视觉上被明确区分
- 为什么不会混淆业务事实

### Q3. 顶部预览区具体怎么做
请明确：
- 用了哪些现有字段
- 哪些只是 UI 预览，不是业务事实
- 用了什么 icon / emoji / tag / 色块策略
- 为什么不需要新后端字段

### Q4. 这轮如何保证没越界到 Phase 5 / B2
请明确：
- 没有扩 catalog
- 没有扩 companion copy 池
- 没有新增 API
- 没有新增状态字段
- 没有改业务规则

### Q5. Phase 5 最自然的开工点是什么
请给出最小建议：
- copy 池最适合从哪几类开始扩
- 哪些 UI 可以先复用，不需要再改结构
- 哪些测试最该先跟进

---

## 9. 这轮允许做什么，不允许做什么

### 允许做的
1. 重排 Customize 页面结构
2. 加顶部预览区
3. 接入 shared theme / components / animations
4. 强化 item card 三态
5. 做 equip / purchase 的轻反馈增强
6. 做最小友好名称映射 / icon 映射
7. 更新 / 新增 widget tests
8. 做 very small docs sync（只记录 Phase 4 新事实）

### 不允许做的
1. 不改后端 API
2. 不扩 catalog
3. 不扩文案池
4. 不新增业务字段
5. 不改业务规则
6. 不改 DB / API / persistence
7. 不把 preview 伪装成后端真相

如果你做了任何超出 Phase 4 的事，必须解释为什么仍算 Customize 表现层升级，而不是 scope creep。

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

### 10.2 Phase 4 专项验证
至少完成这些验证：
1. Customize 页结构已明显变化
2. 顶部预览区已落地
3. purchasable / owned / equipped 三态更清楚
4. equip / purchase 反馈更自然
5. 现有功能链路不破
6. 没有越界进入 Phase 5 / B2

### 10.3 建议额外覆盖
如果范围允许，建议补：
- Customize widget tests
- 三态显示正确性测试
- purchase / equip 后视觉反馈 smoke
- preview 区刷新检查
- equipment / inventory truth 不被 UI 误读检查

---

## 11. 本轮必须产出的文件（硬要求）

### Deliverable A — Option B status 更新
请更新：

```text
docs/R4_OptionB_Status_v0.1.md
```

至少补：
1. 当前完成到哪个 phase（必须写 Phase 4）
2. 已实现范围
3. 未实现范围
4. assumptions
5. blockers
6. risks
7. 当前是否允许进入 Phase 5

### Deliverable B — Option B test entry 更新
请更新：

```text
docs/R4_OptionB_Test_Entry_v0.1.md
```

至少补：
- Phase 4 影响到的 widget / page / smoke tests
- 哪些 Customize tests 已更新
- 哪些回归要带到 Phase 5

### Deliverable C — Handoff summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionB_Phase4_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **How Customize is now structured**
3. **How three-state is now expressed**
4. **What preview boundary was kept**
5. **What pages were not touched**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current risks**

---

## 12. 这轮完成标准（严格）

以下全部满足，才算 Phase 4 完成：

1. Customize 页面结构已升级
2. 顶部预览区已落地
3. purchasable / owned / equipped 三态已更清楚
4. equip / purchase 反馈已增强，但无业务越界
5. 没有改后端契约
6. `docs/R4_OptionB_Status_v0.1.md` 已更新
7. `docs/R4_OptionB_Test_Entry_v0.1.md` 已更新
8. `docs/R4_cursor_round_summary_OptionB_Phase4_v0.1.md` 已生成
9. 最终能明确回答：是否 ready for **Phase 5**

---

## 13. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 Option B Phase 4（Customize / Catalog / Inventory / Equipment 体验升级），不是 Phase 5 copy 扩池

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 Customize 结果
请按这几项写清楚：
1. preview area
2. tabs / segmented control
3. three-state expression
4. equip / purchase feedback
5. truth boundary
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 是否跑了后端命令（如果没跑请说明为什么）
- Phase 4 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionB_Status_v0.1.md`
- `docs/R4_OptionB_Test_Entry_v0.1.md`
- `docs/R4_cursor_round_summary_OptionB_Phase4_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **Option B Phase 4**
2. 是否 ready for **Phase 5**
3. 当前最大的剩余风险是什么

---

## 14. 最后提醒

这轮不是让你扩 catalog 或扩 companion copy 池。

这轮唯一要做好的事情是：

> **把 Customize 做成更顺手、更看得懂、更有“我真的拥有并装备了什么”的页面。**

不要扩 scope。  
不要偷拍板。  
不要把 B2 混进来。  
现在开始执行。
