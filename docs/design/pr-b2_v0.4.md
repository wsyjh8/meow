# v0.3 PR-B2 · mobile 基础设施（不切流量）— 2 天工作分解 v0.4

## Context

**Status:** SSOT v0.4，**取代** v0.1 / v0.2 / v0.3。
**变体决策**: 变体 C（bundle 永驻 + manifest 增量覆盖）。
**v0.3 → v0.4 修订**: 吸收两份外部评审 18 处真改进，含 4 个 scope 决策（D1/D3/D4/D5）+ 14 个 plan 细节修。

PR-A 已 merge `b072eb3` + PR-B1 已 merge `b26bff7`。
PR-B2 让 mobile 端**有能力消费 manifest**——但默认行为不变（不切流量）。

工作分支：`feat/v0.3-pr-b2-app-manifest-consumption` @ `b26bff7`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b2`

### 评审吸收（v0.3 → v0.4）

| # | 来源 | 处置 |
|---|---|---|
| D1 / R1#1 | scope vs WordbookLoader 三角矛盾 | scope 改：PR-B3 改 WordbookLoader（PR-B2 不改）|
| D3 / R2#1 | PR-B4 默认开 sync 没下载 URL | scope 改：PR-B3 加 server staging serve（+0.5 天）|
| D4 / R2#3 | since_release checkpoint 漏失败包 | **本 plan 改 ContentPackageService 算法：每次拉全量** |
| D5 / R2#4 | tombstone | scope 改：v0.3 不做（manifest 仅覆盖不删）|
| R1#2 | local_settings drift 表不存在 | scope 改：SharedPreferences |
| R1#3 | brotli compression guard | **本 plan 加** |
| R1#4 | content_package_state 缺 4 列 | **本 plan 加 4 列** |
| R1#5 | ContentPackageService 假失败 | **本 plan 加 kind filter** |
| R1#6 / R2#2 | 路径错（lib/data/local 应是 lib/core/...）| **本 plan 全改** |
| R1#7 | crypto 已在 pubspec | **本 plan 删 pubspec.yaml 修改清单** |
| R1#8 | 工作量数字不自洽 | **本 plan + scope 统一**: B2=2 / B3=2.5 / B4=1 共 5.5 天 |
| R1#10 | 5.6MB → 5.4MB recon | **本 plan 改 + 验收用 du** |
| R1#11 | 集成测覆盖不到启动行为 | **本 plan 加 baseline test 不破声明** |
| R1#12 | grep / du PowerShell 等价 | **本 plan 给 PowerShell 命令** |
| R2#5 | 集成测不能砍超时项 | **本 plan 改"超时砍 UI/文档而非集成测"** |
| R2 小项 | "APK 大小不变" 改"assets/words 不变" | **本 plan + scope 全改** |

### 严格范围（与 v0.3 一致：PR-B2 不动 WordbookLoader / 不动 server）

> "drift v12 + content_package_state 表（**12 列**）+ manifest fetch（**全量**）+ 包下载校验导入逻辑（**仅 examples kind**）。
> **默认走 bundled，不走 manifest**。WordbookLoader 不动。"

### 完成条件

1. 单测覆盖：manifest fetch / 包下载 / checksum 校验 / row-level diff 导入 / 失败重试
2. 集成测：mock CDN 下放新包 → 触发服务 → 导入到 example_sentences
3. App 默认行为不变（仍走 bundled）
4. assets/words bundle 文件列表 / 大小不变（5.4MB）

### 不做（明示边界）

- ❌ 改 WordbookLoader（PR-B3）
- ❌ feature flag（PR-B3）
- ❌ server staging serve（PR-B3）
- ❌ 启动联动 / UI 入口（PR-B4）
- ❌ 改 main.dart 启动序列
- ❌ minimum-set / 删 bundle（变体 C 永远不做）
- ❌ tombstone（v0.3 不做，PR-C）
- ❌ since_release 增量（每次全量；D4 决策）

### 核实事实（recon 后）

- **drift v2.32.1**：4 个目标表全部存在
- **http v1.1.0** + **crypto ^3.0.5** 已在 pubspec（pubspec.yaml:13/27）
- **真实路径**（v0.3 写错的全改对）：
  - `apps/mobile/lib/core/storage/drift/app_database.dart`（不是 lib/data/local）
  - `apps/mobile/lib/core/storage/drift/tables/`（drift table 定义）
  - `apps/mobile/lib/core/memory/wordbook_loader.dart`（不是 lib/data/local）
  - `apps/mobile/lib/core/audio/audio_cache_repository.dart`（不是 lib/data/local）
- **api_client.dart**: baseUrl `http://10.0.2.2:3000/api/v1`
- **assets/words bundle**: ~5.4MB（recon 实测，不是 5.6MB）
- **状态管理**：原生 StatefulWidget
- **启动序列**（main.dart:27-62）：LocalDatabase → AppDatabase → WordbookLoader×3 → EnrichmentBootstrap → runApp（PR-B2 不改）

