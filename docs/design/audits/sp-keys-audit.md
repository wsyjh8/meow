# Mobile Local Storage Audit — Phase 0 / 需求 23

**Status:** complete (v1.2 — Phase G 落地映射 + Phase C 实施全部 commit hash)
**Scope:** `apps/mobile/lib/` 的 SharedPreferences keys + raw sqflite `LocalDatabase` + drift `AppDatabase` 表
**Purpose:** 列出所有需在多用户化时改为 user-scoped 的本地存储，并解决 drift 与 raw sqflite 的同名表归属；v1.2 补 Phase B/C 实施完成后的落地映射
**关联:**
- [plan-023-用户系统与用户数据隔离-v2.md](../plan-023-用户系统与用户数据隔离-v2.md) §7 / §14
- [plan-023-C-mobile-local-partition-v2.md](../plan-023-C-mobile-local-partition-v2.md)
- [prd-§9-acceptance-coverage.md](./prd-§9-acceptance-coverage.md)
**日期:** 2026-05-09 (v1.0) → 2026-05-09 (v1.1，吸收两份外部 review) → 2026-05-11 (v1.2，Phase G 落地映射)

---

## v1.1 修订记录

| 修订点 | 来源 | 处理 |
|--------|------|------|
| §4.4 "drift 总表数 22 张" → "20 张" | review 1+2 | ✅ 采纳，5+4+11=20，原数字笔误。同步影响 plan v2 §7.2（plan v2 也有同笔误，需同步修正） |
| §1.3 `auth_access_token` 从 SharedPreferences 改到 `flutter_secure_storage` | review 2 #2（技术建议部分） | ✅ 采纳，安全最佳实践。pubspec.yaml 当前没有 `flutter_secure_storage` 依赖，Phase B 实施时需新增 |
| §5 v13 migration 改为 PRAGMA table_info 条件式 | review 2 #3 | ✅ 采纳，避免 fresh install + 历史升级路径产生的列冲突 |
| §7.3 启动顺序加 "目标状态" 免责声明 | review 1 | ✅ 采纳 |
| `../apps/` 路径 → `../../../apps/` | review 2 #6 | ✅ 采纳 |
| 跨审计联动 | review 1 §4.2 | ✅ 采纳 |
| Review 2 #5 提议复活 `local_guest_id` 双 ID 流程 | review 2 #5 | ❌ **拒绝**。plan v2 §6.3 / D6 已用户拍板"单 ID = server_guest_user_id + 离线占位 `pending-local-guest`"，这是已确认决策。Review 2 #5 的"你给的流程是首次安装先生成 device_id + local_guest_id"是错误前提（用户从未给过此流程）。本审计继续按 plan v2 §6.3 单 ID 方案，不变。详见 §5.4 |

> 注：plan v2 §13 列名为 `sp-keys-audit.md`。本文按计划交付该文件，但内容范围扩到 mobile 全部本地存储（SP + sqflite + drift），因为三者在多用户化方案里互相耦合，分三份会重复且容易遗漏交叉点。

---

## 1. SharedPreferences keys 全列表

按用户归属性质分三类：

### 1.1 用户数据（必须 user-scoped）

