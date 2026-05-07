# v0.3 PR-B3 · Day 3 plan v0.1 — 启动异步 sync hook + settings 页 debug 开关 + sub-smokes + README

## Context

PR-B3 Day 1（server staging serve + URL transform，commit `5e7313c`）+ Day 2
（feature flag 存储层 + WordbookLoader D1 收口 v0.2，commit `bee3700`）+ baseline
test cleanup（commit `cad06f0`）已 push。Day 3 收口接通整条 PR-B3 流量，让
`manifestSyncEnabled` flag 真正能从 settings 开关 → 启动 hook → ContentPackageService
→ drift 写入闭环。

- **Wire-up**：main.dart 在 `runApp()` 前 fire-and-forget 启动 manifest sync
  （仅当 `manifestSyncEnabled=true`）；失败静默 debugPrint。
- **设置页**：`settings_page.dart` 现有 `_buildDebugSection(context)` 内加一项
  `SwitchListTile`（kDebugMode-only），切换 flag。
- **Sub-smokes 5 步 (A-E)**：master plan v0.2 §"Sub-smokes 5 步"已固化，含
  E 详细命令（flutter run + adb logcat + drift sqlite）。
- **README + PR description**。

工作分支：`feat/v0.3-pr-b3-feature-flag-wire-up` @ `cad06f0`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b3`
对照基线 commit：`bee3700`（PR-B3 Day 2 commit；Day 3 改动 vs Day 2）

## 偏离 master plan v0.2 §150-156 的设计决策（**明示，待评审确认**）

master plan v0.2 §150-156 要求 "MeowApp 顶层 InheritedWidget 持有 settings + appDb"。
recon 后建议 Day 3 **跳过 InheritedWidget**：

- 现有 `settings_page.dart` 已用"按需 `await SharedPreferences.getInstance()`
  + `LocalSettingsService(prefs)`" 模式 6+ 处（line 73 / 88 / 105 / `_loadDeviceInfo`
  / `_performBackup` 等）；引入 InheritedWidget = 与既有风格不一致
- main.dart 启动 hook 只读一次 flag，开销 ~ms；用 `await SharedPreferences.getInstance()`
  比加 InheritedWidget scaffolding 更直接
- MeowApp 是现成 `StatefulWidget` + `MaterialApp`，没现成 InheritedWidget
  pattern；Day 3 引入 = 改 MeowApp 构造 + SpecShell 数据来源传播 = 风险大、
  Day 3 范围爆掉
- ContentPackageService 在 main.dart 局部构造，不需要全局可见

**Day 3 plan 主张**：用"按需 await prefs"现有模式，不引 InheritedWidget。如
codex / 评审反对，再升 v0.2 加 InheritedWidget。

其它已锁定决策（来自 master plan v0.2 / Day 1 / Day 2 v0.2）：
- `unawaited()` 来自 `dart:async`（main.dart line 1 已 import；v0.2 #5）
- main.dart 加 `import 'package:path_provider/path_provider.dart'`
  （首次引入；v0.2 #6）
- ContentPackageService cacheDir 用 `await getApplicationDocumentsDirectory()`，
  与 audio_cache_repository.dart:6 / line 200 一致
- WordbookLoader 公共 API `loadIfNeeded(slug)` 已在 Day 2 v0.2 改
  `assetLoader` named optional 参数，main.dart 现有 caller 不传参 → 行为不变
  （Day 3 不动 main.dart 中 wordbookLoader 调用方式）

## 严格范围

仅改 mobile 端（无 server / pipeline / migration / WordbookLoader / LocalSettingsService /
ContentPackageService 改动）+ 1 份 README + 1 份 PR description。**1 天预算**。

### 不做（明示边界）

- ❌ 改 `WordbookLoader` / `LocalSettingsService`（Day 2 已稳定）
- ❌ 改 `ContentPackageService` / `PackageInstaller` / `DownloadManager` /
  `ManifestClient`（PR-B2 已稳定）
- ❌ 改 `MeowApp` / `SpecShell` 顶层结构（不引 InheritedWidget；明示偏离 master plan）
- ❌ 改 server / pipeline / migration / cdn-mock / audio-pipeline-staging
- ❌ 接 `package_info_plus` 取 build version（Day 3 暂传 `appVersion=null`，让
  server 不过滤；Day 4 或后续 PR 接）
- ❌ 给现有 `_buildDebugSection` "复习历史" / "重新导入" 加 kDebugMode 包裹
  （仅本次新加 ListTile 是 kDebugMode-only；保守不改既有 release 可见性）
- ❌ 真 CDN 接入 / multi-codec 下载 / Range resume

## 核实事实（recon 后；v0.2 #14 R1#10 review-adopted）

### `ContentPackageService.syncIfNeeded` 签名

文件：`apps/mobile/lib/core/manifest/content_package_service.dart`
- 行 87-97 构造：`required Directory cacheDir + required AppDatabase db`
  （Day 2 v0.2 #8 / #16 关键：no silent defaults）
- 行 99：`Future<SyncResult> syncIfNeeded({String? appVersion}) async`
  → Day 3 hook 传 `appVersion: null`（Day 3 不接 package_info_plus）

### `SyncResult` 字段（v0.2 #14 关键 recon）

文件：`apps/mobile/lib/core/manifest/content_package_service.dart:27-72`
- 行 53：`final String? manifestError;` ← **String?**（PR-B2 Day 2 v0.2 #12 已加）
- 行 64：`bool get hasChanges => installed.isNotEmpty || replaced.isNotEmpty;`
- 行 65：`bool get hasFailure => failed.isNotEmpty || manifestError != null;`
- 行 67-71：`toString()` 含 5 字段计数 + manifestError yes/no
- master plan §250-251 用法 `result.manifestError ?? ""` 与签名 `String?` 兼容 ✅

### `main.dart` 现状（line 1-63，63 行）

- 行 1：`import 'dart:async';` 已存在（Day 3 用 `unawaited()` 免新加 import）
- 行 27：`void main() async {`
- 行 29：`await LocalDatabase.initialize();`
- 行 31：`final appDb = AppDatabase();` ← Day 3 直接复用此 instance 给
  ContentPackageService（避免 multi-instance race，与 audio_cache_repo 同模式）
- 行 35-38：`await wordbookLoader.loadIfNeeded('book-001' / 'zk' / 'gk');`
- 行 51-60：`try { await EnrichmentBootstrap(driftDb: appDb).ensurePopulated().timeout(...); }`
- 行 62：`runApp(const MeowApp());` ← Day 3 hook 在此**之前**插入
  （unawaited，不阻塞）

### `settings_page.dart` 现状（878 行）

- 行 5：`import '../../core/storage/local_settings_service.dart';` 已存在
- 行 1：`import 'package:flutter/material.dart';`（Day 3 加 `flutter/foundation.dart`
  for `kDebugMode`）
- 行 48：`class SettingsPage extends StatefulWidget`
- 行 55：`class _SettingsPageState extends State<SettingsPage>`
- 行 73, 88, 105 等多处：`final prefs = await SharedPreferences.getInstance(); ...`
  → Day 3 沿用此模式，不引 InheritedWidget
- **行 192-234：`_buildDebugSection(context)`** ← Day 3 新 ListTile 加此方法内（末尾）
- 行 220-230：现有第 2 项 ListTile "重新导入增强数据" — 加新项放其后

### `MeowApp` 现状（apps/mobile/lib/app/app.dart:28-74）

- StatefulWidget + MaterialApp + WidgetsBindingObserver（监 backup lifecycle）
- 现无 InheritedWidget；Day 3 不改
- `home: const SpecShell()` — 无需 settings 数据传播

### `path_provider` 用法参考

`apps/mobile/lib/core/audio/audio_cache_repository.dart`
- 行 6：`import 'package:path_provider/path_provider.dart';`
- 行 200：`final docs = await getApplicationDocumentsDirectory();`
- Day 3 main.dart hook 用同样写法

### Sub-smoke E 详细命令已固化

master plan v0.2 §"Sub-smokes 5 步" 已写明 sub-smoke E 的 6 步具体命令
（v0.2 #11 R1#9 review-adopted；Day 3 plan 直接引用，不再重复）。

## 实施

### Step 1：`main.dart` 加启动异步 sync hook（~30 行）

文件：`apps/mobile/lib/main.dart`

#### 1a. imports 增量

```dart
import 'package:flutter/foundation.dart';  // debugPrint
import 'package:path_provider/path_provider.dart';  // getApplicationDocumentsDirectory
import 'package:shared_preferences/shared_preferences.dart';

import 'core/manifest/content_package_service.dart';
import 'core/storage/local_settings_service.dart';
```

（`dart:async` 已在 line 1；`AppDatabase` 已在 line 7）

#### 1b. hook 在 EnrichmentBootstrap 之后、runApp 之前

```dart
// PR-B3 Day 3: manifest sync 启动异步触发 (flag 默认 false → 此段不执行；
// 行为完全等同 PR-B2 之前)。
//
// fire-and-forget — 不 await，不阻塞 UI 启动。失败静默 debugPrint
// (release build no-op)。
//
// flag → main.dart hook 决策必须在 runApp 之前完成（否则 UI 已显示，
// hook 才决定执不执行；用户看到延迟启动）。读 SharedPreferences 是 ms 级。
final prefsForSync = await SharedPreferences.getInstance();
final settingsForSync = LocalSettingsService(prefsForSync);
if (settingsForSync.manifestSyncEnabled) {
  // PR-B3 Day 3: cacheDir 用 getApplicationDocumentsDirectory，与
  // AudioCacheRepository (audio_cache_repository.dart:200) 一致。
  // 同 appDb instance — 避免 drift multi-instance race（与 EnrichmentBootstrap
  // 共用 driftDb 同思路）。
  // appVersion: null — Day 3 暂不接 package_info_plus；Day 4 / 后续接。
  unawaited(() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final service = ContentPackageService(cacheDir: cacheDir, db: appDb);
      final result = await service.syncIfNeeded(appVersion: null);
      if (result.hasFailure) {
        debugPrint('[main] manifest sync hasFailure: '
            'failed=${result.failed} '
            'failureReasons=${result.failureReasons} '
            'manifestError=${result.manifestError ?? "(null)"}');
      } else if (result.hasChanges) {
        debugPrint('[main] manifest sync: $result');
      } else {
        // no-op: hasFailure=false && hasChanges=false → quiet
      }
    } catch (e, st) {
      debugPrint('[main] manifest sync threw: $e\n$st');
    }
  }());
}