## 2 天工作分解

### Day 1：drift schema v12 + ManifestClient + DownloadManager

**目标**：表 + HTTP fetch + 下载校验全部就绪，可单测。

#### 1. drift schema v11 → v12（含 4 列补充，R1#4）

新表 `content_package_state`（12 列，比 v0.3 多 book_id / size_bytes / compression / min_app_version）：

```dart
class ContentPackageStates extends Table {
  TextColumn get packageId => text()();              // examples-zk@v5
  TextColumn get packageName => text()();            // examples-zk
  TextColumn get packageKind => text()();            // examples / audio_meta / wordbook / dictionary
  TextColumn get contentVersion => text()();         // v5
  TextColumn get releaseId => text()();              // 最近一次带它来的 release
  TextColumn get bookId => text().nullable()();      // R1#4: zk / cet4 / dictionary 时 null（按书展示进度 / debug）
  TextColumn get checksumSha256 => text()();         // 安装时 checksum
  IntColumn get sizeBytes => integer().nullable()(); // R1#4: 进度条 / 缓存预算
  TextColumn get compression => text().nullable()(); // R1#4: gzip / brotli / null（PackageInstaller 选解压器）
  TextColumn get minAppVersion => text().nullable()();// R1#4: 客户端兜底 guard
  IntColumn get installedAt => integer()();          // unix ms
  TextColumn get fileUrl => text().nullable()();     // debug + 重新下载

  @override
  Set<Column> get primaryKey => {packageId};
}
```

migration：仅 `m.createTable(contentPackageStates)`（纯 ADD）。
测试 v11 → v12 路径（sqflite_common_ffi）。

文件路径：`apps/mobile/lib/core/storage/drift/tables/content_package_state.dart`（R1#6 修对）。

#### 2. ManifestClient（约 200 行）

`apps/mobile/lib/core/manifest/manifest_client.dart`（路径 R1#6 修对）：
- `Future<ManifestResponse> fetchManifest({String? appVersion})` — **不传 since_release**（D4：全量拉）
- DTO: `ManifestResponse(release_ids, packages)` / `ManifestPackage` 含 12 字段（与新 drift 表对齐）
- 错误：`ManifestNetworkError` / `ManifestParseError`
- 复用 `api_client.dart` 风格
- 单测：mock http 200 / 400 / 网络断

#### 3. DownloadManager（约 250 行）

`apps/mobile/lib/core/manifest/download_manager.dart`：
- `Future<File> downloadPackage(ManifestPackage pkg)`
- **brotli guard（R1#3）**：`if (pkg.compression == 'brotli') throw UnsupportedCompressionError(pkg.compression)`；仅 'gzip' 和 null（默认 gzip）支持
- 流式写 `{cacheDir}/manifest_packages/.tmp/{packageId}.partial`
- sha256 累计校验（crypto ^3.0.5 已在 pubspec，R1#7）
- 完整后 sha256 == manifest.checksum_sha256 → rename to `.gz`；否则删 + `ChecksumMismatchError`
- retry 指数退避 3 次
- 单测：mock 下载 + sha256 mismatch + 重试 + brotli reject

