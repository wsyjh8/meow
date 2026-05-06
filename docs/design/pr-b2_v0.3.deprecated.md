> **⚠️ DEPRECATED — 2026-05-06**
> 本 v0.3 走变体 C 但留下 4 个 scope 层未收口：WordbookLoader 升级清表冲突 / server staging URL 不可下载 / since_release checkpoint 漏失败包 / tombstone 未明确。两份外部评审打中。
> **请阅读取代版本**: `v0.3_PR-B_scope_v0.4.md` / `pr-b2_v0.4.md`
> 本文保留作历史记录。

---

# v0.3 PR-B2 · mobile 基础设施（不切流量）— 2 天工作分解 v0.3

## Context

**Status:** SSOT v0.3，**取代** v0.1（错路线）+ v0.2（变体 A 上下文）。
**变体决策**: 用户选 **变体 C** —— bundle 永驻 + manifest 增量覆盖；APK 不减包；无 PR-B5 清理步。

**PR-B2 范围在变体 A / C 下完全一致**——都是基建 + 不切流量。本 v0.3 仅刷新
Context 描述（指向 v0.3 路线图），实施步骤、代码、测试与 v0.2 完全相同。

PR-A 已 merge `b072eb3` + PR-B1 已 merge `b26bff7`。
PR-B2 让 mobile 端**有能力消费 manifest**——但默认行为不变（不切流量）。

工作分支：`feat/v0.3-pr-b2-app-manifest-consumption` @ `b26bff7`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b2`

### 严格范围（原 §B.10 PR-B：§B.503-516）

> "drift v12 + content_package_state 表 + manifest fetch + 包下载校验导入逻辑。
> **默认走 bundled，不走 manifest**。WordbookLoader **不动**。"

### 变体 C 上下文澄清（关键）

PR-B2 在变体 C 下的位置：
- 现在：bundled 启动写 drift（永远；APK 5.6MB）
- PR-B2：**加新模块代码 + 单测；零调用入口**——App 行为不变
- PR-B3：加 feature flag（默认关）+ WordbookLoader 加异步 sync 调用
- PR-B4：flag 默认开 + 接入启动序列；APK 仍 5.6MB；bundle 永驻
- ~~PR-B5~~：删除（变体 C 无 fallback 清理）

**变体 C vs 变体 A 对 PR-B2 的影响**：完全无影响。本 PR 范围、代码、测试 100% 一致。

### 完成条件（原 §B.513-516）

1. 单测覆盖：manifest fetch / 包下载 / checksum 校验 / row-level diff 导入 / 失败重试
2. 集成测：mock CDN 下放新包 → 触发服务 → 导入到 example_sentences
3. **App 默认行为不变**（仍走 bundled）

### 不做（明示边界）

- ❌ 改 WordbookLoader（PR-B3）
- ❌ feature flag（PR-B3）
- ❌ 启动联动 / UI 入口（PR-B4）
- ❌ 改 main.dart 启动序列
- ❌ minimum-set / 删 bundle（**变体 C 永远不做**）
- ❌ 后台进程 / BackgroundFetch
- ❌ A/B 灰度 / ETag 缓存
- ❌ 真 CDN
- ❌ 改 server / API / migration

### 核实事实（recon 后，与 v0.2 一致）

- **drift v2.32.1**：4 个目标表全部存在
- **http v1.1.0**（不是 dio）：现有 `api_client.dart:1-1802`，baseUrl `http://10.0.2.2:3000/api/v1`
- **WordbookLoader 模板**（`wordbook_loader.dart:26-204`）：idempotent + contentVersion 比对（**PR-B2 不改**）
- **AudioCacheRepository 模板**（`audio_cache_repository.dart:25-208`）：download + sha256 + cache eviction（**模板复用**）
- **状态管理**：原生 StatefulWidget
- **启动序列**（`main.dart:27-62`）：LocalDatabase → AppDatabase → WordbookLoader×3 → EnrichmentBootstrap → runApp（**PR-B2 不改**）

## 2 天工作分解

### Day 1：drift schema v12 + ManifestClient + DownloadManager

**目标**：表 + HTTP fetch + 下载校验全部就绪，可单测。

#### 1. drift schema v11 → v12

新表 `content_package_state`：
```dart
class ContentPackageStates extends Table {
  TextColumn get packageId => text()();        // examples-zk@v5
  TextColumn get packageName => text()();      // examples-zk
  TextColumn get packageKind => text()();      // examples / audio_meta / wordbook / dictionary
  TextColumn get contentVersion => text()();   // v5
  TextColumn get releaseId => text()();        // 最近一次带它来的 release
  TextColumn get checksumSha256 => text()();   // 安装时 checksum
  IntColumn get installedAt => integer()();    // unix ms
  TextColumn get fileUrl => text().nullable()();// debug + 重新下载

  @override
  Set<Column> get primaryKey => {packageId};
}
```

migration：仅 `m.createTable(contentPackageStates)`（**纯 ADD**）。
测试 v11 → v12 路径（sqflite_common_ffi）。

#### 2. ManifestClient（约 200 行）

`lib/core/manifest/manifest_client.dart`：
- `Future<ManifestResponse> fetchManifest({String? sinceRelease, String? appVersion})`
- DTO：`ManifestResponse(release_ids, packages)` / `ManifestPackage` 字段对齐 server controller
- 错误：`ManifestNetworkError` / `ManifestParseError`
- 复用 `api_client.dart` 风格
- 单测：mock http 200 / 400 / 网络断

#### 3. DownloadManager（约 250 行）