| key | owner | 类型 | 用途 | 现状 |
|-----|-------|------|------|------|
| `settings_daily_goal` | LocalSettingsService | int | 每日目标 | 全局 |
| `settings_sound_enabled` | LocalSettingsService | bool | 音效开关 | 全局 |
| `settings_theme` | LocalSettingsService | string | 主题 | 全局 |
| `settings_notification_time` | LocalSettingsService | string | 推送时间 HH:mm | 全局 |
| `settings_desired_retention` | LocalSettingsService | double | FSRS 期望留存率 | 全局 |
| `settings_active_wordbook` | LocalSettingsService | string | 当前激活词书 | 全局 |
| `settings_manifest_sync_enabled` | LocalSettingsService | bool | 内容包同步 flag | 全局 |
| `progress_word_records` | LocalProgressRepository | json list | 学习记录 | 全局 |
| `progress_wordbook_progress` | LocalProgressRepository | json map | 词书进度 | 全局 |
| `progress_daily_checkins` | LocalProgressRepository | json list | 签到记录 | 全局 |
| `progress_custom_wordbooks` | LocalProgressRepository | json list | 自定义词书 | 全局 |
| `progress_vocabulary_notebook` | LocalProgressRepository | json list | 生词本 | 全局 |
| `backup_latest_status` | BackupUploadService | string | 最近备份状态 | 全局 |
| `backup_latest_id` | BackupUploadService | string | 最近备份 ID | 全局 |
| `backup_latest_uploaded_at` | BackupUploadService | string | 上传时间 | 全局 |
| `backup_latest_schema_version` | BackupUploadService | string | snapshot schema | 全局 |
| `auto_backup_last_at_ms` | AutoBackupService | int | 自动备份时间戳 | 全局 |
| `room_canvas_layout_v1` | RoomCanvasStorage | json | 家具布局 | 全局 |

**计 18 个 key 需要改为 `u_${userId}_${原 key}` 命名空间。**

### 1.2 设备级数据（不动）

| key | owner | 类型 | 用途 | 决策 |
|-----|-------|------|------|------|
| `device_unique_id` | DeviceInfoService | string | UUID v4，设备唯一标识 | **保留全局**（device 级，绑定 user 起号用） |
| `mochi_night_mode` | spec_shell.dart | bool | 夜间模式 UI 切换 | **保留全局**（device-level UI 状态，跨用户共享 OK） |
| `_enrichment_seed_version` | enrichment_bootstrap.dart | int | bundled seed 版本，避免重复导入 | **保留全局**（asset bundle 版本，与用户无关） |

### 1.3 鉴权专用（Phase B 新增）

**重要分桶（v1.1）：** token 是凭证（敏感），其他是元数据（非敏感）。前者进 secure storage，后者进 SharedPreferences。

#### 1.3a 凭证 — `flutter_secure_storage`（v1.1 新增依赖）

| key | 类型 | 用途 |
|-----|------|------|
| `auth_access_token` | string | JWT；登出清空 |

理由：SharedPreferences 在 Android 上明文存放（不加密），iOS 也仅 Keychain 间接接入。token 一旦落本地必须用 OS 级 secure storage（Android Keystore / iOS Keychain）。`flutter_secure_storage` 是社区标准方案。

**Phase B 实施变化：**
- pubspec.yaml 加依赖 `flutter_secure_storage: ^X.Y.Z`（具体版本 Phase B 选）
- 新增 `AuthSecureStorage` 类，与 `AuthStorage`（管 SP 部分）分开
- 启动流程读 token 从 secure storage、读 user_id 从 SP

#### 1.3b 非敏感元数据 — SharedPreferences

| key | owner | 类型 | 用途 |
|-----|-------|------|------|
| `auth_current_user_id` | AuthStorage（新增） | string | 当前 active user_id；游客也填（server_guest_id 或 `pending-local-guest`） |
| `auth_account_type` | AuthStorage（新增） | string | `'guest' \| 'registered'` |
| `auth_pending_sp_migration` | AuthStorage（新增） | bool | SP 命名空间迁移未完成标记，启动时重试 |
| `auth_pending_local_drift_migration` | AuthStorage（新增） | bool | drift 数据迁移未完成标记 |
| `auth_pending_local_sqflite_migration` | AuthStorage（新增） | bool | sqflite 数据迁移未完成标记 |

理由：user_id / account_type / pending flags 不是凭证，不构成访问能力，丢了也只是状态信息丢失。SP 即可。

---

## 2. 命名空间迁移方案

### 2.1 命名约定

```
原 key:       settings_daily_goal
新 key:       u_<user_id>_settings_daily_goal
```

`<user_id>` 是 `auth_current_user_id` 当前值。Phase C3 实施时，所有访问点改为：

