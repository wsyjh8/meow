# PR-D plan v0.1 — Option B (server volume mount) 详细实施

- **Date**: 2026-05-07
- **Status**: plan v0.1 — 与 `pr-d-scope.md` v0.1 同步；待评审 + 确认 D1=B
- **基线 commit**: PR-C head `2a3cbeb`（依赖 PR-C merge 进 main 后 rebase）
- **工作分支**: `feat/v0.3-pr-d-audio-asset-ingest-cos`
- **预算**: 用户 50 min（Phase 0 + 真机 sub-smoke）+ 我 1d（Phase 1-2）

---

## 起手前 recon（已完成）

```bash
# audio_assets URL 当前形态
grep -n "url" apps/api/src/infrastructure/postgres/migrations/004_audio_assets_pilot.sql | head
# → line 66: url TEXT NOT NULL  -- CDN URL (or 'local://...' before publish)

# ingest-audio-assets.ts cdnOrigin 默认值
grep -n "cdnOrigin" apps/api/scripts/ingest-audio-assets.ts | head
# → line 90: cdnOrigin: get('--cdn-origin', 'http://10.0.2.2:3000/cdn')
# → line 158: row.url = cdnOrigin + row.url.substring('local://cdn'.length)

# pronunciation controller 依赖路径
grep -n "data/pronunciation\|dataDir" apps/api/src/controllers/pronunciation.controller.ts
# → controller 读 path.resolve(__dirname, '..', '..', 'data', 'pronunciation', ...)
# → 编译后 dist/controllers → 项目根 → /app/data/pronunciation/...
# → Option B 需 volume mount /app/data/pronunciation

# main.ts /cdn static route (PR-C 后)
grep -n "useStaticAssets" apps/api/src/main.ts
# → line ~36: app.useStaticAssets(join(__dirname, '..', 'cdn-mock'), { prefix: '/cdn' })
# → 项目根 cdn-mock/. 编译后 dist/.. = /app
# → Option B 需 volume mount /app/cdn-mock

# Dockerfile (PR-C 已加, NOT COPY cdn-mock + data/pronunciation)
grep "COPY\|cdn-mock\|data/pronunciation" apps/api/Dockerfile
# → 不 COPY (PR-C 故意避免传空目录); Option B 走 volume mount

# audio_assets 表当前数据预估
# 假设 dev 机 PG 里若干 row, url 全是 http://10.0.2.2:3000/cdn/audio/v1/...
# (以 ingest 默认参数写入). production PG 同样状态 (因为 PR-A → PR-B → PR-C
# 所有 ingest 都用默认 cdnOrigin)
```

---

## Phase 0 — 用户操作（你做，~30 min；含 server-side rsync + docker-compose 改）

### 0.1 估算资产大小

```bash
# 在 dev 开发机
du -sh apps/api/cdn-mock/
du -sh apps/api/data/pronunciation/
# 如果总和 > 5GB 考虑 Option A audio 迁 COS (PR-E 候选; 当前先 Option B)
```

### 0.2 rsync 资产到 server

```bash
# 1. 在 server 上建目录 (一次性)
ssh user@<your-server>
sudo mkdir -p /var/lib/meow/cdn-mock /var/lib/meow/data/pronunciation
sudo chown $USER:$USER /var/lib/meow -R
exit

# 2. 在开发机同步 (--delay-updates 防部分文件可见;
#    --delete 让 server 与 dev 一致;
#    -avz 增量 + verbose + 压缩传输)
cd /d/code/AI/startUp/meow/apps/api

rsync -avz --delete --delay-updates \
  cdn-mock/ \
  user@<your-server>:/var/lib/meow/cdn-mock/

rsync -avz --delete --delay-updates \
  data/pronunciation/ \
  user@<your-server>:/var/lib/meow/data/pronunciation/
```

### 0.3 docker-compose.yml 加 volumes（部署目录改 2 行）

