# Plan: 需求 23 Phase C — 移动端本地数据 user-scoped partition

> ⚠️ **Superseded by [`plan-023-C-mobile-local-partition-v2.md`](./plan-023-C-mobile-local-partition-v2.md)** — historical iteration only. v1 用户确认前收到两份评审，所有项成立，整体被 v2 重写。Phase C 实施记录走 v2；本文档保留为历史 trace。
>
> 不要按本文档实施。

---

**Plan Version:** v1
**Status:** draft → superseded
**Branch:** `feature/user-auth`（与 A/B 同分支）
**前序:**
- Phase A1-A3: commit `5547a85`（后端 auth 地基）
- Phase A4-α: commit `1991be7`（userId plumb）
- Phase A4-β: commits `52c1a30 / 3833c25 / 78eec7c / a4b1627`（dev-store partition + pg-persistence userId + audit §6）
- Phase B: commits `9d992c8 / 5d83936`（移动端身份层 + hot-fixes）

**关联文档:**
- [plan-023-用户系统与用户数据隔离-v2.md](plan-023-用户系统与用户数据隔离-v2.md) §7 / §9
- [audits/sp-keys-audit.md](audits/sp-keys-audit.md) v1.1 §3 / §5 / §7
- [plan-023-A4-beta-v1.md](plan-023-A4-beta-v1.md)（模式参考）

**日期:** 2026-05-10

---

## 0. Context

Phase A 后端能力层 + Phase B 移动端身份层都已落地。`AuthController` 已经能给所有 ApiClient 注入 Bearer token（Phase B hot-fix `ApiClient.setDefaultHttpClient`），用户身份从 `currentUserId` getter 暴露出来。**但移动端本地存储仍 100% 单用户语义**：

```
sqlite (meow_progress.db)
├── 5 legacy tables (raw sqflite LocalDatabase API + drift API 共享)
│   word_records, wordbook_progress, daily_checkins, custom_wordbooks, vocabulary_notebook
│   → 0 user_id columns（核实 by grep）
├── 4 drift-only user behavior tables
│   card_states, review_logs, sessions, review_records
│   → 0 user_id columns
└── 11 public content / cache tables
    preset_wordbooks, word_entries, word_book_assignments, example_sentences,
    word_forms, word_relations, word_phrases,
    morpheme_entries, word_morpheme_matches,
    audio_file_cache, content_package_states
    → 不需 user_id（PRD §5.2 公共内容层）

SharedPreferences:
├── 18 user-data keys → 仍是全局 key（A / B 共用一份）
├── 3 device-level keys → 不动（按用户隔离需求）
└── 4 auth keys → Phase B 已建立（auth_current_user_id 等）
```

按 PRD §3 / Plan v2 §6.2 / §7：**Phase C 的工作是把这两层都改成 per-user**。Phase B 已经为此铺好身份层；Phase C 把数据层接上。

---

## 1. Phase C scope（明确范围 + 不在范围）

### 1.1 在 Phase C 范围

| 子项 | 工作量 | 优先级 |
|------|--------|--------|
| C.1 启动顺序硬约束 + AuthBootstrap 顺利接入 drift onUpgrade | 小 | 🔴 必须 |
| C.2 drift v12 → v13 migration（9 张表加 user_id） | 大 | 🔴 必须 |
| C.3 LocalDatabase（raw sqflite）DAO 全部接 userId 参数 | 中 | 🔴 必须 |
| C.4 drift DAO 全部接 userId | 中 | 🔴 必须 |
| C.5 SP namespace migration（18 keys 改 `u_<userId>_*`） | 中 | 🔴 必须 |
| C.6 SP-backed services 改造（5 个 service 类）| 中 | 🔴 必须 |
| C.7 e2e / unit 测试 multi-user partition | 中 | 🔴 必须 |

### 1.2 不在 Phase C 范围（明示）

