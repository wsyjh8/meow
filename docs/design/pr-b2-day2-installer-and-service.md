# v0.3 PR-B2 · Day 2 plan v0.2 — PackageInstaller + ContentPackageService + 集成测

## Context

PR-B2 Day 1 已 merge `6557fb4`。Day 2 plan v0.1 收到两份外部评审，去重后 **16 处真改进**。本 v0.2 全部吸收。

工作分支：`feat/v0.3-pr-b2-app-manifest-consumption` @ `6557fb4`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b2`
对照基线 commit：`b26bff7`（PR-B1 merge 点）

## v0.1 → v0.2 修订（吸收两份评审 16 处）

### 🔴 P1 必修（功能性 bug）

| # | 来源 | 修订 |
|---|---|---|
| 1 | R1#1 / R2#1 | **`_upsertPackageState` 改 DELETE WHERE packageName + INSERT**：避免升级后留旧 packageId 行污染 state 表，破坏 packageName-索引 race |
| 2 | R2#2 | **ContentPackageService 共享 effective db**：default installer 不再独立 new AppDatabase()，避免注入 db 后写到另一套 |
| 3 | R2#3 | **空 examples 包 throw InstallFailedError**：≥ 1 行有效 jsonl 才视为成功，否则 transaction 回滚 state |
| 4 | R2#4 | **stable_id 缺/空 throw**：null 不被 SQLite unique index 约束，会破坏 InsertOrReplace 覆盖语义 |

### 🟡 P2 应修

| # | 来源 | 修订 |
|---|---|---|
| 5 | R1#2 | 注释删"行级 stream"，与 `.toList()` 实装一致（drift batch callback 必须 sync）|
| 6 | R1#3 | 单测加 "install ok but state UPSERT fails → example_sentences 也 rollback" |
| 7 | R1#4 | plan 加注：双 unique index + InsertOrReplace + server 包内 dedup 责任 |
| 8 | R1#5 / R1#12 | **cacheDir + db 都改 required**：删 systemTemp / AppDatabase() 默认值 |
| 9 | R1#6 | `upgraded` → `replaced`（含 rollback downgrade 场景）|
| 10 | R1#7 | baseline 6 failures 验证命令具体化（diff 失败列表）|
| 11 | R1#8 | git diff 用 `b26bff7` 精确 hash 对照 |
| 12 | R2#5 | SyncResult 加 `manifestError` 顶层字段，调用方区分 sync 失败 vs 无变化 |

### 🟢 Nit

| # | 来源 | 修订 |
|---|---|---|
| 13 | R1#9 | `catch (e, st)` 保 stack trace（`Error.throwWithStackTrace`）|
| 14 | R1#10 | 集成测 `_FakeManifestCdnServer` helper 减重复 |
| 15 | R1#11 | 风险表降级优先级写清（doc → 单测 → 集成测，集成测底线）|
| 16 | R1#12 | PackageInstaller `required AppDatabase db`（同 #8）|

## 实施

### Step 1：PackageInstaller v0.2

文件：`apps/mobile/lib/core/manifest/package_installer.dart`（~310 行）

#### 1a. 错误类（不变）

```dart
class UnsupportedKindError implements Exception {
  final String packageKind;
  UnsupportedKindError(this.packageKind);
  @override
  String toString() =>
      'UnsupportedKindError($packageKind): only "examples" implemented in PR-B2';
}

class InstallFailedError implements Exception {
  final String packageId;
  final String message;
  InstallFailedError(this.packageId, this.message);
  @override
  String toString() => 'InstallFailedError($packageId, $message)';
}
```

#### 1b. 主类（v0.2 关键修订）

```dart
class PackageInstaller {
  final AppDatabase _db;

  /// #16 review-adopted: db 改 required（避免测试漏传时 new 真 AppDatabase）。
  PackageInstaller({required AppDatabase db}) : _db = db;

