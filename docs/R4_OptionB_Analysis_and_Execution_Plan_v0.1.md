# Option B — Room 4 Analysis & Execution Plan v0.1

**Date**: 2026-04-04
**Author**: Room 4 (执行端)
**Input**: `UI_SPEC_OptionB_v0.1.1.md` (Room 5) + 当前 repo 实际代码状态
**Purpose**: 评估 UI Spec 可行性，结合代码现实给出最优执行计划

---

## 1. UI Spec 审核结论

### 1.1 整体评价
`UI_SPEC_OptionB_v0.1.1.md` 质量很高，方向正确。特别好的点：

- **B1/B2 分步策略** 非常务实——先做可见变化，后扩内容
- **数据来源三分法**（Direct existing field / Very small sync patch / Pure frontend）清晰，避免前端拼真相
- **guardrails 继承**（delayed snapshot ≠ truth, pending ≠ 到账）严格
- **动效原则**（允许呼吸感微反馈，禁止大面积炫技）克制
- **文案原则**（温柔不粘，可爱不低幼）和产品定位一致

### 1.2 需要调整或补充的点

#### A. Interaction button "真业务" vs "纯 UI 反馈" 边界需要更硬
Spec 说"第一版不要求引入新业务奖励"，但又说"互动必须产生看得见的回应"。当前 repo 中 interaction 是纯 placeholder，**后端没有 interaction endpoint**。

**Room 4 建议**：B1 阶段互动按钮只做**纯前端本地反馈**（随机文案 + 按钮状态变化），不创建新的后端 API。如果要做 cooldown、mood 影响、bond 增加，那属于 B2 或需要 very small sync patch。

#### B. "今日变化条" 当前后端不直接提供 `change_highlights[]`
Spec 建议的"今日变化条"需要知道"今天发生了什么变化"。当前 `secondary_summary` 不返回 change history。

**Room 4 建议**：B1 阶段用**前端本地比较**（进入页面前 vs 刷新后的 summary 差值）来推导变化，不依赖新后端字段。标注为"UI 承接文案"，不表达为业务事实。

#### C. Customize 顶部预览区 "猫猫当前样貌" — 当前没有视觉资产
Spec 建议的"进入 Customize 时顶部显示当前猫猫/房间预览"，但当前所有装备都是文字标签，没有图片/图标资源。

**Room 4 建议**：B1 用 **emoji + 风格化文字标签 + 柔和色块** 代替正式美术资产。把"看得出差异"做出来，不等高保真素材。这与 Spec 5.4 的 Asset strategy 一致。

#### D. Catalog 扩容从 5 → 10-14 需要后端 seed 配合
当前 catalog 只有 5 个 dev items 硬编码在 DevStore。扩容需要同时更新后端 catalog + PG seed。

**Room 4 建议**：B1 阶段先做 **UI 框架升级**（三态/tabs/预览），catalog 扩容放 B2。避免 B1 范围过大。

---

## 2. 代码现实 vs Spec 差距分析

| Spec 要求 | 当前代码状态 | 差距 | B1 可做程度 |
|---|---|---|---|
| Today Companion Card 更温暖 | 有 companion_response 数据，有基础卡片 | UI 太朴素，无视觉分层 | **可直接做** |
| Meow Home 页面重排 | 扁平 Card 列表，无主体焦点 | 需要重排：猫猫主体→资源栏→Growth Card | **可直接做** |
| 猫猫主体区更大更像角色 | 104x104 圆形 icon（`Icons.pets`） | 需要放大+样式化 | **可直接做**（emoji/插画占位） |
| 状态泡泡 | 无 | 需新增，数据来自 companion_response | **可直接做** |
| 资源轻栏 vs Growth Card 分层 | 资源和状态混在一起 | 需要拆层重排 | **可直接做** |
| 已装备反馈更明显 | 文字标签 `head: cat_hat_red` | 需要变成友好名称 + icon | **可直接做**（映射表） |
| Interaction button 真实 | `_showComingSoon('互动功能将在后续阶段开放')` | 需要前端本地反馈 | **可直接做**（纯前端） |
| Customize 三态清晰化 | 已有但样式朴素 | 需要视觉增强 | **可直接做** |
| Customize 顶部预览 | 无 | 需新增 | **可直接做**（文字/emoji 预览） |
| Customize tabs 分组 | 按 outfit/room 分 section | 可改为 tabs | **可直接做** |
| companion copy 扩池 | 3 种 greeting + 3 种 post_learning + 4 节点 | 需要扩展 | **后端改动小**（DevStore 文案池） |
| 升级弹层样式优化 | 已有 AlertDialog，简单文字 | 需要更温暖的视觉 | **可直接做** |
| 全局色彩/圆角/字体 | Material 默认 orange seedColor | 需要自定义主题 | **可直接做** |
| Catalog 扩容 5→14 | 5 个硬编码 | 需改后端 + seed | **放 B2** |

---

## 3. Room 4 推荐的 B1 执行切片

### 原则
- **不改后端 API 语义**
- **不新增后端 endpoint**（interaction 纯前端）
- **允许极小后端 content patch**（companion copy 扩池、item 名称映射）
- **先做全局主题，再逐页改**

