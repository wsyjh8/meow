# PR-D plan v0.2 — Option A 详细实施（audio + pronunciation 全 COS；D2=a redirect）

- **Date**: 2026-05-07
- **Status**: plan v0.2 — 与 `pr-d-scope.md` v0.2 同步；D1=A 用户拍板；D2=a server-side 302 redirect；取代 v0.1（v0.1 主张 Option B）
- **基线 commit**: `ec095ea`（PR-C merged 进 main）
- **工作分支**: `feat/v0.3-pr-d-audio-asset-ingest-cos`
- **预算**: 我做 ~2-2.5d；用户 Phase 0 ~1-1.5 hr

---

## 0. v0.1 → v0.2 修订

| # | v0.1 | v0.2 |
|---|---|---|
| D1 主张 | Option B（server volume mount）| **Option A**（用户拍板，全 COS）|
| D2 决策 | 未提（B 不需要）| **a: server-side 302 redirect** |
| 估时 | 1d | 2-2.5d |
| 工具 | 1 个：repipe-audio-urls.ts | 3 个：sync-audio-mp3 + sync-pronunciation + repipe（共 ~400 行 ts）|
| pronunciation controller | 不动 | 重写：fs.readFile → 302 redirect |
| main.ts /cdn route | 保留 | 删除 |
| docker-compose volumes | 加 cdn-mock + data/pronunciation mounts | 不加（资产全 COS）|
| mobile 改动 | 0 | **0**（D2=a 关键好处：http follows redirect）|

---

## 起手前 recon（已完成）

```bash
# 1. partial_publish.py mp3 写入 layout (PR-D 沿用同 layout 上 COS)
grep -A 12 "def cdn_relative_path" apps/api/scripts/audio_pipeline/partial_publish.py
# → audio/v1/{kind}s/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3
# → shard = audio_id[:2] (2 hex chars)

# 2. pronunciation 路径 layout (PR-D 沿用同 layout 上 COS)
grep -A 5 "data/pronunciation\|firstLetter" apps/api/src/controllers/pronunciation.controller.ts
# → data/pronunciation/{locale}/{voice}/v1/{firstLetter}/{word}.wav

# 3. word regex (controller 校验保留)
grep "^[a-z]" apps/api/src/controllers/pronunciation.controller.ts
# → /^[a-z][a-z0-9''\-]{0,59}$/

# 4. ingest-audio-assets.ts cdnOrigin default
grep -n "cdnOrigin" apps/api/scripts/ingest-audio-assets.ts | head
# → line 90: cdnOrigin: get('--cdn-origin', 'http://10.0.2.2:3000/cdn')
# → line 158: row.url = cdnOrigin + row.url.substring('local://cdn'.length)

# 5. main.ts /cdn static route (PR-C 后)
grep -n "useStaticAssets\|cdn-mock" apps/api/src/main.ts
# → ~line 36-50: app.useStaticAssets(join(__dirname, '..', 'cdn-mock'), { prefix: '/cdn' })
# → PR-D 删除整段

# 6. 现有 .env.example
cat apps/api/.env.example
# → 已有 PORT / NODE_ENV / DATABASE_URL / PERSISTENCE_BACKEND
# → PR-D 加 AUDIO_CDN_ORIGIN + PRONUNCIATION_CDN_ORIGIN

# 7. PR-C 用的 COS 配置 (在 content_pipeline/.env)
cat apps/api/scripts/content_pipeline/.env.example
# → COS_REGION + COS_BUCKET + COS_SECRET_ID + COS_SECRET_KEY + COS_PUBLIC_URL_BASE
# → PR-D 复用同 bucket，仅 prefix 不同 (audio/v1/... 和 pronunciation/...)
```

**Recon 关键决定**:

- COS 同 bucket 复用（PR-C 已建 `meow-content-mvp-<appid>`）；只是 key prefix 不同：
  - manifest 包: `v1/<package>@<version>.<suffixes>` (PR-C 已用)
  - audio mp3: `audio/v1/{kind}s/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3`
  - pronunciation wav: `pronunciation/{locale}/{voice}/v1/{firstLetter}/{word}.wav`
- `AUDIO_CDN_ORIGIN` + `PRONUNCIATION_CDN_ORIGIN` 默认值都是 `${COS_PUBLIC_URL_BASE}` 的衍生，但允许独立配置以备未来分桶 / 接 CDN
- `apps/api/.env`（NestJS 用）跟 `apps/api/scripts/content_pipeline/.env`（pipeline 用）分开。PR-D 工具放 `apps/api/scripts/`，复用 `content_pipeline/.env`（COS_*）+ `apps/api/.env`（DATABASE_URL）；或新建 `apps/api/scripts/.env` 集中。**采用现有混用**（无碎片化）。

---

## Phase 0 — 用户操作（你做，~1-1.5 hr）

### 0.1 估算资产大小

```bash
cd /d/code/AI/startUp/meow/apps/api
du -sh cdn-mock/
du -sh data/pronunciation/
# 假设 cdn-mock 数 GB（mp3 量大），data/pronunciation 数 GB（wav 多）
# 上传 COS 流量 = 数据总量 × 2（双向; 公网上行 + 储存成本依然只算单边）
```

### 0.2 准备 .env（COS 配置已在 PR-C 时建好）