  Future<void> install(File gzFile, ManifestPackage pkg) async {
    if (pkg.packageKind != 'examples') {
      throw UnsupportedKindError(pkg.packageKind);
    }
    if (!await gzFile.exists()) {
      throw InstallFailedError(pkg.packageId, 'file not found: ${gzFile.path}');
    }

    await _db.transaction(() async {
      try {
        final rowsInstalled = await _installExamples(gzFile, pkg);
        // #3 review-adopted: 空包不算成功（防止 server 出 0-row 包导致客户端
        // 误以为已安装，跳过后续 sync）
        if (rowsInstalled == 0) {
          throw InstallFailedError(
            pkg.packageId,
            'installed 0 rows from gz; package is empty or all rows invalid',
          );
        }
        await _upsertPackageState(pkg);
      } on InstallFailedError {
        rethrow;  // 已是 InstallFailedError，直接重抛保留 packageId
      } on UnsupportedKindError {
        rethrow;
      } on Object catch (e, st) {
        // #13 review-adopted: 保 stack trace
        Error.throwWithStackTrace(
          InstallFailedError(pkg.packageId, '$e'),
          st,
        );
      }
    });
  }

  /// 注释 #5 修订：drift batch callback 必须 sync，所以 .toList() 强制 buffer
  /// 全部行。单包 gzip 后 ≤ 2MB，解压后 ~5-10MB；buffer 内存可接受。
  /// （行级 stream + 单 INSERT 是另一种实现，但放弃 batch 优化的批量提交。）
  ///
  /// Returns: 实际 insert 的有效 jsonl 行数。
  Future<int> _installExamples(File gzFile, ManifestPackage pkg) async {
    final lines = await gzFile
        .openRead()
        .transform(gzip.decoder)
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();

    var inserted = 0;
    await _db.batch((batch) {
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final j = jsonDecode(line) as Map<String, dynamic>;

        // #4 review-adopted: stable_id 必须非空非 null
        final stableId = j['stable_id'] as String?;
        if (stableId == null || stableId.isEmpty) {
          throw InstallFailedError(
            pkg.packageId,
            'jsonl line missing stable_id; manifest covering semantics '
            'depend on it (SQLite unique index does not constrain NULL)',
          );
        }

        batch.insert(
          _db.exampleSentences,
          ExampleSentencesCompanion.insert(
            wordId: j['word_id'] as String,
            sense: (j['sense_label'] as String?) ?? '',
            en: j['en'] as String,
            cn: j['cn'] as String,
            sortOrder: Value((j['ordinal'] as int?) ?? 0),
            stableId: Value(stableId),
          ),
          mode: InsertMode.insertOrReplace,
        );
        inserted++;
      }
    });
    return inserted;
  }

  /// #1 review-adopted: DELETE WHERE packageName + INSERT。
  /// 升级 examples-zk@v3 → examples-zk@v5 时，先删 v3 row 再插 v5；
  /// 同 transaction 内 atomic，保证 state 表 "每个 packageName ≤ 1 行"。
  Future<void> _upsertPackageState(ManifestPackage pkg) async {
    await (_db.delete(_db.contentPackageStates)
          ..where((t) => t.packageName.equals(pkg.packageName)))
        .go();
    await _db.into(_db.contentPackageStates).insert(
          ContentPackageStatesCompanion.insert(
            packageId: pkg.packageId,
            packageName: pkg.packageName,
            packageKind: pkg.packageKind,
            contentVersion: pkg.contentVersion,
            releaseId: pkg.releaseId,
            checksumSha256: pkg.checksumSha256,
            installedAt: DateTime.now().millisecondsSinceEpoch,
            bookId: Value(pkg.bookId),
            sizeBytes: Value(pkg.sizeBytes),
            compression: Value(pkg.compression),
            minAppVersion: Value(pkg.minAppVersion),
            fileUrl: Value(pkg.fileUrl),
          ),
        );
  }
}
```

#### 1c. 设计注释 #7（双 unique index + server 责任）

加在 install 方法 docstring：

> **example_sentences 双 unique index 语义**（#7 review-adopted）：
> 表上有 `(stableId)` + `(wordId, sortOrder)` 两个 unique index。
> InsertOrReplace 触发任一冲突都会 DELETE 旧行 + INSERT 新行。
> **本设计依赖 server `build_examples_package` 在单包内保证 (wordId,
> sortOrder) 唯一**（PR-A README §6 设计要点 5 "Full snapshot"）。
> 若未来发现包内重复，先排查 server build 而非 client side（client 会
> 静默 dedup 让最后一行赢，难以察觉）。

#### 1d. 单测 v0.2（7 cases，加 4 个评审 case）

文件：`apps/mobile/test/core/manifest/package_installer_test.dart`

```dart
test('happy: install examples package writes drift + state', ...);
test('insertOrReplace: existing stable_id row replaced (manifest > bundle)',
    ...);
