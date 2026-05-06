# v0.3 PR-B3 · Day 1 plan — server staging serve route + manifest URL transform (D3 收口)

## Context

PR-B3 master plan v0.1 已写到 `docs/design/pr-b3.md`。Day 1 严格在 master plan §Day 1 范围内：

- **D3 收口**：PR-B4 默认开 sync 时 Flutter 客户端必须能 HTTP GET 到 manifest 包文件。当前 dev 模式 manifest API 直接返 `file://` URL，client 不能用；production 直接 skip file:// 行（PR-A 既有行为）。
- **解决方案**：server 加 staging serve route（NestJS useStaticAssets 暴露 audio-pipeline-staging 为 `/cdn/staging`）+ manifest API dev 模式做 `file://` → `http://` URL transform。production 行为完全不变。

工作分支：`feat/v0.3-pr-b3-feature-flag-wire-up` @ `7058387`
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b3`
对照基线 commit：`7058387`（PR-B2 merge 点）

## 严格范围

仅改 server 端（无 mobile / migration / 其他改动）。**0.5 天预算**。

### 不做（明示边界）

- ❌ feature flag（Day 2）
- ❌ WordbookLoader 改（Day 2）
- ❌ 启动 sync hook（Day 3）
- ❌ Mobile 任何改动
- ❌ migration / pipeline.py / cdn-mock 目录结构

## 核实事实（recon 后）

### main.ts 现状

文件：`apps/api/src/main.ts:1-44`

- imports: `NestFactory / NestExpressApplication / path.join / AppModule / 3 个 middleware/filter`
- 现有 useStaticAssets（行 19-25）：
  ```typescript
  app.useStaticAssets(join(__dirname, '..', 'cdn-mock'), {
    prefix: '/cdn',
    setHeaders: (res) => {
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    },
  });
  ```
- bootstrap 流程：`setGlobalPrefix('api/v1')` + middleware + filters + cors + listen
- **isProduction 判断**：main.ts 无；只有 controller 行 106 用 `process.env.NODE_ENV === 'production'`

### content-manifest.controller.ts 现状

文件：`apps/api/src/controllers/content-manifest.controller.ts`

- `@Get('manifest')` 行 100，方法签名两个 `@Query` 参数
- `isProd` 判断行 106：`process.env.NODE_ENV === 'production'`
- 循环结构行 158-209：
  - 行 162-168：跳过 null/empty `file_url`
  - 行 171-177：production 跳过 file:// 行（PR-A 行为）
  - 行 195-209：`packages.push({ ... file_url: row.file_url, ... })`

### NestJS @Req() 注入

仓内无现成 @Req() 示例。标准写法：
```typescript
import { Controller, Get, Req } from '@nestjs/common';
import { Request } from 'express';

