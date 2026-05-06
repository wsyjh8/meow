# v0.3 PR-B3 · Day 2 plan v0.1 — feature flag + WordbookLoader D1 收口（mobile only）

## Context

PR-B3 Day 1 已 merge 到分支 `feat/v0.3-pr-b3-feature-flag-wire-up` @ `5e7313c`：
server staging serve route + manifest URL transform。Day 2 转 mobile：

- **D1 收口**：app 升级时 `WordbookLoader._clearContentTables()` 会无脑
  `DELETE FROM example_sentences` —— 把 PR-B2 ContentPackageService 写入的
  manifest 数据一并干掉。修法是**当本地有 manifest 装过 examples 包时跳过
  example_sentences 的清表**，其它 3 张 bundle-only 表照旧清。
- **feature flag**：在 `LocalSettingsService` 加 `manifestSyncEnabled` getter /
  setter（默认 false）。Day 3 才把 flag 接到 `main.dart` 启动 hook + 设置页
  开关；Day 2 只做存储层。

工作分支：`feat/v0.3-pr-b3-feature-flag-wire-up` @ `5e7313c`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b3`
对照基线 commit：`7058387`（PR-B2 merge 点）

## 严格范围

仅改 mobile 端（无 server / pipeline / migration 改动）。**1 天预算**。

### 不做（明示边界）

- ❌ `main.dart` 启动 sync hook（Day 3）
- ❌ 设置页 debug 开关 UI（Day 3）
- ❌ `LocalSettingsService` 顶层 InheritedWidget DI scaffolding（Day 3）
- ❌ Sub-smokes A-E 真机走（Day 3）
- ❌ README / PR_DESCRIPTION（Day 3）
- ❌ server / pipeline.py / migration / cdn-mock / audio-pipeline-staging
- ❌ 改 `ContentPackageService` / `PackageInstaller`（PR-B2 已稳定，不动）

## 核实事实（recon 后，v0.2 #15 review-adopted）

### `LocalSettingsService` 现状

文件：`apps/mobile/lib/core/storage/local_settings_service.dart`（**注意路径
是 core/storage/，不是 core/services/**——v0.2 #3 修订）

- 行 1：`import 'package:shared_preferences/shared_preferences.dart';`
- 行 9-12：构造接收 `SharedPreferences` 实例，无别的依赖
- 行 14-20：6 个既有 key（dailyGoal / soundEnabled / theme / notificationTime /
  desiredRetention / activeWordbook）
- 行 22-54：每个字段 getter + setter 配对，全部是同步 getter / `Future<bool>`
  setter，return prefs.setX 的结果
- 行 56-57：`clearAll()` 用于 testing
- pubspec 已含 `shared_preferences: ^2.2.0`（无新依赖）

### `WordbookLoader` 现状（line numbers）

文件：`apps/mobile/lib/core/memory/wordbook_loader.dart`

- 行 47 入口：`Future<int> loadIfNeeded(String bookSlug) async`
- 行 53-64：版本对比 + integrity backstop；版本相同 + 完整性 ok 则返 0
- 行 68-70：版本不同 / integrity 失败 → 调 `_clearContentTables()` + `_loadFromData()`
- 行 88-94：`_storedContentVersion(bookSlug)` 查 `preset_wordbooks.content_version`
- **行 99-104：`_clearContentTables()` —— D1 收口的关键修改点**
  ```dart
  Future<void> _clearContentTables() async {
    await _db.customStatement('DELETE FROM example_sentences');     // ← 改
    await _db.customStatement('DELETE FROM word_book_assignments'); // bundle only
    await _db.customStatement('DELETE FROM word_entries');          // bundle only
    await _db.customStatement('DELETE FROM preset_wordbooks');      // bundle only
  }
  ```
- 行 106-203：`_loadFromData()` — 走 InsertOrIgnore，`(word_id, sort_order)`
  唯一索引保证幂等。manifest 已写的行因 `(word_id, sort_order)` 与 bundle 行
  不冲突（manifest 走 stable_id 主键，bundle 走 sort_order 唯一）保留；万一
  冲突 InsertOrIgnore 也是保留 manifest 行（因为 manifest 在前）。

### `content_package_state` 表 schema

文件：`apps/mobile/lib/core/storage/drift/tables/content_package_state.dart`

- 12 列；主键 `packageId`
- `package_kind` 列（行 26）：`"examples" / "audio_meta" / "wordbook" / "dictionary"`
- D1 收口判断条件：`SELECT 1 FROM content_package_state WHERE package_kind='examples' LIMIT 1`
- PR-B2 PackageInstaller 仅装 examples 包；其它 kind 在
  `ContentPackageService` kind 过滤层就被 skip 掉，不会写表（PR-B2 #5
  review-adopted）

### 既有 SharedPreferences 测试模式

`apps/mobile/test/p31_delta_phase1_daily_goal_test.dart:12-17` 已有标准模式：
```dart
late LocalSettingsService settings;
SharedPreferences.setMockInitialValues({});
final prefs = await SharedPreferences.getInstance();
settings = LocalSettingsService(prefs);
```

### `main.dart` 现状（仅 confirm，Day 2 不动）

`apps/mobile/lib/main.dart:1` 已 `import 'dart:async';`（Day 3 用 `unawaited()`
免新增 import；v0.2 #5 修订）。Day 2 完全不动 main.dart。

## 实施

### Step 1：`LocalSettingsService` 加 manifestSyncEnabled（~8 行）

文件：`apps/mobile/lib/core/storage/local_settings_service.dart`

在行 20 末尾加 key、行 54 末尾加 getter/setter：

```dart
// 加在 _keyActiveWordbook 之后
static const _keyManifestSyncEnabled = 'settings_manifest_sync_enabled';

