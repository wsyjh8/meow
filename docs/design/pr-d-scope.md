# PR-D scope v0.2 · audio mp3 + pronunciation wav 接 COS（Option A，全 CDN 化）

- **Date**: 2026-05-07
- **Status**: scope v0.2 — 用户拍板 **D1 = Option A**（全 COS，audio + pronunciation 都迁）+ **D2 = a**（pronunciation controller 改 302 redirect，mobile 0 改动）；plan v0.2 同步；取代 v0.1（v0.1 主张 Option B 已被否决）
- **基线 commit**: PR-C merged @ `ec095ea`（main）；PR-D 从 `2a3cbeb` 开，可直接基于新 main rebase
- **工作分支**: `feat/v0.3-pr-d-audio-asset-ingest-cos`
- **关系**: 闭合 `pr-c-scope.md` v0.3 §0.5.1 caveat 列出的"release 仍不能"3 条

---

## 0. v0.1 → v0.2 修订（用户决策点 D1 + D2）

| # | 决策 | v0.1 | v0.2 |
|---|---|---|---|
| **D1** | audio + pronunciation 接 CDN 路径 | Option B 推荐（server volume mount） | **Option A 拍板**（全 COS）|
| **D2** | pronunciation API 形态 | 未提（B 模式下 controller 不动） | **a: server-side 302 redirect 到 COS URL**（mobile 0 改动）|

### 0.1 D1=A 选择理由

用户拍板 Option A。优于 B/C 的论据：

- **release 流量不在 app server**：audio + pronunciation 都走 COS public-read URL，
  app server 只承担 metadata API + 业务接口；带宽永远不会成为 server 瓶颈
- **未来真接 CDN 边缘节点零成本**：腾讯云 COS 之前可叠加腾讯云 CDN（改 DNS / `Cache-Control` 即可），不需再迁数据
- **server 磁盘解耦**：app server 不再依赖 `cdn-mock/` 和 `data/pronunciation/`
  目录存在；server 容器纯粹无状态（PG 是唯一有状态依赖）
- **架构一致性**：与 manifest pipeline（PR-C 已接 COS）模式对齐；PG 仅存 url，
  实际 bytes 在 COS，是云原生最佳实践
- 接受代价：实施范围比 Option B 多 ~1.5d（一次性大批量上传 + 重 ingest）

放弃 B/C 理由：

- **B（server volume mount）**：流量都在 app server，扩容受限；docker-compose
  耦合宿主目录；未来切真 CDN 仍需第二次迁移（这次工作白做大半）
- **C（混合）**：audio 接 COS / pronunciation 留 server 不一致；pronunciation
  数据量也不小（几万 wav），最终一致性更优是全 COS

### 0.2 D2=a 选择理由（pronunciation API 形态）

用户拍板 D2=a：pronunciation controller 改成 302 redirect 到 COS URL。

| 选项 | 描述 | mobile 改动 | server 改动 | 优 / 劣 |
|---|---|---|---|---|
| **(a)** | controller 返 302 redirect → COS URL | **0**（http package 默认 follow redirect）| 改 ~30 行（删 fs.readFile，加 res.redirect）| ⭐ 推荐：mobile 不动 / API 形态保 / 未来切 CDN 改 redirect target 即可 |
| (b) | controller 删，mobile `PronunciationService` 直拼 COS URL | 重构（baseUrl + path 模板嵌入 client） | 删 controller | mobile 改动多；URL pattern 嵌客户端难升级 |
| (c) | controller 改 metadata API（先返 url，client GET COS）| 重构（先调 metadata API 拿 url，再 GET COS 同 ExampleAudioService 模式） | 改 controller + 加 PG 表（pronunciation_assets）| 一致性最强但范围爆炸（新表 / 新 schema migration），不值得 |

(a) 折中最佳：mobile 不动 + API URL 形态保（client 仍调 `/api/v1/pronunciation/<word>`）+ server 仅一次性 redirect 流量微不足道。

---

## 1. 6 个 scope 决策

