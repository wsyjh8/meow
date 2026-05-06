# v0.3 PR-B2 · Day 2 plan — PackageInstaller + ContentPackageService + 集成测

## Context

PR-B2 Day 1 已 merge `6557fb4`：drift v12 + ManifestClient + DownloadManager 全部就位 + 12 单测全过 + App 默认行为不变。

Day 2 完成 PR-B2 闭环（master plan v0.4 §Day 2）：
1. PackageInstaller（gzip 解压 → drift 写入；仅 examples kind）
2. ContentPackageService（组合 ManifestClient/DownloadManager/PackageInstaller，编排 sync）
3. 集成测（manifest_sync_test：mock CDN 全 flow）
4. App 默认行为依然不变（不接入启动；零 grep 命中）

工作分支：`feat/v0.3-pr-b2-app-manifest-consumption` @ `6557fb4`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b2`

## 核实事实（recon 后）

### example_sentences drift schema（fsrs_tables.dart:197-221）

```
id           IntColumn AUTO_INCREMENT (PK)
wordId       TextColumn       (FK → word_entries.word_id)
stableId     TextColumn nullable
sense        TextColumn       (义项标签)
en           TextColumn       (英文例句)
cn           TextColumn       (中文翻译)
sortOrder    IntColumn nullable default 0
```

**关键观察**：
- 无 `source_package` / `source_release` 字段——manifest 数据与 bundle 数据混在同表。
  D1（PR-B3 改 WordbookLoader）靠 `content_package_state` 行存在性区分，**不**需要扩 example_sentences schema
- UNIQUE INDEX on `(wordId, sortOrder)` + `(stableId)`
- 主键 id 是 autoIncrement，但**冲突解决靠 stableId 唯一索引**

### WordbookLoader batch insert 模式（wordbook_loader.dart:185-197）

```dart
batch.insert(
  _db.exampleSentences,
  ExampleSentencesCompanion.insert(
    wordId: wordId,
    sense: ...,
    en: ...,
    cn: ...,
    sortOrder: Value(...),
    stableId: Value(resolvedStableId),
  ),
  mode: InsertMode.insertOrIgnore,  // bundle 模板用 ignore
);
```

**PR-B2 PackageInstaller 用 `InsertMode.insertOrReplace`**——manifest 是权威，覆盖 bundle 数据（变体 C §1.2 语义）。

### build_examples_package 输出 jsonl 格式（build_examples_package.py:144-154）

每行 JSON 9 字段：
```json
{
  "stable_id": "abc123",
  "word_id": "abandon",
  "sense_label": "v. 放弃",
  "en": "Don't [abandon] your dreams",
  "cn": "不要[放弃]你的梦想",
  "difficulty": 2.5,
  "ordinal": 1,
  "status": "active",
  "content_hash": "sha256-hex"
}
```

**字段映射到 drift（仅 5 个，其他暂忽略）**：
| jsonl 字段 | drift 字段 | 备注 |
|---|---|---|
| stable_id | stableId | 主匹配 key（unique index）|
| word_id | wordId | |
| sense_label | sense | |
| en | en | |
| cn | cn | |
| ordinal | sortOrder | |
| difficulty / status / content_hash | — | drift 表无对应字段，PR-C/D 决定是否扩 |

文件压缩：`gzip` (compresslevel=6)，无 brotli 路径。

### 集成测基础设施（recon 确认）

- **无现成 shelf / shelf_test_handler**——继续用 Day 1 的 `_FakeHttpClient extends http.BaseClient`
- `sqflite_common_ffi NativeDatabase.memory()` 已确认能跑（migration_test 在用）
- `Directory.systemTemp.createTemp()` 临时目录模式（audio_cache_repository_test 在用）
- 集成测组合：drift in-memory + _FakeHttpClient + 临时 cacheDir

### ContentPackageService 架构（参考既有 service）

ApiClient / AudioCacheRepository 模式：
- 构造函数 optional DI（test 注入）
- 每次 new（不是 singleton）
- 由上层（main / 测试）管理生命周期

**ContentPackageService 沿用此模式**：
```dart
ContentPackageService({
  ManifestClient? manifestClient,
  DownloadManager? downloadManager,
  PackageInstaller? installer,
  AppDatabase? db,
})
```

## 实施

### Step 1：PackageInstaller

文件：`apps/mobile/lib/core/manifest/package_installer.dart`（新建，~280 行）

#### 1a. 错误类

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

#### 1b. 主类

```dart
class PackageInstaller {
  final AppDatabase _db;

