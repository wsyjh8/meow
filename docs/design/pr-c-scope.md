# PR-C scope v0.2 · 真 CDN 接入（腾讯云 COS）+ PR-B5 release default-on（合并）

- **Date**: 2026-05-07
- **Status**: scope v0.2 — 吸收三份外部评审 24 处修订（R1 13 + R2 7 + R3 4）+ 最终决策 **S1=β**（用户拍板：4 service 全切；R3 评审 P0 反对 α 切片，用户改回 β）+ R2#7 改 acme-companion 优先 + R3 P1/P2 修订（DATABASE_URL / scope=packages / validate https-only）（plan v0.2 同步）；取代 v0.1
- **基线 commit**: `5392032`（PR-B4 merge 进 main）
- **工作分支**: `feat/v0.3-pr-c-cos-and-prb5`
- **worktree**: `D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-c`
- **关系**: 延伸 `v0.3_PR-B_scope_v0.4.md` §7.1（PR-C 候选；v0.4 SSOT 标记 "v0.3 之外按需触发"），不替换 v0.4 主线。

---

## 0. v0.1 → v0.2 修订（吸收两份评审 + S1 决策 + R3 评审）

合并 R1（13 条）+ R2（7 条）+ R3（4 条 P0/P1/P2）+ recon 实测 = **24 处去重修订**。scope 决策点 **S1=β**（用户最终拍板）：mobile **4 个** service 一并环境化（`ManifestClient` / `ApiClient` / `ExampleAudioService` / `PronunciationService`），让 release build 整链路（manifest + api + audio + pronunciation）连 production；PR-C 不再制造 release 半生产态。

PR-C 边界：**release app 全链路可用**（manifest + api + audio + pronunciation 全部走 `apiV1Base`）。无需 caveat 软化——β 是诚实承诺。

### 0.1 P0 必修（评审一致；6 处）

| # | 来源 | 问题 | 修订 |
|---|---|---|---|
| 1 | R1#1 / R2#3 | `cmd_validate` 硬性要求 file:// → PR-C 写 https URL 后 validate 100% fail，整条 release 流水线崩 | Phase 1 加 step：`cmd_validate` Step 5 改写——https URL 跳过本地 file existence/checksum/size 校验（mobile DownloadManager 检 sha256 兜底）+ 1 unit test |
| 2 | R1#2 | 仓内无 Dockerfile，`docker-compose` 假设 `meow-api:latest` 已 build | Phase 0 §0.0 加 `apps/api/Dockerfile`（多阶段 node:20 build → node:20-alpine runtime）+ `docker build -t meow-api:latest .` step |
| 3 | R1#3 / R2#2 | 先上传 COS 再查 DB idempotent → 同 manifest_id 不同内容场景先污染线上对象再被 PG 拒绝 | `cmd_publish_manifest` 重排：拼 `expected_url` → 查 PG idempotent / conflict → **仅真 INSERT 时**才 `_upload_to_cos`；idempotent re-run 零网络 cost |
| 4 | R1#4 | `orphan_scan` default `--scope='all'` 扫两根，PR-C 后 audio-pipeline-staging 中间产物全被识别 orphan，`--clean` 误删 | argparse default 改 `'audio'`（仅 cdn-mock）；显式 `--scope all` 才含 staging；README 加 break-change 说明 |
| 5 | R2#4 | pipeline.py 没 `python-dotenv`，`.env` 文件不会被自动读 | `requirements.txt` 加 `python-dotenv>=1.0.0`；pipeline.py 顶部 `load_dotenv(Path(__file__).parent / '.env')` 显式按脚本目录加载（不依赖 cwd）|
| 6 | **S1=β** | mobile 4 service hardcode `http://10.0.2.2:3000` → PR-B5 release default-on 后 release 用户连不到 production；α 切片让 audio/api 留半生产态被 R3 评审反对，用户最终改回 β | 新建 `apps/mobile/lib/core/config/api_base.dart`（const `apiV1Base` via `String.fromEnvironment('API_BASE')`）+ **4 个 service 全切到 `apiV1Base`**：`ManifestClient` (line 114) / `ApiClient` (line 15) public final default 改 `apiV1Base`；`ExampleAudioService` (line 35) / `PronunciationService` (line 21) `static const _baseUrl` → `final _baseUrl` + 加 `{String? baseUrl}` named optional 参数（既有调用方零改动，default fallback `apiV1Base`）；release build 必传 `--dart-define=API_BASE=https://api.<domain>/api/v1` |

