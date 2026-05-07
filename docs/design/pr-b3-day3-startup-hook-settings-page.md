# v0.3 PR-B3 · Day 3 plan v0.2 — 启动异步 sync hook + settings 页 debug 开关 + sub-smokes + README

> **v0.1 → v0.2**：吸收两份外部评审共 13 处去重修订。**3 处 P0 根本性修订**：
> 1. **hook 重构**：`prefs.getInstance + flag 判断 + sync` 全部搬进 `unawaited`
>    闭包；`runApp()` 立即调用，flag=false 时启动序列**真**完全等同 PR-B2 之前
>    （v0.1 在 runApp 前 `await prefs.getInstance()` 引入 ~10-50ms 启动阻塞，
>    与"等同"自相矛盾）
> 2. **release/profile 双 guard**：hook 加 `kDebugMode &&` 前置守卫，避免
>    debug build 的 SharedPreferences flag 残留到同包名 release/profile build
>    后仍触发 sync（违反 debug-only 边界）
> 3. **接 package_info_plus 真填 appVersion**：v0.1 传 `appVersion: null`
>    会绕过 server `min_app_version` 过滤，PR-B4 默认开会让用户下载并安装
>    超前版本包；Day 3 直接接 `package_info_plus: ^8.0.0` 真填
>
> 同时 helper 抽离 + 加 2 cases unit test 覆盖 wire-up（v0.1 "0 unit test"
> 的边角缺口）。

## v0.1 → v0.2 修订（13 处去重）

### 🔴 P0 必修（开工前）

| # | 来源 | 问题 | 修订 |
|---|---|---|---|
| 1 | R1#1 + R2#P2 (158) | v0.1 `await prefs.getInstance()` 在 `runApp()` **之前** 跑，且注释反向论证；flag=false 用户每次冷启动也吃 ~10-50ms shared_prefs 桥；与"等同 PR-B2 之前"自相矛盾 | **重构 hook**：把 `prefs + flag 判断 + sync` 全搬进单个 `unawaited` 闭包；`runApp()` **立即调用**；删除 v0.1 §158 反向论证注释 |
| 2 | R2#P1 #1 (release flag 泄漏) | v1 仅 settings UI 用 `kDebugMode` 隐藏 SwitchListTile；用户在 debug build 把 SharedPreferences flag 设 true，再装同包名 release/profile build，main.dart hook 仍读到 true → 触发 sync；违反"debug-only / release 行为不变"边界 | hook **加 `kDebugMode &&` 前置守卫**（`if (!kDebugMode) return;`）。release/profile dead-code-eliminate 后整段消失，无论 prefs 残留值如何 |
| 3 | R2#P1 #2 (appVersion=null 绕过过滤) | v0.1 传 `appVersion: null`；server 收到 null 时**不过滤** `min_app_version`，一旦 active manifest 含超前版本包，hook 会下载并安装；Day 4 接是给 PR-B4 默认开埋雷 | **Day 3 直接接** `package_info_plus: ^8.0.0`；hook 内 `final info = await PackageInfo.fromPlatform(); ... appVersion: info.version`。新增 1 项 pubspec 依赖；当前 `version: 0.0.1` 让 server 过滤掉 min > 0.0.1 的包 |

### 🟡 P1 应修

| # | 来源 | 修订 |
|---|---|---|
| 4 | R1#2 (D1 README 漂移) | **起手前 recon 已确认**：`git show bee3700 -- apps/mobile/lib/core/memory/wordbook_loader.dart` 显示 Day 2 实装 = "按 packageName 过滤 + 仅清 stable_id IS NULL"，与 v0.1 plan README §326 描述一致。Reviewer 引用的"整表跳过"是 Day 2 v0.1 plan（已被 v0.2 否决）。**v0.2 README 文案保持原样并显式注明 recon 结果** |
| 5 | R1#3 (staging README 漂移) | **起手前 recon 已确认**：`git show 5e7313c -- apps/api/src/main.ts` 显示 Day 1 实装确有 `if (!isProdEnv)` guard，与 v0.1 plan README §307-309 描述一致。**v0.2 README 文案保持原样并显式注明 recon 结果** |
| 6 | R1#4 (hasFailure log 漏 installed) | `hasFailure=true` 与 `hasChanges=true` 可共存（部分包成功 + 部分失败混合）；v0.1 if/elif 分支只输出 failed 信息，丢失 installed/replaced 计数；调试时无从知道哪些包真装好 → **改为单 if + 全字段输出 mixed log** |
| 7 | R2#P2 #4 (zero server diff 验证打爆) | v0.1 §407 验证命令 `git diff -- apps/api/` 包括本次 Day 3 README 改动 `apps/api/scripts/content_pipeline/README.md`，跑必然失败。**改为精确 path**：`apps/api/src/`（runtime） + `apps/api/test/` + `apps/api/scripts/content_pipeline/pipeline.py`（不含 README） |

### 🟢 P2 应修

