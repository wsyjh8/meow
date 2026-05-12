# Plan: 需求 23 Phase D — 备份/恢复 user-scoped 闭环 (v2)

**Plan Version:** v2（v1 → v2 大重写，吸收两份外部评审）
**Status:** **complete**（PR-D-α/β/γ/δ 全部落地；mobile +4 phase_d_e2e + backend backup-persistence ~12 e2e 全部通过。Phase G 收尾时确认 PRD §9 §9.5 / §9.7-1 全 ✅）
**Branch:** `feature/user-auth`
**实施模型:** Opus 4.7 1M context Max

**前序:** A1-A3 / A4-α / A4-β + hot-fixes / B + hot-fixes / C (PR-α/β/γ/δ)

**Phase D commits（按 PR 顺序）：**
- PR-D-α (mobile backup auth client + 10MB body limit): `83726ec`
- PR-D-β (backup PG 持久化 + BackupController 旁路 dev-store + user_id 校验): `aaefffc`
- PR-D-γ (restore 无条件 user_id 覆盖 + 6-entity pollution check): `2f32510`
- PR-D-δ (phase_d_e2e T1-T14 + multi-account coexistence + bind preserves backup): `4c679a9`

**关联:**
- [plan-023-用户系统与用户数据隔离-v2.md](plan-023-用户系统与用户数据隔离-v2.md) §8 / §14
- [plan-023-D-backup-restore-closure-v1.md](plan-023-D-backup-restore-closure-v1.md)（前一版，本文重写，v1 已标 ⚠️ Superseded）
- [plan-023-C-mobile-local-partition-v2.md](plan-023-C-mobile-local-partition-v2.md)

**日期:** 2026-05-10（v2 起草 + 落地）→ 2026-05-11（Phase G 闭环确认）

---

## 0. v2 重写说明

v1 收到两份外部评审，**所有 P0/P1/P2 指控经 grep 核实全部成立**。v1 主要缺陷：

| 缺陷 | 严重度 | v1 处理 | v2 修复 |
|------|--------|---------|---------|
| **mobile BackupUploadService / BackupRestoreService 直接用 http.* 不走 AuthHttpClient** | 🔴 P0 | v1 未列入 scope | v2 §4.1 + D.0 强制接 ApiClient / AuthHttpClient |
| **`storeBackup(userId)` → `saveToDisk()` 用 this.userId 不是入参** | 🔴 P0 | v1 未发现 | v2 §4.2 修 storeBackup 调用链 |
| **lazy-load 排除 + 承诺 restart 不丢 backup 互相矛盾** | 🔴 P1 | v1 §1.2 推 β.5b 但 §9 又承诺闭环 | v2 §4.2 BackupController 旁路 dev-store 直接读 PG（不依赖 lazy-load） |
| **restore 不强制覆盖 user_id（`r['user_id'] ?? userId` 保留 snapshot 行字段）** | 🔴 P1 | v1 §4.2 示例只检查 word_records 一个表 | v2 §4.3 LocalDatabase.replaceAll* 全部改为无条件覆盖 + 服务端上传时校验 |
| **snapshot 污染检查只覆盖 word_records 一个表 + 服务端零校验** | 🟡 P2 | v1 §4.2 示例代码片段 | v2 §4.3 客户端 + 服务端双重校验所有 user_id 字段 |
| **HTTP body limit NestJS 默认 100KB，10MB snapshot 必 413** | 🟡 P2 | v1 D-T6 假设成功 | v2 §4.2 main.ts 显式 `express.json({limit:'10mb'})` |
| **migration 010 缺 DOWN** | 🟡 P2 | v1 §4.1 只给 UP | v2 §5.1 加 DOWN |
| **§9 "闭环达成"过于乐观（backup 不含猫猫数据）** | 🟡 术语 | v1 §9 措辞模糊 | v2 §9 明示「backup 闭环 = mobile 学习进度跨设备恢复；猫猫/装扮/奖励靠 user_id 稳定延续不走 backup payload」 |
| **schema_version 不匹配策略未明示** | 🟢 弱 | v1 D-T7 仅测字段缺失 | v2 D6 + §4.3 决策 |
| **多账号本地共存 restore 未测** | 🟢 弱 | 无 | v2 §6 D-T11 新增 |
| **估时偏乐观（A4-β 30% 折扣不适用 D）** | 🟢 弱 | v1 §8 "实际 5-8h" | v2 §8 用保守 9-12h，删折扣行 |
| **PG 表数 35 vs 34** | 🟢 笔误 | v1 §2.6 | v2 改 34 |

