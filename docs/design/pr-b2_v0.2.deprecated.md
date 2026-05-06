> **⚠️ DEPRECATED — 2026-05-06（变体 A 上下文，用户选了变体 C）**
> 本 v0.2 master plan 的 Context 假设 PR-B4 会做"减 APK + minimum-set"。
> 用户改选 **变体 C**：bundle 永驻 + manifest 增量覆盖。PR-B2 范围本身不变（仍 2 天），但 Context 描述需要刷新。
> **请阅读取代版本**: `pr-b2_v0.3.md`
> 本文保留作历史记录。

---

# v0.3 PR-B2 · mobile 基础设施（不切流量）— 2 天工作分解 v0.2

## Context

**Status:** SSOT v0.2，**取代** `pr-b2.md` v0.1（已 archive，6 天合并版超范围）。

**修正动机:** v0.1 把原 §B.10 的 PR-B / PR-C / PR-D 三个里程碑（mobile 基建 / feature flag / 默认开 + minimum-set）合并成一个 6 天 PR——违反"每个 PR 独立 revert"原则，丢了 feature flag 灰度保护。本 v0.2 严格回归原 §B.503-516 锁定的 PR-B 范围（2 天）。

PR-A 已 merge `b072eb3` + PR-B1 已 merge `b26bff7`，server 端发布闭环完整。
PR-B2 让 mobile 端**有能力消费 manifest**——但默认行为不变（不切流量）。

工作分支：`feat/v0.3-pr-b2-app-manifest-consumption` @ `b26bff7`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b2`

### 严格范围（原 §B.10 PR-B：§B.503-516）

> "drift v12 + content_package_state 表 + manifest fetch + 包下载校验导入逻辑。
> **默认走 bundled，不走 manifest**。WordbookLoader **不动**。"

### 完成条件（原 §B.513-516）

1. 单测覆盖：manifest fetch / 包下载 / checksum 校验 / row-level diff 导入 / 失败重试
2. 集成测：mock CDN 下放新包 → 触发服务 → 导入到 example_sentences
3. **App 默认行为不变**（仍走 bundled）

### 不做（明示边界——v0.1 错的全部踢出）

- ❌ 改 WordbookLoader（PR-B3 才加分支）
- ❌ feature flag（PR-B3 才加）
- ❌ 启动联动 / UI 入口（PR-B3 / PR-B4）
- ❌ minimum-set / 删 bundle（PR-B4）
- ❌ 后台进程 / BackgroundFetch（永远不做或 PR-C+）
- ❌ A/B 灰度 / ETag 缓存（v0.3 §B.13 占位，按需做）
- ❌ 真 CDN（按需触发）
- ❌ 改 server / API / migration

### 核实事实（recon 后）

- **drift v2.32.1**：4 个目标表全部存在（example_sentences / word_entries / preset_wordbooks / audio_file_cache）
- **http v1.1.0**（不是 dio）：现有 `api_client.dart:1-1802`，baseUrl `http://10.0.2.2:3000/api/v1`
- **WordbookLoader 模板**（`wordbook_loader.dart:26-204`）：idempotent + contentVersion 比对 + 版本差异 → 清表重导（**PR-B2 不改这里**，仅作 row-level diff 参考）
- **AudioCacheRepository 模板**（`audio_cache_repository.dart:25-208`）：download + sha256 + cache eviction（**模板复用**）
- **状态管理**：原生 StatefulWidget，无 Riverpod / Provider / bloc
- **启动序列**（`main.dart:27-62`）：LocalDatabase → AppDatabase → WordbookLoader×3 → EnrichmentBootstrap → runApp（**PR-B2 不改启动**）

## 2 天工作分解

### Day 1：drift schema v12 + ManifestClient + DownloadManager

**目标**：表 + HTTP fetch + 下载校验全部就绪，可单测。

主要工作：

**1. drift schema v11 → v12**
- 新表 `content_package_state`：
  ```dart
  class ContentPackageStates extends Table {
    TextColumn get packageId => text()();        // examples-zk@v5
    TextColumn get packageName => text()();      // examples-zk
    TextColumn get packageKind => text()();      // examples / audio_meta / wordbook / dictionary
    TextColumn get contentVersion => text()();   // v5
    TextColumn get releaseId => text()();        // 最近一次带它来的 release
    TextColumn get checksumSha256 => text()();   // 安装时 checksum（完整性校验）
    IntColumn get installedAt => integer()();    // unix ms
    TextColumn get fileUrl => text().nullable()();// 来源 URL（debug + 重新下载）

    @override
    Set<Column> get primaryKey => {packageId};
  }
  ```
