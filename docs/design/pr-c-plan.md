# PR-C plan v0.2 — 腾讯云 COS 接入 + S1=β mobile 4 service 全栈环境化 + 合并 PR-B5

- **Date**: 2026-05-07
- **Status**: plan v0.2（与 `pr-c-scope.md` v0.2 同步）— 吸收三份评审 24 处修订（R1 13 + R2 7 + R3 4）+ S1=β（用户最终拍板，R3 评审 P0 反对 α 后定稿）+ R2#7 acme-companion 优先 + host cron fallback + R3 P1/P2（DATABASE_URL / orphan-scan packages / validate https-only）；取代 v0.1
- **基线 commit**: `5392032`（PR-B4 merge 进 main）
- **工作分支**: `feat/v0.3-pr-c-cos-and-prb5`
- **预算**: 用户 45 min（Phase 0）+ 我 3 day（Phase 1-3）+ 真机 30 min（Phase 4）

> **PR-C 边界声明（β 后无需 caveat 软化，scope §0.4.1）**
>
> PR-C 兑现的是「release app 全链路可用」：
> - ✅ 启动 → 自动从腾讯云 COS 拉 manifest → 导入 drift（`ManifestClient`）
> - ✅ 点播放例句音频走真域名（`ExampleAudioService`）
> - ✅ 取题目 / 业务接口走真域名（`ApiClient`）
> - ✅ 听单词发音走真域名（`PronunciationService`）
>
> β 一刀切：4 个 service 全切 `apiV1Base`；release 用户体验与 dev/emulator 一致；不留半生产态。
>
> **PR-D 不再需要做 mobile baseUrl 重构**（β 已合并）。

---

## 起手前 recon（v0.2 行号刷新）

```bash
# pipeline.py publish-manifest 现状
grep -n "file_url = f" apps/api/scripts/content_pipeline/pipeline.py
# → line 164: file_url = f"file:///{file_path.as_posix().lstrip('/')}"

# pipeline.py cmd_validate Step 5 file:// 强制校验（v0.2 新核实）
grep -n "file_url scheme must be file://" apps/api/scripts/content_pipeline/pipeline.py
# → line 313-319: raise ReleaseError if not url.startswith("file://")

# orphan_scan.py argparse --scope default（v0.2 新核实）
grep -n "default=\"all\"" apps/api/scripts/content_pipeline/orphan_scan.py
# → line ~948: parser.add_argument("--scope", default="all", choices=["audio", "packages", "all"])
#   (R3 P1: actual choices contain "packages", NOT "staging" — v0.1 plan 写错)

# requirements.txt 现状
cat apps/api/scripts/content_pipeline/requirements.txt
# → psycopg2-binary>=2.9
# → PyYAML>=6.0
# → (v0.2 加 boto3 + python-dotenv)

# server controller 现状（v0.2 行号刷新 R1#10）
grep -n "transformFileUrlForDev\|isProd && row.file_url" apps/api/src/controllers/content-manifest.controller.ts
# → transformFileUrlForDev helper 起点 line 119（v0.1 写 99 错）
# → if (isProd && row.file_url.startsWith('file://')) skip line 220（v0.1 写 178-184 错）

# main.ts staging route
grep -n "useStaticAssets\|isProdEnv" apps/api/src/main.ts
# → const isProdEnv line ~30
# → if (!isProdEnv) { app.useStaticAssets('/cdn/staging' ...) } line 30-39
# → app.useStaticAssets('/cdn' for cdn-mock ...) line 44-47

# main.dart kDebugMode guard（v0.2 行号刷新 R1#10）
grep -n "kDebugMode" apps/mobile/lib/main.dart
# → if (!kDebugMode) return;  line 63（v0.1 写 ~53 偏）

# settings_page kDebugMode 包裹（v0.2 行号刷新 R1#10）
grep -n "kDebugMode\|flutter/foundation" apps/mobile/lib/features/settings/settings_page.dart
# → import 'package:flutter/foundation.dart'; line ~1
# → if (kDebugMode) SwitchListTile (line 263-264；v0.1 写 ~235 偏)

# S1=β recon: mobile 4 处 hardcode 全切（PR-C 都改）
grep -n "baseUrl" apps/mobile/lib/core/manifest/manifest_client.dart
# → line 114: this.baseUrl = 'http://10.0.2.2:3000/api/v1'  (named param 已支持; PR-C 改 default → apiV1Base)

grep -rn "10\.0\.2\.2:3000" apps/mobile/lib/core/api/ apps/mobile/lib/core/audio/
# → core/api/api_client.dart:15             final String baseUrl = 'http://10.0.2.2:3000/api/v1'  (named param 已支持; PR-C 改 default → apiV1Base)
# → core/audio/example_audio_service.dart:35 static const String _baseUrl = 'http://10.0.2.2:3000/api/v1'  (无 named param; PR-C 改: static const → final + 加 {String? baseUrl} named optional)
# → core/audio/pronunciation_service.dart:21 static const String _baseUrl = 'http://10.0.2.2:3000/api/v1'  (无 named param; PR-C 改: 同上)

# Dockerfile / docker-compose 仓内现状（v0.1 已 recon）
find apps/api -name "Dockerfile*" -o -name "docker-compose*"
# → 0 results（v0.2 Phase 0 §0.0 加 Dockerfile）

# config/ 目录（v0.2 新核实）
ls apps/mobile/lib/core/config/ 2>/dev/null
# → 不存在（v0.2 新建）

# Flutter SDK 版本支持 String.fromEnvironment
# → pubspec.yaml flutter sdk constraint >=3.0.0；Dart 3.0+ 原生支持

# e2e 实际 it() 计数（v0.2 R1#9）
grep -c "^\s*it(" apps/api/test/pg-regression.e2e-spec.ts
# → 50 cases（v0.1 plan 估"~49"偏 1）
```

**v0.2 关键 recon 发现（v0.1 漏 / 错的）**：

1. `cmd_validate` line 313-319 硬性 file:// → PR-C 写 https URL 后 100% fail（**P0 必修**，R1#1）
2. mobile 4 处 hardcode `10.0.2.2:3000` —— PR-C/S1=β **4 处全改**（β：release 整链路诚实可用，不留半生产态）
3. `transformFileUrlForDev` 起点 line **119**（v0.1 写 99 错）
4. `isProd skip` line **220**（v0.1 写 178-184 错）
5. `main.dart kDebugMode guard` line **63**（v0.1 写 ~53 偏）
6. `settings_page if (kDebugMode)` line **263-264**（v0.1 写 ~235 偏）
7. `orphan_scan` default `--scope='all'` → PR-C 后 staging 中间产物全 orphan 误删（**P0 必修**，R1#4）
8. `pipeline.py` 无 dotenv，`.env` 不会自动读（**P0 必修**，R2#4）

---

## Phase 0 — 用户操作（你做，~45 min）

### 0.0 Build NestJS Docker image（v0.2 新加，R1#2）

仓内**无** Dockerfile（v0.1 plan 假设 `meow-api:latest` 已有 build 是 P0 漏洞）。先在 repo 加 `apps/api/Dockerfile`：