runApp(const MeowApp());
```

**关键不变量**：
- flag=false → `if` 块跳过 → 启动序列完全等同 PR-B2 之前
- flag=true → unawaited 异步触发；UI 不阻塞；失败静默 log
- 同一个 `appDb` instance — 不开第二个 drift 进程
- `prefsForSync.getBool` 1 次 IO（ms 级），不影响启动感知

### Step 2：`settings_page.dart` 加 SwitchListTile（~30 行）

文件：`apps/mobile/lib/features/settings/settings_page.dart`

#### 2a. import 增量

```dart
import 'package:flutter/foundation.dart';  // kDebugMode
```

#### 2b. `_SettingsPageState` 加 flag state + load/save

加在 `_loadDeviceInfo()`（line 87）之后：

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

`initState`（line 66）加一行 `_loadManifestSyncFlag();`：

```dart
@override
void initState() {
  super.initState();
  _loadLatestStatus();
  _loadDeviceInfo();
  _loadManifestSyncFlag();   // ← 加
}
```

#### 2c. `_buildDebugSection`（line 192-234）末尾加 SwitchListTile

放在 "重新导入增强数据" ListTile（line 220-230）之后：

```dart
// PR-B3 Day 3: manifest sync debug 开关（kDebugMode-only）。
// 现有 debug section 中其它 ListTile（"复习历史" / "重新导入"）保留
// release 可见性不变；仅本新项隐藏在 release build。
if (kDebugMode)
  SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    secondary: const Icon(Icons.cloud_sync_outlined),
    title: const Text('Manifest sync (PR-B3 dev)'),
    subtitle: const Text(
      '开后启动异步从服务器拉内容包；失败静默。下次重启 App 生效。',
    ),
    value: _manifestSyncEnabled,
    onChanged: _setManifestSyncFlag,
  ),