// ==================== Manifest Sync (PR-B3) ====================
/// PR-B3 feature flag — when true, app fires async manifest sync on
/// startup (Day 3 wires it into main.dart). Default false until rollout
/// is gated by the user from the debug settings page (Day 3).
///
/// Failure of sync NEVER blocks UI; flag exists purely to gate the
/// fire-and-forget call in main.dart.
bool get manifestSyncEnabled =>
    _prefs.getBool(_keyManifestSyncEnabled) ?? false;
Future<bool> setManifestSyncEnabled(bool value) =>
    _prefs.setBool(_keyManifestSyncEnabled, value);
```

**契约**：
- 默认值 false（与 PR-B2 merge 之前的行为完全一致）
- 类型 `bool`（不是 nullable；缺失即视为 false）
- key 命名沿用 `settings_<name>` 风格（与 dailyGoal / soundEnabled 等一致）

### Step 2：`WordbookLoader` D1 收口（~25 行）

文件：`apps/mobile/lib/core/memory/wordbook_loader.dart`

#### 2a. 加 `_hasManifestExamples()` 私有方法

放在 `_exampleSentencesIntegrityOk()`（行 77-86）之后：

```dart
/// PR-B3 D1 收口: 当 content_package_state 含 package_kind='examples' 行
/// 时，说明本地 example_sentences 至少部分由 manifest 写入，bundle clear
/// 时不能无脑 DELETE，否则会丢 manifest 数据。
///
/// 判断条件最低成本: LIMIT 1。不在乎几个 examples 包，只要 ≥1。
/// 其它 3 张 bundle-only 表（preset_wordbooks / word_entries /
/// word_book_assignments）当前 manifest 不写，仍可清。
Future<bool> _hasManifestExamples() async {
  final row = await _db
      .customSelect(
          "SELECT 1 AS hit FROM content_package_state "
          "WHERE package_kind = 'examples' LIMIT 1")
      .getSingleOrNull();
  return row != null;
}
```

#### 2b. 修改 `_clearContentTables()`（行 99-104）

```dart
/// Drop and recreate bundle-derived content-layer tables.
///
/// Called when a version mismatch is detected — safe for the 3 bundle-only
/// tables because their data is reloaded from bundled assets.
///
/// **PR-B3 D1 收口**: example_sentences MAY contain manifest-installed
/// rows (PR-B2 ContentPackageService writes them via stable_id-keyed
/// InsertOrReplace). When the local DB has at least one
/// content_package_state row with package_kind='examples', we SKIP the
/// example_sentences clear. The subsequent _loadFromData() reimport uses
/// InsertOrIgnore on (word_id, sort_order) which is conflict-safe with
/// pre-existing manifest rows (different stable_id keys; same
/// (word_id, sort_order) collisions are resolved in favor of the
/// already-present manifest row).
Future<void> _clearContentTables() async {
  if (await _hasManifestExamples()) {
    // ignore: avoid_print
    print('[WordbookLoader] manifest examples present; '
          'skipping example_sentences clear (PR-B3 D1 收口).');
  } else {
    await _db.customStatement('DELETE FROM example_sentences');
  }
  await _db.customStatement('DELETE FROM word_book_assignments');
  await _db.customStatement('DELETE FROM word_entries');
  await _db.customStatement('DELETE FROM preset_wordbooks');
}
```

**关键不变量**：
- 没装过 manifest（`content_package_state` 为空 / 无 examples kind）→ 行为
  完全等同 PR-B2 之前（4 张表全清，bundle 重导）
- 装过 manifest examples → example_sentences 不清；其它 3 张表正常清；
  `_loadFromData` 用 InsertOrIgnore 重导 bundle 行不会覆盖已有 manifest 行
- ContentPackageService kind 过滤保证 `audio_meta` / `wordbook` 等不会写
  `content_package_state`（PR-B2 R1#5 review-adopted），所以 `_hasManifestExamples`
  只可能因真有 examples 包返 true

### Step 3：单元测试（5 cases，~180 行）

#### 3a. `test/core/storage/local_settings_service_test.dart`（新建，3 cases）

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meow_mobile/core/storage/local_settings_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalSettingsService.manifestSyncEnabled (PR-B3 Day 2)', () {
    test('default false', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(LocalSettingsService(prefs).manifestSyncEnabled, isFalse);
    });

    test('set true persists across reload', () async {
      final prefs = await SharedPreferences.getInstance();
      await LocalSettingsService(prefs).setManifestSyncEnabled(true);
      final reloaded = LocalSettingsService(prefs);
      expect(reloaded.manifestSyncEnabled, isTrue);
    });

    test('set false then read returns false', () async {
      SharedPreferences.setMockInitialValues({
        'settings_manifest_sync_enabled': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await LocalSettingsService(prefs).setManifestSyncEnabled(false);
      expect(LocalSettingsService(prefs).manifestSyncEnabled, isFalse);
    });
  });
}
```

