# v0.3 PR-B3 · Day 2 plan v0.2 — feature flag + WordbookLoader D1 收口（mobile only）

> **v0.1 → v0.2**：吸收两份外部评审共 14 处去重修订。**根本性修订**：D1 收口策略
> 从 v0.1 的"整表跳过清表"改为"按 bookSlug 过滤 + 仅清 legacy null stable_id
> 行 + 接受 bundle examples 升级被 manifest 接管后屏蔽（v0.4 scope §1.3 隐含限制，
> 显式记录）"。WordbookLoader 加 `assetLoader` DI 参数替换仓内首次的 mock channel
> 路径。测试 fixture 全调（旧 bundle 行 stable_id 非 null + v4 用不冲突 sortOrder）。

## v0.1 → v0.2 修订（14 处去重）

### 🔴 P0 必修（开工前）

| # | 来源 | 问题 | 修订 |
|---|---|---|---|
| 1 | R1#1 + R2#P1.1 | D1 测试 `expect 'v4-bundle'` 在 `(wordId, sortOrder)` unique + InsertOrIgnore 下不可能为真；策略整表跳过清表会挡住 bundle 升级 | **策略重新设计**（详见 §"D1 收口策略 v0.2"）：本 book 有 manifest → 仅清 `stable_id IS NULL` 的 legacy 行（不动 stable_id 非 null 的 bundle/manifest 行）；接受 bundle examples 升级被屏蔽，文档显式写出 |
| 2 | R1#2 | `setMockMessageHandler('flutter/assets')` 仓内首次使用，plan 写"已有同模式"是错的（grep 0 处） | **方案 A**：WordbookLoader 加 `assetLoader: Future<String> Function(String)?` named optional 参数，default 走 `rootBundle.loadString`；测试注入 fake loader。公共 API `loadIfNeeded(slug)` 不传新参数时行为不变 |
| 3 | R2#P1.2 | `_hasManifestExamples()` 全库判断粒度过粗 → 装过 examples-zk 后 book-001 / gk 升级也跳过清表 | 改 `_hasManifestExamplesForBook(bookSlug)`，按 `package_name = _packageNameForBookSlug(bookSlug)` 过滤；单独维护 bookSlug → packageName 映射（`book-001 → examples-cet4`，其它 `examples-${slug}`） |
| 4 | R2#P1.3 | 旧的 NULL stable_id 行触发 integrity backstop 重导 → D1 收口又跳过清表 → 永远 NULL → 无限循环 | 即使本 book 有 manifest，**也清掉 `stable_id IS NULL` 的 legacy 行**（这些是 v0.3 P0 之前的 bundle 行，本就该清）。这样 integrity 检查通过，下次启动版本 match 直接 0 退出 |

### 🟡 P1 应修

| # | 来源 | 修订 |
|---|---|---|
| 5 | R1#3 | §66-70 / §188 双 unique index 描述改准：`(wordId, sortOrder)` 和 `stableId` **两个 unique index 同时生效，任一冲突都触发 InsertOrIgnore no-op**（不是"两个维度不同所以不冲突"） |
| 6 | R1#4 | `print(...) + // ignore: avoid_print` 改 `debugPrint(...)`（release build 自动 no-op，不污染 logcat） |
| 7 | R1#5 | §510 "PR-B2 已用 `AppDatabase.forTesting` 启动 `content_package_states` 表" 改 "PR-B2 已加 v12 schema 含 content_package_states 表；in-memory db 启动走 `onCreate` 直接生成 v12，表存在"（不是 onUpgrade migration 路径） |
| 8 | R1#6 | 验收清单加 "Day 2 commit 后 manifestSyncEnabled 字段实装但仅 LocalSettingsService 测试访问；Day 3 commit 接 main.dart 启动 hook + settings page 开关" 显式说明（避免 reviewer 疑惑 flag 死代码） |
| 9 | R2#P2.1 | wordbook_loader_test.dart 测试模板加 `import 'dart:convert';` (gzip / utf8 用 dart:io+dart:convert，sortOrder 改后不再需要 mock channel 但 v0.2 测试仍可能用 utf8.encode；保险加上) |

### 🟢 Nit

