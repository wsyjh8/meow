# Plan: 需求 23 Phase D — 备份/恢复 user-scoped 闭环

> ⚠️ **Superseded by [`plan-023-D-backup-restore-closure-v2.md`](./plan-023-D-backup-restore-closure-v2.md)** — historical iteration only. v1 用户确认前收到两份评审，所有 P0/P1/P2 指控成立，整体被 v2 重写（新增 mobile auth client 接通 + BackupController 旁路 dev-store + restore 无条件覆盖 + 多账号本地共存等）。Phase D 实施记录走 v2；本文档保留为历史 trace。
>
> 不要按本文档实施。

---

**Plan Version:** v1
**Status:** draft → superseded
**Branch:** `feature/user-auth`
**实施模型:** Opus 4.7 1M context Max
**前序:**
- Phase A1-A3 / A4-α / A4-β + hot-fixes: 后端 auth + dev-store partition + audit §6
- Phase B + hot-fixes: 移动端身份层
- Phase C (PR-α/β/γ/δ): 移动端本地 partition + drift v13 + pending-local-guest migration + epoch race guard

**关联:**
- [plan-023-用户系统与用户数据隔离-v2.md](plan-023-用户系统与用户数据隔离-v2.md) §8
- [plan-023-C-mobile-local-partition-v2.md](plan-023-C-mobile-local-partition-v2.md) §1.3 §10（明示 C ≠ 闭环 + D 接力）
- [audits/sp-keys-audit.md](audits/sp-keys-audit.md) §8

**日期:** 2026-05-10

---

## 0. Context — Phase D 真实 scope

写 plan 前实测 grep，发现 **Phase D 的工作范围远小于 plan v2 §8 写的**——大部分子项被 PR-C-β 和 A4-β.2 提前做了：

| plan v2 §8 写的 Phase D 工作 | 实际状态 |
|----------------------------|---------|
| §8.1 mobile `snapshot_export` 限定当前 user_id | ✅ **PR-C-β 已完成**：`snapshot_export_service.dart:13-19` 注释 + 实施确认每个表读都按 `_userId` 过滤 |
| §8.2 mobile `backup_restore` 限定当前 user_id | ✅ **PR-C-β 已完成**：`backup_restore_service.dart:177-237` `_applySnapshot` 全部用 `userId: _userId` |
| §8.3 后端 backup 路径含 user_id | ⚠️ **API 路径不变**（仍 `/me/backup`，user 从 token 解析）— A4-β.2 commit 52c1a30 已 partition `BackupController` |

**但 grep 揭露了一个 plan v2 §8 没明示的真问题：**

```
$ grep -n -i "backup" apps/api/src/infrastructure/postgres/pg-persistence.ts
# 0 matches
$ psql -d meow_dev -c "\dt" | grep -i backup
# 0 matches
```

**P0 gap：后端备份数据从未持久化到 PG。** dev-store 在 `latestBackupByUser` / `backupSnapshotByUser` 两个 `Map<userId, ...>` 里 in-memory 存着，DevStoreSnapshot 序列化字段也写好了（`latestBackupsByUser` / `backupSnapshotsByUser`），但 `PgDevStorePersistence.saveAsync` 不识别这两个字段——**只是默默丢弃**。

→ 用户上传备份后，**server restart 即丢失全部备份数据**。
→ 跨设备恢复（设备 1 备份 → 设备 2 拉同一 user 的备份）功能上**当前不工作**——backup 数据虽然 in-memory per-user 分桶了，但 server restart 后所有用户都看到 `no_backup_yet`。

这才是 Phase D 真正要补的核心。

---

## 1. Phase D scope

### 1.1 在范围

| 子项 | 工作量 | 优先级 |
|------|--------|--------|
| D.1 后端加 `backup_snapshots` 表 + migration 010 | 中 | 🔴 必须 |
| D.2 `pg-persistence.ts` 加 backup 字段 load/save | 中 | 🔴 必须 |
| D.3 历史 in-memory 备份兼容性（dev-user-001 已存 in-memory 数据的 migration 路径）| 小 | 🟡 视实测情况 |
| D.4 跨设备 restore 流程 e2e | 中 | 🔴 必须 |
| D.5 客户端 restore 后 user_id 校验（防误恢复他人备份）| 小 | 🔴 必须（安全） |
| D.6 backup 元数据 SP key user-scoped 验证（已应 PR-C-β 完成）| 小 | 🟢 验收型 |