```dart
// 旧:
String get _key => 'settings_daily_goal';

// 新:
String _key(String userId) => 'u_${userId}_settings_daily_goal';
```

### 2.2 迁移时机

启动流程（plan v2 §7.4）拿到 `server_guest_user_id` 之后：

```
if (auth_pending_sp_migration == true || (该 user 命名空间下 key 全空 && 原全局 key 有值)) {
  for each 旧 key in §1.1:
    new_value = _prefs.get(旧 key)
    if (new_value != null):
      _prefs.set(`u_<user>_${旧 key}`, new_value)
      _prefs.remove(旧 key)
  _prefs.remove('auth_pending_sp_migration')
}
```

**幂等性**：迁移每个 key 是单独操作，部分失败可重试。读迁移源前先校验目标 namespace 是空，避免覆盖更新数据。

### 2.3 退出登录后的访问

退出登录后切到游客上下文，新 server_guest_user_id 的命名空间是空的（除非用户曾以游客身份用过，那时已有数据）。**绝不读 registered user 的命名空间**，避免数据穿透。

---

## 3. 移动端两套数据库重叠（关键发现）

### 3.1 现状：raw sqflite + drift 共享同一 .db 文件

物理文件：`<app>/databases/meow_progress.db`

两个 Dart API 都打开它：

```
LocalDatabase（apps/mobile/lib/core/storage/local_database.dart）
  - openDatabase(path, version: 1)
  - 显式创建 5 张表：word_records / wordbook_progress / daily_checkins
                    / custom_wordbooks / vocabulary_notebook

AppDatabase（apps/mobile/lib/core/storage/drift/app_database.dart）
  - drift opens same path via _openConnection()
  - schemaVersion = 12
  - onUpgrade from < 2 注释明确写：
    "Upgrading from raw sqflite v1: The 5 legacy tables already exist
     in the database file. Only create the 2 new FSRS tables..."
```

**含义：** 同一份物理表被两个 Dart API 共同访问。drift v2+ 接管后没动这 5 张表的 schema，但代码两个入口都在用：

| 表 | LocalDatabase API 用法 | drift API 用法 |
|----|------------------------|----------------|
| `word_records` | `insertWordRecord()`, `getAllWordRecords()`, `replaceAllWordRecords()` | `WordRecords` Drift table |
| `wordbook_progress` | LocalDatabase 方法 | `WordbookProgress` Drift table |
| `daily_checkins` | LocalDatabase 方法 | `DailyCheckins` Drift table |
| `custom_wordbooks` | LocalDatabase 方法 | `CustomWordbooks` Drift table |
| `vocabulary_notebook` | LocalDatabase 方法 | `VocabularyNotebook` Drift table |

**新表（仅 drift，sqflite 不知道）：** `card_states`、`review_logs`、`sessions`、`review_records`、`word_forms`、`word_relations`、`word_phrases`、`morpheme_entries`、`word_morpheme_matches`、`audio_file_cache`、`content_package_states`、`preset_wordbooks`、`word_entries`、`word_book_assignments`、`example_sentences`

`snapshot_export_service.dart` 读这些表用混合方式：[snapshot_export_service.dart:73](../../../apps/mobile/lib/core/storage/snapshot_export_service.dart) `_db.getAllWordRecords()`（走 LocalDatabase API）+ `_db.getAllFromTable('card_states')`（走 LocalDatabase 的 raw query 方法读 drift 表）。

### 3.2 多用户化的影响

**坏消息：** schema 修改要改两次代码（虽然只改一次 SQL）：
- 加 `user_id` 列：写 SQL 一次（drift 的 onUpgrade 回调里加，sqflite 的 onUpgrade 也要走同一逻辑）
- LocalDatabase 的所有 API 加 `userId` 参数
- drift 的所有 DAO 查询加 `where user_id = :uid`
- snapshot_export 读两套都得带 user_id

