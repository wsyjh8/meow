# 背单词喵喵 App — UI_SPEC_OptionB_v0.1.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Status:** review absorption patch / ready for Room 1 review
- **Type:** UI / UX + Content Polish Round
- **Purpose:** 在不重做业务真相层、不改主机制规则、不重开 persistence hardening 的前提下，把当前产品从“功能已跑通、主副机制闭环已成立、PG 真相层已成立”推进到“更好看、更顺手、更有陪伴感、更适合 demo / user testing”。
- **Direct Room 1 decision input:** `message6_R1toR5.md`
- **Based on current runtime active versions:**
  - `背单词喵喵app_主机制prd_v0.3.md`
  - `背单词喵喵app_副机制prd_v_0.md`
  - `背单词喵喵app_副机制设计稿_v_0.md`
  - `背单词喵喵app_副机制数值草案_v_0.md`
  - `PROJECT_RULES_MASTER_v0.3.1.md`
  - `room5_v0.1.1.md`
  - `BR-OPP-001_v0.1.5.md`
  - `背单词喵喵app_DB设计草案_v0.1.4.md`
  - `背单词喵喵app_API设计草案_v0.1.3.md`
  - `UI_SPEC_v0.1.4.md`
  - `Main_updated_2026-04-04_v10.md`
  - `STATUS_updated_2026-04-04_v9.md`

---

## 0. 本稿定位

本稿不是新一轮规则冻结，也不是 DB / API 重构稿。

本稿只做一件事：

> **定义 Option B — Visual Polish & Content Expansion 的第一版 UI / UX 方案。**

本稿用于：
- 让 Room 1 判断 Option B 的 UI / UX 范围是否合适
- 让 Room 4 后续能按页面与状态直接接实现计划
- 让 Room 2 / Room 3 只在确有 very small sync patch 时再做 review，而不是被迫重开业务层

### 0.1 当前基线判断
当前项目已具备以下前提：
1. P1 主机制闭环已成立
2. P2 副机制 MVP 承接闭环已成立
3. PostgreSQL 已成为 active runtime truth
4. Option A.1 已 close，关键 persistence 语义与 PG-path regression 已补齐
5. 当前 active UI baseline 为 `UI_SPEC_v0.1.4.md`

因此，Option B 可以正式从 Room 5 启动，但必须遵守：
- **学习优先**
- **低阻力**
- **温柔反馈**
- **可爱但不低幼**
- **副机制服务长期留存，不反向主导主学习链路**

### 0.2 Option B 的一句话目标

> **在不改变主副机制边界与后端真相层的前提下，让用户更容易感知“我学了、猫有回应、房间有变化、装扮更可见、今天回来更有期待”。**

### 0.3 本稿与 `UI_SPEC_v0.1.4.md` 的关系
- `UI_SPEC_v0.1.4.md` 仍是当前主机制 / persistence window 的 active UI baseline
- 本稿是 **Option B 新阶段的 UI / UX 方案稿**
- 本稿不覆盖主机制所有细节，只补 **Option B 需要加强的页面体验、内容层与反馈层**
- Room 1 若接受本稿，应在下一轮决定：
  - 直接 pin `UI_SPEC_OptionB_v0.1.1.md` 作为 Option B 方案输入
  - 或要求 Room 5 先出 `v0.1.1` 小修

### 0.4 继承自 `UI_SPEC_v0.1.4.md` 的强 guardrails
Option B 是 polish round，不是 persistence round。
因此，本稿默认继承并继续服从 `UI_SPEC_v0.1.4.md` 已写硬的 truth / degraded-state guardrails：
- `delayed snapshot ≠ fresh backend truth`
- `read_only / maintenance / temporarily_unavailable` 必须保持中性说明，不得包装成成功
- `pending reward / settling reward` 不得写成到账成功
- UI 不能为了“更有变化感”而把候选变化、展示变化或推测变化写成已确认业务事实

一句话：
> **Option B 可以增强感知，但不能削弱真相边界。**

---