  PackageInstaller({AppDatabase? db}) : _db = db ?? AppDatabase();

  /// 安装一个已下载验证的 .gz 包。
  ///
  /// 流程（drift transaction wrap）：
  ///   1. 按 package_kind 分发（PR-B2 仅 examples）
  ///   2. gzip 解压 + jsonl 行解析
  ///   3. drift batch upsert（InsertMode.insertOrReplace；manifest 覆盖 bundle）
  ///   4. UPSERT content_package_state（同 transaction，install + state 原子）
  ///
  /// 失败：drift transaction 自动 rollback；throw InstallFailedError。
  /// 不会留 partial state。
  Future<void> install(File gzFile, ManifestPackage pkg) async {
    if (pkg.packageKind != 'examples') {
      throw UnsupportedKindError(pkg.packageKind);
    }
    if (!await gzFile.exists()) {
      throw InstallFailedError(pkg.packageId, 'file not found: ${gzFile.path}');
    }

    await _db.transaction(() async {
      try {
        await _installExamples(gzFile, pkg);
        await _upsertPackageState(pkg);
      } catch (e) {
        // drift 自动 rollback；包装错误
        throw InstallFailedError(pkg.packageId, e.toString());
      }
    });
  }

  /// gzip 解压 + jsonl 解析 + drift batch insertOrReplace。
  ///
  /// 内存峰值：单包 gzip 后 ≤ 2MB，解压后 ~5-10MB。dart:io GZipCodec.decoder
  /// + LineSplitter 行级 stream，避免一次性加载全文件。
  Future<void> _installExamples(File gzFile, ManifestPackage pkg) async {
    final lines = await gzFile
        .openRead()
        .transform(gzip.decoder)
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();

    if (lines.isEmpty) return;

    await _db.batch((batch) {
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final j = jsonDecode(line) as Map<String, dynamic>;
        batch.insert(
          _db.exampleSentences,
          ExampleSentencesCompanion.insert(
            wordId: j['word_id'] as String,
            sense: (j['sense_label'] as String?) ?? '',
            en: j['en'] as String,
            cn: j['cn'] as String,
            sortOrder: Value((j['ordinal'] as int?) ?? 0),
            stableId: Value(j['stable_id'] as String?),
          ),
          mode: InsertMode.insertOrReplace,  // manifest 覆盖 bundle
        );
      }
    });
  }

  Future<void> _upsertPackageState(ManifestPackage pkg) async {
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
          mode: InsertMode.insertOrReplace,
        );
  }
}
```

**关键决策**：
- drift transaction wrap install + state 写入 → 原子（install 失败时 state 也回滚，避免脏 state）
- `gzip.decoder` 来自 `dart:io`（GZipCodec），零新依赖
- `LineSplitter` 来自 `dart:convert`
- `InsertMode.insertOrReplace` 对应变体 C "manifest 覆盖 bundle" 语义
- 非 examples kind throw UnsupportedKindError（让 ContentPackageService skip 它，不进 retry）

#### 1c. 单测 `test/core/manifest/package_installer_test.dart`（5 cases）

```dart
void main() {
  late AppDatabase db;
  late Directory tmp;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tmp = await Directory.systemTemp.createTemp('installer_test_');
  });
  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  Future<File> _writeGz(List<Map<String, dynamic>> rows) async {
    final lines = rows.map(jsonEncode).join('\n');
    final gzBytes = gzip.encode(utf8.encode(lines));
    final f = File('${tmp.path}/test.gz');
    await f.writeAsBytes(gzBytes);
    return f;
  }

  test('happy: install examples package writes drift + state', ...);
  test('insertOrReplace: existing stable_id row replaced (manifest > bundle)',
      ...);
  test('non-examples kind → UnsupportedKindError, no drift writes', ...);
  test('file missing → InstallFailedError', ...);
  test('drift transaction rollback on bad jsonl line: state not written', ...);
}
```

**Day 2 期望增量（Step 1）**：~280 行新代码 + ~250 行测试。

### Step 2：ContentPackageService

文件：`apps/mobile/lib/core/manifest/content_package_service.dart`（新建，~220 行）

#### 2a. SyncResult DTO

```dart
class SyncResult {
  final List<String> installed;   // 新装的 packageId
  final List<String> upgraded;    // 升级的 packageId
  final List<String> skipped;     // 已是最新 / 非 examples kind
  final List<String> failed;      // download / install 失败
  final Map<String, String> failureReasons;  // packageId → error str