确保 `apps/api/scripts/content_pipeline/.env` 含：
```
COS_REGION=ap-shanghai
COS_BUCKET=<bucket>
COS_SECRET_ID=<key-id>
COS_SECRET_KEY=<key-secret>
COS_PUBLIC_URL_BASE=https://<bucket>.cos.<region>.myqcloud.com
```

新增 `apps/api/.env` 末尾两行（让 NestJS pronunciation controller 知道 redirect target）：
```
AUDIO_CDN_ORIGIN=https://<bucket>.cos.<region>.myqcloud.com
PRONUNCIATION_CDN_ORIGIN=https://<bucket>.cos.<region>.myqcloud.com
```

（实际可以省略 `AUDIO_CDN_ORIGIN`，server 端 NestJS 不需要这个变量；只有 ingest-audio-assets.ts 用到。）

### 0.3 一次性 sync audio mp3 到 COS

```bash
cd /d/code/AI/startUp/meow/apps/api

# Dry-run: 列举将上传文件数 + 总大小估算
npx ts-node scripts/sync-audio-mp3-to-cos.ts \
  --src cdn-mock \
  --prefix audio/v1 \
  --dry-run

# 实跑
npx ts-node scripts/sync-audio-mp3-to-cos.ts \
  --src cdn-mock \
  --prefix audio/v1 \
  --commit
# 输出: "uploaded N files, skipped M (same ETag)"; 进度条
# 网络 OK 时 ~ 1 min/100 MB；增量同步重复跑无害
```

### 0.4 一次性 sync pronunciation wav 到 COS

```bash
npx ts-node scripts/sync-pronunciation-to-cos.ts \
  --src data/pronunciation \
  --prefix pronunciation \
  --dry-run

npx ts-node scripts/sync-pronunciation-to-cos.ts \
  --src data/pronunciation \
  --prefix pronunciation \
  --commit
```

### 0.5 重写 PG `audio_assets.url`（一次性）

PR-C 时 PG 里的 url 仍是 `http://10.0.2.2:3000/cdn/...`. PR-D 重写到 COS：

```bash
# Dry-run
npx ts-node scripts/repipe-audio-urls.ts \
  --from 'http://10.0.2.2:3000/cdn' \
  --to   'https://<bucket>.cos.<region>.myqcloud.com' \
  --dry-run
# 输出: matched rows: N; sample 3 rows showing before/after; rolled back

# Commit
npx ts-node scripts/repipe-audio-urls.ts \
  --from 'http://10.0.2.2:3000/cdn' \
  --to   'https://<bucket>.cos.<region>.myqcloud.com' \
  --commit
# 输出: rewrote N rows
```

注：因 audio path layout 用了 `audio/v1/...` prefix，从 `http://10.0.2.2:3000/cdn/audio/v1/...` 重写到 `https://<bucket>.cos.<region>.myqcloud.com/audio/v1/...`，path 后段不变。

### 0.6 docker-compose 删 v0.1 试验过的 volumes（如有）

如 v0.1 曾试加 `cdn-mock` / `data/pronunciation` mount，PR-D 删除：

```yaml
services:
  api:
    image: meow-api:latest
    # volumes:                          # ← Option A 删
    #   - /var/lib/meow/cdn-mock:...    # ← 删
    #   - /var/lib/meow/data/...:...    # ← 删
```

### 0.7 部署新 NestJS image（含 PR-D 改动）

```bash
# Dev 机 build 新 image (Phase 1-3 代码 merged 后)
cd apps/api
docker build -t meow-api:latest .

# Push 到 server (rsync, scp, 或 docker registry)
# ...

# Server 上 force recreate
ssh user@server
docker compose up -d --force-recreate api
docker compose logs -f api  # 确认无 error
```

### 0.8 验证

```bash
# COS 直读 audio
curl -I '<COS_PUBLIC_URL_BASE>/audio/v1/examples/en-US/af_bella/v1/<shard>/<audio_id>.mp3'
# 期望: 200 OK; Content-Type: audio/mpeg

# COS 直读 pronunciation
curl -I '<COS_PUBLIC_URL_BASE>/pronunciation/en-US/am_michael/v1/a/abandon.wav'
# 期望: 200 OK; Content-Type: audio/wav (或 application/octet-stream，COS 默认)

# server pronunciation API → redirect
curl -I 'https://api.<your-domain>/api/v1/pronunciation/abandon?locale=en-US&voice=am_michael'
# 期望: 302 Found; Location: <COS_PUBLIC_URL_BASE>/pronunciation/en-US/am_michael/v1/a/abandon.wav

# server pronunciation API + follow redirect → COS wav
curl -L 'https://api.<your-domain>/api/v1/pronunciation/abandon?locale=en-US&voice=am_michael'
# 期望: 跳到 COS 后 200 + wav bytes

# manifest API audio asset URL
curl 'https://api.<your-domain>/api/v1/examples/<stable_id>/audio?voice=af_bella&format=mp3'
# 期望: JSON; url 字段含 .cos. host 而非 10.0.2.2
```

---

## Phase 1 — 3 个 ts 工具（我做，~1d）

### Step 1.1 `apps/api/scripts/sync-audio-mp3-to-cos.ts` (新)