12 项修复。v1 保留作历史 iteration 记录。

---

## 1. Phase D scope（v2 修订）

### 1.1 在范围（v2 新增 D.0 mobile auth client + D.0.5 storeBackup 修链）

| 子项 | 工作量 | 优先级 |
|------|--------|--------|
| **D.0 mobile BackupUploadService / BackupRestoreService 接 ApiClient（v2 新增）** | 小 | 🔴 P0 必须 |
| **D.0.5 storeBackup 调用链修：bind userId 至 saveAsync（v2 新增）** | 小 | 🔴 P0 必须 |
| D.1 后端加 `backup_snapshots` 表 + migration 010（含 DOWN） | 中 | 🔴 必须 |
| **D.2 `pg-persistence.ts` 加 backup load/save **+ BackupController 直接绕过 dev-store 读 PG**（v2 修订）** | 中 | 🔴 必须 |
| D.3 客户端 restore 强制覆盖 user_id（不再 `r['user_id'] ?? userId`）+ 服务端上传校验 | 小 | 🔴 P1 必须 |
| D.4 main.ts 配置 HTTP body limit | 极小 | 🔴 必须 |
| D.5 历史 in-memory 备份兼容性 | 小 | 🟢 接受丢失 |
| D.6 跨设备 restore e2e + 多账号本地共存测试 | 中 | 🔴 必须 |
| D.7 PRD §9.5 / §9.7 验收 e2e + 文档收尾 | 小 | 🔴 必须 |

### 1.2 不在范围（v2 收紧）

- AUTH_ENFORCE=true 切流 → Phase E1
- β.5b 后端 lazy-load 完整版（user A/B/C 不限于 backup 的 lazy-load）→ 独立后端 PR
  - **注意：backup 数据的 cross-user 读取通过 D.2 BackupController 直接查 PG 实现，不依赖 β.5b。** v1 把 β.5b 排除但又承诺 backup 闭环是逻辑漏洞，v2 通过"backup 走专用 PG 旁路"切断这个依赖。
- β.5c 后端 snapshot 扩字段（`ownedItems` / `equipped*` / `wallet`） → 独立后端 PR
  - **注意：这些数据不属于 backup payload。** 它们已经在后端 PG 业务表 (`inventory_items` / `equipment_slots` / `secondary_wallets`) 按 user_id partition 持久化（A4-β 已做）。换设备登录后，由后端业务表查询自然延续，**不需要走 backup**。详见 §9 闭环定义。
- 备份加密
- 跨设备恢复主动 UI 触发 / 文案 → Phase F UX 范围
- Audit §6 e2e 残留 4 用例 → 独立后端 PR

---

## 2. 现状摸底（v2 grep 实测重新核对）

### 2.1 Mobile snapshot_export / backup_restore — **scope 是 user-scoped**

但**调用 HTTP 的 service 没接 AuthHttpClient**：

| service | 现状 | grep |
|---------|------|------|
| `SnapshotExportService` | ✅ user-scoped 读 SQLite | `snapshot_export_service.dart:33/40` |
| `BackupRestoreService._applySnapshot` | ✅ user-scoped 写 SQLite | `backup_restore_service.dart:33/42` |
| `BackupUploadService.upload(snapshot)` | ❌ **直接 `http.post`** | `backup_upload_service.dart:2/64` |
| `BackupRestoreService.fetchLatestMeta()` | ❌ **直接 `http.get`** | `backup_restore_service.dart:2/53` |
| `BackupRestoreService.fetchLatestSnapshot()` | ❌ **直接 `http.get`** | `backup_restore_service.dart:2/97` |

**含义：** mobile 备份/恢复请求**完全不带 `Authorization` header**。

- AUTH_ENFORCE=false: 后端 `AuthGuard` permissive fallback 到 `DEV_FALLBACK_USER_ID` (`dev-user-001`)。真实用户上传的备份 → 后端写到 dev-user-001 bucket。**这是当前生产数据的真实状态。**
- AUTH_ENFORCE=true: 直接 401，备份功能完全不工作。

