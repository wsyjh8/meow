# v0.3 PR-B3 · feature flag + WordbookLoader 改 + server staging serve（3 天工作分解）

## Context

PR-A 已 merge / PR-B1 已 merge / PR-B2 已 merge（main @ `7058387`）。
- Server: 发布闭环 + 治理工具完整
- Mobile: ManifestClient / DownloadManager / PackageInstaller / ContentPackageService
  全部就绪，单测 + 集成测覆盖；**但完全没接入流量**

PR-B3 接入流量（仍默认关）+ 修两个 v0.4 收口的 scope 决策的实施层：
- **D1 收口**：app 升级 WordbookLoader 清表会顿掉 manifest 数据 → 改清表逻辑
- **D3 收口**：PR-B4 默认开 sync 但 file:// URL Flutter 不能 HTTP GET → server 加 staging serve

工作分支：`feat/v0.3-pr-b3-feature-flag-wire-up` @ `7058387`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b3`
对照基线 commit：`7058387`（PR-B2 merge 点）

### 严格范围

**PR-B3 加 feature flag 但默认关**——App 用户感知零变化；只有 dev 手动开 flag 才走 manifest 路径。PR-B4 才默认开。

### 不做（明示边界）

- ❌ flag 默认开（PR-B4）
- ❌ 删 bundle / minimum-set / APK 缩水（变体 C 永驻）
- ❌ 真 CDN 接入（PR-B3 仅 mock + staging serve）
- ❌ tombstone（v0.3 不做）
- ❌ audio_meta / wordbook / dictionary kind 实装（PR-B2+ 视需要）
- ❌ ETag / Range resume / brotli（PR-C 候选）

### 核实事实（recon 后）

**Server**:
- NestJS 已用 `app.useStaticAssets(cdn-mock, {prefix: '/cdn'})`（`main.ts:19-25`）——只需扩到 audio-pipeline-staging
- `content-manifest.controller.ts:160-177`：production 跳过 file://；dev 直接返 file://（客户端不能用）→ **dev 模式需 file:// → http:// transform**
- AppModule + RoutesModule 已注册 ContentManifestController（`routes.module.ts:59`）

**Mobile**:
- `shared_preferences: ^2.2.0` 已在 pubspec（`pubspec.yaml:14`）
- `local_settings_service.dart` 完整实装但**还没挂 main()**（行 1-58；需要 SharedPreferences 实例 DI）
- `main.dart:27-63` 启动序列干净，`runApp()` 前能插异步 sync hook
- `wordbook_loader.dart:47-72` `loadIfNeeded` 算法清晰：版本匹配 + integrity 过 → 返 0 不重导；否则清表重导
- `_clearContentTables()` 删 4 张表（example_sentences / word_book_assignments / word_entries / preset_wordbooks，行 99-104）

## 3 天工作分解

### Day 1：server staging serve route + manifest API URL transform（0.5 天，server only）

**目标**：让 dev 模式 manifest API 返回**可被 Flutter HTTP GET** 的 URL。production 行为完全不变。

主要工作（单 commit）：

#### 1. NestJS main.ts 加第二个 useStaticAssets

```typescript
// main.ts, after existing useStaticAssets(cdn-mock):
const stagingDir = path.resolve(__dirname, '..', 'audio-pipeline-staging');
app.useStaticAssets(stagingDir, {
  prefix: '/cdn/staging',
  setHeaders: (res) => {
    res.set('Cache-Control', 'no-cache');  // dev only; production 真 CDN 才有 cache
  },
});
```

**注意**：`/cdn` 已被 PR-A 占用（cdn-mock 下的 audio 文件）；新前缀 `/cdn/staging` 与之并行。

#### 2. content-manifest.controller.ts 加 dev URL transform

新增 helper（同文件内私有）：
```typescript
function transformFileUrlForDev(fileUrl: string, host: string): string {
  // dev 模式：file:///D:/.../audio-pipeline-staging/foo.gz
  //         → http://{host}/cdn/staging/foo.gz
  // dev 模式：file:///D:/.../cdn-mock/audio/v1/...mp3
  //         → http://{host}/cdn/audio/v1/...mp3
  if (!fileUrl.startsWith('file://')) return fileUrl;  // already http(s)
  if (fileUrl.includes('/audio-pipeline-staging/')) {
    const fileName = fileUrl.split('/audio-pipeline-staging/').pop();
    return `http://${host}/cdn/staging/${fileName}`;
  }
  if (fileUrl.includes('/cdn-mock/')) {
    const rel = fileUrl.split('/cdn-mock/').pop();
    return `http://${host}/cdn/${rel}`;
  }
  return fileUrl;  // 未知形态保持原样（让客户端 throw 易于排查）
}
```

修改 controller 行 171 附近：
```typescript
// production: 跳过 file:// 行（PR-A 既有行为，不变）
if (isProd && row.file_url.startsWith('file://')) {
  console.error(...);
  continue;
}

