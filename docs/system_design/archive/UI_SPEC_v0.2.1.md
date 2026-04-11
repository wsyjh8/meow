# 背单词喵喵 App UI SPEC v0.2.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.2.1
- **Date:** 2026-04-09
- **Status:** user-approved absorption patch / ready for Room 1 runtime-baseline update
- **Purpose:** 在用户明确允许“将 `UI_SPEC_v0.2.0.md` 吸收进正式 UI SPEC，并作为下一步开发、维护与新功能依据”的前提下，基于当前治理层 SSOT、推进层 SSOT 与代码反查稿，对 `UI_SPEC_v0.2.0.md` 做正式化吸收。  
  本稿的目标不是保留“代码 audit 口吻”，而是把**已在代码中长期存在、且已经足够影响开发/维护/新功能判断的页面结构、入口关系、状态边界与设计系统现状**，收口成一份可被后续继续引用的 Room 5 UI 基线候选。

---

## 0. 文档定位

本稿是 **Room 5 的正式 UI SPEC 候选基线**，不是 code audit，不是 Room 2/Room 4 的实现盘点文档，也不是简单把 `UI_SPEC_v0.2.0.md` 原样升格。  
本稿已经吸收了 `UI_SPEC_v0.2.0.md` 中可被 Room 5 正式接管的内容，并将以下内容降级处理：

- **保留为正式 UI SPEC 主体：**
  - 页面结构
  - 信息层级
  - 路由与导航关系
  - 组件与设计系统现状
  - 页面状态矩阵
  - 文案事实边界
  - Pending / 风险 / gap

- **降级为 appendix / implementation reality 参考，不作为 UI owner 主结论：**
  - 代码文件路径
  - 路由具体注册实现方式
  - Service/SQLite/fire-and-forget 等实现细节
  - 仅用于 code reality 说明、尚未被 Room 1 pin 的实验性结构升级

### 0.1 运行时说明
- 当前推进层 SSOT 里，active UI baseline 仍以 `Main / STATUS` 已 pin 的版本为准。
- 本稿是 **推荐 next-step UI baseline candidate**。
- 在 Room 1 将本稿正式吸收到 `Main / STATUS` 前，原 active UI references 仍然保留为运行态依据。
- 但从 Room 5 视角，后续开发、维护与新功能设计，**默认应优先参考本稿**，再向上服从当前 active PRD / BR / DB / API / ORG / Role Cards。

---

## 1. 输入依据

### 1.1 当前治理层 / 运行层依据
- `ORG_v0.3.1.md`
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `room5_v0.2.1.md`
- `Main_updated_2026-04-07_v17.md`
- `STATUS_updated_2026-04-07_v16.md`

### 1.2 当前仍需服从的 active runtime basis
- `背单词养猫app项目介绍书_v0.1.1_P3.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `BR-OPP-001_v0.1.9_full.md`
- `背单词喵喵app_DB设计草案_v0.1.5.md`
- `背单词喵喵app_API设计草案_v0.1.4.md`
- `UI_SPEC_P3_1_LocalProgress_CloudBackup_v0.1.1.md`
- `UI_SPEC_P3_1_DirectScopePin_Delta_v0.1.1.md`
- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`
- `UI_SPEC_v0.1.4.md`

### 1.3 本轮吸收输入
- `UI_SPEC_v0.2.0.md`
- `背单词喵喵app_DB设计草案_v0.2.0.md`
- `背单词喵喵app_API设计草案_v0.2.0.md`
- `BR-OPP-001_v0.2.0_full.md`

---

## 2. Room 5 吸收原则

### 2.1 可以正式吸收的内容
1. 代码里已长期存在、且已经影响开发和维护判断的页面结构
2. 代码里已真实存在的入口、路由、Tab 信息架构
3. 已实现页面的状态分层与交互主路径
4. 已经能稳定复现的设计系统现状
5. 已经影响文案事实边界的实现差异（例如 2 按钮 vs 4 按钮、占位页、mock stats）

### 2.2 不能直接升格成正式 UI 事实的内容
1. 尚未被 Room 1 pin 的产品结构变化
2. mock / placeholder / debug-only 内容
3. 代码级实现细节和技术权衡
4. Room 2 / Room 4 负责的 contract / implementation owner 结论
5. 会与当前 active PRD / BR / DB / API 冲突的“代码即真相”表达

