# 背单词喵喵 App API 设计草案 v0.1.4

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Status:** incremental P3.1 direct-scope delta write-back / ready for Room 1 review
- **Purpose:** 基于当前推进层 SSOT、`BR-OPP-001_v0.1.9.md`、`背单词喵喵app_DB设计草案_v0.1.5.md` 与 `R1_to_R2_P3_1_Delta_DB_API_Writeback_Handoff_v0.1.md`，在不推翻 `v0.1.3` 主链路结构的前提下，做一次最小 API write-back：把 P3.1 direct-scope delta round 已 close 的 upload / download / restore / daily_goal 相关契约正式回写进 Room 2 的技术契约。
- **Scope:** 本稿继续保留主机制主链路、今日页聚合、学习/复习、Session、签到、结算、基础统计与 P2 已吸收的最小副机制 API，并新增 P3.1 direct-scope delta 所需的 backup / restore / latest backup metadata API 契约。
- **Out of scope:** full sync、real-time sync、background sync、multi-device merge、partial restore、snapshot picker、delete backup、clear local、destructive actions bundle、production persistence rollout 细节。

---

## 0. Based on current active versions

### Runtime / Product
- `Main.md`（current runtime: `Main_updated_2026-04-07_v17.md`）
- `OPP-001_STATUS.md`（current runtime: `STATUS_updated_2026-04-07_v16.md`）
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `背单词喵喵app_副机制prd_v_0.md`
- `背单词喵喵app_副机制数值草案_v_0.md`
- `UI_SPEC_P3_1_LocalProgress_CloudBackup_v0.1.1.md`
- `UI_SPEC_P3_1_DirectScopePin_Delta_v0.1.1.md`

### Governance / Rules / Decision basis
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `room1_v0.2.0.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.0.md`
- `room4_v0.2.0.md`
- `room5_v0.2.0.md`
- `BR-OPP-001_v0.1.9.md`
- `R1_to_R2_P3_1_Delta_DB_API_Writeback_Handoff_v0.1.md`
- `R2_P3_1_DirectScopePin_Delta_Tech_Note_v0.1.1.md`
- `R3_P3_1_DirectScopePin_Delta_Rules_Note_v0.1.1.md`
- `R4_P3_1_DirectScopePin_Delta_Execution_Note_v0.1.1.md`
- `背单词喵喵app_DB设计草案_v0.1.5.md`

> 说明：本稿是对 `背单词喵喵app_API设计草案_v0.1.2.md` 的 **incremental P2 secondary write-back**。
> - 保留 `v0.1.2` 已经稳定的主机制 backend-truth / idempotent-by-default / 主链路接口面。
> - 只回写 Room 4 在 P2 final delivery 中已经真正落地、并且已经形成 backend runtime truth 的副机制最小 API 面。
> - 不反向扩大多猫、社交、复杂商店、远程文案系统与 production-only persistence API 范围。

---

## 1. 本轮更新目标

本轮 v0.1.2 只解决 7 件事：

1. 把 `D-OPP-001-010` 正式回写到 API：
   - `review_group_id`
   - `group_status`
   - `group_completed`
   - today review progress 的分层返回
2. 把 `D-OPP-001-011` 正式回写到 API：
   - `check_in` / `learning_day` / `streak` 三类事实分离返回
   - `streak_basis_type = check_in`
   - `local_date / timezone` 统一自然日口径
3. 让 Room 4 不再只靠 `review_group_id` + 本地 remaining 推导“本组完成”。
4. 让前端能分别读取：签到事实、learning day 事实、streak 事实，而不是继续把签到语义外推成 learning day。
5. 把 based-on / metadata 同步到当前 runtime baseline，消除 `v0.1.1` 中 `Main v2 / DB v0.1.1 / BR v0.1.1` 的旧引用残留。
6. 保留真正仍未冻结的事项：熟练度 / 掌握阈值、完整 SRS / review priority / review group 分组算法、CTA winner rule、统计页完整规格。
7. 保持本稿仍然是 **增量 write-back**，不重写未被本轮决策触发的接口面。

---

## 2. 仍然成立的设计原则

### 2.1 Backend-truth（后端真相源）
所有以下事实都以后端判定为准：
- 有效学习
- 有效复习
- 今日目标完成
- 有效 Session
- 签到事实
- streak 事实
- 奖励到账结果

### 2.2 Fact-first（先事实，再聚合，再展示）
API 不直接把 UI 文案当事实返回；优先返回：
- 原子行为结果
- 聚合状态
- 结算状态
- 跳转建议

### 2.3 Idempotent-by-default（默认防重）
所有可能影响：
- 进度
- Session
- 签到
- 奖励

的写接口，都必须支持幂等。

### 2.4 Async-safe（允许异步补齐）
结算与到账允许出现：
- `pending`
- `settling`
- `succeeded`
- `failed`
- `compensated`

前端不得把“已触发结算”误写成“已到账”。

### 2.5 UI-driven contract（页面驱动契约）
优先保证以下 6 个页面能不补脑：
1. 今日页
2. 新词学习页
3. 复习页
4. 主机制结算浮层
5. 签到区块 / 签到页
6. Session 入口与完成反馈

---

## 3. 本轮已冻结 / 仍待冻结

### 3.1 已冻结（本稿必须正式体现）

#### FD-API-001 `daily_goal_status` 严格判定口径
- 只由“今日新词目标 + 今日复习要求”共同决定。
- **不包含** Session 是否完成。
- **不包含** 签到是否成功。
- 当日无待复习内容时，复习要求视为自然满足。

#### FD-API-002 `session_validation_status` MVP 阈值
- 只有同时满足以下条件，Session 才记为 `valid`：
  1. 正常启动
  2. 正常结束
  3. 达到当前配置时长（MVP 默认 15 分钟）
  4. Session 内至少 5 次 `effective learning / effective review attempts` 总和
- 否则在校验完成后记为 `invalid`。

#### FD-API-003 主机制结算层与副机制承接页边界
- 结算浮层只承接本轮学习结果。
- 允许展示：
  - `daily_goal_status`
  - `session_validation_status`
  - `reward_settlement_status`
  - 奖励摘要
  - 弱次级跳转 CTA
- 不允许在该层做副机制深操作。
- 不允许把“结算已触发 / 已展示”写成“奖励已到账成功”。

#### FD-API-004 `review_group` 最小业务合同
- `review_group` 是 **后端生成、后端持有的一次有限复习批次对象**。
- 同一用户同一时刻 **只允许一个 active `review_group`**。
- “本组复习完成”指：当前 `review_group_id` 下，后端要求完成的 item 已全部获得有效提交结果，且该组完成结果已被服务端唯一确认。
- “本组完成”只推进“今日复习进度”，**不自动等于**“今日复习完成”。
- 允许同一 active group 跨 Session 继续完成，但不得并行生成多个 active group，不得重复结算，不得重复发奖。

#### FD-API-005 `check_in / learning_day / streak` 关系
- 当前 MVP 冻结为三类独立事实：
  - `check_in`
  - `learning_day`
  - `streak`
- `check_in` 只表示签到事实成立，不自动等于 `learning_day`、有效学习完成、或 `daily_goal_status=completed`。
- `learning_day` 表示该 `local_date` 下满足后端口径的有效学习事实成立，不依赖签到是否发生。
- `streak` 当前阶段 **按 `check_in` 驱动**，即 `streak_basis_type = check_in`。
- 三类事实统一按用户时区折算后的 `local_date` 处理，服务端为最终真相源。

### 3.2 仍待冻结（本稿继续显式保留）
- 熟练度 / 掌握阈值
- 完整 SRS / review priority / review_group 分组算法细节
- 今日页主 CTA winner rule
- 统计页是否扩成下一轮极简规格

---

## 4. API 范围总览

本稿覆盖 8 组接口：

1. 认证与基础身份（MVP 最小版）
2. 词书与学习目标设置
3. 今日页聚合
4. 新词学习
5. 复习
6. Session
7. 签到与 streak
8. 主机制结算与统计

