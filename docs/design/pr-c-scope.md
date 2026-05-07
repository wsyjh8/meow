# PR-C scope · 真 CDN 接入（腾讯云 COS）+ PR-B5 release default-on（合并）

- **Date**: 2026-05-07
- **Status**: scope v0.1（plan v0.1 同步初稿；待用户 review）
- **基线 commit**: `5392032`（PR-B4 merge 进 main）
- **工作分支**: `feat/v0.3-pr-c-cos-and-prb5`
- **worktree**: `D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-c`
- **关系**: 延伸 `v0.3_PR-B_scope_v0.4.md` §7.1（PR-C 候选；v0.4 SSOT 标记 "v0.3 之外按需触发"），不替换 v0.4 主线。

---

## 0. 目标 + 不目标

### 0.1 目标

1. **真 CDN 接入** — `pipeline.py` 把 manifest 包上传到腾讯云 COS（上海 region，public-read），写 https URL 到 PG `content_manifest.file_url`。
2. **release 用户也能用 manifest sync** — 移除 PR-B3 的 `kDebugMode` guard（合并的 PR-B5），让 default flag=true 在 release/profile build 也生效。
3. **零外部 PR 阻塞** — 同 PR 内完成 1+2，单 commit 集合（沿用 PR-B3 模式：plan v0.1 → 评审 → v0.2 → 实施 commit）。

### 0.2 不目标

- ❌ 真 Cloudflare/AWS CDN 接入（boto3 选型已铺路 future swap，但 v0.3 不做）
- ❌ presigned URL（v0.3 走 public-read 简化）
- ❌ ETag / Range / multi-codec 下载优化（用户量起来再做；v0.4 §7.4 候选）
- ❌ 改 ContentPackageService / PackageInstaller / DownloadManager / WordbookLoader（PR-B2/B3 稳定）
- ❌ 改 drift schema / pubspec 新依赖（mobile 0 改动）
- ❌ Tombstone / status='deleted' 路径（v0.4 §7.3 留位，v0.3 不做）

---

## 1. 5 个 scope 决策（用户拍板，2026-05-07）

| # | 决策 | 理由 |
|---|---|---|
| **C1** | 真 CDN = **腾讯云 COS**（上海 region，public-read） | 用户已有腾讯云账号 / 国内用户 / 公网无鉴权访问最简单 / 包文件本身是公开二进制 |
| **C2** | HTTPS = **自购域名 + nginx + Let's Encrypt** | docker-compose 已有 nginx → 加 5 行 + certbot sidecar / 域名 ¥9-50/年 / 完全自有 |
| **C3** | COS SDK = **boto3 with `endpoint_url`**（COS 兼容 S3 API）| 未来切真 S3 / Cloudflare R2 不用改代码 / 包大小可接受 / `cos-python-sdk-v5` 后期可切 |
| **C4** | PR-C 与 PR-B5 **合并单 PR** | PR-B5 改动小（移 2 处 `kDebugMode` guard）+ 强依赖 PR-C 完成（否则 release 跑空 sync）/ 同 PR 一次到位 |
| **C5** | `pipeline.py` 部署 = **开发机本地脚本** | MVP 不进 docker；后期再做 one-shot tools container |

---

## 2. 关系图（v0.4 SSOT 路线图升级）

```
v0.4 SSOT (已完成):
  PR-A   ✅ server 发布闭环           (b072eb3)
  PR-B1  ✅ server 治理补完            (b26bff7)
  PR-B2  ✅ mobile 基建 (不切流量)     (7058387)
  PR-B3  ✅ feature flag + D1 + staging (5e063dc)
  PR-B4  ✅ default flag → true        (5392032)

PR-C (本 scope, v0.4 §7.1 兑现):
  Phase 0 (用户做)   buy domain + nginx HTTPS + COS bucket public-read
  Phase 1 (代码)     pipeline.py 接 COS + 写 https URL
  Phase 2 (代码)     server cleanup (删 transform helper / staging route)
  Phase 3 (代码)     合并 PR-B5: 移 kDebugMode guard
  Phase 4 (验收)     sub-smoke A-E 真机 + PR description

不做 (v0.3 之外, 按需触发):
  v0.4 §7.2  审批 Web UI       (多人协作时)
  v0.4 §7.3  观测性 / Tombstone (用户量起 / 操作员真要删)
  v0.4 §7.4  性能 (ETag / 分页) (流量起来)
```

