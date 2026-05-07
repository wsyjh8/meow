# Content Pipeline (v0.3 PR-A)

统一发布 pipeline 单一 entry。逐步替代当前散落的 4 个旧脚本：
- `partial_publish.py` (audio_pipeline/, P2.1)
- `ingest_external_mp3s.py` (audio_pipeline/, P2.2)
- `ingest-audio-assets.ts` (scripts/, P2.1)
- `generate_words_json.py` (audio_pipeline/, P2.2)

PR-A 期间 4 个旧脚本保留为 wrapper / 兼容层，PR-D 之后再删。

## Subcommand reference

| 子命令 | 阶段 | 写? | 描述 |
|---|---|---|---|
| `build-examples-package` | 准备 | 写 FS | 生成 `examples-{book}` package + checksum |
| `create-release` | 治理 | 写 PG | INSERT content_release status='draft' |
| `publish-manifest` | 治理 | 写 PG | UPSERT content_manifest，关联 release（**仅 draft state**） |
| `validate` | 治理 | 写 PG | draft → validated（强制 package_set ↔ manifest.release_id 对齐） |
| `approve` ⭐ B1 Day 3 | 治理 | 写 PG | 写 approved_by + audit log（**仅 env CONTENT_RELEASE_REQUIRE_APPROVAL=true 时为 activate 前置；默认可跳过**） |
| `activate` | 治理 | 写 PG | validated → active + cascade 旧 manifest is_active；env truthy 时校验 approved_by |
| `deprecate` ⭐ Day 5 | 治理 | 写 PG | active → deprecated（软下线，不动 manifest.is_active） |
| `rollback` ⭐ B1 Day 2 | 治理 | 写 PG | deprecated → active（同时把当前 active demote 回 deprecated；revoked 不可恢复） |
| `revoke` | 治理 | 写 PG | active/deprecated → revoked（硬撤回，cascade is_active=false，不可逆） |
| `list-releases` ⭐ Day 5 | 可视化 | 只读 | 表格输出 release 列表 |
| `gc-stale` | 运维 | 写 PG + FS | PG 状态机驱动 GC（cdn-mock 范围；superseded → eligible_for_gc → deleted） |
| `orphan-scan` ⭐ B1 Day 1 | 运维 | 写 FS | FS 物理孤儿扫描（cdn-mock + audio-pipeline-staging 双根 + 白名单） |

## State machines

### content_release（基础流）

```
   create-release
        │
        ▼
     [draft] ──────publish-manifest──────▶ (在 draft 时 UPSERT manifest，
        │                                  validated 后 package_set 冻结)
        │ validate
        ▼
   [validated]            ←── (approve 写 approved_by 字段；非状态转换)
        │
        │ activate (env CONTENT_RELEASE_REQUIRE_APPROVAL truthy 时校验 approved_by)
        │ + cascade 同 package_name 旧 manifest is_active=false
        ▼
     [active]
        │
        ├─── deprecate ──▶ [deprecated]
        │                       │
        │                       │ revoke
        │ revoke                ▼
        ▼                   [revoked]
    [revoked]
```

### content_release（rollback 旁注）

```
                           rollback
   [deprecated] ──────────────────────────▶ [active]   ✅ 唯一允许
        ▲                                        │
        │ (同时 demote 当前 active)              │
        └────────────────────────────────────────┘

   [revoked] ─────╳─────▶ [active]   ❌ 永远不允许（revoke 是不可逆硬撤回）
```

注：
- `approve` 不是状态转换，仅写 `approved_by` 字段 + audit log entry（form `from=to=validated`）
- `rollback` 仅 deprecated → active；revoked 永远不能恢复（操作员要恢复需 `create-release` 起新 release）

### audio_assets GC

```
[ready] ──新版 publish──▶ [superseded] ──grace_days_promote──▶ [eligible_for_gc] ──grace_days_delete──▶ [deleted]
                                                                       │
                                                                       └─ FS 删除失败 → 留 eligible_for_gc，下次重试
```