**`apps/api/Dockerfile`**（新建）:
```dockerfile
# PR-C: NestJS multi-stage build
# Stage 1: TypeScript build
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Alpine runtime（slim image，~150MB）
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=builder /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

build：

```bash
cd apps/api
docker build -t meow-api:latest .
docker images | grep meow-api  # 验证 ~150MB image
```

如 build 失败（package.json 没 `"build": "tsc"` / 别的 quirk），fallback 用 single-stage:

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm ci && npm run build
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

### 0.1 域名 + DNS

1. 注册 `<your-domain>.<tld>`（namesilo / 腾讯云域名 / Cloudflare Registrar 都行）
2. DNS 加 A 记录：
   ```
   类型  主机记录  记录值       TTL
   A     api      <your IP>    600
   ```
3. 等 5-10 分钟 DNS propagate；`ping api.<your-domain>.<tld>` 应返你 server IP

### 0.2 docker-compose with HTTPS（默认推荐 acme-companion + fallback host cron；R1#8 / R2#7）

> v0.1 自写 nginx.conf + certbot sidecar + bootstrap 临时配置——三个权衡点：cert renew 后 nginx reload / bootstrap chicken-and-egg / 自写 nginx.conf 维护成本。
>
> v0.2 给两条路径，**默认推荐 A**，**B 留给 "已有手写 nginx 不想换镜像" 用户**，**C（mount docker.sock 给 certbot 容器）明确不推荐**（攻击面太大；R2#7）。

#### 方案 A（**默认推荐**）：`nginxproxy/nginx-proxy` + `nginxproxy/acme-companion`

镜像组合自带：自动从 docker label 探测 service + 生成 nginx.conf + ACME issue + auto-renew + nginx reload。零自写 nginx.conf，零 bootstrap chicken-and-egg。

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
      VIRTUAL_HOST: api.${DOMAIN}
      VIRTUAL_PORT: 3000
      LETSENCRYPT_HOST: api.${DOMAIN}
      LETSENCRYPT_EMAIL: ${LE_EMAIL}
    depends_on: [postgres]
    expose: ['3000']
    restart: unless-stopped

  nginx-proxy:
    image: nginxproxy/nginx-proxy:1.6
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - certs:/etc/nginx/certs
      - vhost:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html
      - /var/run/docker.sock:/tmp/docker.sock:ro
    restart: unless-stopped

  acme-companion:
    image: nginxproxy/acme-companion:2.4
    volumes_from: [nginx-proxy]
    volumes:
      - certs:/etc/nginx/certs
      - acme:/etc/acme.sh
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      DEFAULT_EMAIL: ${LE_EMAIL}
      NGINX_PROXY_CONTAINER: nginx-proxy
    restart: unless-stopped

volumes:
  pgdata:
  certs:
  vhost:
  html:
  acme:
```

**`.env`**（部署目录，不进 repo）:
```bash
PG_PASSWORD=<strong-postgres-password>
DOMAIN=<your-domain>.<tld>
LE_EMAIL=<your-email>
```

启全套：

```bash
docker compose up -d
# acme-companion 监 docker socket → 看到 api service 的 LETSENCRYPT_HOST
# label → 自动 ACME http-01 challenge issue cert → 写到 certs volume
# → nginx-proxy 自动 reload 用新 cert
# 整个过程 ~30s（首次）；之后 cert 60d auto-renew + auto-reload
```

**安全注（A 方案）**：

- `nginx-proxy` mount `docker.sock` read-only；`acme-companion` mount read-write
- 攻击面：如果有人攻入这两个容器之一可能控制 docker daemon
- MVP 接受此风险；生产场景建议加 docker-socket-proxy 做权限隔离

#### 方案 B（fallback）：手写 nginx + host cron renew

**适用场景**：你已经有手写 nginx + 不想换 docker 镜像组合。

```bash
# 在 server 上一次性 issue cert（standalone，不需要现成 nginx）：
docker run --rm -p 80:80 \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot:latest certonly --standalone \
  --email <your-email> --agree-tos --no-eff-email \
  -d api.<your-domain>.<tld>

# 启 docker-compose（你自己手写 nginx.conf + 自己 mount certbot/conf:/etc/letsencrypt）
docker compose up -d

# crontab -e 加 host-level renew 每天凌晨 3 点（renew + nginx reload 两步）：
0 3 * * * docker run --rm -v /path/certbot/conf:/etc/letsencrypt -v /path/certbot/www:/var/www/certbot certbot/certbot:latest renew && docker compose -f /path/docker-compose.yml exec -T nginx nginx -s reload
```

cron 里 `docker compose exec nginx nginx -s reload` 在 host 上跑，不需要给 certbot 容器 docker socket。

#### 方案 C（**明确不推荐**）：mount `docker.sock` 给 certbot 容器

挂 docker socket 给 certbot 让它 `docker exec nginx nginx -s reload` —— 攻击面太大，certbot 镜像默认无 docker CLI 还要 build 自定义镜像。**用 A 替代**（自带 reload）。

### 0.3 验证 HTTPS 反代

```bash
# 等 ~30s 让 ACME issue cert（A 方案）
docker compose logs acme-companion | grep "Reloading nginx-proxy"
# 期望: 见 "Reloading nginx-proxy ..."（cert 已 issue + nginx 已 reload）

curl -v https://api.<your-domain>.<tld>/api/v1/content/manifest
# 期望: 200 OK + JSON (空 packages 列表，因为 file:// 行被 production skip)
# 如果 200 → HTTPS + nginx-proxy + NestJS 链路 OK
```

### 0.4 腾讯云 COS bucket（v0.1 §0.5 沿用，v0.2 编号调整）

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
3. 防盗链 / CORS（可选）
4. 创建 CAM 子账号（推荐）
   - 控制台 → 访问管理 → 用户 → 子用户 → 新建子用户
   - 权限: 仅本 bucket 的 read/write（`QcloudCOSDataReadOnly` + `QcloudCOSDataWriteOnly` 限定 resource）
   - 生成 SecretId / SecretKey → 妥善保存

### 0.5 把 SecretId/Key 放到开发机 `.env`（v0.2 R3 P1 修订：用 DATABASE_URL）

`apps/api/scripts/content_pipeline/.env`（**不要 commit**，`.gitignore` 已忽略）:
```bash
# Postgres — pipeline.py 仅读 DATABASE_URL（_connect_or_die line 69），不读
# PGHOST/PGPORT 等散乱 env。R3 评审 P1 修订：v0.1 模板用 PG* 形式实际不工作。
DATABASE_URL=postgresql://postgres:jason123@localhost:5432/meow_dev

# (推荐) 开发机连 production DB 走 SSH tunnel：
# ssh -L 5432:localhost:5432 user@your-server-ip
# 然后 DATABASE_URL=postgresql://postgres:<prod-password>@localhost:5432/meow_prod
# (与连本地 dev DB 形式一致，仅 password / database 不同)

# COS (PR-C new)
COS_REGION=ap-shanghai
COS_BUCKET=meow-content-mvp-1234567890     # 替换成你 bucket 名
COS_SECRET_ID=AKIDxxxxxxxxxxxxxxxxxxxx     # 替换
COS_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxx # 替换
COS_PUBLIC_URL_BASE=https://meow-content-mvp-1234567890.cos.ap-shanghai.myqcloud.com
```

**v0.2 新增**：pipeline.py 加 `python-dotenv` + `load_dotenv(Path(__file__).parent / '.env')` 显式按脚本目录加载（不依赖 cwd）。
**v0.2 R3 P1 必读**：`.env` 模板用 `DATABASE_URL=postgresql://...` 形式，不要写 PG* 散乱 env——pipeline.py `_connect_or_die()` line 69 只读 `DATABASE_URL`，PG* 写了也不会被认。

### 0.6 release build 用 dart-define（S1=β 验证前必读）

PR-C/B5 后 release build 启动会自动 manifest sync，且 `ApiClient` / `ExampleAudioService` / `PronunciationService` 也走 `apiV1Base`。**必须**传 dart-define 让 4 个 service 都连 production：

```bash
cd apps/mobile

flutter build apk --release \
  --dart-define=API_BASE=https://api.<your-domain>.<tld>/api/v1
```

不传 → 4 个 service 全 fallback `http://10.0.2.2:3000/api/v1` → release 用户启动后 manifest + audio + api + pronunciation 全 timeout（不是 silent，sub-smoke A + F 都会撞）。

debug / dev build 不传 dart-define：`flutter run` 行为完全等同 PR-A/B（4 个 service 全连 emulator 10.0.2.2:3000）。