**好消息：** 只有一份物理数据需要 backfill 老 user_id；不用担心两份数据要双写。

### 3.3 迁移决策

**Phase 0 不做架构归并**（不把 LocalDatabase 改成只用 drift），原因：
- 那是独立重构（CLAUDE.md §3.3 范围纪律），与需求 23 正交
- 重构会破坏 [snapshot_export_service.dart](../../../apps/mobile/lib/core/storage/snapshot_export_service.dart) 等依赖 LocalDatabase API 的代码

**Phase C 实施策略：**

```
1. 写一份 SQL 级别的 migration（drift onUpgrade v12→v13 里执行）
   - 5 张 legacy 表都按"新表 + INSERT SELECT + DROP + RENAME"加 user_id
   - 7 张 drift-only 用户行为表（card_states 等）按 drift Migrator 标准方式加 user_id
2. LocalDatabase API 全改为接受 userId 参数
   - LocalDatabase 自身**不要**追 schemaVersion=2，因为 schema 由 drift 管。
   - LocalDatabase 的 _createTables 里也要把 user_id 列加进去（保护 onCreate 路径，
     但实际触发的是 drift onCreate）
3. drift DAO 全改为按 currentUserId 过滤
4. snapshot_export / backup_restore 全改为 per-user 过滤
```

**风险：drift onCreate 与 sqflite onCreate 的二次接触**

如果用户首次启动（fresh install）时 LocalDatabase 先 init（_createTables 跑），后 AppDatabase 再 init（drift onCreate 想 createAll），drift 的 `m.createAll()` 会尝试创建 5 张 legacy 表导致重复。这是当前已有的 race，drift v1→v2 的 onUpgrade 注释也提到这个边界。Phase 0 仅记录，**Phase C 实施时必须做 fresh install 测试**确保新版仍能干净启动。

---

## 4. 数据库表完整清单（按 user-scope 分类）

### 4.1 raw sqflite + drift 共享的 5 张 legacy 表（v13 必须加 user_id）

| 表 | 性质 | 备注 |
|----|------|------|
| `word_records` | 用户写 | 学习事件 log |
| `wordbook_progress` | 用户读写 | 词书进度（含 UNIQUE(`book_id`)，要改为 UNIQUE(`user_id`, `book_id`)） |
| `daily_checkins` | 用户写 | 签到（含 UNIQUE(`date`)，要改为 UNIQUE(`user_id`, `date`)） |
| `custom_wordbooks` | 用户读写 | 自定义词书 |
| `vocabulary_notebook` | 用户读写 | 生词本 |

### 4.2 drift-only 用户行为表（v13 必须加 user_id）

| 表 | drift 文件 | 性质 |
|----|------------|------|
| `card_states` | fsrs_tables.dart | FSRS 卡片状态 |
| `review_logs` | fsrs_tables.dart | FSRS 复习日志 |
| `sessions` | session_tables.dart | 学习 session |
| `review_records` | session_tables.dart | session 内复习记录 |

**4 张表。**

### 4.3 公共内容表（不加 user_id）

| 表 | drift 文件 |
|----|------------|
| `preset_wordbooks` | （contentor） |
| `word_entries` | |
| `word_book_assignments` | |
| `example_sentences` | |
| `word_forms` | enrichment_tables.dart |
| `word_relations` | |
| `word_phrases` | |
| `morpheme_entries` | |
| `word_morpheme_matches` | |
| `audio_file_cache` | （audio cache，跨用户共享 mp3 文件，节省存储） |
| `content_package_states` | content_package_state.dart |

**11 张表，全部不加 user_id**（按 PRD §5.2）。

### 4.4 总计

- **加 user_id 的表：5 (legacy) + 4 (drift-only 行为) = 9 张**
- **不动的表：11 张**
- **drift 总表数：20 张** ✅ 与 [app_database.dart:30-61](../../../apps/mobile/lib/core/storage/drift/app_database.dart) `@DriftDatabase(tables: [...])` 注解的 20 个 table class 对齐
- ⚠️ plan v2 §7.2 写的"22 张"是同源笔误，需在 plan v2 patch 中同步修正为 20