```typescript
/**
 * PR-D Option A: One-shot tool to sync local audio mp3 files to Tencent COS.
 *
 * Reads a source dir (typically apps/api/cdn-mock/audio/v1/...) and uploads
 * each .mp3 file to COS at the same relative path under --prefix. Idempotent:
 * checks COS HEAD ETag and skips files whose checksum matches.
 *
 * Usage:
 *   npx ts-node scripts/sync-audio-mp3-to-cos.ts \
 *     --src cdn-mock \
 *     --prefix audio/v1 \
 *     [--dry-run | --commit]
 *
 * The --prefix is prepended to the path inside --src. So a file at
 * cdn-mock/audio/v1/examples/en-US/.../audio_id.mp3 with --src=cdn-mock
 * --prefix=audio/v1 ends up at COS key audio/v1/examples/en-US/.../audio_id.mp3
 * (i.e., the cdn-mock root collapses since cdn-mock already nests audio/v1).
 *
 * To customize, see Step 1.5 path-flatten logic.
 *
 * Picks up COS_* env vars from apps/api/scripts/content_pipeline/.env via
 * dotenv. Falls back to plain shell-export if .env missing.
 */

import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

import { S3Client, PutObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';

// ----- env loading (same pattern as ingest-audio-assets.ts) -----
const envCandidates = [
  path.resolve(__dirname, '..', 'scripts', 'content_pipeline', '.env'),
  path.resolve(__dirname, '..', '.env'),
];
for (const envPath of envCandidates) {
  if (fs.existsSync(envPath)) {
    const content = fs.readFileSync(envPath, 'utf-8');
    for (const line of content.split('\n')) {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const eq = trimmed.indexOf('=');
        if (eq > 0) {
          const key = trimmed.substring(0, eq);
          if (!process.env[key]) process.env[key] = trimmed.substring(eq + 1);
        }
      }
    }
  }
}

interface Args {
  src: string;
  prefix: string;
  commit: boolean;
}

function parseArgs(): Args {
  const argv = process.argv.slice(2);
  const get = (flag: string): string | null => {
    const i = argv.indexOf(flag);
    return i >= 0 && i + 1 < argv.length ? argv[i + 1] : null;
  };
  const has = (flag: string) => argv.includes(flag);

  const src = get('--src');
  const prefix = get('--prefix');
  if (!src || !prefix) {
    console.error('Usage: ts-node sync-audio-mp3-to-cos.ts --src <dir> --prefix <cos-prefix> [--commit | --dry-run]');
    process.exit(2);
  }
  return { src, prefix, commit: has('--commit') };
}

function md5sumFile(filePath: string): string {
  const hash = crypto.createHash('md5');
  hash.update(fs.readFileSync(filePath));
  return hash.digest('hex');
}

async function* walkMp3(dir: string, base = ''): AsyncGenerator<{ abs: string; rel: string }> {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const abs = path.join(dir, entry.name);
    const rel = path.posix.join(base, entry.name);
    if (entry.isDirectory()) {
      yield* walkMp3(abs, rel);
    } else if (entry.name.endsWith('.mp3')) {
      yield { abs, rel };
    }
  }
}

async function main() {
  const args = parseArgs();
  const region = process.env.COS_REGION || 'ap-shanghai';
  const bucket = process.env.COS_BUCKET;
  const secretId = process.env.COS_SECRET_ID;
  const secretKey = process.env.COS_SECRET_KEY;
  if (!bucket || !secretId || !secretKey) {
    console.error('ERROR: COS_BUCKET / COS_SECRET_ID / COS_SECRET_KEY missing');
    process.exit(2);
  }

  if (!fs.existsSync(args.src)) {
    console.error(`ERROR: src dir not found: ${args.src}`);
    process.exit(2);
  }

  const client = new S3Client({
    region,
    endpoint: `https://cos.${region}.myqcloud.com`,
    credentials: { accessKeyId: secretId, secretAccessKey: secretKey },
  });

  console.log(`mode: ${args.commit ? 'COMMIT' : 'DRY-RUN'}`);
  console.log(`src:  ${args.src}`);
  console.log(`bucket: ${bucket}`);

  let total = 0;
  let uploaded = 0;
  let skipped = 0;
  let totalBytes = 0;

  for await (const { abs, rel } of walkMp3(args.src)) {
    total++;
    const key = path.posix.join(args.prefix, rel);

    // Idempotent: HEAD check ETag (md5 for single-PUT < 5GB)
    let needUpload = true;
    try {
      const head = await client.send(new HeadObjectCommand({ Bucket: bucket, Key: key }));
      const remoteEtag = (head.ETag || '').replace(/"/g, '');
      const localMd5 = md5sumFile(abs);
      if (remoteEtag === localMd5) {
        needUpload = false;
        skipped++;
      }
    } catch (err: any) {
      if (err?.$metadata?.httpStatusCode !== 404 && err?.name !== 'NotFound') throw err;
    }

    const size = fs.statSync(abs).size;
    totalBytes += size;

    if (!needUpload) continue;

    if (!args.commit) {
      console.log(`  [dry] would upload ${rel} (${size.toLocaleString()} bytes)`);
      uploaded++;
      continue;
    }

    await client.send(new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: fs.readFileSync(abs),
      ContentType: 'audio/mpeg',
      CacheControl: 'public, max-age=31536000, immutable',
      ACL: 'public-read',
    }));
    uploaded++;
    if (uploaded % 50 === 0) console.log(`  uploaded ${uploaded}/${total}`);
  }

  console.log(`\ndone. total=${total} uploaded=${uploaded} skipped=${skipped} totalBytes=${totalBytes.toLocaleString()}`);
}

