# 背单词喵喵 App 主机制页面结构稿 / UI SPEC v0.1.4

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Status:** review5 absorption patch / ready for Room 1 review
- **Purpose:** 在不重写结构主干、不扩写页面范围的前提下，以 `UI_SPEC_v0.1.2.md` 为 base，吸收 `R2_OptionA_Persistence_Hardening_Plan_v0.1.2.md` 中已进入用户可见层的 migration / degraded-state 语义，把 persistence hardening 对 Today / Meow Home / Customize 的界面影响正式回写到 UI 层。
- **Based on active versions:**
  - `背单词喵喵app_主机制prd_v0.3.md`
  - `背单词喵喵app_副机制prd_v_0.md`
  - `背单词喵喵app_副机制数值草案_v_0.md`
  - `PROJECT_RULES_MASTER_v0.3.1.md`
  - `room5_v0.1.1.md`
  - `Main.md`
  - `OPP-001_STATUS.md`
- **Sync input for this patch (not auto-active unless Room 1 pins it):**
  - `R2_OptionA_Persistence_Hardening_Plan_v0.1.2.md`
- **Current runtime active UI baseline:** `UI_SPEC_v0.1.2.md` until Room 1 updates Main / STATUS.

---

## 0. 本稿定位

本稿只覆盖 **主机制关键页面**，目标是让：
- Room 1 能审核主机制页面是否达到 Design-Ready
- Room 2 能基于页面状态反推 DB / API / 状态字段
- Room 4 能据此建立后续实现入口与测试入口

本稿 **不做**：
- 高保真视觉稿
- 动效精修
- 副机制详情页展开
- 多端像素级适配细节
- 新增奖励规则、改写业务口径


### 0.1 本轮 patch 范围（v0.1.3 → v0.1.4）
本轮只做以下修补，不做大改版：
1. 吸收 `R2_OptionA_Persistence_Hardening_Plan_v0.1.2.md` 中已经进入用户可见层的 migration / degraded-state 规则。
2. 正式回写：`sync_status=delayed`、`maintenance=true`、`read_only=true`、`temporarily_unavailable=true` 这类状态在 UI 层的最小表现策略。
3. 为 Today / Meow Home / Customize 补上迁移窗口、只读窗口、read-model rebuild 窗口的最小可用态与文案边界。
4. 保留当前 6 个主机制关键页面范围；对 Meow Home / Customize 只补 persistence hardening 影响附录，不重写完整副机制页面稿。
5. 保留仍未冻结事项为 pending：CTA winner 详细仲裁规则、`review_group` 分组算法细节、统计页完整规格、未来是否把 `streak` basis 从 `check_in` 改为其他口径。
6. 本轮补一句更硬的执行边界：这些 migration / degraded-state UI 规则，仅在 Room 1 正式 pin Option A 并进入 cutover / maintenance / degraded-state 实施窗口后，才作为 Room 4 的强实现与强回归断言执行。

### 0.2 本轮未扩写内容
- 统计页仍未展开成独立完整页面稿；本轮只补 migration / degraded-state 相关范围说明，不阻塞当前主机制 6 页 patch。
- 不在 UI 层冻结 `review_group` 的 group size / 分组算法 / review priority / 题型比例。
- 不在 UI 层冻结 CTA winner 详细仲裁规则。
- 不在 UI 层改写奖励规则、发奖规则或副机制边界规则。
- 不在 UI 层提前决定未来 `streak` 是否改按 `learning_day` 或组合条件延续。
- 不顺手扩写账号绑定流程、数据恢复向导、多端迁移提示页；这些不属于本轮 Option A UI sync patch 范围。

---

## 1. 页面设计总原则

### 1.1 设计目标
主机制页面必须先满足四件事：
1. 用户一打开就知道今天该做什么
2. 用户进入学习后不被副机制打断
3. 用户完成学习后立刻看见清楚结果
4. 用户若愿意，再自然进入副机制承接页

### 1.2 界面优先级
1. **主学习任务信息**
2. **当前进度与状态**
3. **主 CTA（开始学习 / 去复习 / 完成 Session）**
4. **签到与奖励摘要**
5. **副机制摘要入口**

### 1.3 气质要求
- 学习页：更清爽、更专注、更少装饰
- 今日页：清楚、轻激励、带一点温度
- 结算层：有满足感，但不能手游化过厚
- 全局：可爱但不低幼，温柔但不黏腻

### 1.4 文案总边界
- “部分完成”不能写成“已完成”
- “奖励展示”不能写成“成长已经生效”
- “展示型反馈”不能写成“后端事实已确认”
- “欢迎回来”不能写成责备或内疚型召回
- “签到成功”不能写成“完成有效学习日”
- “本组复习完成”不能写成“今日复习完成”
- “Session 已 started / ended”不能写成“valid session completed”
- “奖励展示成功”不能写成“奖励到账成功”
- “迁移中 / 维护中 / 只读中”不能写成“已成功同步 / 已恢复正常 / 已刷新完成”
- `displayed snapshot` 不能写成 `fresh backend truth`
- “暂不可用 / 稍后再试”应优先表达为系统窗口状态，不写成用户操作错误或责备式文案

### 1.5 页面状态统一约定
关键页面统一使用以下状态语言：
- 未开始
- 进行中
- 部分完成
- 已完成
- 待校验（仅在确有后端确认延迟时出现）
- 结算成功
- 结算失败 / 待重试
- 同步延迟（`sync_status=delayed` 或等价语义）
- 只读中（`read_only=true` 或等价语义）
- 维护中（`maintenance=true` 或等价语义）
- 暂不可用（`temporarily_unavailable=true` 或等价语义）

### 1.6 关键交互统一约定
- 主 CTA 永远只有一个最强按钮
- 次要操作只做次级按钮或文本入口
- 奖励/成长相关入口不覆盖主学习 CTA
- 弹层关闭后，默认回到更靠近主学习的位置，而不是把用户丢到复杂页面


### 1.7 统一命名约定（本轮 patch 新增）
- 页面级奖励结算状态统一使用：`reward_settlement_status`
- Session 是否有效统一使用：`session_validation_status`
- 今日目标是否完成统一使用：`daily_goal_status`
- 若 API 返回最近一次结算对象，则 UI 读取路径写成：`last_reward_settlement.reward_settlement_status`
- `reward_items[].reward_status` 仅表示单个奖励项到账状态；不得拿它替代页面级 `reward_settlement_status`
- UI 不再使用：`session_reward_status`、`reward_settlement_last_status` 这类平行命名

### 1.8 统一阻塞标记（本轮 patch 新增）
以下标记在相关页面中含义固定：
- **Pending Decision**：规则仍未被 Room 1 / Room 3 / Room 2 正式冻结
- **Final backend truth required**：最终展示必须以后端状态为准
- **UI must not infer by itself**：UI 不得仅凭前端计数、进入页面、按钮点击或倒计时结束自行推断业务完成