---

## 5. 数据迁移 backfill 策略（v13 onUpgrade）

### 5.1 关键约束（v1.1 修订）

v1.0 草案给的 migration 算法对 9 张表统一"新表 + INSERT SELECT + DROP + RENAME"，review 2 #3 指出风险：drift table 定义会在不同版本路径下被以不同形态创建，盲目 rebuild 会撞列。

**实际版本路径列举：**

| 路径 | card_states / review_logs 当前形态 | legacy 5 表当前形态 |
|------|---------------------------------|---------------------|
| Fresh install at v13 (onCreate) | drift 按 v13 table 定义 createAll，**已含 user_id** | 同上 |
| 现网设备 v12 → v13 (onUpgrade from=12) | 历史 v2 创建时**不含 user_id** | v1 创建（raw sqflite era），**不含 user_id** |
| 半旧设备 v8 → v13（多跳） | v2 创建时不含，但中途没改 | 同上 |

**含义：** 同一个表 `card_states` 在 fresh install 后**已经有 user_id**，但在升级路径下**没有 user_id**。migration 必须**逐表用 PRAGMA table_info 判断**当前形态，再决定是否 rebuild。

### 5.2 修订后的 migration 算法

```dart
if (from < 13) {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('auth_current_user_id') ?? 'pending-local-guest';

  // 9 张需 user_id 的表
  const tablesNeedingUserId = [
    // legacy 5 张（共享 raw sqflite + drift）
    'word_records', 'wordbook_progress', 'daily_checkins',
    'custom_wordbooks', 'vocabulary_notebook',
    // drift-only 4 张（用户行为）
    'card_states', 'review_logs', 'sessions', 'review_records',
  ];

  for (final tableName in tablesNeedingUserId) {
    if (await _hasUserIdColumn(tableName)) {
      // fresh install 路径：drift onCreate 已经按 v13 定义建表，跳过
      continue;
    }
    // 现网升级路径：rebuild
    await _rebuildTableWithUserId(tableName, userId);
  }
}

Future<bool> _hasUserIdColumn(String tableName) async {
  final cols = await customSelect(
    'PRAGMA table_info($tableName)',
  ).get();
  return cols.any((r) => r.read<String>('name') == 'user_id');
}

Future<void> _rebuildTableWithUserId(String tableName, String userId) async {
  // 1. CREATE TABLE ${tableName}__new (... + user_id TEXT NOT NULL DEFAULT '$userId')
  // 2. INSERT INTO ${tableName}__new SELECT *, '$userId' FROM ${tableName}
  // 3. DROP TABLE ${tableName}
  // 4. ALTER TABLE ${tableName}__new RENAME TO ${tableName}
  // 5. 重建 index（drift @TableIndex 不会自动恢复，需手写）
  // 6. 对 legacy 5 表的 UNIQUE 改造：
  //    - wordbook_progress: 原 UNIQUE(book_id) → UNIQUE(user_id, book_id)
  //    - daily_checkins: 原 UNIQUE(date) → UNIQUE(user_id, date)
  //    - 其余 3 表无 UNIQUE 约束，不动
}
```

`_safeAddColumn` 的现有 `PRAGMA table_info` 模式（[app_database.dart:266](../../../apps/mobile/lib/core/storage/drift/app_database.dart)）已经为本方案铺好基础设施。

### 5.3 失败处理

drift migration 在事务内执行，整体失败 → schema_version 不前进，下次启动重试。失败原因可能：
- SQLite 容量不足（rebuild 临时占用 ~2x 表大小）
- 单条 INSERT 撞 UNIQUE（pre-existing 数据有冲突，例如 wordbook_progress 已有同 book_id 但不同 user_id 的多行——多用户化前不应该出现，但 dev 环境可能）

