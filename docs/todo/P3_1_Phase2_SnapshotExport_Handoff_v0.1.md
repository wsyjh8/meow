# R4_to_Cursor_P3_1_Phase2_SnapshotExport_Handoff_v0.1.md

- **From:** Room 4 (Eng + QA + Debug Tech Lead)
- **To:** Cursor
- **Project:** 背单词喵喵 App
- **Phase:** P3.1 / Phase 2
- **Goal:** Snapshot export
- **Status of this handoff:** prepared in advance; executable when Room 4 confirms Phase 1 close
- **Important:** 你读不到我们项目文档，所以以下内容已经替你补齐。请严格按这份 handoff 执行，不要自行扩写需求。

---

## 0. 这份 handoff 的使用条件

这份是 **下一轮指令**，默认对应：

> **P3.1 / Phase 2 — Snapshot export**

请注意：
- 只有在 Room 4 确认 **Phase 1 已通过 / 可 close** 后，你才执行这份 handoff。
- 如果 Phase 1 还没通过，这份 handoff 先不要落代码。

---

## 1. 你这轮要做什么

你现在要做的，是把 **设备侧 local runtime truth** 导出成一个 **手动触发的全量 JSON snapshot**。

一句话：

> **让当前本地运行态可以被稳定、可验证地导出成第一拍 snapshot，为后续 cloud upload 做唯一输入。**

### 本轮允许做
1. 建立 snapshot export service / adapter / use case
2. 从 Phase 1 已落地的 local settings + local runtime truth 统一读取数据
3. 产出第一拍的全量 JSON snapshot
4. 写清第一拍 snapshot 的 include / exclude / pending 边界
5. 建立 export 成功 / 失败 / 空数据 / schema version 的测试
6. 预留给 Phase 3 的 upload 输入接口或 seam

### 本轮禁止做
1. 不做 cloud upload
2. 不做“最近一次备份状态”用户可见展示
3. 不做 restore
4. 不做 delete backup / clear local
5. 不把 local export success 写成 upload success
6. 不把 export 完成写成“已同步”
7. 不新增完整 backup center 页面
8. 不顺手改主机制 / 副机制既有业务语义

---

## 2. 你必须服从的事实边界

### 2.1 P3.1 当前产品立场
P3.1 的正式名称是：

> **Local Progress + Cloud Backup**

当前冻结的方向是：

- **local-first**
- **backup-first**
- **manual backup**
- **不是 full sync**
- **restore 不是第一拍默认范围**

### 2.2 三类成功语义必须继续分开
本轮你只实现第一类：

1. **local export success**
2. **cloud upload success**（本轮不做）
3. **restore success**（本轮不做）

必须写硬：

- `local export success != upload success`
- `local export success != sync success`
- snapshot 文件生成成功 ≠ 已经上传云端
- snapshot 文件生成成功 ≠ 可以恢复完成

### 2.3 snapshot 的准确角色
本轮 snapshot 是：

> **当前设备侧运行态的一次可导出、可序列化、可版本化的全量快照。**

它不是：
- 实时同步日志
- 差量同步包
- 多端合并中间格式
- 永久不可变审计链
- 恢复平台本体

---

## 3. 第一拍 snapshot scope（你必须按这个收）

## 3.1 Must include
第一拍 snapshot 默认必须包含以下最小集合（若项目内已有等价命名，可等价映射）：

### A. 轻设置
- `daily_goal`
- `sound_enabled`
- `theme`
- `notification_time`

### B. 主进度事实 / 聚合
- `word_records`
- `wordbook_progress`
- `daily_checkins`
- `custom_wordbooks`
- `vocabulary_notebook`

### C. snapshot metadata
- `schema_version`
- `exported_at`
- `device_timezone`（若你项目已有用户时区读口）
- `app_build` 或等价客户端版本标识（若低成本可得）
- `export_format = full_snapshot_json`

## 3.2 Must exclude
第一拍 snapshot 默认不得包含：

1. transient UI state
2. loading / expanded / selected tab 等界面临时态
3. debug / log / analytics 数据
4. access token / auth secret / refresh token
5. 任何“仅为了展示可重建”的 summary / derived / aggregate 字段
6. restore-only internal bookkeeping
7. server-only settlement / sync internals
8. 未来 full sync 才需要的 conflict metadata

## 3.3 Pending
以下内容若项目里存在，默认列为 pending，不要自己扩大进入第一拍：
1. 副机制更复杂库存与房间状态
2. 运营配置与远程文案缓存
3. 历史趋势缓存
4. 恢复专用安全校验元数据
5. 未来多设备冲突解决字段

### 3.4 一个重要原则
> **凡是可由 source facts 重建的 derived / aggregate / summary 数据，第一拍默认不进 snapshot。**

不要为了“导出后看起来完整”把重建型数据也一起塞进去。

---

## 4. 你应该怎么实现

## 4.1 统一读取入口
不要让 snapshot export 直接从 UI 层拼 JSON。

你应该从统一入口读取：
- local settings repository / adapter
- local runtime truth repository / adapter

也就是说，Phase 2 依赖 Phase 1 的 repository / adapter 层，不要绕开它。

## 4.2 建一个明确的 export service
建议存在一个明确的单独入口，例如：
- `SnapshotExportService`
- `LocalBackupExportUseCase`
- `BackupSnapshotBuilder`

名字按项目风格即可。