```

**关键**：
- `kDebugMode` guard：release build 该 ListTile 不显示（dart 编译时常量，
  整段 widget tree 被 dead-code-eliminate）
- `subtitle` 明示"下次重启 App 生效"——startup hook 在 runApp 前；运行中切
  flag 不立即触发 sync
- 沿用 `dense: true + contentPadding: EdgeInsets.zero`，与同 section 既有
  ListTile 视觉一致

### Step 3：Sub-smokes 5 步（开发本地手测；plan 不执行，sub-smoke 真机走时执行）

**完整命令引用 master plan v0.2 §"Sub-smokes 5 步"（v0.2 #11 R1#9 已固化
flutter run + adb logcat + drift sqlite 反查）**。Day 3 plan 不重复，仅列结构：

```
A. flag=false（default）→ App 启动行为完全等同 PR-B2 之前
   验证: adb logcat 无 ContentPackageService log; drift content_package_states 空
B. flag=true + dev API 跑 → manifest sync 触发，drift 看到 manifest 数据
C. flag=true + 离线 → 启动正常（bundle 路径走通），sync 失败静默
   验证: adb logcat 见 "manifest sync hasFailure: ... manifestError=..."
D. **D1 关键**: flag=true 装 bundle v3 → sync 拉 v8 manifest 写 drift →
   修改 assets bundle 模拟 v4 升级 → 重启 → 验证 manifest 数据保留
   （Day 2 D1 收口 unit test 已覆盖；sub-smoke 是真机回归确认）