> **β 兑现**：4 个 service 一并走 `apiV1Base`，release 用户体验整链路与 dev 一致——manifest sync / 例句音频 / 业务接口 / 发音查询全部连真域名，不留半生产态债务。

---

## Phase 1 — pipeline.py 接 COS + cmd_validate https + dotenv + orphan_scan default（我做，~1 day）

### Step 1.1 加 boto3 + python-dotenv 依赖（v0.2 加 dotenv，R2#4）

文件：`apps/api/scripts/content_pipeline/requirements.txt`

```diff
 psycopg2-binary>=2.9
 PyYAML>=6.0
+# PR-C: COS 接入 (S3-compatible API; future swap to real S3/R2 不改代码)
+boto3>=1.34.0
+# PR-C: 自动加载 .env (apps/api/scripts/content_pipeline/.env)
+python-dotenv>=1.0.0
```

### Step 1.2 pipeline.py 顶部加 `load_dotenv` + `_cos_client()` 无 singleton + `_upload_to_cos()`（v0.2 修订 R1#5/R1#6/R1#7/R1#11/R2#4）

文件：`apps/api/scripts/content_pipeline/pipeline.py`

加在文件顶部（既有 imports 之后）:

```python
# PR-C: load .env from script directory (works regardless of cwd)
import os
import mimetypes
from pathlib import Path
from dotenv import load_dotenv

_HERE = Path(__file__).resolve().parent
load_dotenv(_HERE / ".env")  # silent if .env missing

# PR-C: COS upload (boto3 with COS S3-compatible endpoint).
import boto3
import botocore.exceptions
from botocore.config import Config as BotoConfig


def _cos_client():
    """Build a boto3 S3 client pointed at Tencent COS endpoint.

    NOT singleton (R1#5)：每次新建。boto3 client 创建是 ms 级；singleton 阻碍
    test 注入 + env 改动后不刷新。

    Reads from environment (load_dotenv 已加载 .env):
      COS_REGION       e.g. 'ap-shanghai'
      COS_BUCKET       bucket name (returned for caller convenience)
      COS_SECRET_ID    Tencent CAM SecretId
      COS_SECRET_KEY   Tencent CAM SecretKey

    Returns: (client, bucket_name)
    """
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
    return (client, bucket)


def _upload_to_cos(local_path: Path, key: str) -> str:
    """Upload local file to COS at given key. Returns the public https URL.

    R1#7: 加 try/except + ContentLength；R1#11: ContentType 用 mimetypes。
    """
    client, bucket = _cos_client()
    public_base = os.environ.get("COS_PUBLIC_URL_BASE")
    if not public_base:
        raise ReleaseError("COS_PUBLIC_URL_BASE missing from env")

    size = local_path.stat().st_size
    content_type = (
        mimetypes.guess_type(local_path.name)[0] or "application/octet-stream"
    )

    try:
        with open(local_path, "rb") as f:
            client.put_object(
                Bucket=bucket,
                Key=key,
                Body=f,
                ContentLength=size,
                ContentType=content_type,
                CacheControl="public, max-age=31536000, immutable",
                ACL="public-read",
            )
    except botocore.exceptions.ClientError as e:
        raise ReleaseError(
            f"COS upload failed (bucket={bucket} key={key!r}): {e}"
        ) from e

    return f"{public_base}/{key}"


def _compute_cos_key(file_path: Path, manifest_id: str) -> str:
    """Build COS object key from manifest_id + full file suffixes (R1#6).

    `Path('examples-zk.jsonl.gz').suffixes` returns `['.jsonl', '.gz']`,
    so we concatenate the full chain rather than just `.suffix` (= '.gz').
    Future formats (.tar.gz / .br) work without code changes.
    """
    suffixes = "".join(file_path.suffixes)  # '.jsonl.gz' / '.br' / etc.
    return f"v1/{manifest_id}{suffixes}"
```

### Step 1.3 改 `cmd_publish_manifest`：先查 PG idempotent，仅真 INSERT 时上传 COS（v0.2 关键 R1#3 重排）

文件：`apps/api/scripts/content_pipeline/pipeline.py`，`cmd_publish_manifest`（line 139 起）

**v0.1 错误顺序**: 先 `_upload_to_cos` 再查 PG conflict → 同 manifest_id 不同内容场景先污染线上对象再被 PG 拒绝。

**v0.2 正确顺序**:

```diff
 def cmd_publish_manifest(args: argparse.Namespace) -> int:
     """Register a built package into content_manifest + release.package_set.

     Constraints:
       - release.status MUST equal 'draft'
       - package_name MUST match naming convention
       - Same manifest_id with different content → error
       - Same manifest_id with same content → idempotent no-op
-      - file_url 固定 file:// scheme
+      - PR-C: file_url is the public COS URL (https://...). Idempotent re-runs
+        skip the COS upload entirely (R1#3 — check PG conflict BEFORE upload).
     """
     conn = _connect_or_die()
     if conn is None:
         return 2

     try:
         _validate_package_name(args.package_name, args.package_kind)

         file_path = Path(args.file).resolve()
         if not file_path.exists():
             raise ReleaseError(f"file not found: {file_path}")
         sha = file_sha256(file_path)
         size = file_path.stat().st_size
-        file_url = f"file:///{file_path.as_posix().lstrip('/')}"
         manifest_id = f"{args.package_name}@{args.content_version}"

+        # PR-C R1#3: 先拼 expected_url → 查 PG idempotent → 仅真 INSERT 时
+        # 才上传 COS。避免同 manifest_id 不同内容场景先污染线上对象再被 PG 拒绝。
+        cos_key = _compute_cos_key(file_path, manifest_id)
+        public_base = os.environ.get("COS_PUBLIC_URL_BASE")
+        if not public_base:
+            raise ReleaseError("COS_PUBLIC_URL_BASE missing from env")
+        expected_url = f"{public_base}/{cos_key}"

         with conn:
             with conn.cursor() as cur:
                 # 1. Verify release exists + status='draft'
                 cur.execute(
                     "SELECT status FROM content_release WHERE release_id=%s",
                     (args.release,),
                 )
                 row = cur.fetchone()
                 if not row:
                     raise ReleaseError(f"release {args.release!r} not found")
                 if row[0] != "draft":
                     raise ReleaseError(
                         f"publish-manifest only allowed in 'draft' state, "
                         f"got {row[0]!r}"
                     )

-                # 2. Conflict handling
+                # 2. Conflict / idempotent check — BEFORE COS upload (R1#3)
                 cur.execute(
                     """SELECT checksum_sha256, size_bytes, file_url, release_id
                        FROM content_manifest WHERE id=%s""",
                     (manifest_id,),
                 )
                 existing = cur.fetchone()
                 if existing:
-                    if existing == (sha, size, file_url, args.release):
+                    if existing == (sha, size, expected_url, args.release):
                         print(
                             f"  manifest {manifest_id} already registered "
-                            f"(idempotent, no change)"
+                            f"(idempotent, no change; skipped COS upload)"
                         )
                         return 0
                     raise ReleaseError(
                         f"manifest {manifest_id} exists with different metadata "
                         f"(existing checksum/size/url/release={existing}, "
-                        f"new=({sha},{size},{file_url},{args.release})); "
+                        f"new=({sha},{size},{expected_url},{args.release})); "
                         f"use a new content_version instead of overwriting"
                     )

-                # 3. INSERT manifest (is_active=false until activate)
+                # 3. New row → upload to COS first (within tx so rollback on
+                #    INSERT failure leaves object on COS but unreferenced;
+                #    next idempotent re-run sees same expected_url and skips
+                #    upload, so no real cost)
+                print(f"  uploading to COS: key={cos_key} size={size:,}")
+                actual_url = _upload_to_cos(file_path, cos_key)
+                assert actual_url == expected_url, (
+                    f"upload URL drift: expected={expected_url!r} actual={actual_url!r}"
+                )
+                print(f"    cos url = {actual_url}")
+
+                # 4. INSERT manifest (is_active=false until activate)
                 cur.execute(
                     """INSERT INTO content_manifest
                        (id, package_name, package_kind, content_version, file_url,
                         checksum_sha256, size_bytes, min_app_version, is_active,
                         generated_at, release_id)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, false, NOW(), %s)""",
                     (
                         manifest_id,
                         args.package_name,
                         args.package_kind,
                         args.content_version,
-                        file_url,
+                        actual_url,
                         sha,
                         size,
                         args.min_app_version or "0.0.0",
                         args.release,
                     ),
                 )
```