- migration 步骤 v11 → v12：仅 `m.createTable(contentPackageStates)`（**纯 ADD，零数据迁移**）
- 测试 migration 路径：sqflite_common_ffi 模拟 v11 DB → 升级 v12 → 表存在

**2. ManifestClient**（约 200 行）
- 新文件 `lib/core/manifest/manifest_client.dart`
- `Future<ManifestResponse> fetchManifest({String? sinceRelease, String? appVersion})`
- DTO：`ManifestResponse(release_ids, packages)` / `ManifestPackage(packageId, packageName, packageKind, contentVersion, fileUrl, checksumSha256, sizeBytes, compression, minAppVersion, releaseId, bookId?)`
- 错误类型：`ManifestNetworkError` / `ManifestParseError`
- 复用 `api_client.dart` 风格（URI 拼接 / json.decode / Exception 包装）
- 单测：mock http response，覆盖 200 / 400 / 网络断开

**3. DownloadManager**（约 250 行）
- 新文件 `lib/core/manifest/download_manager.dart`
- `Future<File> downloadPackage(ManifestPackage pkg)`
- 流式写 `{cacheDir}/manifest_packages/.tmp/{packageId}.partial`
- sha256 累计计算（`crypto` package；如未在 pubspec 加依赖）
- 完整后：sha256 == manifest.checksum_sha256 → rename to `.gz`；否则删 + 抛 `ChecksumMismatchError`
- retry 策略：指数退避 3 次
- 单测：mock 下载 + sha256 mismatch + 重试

**Day 1 期望增量**：~450 行新代码 + ~350 行测试 + drift migration。

### Day 2：PackageInstaller + ContentPackageService + 集成测

**目标**：解压 + drift 写入 + service-level 编排 + 集成测。

主要工作：

**1. PackageInstaller**（约 300 行）
- 新文件 `lib/core/manifest/package_installer.dart`
- `Future<void> install(File gzFile, ManifestPackage pkg)`
- gzip 解压：`dart:io` GZipCodec.decoder（无新依赖）
- 按 `package_kind` 分发（**Day 2 仅完整实装 examples 一种**——其他 3 种 throw UnimplementedError，留 PR-B3 / PR-B4 加）
  - `_installExamples(jsonlLines)`：upsert 到 example_sentences（drift batch + InsertMode.insertOrReplace）
  - `_installAudioMeta(jsonlLines)`：throw UnimplementedError （audio_meta package 当前不存在；占位）
  - `_installWordbook(jsonlLines)`：throw UnimplementedError
  - `_installDictionary(jsonlLines)`：throw UnimplementedError
- 全 install 包裹 drift transaction，失败回滚
- 成功后 UPSERT `content_package_state`（同事务）
- 单测：fixture .jsonl.gz + 验证 drift 写入

**2. ContentPackageService**（约 200 行）
- 新文件 `lib/core/manifest/content_package_service.dart`
- 顶层 service，组合 ManifestClient + DownloadManager + PackageInstaller
- `Future<SyncResult> syncIfNeeded()` —— **此方法 Day 2 写好但无入口调用**（PR-B3 才接 WordbookLoader）
- 算法：
  1. 读本地 `content_package_state` 拿最近 release_id（`max(installedAt)`）
  2. 调 `ManifestClient.fetchManifest(sinceRelease=last_release_id, appVersion=appVer)`
  3. 对每个 package：
     - 本地无 packageId → 新装（先 download → install）
     - 本地有但 contentVersion 不同 → 升级（同上）
     - 本地有且版本一致 → skip
  4. 返回 SyncResult: installed[] / upgraded[] / failed[] / skipped[]
- 单测：mock client + manager + installer

**3. 集成测**（约 200 行）
- `test/integration/manifest_sync_test.dart`
- sqflite_common_ffi 真 drift + mock HTTP server
- 全 flow：fetch manifest → download → checksum → install → drift 反查
- 边界 cases：网络断 / checksum 不对 / drift transaction rollback / 已 imported 跳过

**4. 启动行为不变验证**（关键）
- grep `main.dart` 没新增 `ContentPackageService` 调用
- grep `wordbook_loader.dart` 未改
- `flutter analyze` 0 error
- `flutter test` 全过（包含既有 ~20 测试）

**Day 2 期望增量**：~500 行新代码 + ~400 行测试。

## 关键文件