main().catch((err) => { console.error('ERROR:', err); process.exit(1); });
```

### Step 1.2 `apps/api/scripts/sync-pronunciation-to-cos.ts` (新)

同上 logic，walk `.wav` 文件 + ContentType = `audio/wav`：

```typescript
// 同 sync-audio-mp3-to-cos.ts 但:
//   - walkMp3 → walkWav (filter .wav extension)
//   - ContentType: 'audio/wav'
//   - CacheControl: 'public, max-age=86400' (PR-A 原 controller header)
//   - 其它逻辑相同
```

为避免重复代码，把 walk + upload 抽成 shared `cos-sync-helper.ts`，两个 sync 工具调用 helper：

```typescript
// apps/api/scripts/cos-sync-helper.ts (新)
export async function syncDirectoryToCos(opts: {
  src: string;
  prefix: string;
  fileExt: string;
  contentType: string;
  cacheControl: string;
  commit: boolean;
}): Promise<{ total: number; uploaded: number; skipped: number; totalBytes: number }>;
```

两个 sync 工具就是几行：parseArgs + 调 helper + console.log 结果。代码 +200 行 helper +50 行 audio +50 行 pron。

### Step 1.3 `apps/api/scripts/repipe-audio-urls.ts` (新；同 v0.1 设计，沿用)

```typescript
// 同 v0.1 plan §1.2 完整代码 (~120 行)
// 关键: dry-run 默认; --commit 显式才写; 事务 BEGIN/UPDATE/COMMIT
//      WHERE url LIKE $1 (前缀匹配); 幂等 (二次跑 0 行匹配)
//      sample 3 rows before/after 显示
```

### Step 1.4 dependency: `@aws-sdk/client-s3`

`apps/api/package.json` 加：

```diff
   "dependencies": {
     ...
+    "@aws-sdk/client-s3": "^3.x.x",
     ...
   }
```

或用 `aws-sdk` v2（更老但更小）；推荐 v3 模块化。

注：PR-C 已用 `boto3` (Python) 给 manifest 上传。这里是 TypeScript 部分，需要 JS 版 S3 SDK。`@aws-sdk/client-s3` 是官方 v3。

```bash
cd apps/api
npm install @aws-sdk/client-s3
```

### Step 1.5 path layout 确认

`--src cdn-mock --prefix audio/v1` 时：
- 文件 `cdn-mock/audio/v1/examples/en-US/af_bella/v1/ab/abc123.mp3`
- walk yields `rel = 'audio/v1/examples/en-US/af_bella/v1/ab/abc123.mp3'`
- COS key = `audio/v1` + `/` + `audio/v1/examples/.../abc123.mp3` = **冲突**（双 audio/v1）

修：sync 工具加 `--strip-prefix` 或类似选项。或者更简单，src 直接指 `cdn-mock/audio/v1`，prefix `audio/v1`。

最 KISS：**约定 src 与 COS prefix 关系**：
- audio: `--src cdn-mock/audio/v1 --prefix audio/v1`（两边对应）
- pronunciation: `--src data/pronunciation --prefix pronunciation`（两边对应）

walk 时 rel 从 src 起算（不含 src 路径），COS key = prefix + rel：
- `cdn-mock/audio/v1/examples/.../abc.mp3` → rel = `examples/.../abc.mp3` → key = `audio/v1/examples/.../abc.mp3` ✓

更新示例命令（已在 §0.3 / §0.4）：
```bash
npx ts-node scripts/sync-audio-mp3-to-cos.ts --src cdn-mock/audio/v1 --prefix audio/v1
npx ts-node scripts/sync-pronunciation-to-cos.ts --src data/pronunciation --prefix pronunciation
```

代码里 walk 从 src 起算 rel（不含 src 路径前缀）。

---

## Phase 2 — pronunciation controller redirect + main.ts 删 /cdn（我做，~0.5d）

### Step 2.1 `apps/api/src/controllers/pronunciation.controller.ts` 重写

```diff
 import {
   Controller,
   Get,
-  Header,
   NotFoundException,
   BadRequestException,
   Param,
   Query,
-  StreamableFile,
+  Res,
 } from '@nestjs/common';
