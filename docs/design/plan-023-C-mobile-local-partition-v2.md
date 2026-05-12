# Plan: 需求 23 Phase C — 移动端本地数据 user-scoped partition (v2)

**Plan Version:** v2（v1 → v2 是大重写，吸收两份外部评审 + D1-D9 拍板 + Opus 4.7 1M Max PR 重切）
**Status:** **complete**（PR-C-α/β/γ/δ 全部落地；1212/1212 mobile + 14 phase_c_e2e 通过。Phase G 收尾时确认 PRD §9 全 ✅）
**实施模型:** Opus 4.7 1M context Max
**Branch:** `feature/user-auth`
**前序:**
- Phase A1-A3: commit `5547a85`
- Phase A4-α: commit `1991be7`
- Phase A4-β: `52c1a30 / 3833c25 / 78eec7c / a4b1627`
- Phase B: `9d992c8 / 5d83936`

**Phase C commits（按 PR 顺序）：**
- PR-C-α (drift v13 schema): `6d33cbe`
- PR-C-α tidy (backend e2e + analyzer): `3ce5ec0`
- PR-C-β (DAOs + repositories + SpMigrator): `d93279d`
- PR-C-γ (epoch race guard + pending-local-guest migrator): `1584440`
- PR-C-δ (phase_c_e2e T1-T14): `4d3cb3a`

**关联:**
- [plan-023-用户系统与用户数据隔离-v2.md](plan-023-用户系统与用户数据隔离-v2.md) §1.1 / §6.3 / §6.6 / §7 / §14
- [plan-023-C-mobile-local-partition-v1.md](plan-023-C-mobile-local-partition-v1.md)（前一版，本文是其重写，v1 已标 ⚠️ Superseded）
- [audits/sp-keys-audit.md](audits/sp-keys-audit.md) v1.1（Phase G 加 v1.2 修订记录）
- [plan-023-A4-beta-v1.md](plan-023-A4-beta-v1.md)（模式参考）

**日期:** 2026-05-10（v2 起草 + 落地）→ 2026-05-11（Phase G 闭环确认）

---

## 0. v2 重写说明

v1 收到两份外部评审，核实后**所有评审项均成立，无一可拒**。v1 主要缺陷：

| 缺陷 | 严重度 | v1 处理 | v2 修复 |
|------|--------|---------|---------|
| **plan v2 §1.1 Phase C 编号 C1-C6 与 v1 子阶段编号不对齐**——v1 把 C.5 / C.6 编号挪用做 SP migration / services 改造 | 🔴 致命 | v1 写「C.5: SP namespace migration」 | v2 严格按 plan v2 §1.1 编号 C1-C6，本文 §4 重写子阶段拆分 |
| **plan v2 C5（切换账号 in-flight 取消 + epoch + cache 销毁）完全缺失** | 🔴 致命 | v1 完全没提 | v2 §4.5 完整子阶段 |
| **plan v2 C6（pending-local-guest 老数据迁移）只在风险表一句话** | 🔴 致命 | v1 §7 风险表 + §11 备注 | v2 §4.6 主线任务 |
| **Fresh install 路径 user_id 列永远建不出来** | 🔴 致命 | v1 D1 选 Option B 但没动 LocalDatabase._createTables，矛盾 | v2 D1 改决策 + §4.0 strip LocalDatabase schema 责任 |
| **ALTER TABLE ... DEFAULT '$userId' 串号风险** | 🔴 P1 | v1 §5 直接拼 SQL | v2 §5 改算法：nullable add + backfill + drop default |
| **D4 SP progress 弃用 vs C.6 改造矛盾** | 🟡 P1 | v1 §3 / §4 两边写得对立 | v2 加 D9 + 决策清晰：弃用 = 删 LocalProgressRepository |
| **DAO 改造漏所有 raw SQL 调用点** | 🟡 P2 | v1 仅列 LocalDatabase 公共方法 | v2 §4.4 扩到 stats / today / 任何直接写 SQL 的代码 |
| **markSynced 等"看似无关 user"的方法漏防御** | 🟡 P2 | v1 §4.3 写「不需要 userId」 | v2 改成「加 user_id WHERE 防止账号切换在 in-flight 落错用户」 |
| **§2.4 / D6 / C.4 / D8 内部 4 处不一致** | 🟡 一致性 | v1 plan-level 错 | v2 §3 重新对齐 |
| **D1 没解释为什么偏离 plan v2 §7.1** | 🟢 弱覆盖 | v1 引用 sp-keys-audit §5.5 但没说 plan v2 §7.1 不算了 | v2 §3 D1 加偏离段落 |
| **LocalProgressRepository 命运不清** | 🟢 弱覆盖 | v1 没决定 | v2 D9 + §4.4 详写 |
| **C.1 钩子点 main.dart 哪一行** | 🟢 弱覆盖 | v1 没说 | v2 §4.1 标行号 |
| **drift stream 未来风险** | 🟢 弱覆盖 | 无提及 | v2 §4.5 加注释 |
| **backup/restore Phase D 验收边界** | 🟢 弱覆盖 | v1 §11 一句 | v2 §1.2 + §10 明示「Phase C ≠ 需求 23 完整闭环」 |

13 项修复。本文不删 v1（保留作历史 plan iteration 记录）。

---

## 1. Phase C scope（严格按 plan v2 §1.1）

### 1.1 plan v2 §1.1 原文（第 72-78 行）

> Phase C — 移动端本地数据隔离（**最大风险点**）
> ├── C1: raw sqflite LocalDatabase 升级 v1 → v2（5 张表加 user_id）
> ├── C2: drift v12 → v13（20 张表中的用户行为表加 user_id；公共内容层不动）
> ├── C3: SharedPreferences key 改造为 user-scoped 命名空间
> ├── C4: 仓库层 / DAO / 全部查询带 currentUserId 过滤
> ├── C5: 切换账号时 in-flight 请求取消 + cache 销毁（epoch 计数器机制，见 §6.6）
> └── C6: 老数据迁移到 server_guest_user_id（同时清理本地占位 pending-local-guest）

### 1.2 本 plan 实施编号映射（与 plan v2 严格对齐）