### 新建
- `apps/mobile/lib/core/manifest/manifest_client.dart`
- `apps/mobile/lib/core/manifest/download_manager.dart`
- `apps/mobile/lib/core/manifest/package_installer.dart`
- `apps/mobile/lib/core/manifest/content_package_service.dart`
- `apps/mobile/lib/data/local/tables/content_package_state.dart`（drift 表定义）
- `apps/mobile/test/manifest_client_test.dart` / `download_manager_test.dart` / `package_installer_test.dart` / `content_package_service_test.dart`
- `apps/mobile/test/integration/manifest_sync_test.dart`
- `docs/design/pr-b2_v0.2.md`（本文档）
- `docs/design/v0.3_PR-B_scope_v0.2.md`（路线图）

### 修改
- `apps/mobile/lib/data/local/app_database.dart`（schemaVersion 11 → 12 + migration step）
- `apps/mobile/pubspec.yaml`（如需加 `crypto` 依赖；先 grep 确认）

### 不动（关键）
- `apps/mobile/lib/main.dart`（启动序列）
- `apps/mobile/lib/data/local/wordbook_loader.dart`
- `apps/mobile/lib/data/local/audio_cache_repository.dart`
- 任何 server / migration / pipeline.py
- cdn-mock 目录

## 风险

| 风险 | 缓解 |
|---|---|
| drift migration 破坏既有用户数据 | 仅 ADD 新表，零数据迁移；测 v11→v12 路径 |
| PackageInstaller 仅实装 examples 一种 | Day 2 明示限制；其他 3 种 throw UnimplementedError + 注释指向 PR-B3/B4 实装 |
| `http` package 无 Range 续传 | v1 简化整包重下；上限 3 次 retry；不写 content_package_state，下次启动重试 |
| jsonl.gz 解压内存峰值（examples-zk 约 5MB）| 行级 stream 处理（dart:io GZipCodec.decoder + LineSplitter）|
| 既有用户 example_sentences 已有数据，install 用 InsertOrReplace 是否覆盖错？| stable_id 主键：bundled 路径写 stable_id PK，manifest 路径同 stable_id PK 直接 replace（语义对：manifest 数据是 server 端权威）|
| Day 2 工作量超 2 天 | PackageInstaller 仅实装 examples（其他 3 种 stub）压缩范围；service 仅写好不接入；如真超时砍集成测留 Day 3（不存在的 day，意味着进 PR-B3）|
| 单测 mock 链复杂（client + manager + installer 三层）| 用 mocktail（如已在 pubspec）/ 手写 fake 实现；分别单测 + service-level 用 fake 组合 |

## 评审节奏

每个 Day 起手前单独写一个 day-plan，外部 review 后再开工：
- Day 1 plan → review → 实装 → commit
- Day 2 plan → review → 实装 → commit

## 验收清单

- [ ] drift schema v11 → v12，新表 `content_package_state` 创建
- [ ] migration 测试通过（v11 → v12 路径）
- [ ] ManifestClient 单测：fetch / 200 / 400 / 网络断
- [ ] DownloadManager 单测：成功 / checksum 不对 / 重试
- [ ] PackageInstaller 单测：examples kind 解压 + drift 写入；其他 3 kind throw
- [ ] ContentPackageService 单测：state diff / install / upgrade / skip
- [ ] 集成测：mock CDN 全 flow（fetch → download → install → drift 反查）
- [ ] **App 启动行为不变**：grep main.dart / wordbook_loader.dart 无新增调用
- [ ] `flutter analyze` 0 error
- [ ] `flutter test` 全过
- [ ] PR_DESCRIPTION_PR-B2.md 写到 user dir

## PR-B2 之后（PR-B3 起点）

PR-B3（feature flag）的范围由 `pr-b3-*.md` 详细 plan 定义，简要：
- WordbookLoader 加 if/else：flag → ContentPackageService.syncIfNeeded() / else → bundled
- flag 默认 false，从 `local_settings` 表读
- 关 flag regression test 通过
- App 默认行为依然不变

PR-B4（默认开 + minimum-set）：
- flag 默认 true
- 生成 `assets/words/minimum-set.json`（CET-4 前 200 词，~600KB）
- 删 `assets/words/{book-001,zk,gk}.json` 三个大文件
- WordbookLoader 默认走 manifest，未 imported 用 minimum-set 兜底
- 离线首启 + 在线首启 + 老用户升级三场景 smoke

PR-B5（清理，30 天后）：
- 删 feature flag
- 删 bundled fallback 兼容代码
- 写 retro

详见 `docs/design/v0.3_PR-B_scope_v0.2.md`。
