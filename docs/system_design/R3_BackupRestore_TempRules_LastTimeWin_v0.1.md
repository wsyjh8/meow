# R3_BackupRestore_TempRules_LastTimeWin_v0.1

- **Room:** Room 3 / Business Rules Engine
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Status:** temporary rules note / candidate for Room 1 review
- **Date:** 2026-04-11
- **Purpose:** 在当前阶段，不引入复杂多设备自动同步与自动 merge 的前提下，先解决“换机 / 重装导致本地 FSRS 状态清零”的现实问题，并为后续真正的 sync / conflict round 预留清晰边界。

---

## 1. 一句话结论

> **当前阶段先采用“本地为主、云端备份、手动恢复、快照覆盖”的保守策略；多设备冲突暂以 `latest snapshot wins` 处理，但该规则仅适用于备份恢复场景，不视为未来在线同步 / 自动 merge 的最终规则。**

---

## 2. 当前暂定范围

### 2.1 In scope
1. 设置页保留 **备份** / **恢复** 按钮
2. 点击 **备份**：上传当前本地状态快照到云端
3. 点击 **恢复**：下载所选云端快照，并恢复到当前设备本地
4. 增加 **不定期自动备份**（best-effort）
5. 备份记录补充 **device_model** 与 **device_id** 字段

### 2.2 Out of scope
1. 实时双向同步
2. 自动 merge
3. 多设备同时在线复习的实时冲突协调
4. 卡片级 field-by-field merge
5. 登录即自动把云端状态覆盖本地
6. 把 backup / restore 写成 sync completed

---

## 3. 临时业务规则（Room 3 推荐口径）

### R3-TEMP-BR-001｜运行态主真相
当前阶段，**本地仍是学习运行态主真相**。云端在本轮只承担：
- 备份容器
- 恢复来源
- 备份元信息记录

云端当前**不是**实时同步真相源，也**不是**多设备自动合并真相源。

### R3-TEMP-BR-002｜备份语义
点击 **备份** 时，系统上传的是：
- 当前设备本地状态的 **完整快照（snapshot）**
- 而不是卡片级增量 merge 包

业务表达必须使用：
- “已备份”
- “备份成功 / 失败”

不得写成：
- “已同步”
- “所有设备已一致”
- “云端已成为当前运行态真相”

### R3-TEMP-BR-003｜恢复语义
点击 **恢复** 时，系统执行的是：
- 下载所选备份快照
- 用该快照**覆盖当前设备本地状态**

因此，恢复的正式业务语义是：
> **manual restore / snapshot overwrite**

不是：
- 自动 merge
- 智能冲突协调
- 实时同步完成

### R3-TEMP-BR-004｜冲突策略（当前暂定）
当前多设备冲突暂采用：
> **latest snapshot wins**

但该规则的适用范围必须被写死为：
- **只适用于 backup / restore 场景下的 snapshot 选择与恢复覆盖**
- **不自动升格为未来 online sync / auto-merge 的长期规则**

更白话地说：
- 如果用户要恢复，就恢复用户选中的最新快照
- 当前系统不承诺把两台设备的 card state 自动合并成一个更优结果

### R3-TEMP-BR-005｜自动备份语义
自动备份只允许被描述为：
> **best-effort automatic backup**

必须同时满足：
- 不保证实时
- 不保证跨设备立即一致
- 不保证替代用户主动备份

业务文案不得暗示：
- 自动备份 = 自动同步
- 自动备份 = 所有设备总是最新
- 自动备份 = 不会丢任何多端并行修改

### R3-TEMP-BR-006｜恢复前警告
恢复前必须明确提示以下风险：
1. 将覆盖当前设备本地状态
2. 可能丢失该设备恢复前、尚未进入所选快照的较新本地进度
3. 这不是多设备智能合并
4. 请确认所选备份来自你希望恢复的设备 / 时间点

### R3-TEMP-BR-007｜备份元信息字段
每条备份记录至少应包含以下元信息：
- `backup_id`
- `user_id`
- `device_id`
- `device_model`
- `app_version`
- `snapshot_schema_version`
- `backup_created_at`
- `backup_reason`（`manual` / `auto`）
- `state_scope`（推荐固定为 `full_snapshot`）

### R3-TEMP-BR-008｜文案事实边界
以下三种成功语义必须严格分开：
- `backup success`
- `restore success`
- `sync success`

当前阶段只允许前两种；
**不得把备份成功或恢复成功写成同步成功。**

---

## 4. Room 3 judgment

### 4.1 为什么当前推荐这套临时方案
1. 它优先解决“换机 / 重装后 FSRS 状态清零”的真实痛点
2. 它不把项目直接拉入复杂 sync / merge / conflict-engine 范围
3. 它与当前项目的 local-first + manual backup/restore 基线一致
4. 它保留未来升级到真正 sync round 的空间

### 4.2 当前已知代价
1. 两台设备并行使用时，不能智能合并学习进度
2. `latest snapshot wins` 会牺牲多端并行更新下的精细正确性
3. 它本质更像“恢复覆盖规则”，不是“真正同步规则”

---

## 5. 后续升级边界（先记住，不在本轮实现）

如果未来真的进入多设备同步 round，Room 3 当前倾向的方向仍是：
- 不直接 merge raw `card_states`
- 改走 **event truth + derived state + stale-base reject**
- 把未来 online conflict strategy 与当前 snapshot restore strategy 明确拆开

也就是说：
> **本轮 latest snapshot wins 只是 restore 规则，不是未来 sync 的终局规则。**

---

## 6. 给 Room 1 / Room 2 / Room 4 的最短执行口径

### 给 Room 1
当前可把它视为：
- 一个 **用户可感知但范围受控** 的数据安全增强
- 不是多设备同步产品立项
- 不是 full sync / auto merge 上线

### 给 Room 2
当前请按：
- 备份容器
- 快照元信息
- 恢复覆盖
- 自动备份 best-effort
进行技术收口；不要把 API / data model 过度设计成真正 sync engine。

### 给 Room 4
当前实现与测试重点应放在：
- 备份成功/失败
- 恢复成功/失败
- 恢复覆盖 warning
- 备份记录设备信息可见
- 自动备份不误报为同步成功

---

## 7. 最终结论

> **先把“本地状态不轻易丢”解决掉，再谈“多设备状态如何优雅合并”。**

Room 3 认为，这个顺序是当前阶段最稳的。