---

## 2. 全局信息架构与跳转关系

### 2.1 主机制关键链路
1. 打开 App
2. 进入今日页
3. 完成签到（若未签）
4. 去学新词 or 去复习
5. 完成一轮有效学习
6. 进入主机制结算浮层
7. 返回今日页 or 进入副机制承接页

### 2.2 首次链路（主机制侧）
1. 登录 / 游客进入
2. 选词库 / 目标
3. 进入今日页
4. 首轮新词学习
5. 主机制结算浮层
6. 结算后可引导进入喵喵主页（不强制）

### 2.3 与副机制的界面边界
- 今日页：只显示 **猫猫摘要卡 / 入口**，不展开喂猫与装扮操作
- 主机制结算浮层：可以展示副机制奖励结果，但不在此完成副机制深操作
- 主机制页面里不出现复杂喂猫、装扮、商店流


### 2.4 跨页面统一兜底状态（本轮 patch 新增）
以下兜底态在关键页面中应保持同一口径：
1. **同步失败兜底态**
   - 允许展示：`记录仍在同步中` / `稍后刷新补齐` / `可重试`
   - 禁止展示：把未同步成功写成已成功到账 / 已完成
2. **升级 / 解锁态**
   - 仅在后端已确认可展示时，才允许使用“已升级 / 已解锁”
   - 若只是前端预展示或等待异步确认，只能使用中性承接语，如：`可去看看今天的变化`
3. **本轮完成 / 本组完成 vs 今日完成**
   - 本轮完成：只描述当前学习轮次 / 当前复习组 / 当前签到动作 / 当前 Session 状态。
   - `本组完成` 只表示当前 `review_group_id` 的 group completion，只推进今日复习进度，不自动等于今日复习完成。
   - 今日完成：只在 `daily_goal_status=completed` 时允许使用。
4. **`check_in` / `learning_day` / `streak` 三类事实**
   - `check_in` 只表示签到事实成立。
   - `learning_day` 表示当日满足后端口径的有效学习事实成立。
   - 当前 MVP 下 `streak` 按 `check_in` 延续。
   - `check_in=true` 不自动等于 `learning_day=true`；`learning_day=true` 也不自动等于 `streak` 延续。
   - 三类自然日口径统一按用户时区折算后的 `local_date` 处理；**Final backend truth required; UI must not infer by itself**。
5. **Session started / ended / valid / invalid**
   - 倒计时开始 ≠ 已完成有效学习
   - 倒计时结束 ≠ valid session completed
   - 必须等 `session_validation_status` 最终返回
6. **迁移窗口 / read-model rebuild / 只读降级**
   - 若 Today / Secondary / Customize 相关链路不能保证同源一致，接口必须显式返回：`sync_status=delayed`、`maintenance=true`、`read_only=true`、`temporarily_unavailable=true` 或等价语义。
   - UI 允许展示最后可信 snapshot，但必须显式标注它仍是“同步中 / 只读中 / 维护中”的受限状态。
   - `displayed snapshot` ≠ `fresh backend truth`；禁止把旧快照写成“刚刚已完成 / 已到账 / 已刷新成功”。
   - 写操作若被暂停，按钮必须进入禁用或只读态，并给出中性原因提示；不得只抛 generic error。

### 2.5 Persistence hardening 受影响页附录（本轮 patch 新增）
- 本轮不重写副机制完整页面稿，但正式补充以下受影响页的 migration / degraded-state 契约：
  1. Today
  2. Meow Home
  3. Customize
- 若 Room 1 未 pin Option A 或未 pin相关内部契约，本稿中的 persistence hardening 相关条目均按 **sync patch 候选** 处理，不自动视为 active UI 基线。
- 本轮不新增账号绑定向导、数据恢复向导、多端迁移提示页；仅处理迁移窗口内的状态表达与写操作降级。

### 2.6 统计页范围说明（本轮 patch 新增）
- 主机制 PRD 包含“学习统计基础能力”，但本轮 Room 5 handoff 的正式交付范围仍是 6 个关键页面
- 因此本稿保留统计入口，但不展开完整统计页页面稿
- 该缺口不阻塞当前 patch；是否在下一轮补极简统计页规格，需由 Room 1 明确 pin

---

## 3. 页面一：今日页

### A. 页面目标
让用户在 3 秒内知道：
- 今天还有什么要做
- 先做哪件事最合适
- 自己当前是未开始、部分完成还是已完成

### B. 页面入口
- App 打开后的默认落点
- 学习完成结算后返回落点
- 从底部导航 / 首页入口进入

### C. 页面退出路径
- 去新词学习页
- 去复习页
- 打开签到页 / 展开签到层
- 进入 Session 入口
- 进入统计页（弱入口）
- 进入副机制承接页（弱入口）

### D. 页面结构说明
#### D1 顶部区
- 今日问候
- 当前词库名称
- 日期 / streak 简报
- 若 API 提供，可弱展示今日 `learning_day` 状态（仅独立事实，不与签到合并表达）
- 弱化的设置入口

#### D2 核心任务卡（最高优先级）
- 今日新词目标：目标值 / 已完成值 / 当前状态
- 今日复习目标：待复习数 / 已完成值 / 当前状态
- 今日总状态标签：未开始 / 部分完成 / 已完成
- 主 CTA：
  - 未开始时：`开始今日学习`
  - 若存在 active `review_group` 且当前应继续复习时：`继续本组复习`
  - 无 active group 但有待复习且优先级更高时：`先去复习`
  - 部分完成时：`继续完成今日目标`
  - 已完成时：`再学一点`（次级语义，不等同新任务）

#### D3 Session 区块
- 15 分钟 Session 入口
- 今日 Session 状态摘要
- 当前是否已完成有效 Session

#### D4 签到区块
- 今日是否已签到
- 当前 streak
- 最近节点奖励预览
- 入口：展开签到页 / 签到层

#### D5 副机制摘要区（弱于任务卡）
- 猫猫今日状态简报
- 今日通过学习拿到的奖励摘要
- 进入喵喵主页入口

#### D6 辅助信息区
- 统计入口
- 同步状态 / 异常提示（仅在有问题时出现）

### E. 核心操作
1. 开始新词学习
2. 开始复习
3. 启动 Session
4. 完成签到
5. 进入副机制承接页（弱入口）

### F. 状态矩阵
#### F1 正常态
- 新词目标、复习目标、签到状态、Session 状态都可见
- 一个主 CTA 明确突出

#### F2 空态
- 当前无待复习、今日目标极低或已清空时：
  - 展示“今天这一部分已经清掉了”
  - 仍给出“再学一点 / 去统计页 / 去看看喵喵变化”的弱动作