**关键不变量**：

- 同 manifest_id + 同 content (sha/size 一致) + 同 release → idempotent return 0 **不上传 COS**
- 同 manifest_id + 不同 content → ReleaseError **不上传 COS**（保护线上 immutable URL）
- 真新行 → 上传 COS → 写 PG `content_manifest.file_url = https://...`
- INSERT 失败时 PG rollback；COS 对象留下来作为孤儿（下次 idempotent re-run 看到同 expected_url + 同 PG 条件就 skip）

### Step 1.4 加 `cmd_validate` https URL 跳过本地校验（v0.2 关键 R1#1 P0）

文件：`apps/api/scripts/content_pipeline/pipeline.py`，`cmd_validate`（line 245 起）

**v0.1 错误**：`cmd_validate` Step 5 (line 313-319) 硬性 `if not url.startswith("file://")` 抛错。PR-C 写 https URL 后 validate 100% fail，整条 release 流水线崩。

**v0.2 修订**：

```diff
@@ Step 5-8: file_url scheme + file existence + checksum + size @@
         for mid, m in manifests_by_id.items():
             url: str = m["file_url"]
+            # PR-C R1#1: https URL → skip local existence/checksum/size checks.
+            # Mobile DownloadManager validates checksum on download (PR-B2).
+            # Server-side HEAD verification 留 PR-C+ 候选（v0.4 §7.4 性能）。
+            if url.startswith("https://"):
+                # R3 P2: only https accepted (no http://); production must
+                # be HTTPS. Plain http would be a security regression and
+                # bypasses the cmd_validate scheme check.
+                continue
             if not url.startswith("file://"):
                 raise ReleaseError(
-                    f"manifest {mid} file_url scheme must be file://, got {url!r}; "
-                    f"remote URL validation is PR-B / Day 5+, not Day 3"
+                    f"manifest {mid} file_url scheme must be file:// or https://, "
+                    f"got {url!r}"
                 )
             # existing file:// path: file existence + checksum + size 校验（不变）
             ...
```

加 1 个 unit test 在 Python pytest 套件（如已有）或简单 shell smoke：

```python
def test_validate_https_url_skips_local_check(monkeypatch, conn):
    """PR-C R1#1: cmd_validate https URL → 不查文件系统 → 通过。"""
    # seed release w/ manifest having https URL (no local file)
    # call cmd_validate
    # expect: returns 0; no FileNotFoundError raised
    ...
```

如果 pipeline.py 没现有 pytest 套件，放进 `apps/api/test/pg-regression.e2e-spec.ts`（child_process 调 Python）或仅 manual smoke 覆盖（manual smoke `validate pr-c-smoke` 步骤）。**起手前 grep 仓内有无 pytest**。

### Step 1.5 改 `orphan_scan.py` `--scope` default（v0.2 关键 R1#4 P0）

文件：`apps/api/scripts/content_pipeline/orphan_scan.py`

```diff
 parser_orphan.add_argument(
     "--scope",
     choices=["audio", "packages", "all"],   # R3 P1: actual choices = packages (NOT staging)
-    default="all",
+    default="audio",
     help=(
-        "Which roots to scan: audio (cdn-mock), packages (audio-pipeline-staging), "
-        "or all (both)."
+        "Which roots to scan: audio (cdn-mock), packages (audio-pipeline-staging), "
+        "or all (both). Default: 'audio'. PR-C 后 audio-pipeline-staging 是 build 中间产物，"
+        "不再被 manifest API 引用 (file_url 全在 COS), default 不扫避免 --clean 误删。"
     ),
 )
```

**Break change**: PR-B1 default `'all'` → PR-C default `'audio'`。用户如有 cron 跑 `pipeline.py orphan-scan --clean` 会从扫两根缩到只扫 cdn-mock。要清 staging 中间产物需显式 `--scope packages`（R3 P1：实际 choices 是 `audio` / `packages` / `all`，**不是** `staging`）或 `--scope all`。README 加说明。

### Step 1.6 加 `.env.example`（v0.1 §1.4 沿用）

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

### Step 1.7 README PR-C 章节（v0.2 加 dart-define + orphan-scan break + dotenv + S1=β 决策段）

文件：`apps/api/scripts/content_pipeline/README.md`，在 PR-B4 子节后加：

```markdown
## v0.3 PR-C (Tencent COS integration + S1=β mobile 4-service env + PR-B5 release default-on)

PR-C swaps `pipeline.py`'s `file://` URLs for real Tencent COS public-read
URLs, and unblocks release-build full-chain via `--dart-define=API_BASE`.

### PR-C 边界声明（S1=β：release 整链路可用）

PR-C 兑现的是「release app 全链路可用」：

- ✅ 启动 → 从腾讯云 COS 拉 manifest → 导入 drift（`ManifestClient`）
- ✅ 点播放例句音频走真域名（`ExampleAudioService`）
- ✅ 取题目 / 业务接口走真域名（`ApiClient`）
- ✅ 听单词发音走真域名（`PronunciationService`）

β 一刀切：4 个 service 全切 `apiV1Base`（来自 `--dart-define=API_BASE`）；
release 用户体验与 dev/emulator 一致；不留半生产态债务。

### pipeline.py prerequisites

- Tencent COS bucket (ap-shanghai recommended), public-read ACL
- CAM subaccount with `QcloudCOSDataWrite` scoped to the bucket
- `pip install -r apps/api/scripts/content_pipeline/requirements.txt` (adds
  `boto3>=1.34.0` and `python-dotenv>=1.0.0`)