| # | 来源 | 修订 |
|---|---|---|
| 10 | R1#7 | 行号引用 "68-70" 改 "67-71"（68 条件 / 69 清表调用 / 70 重导 / 71 close brace） |
| 11 | R1#8 | 方案 A 已不用 mock channel 了；本条不再适用，仅保留注：未来如需测试 mock asset 加载，把 helper 抽 `apps/mobile/test/helpers/` |
| 12 | R1#9 + R2#P2.2 | git diff 验证：基线从 `7058387`（PR-B2 merge）改 **`5e7313c`**（PR-B3 Day 1 commit）；path 列表加 `apps/mobile/lib/core/manifest/` + `apps/mobile/lib/core/storage/drift/` |
| 13 | R1#10 | master plan §300 `core/services/local_settings_service.dart` → `core/storage/`（Day 4 README 收尾时一并改；Day 2 本身不动 master plan） |
| 14 | (Day 2 本身) | "评审 pre-set #5"（onCreate vs onUpgrade）已并入 #7；"#3 双 unique index"已并入 #5；本表与正文交叉引用清晰 |

## D1 收口策略 v0.2（关键设计变更）

### 问题（v0.1 缺陷）

v0.1 plan 的 `_clearContentTables()` 修订：
```dart
if (await _hasManifestExamples()) {
  // 跳过 example_sentences clear
} else {
  await _db.customStatement('DELETE FROM example_sentences');
}
```

3 个根本缺陷：

1. **bundle 升级被屏蔽且无文档说明**：跳过整表清 → 旧 bundle 行（无论 stable_id
   有没有）残留。`_loadFromData(v4)` 的 InsertOrIgnore 命中
   `(wordId, sortOrder)` 或 `stableId` 任一 unique index 即 no-op，新 bundle 行写不进。
2. **粒度过粗（跨 book 误伤）**：判断条件 `WHERE package_kind='examples' LIMIT 1`
   是全库的——装过 examples-zk 后，book-001 / gk 升级也跳过清表，即使这些 book
   完全没有 manifest 数据。
3. **integrity backstop 死循环**：legacy null stable_id 行（v0.3 P0 之前的 bundle 行）
   留下 → integrity check 失败 → 强制 reimport → 又跳过清表 → null 永远在 →
   每次启动都 reimport，浪费时间。

### 解法（v0.2）

```dart
/// PR-B3 D1 收口 v0.2：按 bookSlug 过滤 + 仅清 legacy null stable_id 行。
///
/// 三个维度：
/// 1. _hasManifestExamplesForBook(bookSlug) — 仅当本 book 真有 manifest examples
///    包时触发 D1 收口分支；其它 book 升级走 PR-B2 之前行为（4 张表全清）。
/// 2. example_sentences 仍清 stable_id IS NULL 的 legacy 行 — 这些是 v0.3 P0
///    之前的 bundle 行，本就该清，不清会触发 integrity backstop 死循环。
/// 3. example_sentences stable_id 非 null 的行（manifest 写的 + bundle v3+ 写的）
///    都保留 — 这是 D1 收口的核心目标。
///
/// **副作用（v0.4 scope §1.3 隐含限制，显式记录 R1#1 review-adopted）**：
/// 本 book 有 manifest 介入后，bundle examples 升级被屏蔽 — bundle v4 用同
/// (wordId, sortOrder) 写入会被 InsertOrIgnore 挡，同 stableId 重写也会被
/// stableId unique index 挡。bundle examples 内容更新走 manifest 推包，不走
/// app 升级 + bundle JSON 替换。这是与 PR-B 系列把 examples 内容主权转给
/// server 一致的设计选择。
Future<void> _clearContentTables(String bookSlug) async {
  // 1. 三张 bundle-only 表照旧清（manifest 不写这些）
  await _db.customStatement('DELETE FROM word_book_assignments');
  await _db.customStatement('DELETE FROM word_entries');
  await _db.customStatement('DELETE FROM preset_wordbooks');

  // 2. example_sentences: 按本 book 是否有 manifest 决定清表粒度
  if (await _hasManifestExamplesForBook(bookSlug)) {
    debugPrint('[WordbookLoader] $bookSlug has manifest examples; '
               'preserving non-null stable_id rows (PR-B3 D1 收口). '
               'Bundle examples upgrades for this book are now manifest-driven.');
    // 仅清 legacy null stable_id 行（避免 integrity backstop 死循环）
    await _db.customStatement(
      'DELETE FROM example_sentences WHERE stable_id IS NULL'
    );
  } else {
    // 无 manifest 介入：行为完全等同 PR-B2 之前
    await _db.customStatement('DELETE FROM example_sentences');
  }
}

/// bookSlug → manifest packageName 映射。bookSlug 'book-001' 在 server 端
/// 对应 packageName 'examples-cet4' (server controller deriveBookId 行 79
/// 给 examples-cet4 的 book_id = 'cet4')。其它 bookSlug 直接前缀。
String _packageNameForBookSlug(String bookSlug) {
  if (bookSlug == 'book-001') return 'examples-cet4';
  return 'examples-$bookSlug';
}

/// PR-B3 D1 收口 v0.2: per-book manifest existence check.
/// 解决 v0.1 全库判断的跨 book 误伤问题（R2#P1.2 review-adopted）。
Future<bool> _hasManifestExamplesForBook(String bookSlug) async {
  final pkgName = _packageNameForBookSlug(bookSlug);
  final row = await _db.customSelect(
    "SELECT 1 AS hit FROM content_package_state "
    "WHERE package_kind = 'examples' AND package_name = ? LIMIT 1",
    variables: [Variable.withString(pkgName)],
  ).getSingleOrNull();
  return row != null;
}
```

