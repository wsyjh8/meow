# UI_SPEC_P3_3_HomeEntry_and_4Button_UI_Preflight_v0.1.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1.1
- **Date:** 2026-04-09
- **Status:** preflight input / review absorption patch / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Runtime basis:** `Main_updated_2026-04-09_v18.md` + `STATUS_updated_2026-04-09_v17.md`
- **Source handoff:** `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目的

本文件由 **Room 5** 产出，用于把 P3.3 中与：

1. 首页“背单词”主入口  
2. 学习页 / 复习页的 4 按钮交互  
3. 两字中文按钮文案候选  
4. 学习主线与复习规划的页面承接关系  

相关的 UI / UX 问题，先收成一份 **preflight UI input**，供 Room 1 / Room 2 / Room 3 后续吸收与对齐。

本文件不是：
- 最终高保真视觉稿
- Room 3 的业务语义正文
- Room 2 的 FSRS 技术接入方案
- Room 4 的执行单

一句话：

> **先把“入口放哪、怎么点进去、4 按钮怎么摆、文案候选怎么收、哪里还不能让实现层补脑”写清楚。**

---

## 1. 输入依据

### 1.1 当前推进层 / 治理层依据
- `ORG_v0.3.1.md`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- `Main_updated_2026-04-09_v18.md`
- `STATUS_updated_2026-04-09_v17.md`

### 1.2 当前 active runtime UI / rule / contract basis
- `UI_SPEC_v0.2.1.md`
- `BR-OPP-001_v0.2.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

