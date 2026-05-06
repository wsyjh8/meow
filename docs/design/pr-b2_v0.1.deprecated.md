> **⚠️ DEPRECATED — 2026-05-06**
> 本 v0.1 master plan 把原 §B.10 的 PR-B (mobile 基建) + PR-C (feature flag) + PR-D (默认开 + minimum-set) 三个独立里程碑合并成 6 天单 PR——**违反"每个 PR 独立 revert"原则**，丢了 feature flag 灰度保护。
> **请阅读取代版本**: `pr-b2_v0.2.md`（严格 2 天，仅 PR-B 范围；PR-B3/B4/B5 单独 plan）
> 本文保留作历史记录，**不要按它执行**。

---

# v0.3 PR-B2 · App 端 manifest 消费（6 天工作分解）

## Context

PR-A 已 merge（main @ `b072eb3`）+ PR-B1 已 merge（main @ `b26bff7`）。
Server 端发布闭环 + 治理工具都齐了，App 端还在 bundle-only 模式（v0.3 §A.1）。
PR-B2 让 Flutter App 真正消费 `GET /api/v1/content/manifest`，把包下载、校验、
落地、缓存失效完整跑通。

工作分支：`feat/v0.3-pr-b2-app-manifest-consumption` @ `b26bff7`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b2`

### 边界（明示）

- **100% mobile-only**——不动 server / cdn-mock 路径不变
- **继续打 cdn-mock**（http://10.0.2.2:3000 dev / LAN）；不接真 CDN（PR-B3）
- **不替换 WordbookLoader bundle 路径**——bundle 仍是首装兜底；manifest 提供"更新"覆盖
- **不做后台进程 / 推送**（BackgroundFetch / WorkManager 等留 PR-C）

### 5 大交付物（design doc §2）

| # | 交付物 | 主语 |
|---|---|---|
| 1 | `ManifestClient` | HTTP GET `/api/v1/content/manifest?since_release=&app_version=` 反序列化 + 错误处理 |
| 2 | `DownloadManager` | 流式下载 .gz → temp file → sha256 校验 → 移到 cache dir |
| 3 | `PackageInstaller` | gzip 解压 → 按 `package_kind` 分发到 drift（examples / audio_meta / wordbook / dictionary）|
| 4 | `CacheInvalidator` | state diff: local_package_state vs manifest → 决定 install/upgrade/grace |
| 5 | 启动联动 | 冷启动 + 刷新按钮触发 + 后台静默更新（不阻塞 UI）|

### 核实事实（recon 后）

- **drift v2.32.1**：4 个目标表全部存在（example_sentences / word_entries / preset_wordbooks / audio_file_cache）
- **http v1.1.0**（不是 dio）：现有 `api_client.dart:1-1802`，baseUrl hardcoded `http://10.0.2.2:3000/api/v1`
- **WordbookLoader 模板**（`wordbook_loader.dart:26-204`）：idempotent + contentVersion 比对 + 版本差异 → 清表重导
- **AudioCacheRepository 模板**（`audio_cache_repository.dart:25-208`）：download + sha256 + cache eviction
- **状态管理**：原生 StatefulWidget + WidgetsBindingObserver，**无 Riverpod / Provider / bloc**
- **启动序列**（`main.dart:27-62`）：LocalDatabase → AppDatabase → WordbookLoader×3 → EnrichmentBootstrap → runApp
- **测试**：~20 个 unit/service test，无 widget/integration，无 CI

## 6 天工作分解

### Day 1：drift schema + ManifestClient

**目标**：本地 release 状态追踪 + HTTP 客户端就绪。

主要工作：
- 新 drift 表 `local_package_state`：
  ```dart
  class LocalPackageStates extends Table {
    TextColumn get packageId => text()();        // examples-zk@v5（与 manifest.id 一致）
    TextColumn get packageName => text()();      // examples-zk
    TextColumn get packageKind => text()();      // examples / audio_meta / wordbook / dictionary
    TextColumn get contentVersion => text()();   // v5
    TextColumn get releaseId => text()();        // 最近一次带它来的 release
    TextColumn get checksumSha256 => text()();   // 安装时的 checksum（用于完整性校验）
    IntColumn get installedAt => integer()();    // unix ms
    TextColumn get fileUrl => text().nullable()(); // 来源（debug + 重新下载时用）

    @override
    Set<Column> get primaryKey => {packageId};
  }
  ```