```yaml
services:
  api:
    image: meow-api:latest
    environment:
      DATABASE_URL: postgresql://postgres:${PG_PASSWORD}@postgres:5432/meow_prod
      NODE_ENV: production
      VIRTUAL_HOST: api.<your-domain>
      VIRTUAL_PORT: '3000'
      LETSENCRYPT_HOST: api.<your-domain>
      LETSENCRYPT_EMAIL: <your-email>
    volumes:
      # PR-D Option B: mount audio mp3 + pronunciation wav 资产, 让 NestJS
      # /cdn static route 和 pronunciation.controller.ts 能读到 (R4-2/R4-3 收口).
      # 资产由开发机 rsync 到 server /var/lib/meow/... (一次性 + 增量).
      - /var/lib/meow/cdn-mock:/app/cdn-mock:ro
      - /var/lib/meow/data/pronunciation:/app/data/pronunciation:ro
    depends_on: [postgres]
    expose: ['3000']
    restart: unless-stopped
  # ... 其它 service 不变 (postgres / nginx-proxy / acme-companion)
```

注：`:ro` (read-only) 让 container 不能误改 server 资产；`:rw` 也可（如需 server-side 写）。

```bash
# server 上重启 api container
cd /path/to/docker-compose
docker compose up -d --force-recreate api
docker compose logs -f api  # 确认无 error
```

### 0.4 验证 nginx-proxy 反代 → /cdn + /api/v1/pronunciation 透传

```bash
# audio mp3 (random 已知文件; 看 cdn-mock/audio/v1/... 选一)
curl -I 'https://api.<your-domain>/cdn/audio/v1/examples/en-US/af_bella/v1/<shard>/<audio_id>.mp3'
# 期望: 200 OK; Content-Type: audio/mpeg; Content-Length 非零

# pronunciation wav
curl -I 'https://api.<your-domain>/api/v1/pronunciation/abandon?locale=en-US&voice=am_michael'
# 期望: 200 OK; Content-Type: audio/wav; Content-Length 非零
```

### 0.5 重 ingest PG `audio_assets.url`（一次性）

PR-C 后 mobile baseUrl 走 production 真域名，但 PG `audio_assets.url` 字段值
仍是 `http://10.0.2.2:3000/cdn/...` 老 cdnOrigin。需要 one-shot 工具重写。

详见 §"Phase 1 Step 1.2" 新工具 `repipe-audio-urls.ts` 用法。

```bash
cd /d/code/AI/startUp/meow/apps/api
# .env 已含 DATABASE_URL (开发机本地 / SSH tunnel 到 prod)
npx ts-node scripts/repipe-audio-urls.ts \
  --from 'http://10.0.2.2:3000/cdn' \
  --to   'https://api.<your-domain>/cdn' \
  --dry-run
# 期望: 列出 N 行将被重写, 显示 sample row before/after; 不改 PG

npx ts-node scripts/repipe-audio-urls.ts \
  --from 'http://10.0.2.2:3000/cdn' \
  --to   'https://api.<your-domain>/cdn' \
  --commit
# 期望: 在事务内 UPDATE; 输出 "rewrote N rows"
```

---

## Phase 1 — 代码改动（我做，~0.5d）

### Step 1.1 `ingest-audio-assets.ts` cdnOrigin 默认值改 + dotenv 读 env

文件：`apps/api/scripts/ingest-audio-assets.ts`，line 90

```diff
+// PR-D: cdnOrigin default reads AUDIO_CDN_ORIGIN env (loaded by dotenv block
+// at top); fallback to historical hardcode for back-compat with no-env setups.
-cdnOrigin: get('--cdn-origin', 'http://10.0.2.2:3000/cdn'),
+cdnOrigin: get(
+  '--cdn-origin',
+  process.env.AUDIO_CDN_ORIGIN || 'http://10.0.2.2:3000/cdn',
+),
```

注：dotenv loading block 已在文件顶部（PR-A 时加的）。`AUDIO_CDN_ORIGIN` 不读时回落老 hardcode（不破 dev 行为）。