#### 3b. `test/core/memory/wordbook_loader_test.dart`（新建，2 cases）

**关键 case** D1: bundle v3 + manifest 写入 → bundle 升 v4 → manifest 数据保留

```dart
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/memory/wordbook_loader.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  /// Mock rootBundle 的方式: 用 ServicesBinding 的 defaultBinaryMessenger
  /// 拦截 'flutter/assets' channel。最小可用模板:
  void mockBundleAsset(String path, String json) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == path) {
        return ByteData.view(utf8.encode(json).buffer);
      }
      return null;
    });
  }

  group('WordbookLoader._clearContentTables D1 收口 (PR-B3)', () {
    test(
        'manifest examples present: example_sentences NOT cleared on bundle upgrade',
        () async {
      // 1. 模拟 bundle v3 已加载（preset_wordbooks v3 + 1 example row）
      await db.into(db.presetWordbooks).insert(
            PresetWordbooksCompanion.insert(
              slug: 'zk',
              displayName: '中考',
              contentVersion: const Value('v3'),
            ),
          );
      // bundle row：没有 stable_id，sort_order=0
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'apple',
              sense: 'noun',
              en: 'BUNDLE old example',
              cn: '旧例句',
              sortOrder: const Value(0),
              stableId: const Value.absent(),
            ),
          );

      // 2. 模拟 PackageInstaller 写 manifest examples 包 +
      //    insert 一个 stable_id='manifest-row' 的 example
      await db.into(db.contentPackageStates).insert(
            ContentPackageStatesCompanion.insert(
              packageId: 'examples-zk@v1',
              packageName: 'examples-zk',
              packageKind: 'examples',
              contentVersion: 'v1',
              releaseId: 'rel-1',
              checksumSha256: 'h',
              installedAt: 1,
            ),
          );
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'apple',
              sense: 'noun',
              en: 'MANIFEST example',
              cn: '清单例句',
              sortOrder: const Value(1),
              stableId: const Value('manifest-row'),
            ),
          );

      // 3. 模拟 bundle v4 升级（assets/words/zk.json 改 contentVersion='v4'）
      mockBundleAsset(
        'assets/words/zk.json',
        '{"displayName":"中考","contentVersion":"v4","words":['
        '{"wordId":"apple","wordText":"apple","meaning":"noun apple",'
        '"sortOrder":0,"examples":[{"sense":"noun","en":"V4 BUNDLE",'
        '"cn":"v4 例句","sortOrder":0,"stableId":"v4-bundle"}]}]}',
      );

      // 4. 调 loadIfNeeded → 触发 _clearContentTables
      await WordbookLoader(db: db).loadIfNeeded('zk');

      // 5. assert: example_sentences 仍含 stable_id='manifest-row'
      final rows = await db.select(db.exampleSentences).get();
      final stableIds = rows.map((r) => r.stableId).toSet();
      expect(stableIds, contains('manifest-row'),
          reason: 'manifest-installed row must NOT be cleared (D1 收口)');

      // bundle v4 行也应被 InsertOrIgnore 加入（sort_order=0 vs sort_order=1
      // 不冲突，stable_id 不同）
      expect(stableIds, contains('v4-bundle'));

      // preset_wordbooks 应被清并写入 v4
      final pw = await db.select(db.presetWordbooks).get();
      expect(pw.single.contentVersion, 'v4');
    });

    test(
        'no manifest data: classic clear-and-reload (PR-B2 之前行为不变)',
        () async {
      // 1. bundle v3 状态
      await db.into(db.presetWordbooks).insert(
            PresetWordbooksCompanion.insert(
              slug: 'zk',
              displayName: '中考',
              contentVersion: const Value('v3'),
            ),
          );
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'apple',
              sense: 'noun',
              en: 'V3 BUNDLE',
              cn: 'v3 例句',
              sortOrder: const Value(0),
              stableId: const Value('v3-bundle'),
            ),
          );

      // 2. content_package_state 为空（无 manifest 装过）
      expect(await db.select(db.contentPackageStates).get(), isEmpty);

      // 3. bundle v4
      mockBundleAsset(
        'assets/words/zk.json',
        '{"displayName":"中考","contentVersion":"v4","words":['
        '{"wordId":"apple","wordText":"apple","meaning":"noun",'
        '"sortOrder":0,"examples":[{"sense":"noun","en":"V4 BUNDLE",'
        '"cn":"v4","sortOrder":0,"stableId":"v4-bundle"}]}]}',
      );

      // 4. loadIfNeeded
      await WordbookLoader(db: db).loadIfNeeded('zk');

      // 5. v3 row 已清；只剩 v4 row
      final rows = await db.select(db.exampleSentences).get();
      expect(rows, hasLength(1));
      expect(rows.first.stableId, 'v4-bundle');
    });
  });
}
```