- drift migration 加 v12（schemaVersion 从 v11 → v12）
- 新文件 `lib/core/manifest/manifest_client.dart`（约 200 行）：
  - `ManifestResponse` DTO（release_ids + packages）
  - `ManifestPackage` DTO（与 server controller 字段对齐）
  - `Future<ManifestResponse> fetchManifest({String? sinceRelease, String? appVersion})`
  - 错误类型：`ManifestNetworkError` / `ManifestParseError`（区分 caller 处置）
  - **复用 api_client.dart 风格**：URI 拼接、json.decode、Exception 包装
- 单元测试：`test/manifest_client_test.dart`（mock http response，覆盖 200/400/网络断开）

期望增量：~250 行新代码 + ~150 行测试。

### Day 2：DownloadManager

**目标**：流式下载 + sha256 + retry。

主要工作：
- 新文件 `lib/core/manifest/download_manager.dart`（约 280 行）：
  - `Future<File> downloadPackage(ManifestPackage pkg, {Function(double)? onProgress})`
  - 流式写 `{cacheDir}/manifest_packages/.tmp/{pkg.packageId}.partial`
  - sha256 累计计算（`crypto` package，已在 pubspec？需查）
  - 完整下载后：sha256 == manifest.checksum_sha256 → rename to `.gz`；否则删 + 抛 `ChecksumMismatchError`
  - retry 策略：指数退避 3 次，每次失败保留 .partial 等下次复用（**不实装 HTTP Range**——`http` package 不直接支持，简化为 v1 不续传）
  - 并发控制：semaphore max=2（避免抢带宽）
  - 取消（cancel token，配合 dispose）
- 单元测试：mock 下载 + sha256 mismatch + 重试场景

**关键设计**：
- 不实装 Range resume（PR-B2 v1 简化；PR-C 升级用 dio 时再考虑）
- 失败 retry 上限 3 次后标记 `package_state.broken=true`（drift 可加列；或单独 broken_packages 表）—— 简化方案：保留 `local_package_state` 不写，下次启动重试

期望增量：~280 行新代码 + ~200 行测试。

### Day 3：PackageInstaller

**目标**：gzip 解压 + drift 各表写入。

主要工作：
- 新文件 `lib/core/manifest/package_installer.dart`（约 350 行）：
  - `Future<void> install(File gzFile, ManifestPackage pkg)`
  - 解压用 `dart:io` GZipCodec.decoder（无新依赖）
  - 按 `package_kind` 分发（4 个子函数）：
    - `_installExamples(jsonlLines)`：upsert 到 example_sentences（drift batch + InsertMode.insertOrReplace）
    - `_installAudioMeta(jsonlLines)`：写到 audio_file_cache (metadata only，不下载 audio file 本身，那是 AudioCacheRepository 职责)
    - `_installWordbook(jsonlLines)`：写到 preset_wordbooks + word_entries + word_book_assignments
    - `_installDictionary(jsonlLines)`：写到 dictionary 表（如果有，否则 PR-C 加）
  - 全 install 包裹在 drift transaction，失败回滚
  - 成功后 UPDATE `local_package_state`（同事务）
  - **大文件优化**：用 `compute()` 把解压 + parse JSON 放 isolate（避免阻塞 UI 线程）
- 单元测试：用 fixture .jsonl.gz（手工构造小样本）+ 验证 drift 写入

**关键设计**：
- examples 包：每行 JSON 用 stable_id 作 PK，用 InsertOrReplace 覆盖现有行（与 WordbookLoader bundle 路径并存——manifest 数据后到，覆盖 bundle）
- 不删原 WordbookLoader bundle 数据；只覆盖
- jsonl 而不是单 json：减少内存峰值