### Step 1.2 新工具 `apps/api/scripts/repipe-audio-urls.ts`

PR-D one-shot 工具：扫 PG `audio_assets` 表，把 url 字段从 `<old-prefix>/...`
重写为 `<new-prefix>/...`。dry-run + commit 双模；事务内执行；幂等（`--from`
不匹配的行不动）。

```typescript
/**
 * PR-D: One-shot tool to rewrite audio_assets.url prefix in PG.
 *
 * Use case: PR-C ingest used cdnOrigin='http://10.0.2.2:3000/cdn' (emulator
 * host, default); PR-D Option B switches to 'https://api.<your-domain>/cdn'
 * (server volume mount via nginx-proxy reverse proxy). Existing PG rows
 * still carry the old prefix → release users get metadata 200 but mp3
 * timeout. This tool rewrites them.
 *
 * Idempotent: rows whose url doesn't start with --from are NOT touched.
 * Safe: dry-run by default; --commit required to actually write.
 *
 * Usage:
 *   npx ts-node scripts/repipe-audio-urls.ts \
 *     --from 'http://10.0.2.2:3000/cdn' \
 *     --to   'https://api.<your-domain>/cdn' \
 *     [--dry-run | --commit]
 *
 * Future: same pattern works for 'http://10.0.2.2:3000/cdn' → COS URL
 * when PR-E lands (Option A audio migration).
 */

import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';

// dotenv loading (same pattern as ingest-audio-assets.ts)
const envPath = path.resolve(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf-8');
  for (const line of envContent.split('\n')) {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const eqIdx = trimmed.indexOf('=');
      if (eqIdx > 0) {
        const key = trimmed.substring(0, eqIdx);
        const value = trimmed.substring(eqIdx + 1);
        if (!process.env[key]) process.env[key] = value;
      }
    }
  }
}

interface Args {
  from: string;
  to: string;
  commit: boolean;
}

function parseArgs(): Args {
  const argv = process.argv.slice(2);
  const get = (flag: string): string | null => {
    const idx = argv.indexOf(flag);
    if (idx >= 0 && idx + 1 < argv.length) return argv[idx + 1];
    return null;
  };
  const has = (flag: string): boolean => argv.includes(flag);

  const from = get('--from');
  const to = get('--to');
  if (!from || !to) {
    console.error('Usage: ts-node repipe-audio-urls.ts --from <old-prefix> --to <new-prefix> [--commit | --dry-run]');
    process.exit(2);
  }
  if (has('--commit') && has('--dry-run')) {
    console.error('ERROR: --commit and --dry-run are mutually exclusive');
    process.exit(2);
  }
  // Default dry-run unless --commit explicit
  const commit = has('--commit');
  return { from, to, commit };
}

async function main() {
  const args = parseArgs();
  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    console.error('ERROR: DATABASE_URL not set');
    process.exit(2);
  }

  const pool = new Pool({ connectionString: dbUrl });
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Count rows that match --from prefix
    const countRes = await client.query<{ n: string }>(
      `SELECT COUNT(*)::text AS n FROM audio_assets WHERE url LIKE $1`,
      [args.from + '%'],
    );
    const matchCount = parseInt(countRes.rows[0].n, 10);

    console.log(`mode: ${args.commit ? 'COMMIT' : 'DRY-RUN'}`);
    console.log(`from: ${args.from}`);
    console.log(`to:   ${args.to}`);
    console.log(`matched rows: ${matchCount}`);

    if (matchCount === 0) {
      console.log('No rows match --from prefix; nothing to rewrite.');
      await client.query('ROLLBACK');
      return;
    }

    // Show 3 sample rows before
    const sampleRes = await client.query<{ id: string; url: string }>(
      `SELECT id, url FROM audio_assets WHERE url LIKE $1 ORDER BY id LIMIT 3`,
      [args.from + '%'],
    );
    console.log('sample rows (before):');
    for (const row of sampleRes.rows) {
      console.log(`  ${row.id}: ${row.url}`);
      const newUrl = args.to + row.url.substring(args.from.length);
      console.log(`    → ${newUrl}`);
    }

    if (!args.commit) {
      console.log('--dry-run mode; rolling back. Re-run with --commit to apply.');
      await client.query('ROLLBACK');
      return;
    }

    // Actually rewrite. SUBSTRING(url, FROM length(args.from) + 1) extracts
    // the path after the old prefix; concat to new prefix.
    const updateRes = await client.query(
      `UPDATE audio_assets
         SET url = $2 || SUBSTRING(url FROM ${args.from.length + 1})
       WHERE url LIKE $1`,
      [args.from + '%', args.to],
    );
    await client.query('COMMIT');
    console.log(`COMMIT: rewrote ${updateRes.rowCount} rows`);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('ERROR:', err);
  process.exit(1);
});
```