| plan v2 子项 | 本 plan 子阶段 | 备注 |
|-------------|---------------|------|
| **C1** raw sqflite LocalDatabase | §4.0 + §4.1（合并：先 strip schema 责任，再 DAO 改造）| 策略调整见 D1 — 不升 version，让 drift 唯一管 schema |
| **C2** drift v12 → v13 | §4.2 | 含 v13 migration 算法（§5）|
| **C3** SP 命名空间 | §4.3 | 18 keys |
| **C4** DAO 仓库层 | §4.4 | 含 LocalDatabase + drift query + raw SQL 调用点（stats / today 等）|
| **C5** **epoch + 切换账号 cache 销毁** | §4.5 | v1 缺失，v2 补 |
| **C6** **pending-local-guest 迁移** | §4.6 | v1 缺失，v2 补 |
| — | §4.7 | e2e 测试（多用户隔离 + fresh install + 老数据回填）|

### 1.3 不在 Phase C 范围（明示，写在 plan 验收边界）

| 不在范围 | 归属 |
|---------|------|
| backup_export / restore per-user（snapshot 全表读 → 用户过滤） | **Phase D** |
| AUTH_ENFORCE=true 实际切流 | **Phase E1** |
| 游客绑定客户端事务不一致重试 | **Phase F** |
| β.5b 后端 lazy-load + β.5c snapshot 字段扩 user_id | 后端独立 PR |

**⚠️ 验收边界（评审 1 P1 采纳）：Phase C 完成 ≠ 需求 23 完整闭环。** 需求 23 要求"备份/恢复只属于当前 user"（PRD §3.6），Phase D 完成才算闭环。Phase C 完成后可以宣布「移动端本地数据已 user-scoped」，但 backup / restore 接口仍读全表（snapshot_export_service.dart:73-88 / backup_restore_service.dart:172）。Phase D PR 描述需附 Phase C ↔ D 接力的验收测试。

---

## 2. 现状摸底（grep 实测）

（与 v1 §2 大致一致，仅修订关键事实）

### 2.1 drift schema：v12，20 张表，0 user_id 列

20 张表确认：legacy 5 + FSRS 2 + content 4 + session 2 + enrichment 3 + morpheme 2 + audio cache 1 + content package state 1 = 20 ✓

### 2.2 raw sqflite LocalDatabase

- `version: 1`，onCreate 创 5 张表无 user_id（`local_database.dart:25-29`）
- **关键事实（评审 2 致命 1 核实）**：fresh install 启动时序为：
  1. `LocalDatabase.initialize()` 打开空 .db，触发 `_createTables`，5 张 legacy 表建好无 user_id
  2. `AppDatabase()` 接管同一 .db，drift `onCreate` 跑 `m.createAll()`
  3. drift 默认用 `CREATE TABLE IF NOT EXISTS`，5 张 legacy 表已存在 → **跳过**
  4. 结果：fresh install 后 legacy 5 张表永远没 user_id 列

**这是 v1 plan 致命缺陷源头。** v1 D1 选 Option B（不升 LocalDatabase version）但没动 `_createTables`，导致 fresh install 永远不会得到正确 schema。

### 2.3 UNIQUE 改造确认 3 张（v1 §2.4 模糊说"待确认"，v2 写死）

- `wordbook_progress.book_id` UNIQUE → UNIQUE(user_id, book_id)
- `daily_checkins.date` UNIQUE → UNIQUE(user_id, date)
- `card_states.word_id` UNIQUE → UNIQUE(user_id, word_id)（核实 `fsrs_tables.dart:18`）

### 2.4 9 张需 user_id 表 + 11 张不动表

不变。

### 2.5 SP keys：18 user-data + 3 device-level + 5 auth

不变。

### 2.6 直接写 raw SQL 的调用点（评审 1 P2 — 新发现）

grep 命中：
- `stats_service.dart:43 / 606`：直接 `_db.rawQuery('SELECT ... FROM word_records / review_logs / daily_checkins')`
- `local_today_service.dart:93`：直接 `_db.insert('daily_checkins', ...)`

→ Phase C DAO 改造**不能只动 LocalDatabase 公共方法**，必须扩到所有直接写 SQL 的代码。

### 2.7 LocalProgressRepository 双写真理（评审 1 P1）

- `LocalProgressRepository` 用 SP key `progress_word_records` 存 JSON 数组（`local_progress_repository.dart:38`）
- `LocalDatabase` 的 `word_records` SQLite 表也存同一份数据
- `snapshot_export_service.dart:73-88` 同时读 SQLite（`getAllWordRecords()`）和 SP（`progress.getWordbookProgress()` 等）
- 这是确凿的双写

### 2.8 启动顺序（main.dart 现状）

```
1. WidgetsFlutterBinding.ensureInitialized
2. SharedPreferences.getInstance
3. AuthBootstrap.run                    [Phase B]
4. ApiClient.setDefaultHttpClient       [Phase B hot-fix]
5. LocalDatabase.initialize()           ← 打开 .db + 建 legacy 5 表（无 user_id）
6. AppDatabase() (drift lazy)
7. wordbookLoader.loadIfNeeded x3       ← 首个 drift query → 触发 onUpgrade
8. EnrichmentBootstrap
9. runManifestSyncIfEnabled (fire-and-forget)
10. runApp(MeowApp)
```

**步骤 5 必须改造或后挪**（v1 plan 漏点）。

---

## 3. 决策点（D1-D9，**已拍板**，按推荐方案）

> **2026-05-10 用户拍板：D1-D9 全部按本节推荐方案执行。** 实施时不再就此回头问。

### D1 — LocalDatabase schema 责任（**重大修订 vs v1**）

**plan v2 §7.1 原方案：** LocalDatabase v1 → v2，5 张表加 user_id（v1 D1 偏离 Option B）

**v1 D1：** 不升 LocalDatabase version，让 drift 唯一管 schema。但**没动 `_createTables`** — fresh install 仍由 LocalDatabase 建无 user_id 的表。

**v2 决策：** **删除 `LocalDatabase._createTables` 中的所有 CREATE TABLE 语句**，让 drift 唯一拥有 schema 创建权。