### 0.2 P1 应修（7 处）

| # | 修订 |
|---|---|
| R1#5 | `_cos_client()` 去掉 singleton（每次新建；boto3 创建 ms 级；便于 test 注入 + env 改动后刷新）|
| R1#6 | `cos_key` 用全 `"".join(file_path.suffixes)` 替代 `.suffix + fallback if .gz` 笨拙逻辑（未来加 .br/.tar.gz 不用改）|
| R1#7 | `_upload_to_cos` 加 `try/except botocore.exceptions.ClientError` 友好错误 + `ContentLength=size` 让 COS 字节验证 |
| R1#8 / R2#7 | Phase 0 nginx + certbot 整段重写：**默认推荐** `nginxproxy/nginx-proxy` + `nginxproxy/acme-companion` 镜像（自带 ACME issue + auto-renew + nginx reload）；**fallback**（如用户已有手写 nginx）host-level cron `certbot renew && docker compose exec nginx nginx -s reload`；**明确不推荐** mount `/var/run/docker.sock` 给 certbot 容器（攻击面太大）|
| R1#11 | `ContentType` 用 `mimetypes.guess_type(local_path.name)[0] or "application/octet-stream"` 替代 hardcode `application/gzip` |
| R2#5 | smoke 命令 `--package-name test-prc-examples` 改 `examples-test-prc`（PR-A R1.5 naming convention：`examples-` 前缀必须）|
| R2#6 | `settings_page.dart` 删 `flutter/foundation` import（PR-B5 移 kDebugMode 后唯一用途消失，触发 `unused_import` lint）|

### 0.3 Nit / Doc 校对（5 处）

| # | 修订 |
|---|---|
| R1#9 | e2e 计数 ~47 → **~48**（recon 实测当前 50 it cases；Phase 2 删 3 it + 加 1 https pass-through case = 净 -2）|
| R1#10 | recon 行号刷新：`transformFileUrlForDev` 起点 line **119**（不是 99）；`isProd` skip line **220**（不是 178-184）；main.dart kDebugMode guard line **63**（不是 ~53）；settings_page `if (kDebugMode)` SwitchListTile line **263-264** |
| R1#12 | scope C5 加 SSH tunnel 注解（开发机直连 production DB 的安全做法：`ssh -L 5432:localhost:5432 user@server` + 本机 `DATABASE_URL=postgres://...@localhost:5432/...`）|
| R1#13 | `main.ts` 同步删 `const isProdEnv` 声明（删 `/cdn/staging` route 后唯一引用消失；TS strict unused-variable warning）|
| (新) | scope §3.1 / §3.2 mobile 改动列表加 4 个 service + `api_base.dart` 新文件（S1=β）|

### 0.4 决策点 S1：mobile API base URL 环境化（用户最终拍板 β）

**问题**：`http://10.0.2.2:3000` 在 mobile **4 个** service 硬编码：

| Service | 文件 | 行号 | 字段形态 | 既有 named param 注入？| PR-C 改 (S1=β)？|
|---|---|---|---|---|---|
| `ManifestClient` | `core/manifest/manifest_client.dart` | 114 | `final String baseUrl` (public, default value) | ✅ 已支持 | ✅ 改 |
| `ApiClient` | `core/api/api_client.dart` | 15 | `final String baseUrl` (public, default value) | ✅ 已支持 | ✅ 改 |
| `ExampleAudioService` | `core/audio/example_audio_service.dart` | 35 | `static const String _baseUrl` | ❌ 不支持 → 改 `final` + named optional | ✅ 改 |
| `PronunciationService` | `core/audio/pronunciation_service.dart` | 21 | `static const String _baseUrl` | ❌ 不支持 → 改 `final` + named optional | ✅ 改 |

PR-C 合并 PR-B5（release default-on）后，release 用户启动会跑 manifest sync → connect 真 CDN ✓；audio/api/pronunciation 也要连 production 真域名 ✓——**β 让 release 整链路诚实可用**，不留半生产态。

**用户最终拍板 β（4 service 全切，估时 +1d → 总 3d）**：