-import * as fs from 'fs';
-import * as path from 'path';
+import type { Response } from 'express';

 /**
- * Pronunciation controller — stream WAV audio for a given word.
+ * Pronunciation controller — 302 redirect to COS public-read URL.
  *
  * GET /api/v1/pronunciation/:word?locale=en-US&voice=am_michael
  *
- * Audio files live at:
- *   data/pronunciation/{locale}/{voice}/v1/{firstLetter}/{word}.wav
+ * PR-D: WAV files are now served from Tencent COS at:
+ *   {PRONUNCIATION_CDN_ORIGIN}/pronunciation/{locale}/{voice}/v1/{firstLetter}/{word}.wav
+ *
+ * Server returns 302 redirect; client (mobile http package) follows
+ * automatically. fail-fast 400 on invalid word/locale/voice format is
+ * preserved; 404 (file missing on COS) surfaces from COS GET, not server
+ * stat.
  */
 @Controller('pronunciation')
 export class PronunciationController {
-  // In ts-node dev:   __dirname = src/controllers/  → up 2 → project root
-  // In compiled dist: __dirname = dist/controllers/ → up 2 → project root
-  private readonly dataDir = path.resolve(
-    __dirname,
-    '..',
-    '..',
-    'data',
-    'pronunciation',
-  );

   @Get(':word')
-  @Header('Cache-Control', 'public, max-age=86400')
   getAudio(
     @Param('word') word: string,
     @Query('locale') locale = 'en-US',
     @Query('voice') voice = 'am_michael',
-  ): StreamableFile {
+    @Res() res: Response,
+  ): void {
     const normalized = word.toLowerCase().trim();

-    // Sanitize: only allow characters that appear in English words.
-    // Prevents path traversal (no slashes, dots, etc.).
+    // Sanitize: only allow characters that appear in English words (preserved
+    // from PR-A; protects against path traversal in COS key).
     if (!/^[a-z][a-z0-9''\-]{0,59}$/.test(normalized)) {
       throw new BadRequestException('Invalid word');
     }

-    const audioPath = path.join(
-      this.dataDir,
-      locale,
-      voice,
-      'v1',
-      normalized[0],
-      `${normalized}.wav`,
-    );
-
-    if (!fs.existsSync(audioPath)) {
-      throw new NotFoundException({
-        error: 'Pronunciation not found',
-        word: normalized,
-      });
-    }
+    // Validate locale / voice (defensive; client-supplied values shouldn't
+    // contain path traversal chars).
+    if (!/^[a-zA-Z\-]{1,16}$/.test(locale)) {
+      throw new BadRequestException('Invalid locale');
+    }
+    if (!/^[a-z_]{1,32}$/.test(voice)) {
+      throw new BadRequestException('Invalid voice');
+    }

-    // Include Content-Length so Android's MediaPlayer can properly size its buffer.
-    // Without it, the chunked transfer response causes MEDIA_ERROR_SYSTEM on Android.
-    const { size } = fs.statSync(audioPath);
-    return new StreamableFile(fs.createReadStream(audioPath), {
-      type: 'audio/wav',
-      length: size,
-    });
+    const cdnOrigin = process.env.PRONUNCIATION_CDN_ORIGIN;
+    if (!cdnOrigin) {
+      throw new NotFoundException({
+        error: 'PRONUNCIATION_CDN_ORIGIN not configured on server',
+        word: normalized,
+      });
+    }
+
+    const cosUrl = `${cdnOrigin}/pronunciation/${locale}/${voice}/v1/${normalized[0]}/${normalized}.wav`;
+    res.redirect(302, cosUrl);
   }
 }
```

注：保留 `NotFoundException` import 用于 PRONUNCIATION_CDN_ORIGIN 缺失时返 500（架构错误）；word 格式非法仍是 `BadRequestException`。

### Step 2.2 `apps/api/src/main.ts` 删 /cdn static route

```diff
   // Global prefix for API versioning (does NOT affect static assets below)
   app.setGlobalPrefix('api/v1');

-  // PR-C: PR-B3 Day 1 staging serve route + isProdEnv guard removed.
-  // pipeline.py uploads packages to Tencent COS and writes the public https
-  // URL to content_manifest.file_url, so the dev-mode file:// → http://host/
-  // cdn/staging fallback is no longer needed. /cdn cdn-mock route below
-  // remains for legacy mp3 audio assets (留 PR-D 接 COS).
-
-  // Mock CDN — serve published audio assets from apps/api/cdn-mock/ at /cdn/*
-  // ... (PR-D: 删除 cdn static route 整段)
-  // PR-D candidate: replace this static route with COS public-read URLs in
-  // audio_assets.url ...
-  app.useStaticAssets(join(__dirname, '..', 'cdn-mock'), {
-    prefix: '/cdn',
-    setHeaders: (res) => {
-      // Long cache: audio_id is content-addressable + version-pathed, never overwritten in place
-      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
-    },
-  });
+  // PR-D: /cdn static route removed. audio_assets.url now points to Tencent
+  // COS public-read URLs (PR-D Option A); pronunciation.controller.ts returns
+  // 302 redirect to COS. cdn-mock dir kept in repo as .gitkeep placeholder
+  // (dev pipeline still writes there as intermediate; sync-audio-mp3-to-cos.ts
+  // pushes to COS after partial_publish).

   // Request logging
   app.use(loggingMiddleware);
```

如果 `import { join } from 'path'` 仅用于 cdn static route，删后 `join` 不再使用 → 同步删 import。

### Step 2.3 `apps/api/scripts/ingest-audio-assets.ts` cdnOrigin default 改 env

```diff
+// PR-D: cdnOrigin reads AUDIO_CDN_ORIGIN env (falls back to legacy hardcode
+// if env unset, preserving PR-A behavior for users who haven't migrated).
-cdnOrigin: get('--cdn-origin', 'http://10.0.2.2:3000/cdn'),
+cdnOrigin: get(
+  '--cdn-origin',
+  process.env.AUDIO_CDN_ORIGIN || 'http://10.0.2.2:3000/cdn',
+),
```

注：`AUDIO_CDN_ORIGIN` 是 COS public base（含或不含 `/cdn` 段取决于 layout）。PR-D 用 `https://<bucket>.cos.<region>.myqcloud.com`（不含 `/cdn`）+ ingest 拼 `audio/v1/...` 上去。