## 1. Option B 范围定义

### 1.1 In scope
本轮 Option B UI / UX 范围包括：

1. **Meow Home 视觉与反馈提升**
   - 猫猫主体区更真实
   - 已装备物品更可感知
   - 成长 / 陪伴 / 互动反馈更细腻
   - 让页面更适合 demo / user testing

2. **Customize / Catalog / Inventory / Equipment 体验提升**
   - 购买 / 已拥有 / 已装备三态更清楚
   - 装备反馈更明显
   - 浏览路径更顺手
   - 让“买了什么、装了什么、现在房间变了什么”更直观

3. **Interaction / companion content 的可感知性提升**
   - interaction button 不再只是占位按钮
   - companion copy / response 更有层次
   - 喂猫、互动、升级、装备后都更有“被回应”的感觉

4. **Today 页与副机制摘要的协调优化**
   - 保持学习优先
   - 更自然地展示“今天学了之后，猫有什么变化”
   - 不让副机制卡片压过主 CTA

5. **结算承接区的满足感增强**
   - 不把主机制结算做厚重手游页
   - 但让“去看看喵喵变化”更有吸引力

6. **Option B 的内容扩展建议**
   - companion copy 扩池
   - catalog item 增量扩充
   - micro-feedback 内容更丰富

### 1.2 Out of scope
本轮明确不做：

1. 重做主机制规则
2. 重写 `daily_goal_status` / `session_validation_status` / `reward_settlement_status` 语义
3. 改 DB / API 主结构
4. 重开 persistence hardening
5. 扩成 P3 或新 major phase
6. 多猫 / 社交 / 排行 / 抽卡
7. 偷冻结 CTA winner / 完整 SRS / review_group 分组算法 / streak future basis
8. 完整统计页重设计
9. 账号体系重做 / 多端迁移向导 / 数据恢复向导
10. 高保真美术产出要求

### 1.3 本轮产出边界
Option B 的第一轮交付目标不是“所有页面立刻像正式商业版”，而是：
- **先把页面层级、状态、内容池和反馈逻辑定义清楚**
- 让 Room 4 可以做一轮可落地的 polish 实现
- 让 Room 1 能更快做 demo / user testing 判断

### 1.4 默认执行顺序（本轮 patch 新增）
本轮 Option B 默认按 **B1 → B2** 执行，而不是默认全量并行推进：

- **B1：首轮直接实现 / UI polish first**
  - Today Companion Card
  - Meow Home 重排
  - Customize 三态清晰化
  - interaction button 的可见回应
  - 一小批 companion copy 的可见扩充

- **B2：内容扩展候选 / Content expansion second**
  - catalog 扩容
  - 更多 copy pool
  - 更细的装备 / 成长反馈

当前 Option B 第一轮默认只做 **B1**；**B2 不自动进入本轮实施**。
若 Room 1 要求同轮推进 B2，应在下一轮 handoff 中显式 pin。

---

## 2. 全局 UI / UX 方向

### 2.1 新阶段关键词
- 更柔和
- 更萌一点
- 更有陪伴感
- 更有成长感
- 更有装扮反馈
- 更适合演示
- 仍然低阻力

### 2.2 视觉基调
- 学习页继续偏清爽、轻、少打扰
- 养成页允许更暖、更丰富，但不做手游式厚 HUD
- 卡片可更柔和、圆角更明显、信息层级更分明
- 允许更明显的插画位 / 角色位 / 物品预览位

### 2.3 动效原则
允许的动效：
- 轻微呼吸感
- 点按微反馈
- 奖励到账轻跳动
- 互动后猫猫短动作
- 装备后局部高亮 / 切换

禁止的动效：
- 连续多层弹窗
- 大面积炫技转场
- 打断学习流的长动画
- 每次进入都重复表演式动效

### 2.4 文案原则
- 温柔，但不粘
- 可爱，但不低幼
- 表达陪伴，不表达责备
- 表达“变化”，但不伪造“真相”
- 奖励、成长、装备反馈更具体，但仍不越过 BR / API 真相边界