| 不在范围 | 归属 |
|---------|------|
| 移动端 backup / restore per-user 改造（snapshot_export_service / backup_restore_service 全表 → 用户过滤） | **Phase D**（plan v2 §1.1 / §8） |
| AUTH_ENFORCE=true 实际切流 | Phase E1 |
| 游客绑定客户端事务的不一致重试机制 | Phase F |
| β.5b 后端 lazy-load 非 dev 用户数据 | β.5b（独立残留 PR） |
| β.5c 后端 snapshot 扩 user_id（ownedItems / equipped*） | β.5c（独立残留 PR） |

Phase D 在 Phase C 之上：本地数据先按 user 分桶，然后才谈"每个用户的备份"。

---

## 2. 现状摸底（grep 实测，非估算）

### 2.1 drift schema

- 当前 `schemaVersion = 12`（`app_database.dart:88`）
- `@DriftDatabase(tables: [...])` 注册 **20 张表**（核对 sp-keys-audit §4.4 一致）
- 全部 20 张表中 **0 张有 user_id 列**（grep `user_id` `apps/mobile/lib/core/storage/drift/tables/` 命中 0 处）
- 当前 onUpgrade 已有 `v1 → v12` 的多版本迁移链（`app_database.dart:102-256`），其中已有 `_safeCreateTable` / `_safeAddColumn` / `_tableExists` 三个 PRAGMA-based 辅助方法（partial-state dev devices 已经在用）

### 2.2 raw sqflite LocalDatabase

- `local_database.dart:25`：`openDatabase(path, version: 1)` 永远 version=1
- `_createTables` 创建 5 张 legacy 表，**全部无 user_id**
- 提供 DAO 方法：`insertWordRecord` / `getMasteredWordIds` / `getUnsyncedRecords` / `markSynced` 等——**全部无 userId 参数**，无 user 过滤
- **核心 bug**：`getMasteredWordIds()` (line 160) `SELECT word_id FROM word_records WHERE action_result='know' AND study_type='new'` — 不过滤 user_id，多用户下 A 已掌握的词会被算给 B

### 2.3 公共/缓存 11 张表（不动）

- 内容层：preset_wordbooks / word_entries / word_book_assignments / example_sentences
- 富词层：word_forms / word_relations / word_phrases
- 词根层：morpheme_entries / word_morpheme_matches
- 缓存：audio_file_cache（device-local mp3 缓存，跨用户共享节省存储）
- 内容包状态：content_package_states（manifest 安装状态，与用户无关）

### 2.4 UNIQUE / PK 约束（必须改造 2 个）

- `wordbook_progress.book_id` UNIQUE（`legacy_tables.dart:38`）→ 必须改为 UNIQUE(user_id, book_id)
- `daily_checkins.date` UNIQUE（`legacy_tables.dart:49`）→ 必须改为 UNIQUE(user_id, date)
- 其余 7 张 user-scoped 表（word_records / custom_wordbooks / vocabulary_notebook / card_states / review_logs / sessions / review_records）无 UNIQUE 约束需补；某些表（如 card_states）可能需要 UNIQUE(user_id, word_id)，待 C.2 设计时确认

### 2.5 SharedPreferences keys（user-data 18 个，device-level 3 个，auth 5 个）

按 [sp-keys-audit.md](audits/sp-keys-audit.md) §1 已 grep 落地：

**Phase C 必须 user-scoped 的 18 个 key：**

| Owner service | Keys |
|---------------|------|
| `LocalSettingsService` | `settings_daily_goal` / `settings_sound_enabled` / `settings_theme` / `settings_notification_time` / `settings_desired_retention` / `settings_active_wordbook` / `settings_manifest_sync_enabled`（7）|
| `LocalProgressRepository` | `progress_word_records` / `progress_wordbook_progress` / `progress_daily_checkins` / `progress_custom_wordbooks` / `progress_vocabulary_notebook`（5）|
| `BackupUploadService` | `backup_latest_status` / `backup_latest_id` / `backup_latest_uploaded_at` / `backup_latest_schema_version`（4）|
| `AutoBackupService` | `auto_backup_last_at_ms`（1）|
| `RoomCanvasStorage` | `room_canvas_layout_v1`（1）|

**保留全局的 3 个 device-level key：**