但 `audio_assets.jsonl` 里 url 字段是 `local://cdn/audio/v1/...`，rewrite 后变 `${cdnOrigin}/audio/v1/...`。如果 `cdnOrigin = https://<bucket>.cos.<region>.myqcloud.com` → 最终 url = `https://<bucket>.cos.<region>.myqcloud.com/audio/v1/...` ✓ 与 sync 上传 layout 一致。

---

## Phase 3 — README + e2e + .env.example（我做，~0.5d）

### Step 3.1 `apps/api/.env.example` 加变量

```diff
 # ========== Meow API Environment Variables ==========

 # Server
 PORT=3000
 NODE_ENV=development
 CORS_ORIGIN=*

 # PostgreSQL (needed from A2 onward)
 DATABASE_URL=postgresql://postgres:jason123@localhost:5432/meow_dev

 # Persistence backend: 'pg' (default) or 'json' (legacy fallback)
 PERSISTENCE_BACKEND=pg
+
+# PR-D Option A: pronunciation controller 302 redirect target.
+# Format: https://<bucket>.cos.<region>.myqcloud.com (no trailing slash)
+# Used by:
+#   - apps/api/src/controllers/pronunciation.controller.ts
+#   - apps/api/scripts/ingest-audio-assets.ts (cdnOrigin default; reads
+#     AUDIO_CDN_ORIGIN; same value as PRONUNCIATION_CDN_ORIGIN typically)
+# Leave commented to fall back to legacy 'http://10.0.2.2:3000/cdn' (PR-A
+# behavior, dev only).
+#PRONUNCIATION_CDN_ORIGIN=https://your-bucket.cos.ap-shanghai.myqcloud.com
+#AUDIO_CDN_ORIGIN=https://your-bucket.cos.ap-shanghai.myqcloud.com
```

### Step 3.2 e2e 加 1 case (pronunciation 302 redirect)

`apps/api/test/pg-regression.e2e-spec.ts` 加：

```typescript
describe('GET /api/v1/pronunciation/:word — PR-D 302 redirect', () => {
  it('returns 302 with Location pointing at PRONUNCIATION_CDN_ORIGIN', async () => {
    process.env.PRONUNCIATION_CDN_ORIGIN = 'https://test-bucket.cos.example.com';

    const res = await request(app.getHttpServer())
      .get('/api/v1/pronunciation/abandon')
      .expect(302);

    expect(res.headers.location).toBe(
      'https://test-bucket.cos.example.com/pronunciation/en-US/am_michael/v1/a/abandon.wav',
    );
  });

  it('returns 400 on invalid word format', async () => {
    process.env.PRONUNCIATION_CDN_ORIGIN = 'https://test-bucket.cos.example.com';

    await request(app.getHttpServer())
      .get('/api/v1/pronunciation/INVALID%20word')
      .expect(400);
  });

  it('returns 500 if PRONUNCIATION_CDN_ORIGIN missing', async () => {
    delete process.env.PRONUNCIATION_CDN_ORIGIN;

    await request(app.getHttpServer())
      .get('/api/v1/pronunciation/abandon')
      .expect(404);  // NestJS NotFoundException maps to 404 by default
  });
});
```

### Step 3.3 README PR-D 章节

`apps/api/scripts/content_pipeline/README.md` 加：