#### 2.4A “今天有变化”类 copy 的统一边界（本轮 patch 新增）
- `喵喵好像有新变化`、`去看看今天的变化`、`今日变化条`、`装备成功轻回应` 这类表达，默认属于 **UI 承接文案**，不自动等同业务事实。
- 只有后端已确认的 **已拥有 / 已装备 / 已升级 / 已到账 / 已解锁** 事实，才允许被写成既成变化。
- 若只是 UI 推测、候选变化、等待到账或等待刷新中的变化，只能写成中性引导，如：`去看看今天的小变化`、`好像有东西可以看看`，不得写成“已经获得 / 已经生效 / 已经到账”。

## 2.5 增强显示块的数据来源标记规则（本轮 patch 新增）
Option B 中以下增强显示块，默认必须标清 **数据来源层级**，以防 Room 4 在前端拼真相：
- Today Companion Card
- 今日变化条
- 结算承接变化摘要
- Meow Home 状态泡泡

每个块都必须在实现输入中归类为以下三种之一：
1. **Direct existing backend field**：直接消费当前已存在的后端字段
2. **Very small sync patch required**：需要极小 API / content sync patch 才能稳定呈现
3. **Pure front-end static content layer**：纯前端静态内容层，不表达业务事实

默认禁止：前端把 Today、secondary summary、inventory、equipment、settlement 等多个来源自由拼接成“今天已经发生了什么”的业务事实。

---

## 3. 页面级改动清单

## 3.1 Today

### 3.1.1 页面目标
保持“3 秒知道今天做什么”的效率，同时把副机制摘要从“功能入口”升级为“更有吸引力的承接卡”。

### 3.1.2 核心改动
1. **副机制摘要卡改成更轻但更有温度的 Companion Card**
   - 展示今日猫猫一句短回应
   - 展示一个最重要的变化点：如“今天又攒够 1 条小鱼干” / “有新装扮可看” / “猫猫刚升到 Lv4”
   - 保持它是弱于主任务卡的次级区块

2. **任务卡与副机制卡视觉分层更明确**
   - 主学习卡：更干净、更强对比、更强调主 CTA
   - Companion Card：更轻、更温柔、更像“学完可以去看看”的承接区

3. **结算返回后的轻承接提示更具体**
   - 目前仅“奖励状态已刷新”不够有吸引力
   - Option B 建议改成：
     - `喵喵好像有新变化` 
     - `去看看今天的小变化` 
     - `有一件新东西可以看看`
   - 仍不得把未到账 item 写成已到账

4. **签到区块可增加更细的情绪反馈**
   - 已签到后增加一句 companion copy
   - 节点日时，视觉比普通日更明显，但不厚重

### 3.1.3 Today 不该做的事
- 不增加第二个强主按钮
- 不把喂猫 / 购买 / 装备操作拉到 Today
- 不让副机制摘要卡占据首屏主位

### 3.1.4 Today Companion Card / 变化摘要的数据来源说明（本轮 patch 新增）
- 今日猫猫短回应：默认可来自 **现有 companion response / 前端静态 copy 池**；若要做类型化样式差异，属于 very small sync patch
- “最重要的变化点”：默认只能引用 **现有后端已确认事实**，如余额变化、已拥有、已装备、已升级、已到账等；若当前没有稳定字段，必须降级为中性引导
- 结算返回后的轻承接提示：默认属于 **UI 承接文案**，不是业务确认文案

---

## 3.2 Meow Home

### 3.2.1 页面目标
把 Meow Home 从“信息已齐的功能页”推进到“用户一眼觉得猫真的更像在陪我”的页面。

### 3.2.2 核心改动
1. **猫猫主体区变成页面第一视觉焦点**
   - 预留更大的猫猫展示位
   - 猫猫上方可显示短状态泡泡，如“很开心 / 想吃小鱼干 / 刚陪你学完”
   - mood / bond / energy 不再只像后台数值，应以“状态标签 + 轻解释”呈现