| # | 来源 | 修订 |
|---|---|---|
| 8 | R1#5 (subtitle 模糊) | subtitle 改 `'开/关后下次重启 App 生效。失败静默。'`（明示开/关都是重启生效语义） |
| 9 | R1#7 (运行中切关 flag 行为没明示) | 风险表加 1 行：`运行中切关 flag 不打断已开始的 sync`（fire-and-forget；已写入数据保留；下次重启不再 sync） |
| 10 | R1#8 (双层守卫疑虑) | **已 recon 确认** `_buildDebugSection(context)` 调用方（settings_page.dart line 185）**无外层 kDebugMode 守卫**；plan §253 加 `if (kDebugMode) SwitchListTile(...)` **不冗余**。recon 结果显式记录 |
| 11 | R1#10 (措辞 "unit-test" → "sub-smoke") | v0.1 §453 风险表 "Day 3 unit-test 范围内可接受" 改 "Day 3 sub-smoke 走 dev API + min_app_version='0.0.0' 不撞过滤"；并因 #3 接 package_info_plus 后此风险**已根本消除**，风险表改写为"已通过接入 package_info_plus 解决" |

### 🟢 Nit / 待评估

| # | 来源 | 修订 |
|---|---|---|
| 12 | R1#9 (settings_page 行号) | **已 recon 确认** `wc -l settings_page.dart = 878`；reviewer 数错了，plan §100 原写 878 是对的，**不动** |
| 13 | R2#P2 #5 (Day 3 缺自动化) | 部分采纳：**hook 抽离成 testable helper** `runManifestSyncIfEnabled(...)`（main.dart 同文件 top-level function）+ 加 **2 cases unit test**（flag=false 短路不调 / flag=true 调用）。**不加 settings widget test**（与 baseline study_sections_test.dart 同样易 stale，性价比低） |

## 起手前 recon 结果（v0.2 修订表 #4 / #5 / #10 / #12 一并记录）

```bash
# Recon 1: Day 2 实装 D1 收口语义（v0.2 修订 #4）
git show bee3700 -- apps/mobile/lib/core/memory/wordbook_loader.dart | grep ...
# → 确认: 按 packageName 过滤 + 仅清 stable_id IS NULL legacy 行；与 v0.1 README §326 一致

# Recon 2: Day 1 staging route conditional（v0.2 修订 #5）
git show 5e7313c -- apps/api/src/main.ts | grep "isProdEnv"
# → 确认: 实装含 `if (!isProdEnv) { app.useStaticAssets(...); }`；与 v0.1 README §307-309 一致

# Recon 3: _buildDebugSection 调用方守卫（v0.2 修订 #10）
grep -B 2 _buildDebugSection apps/mobile/lib/features/settings/settings_page.dart
# → line 185: `_buildDebugSection(context),` 无外层 kDebugMode；plan 内 `if (kDebugMode) SwitchListTile` 不冗余

# Recon 4: settings_page.dart 行数（v0.2 修订 #12）
wc -l apps/mobile/lib/features/settings/settings_page.dart
# → 878 行；plan §100 原写值正确，reviewer 数错了

# 新增 Recon 5（v0.2 #3 关键）：pubspec 当前依赖 + app version
grep -E "package_info_plus|^version:" apps/mobile/pubspec.yaml
# → version: 0.0.1； package_info_plus 未引入。Day 3 加 ^8.0.0 单依赖
```

## Context

PR-B3 Day 1（commit `5e7313c`）+ Day 2（`bee3700`）+ baseline cleanup（`cad06f0`）
已 push。Day 3 收口接通整条 PR-B3 流量（flag → 启动 hook → ContentPackageService
→ drift）。