- `device_unique_id`（device 派生，跨账号共享）
- `mochi_night_mode`（device-level UI 状态）
- `_enrichment_seed_version`（asset bundle 版本）

**已存在的 5 个 auth key（Phase B 建立，不改）：**

- `auth_current_user_id` / `auth_account_type` / `auth_pending_sp_migration` / `auth_pending_local_drift_migration` / `auth_pending_local_sqflite_migration`

注：sp-keys-audit §1.1 漏列了 `progress_*` 的实际使用——`LocalProgressRepository` 用 SharedPreferences 存 JSON。但 `progress_word_records` 等同时也是 SQLite raw 表 `word_records` 的内容。这是真双写——`snapshot_export_service.dart:73-88` 同时读两边。

### 2.6 启动顺序现状（main.dart）

实际现在的 `main.dart` 流程：

```
1. WidgetsFlutterBinding.ensureInitialized()
2. SharedPreferences.getInstance()
3. AuthBootstrap.run() ← Phase B 已接入
4. ApiClient.setDefaultHttpClient() ← Phase B 已接入
5. LocalDatabase.initialize() ← 这里 raw sqflite 打开同一 .db 文件
6. AppDatabase() ← drift 打开 .db 文件（**触发 onUpgrade migration**）
7. WordbookLoader x3
8. EnrichmentBootstrap
9. runManifestSyncIfEnabled（fire-and-forget）
10. runApp(MeowApp(authController))
```

**关键事实：步骤 6 的 drift onUpgrade 在 AuthBootstrap 之后执行**——已经满足 plan v2 §7.4 「drift migration 必须能读 auth_current_user_id」的硬约束。Phase C 无需重排启动顺序。

### 2.7 Phase B 已建立但 Phase C 必须用的 3 个 pending flag

`AuthStorage` 已定义但 Phase B 没设置任何值：

- `auth_pending_sp_migration`
- `auth_pending_local_drift_migration`
- `auth_pending_local_sqflite_migration`

Phase B 的设计是「flag 默认 false；Phase C 启动按数据现状决策」。C.5 的迁移逻辑必须读这些 flag + 数据现状交叉判断。

---

## 3. 决策点（实施前需用户确认）

| # | 决策 | 推荐 |
|---|------|------|
| **D1** | LocalDatabase 是否升 version → v2 | ❌ **不升**（保持 version=1，schema 由 drift 统一维护，sp-keys-audit §5.5 Option B）。LocalDatabase 仅做 DAO 层，所有 SQL 由 drift onUpgrade 落 |
| **D2** | drift v12 → v13 user_id 加列后，老数据 backfill 用哪个 userId | 读 `auth_current_user_id`（Phase B 启动时已写入：server_guest_id / 真实用户 id / `pending-local-guest` 占位）|
| **D3** | SP key 迁移触发条件 | A.「fresh install」（在 SP 中没找到任何 `progress_*` / `settings_*` 老键）→ **不迁移**，直接按 `u_<userId>_*` 命名空间写。<br>B.「老 user」（找到老键）→ 用当前 userId 做迁移并删老键。<br>C. `auth_pending_sp_migration` flag 作为"迁移未完成"的 retry 标记 |
| **D4** | 老 `progress_*` SP 数据 vs SQLite `word_records` 表的双写真理 | SQLite 表是 truth（snapshot_export 已经走表读）。Phase C 迁移时：SQLite 表加 user_id 列保留；SP `progress_*` 旧值直接弃用（删除老键），不双向同步 |
| **D5** | drift schema v13 失败后回滚策略 | drift migration 在事务内，失败回到 v12；启动期检测 schema_version=12 且 PRAGMA 检查发现 `word_records.user_id` 不存在 → 进入降级模式（只读，弹"升级失败请反馈"）。绝不破坏用户数据 |
| **D6** | `card_states` / `review_logs` 是否加 UNIQUE(user_id, word_id) | ✅ 加。card_states 当前 UNIQUE(word_id) — review 1 / sp-keys-audit §4.1 列出的必须改造点 |
| **D7** | partial migration 中途崩溃后的恢复 | 用 PRAGMA table_info 检测当前列状态 + auth_pending_local_drift_migration flag 作辅助；每张表的 rebuild 独立事务（drift 自身保证），单表失败不影响已迁移表 |
| **D8** | sqflite v1→? 与 drift v12→v13 的同步关系 | Option B：两者共享 .db 文件，drift onUpgrade 是唯一 schema 改动入口。raw sqflite DAO 内部 SQL 全改为带 user_id 谓词（不动 schema）。两库各自的 version 字段独立，不会撞车 |