- 新建 `apps/mobile/lib/core/config/api_base.dart`（单一 const `apiV1Base` via `String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000/api/v1')`）
- 4 个 service 全切：
  - `ManifestClient.baseUrl` default → `apiV1Base`（line 114；既有 named param 保留）
  - `ApiClient.baseUrl` default → `apiV1Base`（line 15；既有 named param 保留）
  - `ExampleAudioService._baseUrl`：`static const → final`；构造加 `{String? baseUrl}` named optional + `baseUrl ?? apiV1Base`（既有调用方 `XxxService()` 零改动）
  - `PronunciationService._baseUrl`：同上
- dev / emulator / debug / test 默认 fallback `http://10.0.2.2:3000/api/v1`（无 `--dart-define` 时行为完全不变）
- release / profile build 必传 `--dart-define=API_BASE=https://api.<domain>/api/v1`
- 不重构调用层 / 不做环境选择 UI / 不碰业务逻辑（仅 baseUrl 替换 + 2 个 service 加 named param）

#### 0.4.1 PR-C 边界声明（β 后无需 caveat 软化）

> **PR-C 兑现的是「release app 全链路可用」**：
> - ✅ 启动自动从腾讯云 COS 拉 manifest 包，导入 drift
> - ✅ 点播放例句音频走真域名（`ExampleAudioService`）
> - ✅ 取题目 / 业务接口走真域名（`ApiClient`）
> - ✅ 听单词发音走真域名（`PronunciationService`）
>
> β 后 release 用户体验与 dev/emulator 一致，不留半生产态债务。
>
> **PR-D 不再需要做 baseUrl 重构**——本来 α 留下的 3 个 service 在 β 已一并处理。后续 PR-D 候选（如真做）改成 audio file 接 COS / multi-env build flavor / 其他。

#### 0.4.2 历经 α → β 决策路径

1. **v0.1**: 未察觉 mobile 4 处 hardcode 是 PR-B5 release 触发会暴露的盲区
2. **R1+R2 评审**: R2#1 P0 揭示问题，提议 β 全切
3. **plan v0.2 β 起草**: 用户初拍 β（统一 4 service，估时 3d）
4. **plan v0.2 改 α**: 用户被中间评审说服改 α + 硬 caveat（"切片诚实"逻辑）
5. **R3 评审 P0 反对 α**: "α 制造 release 半生产态用户体验诚实性差"
6. **最终拍板 β**: 接受 R3 P0；β 一刀切干净，PR-C 范围 +0.5d 比留半生产态债务值

最终走 β 的关键论据：
- PR-B5 release default-on 是 PR-C 的核心价值兑现，release 用户**只能**用 manifest sync 不能用 audio 是诡异体验
- PR-D 留位 baseUrl 拆分意义有限（拆出仅为不同步 PR-C 风险，但 β 改动小本身风险不高）
- caveat 三处硬写虽然诚实但不如代码兑现一刀切干净
- α 节省的 0.5d 不值得让 release 用户体验半生产态

#### 0.4.3 放弃 α / γ 理由

- **α（仅 ManifestClient）**: 用户体验半生产态——manifest sync 走真域名，audio/api 仍 `10.0.2.2` → release 用户启动后可见进度但点啥都 timeout；caveat 硬写也无法让用户预期（用户不读 PR description）
- **γ（PR-C 不动 mobile，PR-B5 拆出等 PR-D）**: 让 PR-C 失去"用户可见 manifest sync 兑现"价值，退化纯 server cleanup PR；release default-on 又往后推一轮迭代

---

## 1. 6 个 scope 决策（v0.1 5 个 + S1=β 新加）

| # | 决策 | 理由 |
|---|---|---|
| **C1** | 真 CDN = **腾讯云 COS**（上海 region，public-read） | 用户已有腾讯云账号 / 国内用户最优 / 包文件本身公开二进制 |
| **C2** | HTTPS 默认 = **自购域名 + nginxproxy/nginx-proxy + acme-companion**；fallback = host cron `certbot renew + nginx -s reload` | 镜像组合自带 ACME issue / auto-renew / nginx reload，零自写 nginx.conf；fallback 给已有手写 nginx 的用户；**不推荐**给 certbot mount docker socket（攻击面太大，R2#7） |
| **C3** | COS SDK = **boto3 with `endpoint_url`**（S3-compatible API） | 未来切真 S3 / Cloudflare R2 / B2 等 S3-compat backend 零改代码 |
| **C4** | PR-C 与 PR-B5 **合并单 PR** | PR-B5 改动小 + 强依赖 PR-C 真 CDN 才有意义；同 PR 一次到位 |
| **C5** | `pipeline.py` 部署 = **开发机本地脚本** | MVP 不进 docker；连 production DB 推荐 SSH tunnel `ssh -L 5432:localhost:5432 user@server` 后本机 `DATABASE_URL=postgres://...@localhost:5432/...`（不外网开 5432）|
| **S1** | mobile baseUrl = **β（统一 4 service via `api_base.dart`）** | release 整链路诚实可用，不留半生产态；PR-D 不再需做 baseUrl 重构；R3 评审 P0 反对 α 后用户最终拍板 |