工作分支：`feat/v0.3-pr-b3-feature-flag-wire-up` @ `cad06f0`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b3`
对照基线 commit：`bee3700`（PR-B3 Day 2 commit；Day 3 改动 vs Day 2）

## 偏离 master plan v0.2 §150-156 的设计决策（**与 v0.1 同，明示偏离**）

**Day 3 主张跳过 InheritedWidget**，沿用现有 `await prefs.getInstance()` +
`LocalSettingsService(prefs)` 模式（settings_page.dart 已用 6+ 处）。理由
与 v0.1 同（详见 v0.1 plan 顶部）。如评审反对升 v0.3 加。

## 严格范围

仅改 mobile 端（无 server / pipeline / migration / WordbookLoader / LocalSettingsService /
ContentPackageService 改动）+ 1 份 README + 1 份 PR description。**1 天预算**。

### 不做（明示边界）

- ❌ 改 `WordbookLoader` / `LocalSettingsService`（Day 2 已稳定）
- ❌ 改 `ContentPackageService` / `PackageInstaller` / `DownloadManager` /
  `ManifestClient`（PR-B2 已稳定）
- ❌ 改 `MeowApp` / `SpecShell` 顶层结构（不引 InheritedWidget）
- ❌ 改 server / pipeline / migration / cdn-mock / audio-pipeline-staging
- ❌ 给现有 `_buildDebugSection` "复习历史" / "重新导入" 加 kDebugMode 包裹
  （仅本次新加 SwitchListTile 是 kDebugMode-only）
- ❌ 真 CDN 接入 / multi-codec 下载 / Range resume
- ❌ Settings widget test（v0.2 修订 #13：与 baseline study_sections_test.dart
  一样易 stale，性价比低）

## 实施

### Step 0：pubspec 加 `package_info_plus` 依赖（v0.2 #3 P0）

文件：`apps/mobile/pubspec.yaml`

```yaml
# 现有依赖块加一行（与 device_info_plus / shared_preferences 同 publisher 同规模）
package_info_plus: ^8.0.0
```

`flutter pub get` 后即可 `import 'package:package_info_plus/package_info_plus.dart';`。
此包是 Flutter 官方 plugin（pub.dev verified），平台覆盖 Android/iOS/Web/Desktop，
零原生 配置。

### Step 1：`main.dart` 加启动异步 sync hook（v0.2 重构）

文件：`apps/mobile/lib/main.dart`

#### 1a. imports 增量（v0.2 #1 不在 runApp 之前 await prefs；v0.2 #3 加
package_info_plus）

```dart
import 'package:flutter/foundation.dart';  // debugPrint, kDebugMode
import 'package:package_info_plus/package_info_plus.dart';  // PackageInfo
import 'package:path_provider/path_provider.dart';  // getApplicationDocumentsDirectory
import 'package:shared_preferences/shared_preferences.dart';

import 'core/manifest/content_package_service.dart';
import 'core/storage/local_settings_service.dart';
```

（`dart:async` 已在 line 1）

#### 1b. 抽 hook 成 top-level helper（v0.2 #13 部分采纳）

```dart
/// PR-B3 Day 3 (v0.2): manifest sync 启动异步 hook。
///
/// 抽离成 top-level helper 而非 main() 内匿名闭包：便于 unit test 注入
/// fake ContentPackageService + 验证 wire-up 不漏（v0.2 #13 R2#P2 #5
/// review-adopted）。
///
/// **三层 guard 顺序**（任一不满足直接 return）：
///   1. kDebugMode（v0.2 #2 R2#P1 #1）— release/profile build 直接 dead-
///      code-eliminate；防止 debug 写入的 SharedPreferences flag 残留到
///      同包名 release build 后仍触发 sync
///   2. settings.manifestSyncEnabled（PR-B3 feature flag）— 默认 false，
///      用户主动开启
///   3. 实际 ContentPackageService.syncIfNeeded — 失败静默 debugPrint
///
/// **fire-and-forget 契约**: 所有 await 都在闭包内；caller 用
/// `unawaited(runManifestSyncIfEnabled(db: db));` 启动。runApp 立即调用，
/// 启动 UI 零延迟（v0.2 #1 R1#1 + R2#P2 review-adopted）。
///
/// 测试 hook：传 `serviceFactory` 注入 fake；prod 默认走真 ContentPackageService。
typedef ContentPackageServiceFactory = ContentPackageService Function(
    Directory cacheDir, AppDatabase db);

Future<void> runManifestSyncIfEnabled({
  required AppDatabase db,
  ContentPackageServiceFactory? serviceFactory,
}) async {
  // Layer 1: release/profile build dead-code-eliminate
  if (!kDebugMode) return;

  try {
    // Layer 2: feature flag (默认 false)
    final prefs = await SharedPreferences.getInstance();
    if (!LocalSettingsService(prefs).manifestSyncEnabled) return;

    // Layer 3: 真触发 sync
    final cacheDir = await getApplicationDocumentsDirectory();
    final info = await PackageInfo.fromPlatform();
    final service = (serviceFactory ?? ContentPackageService.new)(cacheDir, db);
    final result = await service.syncIfNeeded(appVersion: info.version);

    // v0.2 #6 R1#4: hasFailure 与 hasChanges 可共存；输出全字段 mixed log
    // 不要走 if/elif 排他分支，否则部分成功被淹没
    if (result.hasFailure || result.hasChanges) {
      debugPrint('[main] manifest sync result: '
          'installed=${result.installed.length} '
          'replaced=${result.replaced.length} '
          'skipped=${result.skipped.length} '
          'failed=${result.failed.length} '
          'failureReasons=${result.failureReasons} '
          'manifestError=${result.manifestError ?? "(null)"}');
    }
  } catch (e, st) {
    debugPrint('[main] manifest sync threw: $e\n$st');
  }
}
```

注：`ContentPackageService.new` 是 Dart 2.15+ tear-off 语法，签名匹配
`(Directory, AppDatabase) → ContentPackageService` 仅对 positional ctor
有效；ContentPackageService 当前是 named-only ctor。**实施时改为显式
lambda**：

```dart
final factory = serviceFactory ??
    ((cacheDir, db) => ContentPackageService(cacheDir: cacheDir, db: db));