`orphan-scan` 与 `gc-stale` 互补：`gc-stale` 由 PG 状态机驱动（PG 有行 + status='eligible_for_gc' → 删 FS），
`orphan-scan` 由 FS 驱动（FS 有文件 + PG 无引用 → 删 FS）。两者目录不同：
`gc-stale` 仅扫 cdn-mock；`orphan-scan` 同时扫 cdn-mock 和 audio-pipeline-staging。

参考 v0.3 §B.4.5（release 状态机）/ §B.7.3（不可逆原则）

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

### Day 5 实装

#### `deprecate` ✅ （**软下线**，不是 revoke）

active release 的软下线入口。state 变为 `deprecated` 后 manifest API 不再返回该
release 下的包，但 `content_manifest.is_active` 保留为 true，方便未来 PR-B
`rollback --to <release>` 重新激活。

```bash
python scripts/content_pipeline/pipeline.py deprecate rel-2026-05-05-001 \
  --reason "下个版本即将上线，先做软切" \
  --yes
```

参数：
- `release_id` 必填
- `--reason <txt>` **必填**（写入 activation_log，治理审计）
- `--yes` 跳过 stdin 二次确认（CI 用）

**副作用契约**（v0.3 PR-A Day 5 评审采纳 R2.3）：
- 仅改 `content_release.status` + 写 activation_log entry
- **不动** `content_manifest.is_active`
- manifest API 自然不返回（dual-condition 卡 status='active'）

`deprecate` vs `revoke` 区别：
- `deprecate`：软下线，manifest 行保留 active；可被 PR-B rollback 重新激活
- `revoke`：硬撤回，manifest 行 cascade `is_active=false`，不可逆

#### `list-releases` ✅

治理可视化：表格列出 release 概览。只读。

```bash
\ 全部
python scripts/content_pipeline/pipeline.py list-releases

\ 仅 active
python scripts/content_pipeline/pipeline.py list-releases --status active

\ 限制 10 行
python scripts/content_pipeline/pipeline.py list-releases --limit 10
```

参数：
- `--status {draft|validated|active|deprecated|revoked}` 可选过滤
- `--limit N` 范围 [1, 500]，默认 50；越界报错退出码 2

排序：`created_at DESC, release_id DESC`（二级键防同秒抖动 R2.11）。

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

# 6. 治理可视化
python scripts/content_pipeline/pipeline.py list-releases --status active

# 后续如要替换:
# 7. 创建新 release，publish 新版本，validate，activate
#    → 自动 cascade deactivate 旧 manifest
# 8a. 老 release 软下线（保留可 rollback）:
#     python scripts/content_pipeline/pipeline.py deprecate rel-001 --reason "...
" --yes
# 8b. 或紧急硬撤回:
#     python scripts/content_pipeline/pipeline.py revoke rel-001 --reason "...
"
```

## Troubleshooting

### `validate` 报 "package_set ↔ release_id mismatch"

含义：`content_release.package_set` 与 `content_manifest.release_id` 双向一致性失败。
真实检查在 `pipeline.py cmd_validate()` Step 3-4（forward + reverse 双向 set diff）。

原因：手动 SQL 改过其中一边、或 `publish-manifest` 用错 release_id。

处置：跑 `list-releases` 找 release，SELECT `package_set` + 对应 manifest 行，手工 UPDATE 对齐后重跑 `validate`。

### `publish-manifest` 报 "publish-manifest only allowed in 'draft' state"

含义：尝试在 validated / active / deprecated / revoked release 上添加 manifest。

原因：validated 后 package_set 冻结（治理硬约束，pipeline.py:168 状态守卫）。

处置：要么改加到新 release（create-release + publish + validate），要么 revoke
老 release 后从头来过。

### `gc-stale` 总是报 "skipped {n}: file not resolvable"

原因：`file_url` 是 `http://...//cdn/` 形式但 `cdn-mock` 路径不对，或 `file:///`
在 Windows 下 drive letter 没正确剥离。

