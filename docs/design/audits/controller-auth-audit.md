# Controller Auth Audit — Phase 0 / 需求 23

**Status:** complete (v1.1 — 修订计数错 + 增加 §6 对象归属校验矩阵)
**Scope:** `apps/api/src/controllers/` 全部 23 个控制器、所有 HTTP 路由
**Purpose:** 为 Phase A AuthGuard 实施提供逐路由决策依据
**关联:** [plan-023-用户系统与用户数据隔离-v2.md](../plan-023-用户系统与用户数据隔离-v2.md) §4.1
**日期:** 2026-05-09 (v1.0) → 2026-05-09 (v1.1，吸收两份外部 review)

---

## v1.1 修订记录

| 修订点 | 来源 | 处理 |
|--------|------|------|
| §2.2.1 header "22 条" → "20 条" | review 1+2 | ✅ 采纳，原数字笔误 |
| §2.2.2 header "8 条" → "9 条" | review 1+2 | ✅ 采纳，与表格对齐 |
| §2.2.2 标题 "用户写路由" → "用户访问路由（含读写）" | review 1 | ✅ 采纳，因含 GET 读路由 |
| 新增 §6 对象归属校验矩阵 | review 2 #1 | ✅ 采纳，本审计 v1.0 仅审路由级 guard，未审对象级 owner 校验 |
| 跨审计联动（idempotency 改造） | review 1 §4.2 | ✅ 采纳，§5 加 cross-ref |
| 文档内 `../apps/` 路径 → `../../../apps/` | review 2 #6 | ✅ 采纳，docs/design/audits/ 距 apps/ 实际 3 级 |

---

## 0. 标记规约

- **Auth**：`required` = AuthGuard 必加；`optional` = 公开但解析 token 可附加上下文；`public` = 无需鉴权
- **Scope**：`user-write` = 写当前用户数据；`user-read` = 读当前用户数据；`content-read` = 公共内容；`system` = 系统/健康
- **粒度**：`controller` = 整个 controller 加 guard；`method` = 方法级（同 controller 内不同方法策略不同）
- **`/me/*` 前缀**：标 ✅ 表示 controller 路径含 `/me/`，标 ❌ 表示不含

---

## 1. 一览表（按文件名字母序）

| # | 文件 | controller path | `/me/*` | 路由数 | Auth 决策 | 粒度 |
|---|------|------------------|---------|--------|-----------|------|
| 1 | audio-assets.controller.ts | `examples` + `words` | ❌ | 2 | public | controller |
| 2 | backup.controller.ts | `me/backup` | ✅ | 3 | required | controller |
| 3 | check-ins.controller.ts | `check-ins` | ❌ | 2 | required | controller |
| 4 | content-manifest.controller.ts | `content` | ❌ | 1 | public | controller |
| 5 | daily-tasks.controller.ts | `me/daily-tasks` | ✅ | 2 | required | controller |
| 6 | equipment.controller.ts | `me/equipment` | ✅ | 3 | required | controller |
| 7 | feed.controller.ts | `me/feed` | ✅ | 1 | required | controller |
| 8 | health.controller.ts | `health` | ❌ | 1 | public | controller |
| 9 | inventory.controller.ts | `me/inventory` | ✅ | 1 | required | controller |
| 10 | lottery.controller.ts | `me/lottery-boxes` | ✅ | 2 | required | controller |
| 11 | me-words.controller.ts | `me/words` | ✅ | 1 | required | controller |
| 12 | pronunciation.controller.ts | `pronunciation` | ❌ | 1 | public | controller |
| 13 | review-attempts.controller.ts | `review-attempts` | ❌ | 2 | required | controller |
| 14 | review-groups.controller.ts | `me/review-groups` | ✅ | 1 | required | controller |
| 15 | secondary-summary.controller.ts | `me/secondary-summary` | ✅ | 1 | required | controller |
| 16 | sessions.controller.ts | `sessions` | ❌ | 3 | required | controller |
| 17 | settings.controller.ts | `me/settings` | ✅ | 1 | required | controller |
| 18 | settlements.controller.ts | `settlements` | ❌ | 2 | required | controller |
| 19 | shop.controller.ts | `shop` | ❌ | 2 | **mixed** | **method** |
| 20 | study-attempts.controller.ts | `me/new-words` | ✅ | 2 | required | controller |
| 21 | task-attempts.controller.ts | `me/task-attempts` | ✅ | 1 | required | controller |
| 22 | today.controller.ts | `me/today` | ✅ | 1 | required | controller |
| 23 | words.controller.ts | `books` | ❌ | 1 | public | controller |