### 1.2 不在范围（明示）

- AUTH_ENFORCE=true 切流 → Phase E1
- β.5b 后端 lazy-load → 独立后端 PR（与 Phase E1 同期）
- β.5c 后端 snapshot 扩字段（`ownedItems` / `equippedOutfit` 等）→ 独立后端 PR
- Audit §6 e2e 残留 4 用例 → 独立后端 PR
- 备份加密 / 用户主动恢复 UI 文案 → 不在需求 23 范围

---

## 2. 现状摸底（grep 实测，非估算）

### 2.1 Mobile 侧（已完成）

- `snapshot_export_service.dart`:
  - 构造接 `userId` 参数（line 33）
  - `_db.getAllWordRecords(_userId)`（line 77）
  - `_db.getAllFromTableForUser('card_states', _userId)`（line 84）
  - 4 个 ex-SP-backed entity 也读 SQLite 按 user 过滤（PR-C-β D9）

- `backup_restore_service.dart`:
  - 构造接 `userId`
  - `_applySnapshot` 全部用 `userId: _userId`
  - `replaceAllWordRecords` / `replaceAllCardStates` / 4 个 ex-SP entity replace 都已 user-scoped

### 2.2 后端 BackupController（已 partition）

`backup.controller.ts`:
- `@UseGuards(AuthGuard)` + `@CurrentUser() user`
- `devStore.storeBackup(user.id, ...)`
- `devStore.getLatestBackupMeta(user.id)` / `getBackupSnapshot(user.id)`
- 路径无变化（`/me/backup` POST / GET）

### 2.3 dev-store backup 状态（in-memory Map<userId, ...>）

`dev-store.ts:199-204`:
```ts
private latestBackupByUser: Map<string, any> = new Map();
private backupSnapshotByUser: Map<string, any> = new Map();
```

`storeBackup` / `getLatestBackupMeta` / `getBackupSnapshot` 三个公共方法都接 `userId` 第一参数（β.2 已 partition）。

### 2.4 DevStoreSnapshot 序列化（已含 backup 字段）

`persistence.ts:55-71`:
```ts
// P3.2 Backup persistence
latestBackup?: any | null;          // legacy single-slot, kept for back-compat hydration
backupSnapshot?: any | null;        // legacy single-slot
latestBackupsByUser?: Record<string, any>;   // β.2 真理
backupSnapshotsByUser?: Record<string, any>; // β.2 真理
```

`dev-store.ts:508-509` serialize / `dev-store.ts:621-635` hydrate — 双向都接 backup 字段。

### 2.5 PgDevStorePersistence —— **完全不处理 backup**

`pg-persistence.ts`:
- `loadAsync(userId)` 16 个 `pool.query` SELECT 没有 backup 相关
- `saveAsync(snapshot, userId)` 完整扫了 `studyAttempts` / `reviewGroups` / 等 12 类业务表 INSERT，**没碰 snapshot.latestBackupsByUser / snapshot.backupSnapshotsByUser**

→ 结果：snapshot 序列化时这两个字段会写出，但 PG 持久化层选择性 INSERT 时**忽略它们**。下次 restart 加载只能从 PG 表读出业务数据，backup 字段在 loadAsync 返回的 snapshot 里是 undefined → hydrate 时进入空 Map。

### 2.6 PG 数据库现状

```
$ psql -d meow_dev -c "\dt"
# 35 张表，无任何含 'backup' 的表名
```

**没有 backup_snapshots 表。** 这是 D.1 的核心新增。

---

## 3. 决策点（D1-D5）

> **2026-05-10：以下为推荐方案，待用户拍板。**

### D1 — backup 数据存什么形态

**选项：**
- (a) JSONB 列存整个 snapshot（每用户一行，UPSERT by user_id）— 简单，与现有 last-write-wins 语义对齐
- (b) 关系化拆 snapshot 内容到现有业务表（study_attempts 等已有数据）— 重复存储，复杂
- (c) Object Storage（S3 / COS）+ PG 仅存指针 — 大 snapshot 友好但运维复杂

