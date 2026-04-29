# DB 变更文档 — P3.2 备份与恢复 + P3.3.16 本地批量提交

- **版本：** v0.1
- **日期：** 2026-04-11
- **范围：** P3.2 备份/恢复增强 + P3.3.16 本地复习批量提交
- **状态：** Code-truth implemented reality（已落地代码）

---

## 概览

本轮 DB 变更分为三个层面：

| 层面 | 变更内容 |
|------|----------|
| 云端 DevStore（后端持久化） | 备份数据新增持久化字段：`latestBackup`、`backupSnapshot`；备份元数据新增设备字段 |
| 本地 SQLite（移动端 drift） | `card_states` 表现在纳入备份/恢复范围；snapshot schema 升级 |
| 快照内嵌 schema | `p3_1_snapshot_v2` → `p3_2_snapshot_v1`（新增 card_states + device 块） |

---

## 一、云端 DevStore 持久化层变更

### 1.1 背景

原备份数据（`_latestBackup`、`_backupSnapshot`）仅保存在内存中，服务重启后丢失。P3.2 将其纳入 `DevStoreSnapshot` 持久化链，通过 JSON 文件或 PostgreSQL 持久化。

### 1.2 `DevStoreSnapshot` 新增字段

文件：`apps/api/src/domain/persistence.ts`

| 字段名 | 类型 | 必须 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `latestBackup` | `object \| null` | 可选 | `null` | 最新备份的元数据对象（见 §1.3）；旧状态文件中不存在此字段时自动置 null |
| `backupSnapshot` | `object \| null` | 可选 | `null` | 最新备份的完整快照 JSON 对象；服务重启后可继续提供恢复服务 |

**持久化行为：**
- 每次 `POST /me/backup` 成功后，`latestBackup` 和 `backupSnapshot` 随 `saveToDisk()` 持久化
- 服务重启后通过 `hydrate()` 恢复，`GET /me/backup/latest/snapshot` 立即可用
- last-write-wins：新备份上传后直接覆盖

### 1.3 备份元数据对象结构（`latestBackup`）

```json
{
  "backup_id": "backup-1712829600000",
  "schema_version": "p3_2_snapshot_v1",
  "uploaded_at": "2026-04-11T10:00:00.000Z",
  "snapshot_size": 8192,
  "status": "succeeded",
  "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "device_model": "Google Pixel 7a"
}
```

| 字段 | 类型 | 含义 |
|------|------|------|
| `backup_id` | string | 服务端生成的唯一备份ID，格式 `backup-{epoch_ms}` |
| `schema_version` | string | 快照的 schema 版本号，如 `"p3_2_snapshot_v1"` |
| `uploaded_at` | string | 上传时间，ISO 8601 UTC |
| `snapshot_size` | number | 快照 JSON 字符串字节数，仅供参考 |
| `status` | string | 固定为 `"succeeded"`（失败时不存储） |
| `device_id` | string \| null | 上传设备的 UUID；来自快照 `device.device_id` 或请求顶层字段 |
| `device_model` | string \| null | 上传设备的型号字符串；仅信息展示用，不参与合并/冲突决策 |

### 1.4 `review_attempts` 表 — 新增 `local_batch_*` 记录（P3.3.16）

P3.3.16 本地复习批量提交时，`review_attempts` 表新增一类 `review_group_id` 格式：

| 字段 | 原有值 | 新增值 |
|------|--------|--------|
| `review_group_id` | `"group-{uuid}"` | `"local_batch_{timestamp}_{random6}"` |

**含义：** `local_batch_*` 前缀标识该组来自本地 FSRS 队列，由客户端自主规划，不对应云端 `review_groups` 表中的任何记录。此为临时/内部 ID，仅用于幂等判断和结算关联。

**`local_batch_*` 记录特性：**
- 存储逻辑与普通 review_attempts 相同（写入同一张表）
- 不会在 `review_groups` 表中有对应行
- 后续 `reward_source_events` 中的 `source_ref_id` 指向此 `local_batch_*` ID

---

## 二、本地 SQLite（移动端）变更

### 2.1 `card_states` 表 — 新纳入备份/恢复范围

**表位置：** drift `AppDatabase`，文件 `apps/mobile/lib/core/storage/drift/tables/fsrs_tables.dart`

**变更说明：** 该表此前只用于本地 FSRS 调度，本轮开始纳入 cloud backup/restore 流程。

#### 完整字段说明