### `_clearContentTables` 签名变化

v0.1：`Future<void> _clearContentTables() async` （无参）
v0.2：`Future<void> _clearContentTables(String bookSlug) async` （加 bookSlug）

调用点（行 69）一起改：
```dart
// v0.2 (line 69)
if (storedVersion != null) {
  await _clearContentTables(bookSlug);  // ← 加 bookSlug
}
```

公共 API `loadIfNeeded(String bookSlug)` 签名 / 语义 / 返回值都不变。

## Context（与 v0.1 一致）

PR-B3 Day 1 已 merge 到分支 `feat/v0.3-pr-b3-feature-flag-wire-up` @ `5e7313c`：
server staging serve route + manifest URL transform。Day 2 转 mobile：

- **D1 收口**：app 升级时 `WordbookLoader._clearContentTables()` 不再无脑
  `DELETE FROM example_sentences`；按 bookSlug 过滤 + 仅清 legacy null
  stable_id 行（详见上 §"D1 收口策略 v0.2"）。
- **feature flag**：`LocalSettingsService` 加 `manifestSyncEnabled` getter /
  setter（默认 false）。Day 3 才把 flag 接到 `main.dart` 启动 hook + 设置页
  开关；Day 2 只做存储层。

工作分支：`feat/v0.3-pr-b3-feature-flag-wire-up` @ `5e7313c`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b3`
对照基线 commit：`5e7313c`（PR-B3 Day 1 commit；v0.2 #12 修订）

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
- 行 9-12：构造接收 `SharedPreferences` 实例
- 行 14-20：6 个既有 key
- 行 22-54：每个字段 getter + setter；同步 getter / `Future<bool>` setter
- 行 56-57：`clearAll()` for testing
- pubspec 已含 `shared_preferences: ^2.2.0`（无新依赖）

### `WordbookLoader` 现状（行号 v0.2 校准，#10 修订）

文件：`apps/mobile/lib/core/memory/wordbook_loader.dart`

- 行 47 入口：`Future<int> loadIfNeeded(String bookSlug) async`
- 行 53-64：版本对比 + integrity backstop
- 行 67-71：版本不同 / integrity 失败 → `_clearContentTables() + _loadFromData()`
  - 行 68: `if (storedVersion != null) {`
  - 行 69: `await _clearContentTables();` ← v0.2 改 `_clearContentTables(bookSlug)`
  - 行 70: `}`
  - 行 71: `return _loadFromData(bookSlug, data);`
- 行 88-94：`_storedContentVersion(bookSlug)`
- **行 99-104：`_clearContentTables()` —— v0.2 重写为 §"D1 收口策略 v0.2" 形态**
- 行 106-203：`_loadFromData()` — InsertOrIgnore；**双 unique index** `(wordId, sortOrder)`
  和 `stableId` 同时生效，任一冲突都触发 no-op（v0.2 #5 修订）

### `content_package_state` 表 schema

文件：`apps/mobile/lib/core/storage/drift/tables/content_package_state.dart`
- 12 列；主键 `packageId`
- D1 收口判断用 `package_kind='examples' AND package_name='examples-${...}'`
  （v0.2 #3 改按 packageName 而非全库）
- in-memory test 启动走 `onCreate` 直接生成 v12 schema（v0.2 #7 修订；不是
  `onUpgrade` migration 路径）

### server-side `book_id` 命名（v0.2 #3 关键 recon）

`apps/api/src/controllers/content-manifest.controller.ts:79-90` `deriveBookId`：
- `examples-cet4` → `book_id='cet4'`
- `examples-zk`   → `book_id='zk'`
- `examples-gk`   → `book_id='gk'`

WordbookLoader 调用 `loadIfNeeded(bookSlug)` 用的是：
- `'book-001'`（CET-4，main.dart:36）
- `'zk'` / `'gk'`（main.dart:37-38）

**不一致**：bookSlug `'book-001'` ≠ server book_id `'cet4'`。
v0.2 解：用 `_packageNameForBookSlug(bookSlug)` 映射（`'book-001' → 'examples-cet4'`），
按 `package_name` 列查询，**不直接用 book_id**。

### 既有 SharedPreferences 测试模式（confirm，与 v0.1 一致）

`apps/mobile/test/p31_delta_phase1_daily_goal_test.dart:12-17`

### `setMockMessageHandler('flutter/assets')` 仓内**首次使用** ⚠️

```bash
grep -rn "setMockMessageHandler" apps/mobile/test/   # 0 结果
```

v0.1 plan §488 写"仓内已有同模式"是**错的**（v0.2 #2 修订）。v0.2 改 assetLoader
DI 方案，避开 mock channel 完全。

### `main.dart` 现状（仅 confirm，Day 2 不动）

`apps/mobile/lib/main.dart:1` 已 `import 'dart:async';`（Day 3 用 `unawaited()`
免新增 import；v0.2 #5 修订与 master plan 一致）。Day 2 完全不动 main.dart。

## 实施

### Step 1：`LocalSettingsService` 加 manifestSyncEnabled（~10 行；与 v0.1 同）

文件：`apps/mobile/lib/core/storage/local_settings_service.dart`

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

**契约**：默认 false / `bool`（缺失视为 false）/ key 命名 `settings_manifest_sync_enabled`。

### Step 2：`WordbookLoader` D1 收口 v0.2 + assetLoader DI（~50 行；v0.2 关键）

文件：`apps/mobile/lib/core/memory/wordbook_loader.dart`

#### 2a. 加 import + assetLoader 类型别名

顶部 imports 加：
```dart
import 'package:flutter/foundation.dart';  // debugPrint (v0.2 #6 修订)

