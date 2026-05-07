# v0.3 PR-B4 · 默认开 manifest sync (flag default true) — single-day 单 PR

## Context

PR-B3 已 merge 到 main @ `5e063dc`（10 commit，3 day 交付：server staging serve +
mobile feature flag + WordbookLoader D1 收口 + 启动 hook + settings 开关）。

PR-B3 留下的 `LocalSettingsService.manifestSyncEnabled` SharedPreferences flag
**默认 `false`** —— 用户必须手动到 settings 页（debug build only）开开关，下次
启动才触发 sync。

PR-B4 = "把 default 翻成 true"，让团队 / 测试同事开发体验自动化。

工作分支：`feat/v0.3-pr-b4-default-on` @ `5e063dc`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b4`

## 关键 server-side 事实（决定 PR-B4 范围的硬约束）

实施前 recon：

```bash
# pipeline.py 写的 file_url 是什么？
grep "file_url = " apps/api/scripts/content_pipeline/pipeline.py
# → line 164: file_url = f"file:///{file_path.as_posix().lstrip('/')}"
# pipeline 写的是 file:// scheme（PR-A 决策；R1.4/R2.5 锁定）

# production manifest API 怎么处理 file:// 行？
grep -A 4 "isProd && row.file_url" apps/api/src/controllers/content-manifest.controller.ts
# → if (isProd && row.file_url.startsWith('file://')) {
#     console.error('[content/manifest] refusing to return file:// URL in production');
#     continue;  // 跳过
#   }
# production 模式直接 skip 所有 file:// 行
```

**含义**：
- **dev/local NestJS server** (NODE_ENV != 'production'): `file://` → `http://host/cdn/staging/...`
  transform，客户端能下载（PR-B3 Day 1 的能力）
- **production NestJS server**: 跳过 file:// 行 → manifest API 返回**空 packages**
- 真 CDN（http(s) URL 的 manifest）需要 PR-C 接入后 pipeline 改写 https URL

## 3 选 1 决策点（**待评审 / 用户选**）

### Option A: default=true，**保留** `kDebugMode` guard ⭐ 推荐

- main.dart `runManifestSyncIfEnabled` 内 `if (!kDebugMode) return;` **不动**
- settings_page `_buildDebugSection` 内 `if (kDebugMode) SwitchListTile(...)` **不动**
- 改动: `LocalSettingsService.manifestSyncEnabled` getter 返回 `_prefs.getBool(_k) ?? true`
- 测试: `local_settings_service_test.dart` "default false" → "default true"；
  `main_manifest_sync_hook_test.dart` flag=false case 改用显式 `setMockInitialValues({_k: false})`
- **release/profile 行为**: dead-code-eliminate 不变；用户体验 = PR-B3 之前 = 静默
- **dev/debug 行为**: 默认开 → 启动时 sync 跑 → /cdn/staging 拉包

**价值**: 团队 / 测试同事在 dev build 上自动 sync，不再需要手动切开关。
**风险**: 极小（1 行代码 + 测试 expect 翻转）。
**遗留**: release 仍需 PR-C 真 CDN + 后续 PR-B5（移 kDebugMode guard）才能真用上 manifest。

### Option B: default=true，**移除** `kDebugMode` guard ⚠️ 不推荐

- main.dart 移除 `if (!kDebugMode) return;`
- settings_page 移除 `if (kDebugMode)` 包裹（settings 开关 release 也可见）
- **release/profile**: sync 真跑 → 但 production manifest API 返空 packages →
  no-op + **每次启动 1 次空 HTTP roundtrip** + manifest API 服务器日志噪声

**价值**: 等 PR-C 真 CDN 完成后 release 用户立即受益；用户升级一次就开。
**风险**: 中等。
- 生产用户每次启动多一个空 manifest API call (~100ms 网络 RT + 流量)
- production 服务器日志被无意义 file:// 跳过 console.error 刷屏（每用户每启动 N 行）
- 一旦 manifest 出现 file:// 包（pipeline 还在写 file://），即使 production 跳过也是噪声

