# R4_to_Cursor_P3_1_Phase1_LocalTruth_Handoff_v0.1.md

- **From:** Room 4 (Eng + QA + Debug Tech Lead)
- **To:** Cursor
- **Project:** 背单词喵喵 App
- **Phase:** P3.1 / Phase 1
- **Goal:** Local settings + local runtime truth
- **Status of this handoff:** prepared in advance; executable when Room 4 confirms Phase 0 close
- **Important:** 你读不到我们项目文档，所以以下内容已经替你补齐。请严格按这份 handoff 执行，不要自行扩写需求。

---

## 0. 这份 handoff 的使用条件

这份是 **下一轮指令**，默认对应：

> **P3.1 / Phase 1 — Local settings + local runtime truth**

请注意：
- 只有在 Room 4 确认 **Phase 0 已通过 / 可 close** 后，你才执行这份 handoff。
- 如果 Phase 0 还没通过，这份 handoff 先不要落代码。

---

## 1. 你这轮要做什么

你现在要做的，是把 P3.1 的**设备侧最小持久化底盘**立起来。

一句话：

> **把轻设置和本地主进度真相层正式落地，让 App 在设备侧具备稳定保存与离线延续能力。**

### 本轮允许做
1. 落地本地轻设置层（DataStore 或项目现有等价本地 KV）
2. 落地本地主进度真相层（SQLite / Room 或项目现有等价本地 DB）
3. 为学习进度相关实体建立最小本地持久化容器
4. 为本地数据读写建立最小 repository / adapter / storage seam
5. 为离线最小闭环建立测试
6. 建立“local runtime truth”与现有主业务事实边界不冲突的回归挡板

### 本轮禁止做
1. 不做 snapshot export
2. 不做 cloud upload
3. 不做 restore
4. 不做 full sync / background sync / multi-device merge
5. 不新增“已备份 / 已同步”用户可见成功流
6. 不反向改写现有主机制奖励、签到、streak、结算规则
7. 不把“设备侧持久化真相”写成“全项目主业务真相源切换完成”

---

## 2. 你必须服从的事实边界

### 2.1 P3.1 当前产品立场
P3.1 正式名称是：

> **Local Progress + Cloud Backup**

当前冻结的方向是：

- **local-first**
- **backup-first**
- **manual backup**
- **不是 full sync**
- **restore 不是第一拍默认范围**

### 2.2 local runtime truth 的准确含义
这里的 **local runtime truth** 指的是：

> **设备侧用户进度持久化真相**

这句话非常重要。你必须按这个理解来实现。

它不等于：
- 全项目主业务真相源已经全部切到本地
- 后端规则失效
- 未来不再需要服务端判断

当前仍然成立的边界：
- 主机制关键业务规则事实，仍服从当前 active BR / active versions
- 设备侧只是先把用户进度、设置、轻离线能力稳住
- 后续 snapshot / upload / restore 都建立在这个设备侧真相层之上

### 2.3 本轮不碰的云端链路
虽然 P3.1 最终包含 cloud backup，但这轮你不要碰：
- upload API
- backup container
- latest backup status UI
- restore
- overwrite safety
- checksum
- versioning 展开实现

这轮只把**本地底盘**做好。

---

## 3. 这轮应该落什么

## 3.1 Local settings lane
请为以下轻设置建立设备侧持久化：

建议最小集合：
- `daily_goal`
- `sound_enabled`
- `theme`
- `notification_time`

要求：
1. 设置层与业务主进度层分开
2. 不把这类轻设置塞进主业务大表
3. 提供最小读取、更新、默认值能力
4. 能支持 App 重启后保留

如果项目现有代码里已经有部分本地设置实现：
- 优先复用
- 不做大规模重写
- 只做最小清理与收口

## 3.2 Local runtime truth lane
请为设备侧用户进度持久化建立最小真相层。

建议第一拍至少覆盖这些实体或等价概念：
- `word_records`
- `wordbook_progress`
- `daily_checkins`
- `custom_wordbooks`
- `vocabulary_notebook`

要求：
1. 结构要能稳定落盘
2. 读写要可测
3. 至少支持 App 重启后仍能读回
4. 不要求这轮把所有未来字段都做满
5. 但要为 Phase 2 的 snapshot export 留出稳定可读的数据源

## 3.3 最小 repository / adapter 层
请不要把本地 DB 读写散落到 UI 层或 action handler 里。

你至少要建立一个最小、可测的抽象层，例如：
- repository
- local data source
- storage adapter
- persistence service

名字按你项目现有风格即可。

目标：
- 让 Phase 2 的 snapshot export 能从统一入口读数据
- 让 Phase 3 的 upload 不直接依赖 UI 状态拼装数据
- 让测试可直接覆盖存取逻辑

---

## 4. 这轮必须写硬的边界

### 4.1 不改写现有主机制语义
P3.1 Phase 1 不能改变以下现有语义：
- `daily_goal_status`
- `session_validation_status`
- `check_in / learning_day / streak` 的当前关系
- 奖励结算与到账语义
- 复习组最小合同