---

## 5. 通用约定

## 5.1 Base URL
- `https://api.example.com/v1`

## 5.2 Auth
除游客创建和登录接口外，其余接口都要求：
- `Authorization: Bearer <token>`

## 5.3 Headers
### 必填（写接口）
- `X-Idempotency-Key: <string>`

### 建议
- `X-Client-Timezone: America/Toronto`
- `X-Client-Version: ios-0.1.0`
- `X-Request-Id: <uuid>`

## 5.4 时间与自然日
- 服务端统一使用 UTC 存储
- 所有 streak / 签到 / daily goal 相关接口，返回中同时带：
  - `server_time_utc`
  - `user_local_date`
  - `user_timezone`

## 5.5 响应信封

```json
{
  "ok": true,
  "request_id": "req_123",
  "data": {},
  "meta": {}
}
```

失败响应：

```json
{
  "ok": false,
  "request_id": "req_123",
  "error": {
    "code": "CHECK_IN_ALREADY_DONE",
    "message": "Today check-in already exists.",
    "retryable": false,
    "details": {}
  }
}
```

## 5.6 幂等规则
### 所有写接口统一规则
- 同一 `user_id + endpoint semantic + X-Idempotency-Key` 必须只成功写入一次。
- 重试时返回同一业务结果，不得重复推进状态或重复发奖。
- 若语义冲突但 key 相同，返回 `IDEMPOTENCY_KEY_REUSED_WITH_DIFFERENT_PAYLOAD`。

---

## 6. 全局命名统一（v0.1.1）

### 6.1 当前主命名
- `daily_goal_status`
- `session_validation_status`
- `reward_settlement_status`

### 6.2 废弃旧主叫法
以下不再作为正式主命名保留：
- `reward_settlement_last_status`
- `session_reward_status`
- `reward_status`（仅允许保留为账本项级状态，不得替代页面级结算状态）

### 6.3 命名层级区分
- 页面 / 聚合层：`reward_settlement_status`
- 账本奖励项层：`reward_items[].reward_status`
- Session 校验层：`session_validation_status`

---

## 7. 核心状态枚举（API 口径）

## 7.1 `daily_goal_status`
- `not_started`
- `in_progress`
- `partially_completed`
- `completed`

## 7.2 `session_validation_status`
- `pending`
- `valid`
- `invalid`

## 7.3 `session_status`
- `started`
- `ended`
- `validating`
- `valid`
- `invalid`

## 7.4 `reward_settlement_status`
- `pending`
- `settling`
- `succeeded`
- `failed`
- `compensated`

## 7.5 `submit_status`
- `accepted`
- `replayed`
- `rejected`

## 7.6 `sync_status`
- `healthy`
- `delayed`
- `failed`

> 注意：API 返回的是状态码，不是前端展示文案。

---

## 8. 错误码总表（v0.1.1）

### 8.1 通用
- `AUTH_REQUIRED`
- `FORBIDDEN`
- `INVALID_ARGUMENT`
- `RESOURCE_NOT_FOUND`
- `CONFLICTING_STATE`
- `IDEMPOTENCY_KEY_REQUIRED`
- `IDEMPOTENCY_KEY_REUSED_WITH_DIFFERENT_PAYLOAD`
- `UPSTREAM_SYNC_DELAY`
- `INTERNAL_ERROR`

### 8.2 今日页 / 词书
- `ACTIVE_BOOK_NOT_SET`
- `BOOK_NOT_AVAILABLE`
- `INVALID_DAILY_TARGET`

### 8.3 学习 / 复习
- `WORD_NOT_AVAILABLE`
- `STUDY_ATTEMPT_ALREADY_RECORDED`
- `REVIEW_GROUP_NOT_AVAILABLE`
- `REVIEW_ITEM_NOT_AVAILABLE`
- `ATTEMPT_SUBMIT_FAILED`

### 8.4 Session
- `SESSION_ALREADY_ACTIVE`
- `SESSION_NOT_FOUND`
- `SESSION_NOT_FINISHABLE`
- `SESSION_VALIDATION_PENDING`
- `SESSION_NOT_VALID`

### 8.5 签到 / streak
- `CHECK_IN_ALREADY_DONE`
- `CHECK_IN_NOT_ALLOWED`

### 8.6 结算
- `SETTLEMENT_NOT_FOUND`
- `SETTLEMENT_IN_PROGRESS`
- `SETTLEMENT_RETRY_NOT_ALLOWED`
- `REWARD_LEDGER_WRITE_FAILED`

---

## 9. 接口清单总览

| 组 | 接口 | 方法 | 目的 |
|---|---|---|---|
| Auth | `/auth/guest-sessions` | POST | 创建游客身份 |
| Auth | `/auth/email-sessions` | POST | 邮箱登录（MVP 占位） |
| Book | `/word-books` | GET | 获取可选词书 |
| Book | `/me/book-settings` | PUT | 设置当前词书与每日目标 |
| Today | `/me/today` | GET | 今日页聚合查询 |
| New Study | `/me/new-words/next` | GET | 获取下一条新词 |
| New Study | `/study-attempts` | POST | 提交新词学习结果 |
| Review | `/me/review-groups/next` | GET | 获取下一组复习 |
| Review | `/review-attempts` | POST | 提交复习结果 |
| Session | `/sessions` | POST | 启动 Session |
| Session | `/sessions/{session_id}/finish` | POST | 结束 Session 并进入校验 |
| Session | `/sessions/{session_id}` | GET | 查询 Session 状态 |
| Check-in | `/check-ins` | POST | 每日签到 |
| Settlement | `/settlements/learning-rounds` | POST | 触发 / 复用主机制结算 |
| Settlement | `/settlements/{source_event_id}` | GET | 查询结算状态 |
| Stats | `/me/stats/summary` | GET | 统计页基础汇总 |
| Secondary | `/me/secondary-summary` | GET | 获取副机制最小摘要真相层 |
| Secondary | `/me/feed` | POST | 喂猫并返回最新副机制状态 |
| Shop | `/shop/catalog` | GET | 获取当前目录项 |
| Shop | `/shop/purchases` | POST | 购买目录项 |
| Inventory | `/me/inventory` | GET | 获取已拥有物品 |
| Equipment | `/me/equipment` | GET | 获取当前装备状态 |
| Equipment | `/me/equipment/equip` | POST | 装备物品到指定槽位 |
| Equipment | `/me/equipment/unequip` | POST | 卸下指定槽位物品 |

---

## 10. 认证与基础身份

# 10.1 POST `/auth/guest-sessions`

## 10.1.1 目标
支持游客模式快速进入主链路。

## 10.1.2 权限要求
- 无需登录

## 10.1.3 请求体
```json
{
  "device_id": "device_123",
  "timezone": "America/Toronto",
  "locale": "zh-CN"
}
```

## 10.1.4 返回
```json
{
  "user_id": "uuid",
  "access_token": "token",
  "account_type": "guest",
  "user_timezone": "America/Toronto"
}
```

## 10.1.5 错误码
- `INVALID_ARGUMENT`
- `INTERNAL_ERROR`

## 10.1.6 幂等要求
- 同一设备首次创建允许复用同一游客账号；
- 若后续改为“一设备一游客”，服务端需保证幂等返回。

---

# 10.2 POST `/auth/email-sessions`

## 10.2.1 目标
为 MVP 留登录契约入口。

## 10.2.2 请求体
```json
{
  "email": "user@example.com",
  "password": "***"
}
```

## 10.2.3 返回
```json
{
  "user_id": "uuid",
  "access_token": "token",
  "account_type": "email"
}
```

## 10.2.4 错误码
- `AUTH_REQUIRED`
- `INVALID_ARGUMENT`
- `FORBIDDEN`

---

## 11. 词书与学习目标设置

# 11.1 GET `/word-books`

## 11.1.1 目标
返回当前可用词书列表。