final service = factory(cacheDir, db);
```

#### 1c. main() 内调用（v0.2 #1 关键：runApp **立即**调用）

在 `runApp(const MeowApp());` 之前**只加一行 unawaited**：

```dart
// PR-B3 Day 3: manifest sync — 三层 guard (kDebugMode + flag + sync)
// 全在 helper 内异步背景跑；runApp 立即调用，UI 启动零延迟。
// flag=false / release/profile build → helper 内 return → 启动序列等同
// PR-B2 之前 (无 await prefs / 无 IO 阻塞)。
unawaited(runManifestSyncIfEnabled(db: appDb));

runApp(const MeowApp());
```

**关键不变量（v0.2 修订）**：
- ❌ v0.1: `await prefs.getInstance()` 在 runApp 前 → 阻塞 ~10-50ms
- ✅ v0.2: 0 await 在 runApp 前；hook 全异步背景；UI 启动**真**零延迟
- ✅ release/profile build dead-code-eliminate；prefs 残留无影响（v0.2 #2）
- ✅ appVersion 真填（v0.2 #3）；server min_app_version 过滤生效

### Step 2：`settings_page.dart` 加 SwitchListTile（与 v0.1 几乎同；只动 subtitle）

文件：`apps/mobile/lib/features/settings/settings_page.dart`

#### 2a. import 增量

```dart
import 'package:flutter/foundation.dart';  // kDebugMode
```

#### 2b. `_SettingsPageState` 加 flag state + load/save（与 v0.1 同）

加在 `_loadDeviceInfo()`（line 87）之后；`initState`（line 66）加一行
`_loadManifestSyncFlag();`。

```dart
// ===== PR-B3 manifest sync flag (Day 3 debug-only switch) =====
bool _manifestSyncEnabled = false;

Future<void> _loadManifestSyncFlag() async {
  final prefs = await SharedPreferences.getInstance();
  if (mounted) {
    setState(() {
      _manifestSyncEnabled =
          LocalSettingsService(prefs).manifestSyncEnabled;
    });
  }
}

Future<void> _setManifestSyncFlag(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await LocalSettingsService(prefs).setManifestSyncEnabled(value);
  if (mounted) setState(() => _manifestSyncEnabled = value);
}
```

#### 2c. `_buildDebugSection`（line 192-234）末尾加 SwitchListTile

放在 "重新导入增强数据" ListTile（line 220-230）之后；**v0.2 #8 修 subtitle
文案明示开/关均为重启生效语义**：

```dart
// PR-B3 Day 3: manifest sync debug 开关（kDebugMode-only）。
// 现有 debug section 既有 ListTile（"复习历史" / "重新导入"）保留 release
// 可见性不变；仅本新项隐藏在 release build。
// recon 已确认 _buildDebugSection 调用方（line 185）无外层 kDebugMode
// 守卫，本 if (kDebugMode) 不冗余 (v0.2 #10 R1#8 review-adopted)。
if (kDebugMode)
  SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    secondary: const Icon(Icons.cloud_sync_outlined),
    title: const Text('Manifest sync (PR-B3 dev)'),
    subtitle: const Text('开/关后下次重启 App 生效。失败静默。'),
    value: _manifestSyncEnabled,
    onChanged: _setManifestSyncFlag,
  ),
```

### Step 3：unit test（v0.2 #13 新增 helper 抽离 + 2 cases）

新建 `apps/mobile/test/main_manifest_sync_hook_test.dart`：

```dart
// PR-B3 Day 3 v0.2 #13 (R2#P2 #5) review-adopted: helper unit test
// 验证 wire-up 三层 guard。
//
// 注意：kDebugMode 在 test 环境为 true（与 debug build 一致）；测试覆盖
// Layer 2 (flag) + Layer 3 (sync 调用)。Layer 1 (kDebugMode) 由 dart
// 编译时常量保证 release build 正确，无法在 unit test 内伪造 false。

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meow_mobile/core/manifest/content_package_service.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';
import 'package:meow_mobile/main.dart' show runManifestSyncIfEnabled;

class _RecordingService implements ContentPackageService {
  int syncCalls = 0;
  String? lastAppVersion;

  @override
  Future<SyncResult> syncIfNeeded({String? appVersion}) async {
    syncCalls++;
    lastAppVersion = appVersion;
    return const SyncResult(
      installed: [],
      replaced: [],
      skipped: [],
      failed: [],
      failureReasons: {},
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late _RecordingService fakeService;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeService = _RecordingService();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await db.close();
  });