理由：
1. sp-keys-audit §5.5 Option B 推荐"LocalDatabase 不再是 schema 维护方，只是 DAO 层"——v1 选了 Option B 但没真正实施
2. drift onCreate `m.createAll()` 在空 .db 上建所有 20 张表（含 user_id），fresh install 路径自然正确
3. **必须改启动顺序**：把 drift 首次访问移到 LocalDatabase DAO 使用之前

实施细节见 §4.0。

### D2 — Backfill userId 来源

不变：读 `auth_current_user_id`（B 启动保证已写入：真 id / `pending-local-guest` 占位 / null 仅极端情况）

### D3 — SP 迁移触发条件

不变：fresh install 不迁移；老用户用 `auth_pending_sp_migration` flag retry

### D4 — `progress_*` SP keys vs SQLite tables 双写处置（**v2 修订**）

**v1 D4：** SP `progress_*` 旧值直接弃用（删老键）

**v2 修订：** 删 SP `progress_*` 老键 **+ 整个 `LocalProgressRepository` 类弃用**（不仅删数据，也删消费者）。配套：snapshot_export_service 改为只读 SQLite。

理由：双写问题不只是数据冗余，是代码层面 LocalProgressRepository 这个类的存在让"哪边是 truth"模糊。删类 + 单 truth 比保留+决策更干净。详见 D9。

### D5 — drift 失败回滚

不变。

### D6 — card_states UNIQUE (**v2 写死，v1 模糊**)

明确加 UNIQUE(user_id, word_id)。与 wordbook_progress / daily_checkins 并列为 **必须 rebuild 的 3 张表**。

### D7 — partial migration crash 恢复

不变：PRAGMA + flag 双重判断

### D8 — sqflite vs drift 同步（**v2 修订**）

**v1 D8：** "raw sqflite DAO 内部 SQL 全改为带 user_id 谓词（**不动 schema**）"——矛盾于 D1 下 LocalDatabase 自己在 onCreate 建表

**v2 修订：** raw sqflite DAO 走 drift 同一 schema（D1 strip 后唯一 owner），DAO 内部用 `_db.rawQuery('... WHERE user_id = ?', [userId])` 风格的 raw SQL，**不动 schema 责任由 D1 保证**。

### D9 — `LocalProgressRepository` 命运（**v2 新增，评审采纳**）

**决策：弃用整个类。**

理由：
1. 双写 SQLite `word_records` ↔ SP `progress_word_records` 增加心智负担
2. `snapshot_export_service` 已经 dual-source（既读 SQLite 又读 SP）—— Phase D 改造时合并为单源更清晰
3. `LocalProgressRepository` 的 SP 持久化逻辑已经被 SQLite 覆盖，没有独立价值

**实施：**
- C.3 SP 迁移时 `progress_*` 5 个键的「迁移」实际是「删除」（不迁移到 `u_<userId>_progress_*`）
- C.4 移除 LocalProgressRepository 类
- snapshot_export_service 改为只读 SQLite（D4 同 issue，§4.4 详写）
- 测试矩阵 T3 改为「迁移后 SP `progress_*` 老键被删除，新键不存在，数据全在 SQLite」

---

## 4. 实施拆分（v2 — 严格对齐 plan v2 §1.1 C1-C6 + 启动/测试）

### 4.0 — 启动改造（D1 配套 / 新增子阶段，PR-C0）

**目的：** 让 drift 成为 schema 唯一 owner，main.dart 顺序调整。

**改动：**

1. `local_database.dart`：删 `_createTables` 中所有 `CREATE TABLE` 语句（保留方法签名作为 no-op，加注释「schema 由 drift onCreate 维护」）
2. `main.dart`：在 LocalDatabase 任何 DAO 调用之前**强制触发 drift 初始化**——可通过在 `LocalDatabase.initialize()` 后立即 `await appDb.customSelect('SELECT 1').get()` 或类似空查询激活 drift onCreate
3. C.1 子阶段 (`markFreshInstallIfNeeded`) 在步骤 5 LocalDatabase.initialize 之前调用
4. 启动期 assert：drift open 后 5 张 legacy 表必有 user_id 列（fail-fast）

**main.dart 修订后顺序：**

```
1-4. 同上
5. AuthStorage.markFreshInstallIfNeeded()              [新增, C.1]
6. LocalDatabase.initialize()                          [_createTables 现在 no-op]
7. AppDatabase() + 强制 drift 初始化（appDb.customSelect('SELECT 1').get()）
   ↓ 这一步触发 drift onCreate（fresh install）或 onUpgrade（升级）
8. 启动期 PRAGMA assert: word_records.user_id 列存在
9. wordbookLoader.loadIfNeeded x3
10. EnrichmentBootstrap
11. runManifestSyncIfEnabled
12. runApp(MeowApp)
```

**测试：**
- fresh install 后 5 张 legacy 表都有 user_id 列
- legacy upgrade（v12 → v13）后 5 张 legacy 表新增 user_id 列
- legacy 表 INSERT 不带 user_id 报错（D5 fail-fast）

**工作量：** 0.5 小时

### 4.1 — plan v2 C1：LocalDatabase DAO 接 userId（PR-C1）

**目的：** 5 张 legacy 表的 raw sqflite DAO 全部接 userId 参数。

**改造范围（评审 1 P2 — 扩到所有 raw SQL）：**

| 来源 | 方法/行号 | 改造 |
|------|-----------|------|
| LocalDatabase | insertWordRecord / getMasteredWordIds / getUnsyncedRecords / distinctWordIdsRatedToday / upsertWordbookProgress / 等 ~17 个公共方法 | 加 userId 参数 + WHERE user_id |
| LocalDatabase | markSynced(id) | 加 userId：WHERE id=? **AND user_id=?**（评审 1 P2 采纳：防 in-flight 切换账号写错行） |
| StatsService | `stats_service.dart:43 / 606` 直接 `_db.rawQuery` | 加 userId 参数 + WHERE |
| LocalTodayService | `local_today_service.dart:93` 直接 `_db.insert('daily_checkins')` | 加 userId 字段 |
| 其他 grep `_db.rawQuery` / `_db.insert` / `_db.update` / `_db.delete` 命中点 | 全部审计 | 同上 |

