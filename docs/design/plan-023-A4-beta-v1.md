# Plan: 需求 23 Phase A4-β — 真正的多用户数据隔离

**Plan Version:** v1
**Status:** **已完成**（3 个 batch 全部 commit, 76/76 e2e pass）
**Branch:** `feature/user-auth`（同 α）
**前序:** Phase A4-α（commit `1991be7`）
**Batch commits:**
- Batch 1 (β.1+β.2): `52c1a30` — withUser async-guard + 错误码统一 + backup partition (P0)
- Batch 2 (β.3+β.4+β.5+β.6 部分): `3833c25` — dev-store 全部 *ByUser partition + idempotency Map + pg-persistence userId
- Batch 3 (β.7+β.8): 待 commit — 6 个新 isolation e2e + 文档同步

**关联:** [plan-023-用户系统与用户数据隔离-v2.md](plan-023-用户系统与用户数据隔离-v2.md) §1.1 / §5
**日期:** 2026-05-09 (v1 起草) → 2026-05-10 (v1 落地完成)

---

## Context

A4-α 已落地 commit `1991be7`：repository 接口加 userId、AuthGuard 接 17 controllers、audit §6 部分 owner-check、auth-isolation e2e 6/6。但 α 完成后两份外部评审揭示：

1. α 实施与 plan v2 有 3 处 silent 偏离（withUser 策略 / pg-persistence 推迟 / assertSingleUser 漏）
2. 内部状态仍**单用户共享**（不是真隔离），意见 2 列出至少 6 个数据查询点没按 userId 过滤
3. **备份跨用户共享同一插槽**（P0 安全漏洞），意见 2 自承担风险但 α 只标了 marker
4. **idempotency 内部 Map 仍 raw key**——同 key 跨用户在 in-memory 路径会撞（PG 层 PK 已隔离，但 in-memory cache 早于 PG 写入）
5. audit §6 矩阵 e2e 覆盖率 ~33%（6/18 方法路径）

**β 是 `AUTH_ENFORCE=true` 切流（Phase E1）的硬前置**：β 不完，绝不能在生产打开 AUTH_ENFORCE。permissive 模式下 α 可继续运行，β 与 Phase B（移动端）正交可并行。

---

## α 偏离自我修订

按 CLAUDE.md §3.1「不把 partially completed 写成 completed」，先把 plan v2 的失真之处认账：

| plan v2 / α plan 写的 | 实际 | β 处理 |
|----------------------|------|--------|
| §3.1: 删除 `private readonly userId`，替换 4 处 `this.userId` | 53 处引用，改用 `withUser` 包装策略保留 `this.userId` | β 真做 partition（不再保留单字段）|
| §4: pg-persistence 删 DEV_USER_ID + 44 处替换 | 仅加 6 行 marker 注释 | β 必做（β.5）|
| §3.3: 加 `assertSingleUser` 防呆 | 没写 | β 用 withUser async-guard 替代（更有效）|
| audit §6 owner-check `~15 个方法` | 实际 18 个，且 6 个 e2e 仅覆盖 3 类 | β 补全 5 类 e2e（β.7）|
| 数字 / 工时估算 | 多处偏差 | 教训：β plan 数字先 grep 再下 |

**这次 plan 严格按 grep / line-count 给数。**

---

## β 范围（按风险倒序）

### β.1 — 立即修小问题（低风险，独立小 PR）

**1.1 `withUser` async-guard（防御未来串数据 bug）**

文件：`apps/api/src/domain/dev-store.ts:242`

当前：

```ts
withUser<T>(userId: string, fn: () => T): T {
  const prev = this.userId;
  this.userId = userId;
  try { return fn(); }
  finally { this.userId = prev; }
}
```

修订：

```ts
withUser<T>(userId: string, fn: () => T): T {
  const prev = this.userId;
  this.userId = userId;
  try {
    const result = fn();
    if (result && typeof (result as any).then === 'function') {
      // Defensive: async fn would resume after `this.userId = prev` and
      // see the wrong userId. Forbid until A4-β actually partitions state.
      this.userId = prev;
      throw new Error(
        '[withUser] async fn forbidden — see plan-023-A4-beta-v1.md §β.1',
      );
    }
    return result;
  } catch (err) {
    this.userId = prev;
    throw err;
  } finally {
    if (this.userId !== prev) this.userId = prev; // double-guard
  }
}
```