  group('runManifestSyncIfEnabled (PR-B3 Day 3 v0.2)', () {
    test('flag=false: short-circuits before calling service', () async {
      // default flag = false
      await runManifestSyncIfEnabled(
        db: db,
        serviceFactory: (_, __) => fakeService,
      );
      expect(fakeService.syncCalls, 0,
          reason: 'flag=false must not invoke ContentPackageService');
    });

    test('flag=true: invokes service.syncIfNeeded', () async {
      final prefs = await SharedPreferences.getInstance();
      await LocalSettingsService(prefs).setManifestSyncEnabled(true);

      await runManifestSyncIfEnabled(
        db: db,
        serviceFactory: (_, __) => fakeService,
      );
      expect(fakeService.syncCalls, 1);
      // appVersion 来自 PackageInfo.fromPlatform() — test 环境是 'unknown'
      // 或 mock；具体值不关键，只确认不是 null（v0.2 #3 R2#P1 #2 主张）
      expect(fakeService.lastAppVersion, isNotNull);
    });
  });
}
```

降级（时间紧时）：可砍 case 2（flag=true 调用），保 case 1（flag=false 短路）；
case 1 是 release 行为不变的最重要保护。

### Step 4：Sub-smokes 5 步（与 v0.1 同 + v0.2 #3 微调）

**完整命令引用 master plan v0.2 §"Sub-smokes 5 步"**。Day 3 v0.2 sub-smoke
执行时额外**须验证 v0.2 #3 (appVersion=info.version 真填)**：

```
A. flag=false（default）→ App 启动 = PR-B2 之前；adb logcat 0 sync log
B. flag=true + dev API → drift content_package_states 写入；adb logcat
   verify "manifest sync result: installed=N replaced=M ..."
C. flag=true + 离线 → 启动正常；sync 失败 silent；
   adb logcat verify "manifest sync threw: ..." 或 "manifestError=..."
D. **D1 关键**：bundle v3 + manifest sync → 改 bundle v4 → 重启 → 验证
   manifest 数据保留（Day 2 D1 收口 unit test 已覆盖；sub-smoke 真机回归）
E. **D3 关键 — DownloadManager 真能下载** + appVersion 真填:
   master plan v0.2 §"Sub-smokes 5 步" sub-smoke E 6 步;
   **额外 v0.2 #3 验证**: 用 PostgreSQL 直接 INSERT 一个测试包
   `min_app_version='99.99.99'`;flag=true 启动后验证 app **不下载**该包
   （server 用 appVersion='0.0.1' 过滤掉；hook 不写 drift）。证明
   v0.1 的 appVersion=null 漏洞已修
```

### Step 5：README 更新（v0.1 同；recon 已确认描述与实装一致）

文件：`apps/api/scripts/content_pipeline/README.md`

加 "## PR-B3 (v0.3 mobile manifest sync wire-up)" 章节，3 段（与 v0.1 一致；
recon 修订 #4 / #5 已确认 README 描述与 Day 1 / Day 2 实装一致，**文案保持
原样**）：

1. **Server staging serve route**（recon 确认 Day 1 commit `5e7313c` 含
   `if (!isProdEnv)` guard）
2. **Mobile feature flag**（v0.2 加注：appVersion 真填来自 `package_info_plus`；
   release/profile build 因 `kDebugMode` guard 不触发 sync）
3. **WordbookLoader D1 收口**（recon 确认 Day 2 commit `bee3700` 实装 = 按
   packageName 过滤 + 仅清 stable_id IS NULL legacy 行）

### Step 6：PR description 草稿（v0.1 同）

文件：`C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-B3.md`（user dir，不进 commit）。
v0.2 加注 11 章 "评审历史" 部分要包含 Day 3 v0.1 → v0.2 的 13 处去重修订。

## 关键文件

### 修改
- `apps/mobile/pubspec.yaml`（+1 行：`package_info_plus: ^8.0.0`，v0.2 #3）
- `apps/mobile/lib/main.dart`（+50 行：6 个 imports + `runManifestSyncIfEnabled`
  helper + main 内 1 行 unawaited 调用；v0.2 重构 hook）
- `apps/mobile/lib/features/settings/settings_page.dart`
  （+30 行：与 v0.1 几乎同；subtitle 文案改 v0.2 #8）
- `apps/api/scripts/content_pipeline/README.md`（+30 行；与 v0.1 同）

### 新建
- `apps/mobile/test/main_manifest_sync_hook_test.dart`（2 cases ~80 行；v0.2 #13）
- `C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-B3.md`（PR description；与 v0.1 同）

### 不动
- `apps/mobile/lib/app/app.dart`（不引 InheritedWidget；MeowApp 不改）
- `apps/mobile/lib/spec/`（SpecShell 顶层不动）
- `apps/mobile/lib/core/manifest/`（PR-B2 稳定）
- `apps/mobile/lib/core/memory/wordbook_loader.dart`（Day 2 已稳定）
- `apps/mobile/lib/core/storage/local_settings_service.dart`（Day 2 已稳定）
- `apps/mobile/lib/core/storage/drift/`（schema 不变）
- `apps/api/src/`（Day 1 已 commit；Day 3 0 server runtime 改动）
- `apps/api/test/`（Day 1 已 commit；Day 3 0 e2e 改动）
- `apps/api/scripts/content_pipeline/pipeline.py`

## 验证

### 1. flutter pub get（拉 package_info_plus）

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b3\apps\mobile
flutter pub get
```