### 推荐执行顺序

#### Phase B1-0: 全局主题与设计基础（必须先做）
1. 自定义 Flutter 主题：柔和色板、圆角、字体、卡片样式
2. 共享组件：MeowCard（圆角卡片）、MeowChip（状态标签）、资源小图标
3. 全局色彩常量：primary orange warm、secondary cream、accent soft pink

#### Phase B1-1: Meow Home 重排（核心感知提升）
1. 猫猫主体区放大 + 居中 + 状态泡泡
2. 资源轻栏（coins/fish_treats/exp 横排顶部）
3. Growth Card（level + exp 进度条 + 下一级提示）
4. 已装备区从 raw slot 名变成友好名称 + emoji
5. 喂猫按钮样式提升
6. Interaction 按钮从 placeholder 变成前端本地反馈
7. companion copy 展示样式优化

#### Phase B1-2: Today 页优化
1. 副机制摘要卡升级为 Companion Card（更温暖的视觉）
2. 主学习 CTA 视觉强化（更醒目的按钮）
3. 签到/连续区块视觉优化
4. 结算返回轻承接文案优化

#### Phase B1-3: Customize 页升级
1. 顶部当前预览区
2. Tabs 分组（商店 / 我的物品）
3. 三态视觉增强
4. 装备成功后轻回应

#### Phase B1-4: Companion copy 小批量扩池（极小后端改动）
1. 后端 companion_response 文案池扩展（8-12 条 greeting）
2. 喂猫/互动后回应扩展
3. 装备成功回应

---

## 4. 不在 B1 做的事（明确放 B2 或更后）

| 项目 | 原因 | 何时做 |
|---|---|---|
| Catalog 扩容 5→14 | 需改后端 seed + 可能改 PG | B2 |
| companion_response 类型化（response_type/source_fact_tags） | 需改 API contract | B2 sync patch |
| change_highlights[] 后端字段 | 新 API 字段 | B2 sync patch |
| Interaction 影响 mood/bond/reward | 新业务规则 | B2 或需 Room 2/3 review |
| 高保真美术资产 | 需美术产出 | B2+ |
| 复杂动效/动画 | 优先级低于结构改进 | B2+ |

---

## 5. 与 UI Spec 的对齐表

| Spec Section | Spec 要求 | Room 4 B1 处理 | 对齐状态 |
|---|---|---|---|
| 3.1 Today | Companion Card + 轻承接 | B1-2 | 对齐 |
| 3.2 Meow Home | 重排 + 猫猫焦点 + 状态泡泡 | B1-1 | 对齐 |
| 3.3 Customize | 三态 + 预览 + tabs | B1-3 | 对齐 |
| 3.4 Catalog/Inventory | 同一体验簇 | B1-3（tabs 整合） | 对齐 |
| 3.5 结算承接 | 更具体的轻承接 | B1-2 | 对齐 |
| 4.1-4.8 状态提升 | 正常/空/loading/奖励/成长/互动/装备/降级 | B1-1/B1-2/B1-3 分步覆盖 | 对齐 |
| 5.1-5.3 内容扩展 | copy 扩池 + catalog 扩容 | B1-4（copy 小扩）+ B2（catalog 扩容） | 部分对齐（B2 补全） |
| 7.1 直接实现 | 11 点 | B1 覆盖 9 点，2 点放 B2 | 大部分对齐 |
| 7.2 sync patch | 4 点 | 放 B2 | 延后但不冲突 |

---

## 6. 风险与技术考量

### 6.1 Flutter 主题系统改动范围
当前 `app.dart` 用的是 `ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange))`。B1-0 需要全面自定义主题。这会影响所有页面的默认样式。

**风险**: 低。Flutter Material 3 支持主题继承，改基础主题不会破坏功能。

### 6.2 Meow Home 重排可能影响现有测试
当前 `meow_home_page_test.dart` 有 ~15 个 widget 测试检查特定文本和 Key。重排后需要更新测试。

**风险**: 中。需要同步更新测试 Key 和预期文本。

### 6.3 后端 companion copy 扩池
当前文案硬编码在 `DevStore.getCompanionResponse()`。扩池只需修改该方法，加更多 if/else 分支和随机选择。

**风险**: 低。DevStore 方法修改，不影响 API contract。

---

## 7. B1 完成标准（建议）

1. 全局主题已从 Material 默认切换为"偏萌温暖"风格
2. Meow Home 已重排：猫猫焦点 + 资源轻栏 + Growth Card
3. Today Companion Card 已升级
4. Customize 已有顶部预览 + tabs
5. Interaction 按钮有前端本地反馈
6. companion copy 至少扩到 8 条 greeting
7. 所有测试通过（可能需要更新 widget test 预期）
8. `flutter analyze` 0 errors

---

## 8. 建议 Room 1 决策

1. **确认 B1 范围**：上述 B1-0 到 B1-4 是否合适
2. **确认 B2 延后**：catalog 扩容和 API sync patch 是否放后面
3. **确认 Interaction 纯前端**：B1 阶段互动不接后端，只做前端反馈
4. **确认美术策略**：B1 用 emoji + 风格化占位，不等高保真素材

以上确认后，Room 4 可以立即开始 B1-0 执行。