**降级**（master plan §345 修订风险条目，**只在时间紧时启用**）：
- LocalSettingsService 3 cases → 2（保 default + persist）
- WordbookLoader 2 cases → 1（只保 D1 关键 case）
- 不可少于上面 1+1 = 2 cases，否则 D1 收口无单测覆盖

## 关键文件

### 修改
- `apps/mobile/lib/core/storage/local_settings_service.dart`
  （+10 行：1 个 key + getter + setter + dartdoc）
- `apps/mobile/lib/core/memory/wordbook_loader.dart`
  （+30 行：`_hasManifestExamples()` + 改 `_clearContentTables()` + dartdoc）

### 新建
- `apps/mobile/test/core/storage/local_settings_service_test.dart`（3 cases ~50 行）
- `apps/mobile/test/core/memory/wordbook_loader_test.dart`（2 cases ~150 行）

### 不动
- `apps/mobile/lib/main.dart`（Day 3 才接 startup hook）
- `apps/mobile/lib/features/settings/`（Day 3 才加 debug 开关 UI）
- `apps/mobile/lib/app/`（Day 3 才加 InheritedWidget DI）
- `apps/mobile/lib/core/manifest/`（PR-B2 已稳定）
- `apps/mobile/lib/core/storage/drift/`（PR-B2 schema 已稳定）
- `apps/mobile/pubspec.yaml`（零新依赖）
- 任何 server / pipeline / migration 代码

## 验证