处置：检查 `--cdn-mock-dir` 参数；`--dry-run` 模式下完整列出每个 url 的 resolved path。

### 完整 publish 流程被 stdin 卡住

原因：`activate` / `deprecate` 默认 stdin 二次确认；`gc-stale` 默认 `--dry-run`，
需 `--gc` 显式开。

处置：CI 加 `--yes` / `--gc`。

### `content_hash` mismatch

含义：`build-examples-package` 算出的 hash 与 PG 中持久值不一致。

真实算法位置：`apps/api/scripts/audio_pipeline/reference.py`
- `canonical_json_bytes()` line 74-97
- `compute_example_content_hash()` line 176-230

原因：cn / difficulty / ordinal / status 等 package-visible 字段变动会让 content_hash 变；
en 变动通常应生成新 stable_id。

处置：重跑 `build-examples-package`；如真要变动 stable_id 集合，遵循 "老 release deprecate +
新 release active" 流程。

### activate 报 "activate requires prior approval (env CONTENT_RELEASE_REQUIRE_APPROVAL is set)"

含义：环境变量 `CONTENT_RELEASE_REQUIRE_APPROVAL` 为 truthy（true/1/yes/on，大小写不敏感、空格容忍），
但 release 的 `approved_by` 字段为空。

处置：先 `pipeline.py approve <release_id> --approver <id>` 写入 approver，再 activate。
临时关闭审批（不推荐）：`unset CONTENT_RELEASE_REQUIRE_APPROVAL` 或设为 false。

### approve 报 "approver must be non-empty / non-whitespace"

含义：CLI 收到 `--approver ""` 或 `"   "`（纯空格）。

处置：传非空字符串，长度 ≤ 64（与 schema VARCHAR(64) 对齐）。

### rollback 报 "manifest ... file missing on FS"

含义：rollback target release 的某个 manifest 文件已被 gc-stale 或手动删除。

处置：要么找回文件（从备份），要么放弃此次 rollback，用 `create-release` 起新 release 重发布。
**不要**手动 INSERT 假文件——content_hash 校验在 manifest API 路径里依赖文件真实性。

## 设计要点

1. **content_release 是治理 SSOT**（v0.3 §B.4.5）。`package_set` 是 denormalized
   snapshot，事实源是 `content_manifest.release_id`。validate 阶段强制双向对齐。

2. **状态机**: draft → validated → active → deprecated/revoked
   - draft：可改 package_set（publish-manifest 唯一允许阶段）
   - validated：冻结，不可改 package_set；只能 activate 或重新 create
   - active：包正在生效（manifest API 仅返回此状态）
   - deprecated：软下线（Day 5 加 CLI 入口）；manifest.is_active 保留 true 留 PR-B rollback 余地
   - revoked：硬撤回终态；cascade is_active=false，不可逆

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

## v0.3 PR-B1 实装总览

PR-B1 "发布侧补全" 4 天交付，基于 PR-A 已建立的 release 状态机基座扩展：

| Day | 子命令 / 改动 | 影响 |
|---|---|---|
| 1 | `orphan-scan` | 双根 FS 扫描（cdn-mock + audio-pipeline-staging）+ 白名单 4 条防误删 |
| 2 | `rollback` | 状态机加 deprecated → active 一条；不允许 revoked → active |
| 3 | `approve` + activate gating | 治理审批（默认 false 向后兼容；approved_by 字段已在 PR-A 留位） |
| 4 | README + PR 描述 + smoke | 文档收尾 + 拆分 sub-smoke 验证 |

详见 `docs/design/v0.3_PR-B_scope_v0.1.md` / `docs/design/pr-b1.md` /
`docs/design/pr-b1-day{1,2,3,4}-*.md`。

## v0.3 PR-B3 (mobile manifest sync wire-up)

3-day delivery (`feat/v0.3-pr-b3-feature-flag-wire-up`) adds the mobile-side
plumbing to consume manifests served by the pipeline.