## 11.1.2 返回
```json
{
  "items": [
    {
      "book_id": "uuid",
      "code": "ielts_core",
      "name": "IELTS Core",
      "difficulty": "medium",
      "is_active": true
    }
  ]
}
```

## 11.1.3 错误码
- `AUTH_REQUIRED`
- `INTERNAL_ERROR`

---

# 11.2 PUT `/me/book-settings`

## 11.2.1 目标
设置当前 active 词书与每日新词目标。

## 11.2.2 请求体
```json
{
  "book_id": "uuid",
  "daily_new_target": 20,
  "daily_review_target_mode": "auto",
  "daily_review_target_value": null
}
```

## 11.2.3 返回
```json
{
  "book_id": "uuid",
  "book_name": "IELTS Core",
  "daily_new_target": 20,
  "daily_review_target_mode": "auto",
  "daily_review_target_value": null,
  "updated_at": "2026-04-02T15:00:00Z"
}
```

## 11.2.4 错误码
- `AUTH_REQUIRED`
- `BOOK_NOT_AVAILABLE`
- `INVALID_DAILY_TARGET`

## 11.2.5 幂等要求
- 相同 payload + 相同 idempotency key 重试返回同一结果；
- 不允许因重试生成多个 active setting。

---

## 12. 今日页聚合

# 12.1 GET `/me/today`

## 12.1.1 目标
为今日页返回一次性可渲染的聚合数据。

## 12.1.2 请求参数
无

## 12.1.3 返回
```json
{
  "server_time_utc": "2026-04-02T15:00:00Z",
  "user_timezone": "America/Toronto",
  "user_local_date": "2026-04-02",
  "current_book": {
    "book_id": "uuid",
    "book_name": "IELTS Core"
  },
  "daily_goal": {
    "today_new_target": 20,
    "today_new_completed": 8,
    "today_review_target": 10,
    "today_review_pending": 6,
    "today_review_completed": 4,
    "daily_goal_status": "partially_completed",
    "goal_status_reason": "new_done_review_pending"
  },
  "check_in": {
    "has_checked_in_today": true,
    "check_in_id": "uuid",
    "checked_in_at": "2026-04-02T08:03:00Z",
    "streak_node_reward_preview": {
      "day": 7,
      "reward_code": "hat_special_01"
    }
  },
  "learning_day": {
    "has_learning_day_today": false,
    "effective_attempt_count": 0,
    "fact_source": "server_aggregated"
  },
  "streak": {
    "current_streak": 3,
    "max_streak": 7,
    "streak_basis_type": "check_in",
    "last_counted_local_date": "2026-04-02"
  },
  "session": {
    "has_active_session": false,
    "session_valid_today": false,
    "session_started_today": true,
    "last_session_validation_status": "invalid"
  },
  "last_reward_settlement": {
    "source_event_id": "uuid",
    "reward_settlement_status": "succeeded"
  },
  "cat_summary_brief": {
    "mood_label": "状态不错",
    "energy_label": "今天有在认真学"
  },
  "sync_status": "healthy"
}
```

## 12.1.4 契约说明（v0.1.2）
- `daily_goal.daily_goal_status` 已按冻结口径产出：只看新词目标 + 今日复习要求。
- `check_in.has_checked_in_today=true` 只代表签到事实成立，不等同有效学习日。
- `learning_day.has_learning_day_today=true` 只代表 learning day 事实成立，不要求签到已发生。
- `streak.current_streak` 当前按 `streak_basis_type=check_in` 延续。
- `session.session_valid_today` 与 `session.last_session_validation_status` 只代表 Session 相关状态，不回写为 `daily_goal_status`。
- `last_reward_settlement.reward_settlement_status` 仅表示最近一次页面级结算状态；不等同所有奖励项均已到账。

## 12.1.5 UI 关键字段映射
本接口必须覆盖至少以下字段：
- `current_book_name`
- `today_new_target`
- `today_new_completed`
- `today_review_target`
- `today_review_pending`
- `today_review_completed`
- `daily_goal_status`
- `has_checked_in_today`
- `has_learning_day_today`
- `current_streak`
- `streak_basis_type`
- `streak_node_reward_preview`
- `session_valid_today`
- `session_started_today`
- `session_validation_status`
- `reward_settlement_status`
- `cat_summary_brief`
- `sync_status`

## 12.1.6 错误码
- `AUTH_REQUIRED`
- `ACTIVE_BOOK_NOT_SET`
- `UPSTREAM_SYNC_DELAY`
- `INTERNAL_ERROR`

## 12.1.7 幂等要求
- 读接口，无幂等键要求。

---

## 13. 新词学习

# 13.1 GET `/me/new-words/next`

## 13.1.1 目标
返回当前 active 词书中下一条可学习新词。

## 13.1.2 请求参数
- `session_id`（optional, uuid）

## 13.1.3 返回
```json
{
  "word_id": "uuid",
  "word_text": "abandon",
  "phonetic": "/əˈbændən/",
  "meaning": "放弃",
  "example_sentence": "He decided to abandon the plan.",
  "audio_url": "https://...",
  "progress_current": 8,
  "progress_target": 20,
  "session_id": "uuid"
}
```

## 13.1.4 错误码
- `AUTH_REQUIRED`
- `ACTIVE_BOOK_NOT_SET`
- `WORD_NOT_AVAILABLE`

---

# 13.2 POST `/study-attempts`

## 13.2.1 目标
提交单条新词学习结果，写入事实层并更新聚合进度。

## 13.2.2 请求体
```json
{
  "word_id": "uuid",
  "book_id": "uuid",
  "session_id": "uuid",
  "study_type": "new",
  "action_result": "know"
}
```

## 13.2.3 返回
```json
{
  "attempt_id": "uuid",
  "submit_status": "accepted",
  "is_effective_learning": true,
  "progress_current": 9,
  "progress_target": 20,
  "daily_goal_status": "in_progress",
  "session_snapshot": {
    "session_id": "uuid",
    "effective_learning_count": 5,
    "effective_review_count": 0,
    "session_validation_status": "pending"
  },
  "review_queue_effect": {
    "added_to_review_queue": true
  }
}
```

## 13.2.4 错误码
- `AUTH_REQUIRED`
- `INVALID_ARGUMENT`
- `WORD_NOT_AVAILABLE`
- `STUDY_ATTEMPT_ALREADY_RECORDED`
- `ATTEMPT_SUBMIT_FAILED`

## 13.2.5 幂等要求
- 必须带 `X-Idempotency-Key`
- 同一 attempt 重试只写一次 `study_attempts`
- 不得重复增加 `completed_new_count`
- 不得重复生成奖励来源事件

## 13.2.6 权限要求
- 必须是当前登录用户自己的词书和学习记录

---

## 14. 复习

# 14.1 GET `/me/review-groups/next`

## 14.1.1 目标
返回今日下一组复习内容。

## 14.1.2 请求参数
- `session_id`（optional, uuid）

## 14.1.3 返回
```json
{
  "review_group_id": "uuid",
  "group_status": "active",
  "group_size_total": 5,
  "group_size_completed": 2,
  "group_size_remaining": 3,
  "review_queue_count": 6,
  "review_progress_current": 4,
  "review_progress_target": 10,
  "items": [
    {
      "review_item_id": "uuid",
      "word_id": "uuid",
      "question_type": "choice_cn",
      "prompt": "abandon",
      "options": ["放弃", "坚持", "重复", "隐藏"],
      "answer_input_schema": null
    }
  ],
  "session_id": "uuid"
}
```

## 14.1.4 契约说明（v0.1.2）
- `review_group_id` 现在不只是最小主键占位，而是稳定 group 对象标识。
- 同一用户同一时刻只允许一个 `group_status=active` 的 group。
- `group_size_remaining` 仅表示当前组剩余 item 数；不得由前端用它单独推断“今日复习完成”。
- review group 的详细生成算法、group size 数值与 review priority 仍属 pending。

## 14.1.5 错误码
- `AUTH_REQUIRED`
- `REVIEW_GROUP_NOT_AVAILABLE`