### 1. flutter analyze 0 error in 修改/新增文件

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b3\apps\mobile
flutter analyze lib/core/storage/local_settings_service.dart `
                lib/core/memory/wordbook_loader.dart `
                test/core/storage/local_settings_service_test.dart `
                test/core/memory/wordbook_loader_test.dart
# 期望: 'No issues found!'
```

### 2. flutter test 新增 cases 全过 + baseline 保持

```powershell
flutter test test/core/storage/local_settings_service_test.dart
# 期望: All tests passed (3 cases)

flutter test test/core/memory/wordbook_loader_test.dart
# 期望: All tests passed (2 cases)

# baseline regression
flutter test
# 期望: baseline 失败数不增加（PR-B2 merge 时 baseline 6 失败；保持 ≤6）
```

### 3. 改动行数 vs PR-B2 merge 基线

```powershell
git diff 7058387 -- apps/mobile/lib/core/storage/local_settings_service.dart | wc -l
# 期望: ~25 行（10 业务 + diff 元数据）

git diff 7058387 -- apps/mobile/lib/core/memory/wordbook_loader.dart | wc -l
# 期望: ~50 行（30 业务 + diff 元数据）

# server / pipeline / migration / main.dart / settings UI 零改动
git diff 7058387 -- apps/api/ apps/mobile/lib/main.dart `
                    apps/mobile/lib/features/settings/ `
                    apps/mobile/lib/app/ `
                    apps/api/scripts/ | wc -l
# 期望: 0
# (注: Day 1 commit 已改 apps/api/，但当前 worktree HEAD 已包含 Day 1；
#  Day 2 commit 不应再动 server)
```

## 验收清单

- [ ] `LocalSettingsService.manifestSyncEnabled` getter / setter 实装
- [ ] 默认值 false（PR-B2 之前行为不变）
- [ ] key 命名 `settings_manifest_sync_enabled`（沿用 `settings_<name>` 风格）
- [ ] `WordbookLoader._hasManifestExamples()` 私有方法实装
- [ ] `_clearContentTables()` 在 `_hasManifestExamples=true` 时跳过
      `example_sentences` 清表，其它 3 张照旧
- [ ] **D1 关键 case** 单测过：bundle v3 + manifest row → bundle v4 升级 →
      manifest row 仍在 example_sentences
- [ ] regression case 单测过：无 manifest → 4 张表全清（PR-B2 之前行为）
- [ ] LocalSettingsService 3 cases 全过
- [ ] flutter analyze 0 error in 修改 / 新增 4 个文件
- [ ] flutter test baseline 失败数不增加
- [ ] main.dart / settings UI / app/ / server / pipeline 零改动（grep 验证）

## 风险

| 风险 | 缓解 |
|---|---|
| `_hasManifestExamples()` 多查一次 SQL → 启动慢 | 1 行 SELECT LIMIT 1，<1ms；启动序列已是 ms 级，可忽略 |
| `content_package_state` 表在 fresh install 不存在 | PR-B2 已加 `_safeCreateTable` migration（drift v12）；`AppDatabase()` 启动时 `onUpgrade` 跑 migration，不会出现"表不存在" |
| InsertOrIgnore on (word_id, sort_order) 与 manifest 行冲突 | 当前 manifest 走 stable_id 主键 InsertOrReplace；bundle 走 sort_order 唯一；不同 (word_id, sort_order) 不冲突。同冲突场景下保留先到的 manifest 行（InsertOrIgnore 语义）—— D1 关键 case 覆盖 |
| `assets/words/zk.json` 真实结构与测试 mock 不一致 | recon 已确认（§"WordbookLoader 现状"行 108-198）；JSON 字段名稳定；mock 用最小可用 schema |
| 测试用 `setMockMessageHandler('flutter/assets')` 拦 rootBundle 写法不稳 | 仓内 `migration_test.dart` / `e2e_self_check_test.dart` 已有同样模式；Day 2 沿用 |
| Day 2 工作量超 1 天 | 改动 ~40 行 + 测试 ~200 行；预期 ≤ 4 小时；超时降级单测从 5 → 3 cases（master plan §345 修订）|
| WordbookLoader 改动破坏既有调用方 | 仅新增私有方法 + 改 _clearContentTables 内部分支；公共 API（`loadIfNeeded`）签名/语义不变；regression case 兜底 |

## 评审 pre-set（猜可能被提的）

1. **为什么不一并改 word_entries / word_book_assignments / preset_wordbooks 的清表？**
   ✅ PR-B2 PackageInstaller kind 过滤只允许 'examples'；其它 kind 不会写
   `content_package_state`，3 张 bundle-only 表当前没有 manifest 数据可保护。
   如未来扩 wordbook kind，再按当前模板加 `_hasManifestWordbooks()` 类似判断。

2. **`_hasManifestExamples()` 用 raw SQL 而不是 drift 类型化 query？**
   🟡 一致性优先：`WordbookLoader` 现有 `_storedContentVersion` /
   `_exampleSentencesIntegrityOk` 都用 `customSelect`；新增方法风格保持一致。
   类型化 query 收益小（`SELECT 1 LIMIT 1` 不读列）。

3. **flag 默认 false 的 risk：用户更新到 PR-B3 后 D1 收口逻辑也不触发？**
   ✅ flag 控制的是 Day 3 startup sync hook（拉新数据写表）；
   `_clearContentTables` D1 收口逻辑无条件跑（不查 flag）—— 老用户即使 flag=false
   也能从 D1 收口受益（虽然他们 content_package_state 也是空，所以行为不变；
   一致性 OK）。

4. **`_hasManifestExamples` 在 mock 数据库下能跑吗？**
   ✅ PR-B2 已用 `AppDatabase.forTesting(NativeDatabase.memory())` 启动
   `content_package_states` 表；测试 setUp 后表存在。

5. **同 (word_id, sort_order) 冲突时优先保留哪个？**
   ✅ InsertOrIgnore 语义：if exists then no-op，不会更新已有行。manifest 行
   先存在 → bundle reimport 同 (word_id, sort_order) 被 ignore。如果业务上
   需要 bundle 优先（罕见，因为 manifest 是 server-side 增量），future PR 可
   改 PackageInstaller 的写入策略；不在 Day 2 范围。

## 不做

- ❌ `main.dart` 接 startup sync hook（Day 3）
- ❌ 设置页 SwitchListTile UI（Day 3）
- ❌ MeowApp 顶层 InheritedWidget DI scaffolding（Day 3，master plan §150-156）
- ❌ Sub-smoke A-E 真机验证（Day 3）
- ❌ `LocalSettingsService` 暴露给非 service 层调用（Day 3 通过 InheritedWidget）
- ❌ 改 `PackageInstaller` 写入策略（PR-B2 稳定，不动）
- ❌ 改 `ContentPackageService` kind 过滤（PR-B2 稳定，不动）

## 提交策略

Day 2 完成后单 commit：

```
feat(v0.3-pr-b3): Day 2 — feature flag + WordbookLoader D1 收口 (mobile only)