### 2.3 一句话原则
> **把代码中“已经足够稳定的页面现实”吸收进 UI SPEC；把实现细节、实验结构和未 pin 内容留在 Pending / Appendix。**

---

## 3. 总体信息架构（吸收后口径）

### 3.1 当前推荐壳层结构
应用当前推荐以 `SpecShell` 作为主壳，采用 **6-Tab 底部导航** 作为新的主入口结构：

| Tab | 页面 | 定位 | 状态 |
|---|---|---|---|
| 首页 | `SpecHomePage` | 新默认首页 / 精简主入口 | 已实现 |
| 词书 | placeholder | 词书域保留位 | 占位 |
| Mochi | `SpecMochiPage` | 副机制聚合入口 | 已实现 |
| 统计 | `SpecStatsPage` | 统计独立入口 | 已实现（数据仍有 mock） |
| 我的 | `SpecProfilePage` | 设置 / 账号 / 数据入口 | 已实现 |
| 原版 | `TodayPage` | Legacy 合约驱动页 / 开发参考 | 保留 |

### 3.2 Room 5 对这套结构的正式表述
- **本稿接受 `SpecShell 6-Tab` 作为当前代码现实下的主 UI 结构。**
- 但 `TodayPage` 不视为废弃；它仍承载合约驱动、状态驱动更完整的主机制事实表达。
- `SpecHomePage` 代表更轻、更新、更面向后续演进的首页方向，但当前仍存在 `主 CTA 静态跳转` 等未决项。
- `SpecStatsPage` 与 `词书 Tab` 已进入正式信息架构，但各自状态不同：
  - `Stats`: 结构存在，数据未 fully trustworthy
  - `Books`: 位置存在，页面仍为 placeholder

### 3.3 命名路由（正式吸收）
| 路由 | 页面 | 作用 |
|---|---|---|
| `/` | `TodayPage` | Legacy 今日概览 |
| `/study` | `StudyPage` | 新词学习 |
| `/review` | `ReviewPage` | 复习 |
| `/session` | `SessionPage` | 专注 Session |
| `/check-in` | `CheckInPage` | 签到 |
| `/settlement` | `SettlementPage` | 结算（当前仍为占位） |
| `/meow-home` | `MeowHomePage` | 猫咪主页 |
| `/inventory` | `InventoryPage` | 收藏与商店 |
| `/customize` | `CustomizePage` | 装扮与小窝 |
| `/settings` | `SettingsPage` | 设置 |

---

## 4. 设计系统结论（吸收后口径）

### 4.1 当前并存现状
当前代码现实中，UI 已存在三套系统并行：

1. **SPEC 系统**  
   适用于：`SpecHomePage / SpecMochiPage / SpecStatsPage / SpecProfilePage / SpecTabBar`

2. **Legacy 系统**  
   适用于：`TodayPage / MeowHomePage / CustomizePage / InventoryPage / SettingsPage`

3. **原生 Material 极简系统**  
   适用于：`StudyPage / ReviewPage / SessionPage / CheckInPage / SettlementPage`

### 4.2 Room 5 正式判断
- **这三套系统并存的现实，现在被正式记录为 UI baseline 现状。**
- 后续新功能与维护开发，默认优先原则为：
  1. 不制造第四套系统
  2. 新页面优先向 **SPEC** 收敛
  3. 仍在 Legacy 轨道上的页，优先保持低风险一致性，不做强行重皮
  4. Material 极简页后续可逐步被更完整设计系统吸收，但不应因样式升级打断主学习低阻力

### 4.3 SPEC Token 结论
`SpecBg / SpecText / SpecBrand / SpecTypo / SpecRadius / SpecSpacing / SpecShadow` 体系已可视为当前新版 UI 的设计系统种子。  
后续 Room 5 / Room 4 在新功能页上可直接复用，不需要再重新定义一套命名系统。

---

## 5. 页面级正式吸收结果

## 5.1 SpecHomePage
**定位：** 新首页 / 精简主入口  
**正式吸收结论：**
- 作为当前代码现实中的默认首页方向，正式吸收进 UI SPEC。
- 信息层级为：问候区 → 主卡片 / 签到承接 → 主 CTA → 关键数字块 → 快速复习入口。
- 当前保留问题：
  - 主 CTA 仍是静态跳转 `/study`
  - 还未 fully 接入状态机 / CTA winner