- 不能把“复习为空”自动写成“今日任务完成”

#### F3 loading
- 首次进入加载：
  - 骨架屏覆盖顶部摘要 + 核心任务卡 + 签到区块
- 局部刷新时：
  - 只在对应卡片内 loading，不整页抖动

#### F4 异常态
- 今日数据拉取失败：
  - 显示“今天的学习状态还没同步好”
  - CTA：`重试` / `先进入学习页`
- 不显示错误的完成状态占位

#### F5 首次引导态
- 首次进入时，仅高亮：
  1. 今日任务卡
  2. 开始学习按钮
  3. 签到区块（可第二步提示）
- 不一次性讲所有区块

#### F6 奖励到账态
- 从结算层返回今日页时：
  - 顶部或任务卡上方短暂显示轻提示条
  - 示例：`已记录本轮学习结果` / `奖励状态已刷新`
- 不在今日页重复播放重结算动画

#### F7 部分完成态
- 新词和复习至少一项未满
- 视觉上保留进度条 / 分段完成态
- 文案必须使用：`已完成一部分` / `还差 X` / `继续完成`

#### F8 全部完成态
- 新词目标与复习目标均满足后端完成口径
- 视觉上可以点亮“今日完成”状态
- 但如果 Session 未完成，不能把 Session 也显示为已完成

#### F9 Session 有效 / 无效相关态
- 若今日已完成有效 Session：Session 卡显示完成标记
- 若用户只是开启过但无效：显示“本次未计入有效 Session”或更温和的中性文案

#### F10 签到相关态
- 未签到：按钮可点
- 已签到：显示“今日已签到”与签到结果
- 连签节点日：额外显示节点奖励提示
- 若节点奖励仍在结算中，需显示 `reward_settlement_status=pending/settling` 对应中性提示，不可默认到账成功

#### F11 迁移 / 维护 / 只读相关态（本轮 patch 新增）
- 若 `sync_status=delayed`：允许展示最后可信今日聚合，但需在辅助信息区明确标注“同步中 / 稍后刷新补齐”。
- 若 `read_only=true`：Today 允许浏览，但被暂停的写动作入口需进入禁用态或改为中性说明入口；不得看起来像可提交。
- 若 `maintenance=true`：页面可保留只读摘要，但需把系统窗口状态写清楚，不得误写为“今天已刷新成功”。
- 若 `temporarily_unavailable=true`：只影响对应功能卡或按钮，不整页升级为灾难态；主学习链路优先保留，无法保留时才给出中性重试提示。
- 今日页在迁移窗口中不得把旧 snapshot 写成“刚刚已完成 / 已到账 / 已刷新成功”。

### G. 文案边界
- 禁止把“进入了学习页”写成“今天开始学习了”
- 禁止把“新词完成但复习未完成”写成“今日任务完成”
- 禁止把“签到成功”写成“今天又成长了很多”
- 禁止把“签到成功”写成“完成有效学习日”
- 允许分别展示“今日已签到”“今日有有效学习”“当前 streak”，但三者不得互相偷代
- 猫猫摘要仅表达陪伴，不表达学习事实判定
- 主 CTA 的优先级展示可以依赖后端返回，但 CTA winner 的最终仲裁仍属 **Pending Decision**；**Final backend truth required; UI must not infer by itself**
- 若展示的是最后可信 snapshot，必须让用户知道它是“同步中 / 只读中 / 维护中”的受限状态，不得伪装成 fresh truth

### H. 关键字段依赖
- current_book_name
- today_new_target
- today_new_completed
- today_review_target / today_review_pending / today_review_completed
- daily_goal_status
- has_checked_in_today
- current_streak
- streak_node_reward_preview
- active_review_group_id (optional)
- active_review_group_status / active_review_group_remaining (optional)
- learning_day_today / has_learning_day_today (optional)
- streak_basis_type(optional, if API exposed)
- session_valid_today / session_started_today
- last_reward_settlement.reward_settlement_status
- cat_summary_brief
- sync_status
- maintenance (optional, if API/internal contract exposed to UI)
- read_only (optional, if API/internal contract exposed to UI)
- temporarily_unavailable (optional, if API/internal contract exposed to UI)

### I. 待 Room 1 / 2 / 3 对齐点
1. 主 CTA winner 的详细仲裁规则（何时 `继续本组复习` / `先去复习` / `开始今日学习`）
   - **Pending Decision**
   - **Final backend truth required**
   - **UI must not infer by itself**
2. 若今日页聚合返回 active `review_group`，最小字段集合是否固定为 `group_status / remaining / completed`
   - **Pending Decision**
   - **Final backend truth required**
3. 节点奖励是否同步进入 RewardLedger 以及今日页摘要是否需要单列到账态
   - **Pending Decision**
4. 若 Option A 被 Room 1 pin，Today 页用于迁移窗口降级展示的最小字段集合是否固定包含 `sync_status / maintenance / read_only / temporarily_unavailable`
   - **Sync Decision Needed**
   - **Final backend truth required**
### J. 给 Room 4 的实现提示
- 今日页主 CTA 只能由状态机决定，不能前端写死
- “部分完成 / 已完成”必须吃后端口径，不允许仅按前端计数拼装
- 奖励到账提示应支持延迟到账与刷新补齐
- 若只拿到最近一次结算摘要，UI 只能显示 `last_reward_settlement.reward_settlement_status` 对应的中性反馈，不得倒推出全部奖励已到账
- 若进入 migration / maintenance / read_only 窗口，Today 必须优先保留最小可用学习信息；无法写入的入口应显式降级，而不是靠 generic error 收口

### K. 不可随意改动
- 主 CTA 层级
- 部分完成 / 已完成的严格区分
- 今日页中副机制入口只能做弱入口

---

## 4. 页面二：新词学习页

### A. 页面目标
以最低阻力完成新词学习，持续给用户清楚的进度感，不让非必要信息打断学习。

### B. 页面入口
- 今日页主 CTA
- 新用户首次学习链路
- 结算后继续学习入口（若存在）

### C. 页面退出路径
- 学习完成 → 主机制结算浮层
- 用户主动退出 → 返回今日页（需有确认或保存机制）
- 中断后返回 → 今日页

### D. 页面结构说明
#### D1 顶部区
- 返回按钮
- 当前进度（例如 4/20）
- 轻量进度条
- 可选：当前 Session 标识（若由 Session 内进入）

#### D2 单词主卡区
- 单词
- 音标
- 发音按钮
- 中文释义
- 例句（MVP 可折叠）

#### D3 操作区（最高优先）
- `认识`
- `不认识`
- `稍后复习` / 等价标记

#### D4 辅助区
- 当前剩余数量
- 轻量鼓励提示（仅不打断时显示）

### E. 核心操作
1. 播放发音
2. 提交当前单词学习结果
3. 继续下一个单词
4. 中断并退出