`lib/core/manifest/download_manager.dart`：
- `Future<File> downloadPackage(ManifestPackage pkg)`
- 流式写 `{cacheDir}/manifest_packages/.tmp/{packageId}.partial`
- sha256 累计校验（`crypto` package；如未在 pubspec 加依赖）
- 完整后 sha256 == manifest.checksum_sha256 → rename to `.gz`；否则删 + `ChecksumMismatchError`
- retry 指数退避 3 次
- 单测：mock 下载 + sha256 mismatch + 重试

**Day 1 期望增量**：~450 行新代码 + ~350 行测试 + drift migration。

### Day 2：PackageInstaller + ContentPackageService + 集成测

**目标**：解压 + drift 写入 + service-level 编排 + 集成测。

#### 1. PackageInstaller（约 300 行）

`lib/core/manifest/package_installer.dart`：
- `Future<void> install(File gzFile, ManifestPackage pkg)`
- gzip 解压：`dart:io` GZipCodec.decoder
- 按 `package_kind` 分发（**Day 2 仅完整实装 examples 一种**）
  - `_installExamples(jsonlLines)`：upsert example_sentences (drift batch + InsertMode.insertOrReplace)
  - 其他 3 种 throw UnimplementedError + 注释指向 PR-B3/B4
- drift transaction wrap，失败回滚
- 成功后 UPSERT `content_package_state`（同事务）
- 单测：fixture .jsonl.gz + 验证 drift 写入

#### 2. ContentPackageService（约 200 行）

`lib/core/manifest/content_package_service.dart`：
- 顶层 service，组合 ManifestClient + DownloadManager + PackageInstaller
- `Future<SyncResult> syncIfNeeded()` —— **Day 2 写好但无入口调用**（PR-B3 才接）
- 算法：
  1. 读本地 `content_package_state` 拿最近 release_id（`max(installedAt)`）
  2. 调 `ManifestClient.fetchManifest(sinceRelease=last_release_id, appVersion=appVer)`
  3. 对每个 package：
     - 本地无 → 新装
     - 本地有但 contentVersion 不同 → 升级
     - 本地有且版本一致 → skip
  4. 返回 SyncResult: installed[] / upgraded[] / failed[] / skipped[]
- 单测：mock client + manager + installer

#### 3. 集成测（约 200 行）

`test/integration/manifest_sync_test.dart`：
- sqflite_common_ffi 真 drift + mock HTTP server
- 全 flow：fetch → download → checksum → install → drift 反查
- 边界 cases：网络断 / checksum 不对 / drift transaction rollback

#### 4. 启动行为不变验证（变体 C 关键约束）

- grep `main.dart` 没新增 `ContentPackageService` 调用
- grep `wordbook_loader.dart` 未改
- grep APK assets size: `du -sh apps/mobile/assets/words/` 不变
- `flutter analyze` 0 error
- `flutter test` 全过

**Day 2 期望增量**：~500 行新代码 + ~400 行测试。

## 关键文件

### 新建
- `apps/mobile/lib/core/manifest/manifest_client.dart`
- `apps/mobile/lib/core/manifest/download_manager.dart`
- `apps/mobile/lib/core/manifest/package_installer.dart`
- `apps/mobile/lib/core/manifest/content_package_service.dart`
- `apps/mobile/lib/data/local/tables/content_package_state.dart`
- `apps/mobile/test/manifest_client_test.dart` / `download_manager_test.dart` / `package_installer_test.dart` / `content_package_service_test.dart`
- `apps/mobile/test/integration/manifest_sync_test.dart`
- `docs/design/pr-b2_v0.3.md`（本文档）
- `docs/design/v0.3_PR-B_scope_v0.3.md`（路线图）

### 修改
- `apps/mobile/lib/data/local/app_database.dart`（schemaVersion 11 → 12 + migration step）
- `apps/mobile/pubspec.yaml`（如需加 `crypto` 依赖；先 grep 确认）

### 不动（关键）
- `apps/mobile/lib/main.dart`
- `apps/mobile/lib/data/local/wordbook_loader.dart`
- `apps/mobile/lib/data/local/audio_cache_repository.dart`
- `apps/mobile/assets/words/*.json`（5.6MB bundle 永驻）
- 任何 server / migration / pipeline.py
- cdn-mock 目录

## 风险

| 风险 | 缓解 |
|---|---|
| drift migration 破坏既有用户数据 | 仅 ADD 新表，零数据迁移；测 v11→v12 |
| PackageInstaller 仅 examples 实装 | 其他 3 种 throw UnimplementedError + 注释指向 PR-B3/B4 |
| `http` package 无 Range 续传 | 整包重下；retry 上限 3 次 |
| jsonl.gz 解压内存峰值 | 行级 stream 处理 |
| 既有用户 example_sentences 已有 bundled 数据，install 用 InsertOrReplace 是否覆盖错？| **变体 C 设计如此**——manifest 是权威，覆盖 bundled 是预期行为 |
| Day 2 工作量超 2 天 | 仅 examples kind 实装其他 stub；service 仅写不接入；超时砍集成测 |

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
- [ ] **APK 大小不变**：grep / du `apps/mobile/assets/words/` 5.6MB 保持
- [ ] `flutter analyze` 0 error
- [ ] `flutter test` 全过
- [ ] PR_DESCRIPTION_PR-B2.md 写到 user dir（user dir = `C:\Users\lenovo\.claude\`）

## PR-B2 之后（PR-B3 / PR-B4 简要）

PR-B3：feature flag 默认关 + WordbookLoader 加异步 sync 调用（不阻塞 bundled 路径，叠加上去）。
PR-B4：flag 默认开 + main.dart 启动序列加 sync hook + 设置页"检查更新"按钮。

详见 `docs/design/v0.3_PR-B_scope_v0.3.md` §4-5。
