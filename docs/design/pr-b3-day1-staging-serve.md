# v0.3 PR-B3 · Day 1 plan v0.2 — server staging serve route + manifest URL transform (D3 收口)

> **v0.1 → v0.2**：吸收两份外部评审共 16 处去重修订（详见 master plan 的 v0.2
> 修订表）。关键变化：
> - staging useStaticAssets 必须**注册在 cdn-mock 之前** + `if (!isProdEnv)` 守卫
> - 严格 host check：无 Host header 抛 `InternalServerErrorException`，不再硬编码 fallback
> - e2e 用独立 describe + beforeEach/afterEach 包裹 NODE_ENV override
> - 明确声明 e2e 不能覆盖 main.ts useStaticAssets，由 manual smoke step 3 兜底
> - smoke 删除所有 `--yes`（pipeline.py activate / revoke 无此参数）
> - smoke 加 step 7 production guard 验证（NODE_ENV=production → 404）
> - 测试 prefix `test-day1-` → `test-prb3-d1-`

## Context

PR-B3 master plan v0.2 已写到 `docs/design/pr-b3.md`。Day 1 严格在 master plan §Day 1 范围内：

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

修改（v0.2 #1 R1#1 + R2#1 review-adopted）：在现有 `cdn-mock` useStaticAssets
**之前** 插入；用 `if (!isProdEnv)` 守卫，production 不暴露 staging：

```typescript
// PR-B3 Day 1 (D3): expose audio-pipeline-staging at /cdn/staging so
// Flutter clients can HTTP GET manifest packages. Dev/local mode only —
// production manifest API still skips file:// rows (PR-A behavior).
//
// 关键约束：
//   #1 (R1#1) 必须注册在 cdn-mock useStaticAssets **之前**。NestJS/express
//      useStaticAssets 是按**注册顺序 + next() fallthrough**匹配（v0.2 #16
//      review-adopted），**不是**按 prefix 长度优先。如果 cdn-mock 注册在前，
//      请求 /cdn/staging/foo 会先进 /cdn 中间件查 cdn-mock/staging/foo —
//      若 cdn-mock 误有 staging/ 子目录则会 200 截下错文件。
//   #1 (R2#1) 仅 dev/local 模式注册；production 不暴露 staging。manifest
//      API 在 prod 已 skip file://, 但 static route 仍会暴露部署目录，安全风险。
//
// Cache-Control 'no-cache' because staging files change during develop;
// real CDN (future) sets long-lived cache headers itself.
const isProdEnv = process.env.NODE_ENV === 'production';
if (!isProdEnv) {
  app.useStaticAssets(join(__dirname, '..', 'audio-pipeline-staging'), {
    prefix: '/cdn/staging',
    setHeaders: (res) => {
      res.setHeader('Cache-Control', 'no-cache');
    },
  });
}

// 现有 cdn-mock useStaticAssets（PR-A）保留不动，**必须放在 staging 之后**。
// app.useStaticAssets(join(__dirname, '..', 'cdn-mock'), { prefix: '/cdn', ... });
```

**注意**：useStaticAssets 是**按注册顺序 + next() fallthrough**匹配（v0.2 #16
review-adopted），**不是** prefix 长度优先。staging 必须先注册才会优先于 `/cdn`
中间件。production 通过 `if (!isProdEnv)` 守卫不注册——manual smoke step 7 验证
production 模式下 `/cdn/staging/foo` 返 404。

### Step 2：content-manifest.controller.ts 加 dev URL transform

文件：`apps/api/src/controllers/content-manifest.controller.ts`

#### 2a. 加 import（顶部）