**1.2 Owner-check 错误码统一**

按 plan v2 §3.2 「权限拒绝统一返 NotFound（404）防 entity ID 枚举」，但 α 实际有 4 种行为：

| 方法 | α 实际 | β 改为 |
|------|--------|--------|
| `getSession` | `null` | 保留 `null`，controller 转 NotFound（已是） |
| `finishSession` | `throw Error('Session not found')` | 改 `throw NotFoundException` |
| `getSettlementBySourceEventId` | `null` | 保留 `null`，controller 转 NotFound |
| `createSettlement` | `throw Error` | 改 `throw NotFoundException` |
| `openLotteryBox` | `{ box: null }` | 改 `throw NotFoundException` |
| **`submitReviewAttempt`** | **`{success: false, ...}`** ⚠️ | **改 `throw NotFoundException`** |
| `submitFishingAttempt` | `{ task null }` | 改 `throw NotFoundException` |

`submitReviewAttempt` 的 `{success: false}` 是最危险的——它向客户端**确认了 reviewGroupId 存在但你没权限**，破坏 ID 枚举防护。

实施：dev-store 内部抛 `OwnershipNotFoundError`（自定义），adapter 透传，controller 层 NestJS 自动转 404（或 controller 显式 catch 转）。统一规则：**owner mismatch == "如同不存在"**。

**1.3 isolation e2e 注释失真修订**

`auth-isolation.e2e-spec.ts` 头注释提到 lottery 但代码没测，去掉注释或加测试（β.7 会补）。

**β.1 工作量：小（~50 行代码 + 几个 e2e 断言更新）**。可作为独立 PR 先合，再开 β 大改造。

---

### β.2 — 备份 per-user 隔离（P0 — 意见 2 升级，不能 defer）

文件：`apps/api/src/domain/dev-store.ts:198-199` + `apps/api/src/controllers/backup.controller.ts`

当前：

```ts
private latestBackup: any | null = null;       // 全局单插槽
private backupSnapshot: any | null = null;     // 全局单插槽
```

→ 用户 A 上传 → 用户 B GET `/me/backup/latest/snapshot` 拿到 A 的快照。**这是 PRD 核心红线**（按 plan v2 §6.1 「备份恢复只属于当前 user」）。

修订：

```ts
private latestBackupByUser: Map<string, any> = new Map();
private backupSnapshotByUser: Map<string, any> = new Map();

storeBackup(userId, ...) {
  this.latestBackupByUser.set(userId, meta);
  this.backupSnapshotByUser.set(userId, snapshot);
}

getLatestBackupMeta(userId): any | null {
  return this.latestBackupByUser.get(userId) ?? null;
}

getBackupSnapshot(userId): any | null {
  return this.backupSnapshotByUser.get(userId) ?? null;
}
```

backup.controller.ts 改为直接传 user.id，不再走 `withUser` 包装（语义更清晰）。

**配套 pg-persistence 也得分 user 备份**——但 backup 表结构 PRD 还没冻结，β 内可暂存 in-memory + 写"用户级备份键"到 PG。具体待 β.5 一起处理。

**β.2 工作量：中（dev-store 4 处 + controller 1 处 + 4 个 e2e）**

---

### β.3 — dev-store 内部状态全审 + 数据查询过滤（P1 核心）

意见 2 列出的具体漏洞点（已逐条 grep 核实）：

| 行号 | 代码 | 问题 |
|------|------|------|
| `dev-store.ts:615` | `this.studyAttempts.filter(a => a.study_type === 'new' && ...)` | 没按 user_id |
| `dev-store.ts:768-772` | `masteredWordIds = new Set(this.studyAttempts.filter(...).map(...))` | 没按 user_id |
| `dev-store.ts:1482` | `for (const item of this.rewardLedgerItems)` | 没按 user_id |
| `dev-store.ts:1494` | `feedRecords.reduce(...)` | 没按 user_id |
| `dev-store.ts:1497` | `this.coinsSpent` | 单字段、无 user 维度 |
| `dev-store.ts:1508` | `this.feedExpAccumulated` | 同上 |
| `dev-store.ts:604` | `this.todayStates.get(today)` | key 是 date，跨用户共享 |
| `dev-store.ts:198` | `this.ownedItems[]` | 数组无 user_id 字段 |
| `dev-store.ts:202` | `this.equippedOutfit / equippedRoom` | record 无 user 维度 |