**Day 1 期望增量**：~450 行新代码 + ~350 行测试 + drift migration。

### Day 2：PackageInstaller + ContentPackageService + 集成测

**目标**：解压 + drift 写入 + service-level 编排 + 集成测。

#### 1. PackageInstaller（约 300 行）

`apps/mobile/lib/core/manifest/package_installer.dart`：
- `Future<void> install(File gzFile, ManifestPackage pkg)`
- gzip 解压：`dart:io` GZipCodec.decoder
- 按 `package_kind` 分发（**Day 2 仅完整实装 examples**）
  - `_installExamples(jsonlLines)`：upsert example_sentences (drift batch + InsertMode.insertOrReplace)
  - 其他 3 kind throw `UnimplementedError` + 注释指向 PR-B3/B4 / PR-C
- drift transaction wrap，失败回滚
- 成功后 UPSERT `content_package_state`（同事务，写入 12 个字段）
- 单测：fixture .jsonl.gz + 验证 drift 写入

#### 2. ContentPackageService（约 200 行，D4 + R1#5 收口）

`apps/mobile/lib/core/manifest/content_package_service.dart`：
- 顶层 service，组合 ManifestClient + DownloadManager + PackageInstaller
- `Future<SyncResult> syncIfNeeded()` — Day 2 写好但无入口调用（PR-B3 才接）
- 算法（D4 + R1#5 收口）：
  1. **不读 since_release**，每次调 `ManifestClient.fetchManifest(appVersion=appVer)` 拉全量
  2. **kind filter（R1#5）**：在 download 之前过滤 `package_kind != 'examples'` → 移入 `skipped[]` + reason='kind not implemented in PR-B2'
  3. 对剩余 examples package：
     - 本地 `content_package_state` 无 packageId → 新装（download → install）
     - 本地有但 contentVersion 不同 → 升级（同上）
     - 本地有且版本一致 → skip
  4. 返回 `SyncResult: installed[] / upgraded[] / failed[] / skipped[]`
- 失败：写日志，不更新 content_package_state（**不写脏 state**），下次启动重试
- 单测：mock client + manager + installer

#### 3. 集成测（约 200 行，R2#5 不可砍）

`apps/mobile/test/integration/manifest_sync_test.dart`：
- sqflite_common_ffi 真 drift + mock HTTP server
- 全 flow：fetch → download → checksum → install → drift 反查
- 边界 cases：网络断 / checksum 不对 / drift transaction rollback / brotli reject / 非 examples kind skip
- **R2#5**：集成测**是核心风险验证**，超时不砍；如真超时砍 UI 入口或文档舒适项，但保留至少一个 happy path 集成测

#### 4. 启动行为不变验证（变体 C 关键约束，R1#11/R1#12 修订）

**PowerShell 命令**（R1#12 cross-platform）：
```powershell
# 1. main.dart 没新增 ContentPackageService 调用
Select-String -Path apps\mobile\lib\main.dart -Pattern "ContentPackageService"
# 期望: 无匹配

# 2. WordbookLoader 未改
git diff main -- apps/mobile/lib/core/memory/wordbook_loader.dart
# 期望: 0 lines

# 3. assets/words bundle 大小不变（R1#10 + R2 小项）
(Get-ChildItem apps\mobile\assets\words\ -File -Recurse | Measure-Object Length -Sum).Sum
# 期望: ~5400000 ± 5%（5.4MB recon 实测）

# 4. 既有 wordbook_loader_test 不破基线（R1#11）
flutter test test\wordbook_loader_test.dart
# 期望: 全过

# 5. flutter analyze
flutter analyze
# 期望: 0 error
```

**Day 2 期望增量**：~500 行新代码 + ~400 行测试。

## 关键文件（路径全改对，R1#6 / R2#2）