### Step 1.3 `.env.example` 加 `AUDIO_CDN_ORIGIN`

文件：`apps/api/.env.example`（如已存在；不存在新建）

```diff
+# PR-D Option B: production audio mp3 + pronunciation wav serve via
+# nginx-proxy reverse proxy on the same domain. Used by:
+#   - ingest-audio-assets.ts (--cdn-origin default)
+#   - repipe-audio-urls.ts --to (PR-D one-shot rewrite)
+# Leave commented to fall back to legacy hardcode 'http://10.0.2.2:3000/cdn'.
+#AUDIO_CDN_ORIGIN=https://api.your-domain.tld/cdn
```

### Step 1.4 verify TS compile + smoke

```bash
cd apps/api
npm install
npx tsc --noEmit -p tsconfig.json   # expect clean

# repipe smoke (dry-run; assumes .env has DATABASE_URL pointing at dev DB)
DATABASE_URL=postgresql://...@localhost:5432/meow_dev \
  npx ts-node scripts/repipe-audio-urls.ts \
  --from 'http://10.0.2.2:3000/cdn' \
  --to   'https://api.example.com/cdn' \
  --dry-run
# expect: matched rows: N; sample 3 rows; 'rolling back; --commit to apply'
```

---

## Phase 2 — README + PR description（我做 + 你跑 sub-smoke，~0.5d）

### Step 2.1 README PR-D 章节

`apps/api/scripts/content_pipeline/README.md` 末尾加 "## v0.3 PR-D" 章节：

```markdown
## v0.3 PR-D (audio asset ingest + Docker volume mount; PR-C R4-2/R4-3 收口)

PR-D 闭合 PR-C v0.3 §0.5.1 caveat 列出的 release 仍不能 3 条:
- ✅ 真播例句 mp3 (audio_assets.url 重 ingest 后指向 server /cdn/...)
- ✅ 真听单词发音 wav (data/pronunciation 通过 docker volume mount)
- ✅ /cdn static route 在 production 真 serve mp3

### Option B: server volume mount (PR-D 实施方案)

`docker-compose.yml` api service 加 volumes:
\`\`\`yaml
volumes:
  - /var/lib/meow/cdn-mock:/app/cdn-mock:ro
  - /var/lib/meow/data/pronunciation:/app/data/pronunciation:ro
\`\`\`

开发机一次性 rsync:
\`\`\`bash
rsync -avz --delete --delay-updates \\
  apps/api/cdn-mock/ user@server:/var/lib/meow/cdn-mock/

rsync -avz --delete --delay-updates \\
  apps/api/data/pronunciation/ user@server:/var/lib/meow/data/pronunciation/
\`\`\`

### 重写 audio_assets.url (一次性)

PR-C ingest 写入的 url 仍是 `http://10.0.2.2:3000/cdn/...`. PR-D 提供
one-shot 工具 `repipe-audio-urls.ts`:

\`\`\`bash
# Dry-run (不改 PG)
npx ts-node apps/api/scripts/repipe-audio-urls.ts \\
  --from 'http://10.0.2.2:3000/cdn' \\
  --to   'https://api.<your-domain>/cdn' \\
  --dry-run

# Apply
npx ts-node apps/api/scripts/repipe-audio-urls.ts \\
  --from 'http://10.0.2.2:3000/cdn' \\
  --to   'https://api.<your-domain>/cdn' \\
  --commit
\`\`\`

### 后续 ingest 使用新 cdnOrigin

`.env` 加:
\`\`\`
AUDIO_CDN_ORIGIN=https://api.<your-domain>/cdn
\`\`\`

之后 `ingest-audio-assets.ts` 默认读这个 env (back-compat: 没 env 时回落老
hardcode). 也可显式 `--cdn-origin <url>` 覆盖.

### Option A (audio + pronunciation 全 COS) — 留 PR-E

PR-D 走 Option B (server volume mount); 用户量起 / 带宽吃紧时切 Option A
(audio mp3 接 COS) 是 PR-E 候选. 估时 ~2-3d.
```

### Step 2.2 PR description (user dir)

`C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-D.md`（不进 commit）

11 章 + S1=B 决策 + sub-smoke F1-F4 现在应全过 + R4-2/R4-3 闭合声明。

### Step 2.3 sub-smoke A-F1-F4（你做真机；F2-F4 现在应全 PASS）

承袭 PR-C `sub-smoke A-E` + `F1-F4`。变化：

| # | 场景 | 期望 (PR-D 后) |
|---|---|---|
| A-E | 同 PR-C | 仍全 PASS |
| **F1** (β baseUrl) | release ApiClient 业务接口 | 200 + host = `api.<your-domain>` |
| **F2** (β baseUrl) | release ExampleAudioService metadata API | 200 + 返 `url` 字段 **不含 10.0.2.2**（含 `api.<your-domain>` 或 COS host）|
| **F3** (PR-D 关键) | F2 metadata.url GET → mp3 字节 | **200** + audio/mpeg（PR-C 时 expected timeout 现在 PASS）|
| **F4** (PR-D 关键) | release PronunciationService → wav | **API 200 + wav GET 200**（PR-C 时 expected 404 现在 PASS）|

---

## 关键文件

### 修改

| 文件 | 增 | 删 | 净 |
|---|---|---|---|
| `apps/api/scripts/ingest-audio-assets.ts` | ~5 | ~1 | +4 |
| `apps/api/.env.example` | ~5 | 0 | +5 |
| `apps/api/scripts/content_pipeline/README.md` | ~70 | 0 | +70 |

### 新建

| 文件 | 行数 |
|---|---|
| `apps/api/scripts/repipe-audio-urls.ts` | ~120 |
| `docs/design/pr-d-scope.md` | (本 commit) |
| `docs/design/pr-d-plan.md` | (本 commit) |
| `C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-D.md` | user dir |

### 不动

- mobile 整个 (β 已切)
- `apps/api/src/main.ts` (`/cdn` static route 保留)
- `apps/api/src/controllers/pronunciation.controller.ts`
- `apps/api/src/controllers/audio-assets.controller.ts`
- `apps/api/src/controllers/content-manifest.controller.ts`
- `apps/api/Dockerfile` (Option B 走 volume mount, 不 COPY)
- `apps/api/scripts/audio_pipeline/partial_publish.py` (仍写 `local://cdn/...` placeholder)
- `apps/api/scripts/content_pipeline/pipeline.py`
- 任何 mobile 测试 / e2e 测试

---

## 验证

### TypeScript type check

```bash
cd apps/api
npx tsc --noEmit -p tsconfig.json
# expect: clean (PR-D 仅加 1 ts file + 改 1 行 ingest)
```

### repipe smoke (dry-run)

```bash
# 在 dev 机连 dev DB (or SSH tunnel 连 prod)
DATABASE_URL=postgresql://postgres:password@localhost:5432/meow_dev \
  npx ts-node apps/api/scripts/repipe-audio-urls.ts \
  --from 'http://10.0.2.2:3000/cdn' \
  --to   'https://test.example.com/cdn' \
  --dry-run
# expect: matched rows: N; sample 3 rows; rolled back
```