  const SyncResult({
    required this.installed,
    required this.upgraded,
    required this.skipped,
    required this.failed,
    required this.failureReasons,
  });

  bool get hasChanges => installed.isNotEmpty || upgraded.isNotEmpty;

  @override
  String toString() => 'SyncResult(installed=${installed.length}, '
      'upgraded=${upgraded.length}, skipped=${skipped.length}, '
      'failed=${failed.length})';
}
```

#### 2b. 主类

```dart
class ContentPackageService {
  final ManifestClient _client;
  final DownloadManager _downloader;
  final PackageInstaller _installer;
  final AppDatabase _db;

  ContentPackageService({
    ManifestClient? manifestClient,
    DownloadManager? downloadManager,
    PackageInstaller? installer,
    AppDatabase? db,
    Directory? cacheDir,
  })  : _client = manifestClient ?? ManifestClient(),
        _downloader = downloadManager ??
            DownloadManager(
              cacheDir: cacheDir ?? Directory.systemTemp,  // 仅作 test default
            ),
        _installer = installer ?? PackageInstaller(),
        _db = db ?? AppDatabase();

  /// 同步 server manifest 到本地 drift。
  ///
  /// 算法（D4 决策：每次拉全量，不传 since_release）：
  ///   1. fetchManifest()
  ///   2. **kind filter**（R1#5）：package_kind != 'examples' → skipped[]
  ///   3. 对每个 examples package：
  ///      - 本地无 packageId → 新装 (download → install) → installed[]
  ///      - 本地有但 contentVersion 不同 → 升级 → upgraded[]
  ///      - 本地有且版本一致 → skipped[]
  ///   4. download/install 失败 → failed[] + failureReasons
  ///
  /// 失败不写 content_package_state（PackageInstaller 责任），下次 sync 重试。
  Future<SyncResult> syncIfNeeded({String? appVersion}) async {
    // Step 1: fetch
    final ManifestResponse manifest;
    try {
      manifest = await _client.fetchManifest(appVersion: appVersion);
    } catch (e) {
      // network / parse 失败：返空结果，调用方决定是否 retry
      return SyncResult(
        installed: const [],
        upgraded: const [],
        skipped: const [],
        failed: const [],
        failureReasons: {'_manifest_fetch': e.toString()},
      );
    }

    final installed = <String>[];
    final upgraded = <String>[];
    final skipped = <String>[];
    final failed = <String>[];
    final reasons = <String, String>{};

    // Step 2 + 3: kind filter + state diff
    final localStates = <String, ContentPackageState>{};
    for (final s in await _db.select(_db.contentPackageStates).get()) {
      localStates[s.packageName] = s;
    }

    for (final pkg in manifest.packages) {
      // R1#5: kind filter 在 download 之前
      if (pkg.packageKind != 'examples') {
        skipped.add(pkg.packageId);
        reasons[pkg.packageId] =
            'kind=${pkg.packageKind} not implemented in PR-B2';
        continue;
      }

      final local = localStates[pkg.packageName];
      final isNew = local == null;
      final isUpgrade =
          local != null && local.contentVersion != pkg.contentVersion;
      final isSame =
          local != null && local.contentVersion == pkg.contentVersion;

      if (isSame) {
        skipped.add(pkg.packageId);
        continue;
      }

      // download + install
      try {
        final gzFile = await _downloader.downloadPackage(pkg);
        await _installer.install(gzFile, pkg);
        if (isNew) installed.add(pkg.packageId);
        if (isUpgrade) upgraded.add(pkg.packageId);
      } catch (e) {
        failed.add(pkg.packageId);
        reasons[pkg.packageId] = e.toString();
      }
    }

    return SyncResult(
      installed: installed,
      upgraded: upgraded,
      skipped: skipped,
      failed: failed,
      failureReasons: reasons,
    );
  }
}
```

#### 2c. 单测 `test/core/manifest/content_package_service_test.dart`（5 cases）

```dart
void main() {
  // 用 fake ManifestClient / DownloadManager / PackageInstaller 实现
  // _FakeManifestClient(返 ManifestResponse fixture)
  // _FakeDownloadManager(返 File 或 throw)
  // _FakeInstaller(record install calls 或 throw)

  test('happy: 1 examples package, fresh install', ...);
  test('kind filter: audio_meta package skipped, not downloaded', ...);
  test('upgrade: server v5 vs local v3 → upgraded', ...);
  test('skip: server v3 == local v3 → skipped, no download', ...);
  test('download fails: package in failed[], reason recorded', ...);
}
```

**Day 2 期望增量（Step 2）**：~220 行新代码 + ~250 行测试。

### Step 3：集成测

文件：`apps/mobile/test/integration/manifest_sync_test.dart`（新建，~200 行）

```dart
// 集成测：drift in-memory + _FakeHttpClient 模拟 manifest API + CDN
//
// 不可砍超时项（master plan v0.4 R2#5）——是 fetch → download → checksum →
// install → drift 反查整条链路的回归保险。

