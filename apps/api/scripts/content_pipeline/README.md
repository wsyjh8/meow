# Content Pipeline (v0.3 PR-A)

统一发布 pipeline 单一 entry。逐步替代当前散落的 4 个旧脚本：
- `partial_publish.py` (audio_pipeline/, P2.1)
- `ingest_external_mp3s.py` (audio_pipeline/, P2.2)
- `ingest-audio-assets.ts` (scripts/, P2.1)
- `generate_words_json.py` (audio_pipeline/, P2.2)

PR-A 期间 4 个旧脚本保留为 wrapper / 兼容层，PR-D 之后再删。

## Setup

```bash
\ 装依赖
pip install -r apps/api/scripts/content_pipeline/requirements.txt

\ 设置 .env DATABASE_URL（pipeline.py 读环境变量）
\ 当前 dev 库:
\   DATABASE_URL=postgresql://postgres:<password>@localhost:5432/meow_dev
```

## Subcommands

### Day 2 实装

#### `build-examples-package` ✅

从 PG `examples` 表生成 `examples-{book}.jsonl.gz` 包，可选回填 `content_hash`。

```bash
cd apps/api
python scripts/content_pipeline/pipeline.py build-examples-package \
  --book book-001 --update-pg
```

参数：
- `--book {book-001|zk|gk}` 必填
- `--out-dir <dir>` 默认 `audio-pipeline-staging`（相对 cwd）
- `--assets-dir <dir>` 默认 `../mobile/assets/words`（相对 cwd）
- `--update-pg` 加上则同时回填 PG `examples.content_hash`

输出 `audio-pipeline-staging/examples-{book}.jsonl.gz` + 打印 sha256/size。

### Day 3 实装

#### `create-release` ✅

创建一个 draft release（治理批次容器）。

```bash
python scripts/content_pipeline/pipeline.py create-release rel-2026-05-05-001 \
  --title "Examples v1 first publish"
```

参数：
- `release_id` 必填，自定义字符串（建议 `rel-YYYY-MM-DD-NNN` 形式）
- `--title <txt>` 可选，人类可读描述
- `--target-min-app-version <ver>` 可选，最低 App 版本

#### `publish-manifest` ✅

把已构建的包文件注册到 `content_manifest` + 追加 `release.package_set`。
**仅在 release status='draft' 时可调**。

```bash
python scripts/content_pipeline/pipeline.py publish-manifest \
  --release rel-2026-05-05-001 \
  --package-name examples-book-001 \
  --package-kind examples \
  --content-version v1 \
  --file audio-pipeline-staging/examples-book-001.jsonl.gz
```

参数：
- `--release` 必填，目标 release_id
- `--package-name` 必填，**必须匹配命名约定**（见下文）
- `--package-kind` 必填，`examples` / `audio_meta` / `wordbook` / `dictionary`
- `--content-version` 必填，例如 `v1`
- `--file` 必填，本地包文件路径
- `--min-app-version <ver>` 可选

幂等：同 `manifest_id` + 同内容 → no-op；同 `manifest_id` + 不同内容 → 报错。

#### `validate` ✅

8 步双向一致性 + checksum 验证。通过 → status: draft → validated。

```bash
python scripts/content_pipeline/pipeline.py validate rel-2026-05-05-001
```

检查项（任一失败拒绝 transition）：
1. release 存在 + status='draft'
2. package_set 非空
3. 正向：每个 package_set id 在 content_manifest 有对应行
4. 反向：每个 `content_manifest WHERE release_id=X` 都在 X.package_set 里
5. file_url 必须 file:// 开头
6. 文件存在
7. 文件 sha256 = manifest.checksum_sha256
8. 文件 size = manifest.size_bytes

#### `activate` ✅

事务激活 release，同 package_name 旧版本 cascade deactivate。

```bash
python scripts/content_pipeline/pipeline.py activate rel-2026-05-05-001
```

操作：
1. `package_set` 里的 manifest 置 `is_active=true`
2. 同 `package_name` 但不在 `package_set` 的旧 manifest 置 `is_active=false`
3. release.status: validated → active；写 activation_log

注意：**不**自动 deprecate 别的 release（即使包被 cascade 替换）；显式 revoke 才行。

#### `revoke` ✅ （**撤销/下线**，不是 rollback）