| 列名 | 类型 | 可空 | 默认值 | 含义 |
|------|------|------|--------|------|
| `id` | INTEGER | ✗ | AUTOINCREMENT | 主键，自增；**备份时不导出，恢复时由 DB 重新分配** |
| `word_id` | TEXT | ✗ | — | 单词唯一标识，如 `"cet4-abandon"`；UNIQUE 约束 |
| `stability` | REAL | ✅ | NULL | FSRS 稳定性参数（记忆强度指数）；NULL 表示新卡从未复习 |
| `difficulty` | REAL | ✅ | NULL | FSRS 难度参数（遗忘难易程度）；NULL 表示新卡从未复习 |
| `due` | INTEGER | ✗ | — | 下次应复习时间，UTC 毫秒时间戳 |
| `last_review` | INTEGER | ✅ | NULL | 上次复习时间，UTC 毫秒时间戳；NULL 表示从未复习 |
| `state` | INTEGER | ✗ | 1 | 卡片状态：`1` = Learning（学习中）、`2` = Review（正式复习）、`3` = Relearning（重新学习/遗忘后） |
| `step` | INTEGER | ✅ | NULL | 当前学习/重学步骤索引；仅 state=1 或 state=3 时有值，state=2 时为 NULL |
| `reps` | INTEGER | ✗ | 0 | 累计成功复习次数（从 Learning 进入 Review 后的计数） |
| `lapses` | INTEGER | ✗ | 0 | 累计遗忘次数（从 Review 退回 Relearning 的次数） |
| `created_at` | INTEGER | ✗ | — | 卡片首次创建时间，UTC 毫秒时间戳；用于 `countNewCardsToday()` 统计当日新词数 |

**索引：**

| 索引名 | 列 | 用途 |
|--------|-----|------|
| `idx_card_states_due` | `due` | 按到期时间查找待复习单词（LocalReviewQueueBuilder 主查询） |
| `idx_card_states_state` | `state` | 按状态筛选（如仅取 Review 状态的卡片） |
| `word_id UNIQUE` | `word_id` | 保证每个单词只有一条记录；恢复时 DELETE+INSERT 不会产生重复 |

**备份/恢复行为：**

| 操作 | 行为 |
|------|------|
| 导出（备份） | 读取所有行，**去除 `id` 列**后序列化到快照 `progress.card_states` |
| 导入（恢复） | `DELETE FROM card_states` 后重新 INSERT，不含 `id`，由 SQLite 自增分配 |
| `card_states` 表不存在时（旧数据库） | 导出返回空数组 `[]`，不报错；恢复时若无 `card_states` 数据则跳过 |

### 2.2 SharedPreferences — 新增自动备份时间戳

| Key | 类型 | 含义 |
|-----|------|------|
| `auto_backup_last_at_ms` | int | 上次自动备份成功的 UTC 毫秒时间戳；用于 30 分钟节流判断；不存在时视为从未自动备份 |
| `device_unique_id` | string | 当前设备的 UUID v4；首次访问时生成，后续稳定不变；卸载重装后重置 |

---

## 三、快照 Schema 版本记录

### 3.1 版本历史

| 版本 | 日期 | 新增内容 | 对应备份端点支持 |
|------|------|----------|----------------|
| `p3_1_snapshot_v2` | 2026-04 以前 | word_records + settings | 恢复时降级支持 |
| `p3_2_snapshot_v1` | 2026-04-11 | + `device` 块 + `progress.card_states` | 完整恢复 |

### 3.2 向后兼容策略

- `BackupRestoreService` 在 `preCheck()` 和 `restore()` 中均接受两个版本
- 旧版本（`p3_1_snapshot_v2`）恢复时：仅恢复 word_records + settings，card_states 跳过（本地保留）
- 未知版本：返回 `versionNotSupported`，不执行恢复

---

## 四、权威源汇总（本轮后更新）

| 数据域 | 权威源 | 说明 |
|--------|--------|------|
| FSRS 调度状态（card_states） | 本地 drift SQLite | 本地运行态；云端备份是镜像，恢复后成为本地权威 |
| word_records | 本地 sqflite | 历史学习记录；同样纳入备份 |
| 今日聚合（daily_goal / streak） | 云端 DevStore | 本地 FSRS 评分后通过 `local-batch` 上报触发云端更新 |
| 奖励 / 结算 | 云端 DevStore | 不在备份范围内；由服务端独立维护 |
| 备份元数据 | 云端 DevStore（持久化） | P3.2 后服务重启不丢失 |
| 备份快照 | 云端 DevStore（持久化） | P3.2 后服务重启不丢失 |

---

## 五、不在本轮范围内（Pending）

以下内容当前仍不在本轮变更范围内：

| 内容 | 说明 |
|------|------|
| `review_logs` 表的备份 | 仅备份 card_states（调度状态），不备份不可变的历史 review logs |
| `user_backup_snapshots` 正式数据库表 | 当前仍用 DevStore 内存持久化，未建正式 PostgreSQL 表 |
| 多版本快照保留 | 当前 latest-only，新备份覆盖旧备份 |
| 增量备份 / 差异备份 | 目前是全量快照 |
| 备份加密 | 目前无加密 |
| 跨设备自动同步 | 不在本轮范围；冲突策略为 last-write-wins |