```typescript
import {
  BadRequestException,
  Controller,
  Get,
  InternalServerErrorException,  // 新加 (v0.2 #9 strict host check)
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
  // v0.2 #13 (R1#6) review-adopted: '@' in URL path is RFC 3986-legal
  // (e.g. examples-zk@v1.jsonl.gz); express serve-static handles it
  // correctly — no encoding needed.
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
//
// v0.2 #9 (R1#7) review-adopted: 严格 host 取值。HTTP/1.1 必带 Host
// header；缺失视为异常请求，throw InternalServerErrorException 让排查
// 直接（不再 fallback 'localhost:3000' 硬编码——若 client 跨网段连
// 实际是错的）。
const host = req?.get('host');
if (!host) {
  throw new InternalServerErrorException('Host header missing');
}
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

#### Coverage limit 声明（v0.2 R2#4 review-adopted 关键）

e2e 用 `Test.createTestingModule({ imports: [AppModule] })`，**不会** 跑
`main.ts` 的 `bootstrap()` —— 因此 `useStaticAssets('audio-pipeline-staging',
{ prefix: '/cdn/staging' })` 注册逻辑 **无法被 e2e 覆盖**。

e2e 仅覆盖：
- controller 内 URL transform 字符串输出（dev mode）
- production env override 下 file:// 仍被跳过

`/cdn/staging/foo.gz` 真能 serve 文件 → **必须靠 manual smoke step 3 兜底**
（curl + md5sum 校验）。Sprint review 不能省掉 smoke。

#### 加测试块

在 `describe('GET /api/v1/content/manifest (PR-A Day 4)', ...)` 块**之后**
新加两个独立 describe 块（v0.2 #8 R1#5 review-adopted：production override
用独立 describe + beforeEach/afterEach，避免相互污染）：

```typescript
describe('GET /api/v1/content/manifest — PR-B3 dev URL transform', () => {
  // v0.2 #10 R1#8: prefix test-prb3-d1- (与 PR-B1 sub-smoke 风格一致；
  // 与 PR-A test-pr-a-... / PR-B1 test-prb1-... 等不冲突)
  const releaseId = 'test-prb3-d1-active';
  const packageName = 'test-prb3-d1-examples';
  const manifestId = `${packageName}@v1`;

  it('PR-B3: dev mode transforms file:///audio-pipeline-staging/ → http://host/cdn/staging/', async () => {
    await seedRelease(releaseId, /* status */ 'active', /* package_set */);
    await seedManifest(
      manifestId,
      packageName,
      /* packageKind */ 'examples',
      /* contentVersion */ 'v1',
      'file:///D:/test/audio-pipeline-staging/test-prb3-d1-examples@v1.jsonl.gz',
      /* checksum */,
      /* sizeBytes */,
      true,
      releaseId,
    );

    // 默认 NODE_ENV != 'production' → dev mode
    const res = await request(app.getHttpServer())
      .get('/api/v1/content/manifest')
      .expect(200);

    const found = res.body.packages.find(
      (p: any) => p.package_id === manifestId,
    );
    expect(found).toBeDefined();
    // '@' is RFC 3986-legal in URL path; not encoded.
    expect(found.file_url).toMatch(
      /^http:\/\/[^/]+\/cdn\/staging\/test-prb3-d1-examples@v1\.jsonl\.gz$/,
    );
  });
});

describe('GET /api/v1/content/manifest — PR-B3 production guard', () => {
  // v0.2 #8 R1#5 review-adopted: 用独立 describe + beforeEach/afterEach
  // 包裹 NODE_ENV override，避免与上面 dev describe 串味（jest 同进程
  // 多 describe 顺序不保证）。
  let oldEnv: string | undefined;
  beforeEach(() => {
    oldEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
  });
  afterEach(() => {
    if (oldEnv === undefined) {
      delete process.env.NODE_ENV;
    } else {
      process.env.NODE_ENV = oldEnv;
    }
  });

  it('PR-B3: production mode still skips file:// (PR-A 行为不变)', async () => {
    const releaseId = 'test-prb3-d1-prod';
    const packageName = 'test-prb3-d1-prod';
    const manifestId = `${packageName}@v1`;

    await seedRelease(releaseId, 'active', /* package_set */);
    await seedManifest(
      manifestId,
      packageName,
      'examples',
      'v1',
      'file:///D:/test/audio-pipeline-staging/test-prb3-d1-prod@v1.jsonl.gz',
      /* checksum */,
      /* sizeBytes */,
      true,
      releaseId,
    );

    const res = await request(app.getHttpServer())
      .get('/api/v1/content/manifest')
      .expect(200);

    const found = res.body.packages.find(
      (p: any) => p.package_id === manifestId,
    );
    // production: file:// 行直接 continue，不在响应里
    expect(found).toBeUndefined();
  });
});
```

**注意点**：
- 测试 prefix 用 `test-prb3-d1-`（v0.2 #10 R1#8）—— 与 PR-A Day 4 / PR-B1 风格一致
- production override 用独立 describe + beforeEach/afterEach（v0.2 #8 R1#5）
- e2e **不能**验证 main.ts useStaticAssets 注册（v0.2 R2#4）；route serve 靠 manual smoke step 3
- 不需要真的起 NestJS production mode；controller 行 106 读 env var 即时生效

## 关键文件

### 修改
- `apps/api/src/main.ts`（+12 行 useStaticAssets staging route + isProdEnv 守卫）
- `apps/api/src/controllers/content-manifest.controller.ts`（+30 行 transform helper + import + 注入 + 严格 host check + 应用）
- `apps/api/test/pg-regression.e2e-spec.ts`（+2 cases，~80 行；用独立 describe + beforeEach/afterEach）

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
Copy-Item audio-pipeline-staging\examples-zk.jsonl.gz audio-pipeline-staging\test-prb3-d1@v1.jsonl.gz

# 3. **强制验收（v0.2 R2#4）**：curl staging serve route
#    e2e 测不到 main.ts useStaticAssets 注册逻辑 —— 此步是 /cdn/staging
#    route 的唯一端到端验证；必须跑过且 md5sum 吻合才算 Day 1 收口。
curl http://localhost:3000/cdn/staging/test-prb3-d1@v1.jsonl.gz -o /tmp/test.gz
# 期望：200 OK + 文件下载到 /tmp/test.gz；md5sum 与原文件一致

# 4. curl 现有 cdn-mock 路径仍工作（PR-A 行为不变）
curl http://localhost:3000/cdn/audio/v1/examples/en-US/.../sample.mp3 -I
# 期望：200 OK 或 404（取决于 cdn-mock 真实内容）；任何情况下不应是 500

# 5. 测 manifest API URL transform（dev 模式）
# 先用 pipeline.py 准备一个 release（PR-A 流程）：
# v0.2 #2 R2#2 修订：删除所有 --yes（pipeline.py activate / revoke 没此参数；
# recon 确认 pipeline.py 仅 rollback / deprecate 有 --yes）
python scripts\content_pipeline\pipeline.py create-release pr-b3-d1-smoke --title "smoke"
python scripts\content_pipeline\pipeline.py publish-manifest `
  --release pr-b3-d1-smoke `
  --package-name test-prb3-d1 --package-kind examples `
  --content-version v1 `
  --file audio-pipeline-staging\test-prb3-d1@v1.jsonl.gz
python scripts\content_pipeline\pipeline.py validate pr-b3-d1-smoke
python scripts\content_pipeline\pipeline.py activate pr-b3-d1-smoke

curl http://localhost:3000/api/v1/content/manifest | python -m json.tool
# 期望：返 packages 数组，test-prb3-d1@v1 的 file_url 是
#       "http://localhost:3000/cdn/staging/test-prb3-d1@v1.jsonl.gz"
#       （而不是 file:// 形态）

# 6. cleanup
python scripts\content_pipeline\pipeline.py revoke pr-b3-d1-smoke --reason "smoke done"
psql -h localhost -U postgres -d meow_dev -c `
  "DELETE FROM content_manifest WHERE release_id='pr-b3-d1-smoke';
   DELETE FROM content_release WHERE release_id='pr-b3-d1-smoke';"