```bash
python scripts/content_pipeline/pipeline.py revoke rel-2026-05-05-001 \
  --reason "敏感词审核未通过"
```

操作：
1. `package_set` 里的 manifest 置 `is_active=false`
2. release.status: active|deprecated → revoked

**这不是 rollback** —— 不会自动恢复任何旧版本。如需恢复旧版本，操作员需
publish 新 release（或 PR-B 之后加 `rollback --to <old_release>` 子命令）。

### Day 4 实装

#### `gc-stale` ✅

audio_assets 状态机驱动的 **best-effort GC**（非事务原子）。两阶段：

```
ready                                    (active state)
  ↓ (新音频 publish 替换；Day 5/PR-B；本 Day 4 不做)
superseded
  ↓ (grace_days_promote 后；gc-stale --promote 阶段)
eligible_for_gc
  ↓ (grace_days_delete 后 + 文件删除尝试；gc-stale --delete 阶段)
deleted (终态，行保留作审计)
```

```bash
\ 默认 dry-run，只打印候选 + 异常（transitioned_at IS NULL）告警
python scripts/content_pipeline/pipeline.py gc-stale

\ 实际执行（互斥 --dry-run）
python scripts/content_pipeline/pipeline.py gc-stale --gc \
  --grace-days-promote 30 --grace-days-delete 30
```

参数：
- `--dry-run` (default) / `--gc`（互斥）
- `--grace-days-promote N` 默认 30
- `--grace-days-delete N` 默认 30
- `--cdn-mock-dir <dir>` 默认 `cdn-mock`（相对 cwd）

**安全语义**（review-driven，关键）：
- **不是事务原子**：FS 删除不受 PG transaction 保护
- 文件删除失败（权限错 / URL 解析失败）的行**保留 eligible_for_gc**，
  下次 gc-stale 可重试。**不会误标 deleted 吞掉问题**
- 文件已不存在（被人手动删过 / race）= 成功语义，标 deleted
- 本次刚 promote 的行**不会被本次 delete**：delete candidates 在 promote
  操作之前 SELECT，刚转入 eligible_for_gc 的行不在该集里
- 负数 grace days / 互斥参数 → 早期 fail
- `transitioned_at IS NULL` 的异常行：dry-run 输出 WARN 计数，**不自动处理**

**Day 4 范围限定**（重要）：
- ✅ 处理 DB 状态机驱动的 GC（superseded → eligible_for_gc → deleted）
- ❌ **不处理 filesystem orphan**（cdn-mock 里有文件但 PG audio_assets 没行
  对应它）—— 这类需要单独的 `orphan-scan` 子命令，留 Day 5 / PR-B

### Day 5 (stub)

- 完整 release 流程 e2e + filesystem orphan-scan

## API: `GET /api/v1/content/manifest` ✅ Day 4 实装

客户端发现入口。返回当前 active release 的所有 active manifest packages。

```bash
\ 默认: 所有 active packages
curl http://localhost:3000/api/v1/content/manifest

\ since_release 增量过滤
curl "http://localhost:3000/api/v1/content/manifest?since_release=rel-2026-05-04-002"

\ app_version 过滤（仅返回客户端兼容的包）
curl "http://localhost:3000/api/v1/content/manifest?app_version=1.2.3"
```

Response shape：
```json
{
  "release_ids": ["rel-2026-05-05-001"],
  "packages": [
    {
      "package_id": "examples-zk@v5",
      "package_kind": "examples",
      "package_name": "examples-zk",
      "book_id": "zk",
      "content_version": "v5",
      "file_url": "https://cdn.example.com/.../examples-zk.jsonl.gz",
      "checksum_sha256": "...",
      "size_bytes": 931741,
      "compression": "gzip",
      "min_app_version": "0.0.0",
      "release_id": "rel-2026-05-05-001"
    }
  ]
}
```

**Dual-condition filter**（v0.2 评审采纳 #11）：
- `content_release.status = 'active'`（治理事实源："这一批是否生效"）
- `content_manifest.is_active = true`（包文件级开关："包是否可被引用"）
- 两条件**必须同时满足**才返回。已 revoke 的 release / `is_active=false` 的
  manifest 都不返回

**字段语义**：
- `book_id` server-side 从 `package_name` 派生（命名约定保证），客户端不
  需要解析字符串