D1 收口: app 升级时 WordbookLoader._clearContentTables 不再无脑清
example_sentences；当 content_package_state 含 examples 行时跳过该清表，
保住 PR-B2 ContentPackageService 写入的 manifest 数据。

LocalSettingsService:
- 加 manifestSyncEnabled getter / setter (key settings_manifest_sync_enabled)
- 默认 false (PR-B2 之前行为不变)
- Day 3 才把 flag 接入 main.dart startup hook

WordbookLoader:
- 加 _hasManifestExamples() 私有方法 (SELECT 1 FROM content_package_state
  WHERE package_kind='examples' LIMIT 1)
- _clearContentTables() 在 _hasManifestExamples=true 时跳过 example_sentences
  清表，其它 3 张表 (preset_wordbooks / word_entries / word_book_assignments)
  照旧清
- 公共 API loadIfNeeded 签名 / 语义不变

测试 (5 cases):
- LocalSettingsService 3 cases (default false / set true persists / set false)
- WordbookLoader 2 cases (D1 关键 + 无 manifest regression)

零 main.dart / settings UI / app/ / server / pipeline / migration 改动。
flutter analyze 0 error；flutter test baseline 不退化。
```

## 评审节奏

Plan 推 push 后让 codex 拉到 → 外部 AI 评审 → 吸收意见出 v0.2 → 实装 commit 2。
（沿用 PR-B1 / PR-B2 / PR-B3 Day 1 模式）