/// Function loading an asset string by path. v0.2 #2 review-adopted:
/// injected DI replaces direct rootBundle calls so unit tests can fake
/// the asset layer without touching the binary message channel
/// (which is a first-time use repo-wide and risky to introduce here).
typedef AssetLoader = Future<String> Function(String path);
```

#### 2b. 改 WordbookLoader 构造接受 assetLoader

```dart
class WordbookLoader {
  final AppDatabase _db;
  final AssetLoader _assetLoader;

  WordbookLoader({
    required AppDatabase db,
    AssetLoader? assetLoader,  // v0.2 #2 review-adopted: optional DI
  })  : _db = db,
        _assetLoader = assetLoader ?? rootBundle.loadString;
```

公共 API 不变：现有 caller `WordbookLoader(db: appDb)` 不传新参数 → 行为完全
等同 v0.1（rootBundle.loadString）。

#### 2c. `loadIfNeeded` 改用 _assetLoader

行 49 改：
```dart
// v0.1: final jsonString = await rootBundle.loadString('assets/words/$bookSlug.json');
// v0.2:
final jsonString = await _assetLoader('assets/words/$bookSlug.json');
```

#### 2d. 加 `_packageNameForBookSlug` + `_hasManifestExamplesForBook` 私有方法

放在 `_exampleSentencesIntegrityOk()` 之后；详细代码见 §"D1 收口策略 v0.2"。

#### 2e. 重写 `_clearContentTables(String bookSlug)` 签名 + 行为

详细代码见 §"D1 收口策略 v0.2"；调用点行 69 改 `_clearContentTables(bookSlug)`。

### Step 3：单元测试（5 cases，~200 行；v0.2 fixture 全调）

#### 3a. `test/core/storage/local_settings_service_test.dart`（新建，3 cases，与 v0.1 同）

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

#### 3b. `test/core/memory/wordbook_loader_test.dart`（新建，2 cases，**fixture v0.2 调整**）

v0.2 关键改动（来自 R1#1 + R2#P1.1）：
- 旧 bundle 行 `stableId` 设非 null（避免 integrity backstop 触发）
- bundle v4 mock JSON 用**不冲突的 sortOrder**（如 sortOrder=2）模拟"v4 新增 example"
- 期望加 v3-bundle / manifest-row / v4-bundle 三者共存（v3-bundle 是 D1 收口副作用）
- `_hasManifestExamplesForBook` 测试加 cross-book regression case（装 examples-zk
  不影响 book-001 升级走经典 clear-and-reload）

```dart
import 'dart:convert';  // v0.2 #9 R2#P2.1 review-adopted: 显式 import

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/memory/wordbook_loader.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

/// v0.2 #2 R1#2 review-adopted: 用 assetLoader DI 注入 fake，避开仓内首次使用
/// setMockMessageHandler('flutter/assets') 的风险路径。Helper 直接传字符串。
WordbookLoader _loader(AppDatabase db, Map<String, String> assets) {
  return WordbookLoader(
    db: db,
    assetLoader: (path) async {
      final v = assets[path];
      if (v == null) throw Exception('fake asset not found: $path');
      return v;
    },
  );
}

String _bundleJson({
  required String contentVersion,
  required String wordId,
  required int sortOrder,
  required String stableId,
  required String en,
}) =>
    jsonEncode({
      'displayName': '中考',
      'contentVersion': contentVersion,
      'words': [
        {
          'wordId': wordId,
          'wordText': wordId,
          'meaning': 'noun',
          'sortOrder': 0,
          'examples': [
            {
              'sense': 'noun',
              'en': en,
              'cn': '示例',
              'sortOrder': sortOrder,
              'stableId': stableId,
            }
          ],
        }
      ],
    });

void main() {
  late AppDatabase db;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  group('WordbookLoader._clearContentTables D1 收口 v0.2 (PR-B3)', () {
    // v0.2 关键 case（fixture 全调，符合 InsertOrIgnore + 双 unique 语义）
    test(
        'manifest examples present: stable_id 非 null 行（v3-bundle + manifest-row）'
        '保留；v4 用不冲突 sortOrder=2 写入；legacy null stable_id 清掉',
        () async {
      // 1. 模拟 bundle v3 已加载状态
      await db.into(db.presetWordbooks).insert(
            PresetWordbooksCompanion.insert(
              slug: 'zk',
              displayName: '中考',
              contentVersion: const Value('v3'),
            ),
          );
      await db.into(db.wordEntries).insert(
            WordEntriesCompanion.insert(
              wordId: 'apple',
              wordText: 'apple',
              meaning: 'noun',
              importedAt: 1,
            ),
          );
      await db.into(db.wordBookAssignments).insert(
            WordBookAssignmentsCompanion.insert(
              wordId: 'apple',
              bookSlug: 'zk',
              sortOrder: const Value(0),
            ),
          );
      // bundle 旧行：stable_id 非 null（v0.2 fixture 调整 R1#1）
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
      // legacy null stable_id 行（v0.2 加：覆盖 R2#P1.3 死循环修复）
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'apple',
              sense: 'noun',
              en: 'LEGACY no-stableId',
              cn: '老',
              sortOrder: const Value(3),
              stableId: const Value.absent(),
            ),
          );

      // 2. 模拟 PackageInstaller 写 manifest examples 包（按本 book，name=examples-zk）
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
      // manifest 行：(apple, sortOrder=1) 与 bundle (apple, 0) 不冲突
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

      // 3. 模拟 bundle v4 升级（v4 新增一条 example，sortOrder=2 不冲突任何已有行）
      final assets = {
        'assets/words/zk.json': _bundleJson(
          contentVersion: 'v4',
          wordId: 'apple',
          sortOrder: 2,
          stableId: 'v4-bundle',
          en: 'V4 BUNDLE NEW',
        ),
      };

      // 4. 调 loadIfNeeded → 触发 D1 收口分支（_hasManifestExamplesForBook=true）
      await _loader(db, assets).loadIfNeeded('zk');

      // 5. 断言：
      final rows = await db.select(db.exampleSentences).get();
      final stableIds = rows.map((r) => r.stableId).toSet();

      // (a) manifest-row 保留（D1 收口主目标）
      expect(stableIds, contains('manifest-row'),
          reason: 'manifest-installed row must survive (D1 收口)');
      // (b) v3-bundle 保留（D1 收口副作用：stable_id 非 null 的 bundle 行也留下）
      //     此条副作用文档化于 §"D1 收口策略 v0.2"
      expect(stableIds, contains('v3-bundle'),
          reason: 'non-null stable_id bundle row preserved (D1 副作用)');
      // (c) v4-bundle 写入成功（sortOrder=2 不冲突 (apple, 0/1)，stable_id 不冲突）
      expect(stableIds, contains('v4-bundle'),
          reason: 'v4 bundle row with non-conflicting sort_order writes through');
      // (d) legacy null stable_id 清掉（避免 integrity backstop 死循环；R2#P1.3）
      final nullCount = rows.where((r) => r.stableId == null).length;
      expect(nullCount, 0,
          reason: 'legacy null stable_id rows must be cleared even in D1 收口');

      // (e) preset_wordbooks 升到 v4
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
      await db.into(db.wordEntries).insert(
            WordEntriesCompanion.insert(
              wordId: 'apple',
              wordText: 'apple',
              meaning: 'noun',
              importedAt: 1,
            ),
          );
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'apple',
              sense: 'noun',
              en: 'V3 BUNDLE',
              cn: 'v3',
              sortOrder: const Value(0),
              stableId: const Value('v3-bundle'),
            ),
          );

      // 2. content_package_state 为空
      expect(await db.select(db.contentPackageStates).get(), isEmpty);

      // 3. bundle v4
      final assets = {
        'assets/words/zk.json': _bundleJson(
          contentVersion: 'v4',
          wordId: 'apple',
          sortOrder: 0,
          stableId: 'v4-bundle',
          en: 'V4 BUNDLE',
        ),
      };

      // 4. loadIfNeeded
      await _loader(db, assets).loadIfNeeded('zk');

      // 5. v3 行被清；只剩 v4 行（PR-B2 之前行为；regression）
      final rows = await db.select(db.exampleSentences).get();
      expect(rows, hasLength(1));
      expect(rows.first.stableId, 'v4-bundle');
    });
  });
}
```

**v0.2 #3 R2#P1.2 cross-book regression 也覆盖**：第 2 case 名义上是"无 manifest"，
但 implicit 验证—— content_package_state 为空时 `_hasManifestExamplesForBook('zk')`
返 false，行为与 PR-B2 之前一致。如希望显式覆盖"装过 examples-zk 后 book-001
升级仍走经典清表"，可加第 3 case（降级时可砍）：

```dart
test(
    'cross-book regression: manifest for examples-zk does NOT trigger D1 收口 for book-001',
    () async {
  // 1. content_package_state 装了 examples-zk
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
  // 2. book-001 (CET-4) 现状：bundle v1 + 一行 stable_id 非 null
  await db.into(db.presetWordbooks).insert(
        PresetWordbooksCompanion.insert(
          slug: 'book-001',
          displayName: 'CET-4',
          contentVersion: const Value('v1'),
        ),
      );
  // ... 一行 example with stable_id='cet4-old' ...
  // 3. bundle v2 升级 book-001
  // 4. assert: cet4-old 被清（_hasManifestExamplesForBook('book-001') 查的是
  //    examples-cet4，不存在，返 false → 走经典清表分支）
});
```

**降级**（master plan §345 修订；时间紧时启用）：
- LocalSettingsService 3 cases → 2（保 default + persist）
- WordbookLoader 2 cases → 1（保 D1 关键，砍 regression）
- 不可少于 1+1 = 2 cases，否则 D1 收口无单测覆盖

## 关键文件

### 修改
- `apps/mobile/lib/core/storage/local_settings_service.dart`（+10 行）
- `apps/mobile/lib/core/memory/wordbook_loader.dart`（+50 行：assetLoader DI +
  `_packageNameForBookSlug` + `_hasManifestExamplesForBook` + `_clearContentTables`
  重写 + import flutter/foundation）

### 新建
- `apps/mobile/test/core/storage/local_settings_service_test.dart`（3 cases ~50 行）
- `apps/mobile/test/core/memory/wordbook_loader_test.dart`（2-3 cases ~200 行）

### 不动
- `apps/mobile/lib/main.dart`（Day 3 才接 startup hook + WordbookLoader 现有
  caller `WordbookLoader(db: appDb)` 不传 assetLoader 时行为完全等同 v0.1）
- `apps/mobile/lib/features/settings/`（Day 3）
- `apps/mobile/lib/app/`（Day 3）
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
```

