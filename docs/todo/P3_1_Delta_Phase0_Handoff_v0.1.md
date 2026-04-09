# R4_to_Cursor_P3_1_Delta_Phase0_Handoff_v0.1.md

- **From:** Room 4 (Eng + QA + Debug Tech Lead)
- **To:** Cursor
- **Project:** 背单词喵喵 App
- **Stage:** P3.1 direct-scope pin delta
- **Phase:** Phase 0
- **Goal:** Delta entry / guard / regression fence / state semantics hardening
- **Status of this handoff:** executable
- **Important:** 你读不到我们项目文件，所以以下内容已经替你补齐。请严格按这份 handoff 执行，不要自行扩写需求。

---

## 0. 这轮到底在做什么

这轮不是让你直接实现 3 个新增功能本体。

这轮你做的是：

> **先把 P3.1 delta 的入口、挡板、状态语义和回归防线钉住，防止后续实现把“新增范围”误做成“已生效主线”。**

当前新增的 3 个功能是：

1. **从云端下载进度到本机**
2. **上传进度到云端**
3. **设置每日学习单词数量**

但 **Phase 0 不做这些功能本体**。  
Phase 0 只做：**entry / guard / regression fence / semantics hardening**。

---

## 1. 你必须服从的当前事实边界

### 1.1 当前项目状态
当前推进层状态仍然是：

> **P3.1 Reviewing / Restore Gate Pending**

这意味着：
- 这轮 delta 已经被 User / Room 1 拉进当前范围
- 但它**还不是自动生效的 active runtime truth**
- 你不能把这轮 delta note 直接当成已经 pin 进主线的 build baseline

### 1.2 这轮 delta 的本质
这轮不是重开整条 P3.1 主线。  
这是：

> **在已有 P3.1 基线上，吸收 3 个 direct-scope delta 功能。**

所以你不能：
- 重写旧 P3.1 主线
- 推翻旧 phase map
- 把 direct-scope delta 扩成 full sync / restore platform / merge system

### 1.3 当前仍成立的硬边界
你必须继续服从以下边界：

1. **P3.1 仍不是 full sync**
2. **云端当前仍是 backup container，不是 runtime truth / sync truth**
3. **upload / download / restore 都仍然是 manual only**
4. **不做 multi-device merge**
5. **不做 background sync**
6. **不做 delta sync**
7. **不做 silent overwrite**
8. **不做历史日重算**
9. **这 3 个入口不得破坏主学习链路，不得抢 Today 主 CTA**

---

## 2. Phase 0 允许做什么 / 不允许做什么

## 2.1 本轮允许做
1. 新增 3 个 delta feature 的 guard / seam / routing point
2. 新增三层成功语义挡板：
   - `upload success`
   - `download completed`
   - `restore success`
3. 为 daily_goal / upload / download-to-local 建立 feature-flag-like entry / visibility / state fence
4. 建立既有 P3.1 主线不受污染的 regression fences
5. 在 UI state mapping / copy mapping / result typing 里，把最容易误导的表达先钉住
6. 为后续 Phase 1 / 2 / 3 预留可扩展 seam
7. 补测试

## 2.2 本轮禁止做
1. 不做 `daily_goal` 的真正保存逻辑
2. 不做 `upload progress to cloud` 的真正链路打通
3. 不做 `download-to-local / restore apply`
4. 不做 destructive actions：
   - delete backup
   - clear local
5. 不把 delta note 反写成 active baseline
6. 不顺手改主学习链路业务语义
7. 不顺手做 sync center / restore center / backup center 大页面

---

## 3. 这轮最重要的三层成功语义

你必须先把这三层区分写硬：

### A. upload success
表示：
- 当前本地 snapshot 已成功上传到云端 backup container

不表示：
- 已同步
- 所有设备已一致
- 云端变成当前真相源

### B. download completed
表示：
- 云端 snapshot 已被成功下载到本机
- 只完成下载层动作

不表示：
- 已恢复
- 当前设备数据已更新
- 可以直接显示 restore success

### C. restore success
表示：
- pre-check + confirm + apply 全部成功
- 且当前范围真的允许 restore apply

不表示：
- 已同步
- 多端已一致
- 自动同步成功

### 必须写硬
- `upload success != sync success`
- `download completed != restore success`
- `restore success != sync success`

---

## 4. Phase 0 你应该做的工程动作

## Step A — 找最小侵入点
请先定位现有代码中最适合承接 delta 的位置，不要大范围重构。

优先找：
1. 设置页 / 我的页 / 数据与备份入口
2. 现有 P3.1 backup lane 的入口与状态映射点
3. 现有 UI copy / badge / status / CTA mapping 位置
4. 现有 feature guard / placeholder / disabled-state pattern
5. 测试目录里最适合加 delta regression fences 的位置

目标不是马上接功能，而是找到最小改动入口。