@Get('manifest')
async getManifest(
  @Query('since_release') sinceRelease?: string,
  @Query('app_version') appVersion?: string,
  @Req() req?: Request,  // 新加
): Promise<ManifestResponse> {
```

`req?.get('host')` 拿 host:port（如 `10.0.2.2:3000` from Android emulator）。

### e2e 测试块

`apps/api/test/pg-regression.e2e-spec.ts:596-716`

`describe('GET /api/v1/content/manifest (PR-A Day 4)', () => { ... })` 已有完整 seed helpers（seedRelease / seedManifest）。Day 1 加 2 cases 在 line 716 后。

## 实施

### Step 1：main.ts 加第二个 useStaticAssets

文件：`apps/api/src/main.ts`

修改：在现有 `cdn-mock` useStaticAssets 之后插入：

```typescript
// PR-B3 Day 1 (D3): expose audio-pipeline-staging at /cdn/staging so
// Flutter clients can HTTP GET manifest packages. Dev/local mode only —
// production manifest API still skips file:// rows (PR-A behavior).
//
// Cache-Control 'no-cache' because staging files change during develop;
// real CDN (PR-B3+ future) sets long-lived cache headers itself.
app.useStaticAssets(join(__dirname, '..', 'audio-pipeline-staging'), {
  prefix: '/cdn/staging',
  setHeaders: (res) => {
    res.setHeader('Cache-Control', 'no-cache');
  },
});
```

**注意**：`/cdn` 已被 PR-A 占用，新前缀 `/cdn/staging` 与之并行（NestJS/express
按 prefix 长度匹配，`/cdn/staging/foo.gz` 不会落到 `/cdn` 处理器）。

### Step 2：content-manifest.controller.ts 加 dev URL transform

文件：`apps/api/src/controllers/content-manifest.controller.ts`

#### 2a. 加 import（顶部）

```typescript
import {
  BadRequestException,
  Controller,
  Get,
  Query,
  Req,  // 新加
} from '@nestjs/common';
import type { Request } from 'express';  // 新加
```

#### 2b. 加 helper 函数（文件内私有，靠近其他 helper）

```typescript
/**
 * PR-B3 Day 1 (D3) — Dev/local mode only. Transforms `file://...` URLs
 * into `http://...` URLs the Flutter client can fetch via HTTP GET.
 *
 * Maps:
 *   file:///*/audio-pipeline-staging/{file}    → http://{host}/cdn/staging/{file}
 *   file:///*/cdn-mock/{rel}                   → http://{host}/cdn/{rel}
 *
 * Other file:// shapes are returned unchanged so the client throws
 * "URL not resolvable" — easier to spot a server-side path drift than
 * silently masking it.
 *
 * Production calls this with isProd=true short-circuited; this function
 * is never invoked there.
 */
function transformFileUrlForDev(fileUrl: string, host: string): string {
  if (!fileUrl.startsWith('file://')) return fileUrl;
  if (fileUrl.includes('/audio-pipeline-staging/')) {
    const fileName = fileUrl.split('/audio-pipeline-staging/').pop();
    return `http://${host}/cdn/staging/${fileName}`;
  }
  if (fileUrl.includes('/cdn-mock/')) {
    const rel = fileUrl.split('/cdn-mock/').pop();
    return `http://${host}/cdn/${rel}`;
  }
  return fileUrl;
}
```

#### 2c. 修改方法签名 + 应用 transform

```typescript
@Get('manifest')
async getManifest(
  @Query('since_release') sinceRelease?: string,
  @Query('app_version') appVersion?: string,
  @Req() req?: Request,  // 新加
): Promise<ManifestResponse> {
```

修改循环体（行 195-209 前）：
```typescript
// 现有 production skip（行 171-177）保持不变。

// PR-B3 Day 1: dev/local 模式 file:// → http:// transform。
// production 跳过分支（行 171）已 continue，这里只处理 dev/local。
const host = req?.get('host') ?? 'localhost:3000';
const fileUrl = isProd
  ? row.file_url
  : transformFileUrlForDev(row.file_url, host);

packages.push({
  // ... 其他字段不变
  file_url: fileUrl,  // ← 改用 transformed
  // ...
});
```

### Step 3：e2e 加 2 cases

文件：`apps/api/test/pg-regression.e2e-spec.ts`

在 `describe('GET /api/v1/content/manifest (PR-A Day 4)', ...)` 块末尾（line 716 前 `});`）加：

```typescript
it('PR-B3: dev mode transforms file:///audio-pipeline-staging/ → http://host/cdn/staging/', async () => {
  await seedRelease(/* test prefix release, status='active', package_set */);
  await seedManifest(
    /* manifestId */,
    /* packageName */,
    /* packageKind: 'examples' */,
    /* contentVersion: 'v1' */,
    'file:///D:/test/audio-pipeline-staging/examples-zk@v1.jsonl.gz',
    /* checksum */,
    /* sizeBytes */,
    true,
    /* releaseId */,
  );

  // 默认 NODE_ENV != 'production' → dev mode
  const res = await request(app.getHttpServer())
    .get('/api/v1/content/manifest')
    .expect(200);

  const found = res.body.packages.find(
    (p: any) => p.package_id === /* manifestId */,
  );
  expect(found).toBeDefined();
  expect(found.file_url).toMatch(
    /^http:\/\/[^/]+\/cdn\/staging\/examples-zk@v1\.jsonl\.gz$/,
  );
});