### 新建
- `apps/mobile/lib/core/manifest/manifest_client.dart`
- `apps/mobile/lib/core/manifest/download_manager.dart`
- `apps/mobile/lib/core/manifest/package_installer.dart`
- `apps/mobile/lib/core/manifest/content_package_service.dart`
- `apps/mobile/lib/core/storage/drift/tables/content_package_state.dart`
- `apps/mobile/test/manifest_client_test.dart` / `download_manager_test.dart` / `package_installer_test.dart` / `content_package_service_test.dart`
- `apps/mobile/test/integration/manifest_sync_test.dart`
- `docs/design/pr-b2_v0.4.md`（本文档）
- `docs/design/v0.3_PR-B_scope_v0.4.md`（路线图）

### 修改
- `apps/mobile/lib/core/storage/drift/app_database.dart`（schemaVersion 11 → 12 + migration）

### 不动（关键）
- `apps/mobile/lib/main.dart`
- `apps/mobile/lib/core/memory/wordbook_loader.dart`
- `apps/mobile/lib/core/audio/audio_cache_repository.dart`
- `apps/mobile/assets/words/*.json`（5.4MB bundle 永驻）
- `apps/mobile/pubspec.yaml`（crypto / http / drift / path_provider 全部已在）
- 任何 server / migration / pipeline.py
- cdn-mock / audio-pipeline-staging 目录

## 风险

| 风险 | 缓解 |
|---|---|
| drift migration 破坏既有数据 | 仅 ADD 新表；测 v11→v12 |
| PackageInstaller 仅 examples 实装 | 其他 3 kind throw + 注释；ContentPackageService kind filter 提前 skip |
| `http` package 无 Range 续传 | 整包重下；retry 上限 3 次 |
| jsonl.gz 解压内存峰值 | 行级 stream 处理 |
| 既有 example_sentences 已有 bundled 数据 | InsertOrReplace 是预期行为（变体 C：manifest 是权威）|
| **fetch 全量 manifest 带宽**（D4）| manifest 本身才几百 byte，可忽略 |
| **brotli 包未来出现**（R1#3）| guard throw + 标 failed；PR-C 升级 dio 时支持 |
| Day 2 工作量超 2 天 | 仅 examples kind 实装其他 stub；service 仅写不接入；**超时砍 UI 入口或文档舒适项，集成测不砍**（R2#5）|

## 评审节奏

每个 Day 起手前单独写 day-plan，外部 review 后再开工：
- Day 1 plan → review → 实装 → commit
- Day 2 plan → review → 实装 → commit

## 验收清单

- [ ] drift schema v11 → v12，新表 `content_package_state` **12 列**（含 book_id / size_bytes / compression / min_app_version）
- [ ] migration 测试通过（v11 → v12 路径）
- [ ] ManifestClient 单测：fetch（全量，不传 since_release）/ 200 / 400 / 网络断
- [ ] DownloadManager 单测：成功 / checksum 不对 / 重试 / **brotli reject**
- [ ] PackageInstaller 单测：examples kind 解压 + drift 写入；其他 3 kind throw
- [ ] ContentPackageService 单测：**kind filter 提前 skip 非 examples** / state diff / install / upgrade / skip
- [ ] 集成测（**不可砍**）：mock CDN 全 flow（fetch → download → install → drift 反查）+ 边界（网络断 / checksum / brotli reject / 非 examples skip）
- [ ] **App 启动行为不变**：5 步 PowerShell 命令全过
- [ ] **assets/words bundle 不变**：du / Get-ChildItem 验证 ~5.4MB
- [ ] `flutter analyze` 0 error
- [ ] `flutter test` 全过（**含既有 wordbook_loader_test baseline**）
- [ ] PR_DESCRIPTION_PR-B2.md 写到 user dir

## PR-B2 之后（PR-B3 / PR-B4 简要，详 v0.3_PR-B_scope_v0.4.md §4-5）

PR-B3（2.5 天）：
- server staging serve route（0.5 天，D3 收口）
- mobile feature flag（SharedPreferences，0.5 天）
- WordbookLoader 改：查 content_package_state 决定清表 / INSERT IGNORE（1 天，D1 收口）
- 异步触发 ContentPackageService.syncIfNeeded()（flag=true 时）

PR-B4（1 天）：
- flag 默认开
- main.dart 启动序列加 sync hook（5s 超时）
- 设置页"检查内容更新"按钮