---

# 14.2 POST `/review-attempts`

## 14.2.1 目标
提交复习作答结果，更新复习队列与今日复习进度。

## 14.2.2 请求体
```json
{
  "review_group_id": "uuid",
  "review_item_id": "uuid",
  "word_id": "uuid",
  "question_type": "choice_cn",
  "answer": "放弃",
  "session_id": "uuid"
}
```

## 14.2.3 返回
```json
{
  "attempt_id": "uuid",
  "submit_status": "accepted",
  "is_correct": true,
  "is_effective_review": true,
  "review_group": {
    "review_group_id": "uuid",
    "group_status": "active",
    "group_completed": false,
    "group_size_total": 5,
    "group_size_completed": 3,
    "group_size_remaining": 2
  },
  "today_review_progress": {
    "review_progress_current": 5,
    "review_progress_target": 10,
    "daily_goal_status": "partially_completed"
  },
  "session_snapshot": {
    "session_id": "uuid",
    "effective_learning_count": 0,
    "effective_review_count": 2,
    "session_validation_status": "pending"
  }
}
```

## 14.2.4 契约说明（v0.1.2）
- `review_group.group_completed=true` 只表示当前 group 已完成且完成结果已被服务端唯一确认。
- `review_group.group_completed=true` **不自动等于** `today_review_progress.daily_goal_status=completed`。
- 同一 group 允许跨 Session 继续完成，但不得重复推进今日复习进度、不得重复结算、不得重复发奖。

## 14.2.5 错误码
- `AUTH_REQUIRED`
- `INVALID_ARGUMENT`
- `REVIEW_ITEM_NOT_AVAILABLE`
- `ATTEMPT_SUBMIT_FAILED`

## 14.2.6 幂等要求
- 同一作答提交只允许落一次事实；
- 重试不得重复推进 `completed_review_count`；
- 题目级重复点击返回同一 attempt 结果。

---

## 15. Session

# 15.1 POST `/sessions`

## 15.1.1 目标
启动一个 Session。

## 15.1.2 请求体
```json
{
  "session_type": "focus_15m",
  "planned_duration_seconds": 900
}
```

## 15.1.3 返回
```json
{
  "session_id": "uuid",
  "session_status": "started",
  "session_validation_status": "pending",
  "planned_duration_seconds": 900,
  "required_effective_attempts": 5,
  "started_at": "2026-04-02T15:00:00Z"
}
```

## 15.1.4 错误码
- `AUTH_REQUIRED`
- `SESSION_ALREADY_ACTIVE`
- `INVALID_ARGUMENT`

## 15.1.5 幂等要求
- 相同 key 重试返回同一 `session_id`
- 不允许创建多个并发 active session

---

# 15.2 POST `/sessions/{session_id}/finish`

## 15.2.1 目标
结束 Session，并把状态推进到 `ended` / `validating` / `valid` / `invalid`。

## 15.2.2 请求体
```json
{
  "ended_at_client": "2026-04-02T15:15:10Z"
}
```

## 15.2.3 返回
```json
{
  "session_id": "uuid",
  "session_status": "validating",
  "session_validation_status": "pending",
  "effective_learning_count": 3,
  "effective_review_count": 2,
  "effective_attempts_total": 5,
  "required_effective_attempts": 5,
  "actual_duration_seconds": 910,
  "planned_duration_seconds": 900,
  "reward_settlement_status": "pending",
  "jump_targets_available": ["today", "settlement"]
}
```

## 15.2.4 契约说明（v0.1.1）
- `reward_settlement_status` 在 v0.1.1 中正式替代旧的 `reward_status` 页面级写法。
- `session_validation_status=pending` 只表示“校验未最终完成”，不代表 `valid`。
- Session 是否最终 `valid` 必须同时满足 15 分钟阈值与至少 5 次 effective attempts。

## 15.2.5 错误码
- `AUTH_REQUIRED`
- `SESSION_NOT_FOUND`
- `SESSION_NOT_FINISHABLE`

## 15.2.6 幂等要求
- 同一 finish 请求只能推进一次；
- 重试不得重复触发 session source event。

## 15.2.7 说明
- 允许 finish 后先进入 `validating`，再由查询接口 / 结算接口读最终状态；
- 若服务端可同步完成校验，也可直接返回 `valid` 或 `invalid`。

---

# 15.3 GET `/sessions/{session_id}`

## 15.3.1 目标
供 Session 页面和结算层轮询最终校验状态。

## 15.3.2 返回
```json
{
  "session_id": "uuid",
  "session_status": "valid",
  "session_validation_status": "valid",
  "validation_reason": null,
  "effective_learning_count": 3,
  "effective_review_count": 2,
  "effective_attempts_total": 5,
  "required_effective_attempts": 5,
  "planned_duration_seconds": 900,
  "actual_duration_seconds": 910,
  "reward_settlement_status": "succeeded",
  "started_at": "2026-04-02T15:00:00Z",
  "ended_at": "2026-04-02T15:15:10Z",
  "validated_at": "2026-04-02T15:15:11Z"
}
```

## 15.3.3 契约说明
- `reward_settlement_status` 只代表 Session 这一轮相关来源事件的页面级结算状态。
- 若需要看具体奖励项到账情况，必须去 settlement 详情接口读取 `reward_items[].reward_status`。

## 15.3.4 错误码
- `AUTH_REQUIRED`
- `SESSION_NOT_FOUND`

---

## 16. 签到与 streak

# 16.1 POST `/check-ins`

## 16.1.1 目标
完成用户当天签到，并返回 streak 结果。

## 16.1.2 请求体
空体

## 16.1.3 返回
```json
{
  "check_in": {
    "check_in_id": "uuid",
    "checked_in": true,
    "checked_in_at": "2026-04-02T15:01:00Z",
    "user_local_date": "2026-04-02"
  },
  "learning_day": {
    "has_learning_day_today": false,
    "effective_attempt_count": 0
  },
  "streak": {
    "current_streak": 3,
    "max_streak": 7,
    "streak_basis_type": "check_in",
    "streak_extended_today": true
  },
  "node_reward": {
    "reward_code": null,
    "reward_settlement_status": "pending"
  }
}
```

## 16.1.4 契约说明（v0.1.2）
- `check_in.checked_in=true` 只表示签到事实成立。
- `learning_day.has_learning_day_today` 是独立事实，不由签到动作自动外推。
- `streak.current_streak` 当前按 `streak_basis_type=check_in` 延续。
- 当前 API **不得**把签到成功写成“有效学习日已成立”或“今日学习已完成”。
- 允许出现：
  - `check_in.checked_in=true` 且 `learning_day.has_learning_day_today=false`
  - `check_in.checked_in=false` 且 `learning_day.has_learning_day_today=true`

## 16.1.5 错误码
- `AUTH_REQUIRED`
- `CHECK_IN_ALREADY_DONE`
- `CHECK_IN_NOT_ALLOWED`

## 16.1.6 幂等要求
- 同一天重复签到请求只产生一个 `check_in_record`
- 重试返回同一签到结果，不得重复增加 streak 或重复发节点奖励

## 16.1.7 权限要求
- 仅登录用户自身

---

## 17. 主机制结算

# 17.1 POST `/settlements/learning-rounds`

## 17.1.1 目标
为主机制结算浮层提供统一触发接口：
- 新词完成一轮
- 复习完成一组
- Session 完成
- 今日目标完成
- 签到后节点奖励

都通过本接口进入“source event → ledger”结算链。

## 17.1.2 请求体
```json
{
  "settlement_source_type": "review_group_completed",
  "source_ref_id": "uuid"
}
```

## 17.1.3 `settlement_source_type` 建议枚举
- `new_word_round_completed`
- `review_group_completed`
- `session_finished`
- `daily_goal_completed`
- `check_in_completed`

> 说明：这是 API 层触发语义；落到 DB 层时可能映射成更细的 `reward_source_events.source_event_type`。