### 2. flutter analyze 0 error in 修改/新增文件

```powershell
flutter analyze lib/main.dart `
                lib/features/settings/settings_page.dart `
                test/main_manifest_sync_hook_test.dart
# 期望: No issues found!
```

### 3. flutter test：新增 2 cases 全过 + baseline 1200/1200 保持

```powershell
flutter test test/main_manifest_sync_hook_test.dart
# 期望: All tests passed (2 cases)

flutter test
# 期望: 1202/1202 (baseline 1200 + 新 2)
```

### 4. Sub-smokes 5 步（A-E）真机/模拟器；含 v0.2 #3 验证

完整命令清单：master plan v0.2 §"Sub-smokes 5 步" + 本 v0.2 §"Step 4" sub-smoke
E 加 `min_app_version='99.99.99'` 测试包过滤验证。**全过才算 Day 3 收口**。

### 5. 改动行数 vs Day 2 commit（基线 bee3700；v0.2 #7 path 精确化）

```powershell
git diff bee3700 -- apps/mobile/lib/main.dart | wc -l
# 期望: ~70 行（50 业务 + diff meta）

git diff bee3700 -- apps/mobile/lib/features/settings/settings_page.dart | wc -l
# 期望: ~50 行

git diff bee3700 -- apps/mobile/pubspec.yaml | wc -l
# 期望: ~3 行（package_info_plus 单依赖加 1 行）

# server runtime + WordbookLoader + LocalSettingsService + manifest stack +
# migration + app/ + drift schema 零改动
# v0.2 #7: path 排除 README（apps/api/scripts/content_pipeline/README.md），
# 改用精确 runtime path
git diff bee3700 -- apps/api/src/ apps/api/test/ `
                    apps/api/scripts/content_pipeline/pipeline.py `
                    apps/mobile/lib/core/manifest/ `
                    apps/mobile/lib/core/memory/wordbook_loader.dart `
                    apps/mobile/lib/core/storage/local_settings_service.dart `
                    apps/mobile/lib/core/storage/drift/ `
                    apps/mobile/lib/app/ | wc -l
# 期望: 0
```

## 验收清单（v0.2）

- [ ] `pubspec.yaml` 加 `package_info_plus: ^8.0.0`（v0.2 #3）
- [ ] `main.dart` 加 6 个 imports（含 flutter/foundation 双用 debugPrint+kDebugMode）
- [ ] `main.dart` 加 top-level `runManifestSyncIfEnabled` helper，三层 guard:
      `kDebugMode` → `manifestSyncEnabled` → `syncIfNeeded`
- [ ] `main.dart` `runApp()` 前**只加一行** `unawaited(runManifestSyncIfEnabled(db: appDb));`
      （v0.2 #1 R1#1 + R2#P2 关键）
- [ ] **flag=false 时启动序列真完全等同 PR-B2 之前**（0 await 在 runApp 前；
      sub-smoke A 验证）
- [ ] **release/profile build dead-code-eliminate** `kDebugMode` 整段；prefs
      残留无影响（v0.2 #2 R2#P1 #1）
- [ ] `appVersion: info.version` 真填（来自 `PackageInfo.fromPlatform()`），
      server min_app_version 过滤生效（v0.2 #3 R2#P1 #2）
- [ ] hasFailure/hasChanges 共存场景输出 mixed log（含 installed/replaced 计数；
      v0.2 #6 R1#4）
- [ ] `appDb` instance 复用；`cacheDir` 用 `getApplicationDocumentsDirectory()`
- [ ] `settings_page.dart` 加 `_manifestSyncEnabled` field + load/save 方法 +
      initState 一行 + `if (kDebugMode) SwitchListTile(...)`
- [ ] subtitle 文案 `'开/关后下次重启 App 生效。失败静默。'`（v0.2 #8）
- [ ] **不引 InheritedWidget**；MeowApp/SpecShell 0 改动
- [ ] README 加 PR-B3 章节（recon 已确认 v0.1 描述与实装一致；v0.2 #4 #5）
- [ ] PR_DESCRIPTION_PR-B3.md 写到 user dir
- [ ] **新增 2 cases unit test 全过**（v0.2 #13）：
      flag=false 短路 / flag=true 调 syncIfNeeded
- [ ] **Sub-smokes A-E 5 步全过**含 v0.2 #3 验证（min_app_version='99.99.99'
      测试包不被下载）
- [ ] flutter analyze 0 error in 3 个 changed/new files
- [ ] flutter test 1202/1202 全过
- [ ] zero server runtime / WordbookLoader / LocalSettingsService / manifest
      stack / app/ 改动（git diff vs bee3700 验证；v0.2 #7 排除 README path）

## 风险（v0.2 修订）