---

## 2. 关系图（v0.4 SSOT 路线图升级）

```
v0.4 SSOT (已完成):
  PR-A   ✅ server 发布闭环           (b072eb3)
  PR-B1  ✅ server 治理补完            (b26bff7)
  PR-B2  ✅ mobile 基建 (不切流量)     (7058387)
  PR-B3  ✅ feature flag + D1 + staging (5e063dc)
  PR-B4  ✅ default flag → true        (5392032)

PR-C (本 scope, v0.4 §7.1 兑现 + S1=β 全栈 mobile baseUrl):
  Phase 0 (用户做)   buy domain + Dockerfile + nginx-proxy/acme-companion + COS bucket
  Phase 1 (代码)     pipeline.py 接 COS + cmd_validate https-only + dotenv + orphan_scan default
  Phase 2 (代码)     server cleanup (transform helper / staging route / isProdEnv)
  Phase 3 (代码)     mobile S1=β (api_base.dart + 4 service 全切) + PR-B5 (移 kDebugMode)
  Phase 4 (验收)     sub-smoke A-F 真机 (含 audio/api 全链路 F) + PR description + README

PR-D 不再需要做 mobile baseUrl 重构 (β 已一并处理). 候选改成:
  - audio file 接 COS (替换 cdn-mock URL)
  - multi-env build flavor (staging vs production 两套 dart-define)
  - 其它

不做 (v0.3 之外, 按需触发):
  v0.4 §7.2  审批 Web UI       (多人协作时)
  v0.4 §7.3  观测性 / Tombstone (用户量起 / 操作员真要删)
  v0.4 §7.4  性能 (ETag / 分页) (流量起来)
```

---

## 3. 改动清单（zero out-of-scope confidence）

### 3.1 用户操作（Phase 0，~45 min；β 后 dart-define build 加 ~5 min）

| 项 | 输出 |
|---|---|
| **(新) 编译 NestJS Docker image** | `docker build -t meow-api:latest apps/api/`（plan §"Phase 0 §0.0"）|
| 注册 .top/.xyz 域名 | `<your-domain>` |
| DNS A 记录 → server IP | `api.<your-domain>` resolves |
| `docker-compose.yml` 用 nginxproxy + acme-companion（plan 给完整模板）| nginx 自动配 + cert 自动 issue/renew/reload |
| 验证: `https://api.<your-domain>/api/v1/content/manifest` 200 | curl |
| 腾讯云 COS bucket 创建 | `<bucket-name>`（如 `meow-content-mvp-1234567890`）|
| Bucket ACL 设 public-read | 控制台一键 |
| CAM 子账号 SecretId/SecretKey（仅本 bucket read/write） | pipeline.py `.env` 用 |
| **(新) release smoke build 用 dart-define** | `flutter build apk --release --dart-define=API_BASE=https://api.<your-domain>/api/v1` |

### 3.2 代码改动（Phase 1-3）

#### server (apps/api/)

| 文件 | 改动 |
|---|---|
| **(新)** `apps/api/Dockerfile` | 新建，多阶段 build → alpine runtime（~25 行）|
| `apps/api/src/main.ts` | **删** `/cdn/staging` static route + `const isProdEnv` 声明（约 -28 行）|
| `apps/api/src/controllers/content-manifest.controller.ts` | **删** `transformFileUrlForDev` helper（line 119 起 ~30 行）+ `@Req()` import + `req` 参数 + 调用；https URL pass-through |
| `apps/api/test/pg-regression.e2e-spec.ts` | **删** PR-B3 dev URL transform / production guard 2 个 describe 块（~150 行，3 个 it）；**加** 1 个 case 验证 https URL 透传（~50 行）；e2e 净 -2 cases，~48 cases |

#### pipeline (apps/api/scripts/content_pipeline/)