**测试：**
- A 写 word_record，B getMasteredWordIds 返回空
- 同 word_id 在 A / B 各自独立 word_records.id 行（验证 UNIQUE(user_id, word_id) 防撞）
- 账号切换中 markSynced 写错用户不被允许（用 user_id 不匹配的 id 调用 → 0 rows affected）

**工作量：** 2-3 小时（含 raw SQL grep 全扫）

### 4.2 — plan v2 C2：drift v12 → v13（PR-C2，最大风险）

**目的：** 9 张 user-scoped 表加 user_id 列 + 3 张 UNIQUE 改造 + 老数据 backfill。

drift table classes 改 + onUpgrade `if (from < 13)` 块。详细算法见 §5。

**改动文件：**
- 9 张 drift table class 加 `TextColumn get userId => text().named('user_id')()`
- 3 张 UNIQUE 改造：`wordbook_progress` / `daily_checkins` / `card_states` 用 drift `@TableIndex` 复合 unique，或在 onUpgrade 中 rebuild
- `app_database.dart`：schemaVersion 13；onUpgrade 加 v13 块
- migration_test.dart：drift `verifyMigration` + 多版本起点（fresh / v1→v13 / v8→v13 / v12→v13）

**测试：** 见 §5 算法 + §6 测试矩阵

**工作量：** 4-5 小时

### 4.3 — plan v2 C3：SP key 命名空间迁移 + service 改造（PR-C3）

**目的：** 18 user-data SP keys 迁移到 `u_<userId>_*` 命名空间 + 5 个 service 类按 userId 实例化。

**子项：**

**4.3.1 SP 迁移逻辑（启动时跑一次，幂等）**

```dart
// pseudo
final keyMap = {
  'settings_daily_goal': 'u_${userId}_settings_daily_goal',
  // ... 7 settings_* keys
  'backup_latest_status': 'u_${userId}_backup_latest_status',
  // ... 4 backup_* keys
  'auto_backup_last_at_ms': 'u_${userId}_auto_backup_last_at_ms',
  'room_canvas_layout_v1': 'u_${userId}_room_canvas_layout_v1',
};

// D9: progress_* 5 个 keys 是 DELETE-only（弃用）
final deleteOnly = [
  'progress_word_records',
  'progress_wordbook_progress',
  'progress_daily_checkins',
  'progress_custom_wordbooks',
  'progress_vocabulary_notebook',
];
```

**4.3.2 5 个 service 改造**

| 类 | 改造 |
|----|------|
| `LocalSettingsService` (7 keys) | 构造加 userId 参数，内部 key 前缀化 |
| `BackupUploadService` (4 keys) | 构造加 userId |
| `AutoBackupService` (1 key) | 静态方法加 userId 参数 |
| `RoomCanvasStorage` (1 key) | 构造加 userId |
| **`LocalProgressRepository`** | **整类删除（D9 决策）**，所有消费者改读 SQLite |

调用点：`AuthScope.read(context).currentUserId` 拿 userId 传入。

**测试：**
- 老 prefs 含 `settings_daily_goal` + `progress_word_records` → 迁移后：settings_daily_goal 老键删除、`u_<uid>_settings_daily_goal` 新键存在；progress_word_records 老键删除 + 没有 u_<uid>_progress_* 新键创建
- A / B 各自 `LocalSettingsService` 互不串

**工作量：** 2-3 小时

### 4.4 — plan v2 C4：drift DAO 调用点接 userId（PR-C4）

**目的：** drift 直接 query 调用点（select(table).where(...) / 复杂 join 等）全部加 userId 过滤。

**改造策略（评审 2 不一致 3 采纳：选 service 集中）：**

drift query 散布在 lib/ 各处。**不**让调用点手动加 `.where((t) => t.userId.equals(userId))` —— 这种散布式改动遗漏风险高。

改为：每张 user-scoped drift 表对应一个 service 类（如 `CardStateRepository` / `SessionRepository` / `ReviewLogRepository`），service 构造接 userId，所有 drift query 封装在 service 内。调用点只用 service 方法。

**改造文件：**
- 新增 `lib/core/storage/repositories/`：每张 user-scoped drift 表一个 repository
- 全 grep `select(wordRecords / cardStates / reviewLogs / sessions / reviewRecords)` 调用点（估 30-40 处），改为 repository 调用

**测试：**
- A 在 card_states 写一条，B 通过 repository 查 → 返回空
- repository 单测：未传 userId 构造时抛错

**工作量：** 3-4 小时

### 4.5 — plan v2 C5：epoch + 切换账号 cache 销毁（PR-C5，**v1 缺失**）

**目的：** 切换账号时清掉 in-flight 请求、销毁旧 service 实例、跳路由。

**改动：**

1. **ApiClient 接 AuthController.epoch：**
   ```dart
   class ApiClient {
     final AuthController? _auth;
     ApiClient({..., AuthController? auth}) : _auth = auth;
     
     Future<T> _sendWithEpochCheck<T>(Future<T> Function() send) async {
       final issueEpoch = _auth?.epoch;
       final result = await send();
       if (issueEpoch != null && _auth?.epoch != issueEpoch) {
         throw RequestStaleException('user switched mid-flight');
       }
       return result;
     }
   }
   ```
   - 或：AuthHttpClient 在 send() 入口捕获 epoch，response 回来时校验

2. **AuthHttpClient 接 epoch（更优雅）：**
   ```dart
   @override
   Future<http.StreamedResponse> send(http.BaseRequest request) async {
     final issueEpoch = _controller.epoch;
     final response = await _inner.send(request);
     if (_controller.epoch != issueEpoch) {
       throw RequestStaleException();
     }
     // ... existing 401 handling
     return response;
   }
   ```

3. **AuthController 切换账号时取消 in-flight：**
   ```dart
   Future<void> logout() async {
     // 1. epoch++ (already in B)
     // 2. 关闭当前 AuthHttpClient（取消 in-flight）
     await _currentAuthClient?.close();
     // 3. AuthBootstrap 创建新 AuthHttpClient + ApiClient.setDefaultHttpClient
   }
   ```