### 2. flutter test 全过 + baseline 保持

```powershell
flutter test test/core/storage/local_settings_service_test.dart
flutter test test/core/memory/wordbook_loader_test.dart
flutter test     # baseline failures 不增加
```

### 3. 改动行数 vs PR-B3 Day 1 commit（v0.2 #12 修订基线）

```powershell
# 基线改用 PR-B3 Day 1 commit (5e7313c)，不是 PR-B2 merge (7058387)
git diff 5e7313c -- apps/mobile/lib/core/storage/local_settings_service.dart | wc -l
# 期望: ~25 行

git diff 5e7313c -- apps/mobile/lib/core/memory/wordbook_loader.dart | wc -l
# 期望: ~80 行

# server / pipeline / migration / main.dart / settings UI / manifest / drift 零改动
# v0.2 #12 加 manifest + drift 路径
git diff 5e7313c -- apps/api/ apps/mobile/lib/main.dart `
                    apps/mobile/lib/features/ `
                    apps/mobile/lib/app/ `
                    apps/mobile/lib/core/manifest/ `
                    apps/mobile/lib/core/storage/drift/ `
                    apps/api/scripts/ | wc -l
# 期望: 0
```

## 验收清单（v0.2）

- [ ] `LocalSettingsService.manifestSyncEnabled` getter / setter 实装
- [ ] 默认值 false（PR-B2 之前行为不变）
- [ ] key 命名 `settings_manifest_sync_enabled`
- [ ] **v0.2 #8 R1#6 显式声明**：Day 2 commit 后 manifestSyncEnabled 字段实装
      但仅 LocalSettingsService 测试访问；Day 3 commit 接 main.dart 启动 hook +
      settings page 开关。Day 2 → Day 3 间隔期 flag 是预期"未接通"状态，不是死代码遗漏
- [ ] `WordbookLoader` 加 `assetLoader` named optional 参数（v0.2 #2 R1#2）
- [ ] `WordbookLoader._packageNameForBookSlug` 私有方法
- [ ] `WordbookLoader._hasManifestExamplesForBook(bookSlug)` 私有方法（按
      packageName 过滤；v0.2 #3 R2#P1.2）
- [ ] `_clearContentTables(bookSlug)` 签名加 bookSlug 参数；本 book 有 manifest
      时仅清 `stable_id IS NULL` 行（避免 integrity backstop 死循环；v0.2 #4 R2#P1.3）
- [ ] D1 收口策略副作用文档化：bundle examples 升级被 manifest 接管后屏蔽
      （v0.2 #1 R1#1 + R2#P1.1）
- [ ] `print(...)` 改 `debugPrint(...)`（v0.2 #6 R1#4）
- [ ] **D1 关键 case 单测过**：bundle v3（stable_id 非 null + 1 legacy null 行）
      + manifest row → bundle v4（不冲突 sortOrder） → 4 个断言
      （manifest-row / v3-bundle / v4-bundle 三者共存 + null 清掉）
- [ ] regression case 单测过：无 manifest → 4 张表全清
- [ ] LocalSettingsService 3 cases 全过
- [ ] flutter analyze 0 error in 修改 / 新增 4 个文件
- [ ] flutter test baseline 失败数不增加
- [ ] git diff 基线改 5e7313c；path list 加 manifest / drift（v0.2 #12 R1#9 + R2#P2.2）

## 风险（v0.2 修订）

| 风险 | 缓解 |
|---|---|
| `_hasManifestExamplesForBook` 多查一次 SQL → 启动慢 | 1 行 SELECT LIMIT 1，<1ms |
| `content_package_state` 表在 fresh install 不存在 | PR-B2 v12 schema；in-memory test 走 `onCreate` 直接生成 v12（v0.2 #7 R1#5） |
| **bundle examples 升级被屏蔽**（D1 收口副作用） | **v0.4 scope §1.3 隐含限制**；plan 显式记录；`debugPrint` 提示；bundle examples 内容更新走 manifest 推包 |
| bookSlug → packageName 映射漏（如未来加新 book） | `_packageNameForBookSlug` 集中维护映射；新 book 加一行 if；当前 3 本（book-001/zk/gk）已硬编 |
| `(wordId, sortOrder)` 与 `stableId` 双 unique index 行为认知错误 | v0.2 #5 修订：两个 index **同时生效，任一冲突都 InsertOrIgnore no-op**；不是"两维度不同所以不冲突" |
| 旧 NULL stable_id 行触发 integrity 死循环 | v0.2 #4：D1 收口分支也 `DELETE WHERE stable_id IS NULL` |
| Day 2 工作量超 1 天 | 改动 ~60 行 + 测试 ~250 行；预期 ≤ 5 小时；超时降级单测 5 → 3 |
| `assetLoader` DI 改了 WordbookLoader 构造 → 既有 caller 受影响 | named optional + default `rootBundle.loadString`；现有 main.dart caller 不传参数行为不变（v0.2 #2 R1#2） |
| Day 2 内 flag 加但无 caller → 死代码 git history | v0.2 #8 验收清单显式声明；Day 3 接通；非 blocker |
| `setMockMessageHandler` 仓内首次使用风险 | v0.2 #2 R1#2：换 assetLoader DI 方案 A；完全规避 |

## 评审 pre-set（v0.2 修订）

1. **为什么不一并改 word_entries / word_book_assignments / preset_wordbooks 的清表？**
   ✅ PR-B2 PackageInstaller kind 过滤只允许 'examples'；其它 kind 不写
   `content_package_state`，3 张 bundle-only 表当前没有 manifest 数据可保护。
   未来扩 wordbook kind 时再加类似 `_hasManifestWordbooksForBook` 判断。

2. **`_hasManifestExamplesForBook` 用 raw SQL？** 🟡 一致性优先：WordbookLoader
   现有 `_storedContentVersion` / `_exampleSentencesIntegrityOk` 都用 `customSelect`。

3. **flag 默认 false 用户也能从 D1 收口受益吗？** ✅ flag 控制 startup sync hook
   （拉新数据写表）；`_clearContentTables` D1 收口逻辑无条件跑（不查 flag）—— 老
   用户即使 flag=false 也受保护（虽然他们 content_package_state 也是空，行为与
   PR-B2 之前一致）。

4. **`_hasManifestExamplesForBook` 在 mock 数据库下能跑吗？** ✅ PR-B2 v12 schema
   含 content_package_states；`AppDatabase.forTesting(NativeDatabase.memory())`
   走 onCreate 直接生成 v12；表存在（v0.2 #7 R1#5）。

5. **同 (word_id, sort_order) 冲突时优先保留哪个？** ✅ InsertOrIgnore 语义：
   if exists then no-op，不会更新已有行。manifest 行先存在 → bundle reimport
   同 (word_id, sort_order) 被 ignore（保留 manifest）。**注意双 unique index：
   `(wordId, sortOrder)` 和 `stableId` 任一冲突都 no-op**（v0.2 #5 R1#3）。

6. **D1 收口副作用"bundle examples 升级被屏蔽"是否可接受？**
   ✅ 这是与 PR-B 系列把 examples 内容主权从 bundle 转给 server-manifest 一致的
   设计选择；bundle 仅作"首次安装兜底数据源"。新版 examples 内容靠 server 推
   manifest 包覆盖（PackageInstaller InsertOrReplace by stable_id）。bundle JSON
   只在 fresh install 或本 book 完全无 manifest 时被 reimport。
   **v0.4 scope §1.3 隐含限制**，v0.2 显式记录于 plan + 代码 dartdoc + debugPrint
   日志（v0.2 #1 R1#1 + R2#P1.1）。

## 不做（与 v0.1 同）

- ❌ `main.dart` 接 startup sync hook（Day 3）
- ❌ 设置页 SwitchListTile UI（Day 3）
- ❌ MeowApp 顶层 InheritedWidget DI（Day 3）
- ❌ Sub-smoke A-E 真机验证（Day 3）
- ❌ `LocalSettingsService` 暴露给非 service 层调用（Day 3）
- ❌ 改 `PackageInstaller` 写入策略（PR-B2 稳定，不动）
- ❌ 改 `ContentPackageService` kind 过滤（PR-B2 稳定，不动）

## 提交策略

Day 2 完成后单 commit：

```
feat(v0.3-pr-b3): Day 2 — feature flag + WordbookLoader D1 收口 v0.2 (mobile only)