| 风险 | 缓解 |
|---|---|
| 偏离 master plan §150-156（不引 InheritedWidget）| Day 3 plan 顶部明示偏离理由；同 v0.1 |
| **v0.1 启动阻塞 ~10-50ms (await prefs)** | **v0.2 #1 已根治**：prefs 读取搬进 unawaited 闭包；runApp 立即调用；UI 真零延迟 |
| **v0.1 release/profile flag 残留触发 sync** | **v0.2 #2 已根治**：hook 加 `if (!kDebugMode) return;` 三层 guard 第一层；release build dead-code-eliminate |
| **v0.1 appVersion=null 绕过 server min 过滤** | **v0.2 #3 已根治**：接 `package_info_plus`，真填 `info.version='0.0.1'`；server 过滤 min > 0.0.1 包；sub-smoke E 显式加 `min_app_version='99.99.99'` 测试包验证 |
| sync 失败 log 噪声 | release `debugPrint` 自动 no-op；hasFailure/hasChanges 共存输出 mixed log |
| 运行中切关 flag 用户期望立即 sync | subtitle 明示"开/关后下次重启生效"；不引 service 长连/订阅（v0.2 #8） |
| **运行中切关 flag 不打断已开始的 sync**（v0.2 #9 新加） | fire-and-forget 性质；已写入数据 PR-B2 transaction 原子性保证；下次重启不再触发；接受 |
| ContentPackageService cacheDir 不同 build 路径 | `getApplicationDocumentsDirectory()` Android/iOS 各自固定；与 AudioCacheRepository 一致 |
| package_info_plus 平台覆盖 | Flutter 官方 plugin（pub.dev verified）；Android/iOS/Web/Desktop 全覆盖；零原生配置 |
| Sub-smoke E 真机/模拟器跑失败 → Day 3 收口卡住 | master plan v0.2 §详细命令固化；如失败回头看 Day 1 commit `5e7313c` manual smoke step 7 |
| Day 3 工作量超 1 天 | v0.2 范围比 v0.1 大约 +30%（package_info_plus + helper + 2 unit test）；预期 ≤ 6 小时 |
| `_buildDebugSection` 双层 kDebugMode 守卫疑虑 | recon 已确认调用方无外层守卫；plan 内 `if (kDebugMode)` 不冗余（v0.2 #10） |

## 评审 pre-set（v0.2 修订）

1. **为什么不接 InheritedWidget？** ✅ 同 v0.1。

2. **为什么 Day 3 接 package_info_plus 而不留 Day 4？** ✅ v0.2 #3 R2#P1 #2
   review-adopted；评审升 P1。Day 3 是 wire-up 收口，appVersion 是 hook 完整性
   一部分；不接 = 给 PR-B4 默认开埋兼容性雷。Day 3 接 = 1 行 import + 1 个 await，
   付出小回报大。

3. **release/profile build 是否真完全 dead-code-eliminate？** ✅ Dart 编译时
   `kDebugMode` 是 const bool；`if (!kDebugMode) return;` 在 release 优化阶段
   被消除；整段 hook 不进 release binary。Sub-smoke A 在 release build 上跑
   `flutter build apk --release` 安装 + 切 flag → 启动后 adb logcat 不应有任何
   ContentPackageService 痕迹（验证 Layer 1 真生效）。

4. **`if (settings.manifestSyncEnabled)` 在 await 后判断的 race condition？** ✅
   单线程 Dart event loop；await 后 prefs 读取完成时 flag 是稳定快照；用户
   并发切 flag 不影响本次决策（subtitle 已说"下次重启生效"）。

5. **现有 _buildDebugSection 既有 ListTile release 可见性不变是否有意？** ✅
   recon 确认调用方无外层守卫；既有"复习历史" / "重新导入增强数据" 在 release
   也显示，是既有行为；Day 3 不改既有可见性，避免 PR-B3 引发视觉变化（v0.2 #10）。

6. **为什么不加 Settings widget test？** ✅ v0.2 #13 部分采纳：helper 抽离 +
   helper unit test 已覆盖 wire-up（flag=false 短路 / flag=true 调用）；widget
   test 与 baseline study_sections_test.dart 一样易随 UI redesign stale，性价比
   低。如 codex 坚持，Day 4 / 后续 PR 单独加（不在本范围）。

7. **WordbookLoader assetLoader DI（Day 2 加的）main.dart caller 受影响吗？** ✅
   同 v0.1；不动 main.dart 中 wordbookLoader 调用方式。

8. **README 描述与实装真一致吗？** ✅ v0.2 #4 / #5 已 recon 验证：
   - Day 1 staging route: `git show 5e7313c -- apps/api/src/main.ts` 显示
     `if (!isProdEnv) { ... }` guard 存在
   - Day 2 D1 收口: `git show bee3700 -- apps/mobile/lib/core/memory/wordbook_loader.dart`
     显示 "按 packageName 过滤 + 仅清 stable_id IS NULL"
   - 两份 README 文案与实装一致；保持原样