2. **资源区与成长区拆层**
   - Coins / Fish Treats / EXP 放成上方轻资源栏
   - Level / 当前状态 / 下一级进度形成 Growth Card
   - 让用户一眼知道“我现在是什么状态”“下一步会变成什么”

3. **已装备反馈更明显**
   - 当前装备的 outfit / room item 不只显示文本标签
   - 至少要在猫猫主体区或房间区显示：
     - 轮廓占位
     - 缩略图 / icon
     - 或带名字的小挂件标签
   - 目标是让用户感知“装了和没装真的不一样”

4. **interaction button 变成真正有存在感的轻互动按钮**
   - 按钮文案不建议只写“互动”
   - 建议改成更具体的轻动作，如：
     - `摸摸它`
     - `陪它玩一下`
     - `和喵喵打个招呼`
   - 点击后至少触发：
     - 短动作反馈
     - 一句短回应
     - 页面局部情绪变化
   - **第一版不要求引入新业务奖励**

5. **“今天的变化”单独做成 small change strip**
   - 示例：
     - `今日学习带来：+20 Coins / +3 Fish Treats / Lv 提升中`
     - `刚刚装备：草莓围巾`
     - `今日已喂猫 1 次`
   - 这是 demo / user testing 时很重要的“变化证据”区

### 3.2.3 Meow Home 建议结构
- 顶部：资源轻栏
- 主体：猫猫展示区 + 状态泡泡
- 中部：Growth Card + 今日变化条
- 操作区：喂猫 / 轻互动 / 去装扮
- 下部：已装备预览 / companion copy / 弱入口

### 3.2.4 Meow Home 状态泡泡 / 今日变化条的数据来源说明（本轮 patch 新增）
- 状态泡泡：默认优先消费 **现有 pet state / companion response**；若只是前端气氛文案，不得包装成后端状态字段
- 今日变化条：默认只能引用 **已确认变化事实**；若要展示 typed `change_highlights[]`，属于 very small sync patch
- 已装备反馈：默认必须来自 inventory / equipment 已确认状态，不得由 UI 仅凭点击结果假装已装备

---

## 3.3 Customize

### 3.3.1 页面目标
让用户更容易理解“我现在能买什么、已经有什么、当前装了什么、改了之后发生了什么”。

### 3.3.2 核心改动
1. **把三态做得非常清楚**
   - 未拥有：`购买`
   - 已拥有未装备：`装备`
   - 已装备：`已装备` + 可切 `卸下` 或 `更换`

2. **增加顶部当前预览区**
   - 进入 Customize 时，顶部先展示当前猫猫 / 当前房间预览
   - 让用户先看“现在长什么样”，再往下选

3. **列表不只按“全部物品”堆叠**
   - 至少增加：
     - `已拥有`
     - `未拥有`
     - `已装备`
   - 若实现成本允许，再加 `全部`

4. **装备结果应有即时回显**
   - 装备成功后：
     - 顶部预览立刻变化
     - item 卡片状态切到 `已装备`
     - 给一句短 companion response，如“这套很适合你”

### 3.3.3 Customize 的不做项
- 不做自由摆放坐标系统
- 不做复杂拖拽编辑器
- 不做厚重二级三级商店结构

---

## 3.4 Catalog / Inventory / Equipment

### 3.4.1 页面目标
让 Room 4 不必新增太多新后端，也能把“买 / 拥有 / 装备 / 查看”四步体验理顺。

### 3.4.2 核心改动
1. **建议前端组织成同一体验簇**
   - 不一定必须新开 3 个独立页面
   - 更推荐：
     - Customize 主页
     - 内部 tabs / segmented control：`商店` / `我的物品` / `已装备`

2. **Catalog item 卡片信息更完整**
   - 名称
   - 类型（outfit / room item）
   - 价格
   - level lock（若有）
   - 当前状态标签
   - 简短风格描述