### Day 1 — Server staging serve route + manifest URL transform

- `GET /cdn/staging/<file>` → `apps/api/audio-pipeline-staging/<file>` (dev only).
- `manifest` API in dev mode rewrites `file:///*\/audio-pipeline-staging/<file>`
  → `http://{host}/cdn/staging/<file>` and `file:///*\/cdn-mock/<rel>` →
  `http://{host}/cdn/<rel>` so Flutter clients can fetch via HTTP GET.
- **Production behavior unchanged**: `if (!isProdEnv)` guard around the
  staging `useStaticAssets` registration in `main.ts`; `manifest` API still
  skips `file://` rows in production (PR-A behavior preserved).
- Strict `Host` header check in dev mode — missing header throws 500
  rather than silently falling back to a hardcoded host:port.

### Day 2 — Mobile feature flag + WordbookLoader D1 收口

- `LocalSettingsService.manifestSyncEnabled` SharedPreferences flag,
  default `false`. Wiring deferred to Day 3.
- `WordbookLoader._clearContentTables(bookSlug)` no longer wipes
  `example_sentences` unconditionally on a bundle version bump. When the
  local DB has any `content_package_states` row matching this book's
  `examples-<slug>` package, only rows with `stable_id IS NULL` (legacy
  pre-v0.3-P0 bundle rows) are deleted — manifest-installed rows and
  modern bundle rows with stable_id survive.
- bookSlug → packageName mapping handles `book-001 → examples-cet4`;
  other books map by `examples-<slug>` directly.
- **v0.4 scope §1.3 implicit limit (documented)**: once a book has manifest
  examples, bundle examples upgrades for that book are suppressed. Both
  unique indexes on `example_sentences` — `(word_id, sort_order)` and
  `stable_id` — make the InsertOrIgnore reimport a no-op against any
  preserved row. Bundle examples content updates flow via server-pushed
  manifest packages from this point on; bundle JSON only seeds fresh
  installs and books that never received manifest packages.

### Day 3 — Startup hook + settings page debug switch + sub-smokes

- `main.dart` runs a fire-and-forget `runManifestSyncIfEnabled(db: appDb)`
  helper before `runApp()`. **Three guards, in order**:
  1. `kDebugMode` — release/profile builds dead-code-eliminate the entire
     hook, so a SharedPreferences flag set in a debug build can never
     trigger sync after upgrading to a same-package release build.
  2. `LocalSettingsService.manifestSyncEnabled` — feature flag, default
     false, off until the user opts in.
  3. `ContentPackageService.syncIfNeeded(appVersion: PackageInfo
     .fromPlatform().version)` — real app version (currently `0.0.1`)
     sent to the server so its `min_app_version` filter actually engages.
- Settings page `调试` section gains a `kDebugMode`-only `SwitchListTile`
  ("Manifest sync (PR-B3 dev)") that toggles the flag. Existing debug
  ListTiles ("复习历史" / "重新导入增强数据") keep their pre-PR-B3
  release visibility unchanged.
- **Startup parity guarantee**: when flag=false or build is non-debug,
  the helper returns immediately. The `runApp()` call is not preceded by
  any new awaits, so the cold-start sequence is byte-for-byte identical
  to PR-B2 in those cases.

### Sub-smokes (manual, pre-PR)

A. flag=false default → app behaves identically to PR-B2.
B. flag=true + dev API up → manifest sync writes drift; logcat shows
   "manifest sync result: installed=N replaced=M …".
C. flag=true + offline → app starts normally, sync fails silently.
D. flag=true bundle v3 + manifest install → bump bundle to v4 → restart
   → manifest data preserved (D1 收口 real-device regression).
E. flag=true full E2E: dev API → `/cdn/staging/...` URL → DownloadManager
   fetches → checksum → install → drift readback. Detailed commands in
   master plan v0.2.

## v0.3 PR-B4 (default flag flipped to true)