## 17.1.4 返回
```json
{
  "source_event_id": "uuid",
  "settlement_source_type": "review_group_completed",
  "reward_settlement_status": "settling",
  "effective_learning_count": 0,
  "effective_review_count": 5,
  "daily_goal_status": "partially_completed",
  "session_validation_status": "pending",
  "reward_items": [
    {
      "reward_type": "coins",
      "reward_amount": 5,
      "reward_status": "pending"
    }
  ],
  "cat_growth_summary": null,
  "jump_targets_available": ["today", "cat_home"]
}
```

## 17.1.5 结算边界说明（v0.1.1）
- 本接口只服务“主机制结算浮层”的数据承接。
- `reward_settlement_status` 表示来源事件结算状态，不等同所有奖励项都到账。
- `reward_items[].reward_status` 才表示账本项级到账状态。
- `cat_growth_summary` 只允许轻量摘要；不得承载副机制深操作所需的完整互动数据。
- `jump_targets_available` 只能给弱次级承接入口，不得把结算层升级成副机制详情页。

## 17.1.6 UI 关键字段映射
本接口必须覆盖至少以下字段：
- `settlement_source_type`
- `effective_learning_count`
- `effective_review_count`
- `daily_goal_status`
- `session_validation_status`
- `reward_items[]`
- `reward_settlement_status`
- `cat_growth_summary(optional)`
- `jump_targets_available`

## 17.1.7 错误码
- `AUTH_REQUIRED`
- `INVALID_ARGUMENT`
- `SETTLEMENT_IN_PROGRESS`
- `RESOURCE_NOT_FOUND`
- `REWARD_LEDGER_WRITE_FAILED`

## 17.1.8 幂等要求
- 必须带 `X-Idempotency-Key`
- 相同 source + 相同 key 只能创建 / 复用同一个 `reward_source_event`
- 不得重复发 Coins / Fish Treats / EXP

## 17.1.9 权限要求
- 仅允许对当前用户拥有的 source_ref 发起结算

---

# 17.2 GET `/settlements/{source_event_id}`

## 17.2.1 目标
供结算浮层轮询到账结果或刷新补齐状态。

## 17.2.2 返回
```json
{
  "source_event_id": "uuid",
  "reward_settlement_status": "succeeded",
  "reward_items": [
    {
      "reward_type": "coins",
      "reward_amount": 5,
      "reward_status": "succeeded"
    },
    {
      "reward_type": "fish_treat",
      "reward_amount": 1,
      "reward_status": "succeeded"
    }
  ],
  "settled_at": "2026-04-02T15:20:00Z"
}
```

## 17.2.3 契约说明
- 页面级 `reward_settlement_status=succeeded` 只表示该来源事件结算流程已完成。
- 若未来存在部分到账 / 补偿场景，仍以 `reward_items[].reward_status` 为单项真相源。

## 17.2.4 错误码
- `AUTH_REQUIRED`
- `SETTLEMENT_NOT_FOUND`

---

## 18. 统计页基础查询

# 18.1 GET `/me/stats/summary`

## 18.1.1 目标
给统计页 MVP 提供基础汇总，不做复杂 BI。

## 18.1.2 返回
```json
{
  "today": {
    "learned_new_count": 8,
    "reviewed_count": 4,
    "valid_session_count": 0,
    "has_learning_day_today": true
  },
  "week": {
    "learning_days": 3
  },
  "all_time": {
    "total_learned_words": 120,
    "total_review_count": 60,
    "current_streak": 3,
    "streak_basis_type": "check_in",
    "total_learning_days": 15,
    "mastered_word_count": 40
  }
}
```

## 18.1.3 错误码
- `AUTH_REQUIRED`
- `INTERNAL_ERROR`

## 18.1.4 说明
- 统计页完整规格仍未冻结；本接口继续只提供基础汇总，不反向扩大本轮范围。
- `total_learning_days` 来自独立 `learning_day` 聚合，不要求与 `current_streak` 使用同一 basis。
- 当前 MVP 下 `current_streak` 的解释必须受 `streak_basis_type=check_in` 约束。

---

## 19. 接口与表的映射关系

| 接口 | 主要读写表 |
|---|---|
| `POST /study-attempts` | `study_attempts`, `user_word_progress`, `review_queue`, `daily_goal_progress` |
| `GET /me/review-groups/next` | `review_groups`, `review_group_items`, `review_queue`, `user_word_progress` |
| `POST /review-attempts` | `study_attempts`, `review_groups`, `review_group_items`, `review_queue`, `user_word_progress`, `daily_goal_progress` |
| `POST /sessions` | `session_records` |
| `POST /sessions/{id}/finish` | `session_records`, `study_attempts`（聚合校验） |
| `POST /check-ins` | `check_in_records`, `learning_day_facts`, `streak_records`, `reward_source_events(optional)` |
| `POST /settlements/learning-rounds` | `reward_source_events`, `reward_ledger`, `daily_goal_progress`, `session_records(optional)`, `review_groups(optional)` |
| `GET /me/today` | `daily_goal_progress`, `check_in_records`, `learning_day_facts`, `streak_records`, `session_records`, `reward_source_events`, `user_book_settings` |
| `GET /me/stats/summary` | `learning_stat_daily`, `learning_day_facts`, `streak_records`, `user_word_progress` |

---

## 20. UI / API / DB 最小命名映射（v0.1.2）

| UI 使用名 | API 字段建议 | DB 来源建议 |
|---|---|---|
| `daily_goal_status` | `daily_goal.daily_goal_status` / 等价聚合字段 | `daily_goal_progress.goal_status` |
| `session_validation_status` | `session_validation_status` / `last_session_validation_status` | `session_records.validation_status` |
| `reward_settlement_status` | `last_reward_settlement.reward_settlement_status` 或 settlement API 返回字段 | `reward_source_events.settlement_status` |
| `reward_items[].reward_status` | `reward_items[].reward_status` | `reward_ledger.status` |
| `has_checked_in_today` | `check_in.has_checked_in_today` | `check_in_records` |
| `has_learning_day_today` | `learning_day.has_learning_day_today` | `learning_day_facts` |
| `current_streak` | `streak.current_streak` | `streak_records.current_streak` |
| `streak_basis_type` | `streak.streak_basis_type` | `streak_records.streak_basis_type` |
| `session_valid_today` | `session.session_valid_today` | `session_records` 聚合 |
| `session_started_today` | `session.session_started_today` | `session_records` 聚合 |
| `group_completed` | `review_group.group_completed` | `review_groups.group_status` / group completion 聚合 |
| `group_size_remaining` | `review_group.group_size_remaining` | `review_group_items` / `review_groups` 聚合 |

> 说明：
> 1. 本表继续沿用 v0.1.1 的主命名统一，不回退到旧主叫法。
> 2. `check_in` / `learning_day` / `streak` 现在必须能被分开读取；前端不得再把签到语义外推成 learning day。
> 3. 若后续 API 局部字段名再微调，以 Room 1 pin 的 active API 为准，但 API 主口径不再回退到旧命名。

---

## 21. NFR / 工程要求（API 侧）

## 21.1 性能目标（MVP）
- `GET /me/today`：P95 < 300ms
- `GET /me/new-words/next`：P95 < 250ms
- `POST /study-attempts` / `POST /review-attempts`：P95 < 350ms
- `POST /check-ins`：P95 < 300ms
- `GET /settlements/{source_event_id}`：P95 < 250ms

## 21.2 一致性要求
- 写成功后，同步读今日页允许极短延迟，但不得长时间矛盾；
- 若发生异步结算，必须显式返回 `reward_settlement_status != succeeded`，不能假装到账；
- `daily_goal_status` 与 `session_validation_status` 的最终判定必须来自后端聚合与校验，不允许客户端本地推导覆盖。

## 21.3 重试与补偿
- 学习 / 复习提交失败：允许客户端用相同幂等键重试
- 结算失败：允许保留 source event 并后续补偿
- 前端必须能处理“结果已记录，奖励待补齐”场景