- `compression` 从 `file_url` 后缀派生（.gz → "gzip"，.br → "brotli"）
- `size_bytes` JS number（服务端处理 BIGINT → string 的 node-pg 默认行为）
- `min_app_version` 永远非空（`COALESCE(NULL, '0.0.0')`）

**校验**：
- `app_version` 必须 `^X.Y.Z$`（严格三段非负整数，禁 leading zeros）；
  非法 → 400
- `since_release` 不存在 → 400
- `since_release` 存在但 activated_at IS NULL（draft）→ 等价于无 since 过滤

**Production 安全**：
- `NODE_ENV='production'` 时，`file_url` 以 `file://` 开头的包跳过返回 +
  log error。防止生产环境暴露本地路径

**首次安装客户端**: 不传 `since_release`，拿全量 active manifest。
**已有本地状态客户端**: 传上次拿到的 release_id 作 since，仅拿增量。

## Package naming convention

**publish-manifest 强校验** package_name 必须匹配以下规则：

| package_kind | 命名 prefix | 示例 |
|---|---|---|
| examples | `examples-` | `examples-book-001` / `examples-zk` / `examples-gk` |
| audio_meta | `audio-meta-` | `audio-meta-cet4` |
| wordbook | `wordbook-` | `wordbook-zk` |
| dictionary | `dictionary-` | `dictionary-morphemes` |

不允许裸 `examples` / `audio-meta` 等 —— 否则 `activate` cascade 会按
`package_name` 粒度"全栈级误伤"（把 `examples-book-001` / `examples-zk` /
`examples-gk` 当成同一包名同时下线）。

## End-to-end release flow

```bash
cd apps/api
$env:PGPASSWORD="<your-local-password>"

# 1. 创建 draft release
python scripts/content_pipeline/pipeline.py create-release rel-001 \
  --title "First content release"

# 2. 构建一个包
python scripts/content_pipeline/pipeline.py build-examples-package \
  --book book-001 --update-pg

# 3. 注册到 release
python scripts/content_pipeline/pipeline.py publish-manifest \
  --release rel-001 \
  --package-name examples-book-001 \
  --package-kind examples \
  --content-version v1 \
  --file audio-pipeline-staging/examples-book-001.jsonl.gz

# 4. validate (draft → validated)
python scripts/content_pipeline/pipeline.py validate rel-001

# 5. activate (validated → active)
python scripts/content_pipeline/pipeline.py activate rel-001

# 后续如要替换:
# 6. 创建新 release，publish 新版本，validate，activate
#    → 自动 cascade deactivate 旧版本
# 7. 或紧急下线: revoke rel-001
```

## 设计要点

1. **content_release 是治理 SSOT**（v0.3 §B.4.5）。`package_set` 是 denormalized
   snapshot，事实源是 `content_manifest.release_id`。validate 阶段强制双向对齐。

2. **状态机**: draft → validated → active → deprecated/revoked
   - draft：可改 package_set
   - validated：冻结，不可改 package_set；只能 activate 或重新 create
   - active：包正在生效
   - deprecated：保留状态机入口（active→deprecated），Day 3 无 CLI 入口（PR-B+）
   - revoked：下线终态

3. **content_hash 算法**（reference.py `compute_example_content_hash`）覆盖
   所有 package-visible 字段：
   ```
   sha256_24(canonical_json([
     stable_id, word_id, sense_label_or_empty, en, cn,
     difficulty_or_empty, str(ordinal), status
   ]))
   ```
   改 cn 翻译触发 hash 变化，但 stable_id 不变（v0.3 Strategy A）。

4. **content_hash 全局**: examples 行级，不是 book-local。同一例句在多本词书
   出现时 examples 行只有一份，content_hash 也只算一次。

5. **Full snapshot package**: 当前包内只含 `status='active'` 行。删除/deprecated
   语义靠"包以本次为准"传达。tombstone-style delta 包留给 PR-B 之后。

6. **file_url 占位**: Day 3 仅支持 `file://` 本地路径。真 CDN 上传 + https URL
   留 Day 5 / PR-B。

## Reference

- `docs/design/词书单词例句与例句音频架构_v0.3.md` §B.4 / §B.7 / §B.10
- `docs/design/DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md` r7 §3.4 / §4.7
- `apps/api/scripts/audio_pipeline/reference.py` (hash impls)
- `tests/fixtures/example_content_hash.yaml` (golden fixtures)