Single-day follow-up to PR-B3. `LocalSettingsService.manifestSyncEnabled`
default flips from `false` to `true`, so dev/profile builds auto-sync on
cold start without the user toggling the debug switch.

**Release behavior unchanged.** PR-B3's three-layer guard in
`runManifestSyncIfEnabled` (main.dart) is fully preserved:
1. `if (!kDebugMode) return;` — release builds dead-code-eliminate the
   entire hook.
2. `if (!manifestSyncEnabled) return;` — feature flag gate (now defaults
   to true in dev/profile only).
3. `syncIfNeeded(appVersion: …)` — actually runs sync.

Removing the `kDebugMode` guard is deferred to PR-B5, which will land
**after** PR-C swaps `pipeline.py`'s `file://` URLs for real CDN
(https://) URLs. Until PR-C, production manifest API skips all `file://`
rows and would return an empty packages list to release clients anyway,
so flipping release behavior on now would just add empty network
roundtrips and server log noise.

Existing dev users who explicitly turned the switch OFF in PR-B3 keep
their `false` value (SharedPreferences only consults the default when
the key is absent). Users who never touched the switch get the new
default on next cold start.

## v0.3 PR-C (Tencent COS integration + S1=β mobile 4-service env + PR-B5 release default-on)

PR-C swaps `pipeline.py`'s `file://` URLs for real Tencent COS public-read
URLs and unblocks release-build full-chain via `--dart-define=API_BASE`.

### PR-C 边界声明（β 切 baseUrl 但 audio 资产仍预存债务，留 PR-D）

PR-C 兑现「release mobile 4 service baseUrl 切 production + COS 接入」。

Release 用户**能**：
- ✅ 启动从 COS 拉 manifest → 导入 drift（`ManifestClient`）
- ✅ ApiClient 业务接口走真域名（取题目 / 设置 / 等）
- ✅ Audio/Pronunciation **metadata API 调用** 走真域名（返 JSON 200）

Release 用户**仍不能**（R4-2 / R4-3 揭示的 PR-D 范围）：
- ❌ 真**播放**例句 mp3 字节：`audio_assets.url` 仍是 `ingest-audio-assets.ts:90`
  写入的 emulator host（`http://10.0.2.2:3000/cdn/...`）→ GET 该 url timeout
- ❌ 真**听**单词发音 wav 字节：`data/pronunciation/` 在 Docker image 内不存在
- ❌ `/cdn` static route 在 production 服不到 mp3：`apps/api/cdn-mock/` 在 repo 仅 `.gitkeep`

**PR-D 范围（R4 后明确）**：audio mp3 + pronunciation wav 接 COS 或 mount 进
container；`partial_publish.py` / `ingest-audio-assets.ts` 改用 https origin
重 ingest `audio_assets.url`；server `/cdn` static route 删除。估时 ~2-3d。

### pipeline.py prerequisites

- Tencent COS bucket (ap-shanghai recommended), public-read ACL
- CAM subaccount with `QcloudCOSDataWrite` scoped to the bucket
- `pip install -r apps/api/scripts/content_pipeline/requirements.txt` (adds
  `boto3>=1.34.0` and `python-dotenv>=1.0.0`)
- `.env` populated per `.env.example` (R3 P1 + R4-1: `pipeline.py` only reads
  `DATABASE_URL`, NOT `PG*` split env):
  ```
  DATABASE_URL=postgresql://postgres:<password>@localhost:5432/<dbname>
  COS_REGION COS_BUCKET COS_SECRET_ID COS_SECRET_KEY COS_PUBLIC_URL_BASE
  ```
- Connect to production DB via SSH tunnel (recommended):
  ```
  ssh -L 5432:localhost:5432 user@your-server-ip
  # Then in .env:
  DATABASE_URL=postgresql://postgres:<prod-password>@localhost:5432/meow_prod
  ```

### `publish-manifest` post-PR-C

`publish-manifest` derives the expected COS URL from
`<package_name>@<version>` + file suffixes, **checks PG idempotent /
conflict first**, and only uploads to COS if it's a genuinely new INSERT.
Re-runs of the same manifest with the same content cost **zero network
IO** (R1#3 + R2#2: vs v0.1's "upload first then check" which would corrupt
the COS object on conflict-with-different-content). Different content
under the same manifest_id remains a hard error per PR-A — bump
`content_version` instead.

`Cache-Control: public, max-age=31536000, immutable` on the COS object
because the URL key is content-addressable. `ContentType` auto-detected by
`mimetypes.guess_type` (R1#11; future .br/.tar.gz transparently handled).

### `validate` post-PR-C (R1#1 + R3 P2: https-only)

`pipeline.py validate <release>` accepts `https://` URLs in addition to
legacy `file://` (R1#1). **`http://` is rejected** (R3 P2: production must
be HTTPS; plain http is a security regression). `https://` URLs skip local
file existence / checksum / size checks — mobile DownloadManager performs
sha256 on download (PR-B2). Server-side HEAD verification 留 v0.4 §7.4.

### `orphan-scan` break change post-PR-C (R1#4)

Default `--scope` changed from `'all'` to `'audio'` (cdn-mock only). PR-C
moves all manifest packages to COS, so `audio-pipeline-staging` files are
build intermediates with no PG reference — under the old default they
would all be flagged as orphans by `orphan-scan --clean`.

The actual `orphan_scan.py` choices are `audio` / `packages` / `all`
(NOT `staging`; v0.1 plan typo'd this). To clean staging intermediates
explicitly:

```bash
pipeline.py orphan-scan --scope packages --clean  # only audio-pipeline-staging
pipeline.py orphan-scan --scope all --clean       # both (PR-B1 default behavior)
```

### Server cleanup

PR-B3 Day 1's `/cdn/staging` static route + `transformFileUrlForDev` helper
+ `isProdEnv` const are **all removed**. `pipeline.py` always writes https
URLs now, so the `manifest` API can pass `file_url` straight through. The
defensive `file://` skip remains (any leftover row from pre-PR-C ingest is
treated as a data bug and skipped in any environment).

### PR-B5 (merged into PR-C) + S1=β

PR-B3 Day 3's `runManifestSyncIfEnabled` Layer-1 guard
`if (!kDebugMode) return;` is **removed**. With real CDN URLs reaching
production clients via S1=β + COS, release builds also auto-sync. The
settings page `SwitchListTile`'s `if (kDebugMode)` wrap is removed too;
the title is rebranded from "Manifest sync (PR-B3 dev)" to user-facing
"内容自动更新". The `flutter/foundation` import is removed from both
`main.dart` and `settings_page.dart` (R2#6: would otherwise be an unused
import).

**S1=β (mobile baseUrl 4 service env-aware)**:

New `apps/mobile/lib/core/config/api_base.dart` exports:
```dart
const String apiV1Base = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:3000/api/v1',
);
```

4 mobile services switch to `apiV1Base`:
- `ManifestClient.baseUrl`
- `ApiClient.baseUrl`
- `ExampleAudioService._baseUrl` (`static const → final` + `{String? baseUrl}` named optional)
- `PronunciationService._baseUrl` (same pattern)

Build for release:

```bash
flutter build apk --release \
  --dart-define=API_BASE=https://api.<your-domain>.<tld>/api/v1
```

Without the `--dart-define`, all 4 services fall back to `10.0.2.2` and
release-build manifest/api/audio/pronunciation requests time out
(visible in `adb logcat`, not silent failure).

## v0.3 PR-D (Option A: audio + pronunciation 全 COS；闭合 PR-C R4-2/R4-3)

PR-D 闭合 PR-C v0.3 §0.5.1 caveat 列出的 release **仍不能** 3 条：真播 mp3 字节 /
真听 wav 字节 / `/cdn` static route 不存在。Option A 全 COS：

- audio mp3 上 COS；`audio_assets.url` 重写指 COS public-read URL
- pronunciation wav 上 COS；controller 改 302 redirect → COS
- server `/cdn` static route 删除（不再依赖容器内文件）
- mobile **0 改动**（D2=a；http package 默认 follow 302；audioplayers UrlSource
  走 system http stack 也 follow）

### 6 个 scope 决策

| # | 决策 | 理由 |
|---|---|---|
| **D1** | 全 COS（audio + pronunciation 都迁）| release 流量不在 app server；架构一致；未来真接 CDN 边缘节点零成本 |
| **D2** | pronunciation API = **302 redirect to COS URL**；mobile 0 改动 | mobile 不动 + API URL 形态保 + 未来切 CDN 改 redirect target 即可 |
| **D3** | COS 路径 layout 沿用现有 fs layout | audio: `audio/v1/{kind}s/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3`；pronunciation: `pronunciation/{locale}/{voice}/v1/{firstLetter}/{word}.wav` |
| **D4** | 一次性 bootstrap = 新 ts 工具同步 dev fs → COS；不动 `partial_publish.py` | partial_publish 仍写 `local://cdn/...` placeholder + 写 cdn-mock dir（dev 仍 work） |
| **D5** | server `/cdn` static route **删除** | Option A 不再需要 server-side 静态文件 |
| **D6** | release 端 SwitchListTile 文案 / kDebugMode 不动 | PR-C/PR-B5 已处理 |

### 一次性 bootstrap（用户操作 ~1-1.5 hr）

1) **同步 dev fs → COS**（在 dev 机本地跑）：

   ```bash
   cd apps/api

   # audio mp3（path layout：--src 已包含 audio/v1，--prefix audio/v1 单层不重复）
   npx ts-node scripts/sync-audio-mp3-to-cos.ts \
     --src cdn-mock/audio/v1 \
     --prefix audio/v1 \
     --commit

   # pronunciation wav
   npx ts-node scripts/sync-pronunciation-to-cos.ts \
     --src data/pronunciation \
     --prefix pronunciation \
     --commit
   ```

   两个工具都是 idempotent：HEAD ETag 检查 → skip 同 md5 文件；中断重跑安全。
   流式上传（`createReadStream` + `ContentLength`），不受单文件大小约束。
   **dry-run 模式默认**；加 `--commit` 才真上传。

   **prerequisite**：`apps/api/data/pronunciation/` 在 dev 机存在。如不存在
   （PR-C R4-3 已揭示）：(a) 从备份恢复；(b) 跑 pronunciation pipeline 重新
   生成；(c) 跳过本步 → F4 暂仍 expected fail。

2) **重写 PG `audio_assets.url`**（一次性）：

   ```bash
   # Dry-run 先看 sample 3 行 before/after
   npx ts-node scripts/repipe-audio-urls.ts \
     --from 'http://10.0.2.2:3000/cdn' \
     --to   'https://<bucket>.cos.<region>.myqcloud.com'

   # commit
   npx ts-node scripts/repipe-audio-urls.ts \
     --from 'http://10.0.2.2:3000/cdn' \
     --to   'https://<bucket>.cos.<region>.myqcloud.com' \
     --commit
   ```

   单事务；dry-run 自动 ROLLBACK；`--commit` 显式才 COMMIT。LIKE 前缀精确匹配；
   二次跑 0 行匹配（幂等）。

3) **部署新 NestJS image**（含 pronunciation 302 redirect + 删 `/cdn` route）：

   ```bash
   cd apps/api
   docker build -t meow-api:latest .
   ssh user@server 'cd /path/to/compose && docker compose up -d --force-recreate api'
   ```