如果 `auth_current_user_id == 'pending-local-guest'`，意味着用户从未联网过。Phase F 绑定时这些数据按 plan v2 §6.3 单 ID 方案 UPDATE 替换为 server_guest_id。

### 5.4 plan v2 §6.3 单 ID 方案的再次确认（v1.1）

Review 2 #5 建议改为"启动时始终先生成稳定 local_guest_id，本地 DB 永远先归属 local guest；server guest 仅在登录后做显式迁移"。

**本审计明确不采纳**。理由：

1. **plan v2 §6.3 / D6 已用户拍板**：单 ID = `server_guest_user_id`（拿不到时用 `pending-local-guest` 占位）。这是 v2 修复 v1 双 ID 模糊问题的核心决策。
2. **Review 2 的前提"你给的流程是首次安装先生成 device_id + local_guest_id"是误判**——用户没给过此流程，plan v2 也明确拒绝了 local_guest_id 概念。
3. **复活 local_guest_id 会引入 v1 已经否决的双 ID 问题**：何时把 local_guest_id 数据迁到 server_guest_id（每次启动？每次登录？）会产生反复迁移、idempotency、失败回滚等复杂语义，plan v2 §6.3 的核心目的就是消除这个复杂度。

`pending-local-guest` 占位的语义本身就覆盖了 review 2 想解决的"完全离线启动"场景：

```
启动 → 有网 → /auth/guest → server_guest_id → 本地 DB 全部归属 server_guest_id
启动 → 无网 → 占位 'pending-local-guest' → 本地 DB 临时归属 → 后续启动有网时一次性 UPDATE 替换
```

这个流程是**单 ID 在两种状态间的迁移**，不是"两个 ID 共存"。

### 5.5 LocalDatabase 的双向兼容

由于 LocalDatabase 自身有 `onCreate` 创建 5 张 legacy 表（不带 user_id），需要：

**Option A**：LocalDatabase 的 onCreate 也加 user_id 列（与 drift v13 后的最终 schema 一致），并把 `version: 1` 升级到 `version: 2`。这是更彻底但更复杂的方式。

**Option B**：LocalDatabase 的 onCreate 不动（仍 version=1），让 drift 的 v1→v13 migration 接管所有 schema 变化。LocalDatabase API 的实现内部全改为带 user_id 的 SQL 语句。这是更小的改动，但要确认 fresh install 时 drift 的 createAll 是 truth。

**推荐 Option B**，理由：
- 历史上 v2+ schema 全靠 drift 维护，LocalDatabase.version=1 一直没变过
- LocalDatabase 不再是 schema 维护方，只是个 DAO 层

Phase C1 实施 PR 里明示这个决策。

---

## 6. 与 plan v2 的差异 / 修正

| plan v2 §位置 | 描述 | 本审计修正 |
|---------------|------|-----------|
| §7.1 sqflite v1→v2 | "升级 v1 → v2，5 张表加 user_id" | **修正**：不升级 LocalDatabase 的 version，schema 改动由 drift v13 onUpgrade 统一接管（§5.3 Option B） |
| §7.3 SP keys 表 | 列出 4 类 key | **修正**：补 `auto_backup_last_at_ms`、`mochi_night_mode`、`_enrichment_seed_version` 三个 v2 漏掉的 key（§1.2 / §1.1） |
| §7.2 公共内容层清单 | 11 张内容表 | **确认**：与本审计 §4.3 一致，无差异 |

---

## 7. 实施清单（Phase C 用）

### 7.1 SQL 改动（一次）

drift onUpgrade v12→v13 一段 migration 脚本，对 9 张表（§4.1 + §4.2）做"新表+拷贝+替换"。

### 7.2 Dart 代码改动