---

## 4. 实施拆分

按 Phase A4-β 的成功模式拆 7 个独立子阶段，可分 PR 上线但需注意子阶段之间的耦合。

### C.1 — 启动顺序断言 + AuthStorage flag 写入（小，独立）

**目的：** Phase C 的安全网。在写任何 schema migration 之前，先把启动顺序硬约束在代码里。

**改动：**

1. `main.dart` 加 assertion 风格的注释 + 断言代码：drift onUpgrade 跑之前 `auth_current_user_id` 必须已设置（B 启动流程已保证，C 加 runtime assert 防止未来回归）

2. `AuthStorage` 新增 `markFreshInstallIfNeeded()`：
   - 检查 SP 是否含任何老 user-data key（`settings_daily_goal` / `progress_*` 等的存在性）
   - 若**没有**任何老键 → 这是 fresh install，3 个 pending flag 设 false
   - 若**有**老键 → 老用户首次启动 C 版本，3 个 pending flag 设 true（提示后续 SP/drift/sqflite migration 必跑）
   - 该方法在 AuthBootstrap 完成后、drift 打开前调用一次

3. `AuthController.bootstrap()` 末尾调 `markFreshInstallIfNeeded()`

**测试：**
- fresh prefs → 三 flag 全为 false
- prefs 含 `settings_daily_goal` → 三 flag 全为 true
- 已设置过 flag → 不再覆盖

**工作量：** ~30 分钟代码 + 3 测试用例

### C.2 — drift v12 → v13 migration（核心，大）

**目的：** 9 张 user-scoped 表加 `user_id TEXT NOT NULL` 列 + UNIQUE 改造 + 老数据 backfill。

**改动：**

1. 9 张 drift table class 加 `userId` 列：
   ```dart
   TextColumn get userId => text().named('user_id')();
   ```

2. `wordbook_progress.book_id` UNIQUE → drift 用 `@TableIndex` 或重建 schema：
   - drift 不支持直接改 UNIQUE 约束，必须 rebuild table（SQLite 限制）
   - 实施：在 onUpgrade v13 步骤中 rebuild

3. `daily_checkins.date` UNIQUE → 同上

4. `card_states.word_id` UNIQUE → UNIQUE(user_id, word_id)，rebuild

5. `app_database.dart` schemaVersion 改 13

6. `onUpgrade` 增加 `if (from < 13)` 块（实际 PRAGMA-based 算法见 §5）

7. drift schemaVersion 改动**同时影响 fresh install**：onCreate 也要用新表定义（包含 user_id 列），所以 user_id NOT NULL 在新 install 时也直接生效

**测试：**
- migration_test.dart 新增 v12→v13 实例测试（drift 提供 `verifyMigration` helper，已有先例）
- 老数据有 wordbook_progress / daily_checkins / card_states 行 → 迁移后正确归属到 `auth_current_user_id`
- 同 book_id 不同用户 → 不撞 UNIQUE（验证复合 UNIQUE 生效）

**工作量：** 4-6 小时代码 + 充分测试

### C.3 — LocalDatabase（raw sqflite）DAO 接 userId

**目的：** 5 个 legacy 表的 raw sqflite DAO 全部接 userId 参数 + SQL 加 WHERE 谓词。

**改动 17 个方法**（grep `LocalDatabase` 公共方法）：

```
insertWordRecord(userId, ...)        — INSERT 时写 user_id
getMasteredWordIds(userId)           — WHERE user_id = ?
getUnsyncedRecords(userId)           — WHERE user_id = ?
markSynced(id)                       — id 是 autoincrement，单行 update 不需要 userId
distinctWordIdsRatedToday(userId)    — WHERE user_id = ? AND ...
upsertWordbookProgress(userId, ...)  — INSERT 时写 user_id；UPSERT 按 (user_id, book_id)
... (其余 DAO 同样改造)
```