## 21.4 观测性
每个关键接口至少打点：
- `request_id`
- `user_id`
- `endpoint`
- `latency_ms`
- `status_code`
- `idempotency_hit`（写接口）
- `reward_source_event_id`（若相关）
- `session_id`（若相关）

---

## 22. Room 4 实现注意事项（API 侧）

1. `daily_goal_status` 的 completed / partially_completed 必须只吃后端聚合结果，前端不得按本地计数直接拼。
2. `session_validation_status` 与 `session_status` 不可混用；started / ended 都不等同 valid。
3. `reward_settlement_status` 与 `reward_items[].reward_status` 不可混用；前者是来源事件层，后者是账本项层。
4. `POST /check-ins` 与 `GET /me/today` 现在都必须允许分别读取 `check_in`、`learning_day`、`streak` 三类事实；不得再把签到语义外推成 learning day。
5. `review_group` 现在是稳定对象：实现时必须支持单用户单 active group、group completion 唯一确认、跨 Session 继续但不重复推进。
6. `group_completed` 必须以后端结果返回，不要让前端仅用 `remaining=0` 自己猜。
7. `streak_basis_type` 当前 MVP 冻结为 `check_in`；实现时不要默默切到 learning-day-based。

---

## 23. 本轮 change log

### v0.1.2 (2026-04-02)
- 基于 `R1_Decision_Pack_D-OPP-001-010_011.md` 与 `背单词喵喵app_DB设计草案_v0.1.3.md` 做最小 API write-back，不重写 v0.1.1 已稳定的主链路接口面。
- Based-on / metadata 更新到 `Main.md`（current runtime: `Main_updated_2026-04-02_v4.md`）与 `OPP-001_STATUS.md`（current runtime: `STATUS_updated_2026-04-02_v3.md`），消除旧 runtime 引用残留。
- 把 `review_group` 从“只有 id 的偏薄表达”升级为稳定对象表达：新增 / 明确 `group_status`、`group_completed`、`group_size_total`、`group_size_completed`、`group_size_remaining`。
- 在 `POST /review-attempts` 返回中增加 `today_review_progress` 分层返回，正式写硬“本组完成只推进今日复习进度，不自动等于今日完成”。
- 把 `check_in / learning_day / streak` 的三事实分离正式回写到 `GET /me/today`、`POST /check-ins` 与 `GET /me/stats/summary`。
- 正式写硬 `streak_basis_type = check_in` 与 `local_date / timezone` 统一自然日口径。
- 同步更新接口与表映射、UI / API / DB 命名映射，以及 Room 4 实现注意事项。

### v0.1.1 (2026-04-02)
- Based-on 更新为 `UI_SPEC_v0.1.1`、`BR-OPP-001_v0.1.1`、`DB设计草案_v0.1.1`、最新 `Main`
- 把 `daily_goal_status` 从 pending 改为已冻结口径：只看新词目标 + 复习要求，复习为空自然满足，不含签到 / Session
- 把 `session_validation_status` 从 pending 改为已冻结 MVP 阈值：15 分钟 + 至少 5 次 effective attempts + 正常 started/ended
- 把主机制结算层 vs 副机制承接页边界正式回写到 API 语义层：结算层只承接本轮学习结果与轻量摘要，不承载副机制深操作
- 命名统一到 `daily_goal_status` / `session_validation_status` / `reward_settlement_status`
- `POST /sessions/{id}/finish` 与 `GET /sessions/{id}` 正式把页面级旧字段 `reward_status` 替换为 `reward_settlement_status`
- 新增 UI / API / DB 最小命名映射表，确保 Room 4 不再手工适配旧叫法
- 保留真正仍未冻结的 pending：熟练度、SRS / review priority / review group、签到与 learning day / streak 强关联、CTA winner rule、统计页范围扩展

### v0.1 (2026-04-01)
- 首版 API 草案，完成主机制主链路、今日页聚合、学习/复习提交、Session、签到、结算与基础统计查询的最小闭环设计

---

## 24. 当前版本信息

- **This file:** `API设计草案_v0.1.3.md`
- **Replaces as latest draft:** `API设计草案_v0.1.2.md`
- **Suggested next step:** Room 1 将本稿纳入下一轮 active API 候选；Room 4 后续若继续推进 P2 / production hardening，应在本稿基础上做小步增量 sync，而不是回退到实现代码里的隐性真相层。


---

## 25. P2 secondary mechanism incremental write-back（v0.1.3）

### 25.1 本轮 patch 定位
本轮不重写 `v0.1.2` 已稳定的主机制接口面，只把 Room 4 在 `R4_P2_final_delivery_package_v0.1.md` 中已经实现并验证过的 **P2 minimum backend truth** 正式回写到 API 技术基线。

### 25.2 新增 / 正式回写的副机制最小接口

#### 25.2.1 `GET /me/secondary-summary`
**目标：** 为 Meow Home / Customize 提供当前副机制最小真相层。

**返回建议：**
```json
{
  "balances": {
    "coins": 120,
    "fish_treats": 4,
    "exp": 78
  },
  "cat_summary": {
    "nickname": "喵喵",
    "level": 3,
    "total_exp": 78,
    "mood": 64,
    "bond": 22,
    "energy": 55
  },
  "companion_response": {
    "daily_greeting": "今天也一起学一点吧。",
    "post_learning_response": "刚刚那轮学得不错。",
    "streak_node_response": null
  },
  "equipped_preview": [
    {"slot_key": "hat", "item_code": "cap_blue", "display_name": "蓝色小帽"}
  ],
  "motivation_facts": {
    "has_checked_in_today": true,
    "has_learning_day_today": true,
    "current_streak": 3,
    "streak_basis_type": "check_in",
    "session_valid_today": false
  }
}
```

**本轮冻结：** 这必须是后端 read model；前端不得通过 reward history、本地缓存或页面状态拼“当前余额 / 当前猫猫状态 / 当前已装备真相”。

#### 25.2.2 `POST /me/feed`
**目标：** 消耗 1 个 fish treat，更新 pet-facing 状态并返回最新 balances / cat summary / growth feedback。

**请求体建议：**
```json
{
  "consumed_item_type": "fish_treat"
}
```

**返回建议：**
```json
{
  "submit_status": "accepted",
  "benefit_tier": "full",
  "balances": {
    "coins": 120,
    "fish_treats": 3,
    "exp": 80
  },
  "cat_summary": {
    "level": 3,
    "total_exp": 80,
    "mood": 68,
    "bond": 23,
    "energy": 55
  },
  "growth_feedback": {
    "level_up": false,
    "exp_delta": 2,
    "mood_delta": 4,
    "bond_delta": 1
  }
}
```

**错误码建议：** `FISH_TREATS_NOT_ENOUGH`、`PET_PROFILE_NOT_FOUND`、`IDEMPOTENCY_KEY_REUSED_WITH_DIFFERENT_PAYLOAD`。

> 说明：当前 benefit 数值仍视为 **dev rules**；本稿只冻结 API 能力与状态表达，不冻结具体数值。

#### 25.2.3 `GET /shop/catalog`
**目标：** 返回当前可见目录项、价格、level lock 与基础展示元数据。

#### 25.2.4 `POST /shop/purchases`
**目标：** 购买目录项并建立 ownership truth。

**请求体建议：**
```json
{
  "item_code": "cap_blue"
}
```

**错误码建议：** `CATALOG_ITEM_NOT_FOUND`、`ITEM_ALREADY_OWNED`、`ITEM_LEVEL_LOCKED`、`COINS_NOT_ENOUGH`。

#### 25.2.5 `GET /me/inventory`
**目标：** 返回当前已拥有物品。

#### 25.2.6 `GET /me/equipment`
**目标：** 返回当前装备槽位状态。

#### 25.2.7 `POST /me/equipment/equip`
**目标：** 装备一个 inventory item 到对应槽位。

#### 25.2.8 `POST /me/equipment/unequip`
**目标：** 卸下指定槽位当前物品。