**推荐：(a)** — `backup_snapshots(backup_id, user_id, schema_version, uploaded_at, snapshot_size, device_id, device_model, snapshot JSONB)` UNIQUE(user_id) 单行/用户。理由：当前 snapshot < 1MB（实测 mobile 端 word_records ~几千行），JSONB 完全够用；与 `last-write-wins` 单插槽语义直接对齐；不引入 S3 运维负担。

### D2 — 历史 in-memory 备份兼容性

**场景：** β.2 之后 dev-user-001 用户已上传过若干次 in-memory 备份，pg-persistence 丢弃了。Phase D 上线时这些数据**已经丢了**。

**选项：**
- (a) 接受已丢，不做额外迁移
- (b) Phase D 上线后让 dev-user-001 重新上传一次（手动 smoke）

**推荐：(a)** — dev 数据，不值得写 migration。Phase D PR 描述明示「老的 dev-user-001 in-memory 备份将不再可见，请重新上传」。

### D3 — restore 后客户端 user_id 校验

**场景：** 用户登录后调 `/me/backup/latest/snapshot` 拿回 snapshot，但 snapshot 内容里每行有 `user_id` 字段（来自上传时的客户端导出）。如果客户端拿到这个 snapshot 直接 `_applySnapshot`，会写入当前登录 user 的本地表——可能出现 snapshot.row.user_id ≠ currentUserId 的情况（理论上 A 备份只能给 A 自己恢复，因为 server 按 user.id 返回；但客户端纵深防御该校验一次）。

**选项：**
- (a) 客户端 restore 前 assert `every(row.user_id == currentUserId)`，不匹配则拒绝
- (b) 客户端 restore 时**强制覆盖** `user_id = currentUserId`（把 snapshot 里的 user_id 字段忽略）
- (c) 不校验，信任 server

**推荐：(a) + (b)** — 软校验 + 强制覆盖：

1. 检查 snapshot 中所有行的 user_id 是否一致（要么全是同一个，要么 snapshot 是历史 single-user 形态没有 user_id 字段）
2. 一致但 ≠ currentUserId → 告警 + 仍允许（防止 snapshot 是从其他 device 同账号的，user_id 实际应该是同一个但理论上可能漂移）
3. 写入本地表时强制用 currentUserId 覆盖（β/C 既然已经 user-scoped DAO，所有 replace 方法都接 userId 参数，覆盖天然发生）

实质 (b) 已经在 PR-C-β 实现（`_applySnapshot` 用 `userId: _userId`）；(a) 是附加的纵深防御。

### D4 — backup 表是否 schema_version 版本化

**选项：**
- (a) 不版本化，最新 schema 一份
- (b) 加 `min_app_version` / `expires_at` 字段做未来扩展

**推荐：(a)** — 备份本身已经有 schema_version 字段（snapshot 里），不需要表层版本化。

### D5 — 跨设备恢复路径上有没有额外校验

**场景：** 设备 1 上传备份（device_id=A）→ 设备 2 登录同 user（device_id=B）→ 拉备份。device_id 不同。

**选项：**
- (a) 服务端不管 device_id，按 user.id 取最新 → 正常返回
- (b) 服务端记录 device 不匹配，客户端弹"这是其他设备的备份"提示
- (c) 客户端不弹，UI 只是普通的备份还原确认对话框

**推荐：(c) 不弹** — 跨设备恢复就是该功能的核心场景（PRD §3.6 强调"在新设备上找回进度"）。device_id 在备份记录里是 informational，不参与逻辑判定。

---

## 4. 实施拆分（按 Opus 4.7 1M Max 能力切，3 个 PR）

### 4.1 PR-D-α — Schema + persistence 核心（高风险）

**目的：** 把 backup 数据真正写进 PG，restart 不丢。

**改动：**

1. `apps/api/src/infrastructure/postgres/migrations/010_backup_snapshots.sql`（新增）：
   ```sql
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
   ```

   关键设计：
   - `PRIMARY KEY (user_id)` — 单插槽 last-write-wins per user
   - `ON DELETE CASCADE` — 用户删除时备份自动清理
   - JSONB 列存整个 snapshot

2. `apps/api/src/infrastructure/postgres/pg-persistence.ts`:
   - `loadAsync(userId)` 加 SELECT backup_snapshots WHERE user_id = $1，把结果 hydrate 进 snapshot.latestBackupsByUser / backupSnapshotsByUser
   - `saveAsync(snapshot, userId)` 加 INSERT/UPSERT backup_snapshots — 只持久化 userId 自己的 slice
   - `clearAsync(userId)` 加 DELETE FROM backup_snapshots WHERE user_id = $1