| # | 决策 | 理由 |
|---|---|---|
| **D1** | audio + pronunciation 接 **腾讯云 COS**（同 manifest pipeline）| §0.1 |
| **D2** | pronunciation controller = **302 redirect to COS URL**；mobile 0 改动 | §0.2 |
| **D3** | COS 路径 layout 沿用现有 fs layout（兼容性好）| audio: `audio/v1/{kind}s/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3`；pronunciation: `pronunciation/{locale}/{voice}/v1/{firstLetter}/{word}.wav` |
| **D4** | 一次性 bootstrap = **新 ts 工具同步 dev fs → COS**；不动 `partial_publish.py` | partial_publish 仍写 `local://cdn/...` placeholder + 写 cdn-mock dir（dev 仍 work）；新 sync 工具一次性把 cdn-mock + data/pronunciation 推 COS；ingest cdnOrigin 改 COS public-base |
| **D5** | server `/cdn` static route **删除** | Option A 不再需要 server-side 静态文件；`apps/api/cdn-mock/` 在 repo 仅 `.gitkeep` 也可删（or 留 .gitkeep 防 git 追踪丢失）|
| **D6** | release 端 SwitchListTile 文案 / kDebugMode 不动 | PR-C/PR-B5 已处理 |

---

## 2. 关系图（v0.4 SSOT 路线图升级）

```
v0.4 SSOT (已完成):
  PR-A   ✅ server 发布闭环           (b072eb3)
  PR-B1  ✅ server 治理补完            (b26bff7)
  PR-B2  ✅ mobile 基建 (不切流量)     (7058387)
  PR-B3  ✅ feature flag + D1 + staging (5e063dc)
  PR-B4  ✅ default flag → true        (5392032)
  PR-C   ✅ COS manifest + S1=β + PR-B5 (ec095ea)

PR-D (本 scope, 闭合 PR-C R4-2/R4-3):
  Phase 0 (用户做)  COS bucket prefix 准备 + 一次性同步 cdn-mock/data 到 COS +
                   重 ingest audio_assets.url + 部署新 server image
  Phase 1 (代码)    新工具: sync-audio-mp3-to-cos.ts +
                   sync-pronunciation-to-cos.ts + repipe-audio-urls.ts
                   (3 个 ts one-shot 工具)
  Phase 2 (代码)    pronunciation.controller.ts 改 302 redirect;
                   ingest-audio-assets.ts cdnOrigin default 改 env;
                   main.ts 删 /cdn static route
  Phase 3 (代码)    .env.example + README + PR_DESCRIPTION; e2e 加 1 case
                   (pronunciation redirect 验证)
  Phase 4 (验收)    sub-smoke F1-F4 真机 (PR-C 时 F3/F4 expected fail,
                   PR-D 后应全 PASS)

PR-E 候选 (PR-D 之后, 按需触发):
  - 接真 CDN (腾讯云 CDN over COS;改 COS 防盗链 + DNS)
  - 观测性埋点
  - 多 region / multi-bucket
```

---

## 3. 改动清单（基于 D1=A + D2=a）

### 3.1 用户操作（Phase 0，~1-1.5 hr）

| 项 | 输出 |
|---|---|
| 估算 cdn-mock/ + data/pronunciation/ 大小 (`du -sh`) | 决定上传带宽预估 |
| COS bucket prefix 准备：`audio/v1/...` + `pronunciation/...` 两个目录（按 layout 自动）| bucket 已 public-read（PR-C 时建好）|
| 跑 `sync-audio-mp3-to-cos.ts` 一次性同步 cdn-mock 到 COS | dev 机本地，~10-30 min depending on 文件数 |
| 跑 `sync-pronunciation-to-cos.ts` 一次性同步 data/pronunciation 到 COS | dev 机本地 |
| 跑 `repipe-audio-urls.ts` 重写 PG `audio_assets.url`（dry-run + commit）| 替换 emulator host → COS public URL |
| `docker-compose.yml` **删除** v0.1 plan 提到的 cdn-mock + data/pronunciation volumes（如已配 Option B 需回滚）| Option A 不需 mount |
| 部署新 NestJS image（含 pronunciation 302 redirect + 删 `/cdn` static route）| `docker compose up -d --force-recreate api` |
| 验证 `curl https://api.<your-domain>/api/v1/pronunciation/abandon?locale=en-US&voice=am_michael` 返 302 + Location: COS URL | 不再 200 直接 stream wav |
| 验证 `curl <COS URL>` 直接返 wav 200 | 跳过 server |

### 3.2 代码改动（Phase 1-3）

#### server (apps/api/)

