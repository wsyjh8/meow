# PR-C plan v0.1 — 腾讯云 COS 接入 + 合并 PR-B5（release default-on）

- **Date**: 2026-05-07
- **Status**: plan v0.1（与 `pr-c-scope.md` v0.1 同步初稿；待用户 review）
- **基线 commit**: `5392032`（PR-B4 merge 进 main）
- **工作分支**: `feat/v0.3-pr-c-cos-and-prb5`
- **预算**: 用户 30 min（Phase 0）+ 我 2 day（Phase 1-3）+ 真机 30 min（Phase 4）

---

## 起手前 recon（已完成）

```bash
# pipeline.py publish-manifest 现状
grep -n "file_url = f" apps/api/scripts/content_pipeline/pipeline.py
# → line 164: file_url = f"file:///{file_path.as_posix().lstrip('/')}"

# requirements.txt 现状
cat apps/api/scripts/content_pipeline/requirements.txt
# → psycopg2-binary>=2.9
# → PyYAML>=6.0

# server controller 现状（PR-B3 Day 1 实装）
grep -n "transformFileUrlForDev\|isProd && row.file_url" apps/api/src/controllers/content-manifest.controller.ts
# → transformFileUrlForDev helper (line 99-128) + 调用 (~line 240)
# → if (isProd && row.file_url.startsWith('file://')) skip (line 178-184)

# main.ts staging route
grep -n "useStaticAssets\|isProdEnv" apps/api/src/main.ts
# → if (!isProdEnv) { app.useStaticAssets('/cdn/staging' ...) } (line 30-39)
# → app.useStaticAssets('/cdn' for cdn-mock ...) (line 47-52)

# main.dart kDebugMode guard
grep -n "kDebugMode" apps/mobile/lib/main.dart
# → if (!kDebugMode) return;  (Layer 1, ~line 53)

# settings_page kDebugMode 包裹
grep -n "kDebugMode" apps/mobile/lib/features/settings/settings_page.dart
# → import (line 1)
# → if (kDebugMode) SwitchListTile (~line 235)

# 当前 docker-compose / Dockerfile in repo
find apps/api -name "Dockerfile*" -o -name "docker-compose*"
# → 0 results (用户 server Docker setup 在 repo 之外)
```

**关键发现**：
- pipeline.py `publish-manifest` 当前写 file:// (line 164)
- server controller `transformFileUrlForDev` 是 PR-B3 Day 1 加的；删除后 manifest API 直接 pass-through https URL
- `/cdn/staging` static route 是 PR-B3 Day 1 加的 dev-only fallback；PR-C 后无 file:// 包，可删
- repo 内**无** docker-compose / Dockerfile（用户 server Docker setup 在 repo 之外）→ Phase 0 模板需提供完整可 paste 文件

---

## Phase 0 — 用户操作（你做，~30 min）

### 0.1 域名 + DNS

1. 注册 `<your-domain>.<tld>`（namesilo / 腾讯云域名 / Cloudflare Registrar 都行）
2. DNS 加 A 记录：
   ```
   类型  主机记录  记录值       TTL
   A     api      <your IP>    600
   ```
3. 等 5-10 分钟 DNS propagate；`ping api.<your-domain>.<tld>` 应返你 server IP

### 0.2 docker-compose nginx + certbot 完整模板

> **说明**: 你 repo 内目前没有 `docker-compose.yml`，是你 server 部署独立 setup。下面是**完整可 paste**模板，假设你 NestJS 已经 build 出 image 名 `meow-api:latest`。如果你已有 docker-compose 且只缺 nginx HTTPS 部分，看 §0.3 仅给 diff。