| 文件 | 改动 |
|---|---|
| `requirements.txt` | + `boto3>=1.34.0` + `python-dotenv>=1.0.0` |
| `pipeline.py` | + `load_dotenv` 顶部 + `_cos_client()` (no singleton) + `_upload_to_cos()` (try/except + ContentLength + mimetypes ContentType) + cmd_publish_manifest 重排（idempotent 在 upload 之前）+ **cmd_validate** Step 5 加 https 跳过校验分支（~100 行）|
| `orphan_scan.py` | argparse `--scope` default 从 `'all'` 改 `'audio'`（1 行 + 注释）|
| `.env.example` | 新建：PG + COS 7 个 env var 占位 |
| `README.md` | + PR-C 章节（COS 接入说明 + dotenv + orphan-scan break change + dart-define release build 命令）|

#### mobile (apps/mobile/)

| 文件 | 改动 |
|---|---|
| **(新)** `lib/core/config/api_base.dart` | 新建 ~25 行（const `apiV1Base` via `String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000/api/v1')` + dartdoc + dart-define release build 命令说明）|
| `lib/core/manifest/manifest_client.dart` | baseUrl default 改 `apiV1Base`（line 114；~2 行）|
| `lib/core/api/api_client.dart` | baseUrl default 改 `apiV1Base`（line 15；~2 行）|
| `lib/core/audio/example_audio_service.dart` | `static const _baseUrl` → `final _baseUrl`；构造加 `{String? baseUrl}` named optional + `baseUrl ?? apiV1Base`（line 35；~5 行；既有 `XxxService()` 调用方零改动）|
| `lib/core/audio/pronunciation_service.dart` | 同上（line 21；~5 行）|
| `lib/main.dart` | **PR-B5**: 删 `if (!kDebugMode) return;`（hook helper Layer 1 guard，line 63）|
| `lib/features/settings/settings_page.dart` | **PR-B5**: 删 `if (kDebugMode)` 包裹 SwitchListTile（line 263-264）+ 删 `flutter/foundation` import（R2#6）|
| `test/main_manifest_sync_hook_test.dart` | 注释更新（test 在 debug build 跑，行为不变）|

### 3.3 不动（zero diff vs 5392032）

- `apps/mobile/lib/core/manifest/{download_manager,package_installer,content_package_service}.dart`（PR-B2 稳定；S1=β 仅改 `manifest_client.dart`）
- `apps/mobile/lib/core/memory/wordbook_loader.dart`（PR-B3 Day 2 稳定）
- `apps/mobile/lib/core/storage/local_settings_service.dart`（PR-B4 稳定）
- `apps/mobile/lib/core/storage/drift/`（schema 不变）
- `apps/mobile/pubspec.yaml`（零新依赖）
- `apps/api/src/infrastructure/`（PG 层不动）
- `apps/api/src/middleware/`（middleware 不动）
- `apps/api/scripts/content_pipeline/{build_examples_package,gc_stale,content_release_repo}.py`（不动；orphan_scan 仅改 1 行 default）
- 任何其它 mobile / server / migration 文件

---

## 4. 估时 + 拆分

```
Phase 0 (用户做)        : 45 min (含 Dockerfile build)
Phase 1 pipeline.py     : 1 day  (COS upload + cmd_validate https-only + dotenv + orphan_scan default)
Phase 2 server cleanup  : 0.5 day (transform helper / staging route / isProdEnv / e2e trim)
Phase 3 mobile β + PR-B5: 1 day  (api_base.dart + 4 service + 移 kDebugMode + 测试)
Phase 4 sub-smoke + PR  : 0.5 day (真机 A-F + PR description + README)
─────────────────────────────────
合计                    : 3 day (我做) + 45 min (你做)
```

v0.1 估 2d + S1=β 1d = 3d。**PR-B3 估时 2.5d 实际 3d；PR-B4 估时 1d 实际 0.5d；PR-C 估时 3d 含买余量。**

---

## 5. 风险