test('non-examples kind → UnsupportedKindError, no drift writes', ...);
test('file missing → InstallFailedError', ...);
test('drift transaction rollback on bad jsonl line: state not written', ...);

// #1 review-adopted (state 表不膨胀)
test('upgrade does not leave stale row of old contentVersion in state table',
    () async {
  // 1. install examples-zk@v3 → state 1 行
  // 2. install examples-zk@v5 → state 仍 1 行 (v3 row 已删)
  // 3. 验证 state 表 size == 1, contentVersion == 'v5'
});

// #3 review-adopted (空包不算成功)
test('empty examples package → InstallFailedError, state not written',
    () async {
  // gz 解压后 0 行 → throw InstallFailedError
  // state 表 0 行（transaction rollback）
});

// #4 review-adopted (stable_id 必须非空)
test('jsonl missing stable_id → InstallFailedError, transaction rollback',
    () async {
  // 1 行有效 + 1 行 stable_id=null → throw
  // example_sentences 0 行 (rollback), state 0 行
});

// #6 review-adopted (transaction 嵌套真测)
test('install ok but state UPSERT fails: example_sentences also rolled back',
    () async {
  // mock _upsertPackageState 抛错（如 mock db.into() throw）
  // 验证 example_sentences 0 行 + state 0 行
});
```

**Day 2 期望增量（Step 1）**：~310 行新代码 + ~350 行测试（9 cases）。

### Step 2：ContentPackageService v0.2

文件：`apps/mobile/lib/core/manifest/content_package_service.dart`（~250 行）

#### 2a. SyncResult v0.2（加 manifestError 顶层字段，#12）

```dart
class SyncResult {
  final List<String> installed;
  /// #9 review-adopted: 改名 `replaced`（含 rollback downgrade 场景，
  /// 不止单调升级）。
  final List<String> replaced;
  final List<String> skipped;
  final List<String> failed;
  final Map<String, String> failureReasons;
  /// #12 review-adopted: 顶层 manifestError 字段；fetch 失败时填充，
  /// 调用方易区分 "sync 失败" vs "无变化"。null = fetch 成功。
  final String? manifestError;

  const SyncResult({
    required this.installed,
    required this.replaced,
    required this.skipped,
    required this.failed,
    required this.failureReasons,
    this.manifestError,
  });

  bool get hasChanges => installed.isNotEmpty || replaced.isNotEmpty;
  bool get hasFailure => failed.isNotEmpty || manifestError != null;

  @override
  String toString() => 'SyncResult(installed=${installed.length}, '
      'replaced=${replaced.length}, skipped=${skipped.length}, '
      'failed=${failed.length}, '
      'manifestError=${manifestError != null ? "yes" : "no"})';
}
```

#### 2b. 主类（#2 + #8 + #16 收口）

```dart
class ContentPackageService {
  final ManifestClient _client;
  final DownloadManager _downloader;
  final PackageInstaller _installer;
  final AppDatabase _db;

  /// #2 + #8 + #16 review-adopted:
  ///   - cacheDir + db **required**（删 systemTemp / AppDatabase() 默认）
  ///   - default installer 共享传入的 `db`（不再独立 new 真 AppDatabase）
  ContentPackageService({
    required Directory cacheDir,
    required AppDatabase db,
    ManifestClient? manifestClient,
    DownloadManager? downloadManager,
    PackageInstaller? installer,
  })  : _client = manifestClient ?? ManifestClient(),
        _downloader = downloadManager ??
            DownloadManager(cacheDir: cacheDir),
        _installer = installer ?? PackageInstaller(db: db),  // ← 共享 db
        _db = db;