这是 v1 plan 漏看的 P0 阻塞，必须先修才能谈 Phase D 后续工作。

### 2.2 后端 BackupController + dev-store backup 路径

`BackupController.uploadBackup` 流程：
```ts
@Post()
async uploadBackup(@Body() body: any, @CurrentUser() user: RequestUser) {
  // ...
  devStore.storeBackup(user.id, backupId, ..., snapshot, ...);
  await repositories.ensurePersisted();
  return { status: 'succeeded', ... };
}
```

`devStore.storeBackup`:
```ts
storeBackup(userId, backupId, ...) {
  this.latestBackupByUser.set(userId, { ... });
  this.backupSnapshotByUser.set(userId, snapshot);
  this.saveToDisk();   // ← 这里
}
```

`saveToDisk`:
```ts
saveToDisk(): void {
  if (this.persistence.saveAsync) {
    const snapshot = this.serialize();
    const userIdAtSave = this.userId;   // ← 用 this.userId 不是 storeBackup 的入参！
    // ...
    this.persistence.saveAsync!(snapshot, userIdAtSave);
  }
}
```

**BackupController 没用 withUser 包装** — 它直接调 `devStore.storeBackup(user.id, ...)`。所以 `this.userId` 在这个调用瞬间是上一次任何 withUser 留下的值，最常见就是 default `'dev-user-001'`。saveAsync 收到的 userId 参数错。

后果叠加 §2.1 的问题：
- mobile 无 Authorization → permissive fallback user.id = dev-user-001
- storeBackup 入参 userId = dev-user-001
- saveToDisk 用 this.userId 还是 dev-user-001
- saveAsync 写 PG 用 dev-user-001 — **凑巧"对"**，因为整个链路都是 dev-user-001

**但 D.0 修复 mobile 带 Authorization 后**：
- mobile 带真实 user token → user.id = real-user-A
- storeBackup 入参 userId = real-user-A → in-memory `latestBackupByUser['real-user-A']` 正确
- saveToDisk → this.userId 还是 dev-user-001（没 withUser 改它）
- saveAsync(snapshot, 'dev-user-001') → 用 dev-user-001 过滤 snapshot.latestBackupsByUser → 不命中 → 不写 PG
- **真实用户的 backup 永远不入 PG**

所以 D.0 必须 + D.0.5 修这个调用链才完整。

### 2.3 LocalDatabase.replaceAll* — restore 保留 snapshot 的 user_id

`local_database.dart:350-365`:
```dart
Future<void> replaceAllWordRecords(
  List<Map<String, dynamic>> records, {
  required String userId,
}) async {
  await _db!.delete('word_records', where: 'user_id = ?', whereArgs: [userId]);
  for (final r in records) {
    await _db!.insert('word_records', {
      // ...
      'user_id': r['user_id'] ?? userId,    // ← 优先使用 snapshot 行的 user_id
    });
  }
}
```

如果 snapshot 行的 `user_id` 是其他用户（污染场景或第三方备份注入）：
1. DELETE WHERE user_id=currentUserId（删自己的行 ✓）
2. INSERT 时 user_id 用 snapshot 的 user_id（污染值）
3. 写完后查 `WHERE user_id=currentUserId` 返空 — 数据没了
4. 污染行落到别人的 bucket — 但当前用户看不见

→ **restore 实际把当前用户数据清空** + 数据落到别人 bucket。D-T5 验收会失败。

修法（参考 Review 2 P1-2）：把 `r['user_id'] ?? userId` 改为无条件 `userId`，所有 user-scoped replaceAll* 方法都改。

### 2.4 pg-persistence 不存 backup（v1 已发现，v2 沿用）

`pg-persistence.ts` grep `backup` 0 命中。PG `\dt` 无 backup 表。

### 2.5 dev-store initAsync 只 load DEV_USER_ID

`dev-store.ts:initAsync` 注释：
```
β.5 startup: load only DEV_USER_ID's slice. Other users' state
restores on demand via lazyLoad (β.5b — currently a stub: data
for non-dev users will only exist after their first request).
```

含义：即使 D.1 把 backup 写进 PG，user B 的 backup 行在 PG 里，但 dev-store in-memory `backupSnapshotByUser` 启动时不会预加载 user B 的 slice。BackupController 走 `devStore.getBackupSnapshot(user.id)` 读 in-memory Map → undefined → 返 `no_backup_yet`。