| 风险 | 缓解 |
|---|---|
| Phase 0 Dockerfile build 失败（pacakge.json / tsc 配置 quirks） | plan §"Phase 0 §0.0" 给完整 multi-stage 模板；如失败可 fallback 用 single-stage `node:20` 镜像 |
| nginxproxy/acme-companion 自动 cert 失败（DNS 没 propagate / 80 端口被占）| plan §"Phase 0 §0.2" 列 troubleshooting：等 DNS 5min + 验 80 端口 + 看 acme-companion logs |
| 腾讯云 COS public-read 包文件被恶意 GET 浪费流量 | 流量计费 ¥0.5/GB；早期可接受；用户量起加 hotlink protection（COS 控制台一键）|
| boto3 调 COS endpoint_url 兼容性 | COS 文档支持 S3 API；常见 put_object/list_objects 100% 兼容；plan §"Phase 1" 加 try/except 友好错误 |
| `pipeline.py` 加 boto3 + dotenv 影响 dev 环境 | dev 在开发机本地，pip 安装即可；不影响 server docker（pipeline.py 不进 server 容器）|
| **β 4 service 改动破坏 widget test / unit test 既有 mock** | recon 实测：`ManifestClient` / `ApiClient` 已支持 named param 注入（test 不受影响）；`ExampleAudioService` / `PronunciationService` 改 `static const → final` 后既有调用 `XxxService()` 仍 work（named optional default fallback `apiV1Base`）；**单独跑 baseline test 验证零退化** |
| **release build 忘传 `--dart-define=API_BASE=...`** | `apiV1Base` fallback `http://10.0.2.2:3000/api/v1` → release 用户启动后 manifest + audio + api + pronunciation 全部 timeout（不是 silent failure；4 处一起撞而非 1 处）；sub-smoke A + F 必跑都会撞；README 强调 release build 命令 |
| 移 kDebugMode guard 后 release 用户首次启动多 1 次 manifest API call | sync 是 fire-and-forget unawaited；不阻塞 UI；hasFailure 静默 |
| β `ExampleAudioService` / `PronunciationService` `static const → final` 改动 | 仅签名改；既有 `XxxService()` 调用方零改动（named optional default fallback）；现有 service consumer 也不需要改 |
| sub-smoke F 真机验 audio/api 真域名连通失败 | 阻塞 PR-C 提交；β 一刀切的代价就是 sub-smoke 必须验全链路；如真机失败回头看 nginx-proxy / acme-companion / DNS / dart-define 配置 |
| 删除 server `/cdn/staging` route 后 dev 本地无 fallback | dev 本机 pipeline.py 也走 COS 真上传；如需纯离线 dev 可临时 git revert main.ts 改动 |
| `.env` SecretId/SecretKey 误 commit | `.gitignore` 已忽略 `.env`；plan 强调用 `.env.example` 占位（不含真凭据）|
| **`cmd_validate` Step 5 改写后 file:// 路径回归** | 加 1 unit test 覆盖 file:// 仍走原校验 + https 跳过校验；e2e 既有 cases 也覆盖 |
| **idempotent re-publish 重排逻辑误改 conflict 路径** | recon publish_manifest 现有 line 190-198 conflict 检查保留；只把 _upload_to_cos 移到 conflict check **之后**；e2e + manual smoke 双覆盖 |
| **orphan_scan default 改 'audio' break PR-B1 既有 cron** | 用户当前无 cron；plan README 明示 break change + `--scope all` 可恢复旧行为 |

---

## 6. 提交策略

单 PR `feat/v0.3-pr-c-cos-and-prb5` → main，按 phase 拆 commit（沿用 PR-B3 风格便于 git bisect）：

```
docs(v0.3-pr-c): scope v0.1 + plan v0.1
docs(v0.3-pr-c): scope v0.2 + plan v0.2 (吸收三份评审 24 处 + S1=β + R2#7 acme-companion + R3 P1/P2)
feat(v0.3-pr-c): Phase 0 — Dockerfile multi-stage
feat(v0.3-pr-c): Phase 1 — pipeline.py COS upload + cmd_validate https-only + dotenv + orphan_scan default
feat(v0.3-pr-c): Phase 2 — server cleanup (transform helper / staging route / e2e trim)
feat(v0.3-pr-c): Phase 3 — mobile S1=β (api_base.dart + 4 service) + PR-B5 (移 kDebugMode)
feat(v0.3-pr-c): Phase 4 — README + sub-smoke A-F 验收
Merge feat/v0.3-pr-c-cos-and-prb5 — v0.3 PR-C COS + PR-B5 + S1=β (~3d)
```

---

## 7. 验收清单（PR-C 总）

### Server / pipeline / Phase 0