// dev: file:// → http:// transform（PR-B3 新加）
const transformedUrl = isProd
  ? row.file_url
  : transformFileUrlForDev(row.file_url, req.get('host') ?? 'localhost:3000');
```

注入 `@Req() req: Request`（NestJS 标准用法）。

#### 3. e2e 测试（pg-regression.e2e-spec.ts 加 2 cases）

```typescript
describe('PR-B3 manifest URL transform', () => {
  it('dev mode: file:// → http://localhost:3000/cdn/staging/...', ...);
  it('production mode: file:// 仍跳过（PR-A 既有行为）', ...);
});
```

**Day 1 期望增量**：~50 行 server + ~80 行测试。
**Day 1 commit**：`feat(v0.3-pr-b3): Day 1 — server staging serve + manifest URL transform (D3)`

### Day 2：feature flag + WordbookLoader 改（1 天，mobile only）

**目标**：D1 收口——app 升级时 WordbookLoader 不再无脑清表覆盖 manifest 数据。

主要工作：

#### 1. LocalSettingsService 加 manifestSyncEnabled getter/setter（~20 行）

```dart
// local_settings_service.dart 加：
static const _kManifestSyncEnabled = 'manifest_sync_enabled';

bool get manifestSyncEnabled => _prefs.getBool(_kManifestSyncEnabled) ?? false;

Future<void> setManifestSyncEnabled(bool value) =>
    _prefs.setBool(_kManifestSyncEnabled, value);
```

**默认 false**——PR-B3 不切流量。PR-B4 才默认开。

#### 2. main.dart 初始化 SharedPreferences + LocalSettingsService（~10 行）

如果 LocalSettingsService 还没挂 main，加初始化：
```dart
final prefs = await SharedPreferences.getInstance();
final settings = LocalSettingsService(prefs);
```

Day 2 起手前需确认这一步是否已挂。如已挂，仅加 manifestSyncEnabled 字段；如没挂，顺手加。

#### 3. WordbookLoader 改：查 content_package_state 决定跳过清表（D1 收口，~30 行）

文件：`apps/mobile/lib/core/memory/wordbook_loader.dart`

修改 `loadIfNeeded` 行 68 前后：
```dart
// 行 67-71 现状:
//   if (storedVersion != assetVersion) { ... continue 重导 }
//   if (storedVersion != null) {
//     await _clearContentTables();
//   }
//   await _loadFromData(...);

// 改成:
if (storedVersion != null && storedVersion != assetVersion) {
  // **D1 收口**：升级版本时不无脑清表。先查 content_package_state
  // 是否有该 book 的 manifest 记录。如有 → 跳过清表，仅 INSERT IGNORE
  // 让 bundle 数据补充 manifest 没覆盖的 stable_id。
  final hasManifestData = await _hasManifestPackageFor(bookSlug);
  if (!hasManifestData) {
    await _clearContentTables();  // 老路径：无 manifest 记录 → 清表重导
  }
  // 有 manifest 记录 → 不清表；下面的 _loadFromData 用 InsertOrIgnore
  // 自然不会覆盖 manifest 写入的行（stable_id 为 unique key）
}
await _loadFromData(...);
```

新加 helper：
```dart
Future<bool> _hasManifestPackageFor(String bookSlug) async {
  final packageName = 'examples-$bookSlug';
  final rows = await (_db.select(_db.contentPackageStates)
        ..where((t) => t.packageName.equals(packageName)))
      .get();
  return rows.isNotEmpty;
}
```

**关键不变量**：
- bundle 路径仍走 `InsertMode.insertOrIgnore`（不覆盖 manifest 已写的 stable_id）
- manifest 路径走 `InsertMode.insertOrReplace`（PR-B2 PackageInstaller 已实装）
- 两路径在 stable_id 维度自然 dedup

#### 4. 单测（~150 行）

新增 / 修改测试：
- `wordbook_loader_test.dart` 加 D1 收口 case：
  ```dart
  test('upgrade with manifest data: skip clear, manifest rows preserved',
      () async {
    // 1. 模拟 v3 bundle 已 imported（preset_wordbooks.contentVersion='v3'）
    // 2. seed content_package_state 有 examples-zk@manifest-v8 行
    // 3. seed example_sentences 有 stable_id='manifest-row' 行
    // 4. 调 loadIfNeeded('zk') 模拟 bundle v4 升级
    // 5. assert: example_sentences 仍含 stable_id='manifest-row' 行
    //    （未被清表）
  });

  test('upgrade without manifest data: classic clear-and-reload', ...);
  ```

**Day 2 期望增量**：~50 行代码 + ~150 行测试。
**Day 2 commit**：`feat(v0.3-pr-b3): Day 2 — feature flag + WordbookLoader 改 (D1)`

### Day 3：启动异步触发 sync + sub-smokes + 文档（1 天）

**目标**：把 ContentPackageService 接入启动序列（flag=true 时），写 sub-smokes 验证 D1 + D3 收口实际有效，更新 README。

主要工作：

#### 1. main.dart 加启动异步 sync hook（~15 行）

在 `runApp()` 前加：
```dart
// PR-B3: flag=true 时启动后异步触发 manifest sync。
// fire-and-forget — 不 await，不阻塞启动；失败静默 log。
if (settings.manifestSyncEnabled) {
  unawaited(
    ContentPackageService(
      cacheDir: await getApplicationDocumentsDirectory(),
      db: appDb,
    ).syncIfNeeded(appVersion: ...).then((result) {
      if (result.hasFailure) {
        debugPrint('manifest sync failed: ${result.failureReasons} '
                   '${result.manifestError ?? ""}');
      } else if (result.hasChanges) {
        debugPrint('manifest sync: $result');
      }
    }),
  );
}