### Option C: 推迟 PR-B4，先做 PR-C（真 CDN 接入）

- PR-C: pipeline.py 改 file:// → https://cdn.meow-app.com/...；server staging route 删
- 然后 PR-B4 = Option B 等价（但不再有"production 返空"问题）

**价值**: 顺序最合理，PR-B4 一刀就能让所有用户受益。
**遗留**: 用户已经 explicit 要求做 PR-B4。

## v0.1 plan 主张：**Option A**

理由：
1. 改动小（1 行 + 测试 expect + docs），风险最小
2. 立即让 dev/test 体验自动化（PR-B4 真目的）
3. release 行为完全不变，避免空 sync 浪费
4. PR-C 完成后再做 "PR-B5: 移 kDebugMode guard"，那时 release 真有数据可拉
5. 与 PR-B3 一脉相承的渐进策略（B3 接通 + B4 dev 默认开 + C 真 CDN + B5 全员开）

## 严格范围

仅改 mobile 端（无 server / pipeline / migration / WordbookLoader / ContentPackageService /
PackageInstaller / DownloadManager / ManifestClient 改动）。**0.5 day 预算**。

### 不做（明示边界）

- ❌ 改 server / pipeline.py / migration（本 PR 完全不动 server）
- ❌ 真 CDN 接入（PR-C）
- ❌ 移除 `kDebugMode` guard（Option B；PR-B5 候选）
- ❌ 改 sync 算法 / `ContentPackageService` / `PackageInstaller`（PR-B2 已稳定）
- ❌ 加新依赖（pubspec 不动）

## 实施（Option A）

### Step 1: `LocalSettingsService.manifestSyncEnabled` 默认值翻 `true`

文件：`apps/mobile/lib/core/storage/local_settings_service.dart`

```dart
// PR-B3 (default false):
bool get manifestSyncEnabled =>
    _prefs.getBool(_keyManifestSyncEnabled) ?? false;

// PR-B4 (default true):
bool get manifestSyncEnabled =>
    _prefs.getBool(_keyManifestSyncEnabled) ?? true;
```

更新 dartdoc：
```dart
/// PR-B3 feature flag — when true, app fires async manifest sync on
/// startup (Day 3 wires it into main.dart). PR-B4: default flipped to
/// `true` so dev/profile builds auto-sync without the user toggling
/// the debug switch. Release/profile builds still dead-code-eliminate
/// the entire hook via main.dart's `kDebugMode` guard, so this default
/// only takes effect in debug builds.
///
/// Failure of sync NEVER blocks UI; flag exists purely to gate the
/// fire-and-forget call in main.dart.
bool get manifestSyncEnabled =>
    _prefs.getBool(_keyManifestSyncEnabled) ?? true;
```

### Step 2: 测试 expect 翻转

#### 2a. `apps/mobile/test/core/storage/local_settings_service_test.dart`

```dart
// PR-B3:
test('default false (PR-B2 之前行为不变)', () async {
  ...
  expect(LocalSettingsService(prefs).manifestSyncEnabled, isFalse);
});

// PR-B4 改:
test('default true (PR-B4: dev build 自动 sync)', () async {
  ...
  expect(LocalSettingsService(prefs).manifestSyncEnabled, isTrue);
});
```

`set true persists` case 不变（直接 set true → 读 true）。
`set false then read returns false` case 改 setMockInitialValues 用 false 启动 +
verify default true is overridable（语义不变，措辞调）。

#### 2b. `apps/mobile/test/main_manifest_sync_hook_test.dart`

```dart
// PR-B3:
test('flag=false: short-circuits before invoking service', () async {
  // Default flag = false (setMockInitialValues({}) above).
  ...
});

// PR-B4 改: 显式 set false
test('flag=false (explicit): short-circuits before invoking service', () async {
  // PR-B4: default flipped to true; this case must explicitly set false.
  SharedPreferences.setMockInitialValues({
    'settings_manifest_sync_enabled': false,
  });
  ...
});
```