你可以把相关事实在设备侧持久化，但**不能借机改语义**。

### 4.2 不提前做导出语义
这轮不能出现：
- “导出成功”
- “备份成功”
- “已同步”
- “最近一次备份”
- “恢复成功”

因为这轮根本不做 export / upload / restore。

### 4.3 不把本地持久化做成产品主流程中心
这轮不需要让用户可见大量新入口。
如果为调试或开发需要临时有入口：
- 默认隐藏
- debug only
- 或仅内部 seam
不要让它们看起来像正式产品能力。

### 4.4 不做 restore 准备态 UI
restore 是 Phase 4 的 gated future phase。
这轮不要出现：
- restore CTA
- restore empty state
- restore success flow
- restore conflict dialog

---

## 5. 推荐执行顺序

### Step A — 盘点现有本地存储代码
请先识别项目里已有的：
- 本地设置层
- 本地 SQLite / Room / DAO / schema
- 现有 repository / service / storage adapter
- debug-only persistence path

不要上来就重写。先找最小可复用点。

### Step B — 落 local settings
先把轻设置这一层收住，因为它风险最小，也能最快形成设备重启后保留的测试闭环。

### Step C — 落 local runtime truth 最小表/实体
再把用户进度真相层的最小集合落下来。
优先保证：
- 可写入
- 可读取
- 可更新
- App 重启后仍可读回

### Step D — 接到统一 repository / adapter
不要让调用方直接摸底层存储实现。
至少把 Phase 2 以后要复用的数据读取入口预留出来。

### Step E — 补测试并做回归
必须同轮补测试。
不能只交“能跑”的代码。

---

## 6. 你本轮应该补的测试

## A. Local settings persistence tests
覆盖：
1. 默认值读取
2. 设置修改后再次读取正确
3. App 重启模拟后值仍存在
4. 非法值或缺失值时 fallback 正常

## B. Local runtime truth persistence tests
覆盖：
1. `word_records` 或等价实体可写可读
2. `wordbook_progress` 或等价实体可写可读
3. `daily_checkins` 或等价实体可写可读
4. `custom_wordbooks` 或等价实体可写可读
5. `vocabulary_notebook` 或等价实体可写可读

## C. Restart / rehydrate tests
覆盖：
1. 模拟应用重启后，关键数据仍可重新 hydrate
2. 读取顺序不依赖 UI 临时状态
3. 空本地库时能给出稳定默认态，不 crash

## D. Existing flow regression tests
覆盖：
1. Today 现有主链路不受影响
2. 新词 / 复习 / Session / 签到现有流程不被破坏
3. 已有副机制 summary / pet / reward 展示不受影响
4. 不新增错误的“备份成功 / 已同步”表达

## E. Negative tests
覆盖：
1. 本地层异常时不会把业务状态假装成成功
2. 本地空数据不会被误映射成“已完成 / 已恢复”
3. 不会因为引入 local storage 就破坏现有 active baseline 的关键断言

---

## 7. 代码改动原则

### 7.1 允许的改动风格
- very small / small patch
- reuse-first
- seam-first
- test-led
- minimal schema / entity landing
- minimal abstraction

### 7.2 禁止的改动风格
- 大重构
- 一口气把 Phase 1–4 都做了
- 顺手做 snapshot export
- 顺手做 upload API
- 顺手做 restore
- 自己补产品规则
- 因为“以后会用到”就先做复杂 sync engine

---

## 8. 你完成后必须给出的输出

### A. 改动摘要
按文件列出：
- local settings
- local DB / entities / DAO / schema
- repository / adapter
- tests

### B. 边界说明
请明确写：
- 你如何保证这是“设备侧持久化真相”，而不是“主业务真相源切换”
- 你如何保证没有越到 export / upload / restore
- 你如何保护既有 P1 / P2 / Option A/B/C / P3 已 close 链路

### C. 自测结果
至少给出：
- 跑了哪些测试
- 新增多少测试
- 总通过数 / 失败数
- 若有跳过项，说明原因

### D. 明确声明未做项
你必须明确写：
- 未做 snapshot export
- 未做 cloud upload
- 未做 latest backup status
- 未做 restore

---

## 9. Completion bar（Room 4 验收条）

只有同时满足以下条件，我才会判你 Phase 1 通过：

1. local settings 已能稳定持久化
2. local runtime truth 最小集合已可写可读
3. 有统一 repository / adapter / seam，不是散落直连
4. 有 restart / rehydrate 测试
5. 现有主副机制关键链路回归通过
6. 没有偷做 export / upload / restore
7. 没有新增误导性成功语义
8. 有 self-test summary

---

## 10. 最后一句

这轮你要做的不是“把备份做出来”，而是：

> **把“可被导出、可被上传、可被恢复”的本地真相层先稳定落地。**

请按 **small patch + test-led** 风格推进。