4. **per-page lifecycle 销毁：**
   - 主要 page 在 `didChangeDependencies` 检查 `AuthScope.of(context).epoch` 变化
   - 变化时 `setState(() {})` 重置本地 state（重新走 _loadData）

5. **Navigator 跳转（绑定 + logout 后）：**
   - 绑定成功 / 切换账号后调用 `Navigator.pushAndRemoveUntil` 回根路由
   - 强制重建 widget 树

**关于 drift stream subscription（评审 2 弱覆盖 4）：**
- grep 实测 `.watch()` / `Stream<` 在 lib/ **0 处**——drift 流监听暂未启用
- 加注释「未来若引入须重审切换账号销毁逻辑」防回归

**测试：**
- A 发起 /me/today 请求，请求飞行中切换到 B → response 回来抛 RequestStaleException
- logout 后 setState 在旧 page 不生效（widget 已销毁或 epoch mismatch 守护）

**工作量：** 3-4 小时

### 4.6 — plan v2 C6：pending-local-guest 老数据迁移（PR-C6，**v1 缺失**）

**目的：** 离线首次启动写入 `pending-local-guest` 的数据，在拿到真 user_id 后迁移过去。

**改动：**

1. `AuthController._commitSession` 末尾加：
   ```dart
   final newUserId = res.user.id;
   final oldUserId = storage.readUserId();  // 提交前还存在的 user_id
   if (oldUserId == AuthStorage.pendingLocalGuestUserId &&
       newUserId != AuthStorage.pendingLocalGuestUserId) {
     await _migrateLocalGuestData(from: oldUserId, to: newUserId);
   }
   ```

2. `_migrateLocalGuestData` 跨层迁移：
   ```dart
   Future<void> _migrateLocalGuestData({
     required String from,
     required String to,
   }) async {
     // 1. drift 9 张表：UPDATE WHERE user_id = $from SET user_id = $to
     // 2. raw sqflite 5 张表：UPDATE WHERE user_id = $from SET user_id = $to
     //    (注：raw sqflite 5 张 == drift legacy 5 张 == 同一物理表，
     //     执行一次即可。具体走 drift API)
     // 3. SP namespace：将 u_<from>_* 全部 rename 为 u_<to>_*
     await driftDb.transaction(() async {
       for (final table in userScopedTables) {
         await driftDb.customStatement(
           'UPDATE $table SET user_id = ? WHERE user_id = ?',
           [to, from],
         );
       }
     });
     await _renameSpNamespace(from: from, to: to);
   }
   ```

3. SP namespace rename 算法（同 §4.3 但是 user→user）。

**关键：幂等。** 多次执行无副作用（第二次跑 UPDATE 影响 0 行）。

**测试：**
- 离线启动 → 写一条 word_record（user_id=`pending-local-guest`） → 联网 → /auth/guest 成功 → drift word_records 行 user_id 改为 server_guest_id
- 多次执行迁移不重复
- SP `u_pending-local-guest_settings_daily_goal` 改为 `u_<server_guest_id>_settings_daily_goal`

**工作量：** 2-3 小时

### 4.7 — Phase C 测试矩阵（PR-C7）

详见 §6。

---

## 5. drift v13 onUpgrade 算法（v2 修订，移除 DEFAULT 串号风险）

评审 1 P1 指出 v1 算法直接拼 `DEFAULT '$userId'` 是字符串注入风险 + DEFAULT 保留 = 漏传 userId 静默写错用户。

**v2 算法（参数化 + 三步走，无残留 DEFAULT）：**

```dart
if (from < 13) {
  // Step 1: read userId for backfill
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('auth_current_user_id')
      ?? 'pending-local-guest';

  // Step 2: per-table migration
  const tables = [
    ('word_records', false, null),
    ('wordbook_progress', true, ['user_id', 'book_id']),
    ('daily_checkins', true, ['user_id', 'date']),
    ('custom_wordbooks', false, null),
    ('vocabulary_notebook', false, null),
    ('card_states', true, ['user_id', 'word_id']),
    ('review_logs', false, null),
    ('sessions', false, null),
    ('review_records', false, null),
  ];

  for (final (name, uniqueChange, uniqueCols) in tables) {
    if (await _hasUserIdColumn(name)) continue;  // fresh install ok
    if (!await _tableExists(name)) continue;     // partial state ok

    if (uniqueChange) {
      // Path A: rebuild (SQLite restriction on UNIQUE)
      await _rebuildTableWithUserId(name, userId, uniqueCols!);
    } else {
      // Path B: three-step (no DEFAULT residue)
      await _addUserIdColumnSafe(name, userId);
    }
  }
}

Future<void> _addUserIdColumnSafe(String tableName, String userId) async {
  // Step 1: add as NULLABLE (no DEFAULT)
  await customStatement(
    'ALTER TABLE $tableName ADD COLUMN user_id TEXT');
  
  // Step 2: backfill via parameterized query (NO string concat)
  await customStatement(
    'UPDATE $tableName SET user_id = ? WHERE user_id IS NULL',
    [userId],
  );
  
  // Step 3: SQLite cannot ALTER ... SET NOT NULL post-hoc.
  // Compromise: drift schema definition has NOT NULL constraint,
  // so future drift-managed inserts can't omit it. raw sqflite
  // INSERT bypasses this — we rely on DAO discipline + unit test.
  // (评审 1 P1 完全消除 DEFAULT 串号风险)
}

Future<void> _rebuildTableWithUserId(
    String tableName, String userId, List<String> uniqueCols) async {
  // 1. Rename old
  await customStatement('ALTER TABLE $tableName RENAME TO ${tableName}__old');

  // 2. Create new (drift schema = v13 = has user_id, NOT NULL, UNIQUE)
  //    Use drift's table definition emitter, not hand-rolled SQL
  await m.createTable(_driftTableFor(tableName));

  // 3. Copy with userId backfill — parameterized
  final cols = await _readColumnsOf('${tableName}__old');
  final colList = cols.join(', ');
  await customStatement(
    'INSERT INTO $tableName ($colList, user_id) '
    'SELECT $colList, ? FROM ${tableName}__old',
    [userId],
  );

  // 4. Drop old
  await customStatement('DROP TABLE ${tableName}__old');

  // 5. Recreate indexes (drift @TableIndex doesn't re-emit on rebuild)
  await _recreateIndexesFor(tableName);
}
```