**修订策略：**

#### 3.1 公共数组按 user partition

```
this.studyAttempts: StudyAttempt[]                → Map<userId, StudyAttempt[]>
this.reviewAttempts: ReviewAttempt[]              → Map<userId, ReviewAttempt[]>
this.reviewGroups: ReviewGroup[]                  → Map<userId, ReviewGroup[]>
this.sessions: Session[]                          → Map<userId, Session[]>
this.checkIns: CheckInRecord[]                    → Map<userId, CheckInRecord[]>
this.learningDays: LearningDayRecord[]            → Map<userId, LearningDayRecord[]>
this.sourceEvents: RewardSourceEvent[]            → Map<userId, RewardSourceEvent[]>
this.rewardLedgerItems: RewardLedgerItem[]        → Map<userId, RewardLedgerItem[]>
this.settlements: Settlement[]                    → Map<userId, Settlement[]>
this.feedRecords: FeedRecord[]                    → Map<userId, FeedRecord[]>
this.fishingAttempts: FishingAttempt[]            → Map<userId, FishingAttempt[]>
this.lotteryBoxes: LotteryBox[]                   → Map<userId, LotteryBox[]>
this.ownedItems: OwnedItem[]                      → Map<userId, OwnedItem[]>
```

#### 3.2 公共 Map 用复合 key

```
this.todayStates: Map<localDate, TodayState>      → Map<userId, Map<localDate, TodayState>>
this.fishingTasks: Map<taskId, DailyFishingTask>  → Map<userId, Map<taskId, DailyFishingTask>>
this.idempotencyKeys: Map<key, Record>            → Map<userId, Map<key, Record>>
```

#### 3.3 单字段拆 Map

```
this.coinsSpent: number                           → Map<userId, number>
this.feedMoodAccumulated: number                  → Map<userId, number>
this.feedExpAccumulated: number                   → Map<userId, number>
this.feedBondAccumulated: number                  → Map<userId, number>
this.streakRecord: StreakRecord | null            → Map<userId, StreakRecord>
this.equippedOutfit: Record<slot, itemId>         → Map<userId, Record<slot, itemId>>
this.equippedRoom: Record<slot, itemId>           → Map<userId, Record<slot, itemId>>
this.latestBackup / backupSnapshot                → 已在 β.2 处理
```

#### 3.4 helper：bucketed access

```ts
private bucketArr<T>(map: Map<string, T[]>, userId: string): T[] {
  let arr = map.get(userId);
  if (!arr) { arr = []; map.set(userId, arr); }
  return arr;
}

private bucketMap<K, V>(outer: Map<string, Map<K, V>>, userId: string): Map<K, V> {
  let inner = outer.get(userId);
  if (!inner) { inner = new Map(); outer.set(userId, inner); }
  return inner;
}
```

每个数据查询/聚合方法改为 `this.bucketArr(this.studyAttempts, this.userId).filter(...)` 形式。

#### 3.5 53 处 `this.userId` 引用归类

实际不是单纯的"添加 user 过滤"——很多 `this.userId` 是赋值给新建实体的 `user_id` 字段（OK 不动）。需要逐处过：
- 查询/过滤性质的 → 改为按 bucket 取
- 新建实体赋值 → 保持

β 实施时一处一处过，每处加注释说明属于哪类。

#### 3.6 hydrate / serialize 兼容老 snapshot

`DevStoreSnapshot` 当前是扁平结构（`studyAttempts: StudyAttempt[]`）。β 后 in-memory 是 Map，但 snapshot **保持扁平结构**（与 PG schema 一一对应、与现有 JSON 文件兼容）。serialize/hydrate 内部做 flatten/unflatten 转换：

```ts
serialize(): DevStoreSnapshot {
  return {
    studyAttempts: [...this.studyAttempts.values()].flat(),
    // ... 其他 entity 同样 flatten
  };
}

hydrate(snapshot) {
  this.studyAttempts = new Map();
  for (const a of snapshot.studyAttempts ?? []) {
    this.bucketArr(this.studyAttempts, a.user_id).push(a);
  }
  // ...
}
```

**β.3 工作量：大（~50 处方法体修改 + serialize/hydrate 改写 + 全 unit/e2e 跑一遍）**