### 25.3 本轮新增的副机制错误码建议
- `SECONDARY_SUMMARY_NOT_READY`
- `PET_PROFILE_NOT_FOUND`
- `FISH_TREATS_NOT_ENOUGH`
- `FEED_NOT_ALLOWED`
- `CATALOG_ITEM_NOT_FOUND`
- `ITEM_ALREADY_OWNED`
- `ITEM_LEVEL_LOCKED`
- `COINS_NOT_ENOUGH`
- `INVENTORY_ITEM_NOT_FOUND`
- `ITEM_NOT_EQUIPPABLE`
- `SLOT_NOT_FOUND`

### 25.4 本轮新增的接口与表映射
- `GET /me/secondary-summary` → `secondary_wallets`, `pet_profiles`, `user_equipment_slots`, `user_inventory_items`, `shop_catalog_items`, `check_in_records`, `learning_day_facts`, `streak_records`, `session_records`
- `POST /me/feed` → `pet_feed_events`, `secondary_wallets`, `pet_profiles`
- `GET /shop/catalog` → `shop_catalog_items`
- `POST /shop/purchases` → `shop_catalog_items`, `shop_purchase_events`, `secondary_wallets`, `user_inventory_items`
- `GET /me/inventory` → `user_inventory_items`, `shop_catalog_items`
- `GET /me/equipment` → `user_equipment_slots`, `user_inventory_items`, `shop_catalog_items`
- `POST /me/equipment/equip` / `unequip` → `user_equipment_slots`, `user_inventory_items`, `shop_catalog_items`

### 25.5 本轮冻结与不冻结边界
**本轮冻结：**
1. P2 当前余额 / pet state / ownership / equipped state 都以后端为准。
2. `feed / purchase / equip` 都必须是后端命令，不是前端幻觉。
3. API 可以表达“当前 runtime truth 可跨 restart 保存”，但不得把 file-backed JSON 写成 production-grade persistence 已完成。

**本轮不冻结：**
1. feed 数值、level thresholds、catalog 内容、copy system
2. interaction action
3. room coordinate placement
4. production DB migration 方案 / 多设备同步

### 25.6 Room 4 实现注意事项（补充）
1. `secondary_summary` 是 P2 当前唯一推荐副机制摘要入口；Meow Home / Customize 不要自己拼 balances / pet state。
2. `feed / purchase / equip` 都应要求幂等键，避免按钮重复点击造成“先本地成功、后端再回滚”的幻觉。
3. 当前 dev numbers / copy / catalog 内容可以继续作为可调实现，但接口结构与状态语义应吃本稿固定口径。

### 25.7 当前版本信息补充
- **This patch:** `背单词喵喵app_API设计草案_v0.1.3.md`
- **Replaces as latest draft:** `背单词喵喵app_API设计草案_v0.1.2.md`
- **Suggested next step:** 若 Room 1 接受 P2 closeout，API active pin 建议升到 `v0.1.3`；后续若继续做 P2 polish / production hardening，应在本稿基础上做小步增量 sync，而不是回退到实现代码里的隐性真相层。


## 26. P3.1 direct-scope delta incremental write-back（v0.1.4）

### 26.1 本轮 patch 定位
本轮 `v0.1.4` 不是 full API rewrite，也不是把 P3.1 写成 sync platform。  
本轮只在 `v0.1.3` 的 consolidated baseline 上，增量吸收 **P3.1 direct-scope delta round 已 close** 的 3 个功能对应 API contract：

1. `daily_goal` setting（以 local-first boundary 方式吸收）
2. manual upload / backup
3. manual download-to-local / restore-apply first-shot

### 26.2 Room 2 总体判断
1. 当前需要新增 **backup lane API**
2. 当前需要新增 **restore safety / precheck / apply API**
3. 当前**不**需要为了 `daily_goal` setting 新增一个 server-authoritative daily-goal write endpoint
4. 当前必须把 `upload success / download success / restore success` 三层技术语义写硬，禁止收成模糊 `sync success`

---

### 26.3 新增 / 正式回写的 backup API 面

#### 26.3.1 POST `/me/backups`
##### 目标
手动把当前设备本地 snapshot 上传到云端 backup container。

##### 请求体（conceptual）
```json
{
  "backup_id": "bkp_20260407_xxx",
  "snapshot_scope": "full_local_snapshot",
  "schema_version": "p3_1_v1",
  "snapshot_version": 2,
  "source_app_version": "0.1.x",
  "source_device_label": "iphone-15-pro",
  "payload": {
    "settings": {
      "daily_goal": 30,
      "sound_enabled": true,
      "theme": "light",
      "notification_time": "20:00"
    },
    "progress": {
      "word_records": [],
      "wordbook_progress": [],
      "daily_checkins": [],
      "custom_wordbooks": [],
      "vocabulary_notebook": []
    }
  },
  "checksum_algorithm": "sha256",
  "checksum_value": "sha256_xxx"
}
```

##### 返回（conceptual）
```json
{
  "backup_id": "bkp_20260407_xxx",
  "upload_status": "upload_succeeded",
  "created_at": "2026-04-07T12:00:00Z",
  "schema_version": "p3_1_v1",
  "snapshot_version": 2,
  "source_app_version": "0.1.x",
  "payload_size_bytes": 123456,
  "checksum_algorithm": "sha256",
  "checksum_value": "sha256_xxx"
}
```

##### 契约说明
- `upload_status=upload_succeeded` 只表示上传成功
- 不得把它写成：
  - `sync_succeeded`
  - `all_devices_consistent`
  - `restore_succeeded`

##### 错误码建议
- `BACKUP_PAYLOAD_INVALID`
- `BACKUP_SCHEMA_VERSION_INVALID`
- `BACKUP_CHECKSUM_INVALID`
- `BACKUP_UPLOAD_FAILED`

##### 幂等要求
- 必须要求 `X-Idempotency-Key`
- 同一 snapshot 重试不得制造多个“成功快照”假象

---

#### 26.3.2 GET `/me/backups/latest`
##### 目标
读取最近一次云端备份 metadata，供设置页 / 我的页展示“最近一次备份状态”。

##### 返回（conceptual）
```json
{
  "backup_id": "bkp_20260407_xxx",
  "created_at": "2026-04-07T12:00:00Z",
  "upload_status": "upload_succeeded",
  "schema_version": "p3_1_v1",
  "snapshot_version": 2,
  "source_app_version": "0.1.x",
  "source_device_label": "iphone-15-pro",
  "payload_size_bytes": 123456,
  "checksum_algorithm": "sha256",
  "checksum_value": "sha256_xxx",
  "restorable_hint": true
}
```

##### 契约说明
- `restorable_hint=true` 只表示结构上允许进入 restore-precheck
- 不等于当前本机一定能 restore success
- 不得用它替代 apply success

---

#### 26.3.3 POST `/me/backups/latest/restore-precheck`
##### 目标
在真正 restore / apply 前，先返回 warning / readiness / safety 阻塞信息。

##### 请求体（conceptual）
```json
{
  "target_scope": "current_device_local_store",
  "target_device_label": "iphone-15-pro"
}
```

##### 返回（conceptual）
```json
{
  "backup_id": "bkp_20260407_xxx",
  "schema_version": "p3_1_v1",
  "snapshot_version": 2,
  "source_app_version": "0.1.x",
  "checksum_verified": true,
  "payload_structurally_valid": true,
  "restore_readiness": "ready",
  "warning_required": true,
  "warning_code": "LOCAL_PROGRESS_AND_MIN_SETTINGS_MAY_BE_REPLACED",
  "target_scope": "current_device_local_store"
}
```

##### 契约说明
- 当前 restore/apply 仍是 **manual only**
- pre-check 不等于 download success
- pre-check 不等于 restore success
- pre-check blocked 时不得强行 apply

##### 错误码建议
- `BACKUP_NOT_FOUND`
- `BACKUP_SCHEMA_INCOMPATIBLE`
- `BACKUP_CHECKSUM_INVALID`
- `RESTORE_PRECHECK_BLOCKED`