void main() {
  late AppDatabase db;
  late Directory tmpCache;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tmpCache = await Directory.systemTemp.createTemp('integ_');
  });
  tearDown(() async {
    await db.close();
    await tmpCache.delete(recursive: true);
  });

  test('full flow: fetch → download → checksum → install → drift 反查',
      () async {
    // 1. 准备 fixture
    final exampleRows = [
      {'stable_id': 'sa1', 'word_id': 'apple', 'sense_label': '苹果',
       'en': 'an apple', 'cn': '一个苹果', 'difficulty': 1.0,
       'ordinal': 1, 'status': 'active', 'content_hash': '...'},
    ];
    final gzBytes = gzip.encode(utf8.encode(exampleRows.map(jsonEncode).join('\n')));
    final hash = sha256.convert(gzBytes).toString();

    // 2. 准备 mock client (同时 serve manifest API + CDN)
    final fakeClient = _FakeHttpClient((req) async {
      if (req.url.path.endsWith('/content/manifest')) {
        return _streamResp(200, jsonEncode({
          'release_ids': ['rel-1'],
          'packages': [{
            'package_id': 'examples-zk@v1', 'package_name': 'examples-zk',
            'package_kind': 'examples', 'book_id': 'zk', 'content_version': 'v1',
            'file_url': 'http://cdn.test/examples-zk@v1.gz',
            'checksum_sha256': hash, 'size_bytes': gzBytes.length,
            'compression': 'gzip', 'min_app_version': '0.0.0',
            'release_id': 'rel-1',
          }],
        }));
      }
      if (req.url.path.endsWith('examples-zk@v1.gz')) {
        return _stream(200, gzBytes);
      }
      throw Exception('unexpected URL: ${req.url}');
    });

    // 3. 跑 service
    final service = ContentPackageService(
      manifestClient: ManifestClient(client: fakeClient),
      downloadManager: DownloadManager(client: fakeClient, cacheDir: tmpCache),
      installer: PackageInstaller(db: db),
      db: db,
    );
    final result = await service.syncIfNeeded();

    // 4. 反查
    expect(result.installed, ['examples-zk@v1']);
    expect(result.failed, isEmpty);
    final exRows = await db.select(db.exampleSentences).get();
    expect(exRows, hasLength(1));
    expect(exRows.first.stableId, 'sa1');
    expect(exRows.first.en, 'an apple');
    final stateRows = await db.select(db.contentPackageStates).get();
    expect(stateRows, hasLength(1));
    expect(stateRows.first.packageId, 'examples-zk@v1');
  });

  test('checksum mismatch: not installed, failed[], state not written', ...);
  test('non-examples kind: skipped, not downloaded', ...);
  test('partial failure: 2 packages, 1 install ok, 1 download fails', ...);
  test('upgrade: pre-existing v1 in drift, server v2 → drift updated', ...);
}
```

**Day 2 期望增量（Step 3）**：~200 行集成测。

### Step 4：App 默认行为不变验证

```powershell
# 1. main.dart 无 ContentPackageService 调用
Select-String -Path apps\mobile\lib\main.dart -Pattern "ContentPackageService|PackageInstaller"
# 期望: 无匹配