### F. 状态矩阵
#### F1 正常态
- 单词卡完整可见
- 三个操作按钮固定在下方，位置稳定
- 点击后立刻过渡到下一词或完成态

#### F2 空态
- 无新词可学时，不停留此页
- 直接引导回今日页或进入结算态

#### F3 loading
- 拉取下一词时只替换单词卡局部
- 避免整页闪烁

#### F4 异常态
- 当前单词提交失败：
  - 显示顶部非阻断提示或卡片内错误提示
  - 提供 `重试`
- 下一词拉取失败：
  - 保持当前页，不伪装成已完成

#### F5 首次引导态
- 只讲 2 件事：
  1. 看词卡信息
  2. 通过操作按钮标记掌握情况
- 不讲副机制、不讲复杂系统

#### F6 奖励到账态
- 单词级操作不即时展示货币飘字
- 奖励统一在结算层承接
- 可允许极轻量反馈，例如完成 5 个词时猫猫小动作提示，但不可打断

#### F7 部分完成态
- 该页内体现为：今日新词进度仍未满
- 只通过顶部进度体现，不写“部分完成”大标题

#### F8 全部完成态
- 达到新词目标后，进入完成过渡，不留在最后一词停滞
- 若复习还未完成，结算层不能写“今日全部完成”

#### F9 Session 有效 / 无效相关态
- 若在 Session 内学习：页头可弱展示“Session 进行中”
- Session 是否有效不在此页做最终宣告

### G. 文案边界
- “认识 / 不认识”只是学习行为结果，不等于掌握事实
- 不允许把单次点击写成“已掌握”
- 不允许在单词级别弹出过多奖励文案打断学习

### H. 关键字段依赖
- word_id
- word_text
- phonetic
- meaning
- example_sentence
- audio_url
- progress_current
- progress_target
- action_result
- session_id (optional)
- submit_status

### I. 待 Room 1 / 2 / 3 对齐点
1. `稍后复习` 是否直接进入复习池、如何命名
2. 单次学习行为何时记为 `effective_learning`
3. 新词目标满额后，是否仍允许“继续学下一批”或必须先回结算

### J. 给 Room 4 的实现提示
- 操作按钮位置固定，不因字数变化跳动
- 提交与翻页必须做幂等保护，避免重复点击导致重复记录
- 提交失败时，当前单词状态不可丢

### K. 不可随意改动
- 单词主卡信息层级
- 底部三个核心按钮层级
- 奖励不在学习中段大面积插入

---

## 5. 页面三：复习页

### A. 页面目标
让用户明确知道今天有哪些需要复习，并且完成一组复习后获得清楚反馈，不被不必要的装饰打断。

### B. 页面入口
- 今日页复习 CTA
- 复习提醒入口
- Session 内的复习场景（若存在）

### C. 页面退出路径
- 完成一组复习 → 结算浮层或组内结果反馈后回今日页
- 主动退出 → 返回今日页

### D. 页面结构说明
#### D1 顶部区
- 返回按钮
- 今日复习进度
- 待复习数量

#### D2 题目区
- 题干（如单词 / 释义 / 选择项）
- 选项区 / 输入区
- 当前题序

#### D3 结果反馈区
- 当前题是否答对
- 下一题按钮

#### D4 底部辅助区
- 当前组剩余题数
- 若在 Session 中，显示 Session 进行中弱提示

### E. 核心操作
1. 选择答案 / 提交答案
2. 查看结果反馈
3. 进入下一题
4. 完成一组复习

### F. 状态矩阵
#### F1 正常态
- 当前题、选项、进度清楚
- 提交 → 反馈 → 下一题节奏明确

#### F2 空态
- 今日无待复习：
  - 不进入空白题页
  - 直接提示“今天待复习内容已清空”
  - 返回今日页

#### F3 loading
- 拉题中骨架屏仅替换题目区
- 答案提交中禁用重复提交

#### F4 异常态
- 提交失败：保留当前题，允许重试
- 拉题失败：提示刷新，不误报完成

#### F5 首次引导态
- 只提示“做完这一组会更新今日复习进度”
- 若当前为恢复中的 active group，可用“继续本组复习”表达
- 不引入额外系统说明

#### F6 奖励到账态
- 组完成后不在题中段发大量奖励动画
- 统一在组完成结果或结算浮层承接

#### F7 部分完成态
- 今日复习有总量时，完成一部分后返回今日页显示部分完成
- 本页内以“本组已完成 / 今日仍未完成”区分

#### F8 全部完成态
- 仅当今日复习口径满足后端完成条件时，今日页可显示复习完成
- 本页完成一组不等于今日复习必然完成

#### F9 Session 有效 / 无效相关态
- 若在 Session 内：只显示进行中，不在本页判断是否有效完成

### G. 文案边界
- “答对了”不等于“已经掌握”
- “本组完成”不等于“今日复习完成”
- 若今天没有待复习，不写成“你今天复习完成了全部计划”，除非业务口径允许
- 若当前组完成，也只能表达当前 group completion，不得把组完成偷写成今日复习完成

### H. 关键字段依赖
- review_queue_count
- review_group_id
- group_status(optional)
- group_completed(optional)
- group_size_total / group_size_remaining(optional)
- review_item_id
- question_type
- options / answer_input_schema
- is_correct
- review_progress_current
- review_progress_target
- submit_status
- session_id (optional)

### I. 待 Room 1 / 2 / 3 对齐点
1. `review_group` 的 group size / 分组算法 / review priority / 题型比例仍未冻结
   - **Pending Decision**
2. 当待复习为空时，在日目标里算不算自然满足
   - **Pending Decision**
   - **Final backend truth required**
3. 复习题型 MVP 最小集合
   - **Pending Decision**
### J. 给 Room 4 的实现提示
- 题目提交必须防重复
- 错误态不能吞题
- active group 恢复时不得并行生成多个“当前组”视图
- 组完成和日完成必须分两层状态输出

### K. 不可随意改动
- 题目→反馈→下一题的节奏
- 本组完成 / 今日完成的双层口径

---

## 6. 页面四：主机制结算浮层

### A. 页面目标
把一轮有效学习结果清楚地告诉用户，并给出明确下一步：回今日页、继续学习、或去看喵喵变化。

### B. 页面入口
- 新词学习完成后
- 复习完成后
- 有效 Session 完成后
- 今日目标完成后

### C. 页面退出路径
- 返回今日页（默认主路径）
- 去喵喵主页（副机制承接）
- 继续学习（当主机制仍未完成时可出现）

### D. 页面结构说明
#### D1 标题区
- 中性结果标题
- 根据真实状态展示：
  - `本轮学习已记录`
  - `新词学习已完成`
  - `本轮复习已完成`
  - `今日目标已完成`（仅在业务口径满足时）