**关键修订（vs v1 §5）：**
- ❌ v1 用 `DEFAULT '$userId'` — DEFAULT 残留 + 字符串拼接
- ✅ v2 ALTER ADD COLUMN（nullable）+ 参数化 UPDATE backfill — 无 DEFAULT 残留 + SQL injection 安全
- ✅ NOT NULL 约束在 drift schema 定义层保证（drift code-gen 出来的 insert 强制要 user_id），raw sqflite INSERT 靠 DAO 测试覆盖

---

## 6. 测试矩阵（v2 扩充）

| # | 类别 | 用例 | 验收 |
|---|------|------|------|
| T1 | 基线 | fresh install + guest 学一词 | word_records 1 行带 guest userId |
| T2 | drift v13 backfill | 模拟 v12 状态有数据 → 启动 | 老 word_records 全部归 `auth_current_user_id` |
| T3 | SP 迁移 | 老 prefs 含 settings_daily_goal + progress_word_records | settings_* 迁移、progress_* 删除（D9）|
| T4 | UNIQUE 跨用户 | 同 book_id 两 user | A / B 各有 wordbook_progress 行不撞 |
| T5 | DAO 隔离 | LocalDatabase.getMasteredWordIds 跨用户 | A 已 know 不出现在 B |
| T6 | service 隔离 | RoomCanvasStorage / LocalSettings A/B | A 改不影响 B |
| T7 | logout 数据保留 | 退出登录后 drift 表 user_id 仍是原值 | 不被 wipe |
| T8 | 绑定同行升级 | 绑定后 userId 不变 | 数据无需迁移 |
| T9 | drift migration 失败 | 模拟中途失败 | schema_version 仍 12，启动期 PRAGMA assert 触发降级 |
| **T10** | **fresh install 路径** | fresh prefs + fresh .db → 启动 → 学一词 | word_records 表必有 user_id 列（防 v1 致命 1 回归） |
| **T11** | **C5 epoch in-flight** | A 发请求 → 切到 B → response 回 | RequestStaleException 抛出 |
| **T12** | **C6 pending-local-guest 迁移** | 离线写数据 → 联网拿真 id | UPDATE WHERE user_id='pending-local-guest' 跑成功 |
| **T13** | **C6 SP namespace rename** | 同上场景的 SP | u_pending-local-guest_* → u_<real>_* |
| T14 | DEFAULT 串号防御 | drift v13 migration 后 INSERT 漏 user_id | drift code-gen 拒绝（编译期）；raw sqflite 拒绝（DAO assertion） |

T10-T13 是 v2 新增（v1 缺失致命 1+2+3 对应）。

---

## 7. 风险与缓解（v2 修订）

| 风险 | 缓解 |
|------|------|
| Fresh install schema 漏 user_id（v1 致命 1）| D1 v2：strip LocalDatabase._createTables，drift 唯一管 + 启动期 PRAGMA assert（§4.0）|
| ALTER TABLE DEFAULT 残留串号（v1 P1）| §5 算法改 nullable add + 参数化 backfill |
| LocalProgressRepository 双写残留（v1 P1）| D9 弃用整类 + snapshot 改单源 SQLite |
| Phase C 完成 ≠ 需求 23 闭环（v1 P1）| §1.3 明示 + Phase D 验收必备 |
| 切换账号 in-flight 串数据（v1 致命 2）| §4.5 epoch 接 ApiClient + cancel client |
| pending-local-guest 孤立（v1 致命 3）| §4.6 _migrateLocalGuestData 主线任务 |
| drift / sqflite 不同步 | D1 strip LocalDatabase schema 后 drift 唯一 owner |
| markSynced 切换账号串数据（评审 1 P2）| 加 WHERE user_id 防御 |
| stats / today 直接写 raw SQL 漏改（评审 1 P2）| §4.1 + §4.4 全 grep raw SQL 扫 |
| drift stream 未来引入风险（评审 2 弱覆盖）| §4.5 加注释 |

---

## 8. 拆分上线（v2 — 按 Opus 4.7 1M Max 能力重切，4 个 PR）

### 8.1 模型能力 → PR 切分原则

实施模型是 **Opus 4.7 1M context Max**。1M context 改变了 PR 切分的约束：

- ❌ **不再为「人类 reviewer 疲劳」切碎 PR** — Opus 单次可读懂整个 mobile/lib + 完整 dev-store + 全部 migration 逻辑
- ❌ **不再为「context 装不下」切碎 PR** — 一次性 grep 30-40 处 raw SQL 调用点 + 编辑全部，可在单 PR 完成
- ✅ **仍按「逻辑原子性」切** — 每个 PR 独立可上线 / 可回滚
- ✅ **仍按「风险等级」切** — 高风险（schema migration）单独 PR，便于快速 revert
- ✅ **仍按「依赖链」切** — schema 改动必须先于 DAO 改造

按这套原则，v1/v2 的 7 个 PR 重切为 **4 个 PR**：

### 8.2 PR 拆分（v2 — 4 PR）

| PR | 内容 | 风险 | 工时 | 依赖 |
|----|------|------|------|------|
| **PR-C-α** | §4.0 启动改造 + §4.2 drift v13 migration + migration_test | **高（schema）** | ~5h | 独立 |
| **PR-C-β** | §4.1 LocalDatabase DAO + §4.3 SP migration + service 改造 + LocalProgressRepository 删除 + §4.4 drift query 集中到 repository | 中（大量机械改造） | ~9h | 依赖 α |
| **PR-C-γ** | §4.5 epoch + 切换账号 + §4.6 pending-local-guest migration | 中（跨系统逻辑） | ~5h | 依赖 α；与 β 并行 OK |
| **PR-C-δ** | §4.7 e2e 测试矩阵 T1-T14 + 回归修 | 低 | ~4h | 依赖 α+β+γ |

### 8.3 各 PR 详细范围

#### PR-C-α — Schema foundation（最高风险，单独 PR 便于快速 revert）