it('PR-B3: production mode still skips file:// (PR-A 行为不变)', async () => {
  await seedRelease(/* ... */);
  await seedManifest(/* file:///... 同上 */);

  const oldEnv = process.env.NODE_ENV;
  process.env.NODE_ENV = 'production';
  try {
    const res = await request(app.getHttpServer())
      .get('/api/v1/content/manifest')
      .expect(200);

    const found = res.body.packages.find(
      (p: any) => p.package_id === /* manifestId */,
    );
    // production: file:// 行直接 continue，不在响应里
    expect(found).toBeUndefined();
  } finally {
    process.env.NODE_ENV = oldEnv;
  }
});
```

**注意点**：
- 测试 prefix 用 `test-day1-` 避免与 PR-A Day 4 测试冲突
- `process.env.NODE_ENV` 在 jest 进程里能改（影响后续 controller 调用），用 try/finally 还原
- 不需要真的起 NestJS production mode；controller 行 106 读 env var 即时生效

## 关键文件

### 修改
- `apps/api/src/main.ts`（+8 行 useStaticAssets）
- `apps/api/src/controllers/content-manifest.controller.ts`（+30 行 transform helper + import + 调用）
- `apps/api/test/pg-regression.e2e-spec.ts`（+2 cases，~80 行）

### 不动
- `apps/api/src/app.module.ts` / `routes.module.ts`
- `apps/api/src/infrastructure/postgres/migrations/`（无 schema 改动）
- `apps/api/scripts/content_pipeline/pipeline.py`（生成 file:// URL 的逻辑不动；transform 在消费侧）
- `apps/api/cdn-mock/` / `apps/api/audio-pipeline-staging/` 目录内容
- 任何 mobile 代码

## 验证

### 1. 单元测试 + e2e 全过

```bash
cd apps/api
npm run test:e2e:pg
# 期望：原 27/27 PR-A Day 4 cases + 2 new cases = 29/29 in 'GET manifest' describe 全过
# 总 e2e 数（基线 + Day 1）：47 + 2 = 49
```

### 2. 手动 smoke（PowerShell）

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b3\apps\api
$env:PGPASSWORD = "<your-local-password>"

# 1. 起 API server
npm run start:dev

# 2. 准备 staging file（用 PR-A pipeline.py 现有的 build-examples-package
#    输出，或手工 cp 一个 .gz 到 audio-pipeline-staging/）
Copy-Item audio-pipeline-staging\examples-zk.jsonl.gz audio-pipeline-staging\test-day1@v1.jsonl.gz

# 3. curl staging serve route
curl http://localhost:3000/cdn/staging/test-day1@v1.jsonl.gz -o /tmp/test.gz
# 期望：200 OK + 文件下载到 /tmp/test.gz；md5sum 与原文件一致

# 4. curl 现有 cdn-mock 路径仍工作（PR-A 行为不变）
curl http://localhost:3000/cdn/audio/v1/examples/en-US/.../sample.mp3 -I
# 期望：200 OK 或 404（取决于 cdn-mock 真实内容）；任何情况下不应是 500

# 5. 测 manifest API URL transform（dev 模式）
# 先用 pipeline.py 准备一个 release（PR-A 流程）：
python scripts\content_pipeline\pipeline.py create-release pr-b3-day1-smoke
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release pr-b3-day1-smoke `
  --package-name test-day1 --package-kind examples `
  --content-version v1 `
  --file audio-pipeline-staging\test-day1@v1.jsonl.gz
python scripts\content_pipeline\pipeline.py validate pr-b3-day1-smoke
python scripts\content_pipeline\pipeline.py activate pr-b3-day1-smoke --yes

curl http://localhost:3000/api/v1/content/manifest | python -m json.tool
# 期望：返 packages 数组，test-day1@v1 的 file_url 是
#       "http://localhost:3000/cdn/staging/test-day1@v1.jsonl.gz"
#       （而不是 file:// 形态）

# 6. cleanup
python scripts\content_pipeline\pipeline.py revoke pr-b3-day1-smoke --yes
psql ... -c "DELETE FROM content_manifest WHERE release_id='pr-b3-day1-smoke';
            DELETE FROM content_release WHERE release_id='pr-b3-day1-smoke';"
