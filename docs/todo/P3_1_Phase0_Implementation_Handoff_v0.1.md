# R4_to_Cursor_P3_1_Phase0_Implementation_Handoff_v0.1.md

- **From:** Room 4 (Eng + QA + Debug Tech Lead)
- **To:** Cursor
- **Project:** 背单词喵喵 App
- **Phase:** P3.1 / Phase 0
- **Goal:** Implementation entry + regression fences
- **Status of this handoff:** executable
- **Important:** 你读不到我们项目文档，所以以下内容已经替你补齐。请严格按这份 handoff 执行，不要自行扩写需求。

---

## 0. 你这轮要做什么

你现在做的不是 P3.1 功能开发本身。

你现在只做：

> **P3.1 的实现入口、回归挡板、成功语义分离、以及“不能误写成云同步系统”的防越界基础层。**

这轮是 **Phase 0**，不是 Phase 1。

### 本轮允许做
1. 建立 P3.1 的工程入口和 feature guard
2. 建立不污染既有主副机制链路的 regression fences
3. 建立 `local export success / upload success / restore success` 三类成功语义的基础断言
4. 建立 P3.1 相关 strict parsing / fallback / hidden-state / disabled-state 的测试入口
5. 为后续 Phase 1–4 预留可扩展 seam，但不能提前把 future phase 做出来

### 本轮禁止做
1. 不做 local runtime truth 真落地
2. 不做 DataStore / SQLite 真实存储实现
3. 不做 snapshot export
4. 不做 upload container
5. 不做 restore
6. 不新增“已同步”文案
7. 不新增任何看起来像“完整恢复流程”的入口
8. 不把 P3.1 候选结构当成当前已生效 runtime truth
9. 不顺手改 P1 / P2 / Option A/B/C / P3 已 close 链路的业务语义

---

## 1. 当前你必须服从的事实边界

### 1.1 产品边界
P3.1 的正式名称是：

> **Local Progress + Cloud Backup**

这一阶段的核心不是 full sync，不是实时双向同步，也不是多端冲突合并。

当前立场是：

- **本地进度优先**
- **用户手动触发备份**
- **云端只是 backup container**
- **不是实时同步系统**
- **restore 不是第一拍默认范围**

### 1.2 语义边界
你必须严格分开以下三类成功：

1. **local export success**
   - 本地快照导出成功
2. **cloud upload success**
   - 备份文件成功上传到云端容器
3. **restore success**
   - 从备份恢复成功

它们三者绝不能混写。

特别注意：

- `local export success != upload success`
- `upload success != sync success`
- `has cloud backup != current device has been restored`
- 未进入 restore phase 前，不能出现 restore complete 语义

### 1.3 真相边界
当前 P3.1 的“local runtime truth”指的是：

> **设备侧用户进度持久化真相**

但这**不等于**项目整体主业务真相源已经切换完成。

也就是说：

- 设备侧进度持久化：未来会由本地承载
- 主机制关键业务规则事实：仍必须服从当前 active BR / active versions
- 云端当前只是 backup container，不是 runtime truth / sync truth

### 1.4 UI 边界
P3.1 的入口应该在：

- 设置页
- 我的页
- 轻支持入口

P3.1 不应该：

- 跑到 Today 主 CTA 中心
- 打断学习主线
- 看起来像“现在已经有完整云同步能力”

未单独 pin 前，以下高风险入口默认只能：

- 隐藏
- 占位
- disabled
- warning / pending

不能成为常规主操作：

- restore
- delete cloud backup
- clear local data

---

## 2. 你可以假定的当前目标

本轮 Phase 0 的目标只有一句话：

> **先把 P3.1 的防越界底座搭起来，让后面的 phase 可以安全进入，而不是一上来就开始做备份功能。**

更白话一点：

- 先把“以后能做什么”和“现在还不能做什么”在代码和测试里写硬
- 先把错误文案和成功文案的混用风险挡住
- 先保证现有 P1 / P2 / Option A/B/C / P3 close 链路不被 P3.1 误伤

---

## 3. 推荐执行顺序

### Step A — 找出现有会被 P3.1 影响的最小入口
请你定位并整理以下最小影响面（不要大面积重构）：

1. 设置页 / 我的页中未来可能承接 backup 入口的位置
2. 当前任何可能会复用“同步 / 成功 / 已完成”语义的展示组件
3. 当前与本地持久化 / loading / disabled / temporarily unavailable 相关的 UI 状态处理点
4. 可能需要新增 feature flag / seam / adapter / placeholder 的位置
5. 测试目录中最适合加 P3.1 regression fences 的位置

你的目标不是马上接线，而是找到**最小侵入点**。

### Step B — 建 P3.1 feature seam / guard
请建立 P3.1 的 feature seam，但不要把真实功能做出来。

建议方向（按你项目现状灵活落地）：