**v2 解：D.2 BackupController 不走 dev-store 读，直接查 PG `backup_snapshots` 表**（旁路 in-memory 缓存）。这切断了 backup 与 β.5b 的依赖。

### 2.6 PG 数据库现状

```
$ psql -d meow_dev -c "\dt"
# 34 张表，无任何含 'backup' 的表名
```

（v1 写 35 是笔误，db-uniqueness-audit §1 实测 34）

---

## 3. 决策点（v2 — D1-D6）

> **2026-05-10 用户拍板：D1-D5 按 v1 推荐**（JSONB 单插槽 / 接受老 in-memory 丢失 / soft check + 强制覆盖 / 不版本化表 / 跨设备不弹提示）。**v2 新增 D6 解决评审遗漏。**

### D1-D5 同 v1（不变）

### D6 — snapshot schema_version 不匹配处理（**v2 新增，评审 1 漏覆盖 3**）

**场景：** Device 1 用 schema v1 上传，App 升级到 v2，Device 2 装新版后 restore 拿 v1 snapshot。

**决策：客户端在 `_applySnapshot` 入口校验 schema_version：**
- 完全相等 → 应用
- 兼容旧版（如 `p3_1_snapshot_v2` → `p3_2_snapshot_v1` 是向后兼容，已有 `legacySchemaVersion` 字段支持）→ 应用并 debug log 提示
- 完全不兼容 → 拒绝，UI 弹"这份备份来自不兼容的旧版本，请升级 App"

实现位置：`backup_restore_service.dart:119-122` 现有的 `_acceptedSchemas.contains(schemaVersion)` 检查已部分覆盖此逻辑。v2 不引入新机制，仅在 §4.3 测试加 D-T9 验证。

---

## 4. 实施拆分（v2 — 4 PR for Opus 4.7 1M Max）

按 Phase C 同模式，重切为 4 PR（v1 的 3 PR 范围扩大后重切）：

### 4.1 PR-D-α — Mobile auth client 接入 + HTTP body limit（最高优先 P0）

**目的：** Phase D 任何其他工作的前置——让 mobile backup 请求带 Authorization。

**改动：**

1. `backup_upload_service.dart`:
   - 构造接 `http.Client client` 参数，默认 `http.Client()`
   - 上传走 `_client.post(...)` 而非 `http.post(...)`

2. `backup_restore_service.dart`:
   - 同上 — 构造接 `http.Client client`
   - 三处 `http.get` / `http.post` 全部走 `_client`

3. 调用方（grep `BackupUploadService(...)` / `BackupRestoreService(...)`）：传 `AuthHttpClient` 实例。最简单的方式是利用 PR-B 留下的 `ApiClient.setDefaultHttpClient()`：
   ```dart
   BackupUploadService(client: http.Client client = ApiClient._defaultHttpClient)
   ```
   或者：BackupUpload/Restore 改为通过 ApiClient 暴露的方法（让 ApiClient 包一层）。

4. `apps/api/src/main.ts`:
   ```ts
   import { json } from 'express';
   // ...
   app.use(json({ limit: '10mb' }));
   ```
   或者：`@nestjs/platform-express` 的 NestExpressApplication 上调 `app.useBodyParser('json', { limit: '10mb' })`。

5. 单测：mock AuthHttpClient + 验证上传 / 拉取请求带 Bearer header

**测试：**
- `backup_upload_service_test.dart` / `backup_restore_service_test.dart` 新增/补充：assert Authorization header 注入
- 全套 mobile test 1212/1212 不破

**工作量：** 2-3 小时

### 4.2 PR-D-β — 后端 backup PG 持久化 + BackupController 旁路 dev-store（最高风险）

**目的：** backup 数据真写入 PG + 读取不依赖 dev-store in-memory（切断 β.5b 依赖）。

**改动：**