runApp(const MeowApp());
```

**关键**：
- flag=false（默认） → 这段代码不执行 → 启动行为完全等同 PR-B2 之前
- flag=true → 异步触发，不阻塞 UI；失败静默
- `unawaited()` 来自 `package:flutter/foundation.dart` 或 `package:meta`

#### 2. 设置页 debug 开关（~30 行）

settings_page.dart 加一个 ListTile：
```dart
// 仅在 debug build 显示
if (kDebugMode)
  SwitchListTile(
    title: const Text('Manifest sync (PR-B3 dev)'),
    subtitle: const Text('开后异步从服务器拉内容更新；失败静默'),
    value: settings.manifestSyncEnabled,
    onChanged: (v) async {
      await settings.setManifestSyncEnabled(v);
      if (mounted) setState(() {});
    },
  );
```

#### 3. Sub-smokes 5 步（开发本地手测，PowerShell + Flutter run）

```
A. flag=false（default）→ App 启动行为完全等同 PR-B2 之前
B. flag=true + dev API 跑 → manifest sync 触发，drift 看到 manifest 数据
C. flag=true + 离线 → 启动正常（bundle 路径走通），sync 失败静默
D. **D1 关键**：flag=true 装 bundle v3 → sync 拉 v8 manifest 写 drift →
   修改 assets bundle 模拟 v4 升级 → 重启 → 验证 manifest 数据保留
E. **D3 关键**：dev API 调 manifest API → 收到 http://localhost:3000/cdn/staging/...
   URL（不是 file://），DownloadManager 真能下载