**汇总：**

| 决策 | controller 数 | 路由数 |
|------|--------------|--------|
| AuthGuard required | 17 | 30 |
| public | 5 | 6 |
| mixed (方法级) | 1 | 2（1 public + 1 required） |

**关键观察：** `/me/*` 前缀与 auth 需求只是**正相关**而不是**等价**。
- 13 个 `/me/*` controller 全部需要 auth ✅（前缀准确预测）
- 10 个非 `/me/*` controller 中，**5 个需要 auth**（前缀失效）：sessions / check-ins / review-attempts / settlements / shop（部分）
- 这 5 个绝对不能漏，否则违反 PRD §6 Rule 2

---

## 2. 路由级详细审计（按 auth 决策分组）

### 2.1 公开路由（无需 AuthGuard）

| 路由 | 方法 | 文件 | 性质 | 说明 |
|------|------|------|------|------|
| `/health` | GET | health.controller.ts:11 | system | 健康检查 |
| `/books/:bookId/words` | GET | words.controller.ts:17 | content-read | 词书内容 |
| `/examples/:stable_id/audio` | GET | audio-assets.controller.ts:138 | content-read | 公共例句音频 |
| `/words/:word_id/audio` | GET | audio-assets.controller.ts:185 | content-read | 公共单词音频 |
| `/pronunciation/:word` | GET | pronunciation.controller.ts:39 | content-read | 公共发音 |
| `/content/manifest` | GET | content-manifest.controller.ts:106 | content-read | 内容包清单 |

**理由：** 全部按 PRD §5.2 公共内容层。客户端在用户登录前的"启动期资源拉取"也需要这些不带 auth。

### 2.2 必须加 AuthGuard 的路由（30 条）

#### 2.2.1 `/me/*` 路由（20 条 — 前缀已暗示）

| 路由 | 方法 | 文件:行 | 写/读 | 备注 |
|------|------|---------|------|------|
| `/me/today` | GET | today.controller.ts:11 | read | 主页 |
| `/me/words/:wordId/review-history` | GET | me-words.controller.ts:28 | read | |
| `/me/settings/daily-goal` | PUT | settings.controller.ts:21 | write | |
| `/me/new-words/next` | GET | study-attempts.controller.ts:27 | read | |
| `/me/new-words` | POST | study-attempts.controller.ts:36 | write | 学习提交 |
| `/me/task-attempts` | POST | task-attempts.controller.ts:27 | write | |
| `/me/review-groups/next` | GET | review-groups.controller.ts:24 | read | |
| `/me/daily-tasks` | GET | daily-tasks.controller.ts:21 | read | |
| `/me/daily-tasks/start` | POST | daily-tasks.controller.ts:36 | write | |
| `/me/feed` | POST | feed.controller.ts:41 | write | 喂猫 |
| `/me/inventory` | GET | inventory.controller.ts:11 | read | |
| `/me/equipment` | GET | equipment.controller.ts:35 | read | |
| `/me/equipment/equip` | POST | equipment.controller.ts:47 | write | |
| `/me/equipment/unequip` | POST | equipment.controller.ts:101 | write | |
| `/me/lottery-boxes` | GET | lottery.controller.ts:24 | read | |
| `/me/lottery-boxes/:id/open` | POST | lottery.controller.ts:40 | write | |
| `/me/secondary-summary` | GET | secondary-summary.controller.ts:11 | read | |
| `/me/backup` | POST | backup.controller.ts:21 | write | 备份上传 |
| `/me/backup/latest` | GET | backup.controller.ts:68 | read | |
| `/me/backup/latest/snapshot` | GET | backup.controller.ts:93 | read | |

#### 2.2.2 非 `/me/*` 但用户访问路由（**关键 9 条 — 容易漏，含读写**）