# 2. WordbookLoader 未改
git diff origin/main -- apps/mobile/lib/core/memory/wordbook_loader.dart
# 期望: 0 lines

# 3. AudioCacheRepository 未改
git diff origin/main -- apps/mobile/lib/core/audio/audio_cache_repository.dart
# 期望: 0 lines

# 4. assets/words bundle 大小不变
(Get-ChildItem apps\mobile\assets\words\ -File -Recurse | Measure-Object Length -Sum).Sum
# 期望: ~5400000

# 5. flutter analyze 新文件 0 issue
flutter analyze 2>&1 | Select-String "manifest|content_package|package_installer"
# 期望: 无 error/warning
```

## 关键文件

### 新建
- `apps/mobile/lib/core/manifest/package_installer.dart`（~280 行）
- `apps/mobile/lib/core/manifest/content_package_service.dart`（~220 行）
- `apps/mobile/test/core/manifest/package_installer_test.dart`（~250 行，5 cases）
- `apps/mobile/test/core/manifest/content_package_service_test.dart`（~250 行，5 cases）
- `apps/mobile/test/integration/manifest_sync_test.dart`（~200 行，5 cases）

### 修改
- 无（Day 2 仅新增文件，不动既有）

### 不动（关键）
- `apps/mobile/lib/main.dart`
- `apps/mobile/lib/core/memory/wordbook_loader.dart`
- `apps/mobile/lib/core/audio/audio_cache_repository.dart`
- `apps/mobile/lib/core/storage/drift/app_database.dart`（Day 1 改完后稳定）
- `apps/mobile/pubspec.yaml`（零新依赖）
- 任何 server / migration / pipeline.py
- assets/words bundle

## 风险

| 风险 | 缓解 |
|---|---|
| 大 gz 解压内存峰值 | 行级 stream（gzip.decoder + LineSplitter）；单包解压后 ~5-10MB 可接受 |
| InsertOrReplace 把 bundle 数据完全覆盖 → bundle 中独有的 stable_id 数据丢？| 设计如此 — manifest 是 server 权威（变体 C §1.2）；server 端 build_examples_package 包含**全量 active examples**（PR-A README §6 设计要点 5："Full snapshot"）|
| drift transaction wrap install + state 失败 | 测试覆盖 rollback case；事务边界明确 |
| 集成测复杂（mock client + drift + tmpdir）| 按 Day 1 _FakeHttpClient 模板抄；fixture 集中在 setUp 减重复 |
| Day 2 工作量超 1 天 | **超时砍单测**（5 → 3 cases 各模块）；集成测**不砍**（master plan v0.4 R2#5）|
| ContentPackageService 默认 cacheDir 是 systemTemp 不合产线 | 仅作 test default；PR-B4 接入启动时通过 main 注入 path_provider 拿 ApplicationDocumentsDirectory |

## 评审 pre-set（猜可能被提的）

1. PackageInstaller 不去重 jsonl 行：✅ stable_id 是 unique index，drift 自然去重
2. SyncResult 没区分 "网络断" vs "manifest 解析失败"：🟡 failureReasons map 提供详情；调用方按需查
3. ContentPackageService 默认 cacheDir = systemTemp 是否危险：🟡 测试 only；PR-B4 必须显式传 ApplicationDocumentsDirectory
4. 集成测 mock 同一 client serve manifest + CDN：✅ 简化，realistic（dev 环境真共用 baseUrl）
5. drift transaction 嵌套（_db.transaction → _db.batch）：🟡 drift 支持嵌套；测试覆盖
6. UnsupportedKindError vs UnsupportedCompressionError：✅ 不同维度（kind = 包类型 / compression = 压缩格式）
7. ContentPackageService 没接 isolate：🟡 PR-C 候选；当前同进程异步够用

## 验收清单

- [ ] PackageInstaller 实装：gzip 解压 + drift batch insertOrReplace + content_package_state UPSERT
- [ ] PackageInstaller 单测 5 cases：happy / replace 覆盖 / 非 examples kind reject / 文件丢失 / drift rollback
- [ ] ContentPackageService 实装：D4 不传 since_release + R1#5 kind filter + state diff
- [ ] ContentPackageService 单测 5 cases：happy / kind filter / upgrade / skip / download fail
- [ ] 集成测 5 cases：full flow / checksum mismatch / non-examples skip / partial failure / upgrade
- [ ] `flutter analyze` 0 error in new files
- [ ] `flutter test` 全过 + baseline 6 个 pre-existing 失败保持（不引入新失败）
- [ ] 启动行为不变：5 步 PowerShell 命令全过
- [ ] assets/words bundle 5.4MB 不变
- [ ] pubspec.yaml 不改（零新依赖）

## 不做（Day 3+ / PR-B3+）

- ❌ 改 WordbookLoader（PR-B3）
- ❌ feature flag（PR-B3）
- ❌ 启动序列接入（PR-B4）
- ❌ server staging serve route（PR-B3）
- ❌ audio_meta / wordbook / dictionary kind 实装（PR-B3+ 视需要）
- ❌ tombstone（v0.3 不做）
- ❌ ETag 缓存 / Range resume / brotli 支持（PR-C）

## 提交策略

Day 2 工作完成后单 commit：

```
feat(v0.3-pr-b2): Day 2 — PackageInstaller + ContentPackageService + 集成测