- `.env` populated per `.env.example` (R3 P1: `pipeline.py` only reads
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

`publish-manifest` now uploads the package to COS at key
`v1/<package_name>@<version>.<full-suffixes>` (e.g. `v1/examples-zk@v1.jsonl.gz`)
then writes that URL to `content_manifest.file_url`. **Idempotent re-runs
skip the COS upload entirely** (R1#3): the conflict check happens before
upload, so same content → no network cost; different content under same
manifest_id is a hard error per the PR-A naming-convention rules — bump
`content_version` instead.

`Cache-Control: public, max-age=31536000, immutable` on the COS object
because the URL key is content-addressable. `ContentType` is auto-detected
by `mimetypes.guess_type` (R1#11).

### `validate` post-PR-C (R1#1 + R3 P2: https-only)

`pipeline.py validate <release>` now accepts `https://` URLs in addition to
legacy `file://` (R1#1). **`http://` is rejected** (R3 P2: production must
be HTTPS; plain http would be a security regression). `https://` URLs skip
local file existence / checksum / size checks — mobile DownloadManager
performs sha256 on download (PR-B2). `file://` URLs continue to be
validated against local filesystem.

### `orphan-scan` break change post-PR-C (R3 P1: actual choices = packages)

Default `--scope` changed from `'all'` to `'audio'` (cdn-mock only). PR-C
moves all manifest packages to COS, so `audio-pipeline-staging` files are
build intermediates with no PG reference — they would all be orphans under
the old default.

The actual `orphan_scan.py` choices are `audio` / `packages` / `all`
(R3 P1; **not** `staging`). To clean staging intermediates explicitly:

```bash
pipeline.py orphan-scan --scope packages --clean  # only audio-pipeline-staging
pipeline.py orphan-scan --scope all --clean       # both (PR-B1 default before PR-C)
```

### Server cleanup

PR-B3 Day 1 added `/cdn/staging` static route + `transformFileUrlForDev`
helper for dev-mode `file://` → `http://host/cdn/staging/`. PR-C deletes
both — `pipeline.py` always writes https URLs now.

### PR-B5 (merged into PR-C) + S1=β

PR-B3 Day 3's `runManifestSyncIfEnabled` Layer-1 guard `if (!kDebugMode)
return;` is removed. With real CDN URLs reaching production clients,
release builds also auto-sync. The settings page SwitchListTile's
`if (kDebugMode)` wrap is removed too. The `flutter/foundation` import is
also removed (R2#6).

**S1=β (mobile baseUrl 4 service 全切)**:

新建 `apps/mobile/lib/core/config/api_base.dart` 暴露 const `apiV1Base`
（`String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000/api/v1')`）。
4 个 service 全切 `apiV1Base`：

- `ManifestClient.baseUrl` (line 114)
- `ApiClient.baseUrl` (line 15)
- `ExampleAudioService._baseUrl` (line 35) - `static const → final` + 加 `{String? baseUrl}` named optional
- `PronunciationService._baseUrl` (line 21) - 同上

Release build 用户体验整链路与 dev 一致（manifest sync / 例句音频 / 业务接口 /
发音查询全部连真域名）；不留半生产态债务。

Build for release:

```bash
flutter build apk --release \
  --dart-define=API_BASE=https://api.<your-domain>/api/v1
```

debug / dev / `flutter run` / unit test 默认 fallback `http://10.0.2.2:3000/api/v1`
（与 PR-A 起的 hardcode 行为完全一致）。
```

---

## Phase 2 — server cleanup（我做，~0.5 day）

### Step 2.1 删 `transformFileUrlForDev` helper + 调用（v0.2 行号刷新 R1#10）

文件：`apps/api/src/controllers/content-manifest.controller.ts`

```diff
@@ Helper section (line 119) @@
-/**
- * PR-B3 Day 1 (D3) — Dev/local mode only. Transforms `file://...` URLs
- * into `http://...` URLs the Flutter client can fetch via HTTP GET.
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

@@ imports @@
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

@@ Inside the loop (around line 220) @@
-      const host = req?.get('host');
-      if (!host) {
-        throw new InternalServerErrorException('Host header missing');
-      }
-      const fileUrl = isProd
-        ? row.file_url
-        : transformFileUrlForDev(row.file_url, host);
+      // PR-C: pipeline.py now writes real https URLs (Tencent COS), so the
+      // manifest API just passes file_url through.
+      const fileUrl = row.file_url;

@@ Production safety guard (around line 220) @@
-      if (isProd && row.file_url.startsWith('file://')) {
-        console.error(...);
-        continue;
-      }
+      // Defensive: any leftover file:// row from pre-PR-C is a data bug;
+      // skip in any environment.
+      if (row.file_url.startsWith('file://')) {
+        // eslint-disable-next-line no-console
+        console.error(
+          `[content/manifest] file:// URL in DB after PR-C — should not happen: ${row.package_id}`,
+        );
+        continue;
+      }
```

### Step 2.2 删 `/cdn/staging` static route + `const isProdEnv` 声明（v0.2 R1#13）

文件：`apps/api/src/main.ts`

```diff
   app.setGlobalPrefix('api/v1');

-  // PR-B3 Day 1 (D3) — staging serve route. ...
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
-  // NOTE: Registered AFTER /cdn/staging above — see PR-B3 Day 1 comment.
   app.useStaticAssets(join(__dirname, '..', 'cdn-mock'), {
     prefix: '/cdn',
     ...
```

`isProdEnv` 唯一引用消失（TS strict unused-variable warning），**必须同步删声明**（R1#13）。`/cdn` cdn-mock route 保留（PR-A 既有）。

### Step 2.3 e2e 测试 trim + 加 https pass-through case（v0.2 计数刷新 R1#9）

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
+      const releaseId = `${TEST_PREFIX}active`;
+      const packageName = `examples-${TEST_PREFIX}`;  // R2#5: examples- 前缀
+      const manifestId = `${packageName}@v1`;
+      const cosUrl =
+        'https://meow-content-mvp-1234567890.cos.ap-shanghai.myqcloud.com/v1/examples-test-prc-@v1.jsonl.gz';
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

期望: e2e 50 → 删 3 it (~150 行) + 加 1 case ≈ **净 -2 cases，total ~48 cases**，仍 1 baseline `/me/today` fail。

---

## Phase 3 — mobile S1=β（4 service 全切）+ PR-B5 合并（我做，~1 day）

### Step 3.0 新建 `core/config/api_base.dart`（v0.2 关键 S1=β P0）

文件：`apps/mobile/lib/core/config/api_base.dart`（**新建**）

```dart
/// PR-C S1=β: API base URL 环境化入口。
///
/// 使用 `String.fromEnvironment` 的编译时 const 让 mobile 4 个 service
/// 从 `--dart-define=API_BASE=...` 读 base URL，避免 hardcode `10.0.2.2:3000`
/// 在 release build 跑空。`String.fromEnvironment` 是 const，可作 `final`
/// 字段 default value。
///
/// **Build 命令**:
/// - dev / debug / `flutter run`: 不传 dart-define，fallback
///   `http://10.0.2.2:3000/api/v1`（与 PR-A 起的 hardcode 行为完全一致）。
/// - release / profile:
///   ```
///   flutter build apk --release \
///     --dart-define=API_BASE=https://api.<your-domain>/api/v1
///   ```
///
/// **使用方（PR-C S1=β 范围，4 service 全切）**:
/// - `ManifestClient` (core/manifest/manifest_client.dart:114)
/// - `ApiClient` (core/api/api_client.dart:15)
/// - `ExampleAudioService` (core/audio/example_audio_service.dart:35)
/// - `PronunciationService` (core/audio/pronunciation_service.dart:21)
///
/// **不传 dart-define 时**: release build 用户 4 service 全连 emulator IP
/// → manifest sync + audio + api + pronunciation 全 timeout（不是 silent
/// failure），sub-smoke A + F 立刻撞错。
///
/// **完整 base 含 `/api/v1` 前缀**: 与既有 hardcode 一致，调用方直接拿 base
/// 拼路径（`'$apiV1Base/content/manifest'`）。
const String apiV1Base = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:3000/api/v1',
);
```

### Step 3.1 ManifestClient 接 `apiV1Base`（既有 named param 注入）

文件：`apps/mobile/lib/core/manifest/manifest_client.dart`，line 109-114

```diff
+import '../config/api_base.dart';
+
 class ManifestClient {
   ...
   final String baseUrl;
   final http.Client _client;

   ManifestClient({
-    this.baseUrl = 'http://10.0.2.2:3000/api/v1',
+    this.baseUrl = apiV1Base,
     http.Client? client,
   }) : _client = client ?? http.Client();
```

`apiV1Base` 是 `const` → 作 default value 合法。Test 仍可 `ManifestClient(baseUrl: 'http://test')` 注入。

### Step 3.1.b ApiClient 接 `apiV1Base`（与 ManifestClient 同模式；S1=β）

文件：`apps/mobile/lib/core/api/api_client.dart`，line 15

```diff
+import '../config/api_base.dart';
+
 class ApiClient {
   ...
   final String baseUrl;

   ApiClient({
-    this.baseUrl = 'http://10.0.2.2:3000/api/v1',
+    this.baseUrl = apiV1Base,
     ...
   });
```

既有 named param 注入路径保留；test / call site 不破。

### Step 3.1.c ExampleAudioService: `static const → final` + named optional（S1=β）

文件：`apps/mobile/lib/core/audio/example_audio_service.dart`，line 35

```diff
+import '../config/api_base.dart';
+
 class ExampleAudioService {
-  static const String _baseUrl = 'http://10.0.2.2:3000/api/v1';
+  final String _baseUrl;
+
+  ExampleAudioService({String? baseUrl})
+      : _baseUrl = baseUrl ?? apiV1Base;
   ...
 }
```

**调用方零改动**：现存 `ExampleAudioService()` 不传 `baseUrl` → 默认 `apiV1Base` → release build 走 dart-define / dev 走 emulator fallback。Test / 特殊场景可 `ExampleAudioService(baseUrl: 'http://test')` 注入。

### Step 3.1.d PronunciationService: 同 ExampleAudioService 模式（S1=β）

文件：`apps/mobile/lib/core/audio/pronunciation_service.dart`，line 21

```diff
+import '../config/api_base.dart';
+
 class PronunciationService {
-  static const String _baseUrl = 'http://10.0.2.2:3000/api/v1';
+  final String _baseUrl;
+
+  PronunciationService({String? baseUrl})
+      : _baseUrl = baseUrl ?? apiV1Base;
   ...
 }
```

调用方零改动（同 ExampleAudioService 模式）。

### Step 3.2 PR-B5: main.dart 移 Layer 1 kDebugMode guard（v0.2 行号刷新 R1#10）

文件：`apps/mobile/lib/main.dart`（line 63）

```diff
-  // Layer 1: release/profile dead-code-eliminate
-  if (!kDebugMode) return;
-
-  try {
-    // Layer 2: feature flag
+  try {
+    // Layer 1 (was kDebugMode guard, removed in PR-C/PR-B5): now release/
+    // profile builds also auto-sync. Real CDN (Tencent COS) is in place +
+    // S1=β makes 4 mobile service `apiV1Base` env-aware via dart-define.
+    // Release 用户整链路（manifest + api + audio + pronunciation）连 production
+    // 真域名，不留半生产态。
+    //
+    // Layer 2: feature flag (manifestSyncEnabled, default true since PR-B4)
     final prefs = await SharedPreferences.getInstance();
     if (!LocalSettingsService(prefs).manifestSyncEnabled) return;
```

`flutter/foundation` import 仍保留（debugPrint 还用）。

### Step 3.3 PR-B5: settings_page.dart 移 SwitchListTile 包裹 + 删 `flutter/foundation` import（v0.2 R1#10 + R2#6）

文件：`apps/mobile/lib/features/settings/settings_page.dart`（line 263-264）

```diff
-import 'package:flutter/foundation.dart';   // R2#6: 移 kDebugMode 后 unused
 import 'package:flutter/material.dart';
 ...

-          // PR-B3 Day 3 v0.2: manifest sync debug switch (kDebugMode-only).
-          if (kDebugMode)
-            SwitchListTile(
-              dense: true,
-              ...
-              title: const Text('Manifest sync (PR-B3 dev)'),
-              subtitle: const Text('开/关后下次重启 App 生效。失败静默。'),
-              ...
-            ),
+          // PR-C/PR-B5: SwitchListTile 在 release/profile 也可见。
+          // 真 CDN URL 已落地；PR-B3 Day 3 kDebugMode guard 从 widget +
+          // main.dart hook 都已移除。Title 改面向用户。
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

`flutter/foundation` import 唯一用途是 `kDebugMode`；移 SwitchListTile 包裹后 unused → flutter analyze `unused_import` lint 必报。**必须同步删 import**（R2#6）。

### Step 3.4 测试 expect 调整 + 注释更新

文件：`apps/mobile/test/main_manifest_sync_hook_test.dart`

测试运行在 debug build (`kDebugMode = true`)，移除 Layer 1 后 helper 行为不变。**测试 expect 完全不需要改**。仅注释更新：

```diff
-  group('runManifestSyncIfEnabled (PR-B3 Day 3 + PR-B4)', () {
+  group('runManifestSyncIfEnabled (PR-B3 + PR-B4 + PR-C/PR-B5 + S1=β)', () {
     test(
         'flag=false (explicit, post-PR-B4): short-circuits before invoking service',
         () async {
       // PR-B4: default flipped from false to true.
-      // setMockInitialValues({}) (the setUp default) would yield true
-      // and trip the syncIfNeeded path.
+      // setMockInitialValues({}) (the setUp default) would yield true.
+      // PR-C/PR-B5 also removed the kDebugMode Layer 1 guard, but tests run
+      // as debug build so that has no observable effect here — see release
+      // sub-smoke A for that path.
+      // S1=β: 4 service (ManifestClient/ApiClient/ExampleAudioService/
+      // PronunciationService) now read apiV1Base from --dart-define;
+      // tests don't pass dart-define so all fall back to 10.0.2.2:3000/api/v1
+      // (same as PR-A original hardcode).
```

`ManifestClient` 既有 unit test (`test/core/manifest/manifest_client_test.dart`) 用 named param 注入 `baseUrl: 'http://test'` → 行为不变 ✓。

---

## Phase 4 — README + sub-smoke A-F + PR description（我做 + 你跑真机，~0.5 day）

### Step 4.1 PR description

`C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-C.md`（user dir，不进 commit）

骨架（沿用 PR-A/B1/B2/B3 风格 11 章）:
1. Title + 一句话概述
2. **顶部 §"PR-C 边界声明"**（S1=β 后无需 caveat 软化；release 整链路可用）
3. Why / 用户可见效果（release 全链路可用：manifest + audio + api + pronunciation 全连真域名）
4. 范围 (Phase 0-4) + S1=β 4 service 全切
5. 关键文件清单
6. 测试 (e2e + mobile unit + sub-smoke A-F)
7. 风险 & 缓解
8. 兼容性 (debug/test 不传 dart-define 行为不变；PR-A/B/B1-B4 既有契约不破坏)
9. 不做 (明示边界)
10. 评审历史 (v0.1 → v0.2 共 24 处修订 + S1=β + R3 P1/P2)
11. v0.4 SSOT 关系（PR-C 兑现 §7.1 + S1=β 4 service 全切，PR-D 不再做 baseUrl 重构）

### Step 4.2 Sub-smoke A-F（你做，真机/模拟器，~30 min）

| # | 场景 | 期望 |
|---|---|---|
| **A** | release build (`flutter build apk --release --dart-define=API_BASE=https://api.<domain>/api/v1` + install) → 启动 → adb logcat | "manifest sync result: ..." 出现（release 也跑 sync；PR-B5 + S1=β 验证 ManifestClient 真连 production）|
| **B** | release build settings 页 | 能看到 SwitchListTile (`if (kDebugMode)` 包裹已移)；可关 |
| **C** | release build flag=false 重启 | adb logcat 无 sync log（用户 opt-out 仍生效）|
| **D** | dev build bundle v3 + manifest sync → 改 bundle v4 → 重启 | manifest 数据保留（D1 收口真机回归）|
| **E** | full E2E: dev API → COS https URL → DownloadManager → drift readback | curl `https://<bucket>.cos...` 返 .gz；adb logcat 见 download 200；drift `content_package_state` 写入 |
| **F (β 关键)** | release build → 点播放例句音频 + 查询单词题目 + 听单词发音 | 全部连真域名 (`https://api.<domain>/api/v1/...`)；adb logcat 见 200；不是 timeout |

A + F 是 critical safeguard：A 验证 manifest sync release 受益；F 验证 audio/api/pronunciation release 真连 production（β 兑现"全链路可用"必跑）。

如果 release build 忘传 `--dart-define=API_BASE=...`：

- 4 service 全 fallback `http://10.0.2.2:3000/api/v1`
- A 看 manifest sync timeout；F 看 audio/api/pronunciation 全 timeout
- 不是 silent failure，立即可见

---

## 关键文件汇总（v0.2 刷新，β 版本）

### 修改

| 文件 | 增 | 删 | 净 | 说明 |
|---|---|---|---|---|
| `apps/api/Dockerfile` (新) | ~25 | 0 | +25 | R1#2 |
| `apps/api/scripts/content_pipeline/requirements.txt` | 4 | 0 | +4 | boto3 + python-dotenv |
| `apps/api/scripts/content_pipeline/pipeline.py` | ~120 | ~5 | +115 | COS upload + cmd_validate https-only + dotenv + idempotent 重排 |
| `apps/api/scripts/content_pipeline/orphan_scan.py` | 4 | 1 | +3 | --scope default 改 'audio'（choices 不变 audio/packages/all）|
| `apps/api/scripts/content_pipeline/.env.example` (新) | ~12 | 0 | +12 | DATABASE_URL + COS_* (R3 P1 不用 PG* 散乱 env) |
| `apps/api/scripts/content_pipeline/README.md` | ~70 | 0 | +70 | PR-C 章节 + S1=β 决策段 + dart-define + orphan-scan break + dotenv |
| `apps/api/src/main.ts` | 0 | ~28 | -28 | 删 staging route + isProdEnv |
| `apps/api/src/controllers/content-manifest.controller.ts` | ~5 | ~50 | -45 | 删 transform helper + Req |
| `apps/api/test/pg-regression.e2e-spec.ts` | ~50 | ~150 | -100 | trim 2 describe + 加 1 case |
| `apps/mobile/lib/core/config/api_base.dart` (新) | ~28 | 0 | +28 | **S1=β** + dartdoc |
| `apps/mobile/lib/core/manifest/manifest_client.dart` | ~3 | ~1 | +2 | apiV1Base default |
| `apps/mobile/lib/core/api/api_client.dart` | ~3 | ~1 | +2 | apiV1Base default（β 新加）|
| `apps/mobile/lib/core/audio/example_audio_service.dart` | ~7 | ~1 | +6 | static const → final + named optional（β 新加）|
| `apps/mobile/lib/core/audio/pronunciation_service.dart` | ~7 | ~1 | +6 | 同上（β 新加）|
| `apps/mobile/lib/main.dart` | ~5 | ~3 | +2 | PR-B5: 删 kDebugMode guard |
| `apps/mobile/lib/features/settings/settings_page.dart` | ~5 | ~12 | -7 | PR-B5: 删 SwitchListTile 包裹 + flutter/foundation import |
| `apps/mobile/test/main_manifest_sync_hook_test.dart` | ~10 | ~5 | +5 | 注释更新 |

**预估 diff**: 约 +375 / -252，net +123 行（v0.1 估 -40；v0.2 加 Dockerfile + api_base.dart + cmd_validate + orphan_scan + dotenv + β 4 service 全切；S1=β 比 α 多 +18 行的 ApiClient/ExampleAudioService/PronunciationService 三处）。

### 新建

- `apps/api/Dockerfile`
- `apps/api/scripts/content_pipeline/.env.example`
- `apps/mobile/lib/core/config/api_base.dart`
- `docs/design/pr-c-scope.md`（v0.1 → v0.2）
- `docs/design/pr-c-plan.md`（v0.1 → v0.2，本文件）
- `C:\Users\lenovo\.claude\PR_DESCRIPTION_PR-C.md`（user dir）

### 不动（β 后无 mobile baseUrl 留位；S1=β 已一并处理 4 service）

- `apps/mobile/lib/core/manifest/{download_manager,package_installer,content_package_service}.dart`
- `apps/mobile/lib/core/memory/wordbook_loader.dart`
- `apps/mobile/lib/core/storage/local_settings_service.dart`
- `apps/mobile/lib/core/storage/drift/`
- `apps/mobile/pubspec.yaml`（pubspec 不动；β 不加新依赖）
- `apps/api/src/infrastructure/`
- `apps/api/scripts/content_pipeline/build_examples_package.py` / `gc_stale.py` / `content_release_repo.py`

---

## 验证

### flutter analyze 0 new issues

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-c\apps\mobile
flutter analyze lib/main.dart `
                lib/features/settings/settings_page.dart `
                lib/core/config/api_base.dart `
                lib/core/manifest/manifest_client.dart `
                test/main_manifest_sync_hook_test.dart
# 期望: No issues found
```

### flutter test 1202/1202

```powershell
flutter test
# 期望: 1202/1202 全过 (β 仅改 4 service default value；既有 named param
# 注入测试零影响；ExampleAudioService/PronunciationService 改 static const → final
# 后既有 `XxxService()` 调用方零改动)
```

### server e2e

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-c\apps\api
$env:PGPASSWORD = "<your-local-password>"
npm run test:e2e:pg
# 期望: ~48 cases pass + 1 baseline /me/today fail
```

### pipeline.py manual smoke（v0.2 命名修订 R2#5 + idempotent 验证 R1#3 + validate https R1#1）

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-c\apps\api
# 已配 .env (含 COS_*)
pip install -r scripts\content_pipeline\requirements.txt

python scripts\content_pipeline\pipeline.py create-release pr-c-smoke --title "PR-C smoke"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release pr-c-smoke `
  --package-name examples-test-prc --package-kind examples `
  --content-version v1 `
  --file audio-pipeline-staging\some-package.jsonl.gz
# 期望: stdout 含 "uploading to COS: key=v1/examples-test-prc@v1.jsonl.gz" + "cos url = https://..."
# COS 控制台能看到该 object

# Idempotent re-run（R1#3 验证：不重传，零网络 cost）
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release pr-c-smoke `
  --package-name examples-test-prc --package-kind examples `
  --content-version v1 `
  --file audio-pipeline-staging\some-package.jsonl.gz
# 期望: stdout 含 "(idempotent, no change; skipped COS upload)"
# 不打印 "uploading to COS"

python scripts\content_pipeline\pipeline.py validate pr-c-smoke
# 期望: 通过 (R1#1: cmd_validate https URL 跳过本地校验)

python scripts\content_pipeline\pipeline.py activate pr-c-smoke

curl https://api.<your-domain>/api/v1/content/manifest
# 期望: file_url = "https://meow-content-mvp-...cos.ap-shanghai.myqcloud.com/v1/examples-test-prc@v1.jsonl.gz"

# orphan-scan default 验证（R1#4）
python scripts\content_pipeline\pipeline.py orphan-scan
# 期望: 仅扫 cdn-mock；audio-pipeline-staging 不报 orphan

python scripts\content_pipeline\pipeline.py orphan-scan --scope all
# 期望: 扫两根；staging 中间产物报 orphan（dry-run，不删）

# Cleanup
python scripts\content_pipeline\pipeline.py revoke pr-c-smoke --reason "smoke done"
```

### Sub-smoke A-F（真机；详细 §"Phase 4 Step 4.2"；β 加 F 验全链路）

---

## 风险

| 风险 | 缓解 |
|---|---|
| Phase 0 Dockerfile build 失败 | plan §"Phase 0 §0.0" 给完整 multi-stage 模板 + single-stage fallback |
| nginxproxy/acme-companion 自动 cert 失败（DNS 没 propagate / 80 端口被占） | 等 DNS 5-10min；`docker compose logs acme-companion` 查 ACME log；80 端口被占 `lsof -i :80` 排查；fallback 切方案 B（host cron）|
| boto3 PUT 大包慢 | 当前包 < 1MB，PUT 即时；未来若包变大可加 multipart upload（boto3 builtin）|
| COS bucket 误开 public-write | Phase 0 §0.4 只设 public-read；CAM 子账号 write 权限仅本 bucket |
| 现有 PR-B3 e2e cases 删除后 regression 漏 | Phase 2 Step 2.3 加 1 https pass-through case 验证新行为 |
| `cmd_validate` 改写后 file:// 路径回归 | 加 1 unit test 覆盖 file:// 仍走原校验 + https 跳过；e2e 既有 cases 也覆盖 file:// 路径 |
| idempotent re-publish 重排逻辑误改 conflict 路径 | recon line 190-198 conflict 检查保留；只把 `_upload_to_cos` 移到 conflict check 之后；manual smoke 双覆盖（含 idempotent re-run 验证）|
| orphan_scan default 改 'audio' break PR-B1 既有 cron | 用户当前无 cron；plan README 明示 break change + `--scope all` 可恢复旧行为 |
| **release build 忘传 `--dart-define=API_BASE=...`** | 4 service 全 fallback 10.0.2.2 → release manifest + audio + api + pronunciation 全 timeout（不是 silent，4 处一起撞）；sub-smoke A + F 必跑会撞；README 强调 release build 命令 |
| **β `static const → final` 改动破坏既有 `XxxService()` 调用方** | recon: ExampleAudioService/PronunciationService 既有调用方都是 `XxxService()` 不传 baseUrl，加 named optional 后 default fallback `apiV1Base`，调用方零改动；baseline `flutter test` 验证 |
| **sub-smoke F audio/api 真域名连通失败** | 阻塞 PR-C 提交；β 一刀切的代价就是必须验全链路；如真机失败排查顺序：dart-define / DNS / nginx-proxy / acme-companion / API endpoint 实现 |
| 移 kDebugMode guard 后 release 用户首次启动多 1 次 manifest API call | sync fire-and-forget unawaited；不阻塞 UI；hasFailure 静默 |
| 删除 server `/cdn/staging` route 后 dev 本地无 fallback | dev 本机 pipeline.py 也走 COS 真上传；如需纯离线 dev 可临时 git revert main.ts 改动 |
| `.env` SecretId/SecretKey 误 commit | `.gitignore` 已忽略 `.env`；plan 强调用 `.env.example` 占位 |
| nginx-proxy + acme-companion mount docker.sock 攻击面 | 接受 MVP 风险；生产建议 docker-socket-proxy 隔离权限；fallback 方案 B（host cron）不需 mount socket 给容器 |
| dotenv `load_dotenv` 路径错（cwd 与脚本目录不一致） | 显式 `Path(__file__).parent / '.env'` 不依赖 cwd |

---

## 验收清单（详见 scope §7）

- [ ] Phase 0 Dockerfile build 成功（R1#2）
- [ ] 域名 + HTTPS + COS bucket 完成（acme-companion 自动 cert / fallback 方案 B 任一）
- [ ] `pipeline.py publish-manifest` 上传到 COS + 写 https URL（manual smoke）
- [ ] **Idempotent re-run 跳过 COS upload**（R1#3 manual smoke 第 2 次 publish-manifest）
- [ ] **`pipeline.py validate` 接受 https URL**（R1#1 manual smoke）
- [ ] **`pipeline.py orphan-scan` default 仅扫 cdn-mock**（R1#4 manual smoke）
- [ ] PG `content_manifest.file_url` 是 https
- [ ] manifest API（dev / production 都 OK）返非空 packages，含 https URL
- [ ] **`api_base.dart` 新文件 + 4 个 service default 全切 `apiV1Base`**（S1=β）
  - [ ] `ManifestClient.baseUrl` (line 114)
  - [ ] `ApiClient.baseUrl` (line 15)
  - [ ] `ExampleAudioService._baseUrl` (line 35) - `static const → final` + named optional
  - [ ] `PronunciationService._baseUrl` (line 21) - 同上
- [ ] **flutter test 1202/1202 全过**（β 既有测试不破；既有 named param 注入零退化）
- [ ] flutter analyze 0 new issues（含 settings_page `flutter/foundation` import 已删 R2#6）
- [ ] release build 启动也跑 sync（sub-smoke A）
- [ ] release build settings 能看到开关（sub-smoke B）
- [ ] release build 用户能 opt-out（sub-smoke C）
- [ ] e2e suite ~48 cases 通过 + 1 baseline `/me/today` fail
- [ ] sub-smoke A-E 真机全过（D1 收口 / 全链路 manifest sync）
- [ ] **sub-smoke F 真机全过**（β 关键：release build 点 audio + api + pronunciation 都连真域名，不 timeout）
- [ ] **README PR-C 章节含 S1=β 决策段**（β 后无需 caveat 软化；release 整链路可用）
- [ ] PR_DESCRIPTION_PR-C.md 写到 user dir（11 章 + S1=β 决策段 + sub-smoke F 验证段）

---

## 提交策略

按 scope §6，单 PR `feat/v0.3-pr-c-cos-and-prb5` → main，按 phase 拆 commit:

```
docs(v0.3-pr-c): scope v0.1 + plan v0.1 (旧版，可保留作 history 对照)
docs(v0.3-pr-c): scope v0.2 + plan v0.2 (吸收 24 处评审 + S1=β + R3 P1/P2)
feat(v0.3-pr-c): Phase 0 — Dockerfile multi-stage
feat(v0.3-pr-c): Phase 1 — pipeline.py COS upload + cmd_validate https-only + dotenv + orphan_scan default
feat(v0.3-pr-c): Phase 2 — server cleanup (transform helper / staging route / e2e trim)
feat(v0.3-pr-c): Phase 3 — mobile S1=β (api_base.dart + 4 service) + PR-B5 (移 kDebugMode + 删 flutter/foundation)
feat(v0.3-pr-c): Phase 4 — README + sub-smoke A-F 验收
Merge feat/v0.3-pr-c-cos-and-prb5 — v0.3 PR-C COS + PR-B5 + S1=β (~3d)
```

按 phase 拆 commit — 与 PR-B3 / PR-B4 风格一致，每 phase 独立 commit 便于 git bisect / revert。

---

## 评审节奏

1. 本次：scope v0.2 + plan v0.2 push 让 codex / 用户 review（24 处修订 + S1=β + R3 P1/P2）
2. 评审吸收 → v0.3（如有新 P0/P1）
3. Phase 0 你跑（Dockerfile + 域名 + nginx-proxy + COS）
4. Phase 1-3 我做（pipeline + server + mobile β 4 service + PR-B5）
5. Phase 4 sub-smoke A-F 你跑真机（含 F：audio/api 全链路验证）
6. Merge 进 main + 删 feature branch
7. v0.3 milestone 全部完成 → 打 git tag v0.3.0 + Release notes
8. **PR-D 不再做 mobile baseUrl 重构**（β 已合并）；候选改成 audio file 接 COS / multi-env build flavor / 其他

---

## 不做（与 scope §0.2 同 + β 边界明示）

- ❌ 真 Cloudflare/AWS CDN 接入（boto3 已铺路 future swap）
- ❌ presigned URL（v0.3 走 public-read）
- ❌ ETag / Range / multi-codec / hot-link protection（流量起再做）
- ❌ Tombstone / status='deleted' 路径（D5；v0.4 §7.3 候选）
- ❌ 改 ContentPackageService / PackageInstaller / DownloadManager / WordbookLoader
- ❌ 改 drift schema / pubspec
- ❌ 多 region / multi-bucket（单 ap-shanghai 够 v0.3）
- ❌ **重构 mobile service 调用层**（β 边界：仅 baseUrl default 替换 + 2 个 service 加 named optional；零调用层 / UI / 业务逻辑改动）
- ❌ **环境选择 UI** / build flavor（PR-D 候选；当前 dart-define 一次 build 一套）
- ❌ **audio file 接 COS**（PR-D 候选；当前 audio 仍走 cdn-mock + ApiClient 拼）
- ❌ **server-side cmd_validate HEAD 验证 https**（v0.4 §7.4 性能候选；client checksum 兜底已足够）
- ❌ **`http://` 远程 URL 进 manifest**（R3 P2：production 必须 HTTPS；plain http 是安全 regression）
- ❌ **mount `docker.sock` 给 certbot 容器做 nginx reload**（R2#7：攻击面太大；用 acme-companion 替代）