3. `apps/api/src/domain/persistence.ts`:
   - DevStoreSnapshot 字段不变（已含 `latestBackupsByUser` / `backupSnapshotsByUser`）

**测试：**
- backup-persistence.e2e-spec.ts（新增）：
  - 上传备份 → server "restart"（重新创建 dev-store + persistence）→ 拉备份能拿到原 snapshot
  - 用户 A 备份 → 用户 B 看不到（β.2 已测过 in-memory；D.1 后验证 PG 层也隔离）
  - device_id 在备份元数据中正确保留
  - JSONB snapshot 完整往返（写入大小 == 读取大小）

**工作量：** 4-5 小时

### 4.2 PR-D-β — restore 安全 + 跨设备 e2e（中风险）

**目的：** 客户端 restore 加纵深防御 + 端到端跨设备测试。

**改动：**

1. `apps/mobile/lib/core/storage/backup_restore_service.dart`:
   - `_applySnapshot` 入口加 user_id 一致性检查（D3 (a)）：
     ```dart
     final wordRecords = (snapshot['progress']?['word_records'] as List?) ?? [];
     final foreignRows = wordRecords.where((r) => 
       r['user_id'] != null && r['user_id'] != _userId).toList();
     if (foreignRows.isNotEmpty) {
       // soft warn — server should have returned only our user, but defense-in-depth
       debugPrint('[Restore] WARN: snapshot contains ${foreignRows.length} rows '
                  'with user_id != $_userId; will override on write.');
     }
     ```
   - 写入路径不变（已强制 `userId: _userId`）

2. 后端 e2e：cross-device 流程
   - 模拟 user A 在 device 1 上传备份
   - 模拟 user A 在 device 2 登录（不同 device_id）
   - GET /me/backup/latest/snapshot 返回 device 1 的 snapshot
   - 验证 device_id 在 response 中保留（让客户端 UI 显示"上次备份在 device 1"）

3. 移动端 widget test：
   - 注入 snapshot 含 user_id != currentUserId 的污染数据
   - 验证 restore 不写入污染数据 / debug log 警告
   - 跨设备场景 mock：拉回 device 1 备份 + apply 到 device 2 的本地表

**测试：**
- `backup_restore_service_test.dart`（增）：user_id 一致性 + 跨设备
- `backup-persistence.e2e-spec.ts`（增）：cross-device 拉取

**工作量：** 3-4 小时

### 4.3 PR-D-γ — 验收 e2e + 文档

**目的：** 把 PRD §9.5 / §9.6 / §9.7 安全验收用 e2e 落实。

**改动：**

1. `auth-isolation.e2e-spec.ts` 新增（接力 A4-β.7）：
   - PRD §9.5 「游客绑定不丢数据」：guest A 上传备份 → 绑定为 registered → 仍能拉到原备份（同行升级 user_id 不变，备份记录天然延续）
   - PRD §9.7 「未登录不能访问 backup」（AuthGuard 已保证，加测试明示）

2. `backup_restore_service_test.dart` / mobile e2e:
   - 「换设备登录恢复」manual smoke checklist
   - 「同设备 logout + 重登 同账号」自动恢复进度

3. `plan-023-用户系统与用户数据隔离-v2.md` 末尾加 Phase D 完成 commit hash + 验收清单对照

**工作量：** 2-3 小时

---

## 5. 测试矩阵