Remove-Item audio-pipeline-staging\test-day1@v1.jsonl.gz
```

### 3. App 默认行为不变验证

```powershell
# main.ts 改动 vs PR-B2 merge
git diff 7058387 -- apps/api/src/main.ts | wc -l
# 期望：~10 行新增（useStaticAssets 单 block）

# controller 改动
git diff 7058387 -- apps/api/src/controllers/content-manifest.controller.ts | wc -l
# 期望：~40 行（import + helper + 注入 + 应用）

# Mobile / pipeline 文件零改动
git diff 7058387 -- apps/mobile/ apps/api/scripts/ | wc -l
# 期望：0
```

## 验收清单

- [ ] `main.ts` 加第二个 useStaticAssets，prefix `/cdn/staging`，target `audio-pipeline-staging`
- [ ] `content-manifest.controller.ts` 加 `transformFileUrlForDev` helper
- [ ] `content-manifest.controller.ts` 注入 `@Req() req?: Request`
- [ ] dev 模式 `file://...staging/foo` → `http://{host}/cdn/staging/foo`
- [ ] dev 模式 `file://...cdn-mock/rel` → `http://{host}/cdn/rel`
- [ ] production 行为不变（仍跳过 file://）
- [ ] e2e 加 2 cases（dev transform + production skip）全过
- [ ] PR-A Day 4 既有 e2e cases 全过（regression）
- [ ] manual smoke 6 步全过
- [ ] mobile / pipeline 文件 0 行改动（grep 验证）

## 风险

| 风险 | 缓解 |
|---|---|
| URL transform 在 production 误触发 → 暴露 file 系统路径 | 显式 `isProd` 守卫；e2e case 2 验证 production 行为 |
| `req.get('host')` 在 Android emulator 返 10.0.2.2:3000 | 这是预期——客户端确实用此 host，round-trip 正确 |
| `req.get('host')` 在 reverse proxy 后是错的 | 当前无 reverse proxy；future 加时 NestJS `app.set('trust proxy', true)` |
| useStaticAssets 第二个调用与 cdn-mock 冲突 | NestJS/express 按 prefix 长度匹配，`/cdn/staging` 优先于 `/cdn`，无冲突 |
| audio-pipeline-staging 暴露安全风险 | dev only；production 用真 CDN；本 route 在 prod 部署时按需关闭 |
| Day 1 工作量超 0.5 天 | 改动小，~50 行代码 + 80 行测试；预期 ≤ 3 小时 |

## 评审 pre-set（猜可能被提的）

1. dev 模式没显式 disable transform 是否有后门：✅ `isProd` 守卫显式
2. NestJS @Req() 仓内首次使用：🟡 标准用法，参考官方 docs；e2e 验证
3. transform helper 应该是 controller method 还是顶层 function：✅ 顶层私有 function（无 state）
4. `audio-pipeline-staging` 大小写敏感：🟡 file:// URL 是绝对路径，OS 决定大小写；Linux/Mac 严格，Windows 宽松
5. cdn-mock prefix 已是 `/cdn`，新加 `/cdn/staging` 路由优先级：✅ NestJS/express 按 prefix 长度匹配，长 prefix 优先

## 不做

- ❌ 改 pipeline.py 让 publish-manifest 写 http:// 而不是 file://（这是 server 端责任，但放 transform 在 manifest API 出口更干净——pipeline.py 的 file:// 是源数据 SSOT，不动）
- ❌ 真 CDN 接入（v0.3 之外）
- ❌ 改 cdn-mock / audio-pipeline-staging 目录结构
- ❌ ETag / 缓存（PR-C 候选）
- ❌ multipart upload / Range resume（PR-C 候选）

## 提交策略

Day 1 完成后单 commit：

```
feat(v0.3-pr-b3): Day 1 — server staging serve + manifest URL transform (D3)

- main.ts: 加 useStaticAssets staging route, prefix=/cdn/staging
- content-manifest.controller.ts:
  - 加 transformFileUrlForDev helper
  - 注入 @Req() req
  - dev 模式 file:// → http:// transform
  - production 行为不变（仍跳过 file://）
- e2e +2 cases: dev transform / production skip
- 零 mobile / pipeline / migration 改动

D3 收口：PR-B4 默认开 manifest sync 时 Flutter 客户端能 HTTP GET 包文件。
```