#### D2 结果摘要区
- 本轮完成了什么
- 今日进度更新到了哪里
- 是否完成有效 Session

#### D3 奖励展示区
- Coins
- Fish Treats
- EXP
- 奖励到账状态：到账 / 待补齐 / 失败待重试
- 页面级统一吃 `reward_settlement_status`；若展示单个奖励项到账结果，则使用 `reward_items[].reward_status`，不得混名

#### D4 成长 / 承接区
- 若有副机制奖励或成长变化，展示轻量摘要
- 例如：`喵喵收到了新的小鱼干`、`可去看看今天的变化`
- 仅做承接，不展开副机制深操作
- 若成长/解锁尚待后端确认，只能显示中性承接语，不可直接写“已升级 / 已解锁”

#### D5 操作区
主按钮按优先级动态切换：
1. 主路径优先：`返回今日页` / `继续完成今日目标`
2. 次路径：`去看看喵喵`
3. 关闭入口

### E. 核心操作
1. 看本轮结果
2. 确认奖励到账情况
3. 返回今日页或继续学习
4. 去副机制承接页

### F. 状态矩阵
#### F1 正常态
- 结果、奖励、下一步都明确
- 主按钮只给一个最强方向

#### F2 空态
- 理论上不应出现纯空态
- 若无可展示奖励，也必须展示“本轮结果已记录”与进度变化

#### F3 loading
- 奖励结算中：
  - 标题可显示 `正在同步本轮结果`
  - 奖励区 skeleton / loading
- 不能先显示完整到账再回滚

#### F4 异常态
- 结算失败：
  - 显示“本轮学习已记录，奖励仍在补齐中”或“奖励同步失败，可重试”
  - 提供 `重试` / `返回今日页`
- 不把失败态伪装成成功到账

#### F5 首次引导态
- 首轮结算时，可多一句提示：`学完会在这里看到本轮结果`
- 不做长教学

#### F6 奖励到账态
- 明确展示：到账成功 / 待到账 / 失败待补偿
- 若只是前端预展示，文案必须中性，不可写死“已获得”
- `reward_settlement_status` 只表示本次结算链整体状态；若部分奖励项仍 pending，UI 需按 item 层状态展示，不得自动并入整体成功

#### F7 部分完成态
- 当本轮只完成新词或复习一部分时：
  - 标题不可写“今日完成”
  - CTA 应偏向 `继续完成今日目标`

#### F8 全部完成态
- 仅当今日目标后端判定为完成时，才允许使用“今日目标已完成”标题与视觉强化

#### F9 Session 有效 / 无效相关态
- 有效 Session：展示本次有效 Session 完成结果
- 无效 Session：不发 Session 奖励，标题只能写“本轮学习已记录”，不能写“Session 完成”

#### F10 升级 / 解锁态
- 仅当后端已确认成长结果时，允许展示升级 / 解锁结果
- 若成长结果仍在异步确认，只能展示“可去看看今天的变化”

#### F11 同步失败兜底态
- 若 source event 已成立但奖励仍未写入完成：
  - 显示“本轮学习已记录，奖励仍在同步中”
  - 提供 `刷新状态` / `返回今日页`
- **Final backend truth required; UI must not infer by itself**

### G. 文案边界
- “奖励展示”与“奖励到账”必须分开表达能力
- “今天完成了”只能用于 `daily_goal_status=completed`
- “升级了 / 解锁了 / 获得了”这类高风险词，若涉及后端异步确认，必须由 Room 1 / 3 再确认
- `Session ended` 不能写成 `valid session completed`；必须等 `session_validation_status` 最终返回

### H. 关键字段依赖
- settlement_source_type
- effective_learning_count
- effective_review_count
- daily_goal_status
- session_validation_status
- reward_items[]
- reward_settlement_status
- cat_growth_summary(optional)
- jump_targets_available

### I. 待 Room 1 / 2 / 3 对齐点
1. 奖励到账失败时，是否允许只显示“稍后补齐”而不提供重试按钮
   - **Pending Decision**
   - **Final backend truth required**
2. 哪些 source_type 应合并为一套结算样式，哪些要区分
   - **Pending Decision**
3. 若存在 `review_group_completed` 作为 source type，结算层是否展示“本组完成”标签或只展示更中性的“本轮复习已记录”
   - **Pending Decision**
### J. 给 Room 4 的实现提示
- 结算层必须能处理异步到账与补偿
- 同一 source_event 不可重复展示为多次成功发奖
- 主 CTA 由状态决定，不能静态写死
- 结算浮层只消费后端返回的 `reward_settlement_status` / `reward_items[].reward_status`，不得因前端展示动画先后自行判定到账成功

### K. 不可随意改动
- 结算层主按钮优先级
- 今日完成与本轮完成的区分
- 奖励到账状态的真实表达

---

## 7. 页面五：签到区块 / 签到页

### A. 页面目标
用很低的交互成本完成签到，并让用户知道 streak 与节点奖励状态，但不让签到喧宾夺主。

### B. 页面入口
- 今日页签到区块
- 可展开为轻弹层或独立页

### C. 页面退出路径
- 签到完成后回今日页
- 查看节点奖励后关闭

### D. 页面结构说明
#### D1 简版区块（默认）
- 今日签到状态
- streak 数
- 按钮：`立即签到`
- 下一个节点奖励预告

#### D2 展开层 / 独立页
- 月历 / 猫爪印式签到记录
- 已签到日期
- 当前 streak
- 节点奖励列表（3/7/14/30）
- 今日奖励结果
- 若 API 提供，可弱展示今日 `learning_day` 状态（独立事实，不与签到结果合并）

### E. 核心操作
1. 今日签到
2. 查看 streak 与节点奖励
3. 关闭返回

### F. 状态矩阵
#### F1 正常态
- 未签到时按钮明显可点
- 已签到时按钮替换为结果态

#### F2 空态
- 理论上不需要纯空态
- 若历史记录未拉到，显示骨架或 loading，而非空白

#### F3 loading
- 签到提交中禁用按钮
- 月历数据加载中显示骨架

#### F4 异常态
- 签到失败：显示中性提示 + 重试
- 历史数据失败：保留今日签到入口，不影响主流程

#### F5 首次引导态
- 首次只提示“每天打开可先签到领取基础奖励”
- 不长篇讲规则

#### F6 奖励到账态
- 签到成功后展示基础奖励
- 如遇节点奖励日，额外展示节点奖励
- 若节点奖励待到账，要单独标注，不可默认成功
- 签到页只展示签到事件及其奖励状态；`learning_day` 若要展示，必须作为独立事实单列，不得由签到成功外推出

#### F7 签到已完成 / 未完成 / 节点奖励态
- 未完成：按钮可点
- 已完成：显示“今日已签到”
- 节点奖励态：显示“连续第 X 天奖励”