---

### β.4 — idempotency 内部 Map per-user

α 阶段 adapter / interface / pg-persistence (PK) 都已 user-scoped，但 dev-store 内部 Map 仍 raw key（`Map<string, IdempotencyKeyRecord>`）。

dev-store 改：

```ts
// before:
private idempotencyKeys: Map<string, IdempotencyKeyRecord> = new Map();

getIdempotencyKey(key: string): IdempotencyKeyRecord | null {
  return this.idempotencyKeys.get(key) || null;
}

// after (β.3 已经改了 idempotencyKeys → Map<userId, Map<key, record>>)
getIdempotencyKey(userId: string, key: string): IdempotencyKeyRecord | null {
  return this.bucketMap(this.idempotencyKeys, userId).get(key) ?? null;
}

setIdempotencyKey(userId, key, path, response): void {
  this.bucketMap(this.idempotencyKeys, userId).set(key, { ...record, user_id: userId });
}
```

adapter 层移除 `withUser` 包装、直接传 userId（β 中所有方法签名都加 userId 后，withUser 不再需要——见 β.6）。

α 中所有 `this.getIdempotencyKey(idempotencyKey)` 内部调用（dev-store 自己内部调用，~14 处）需改为带 userId（用 `this.userId` 即从外部传入的当前用户）。

**β.4 工作量：小（adapter + dev-store ~15 处调用点）**

---

### β.5 — pg-persistence 接 userId（plan v2 §4 兑现）

文件：`apps/api/src/infrastructure/postgres/pg-persistence.ts`

接口扩展（`apps/api/src/domain/persistence.ts`）：

```ts
export interface IDevStorePersistence {
  loadAsync?(userId: string): Promise<DevStoreSnapshot | null>;
  saveAsync(snapshot: DevStoreSnapshot, userId: string): Promise<void>;
  clearAsync?(userId?: string): Promise<void>;  // userId 可选 = 全清
}
```

pg-persistence.ts：
- 删 `const DEV_USER_ID = 'dev-user-001'`
- `loadAsync(userId)` / `saveAsync(snapshot, userId)` 全部 SQL 用 `userId` 而非常量
- 45 处替换

调用方（dev-store.ts initAsync / saveToDiskAsync）：当前是 module-level 单调用。β 中变成"按 user 加载"——但 dev-store 启动时不知道有哪些 user，需要：
- **启动 cold load**：仅 `dev-user-001`（保持向后兼容；其他 user 在首次 withUser 时 lazy-load）
- **运行时 hot load**：每次 withUser(newUserId) 之前，如果该 userId 数据未在 in-memory，触发 `pg.loadAsync(newUserId)` 并 hydrate 该 user 的 bucket
- **save**：每次 user 操作后只 save 该 user 的 partition（避免全量 dump）

这是 β 最大块工作。涉及 dev-store 的初始化生命周期重构。

**β.5 工作量：大（pg-persistence 全改写 + dev-store init/save 重构）**

---

### β.6 — Adapter / dev-store 公共方法直接接 userId（移除 withUser）

β.1-β.5 完成后，`withUser` 包装本质上变成多余——因为 dev-store 公共方法可以直接接 userId 第一参数，内部用 bucket 取数。这是 plan v2 §3.1 原本要做的事（α 偏离没做）。

实施：每个公共方法签名 `xxx(args)` → `xxx(userId, args)`。删除 `withUser` 和 `this.userId` 字段。adapter 层 `asUser(userId, () => devStore.xxx())` → `devStore.xxx(userId, ...)` 直接传。

**β.6 工作量：中（与 β.3 重叠，可合并 PR）**

---

### β.7 — 补全 audit §6 e2e 覆盖

α 写了 6 个 isolation 用例，仅覆盖 sessions / settlements / idempotency 3 类。β 必须把 audit §6 全 18 方法覆盖到。

**新增 e2e 矩阵**（`auth-isolation.e2e-spec.ts` 扩展）：