| 文件 | 改动 |
|------|------|
| `LocalDatabase` | 全部 method 加 `userId` 参数（不改 schemaVersion） |
| 9 张 user-scoped drift 表的 DAO | 全部 query 加 `where user_id = :uid` |
| `LocalSettingsService` | 改 user-scoped key naming，构造器要求 userId 或新增 `forUser(userId)` 工厂 |
| `LocalProgressRepository` | 同上 |
| `BackupUploadService` | 同上 |
| `AutoBackupService` | 同上 |
| `RoomCanvasStorage` | 同上 |
| `SnapshotExportService` | 导出时按 userId 过滤数据 |
| `BackupRestoreService` | 恢复时只删除 / 替换当前 userId 的行 |
| 所有调用点 | 从 AuthScope 拿 userId 传给上述 service |

### 7.3 启动顺序保证（plan v2 §7.4 强约束）

> ⚠️ **本节描述 Phase C 实施后的目标启动顺序**。当前 [main.dart](../../../apps/mobile/lib/main.dart) **尚未**包含 SharedPreferences/AuthBootstrap/SP namespace migration 步骤。Phase C PR review 时不要把本节当作现状描述。

```
1. SharedPreferences.getInstance()
2. AuthBootstrap.run() → 写 auth_current_user_id（server_guest_id 或 'pending-local-guest'）
3. LocalDatabase.initialize()
4. AppDatabase.initialize() → drift onUpgrade 在这步读 auth_current_user_id
5. SP namespace migration（如未做过）
6. runApp()
```

第 4 步是关键：drift migration 必须能拿到 `auth_current_user_id`，否则全部 backfill 落到 'pending-local-guest'，需要后续二次迁移。

**当前 main.dart 启动流程对照（v1.1 调研）：** 当前没有 AuthBootstrap 概念；现有 init 流程包括 `LocalDatabase.initialize()`、`AppDatabase()` 单例（懒加载）、`enrichment_bootstrap`。Phase C 实施 PR 必须把上述 6 步显式拼起来，不能依赖懒加载的隐式顺序。

---

## 8. 输出

本文档作为 Phase C 实施的 source of truth，PR 描述需 reference 本文件。Phase C1（raw sqflite + drift v13）和 Phase C3（SP key 命名空间）的实现细节按本文档展开。

---

## 9. v1.2 修订记录（2026-05-11，Phase G 收尾）

### 9.1 §1 SP keys 命名空间迁移落地

| Audit §1 子项 | 实施 commit | 文件:行 |
|---------------|-------------|--------|
| §1.1 用户数据 7 个 settings_* keys 改 per-user prefix | `d93279d`（C-β） | `apps/mobile/lib/core/storage/local_settings_service.dart:22` `_k(suffix) => 'u_${_userId}_$suffix'`；7 个 suffix 见 `:24-30`；`migratableKeySuffixes` 列表 `:35-43` |
| §1.2 设备级数据（device_id 等）不动 | `9d992c8`（Phase B） | `auth_storage.dart` 把 device_id 维持设备级（无 user prefix）|
| §1.3 鉴权专用 keys（v1.1 把 token 改到 secure storage） | `9d992c8`（Phase B） | `auth_storage.dart` 把 token 写入 `flutter_secure_storage`，其他 auth keys (`auth_current_user_id` / `auth_pending_*`) 仍 SharedPreferences |
| §2.1 命名约定 `u_<userId>_<suffix>` | `d93279d`（C-β） | 见上 |
| §2.2 迁移时机（SpMigrator） | `d93279d`（C-β） | `apps/mobile/lib/core/auth/sp_migrator.dart` + `auth_pending_sp_migration` flag (`auth_storage.dart:28`) |
| §2.3 退出登录后的访问 | `9d992c8` + `1584440`（C-γ） | logout 不删 SP business keys，但切回 guest 上下文；access via `AuthScope.currentUserIdOf` 自动按当前 user 取值 |

### 9.2 §3-4 移动端两套数据库重叠 + drift v13 落地