- [ ] Phase 0 Dockerfile build 成功（`docker images | grep meow-api`）
- [ ] 域名 + HTTPS + COS bucket 完成（`curl https://api.<domain>/api/v1/content/manifest` 200）
- [ ] `pipeline.py publish-manifest` 上传到 COS + 写 https URL（manual smoke + idempotent re-run 零网络 cost）
- [ ] **`pipeline.py validate` 接受 https URL**（跳过本地校验；file:// 路径回归未破）
- [ ] `pipeline.py orphan-scan`（无参数）默认仅扫 cdn-mock；`--scope all` 仍含 staging
- [ ] PG `content_manifest.file_url` 是 `https://<bucket>.cos.ap-shanghai.myqcloud.com/...`
- [ ] manifest API（dev / production 都 OK）返非空 packages，含 https URL（pass-through）
- [ ] e2e ~48 cases pass + 1 baseline `/me/today` fail

### Mobile / Phase 3 / S1=β

- [ ] `apps/mobile/lib/core/config/api_base.dart` 新建（const `apiV1Base` + dartdoc + dart-define release build 命令说明）
- [ ] **4 个 service 全切到 `apiV1Base`**：
  - [ ] `ManifestClient.baseUrl` default → `apiV1Base`（既有 named param 保留）
  - [ ] `ApiClient.baseUrl` default → `apiV1Base`（既有 named param 保留）
  - [ ] `ExampleAudioService._baseUrl`：`static const → final` + `{String? baseUrl}` named optional + `?? apiV1Base`
  - [ ] `PronunciationService._baseUrl`：同上
- [ ] dev/emulator/test 默认行为不变（`flutter test` 1202/1202 全过；fallback `http://10.0.2.2:3000/api/v1`）
- [ ] release build 用 `--dart-define=API_BASE=https://api.<domain>/api/v1` 后 4 service 全连真域名
- [ ] flutter analyze 0 new issues
- [ ] PR-B5: release build 启动也跑 sync（移 kDebugMode guard 验证）
- [ ] PR-B5: release build settings 页能看到 SwitchListTile（移 kDebugMode 包裹）
- [ ] PR-B5: settings_page `flutter/foundation` import 已删（unused_import 不报）

### Sub-smoke A-F（真机）

- [ ] **A**: release build (`flutter build apk --release --dart-define=...`) → 启动 → adb logcat 见 manifest sync log（PR-B5 验证）
- [ ] **B**: release build settings 页能看到 SwitchListTile（kDebugMode 包裹已移）
- [ ] **C**: release build flag=false 重启 → 无 sync log（用户 opt-out 仍生效）
- [ ] **D**: dev build bundle v3 + manifest sync → 改 bundle v4 → 重启 → manifest 数据保留（D1 收口真机回归）
- [ ] **E**: full E2E: dev API → COS https URL → DownloadManager → drift readback（curl + adb logcat + sqlite 验证）
- [ ] **F (β 关键)**: release build → 点播放例句音频 + 取题目 + 听单词发音 → 全连 production 真域名（β 兑现"全链路可用"必跑）

### 文档 / PR

- [ ] README PR-C 章节（COS 接入 + dotenv + orphan-scan break change + dart-define release build 命令 + S1=β 决策说明）
- [ ] PR_DESCRIPTION_PR-C.md 写到 user dir（11 章 + S1=β 决策段 + sub-smoke F 验证段）

---

## 8. v0.3 完成后的下一轮（PR-C 之后候选）

| 优先级 | 候选 | 触发 |
|---|---|---|
| 中 | 观测性埋点（v0.4 §7.3）| 用户量起 / PR-B5 long-term 删 flag 触发条件 metrics |
| 低 | 审批 Web UI（v0.4 §7.2）| 多人协作 |
| 低 | 性能（v0.4 §7.4）| 流量起 |
| 低 | Tombstone（v0.4 §7.3 + D5）| 操作员真要删 stable_id |
| 低 | audio file 也接 COS | 真 CDN 替换 cdn-mock；当前 audio file 仍 hardcode 走 cdn-mock |
| 低 | multi-env (staging vs production) | 用 build flavor + 多套 dart-define API_BASE |

---

## 附录 A: scope vs v0.4 §7.1 对照

v0.4 §7.1 写的"真 CDN 接入"原文：
> - 触发：用户买真 CDN
> - 范围：替换 cdn-mock URL；publish-manifest 改成上传到 CDN
> - 不动 ContentPackageService（HTTP URL 透明）