- 删除 `LocalDatabase._createTables` 内的 CREATE TABLE 语句（保留方法 no-op）
- 调整 main.dart 启动顺序：`AuthBootstrap → markFreshInstallIfNeeded → LocalDatabase.initialize → AppDatabase + 强制 drift 初始化 → PRAGMA assert`
- drift schema v12 → v13：9 张 user-scoped 表加 `user_id` 列 + 3 张 UNIQUE 改造（wordbook_progress / daily_checkins / card_states）
- onUpgrade 算法（§5 v2，nullable add + 参数化 backfill）
- migration_test.dart 覆盖：
  - fresh install → 20 张表（5 legacy 含 user_id）
  - v12 → v13 含数据 backfill
  - v8 → v13（多步链）
  - v1 → v13（最远路径，sqflite 时代起点）
- 启动期 PRAGMA assert（`word_records.user_id` 必存在，否则 fail-fast）

**为什么单独：** schema 改动是最不可逆的工作。一旦 v13 落地、用户启动过、word_records 加了 user_id 列，回滚必须配套 drift downgrade（drift 不原生支持）+ 数据 rollback。单独 PR 让 revert 影响面最小。

#### PR-C-β — DAO + Service + SP 全量机械改造（最大体量，Opus 强项）

利用 Opus 1M context 一次性扫完所有调用点：

- **LocalDatabase 公共方法 + 所有 `_db.rawQuery` / `_db.insert` / `_db.update` 调用点**（grep 估 17 + 散落 ~10 处）全加 userId 参数 + WHERE 谓词
  - 含 stats_service.dart:43/606
  - 含 local_today_service.dart:93
  - 含 markSynced(id) 加 `WHERE id=? AND user_id=?` 防御
- **drift query 调用点重构为 repository 封装**（§4.4）：
  - 新建 `lib/core/storage/repositories/`
  - 每张 user-scoped drift 表对应一个 repository（CardStateRepository / SessionRepository / ReviewLogRepository / ReviewRecordRepository）
  - service / feature 代码中 `select(cardStates)...` 等调用全改为 repository 方法
- **SP namespace 迁移**：18 keys 改 `u_<userId>_*`
  - 7 settings_* + 4 backup_* + 1 auto_backup + 1 room_canvas → 真迁移
  - 5 progress_* → **删除**（D9 弃用 LocalProgressRepository）
- **5 个 service 改造**：
  - LocalSettingsService / BackupUploadService / AutoBackupService / RoomCanvasStorage 加 userId
  - **LocalProgressRepository 整类删除**（D9），snapshot_export_service 改单源 SQLite
- 配套单元测试：每个 service 测 userA / userB 互不串

**为什么合并：** 这些改动全是机械化"扫调用点 + 改签名 + 加 userId 参数"。Opus 1M context 可一次性持有完整 mobile/lib 做全局 grep + 改写，比拆 3 个 PR 反复加载 context 高效。逻辑上也强相关（service / SP / DAO 都是同一抽象层的 user-scoped 改造）。

#### PR-C-γ — Cross-cutting：epoch + pending-local-guest（C5 + C6 合并）

- `AuthHttpClient.send()` 入口捕获 `_controller.epoch`，response 回来时校验，不匹配抛 `RequestStaleException`
- `AuthController.logout()` 调用 `_currentAuthClient?.close()` 取消 in-flight
- `AuthController._commitSession` 末尾检测 `oldUserId == 'pending-local-guest' && newUserId != 'pending-local-guest'`，调 `_migrateLocalGuestData`
- `_migrateLocalGuestData` 跨表 UPDATE：
  - 9 张 drift / sqflite 表 `UPDATE WHERE user_id = 'pending-local-guest' SET user_id = $new`
  - SP namespace rename `u_pending-local-guest_*` → `u_<server_id>_*`
- Phase B 留下的 `_epoch` 字段从"死代码"升级为"活代码"（B hot-fix commit message 已预告 Phase F 使用，C 提前接入）
- 单元测试：epoch race + cross-table migration idempotency

**为什么合并 C5 + C6：** 两者都触碰 `AuthController._commitSession` / `logout` 生命周期 + 跨系统状态切换。代码物理位置相同，Opus 一次改完更连贯。各自独立验证仍可通过单元测试隔离。

#### PR-C-δ — E2E test matrix + final integration

T1-T14 全部 e2e 用例 + 手动 smoke 验证清单 + 任何前面 3 个 PR 暴露的回归修复。

**为什么单独：** e2e 测试是"前面 3 个 PR 都接通"后才有意义的最终验证。单独 PR 让测试 churn 不影响业务 commit 历史的清晰度。

### 8.4 合并顺序

```
PR-C-α (schema)
  ↓ 必须先
PR-C-β (DAO + service)  ∥  PR-C-γ (epoch + migration)
  ↓ β 和 γ 互不依赖，可并行开发，建议先合 β（依赖更广）
PR-C-δ (e2e + regressions)
```

**β 和 γ 同时开发的可行性：**
- β 改的是 service 层 + DAO 层 + SP 层
- γ 改的是 AuthController + AuthHttpClient + 跨表迁移逻辑
- 两者只在 `_migrateLocalGuestData` 调用 repository（β 创建的）时有依赖 — γ PR 内 stub repository 接口即可独立测试，合并时再连接

### 8.5 vs v1 plan 7-PR 拆分的对比

| 维度 | v1（7 PR） | v2（4 PR for Opus 4.7） |
|------|-----------|------------------------|
| PR 数 | 7 | 4 |
| 单 PR 平均工时 | ~3h | ~6h |
| 单 PR 最大工时 | ~4h (C2) | ~9h (C-β) |
| 风险隔离 | 7 个隔离点 | 4 个隔离点（schema 仍单独）|
| 模型 context 重载次数 | 7 次 | 4 次 |
| Phase C 总工时 | ~21-23h（同 v2 估时） | ~23h（合并后无 overhead 节省）|
| 适合模型 | 人类 / 中等 context | **Opus 4.7 1M Max** |

---

## 9. 估时（v2 修订，按 4 PR 重切）

按 PR 维度（实施单元，与 §4 子阶段映射）：