## Step B — 建 delta entry / seam / guard
请为以下 3 个功能建 seam / guard，但不要把功能做出来：

1. `dailyGoalSettingEnabled`
2. `manualUploadEnabled`
3. `downloadToLocalEnabled`

名字可按项目风格调整，但要求明确区分。

同时：
- 需要有 UI 层 visibility / enabled / placeholder guard
- 需要有结果态 / copy 映射 guard
- 需要有测试可读入口

## Step C — 建语义挡板
请在你项目里最合适的位置，把以下文案和状态挡住：

### 禁止出现
- 已同步
- 所有设备已一致
- 自动同步成功
- 已恢复（当只有 download completed 时）
- 当前设备数据已更新（当只有 download completed 时）

### 允许出现
- 上传成功
- 备份成功
- 最近一次上传成功
- 已完成下载
- 已取回备份
- 恢复成功（仅在 future apply success 路径存在时才允许）

## Step D — 建 regression fences
你必须证明这轮 delta 不会污染当前已完成的 P3.1 主线和主学习链路。

至少要保护：
1. Today 主链路
2. 新词学习
3. 复习
4. Session
5. 签到 / streak
6. 主机制结算
7. 既有 P3.1 backup lane 主线
8. 既有副机制摘要 / 承接路径

## Step E — 为后续 phases 预留清楚的进入点
后续推荐顺序是：

- **Phase 1：daily_goal setting**
- **Phase 2：manual upload + latest backup status**
- **Phase 3：download-to-local / latest snapshot apply first-shot**

所以你的 seam / guard 设计要支持这个顺序，不要搞成三功能绑在一起才能动。

---

## 5. 你这轮应该补的测试

## A. Entry / guard tests
覆盖：
1. 三个 delta feature 都有独立 entry / seam / guard
2. 未启用时不会直接进入真实功能流
3. 没有 guard leakage 导致按钮一上来可执行
4. 现有主线功能没有被 guard 误伤

## B. Success semantics tests
覆盖：
1. `upload success != sync success`
2. `download completed != restore success`
3. `restore success != sync success`
4. UI / state mapping 中没有一个笼统状态吞掉三层语义

## C. Copy / wording tests
覆盖：
1. 不出现“已同步”
2. 不出现“所有设备已一致”
3. download completed 不映射成“已恢复”
4. 只有 future restore apply 路径存在时，才允许“恢复成功”文案

## D. Existing-flow regression tests
覆盖：
1. Today 主 CTA 不受影响
2. 新词学习、复习、Session、签到不受影响
3. 主机制结算层不受影响
4. 现有 P3.1 主线不受影响
5. 副机制承接入口不受影响

## E. Negative tests
覆盖：
1. 不允许直接做 daily_goal 保存成功流
2. 不允许直接做 upload 成功流
3. 不允许直接做 download / restore 成功流
4. 不允许出现 destructive action 主入口

---

## 6. 代码改动原则

### 6.1 允许的改动风格
- very small patch
- seam-first
- guard-first
- test-led
- regression-first
- reuse-first

### 6.2 禁止的改动风格
- 大重构
- 先把功能做一半再补挡板
- 顺手扩成 sync / restore platform
- 顺手写 active baseline 假设
- 让 copy / state mapping 先跑起来再说
- 反向修改既有主线的业务事实

---

## 7. 你完成后必须给出的输出

### A. 改动摘要
按文件列出：
- seams / guards
- state semantics fences
- UI state / copy mapping hardening
- regression fences
- tests

### B. 边界说明
请明确写：
1. 你如何保证这轮没有把 delta 直接做成 active runtime truth
2. 你如何保证 upload / download / restore 三层语义没有混写
3. 你如何保护既有 P3.1 主线不被污染

### C. 自测结果
至少给出：
- 跑了哪些测试
- 新增了哪些测试
- 总通过数 / 失败数
- 若有跳过项，说明原因

### D. 明确声明未做项
你必须明确写：
- 未做 daily_goal 真正保存
- 未做 manual upload 真正打通
- 未做 download-to-local / restore apply
- 未做 destructive actions
- 未把 delta 写成 active baseline

---

## 8. Completion bar（Room 4 验收条）

只有同时满足以下条件，我才会判 Phase 0 通过：

1. 有独立 delta entry / seam / guard
2. 有 regression fences，证明不会污染既有 P3.1 主线
3. upload / download / restore 三层成功语义挡板已建立
4. 没有“已同步”“自动恢复”等误导表达
5. 没有提前进入 daily_goal / upload / restore 本体实现
6. 有 self-test summary

---

## 9. 最后一句

这轮你要做的不是“直接做功能”，而是：

> **先把 direct-scope delta 的边界钉住，确保后续每一轮都能单独实现、单独验收、单独回归。**

请按 **very small patch + guard-first + test-led** 风格推进。