1. `migrations/010_backup_snapshots.sql`（**含 DOWN**，v1 漏）：
   ```sql
   -- UP
   CREATE TABLE backup_snapshots (
     user_id          VARCHAR(64) NOT NULL PRIMARY KEY
                       REFERENCES users(id) ON DELETE CASCADE,
     backup_id        VARCHAR(64) NOT NULL,
     schema_version   VARCHAR(64) NOT NULL,
     uploaded_at      TIMESTAMPTZ NOT NULL,
     snapshot_size    INT NOT NULL,
     device_id        VARCHAR(128),
     device_model     VARCHAR(255),
     snapshot         JSONB NOT NULL,
     updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );

   CREATE INDEX idx_backup_snapshots_uploaded_at
     ON backup_snapshots(uploaded_at);
   CREATE INDEX idx_backup_snapshots_backup_id
     ON backup_snapshots(backup_id);  -- v2 评审建议

   -- DOWN
   DROP INDEX IF EXISTS idx_backup_snapshots_backup_id;
   DROP INDEX IF EXISTS idx_backup_snapshots_uploaded_at;
   DROP TABLE IF EXISTS backup_snapshots;
   ```

2. `pg-persistence.ts`:
   - 加 `loadBackupForUser(userId)` / `saveBackupForUser(userId, ...)` / `clearBackupForUser(userId)` 三个方法，**独立于 saveAsync / loadAsync 主流程**
   - 这些方法对外暴露给 BackupController 直接调用

3. **BackupController 重写（v2 关键决策）：直接走 pg-persistence，不经 dev-store**
   ```ts
   @Controller('me/backup')
   @UseGuards(AuthGuard)
   export class BackupController {
     constructor(private readonly persistence: PgDevStorePersistence) {}

     @Post()
     async uploadBackup(@Body() body, @CurrentUser() user) {
       const meta = {
         backup_id: `backup-${Date.now()}`,
         schema_version: ...,
         uploaded_at: new Date().toISOString(),
         snapshot_size: ...,
         device_id, device_model,
         snapshot: body.snapshot,
       };
       
       // v2: server-side userId 校验防上传污染（评审 2 P2-1）
       this._validateSnapshotUserIds(body.snapshot, user.id);
       
       await this.persistence.saveBackupForUser(user.id, meta);
       return { status: 'succeeded', backup_id: meta.backup_id, ... };
     }

     @Get('latest')
     async getLatestBackup(@CurrentUser() user) {
       return await this.persistence.loadBackupMetaForUser(user.id);
     }

     @Get('latest/snapshot')
     async getLatestSnapshot(@CurrentUser() user) {
       return await this.persistence.loadBackupFullForUser(user.id);
     }
   }
   ```

   **理由（修复 v1 致命 1）：**
   - 走 dev-store in-memory 必须等 β.5b lazy-load 才能 cross-user 工作
   - 走 pg-persistence 直接查 PG `WHERE user_id = $userId` — 不需要 lazy-load，server restart 后立即正确
   - 切断 Phase D 对 β.5b 的依赖

4. **保留 dev-store backup map 作为 mobile snapshot 容器**——只是 BackupController 不再读它。这样 dev-store 的 hydrate / serialize / withUser 行为不变（避免 ripple 影响 A4-β 已通过的测试）。

5. `_validateSnapshotUserIds(snapshot, expectedUserId)`：扫 snapshot 中所有含 `user_id` 字段的子集合（`progress.word_records[*]` / `progress.card_states[*]` / 4 个 ex-SP entity 等），任一不匹配 → 400 `INVALID_SNAPSHOT_USER_ID`。

**测试：**
- `backup-persistence.e2e-spec.ts`（新）:
  - 上传 → server restart → 拉取 → 内容一致
  - user A 上传 → user B 拉 → no_backup_yet
  - device 1 上传 → device 2 (同 user A) 拉 → 拿到 device 1 内容 + device_id 正确
  - cross-device 不需要任何 lazy-load
  - 上传含他人 user_id 的污染 snapshot → 400
- migration_test: down → up 干净，up → down 干净

**工作量：** 4-5 小时

### 4.3 PR-D-γ — Restore 路径加固（强制覆盖 + 全表 + schema 兼容）

**目的：** 客户端 restore 不被污染数据带偏 + 服务端已防住的二次纵深防御。

**改动：**

1. `LocalDatabase` 所有 `replaceAll*` 方法（grep `replaceAllWordRecords` / `replaceAllInTable` / `replaceUserRowsInTable` 等约 6 个方法）:
   ```dart
   // before
   'user_id': r['user_id'] ?? userId,
   // after (v2 P1-2 评审采纳)
   'user_id': userId,  // unconditional — never trust snapshot row's user_id
   ```
   