---

## 3. 改动清单（zero out-of-scope confidence）

### 3.1 用户操作（Phase 0，~30 分钟）

| 项 | 输出 |
|---|---|
| 注册 .top/.xyz 域名 | `<your-domain>` |
| DNS A 记录 → server IP | `api.<your-domain>` resolves |
| Docker Compose: nginx + certbot sidecar 配置 | 我提供完整模板（plan §"Phase 0 模板"）|
| 验证: `https://api.<your-domain>/api/v1/content/manifest` 200 | curl |
| 腾讯云 COS bucket 创建（如未创建）| `<bucket-name>` (e.g. `meow-content-mvp-1234567890`) |
| Bucket ACL 设 public-read | 控制台一键 |
| 生成 SecretId/SecretKey（CAM 子账号建议，权限仅限本 bucket）| pipeline.py 用 |

### 3.2 代码改动（Phase 1-3）

#### server (apps/api/)

| 文件 | 改动 |
|---|---|
| `apps/api/src/main.ts` | **删** Day 1 加的 `/cdn/staging` static route 整段（10 行） |
| `apps/api/src/controllers/content-manifest.controller.ts` | **删** `transformFileUrlForDev` helper + 调用（30 行）；https URL 透明 pass-through，无需 transform |
| `apps/api/test/pg-regression.e2e-spec.ts` | **删** Day 1 加的 PR-B3 dev URL transform / production guard 2 个 describe 块（150 行）；改加 1 个 case 验证 https URL 透传 |

#### pipeline (apps/api/scripts/content_pipeline/)

| 文件 | 改动 |
|---|---|
| `requirements.txt`（如无则新建）| `+ boto3>=1.34.0`（COS S3 兼容）|
| `pipeline.py` | + `_cos_client()` helper / + `_upload_to_cos(file_path, key)` / 改 `publish-manifest` 子命令：上传 + 写 https URL（~80 行）|
| `.env.example` | + `COS_*` 7 个 env var（plan 详）|
| `README.md` | + PR-C 章节（COS 接入说明）|

#### mobile (apps/mobile/)

| 文件 | 改动 |
|---|---|
| `lib/main.dart` | **PR-B5**: 删 `if (!kDebugMode) return;`（hook helper Layer 1 guard）|
| `lib/features/settings/settings_page.dart` | **PR-B5**: 删 `if (kDebugMode)` 包裹 SwitchListTile；release 也可见 |
| `test/main_manifest_sync_hook_test.dart` | 测试 expect：原 "test 环境 = debug build" 假设不变（kDebugMode 在 test 还是 true），仅注释更新 |

### 3.3 不动（zero diff vs 5392032）

- `apps/mobile/lib/core/manifest/`（PR-B2 稳定）
- `apps/mobile/lib/core/memory/wordbook_loader.dart`（PR-B3 Day 2 稳定）
- `apps/mobile/lib/core/storage/local_settings_service.dart`（PR-B4 稳定）
- `apps/mobile/lib/core/storage/drift/`（schema 不变）
- `apps/mobile/pubspec.yaml`（零新依赖）
- `apps/api/src/infrastructure/`（PG 层不动）
- `apps/api/src/middleware/`（middleware 不动）
- 任何其它 mobile / server / migration 文件

---

## 4. 估时 + 拆分

```
Phase 0 (用户做)        : 30 min
Phase 1 PR-C 代码       : 1 day (pipeline.py 接 COS + server cleanup)
Phase 2 PR-B5 (合并)    : 0.5 day (移 kDebugMode guard + 测试)
Phase 3 sub-smoke + PR  : 0.5 day (真机 A-E + PR description)
─────────────────────────────────
合计                    : 2 day (我做) + 30 min (你做)
```

PR-B3 估时 2.5d 实际 3d；PR-B4 估时 1d 实际 0.5d。**PR-C 估时 2d 含买余量**。

---

## 5. 风险