#### F8 部分完成 / 全部完成关系态
- 签到成功不代表今日目标完成
- 页面与文案必须显式分开
- 签到成功也不代表已构成有效学习日或 `learning_day`
- 当前 MVP 下 `streak` 可按签到延续；但这不代表当日已发生有效学习

#### F9 Session 有效 / 无效相关态
- 无直接关系，不在签到页混入 Session 结论

### G. 文案边界
- 签到只能表达“签到成功 / 奖励到账 / 连签进度”
- 不能表达成“今日学习已完成”
- 不能把 streak 中断写成责备文案
- 允许分别展示 `check_in`、`learning_day`、`streak`，但必须独立标注；不得互相偷代
- 当前 MVP 下 `streak` 按 `check_in` 延续；**Final backend truth required; UI must not infer by itself**

### H. 关键字段依赖
- has_checked_in_today
- learning_day_today / has_learning_day_today(optional)
- current_streak
- streak_basis_type(optional, if API exposed)
- max_streak(optional)
- node_reward.reward_settlement_status (or equivalent check-in reward settlement field)
- monthly_checkin_records[] (if provided in later API; current patch 不要求 Room 4 以此阻塞)
- checkin_submit_status
- local_date / timezone(optional for display-safe diagnostics)

### I. 待 Room 1 / 2 / 3 对齐点
1. 节点奖励是否同步进入 RewardLedger
   - **Pending Decision**
2. 若 API 不返回 `learning_day_today`，签到页是否完全不展示学习日事实，还是仅在今日页展示
   - **Pending Decision**
3. 月历历史字段与 local_date 诊断字段的最小返回集合
   - **Pending Decision**
### J. 给 Room 4 的实现提示
- 签到按钮必须防重复点击
- 节点奖励发放要与普通签到区分来源事件
- 若 `check_in=true` 且 `learning_day=false`，UI 仍只展示“今日已签到”与 streak 结果，不得补写有效学习日
- 若 `learning_day=true` 且 `check_in=false`，UI 不得补写今日已签到；当前 MVP 下 streak 也不得因此延续
- 月历拉取失败不应影响今日签到主入口
- 若 API 当前仅返回 `node_reward.reward_settlement_status` 而未返回完整月历历史，UI 需降级展示，不得因缺月历而阻塞签到主路径

### K. 不可随意改动
- 签到成功 ≠ 今日任务完成
- 签到成功 ≠ `learning_day`
- `learning_day` 成立 ≠ 当前 MVP 下 streak 必然延续
- 节点奖励态必须独立表达

---

## 8. 页面六：Session 入口与完成反馈

### A. 页面目标
降低开始学习门槛，让用户愿意先开一个 15 分钟 Session；同时清楚区分“已开始”“已结束”“有效完成”“无效完成”。

### B. 页面入口
- 今日页 Session 区块
- 学习页/复习页进入时的 Session 模式（可选）

### C. 页面退出路径
- Session 结束 → 完成反馈层 / 并入主机制结算浮层
- 放弃 Session → 回今日页

### D. 页面结构说明
#### D1 入口态
- 标题：15 分钟专注学习
- 说明：只学一小会儿也可以
- 主按钮：`开始 Session`
- 弱说明：完成有效 Session 后可进入奖励结算（不写死到账）

#### D2 进行中态
- 倒计时
- 当前学习行为计数摘要（如：已学新词 X / 已复习 Y）
- 退出或放弃入口

#### D3 完成反馈态
- 显示 Session 已结束
- 明确区分：
  - 已结束待校验
  - 有效完成
  - 无效完成
- 若有效，则引导进入主机制结算层
- 若无效，则引导回今日页继续学习
- 已 started / ended 但仍待校验时，只能显示中性状态，不可提前宣告 valid

### E. 核心操作
1. 开始 Session
2. 在 Session 内完成学习行为
3. 结束或中断 Session
4. 查看 Session 结果

### F. 状态矩阵
#### F1 正常态
- 入口清楚
- 开始后倒计时与进行中状态明确

#### F2 空态
- 若今天已完成有效 Session，可显示“今天这项已完成”而不是空白

#### F3 loading
- 开始时 loading
- 结束后进入待校验 loading

#### F4 异常态
- Session 启动失败：重试
- Session 结束提交失败：显示“记录仍在同步中”
- 不直接把失败写成无效完成
- 若校验结果未回到客户端，保持 `validating / pending` 呈现，不得自动落到 valid / invalid

#### F5 首次引导态
- 首次只解释：
  - 先开始一小段学习
  - 不是只开计时就算完成

#### F6 奖励到账态
- 只有有效完成后才允许展示 Session 奖励结果
- 无效完成不能展示鱼干等奖励
- Session 页面展示奖励时，页面级仍统一吃 `reward_settlement_status`，不得使用 `session_reward_status` 私有命名

#### F7 部分完成态
- Session 已开始但未达到有效条件：
  - 显示“本次还未计入有效 Session”
  - 不等于失败学习

#### F8 全部完成态
- 这里的“完成”只指 Session 本身，不等于今日任务全部完成

#### F9 Session 有效完成态
- 显示有效完成标签
- 允许进入结算层

#### F10 Session 无效完成态
- 显示中性说明：如“这次还没达到有效 Session 条件”
- CTA：`继续学习` / `返回今日页`

#### F11 同步失败兜底态
- Session source event 已成立但结算未完成：
  - 显示“本次记录已保存，奖励仍在同步中”
  - 提供 `刷新状态` / `返回今日页`
- **Final backend truth required; UI must not infer by itself**

### G. 文案边界
- “开始 Session”不等于“开始有效学习”
- “倒计时结束”不等于“有效 Session 完成”
- 无效完成不能写成失败或责备
- `started / ended / validating / valid / invalid` 必须按后端状态展示；UI 不得仅按倒计时自行跳态

### H. 关键字段依赖
- session_id
- session_duration_seconds
- session_started_at
- session_ended_at
- effective_learning_count
- effective_review_count
- session_validation_status
- reward_settlement_status

### I. 待 Room 1 / 2 / 3 对齐点
1. 是否允许用户提前结束仍进入“待校验”
   - **Pending Decision**
   - **Final backend truth required**
2. Session 奖励是否总是并入主机制结算层展示
   - **Pending Decision**
3. 若 Session 已 valid，但今日目标仍未完成，完成反馈层的主 CTA 是否优先继续主目标
   - **Pending Decision**
### J. 给 Room 4 的实现提示
- Session 必须拆分 `started / ended / validating / valid / invalid`
- 只跑倒计时不能直接视为 valid
- 无效完成文案必须中性，不能做惩罚体验
- Session 奖励展示必须依赖 `reward_settlement_status`，而不是前端私有状态名

### K. 不可随意改动
- Started ≠ Valid Completed
- Session 奖励只在 valid 条件下展示

