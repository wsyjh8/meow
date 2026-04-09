# R4_to_Cursor_P3_1_Delta_Phase2_Handoff_v0.1.md

- **From:** Room 4 (Eng + QA + Debug Tech Lead)
- **To:** Cursor
- **Project:** 背单词喵喵 App
- **Stage:** P3.1 direct-scope pin delta
- **Phase:** Phase 2
- **Goal:** Manual upload + latest backup status
- **Status of this handoff:** prepared in advance; executable when Room 4 confirms Phase 1 close
- **Important:** 你读不到我们项目文件，所以以下内容已经替你补齐。请严格按这份 handoff 执行，不要自行扩写需求。

---

## 0. 这份 handoff 的使用条件

这份是 **P3.1 delta / Phase 2** 的预备指令。

只有在 Room 4 明确确认以下条件后，你才执行这份 handoff：

1. **Phase 1 已通过 / 可 close**
2. `daily_goal setting` 已稳定落地
3. 当前实现仍未污染既有 P3.1 主线与主学习链路
4. `upload / download / restore` 三层语义挡板仍保持成立

如果 Phase 1 还没被 Room 4 放行，这份 handoff 先不要落代码。

---

## 1. 这轮到底做什么

这轮只做一件事：

> **把“上传进度到云端”做成一个可手动触发、状态清楚、不会被误读成同步系统的最小闭环。**

当前 direct-scope delta 的 3 个功能是：
1. 从云端下载进度到本机
2. 上传进度到云端
3. 设置每日学习单词数量

但 **Phase 2 只做第 2 个**。  
不要顺手碰 download / restore，也不要顺手回改 Phase 1 的 daily goal 逻辑。

---

## 2. 你必须服从的当前事实边界

### 2.1 当前项目状态
当前推进层状态仍然是：

> **P3.1 Reviewing / Restore Gate Pending**

因此：
- 这轮 delta 已被 User / Room 1 拉进范围
- 但仍不是自动生效的 active runtime truth
- 你的实现必须继续服从 Room 4 phase gate 与当前 active versions

### 2.2 本轮功能的准确含义
本轮功能是：

> **用户手动触发，把当前本地 snapshot 上传到云端 backup container，并展示最近一次上传状态 / 时间。**

这不是：
- 实时双向同步
- 后台自动同步
- 持续 sync engine
- 云端成为 runtime truth
- 多设备自动对齐

### 2.3 当前仍成立的硬边界
你必须继续服从以下边界：

1. **manual upload / manual backup only**
2. **云端当前仍是 backup container，不是 runtime truth / sync truth**
3. **upload success != sync success**
4. **最近一次备份状态默认展示 upload result，不是 export result**
5. 若同时存在“本地导出成功”，只能作为 **次级说明**
6. 不出现：
   - 已同步
   - 所有设备已一致
   - 自动同步成功
7. 不得破坏主学习链路，不得抢 Today 主 CTA
8. 不做 download / restore / destructive actions

---

## 3. 本轮允许做什么 / 不允许做什么

## 3.1 本轮允许做
1. 设置页 / 我的页中的 `上传进度到云端` 按钮
2. 手动上传触发链路
3. upload service / adapter / use case
4. upload result / latest backup metadata 读取与映射
5. upload 状态矩阵：
   - idle
   - uploading
   - succeeded
   - failed
   - retrying
6. 最近一次备份时间 / 状态展示
7. retry
8. 相关测试与回归

## 3.2 本轮禁止做
1. 不做 download-to-local
2. 不做 restore apply
3. 不做 delete backup
4. 不做 clear local
5. 不做 background sync
6. 不做 full sync
7. 不做 multi-device merge
8. 不做 backup center 大页面
9. 不改写 Phase 1 已落下的 daily goal 生效逻辑

---

## 4. 你应该怎么实现

## Step A — 复用现有 P3.1 backup lane
优先复用：
- 既有 snapshot export / upload 基础
- 既有 backup service / repository / adapter
- 现有 settings / 我的页承接入口模式
- 现有结果对象与状态映射方式

不要另起一条“新同步系统”。

## Step B — 接通 manual upload
至少要有：
1. 用户点击按钮
2. 触发上传动作
3. 调用最小 upload 链路
4. 返回 upload result
5. 更新最近一次备份状态 / 时间

### 推荐命名（按项目风格可调整）
- `manualUpload`
- `uploadProgressToCloud`
- `BackupUploadService`
- `latestBackupStatus`
- `LatestBackupInfo`

重点不是名字，而是：
- 明确是 upload / backup
- 不和 sync 命名混在一起

## Step C — 建 latest backup status
默认规则必须写硬：

> **“最近一次备份状态”默认展示的是最近一次上传结果。**

如果同时想展示本地导出成功信息：
- 只能作为次级说明
- 不能盖过上传结果
- 不能把“本地导出成功”说成“云端已备份成功”