```markdown
## v0.3 PR-D (Option A: audio + pronunciation 全 COS;闭合 PR-C R4-2/R4-3)

PR-D 闭合 PR-C v0.3 §0.5.1 caveat 列出的 release 仍不能 3 条。**Option A 全 COS**:

- audio mp3 上 COS;`audio_assets.url` 重写指 COS public URL
- pronunciation wav 上 COS;controller 改 302 redirect → COS
- server `/cdn` static route 删除
- mobile **0 改动**(D2=a; PronunciationService follows redirect 自动透明)

### Phase 0 用户操作

1. 一次性同步 dev fs → COS(从 dev 机跑):

   \`\`\`bash
   cd apps/api

   # audio mp3
   npx ts-node scripts/sync-audio-mp3-to-cos.ts \\
     --src cdn-mock/audio/v1 --prefix audio/v1 --commit

   # pronunciation wav
   npx ts-node scripts/sync-pronunciation-to-cos.ts \\
     --src data/pronunciation --prefix pronunciation --commit
   \`\`\`

   两个工具:idempotent (HEAD ETag 检查 skip same content);进度条;dry-run 默认.

2. 重写 PG \`audio_assets.url\`:

   \`\`\`bash
   npx ts-node scripts/repipe-audio-urls.ts \\
     --from 'http://10.0.2.2:3000/cdn' \\
     --to   'https://<bucket>.cos.<region>.myqcloud.com' \\
     --commit
   \`\`\`

3. 部署新 server image (含 pronunciation 302 redirect + 删 /cdn route):

   \`\`\`bash
   ssh user@server 'cd /path/to/compose && docker compose up -d --force-recreate api'
   \`\`\`

### server-side env (PR-D)

\`apps/api/.env\` 加:

\`\`\`
AUDIO_CDN_ORIGIN=https://<bucket>.cos.<region>.myqcloud.com
PRONUNCIATION_CDN_ORIGIN=https://<bucket>.cos.<region>.myqcloud.com
\`\`\`

\`PRONUNCIATION_CDN_ORIGIN\` 是 NestJS pronunciation controller 的 redirect target.
\`AUDIO_CDN_ORIGIN\` 是 ingest-audio-assets.ts 的 cdnOrigin default (back-compat
fallback to legacy hardcode if unset).

### pronunciation API 形态变化 (D2=a)

PR-A:
\`\`\`
GET /api/v1/pronunciation/abandon → 200 + audio/wav stream
\`\`\`

PR-D:
\`\`\`
GET /api/v1/pronunciation/abandon → 302 Found
  Location: https://<bucket>.cos...../pronunciation/en-US/am_michael/v1/a/abandon.wav
client follow → COS 200 + audio/wav
\`\`\`

mobile \`http\` package 默认 follow 302 redirect;client 透明.
PronunciationService 0 改动.

### 后续 ingest 流程 (新 mp3 加入)

1. dev 机 partial_publish.py 跑 → cdn-mock/ 写 mp3 + audio_assets.jsonl 写 \`local://cdn/...\`
2. dev 机 sync-audio-mp3-to-cos.ts 跑 → 增量上传新 mp3 到 COS (HEAD ETag skip same content)
3. ingest-audio-assets.ts 跑 (server / dev) → \`cdnOrigin\` 从 \`AUDIO_CDN_ORIGIN\` env 读 → INSERT/UPDATE PG \`audio_assets.url\` 指 COS

\`partial_publish.py\` 不动, 仍写 \`local://cdn/...\` placeholder + cdn-mock dir
(供 dev 本地测试 + sync 工具的 src). 流程改进留 PR-E.
```

### Step 3.4 PR description (user dir)

`C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-D.md` 11 章 + Option A 决策 + sub-smoke F1-F4 现在应全 PASS 声明 + R4-2/R4-3 闭合声明.

---

## Phase 4 — sub-smoke A-F1-F4 真机（你做，~30 min）

承袭 PR-C sub-smoke 命令。变化：

| # | 场景 | 期望（PR-D 后）|
|---|---|---|
| A-E | 同 PR-C | 全 PASS（regression）|
| **F1** (β baseUrl) | release ApiClient 业务接口 | 200 + `https://api.<your-domain>/api/v1/...` |
| **F2** (PR-D 关键) | release ExampleAudioService metadata API | 200 + 返 `url` 字段 **含 `.cos.<region>.myqcloud.com`** 而**不**含 `10.0.2.2`（PR-C 时该 url 含 10.0.2.2，验证 R4-2 真存在；PR-D repipe 后 url 更新）|
| **F3** (PR-D 关键) | F2 metadata.url GET → mp3 字节 | **200** + audio/mpeg（PR-C 时 expected timeout 现在 PASS）|
| **F4** (PR-D 关键) | release PronunciationService → wav | 第一跳 302 + Location → 第二跳 COS 200 + audio/wav（PR-C 时 expected 404 现在 PASS）|

---

## 关键文件汇总

### 修改

| 文件 | 增 | 删 | 净 |
|---|---|---|---|
| `apps/api/scripts/ingest-audio-assets.ts` | ~5 | ~1 | +4 |
| `apps/api/src/controllers/pronunciation.controller.ts` | ~30 | ~30 | 0 |
| `apps/api/src/main.ts` | ~5 | ~15 | -10 |
| `apps/api/.env.example` | ~12 | 0 | +12 |
| `apps/api/scripts/content_pipeline/README.md` | ~80 | 0 | +80 |
| `apps/api/test/pg-regression.e2e-spec.ts` | ~50 | 0 | +50 |
| `apps/api/package.json` | 1 dep | 0 | +1 |

### 新建

| 文件 | 行数 |
|---|---|
| `apps/api/scripts/cos-sync-helper.ts` | ~150 |
| `apps/api/scripts/sync-audio-mp3-to-cos.ts` | ~50 (uses helper) |
| `apps/api/scripts/sync-pronunciation-to-cos.ts` | ~50 (uses helper) |
| `apps/api/scripts/repipe-audio-urls.ts` | ~120 |
| `docs/design/pr-d-scope.md` v0.2 | (本 commit) |
| `docs/design/pr-d-plan.md` v0.2 | (本 commit) |
| `C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-D.md` | user dir |

### 不动