### 1.3 本轮 handoff basis
- `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.4 本轮 review absorption basis
- `p3_3_review.md`

---

## 2. Room 5 当前判断

### 2.1 这轮为什么应该新建 P3.3 UI preflight
原因有三点：

1. `UI_SPEC_v0.2.1.md` 已经是当前 **runtime active UI baseline**，它服务的是 P3.1 整体 close 后的页面现实，不适合直接被一轮 P3.3 preflight 混改。
2. Room 1 这轮给 Room 5 的任务是 **preflight / scope pin**，不是直接下实现，也不是直接出正式 baseline 替代稿。
3. 当前用户拍板同时牵涉首页入口、FSRS 接入、4 按钮词面与复习规划边界；Room 5 先独立出专项 preflight，最有利于后续 Room 1 做 cross-room 吸收。

### 2.2 Room 5 的一句话立场
> **P3.3 本轮先做“学习主线入口 + 4 按钮交互 + 页面承接关系”的 UI 收口，不做全量 IA 重构，也不在 Room 3 / Room 2 未收口前把 4 按钮业务含义写死。**

### 2.3 当前 runtime reality vs 本轮候选
1. 当前 runtime active UI baseline 仍是 `UI_SPEC_v0.2.1.md`。
2. 当前 Study / Review 的 runtime reality 仍可视为 **2 按钮现实**。
3. 本稿只是 **P3.3 的 4 按钮 preflight delta candidate**，不得被执行层视为 runtime 已切换。
4. 除非 Room 1 后续另行 pin，本稿中的“首页”默认指 **`SpecHomePage`**，不是泛指任意首页容器，也不是自动改写 `TodayPage` 的历史定位。

---

## 3. 本轮 UI 范围

## 3.1 In Scope
1. 首页“背单词”按钮的入口位置与层级建议
2. 点击后的页面承接关系
3. 学习页 / 复习页 4 按钮布局建议
4. 两字中文按钮的 UI 文案候选
5. 首页入口属于最强主 CTA 还是次强入口的建议
6. 哪些页面态 / 文案态现在可以收，哪些必须继续等 Room 2 / Room 3

## 3.2 Out of Scope
1. 不定义 4 按钮最终业务语义
2. 不定义 FSRS 接入的技术实现方式
3. 不定义完整复习调度产品
4. 不重做 `SpecShell 6-Tab`
5. 不重画全套高保真视觉稿
6. 不扩写统计、词书、副机制商店、P3.1 backup/restore

---

## 4. 首页“背单词”入口建议

## 4.1 Room 5 推荐结论
**首页应增加“背单词”主入口，而且应视为首页当前轮最强主 CTA。**

原因：
1. Room 1 已明确本轮用户拍板的是“把背单词按钮放到首页上，点开后可以背单词页面”。
2. P3.3 的核心不是“把复习先拉到首页最中间”，而是把“进入学习主线”重新做强。
3. 当前 `SpecHomePage` 已是首页现实基线，但它的主 CTA 还停留在静态跳转状态；P3.3 正好是把这个首页主 CTA 从“泛跳转”升级为“明确进入学习主线”。

> 说明：
> - 这里的“首页最强主 CTA”是 **P3.3 preflight 默认建议**，用于新首页入口收口。
> - 它**不自动覆盖**当前 active BR 中与 Today / review continuation / CTA winner 相关的既有规则。
> - 若 Room 3 + Room 2 + Room 1 后续正式吸收“review 优先”或更完整 CTA winner 规则，Room 5 应再以 delta patch 调整首页主次关系。

## 4.2 入口层级建议
首页当前轮建议采用以下优先级：

### A. 最强主 CTA
- **背单词**
- 放在首页首屏主卡片区域
- 视觉权重最高
- 单手区优先可点击
- 允许带小的次级辅助文案，例如：
  - “开始今天的学习”
  - “先学一组新词”

### B. 次强入口
- **去复习 / 继续复习**
- 仍可在首页首屏存在，但不和“背单词”做双主 CTA 并列
- 若后续 Room 3 / Room 2 收口后证明“当前应该优先复习”，再允许通过状态机把首页最强 CTA 从“背单词”切为“去复习”
- **在本轮 preflight 中，不先默认这么做**

### C. 弱入口
- Session
- Check-in
- Mochi / 副机制入口
- 统计 / 词书入口

## 4.3 首页入口位置建议
推荐位置：
- 首页主卡片下方第一主按钮位
- 不建议埋到二级卡片、快速操作网格或 Tab 下二级入口
- 不建议作为 Banner 文案中的文字链接

---

## 5. 页面承接关系建议

## 5.1 Room 5 推荐路径
当前推荐页面路径为：

### Path A：默认学习入口
`首页 -> 背单词 -> StudyPage`

### Path B：已有待复习 / 未来复习优先时
`首页 -> 去复习 -> ReviewPage`

### Path C：学习中自然进入复习
- 暂不在本轮 UI preflight 写死
- 是否从 StudyPage 自然切 ReviewPage，必须等 Room 2 / Room 3 收口

## 5.2 当前不建议的路径
1. 不建议把首页“背单词”按钮直接点进一个“学习 / 复习二选一中间页”
2. 不建议现在就做“统一学习页（既学新词又复习）”作为 Room 5 结论
3. 不建议让首页直接出现“4 按钮评分卡片”，这样会压缩首页判断效率

## 5.3 首页入口的 session / 承接合同（当前仍属 gap）
Room 5 当前建议只先冻结：

- 首页点击“背单词”默认进入 `StudyPage`
- 首页点击“去复习 / 继续复习”默认进入 `ReviewPage`

但以下内容 **当前仍不得由 Room 4 自行补脑**：
1. “背单词”是否启动 **新词学习 session**
2. 是否启动 **复习 session**
3. 是否进入 **混合 session**
4. 是否需要按今日计划 / readiness 自动分流

一句话：
> **本轮先冻结页面入口，不冻结 session 启动合同。**

---

## 6. 4 按钮交互布局建议

## 6.1 Room 5 当前建议
学习页 / 复习页的 4 按钮，**推荐采用 2 × 2 网格布局**。

原因：
1. 在手机上最稳，两个字中文长度可控
2. 2x2 比横向 4 连更不容易误触
3. 便于做“上排偏积极 / 下排偏困难”或“由易到难”的视觉分组
4. 未来接 Room 3 的业务语义时，信息层级更容易保持清楚

## 6.2 布局建议
### 推荐结构
- 卡片主体：单词 / 释义 / 例句 / 发音
- 卡片底部：4 按钮区
- 按钮排布：
  - 第一排：2 个按钮
  - 第二排：2 个按钮
- 每个按钮保持：
  - 同宽
  - 同高
  - 两字中文
  - 强对比、清晰可点击
  - 不依赖长解释才能理解

### 不推荐结构
1. 横排 4 连按钮
2. 1 主 3 次结构
3. 上下滑动式评分条
4. 文字很长的按钮 + 解释小字并排

## 6.3 学习页 / 复习页的共用原则
- **共用同一 4 按钮视觉框架**
- 业务语义可后续细分，但 UI 结构先统一
- 这样更适合后续真正进入 FSRS 接入时做系统化延展

## 6.4 4 按钮的 UI 排序占位（不是最终算法映射）
为减少后续 Room 4 对布局顺序的补脑，Room 5 当前只冻结 **显示顺序占位**，不冻结最终业务映射。

| UI 候选词面（候选集 A） | 当前 UI 顺序占位 | 记忆信心方向 | 业务 / 算法映射状态 |
|---|---|---|---|
| 不会 | Slot 1 | 最低 | pending |
| 模糊 | Slot 2 | 较低 | pending |
| 记得 | Slot 3 | 较高 | pending |
| 熟练 | Slot 4 | 最高 | pending |

说明：
1. 这张表只回答 **UI 排序与视觉分组**，不回答最终 rating / grade 枚举。
2. 前端最终传什么值、后端最终存什么值、是否直接映射 FSRS 4 档，必须等待 Room 2 + Room 3 收口。
3. Room 4 不得把上表直接当作已冻结算法枚举映射。

---

## 7. 两字中文按钮候选（UI 候选，不是业务定稿）

### 7.1 Room 5 输出原则
当前只能给 **UI 文案候选**，不能宣告最终冻结。
原因：
- Room 3 才能裁定“词面是否准确表达业务事实”
- Room 2 还没完成 FSRS 接入技术 preflight
- Room 1 也尚未完成 cross-room 吸收

> 当前所有两字中文按钮都只是 **UI 候选词面**，不属于 Fact Copy，不得在 Room 4 实现中当作最终业务冻结。

### 7.2 推荐候选集 A（最稳）
1. **不会**
2. **模糊**
3. **记得**
4. **熟练**

优点：
- 用户天然能理解
- 两字中文长度稳定
- 比较像真实学习感受
- 适合中文语境

风险：
- “记得 / 熟练”是否精确映射 FSRS 业务语义，需 Room 3 判定

### 7.3 候选集 B（更偏程度）
1. **很难**
2. **一般**
3. **较好**
4. **很好**

优点：
- 程度感强
- 容易按从差到好排序

风险：
- 太像主观程度词
- 可能弱化“记忆状态”而变成“做题感觉”

### 7.4 候选集 C（更偏行为结果）
1. **重来**
2. **再想**
3. **想起**
4. **掌握**

优点：
- 更接近动作 / 结果

风险：
- “重来 / 掌握”业务事实意味更重
- Room 3 更可能要求收紧

## 7.5 Room 5 当前推荐
**推荐候选集 A 作为首轮 UI 对齐输入。**


原因：
- 最容易被普通用户一眼看懂
- 最适合首轮 preflight 收口
- 对学习产品来说，语气更自然，不像算法后台术语

---

## 8. 首页入口是否属于最强主 CTA

## 8.1 Room 5 当前判断
**是。**

在 Room 3 / Room 2 还未把“当前是否必须先复习”“FSRS 接入后首页主动作是否改成复习优先”收口前，Room 5 当前建议是：

- 首页“背单词”入口先作为最强主 CTA
- “去复习 / 继续复习”作为次强入口预留位
- 后续如 cross-room 判断证明 review 应优先，再通过 UI delta patch 调整主次关系

## 8.2 为什么不是首页双主 CTA
因为双主 CTA 会带来 3 个问题：
1. 用户不知道“今天先做哪个”
2. Room 4 容易在没有收口前用本地条件补脑
3. 会直接削弱本轮“把学习主线重新做强”的目标

---

## 9. State Contract Matrix（最小版）

## 9.1 首页背单词入口
- **UI state:** 背单词主入口可见
- **Trigger rule / BR:** 当前由 Room 1 范围拍板触发；不是 Room 3 最终业务语义冻结
- **Required fields / API:** 无需新增 API 才能先做入口；session / route 分流合同仍待 Room 2 / Room 3
- **Local-only or source-of-truth:** 页面结构级 UI state
- **Loading / retry / stale behavior:** 无
- **Fact copy:** “背单词”
- **Tone copy:** 可选弱辅助文案，如“开始今天的学习”
- **Gap / blocker:** 若未来 Room 3 / Room 2 判断 review 应高优先，则需 UI delta patch 调整 CTA 主次；默认首页容器为 `SpecHomePage`

## 9.2 4 按钮评分区
- **UI state:** 4 按钮卡片交互区
- **Trigger rule / BR:** 业务语义待 Room 3 冻结
- **Required fields / API:** 当前只需页面布局 preflight；真正接入需 Room 2 提供 FSRS integration path
- **Local-only or source-of-truth:** 当前仅为 UI preflight，不能代表业务定稿
- **Loading / retry / stale behavior:** 提交中需统一 disable / loading；提交中同一题卡不得重复记分；失败需允许重试并回到原题卡；未显式失败前，不得允许二次记分
- **Fact copy:** 当前按钮词面仅是候选，不得在 Room 4 实现中当作最终业务冻结
- **Tone copy:** 不建议给每个按钮额外加情绪化文案
- **Gap / blocker:** 缺 Room 3 的 4 按钮业务语义冻结；缺 Room 2 的页面接入路径；缺最终算法枚举映射

## 9.3 4 按钮提交后的最小 UI 返回预期（仍属 preflight 推荐）
为减少首页任务感 / 进度感与学习页之间的断层，Room 5 当前建议 Room 2 后续至少评估以下最小返回能力：

1. 当前提交是否被接受（accepted / rejected）
2. 当前题卡是否可以切到下一题
3. 当前题卡结果摘要是否可用于本地即时反馈
4. 首页 / 今日任务卡是否需要刷新

以下字段对 UI 很有帮助，但 **当前仍不是冻结 contract**：
- `next_due`
- `current_item_new_status`
- `session_remaining_count`
- `home_refresh_hint`

一句话：
> **Room 5 需要“足够支撑即时反馈和首页刷新”的最小返回信息，但不在本稿里替 Room 2 冻结具体 payload。**

---

## 10. UI blocker / gap

### 10.1 当前无 blocker 的内容
1. 首页增加“背单词”按钮
2. StudyPage / ReviewPage 预留 4 按钮布局结构
3. 先给出中文候选词面
4. 先确定首页主 CTA 与次强入口层级

### 10.2 当前必须等 Room 3 / Room 2 的内容
1. 4 个按钮最终中文词面冻结
2. 4 按钮与 FSRS 语义一一映射
3. 前端最终提交什么值、后端最终存什么值
4. StudyPage / ReviewPage 是否共用同一交互逻辑
5. 首页“背单词”到底启动新词 session、复习 session、混合 session，还是按计划自动分流
6. 复习规划本轮到底冻结到：
   - 页面入口层
   - 规则层
   - 还是已经能进入实现层
7. 首页主 CTA 是否应根据 review readiness 自动切换

### 10.3 Room 5 当前一句话风险判断
> **P3.3 现在可以先把“入口位置、页面承接、按钮布局、候选词面”收清，但还不能让 Room 4 直接按某一组中文按钮、某一组算法枚举映射、或某一种 session 分流逻辑开做。**

---

## 11. 对 Room 1 的建议

### 建议吸收方式
Room 1 后续吸收本稿时，建议只吸收 3 件事：
1. 首页要有明确“背单词”主入口
2. 学习页 / 复习页的 4 按钮推荐采用 2×2 布局
3. 首轮中文按钮候选先以 **候选集 A** 进入 cross-room 对齐

### 不建议现在就吸收成 runtime truth 的内容
1. 4 个按钮最终词面
2. review 是否高于 new words 的首页主 CTA 优先级
3. StudyPage / ReviewPage 最终是否统一成一个承接页
4. 复习规划的完整产品结构

---

## 12. 一句话结论

> **Room 5 当前已完成 P3.3 的最小 UI preflight：首页“背单词”应先作为最强主 CTA，默认落点为 `SpecHomePage` 上的学习主入口，点击进入 `StudyPage`；学习页 / 复习页的 4 按钮推荐采用 2×2 布局；两字中文按钮可先用 `不会 / 模糊 / 记得 / 熟练` 作为首轮 UI 候选，但当前仍只是 P3.3 preflight delta candidate，不代表 runtime 已切换为 4 按钮现实，最终词面、算法枚举映射与 session 分流合同都必须等待 Room 3 + Room 2 收口后才能进入 Room 4 执行。**