---

## 9. 跨页面统一组件建议（供 Room 4 / 后续视觉稿参考）

### 9.1 任务状态标签
统一采用：
- 未开始
- 进行中
- 部分完成
- 已完成
- 待确认 / 待补齐（仅异步场景）

### 9.2 奖励展示组件
统一字段：
- 页面级：`reward_settlement_status`
- 奖励项级：`reward_items[].reward_status`
- `reward_type`
- `reward_amount`
- `settlement_source_type` / `source_event_type`

统一表现：
- 页面级结算成功：允许展示整体到账完成
- 页面级待到账 / 待补齐：弱化 + 中性说明
- 奖励项级 pending：只表示该 item 仍待到账，不代表整页失败
- 失败：警示但不惊吓

### 9.3 错误提示组件
- 优先用轻提示条 / 局部提示
- 不轻易整页打断
- 学习中错误尽量不吞当前进度

### 9.4 首次引导组件
- 一页不超过 2 个提示点
- 引导只讲当前动作，不讲整个系统

---


## 9.5 UI 字段 → API 字段 → DB 来源（最小对齐表）

| UI 使用名 | API 字段建议 | DB 来源建议 |
|---|---|---|
| `daily_goal_status` | `daily_goal.daily_goal_status` / 等价聚合字段 | `daily_goal_progress.goal_status` |
| `session_validation_status` | `session_validation_status` / `last_session_validation_status` | `session_records.validation_status` |
| `reward_settlement_status` | `last_reward_settlement.reward_settlement_status` 或 settlement API 返回字段 | `reward_source_events.settlement_status` |
| `reward_items[].reward_status` | `reward_items[].reward_status` | `reward_ledger.status` / 等价账本状态 |
| `has_checked_in_today` | `check_in.has_checked_in_today` | `check_in_records` |
| `learning_day_today` | `learning_day.learning_day_today` / 等价聚合字段 | `learning_day_facts` |
| `current_streak` | `check_in.current_streak` / `streak.current_streak` | `streak_records.current_streak` |
| `session_valid_today` | `session.session_valid_today` | `daily_goal_progress.valid_session_completed` 或 `session_records` 聚合 |
| `session_started_today` | `session.session_started_today` | `session_records` 聚合 |
| `active_review_group_id` | `review_group.review_group_id` / 等价聚合字段 | `review_groups.id` |
| `active_review_group_remaining` | `review_group.group_size_remaining` / 等价聚合字段 | `review_groups` + `review_group_items` 聚合 |

> 说明：
> 1. 若 API / DB 后续字段名微调，以 Room 1 pin 的 active DB/API 为准。
> 2. UI 只保留一套主命名，不再维护 `session_reward_status` / `reward_settlement_last_status` 之类平行叫法。
## 9.6 Persistence Hardening 受影响页附录（Today / Meow Home / Customize）

> 注：本附录不是完整副机制页面重写，只定义 Option A 迁移窗口里，Room 5 认为必须提前钉住的最小界面契约。

### 9.6.1 适用边界
- 仅当 Room 1 正式 pin Option A 或 Room 4 开始消费相关内部契约时，本附录进入实施参考。
- **这些 migration / degraded-state UI 规则，仅在 Room 1 正式 pin Option A，并进入 cutover / maintenance / degraded-state 实施窗口后，才作为 Room 4 的强实现与强回归断言执行。**
- 在此之前，当前 runtime active UI baseline 仍是 `UI_SPEC_v0.1.2.md`；本附录仅作为 sync patch 候选，不自动升级为现行强基线。
- 本附录不新增账号绑定、新设备迁移、数据恢复向导、多端同步教育弹层。
- 本附录只处理：迁移窗口、只读窗口、read-model rebuild 窗口、同源一致性保护失败时的 UI 降级策略。

### 9.6.2 Meow Home（副机制承接主页）最小契约
#### A. 允许展示
- 最后可信的 `secondary summary`
- 当前可见的 coins / fish treats / exp / cat summary / equipped preview snapshot
- 中性 companion copy，但不得暗示这是 fresh backend truth

#### B. 必须降级的场景
- 若 `sync_status=delayed`：页面可展示最后可信摘要，但需显示“同步中 / 稍后刷新补齐”类中性提示。
- 若 `maintenance=true`：页面允许只读浏览，不允许把余额、成长、装备快照写成“刚刚刷新完成”。
- 若 `read_only=true`：喂猫、购买跳转、装备入口等写动作要么禁用、要么进入中性说明，不得看起来仍可成功提交。
- 若 `temporarily_unavailable=true`：只影响对应按钮或局部卡片，优先保留页面浏览能力。

#### C. 文案边界
- `displayed snapshot` ≠ `fresh backend truth`
- “奖励看见了” ≠ “奖励已到账成功”
- “看起来有成长结果” ≠ “当前状态刚被实时确认”

### 9.6.3 Customize（装扮 / 装备）最小契约
#### A. 允许展示
- catalog / owned / equipped 的最后可信 snapshot
- 已拥有 / 已装备 / 未拥有 三态 UI

#### B. 必须降级的场景
- 若购买 / 装备写操作被暂停：按钮必须进入只读禁用态，并给出“当前只读 / 稍后再试 / 维护中”之类中性提示。
- 若 inventory / equipment summary 正在 rebuild：允许浏览，但不能把旧装备状态写成“已成功切换”。
- 若链路存在混源风险：Customize 不得假装可提交；宁可显式降级为浏览态。

#### C. 文案边界
- “已展示已拥有 / 已装备快照” ≠ “刚刚购买成功 / 刚刚装备成功”
- 降级提示应说明系统窗口状态，不责备用户，不把失败归因于用户没点对

### 9.6.4 Degraded-state 最小可观察结果表（Today / Meow Home / Customize）
> 说明：本表只补“最小可观察结果”，帮助 Room 4 写 migration / degraded-state regression；不扩写新页面、不新增新规则。

| 状态 | Today 最小可观察结果 | Meow Home 最小可观察结果 | Customize 最小可观察结果 | 禁止写成的成功语义 |
|---|---|---|---|---|
| `sync_status=delayed` | 辅助信息区或任务卡下方至少出现“同步中 / 稍后刷新补齐”；允许显示最后可信今日聚合 | 资源区或 companion copy 附近至少出现“同步中 / 稍后刷新补齐”；允许显示最后可信 `secondary summary` | catalog / inventory 可继续展示最后可信 snapshot，但需说明仍在同步中 | `已同步完成` / `刚刚刷新成功` / `已实时更新` |
| `read_only=true` | 被暂停的写动作入口进入禁用态或中性说明入口；Today 仍可浏览摘要 | 喂猫、购买跳转、装备相关写入口禁用或改为只读说明 | 购买 / 装备 / 卸下按钮禁用，并显示“当前只读 / 稍后再试” | `可正常提交` / `已提交成功` / `刚刚改好了` |
| `maintenance=true` | 页面保留只读摘要与必要说明；主链路若受影响必须明确标系统窗口状态 | 允许浏览 cat summary / 余额 / equipped snapshot，但需明确“维护中” | 优先降级为浏览态；若功能暂停，保持内容可见但不允许假提交 | `已恢复正常` / `已刷新完成` / `当前数据已确认最新` |
| `temporarily_unavailable=true` | 仅受影响卡片 / 按钮局部降级；优先不整页打断 | 仅受影响按钮或卡片局部禁用；其余浏览能力优先保留 | 局部功能短时不可用时，优先局部禁用而非整页报错 | `操作已成功` / `只是你没点对` / `系统已经处理完成` |