| 测试 | 验证 |
|------|------|
| 用户 B 装备用户 A 的物品 → 404 | equipment §6 |
| 用户 B 卸下用户 A 的装备 → 404 | equipment §6 |
| 用户 B 用用户 A 的 inventory 喂猫 → 隔离（B 自己的 fish_treats 不被 A 影响）| feed §6 |
| 用户 B 开用户 A 的 lottery box → 404 | lottery §6 |
| 用户 B 提交 fishing attempt 到用户 A 的 task → 404 | fishing §6 |
| 用户 B 提交 review-batch 到用户 A 的 review_group → 404 | review §6 |
| 用户 B 读用户 A 的 backup snapshot → 404（β.2 配套）| backup |
| 用户 B 看 today（A 学过的词不出现在 B 的已学）| dev-store §3.1 验收 |
| 用户 B 看 balance（A 的 ledger 不出现在 B 的 balance）| dev-store §3.3 验收 |
| 用户 B 看 next-new-word（A 已掌握的词仍可作为 B 的新词）| dev-store §3.5 验收 |
| 用户 B 看 inventory（A 拥有的物品不在 B 的 inventory）| dev-store §3.4 验收 |
| 同 idempotency key 跨用户：response 不串（**真正测，用同 source_ref_id**）| idempotency §3.6 |

**至少 12 个新用例**，全部跑通后 audit §6 覆盖率从 ~33% 提升到 100%。

**β.7 工作量：中（写 12 个 e2e + 调试）**

---

### β.8 — 文档同步

- plan v2 §3.1 / §4 / §3.3 patch（吸收 α 偏离）
- audits §6 标注真实覆盖率
- 评审采纳记录（与 Phase 0 audits v1.1 同模式，加 v1.2 修订记录）

**β.8 工作量：小（~1 小时文档修订）**

---

## 拆分上线（建议）

| PR | 内容 | 风险 |
|----|------|------|
| **β.1** | hot-fix（withUser async-guard + 错误码统一）| 低 |
| **β.2** | backup per-user partition + 4 e2e | 中（影响 P3 备份链路）|
| **β.3+β.4+β.6** | dev-store 内部 partition + adapter 直接传 userId + idempotency Map | 大（影响所有写路径）|
| **β.5** | pg-persistence userId 全栈 | 大（持久化层重构）|
| **β.7** | 补 12 个 e2e | 中 |
| **β.8** | 文档同步 | 低 |

**β.1 / β.2 / β.7 可作为独立小 PR 先行落地**，β.3-β.6 必须一起上（互相耦合，分开会留中间不一致状态）。

---

## 风险

| 风险 | 缓解 |
|------|------|
| dev-store 重构破坏全 e2e 套件 | 分 step 跑 e2e；β.3 之前先跑过老套件作为 baseline |
| pg-persistence 重构丢数据（dev-user-001 已有数据）| 不动现有数据，只改读写路径；β.5 PR 描述含手动 smoke test |
| `withUser` async 防御误伤现有 async 路径 | 当前 5 个 async 路径已知（initAsync / saveToDiskAsync / loadWordPool / loadUserSettings / updateDailyNewTarget）——β.1 PR 描述列清单，确认这些不走 withUser |
| serialize/hydrate 与现有 PG snapshot 兼容 | β.3 实施前先 snapshot 一份现有 PG 状态；改完 hydrate 一次确认 round-trip 一致 |
| AUTH_ENFORCE 误开启 | β 完成前 `assertProductionAuthEnforce` 仍是只允许 prod；β 完成后 PR 才 lift dev/staging 限制 |

---

## 验证

每个子 PR 单独跑：

```
cd apps/api && npm run build
cd apps/api && npm run test:e2e:pg
```

β 全部完成后：

```
# AUTH_ENFORCE=true 下跑全 e2e（含 isolation 12+6=18 用例）
AUTH_ENFORCE=true cd apps/api && npm run test:e2e:pg
```

**期望：**
- 18+ isolation 用例全过
- 现有 55+7 用例全过
- Audit §6 覆盖率 100%
- TypeScript 编译 0 错误

---

## 不在 β 范围（明示）

- **移动端 token / AuthScope（Phase B）**：与 β 正交，可并行
- **drift v13 schema（Phase C）**：与 β 正交
- **AUTH_ENFORCE=true 实际切流（Phase E1）**：β 之后才能开
- **绑定流程的服务端事务（Phase F）**：A2 已实现 `/auth/bind`，β 不动

---

## 估时（这次按实测给）