4) **验证**：

   ```bash
   # COS 直读
   curl -I '<COS_PUBLIC_URL_BASE>/audio/v1/examples/.../<audio_id>.mp3'
   curl -I '<COS_PUBLIC_URL_BASE>/pronunciation/en-US/am_michael/v1/a/abandon.wav'

   # server pronunciation API → 302 + Location
   curl -I 'https://api.<your-domain>/api/v1/pronunciation/abandon?locale=en-US&voice=am_michael'
   # 期望: HTTP/2 302 + location: <COS URL>

   # follow redirect → COS wav
   curl -L 'https://api.<your-domain>/api/v1/pronunciation/abandon' -o /tmp/abandon.wav
   ```

### server-side env（PR-D 必填）

`apps/api/.env`：

```
AUDIO_CDN_ORIGIN=https://<bucket>.cos.<region>.myqcloud.com
PRONUNCIATION_CDN_ORIGIN=https://<bucket>.cos.<region>.myqcloud.com
```

- `AUDIO_CDN_ORIGIN`：`scripts/ingest-audio-assets.ts` 必读（fail-fast；缺失
  exit 2）。R4 P1#2 R2：`/cdn` route 已删，老 `10.0.2.2:3000` fallback 移除，
  避免写出 forever-404 URL 进 PG。