| 文件 | 改动 |
|---|---|
| **(新)** `apps/api/scripts/sync-audio-mp3-to-cos.ts` | one-shot 工具：扫 `cdn-mock/audio/v1/...` 全部 mp3，上传到 COS（public-read，Cache-Control immutable）；增量同步（COS HEAD 检查 ETag → skip if same checksum）；dry-run + commit 双模 |
| **(新)** `apps/api/scripts/sync-pronunciation-to-cos.ts` | 同上但扫 `data/pronunciation/{locale}/{voice}/v1/...` |
| **(新)** `apps/api/scripts/repipe-audio-urls.ts` | one-shot 工具：扫 PG `audio_assets`，把 url 字段从 `<from-prefix>/...` 重写为 `<to-prefix>/...`；dry-run + commit；事务内（同 v0.1 plan 相同设计）|
| `apps/api/scripts/ingest-audio-assets.ts` | `cdnOrigin` default 改 `process.env.AUDIO_CDN_ORIGIN \|\| 'http://10.0.2.2:3000/cdn'`（back-compat 不破 dev）|
| `apps/api/src/controllers/pronunciation.controller.ts` | 重写：删 `dataDir` + `fs.readFile` + `StreamableFile`；改 `@Get` 返 `HttpException(302)` with `Location: <COS URL>`；word/locale/voice 校验保留（fail-fast 400 仍在）|
| `apps/api/src/main.ts` | 删 `/cdn` cdn-mock useStaticAssets 整段（~10 行）|
| `apps/api/test/pg-regression.e2e-spec.ts` | 加 1 case 验证 pronunciation 返 302 + Location header |
| `apps/api/.env.example` | + `AUDIO_CDN_ORIGIN=https://<bucket>.cos.<region>.myqcloud.com` + `PRONUNCIATION_CDN_ORIGIN=...` 同 |
| `apps/api/scripts/content_pipeline/README.md` | + PR-D Option A 章节（D1/D2 决策 + sync 工具用法 + repipe 流程）|

#### mobile (apps/mobile/)

**0 改动**（Option A + D2=a 关键好处）：
- `PronunciationService`：http package 默认 follow 302 redirect；client 透明
- `ExampleAudioService`：已经走 metadata API 拿 url；PG 重 ingest 后 url 自动指向 COS
- `ApiClient` / `ManifestClient`：PR-C β 已切 baseUrl，无关
- 4 service apiV1Base 不动

#### 不动（zero diff vs PR-C head）

- `apps/api/src/controllers/audio-assets.controller.ts`（继续 SELECT FROM audio_assets pass-through）
- `apps/api/src/controllers/content-manifest.controller.ts`（PR-C 稳定）
- `apps/api/scripts/audio_pipeline/partial_publish.py`（仍写 `local://cdn/...` placeholder + 写 cdn-mock dir for dev）
- `apps/api/scripts/content_pipeline/pipeline.py`（manifest pipeline 已稳定）
- `apps/api/cdn-mock/.gitkeep`（保留；防 git 追踪丢失）
- `apps/api/data/pronunciation/`（仍 .gitignore；dev 机本地保留）
- `apps/api/Dockerfile`（PR-C 已加；Option A 不需 COPY 资产）
- `docker-compose.yml`（用户操作；plan 不进 repo；如用户 v0.1 plan 时尝试加了 volumes，Option A 需 **删除** volumes mount）
- 所有 mobile 文件
- drift schema / pubspec
- migrations / 任何 PG schema

---

## 4. 估时 + 拆分

```
Phase 0 (用户做)        : 1-1.5 hr (sync 上传 + repipe + 部署 + 验证)
Phase 1 sync + repipe   : 1d   (3 个 ts 工具 + dotenv 对齐)
Phase 2 controller 改   : 0.5d (pronunciation controller redirect + main.ts 删 /cdn)
Phase 3 README + e2e    : 0.5d (e2e 加 1 case + README 加 PR-D 章节 + PR description)
Phase 4 sub-smoke 真机  : 30 min (F1-F4 全过)
─────────────────────────────────
合计                    : 2 day (我做) + 1.5 hr (你做)
```

带 buffer 估 2.5d（Option B 是 1d，Option A 多 1.5d 主要在 sync 工具 + pronunciation controller 重写）。

---

## 5. 风险