- feature flag
- stub contract
- hidden / disabled entry guard
- placeholder state mapper
- dedicated view-model guard
- backend route guard（如果代码里已有类似模式）

**注意：**
这个 seam 的目的是：
- 让未来 Phase 1–4 有入口
- 让当前 Phase 0 可以写测试
- 不是为了提前把假功能做出来

### Step C — 建立成功语义防混写挡板
请确保代码层或展示层能明确防止以下误写：

- 把 `upload success` 显示成“已同步”
- 把 `has snapshot` 显示成“已恢复”
- 把未来 restore 入口当作已可用功能
- 把本地占位态写成后端已确认成功

如果项目里有统一 copy / state mapping / badge / status label / CTA render 的地方，优先在那里加挡板。

### Step D — 建立 Phase 0 regression fences
请为以下事实建回归挡板：

1. 既有学习主链路不受影响
   - 新词学习
   - 复习
   - 今日目标
   - Session
   - 签到 / streak
   - 主机制结算

2. 既有副机制主链路不被 P3.1 误伤
   - 喵喵主页
   - 喂猫
   - 装扮 / 购买 / 装备
   - 已有 summary / state / reward 展示

3. P3.1 未启用时：
   - 不新增显眼入口
   - 不新增误导文案
   - 不出现 restore 可执行流
   - 不出现“已同步”暗示

### Step E — 补测试
你必须把这轮做成：

> **实现挡板 + 测试挡板一起交付**

---

## 4. 你本轮应该补的测试

请至少覆盖以下测试类别。测试命名可以按项目风格调整，但语义必须覆盖到。

### A. P3.1 feature disabled / hidden state tests
覆盖：
1. P3.1 未启用时，不出现可执行 backup 主入口
2. P3.1 未启用时，不出现 restore 主入口
3. 高风险动作不是默认可点状态
4. 不出现“已同步”文案

### B. Success semantics separation tests
覆盖：
1. `local export success` 不等于 `upload success`
2. `upload success` 不等于 `sync success`
3. `restore success` 未实现前不能被映射出来
4. `has backup record` 不等于 `restore available and completed`

### C. Existing flow regression tests
覆盖：
1. Today 主 CTA 不受 P3.1 影响
2. 主机制结算流不受影响
3. 已有 secondary summary / pet / reward 展示不受影响
4. 签到、learning day、streak 现有语义不被污染

### D. Placeholder / disabled-state tests
覆盖：
1. backup 相关入口若存在，占位文案是中性表达
2. disabled state 不会被用户误读成系统故障或已同步成功
3. restore / delete / clear local 若显示占位，不可执行

### E. Negative tests
覆盖：
1. 不允许从 copy mapping 中出现“已同步”替代“已备份”
2. 不允许出现 restore success flow
3. 不允许出现 fake synced badge
4. 不允许新 route 冒出来承接完整 backup center（若本轮未设计）

---

## 5. 代码改动原则

### 5.1 允许的改动风格
- very small patch
- seam-first
- guard-first
- test-led
- 尽量复用现有 pattern

### 5.2 禁止的改动风格
- 大重构
- 顺手统一全局 copy
- 顺手补完整 backup feature
- 顺手做 restore
- 先做半套 UI 再说
- 自己补业务事实

### 5.3 关于文案
这轮你不要追求“设计最优文案”，只要保证：
- 不误导
- 不越界
- 不把 backup 写成 sync
- 不把 future restore 写成 current success

---

## 6. 本轮交付物要求

你完成后，必须给出以下输出：

### A. 改动摘要
按文件列出你改了什么，分成：
- seams / guards
- UI state handling
- regression fences
- tests

### B. 为什么这样改
简短说明：
- 你如何避免把 P3.1 做成“假同步系统”
- 你如何避免污染既有主副机制链路
- 你如何把成功语义分开

### C. 自测结果
至少给出：
- 跑了哪些测试
- 新增了哪些测试
- 总通过数 / 失败数
- 若有跳过项，说明为什么跳过

### D. 明确声明未做项
你必须明确写：
- 未做 local runtime truth
- 未做 snapshot export
- 未做 upload container
- 未做 restore

---

## 7. Completion bar（Room 4 验收条）

只有同时满足以下条件，我才会判你 Phase 0 通过：

1. 有 P3.1 seam / guard，不是空口说“以后再做”
2. 有明确 regression fences，证明不会误伤既有链路
3. 有 success semantics separation 的测试
4. 没有把 backup 写成 sync
5. 没有把 restore 偷做出来
6. 没有新增误导性的主入口或主文案
7. 有 self-test summary

---

## 8. 最后一句

这轮你要做的不是“把功能做出来”，而是：

> **把以后做功能时最容易越界、最容易误导、最容易污染旧链路的地方，先用代码和测试钉住。**

请按 **very small patch** 风格推进。