- `PRONUNCIATION_CDN_ORIGIN`：NestJS `pronunciation.controller.ts` 必读；缺失
  抛 `InternalServerErrorException`（500，**不是** 404 — R4 P1-3）。
- 单 bucket 时两者同值；split 出来留给 multi-bucket 弹性。

`apps/api/scripts/content_pipeline/.env`（PR-C 已建；PR-D sync 工具复用）：
`COS_REGION` / `COS_BUCKET` / `COS_SECRET_ID` / `COS_SECRET_KEY` /
`COS_PUBLIC_URL_BASE`。

### pronunciation API 形态变化（D2=a）

PR-A：

```
GET /api/v1/pronunciation/abandon
  → 200 + audio/wav stream (server reads data/pronunciation/.../*.wav)
```

PR-D：

```
GET /api/v1/pronunciation/abandon
  → 302 Found
    Location: https://<bucket>.cos...../pronunciation/en-US/am_michael/v1/a/abandon.wav
client follow → COS 200 + audio/wav
```

mobile `http` package 默认 maxRedirects=5 → follow 透明；`PronunciationService` 0 改动。

### 后续 ingest 流程（新 mp3 加入）

1. dev 机 `partial_publish.py` 跑 → `cdn-mock/` 写 mp3 + `audio_assets.jsonl` 写
   `local://cdn/...` placeholder