- 因此，后续开发维护时：
  - 可把它视为首页主容器
  - 但**不能把它当前静态 CTA 行为误写成已冻结业务规则**

## 5.2 SpecMochiPage
**定位：** 副机制聚合入口  
**正式吸收结论：**
- 正式吸收为独立一级入口
- 负责承接陪伴感、轻互动、弱收集欲，不反向主导主学习链路
- `学单词，赚小鱼干` CTA 可以存在，但始终属于“引回主线”而不是“副线主导主线”

## 5.3 SpecStatsPage
**定位：** 统计独立入口  
**正式吸收结论：**
- 结构正式吸收，视为当前 IA 中真实存在的一级入口
- 但页面数据可信度仍受限制：
  - 当前存在 mock / 硬编码部分
  - 不得把其中所有指标都当作 backend-confirmed truth
- 后续开发维护可在此页继续做真实数据替换与 minimal stats deepening
- 但 Room 5 口径仍是：**页面结构已吸收，数据事实仍需向 BR / DB / API / runtime 对齐**

## 5.4 SpecProfilePage
**定位：** 我的 / 设置 / 数据入口  
**正式吸收结论：**
- 正式吸收
- 视为当前设置、同步与备份、个人/词书入口的上层容器
- 与 `/settings` 的关系：`Profile` 是导航入口，`Settings` 是具体操作页

## 5.5 TodayPage（Legacy）
**定位：** 合约驱动更完整的今日页 / 保留参考页  
**正式吸收结论：**
- 不视为废弃
- 继续保留为“主机制状态表达最完整”的参考基线之一
- 后续如需迁移其合约驱动能力到 SpecHomePage，应明确做 sync patch，而不是默认认为两页已经等价

## 5.6 StudyPage
**定位：** 新词学习主页  
**正式吸收结论：**
- 正式吸收当前 local-first reality：
  - 本地写入优先
  - 后台 fire-and-forget 同步
- 评分按钮现状正式记录为：
  - 当前页仍是 2 按钮（掌握 / 模糊）
  - FSRS 4 按钮组件已开发但未集成
  - **最终方案仍为 Pending**
- 这意味着后续开发可以此为真实现状继续维护，但不能把“2 按钮方案”误写成最终长期 frozen choice

## 5.7 ReviewPage
**定位：** 复习页  
**正式吸收结论：**
- 正式吸收当前 2 按钮复习路径
- 正式吸收 `本组完成 != 今日复习完成` 的页面文案边界
- 若未来切换到更完整 FSRS 评分交互，必须走单独 sync patch，而不是默认视为此页已支持

## 5.8 SessionPage
**定位：** 专注 Session  
**正式吸收结论：**
- 正式吸收三态结构：无 session / 进行中 / 已结束反馈
- `valid / invalid / pending` 的最终展示必须继续以后端 `session_validation_status` 为准

## 5.9 CheckInPage
**定位：** 签到页  
**正式吸收结论：**
- 正式吸收当前精简版
- 月历、节点奖励列表、节点奖励预告继续保持 Pending
- 当前已吸收的强边界：
  - `check_in != learning_day`
  - `learning_day != streak`

## 5.10 SettlementPage
**定位：** 结算页  
**正式吸收结论：**
- 正式吸收它目前是 **占位页**
- 不再假装已有完整结算体验
- 后续所有结算相关开发，应以“当前未实现”作为依据，而不是沿用旧稿中的完整五区结算假设

## 5.11 MeowHomePage
**定位：** 猫咪主页  
**正式吸收结论：**
- 正式吸收
- 当前已具备：
  - 资源栏
  - 成长区
  - 亮点区
  - companion 区
  - 跳转 Customize / Inventory
- 后续副机制维护和增强应以此页为真实基线，而不是回到最初仅摘要卡的抽象状态

## 5.12 CustomizePage
**定位：** 装扮与小窝  
**正式吸收结论：**
- 正式吸收
- 当前“预览区 + 资源栏 + 攒钱目标 + 已拥有未装备提示 + tab + 物品卡片 + 槽位”结构可作为后续装扮维护基线