3. **Inventory 不只是列表，应强调“可用来做什么”**
   - 已拥有但未装备时，应明确 `去装备`
   - 已拥有且已装备时，应明确 `正在使用`

4. **Equipment 区不该像调试页**
   - 建议使用更直观的 slot 分组
   - 例如：
     - 猫猫穿戴
     - 房间摆件
   - 即使底层仍是 slot-based，也不直接把技术 slot 名抛给用户

---

## 3.5 结算承接区（若涉及）

### 3.5.1 页面目标
保留主机制结算“轻、清楚”的前提下，让副机制承接更有吸引力。

### 3.5.2 核心改动
1. **弱 CTA 由“进入喵喵主页”升级为“去看看今天的变化”**
2. **如果本轮存在可见变化，应优先摘要变化，而非只列数字**
   - 如：
     - `喵喵刚刚升到 Lv4`
     - `草莓围巾已经可以穿上啦`
     - `今天又可以喂它一次`
3. **不把结算页做成厚重游戏奖励页**
   - 保持 1 个主完成结论 + 1 组奖励摘要 + 1 个弱承接 CTA 即可

---

## 4. 状态与交互提升点

## 4.1 正常态
- Today：任务清楚，副机制摘要有吸引力但不抢主位
- Meow Home：猫猫主体区有状态、有陪伴文案、有装备感
- Customize：三态清晰，预览区先于列表
- Catalog / Inventory / Equipment：能迅速知道下一步该点什么

## 4.2 空态
- Meow Home 空装扮时，不要只写“暂无装扮”
  - 改成：`现在还是初始小窝，继续学习就能慢慢变得更丰富`
- Inventory 空时，不要做冷清白板
  - 给一张轻引导卡：`先从第一件小物件开始吧`
- Today 完成后，不只剩空进度
  - 给弱承接：`今天已经很不错了，去看看喵喵现在的样子`

## 4.3 loading
- Today：继续维持局部骨架，不整页闪烁
- Meow Home：先出猫猫主体骨架位，再出资源与下方卡片
- Customize：先出顶部预览骨架，再出 item skeleton grid
- loading 态仍保持“软”和“轻”，不要像后台管理页

## 4.4 奖励反馈态
- 奖励到账时允许：
  - 数字轻跳动
  - 小图标亮一下
  - “今日变化条”出现新变化
- 但仍要保留：
  - 页面级 `reward_settlement_status`
  - item 级到账仍可延迟
- 禁止把 pending item 展示成已到账成功

## 4.5 成长反馈态
- Lv up 不只弹一句文字
- 建议包含：
  - `Lv x → Lv y`
  - 一句猫猫回应
  - 若有新解锁入口，轻提示“可以去看看”
- Growth Card 内保留下一等级进度，让成长不是一次性消息，而是持续感知

## 4.6 互动反馈态
- 互动必须产生“看得见的回应”
- 第一版最小标准：
  - 按钮点击反馈
  - 猫猫微动作
  - 一句 companion response
  - 冷却前后视觉区别
- 若仍只是点一下没有变化，则不算 Option B 合格交互

## 4.7 装备反馈态
- 购买成功后应立即把 item 推进到拥有态
- 装备成功后至少要同时发生三件事：
  1. 当前预览变化
  2. 卡片状态变化
  3. 有一条轻回应 / 轻提示

## 4.8 降级态与异常态
Option B 不是 persistence round，但不能丢掉 `UI_SPEC_v0.1.4` 已经建立的底线：
- delayed snapshot 仍必须可区分
- read_only / maintenance / temporarily_unavailable 仍必须保持中性说明
- polish 不能覆盖真相层提示

---

## 5. 内容扩展建议

## 5.1 建议扩充的 companion copy / response

### A. 日常打开类
建议以 **8–12 条** 作为候选目标，分轻状态池：
- 普通欢迎
- 已签到欢迎
- 已学习欢迎
- 连签节点欢迎
- 回归欢迎（隔几天回来）

### B. 学习后回应类
建议扩成按事实触发的 4 组：
1. 新词完成后
2. 复习完成后
3. 今日部分完成后
4. 今日全部完成后