### 用户真机 sub-smoke F1-F4

详见 §"Phase 2 Step 2.3"。**F3 + F4 是 PR-D 的 critical safeguard**（PR-C 时
expected fail，PR-D 后应全 PASS）。

---

## 风险

| 风险 | 缓解 |
|---|---|
| `repipe-audio-urls.ts` SQL 操作失误 | 默认 `--dry-run`；commit 必须显式 `--commit`；事务内 BEGIN/UPDATE/COMMIT；行 LIKE prefix 匹配（不模糊）|
| rsync 同步过程中 server 部分文件不一致 | `rsync --delay-updates`：所有更新先到 `.~tmp~/`，原子 mv 切换 |
| nginx-proxy serve 大量静态请求性能 | nginx 单核 10K req/s 起；早期用户量小不是瓶颈；监控 1-3 天再决定 |
| server 磁盘满（cdn-mock + data/pronunciation 总大） | Phase 0 §0.1 先 `du -sh` 估算；不够先扩容 |
| `audio_assets.url` 重写后破坏 client cache | client 缓存按 `audio_id` (DB §7.4)，不按 url；audio_id 不变 → 缓存继续命中 |
| `partial_publish.py` 之后 ingest 仍用老 cdnOrigin | `.env` `AUDIO_CDN_ORIGIN` 设置后 ingest-audio-assets.ts 自动读；如未设回落老 hardcode（不破回归测试）|
| pronunciation controller dataDir path 在 container 内不对 | recon: `path.resolve(__dirname, '..', '..', 'data', 'pronunciation')`；container 内 `__dirname=/app/dist/controllers` → `/app/data/pronunciation` ✓ 与 mount 路径吻合 |
| Docker volume mount 在 Linux server 权限错（uid/gid 不匹配）| `:ro` 模式只读 + `chown` server 上 dir 给 docker user；NestJS process 只读权限即可 |

---

## 提交策略

按 phase 拆 commit:

```
docs(v0.3-pr-d): scope v0.1 + plan v0.1 (Option B 推荐; A/C 备选)
feat(v0.3-pr-d): Phase 1 — ingest-audio-assets cdnOrigin default + repipe-audio-urls.ts
feat(v0.3-pr-d): Phase 2 — README PR-D 章节 + PR description
Merge feat/v0.3-pr-d-... → v0.3 PR-D audio asset 接通 (Option B; ~1d)
```

---

## 评审节奏

1. 本次：scope v0.1 + plan v0.1 push 让 codex / 用户 review；**重点 D1 决策（Option B vs A vs C）**
2. 评审吸收 → v0.2（如有 P0/P1）
3. Phase 0 你跑 (rsync + docker-compose 改 + 重 ingest)
4. Phase 1-2 我做 (ingest 改 + repipe-audio-urls.ts + README + PR description)
5. Phase 4 sub-smoke F1-F4 你跑真机
6. Merge 进 main + 删 feature branch
7. v0.3 PR-A → PR-B1 → PR-B2 → PR-B3 → PR-B4 → PR-C → **PR-D** 全部完成 → 打 git tag v0.3.0

---

## 不做（与 scope §6 同 + Option B 边界明示）

- ❌ audio mp3 接真 CDN（PR-E 候选）
- ❌ pronunciation wav 接 COS（PR-E 候选；audio 接 COS 时一并）
- ❌ 改 pronunciation.controller.ts 内部逻辑
- ❌ 改 audio-assets.controller.ts
- ❌ 改 content-manifest.controller.ts (PR-C 已稳定)
- ❌ mobile 任何代码改动 (β 已切 baseUrl)
- ❌ 给 audio_assets 加 version 字段 / migration (in-place UPDATE 即可)
- ❌ 真 CDN 多 region / multi-origin (PR-F 候选)
- ❌ 改 partial_publish.py 写入路径 (continue using local://cdn/... placeholder)
- ❌ 改 Dockerfile COPY cdn-mock / data/pronunciation (Option B 走 volume mount)