```

#### 4. README 更新（~30 行）

`apps/api/scripts/content_pipeline/README.md` 加 PR-B3 章节：
- 新 staging serve route 说明
- dev / prod 行为差异（dev: http:// transform；prod: 仍 file:// skip）
- mobile feature flag 说明（默认关 / 开关位置 / 风险）

#### 5. PR description 草稿到 user dir

`C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-B3.md`（沿用 PR-A / PR-B1 风格，11 章）

**Day 3 期望增量**：~50 行 mobile 代码 + 30 行 README + 5 步 sub-smoke 验证 + PR description。
**Day 3 commit**：`feat(v0.3-pr-b3): Day 3 — 启动异步触发 sync + sub-smokes + README`

## 关键文件

### 修改（server）
- `apps/api/src/main.ts`（+8 行，第二个 useStaticAssets）
- `apps/api/src/controllers/content-manifest.controller.ts`（+30 行，URL transform）
- `apps/api/test/pg-regression.e2e-spec.ts`（+2 cases，~80 行）

### 修改（mobile）
- `apps/mobile/lib/core/services/local_settings_service.dart`（+20 行，flag getter/setter）
- `apps/mobile/lib/main.dart`（+25 行，settings init + 启动 sync hook）
- `apps/mobile/lib/core/memory/wordbook_loader.dart`（+30 行，D1 收口）
- `apps/mobile/lib/features/settings/settings_page.dart`（+30 行，debug 开关）
- `apps/mobile/test/core/memory/wordbook_loader_test.dart`（+150 行，D1 case）

### 新建
- `docs/design/pr-b3.md`（本文档）
- `docs/design/pr-b3-day{1,2,3}-*.md`（每日详细 plan，用前再写）

### 不动
- `apps/api/scripts/content_pipeline/`（pipeline.py 等不动）
- `apps/api/src/infrastructure/postgres/migrations/`（无 schema 改动）
- `apps/mobile/lib/core/manifest/`（PR-B2 已稳定）
- `apps/mobile/lib/core/storage/drift/`（PR-B2 schema 已稳定）
- `apps/mobile/lib/core/audio/audio_cache_repository.dart`
- `apps/mobile/assets/words/*.json`（5.4MB bundle 永驻）
- `apps/mobile/pubspec.yaml`（零新依赖；shared_preferences ^2.2.0 已在）

## 风险

| 风险 | 缓解 |
|---|---|
| URL transform 在 production 误触发 → 暴露 file 系统路径 | 显式 `isProd` 守卫；e2e 反向 case 验证 production 仍 file:// skip |
| WordbookLoader 改后老用户升级丢数据 | D1 关键测试覆盖；保留"无 manifest 记录 → 清表"老路径 |
| 启动序列改后崩溃 | flag 默认关 → 改动代码路径不执行；regression test 覆盖 flag=false 路径 |
| settings 页 SwitchListTile 误开 | 仅 debug build 显示（kDebugMode）；release 用户看不到 |
| Day 2 工作量超 1 天（WordbookLoader 改 + 单测）| 降级优先级：砍 settings 页（移到 Day 3）；保留 D1 单测 |
| Day 3 启动 sync + sub-smokes 难手测 | 文档化 5 步流程；本机能完成；CI 不上 |
| ContentPackageService cacheDir 来源 | main.dart 用 `await getApplicationDocumentsDirectory()` (path_provider)；与 AudioCacheRepository 一致 |
| 启动 sync 失败 log 噪声 | 仅在 hasFailure 时 debugPrint；release build 默认压制 |

## 评审节奏（沿用 PR-B1 / PR-B2 模式）

- Day 1 plan → review → 实装 → commit + push
- Day 2 plan → review → 实装 → commit + push
- Day 3 plan → review → 实装 → commit + push

每个 Day plan 写到 `docs/design/pr-b3-day{N}-*.md`，commit 前让外部评审一轮。

## 验收清单（PR-B3 总）

- [ ] server staging serve route 工作（curl `/cdn/staging/foo.gz` 200）
- [ ] manifest API dev mode 返 http:// transformed URL（不是 file://）
- [ ] manifest API production mode 仍跳过 file://（PR-A 行为不变）
- [ ] LocalSettingsService 含 manifestSyncEnabled getter/setter，默认 false
- [ ] WordbookLoader 改：有 manifest 记录时跳过清表（D1 关键 unit test）
- [ ] WordbookLoader 老路径不破坏（无 manifest 记录时仍清表重导）
- [ ] main.dart 启动 sync hook（flag=true 时 fire-and-forget；flag=false 不执行）
- [ ] settings 页 debug 开关（kDebugMode only）
- [ ] sub-smoke 5 步（A-E）全过
- [ ] README PR-B3 章节
- [ ] PR_DESCRIPTION_PR-B3.md 写到 user dir
- [ ] flutter analyze 0 error in new/modified files
- [ ] flutter test 全过 + baseline 6 失败保持（不引入新失败）
- [ ] App **flag=false 默认行为**完全等同 PR-B2 merge（vs `7058387`）

## 总账（Day 1 + Day 2 + Day 3）

| Day | 主题 | 估时 | 增量代码 | 增量测试 |
|---|---|---|---|---|
| 1 | server staging serve + URL transform | 0.5 天 | ~50 server | ~80 e2e |
| 2 | feature flag + WordbookLoader 改 | 1 天 | ~50 mobile | ~150 unit |
| 3 | 启动 sync + sub-smokes + 文档 | 1 天 | ~85 mobile + 30 README | sub-smoke 手测 |
| **总** | — | **2.5 天** | ~165 行 + 30 README | ~230 行 + sub-smoke |

## PR-B3 之后（PR-B4，1 天）

PR-B4 把 flag 默认开 + 接入启动序列（不再依赖 dev 手动开）：
- LocalSettingsService.manifestSyncEnabled default false → true
- main.dart 启动 sync hook 改为始终触发（删 flag 守卫）
- 设置页"内容更新"按钮（kDebugMode 守卫去掉，给最终用户用）
- regression: 既有用户升级时 SharedPreferences key 不存在 → 默认 true
  （新装也是默认 true）
- baseline 6 失败保持

PR-B4 详细 plan 见 master plan v0.4 §5。

## 设计参考

- `docs/design/v0.3_PR-B_scope_v0.4.md` §3-4（变体 C 路线 / PR-B3 范围）
- `docs/design/pr-b2_v0.4.md`（PR-B2 master，提供 ContentPackageService 接口契约）
- PR-A `apps/api/src/main.ts:19-25`（useStaticAssets 模板）
- PR-A `apps/api/src/controllers/content-manifest.controller.ts:160-177`（file_url 处理位置）
- mobile `apps/mobile/lib/core/memory/wordbook_loader.dart:47-72`（loadIfNeeded 算法）
- mobile `apps/mobile/lib/core/services/local_settings_service.dart`（flag 持久化模板）