| PR | 子阶段 | 估时（保守） | 实际预期 |
|----|--------|------------|---------|
| **PR-C-α** | §4.0 启动改造 + §4.2 drift v13 + migration_test | 6-7 小时 | **5 小时** |
| **PR-C-β** | §4.1 + §4.3 + §4.4（DAO + SP migration + service + repository） | 12-14 小时 | **9 小时** |
| **PR-C-γ** | §4.5 + §4.6（epoch + pending-local-guest）| 7-8 小时 | **5 小时** |
| **PR-C-δ** | §4.7 测试矩阵 T1-T14 + 回归修 | 5 小时 | **4 小时** |
| **合计** | | **30-34 小时** | **23 小时** （约 3 个工作日）|

按子阶段维度（与 plan v2 §1.1 C1-C6 对齐，参考）：

| 子项 | 估时 |
|------|------|
| C.0 启动改造（v2 新增）| 0.5 |
| C.1 LocalDatabase DAO + raw SQL 扩散点 | 2 |
| C.2 drift v13 + UNIQUE rebuild | 5 |
| C.3 SP migration + service 改造 | 2 |
| C.4 drift query → repository 集中 | 3-4 |
| C.5 epoch + 切换账号 | 3-4 |
| C.6 pending-local-guest migration | 2-3 |
| C.7 测试矩阵 | 4 |
| **合计** | **~23h** |

合并 4 PR 后总工时与 7 PR 基本持平（合并节省的 context 加载 overhead 与单 PR 复杂度增加大致抵消）。

vs Phase A4-β 实测（估 12-17h，实际 5h），Phase C 预期实际可能在 **15-18 小时**（约 2 个工作日）落地——因为 Opus 1M context 让大量机械改造在单 context 内完成，减少多次 grep + 加载 overhead。

---

## 10. 验收（v2 明示 Phase C ≠ 需求 23 闭环）

PR-C7 全过后可以宣布**「Phase C 完成」**，但**需求 23 闭环必须 Phase D backup/restore per-user 改造完成才能算**。

Phase C 完成的可宣告：
- ✅ 移动端本地数据按 userId 分桶
- ✅ 切换账号不串 in-flight 数据
- ✅ 离线占位 `pending-local-guest` 数据可正确归到真 user_id
- ✅ SP namespace per-user
- ❌ 备份/恢复仍读全表（Phase D）

Phase E1 切流（`AUTH_ENFORCE=true`）的**最低前置**：
- A 后端能力层（已完成）
- B 移动端身份层（已完成）
- C 移动端 partition（本计划）
- Phase D 备份/恢复 per-user（之后）
- β.5b 后端 lazy-load
- β.5c 后端 snapshot 字段扩

---

## 11. 不在 Phase C 范围（v2 不变）

同 v1 §11 + §1.3 强化的 Phase D / E1 / F 边界。

---

## 12. 评审采纳记录

### Review 1 全部采纳（8 项）

| # | 评审项 | 严重度 | 采纳位置 |
|---|--------|--------|---------|
| 1 | C5 epoch + 切换账号 cache scope 缺失 | P1 | §4.5（v1 缺失，v2 补） |
| 2 | pending-local-guest 回填没列主线 | P1 | §4.6（v1 缺失，v2 补） |
| 3 | ALTER TABLE DEFAULT 串号风险 | P1 | §5（v2 改 nullable add + 参数化 backfill） |
| 4 | SP progress 策略矛盾 | P1 | D4 + D9（v2 改成弃用整类） |
| 5 | Phase D backup 验收边界 | P1 | §1.3 + §10（v2 明示 Phase C ≠ 闭环） |
| 6 | fresh install schema ownership | P2 | D1 + §4.0（v2 strip LocalDatabase._createTables） |
| 7 | DAO 改造漏 stats / today 直接 SQL | P2 | §4.1（v2 扩到 raw SQL 全 grep） |
| 8 | markSynced 也应加 user_id WHERE | P2 | §4.1（v2 加防御） |

### Review 2 全部采纳（10 项）

| # | 评审项 | 严重度 | 采纳位置 |
|---|--------|--------|---------|
| 1 | Fresh install 路径致命 1 | 🔴 | D1 + §4.0（同 review 1 #6 同源） |
| 2 | plan v2 C5 完全缺失 | 🔴 | §4.5（同 review 1 #1） |
| 3 | pending-local-guest 不在主线 | 🔴 | §4.6（同 review 1 #2） |
| 4 | D1 与 LocalDatabase 现实不符 | 🟡 | D1 v2 修订 |
| 5 | D6 与 §2.4 措辞冲突 | 🟡 | §2.3 + D6 v2 写死 |
| 6 | C.4 选项 A vs service 集中冲突 | 🟡 | §4.4 v2 选 service 集中 |
| 7 | D8 自相矛盾 | 🟡 | D8 v2 修订 |
| 8 | D1 没解释偏离 plan v2 §7.1 | 🟢 | §0 + D1 v2 加偏离段 |
| 9 | LocalProgressRepository 命运不清 | 🟢 | D9 新增决策点 |
| 10 | markFreshInstallIfNeeded 钩子点 + drift stream 未来风险 | 🟢 | §4.0 + §4.5 标注 |

### 拒绝

**0 项。** 所有评审项均成立无可拒。这表明 v1 plan 写得不足，v2 全面修复后才进入实施。

---

## 13. 下一步（拍板状态）

**2026-05-10 用户拍板：**
- ✅ D1-D9 全部按 §3 推荐方案
- ✅ 4 PR 拆分（按 Opus 4.7 1M Max 能力重切，§8）
- ✅ 估时 ~23h（约 3 个工作日）
- ✅ 实施顺序：α → (β ∥ γ) → δ

下一步直接进入 **PR-C-α 实施**（schema foundation + drift v13 migration）：

1. 删除 `LocalDatabase._createTables` 内 CREATE TABLE
2. 改造 main.dart 启动顺序 + PRAGMA assert
3. drift schema v12→v13（9 张表 + 3 张 UNIQUE 改造）
4. migration_test 覆盖 fresh / v1→v13 / v8→v13 / v12→v13 四种起点

PR-C-α 完成后跑全套 `flutter test`（baseline 1218 + migration_test 新增），无回归 + 新测试 pass 则合并，进入 (PR-C-β ∥ PR-C-γ) 阶段。