| 风险 | 缓解 |
|---|---|
| Phase 0 用户买域名 + nginx HTTPS 卡住 → 阻塞 Phase 1+ | plan §"Phase 0 模板" 提供完整 docker-compose / nginx.conf / certbot 一行启动 |
| 腾讯云 COS public-read 风险（包文件被任意 GET）| **接受**：包是公开二进制（content-addressable + content_version 路径，无 PII）；与 CDN 接入后行为一致 |
| boto3 调 COS 的 endpoint_url 兼容性问题 | COS 官方文档支持 S3 API；常见 list/put/get 操作 100% 兼容 |
| `pipeline.py` 加新依赖（boto3）影响 dev 环境 | dev 在开发机本地，pip 安装即可；不影响 server docker |
| 移 kDebugMode guard 后 release 用户首次启动多 1 次 manifest API call | sync 是 fire-and-forget unawaited；不阻塞 UI；hasFailure 静默 |
| sub-smoke E 真机回归没跑过（PR-B3/B4 也没跑过）| Phase 3 强制必跑；阻塞 PR-C 提交 |
| 删除 server `/cdn/staging` route 后 dev 本地测无 fallback | dev 本机 pipeline.py 也走 COS 真上传；或保留 route 仅 dev mode (decision 留给 plan) |
| `.env` SecretId/SecretKey 误 commit | `.gitignore` 已忽略 `.env`；plan 强调用 `.env.example` 占位 |
| PR-B5 移 kDebugMode 后，flutter test 中 fakeService 的 PackageInfo 0.0.1 仍 OK | test 环境 kDebugMode 仍是 true（debug build）；仅 release/profile build 行为变；unit test 无影响 |

---

## 6. 提交策略

单 PR `feat/v0.3-pr-c-cos-and-prb5` → main，沿用 PR-B3 模式：

```
docs(v0.3-pr-c): scope v0.1 + plan v0.1
docs(v0.3-pr-c): scope v0.1 → v0.2 (吸收评审 N 处) — 如有
feat(v0.3-pr-c): Phase 1 — pipeline.py COS upload + server cleanup
feat(v0.3-pr-c): Phase 2 — PR-B5 merge: 移 kDebugMode guard + release default-on
feat(v0.3-pr-c): Phase 3 — README + sub-smoke 验收
Merge feat/v0.3-pr-c-cos-and-prb5 — v0.3 PR-C COS 接入 + PR-B5 (~2d)
```

或单 commit（合并 Phase 1-3）— 看评审需要多细的拆分。

---

## 7. 验收清单（PR-C 总）

- [ ] Phase 0 用户操作完成（域名 + HTTPS + COS bucket）
- [ ] `pipeline.py publish-manifest` 上传到 COS + 写 https URL
- [ ] PG `content_manifest.file_url` 是 `https://<bucket>.cos.ap-shanghai.myqcloud.com/...`
- [ ] manifest API（dev / production 都 OK）返非空 packages，含 https URL
- [ ] mobile DownloadManager 能 HTTP GET COS URL 拉到包（curl + adb logcat 验证）
- [ ] release build 启动也跑 sync（移 kDebugMode guard 验证）
- [ ] release build settings 页能看到 SwitchListTile（仍可关）
- [ ] flutter analyze 0 new issues
- [ ] flutter test 1202/1202 全过（baseline 不退化）
- [ ] e2e suite 通过（Day 1 删的 case 已 trim，新 case 验证 https URL 透传）
- [ ] sub-smoke A-E 真机全过（含 D1 收口 + 真 CDN E2E + release default-on）
- [ ] README PR-C 章节
- [ ] PR_DESCRIPTION_PR-C.md 写到 user dir

---

## 8. v0.3 完成后的下一轮（PR-C 之后候选）

| 优先级 | 候选 | 触发 |
|---|---|---|
| 中 | 观测性埋点（v0.4 §7.3）| 用户量起 / PR-B5 long-term 删 flag 触发条件 metrics |
| 低 | 审批 Web UI（v0.4 §7.2）| 多人协作 |
| 低 | 性能（v0.4 §7.4）| 流量起 |
| 低 | Tombstone（v0.4 §7.3 + D5）| 操作员真要删 stable_id |

---

## 附录 A: scope vs v0.4 §7.1 对照

v0.4 §7.1 写的"真 CDN 接入"原文：
> - 触发：用户买真 CDN
> - 范围：替换 cdn-mock URL；publish-manifest 改成上传到 CDN
> - 不动 ContentPackageService（HTTP URL 透明）

PR-C scope 实际：
- 触发：✅ 用户已有腾讯云 COS（虽然不是"真 CDN"，但等价于"真 HTTP 存储"）
- 范围：✅ pipeline.py 改写 https URL；server controller 删 transform / staging route；合并 PR-B5
- 不动：✅ ContentPackageService / DownloadManager / PackageInstaller / WordbookLoader / drift / pubspec