注意：所有调用方（study_service.dart / stats_service.dart / today_service.dart 等）也要改，从 `AuthScope.read(context).currentUserId` 拿 userId 传入。

**测试：**
- LocalDatabase 集成测试：A 写 word_record，B 调 getMasteredWordIds 返回空
- 同 word_id 在 A 和 B 各自独立的 word_records.id 行

**工作量：** 2-3 小时

### C.4 — drift DAO 接 userId

**目的：** drift 的 select / insert query 在调用层加 userId 过滤。

drift 不像 raw sqflite 是封装好的 DAO 方法集合——业务代码直接写 `select(wordRecords).get()`、`(select(reviewLogs)..where((r) => ...)).get()` 等。grep 实测调用点约 30-40 处（散落在 services / features 中）。

**改造方式（评估两选项）：**

- **选项 A**：调用点手改加 userId 过滤（labor-intensive）
- **选项 B**：drift 加 mixin / extension 提供 user-scoped variants `selectForUser(userId, table)` ，鼓励新代码用 + 老代码逐步迁移

选项 A 更彻底，选项 B 更渐进。Phase C 推荐 **A**（一次到位），β 时间为 4-6 小时给。

**测试：**
- A 写 review_log，B 查询 review_logs 返回空
- A 学习一个词进 sessions 表，B 的 sessions 列表为空

**工作量：** 4-6 小时

### C.5 — SP namespace migration（18 keys）

**目的：** 把全局 `settings_daily_goal` 等键迁移到 `u_<userId>_settings_daily_goal`。

**迁移算法（启动时跑一次）：**

```dart
class SpMigrator {
  Future<void> migrateIfNeeded(SharedPreferences prefs, String userId) async {
    if (storage.readPendingSpMigration() == false) return; // 已完成或 fresh install
    
    final keyMap = <String, String>{
      'settings_daily_goal': 'u_${userId}_settings_daily_goal',
      'settings_sound_enabled': 'u_${userId}_settings_sound_enabled',
      // ... 18 个键
    };
    
    for (final entry in keyMap.entries) {
      final oldKey = entry.key;
      final newKey = entry.value;
      if (prefs.containsKey(oldKey) && !prefs.containsKey(newKey)) {
        // 类型自适应复制
        final dynamic value = prefs.get(oldKey);
        if (value is int) await prefs.setInt(newKey, value);
        else if (value is bool) await prefs.setBool(newKey, value);
        else if (value is double) await prefs.setDouble(newKey, value);
        else if (value is String) await prefs.setString(newKey, value);
        else if (value is List<String>) await prefs.setStringList(newKey, value);
        await prefs.remove(oldKey);
      }
    }
    
    await storage.writePendingSpMigration(false); // 标记完成
  }
}
```

**特性：**
- 幂等：再跑一次是 no-op（pending flag 检查 + 目标键已存在检查）
- 失败安全：若中途断电，pending flag 还是 true，下次启动继续；目标键已存在则跳过个别键（不覆盖）
- 老键删除：确保 fresh install 行为一致（fresh install 时这些键就不存在）

**测试：**
- 含老键 + pending=true → 迁移后老键删除、新键存在、pending=false
- 不含老键 + pending=true → 迁移空跑、flag 仍设 false（标记完成）
- 含部分新键 + 部分老键 → 跳过新键，迁移老键

**工作量：** 1-2 小时

### C.6 — SP-backed services 改造

**目的：** 5 个 service 类构造时接收 userId 或从 SP 读 `u_<userId>_*`。

**改造的类：**

1. `LocalSettingsService`（7 keys）：构造函数加 userId 参数，内部 key 前缀化
2. `LocalProgressRepository`（5 keys）：构造函数加 userId
3. `BackupUploadService`（4 keys）：构造函数加 userId
4. `AutoBackupService`（1 key）：单方法静态调用，加 userId 参数
5. `RoomCanvasStorage`（1 key）：构造函数加 userId