### C. 喂猫 / 互动类
建议单独扩一组，不与学习完成文案混用：
- 喂猫后
- 互动后
- 今日已互动过一次后
- 今日喂养达到 full-benefit 上限后（中性提示）

### D. 装备 / 购买类
建议新增：
- 买到新物品时
- 装备成功时
- 首次换装时
- 房间有变化时

### E. 成长类
建议新增：
- 刚升级
- 接近升级
- 今日进步明显
- 一段时间后变化可见

## 5.2 content item 扩充建议
Option B 适合优先增加的是：

### A. 低成本高感知 item
1. 围巾
2. 小帽子
3. 胸前小挂饰
4. 小地毯
5. 靠垫
6. 桌灯
7. 小鱼玩具
8. 墙贴

### B. 风格建议
- 奶油系
- 软糯系
- 简单少女感
- 初春 / 周末 / 夜晚三种情绪主题

### C. 不建议此轮加入的 item
- 强特效 item
- 复杂套装加成
- 稀有度体系过重
- 抽卡限定道具

## 5.3 推荐 catalog 扩容方式
- 当前若已有 5 个 dev items，可把 **10–14 个** 作为候选扩容量
- 价格仍保持简单梯度，不引入新货币
- 优先做“看得出差异的小物件”，不要优先做只有文本名不同的 item

### 5.4 Asset strategy（本轮 patch 新增）
- Option B 第一轮允许使用 **统一风格 placeholder / stable asset key / dev thumbnail** 落地
- 不等待正式高保真美术，不卡住 Room 4 的首轮 polish 实现
- 若后续进入更高保真阶段，可在不改业务真相层的前提下替换资源映射
- 当前默认策略：先把“看得出差异”做出来，再升级素材精度

---

## 6. 视觉 polish 原则

## 6.1 什么属于“更真实、更细腻、更适合 demo”
1. 猫猫主体区更大、更像角色而不是 icon
2. 已装备物件有更明确的视觉挂载感
3. 状态标签比纯数字更易懂
4. 页面有“今天真的有变化”的证据区
5. 购买 / 装备 / 互动 / 喂猫都有明确但轻量的反馈
6. 列表卡片从“开发态”提升到“可展示态”
7. demo 时打开页面，外部人能 5 秒看懂“这是学完以后能养的猫”

## 6.2 什么不能为了好看破坏主流程效率
1. Today 不得出现多个同级主 CTA
2. 学习页、复习页不得增加装饰性打断弹层
3. 结算页不得做成又长又厚的奖励仪式页
4. 不能为了萌而让文案失真
5. 不能为了展示 item 而把主学习路径埋深
6. 不能为了“像游戏”而让信息层级混乱

## 6.3 推荐风格边界
- 卡片更柔和，但层级要更清楚
- 颜色可稍暖，但任务主按钮仍要最醒目
- 猫猫页允许更丰富，但 Today 仍偏克制
- 可爱靠细节与反馈，不靠堆满贴纸

---

## 7. 对 Room 4 的实现输入

> 本节固定分为 3 类：
> 1. **Room 4 可以直接实现**
> 2. **需要先做 very small sync patch**
> 3. **需要 Room 2 / Room 3 review**
> Room 4 不应在这三类之外自行追加第四类口径。


## 7.1 Room 4 可以直接实现的点
这些点在不改 DB / API 主结构的前提下，可以直接进实现计划：

1. Today Companion Card 的视觉与层级调整
2. Today 结算返回后更具体的轻承接提示
3. Meow Home 页面重排：资源轻栏 / 猫猫主体区 / Growth Card / 今日变化条
4. Meow Home 的状态标签化呈现
5. Customize 顶部预览区 + tabs / segmented control
6. Catalog / Inventory / Equipment 的三态清晰化
7. item 卡片的状态标签、价格展示、level lock 提示
8. 装备成功后的局部 UI 回显与轻提示
9. 互动按钮的前端存在感提升（文案、样式、点击反馈、局部回应）
10. companion copy 的前端展示样式优化
11. 升级弹层 / 成长反馈的样式优化