| 路由 | 方法 | 文件:行 | 写/读 | 风险 |
|------|------|---------|------|------|
| `/sessions` | POST | sessions.controller.ts:36 | write | session 起止与有效学习计数挂钩 |
| `/sessions/:sessionId/finish` | POST | sessions.controller.ts:66 | write | 同上 |
| `/sessions/:sessionId` | GET | sessions.controller.ts:99 | read | 当前 session 状态 |
| `/check-ins` | POST | check-ins.controller.ts:16 | write | 签到事实 + 连击 |
| `/check-ins/today` | GET | check-ins.controller.ts:43 | read | 今日签到状态 |
| `/review-attempts` | POST | review-attempts.controller.ts:27 | write | 复习答题 + 奖励链路 |
| `/review-attempts/local-batch` | POST | review-attempts.controller.ts:111 | write | 离线批量复习提交 |
| `/settlements/learning-rounds` | POST | settlements.controller.ts:24 | write | 奖励结算入口 |
| `/settlements/:sourceEventId` | GET | settlements.controller.ts:65 | read | |

**这 9 条是 v1 plan 漏的"看名字明显是用户访问"的关键路由，必须在 Phase A 加 AuthGuard。**

> 注：其中 3 条是 GET（读）：`/sessions/:sessionId`、`/check-ins/today`、`/settlements/:sourceEventId`；6 条是 POST（写）。读路由仍需 guard，因为响应体含用户私有数据（session 状态、签到记录、结算明细）。

#### 2.2.3 Mixed controller — `shop`（方法级 AuthGuard）

| 路由 | 方法 | 文件:行 | Auth | 说明 |
|------|------|---------|------|------|
| `/shop/catalog` | GET | shop.controller.ts:22 | **public** | 商品目录是公共内容 |
| `/shop/purchases` | POST | shop.controller.ts:29 | **required** | 用户购买，写 inventory + 扣 coins |

**`shop` 是唯一 mixed controller。** 实现时不能在 controller 类上加 `@UseGuards(AuthGuard)`，必须方法级：

```typescript
@Controller('shop')
export class ShopController {
  @Get('catalog') getCatalog() { /* public */ }

  @UseGuards(AuthGuard)
  @Post('purchases')
  async purchase(@CurrentUser() user, ...) { /* required */ }
}
```

---

## 3. 实施清单（给 Phase A 用）

### 3.1 控制器级 `@UseGuards(AuthGuard)`（17 个）

```
backup, check-ins, daily-tasks, equipment, feed, inventory, lottery,
me-words, review-attempts, review-groups, secondary-summary, sessions,
settings, settlements, study-attempts, task-attempts, today
```

### 3.2 方法级 `@UseGuards(AuthGuard)`（1 个）

```
shop.controller.ts → 仅 @Post('purchases') 加
```

### 3.3 不加（5 个）

```
audio-assets, content-manifest, health, pronunciation, words (books)
```

### 3.4 路由前缀**不动**（CLAUDE.md §4.4 红线）

不把 `/sessions` 改成 `/me/sessions`、不把 `/check-ins` 改成 `/me/check-ins` 等。AuthGuard 与路由前缀正交。

---

## 4. 用户上下文注入约定

每个 required 路由的方法签名加：

```typescript
@Get()
@UseGuards(AuthGuard)
getXxx(@CurrentUser() user: { id: string; type: 'guest' | 'registered' }) {
  return repositories.xxx.getYyy(user.id);
}
```

`@CurrentUser()` 是 Phase A 新加的 NestJS param decorator，从 `req.user`（AuthGuard 注入）取值。

---

## 5. 已知陷阱