  Future<SyncResult> syncIfNeeded({String? appVersion}) async {
    // Step 1: fetch
    final ManifestResponse manifest;
    try {
      manifest = await _client.fetchManifest(appVersion: appVersion);
    } catch (e) {
      // #12 review-adopted: 顶层 manifestError，调用方易判断
      return SyncResult(
        installed: const [],
        replaced: const [],
        skipped: const [],
        failed: const [],
        failureReasons: const {},
        manifestError: e.toString(),
      );
    }

    final installed = <String>[];
    final replaced = <String>[];
    final skipped = <String>[];
    final failed = <String>[];
    final reasons = <String, String>{};

    // 读本地 state，按 packageName 索引
    final localStates = <String, ContentPackageState>{};
    for (final s in await _db.select(_db.contentPackageStates).get()) {
      localStates[s.packageName] = s;
    }

    for (final pkg in manifest.packages) {
      // R1#5 (Day 1 review): kind filter 在 download 之前
      if (pkg.packageKind != 'examples') {
        skipped.add(pkg.packageId);
        reasons[pkg.packageId] =
            'kind=${pkg.packageKind} not implemented in PR-B2';
        continue;
      }

      final local = localStates[pkg.packageName];
      final isNew = local == null;
      final isReplace =
          local != null && local.contentVersion != pkg.contentVersion;
      final isSame =
          local != null && local.contentVersion == pkg.contentVersion;

      if (isSame) {
        skipped.add(pkg.packageId);
        continue;
      }

      try {
        final gzFile = await _downloader.downloadPackage(pkg);
        await _installer.install(gzFile, pkg);
        if (isNew) installed.add(pkg.packageId);
        if (isReplace) replaced.add(pkg.packageId);
      } catch (e) {
        failed.add(pkg.packageId);
        reasons[pkg.packageId] = e.toString();
      }
    }

    return SyncResult(
      installed: installed,
      replaced: replaced,
      skipped: skipped,
      failed: failed,
      failureReasons: reasons,
    );
  }
}
```

#### 2c. 单测 v0.2（6 cases，#12 加一个 manifest fetch 失败 case）

```dart
test('happy: 1 examples package, fresh install', ...);
test('kind filter: audio_meta package skipped, not downloaded', ...);
test('replace: server v5 vs local v3 → replaced (rollback / upgrade 共用)',
    ...);
test('skip: server v3 == local v3 → skipped, no download', ...);
test('download fails: package in failed[], reason recorded', ...);

// #12 review-adopted
test('manifest fetch fails: result.manifestError populated, hasFailure=true',
    () async {
  // mock client throw ManifestNetworkError
  // 验证 result.manifestError != null && result.installed.isEmpty
});
```

**Day 2 期望增量（Step 2）**：~250 行新代码 + ~280 行测试。

### Step 3：集成测 v0.2（5 cases + helper #14）

文件：`apps/mobile/test/integration/manifest_sync_test.dart`（~250 行）

#### 3a. _FakeManifestCdnServer helper（#14 review-adopted）

```dart
/// 同时 serve manifest API + CDN 下载的 fake server，供 5 个集成测复用。
class _FakeManifestCdnServer extends http.BaseClient {
  Map<String, dynamic>? manifestJson;
  final Map<String, List<int>> _files = {};
  final Map<String, int> _statusCodes = {};

  /// 注册 fake CDN 文件。
  void registerPackage({required String url, required List<int> bytes}) {
    _files[url] = bytes;
  }

  /// 注入特定 URL 的非 200 响应（测试错误路径）。
  void registerStatus(String url, int statusCode) {
    _statusCodes[url] = statusCode;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) async {
    final url = req.url.toString();
    if (req.url.path.endsWith('/content/manifest')) {
      if (manifestJson == null) {
        throw Exception('manifestJson not set');
      }
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(manifestJson!))),
        200,
      );
    }
    final status = _statusCodes[url] ?? 200;
    if (status != 200) {
      return http.StreamedResponse(Stream.empty(), status);
    }
    final bytes = _files[url];
    if (bytes != null) {
      return http.StreamedResponse(Stream.value(bytes), 200);
    }
    throw Exception('unexpected URL: $url');
  }
}
```

#### 3b. 5 个集成测（用 helper 简化）

```dart
test('full flow: fetch → download → checksum → install → drift 反查',
    () async {
  final server = _FakeManifestCdnServer();
  final exampleRows = [/* fixture 含 stable_id */];
  final gzBytes = gzip.encode(utf8.encode(exampleRows.map(jsonEncode).join('\n')));
  final hash = sha256.convert(gzBytes).toString();

  server.manifestJson = {
    'release_ids': ['rel-1'],
    'packages': [{/* manifest 12 字段, checksum=hash */}],
  };
  server.registerPackage(
    url: 'http://cdn.test/examples-zk@v1.gz',
    bytes: gzBytes,
  );

  final service = ContentPackageService(
    db: db,
    cacheDir: tmpCache,
    manifestClient: ManifestClient(client: server),
    downloadManager: DownloadManager(client: server, cacheDir: tmpCache),
    installer: PackageInstaller(db: db),
  );
  final result = await service.syncIfNeeded();

  expect(result.installed, ['examples-zk@v1']);
  expect(result.failed, isEmpty);
  expect(result.manifestError, isNull);

  final exRows = await db.select(db.exampleSentences).get();
  expect(exRows, isNotEmpty);

  final stateRows = await db.select(db.contentPackageStates).get();
  expect(stateRows, hasLength(1));  // #1 关键：state 表 1 行
});

