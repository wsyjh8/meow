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

### Day 4 / Day 5 (stub)

- `gc-stale` 🟡 PR-A Day 4 (stub)：状态机查询版 GC

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
