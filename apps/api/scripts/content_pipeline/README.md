# Content Pipeline (v0.3 PR-A)

统一发布 pipeline 单一 entry。逐步替代当前散落的 4 个脚本：
- `partial_publish.py` (audio_pipeline/, P2.1)
- `ingest_external_mp3s.py` (audio_pipeline/, P2.2)
- `ingest-audio-assets.ts` (scripts/, P2.1)
- `generate_words_json.py` (audio_pipeline/, P2.2)

PR-A 期间这 4 个旧脚本保留为 wrapper / 兼容层，PR-D 之后再删。

## Setup

```bash
\ 装依赖
pip install -r apps/api/scripts/content_pipeline/requirements.txt

\ 设置 .env DATABASE_URL（pipeline.py 读环境变量）
\ 当前 dev 库:
\   DATABASE_URL=postgresql://postgres:<password>@localhost:5432/meow_dev
```

## Subcommands

### `build-examples-package` ✅ PR-A Day 2 (实装)

从 PG `examples` 表生成 `examples-{book}.jsonl.gz` 包，可选回填 `content_hash`。

```bash
cd apps/api
python scripts/content_pipeline/pipeline.py build-examples-package \
  --book book-001 --update-pg
```

参数：
- `--book {book-001|zk|gk}` 必填，词书 slug
- `--out-dir <dir>` 默认 `audio-pipeline-staging`（相对 cwd）
- `--assets-dir <dir>` 默认 `../mobile/assets/words`（相对 cwd）
- `--update-pg` 加上则同时回填 PG `examples.content_hash`

输出：
```
audio-pipeline-staging/examples-book-001.jsonl.gz
```

stdout 打印：
```
rows=<N>  bytes=<size>  sha256=<64 hex>
```

#### 设计要点

1. **Source of truth for word→book mapping**: `apps/mobile/assets/words/{book}.json`
   不是 `word_book_memberships`。后者在 dev DB 只有 29 行（dev-seed 样本），不全。
   JSON 是 SSOT；future PR-B 改用 CDN package 后包生成器输入仍是抽象 source content。

2. **content_hash 算法**: `sha256_24(canonical_json([
   stable_id, word_id, sense_label_or_empty, en, cn, difficulty_or_empty,
   str(ordinal), status]))` — 见 `apps/api/scripts/audio_pipeline/reference.py`
   `compute_example_content_hash`。覆盖所有 package-visible 字段。

3. **content_hash 是全局 examples 行级**, 不是 book-local。同一例句在多本词书出现时，
   examples 行只有一份，content_hash 也只算一次。多次 `--update-pg` 跑不同 book
   的 build 不会冲突（`_changed` 标记跳过未变行）。

4. **Day 2 包是 full snapshot**: 包内只含 `status='active'` 行。删除 / deprecated
   语义靠"包以本次为准"传达 —— 客户端导入时本地多余 stable_id 应隐藏 / 删除。
   后续 delta package + tombstone 行格式留给 PR-B 之后。

### `validate` 🟡 PR-A Day 3 (stub)
当前调用 raise `NotImplementedError("validate: PR-A Day 3")`。

### `activate` 🟡 PR-A Day 3 (stub)
### `revoke` 🟡 PR-A Day 3 (stub)
### `publish-manifest` 🟡 PR-A Day 3 (stub)
### `gc-stale` 🟡 PR-A Day 4 (stub)

## Verification

```bash
\ 顶层 help
python scripts/content_pipeline/pipeline.py --help

\ 子命令 help
python scripts/content_pipeline/pipeline.py build-examples-package --help

\ 跨实现 fixture (Python now; TS / Dart 留 PR-B)
python scripts/audio_pipeline/verify_fixtures.py
```

## Reference

- `docs/design/词书单词例句与例句音频架构_v0.3.md` §B.4 / §B.7 / §B.10
- `docs/design/DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md` r7 §3.4 / §4.7
- `apps/api/scripts/audio_pipeline/reference.py` (hash impls)
- `tests/fixtures/example_content_hash.yaml` (golden fixtures)