E. **D3 关键 — DownloadManager 真能下载**: 详细命令见 master plan v0.2
   §"Sub-smokes 5 步" sub-smoke E 6 步（flutter run + adb logcat + sqlite 反查）
```

**Sub-smoke 执行强制约束**（v0.2 R2#4 + master plan §367-368）：
- E 是 `/cdn/staging` route + manifest URL transform + DownloadManager 的
  唯一端到端验证（e2e 不能跑 main.ts useStaticAssets）
- A-E 全过才算 PR-B3 收口

### Step 4：README 更新（~30 行）

文件：`apps/api/scripts/content_pipeline/README.md`

加一节 "## PR-B3 (v0.3 mobile manifest sync wire-up)"，3 段：

1. **Server staging serve route**（dev only；production 不暴露）
   ```
   - GET /cdn/staging/<file>.gz → audio-pipeline-staging/<file>.gz
   - dev 模式 manifest API file:// → http://{host}/cdn/staging/{file} 自动 transform
   - production 仍跳过 file:// 行（PR-A 行为不变）
   - 仅 NODE_ENV != 'production' 时 useStaticAssets 注册
   ```

2. **Mobile feature flag**
   ```
   - LocalSettingsService.manifestSyncEnabled (默认 false)
   - settings 页 → 调试 → "Manifest sync (PR-B3 dev)" 开关 (kDebugMode-only)
   - 开关 → 下次启动 main.dart 异步 fire-and-forget 调
     ContentPackageService.syncIfNeeded(appVersion: null)
   - 失败静默 debugPrint，不阻塞 UI
   ```

3. **WordbookLoader D1 收口**
   ```
   - bundle 升级 (content_version 变) 不再无脑清 example_sentences
   - 当 content_package_states 含 examples-${bookSlug} 行时，仅清
     stable_id IS NULL legacy 行；保留 manifest + 已 stableId 的 bundle 行
   - 副作用 (v0.4 scope §1.3): 本 book 接管后 bundle examples 升级被屏蔽,
     更新走 server 推 manifest 包
   ```

### Step 5：PR description 草稿（~PR-B1 / PR-B2 风格 11 章）

文件：`C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-B3.md`（user dir，不进 commit）

骨架（PR-B1 / PR-B2 PR description 风格）：
1. Title + 一句话概述
2. Why / 用户可见效果
3. 范围 (Day 1 + Day 2 + Day 3)
4. 关键文件清单
5. 测试 (e2e / mobile unit / sub-smoke)
6. 风险 & 缓解
7. 兼容性 (flag 默认 false → PR-B2 之前行为不变)
8. 不做 (明示边界，下游 PR-B4 / PR-C 候选)
9. v0.4 scope §1.3 副作用 (D1 收口；bundle examples 升级被 manifest 接管)
10. 评审历史 (Day 1 v0.2 / Day 2 v0.2 各 14-16 处)
11. 测试结果 (e2e 49/50 / mobile 1200/1200 / sub-smoke 5/5)

## 关键文件

### 修改
- `apps/mobile/lib/main.dart`（+30 行：5 个 import + startup hook block）
- `apps/mobile/lib/features/settings/settings_page.dart`
  （+30 行：flutter/foundation import + flag state + load/save 方法 +
  initState 加一行 + SwitchListTile in `_buildDebugSection`）
- `apps/api/scripts/content_pipeline/README.md`（+30 行：PR-B3 章节）

### 新建
- `C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-B3.md`（PR description 草稿）

### 不动
- `apps/mobile/lib/app/app.dart`（不引 InheritedWidget；MeowApp 不改）
- `apps/mobile/lib/spec/`（SpecShell 顶层不动）
- `apps/mobile/lib/core/manifest/`（PR-B2 稳定）
- `apps/mobile/lib/core/memory/wordbook_loader.dart`（Day 2 已稳定）
- `apps/mobile/lib/core/storage/local_settings_service.dart`（Day 2 已稳定）
- `apps/mobile/lib/core/storage/drift/`（schema 不变）
- `apps/mobile/pubspec.yaml`（零新依赖；path_provider ^2.1.5 / shared_preferences
  ^2.2.0 已在；本次也不加 package_info_plus）
- `apps/api/`（Day 1 已 commit；Day 3 0 server 改动）
- `apps/api/scripts/content_pipeline/pipeline.py`

## 验证

### 1. flutter analyze 0 error in 修改/新增文件

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b3\apps\mobile
flutter analyze lib/main.dart lib/features/settings/settings_page.dart
# 期望: No issues found! (在新增/修改的两个文件)
```