PR-C scope v0.2 实际：
- 触发：✅ 用户已有腾讯云 COS（等价于"真 HTTP 存储"）
- 范围：✅ pipeline.py 改写 https URL；server controller 删 transform / staging route；合并 PR-B5；**S1=β 一并环境化 mobile 4 service**
- 不动：✅ ContentPackageService / DownloadManager / PackageInstaller / WordbookLoader / drift / pubspec

S1=β 是 v0.4 §7.1 没明示但 PR-B5 触发后必须做的"全链路收口"——v0.2 加进 PR-C 范围一次到位。**PR-D 不再承担 mobile baseUrl 重构**（β 已合并）。

---

## 附录 B: v0.1 → v0.2 修订汇总（按 plan 段落）

| plan 段 | v0.1 | v0.2 |
|---|---|---|
| Phase 0 §0.0 | （无）| Dockerfile + `docker build` step（R1#2）|
| Phase 0 §0.2 | 自写 docker-compose nginx + certbot + nginx.conf 模板 | 改用 `nginxproxy/nginx-proxy` + `nginxproxy/acme-companion` 镜像（R1#8 R2#7；自带 reload）|
| Phase 0 §0.3 | nginx.conf.bootstrap 临时配置 + standalone 双方案 | 删（acme-companion 自带）|
| Phase 1 step 1.1 | requirements.txt + boto3 | + python-dotenv（R2#4）|
| Phase 1 step 1.2 | `_cos_client()` singleton | 去 singleton（R1#5）|
| Phase 1 step 1.X | （无）| **加 cmd_validate Step 5 https 跳过校验 + 1 unit test**（R1#1）|
| Phase 1 step 1.X | （无）| `pipeline.py` 顶部 `load_dotenv(Path(__file__).parent / '.env')`（R2#4）|
| Phase 1 step 1.3 | 先 `_upload_to_cos` 再查 PG conflict | **重排：先拼 expected_url + 查 PG idempotent → 仅真 INSERT 时 upload**（R1#3）|
| Phase 1 step 1.3 | cos_key `.suffix + fallback if .gz` | 全 `"".join(file_path.suffixes)`（R1#6）|
| Phase 1 step 1.3 | `_upload_to_cos` 无 try/except 无 ContentLength | 加 `try/except ClientError` + ContentLength + mimetypes ContentType（R1#7 R1#11）|
| Phase 1 step 1.X | （无）| `orphan_scan.py` argparse `--scope` default `'all'` → `'audio'`（R1#4）|
| Phase 1 step 1.5 README | 不含 PR-B5 / β | + dart-define release build 命令 + orphan-scan break change（R1#10 R2#5）|
| Phase 2 step 2.1 | 删 transform + 注 isProd 保留 | 同步删 `const isProdEnv` 声明（R1#13）|
| Phase 2 step 2.3 | e2e ~47 cases | ~48 cases（R1#9）|
| Phase 3 (新) | （v0.1 无 mobile baseUrl step）| **加 step 3.0：`api_base.dart` 新文件 + 4 service 全替换**（S1=β）|
| Phase 3 step 3.2 | 删 `if (kDebugMode)` SwitchListTile | + 同步删 `flutter/foundation` import（R2#6）|
| Phase 4 sub-smoke | A-E 5 步 | A-E + **F：release build 验 audio/api 真域名**（β 兑现"全链路可用"必跑）|
| R3 P1 (新) | （v0.1 .env 用 PG\* 散乱 env）| `.env` 改用 `DATABASE_URL=postgresql://...`（pipeline.py 仅读 `DATABASE_URL`）|
| R3 P1 (新) | orphan-scan choices `[audio,staging,all]` | 改 `[audio,packages,all]`（实际 `orphan_scan.py` line 216 只接受这 3 个）|
| R3 P2 (新) | validate 接受 https \|\| http | 仅接 https（不接 http://）+ legacy file://；production 不应放行 plain http |
| 全文 | recon 行号 99/178/53/235 | 119/220/63/263（R1#10）|
| Phase 1 smoke | `--package-name test-prc-examples` | `examples-test-prc`（R2#5；naming convention）|
| §C5 注 | （无）| SSH tunnel 注解（R1#12）|

24 处去重修订（R1 13 + R2 7 + R3 4）全部映射到 plan v0.2 具体 step。