### 最小状态集合
至少要支持：
- `no_backup_yet`
- `uploading`
- `succeeded`
- `failed`
- `retrying`

如果你项目已有等价命名，可以等价映射。

## Step D — 文案与状态表达写硬
### 允许
- 上传成功
- 备份成功
- 最近一次上传成功
- 上传失败
- 重试
- 尚未备份

### 禁止
- 已同步
- 所有设备已一致
- 自动同步成功
- 云端当前永远是最新真相
- 恢复成功（本轮不能出现）
- 当前设备数据已更新（本轮不能出现）

## Step E — 不污染主学习链路
这个功能不能导致：
- Today 主 CTA winner rule 被顺手改掉
- 新词学习 / 复习 / Session / 签到被打断
- 主机制结算层被挪成备份中心
- P3.1 既有 backup lane 被重写成 sync system

---

## 5. UI / UX 最小要求

### 5.1 入口位置
默认优先放在：
- 设置页
- 我的页

不要放在：
- Today 主 CTA 中心
- 学习主流程中间
- Session 完成弹层主位

### 5.2 默认展示
至少应展示：
- 上传进度到云端
- 最近一次备份状态
- 最近一次备份时间（若有）
- 重试（失败时）

### 5.3 最小状态矩阵
#### A. no_backup_yet
- 中性说明
- 可以有“上传进度到云端”

#### B. uploading
- 按钮 loading / disabled
- 文案中性：正在备份中
- 不能写成“正在同步全部设备”

#### C. succeeded
- 可显示最近一次上传成功时间
- 可写“已备份”/“上传成功”
- **不能**写“已同步”

#### D. failed
- 明确失败
- 可展示“重试”
- 不责备用户

#### E. retrying
- 类似 uploading
- 可写“正在重试”
- 仍不能写成“同步修复中”

---

## 6. 你这轮应该补的测试

## A. Upload flow tests
覆盖：
1. 手动点击可触发上传
2. uploading 状态可见
3. succeeded 状态可见
4. failed 状态可见
5. retrying 状态可见
6. retry 可触发重新上传

## B. Latest backup status tests
覆盖：
1. “最近一次备份状态”默认读取 upload result
2. 若存在本地导出成功信息，只作为次级说明
3. 不会把 export result 误当 latest upload result
4. `no_backup_yet` 正常显示

## C. Copy / wording tests
覆盖：
1. 不出现“已同步”
2. 不出现“所有设备已一致”
3. 不出现“自动同步成功”
4. 不出现“恢复成功”
5. 不出现“当前设备数据已更新”

## D. Regression tests
覆盖：
1. Today 主链路不受影响
2. 新词学习 / 复习 / Session / 签到不受影响
3. Phase 1 的 daily goal setting 不受影响
4. download / restore 没有被顺手做出来

## E. Negative tests
覆盖：
1. upload failed 不会被映射成 success
2. latest backup status 不会吞掉真实失败态
3. 不会顺手长出 delete backup / clear local / restore 按钮
4. 不会把 upload 功能做成 sync engine

---

## 7. 代码改动原则

### 7.1 允许的改动风格
- small patch
- upload-lane-first
- state-matrix-first
- reuse-first
- test-led
- no-sync-overclaim

### 7.2 禁止的改动风格
- 大重构
- 顺手扩成 sync system
- 顺手做 download / restore
- 顺手做 destructive actions
- 让文案先写“已同步”图省事
- 把 export / upload / restore 三层状态混写

---

## 8. 你完成后必须给出的输出

### A. 改动摘要
按文件列出：
- 上传入口
- upload service / adapter
- latest backup status / time
- state mapping
- tests

### B. 边界说明
请明确写：
1. 你如何保证这轮仍然只是 manual upload / backup
2. 你如何保证 latest backup status 默认展示 upload result
3. 你如何保证没有把 upload 写成 sync success
4. 你如何保证没有顺手做 download / restore

### C. 自测结果
至少给出：
- 跑了哪些测试
- 新增哪些测试
- 总通过数 / 失败数
- 若有跳过项，说明原因

### D. 明确声明未做项
你必须明确写：
- 未做 download-to-local
- 未做 restore
- 未做 delete backup
- 未做 clear local
- 未做 full sync / background sync / merge

---

## 9. Completion bar（Room 4 验收条）

只有同时满足以下条件，我才会判 Phase 2 通过：

1. `上传进度到云端` 入口已成立
2. 手动上传闭环已成立
3. latest backup status 默认显示 upload result
4. retry 已成立
5. 文案不误导成 sync
6. 既有主学习链路不受污染
7. 没有顺手做 download / restore / destructive actions
8. 有 self-test summary

---

## 10. 最后一句

这轮你要做的不是“把同步系统做出来”，而是：

> **先把 manual upload + latest backup status 这个最小可见闭环收稳。**

请按 **small patch + state-matrix-first + no-sync-overclaim + test-led** 风格推进。