- PackageInstaller (~280 行): gzip 解压 + drift batch insertOrReplace
  + content_package_state UPSERT (单 transaction 原子);
  仅 examples kind, 其他 throw UnsupportedKindError
- ContentPackageService (~220 行): 编排 ManifestClient/DownloadManager/
  PackageInstaller; D4 全量拉; R1#5 kind filter; state diff 决策
- 单测 +10 cases: PackageInstaller 5 + ContentPackageService 5
- 集成测 +5 cases: drift in-memory + _FakeHttpClient 全 flow
- App 默认行为完全不变 (5 步 PowerShell 验证)
- 零新依赖 (pubspec 不改)
- baseline 6 个 pre-existing failures 保持 (不引入新失败)
```

## Day 2 完成后状态

- PR-B2 收口（mobile 基建完整 + 不切流量验证）
- 5 模块全部就绪：drift / ManifestClient / DownloadManager / PackageInstaller / ContentPackageService
- 单测 22 cases + 集成测 5 cases + migration 1 case 全过
- App 默认行为完全不变（4 个不动文件 + assets 不变 + 无启动调用）
- 准备进 PR-B3：feature flag + WordbookLoader 改 + server staging serve route

详见 `docs/design/pr-b2_v0.4.md` §Day 2 完成条件。