### 9.6.5 多端 / 数据恢复 / 账号绑定
- 本轮 **不新增** 多端同步提示页。
- 本轮 **不新增** 数据恢复向导或“从旧设备恢复中”流程提示。
- 本轮 **不新增** 账号绑定教育弹层；游客绑定收益仍按主机制 PRD 的既有边界处理，不在本 patch 扩写。
- 若后续 Room 1 明确把“多端同步 / 账号绑定 / 恢复”列为独立产品范围，Room 5 再另起页面稿，不在本稿提前偷扩。

## 10. 当前风险与待对齐清单

### Major
1. 主 CTA winner 的详细仲裁规则仍未冻结
   - **Pending Decision / Final backend truth required / UI must not infer by itself**
2. `review_group` 的 group size / 分组算法 / review priority / 题型比例仍未冻结
   - **Pending Decision / Final backend truth required**
3. 统计页完整规格仍未冻结；当前只保留入口与范围说明
   - **Pending Decision**

### Minor
4. 节点奖励是否同步进入 RewardLedger 仍待下游对齐
   - **Pending Decision**
5. 若 API 暂未返回 `learning_day_today`、`streak_basis_type`、月历历史等字段，签到页需降级展示，但不阻塞签到主路径
6. 未来是否把 `streak` basis 从 `check_in` 改为 `learning_day` 或组合条件，不在当前 v0.1.4 冻结范围内
7. 若 Option A 被 pin，但 API / internal contract 尚未稳定返回 `sync_status / maintenance / read_only / temporarily_unavailable`，Today / Meow Home / Customize 的 migration 降级态仍存在实现歧义
   - **Sync Decision Needed**
## 11. 给 Room 1 的简短吸收建议

建议 Room 1 在 Main / Status 吸收以下内容：
1. Room 5 已提交 `UI_SPEC_v0.1.4.md`，作为吸收 persistence hardening migration / degraded-state 语义的 UI sync patch 候选。
2. 当前 UI 层已正式回写：
   - `review_group` 为最小复习批次对象的界面表达
   - 本组完成只推进今日复习进度，不自动等于今日复习完成
   - `check_in / learning_day / streak` 为三类独立事实，当前 MVP 下 `streak` 按 `check_in` 延续
   - Today / Meow Home / Customize 在 migration / maintenance / read_only 窗口下的最小可用态与文案边界
3. 当前仍未冻结但不阻塞本轮 UI patch 的事项：
   - CTA winner 详细仲裁规则
   - `review_group` 分组算法细节
   - 统计页完整规格
   - 节点奖励与部分辅助字段的 API 返回细节
   - Option A 相关内部契约何时被 Room 1 正式 pin 进 active baseline
## 12. 给 Room 4 的实现交接最小提示

1. 先按本稿搭状态机，再接 API，不要反过来凭页面猜业务。
2. 所有“已完成”展示必须依赖后端事实，不要用前端本地计数兜底成最终态。
3. 奖励到账、延迟到账、失败待补齐，必须至少有 3 态。
4. Session 至少拆成：started / ended / validating / valid / invalid。
5. 今日页必须能回答：
   - 今天还差什么
   - 主 CTA 是什么
   - 当前是部分完成还是全部完成
6. 若 Option A 被 pin，Today / Meow Home / Customize 还必须能回答：
   - 当前是不是 fresh truth，还是 delayed / read_only snapshot
   - 当前按钮为什么不可用
   - 当前是系统窗口降级，还是业务失败

---

## 13. Handoff Packet (Room 5 -> Room 1 / Room 4)

> 注：本 handoff 已按 v0.1.4 review5 absorption patch 更新；结构主干不变，重点是把执行前提写硬，并补 degraded-state 最小观察结果表，不扩写页面范围。

**To:** Room 1 / Room 4  
**CC:** Room 2 / Room 3  
**Decision Needed by:** Room 1

**TL;DR (≤3 lines):**
- Room 5 已提交 `UI_SPEC_v0.1.4.md`，以 `UI_SPEC_v0.1.2.md` 为 base，补 persistence hardening 对 Today / Meow Home / Customize 的 migration / degraded-state 契约，并把其强执行前提写硬。 
- 当前 6 个关键页面范围不变；Meow Home / Customize 只补受影响页附录，不扩成完整新页面稿。  
- 本轮后 UI 明确区分 delayed snapshot / read_only / maintenance 与 fresh truth，不把迁移窗口状态写成成功。

**Key Points (≤3 bullets):**
- 已保留并继承 v0.1.2：`review_group`、`check_in / learning_day / streak` 的已冻结口径。 
- 本轮新增：Today / Meow Home / Customize 在 migration / maintenance / read_only / temporarily_unavailable 窗口下的最小可用态、按钮禁用态与文案边界。 
- 仍保持 pending：CTA winner 详细仲裁规则、`review_group` 分组算法细节、统计页完整规格，以及 Option A 相关内部契约何时被 Room 1 pin 为 active。

**Dependencies (if any; else "None")：**
- Need from Room 1: 是否 pin `UI_SPEC_v0.1.4.md` 为当前 active UI baseline，或至少 pin 其中 persistence hardening sync 附录可供 Room 4 执行  
  Deliverable Spec: 在 Main / Status 中吸收 v0.1.4 为 UI sync patch 候选或 active 版本  
  Deadline: 下一轮
- Need from Room 2: 若 Option A 被推进，请在 API / internal contract 中稳定返回 `sync_status / maintenance / read_only / temporarily_unavailable` 的最小可消费语义  
  Deliverable Spec: 至少保证 Room 4 不需要靠前端猜 delayed snapshot / read_only / maintenance 行为  
  Deadline: implementation-ready technical baseline 下一版
- Need from Room 4: 测试显式覆盖 Today / Meow Home / Customize 的只读降级、同步延迟、写操作暂停与 snapshot 文案边界  
  Deliverable Spec: 纳入 persistence test matrix 与页面状态矩阵  
  Deadline: TEST_PLAN / implementation slices 下一轮