## 7.2 需要先做 very small sync patch 的点
以下点不是大改，但如果要做得更好，建议先做 very small sync patch：

1. **companion_response 的类型化**
   - 若当前只返回单一字符串，建议 very small patch 增加：
     - `response_type`
     - `source_fact_tags[]`
   - 这样 Room 4 更容易做分样式呈现，而不必靠字符串猜

2. **secondary summary 的 change highlights**
   - 若 Room 1 希望结算承接更强，可 very small patch 增加轻量字段：
     - `change_highlights[]`
   - 仅用于显示“今天的变化”，不改变真相层

3. **catalog item 预览 key / thumbnail key**
   - 若当前 item 只有文本字段，建议 very small patch 为 item 增加稳定的前端资源 key
   - 这不改业务规则，只提高渲染能力

4. **interaction button 的 typed response / cooldown / richer outcome**
   - 当前 Option B 第一轮默认只要求 **UI-presentational upgrade**：更明确的文案、点击反馈、局部回应
   - 若要进一步做 typed response、cooldown 状态、或更丰富的 interaction outcome，建议先走 very small sync patch
   - Room 4 不应自行假设 interaction 已拥有新的后端合同

## 7.3 需要 Room 2 / Room 3 review 的点
以下点不能由 Room 5 自行推进，应先经 Room 2 / Room 3 review：

1. interaction 如果要推进成 **会影响 mood / bond / reward / daily fact** 的真业务动作
2. 新 catalog item 若涉及：
   - 新 slot 类型
   - 新 level lock 规则
   - 新价格体系
   - 新资源消耗规则
3. 若要给 companion_response 新增会影响业务解释的事实字段
4. 若要把“今日变化条”中的某些内容当成正式业务事实，而不是 UI 承接文案

---

## 8. Room 5 的最终建议

### 8.1 默认推进顺序
Option B 第一轮默认按两小步推进：

#### B1. 首轮直接实现（默认本轮范围）
- Today Companion Card
- Meow Home 重排
- Customize 三态清晰化
- 互动按钮存在感提升
- companion copy 小批量可见扩充

#### B2. 内容扩展候选（不自动进入本轮实施）
- catalog items 扩容
- more copy pools
- 更细的装备 / 成长反馈

> 当前 Option B 第一轮默认只做 **B1**；**B2 不自动进入本轮实施**。

### 8.2 为什么这样切
因为当前产品已经“能跑通”，Option B 的关键不是再开规则，而是：
- **让已有闭环更有感知**
- **让 demo 时更能打动人**
- **让 user testing 时更容易看出用户是否真的被陪伴感 / 成长感吸引**

### 8.3 Option B 第一轮最小通过标准 / through bar（本轮 patch 新增）
以下标准用于帮助 Room 4 后续做 plan / test，也帮助 Room 1 判断 Option B 第一轮是否做到：
1. **Today Companion Card** 已落地，且不压过主 CTA
2. **Meow Home** 已形成主体区 + Growth Card + 今日变化条
3. **Customize** 的未拥有 / 已拥有 / 已装备三态清楚
4. **interaction button** 已有用户可见回应，不再只是占位
5. 至少一批 **companion copy / low-cost high-visible items** 已进入前端可见范围
6. 所有“今天有变化”类 copy 仍服从 truth guardrails，不把候选变化写成已确认事实

---

## 9. 给 Room 1 的最简结论

Room 5 的判断是：

> **Option B 适合先以“UI / UX + content polish round”启动，而不是先重开业务和技术层。**

本稿建议 Room 1 先审核三件事：
1. Option B 是否接受以 Meow Home / Customize / Today companion coordination 为第一优先级
2. interaction button 是否允许先做“轻互动有存在感”，而不是立刻升级成新业务动作
3. content 扩容是否接受“先扩 low-cost high-visible items + companion copy pool”这一条路线