| # | 类型 | 用例 | 验收 |
|---|------|------|------|
| D-T1 | persistence | 上传备份 → 重新初始化 dev-store + pg-persistence → 拉备份 | 内容完全一致 |
| D-T2 | persistence | 同 user 多次上传 → 表中只有最新一行 | UNIQUE(user_id) UPSERT 工作 |
| D-T3 | 跨用户 | A 上传 → B 拉自己的 | `no_backup_yet`（β.2 已测，D 加 PG 层验证） |
| D-T4 | 跨设备 | device 1 上传 → device 2 同 user 拉 | 取回 device 1 的 snapshot + device_id 在元数据 |
| D-T5 | 安全 | snapshot 注入 user_id ≠ current 的污染行 | restore debug 告警 + 写入仍用 currentUserId（不污染他人） |
| D-T6 | 大数据 | 上传 10MB JSONB snapshot | 成功；查询性能 < 200ms |
| D-T7 | 边界 | snapshot 字段缺失（向后兼容） | restore 部分 entity，其他 entity 保留现状 |
| D-T8 | 删除级联 | DELETE FROM users WHERE id = X | backup_snapshots 行自动级联删除 |
| D-T9 | PRD §9.5 | guest 上传 → bind → 仍能拉 | user_id 不变（同行升级），备份延续 |
| D-T10 | PRD §9.7 | 未带 token 调 /me/backup/* | 401（AUTH_ENFORCE=true）/ permissive fallback 到 dev（false） |

---

## 6. 风险与缓解

| 风险 | 缓解 |
|------|------|
| JSONB snapshot 过大（>10MB）导致写入慢 | D.1 测大 snapshot 性能；如有问题改 D1 决策为 Object Storage |
| 用户跨设备恢复失败但客户端无提示 | D.5 客户端 debug log + restore 失败弹错（已在 backup_restore_service 中实现） |
| dev-user-001 升级 D 后老 in-memory 备份丢失 | D2 决策明示接受丢失 + commit message 提示重新上传 |
| backup_snapshots 表 PK = user_id 限制单插槽 | 与现有 last-write-wins 语义对齐；plan v2 §3.6 不要求保留多版本 |
| migration 010 与 008/009 冲突 | 010 仅新增表，无 ALTER；测试运行 down/up 验证 |
| backend `loadAsync(userId)` 加 backup SELECT 增加冷启耗时 | 单行 JSONB 查询忽略不计；如有性能问题可 lazy load |

---

## 7. 拆分上线（3 PR for Opus 4.7 1M Max）

```
PR-D-α (migration 010 + pg-persistence backup CRUD)
  ↓
PR-D-β (mobile restore 防御 + cross-device e2e)
  ↓
PR-D-γ (PRD §9 验收 + 文档收尾)
```

**为什么 3 PR：** 与 Phase C 4 PR 同理，按风险隔离（α schema 高风险 / β 业务变更中等 / γ 测试文档低风险）切分。

---

## 8. 估时

| PR | 内容 | 估时 |
|----|------|------|
| PR-D-α | migration 010 + pg-persistence backup load/save | 4-5 小时 |
| PR-D-β | mobile restore 校验 + cross-device e2e | 3-4 小时 |
| PR-D-γ | PRD §9 验收 + 文档 | 2-3 小时 |
| **合计** | | **9-12 小时**（约 1.5 个工作日） |

vs Phase A4-β 实测（估 12-17h 实际 5h）+ Phase C 实测约 10h（按 4 PR 推算），Phase D 范围更聚焦——预期落地工时 **5-8 小时**。

---

## 9. Phase D 完成后的状态

Phase D 完成可宣布「需求 23 backup 闭环达成」：
- ✅ Mobile 备份只导出当前 user 数据（PR-C-β）
- ✅ Mobile 恢复只覆盖当前 user 数据（PR-C-β）+ 注入污染数据防御（PR-D-β）
- ✅ 后端 backup_snapshots 表 + PG 持久化（PR-D-α）
- ✅ Server restart 不丢备份（PR-D-α）
- ✅ 跨设备恢复（PR-D-β e2e 覆盖）
- ✅ PRD §9.5 / §9.7 验收测试覆盖（PR-D-γ）

**距离需求 23 完整闭环还差：**
- β.5b 后端 lazy-load
- β.5c 后端 snapshot 扩 user_id（ownedItems / equipped*）
- Audit §6 e2e 残留 4 用例
- Phase E1 切流（生产 AUTH_ENFORCE=true）

这 4 项不需要独立 plan（机械改造 / 文档型 / ops 性质 checklist），可在 Phase D 完成后直接做。

---

## 10. 下一步

请用户确认：

1. **D1-D5 五个决策点**逐条 OK 或修改
2. **3 PR 拆分**是否合理
3. **估时 9-12 小时（实际 5-8 小时）**是否在预期范围
4. 是否同意先开 PR-D-α（schema + persistence，高风险但独立可 revert）

确认后按 α → β → γ 顺序实施。