它至少要做 4 件事：
1. 读取允许进入 snapshot 的本地数据
2. 组装成稳定 JSON 结构
3. 填充 metadata
4. 返回导出结果对象（成功 / 失败 / 路径 / payload / 错误）

## 4.3 导出结果对象
本轮建议你至少有一个明确结果对象，表达：
- `status`
- `snapshotJson` 或 `snapshotPayload`
- `schemaVersion`
- `exportedAt`
- `errorCode`（失败时）
- 可选：`byteLength`

注意：
- 这个对象表达的是 **export result**
- 不是 upload result
- 不要提前长出 `syncStatus`

## 4.4 schema version
这轮请把 snapshot 版本号写出来。
最少要有：
- 顶层 `schema_version`
- 第一拍固定版本，例如 `p3_1_snapshot_v1`

原因：
- Phase 3 upload container 需要知道自己接的是什么
- Phase 4 restore 即便以后再做，也必须知道版本

但注意：
- 这轮只要求有最小版本号
- 不要求你做复杂 migration matrix

## 4.5 失败处理
export 失败时至少要能区分：
1. 本地读取失败
2. 序列化失败
3. 数据为空但可导出
4. 非法字段 / 不可序列化对象

默认要求：
- 不 crash
- 不把失败映射成成功
- 不偷偷吞掉错误再返回空成功结果

---

## 5. 推荐执行顺序

### Step A — 盘点 Phase 1 的本地数据入口
确认你上一轮 Phase 1 已经落下来的：
- local settings
- local runtime truth entities / tables
- repository / adapter

优先从这些稳定入口读取，不要新开一套读口。

### Step B — 冻住第一拍 snapshot shape
先把 snapshot 顶层结构收住，再接具体字段。
例如（只示意，不要求逐字一致）：

```json
{
  "schema_version": "p3_1_snapshot_v1",
  "exported_at": "2026-04-06T12:34:56Z",
  "export_format": "full_snapshot_json",
  "settings": {},
  "progress": {}
}
```

### Step C — 接入 Must include 数据
按 include 范围逐步接：
- settings
- word_records
- wordbook_progress
- daily_checkins
- custom_wordbooks
- vocabulary_notebook

### Step D — 补错误处理与结果对象
把 export 成功 / 失败 / 空数据态收成明确结果对象。

### Step E — 补测试并做回归
必须同轮补测试，不允许只交“导出功能看起来能跑”。

---

## 6. 你本轮必须补的测试

## A. Snapshot shape tests
覆盖：
1. 顶层有 `schema_version`
2. 顶层有 `exported_at`
3. 顶层有 settings / progress 或项目等价结构
4. 导出结构稳定，不依赖 UI 层临时状态

## B. Include / exclude tests
覆盖：
1. Must include 的数据确实进入 snapshot
2. transient UI state 不进入 snapshot
3. auth secret / token 不进入 snapshot
4. derived / aggregate / summary 数据默认不进入 snapshot

## C. Export semantics tests
覆盖：
1. export success 只表示本地导出成功
2. export success 不等于 upload success
3. export success 不等于 sync success
4. 本轮没有 restore success 语义

## D. Empty / failure tests
覆盖：
1. 空本地数据也能产出合法最小 snapshot
2. 本地读失败时返回失败结果
3. 序列化失败时返回失败结果
4. 不会把失败误映射成成功

## E. Existing flow regression tests
覆盖：
1. Today 主链路不受影响
2. 主机制结算语义不受影响
3. 副机制既有可见链路不受影响
4. 没有新增“已同步 / 已恢复”误导文案或状态

---

## 7. 代码改动原则

### 7.1 允许的改动风格
- small patch
- export-service-first
- repository reuse
- test-led
- explicit result typing
- explicit snapshot scope

### 7.2 禁止的改动风格
- 一口气做 upload
- 顺手做“最近一次备份状态”
- 顺手做 restore
- 顺手补完整 backup page
- 为了未来 restore 先做复杂安全系统
- 为了“导出完整”把所有 summary 都塞进去
- 自己扩写 pending 范围

---

## 8. 你完成后必须给出的输出

### A. 改动摘要
按文件列出：
- export service / builder
- snapshot schema / types
- repository reuse points
- tests

### B. 边界说明
请明确写：
- 你如何保证 export success 不会被误读成 upload success
- 你如何限制第一拍 snapshot scope
- 你如何保证没有把 derived 数据偷塞进去

### C. 自测结果
至少给出：
- 跑了哪些测试
- 新增了哪些测试
- 总通过数 / 失败数
- 若有跳过项，说明原因

### D. 明确声明未做项
你必须明确写：
- 未做 cloud upload
- 未做 latest backup status UI
- 未做 restore
- 未做 delete backup / clear local

---

## 9. Completion bar（Room 4 验收条）

只有同时满足以下条件，我才会判你 Phase 2 通过：

1. 已有稳定 snapshot export 入口
2. 第一拍 snapshot shape 已冻结并可测试
3. include / exclude / pending 边界明确
4. export success 与 upload / restore 语义严格分开
5. 空数据 / 失败态都能稳定返回
6. 既有主副机制关键链路回归通过
7. 没有偷做 upload / restore / latest backup status
8. 有 self-test summary

---

## 10. 最后一句

这轮你要做的不是“把云备份做完”，而是：

> **把“可被上传的本地快照”先做对。**

请按 **small patch + explicit snapshot scope + test-led** 风格推进。