Remove-Item audio-pipeline-staging\test-prb3-d1@v1.jsonl.gz

# 7. **production guard 验证（v0.2 #1 R2#1 关键）**
# 重启 server 进 production 模式；staging route 不应被注册。
# Ctrl+C 现有 server，然后:
$env:NODE_ENV = "production"
npm run start:dev
# （另一窗口）
curl http://localhost:3000/cdn/staging/test-prb3-d1@v1.jsonl.gz -I
# 期望：404 Not Found（route 在 production 不注册）
# 不应：200（说明 isProdEnv 守卫漏了）
$env:NODE_ENV = "development"   # 还原
```

### 3. App 默认行为不变验证

```powershell
# main.ts 改动 vs PR-B2 merge
git diff 7058387 -- apps/api/src/main.ts | wc -l
# 期望：~14 行新增（isProdEnv const + if 守卫 + useStaticAssets block）

# controller 改动
git diff 7058387 -- apps/api/src/controllers/content-manifest.controller.ts | wc -l
# 期望：~40 行（import + helper + 注入 + 应用）

# Mobile / pipeline 文件零改动
git diff 7058387 -- apps/mobile/ apps/api/scripts/ | wc -l
# 期望：0
```

## 验收清单（v0.2）

- [ ] `main.ts` 加 staging useStaticAssets，**注册在 cdn-mock 之前** + `if (!isProdEnv)` 守卫
- [ ] `content-manifest.controller.ts` 加 `transformFileUrlForDev` helper
- [ ] `content-manifest.controller.ts` 注入 `@Req() req?: Request` + 严格 host check（无 host 抛 `InternalServerErrorException`）
- [ ] dev 模式 `file://...staging/foo` → `http://{host}/cdn/staging/foo`
- [ ] dev 模式 `file://...cdn-mock/rel` → `http://{host}/cdn/rel`
- [ ] production 行为不变（仍跳过 file://）
- [ ] e2e 加 2 cases（dev transform + production guard）：用独立 describe + beforeEach/afterEach
- [ ] e2e 文档说明 "createTestingModule 不覆盖 main.ts useStaticAssets，靠 smoke 兜底"
- [ ] manual smoke 7 步全过（含 step 7 production guard 404 验证）
- [ ] manual smoke step 3（curl /cdn/staging/）是 route 唯一端到端验证（强制必跑）
- [ ] smoke 中无 `activate --yes` / `revoke --yes`（pipeline.py 无此参数）
- [ ] 测试 prefix 用 `test-prb3-d1-`（不与 PR-A / PR-B1 冲突）
- [ ] PR-A Day 4 既有 e2e cases 全过（regression）
- [ ] mobile / pipeline 文件 0 行改动（grep 验证）