- mobile 整个 (D2=a 关键 win)
- `apps/api/src/controllers/audio-assets.controller.ts` (pass-through 不变)
- `apps/api/src/controllers/content-manifest.controller.ts` (PR-C 已稳定)
- `apps/api/scripts/audio_pipeline/partial_publish.py` (写 local://cdn 不变)
- `apps/api/scripts/content_pipeline/pipeline.py` (manifest pipeline 不变)
- `apps/api/Dockerfile` (PR-C 加;Option A 不需 COPY 资产)
- `apps/api/cdn-mock/.gitkeep` (placeholder 保留)
- drift schema / pubspec / migrations / 任何 PG schema

---

## 验证

### TypeScript type check

```bash
cd apps/api && npx tsc --noEmit -p tsconfig.json
# expect clean
```

### sync 工具 dry-run smoke

```bash
# 在 dev 机配好 .env (含 COS_*) 后
cd apps/api
npx ts-node scripts/sync-audio-mp3-to-cos.ts \
  --src cdn-mock/audio/v1 --prefix audio/v1 --dry-run
# expect: walk N files; "would upload" 输出;不上传

npx ts-node scripts/sync-pronunciation-to-cos.ts \
  --src data/pronunciation --prefix pronunciation --dry-run
# 同上
```

### repipe-audio-urls.ts dry-run smoke

```bash
DATABASE_URL=postgresql://...@localhost:5432/meow_dev \
  npx ts-node scripts/repipe-audio-urls.ts \
  --from 'http://10.0.2.2:3000/cdn' \
  --to   'https://test.example.com' \
  --dry-run
# expect: matched rows N; sample 3 rows;rolled back
```

### e2e:pg

```bash
cd apps/api && npm run test:e2e:pg
# expect: ~50/51 cases pass + 1 baseline /me/today fail (PR-D 加 3 个 redirect cases)
```

### Phase 4 sub-smoke

详见 §"Phase 4"。

---

## 风险

| 风险 | 缓解 |
|---|---|
| sync 工具上传量大 (cdn-mock + data/pronunciation 几 GB) | dev 后台跑;增量同步 (HEAD ETag);中断重跑幂等 |
| `repipe-audio-urls.ts` 误改 PG | 默认 dry-run;commit 显式;事务 rollback safe;prefix LIKE 匹配 |
| pronunciation 302 redirect 客户端不 follow | http package 默认 follow;audioplayers UrlSource 走 system http stack 也 follow;Phase 4 真机 F4 必跑 |
| AudioCacheRepository 旧缓存命中失败 | 缓存按 audio_id (DB §7.4),不按 url;audio_id 不变 → 缓存继续命中 |
| pronunciation `Cache-Control` 行为变 | 从 server `max-age=86400` → COS object's `Cache-Control public, max-age=86400, immutable` (sync-pronunciation-to-cos.ts 设置);client 看到的 cache 行为基本不变 |
| word 校验 regex 在 PR-A 时容忍单引号 + 连字符 | controller 重写保留 regex;COS key 也接受这些字符 (URL 正常 encode);Phase 4 可加 case 验证 |
| `partial_publish.py` 之后 ingest 仍用老 cdnOrigin | `.env` `AUDIO_CDN_ORIGIN` 设置后 ingest 自动读;back-compat fallback 老 hardcode |
| @aws-sdk/client-s3 与 boto3 一致性 | COS S3 兼容;实测 PR-C 用 boto3 OK;PR-D 用 @aws-sdk v3 同样兼容 |
| 部署 server 时 `PRONUNCIATION_CDN_ORIGIN` 漏配 → controller 抛 NotFound | controller fail-fast;Phase 0 §0.8 验证步骤会撞;不会 silent failure |
| sub-smoke F2 url 断言 (含 .cos.) 在 multi-bucket 未来场景失效 | 当前单 bucket;F2 断言 specific to PR-D;PR-E multi-bucket 时再调整 |

---

## 提交策略

```
docs(v0.3-pr-d): scope v0.1 + plan v0.1 (Option B 推荐)
docs(v0.3-pr-d): scope v0.2 + plan v0.2 (D1=A 用户拍板, D2=a redirect)
feat(v0.3-pr-d): Phase 1 — cos-sync-helper + sync-audio-mp3-to-cos +
                 sync-pronunciation-to-cos + repipe-audio-urls
feat(v0.3-pr-d): Phase 2 — pronunciation 302 redirect + main.ts 删 /cdn
                 + ingest cdnOrigin env
feat(v0.3-pr-d): Phase 3 — README PR-D 章节 + .env.example + e2e 加 redirect cases
Merge feat/v0.3-pr-d-... → v0.3 PR-D Option A 全 COS (~2-2.5d)
```

---

## 评审节奏

1. 本次:scope v0.2 + plan v0.2 push
2. 评审吸收 → v0.3 (如有 P0/P1)
3. Phase 1-3 我做 (代码)
4. Phase 0 你跑 (sync + repipe + 部署)
5. Phase 4 sub-smoke 你跑真机
6. Merge 进 main + 删 feature branch
7. v0.3.0 git tag (PR-A → B1 → B2 → B3 → B4 → C → **D** 全部完成)

---

## 不做（与 scope §6 同 + Option A 边界明示）

- ❌ 接真 CDN 边缘节点 (PR-E)
- ❌ pronunciation_assets PG 表 (D2=c 已否决)
- ❌ multi-region / multi-bucket
- ❌ ETag / Range / hot-link protection / multi-codec
- ❌ partial_publish.py 直接上 COS (留 PR-E;当前 sync 工具够用)
- ❌ 改 audio-assets.controller.ts (pass-through 不变)
- ❌ 改 content-manifest.controller.ts (PR-C 稳定)
- ❌ 改 mobile 任何文件 (D2=a 关键)
- ❌ drift schema / pubspec / migrations / PG schema