| Audit §3-4 子项 | 实施 commit | 详情 |
|----------------|-------------|------|
| §3.3 决策：Option B（LocalDatabase 让出 schema 维护权，drift 接管） | `6d33cbe`（C-α） | LocalDatabase 不再 `_createTables`；drift schemaVersion = 13 (`app_database.dart:119`)|
| §4.1 raw sqflite + drift 共享的 5 张 legacy 表 v13 加 user_id | `6d33cbe`（C-α） | `legacy_tables.dart`：`word_records` / `wordbook_progress` / `daily_checkins` / `custom_wordbooks` / `vocabulary_notebook` 全部 `text().named('user_id')()` NOT NULL |
| §4.2 drift-only 用户行为表 v13 加 user_id | `6d33cbe`（C-α） | `card_states` / `review_logs` / `sessions` / `review_records` 共 4 张 |
| §4.3 公共内容表不加 user_id | n/a（保持原样） | `cached_words` / `examples` / `audio_assets` / `wordbooks` 等 11 张未动 |
| §4.4 总计 20 张表 | `6d33cbe` | 5 + 4 + 11 = 20，已对齐 |
| §5.2 v13 onUpgrade migration 算法（PRAGMA table_info 条件式） | `6d33cbe` | drift onUpgrade 用 `PRAGMA table_info` 检查列是否已存在，避免 fresh install 与升级路径冲突 |
| §5.3 失败处理 | `6d33cbe` + `3ce5ec0` | migration 幂等；PR-C-α tidy 补 backend e2e state-resilience |

### 9.3 §6 与 plan v2 的差异落地

| plan v2 / audit 差异点 | 实施 commit |
|------------------------|-------------|
| `local_guest_id` 双 ID 方案 → **拒绝**（v1.1 §5.4）；单 ID 方案落地 | `9d992c8`（Phase B 实现 server_guest_user_id + 离线占位 `pending-local-guest`） |
| pending-local-guest → server_guest_user_id 同行替换 | `1584440`（C-γ）`pending_guest_migrator.dart` + `auth_pending_local_*_migration` 三个 flag |
| 完全离线启动场景 | `1584440`（C-γ）AuthBootstrap 在无网时返回 `pending-local-guest`，DB 写入仍按当前 currentUserId 路由 |

### 9.4 §7 启动顺序保证（plan v2 §7.4）落地

| 步骤 | 实施 commit | 文件:行 |
|------|-------------|--------|
| 1. SharedPreferences.getInstance() | `9d992c8` | `main.dart` 启动早期 |
| 2. AuthBootstrap.run() → 写 currentUserId | `9d992c8` + `1584440` | `auth_bootstrap.dart` |
| 3. LocalDatabase.initialize() | C-α `6d33cbe` | `main.dart`，在 drift initialize 之前 |
| 4. AppDatabase.initialize() → drift onUpgrade 读 currentUserId | `6d33cbe` | `app_database.dart` v13 onUpgrade |
| 5. SP namespace migration | `d93279d`（C-β） | `SpMigrator.runIfNeeded`，gated on `auth_pending_sp_migration` flag |
| 6. runApp() | 同上 | 完成所有 pre-runApp 工作后 |

测试覆盖：`phase_c_e2e_test.dart:521` "integration — full Phase C handoff" 提供完整启动顺序的端到端用例。

### 9.5 与 PRD §9 验收的对应

| audit 项 | PRD §9 验收对应 |
|----------|---------------|
| §1.1 settings_* per-user prefix | §9.2 用户设置隔离 5 项 |
| §4.1-4.2 drift v13 user_id partition | §9.3 学习数据隔离 + §9.4 FSRS 隔离 |
| §5 v13 migration | §9.5 游客绑定（id 稳定 → backfill 后行不需迁移）|
| §6 单 ID 决策 + pending-local-guest | §9.5-2~5（绑定不丢数据）+ §9.6 退出/切换 |
| §7 启动顺序 | §9.6 (App 各页面不显示 A 数据 = 全部 init 步骤都在 currentUserId 已绑定后) |