## 5.13 InventoryPage
**定位：** 收藏与商店  
**正式吸收结论：**
- 正式吸收
- 当前已具备“余额卡片 + 收藏列表 + 商店列表 + 购买反馈”主结构
- 后续开发可在此页继续扩商店与收藏，但不应引入超出当前主副机制边界的复杂运营逻辑

## 5.14 SettingsPage
**定位：** 设置 / 本地数据 / 备份恢复  
**正式吸收结论：**
- 正式吸收
- 当前它已经是：
  - daily goal 设置页
  - desired retention 设置入口
  - backup 上传入口
  - restore gated 入口
- 后续与 P3.1 相关的开发维护，默认以本页为入口基线，而不是重新发明一条数据设置路径

## 5.15 词书 Tab
**定位：** IA 保留位  
**正式吸收结论：**
- 正式记录“位置存在，但页面未设计”
- 后续新功能若涉及词书域，可直接以此保留位继续展开
- 但在当前版本，不应把它误写成已完成页面

---

## 6. 关键状态与文案边界（正式保留）

以下边界继续作为正式 UI 口径保留，并适用于后续开发、维护、新功能：

1. **部分完成 != 已完成**
2. **本轮完成 / 本组完成 != 今日完成**
3. **签到成功 != learning_day**
4. **learning_day != streak 自动成立**
5. **Session started / ended != valid session completed**
6. **奖励展示 != 奖励到账**
7. **displayed snapshot != fresh backend truth**
8. **upload success != download success != restore success**
9. **副机制反馈不得反向宣告主机制事实**
10. **未 pin 的 candidate contract，前端不得自行补脑为已存在事实**

---

## 7. 当前可直接作为下一步依据的内容

以下内容现在就可以作为后续开发、维护、新功能的直接 UI 依据：

### 7.1 IA / 导航层
- `SpecShell 6-Tab`
- `Profile -> Settings`
- `Legacy Today` 保留
- `MeowHome / Customize / Inventory` 作为真实副机制链路

### 7.2 设计系统层
- 新功能页优先向 SPEC 收敛
- 旧页短期保持 Legacy，不强行重皮
- 不再新增第四套视觉体系

### 7.3 页面事实层
- `SettlementPage` 当前仍是占位
- `Stats` 结构存在但数据未 fully trustworthy
- `Study / Review` 当前仍是 2 按钮现实
- `Settings` 已是数据设置与备份入口

### 7.4 新功能开发层
- 若新增首页模块，默认加在 `SpecHomePage`
- 若新增副机制承接，默认看 `SpecMochiPage` 与 `MeowHomePage`
- 若新增统计能力，默认加在 `SpecStatsPage`
- 若新增账号/设置/备份项，默认加在 `SpecProfilePage -> SettingsPage`

---

## 8. Pending / 风险（吸收后保留）

### Critical
1. 评分按钮最终方案（Study / Review 是否走 2 按钮还是 4 按钮）
2. Settlement 真正实现
3. SpecHomePage 主 CTA 状态驱动化

### Major
4. 主 CTA winner 仲裁规则完整收口
5. `review_group` 分组算法细节
6. Stats 真实数据接入与可信度对齐
7. SPEC 设计系统进一步统一

### Minor
8. Mochi 页主 CTA 是否过强
9. Stats Tab 与 feature guard 可见性一致性
10. 词书页完整设计
11. 云端 vs 本地端复习系统长期收敛方向

---

## 9. Appendix A — 代码现状附录（降级信息）

以下内容保留为附录参考，不作为 Room 5 主结论：
- 具体代码文件路径
- 具体 route 注册方式
- drift / SQLite / SharedPreferences / service 编排细节
- 仅用于解释“为什么页面现在是这样”，不用于替代 PRD / BR / DB / API / UI 的正式层级

---

## 10. 下一步建议（Room 5）

1. 由 Room 1 将本稿作为 **next UI baseline candidate** 吸收到 `Main / STATUS`
2. Room 4 后续开发、维护、新功能默认优先参考本稿
3. Room 2 / Room 3 若对其中某些页面事实存在 contract 冲突，再做针对性 sync patch，而不是回退到 `v0.1.4`