| 风险 | 缓解 |
|---|---|
| sync 工具上传失败（网络中断 / COS API 限流）| 每个工具支持增量（HEAD 检查 ETag → skip same content）；中断重跑幂等 |
| sync 上传量大（cdn-mock + data/pronunciation 几 GB）| dev 机后台跑；`du -sh` 先估算 |
| `repipe-audio-urls.ts` 误改 PG | 默认 dry-run；commit 必须显式 `--commit`；事务 BEGIN/UPDATE/COMMIT；prefix LIKE 匹配（精确）|
| pronunciation 302 redirect 客户端不 follow | http package 默认 maxRedirects=5；audio_players UrlSource 走 system http stack 也 follow；测试 (a) flutter `http.get` 验证 + (b) audioplayers 真机播放验证 |
| 客户端 cache 旧 url（已下载 mp3 缓存命中）| AudioCacheRepository 按 audio_id 查缓存（DB §7.4），不按 url；audio_id 不变 → 缓存继续命中 ✓ |
| pronunciation controller 改后 fail-fast 404 / 400 信号丢失 | word/locale/voice regex 校验保留（400 fail-fast）；wav 不存在仍 302 + COS 404，client GET COS 后拿 404，行为等价（多 1 RTT）|
| 删 `/cdn` static route 后 dev 本地无 fallback | dev 机直接跑 partial_publish 仍写 cdn-mock；如要本地试 audio fetch，跑 sync-audio-mp3-to-cos 后用 COS URL 代 |
| COS bucket public-read 导致流量费用 | 接受；流量 ¥0.5/GB；早期可控；用户量起来再加 hotlink protection / 真 CDN |
| pronunciation `Header('Cache-Control', ...)` 行为变了 | 改 redirect 后 server 不返 Cache-Control（302 不该缓存）；client GET COS 后拿 COS 的 Cache-Control（plan 里上传时设 `public, max-age=86400`，与原 controller 一致）|
| sub-smoke F2 metadata.url 现在含 COS host | F2 断言改 "url 含 `.cos.` host 而非 `10.0.2.2`"；F3 GET 200（PR-D 关键 PASS）；F4 redirect → COS 200 |

---

## 6. 不做（明示边界）

- ❌ 接真 CDN 边缘节点（PR-E；腾讯云 CDN over COS 接入是单独 PR）
- ❌ 改 partial_publish.py 写入路径（仍 local://cdn placeholder + cdn-mock dir for dev）
- ❌ 改 audio-assets.controller.ts（仍 pass-through audio_assets.url）
- ❌ 改 content-manifest.controller.ts（PR-C 稳定）
- ❌ 改 mobile 任何文件（PR-C β 已处理）
- ❌ 改 drift / pubspec / 任何 schema
- ❌ 加 pronunciation_assets PG 表（D2=c 已否决）
- ❌ multi-region / multi-bucket（PR-E）
- ❌ ETag / Range / hot-link protection（流量起再做）

---

## 7. 提交策略

按 phase 拆 commit:

```
docs(v0.3-pr-d): scope v0.1 + plan v0.1 (Option B 推荐)
docs(v0.3-pr-d): scope v0.2 + plan v0.2 (D1=A 用户拍板, D2=a redirect)
feat(v0.3-pr-d): Phase 1 — sync-audio + sync-pronunciation + repipe-audio-urls (3 个 ts 工具)
feat(v0.3-pr-d): Phase 2 — pronunciation 302 redirect + main.ts 删 /cdn + ingest cdnOrigin env
feat(v0.3-pr-d): Phase 3 — README PR-D 章节 + e2e 加 redirect case + .env.example
Merge feat/v0.3-pr-d-... → v0.3 PR-D audio + pronunciation 接 COS (~2-2.5d)
```

---

## 8. 验收清单（基于 D1=A + D2=a）

### Phase 0 / 用户操作