| 子项 | 估时 |
|------|------|
| β.1 hot-fix | 0.5-1 小时 |
| β.2 备份 partition | 1-2 小时 |
| β.3 内部状态 partition | 4-6 小时（最大块）|
| β.4 idempotency Map | 0.5 小时（β.3 内顺手）|
| β.5 pg-persistence userId | 2-3 小时 |
| β.6 移除 withUser | 1 小时（β.3 内顺手）|
| β.7 补 12 e2e | 2-3 小时 |
| β.8 文档 | 1 小时 |
| **合计** | **12-17 小时**（一个完整工作日 + 调试 buffer）|

---

## 评审吸收记录

### 意见 1（采纳清单）

| 评审点 | 采纳处 |
|--------|--------|
| 1.1 dev-store 改造方式偏离 | β plan §"α 偏离自我修订" + β.6 |
| 1.2 Step 4 pg-persistence silent defer | β.5 |
| 1.3 assertSingleUser 漏 | β.1 用 withUser async-guard 替代（更有效）|
| 1.4 plan 数字不准 | β plan 全用 grep 实测 |
| 严重 P1: ownedItems / equipment / inventory 共享 | β.3 §3.1 / §3.3 |
| 中等：withUser 同步脆弱 | β.1 |
| 中等：错误码不统一 | β.1 |
| 测试覆盖 ~33% | β.7 补到 100% |

### 意见 2（采纳清单）

| 评审点 | 采纳处 |
|--------|--------|
| P0 备份跨用户泄漏 | β.2（升级为高优先独立 PR）|
| P1 pg-persistence 没接 userId | β.5 |
| P1 withUser 不是真隔离 + 6 处查询未过滤 | β.3（核心，包括两份评审都列的具体行号）|
| P1 idempotency Map 仍 raw key | β.4 |
| P2 isolation e2e 注释失真 + idempotency 测试说服力不足 | β.1 注释修订 + β.7 重写 idempotency 测试 |

### 不采纳/调整

| 评审点 | 处理 |
|--------|------|
| 意见 2「不建议把 α 认定为通过」 | **保留 α 为 milestone**：α 在 permissive 模式可运行、不阻塞 Phase B；β 是 AUTH_ENFORCE=true 切流前置。两份评审实质都同意 permissive 模式 OK，分歧仅在"通过节点"的命名 |

---

## 下一步

请用户确认：

1. β 总体方向是否 OK
2. 是否同意"α 保留为 milestone + β 作为 AUTH_ENFORCE=true 切流前置"的定位
3. PR 拆分（β.1+β.2+β.7 先 / β.3-β.6 一起）是否合理
4. 估时 12-17 小时是否在你预期范围

确认后按 β.1 → β.2 → β.7 → β.3-β.6 顺序实施。

---

## 实施记录（2026-05-10 完成）

用户确认后实际拆分为 3 个 batch（与原 plan 略有调整）：

### Batch 1: β.1 hot-fix + β.2 backup partition（commit `52c1a30`）

**β.1 hot-fix：**
- `withUser` async-guard：检测 `fn()` 返回 Promise 时主动抛错（阻止未来在 withUser 内加 await 导致的隐式串数据 bug）
- Owner-check 错误码统一：dev-store 内 `finishSession` / `createSettlement` / `openLotteryBox` / `submitReviewAttempt` / `submitFishingAttempt` 全部统一抛 `NotFoundException`，替代之前 4 种不一致的返回形态（最危险的是 `submitReviewAttempt` 返 `{success: false}` 泄露 review_group 存在性，β.1 修复）
- `auth-isolation.e2e-spec.ts` 头注释失真修订

**β.2 backup per-user（P0 closeout）：**
- `dev-store.ts`: `latestBackup` / `backupSnapshot` 单插槽 → `latestBackupByUser` / `backupSnapshotByUser` Map<userId, ...>
- 三个方法（storeBackup / getLatestBackupMeta / getBackupSnapshot）接 `userId` 第一参数（不再走 withUser 包装）
- `backup.controller.ts` 直接传 `user.id`
- `DevStoreSnapshot` 加 `latestBackupsByUser` / `backupSnapshotsByUser` 字段；保留 legacy 单插槽字段做向后兼容（hydrate 时自动 migrate 到 DEV_USER_ID bucket）
- 2 个新 e2e：「B 看不到 A 的 backup snapshot」「LWW 跨用户隔离」

**测试：70/70 e2e pass**（+2 new backup e2e）

---

### Batch 2: β.3 + β.4 + β.5 主 + β.6 部分（commit `3833c25`）