D1 收口 v0.2: app 升级时 WordbookLoader._clearContentTables 不再无脑清
example_sentences；按本 bookSlug 是否有 manifest examples 决定清表粒度，
仅清 legacy null stable_id 行；接受 bundle examples 升级被 manifest 接管后
屏蔽（v0.4 scope §1.3 隐含限制）。

LocalSettingsService:
- 加 manifestSyncEnabled getter / setter (key settings_manifest_sync_enabled)
- 默认 false (PR-B2 之前行为不变)
- Day 3 才把 flag 接入 main.dart startup hook + settings UI

WordbookLoader v0.2:
- 加 assetLoader DI (named optional; default rootBundle.loadString) 替代
  仓内首次使用 setMockMessageHandler('flutter/assets')
- 加 _packageNameForBookSlug(bookSlug) 映射 (book-001 → examples-cet4)
- 加 _hasManifestExamplesForBook(bookSlug) 私有方法 (按 packageName 过滤;
  解决 v0.1 全库判断的跨 book 误伤)
- _clearContentTables(bookSlug) 签名加 bookSlug 参数
  - 本 book 有 manifest examples → 仅清 stable_id IS NULL 的 legacy 行
    (避免 integrity backstop 死循环)
  - 无 manifest → 4 张表全清 (PR-B2 之前行为)
- print → debugPrint (release build no-op)
- 公共 API loadIfNeeded(bookSlug) 签名/语义不变

测试 (5 cases):
- LocalSettingsService 3 cases (default false / set true persists / set false)
- WordbookLoader 2 cases:
  - D1 关键: bundle v3 + manifest row + legacy null → bundle v4 (不冲突
    sortOrder=2) → 4 断言: manifest-row + v3-bundle + v4-bundle 三共存,
    null 清掉
  - regression: 无 manifest → 全清 (PR-B2 之前行为)

零 main.dart / settings UI / app/ / server / pipeline / migration / manifest /
drift 改动。

吸收 2 份评审共 14 处去重修订 (v0.1 → v0.2)。
flutter analyze 0 error；flutter test baseline 不退化。
```

## 评审节奏

Plan v0.2 push 后让 codex 拉到 → 等可能的 v0.3 评审 / 直接实装 commit 2。
（沿用 PR-B1 / PR-B2 / PR-B3 Day 1 模式）