9. **`runManifestSyncIfEnabled` helper 是 main.dart 同文件 top-level 还是单独
   文件？** 🟡 v0.2 选**同文件 top-level**：避免新建文件 + 一致性高；只在
   `main.dart` 内 export（unit test `import 'package:meow_mobile/main.dart' show
   runManifestSyncIfEnabled;`）。如未来 hook 复用场景多再抽 `lib/core/startup/`。

## 不做（与 v0.1 同）

- ❌ `LocalSettingsService` 暴露给非 service 层调用（Day 3 仍 await prefs）
- ❌ 改 `PackageInstaller` 写入策略（PR-B2 稳定）
- ❌ 改 `ContentPackageService` kind 过滤（PR-B2 稳定）
- ❌ Settings widget test（v0.2 #13 部分采纳：仅 helper unit test）
- ❌ 改 main.ts 部署目录暴露策略（Day 1 已加 isProdEnv guard）

## 提交策略

Day 3 完成后单 commit（v0.2）：

```
feat(v0.3-pr-b3): Day 3 — 启动 hook + settings 开关 + sub-smokes + README (v0.2)

D3 收口: 接通 PR-B3 整条流量 (flag → 启动 hook → ContentPackageService → drift)。

main.dart:
- 加 6 个 imports (含 package_info_plus + flutter/foundation 双用)
- 加 top-level helper runManifestSyncIfEnabled(db, serviceFactory):
  - Layer 1: if (!kDebugMode) return;  (v0.2 #2 R2#P1 #1: release/profile
    dead-code-eliminate; 防 prefs flag 残留)
  - Layer 2: if (!manifestSyncEnabled) return;  (PR-B3 feature flag)
  - Layer 3: 真触发 syncIfNeeded(appVersion: PackageInfo.fromPlatform().version)
    (v0.2 #3 R2#P1 #2: 真填 app version 让 server min_app_version 过滤生效)
- runApp() 前只加一行 unawaited(runManifestSyncIfEnabled(db: appDb));
  flag=false / release/profile build → helper 内 return → 启动序列真完全
  等同 PR-B2 之前 (v0.2 #1 R1#1 + R2#P2: 不再 await prefs 阻塞 ~10-50ms)
- hasFailure/hasChanges 共存输出 mixed log (v0.2 #6 R1#4: 不丢部分成功信息)

settings_page.dart:
- 加 flutter/foundation import (kDebugMode)
- 加 _manifestSyncEnabled state + _loadManifestSyncFlag /
  _setManifestSyncFlag 方法
- initState 加 _loadManifestSyncFlag()
- _buildDebugSection 末尾加 if (kDebugMode) SwitchListTile;
  subtitle '开/关后下次重启 App 生效。失败静默。' (v0.2 #8)

pubspec.yaml: + package_info_plus: ^8.0.0

测试 (新增 2 cases):
- runManifestSyncIfEnabled flag=false: short-circuits before service
- runManifestSyncIfEnabled flag=true: invokes service.syncIfNeeded

明示偏离 master plan v0.2 §150-156: 不引 InheritedWidget DI scaffolding,
沿用 await prefs.getInstance + LocalSettingsService 模式。如评审反对升 v0.3 加。

吸收 2 份评审 13 处去重 (Day 3 plan v0.1 → v0.2):
- P0 (3): hook 重构 / kDebugMode 双 guard / 接 package_info_plus
- P1 (4): D1+staging README 已 recon 一致 / hasFailure log 加 installed /
  zero server diff 排除 README path
- P2 (4): subtitle 改 / 风险表加运行中切关 / 双层守卫已 recon 确认 / 措辞改
- Nit/待评估 (2): 行号已 recon 是 878 / Day 3 加 helper unit test (不加 widget test)

apps/api/scripts/content_pipeline/README.md: + PR-B3 章节 (recon 确认 v0.1
描述与 Day 1 / Day 2 实装一致, 文案保持原样)

零 server runtime / WordbookLoader / LocalSettingsService / manifest stack /
app/ / drift schema 改动 (git diff vs bee3700 验证).

flutter analyze 3 个 changed files: No issues found!
flutter test: 1202/1202 全过 (1200 baseline + 2 新).
Sub-smokes A-E 真机走全过 + v0.2 #3 sub-smoke E 加 min_app_version='99.99.99'
包验证 server 过滤生效.
```

## 评审节奏

Plan v0.2 push 后让 codex 拉到 → 等评审 / 直接实装 commit。

## 完成后状态

PR-B3 收口 = 9 个 commit ready for PR-B3 PR：
- `c554412` docs Day 1 v0.2
- `5e7313c` feat Day 1 (server staging serve + URL transform)
- `e0984b1` docs Day 2 v0.1
- `d2dca3a` docs Day 2 v0.2
- `bee3700` feat Day 2 (feature flag + WordbookLoader D1 收口 v0.2)
- `cad06f0` test (baseline study_sections cleanup)
- `b87bf94` docs Day 3 v0.1
- (本 commit) docs Day 3 v0.2
- (Day 3 实装) feat Day 3 (启动 hook + settings 开关 + helper unit test + README)