2. `backup_restore_service.dart._applySnapshot` 入口加全表 user_id 一致性校验（v1 §4.2 只检查 word_records，v2 扩到全部 5 个 entity）:
   ```dart
   final foreignRowCounts = {
     'word_records': _countForeignRows(snapshot['progress']?['word_records']),
     'card_states': _countForeignRows(snapshot['progress']?['card_states']),
     'daily_checkins': _countForeignRows(snapshot['progress']?['daily_checkins']),
     'wordbook_progress': _countForeignRows(...),
     'custom_wordbooks': _countForeignRows(...),
     'vocabulary_notebook': _countForeignRows(...),
   };
   if (foreignRowCounts.values.any((c) => c > 0)) {
     debugPrint('[Restore] WARN: snapshot contains foreign user_ids: $foreignRowCounts');
   }
   ```

3. schema_version 兼容性（D6 决策）— 现有 `_acceptedSchemas.contains(schemaVersion)` 检查在 `:119-122` 已存在，v2 加 e2e 验证。

**测试：**
- `backup_restore_service_test.dart` 扩充：
  - 注入 snapshot 含 user_id != currentUserId 的 word_records 行 → restore 后查表，**所有写入的 user_id == currentUserId**（D-T5 真验收）
  - schema_version 不在 _acceptedSchemas 列表 → 拒绝 + UI 错误返回

**工作量：** 2-3 小时

### 4.4 PR-D-δ — E2E + 多账号本地共存 + PRD §9 验收 + 文档（最后）

**目的：** 把所有验收 e2e 落地 + 文档收尾。

**改动 / 测试矩阵 — 见 §6。**

**工作量：** 3-4 小时

---

## 5. migration 010 SQL（v2 含 DOWN）

```sql
-- 010_backup_snapshots.sql
-- 需求 23 Phase D PR-D-β：备份 PG 持久化（v1 漏 DOWN，v2 补）
--
-- 设计：单插槽 per user，last-write-wins。snapshot JSONB 存
-- 完整客户端导出（mobile 端表数据，不含后端业务表如 inventory_items
-- — 那些数据通过自己的 user_id-scoped PG 表跨设备延续）。
--
-- References:
--   docs/design/plan-023-D-backup-restore-closure-v2.md §4.2

-- UP

CREATE TABLE backup_snapshots (
  user_id          VARCHAR(64) NOT NULL PRIMARY KEY
                    REFERENCES users(id) ON DELETE CASCADE,
  backup_id        VARCHAR(64) NOT NULL,
  schema_version   VARCHAR(64) NOT NULL,
  uploaded_at      TIMESTAMPTZ NOT NULL,
  snapshot_size    INT NOT NULL,
  device_id        VARCHAR(128),
  device_model     VARCHAR(255),
  snapshot         JSONB NOT NULL,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_backup_snapshots_uploaded_at
  ON backup_snapshots(uploaded_at);
CREATE INDEX idx_backup_snapshots_backup_id
  ON backup_snapshots(backup_id);

-- DOWN

DROP INDEX IF EXISTS idx_backup_snapshots_backup_id;
DROP INDEX IF EXISTS idx_backup_snapshots_uploaded_at;
DROP TABLE IF EXISTS backup_snapshots;
```

---

## 6. 测试矩阵（v2 — 新增 D-T8 / D-T11 / D-T12）