---

#### 26.3.4 POST `/me/backups/latest/download`
##### 目标
显式完成“download completed / snapshot fetched”这一层动作，并把它与 apply success 分层。

##### 请求体（conceptual）
```json
{
  "target_scope": "current_device_local_store",
  "target_device_label": "iphone-15-pro"
}
```

##### 返回（conceptual）
```json
{
  "backup_id": "bkp_20260407_xxx",
  "download_status": "download_succeeded",
  "schema_version": "p3_1_v1",
  "snapshot_version": 2,
  "payload": {
    "settings": {
      "daily_goal": 30
    },
    "progress": {}
  },
  "checksum_algorithm": "sha256",
  "checksum_value": "sha256_xxx",
  "target_scope": "current_device_local_store"
}
```

##### 契约说明
- `download_status=download_succeeded` 只表示下载层动作成功
- `download completed` 本身**不改变**本地 runtime state
- 不得在 UI / API 上把它写成 `restore_success`

##### 错误码建议
- `BACKUP_NOT_FOUND`
- `BACKUP_DOWNLOAD_FAILED`

---

#### 26.3.5 POST `/me/backups/latest/restore-apply`
##### 目标
在 warning + confirm 之后，确认把已下载 snapshot apply 到当前本机本地持久化层。

##### 请求体（conceptual）
```json
{
  "backup_id": "bkp_20260407_xxx",
  "target_scope": "current_device_local_store",
  "target_device_label": "iphone-15-pro",
  "confirm_overwrite": true,
  "client_checksum_verified": true
}
```

##### 返回（conceptual）
```json
{
  "backup_id": "bkp_20260407_xxx",
  "restore_status": "apply_succeeded",
  "applied_at": "2026-04-07T12:10:00Z",
  "target_scope": "current_device_local_store"
}
```

##### 契约说明
- 当前 restore/apply 仍必须：
  - manual only
  - warning + confirm 前置
  - no silent overwrite
- `restore_status=apply_succeeded` 才允许表达：
  - 当前本机本地持久化层已完成 apply
- 它也**不等于**：
  - sync success
  - full sync enabled

##### 错误码建议
- `RESTORE_CONFIRM_REQUIRED`
- `RESTORE_BLOCKED`
- `BACKUP_SCHEMA_INCOMPATIBLE`
- `BACKUP_CHECKSUM_INVALID`
- `RESTORE_APPLY_FAILED`

##### 幂等要求
- `restore-apply` 作为高风险写操作，必须要求 `X-Idempotency-Key`
- 应支持 request / backup_id / target_scope 级别可追踪

---

### 26.4 `daily_goal` setting 的 API 边界（本轮新增）
#### 26.4.1 当前选择
本轮 **不新增** standalone server-authoritative `PUT /me/settings/daily-goal` 写接口。

#### 26.4.2 原因
因为当前 P3.1 delta 已 pin 的能力边界是：
- local-first
- local immediate effect
- cloud backup 只通过手动 upload 进入云端 snapshot
- 不把 local-first 反写成 always-online account-setting sync

#### 26.4.3 本轮如何吸收 `daily_goal`
API v0.1.4 只在以下位置正式吸收：
1. backup upload payload：`payload.settings.daily_goal`
2. latest backup metadata / restore-precheck / download / restore-apply 的 scope/warning 说明
3. snapshot payload validation

#### 26.4.4 必须继续保持
- `daily_goal` 改动本地即时生效
- 只影响当前生效后的今日 / 后续目标
- 不回溯重算历史日
- `1–500` 当前仅作为 Room 2 recommended validation range，不自动升格为长期 frozen business rule

#### 26.4.5 额外校验（可选但推荐）
若后端在 upload / restore 路径中读取到 `settings.daily_goal`，建议附加：
- `DAILY_GOAL_SNAPSHOT_VALUE_INVALID`

但它表达的是 snapshot payload 校验失败，**不是** server-authoritative daily-goal save endpoint 的业务错误。

---

### 26.5 本轮继续明确不做
1. full sync
2. real-time sync
3. background sync
4. multi-device merge
5. partial restore
6. snapshot picker
7. delete backup
8. clear local
9. destructive actions bundle

---

### 26.6 接口清单总览补充（P3.1 delta）
在既有 8 组接口之外，本轮新增第 9 组：

| 组 | 接口 | 方法 | 目的 |
|---|---|---|---|
| Backup | `/me/backups` | POST | 手动上传本地 snapshot 到云端 backup container |
| Backup | `/me/backups/latest` | GET | 读取最近一次备份 metadata |
| Backup | `/me/backups/latest/restore-precheck` | POST | restore 前安全检查 |
| Backup | `/me/backups/latest/download` | POST | 完成 download 层动作 |
| Backup | `/me/backups/latest/restore-apply` | POST | 完成 restore/apply |

---

### 26.7 错误码总表补充（P3.1 delta）
新增建议错误码：

#### Backup / restore
- `BACKUP_PAYLOAD_INVALID`
- `BACKUP_NOT_FOUND`
- `BACKUP_SCHEMA_VERSION_INVALID`
- `BACKUP_SCHEMA_INCOMPATIBLE`
- `BACKUP_CHECKSUM_INVALID`
- `BACKUP_UPLOAD_FAILED`
- `BACKUP_DOWNLOAD_FAILED`
- `RESTORE_PRECHECK_BLOCKED`
- `RESTORE_CONFIRM_REQUIRED`
- `RESTORE_BLOCKED`
- `RESTORE_APPLY_FAILED`

#### Snapshot payload validation
- `DAILY_GOAL_SNAPSHOT_VALUE_INVALID`

---

### 26.8 UI / API / DB 最小命名映射（P3.1 delta）
- 上传成功：`upload_status=upload_succeeded`
- 下载成功：`download_status=download_succeeded`
- 恢复成功：`restore_status=apply_succeeded`
- 最近一次备份：`latest backup metadata`
- restore 目标：`target_scope=current_device_local_store`
- warning 覆盖范围：`LOCAL_PROGRESS_AND_MIN_SETTINGS_MAY_BE_REPLACED`

---

### 26.9 Room 4 实现注意事项（API 侧补充）
1. 不要把 `download` 与 `restore-apply` 合并成一个模糊成功态
2. `restore-precheck` blocked 时不得进入 `restore-apply`
3. warning + confirm 缺一不可
4. `daily_goal` 当前不新增 server-authoritative settings write endpoint
5. restore apply 的 warning 必须覆盖：
   - progress
   - 最小设置层（例如 `daily_goal`）
6. 不得把 upload / download / restore 文案写成 `sync success`

---

### 26.10 Room 1 吸收建议（Main / Status）
建议 Room 1 在完成 review 后，若接受本稿：

1. **Evidence**
   - Room 2 已交付 `API v0.1.4`，把 P3.1 direct-scope delta 已 close 的 backup / restore / daily_goal 相关 API contract 正式回写进候选基线。

2. **Decision（建议待审）**
   - API active pin 应由 `背单词喵喵app_API设计草案_v0.1.3.md` 升到 `背单词喵喵app_API设计草案_v0.1.4.md`。
   - 当前 API 继续采用：
     - 主机制主链路
     - P2 secondary minimal API
     - P3.1 backup / restore delta API
   - 不把本轮写成 full sync API baseline。

3. **Status**
   - `P3.1 delta round` 的 API write-back 已完成，等待 Room 1 最终 pin active API baseline。

---

### 26.11 结论
本稿在 `v0.1.3` 的 consolidated baseline 上，正式补齐了：
- upload / download / restore success semantics 的 API 分层
- restore-precheck / download / restore-apply 的最小 API 面
- latest backup metadata 的读取面
- `daily_goal` 在 local-first 路线下的 API 边界说明
- checksum / versioning / restore safety 的最小 API contract

**当前判断：**
- 应升级为新的 active API 候选基线
- 不需要重写主机制主链路接口面
- 已足够支撑 Room 1 判断是否更新 active API baseline