## 风险

| 风险 | 缓解 |
|---|---|
| production 部署误开 staging route → 暴露部署目录文件 | `if (!isProdEnv)` 守卫 + smoke step 7 验证 production 模式 404 |
| URL transform 在 production 误触发 → 暴露 file 系统路径 | 显式 `isProd` 守卫；e2e production guard describe 验证 |
| cdn-mock 下意外有 staging/ 子目录 → 拦截 staging 请求 | staging 注册在 cdn-mock 之前（v0.2 #1 R1#1 review-adopted） |
| `req.get('host')` 在 Android emulator 返 10.0.2.2:3000 | 这是预期——客户端确实用此 host，round-trip 正确 |
| `req.get('host')` 在 reverse proxy 后是错的 | 当前无 reverse proxy；future 加时 NestJS `app.set('trust proxy', true)` |
| Host header 缺失 | 严格守卫：抛 `InternalServerErrorException`（v0.2 #9 R1#7 review-adopted），不再 fallback 硬编码 |
| useStaticAssets 注册顺序认知错误 | v0.2 #16 review-adopted: useStaticAssets 是按**注册顺序 + next() fallthrough**匹配，**不是** prefix 长度优先；staging 必须先注册 |
| `@` 字符 in URL path | RFC 3986 合法（v0.2 #13 R1#6）；serve-static 处理；smoke step 3 实测 |
| audio-pipeline-staging 暴露安全风险 | dev only（`if (!isProdEnv)`）；production 用真 CDN |
| Day 1 工作量超 0.5 天 | 改动小，~50 行代码 + 80 行测试；预期 ≤ 3 小时 |

## 评审 pre-set（猜可能被提的）

1. dev 模式没显式 disable transform 是否有后门：✅ `isProd` 守卫显式 + `if (!isProdEnv)` 双重守卫
2. NestJS @Req() 仓内首次使用：🟡 标准用法，参考官方 docs；e2e 验证
3. transform helper 应该是 controller method 还是顶层 function：✅ 顶层私有 function（无 state）
4. `audio-pipeline-staging` 大小写敏感：🟡 file:// URL 是绝对路径，OS 决定大小写；Linux/Mac 严格，Windows 宽松
5. useStaticAssets 注册优先级：✅ v0.2 #16 review-adopted —— 按**注册顺序 + next() fallthrough**（不是 prefix 长度），staging 必须先于 cdn-mock 注册
6. e2e 真能验证 staging serve 吗：❌ 不能（v0.2 R2#4）—— `Test.createTestingModule` 不跑 `main.ts`；靠 manual smoke step 3 兜底
7. host header 缺失 fallback：✅ v0.2 #9 R1#7 review-adopted —— 严格抛 500，不再硬编码 'localhost:3000'

## 不做

- ❌ 改 pipeline.py 让 publish-manifest 写 http:// 而不是 file://（这是 server 端责任，但放 transform 在 manifest API 出口更干净——pipeline.py 的 file:// 是源数据 SSOT，不动）
- ❌ 真 CDN 接入（v0.3 之外）
- ❌ 改 cdn-mock / audio-pipeline-staging 目录结构
- ❌ ETag / 缓存（PR-C 候选）
- ❌ multipart upload / Range resume（PR-C 候选）

## 提交策略

Day 1 完成后单 commit（v0.2）：

```
feat(v0.3-pr-b3): Day 1 — server staging serve + manifest URL transform (v0.2)

- main.ts: 加 staging useStaticAssets，注册在 cdn-mock 之前
  + if (!isProdEnv) 守卫；production 不暴露 staging
- content-manifest.controller.ts:
  - 加 transformFileUrlForDev helper（'@' RFC 3986-legal 注释）
  - 注入 @Req() req?: Request
  - 严格 host check（无 host 抛 InternalServerErrorException）
  - dev 模式 file:// → http:// transform
  - production 行为不变（仍跳过 file://）
- e2e +2 cases: dev transform / production guard，用独立 describe +
  beforeEach/afterEach；测试 prefix test-prb3-d1-
- 零 mobile / pipeline / migration 改动

D3 收口：PR-B4 默认开 manifest sync 时 Flutter 客户端能 HTTP GET 包文件。
v0.2 已吸收两份评审 16 处。
```