test('checksum mismatch: not installed, failed[], state not written', ...);
test('non-examples kind: skipped, not downloaded', ...);
test('partial failure: 2 packages, 1 install ok, 1 download fails', ...);
test('replace: pre-existing v1 in drift, server v2 → drift updated, '
     'state 仍 1 行 (v1 row 已删)', () async {
  // #1 关键 case：升级后 state 表不膨胀
  // 1. seed db with examples-zk@v1 in state
  // 2. server returns examples-zk@v2
  // 3. sync
  // 4. 验证 state 1 行, contentVersion='v2', packageId='examples-zk@v2'
});
```

**Day 2 期望增量（Step 3）**：~250 行集成测。

### Step 4：App 默认行为不变验证（v0.2 修订命令）

```powershell
# 1. main.dart 无 ContentPackageService 调用
Select-String -Path apps\mobile\lib\main.dart -Pattern "ContentPackageService|PackageInstaller"
# 期望: 无匹配

# 2. WordbookLoader 未改（#11: 用精确 PR-B1 merge hash b26bff7 对照，抗 main 噪声）
git diff b26bff7 -- apps/mobile/lib/core/memory/wordbook_loader.dart
# 期望: 0 lines

# 3. AudioCacheRepository 未改
git diff b26bff7 -- apps/mobile/lib/core/audio/audio_cache_repository.dart
# 期望: 0 lines

# 4. assets/words bundle 大小不变
(Get-ChildItem apps\mobile\assets\words\ -File -Recurse | Measure-Object Length -Sum).Sum
# 期望: ~5400000 ± 5%

# 5. flutter analyze 新文件 0 issue
flutter analyze 2>&1 | Select-String "manifest|content_package|package_installer"
# 期望: 无 error/warning