**β.3 dev-store 内部状态全 partition：**
- 23 个原本共享的内部字段全部转为 per-user Map：
  - 数组类（13 个）：`studyAttempts` / `reviewGroups` / `reviewAttempts` / `sourceEvents` / `rewardLedgerItems` / `settlements` / `sessions` / `checkIns` / `learningDays` / `feedRecords` / `ownedItems` / `fishingAttempts` / `lotteryBoxes` → `Map<userId, T[]>`
  - Map 类（3 个）：`todayStates` / `idempotencyKeys` / `fishingTasks` → `Map<userId, Map<key, T>>`
  - 单值类（7 个）：`coinsSpent` / `feedMoodAccumulated` / `feedExpAccumulated` / `feedBondAccumulated` / `streakRecord` / `equippedOutfit` / `equippedRoom` → `Map<userId, T>`
- **关键设计：用 TypeScript getter/setter 保留 legacy 字段名（`this.studyAttempts` 等），方法体零改动**——getter 自动按 `this.userId`（由 withUser 绑定）路由到对应 bucket
- `serialize` / `hydrate` 重写：
  - serialize 数组类跨用户 flatten（PG 用每行 `user_id` 区分）
  - serialize Map 类只 dump DEV_USER_ID 的 slice（β.5 单用户 PG schema 限制，β.5b 修）
  - hydrate 按每行 `user_id` field 重新 bucketize
- `reset()` 清空所有 *ByUser

**β.4 idempotency Map per-user：**
- 内部从 `Map<key, IdempotencyKeyRecord>` 升级为 `Map<userId, Map<key, Record>>`（嵌套 Map）
- 通过 getter 自动按当前 user 取 inner Map
- 修复评审 2 P1 漏洞：之前同 key 跨用户在 in-memory 路径会撞（PG PK 层已隔离，但 cache 早于 PG 写入）

**β.5 pg-persistence userId 参数：**
- 接口扩展：`loadAsync?(userId)` / `saveAsync(snapshot, userId)` / `clear(userId)`
- 30+ 处 `DEV_USER_ID` 常量替换为参数（默认 `DEV_USER_ID` 保持单用户向后兼容）
- saveAsync 用 `ownedBy = row.user_id === userId` 过滤每个数组的行——只持久化当前 user 的 slice
- DELETE-replace 模式按 userId 范围，不影响其他 user 的 PG 行
- dev-store.saveToDisk 捕获 `this.userId` 传给 saveAsync

**β.6 部分（withUser 角色重新定位）：**
- α 阶段 withUser 是「临时 userId 覆盖 hack」
- β.3 之后 withUser 是**正式的 user-binding 入口**：选择 getter/setter 路由到哪个 bucket
- 完全去 withUser（给 ~50 个公共方法加 userId 参数）是纯 cosmetic 改动，defer 到未来 cleanup

**β.5 / β.6 已知限制（源代码注释 + β plan 明示）：**
1. **β.5b lazy-load**: 启动只 `loadAsync(DEV_USER_ID)` — 其他 user server restart 后 in-memory 丢，PG 真理仍在。Phase E1 切流前必修
2. **ownedItems / equipped* / wallet 持久化**: 这几个 snapshot 字段没 user_id，pg-persistence 仅 DEV_USER_ID 路径持久化；其他 user 数据只在 in-memory 存活。Phase E1 切流前必修（snapshot type 加 *ByUser 字段）

**测试：70/70 e2e pass**（无新增）

---

### Batch 3: β.7 e2e + β.8 文档（当前 commit）

**β.7 isolation e2e 补全 — audit §6 覆盖率从 ~33% (6/18) 提升到 ~78% (14/18)：**

| 新增 e2e（6 个）| 验证内容 |
|---------------|---------|
| idempotency 真测（替换原弱测试）| 同 idem key + 同 source_ref_id 跨用户产生不同 settlement |
| A 的 study 不出现在 B 的 today | β.3 partition 内部数据隔离 |
| A 的 reward ledger 不污染 B 的 balance | 用 before/after delta 验证（评审采纳）|
| B 不能写入 A 的 review_group | audit §6 review owner-check |
| B 的 inventory 不被 A 的 purchase 污染 | β.3 in-memory partition（β.5 持久化 dev only）|
| B 不能开 A 的 lottery box → 404 | audit §6 lottery owner-check（PG 直插）|
| B 不能提交到 A 的 fishing task → 404 | audit §6 fishing owner-check |

