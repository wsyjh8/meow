# API 变更文档 — P3.2 备份与恢复 + P3.3.16 本地批量提交

- **版本：** v0.1
- **日期：** 2026-04-11
- **范围：** P3.2 备份/恢复增强 + P3.3.16 本地复习批量提交
- **状态：** Code-truth implemented reality（已落地代码）
- **Base URL：** `/api/v1`
- **鉴权：** 无（dev mode）

---

## 概览

本轮变更涉及两个方向：

| 方向 | 内容 |
|------|------|
| P3.2 备份增强 | `POST /me/backup`、`GET /me/backup/latest`、`GET /me/backup/latest/snapshot` 新增设备字段；快照 schema 升级到 `p3_2_snapshot_v1`（含 FSRS card_states） |
| P3.3.16 本地复习 | 新增 `POST /review-attempts/local-batch`，接受本地来源复习批量提交，不需要后端 reviewGroupId |

---

## 一、备份相关端点

### 1.1 `POST /me/backup` — 上传备份快照

**变更：** 新增 `device_id`、`device_model` 字段；备份数据现已持久化（服务重启后不丢失）。

#### 请求体

```json
{
  "snapshot": {
    "schema_version": "p3_2_snapshot_v1",
    "exported_at": "2026-04-11T10:00:00.000Z",
    "export_format": "full_snapshot_json",

    "device": {
      "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "device_model": "Google Pixel 7a"
    },

    "settings": {
      "daily_goal": 20,
      "sound_enabled": true,
      "theme": "light",
      "notification_time": "09:00"
    },

    "progress": {
      "word_records": [...],
      "card_states": [...],
      "wordbook_progress": {},
      "daily_checkins": [],
      "custom_wordbooks": [],
      "vocabulary_notebook": []
    }
  },
  "schema_version": "p3_2_snapshot_v1"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `snapshot` | object | ✅ | 完整快照对象 |
| `snapshot.schema_version` | string | ✅ | 快照版本号，当前为 `p3_2_snapshot_v1` |
| `snapshot.device.device_id` | string \| null | ✅ | 设备唯一标识（UUID v4，App 首次安装生成，存 SharedPreferences） |
| `snapshot.device.device_model` | string \| null | ✅ | 设备型号，Android: `"Google Pixel 7a"`，iOS: `"iPhone14,2"` |
| `snapshot.progress.card_states` | array | ✅（新增） | FSRS 调度状态列表，每条一个单词（详见 §三） |
| `schema_version` | string | 可选 | 顶层 schema 版本（冗余，与 `snapshot.schema_version` 一致） |

#### 响应 `200 OK`

```json
{
  "status": "succeeded",
  "backup_id": "backup-1712829600000",
  "uploaded_at": "2026-04-11T10:00:00.000Z",
  "schema_version": "p3_2_snapshot_v1",
  "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "device_model": "Google Pixel 7a"
}
```

| 字段 | 说明 |
|------|------|
| `status` | `"succeeded"` 表示存储成功，`"failed"` 表示载荷无效 |
| `backup_id` | 服务端生成的备份ID，格式 `backup-{timestamp}` |
| `uploaded_at` | ISO 8601 UTC 时间戳 |
| `device_id` | 回显设备ID（来自快照或请求顶层字段） |
| `device_model` | 回显设备型号 |

**失败响应 `200`（payload 无效）：**
```json
{
  "status": "failed",
  "error_code": "INVALID_PAYLOAD",
  "message": "Missing or invalid snapshot payload"
}
```

---

### 1.2 `GET /me/backup/latest` — 获取最新备份元数据

**变更：** 响应新增 `device_id`、`device_model` 字段。

#### 响应 `200 OK`（有备份）

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

#### 响应 `200 OK`（无备份）

```json
{
  "status": "no_backup_yet",
  "backup_id": null,
  "uploaded_at": null,
  "schema_version": null,
  "device_id": null,
  "device_model": null
}
```

---

### 1.3 `GET /me/backup/latest/snapshot` — 获取完整快照（用于恢复）

**变更：** 响应新增 `device_id`、`device_model` 字段；`snapshot` 内容包含 card_states + device 块。

#### 响应 `200 OK`（有备份）

```json
{
  "status": "available",
  "schema_version": "p3_2_snapshot_v1",
  "uploaded_at": "2026-04-11T10:00:00.000Z",
  "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "device_model": "Google Pixel 7a",
  "snapshot": {
    "schema_version": "p3_2_snapshot_v1",
    "exported_at": "2026-04-11T10:00:00.000Z",
    "device": { "device_id": "...", "device_model": "..." },
    "settings": { ... },
    "progress": {
      "word_records": [...],
      "card_states": [...],
      ...
    }
  }
}
```

#### 响应 `200 OK`（无备份）

```json
{
  "status": "no_backup_found",
  "snapshot": null
}
```

**支持的 schema 版本（恢复时接受）：**

| schema 版本 | 是否可恢复 | 说明 |
|-------------|-----------|------|
| `p3_2_snapshot_v1` | ✅ | 含 card_states + device 信息 |
| `p3_1_snapshot_v2` | ✅（降级恢复） | 不含 card_states，设置和 word_records 照常恢复 |
| 其他 | ❌ | 返回 versionNotSupported |

---

## 二、本地复习批量提交（P3.3.16）

### 2.1 `POST /review-attempts/local-batch` — 提交本地复习批次

**背景：** P3.3.16 切换后，非续习 ReviewPage 由本地 FSRS 队列服务。用户在本地评分完一轮后，通过此接口一次性上报所有单词评分，触发每日目标更新和结算奖励。

**特点：**
- 无需传入后端 reviewGroupId
- 后端自动生成临时 `local_batch_{timestamp}_{random}` 作为内部 group ID
- 支持幂等（通过 `X-Idempotency-Key` 头）

#### 请求头

| 头 | 必填 | 说明 |
|---|------|------|
| `Content-Type` | ✅ | `application/json` |
| `X-Idempotency-Key` | 推荐 | 客户端生成的唯一 key，格式 `local-batch-{localGroupId}`，防重复提交 |

#### 请求体

```json
{
  "word_attempts": [
    { "word_id": "cet4-abandon", "action_result": "correct" },
    { "word_id": "cet4-absolute", "action_result": "incorrect" },
    { "word_id": "cet4-abstract", "action_result": "correct" }
  ]
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `word_attempts` | array | ✅ | 本轮评分列表，至少 1 条 |
| `word_attempts[].word_id` | string | ✅ | 单词 ID，如 `"cet4-abandon"` |
| `word_attempts[].action_result` | string | ✅ | `"correct"` 或 `"incorrect"`（由客户端 FSRS 评分映射：`good`/`easy` → correct，`again`/`hard` → incorrect） |

#### 响应 `200 OK`

```json
{
  "submit_status": "accepted",
  "group_completed": true,
  "group_remaining": 0,
  "today_review_completed": 3,
  "daily_goal_status": "partially_completed",
  "already_exists": false,
  "settlement": {
    "source_event_id": "se-xxx",
    "reward_settlement_status": "settled",
    "reward_items": [
      { "reward_type": "coins", "amount": 5, "reward_status": "credited" },
      { "reward_type": "fish_treat", "amount": 1, "reward_status": "credited" }
    ]
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `submit_status` | string | `"accepted"` \| `"rejected"` |
| `group_completed` | bool | 始终为 `true`（本地批次 = 整组已完成） |
| `group_remaining` | number | 始终为 `0` |
| `today_review_completed` | number | 今日已完成复习组数（含本次） |
| `daily_goal_status` | string | `"not_started"` \| `"in_progress"` \| `"partially_completed"` \| `"completed"` |
| `already_exists` | bool | 幂等重复时为 `true` |
| `settlement` | object \| null | 结算奖励信息；幂等重复时为 `null` |
| `settlement.reward_settlement_status` | string | `"settled"` \| `"pending"` |
| `settlement.reward_items` | array | 奖励条目列表 |

**副作用：**
- 向 `review_attempts` 写入所有评分记录（以临时 `local_batch_*` 为 group ID）
- `daily_goal_progress.today_review_completed` +1
- 若任意评分为 `correct`，更新 `learning_day_facts`
- 触发结算链：`reward_source_events` + `reward_ledger` + `settlements`

---

## 三、快照 Schema 规范（p3_2_snapshot_v1）

### 3.1 顶层结构

```json
{
  "schema_version": "p3_2_snapshot_v1",
  "exported_at": "ISO 8601 UTC",
  "export_format": "full_snapshot_json",
  "device": { ... },
  "settings": { ... },
  "progress": { ... }
}
```

### 3.2 `device` 块（新增）

```json
{
  "device_id": "uuid-v4-string 或 null",
  "device_model": "设备型号字符串 或 null"
}
```

| 字段 | 说明 |
|------|------|
| `device_id` | UUID v4，App 首次安装时生成并存入 SharedPreferences；含义：每次安装的唯一标识，非硬件序列号；卸载重装后重置 |
| `device_model` | 人类可读的设备型号；Android: `"{manufacturer} {model}"`，iOS: 硬件型号字符串如 `"iPhone14,2"`；用于恢复确认对话框展示来源设备信息 |

**语义边界：**
- `device_id` 和 `device_model` 仅作**信息性展示**，不参与任何合并或冲突决策
- 多设备冲突策略：**last-write-wins**，即最新上传的备份为准

### 3.3 `progress.card_states`（新增）

FSRS 调度状态列表，每条对应一个单词的 FSRS 卡片状态。

```json
[
  {
    "word_id": "cet4-abandon",
    "stability": 2.5,
    "difficulty": 5.0,
    "due": 1712829600000,
    "last_review": 1712743200000,
    "state": 2,
    "step": null,
    "reps": 3,
    "lapses": 0,
    "created_at": 1712000000000
  }
]
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `word_id` | string | 单词唯一标识，如 `"cet4-abandon"` |
| `stability` | number \| null | FSRS 稳定性参数；null 表示从未复习过 |
| `difficulty` | number \| null | FSRS 难度参数；null 表示从未复习过 |
| `due` | number | 下次应复习的 UTC 毫秒时间戳 |
| `last_review` | number \| null | 上次复习的 UTC 毫秒时间戳；null 表示从未复习 |
| `state` | number | 卡片状态：`1` = Learning，`2` = Review，`3` = Relearning |
| `step` | number \| null | 当前学习/重新学习步骤索引；Review 状态时为 null |
| `reps` | number | 累计成功复习次数 |
| `lapses` | number | 累计遗忘次数（从 Review 回到 Relearning 的次数） |
| `created_at` | number | 卡片首次创建的 UTC 毫秒时间戳；用于统计当天新卡数量 |

**注意：** 导出时不含数据库自增 `id` 字段；恢复时由数据库重新分配。

### 3.4 Schema 版本对比

| 字段 | `p3_1_snapshot_v2` | `p3_2_snapshot_v1` |
|------|--------------------|--------------------|
| `device` 块 | ❌ | ✅ 新增 |
| `progress.card_states` | ❌ | ✅ 新增 |
| `progress.word_records` | ✅ | ✅ |
| `settings` | ✅ | ✅ |
| `progress.wordbook_progress` | ✅ | ✅ |
| `progress.daily_checkins` | ✅ | ✅ |

---

## 四、自动备份触发条件

客户端实现自动备份（非 API 端点，描述客户端行为）：

| 触发时机 | 条件 |
|----------|------|
| App 进入后台（`AppLifecycleState.paused`） | 距上次自动备份 > 30 分钟 |
| 复习会话完成后 | 距上次自动备份 > 30 分钟 |

**特性：**
- Fire-and-forget，不阻塞 UI，失败不提示用户
- 成功时更新本地 SharedPreferences `auto_backup_last_at_ms`
- 与手动备份共用同一个上传链路

---

## 五、语义边界（不变约束）

以下语义边界在本轮后依然冻结：

| 约束 | 说明 |
|------|------|
| 备份成功 ≠ 同步成功 | 备份只是快照上传到云端容器，不代表多设备数据一致 |
| 恢复成功 ≠ 所有设备一致 | 恢复只更新当前设备本地数据 |
| 多设备冲突策略 | last-write-wins，最新上传时间戳的备份覆盖之前的 |
| card_states 权威源 | 本地 drift SQLite；云端备份是镜像，不是主源 |
| FSRS 事实 | 本地 FSRS 做规划，云端负责结算事实（daily_goal / streak / 奖励） |