**`docker-compose.yml`**（server 上的部署目录，不进 repo）:
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: meow_prod
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${PG_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: unless-stopped

  api:
    image: meow-api:latest
    environment:
      DATABASE_URL: postgresql://postgres:${PG_PASSWORD}@postgres:5432/meow_prod
      NODE_ENV: production
      PORT: 3000
    depends_on: [postgres]
    expose: ['3000']  # 仅内网，不暴露到 host
    restart: unless-stopped

  nginx:
    image: nginx:1.25
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certbot/www:/var/www/certbot:ro
      - ./certbot/conf:/etc/letsencrypt:ro
    depends_on: [api]
    restart: unless-stopped

  certbot:
    image: certbot/certbot:latest
    volumes:
      - ./certbot/www:/var/www/certbot
      - ./certbot/conf:/etc/letsencrypt
    # Auto-renew: certbot renew every 12h; on success nginx reloaded
    entrypoint: >-
      sh -c "trap exit TERM;
             while :; do
               certbot renew --webroot -w /var/www/certbot;
               sleep 12h & wait $${!};
             done"
    restart: unless-stopped

volumes:
  pgdata:
```

**`nginx.conf`**（同目录）:
```nginx
# PR-C HTTPS reverse proxy: api.<your-domain>.<tld> → NestJS api:3000
# Certbot ACME http-01 challenge served from /var/www/certbot/.well-known/

server {
    listen 80;
    server_name api.<your-domain>.<tld>;

    # ACME challenge for Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Force HTTPS for everything else
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name api.<your-domain>.<tld>;

    ssl_certificate /etc/letsencrypt/live/api.<your-domain>.<tld>/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.<your-domain>.<tld>/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Reverse proxy → NestJS
    location / {
        proxy_pass http://api:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

### 0.3 首次 issue HTTPS 证书（一次性 bootstrap）

certbot 第一次签证书需要 nginx 已经能 serve 80 端口（ACME http-01 challenge）。但 nginx.conf 引用了还不存在的证书路径 → nginx 起不来。bootstrap 步骤：

```bash
# 在 server 上, 部署目录:

# 1. 临时 nginx.conf 仅 80 (注释掉 443 server 块) 暂存为 nginx.conf.bootstrap
# 2. docker compose up -d postgres api  (api 起来, nginx 还没起)
# 3. 用临时 nginx.conf.bootstrap:
docker compose run --rm \
  -p 80:80 \
  -v ./certbot/www:/var/www/certbot \
  nginx:1.25 nginx -c /tmp/nginx.bootstrap.conf -g 'daemon off;' &
# 或更简单: 启动一个临时 nginx 服 80 + 跑 certbot

# 实际推荐: 用 certbot 官方推荐的 standalone 一次性方法:
docker run --rm \
  -p 80:80 \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot:latest certonly \
    --standalone \
    --email <your-email> \
    --agree-tos \
    --no-eff-email \
    -d api.<your-domain>.<tld>

# 4. 证书签好后
ls certbot/conf/live/api.<your-domain>.<tld>/
# → fullchain.pem privkey.pem chain.pem cert.pem

# 5. 启全套
docker compose up -d
# → nginx 应该能起 + serve 443
```

### 0.4 验证 HTTPS 反代

```bash
curl -v https://api.<your-domain>.<tld>/api/v1/content/manifest
# 期望: 200 OK + JSON (空 packages 列表，因为 file:// 行被 production skip)
# 如果 200 → HTTPS + nginx + NestJS 链路 OK
```

### 0.5 腾讯云 COS bucket

1. 控制台 → 对象存储 → 创建存储桶
   - 名称: `meow-content-mvp-<your-appid>`（appid 是 12 位数字）
   - 地域: **上海 (ap-shanghai)**
   - 访问权限: **公有读私有写** (public-read)
2. 子目录结构（pipeline.py 用）:
   ```
   v1/                         # version prefix; 未来 v2 可独立
     examples-zk@v1.jsonl.gz
     examples-cet4@v1.jsonl.gz
     ...
   ```
3. 防盗链 / 跨域 CORS（可选；mobile HTTP GET 不需要 origin 检查，但浏览器调试时需要）
   - PUT method allowed
   - GET method allowed from `*`
4. 创建 CAM 子账号（推荐，不用主账号 SecretId/Key）
   - 控制台 → 访问管理 → 用户 → 子用户 → 新建子用户
   - 权限: 仅本 bucket 的 read/write（`QcloudCOSDataReadOnly` + `QcloudCOSDataWriteOnly` 限定 resource）
   - 生成 SecretId / SecretKey → 妥善保存

### 0.6 把 SecretId/Key 放到开发机 `.env`

`apps/api/scripts/content_pipeline/.env`（**不要 commit**，`.gitignore` 已忽略）:
```bash
# Postgres (existing)
PGHOST=localhost
PGPORT=5432
PGDATABASE=meow_dev
PGUSER=postgres
PGPASSWORD=jason123

# COS (PR-C new)
COS_REGION=ap-shanghai
COS_BUCKET=meow-content-mvp-1234567890     # 替换成你 bucket 名
COS_SECRET_ID=AKIDxxxxxxxxxxxxxxxxxxxx     # 替换
COS_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxx # 替换
COS_PUBLIC_URL_BASE=https://meow-content-mvp-1234567890.cos.ap-shanghai.myqcloud.com
# 上面 base URL = "https://<bucket>.cos.<region>.myqcloud.com" 拼接
```

---

## Phase 1 — pipeline.py 接 COS（我做，~1 day）

### Step 1.1 加 boto3 依赖

文件：`apps/api/scripts/content_pipeline/requirements.txt`

```diff
 psycopg2-binary>=2.9
 PyYAML>=6.0
+# PR-C: COS 接入 (S3-compatible API; future swap to real S3/R2 不改代码)
+boto3>=1.34.0
```

`pip install -r requirements.txt` 后 `boto3` available。

### Step 1.2 pipeline.py 加 `_cos_client()` + `_upload_to_cos()` helpers

文件：`apps/api/scripts/content_pipeline/pipeline.py`

加在文件顶部（imports 之后，cmd_* 之前）：

```python
# PR-C: COS upload (boto3 with COS S3-compatible endpoint).
# Future swap to real AWS S3 / Cloudflare R2 just changes endpoint_url + region;
# all subsequent SDK calls (put_object / list_objects / etc.) are unchanged.

import os
from typing import Optional
import boto3
from botocore.config import Config as BotoConfig

_COS_CLIENT = None  # lazily-built singleton


def _cos_client():
    """Build a boto3 S3 client pointed at Tencent COS endpoint.

    Reads from environment:
      COS_REGION       e.g. 'ap-shanghai'
      COS_BUCKET       bucket name (returned for caller convenience)
      COS_SECRET_ID    Tencent CAM SecretId
      COS_SECRET_KEY   Tencent CAM SecretKey

    Returns:
      (client, bucket_name)
    """
    global _COS_CLIENT
    if _COS_CLIENT is not None:
        return _COS_CLIENT

    region = os.environ.get("COS_REGION", "ap-shanghai")
    bucket = os.environ.get("COS_BUCKET")
    secret_id = os.environ.get("COS_SECRET_ID")
    secret_key = os.environ.get("COS_SECRET_KEY")
    if not all([bucket, secret_id, secret_key]):
        raise ReleaseError(
            "COS_BUCKET / COS_SECRET_ID / COS_SECRET_KEY missing from env; "
            "see apps/api/scripts/content_pipeline/.env.example"
        )

    endpoint = f"https://cos.{region}.myqcloud.com"
    client = boto3.client(
        "s3",
        endpoint_url=endpoint,
        region_name=region,
        aws_access_key_id=secret_id,
        aws_secret_access_key=secret_key,
        config=BotoConfig(
            signature_version="s3v4",
            retries={"max_attempts": 3, "mode": "standard"},
        ),
    )
    _COS_CLIENT = (client, bucket)
    return _COS_CLIENT


def _upload_to_cos(local_path: Path, key: str) -> str:
    """Upload local file to COS at given key. Returns the public https URL.

    Sets Cache-Control to long-lived because packages are content-addressable
    via stable_id + content_version (the URL key contains content_version, so
    a content change → different key → cache miss naturally).

    Idempotent: if same key already exists with same ETag (sha1 in COS for
    single-PUT under 5GB), put_object is a no-op cost-wise but still 200s.
    """
    client, bucket = _cos_client()
    public_base = os.environ.get("COS_PUBLIC_URL_BASE")
    if not public_base:
        raise ReleaseError("COS_PUBLIC_URL_BASE missing from env")

    with open(local_path, "rb") as f:
        client.put_object(
            Bucket=bucket,
            Key=key,
            Body=f,
            ContentType="application/gzip",
            CacheControl="public, max-age=31536000, immutable",
            ACL="public-read",
        )
    return f"{public_base}/{key}"
```

### Step 1.3 改 `cmd_publish_manifest`：上传 + 写 https URL

文件：`apps/api/scripts/content_pipeline/pipeline.py`，`cmd_publish_manifest`（line 139 起）

```diff
 def cmd_publish_manifest(args: argparse.Namespace) -> int:
     """Register a built package into content_manifest + release.package_set.

     Constraints (v0.2 评审采纳):
       - release.status MUST equal 'draft' (R1.2/R2.1; validated 是冻结态)
       - package_name MUST match naming convention (R1.5)
       - Same manifest_id with different content → error (R1.7/R2.4)
       - Same manifest_id with same content → idempotent no-op
-      - file_url 固定 file:// scheme (R1.4/R2.5; --cdn-prefix 已删)
+      - PR-C: file_url is the public COS URL (https://...). Uploads to COS
+        with Cache-Control immutable; idempotent re-runs are no-op.
     """
     conn = _connect_or_die()
     if conn is None:
         return 2

     try:
         # Naming convention pre-check (cheap, fail fast)
         _validate_package_name(args.package_name, args.package_kind)

         # File metadata
         file_path = Path(args.file).resolve()
         if not file_path.exists():
             raise ReleaseError(f"file not found: {file_path}")
         sha = file_sha256(file_path)
         size = file_path.stat().st_size
-        # Use POSIX path with file:// scheme for cross-platform consistency
-        file_url = f"file:///{file_path.as_posix().lstrip('/')}"
         manifest_id = f"{args.package_name}@{args.content_version}"
+
+        # PR-C: upload to COS, then store the public https URL.
+        # Key includes manifest_id so different content_versions produce
+        # different URLs (cache-friendly).
+        cos_key = f"v1/{manifest_id}{file_path.suffix}"
+        if file_path.suffix == ".gz" and "".join(file_path.suffixes[-2:]) == ".jsonl.gz":
+            cos_key = f"v1/{manifest_id}.jsonl.gz"
+        print(f"  uploading to COS: key={cos_key} size={size:,}")
+        file_url = _upload_to_cos(file_path, cos_key)
+        print(f"    cos url = {file_url}")

         with conn:  # auto BEGIN; commit on success; rollback on exception
             with conn.cursor() as cur:
                 # 1. Verify release exists + status='draft'
                 # ...
```

注意 idempotence：
- 第二次 `publish-manifest` 同 manifest_id + 同 file → COS put_object 覆盖（同 ETag），现有逻辑 line 191 `if existing == (sha, size, file_url, args.release): return idempotent` 仍生效（file_url 现在是 https，但同 file → 同 url → 同 row → idempotent）

### Step 1.4 加 `.env.example`

文件：`apps/api/scripts/content_pipeline/.env.example`（新建）

```bash
# Postgres (PR-A)
PGHOST=localhost
PGPORT=5432
PGDATABASE=meow_dev
PGUSER=postgres
PGPASSWORD=replace_me

# COS (PR-C)
COS_REGION=ap-shanghai
COS_BUCKET=meow-content-mvp-1234567890
COS_SECRET_ID=AKIDxxxxxxxxxxxxxxxxxxxx
COS_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxx
# COS_PUBLIC_URL_BASE = "https://<COS_BUCKET>.cos.<COS_REGION>.myqcloud.com"
COS_PUBLIC_URL_BASE=https://meow-content-mvp-1234567890.cos.ap-shanghai.myqcloud.com
```

`.gitignore` 应已含 `.env`（验证一次）；不应含 `.env.example`（这个要进 repo）。

### Step 1.5 README PR-C 章节

文件：`apps/api/scripts/content_pipeline/README.md`，在 PR-B4 子节后加：

```markdown
## v0.3 PR-C (Tencent COS integration + PR-B5 release default-on)

PR-C swaps `pipeline.py`'s `file://` URLs for real Tencent COS public-read
URLs, unblocking release-build manifest sync.

### pipeline.py prerequisites

- Tencent COS bucket (ap-shanghai recommended), public-read ACL
- CAM subaccount with `QcloudCOSDataWrite` scoped to the bucket
- `pip install -r apps/api/scripts/content_pipeline/requirements.txt` (adds
  `boto3>=1.34.0`)
- `.env` populated per `.env.example`:
  ```
  COS_REGION COS_BUCKET COS_SECRET_ID COS_SECRET_KEY COS_PUBLIC_URL_BASE
  ```

### `publish-manifest` post-PR-C

`publish-manifest` now uploads the package to COS at key
`v1/<package_name>@<version>.jsonl.gz` then writes that URL to
`content_manifest.file_url`. Re-runs of the same manifest with the same
content overwrite the COS object (same ETag, no-op cost) and exit
idempotent. Different content under the same manifest_id is a hard error
per the PR-A naming-convention rules — bump `content_version` instead.

`Cache-Control: public, max-age=31536000, immutable` on the COS object
because the URL key is content-addressable (`@<version>` changes invalidate
naturally).

### Server cleanup

PR-B3 Day 1 added `/cdn/staging` static route + `transformFileUrlForDev`
helper for the dev-mode `file://` → `http://host/cdn/staging/` translation.
PR-C deletes both — `pipeline.py` always writes https URLs now, so the
`manifest` API can pass `file_url` straight through.

### PR-B5 (merged into PR-C)

PR-B3 Day 3's `runManifestSyncIfEnabled` Layer-1 guard `if (!kDebugMode)
return;` is removed in PR-C. With real CDN URLs now reaching production
clients, release builds also auto-sync. The settings page SwitchListTile's
`if (kDebugMode)` wrap is removed too — release users can opt out from the
debug section.
```

---

## Phase 2 — server cleanup（我做，~2 hr）

### Step 2.1 删 `transformFileUrlForDev` helper + 调用

文件：`apps/api/src/controllers/content-manifest.controller.ts`

```diff
@@ Helper section @@
-/**
- * PR-B3 Day 1 (D3) — Dev/local mode only. Transforms `file://...` URLs
- * into `http://...` URLs the Flutter client can fetch via HTTP GET.
- * ...
- */
-function transformFileUrlForDev(fileUrl: string, host: string): string {
-  if (!fileUrl.startsWith('file://')) return fileUrl;
-  if (fileUrl.includes('/audio-pipeline-staging/')) {
-    const fileName = fileUrl.split('/audio-pipeline-staging/').pop();
-    return `http://${host}/cdn/staging/${fileName}`;
-  }
-  if (fileUrl.includes('/cdn-mock/')) {
-    const rel = fileUrl.split('/cdn-mock/').pop();
-    return `http://${host}/cdn/${rel}`;
-  }
-  return fileUrl;
-}

@@ getManifest method @@
-import {
-  BadRequestException,
-  Controller,
-  Get,
-  InternalServerErrorException,
-  Query,
-  Req,
-} from '@nestjs/common';
-import type { Request } from 'express';
+import {
+  BadRequestException,
+  Controller,
+  Get,
+  Query,
+} from '@nestjs/common';

@@ getManifest signature + body @@
-  async getManifest(
-    @Query('since_release') sinceRelease?: string,
-    @Query('app_version') appVersion?: string,
-    @Req() req?: Request,
-  ): Promise<ManifestResponse> {
+  async getManifest(
+    @Query('since_release') sinceRelease?: string,
+    @Query('app_version') appVersion?: string,
+  ): Promise<ManifestResponse> {

@@ Inside the loop, file_url assignment @@
-      // PR-B3 Day 1: dev/local 模式 file:// → http:// transform。
-      // ...
-      const host = req?.get('host');
-      if (!host) {
-        throw new InternalServerErrorException('Host header missing');
-      }
-      const fileUrl = isProd
-        ? row.file_url
-        : transformFileUrlForDev(row.file_url, host);
+      // PR-C: pipeline.py now writes real https URLs (Tencent COS), so the
+      // manifest API just passes file_url through. The PR-B3 Day 1 dev-mode
+      // file:// → http:// transform helper has been removed.
+      const fileUrl = row.file_url;

@@ Production safety guard @@
-      // Production safety: don't leak file:// paths
-      if (isProd && row.file_url.startsWith('file://')) {
-        // eslint-disable-next-line no-console
-        console.error(...);
-        continue;
-      }
+      // Defensive: any leftover file:// row from pre-PR-C is a data bug;
+      // skip it in any environment (was production-only in PR-A/B3).
+      if (row.file_url.startsWith('file://')) {
+        // eslint-disable-next-line no-console
+        console.error(
+          `[content/manifest] file:// URL in DB after PR-C — should not happen: ${row.package_id}`,
+        );
+        continue;
+      }
```

注：`isProd` 变量本身仍保留（其它地方可能用到；不在本步骤删）。

### Step 2.2 删 `/cdn/staging` static route

文件：`apps/api/src/main.ts`

```diff
   // Global prefix for API versioning (does NOT affect static assets below)
   app.setGlobalPrefix('api/v1');

-  // PR-B3 Day 1 (D3) — staging serve route. Two key constraints:
-  // ... 完整注释块 ...
-  const isProdEnv = process.env.NODE_ENV === 'production';
-  if (!isProdEnv) {
-    app.useStaticAssets(join(__dirname, '..', 'audio-pipeline-staging'), {
-      prefix: '/cdn/staging',
-      setHeaders: (res) => {
-        res.setHeader('Cache-Control', 'no-cache');
-      },
-    });
-  }
-
   // Mock CDN — serve published audio assets ...
-  // NOTE: Registered AFTER /cdn/staging above — see PR-B3 Day 1 comment.
   app.useStaticAssets(join(__dirname, '..', 'cdn-mock'), {
     prefix: '/cdn',
     ...
```

`isProdEnv` const 和整个 `if (!isProdEnv)` block 删掉。`/cdn` cdn-mock route 保留（PR-A 既有）。

### Step 2.3 e2e 测试 trim + 加 https pass-through case

文件：`apps/api/test/pg-regression.e2e-spec.ts`

```diff
@@ describe blocks @@
-  describe('GET /api/v1/content/manifest — PR-B3 dev URL transform', () => {
-    // ... 全块删 (~80 行)
-  });
-
-  describe('GET /api/v1/content/manifest — PR-B3 production guard', () => {
-    // ... 全块删 (~70 行)
-  });
+
+  describe('GET /api/v1/content/manifest — PR-C https pass-through', () => {
+    const TEST_PREFIX = 'test-prc-';
+
+    async function cleanup() {
+      const pool = getPool();
+      await pool.query(
+        `DELETE FROM content_manifest WHERE release_id LIKE '${TEST_PREFIX}%'`,
+      );
+      await pool.query(
+        `DELETE FROM content_release WHERE release_id LIKE '${TEST_PREFIX}%'`,
+      );
+    }
+    beforeEach(cleanup);
+    afterEach(cleanup);
+
+    it('https URLs pass through unchanged', async () => {
+      // Seed an active release with a manifest carrying a real-shape COS URL.
+      const releaseId = `${TEST_PREFIX}active`;
+      const packageName = `${TEST_PREFIX}examples`;
+      const manifestId = `${packageName}@v1`;
+      const cosUrl =
+        'https://meow-content-mvp-1234567890.cos.ap-shanghai.myqcloud.com/v1/test-prc-examples@v1.jsonl.gz';
+
+      const pool = getPool();
+      await pool.query(
+        `INSERT INTO content_release (release_id, status, activated_at, revoked_at, package_set, generated_by)
+         VALUES ($1, 'active', $2, NULL, $3::jsonb, 'e2e-prc')`,
+        [releaseId, new Date(Date.now() - 3600 * 1000).toISOString(), JSON.stringify([manifestId])],
+      );
+      await pool.query(
+        `INSERT INTO content_manifest (id, package_name, package_kind, content_version,
+          file_url, checksum_sha256, size_bytes, min_app_version, is_active, release_id)
+         VALUES ($1, $2, 'examples', 'v1', $3, 'sha256:test-prc', 1024, '0.0.0', true, $4)`,
+        [manifestId, packageName, cosUrl, releaseId],
+      );
+
+      const res = await request(app.getHttpServer())
+        .get('/api/v1/content/manifest')
+        .expect(200);
+      const found = res.body.packages.find(
+        (p: { package_id: string }) => p.package_id === manifestId,
+      );
+      expect(found).toBeDefined();
+      expect(found.file_url).toBe(cosUrl);
+    });
+  });
```

期望: e2e 49 → 删 2 cases (~3 个 it) + 加 1 case ≈ 净 -2 cases，total ~47 cases，仍 1 baseline `/me/today` fail。

---

## Phase 3 — PR-B5 合并: 移 kDebugMode guard（我做，~2 hr）

### Step 3.1 main.dart 移 Layer 1 guard

文件：`apps/mobile/lib/main.dart`

```diff
-  // Layer 1: release/profile dead-code-eliminate
-  if (!kDebugMode) return;
-
-  try {
-    // Layer 2: feature flag
+  try {
+    // Layer 1 (was kDebugMode guard, removed in PR-C/PR-B5): now release/
+    // profile builds also auto-sync. Real CDN (Tencent COS) is in place
+    // and the manifest API returns non-empty packages in production.
+    //
+    // Layer 2: feature flag (manifestSyncEnabled, default true since PR-B4)
     final prefs = await SharedPreferences.getInstance();
     if (!LocalSettingsService(prefs).manifestSyncEnabled) return;
```

`flutter/foundation` 仍 import（debugPrint 还用），但 `kDebugMode` 直接引用没有了（保留 import 因为 `debugPrint` 同 package）。

### Step 3.2 settings_page.dart 移 SwitchListTile 包裹

文件：`apps/mobile/lib/features/settings/settings_page.dart`

```diff
-          // PR-B3 Day 3 v0.2: manifest sync debug switch (kDebugMode-only).
-          // ... 完整注释 ...
-          if (kDebugMode)
-            SwitchListTile(
-              dense: true,
-              ...
-              title: const Text('Manifest sync (PR-B3 dev)'),
-              subtitle: const Text('开/关后下次重启 App 生效。失败静默。'),
-              ...
-            ),
+          // PR-C/PR-B5: SwitchListTile is now visible in release/profile
+          // builds too (real CDN URLs landed; PR-B3 Day 3 kDebugMode guard
+          // has been removed from both this widget and main.dart's hook).
+          // Title rebranded from "(PR-B3 dev)" to user-facing copy.
+          SwitchListTile(
+            dense: true,
+            contentPadding: EdgeInsets.zero,
+            secondary: const Icon(Icons.cloud_sync_outlined),
+            title: const Text('内容自动更新'),
+            subtitle: const Text('开/关后下次重启 App 生效。失败静默。'),
+            value: _manifestSyncEnabled,
+            onChanged: _setManifestSyncFlag,
+          ),
```

`flutter/foundation` import 仍保留（其它地方可能用；如未用 flutter analyze 会提醒）。

> **设计抉择**: title 从 `'Manifest sync (PR-B3 dev)'` 改成 `'内容自动更新'` 因为 release 用户也看得到，dev 标记不合适。如果你想保留 dev 标记，告诉我换回。

### Step 3.3 测试 expect 调整

文件：`apps/mobile/test/main_manifest_sync_hook_test.dart`

测试运行在 debug build (`kDebugMode = true`)，移除 Layer 1 后 helper 行为不变（之前 kDebugMode=true 会进入 Layer 2，现在没 Layer 1 也是同样进 Layer 2）。**测试 expect 完全不需要改**。仅注释更新：

```diff
-  group('runManifestSyncIfEnabled (PR-B3 Day 3 + PR-B4)', () {
+  group('runManifestSyncIfEnabled (PR-B3 + PR-B4 + PR-C/PR-B5)', () {
     test(
         'flag=false (explicit, post-PR-B4): short-circuits before invoking service',
         () async {
       // PR-B4: default flipped from false to true. To exercise the
-      // short-circuit branch we must EXPLICITLY persist false now —
-      // setMockInitialValues({}) (the setUp default) would yield true
-      // and trip the syncIfNeeded path.
+      // short-circuit branch we must EXPLICITLY persist false (PR-B4
+      // default true; PR-C/PR-B5 also removed the kDebugMode Layer 1
+      // guard, but tests run as debug build so that has no observable
+      // effect here — see release sub-smoke A for that path).
```

---

## Phase 4 — README + sub-smoke + PR description（我做 + 你跑真机，~2 hr）

### Step 4.1 PR description

`C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-C.md`（user dir，不进 commit）

骨架（沿用 PR-A/B1/B2/B3 风格 11 章）:
1. Title + 一句话
2. Why / 用户可见效果
3. 范围 (Phase 0-3)
4. 关键文件清单
5. 测试 (e2e + mobile unit + sub-smoke)
6. 风险 & 缓解
7. 兼容性
8. 不做 (明示边界)
9. 评审历史 (v0.1 → v0.2 if any)
10. 测试结果
11. v0.4 SSOT 关系（PR-C 兑现 §7.1）

### Step 4.2 Sub-smoke A-E（你做，真机/模拟器，~30 min）

| # | 场景 | 期望 |
|---|---|---|
| **A** | release build (`flutter build apk --release && install`) → 启动 → adb logcat | "manifest sync result: ..." 出现（release 也跑 sync；PR-B5 验证）|
| **B** | release build settings 页 | 能看到 SwitchListTile (kDebugMode 包裹已移)；可关 |
| **C** | release build flag=false 重启 | adb logcat 无 sync log（用户 opt-out 仍生效）|
| **D** | dev build bundle v3 + manifest sync → 改 bundle v4 → 重启 | manifest 数据保留（D1 收口真机回归；PR-B3 Day 2 unit 已覆盖，sub-smoke 真机）|
| **E** | full E2E: dev API → COS https URL → DownloadManager → drift readback | curl https://<bucket>.cos... 返 .gz；adb logcat 见 download 200；drift content_package_state 写入 |

A 是 critical safeguard：验证 PR-C/PR-B5 真让 release 受益（vs PR-B4 dev-only）。

---

## 关键文件汇总

### 修改

| 文件 | 增 | 删 | 净 |
|---|---|---|---|
| `apps/api/scripts/content_pipeline/requirements.txt` | 2 | 0 | +2 |
| `apps/api/scripts/content_pipeline/pipeline.py` | ~80 | ~5 | +75 |
| `apps/api/scripts/content_pipeline/.env.example` (新) | ~15 | 0 | +15 |
| `apps/api/scripts/content_pipeline/README.md` | ~50 | 0 | +50 |
| `apps/api/src/main.ts` | 0 | ~25 | -25 |
| `apps/api/src/controllers/content-manifest.controller.ts` | ~5 | ~50 | -45 |
| `apps/api/test/pg-regression.e2e-spec.ts` | ~50 | ~150 | -100 |
| `apps/mobile/lib/main.dart` | ~3 | ~3 | 0 |
| `apps/mobile/lib/features/settings/settings_page.dart` | ~5 | ~10 | -5 |
| `apps/mobile/test/main_manifest_sync_hook_test.dart` | ~5 | ~5 | 0 |

**预估 diff**: 约 +210 / -250，net -40 行。

### 新建
- `apps/api/scripts/content_pipeline/.env.example`
- `docs/design/pr-c-scope.md`（本 PR docs）
- `docs/design/pr-c-plan.md`（本 PR docs）
- `C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-C.md`（user dir）

### 不动
- `apps/mobile/lib/core/manifest/`
- `apps/mobile/lib/core/memory/wordbook_loader.dart`
- `apps/mobile/lib/core/storage/local_settings_service.dart`
- `apps/mobile/lib/core/storage/drift/`
- `apps/mobile/pubspec.yaml`（pubspec 不动；仅 mobile lib + test 微调）
- `apps/api/src/infrastructure/`
- `apps/api/scripts/content_pipeline/build_examples_package.py` / `gc_stale.py` / `orphan_scan.py` / `content_release_repo.py`

---

## 验证

### flutter analyze 0 new issues

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-c\apps\mobile
flutter analyze lib/main.dart `
                lib/features/settings/settings_page.dart `
                test/main_manifest_sync_hook_test.dart
```

### flutter test 1202/1202

```powershell
flutter test
```

### server e2e

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-c\apps\api
$env:PGPASSWORD = "<your-local-password>"
npm install boto3 # 不需要 (boto3 是 Python)
npm run test:e2e:pg
# 期望: ~47 cases pass + 1 baseline /me/today fail
```

### pipeline.py manual smoke

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-c\apps\api
# 已配 .env (含 COS_*)
pip install -r scripts\content_pipeline\requirements.txt

python scripts\content_pipeline\pipeline.py create-release pr-c-smoke --title "PR-C smoke"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release pr-c-smoke `
  --package-name test-prc-examples --package-kind examples `
  --content-version v1 `
  --file audio-pipeline-staging\some-package.jsonl.gz
# 期望: stdout 含 "uploading to COS: key=v1/..." + "cos url = https://..."
# COS 控制台能看到该 object

python scripts\content_pipeline\pipeline.py validate pr-c-smoke
python scripts\content_pipeline\pipeline.py activate pr-c-smoke

curl https://api.<your-domain>/api/v1/content/manifest
# 期望: file_url = "https://meow-content-mvp-...cos.ap-shanghai.myqcloud.com/v1/test-prc-examples@v1.jsonl.gz"

# Cleanup
python scripts\content_pipeline\pipeline.py revoke pr-c-smoke --reason "smoke done"
```

### Sub-smoke A-E（真机；详细 §"Phase 4 Step 4.2"）

---

## 风险

| 风险 | 缓解 |
|---|---|
| Phase 0 域名 + nginx HTTPS bootstrap 卡住 | plan §"Phase 0 模板" 完整 docker-compose + nginx.conf + certbot bootstrap 命令 |
| boto3 PUT 大包慢 | 当前包 < 1MB，PUT 即时；未来若包变大可加 multipart upload（boto3 builtin）|
| COS bucket 误开 public-write | Phase 0 §0.5 只设 public-read；CAM 子账号 write 权限仅本 bucket |
| 现有 PR-B3 测试 e2e cases 删除后 regression 漏 | Phase 2 Step 2.3 加 1 https pass-through case 验证新行为；删的 cases 是 dev-only 路径，PR-C 后无需 |
| PR-B5 移 kDebugMode 后 release 用户首次启动多 1 manifest API call | sync fire-and-forget；不阻塞 UI；hasFailure 静默 |
| 旧 dev 用户曾 opt-out 的 prefs 残留 | 不影响（用户主动 opt-out 仍生效）|
| 真机 sub-smoke A 跑失败 → release dead-code-eliminate 没破除 | 阻塞 PR-C 合 main；回退方案：保留 kDebugMode guard，只做 PR-C COS 部分（半 PR）|
| COS 包文件被恶意 GET 浪费流量 | 流量计费 ¥0.5/GB；早期可接受；用户量起加 CDN 反代 / 防盗链 hotlink protection |
| `.env` SecretId 误 commit | `.gitignore` 已忽略 `.env`；plan 强调 `.env.example` 占位 |

---

## 验收清单（详见 scope §7）

- [ ] Phase 0 完成（域名 + HTTPS + COS bucket public-read）
- [ ] `pipeline.py publish-manifest` 上传到 COS + 写 https URL（manual smoke）
- [ ] PG `content_manifest.file_url` 是 https
- [ ] manifest API 返非空 packages，含 https URL
- [ ] mobile DownloadManager 能 HTTP GET COS URL
- [ ] release build 启动也跑 sync（sub-smoke A）
- [ ] release build settings 能看到开关（sub-smoke B）
- [ ] release build 用户能 opt-out（sub-smoke C）
- [ ] flutter analyze 0 new issues
- [ ] flutter test 1202/1202 全过
- [ ] e2e suite ~47 cases 通过 + 1 baseline `/me/today` fail
- [ ] sub-smoke A-E 真机全过
- [ ] README PR-C 章节
- [ ] PR_DESCRIPTION_PR-C.md 写到 user dir

---

## 提交策略

按 scope §6，单 PR `feat/v0.3-pr-c-cos-and-prb5` → main。commit 拆分（评审决定细粒度）:

**Option 1: 4 commit**
```
docs: scope v0.1 + plan v0.1 (本 commit)
feat: Phase 1 — pipeline.py COS upload + boto3
feat: Phase 2 — server cleanup (transform helper / staging route / e2e trim)
feat: Phase 3 — PR-B5 merge (移 kDebugMode guard + release default-on)
test: README + PR description
Merge feat/v0.3-pr-c-cos-and-prb5 — v0.3 PR-C COS + PR-B5 (~2d)
```

**Option 2: 单 commit**
```
feat(v0.3-pr-c): COS 接入 + 合并 PR-B5 (release default-on)
Merge feat/v0.3-pr-c-cos-and-prb5 — v0.3 PR-C COS + PR-B5 (~2d)
```

我倾向 **Option 1** — 与 PR-B3 / PR-B4 风格一致，每个 phase 独立 commit 便于 git bisect / revert。

---

## 评审节奏

1. 本次：scope + plan v0.1 push 让 codex / 用户 review
2. 评审吸收 → v0.2（如果有 P0/P1 改动）
3. Phase 0 你跑（域名 + nginx + COS）
4. Phase 1-3 我做（pipeline + server + PR-B5）
5. Phase 4 sub-smoke 你跑真机
6. Merge 进 main + 删 feature branch
7. v0.3 milestone 全部完成 → 打 git tag v0.3.0 + Release notes

---

## 不做（与 scope §0.2 同）

- ❌ 真 Cloudflare/AWS CDN 接入（boto3 已铺路 future swap）
- ❌ presigned URL（v0.3 走 public-read）
- ❌ ETag / Range / multi-codec / hot-link protection（流量起再做）
- ❌ Tombstone / status='deleted' 路径（D5；v0.4 §7.3 候选）
- ❌ 改 ContentPackageService / PackageInstaller / DownloadManager / WordbookLoader
- ❌ 改 drift schema / pubspec
- ❌ 多 region / multi-bucket（单 ap-shanghai 够 v0.3）