| # | 类型 | 用例 | 验收 |
|---|------|------|------|
| D-T1 | persistence | 上传 → server restart → 拉取 | 内容一致（**v2 必过项**，验证 PR-D-β 切断了 β.5b 依赖） |
| D-T2 | persistence | 同 user 多次上传 | PRIMARY KEY 单插槽 UPSERT，最新 wins |
| D-T3 | 跨用户 | A 上传 → B 拉 | `no_backup_yet`（PR-D-β PG 层验证）|
| D-T4 | 跨设备 | device 1 上传 → device 2 同 user 拉 | snapshot + device_id 正确 |
| **D-T5** | **restore 防御** | **snapshot 注入 user_id ≠ current 的行 → restore** | **所有写入行 user_id == currentUserId（验证 PR-D-γ replaceAll* 强制覆盖）** |
| D-T6 | 大数据 | 上传 9.5 MB JSONB snapshot | 成功（验证 main.ts body limit=10MB） |
| D-T7 | 边界 | snapshot 字段缺失 | 部分 restore，已有 entity 保留 |
| **D-T8** | **服务端校验**（v2 新增） | **客户端伪造 snapshot 含 user_id != token user 的行 → 上传** | **400 INVALID_SNAPSHOT_USER_ID** |
| D-T9 | schema_version | 上传 v1 schema → app v2 拉 | 根据 `_acceptedSchemas` 兼容列表决定 accept/reject |
| D-T10 | 删除级联 | DELETE FROM users WHERE id=X | backup_snapshots 行级联删除 |
| **D-T11** | **多账号共存**（v2 新增）| **device 1: A 学习 → logout → C 登录 → C restore C 自己的 snapshot** | **本地 drift 同时存在 user_id=A 和 user_id=C 行；C 的 restore 只 DELETE WHERE user_id=C；A 数据原封不动等 A 重登可见** |
| **D-T12** | **auth header**（v2 新增）| **mobile 上传 / 拉取请求** | **所有请求带 `Authorization: Bearer ...`（验证 PR-D-α）** |
| D-T13 | PRD §9.5 | guest 上传 → bind → 仍能拉 | user_id 不变，备份延续 |
| D-T14 | PRD §9.7 | 未带 token /me/backup/* | AUTH_ENFORCE=true → 401；false → permissive |

---

## 7. 风险与缓解（v2）

| 风险 | 缓解 |
|------|------|
| mobile 接入 AuthHttpClient 破坏现有 backup 功能 | D-T12 + 现有 backup 单测全过；分 PR D-α 隔离 |
| storeBackup 调用链改造影响 A4-β 测试 | D-α 不动 storeBackup，D-β 让 BackupController 旁路 dev-store；dev-store 行为不变 |
| BackupController 直接查 PG 后 dev-store backup map 变成 dead 字段 | 保留 in-memory map（A4-β 仍依赖于 snapshot serialize）；只是 BackupController 不读 |
| migration 010 在生产已有数据库部署失败 | 010 仅 CREATE TABLE，无 ALTER；DOWN 干净；与 008/009 不冲突 |
| JSONB snapshot > 10MB | 10MB body limit + 上传前 client 检查；如真撞 → §3 D1 改 Object Storage |
| LocalDatabase.replaceAll* 改 user_id 后老逻辑误回归 | unit test 锁定行为；PR-D-γ 完整 grep `r\['user_id'\]` 替换 |
| 服务端 _validateSnapshotUserIds 性能（大 snapshot 扫一遍）| 校验只看 user_id 字段，O(n) 不算昂贵；< 1MB 典型 snapshot < 10ms |
| schema_version 拒绝场景缺 UI 文案 | Phase F 范围；v2 仅在 backup_restore_service 留 errorCode，UI 文案归 F |

---

## 8. 拆分上线 + 估时（v2 — 4 PR，去 30% 折扣）

```
PR-D-α (mobile auth client + body limit, P0 前置)
  ↓
PR-D-β (PG 持久化 + BackupController 旁路 dev-store + 服务端校验)
  ↓
PR-D-γ (restore 强制覆盖 + 全表污染防御)
  ↓
PR-D-δ (e2e + 多账号共存 + 文档)
```

| PR | 估时（保守，无折扣）|
|----|-----|
| PR-D-α mobile auth + body limit | 2-3h |
| PR-D-β PG persistence + Controller 旁路 + server-side 校验 | 4-5h |
| PR-D-γ restore 强制覆盖 + 全表防御 | 2-3h |
| PR-D-δ e2e + multi-account + docs | 3-4h |
| **合计** | **11-15h**（约 1.5-2 个工作日） |

v1 估时 9-12h + "实际 5-8h" 折扣 — v2 评审采纳删掉折扣，承认 Phase D 涉及真 schema migration + 跨系统校验 + 跨设备 e2e，不适用 A4-β 30% 机械改造经验。

---

## 9. Phase D 完成后的状态（v2 修订口径）

**Phase D 闭环达成的精确定义（v2 修订）：**

> Phase D 完成 = **mobile 端学习数据 + 设置 + 备份元数据**的跨设备 user-scoped 恢复链路打通。
>
> 后端业务数据（猫猫 / 装扮 / 奖励 / 钱包 / inventory / equipment）的跨设备延续**不依赖 backup payload** — 它们已经存在后端 user_id-scoped PG 业务表（`inventory_items` / `equipment_slots` / `secondary_wallets` / `pet_profiles` 等，A4-β 已 partition）。换设备登录后由后端 `/me/*` API 自然返回，不需要走 `/me/backup/*` 通道。
>
> 这是 plan v2 §6.2「同行升级 user_id 不变」+ §3.5「副机制数据 per-user」的直接 corollary，**不是 Phase D 缺陷**。

### Phase D 完成可宣告（v2 修订口径）

- ✅ Mobile 备份请求带 Authorization（PR-D-α）
- ✅ 后端 `backup_snapshots` 表持久化（PR-D-β）+ server restart 不丢
- ✅ BackupController 旁路 dev-store 直接查 PG（PR-D-β）— 不依赖 β.5b lazy-load
- ✅ 跨设备同 user 恢复 mobile 学习数据（PR-D-β + D-T4）
- ✅ Restore 写入强制覆盖 user_id（PR-D-γ）+ 服务端 + 客户端双校验
- ✅ 多账号共存：A 数据不被 C 的 restore 污染（PR-D-δ D-T11）
- ✅ PRD §9.5（绑定不丢）+ §9.7（未授权拒访）e2e（PR-D-δ）

### 距离需求 23 完整闭环还差

- β.5b 后端 lazy-load（非 backup 路径的用户数据）→ 独立 PR
- β.5c 后端 snapshot 扩字段（`ownedItems` / `equipped*` / `wallet`）→ 独立 PR
  - 不影响 backup（这些数据走业务表 user_id partition）
  - 影响 in-memory restart 后非 dev 用户数据可见性
- Audit §6 e2e 残留 4 用例
- Phase E1 切流

---

## 10. 评审采纳记录

### Review 1（10 项全部采纳，0 拒绝）

| 评审项 | 处理 |
|--------|------|
| 致命 1: lazy-load 缺口（β.5b 矛盾） | v2 BackupController 旁路 dev-store 直接查 PG |
| 致命 2: §9 闭环过乐观（猫猫数据）| v2 §9 修订术语：「backup 闭环 = mobile 学习数据；后端业务数据靠 user_id 稳定」 |
| HTTP body limit 漏 | v2 §4.1 main.ts express.json limit |
| 幂等性未明示 | v2 §9：「last-write-wins + PRIMARY KEY 单插槽 = 天然幂等」 |
| schema_version 兼容策略 | v2 D6 新增 + 利用现有 `_acceptedSchemas` |
| PG 表数 35→34 | v2 §2.6 改 34 |
| 估时偏乐观 | v2 §8 删 30% 折扣 |
| 跨设备 UI 触发归属 | v2 §1.2 明示 Phase F |
| 多账号本地共存测试 | v2 §6 D-T11 |
| backup_id 索引 | v2 §5 加 `idx_backup_snapshots_backup_id` |

### Review 2（6 项全部采纳，0 拒绝）

| 评审项 | 处理 |
|--------|------|
| P0-1: mobile backup/restore 不走 AuthHttpClient | v2 §4.1 PR-D-α |
| P0-2: storeBackup → saveToDisk this.userId 不一致 | v2 §4.2 BackupController 旁路（绕过 saveToDisk） |
| P1-1: lazy-load 矛盾 | 同 Review 1 致命 1 |
| P1-2: replaceAll user_id 不强制 | v2 §4.3 无条件覆盖 |
| P2-1: snapshot 污染只检查 word_records + 服务端零校验 | v2 §4.3 客户端全表 + 服务端 `_validateSnapshotUserIds` |
| P2-2: migration 010 缺 DOWN | v2 §5 加 DOWN |

---

## 11. 下一步

请用户确认：

1. **D1-D6 决策点**（D1-D5 同 v1 用户已拍板；**D6 schema_version 兼容**新增是否同意）
2. **4 PR 拆分**是否合理（v2 比 v1 多 1 个 PR，因为 D.0 mobile auth client 必须独立前置）
3. **估时 11-15h**（无折扣，承认 v1 5-8h 过于乐观）
4. **§9 闭环术语修订**是否接受（明示 backup 不含后端业务数据，是 by-design 不是漏洞）
5. 是否同意先做 **PR-D-α**（mobile auth client + body limit，P0 阻塞前置）

确认后按 α → β → γ → δ 顺序实施。