期望增量：~350 行新代码 + ~250 行测试。

### Day 4：CacheInvalidator + Orchestrator

**目标**：state diff + 决策 install/upgrade/skip。

主要工作：
- 新文件 `lib/core/manifest/manifest_service.dart`（约 250 行）：
  - 顶层 service，组合 ManifestClient + DownloadManager + PackageInstaller
  - `Future<SyncResult> syncFromManifest({bool forceFull = false})`
  - 算法：
    1. 读本地 `local_package_state` 拿最近 release_id（pick 最大 installed_at）
    2. 调 ManifestClient.fetchManifest(sinceRelease=last_release_id, appVersion=appVer)
    3. 对每个 package：
       - 本地无 packageId → 新装（先 download → install）
       - 本地有 packageId 但 contentVersion 不同 → 升级（同上）
       - 本地有 packageId 且版本一致 → skip
    4. 收集 SyncResult：installed[] / upgraded[] / failed[] / skipped[]
- deprecate 处理：当前 manifest API 返 dual-condition (release.status='active' AND m.is_active=true)，已 deprecate 的不返；本地 grace 处理 = 不动（用户网络差时仍能用本地包）
- service-level test（mock client + manager + installer）

期望增量：~250 行新代码 + ~200 行测试。

### Day 5：启动联动 + UI hooks

**目标**：用户能感知 / 触发 manifest 更新。

主要工作：
- `main.dart` 加 manifest sync 步骤（在 WordbookLoader 之后，runApp 之前 OR 后）：
  - **方案 A（推荐）**：runApp 之前 5s 超时 silent fetch（与 EnrichmentBootstrap 并列）
  - **方案 B**：runApp 之后异步 fetch（不阻塞首屏渲染，但可能用户看到旧数据）
  - 选 A 与 EnrichmentBootstrap 一致语义；超时 fallback 用本地数据继续
- 新 settings page 入口"内容包" / "刷新词书数据"（手动触发）
- 错误状态展示：toast / snackbar（遵循 v0.3 喵喵 UI 偏萌风格）
- StatefulWidget 集成（无 Riverpod，按现有 pattern）

期望增量：~150 行新代码（涉及多文件，散开少量）+ ~100 行测试。

### Day 6：测试 + README + smoke + PR 描述

**目标**：收尾 + PR 就绪。

主要工作：
- 集成测试：sqflite_common_ffi mock server 走完整 flow
- 边界 cases：网络断开 / 下载到一半挂掉 / checksum mismatch / drift transaction rollback
- 手动 smoke：开 dev API + cdn-mock + 真机 / Emulator 跑
  - 触发 syncFromManifest
  - 反查 drift `local_package_state` + `example_sentences` 是否新增