# 6. baseline 6 failures 不增（#10 review-adopted 具体命令）
flutter test 2>&1 | Out-File flutter_test_day2.log
$failureLines = Select-String -Path flutter_test_day2.log -Pattern "TestFailure was thrown"
# 期望: failureLines.Count == 6（与 Day 1 commit 6557fb4 baseline 一致）
# 失败的 test names 与 Day 1 baseline 集合相同（study_sections / audio_cache_repository LRU）
```

## 关键文件

### 新建
- `apps/mobile/lib/core/manifest/package_installer.dart`（~310 行）
- `apps/mobile/lib/core/manifest/content_package_service.dart`（~250 行）
- `apps/mobile/test/core/manifest/package_installer_test.dart`（~350 行，9 cases）
- `apps/mobile/test/core/manifest/content_package_service_test.dart`（~280 行，6 cases）
- `apps/mobile/test/integration/manifest_sync_test.dart`（~250 行，5 cases + helper）

### 修改
- 无（Day 2 仅新增文件）

### 不动（关键，#11 用精确 hash）
- `apps/mobile/lib/main.dart`
- `apps/mobile/lib/core/memory/wordbook_loader.dart`
- `apps/mobile/lib/core/audio/audio_cache_repository.dart`
- `apps/mobile/lib/core/storage/drift/app_database.dart`
- `apps/mobile/pubspec.yaml`（零新依赖）
- 任何 server / migration / pipeline.py
- `apps/mobile/assets/words/*.json`

## 风险（#15 加降级优先级）

| 风险 | 缓解 |
|---|---|
| 大 gz 解压内存峰值 | 单包解压后 ~5-10MB 可接受；buffer 全部行（drift batch 必须 sync）|
| InsertOrReplace 把 bundle 数据完全覆盖 | 设计如此（变体 C §1.2）|
| **server 单包内 (wordId, sortOrder) 重复 → 静默吞数据** | #7 注释明示 server 责任；如发现先排查 server build_examples_package |
| drift transaction wrap install + state 失败 | #6 单测覆盖（install ok + state fails → 全 rollback）|
| 集成测 mock 复杂 | #14 _FakeManifestCdnServer helper 减重复 |
| **Day 2 工作量超 1 天** | #15 review-adopted 降级优先级（从最低风险砍）：<br>1. 文档舒适项（重申注释段）<br>2. 单测 9 → 5 cases（保留 happy / kind filter / state 不膨胀 / drift rollback / file missing）<br>3. 集成测 5 → 1（仅 full flow happy；R2#5 底线，**不再砍**）|

## 评审 pre-set（v0.2 后猜可能再被提的）

1. `_upsertPackageState` DELETE-INSERT 是否 race：✅ 同 transaction 内 atomic
2. SyncResult `replaced` 含 rollback：✅ 文档 + 字段名说清
3. PackageInstaller required db 改后既有调用方的影响：🟡 仅 ContentPackageService default + 未来 PR-B4 main.dart；都需显式传
4. ContentPackageService cacheDir required + PR-B4 main 配置：🟡 PR-B4 plan 必须在 main.dart 显式 `getApplicationDocumentsDirectory()` 后才传给 service
5. transaction 嵌套（_db.transaction → _db.batch）兼容性：✅ drift 文档支持；#6 单测验证

## 验收清单 v0.2

- [ ] PackageInstaller `db` required（无 AppDatabase() default）
- [ ] PackageInstaller `_upsertPackageState` 用 DELETE WHERE packageName + INSERT（state 表不膨胀）
- [ ] PackageInstaller `_installExamples` 空包 / stable_id 缺失 throw InstallFailedError
- [ ] PackageInstaller `catch (e, st)` 保 stack trace
- [ ] PackageInstaller 9 cases 单测全过（含 #1 / #3 / #4 / #6 关键 cases）
- [ ] ContentPackageService `cacheDir` + `db` required（无 systemTemp / AppDatabase 默认）
- [ ] ContentPackageService default installer 共享传入 db（不再独立 new）
- [ ] SyncResult 字段：installed / **replaced**（不是 upgraded） / skipped / failed / failureReasons / **manifestError**
- [ ] ContentPackageService 6 cases 单测全过（含 #12 manifest fetch 失败 case）
- [ ] 集成测 5 cases 全过 + 用 _FakeManifestCdnServer helper
- [ ] 集成测含 #1 关键 case："replace 后 state 表仍 1 行"
- [ ] `flutter analyze` 0 error in new files
- [ ] `flutter test` baseline 6 failures 数+名字与 Day 1 一致（具体命令验证）
- [ ] 启动行为不变 6 步（用 b26bff7 hash 对照）
- [ ] assets/words bundle 5.4MB 不变
- [ ] pubspec.yaml 不改

## 不做（Day 3+ / PR-B3+）

- ❌ 改 WordbookLoader（PR-B3）
- ❌ feature flag（PR-B3）
- ❌ 启动序列接入（PR-B4）
- ❌ server staging serve route（PR-B3）
- ❌ audio_meta / wordbook / dictionary kind 实装（PR-B3+）
- ❌ tombstone（v0.3 不做）
- ❌ ETag 缓存 / Range resume / brotli 支持（PR-C）

## 提交策略

Day 2 工作完成后单 commit：

```
feat(v0.3-pr-b2): Day 2 — PackageInstaller + ContentPackageService + 集成测 (v0.2)

吸收两份外部评审 16 处 (Day 2 plan v0.1 → v0.2):
P1: state 表 packageName 维度清理 / installer 共享 db / 空包拒绝 /
    stable_id 必须非空
P2: 注释行级 stream 删 / transaction 嵌套测试 / 双 unique index server
    责任注释 / cacheDir+db required / replaced 命名 / baseline 验证 /
    精确 hash 对照 / SyncResult.manifestError
Nit: stack trace 保留 / mock helper / 降级优先级 / installer db required

新增 (~810 行代码 + ~880 行测试):
- PackageInstaller (~310 行): drift transaction wrap 原子 install + state;
  仅 examples kind, 空包/stable_id 缺失 throw
- ContentPackageService (~250 行): cacheDir+db required; default installer
  共享 db; SyncResult 加 manifestError 顶层; replaced 含 rollback
- 单测 +15 cases (PackageInstaller 9 + ContentPackageService 6)
- 集成测 +5 cases + _FakeManifestCdnServer helper
- App 默认行为不变 (6 步 PowerShell + b26bff7 精确 hash 对照)
- 零新依赖
```