2. dev 机 `sync-audio-mp3-to-cos.ts` 跑 → 增量上传新 mp3 到 COS（HEAD ETag skip）
3. `ingest-audio-assets.ts` 跑（dev 或 server）→ `cdnOrigin` 从 `AUDIO_CDN_ORIGIN`
   env 读 → INSERT/UPDATE PG `audio_assets.url` 指 COS

`partial_publish.py` 不动（仍写 `local://cdn/...` placeholder + cdn-mock dir
供 dev 本地 + sync 工具的 src）。

### sub-smoke A-F1-F4 真机（PR-D 后）

承袭 PR-C sub-smoke 命令；F2/F3/F4 从 expected-fail 翻 PASS：

| # | 场景 | 期望 |
|---|---|---|
| A-E | 同 PR-C | 全 PASS（regression） |
| **F1** (β baseUrl) | release ApiClient | 200 + `https://api.<domain>/api/v1/...` |
| **F2** (PR-D 关键) | release ExampleAudioService metadata API | 200 + `url` 字段含 `.cos.` 而**不**含 `10.0.2.2` |
| **F3** (PR-D 关键) | F2 metadata.url GET → mp3 字节 | **200** + audio/mpeg（PR-C 时 timeout，现在 PASS）|
| **F4** (PR-D 关键) | release PronunciationService → wav | 第一跳 302 + Location → 第二跳 COS 200 + audio/wav（PR-C 时 404，现在 PASS）|

## Reference

- `docs/design/词书单词例句与例句音频架构_v0.3.md` §B.4 / §B.7 / §B.10
- `docs/design/DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md` r7 §3.4 / §4.7
- `apps/api/scripts/audio_pipeline/reference.py` (hash impls)
- `tests/fixtures/example_content_hash.yaml` (golden fixtures)