### 2. flutter test baseline 不退化

```powershell
flutter test
# 期望: 1200/1200 全过（Day 2 + baseline cleanup 已让 1200/1200；Day 3 不退化）
# 不新增 unit test（Day 3 是 wire-up + UI；逻辑核心已被 Day 2 单测覆盖）
```

### 3. Sub-smokes 5 步（A-E）真机/模拟器

完整命令清单：master plan v0.2 §"Sub-smokes 5 步"。**全过才算 Day 3 收口**。

### 4. 改动行数 vs Day 2 commit（基线 bee3700）

```powershell
git diff bee3700 -- apps/mobile/lib/main.dart | wc -l
# 期望: ~50 行（30 业务 + diff meta）

git diff bee3700 -- apps/mobile/lib/features/settings/settings_page.dart | wc -l
# 期望: ~50 行

# server / WordbookLoader / LocalSettingsService / manifest stack / migration / app/ 零改动
git diff bee3700 -- apps/api/ apps/mobile/lib/core/manifest/ `
                    apps/mobile/lib/core/memory/wordbook_loader.dart `
                    apps/mobile/lib/core/storage/local_settings_service.dart `
                    apps/mobile/lib/core/storage/drift/ `
                    apps/mobile/lib/app/ `
                    apps/api/scripts/content_pipeline/pipeline.py | wc -l