每个 service 现有调用点（grep 显示约 8-12 处）改为传 `AuthScope.read(context).currentUserId`。

**测试：**
- 同一 prefs 实例下，两个 LocalSettingsService(userId='A') 和 (userId='B') 互不串
- 改一边的 dailyGoal 不影响另一边
- RoomCanvasStorage A/B 互不见家具

**工作量：** 2-3 小时

### C.7 — multi-user e2e / unit 测试

**目的：** 验证完整 C 改造在端到端场景下真隔离。

**测试矩阵（widget test 形式）：**

1. fresh install → guest user 启动 → 学习一个词 → drift `word_records` 有 1 行带 guest userId
2. fresh install → guest → 学习 → 绑定到 registered（同行升级，userId 不变）→ 该词仍出现在 mastered
3. fresh install → guest A → 学习 → 退出登录 → 切到 guest B（不同 device 模拟）→ B 的 today_new_completed = 0
4. SP 迁移：模拟老 SP 状态 → 启动 → 迁移完成 → 设置正确归属
5. drift migration: 模拟 v12 状态有 word_records 数据 → 启动 → v13 后数据归当前 user
6. RoomCanvasStorage：A 摆家具 → 切 B → B 房间空 → 切回 A → 家具还在

**工作量：** 3-4 小时

---

## 5. drift v13 onUpgrade 算法（详细）

按 sp-keys-audit v1.1 §5.2 修订后的 PRAGMA-based 条件式：

```dart
if (from < 13) {
  // Step 1: get the userId for backfilling existing rows
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('auth_current_user_id')
      ?? 'pending-local-guest';  // 启动顺序硬约束: AuthBootstrap 先跑

  const tables = [
    // (tableName, hasUniqueChange, uniqueColumns)
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
    if (await _hasUserIdColumn(name)) {
      // fresh install 已经按 v13 schema 建表 → 跳过 rebuild
      continue;
    }
    if (!await _tableExists(name)) {
      // 表不存在（极少 dev devices） → 跳过
      continue;
    }
    if (uniqueChange) {
      await _rebuildTableWithUserId(name, userId, uniqueCols!);
    } else {
      await _addUserIdColumn(name, userId);
    }
  }
}

Future<void> _addUserIdColumn(String tableName, String userId) async {
  // Simple case: ALTER TABLE ADD COLUMN
  await customStatement(
    "ALTER TABLE $tableName ADD COLUMN user_id TEXT NOT NULL DEFAULT '$userId'");
}

Future<void> _rebuildTableWithUserId(
    String tableName, String userId, List<String> uniqueCols) async {
  // SQLite restriction: cannot add UNIQUE constraint via ALTER.
  // Must use new-table + copy + drop + rename pattern.
  // Transaction wrapping is handled by drift's Migrator implicitly.
  
  // 1. Read old columns
  final cols = await customSelect('PRAGMA table_info($tableName)').get();
  final oldColumns = cols.map((r) => r.read<String>('name')).toList();
  
  // 2. Create new table with user_id + new UNIQUE
  // (Use drift's table definition for the canonical shape — same as fresh install)
  await customStatement('ALTER TABLE $tableName RENAME TO ${tableName}__old');
  
  // 3. Create the canonical v13 shape
  // (drift's m.createTable would work but it generates without UNIQUE
  //  customization — for UNIQUE we issue raw SQL matching the drift def)
  await customStatement(_v13CreateSqlFor(tableName, uniqueCols));
  
  // 4. Copy data with userId backfill
  final colList = oldColumns.join(', ');
  await customStatement(
    "INSERT INTO $tableName ($colList, user_id) "
    "SELECT $colList, '$userId' FROM ${tableName}__old"
  );
  
  // 5. Drop old table
  await customStatement('DROP TABLE ${tableName}__old');
  
  // 6. Recreate indexes (drift @TableIndex doesn't re-emit on rebuild)
  await _recreateIndexesFor(tableName);
}
```

**关键属性：**