**β.8 文档同步：**
- 本 plan 文件标 status=已完成 + 加 Batch 1/2/3 实施记录
- α 评审采纳清单已在 plan 开头记录
- β 残留项明示在源代码注释：
  - `dev-store.ts:228` withUser doc 说明 binding 语义
  - `pg-persistence.ts:15` β.5b lazy-load 限制
  - β.5 saveAsync 内联注释 ownedItems/equipped 仅 DEV_USER_ID 持久化

**测试：76/76 e2e pass**（+6 new isolation e2e）

---

## β 残留（Phase E1 切流前 must-do）

按重要度排序：

1. **β.5b: lazy-load 非 DEV_USER_ID 用户数据**
   - 现状：startup `loadAsync(DEV_USER_ID)` 只 hydrate 一个 bucket
   - 影响：AUTH_ENFORCE=true 时，server restart 后非 dev 用户的 in-memory cache 为空，请求看不到自己的历史数据（PG 真理仍在）
   - 实施方案：dev-store 在 `withUser(userId, fn)` 入口检测 unseen userId，触发 async `loadAsync(userId)` + hydrate 到 bucket。需要异步流入 sync withUser 路径，建议增加 `ensureUserLoaded(userId): Promise<void>` 公共方法，controller 在 AuthGuard 之后显式 await

2. **β.5c: ownedItems / equipped* / wallet snapshot 字段扩 user_id**
   - 现状：DevStoreSnapshot 这几个字段是 flat 单用户视角（没有 user_id）；saveAsync 仅 DEV_USER_ID 路径持久化
   - 影响：非 dev 用户的 purchase / equip / wallet 变更不入 PG。Restart 后丢失
   - 实施方案：DevStoreSnapshot 加 `ownedItemsByUser` / `equippedOutfitByUser` / `walletByUser` 字段，serialize 跨用户 dump，pg-persistence 跨用户 INSERT

3. **β.6 完全去 withUser（cosmetic，非阻塞）**
   - 现状：withUser 是合法 binding 入口
   - 替代方案：给所有 ~50 dev-store 公共方法加 userId 第一参数，移除 `this.userId` 字段；getter 内部按入参取 bucket
   - 阻塞性：无（withUser 现在工作正常）

4. **β.7 lottery 跨用户测试硬化**
   - 现状：直接 PG 插入 box，但 dev-store in-memory 未 reload，所以测试实际验证的是「no-such-box」而不是「not-yours」（同样返 404）
   - 修法：β.5b lazy-load 落地后，可触发 dev-store 实际读到 PG 中的 box，再测 cross-user 真隔离

5. **review-attempts /local-batch 跨用户 owner-check 未覆盖**
   - β.7 #11 测了 submit single review attempt cross-user。submitLocalReviewBatch 路径未单独测
   - 路径不同但底层都走 review_group lookup，理论上同样受 audit §6 保护

---

## 工时实测

| 子项 | 估时 | 实际 |
|------|------|------|
| β.1 hot-fix | 0.5-1 小时 | ~30 分钟 |
| β.2 backup partition | 1-2 小时 | ~45 分钟 |
| β.3 内部状态 partition | 4-6 小时 | ~1.5 小时（getter 模式比预期省力）|
| β.4 idempotency Map | 0.5 小时（β.3 内顺手）| ~0 顺带完成 |
| β.5 pg-persistence userId | 2-3 小时 | ~1 小时 |
| β.6 移除 withUser | 1 小时 | 0（决定保留 withUser 作为 binding 入口）|
| β.7 补 e2e | 2-3 小时 | ~1 小时（6 个用例，2 处需修测试预设状态）|
| β.8 文档 | 1 小时 | ~30 分钟 |
| **合计** | **12-17 小时** | **~5 小时实际**（估时偏高，多亏 getter 模式）|

---

## 下一阶段

α + β 主体完成。可以进入：
- **Phase B（移动端身份层）** — 与 β 残留项正交，可并行
- **β 残留收尾**（β.5b lazy-load + β.5c snapshot 扩字段）— Phase E1 切流前必做，可拆为独立 PR
- **Phase E1 AUTH_ENFORCE=true 切流** — 必须先做 β 残留