1. **`backup.controller.ts` 内部直接 import `devStore`**（第 2 行 `import { devStore, repositories } from '../domain'`）。这是一个 in-memory 单例，按 plan v2 §5 必须改造。本审计仅标 auth 需求，后端持久层改造由另行审计。
2. **`review-attempts/local-batch`（POST）是离线批量提交入口**——客户端可能在游客阶段累积，登录后再提交。这条路由的 `req.user` 在游客或 registered 都必须能解析（不要硬限 registered）。
3. **`backup` 的 device_id**：当前实现 device_id 来自请求体（[backup.controller.ts:25](../../../apps/api/src/controllers/backup.controller.ts)）。AuthGuard 不会替代 device_id 字段；它们是**正交的**（device_id 用于 last-write-wins 多设备识别，user_id 用于归属）。
4. **`/settlements/:sourceEventId` GET** 一定要校验 `source_event.user_id === req.user.id`，否则用户 A 拿到 source_event_id 可读 B 的结算。当前查询方法 `getSettlementBySourceEventId` 不带 user_id 过滤（[dev-store.ts:1396](../../../apps/api/src/domain/dev-store.ts)），是漏洞，Phase A 修。这是 v1.1 §6 对象归属校验矩阵的一个具体实例（不是全部，详见 §6）。
5. **idempotency_keys 应用层联动**（与 [db-uniqueness-audit.md](db-uniqueness-audit.md) §2.2 + §3.6 配套）：
   - `getIdempotencyKey(key)` 当前仅按 `key` 查询（[dev-store.ts:1098](../../../apps/api/src/domain/dev-store.ts)、[pg-persistence.ts:66](../../../apps/api/src/infrastructure/postgres/pg-persistence.ts)），多用户化后需改为 `getIdempotencyKey(userId, key)`。
   - 18+ 个调用点（dev-store.ts 内多处 + 9 个 controllers）需要同步改造。
   - 与 §5 #4 同属"应用层 user_id filter 漏洞家族"。

---

## 6. 对象归属校验矩阵（v1.1 新增）

AuthGuard 解决"是否登录"的问题，但**不能解决**"当前 user 能否访问 entity X"的问题。当路由参数 / 请求体携带 entity ID（lottery box id、session id、source event id、review group id 等）时，必须额外做 owner 校验：`entity.user_id === req.user.id` 否则 403。

下表列出所有需补 owner-check 的路由。**这些校验当前全部缺失**，Phase A 必须连 AuthGuard 一起补。

| 路由 | 参数携带的 entity ID | 需校验的 owner 字段 | 当前 dev-store 方法 | 漏洞描述 |
|------|--------------------|------------------|----------------|--------|
| `GET /sessions/:sessionId` | sessionId | `session_records.user_id` | [dev-store.ts:1893](../../../apps/api/src/domain/dev-store.ts) `getSession(sessionId)` | 无 owner 过滤；任意 user 拿 sessionId 可读他人 session |
| `POST /sessions/:sessionId/finish` | sessionId | `session_records.user_id` | [dev-store.ts:1791](../../../apps/api/src/domain/dev-store.ts) `finishSession(sessionId, idempotencyKey)` | 无 owner 过滤；可终结他人 session |
| `GET /settlements/:sourceEventId` | sourceEventId | `reward_source_events.user_id`（间接） | [dev-store.ts:1396](../../../apps/api/src/domain/dev-store.ts) `getSettlementBySourceEventId` | 已在 §5 #4 标记 |
| `POST /settlements/learning-rounds` | body.source_ref_id | source_ref 关联表的 user_id（study_attempt / review_group） | `createOrGetSourceEvent(...)` | 用户 A 提交 B 的 study_attempt id，会以 A 的身份创建 source event 并结算 |
| `POST /me/lottery-boxes/:id/open` | :id | `lottery_boxes.user_id` | [dev-store.ts:2654](../../../apps/api/src/domain/dev-store.ts) `openLotteryBox(boxId, ...)` | 无 owner 过滤；可开他人盒子拿走奖品 |
| `POST /review-attempts` | body.review_group_id | `review_groups.user_id` | `submitReviewAttempt(review_group_id, word_id, ...)` | 无 owner 过滤；用户 A 提交 B 的 review_group_id 可写入 B 的复习进度 |
| `POST /review-attempts/local-batch` | body 中可能带 review_group_id | 同上 | 同上 | 同上风险，且批量放大 |
| `POST /me/new-words` | body.session_id (optional) | `session_records.user_id` | `submitStudyAttempt(...)` | session_id 不校验 owner，可挂到他人 session 上 |
| `POST /me/task-attempts` | body.session_id (optional) | `session_records.user_id` | 同 task-attempts repo | 同上 |
| `POST /me/feed` | body.item / inventory id | `inventory_items.user_id` | `feed(...)` | 喂食时引用 inventory item，必须确认是当前 user 的 |
| `POST /me/equipment/equip` | body.item_id | `inventory_items.user_id`（要 own 才能装备） | `equip(...)` | 可装备他人 inventory 中的物品 |
| `POST /me/equipment/unequip` | body.item_id 或 slot | `equipment_slots.user_id` | `unequip(...)` | 可卸下他人装备 |
| `GET /me/words/:wordId/review-history` | wordId | **无需** owner check（word 是公共内容，但返回的 review history 自动 user-scoped 即可） | `getReviewHistory(userId, wordId)` | 实现需保证 query 内带 userId，且 wordId 是 word_id 不是 user_word_progress.id |
| `POST /me/backup` | body.snapshot | 服务端落库时按 req.user.id 即可 | `storeBackup(...)` | 当前 storeBackup 不带 userId 参数，相当于"全局只有一份 backup"，多用户化后必须改 |
| `GET /me/backup/latest` / `GET /me/backup/latest/snapshot` | — | 隐式 req.user.id | `getLatestBackupMeta()` / `getBackupSnapshot()` | 同上：当前是全局单份，必须改 per-user 查询 |