`flag=true` case 不变（直接 set true → invoke service）。

### Step 3: README 更新

`apps/api/scripts/content_pipeline/README.md` PR-B3 章节末尾加 PR-B4 子节：

```markdown
### PR-B4 (single-day): default flipped to true

`LocalSettingsService.manifestSyncEnabled` default → `true`. Dev/profile
builds auto-sync without the user toggling the debug switch. Release builds
still dead-code-eliminate the entire hook via `main.dart`'s `kDebugMode`
guard (unchanged from PR-B3); release behavior is identical to PR-B2.

The `kDebugMode` guard removal is deferred to PR-B5, after PR-C lands real
CDN URLs in `pipeline.py` (until then, production `manifest` API returns
an empty `packages` list because it skips all `file://` rows).
```

### Step 4: PR description 草稿

`C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-B4.md`（user dir，不进 commit）

## 关键文件

### 修改
- `apps/mobile/lib/core/storage/local_settings_service.dart`（~3 行，1 行业务 + dartdoc）
- `apps/mobile/test/core/storage/local_settings_service_test.dart`（~5 行 expect 翻转）
- `apps/mobile/test/main_manifest_sync_hook_test.dart`（~5 行：flag=false case 显式 set）
- `apps/api/scripts/content_pipeline/README.md`（+10 行 PR-B4 子节）

### 不动
- `apps/mobile/lib/main.dart`（runManifestSyncIfEnabled helper / runApp 调用 0 改动）
- `apps/mobile/lib/features/settings/settings_page.dart`（SwitchListTile + kDebugMode guard 不变）
- `apps/mobile/lib/core/manifest/`（PR-B2 稳定）
- `apps/mobile/lib/core/memory/wordbook_loader.dart`（PR-B3 Day 2 稳定）
- `apps/mobile/lib/core/storage/drift/`（schema 不变）
- `apps/mobile/pubspec.yaml`（零新依赖）
- `apps/api/`（server runtime 0 改动；只动 README）
- `apps/api/scripts/content_pipeline/pipeline.py`（不动 file:// 写入逻辑）

## 验证

### 1. flutter analyze 0 error in 修改文件

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b4\apps\mobile
flutter analyze lib/core/storage/local_settings_service.dart `
                test/core/storage/local_settings_service_test.dart `
                test/main_manifest_sync_hook_test.dart
```

### 2. flutter test 全过

```powershell
flutter test test/core/storage/local_settings_service_test.dart
flutter test test/main_manifest_sync_hook_test.dart
flutter test    # baseline 1202/1202 不退化
```

### 3. 改动行数 vs PR-B3 merge (5e063dc)

```powershell
git diff 5e063dc -- apps/mobile/lib/ | wc -l
# 期望: ~10 行（仅 LocalSettingsService 1 行 + dartdoc）

git diff 5e063dc -- apps/mobile/test/ | wc -l
# 期望: ~20 行

# server / migration / WordbookLoader / manifest stack / drift schema 零改动
git diff 5e063dc -- apps/api/src/ apps/api/test/ apps/api/scripts/content_pipeline/pipeline.py `
                    apps/mobile/lib/core/manifest/ `
                    apps/mobile/lib/core/memory/ `
                    apps/mobile/lib/core/storage/drift/ `
                    apps/mobile/lib/main.dart `
                    apps/mobile/lib/features/settings/ | wc -l
# 期望: 0
```

### 4. Sub-smoke（手测）

#### S1. dev build 默认开
```
1. flutter run -d <emulator>
2. 不切设置开关
3. adb logcat | grep "manifest sync"
   期望: "manifest sync result: ..." 输出（说明启动时自动 sync 触发）
```

#### S2. dev build 用户能关
```
1. 在 settings 页打开 Manifest sync 开关 → 关闭
2. 杀 App + 重启
3. adb logcat
   期望: 无 "manifest sync" log（关掉后不触发）
```

#### S3. release build 行为不变
```
1. flutter build apk --release && flutter install
2. 启动 App
3. adb logcat | grep "manifest"
   期望: 0 行（release dead-code-eliminate）