- [ ] COS bucket prefix `audio/v1/...` + `pronunciation/...` 准备（auto by sync 工具）
- [ ] `sync-audio-mp3-to-cos.ts --dry-run` 列举将上传文件数；`--commit` 执行
- [ ] `sync-pronunciation-to-cos.ts --commit` 同上
- [ ] `repipe-audio-urls.ts --from 'http://10.0.2.2:3000/cdn' --to '<COS_PUBLIC_URL_BASE>' --commit` 重写 PG
- [ ] `curl -I '<COS_PUBLIC_URL_BASE>/audio/v1/examples/.../<audio_id>.mp3'` 返 200 + audio/mpeg
- [ ] `curl -I '<COS_PUBLIC_URL_BASE>/pronunciation/en-US/am_michael/v1/a/abandon.wav'` 返 200 + audio/wav
- [ ] 部署新 server image（pronunciation 302 redirect + 无 `/cdn` route）
- [ ] `docker-compose.yml` 不含 cdn-mock / data/pronunciation volumes（如 v0.1 试过 Option B 需回滚）
- [ ] `curl 'https://api.<your-domain>/api/v1/pronunciation/abandon?locale=en-US&voice=am_michael'` 返 302 + Location 含 `.cos.`

### Phase 1-3 / 代码

- [ ] 3 个新 ts 工具创建 + dry-run smoke 通过
- [ ] `pronunciation.controller.ts` 改 302 redirect；word/locale/voice regex 校验保留
- [ ] `main.ts` 删 `/cdn` static route + 注释
- [ ] `ingest-audio-assets.ts` cdnOrigin default 读 `AUDIO_CDN_ORIGIN` env
- [ ] `.env.example` + `AUDIO_CDN_ORIGIN` + `PRONUNCIATION_CDN_ORIGIN`
- [ ] e2e 加 1 case：`/api/v1/pronunciation/<word>` 返 302 + Location 含 COS host
- [ ] README PR-D 章节（D1=A + D2=a + sync 工具用法 + repipe 流程）
- [ ] PR_DESCRIPTION_PR-D.md 写到 user dir
- [ ] TS type check clean
- [ ] e2e:pg 全过（48/49 + 1 new case = 49/50）+ 1 baseline /me/today fail

### Phase 4 / sub-smoke A-F1-F4 真机

- [ ] **A**: release build 启动 → manifest sync log
- [ ] **B**: release build settings 页能看到 SwitchListTile（PR-C 已验过；regression）
- [ ] **C**: release build flag=false → 无 sync log（regression）
- [ ] **D**: D1 收口 bundle v3+manifest → bundle v4 → manifest 数据保留（regression）
- [ ] **E**: full E2E manifest sync drift readback（regression）
- [ ] **F1 (β baseUrl)**: release ApiClient 业务接口 200，host = `api.<domain>`
- [ ] **F2 (PR-D 关键)**: release ExampleAudioService metadata API 200；**断言** url 含 `.cos.<region>.myqcloud.com` 而**不**含 `10.0.2.2`
- [ ] **F3 (PR-D 关键)**: F2 metadata.url GET → mp3 字节 200 + audio/mpeg（PR-C 时 expected timeout 现在 PASS）
- [ ] **F4 (PR-D 关键)**: release PronunciationService → 第一跳 server 302 → 第二跳 COS wav 200（PR-C 时 expected 404 现在 PASS）

---

## 9. PR-D 之后候选

| 优先级 | 候选 | 触发 |
|---|---|---|
| 中 | **PR-E**: 真 CDN 边缘节点（腾讯云 CDN over COS）+ 观测性埋点 | 用户量起；流量起来 |
| 低 | hotlink protection / Range / multi-codec | 流量起 |
| 低 | multi-region COS（容灾）| 出海或 SLA 要求 |
| 低 | partial_publish.py 直接上传 COS（去掉 sync 工具中间步骤）| 工作流优化（当前 sync 工具够用）|

---

## 附录 A: 与 PR-C v0.3 §0.5.1 caveat 对照

PR-C §0.5.1 列了 release 用户**仍不能**3 条：

| caveat | PR-D Option A 解 | sub-smoke 对应 |
|---|---|---|
| ❌ 真播例句 mp3 字节 | ✅ `repipe-audio-urls.ts` 重写 PG `audio_assets.url` 指向 COS；client 拿 metadata 后 GET COS 拿 200 | F3 |
| ❌ 真听单词发音 wav 字节 | ✅ pronunciation controller 改 302 redirect → COS；wav 在 COS public-read | F4 |
| ❌ `/cdn` static route serve 不到 mp3 | ✅ static route 整段删除（不再需要）；audio 走 COS public URL | (no smoke needed; 直接确认 main.ts 无 useStaticAssets `/cdn` 块) |

PR-D 完成后 PR-C R4-2/R4-3 揭示的预存架构债务**全部闭合**。