# 期望: 0
```

## 验收清单

- [ ] `main.dart` 加 5 个 imports（path_provider / shared_preferences /
      flutter/foundation / ContentPackageService / LocalSettingsService）
- [ ] `main.dart` 在 `runApp()` 前加 manifest sync hook：fire-and-forget +
      失败静默 debugPrint
- [ ] flag 默认 false 时，main.dart 启动序列完全等同 PR-B2 之前
- [ ] `appDb` instance 复用（不开第二个 drift；与 EnrichmentBootstrap 共用同
      driftDb 思路一致）
- [ ] `cacheDir` 用 `getApplicationDocumentsDirectory()`（path_provider；与
      AudioCacheRepository 一致）
- [ ] `appVersion: null` 传入（Day 3 不接 package_info_plus；Day 4 候选）
- [ ] `settings_page.dart` 加 `_manifestSyncEnabled` field + `_loadManifestSyncFlag` +
      `_setManifestSyncFlag`
- [ ] `initState` 加一行 `_loadManifestSyncFlag()`
- [ ] `_buildDebugSection` 末尾加 `if (kDebugMode) SwitchListTile(...)`
- [ ] 现有 debug section 既有 ListTile（"复习历史" / "重新导入增强数据"）
      release 可见性不变（不加 kDebugMode 包裹）
- [ ] `subtitle` 明示"下次重启 App 生效"
- [ ] **不引 InheritedWidget**（明示偏离 master plan §150-156；与现有 `await
      SharedPreferences.getInstance()` 模式一致）
- [ ] `MeowApp` / `SpecShell` 顶层结构 0 改动
- [ ] README 加 PR-B3 章节（3 段：server / mobile flag / D1 收口副作用）
- [ ] PR_DESCRIPTION_PR-B3.md 写到 user dir
- [ ] **Sub-smokes A-E 5 步全过**（master plan v0.2 §详细命令）
- [ ] flutter analyze 0 error in 2 个修改文件
- [ ] flutter test 1200/1200 全过（baseline 不退化）
- [ ] mobile / pipeline / migration / WordbookLoader / LocalSettingsService /
      manifest stack / app/ 零改动（git diff vs bee3700 验证）

## 风险

| 风险 | 缓解 |
|---|---|
| 偏离 master plan §150-156（不引 InheritedWidget）| Day 3 plan 顶部明示偏离理由；如评审反对升 v0.2 加 InheritedWidget；当前现有 prefs.getInstance 模式一致性强 |
| flag=true 时启动序列变慢 | unawaited fire-and-forget；hook 不在主路径；UI 不阻塞 |
| `prefsForSync.getBool` IO 阻塞 main 启动 | shared_preferences ms 级；与现有 EnrichmentBootstrap await 同量级；可忽略 |
| sync 失败 log 噪声 | `hasFailure` 才 log；release build `debugPrint` 自动 no-op |
| 设置页 SwitchListTile 误开（用户在 release 看到 dev flag） | `if (kDebugMode)` 包裹；release dead-code-eliminate；release 看不到 |
| 运行中切 flag 用户期望立即 sync | subtitle 明示"下次重启生效"；不引 service 长连/订阅 |
| ContentPackageService cacheDir 不同 build 路径 | `getApplicationDocumentsDirectory()` Android/iOS 各自固定；与 AudioCacheRepository 一致；测试设备不会出现 missing dir |
| `appVersion=null` 让 server 返超前版本包 → 客户端不能用 | server min_app_version 过滤层有兜底；Day 4 接 package_info_plus 真填值；Day 3 unit-test 范围内可接受 |
| Sub-smoke E 真机/模拟器跑失败 → Day 3 收口卡住 | master plan v0.2 §详细命令固化；本机能完成；如失败回头看 Day 1 commit `5e7313c` 的 manual smoke step 7 是否过 |
| Day 3 工作量超 1 天 | 改动 ~60 行 + 0 unit test + 5 步 sub-smoke + README + PR description；预期 ≤ 5 小时 |

## 评审 pre-set（猜可能被提的）

1. **为什么不接 InheritedWidget？master plan v0.2 §150-156 明确要求** ✅
   现有 settings_page 已用 6+ 处 `await prefs.getInstance()` 模式；引入
   InheritedWidget = 与既有不一致 + 改 MeowApp 构造 + SpecShell 数据来源传播 =
   Day 3 范围爆掉。如评审仍坚持，升 v0.2 加；本 v0.1 plan 主张明示偏离。

2. **`appVersion: null` 是不是漏 D3 行为？** 🟡 server 端 manifest API
   `app_version` 是 optional query param（PR-A 行为）；缺失即不过滤
   `min_app_version`。Day 3 sub-smoke E 走 dev API + 本地包，`min_app_version=
   '0.0.0'` 不会撞过滤。Day 4 接 package_info_plus 后真填 build version，更准。

3. **`if (settingsForSync.manifestSyncEnabled)` 在 await 后判断会不会漏读
   主线程 setState？** ✅ main 函数纯异步序列；无 widget tree 还在；
   SharedPreferences IO 完成后 flag 值是稳定快照；后续 `unawaited` 微任务才
   开始读 cacheDir。

4. **现有 _buildDebugSection 既有项不加 kDebugMode 包裹安全吗？** 🟡 现状：
   "复习历史" / "重新导入增强数据" release build 用户也能看到。这是 PR-B3
   之前的既有行为；Day 3 不改既有可见性，避免引发 release 用户视觉变化。
   如要统一收紧，留下游 PR 处理（不在本 plan 范围）。

5. **WordbookLoader 的 assetLoader DI（Day 2 加的）main.dart caller 受影响吗？**
   ✅ Day 2 加的是 `assetLoader` named optional 参数；main.dart caller
   `WordbookLoader(db: appDb).loadIfNeeded(...)` 不传新参数 → default
   `rootBundle.loadString` → 行为完全等同 PR-B2 之前。Day 3 不动 main.dart 中
   wordbookLoader 调用方式。

6. **Day 3 没新加 unit test 是不是覆盖不足？** ✅ Day 3 是 wire-up + UI；
   核心逻辑（flag 存储、D1 收口、ContentPackageService）已被 Day 2 + PR-B2
   单测覆盖。Settings 页 widget test 与 baseline study_sections_test.dart
   类似——容易随 UI 演进 stale；Day 3 sub-smoke 是更可靠的端到端验收。如评审
   坚持要 widget test，可加 1 case 验证 SwitchListTile 切换确实写 prefs（但
   收益有限）。

## 提交策略

Day 3 完成后单 commit：

```
feat(v0.3-pr-b3): Day 3 — 启动异步 sync hook + settings debug 开关 + sub-smokes + README