4. 设置页 → 调试 section
   期望: 不显示 "Manifest sync" 开关（kDebugMode guard 仍生效）
```

## 验收清单

- [ ] `LocalSettingsService.manifestSyncEnabled` getter 默认值 `true`
- [ ] dartdoc 更新（PR-B3 default false → PR-B4 default true；说明 release dead-code-eliminate）
- [ ] `local_settings_service_test.dart` "default false" case 改为 "default true"
- [ ] `main_manifest_sync_hook_test.dart` "flag=false" case 显式 setMockInitialValues 设 false
- [ ] flutter analyze 0 error in 3 个 changed files
- [ ] flutter test baseline 1202/1202 不退化
- [ ] README 加 PR-B4 子节（说明 dev 默认开 + release dead-code-eliminate 不变）
- [ ] zero server / migration / WordbookLoader / manifest stack / main.dart / settings UI 改动
- [ ] **kDebugMode guard 完整保留**（main.dart + settings_page）
- [ ] PR_DESCRIPTION_PR-B4.md 写到 user dir
- [ ] Sub-smoke S1 / S2 dev build 真机过
- [ ] Sub-smoke S3 release build 真机过（确认 release 行为不变；critical safeguard）

## 风险

| 风险 | 缓解 |
|---|---|
| 现有 dev 用户 (已切过开关) prefs 残留 | prefs 写过 false 的用户保留 false (default 不覆盖)；他们要么自己切回，要么重装。可接受 |
| 现有 dev 用户 (没切过开关) 升级后默认开 | **预期行为**；这是 PR-B4 目的 |
| 默认开后启动慢 | sync 是 fire-and-forget unawaited；UI 不阻塞 |
| sync 失败用户感知 | release 不跑 sync (kDebugMode); dev/profile log 出现 "manifest sync threw"，开发者能看到 |
| Option A 不让 release 受益 | 显式记录 (README + plan)；PR-C + PR-B5 路径 |
| 测试期望翻转破坏 unit test | 同步改 expect；3 个 test case 涉及 |

## 不做（明示边界，下游 PR 候选）

- ❌ **PR-C**: 真 CDN 接入 (S3 / R2) + pipeline.py 改写 https URL + ETag + Range
- ❌ **PR-B5** (PR-C 之后): 移 kDebugMode guard，release 也默认开
- ❌ 改 settings UI release 可见性（kDebugMode guard 保留）
- ❌ 改 ContentPackageService kind 过滤 / sync 算法（PR-B2 稳定）
- ❌ 改 WordbookLoader D1 收口（PR-B3 Day 2 稳定）

## 提交策略

PR-B4 完成后单 commit：

```
feat(v0.3-pr-b4): default flag manifestSyncEnabled → true (dev/profile only)

LocalSettingsService.manifestSyncEnabled getter default 翻 false → true.
Dev/profile build 启动自动触发 manifest sync, 不再需要手动切设置开关.

Release build 行为完全不变 (PR-B3 main.dart 内 if (!kDebugMode) return;
完整保留 → release dead-code-eliminate; settings UI if (kDebugMode)
SwitchListTile 包裹也保留). 等 PR-C 接入真 CDN 让 production manifest
API 返非空 packages 后, 再做 PR-B5 移除 kDebugMode guard 让 release 也
默认开.

测试同步:
- local_settings_service_test "default false" → "default true"
- main_manifest_sync_hook_test "flag=false" 改用显式 setMockInitialValues

零 server / pipeline / migration / WordbookLoader / manifest stack / main.dart /
settings UI 改动 (git diff vs 5e063dc 验证). 仅 1 文件 1 行业务变更 + 测试
expect 翻转 + README 子节.

flutter analyze: No issues found! flutter test: 1202/1202.
Sub-smoke S1-S3 dev/release build 真机验证.
```

## 评审节奏

Plan v0.1 push 后让 codex 拉到 → 等评审决定 Option A vs B vs C →
按结果实装 + commit + push。