- **Fresh install 兼容**：`_hasUserIdColumn` 返 true 时跳过，因为 onCreate 已用 v13 schema 建表
- **多版本升级路径兼容**：v1→v13 / v8→v13 都走同一段代码，每张表独立判断
- **PRAGMA-based 检测**：与现有 v9 / v10 onUpgrade 一致（`_safeAddColumn` / `_safeCreateTable` 已是这个模式）
- **失败原子性**：drift Migrator 包事务；单张表的 rebuild 也包子事务
- **每张表独立**：A 表 rebuild 成功 + B 表失败 → 已迁移的 A 不丢

---

## 6. 测试矩阵（C.7 详细）

| # | 用例 | 验收 |
|---|------|------|
| T1 | fresh install + guest 启动 + 学一词 | `word_records` 1 行，`user_id = <guest_id>` |
| T2 | drift v12 → v13 含老数据 backfill | 老 word_records 全部归 `auth_current_user_id` |
| T3 | 老 `progress_*` SP 迁移到 `u_<userId>_progress_*` | 老键删除，新键存在 |
| T4 | 同 book_id 两 user，UNIQUE 不撞 | A 和 B 各自有 wordbook_progress 行 |
| T5 | LocalDatabase.getMasteredWordIds 跨用户隔离 | A 已 know 不出现在 B 结果 |
| T6 | RoomCanvasStorage A/B 家具不串 | A 摆 → B 空 |
| T7 | logout 后切 guest，原 user 数据保留 | drift 表 `user_id` 仍是原值，不被 wipe |
| T8 | 绑定（同行升级）后 userId 不变 | 数据无需迁移 / 不被错搬 |
| T9 | LocalSettingsService A/B daily_goal 互不串 | 改 A 不影响 B |
| T10 | drift migration 失败 → schema 不前进 | schema_version 仍是 12，PRAGMA 检查 user_id 列不存在 → 进降级模式 |

---

## 7. 风险与缓解

| 风险 | 缓解 |
|------|------|
| drift onUpgrade rebuild 过程中断电 | 每张表独立子事务（drift 内部）；启动时再次进入 v12 状态，重跑 v12→v13 时 `_hasUserIdColumn` 检查使已完成的表跳过 |
| `auth_current_user_id` 在 drift 开库时为 null（启动顺序失误） | C.1 加 assertion；fallback 到 `'pending-local-guest'` 占位 |
| LocalDatabase 与 drift 不同步（drift schema 已 v13，LocalDatabase 仍 version=1） | Option B 保持 LocalDatabase version=1（schema 由 drift 维护），但**所有 SQL 走 drift 现有 schema**——LocalDatabase DAO 改写后用 `_db.rawQuery` 或 drift 的 `customStatement` |
| SP migration 中途崩溃 | 幂等设计 + `auth_pending_sp_migration` flag retry |
| 18 SP key 类型不匹配（int 写成 string） | 类型自适应复制（`prefs.get()` 返 dynamic 再 dispatch） |
| dev 环境用 `pending-local-guest` 作 userId 导致后续登录后老数据无法归到真用户 | 拿到真 user_id 时 `_attachGuest` 或 `_commitSession` 完成后跑一次 drift `UPDATE ... WHERE user_id = 'pending-local-guest' SET user_id = $new` —— Phase C 实施时单独写一个 `migrateLocalGuestData` 方法 |
| 调用点漏改导致部分 query 不带 userId | 集中放到 service 层，service 构造接 userId，调用点不直接写 SQL |
| 测试用 in-memory drift 跑不出 PRAGMA 行为差 | drift `verifyMigration` 配合 NativeDatabase.memory()；多版本起点测试用 SchemaVerifier（drift 提供） |

---

## 8. 拆分上线（建议）

| PR | 内容 | 上线风险 | 依赖 |
|----|------|---------|------|
| **PR-C1** | C.1 启动 + flag 写入 | 低 | 独立 |
| **PR-C2** | C.2 drift v13 migration | **高** | 必须先 |
| **PR-C3** | C.3 + C.4 DAO 改造（LocalDatabase + drift query 调用点） | 中 | 依赖 PR-C2 |
| **PR-C4** | C.5 + C.6 SP migration + services | 中 | 独立于 PR-C3，但建议同 milestone |
| **PR-C5** | C.7 e2e 完整覆盖 + 修发现的回归 | 低 | 依赖 PR-C2/C3/C4 |