### 6.1 实施约定

```typescript
// Bad — only AuthGuard, no owner check:
@Post(':sessionId/finish')
@UseGuards(AuthGuard)
finishSession(@Param('sessionId') id: string, @CurrentUser() user) {
  return repo.finishSession(id);   // ⚠️ 任何人能 finish 任何 session
}

// Good — AuthGuard + owner check:
@Post(':sessionId/finish')
@UseGuards(AuthGuard)
finishSession(@Param('sessionId') id: string, @CurrentUser() user) {
  return repo.finishSession(user.id, id);   // method 内部 SELECT ... WHERE id=$1 AND user_id=$2
                                            // 不命中即抛 NotFoundException（不区分"不存在"/"不属于你"）
}
```

**返回 404 而非 403** 的理由：避免 entity ID 枚举攻击（403 会暴露 entity 存在事实）。统一返 NotFound。

### 6.2 实施清单（Phase A 必做）

需要在 dev-store.ts / 各 repository 中**给 method 加 userId 入参**并在内部过滤。以下方法签名需修改：

```
getSession(sessionId)                        → getSession(userId, sessionId)
finishSession(sessionId, idemKey)            → finishSession(userId, sessionId, idemKey)
getSettlementBySourceEventId(id)             → getSettlementBySourceEventId(userId, id)
createOrGetSourceEvent(type, refId, idem)    → createOrGetSourceEvent(userId, type, refId, idem)
openLotteryBox(boxId, idem)                  → openLotteryBox(userId, boxId, idem)
submitReviewAttempt(groupId, wordId, ...)    → submitReviewAttempt(userId, groupId, wordId, ...)
submitStudyAttempt(...)                      → submitStudyAttempt(userId, ...)
feed(...)                                    → feed(userId, ...)
equip(...) / unequip(...)                    → 带 userId
storeBackup(...)                             → storeBackup(userId, ...)
getLatestBackupMeta()                        → getLatestBackupMeta(userId)
getBackupSnapshot()                          → getBackupSnapshot(userId)
```

总计 ~15 个方法签名变更。每个方法内部 SQL / Map 查询都要带 userId 谓词。**这部分工作量 plan v2 §5 写了"机械改造"但没列方法清单，本表是补全。**

---

## 7. 与 plan v2 §4.1 的对应

plan v2 §4.1 是按 controller 列的；本审计补到方法级，并把以下补充：
- 显式列出每条路由文件:行
- 显式标记 shop 是 mixed
- 显式列出 v1 plan 漏的 9 条"非 /me/* 用户访问"路由（§2.2.2）
- §5 已知陷阱（其中 #4 是 plan 没提到的真实漏洞，需要在 Phase A 修）
- §6 对象归属校验矩阵（v1.1 新增，列出 ~15 个 method 签名变更）

---

## 8. 输出

本文档作为 Phase A 实施的 source of truth，PR 描述需 reference 本文件。Phase A 必须同时落地 §3（路由级 AuthGuard）+ §6（对象归属校验），二者缺一不可。