- README：在 `apps/mobile/README.md`（如有）或 `lib/core/manifest/README.md` 写说明
- PR_DESCRIPTION_PR-B2.md 写到 `C:\Users\lenovo\.claude\`
- `flutter analyze` 0 error
- `flutter test` 全过

期望增量：~100 行测试 + 文档。

## 关键文件

### 新建（PR-B2 内）
- `apps/mobile/lib/core/manifest/manifest_client.dart`
- `apps/mobile/lib/core/manifest/download_manager.dart`
- `apps/mobile/lib/core/manifest/package_installer.dart`
- `apps/mobile/lib/core/manifest/manifest_service.dart`
- `apps/mobile/lib/data/local/tables/local_package_state.dart`（drift 表）
- `apps/mobile/test/manifest_client_test.dart` / `download_manager_test.dart` / `package_installer_test.dart` / `manifest_service_test.dart`
- `docs/design/pr-b2.md`（本文档）
- `docs/design/pr-b2-day{1..6}-*.md`（每日详细 plan）

### 修改
- `apps/mobile/lib/data/local/app_database.dart`（schemaVersion 11 → 12 + migration step）
- `apps/mobile/lib/main.dart`（启动联动 hook）
- `apps/mobile/pubspec.yaml`（如需加 `crypto` 依赖）
- `apps/mobile/lib/ui/pages/settings_page.dart`（如有）/ home_page.dart（manual refresh hook）

### 不动
- 任何 server / migration / pipeline.py 代码
- WordbookLoader bundle 路径（PR-B2 仅在它之上覆盖；不删 bundle）
- AudioCacheRepository（audio_meta package 写 metadata 不动这里的下载逻辑）
- cdn-mock 目录结构

## 风险

| 风险 | 缓解 |
|---|---|
| drift schema migration 破坏现有用户数据 | 用 drift 标准 migration 框架（v11 → v12），仅 ADD 新表，不动现有；测试 upgrade 路径 |
| 大包下载阻塞 UI | DownloadManager 全部走 isolate / async；进度回调 UI 旁路 |
| 多包并发下载抢带宽 | semaphore max=2 + 优先级队列（按 package_kind：examples 优先，audio_meta 次之）|
| sha256 mismatch 反复 retry 死循环 | 上限 3 次后标记 broken；不写 local_package_state，下次启动重试 |
| jsonl.gz 解压内存峰值 | 行级 stream 处理 + isolate 隔离 |
| `http` package 无 Range 续传 | v1 简化不实装；下载失败重新整包；PR-C 升级 dio 时再加 |
| 本地版本与服务端版本不一致（如 server 撤回老版本但客户端已装）| 客户端不主动 deprecate 本地包（grace 期网络差时仍能用）；下次有 active 升级时自然替换 |
| Day 6 工作量超 6 天预算 | Day 5 / Day 6 砍 settings UI 入口（保留 main.dart 自动 sync 即可）|

## 评审节奏（沿用 PR-A / PR-B1 模式）

每个 Day 起手前单独写一个 day-plan，外部 review 后再开工：
- Day 1 plan → review → 实装 → commit
- Day 2 plan → review → 实装 → commit
- ...

本 master plan 让 PR-B2 整体可见，避免 6 天分别看不到全貌。

## 验收清单（PR-B2 总）

- [ ] 5 大交付物实装（ManifestClient / DownloadManager / PackageInstaller / CacheInvalidator / 启动联动）
- [ ] drift schema migration v11 → v12（新表 local_package_state）
- [ ] 单元测试覆盖：4 个新模块各 ~10 cases
- [ ] 集成测试：mock server full flow + 边界 cases
- [ ] 手动真机 smoke：触发 sync → drift 反查
- [ ] `flutter analyze` 0 error
- [ ] `flutter test` 全过
- [ ] README + PR 描述就绪
- [ ] 不动 server / API / migration（grep 验证）
- [ ] WordbookLoader bundle 路径不破坏（启动序列保留）

## 不做的事

- **不**改 server 端任何代码
- **不**接真 CDN（PR-B3）
- **不**做后台进程（BackgroundFetch / WorkManager）（PR-C 候选）
- **不**做 A/B 灰度路由（PR-C 候选）
- **不**做 manifest API 客户端缓存（ETag）（v0.3 §B.13.2 占位 / PR-C）
- **不**改 WordbookLoader bundle 路径（manifest 在它之上覆盖）
- **不**做多语言（manifest 字段已含 locale，UI 不动）
- **不**改 PR-A 既有 audio cache 逻辑

## PR-B2 之后（PR-B3 起点）

PR-B2 收官即 PR-B3 起点。PR-B3 待办（按 scope §3）：
- 真 CDN 接入（替换 cdn-mock；触发条件：用户买服务器）
- 审批 Web UI（多人协作时；与 `rollback_target_id` 启用一起）
- DownloadManager 升级 dio 加 Range/resume

## 设计参考

- v0.3 主架构 doc §B.6 / §B.10 / §B.12
- PR-A `apps/api/scripts/content_pipeline/README.md`（manifest API 字段定义）
- PR-A `apps/api/src/controllers/content-manifest.controller.ts`（response shape SSOT）
- mobile 现有 `wordbook_loader.dart` / `audio_cache_repository.dart`（idempotent + 缓存模板）
- mobile 现有 `api_client.dart`（HTTP client 风格）