PR-C1 可先合（无破坏）。PR-C2 是最大风险点（schema 改动 + 迁移），需充分测试后合并。PR-C3 / PR-C4 互不依赖，可并行。

---

## 9. 与 Phase B hot-fix 留 TODO 的衔接

Phase B 5d83936 commit message 末尾留了一个不采纳条目：

> 评审 1 #6 (pending migration flag 在 B 设): 倾向 C 启动按数据现状决策（避免 fresh install 误判）

Phase C **正式实现这个决策**（C.1 的 `markFreshInstallIfNeeded`）。

Phase B 的 `auth_storage.dart` 已经定义了 3 个 pending flag 字段、提供 read/write 方法——Phase C 直接接用。这意味着 Phase B 没"漏做"，只是把决策时机推到了 C。

---

## 10. 估时

按 plan-023-A4-beta-v1.md 的实测经验校准（β 实际工时是估时的 ~30%）：

| 子项 | 估时（保守）| 实际预期 |
|------|------------|---------|
| C.1 启动 + flag | 1 小时 | 0.5 小时 |
| C.2 drift v13 migration | 6-8 小时 | 4-5 小时 |
| C.3 LocalDatabase DAO | 3 小时 | 2 小时 |
| C.4 drift DAO 调用点 | 4-6 小时 | 3-4 小时 |
| C.5 SP migration | 2 小时 | 1 小时 |
| C.6 SP services | 3 小时 | 2 小时 |
| C.7 e2e + 测试 | 4 小时 | 3 小时 |
| **合计** | **23-27 小时** | **15-17 小时**（约 2 个工作日） |

Phase C 是 Phase A4-β 工作量的 ~3 倍。比 Phase B（5 小时）也大几倍。最大不确定性是 drift v13 migration 真在多种 dev 设备状态下的回放测试。

---

## 11. 不在 Phase C 范围（再次明示）

- **移动端 backup_export / restore per-user 改造**：snapshot_export 当前是全表导出，restore 是全表 delete + insert（sp-keys-audit §8.1 已记录）；Phase D 改为 per-user 过滤
- **AUTH_ENFORCE=true 切流**：Phase E1；β.5b / β.5c 后端残留 + Phase C 完成都做完才能切
- **绑定客户端事务的不一致重试**：Phase F；用 `auth_pending_local_*_migration` 系列标记 + 启动重试
- **`pending-local-guest` → 真 user_id 的数据 backfill**：实际上是 Phase C 必做的副作用（D6 + 风险表里已经列），但属于 C 内部小步骤而非独立 Phase

---

## 12. 验证

每个 PR 单独跑：

```
cd apps/mobile && flutter analyze   # 0 issues
cd apps/mobile && flutter test       # 全套 1218/1218 不破 + 新加用例全过
```

PR-C2 + PR-C3 必须再单独跑：

```
cd apps/mobile && flutter test test/migration_test.dart  # drift migration 真实验证
```

全部完成后：

```
# 完整启动一次（模拟器 / 真机）
cd apps/mobile && flutter run
# 手动验证：
#   1. fresh install → 看 SP 是否落 u_<userId>_settings_*
#   2. 切到老 dev 版本数据库 → 启动 → 看 drift schema 升到 v13
#   3. profile page 显示 nickname 而非 "Alex"
```

---

## 13. 下一步

请用户确认：

1. **D1-D8 八个决策点**逐条 OK 或修改
2. **PR 拆分策略**（5 个 PR 是否合理 / 哪些可合并）
3. **估时 15-17 小时**是否在预期范围
4. 是否同意先做 C.1（启动 + flag 写入，低风险独立 PR），跑通后再开 C.2 大改

确认后按 PR-C1 → PR-C2 → (PR-C3 ∥ PR-C4) → PR-C5 顺序实施。