main.dart:
- 加 5 个 imports (path_provider / shared_preferences / flutter/foundation /
  ContentPackageService / LocalSettingsService)
- runApp() 前加 manifest sync hook: 读 LocalSettingsService.manifestSyncEnabled;
  flag=true 时 unawaited fire-and-forget ContentPackageService.syncIfNeeded
  (appVersion: null; cacheDir = getApplicationDocumentsDirectory; 复用 appDb)
- 失败静默 debugPrint (release build no-op); 不阻塞 UI

settings_page.dart:
- 加 flutter/foundation import (kDebugMode)
- 加 _manifestSyncEnabled state field + _loadManifestSyncFlag /
  _setManifestSyncFlag 方法
- initState 加 _loadManifestSyncFlag() 一行
- _buildDebugSection 末尾加 if (kDebugMode) SwitchListTile (PR-B3 manifest sync
  开关; subtitle 明示"下次重启生效"); 现有 debug section 既有项 release
  可见性不变

明示偏离 master plan v0.2 §150-156: 不引 InheritedWidget DI scaffolding,
沿用现有 settings_page "按需 await SharedPreferences.getInstance() +
LocalSettingsService(prefs)" 模式 (与 _loadDeviceInfo / _performBackup 等
6+ 处一致)。如评审反对再升 v0.2 加 InheritedWidget。

apps/api/scripts/content_pipeline/README.md:
- 加 PR-B3 章节 (server staging route / mobile flag / D1 收口副作用)

PR_DESCRIPTION_PR-B3.md (user dir 草稿; 不进 commit)

零 server / pipeline / migration / WordbookLoader / LocalSettingsService /
manifest stack / app/ / drift schema / pubspec 改动 (git diff vs bee3700 验证).

flutter analyze 2 个 changed files: No issues found!
flutter test: 1200/1200 全过 (baseline 保持; Day 3 不新加 unit test).
Sub-smokes A-E 真机走全过 (详细命令见 master plan v0.2 §"Sub-smokes 5 步").
```

## 评审节奏

Plan v0.1 push 后让 codex 拉到 → 等评审 / 直接实装 commit。
（沿用 PR-B1 / PR-B2 / PR-B3 Day 1 / Day 2 模式）

## 完成后状态

PR-B3 收口 = Day 1 + Day 2 + Day 3 + baseline cleanup 共 6 个 commit：
- `c554412` docs Day 1 v0.2
- `5e7313c` feat Day 1 (server staging serve + URL transform)
- `e0984b1` docs Day 2 v0.1
- `d2dca3a` docs Day 2 v0.2
- `bee3700` feat Day 2 (feature flag + WordbookLoader D1 收口 v0.2)
- `cad06f0` test (baseline study_sections cleanup)
- (本 plan) docs Day 3 v0.1
- (Day 3 实装) feat Day 3 (启动 hook + settings 开关 + README)

PR-B3 PR 候选 ready: `feat/v0.3-pr-b3-feature-flag-wire-up` → main，9 个 commit。
