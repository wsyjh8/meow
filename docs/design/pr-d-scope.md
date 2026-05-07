# PR-D scope · audio asset URL 重 ingest + Docker 资产挂载（PR-C R4-2/R4-3 收口）

- **Date**: 2026-05-07
- **Status**: scope v0.1 — 闭合 PR-C R4-2/R4-3 揭示的预存架构债务；待评审 + 选 D1（Path A/B/C）
- **基线 commit**: PR-C head `2a3cbeb`（依赖 PR-C merge 进 main 后 rebase）
- **工作分支**: `feat/v0.3-pr-d-audio-asset-ingest-cos`
- **关系**: 闭合 `pr-c-scope.md` v0.3 §0.5.1 caveat 列出的"release 仍不能"3 条

---

## 0. 问题陈述（PR-C v0.3 留下的债务）

PR-C v0.3 切了 mobile 4 service `baseUrl` 到 `apiV1Base` (β)，让 release 用户能：
- ✅ 走 production 真域名调 metadata API（manifest / audio / pronunciation）

但**仍然不能**：
- ❌ 真**播放**例句 mp3：`audio_assets.url` 仍是 `ingest-audio-assets.ts:90` 默认 `cdnOrigin = 'http://10.0.2.2:3000/cdn'` 写入的 emulator host
- ❌ 真**听**单词发音 wav：`pronunciation.controller.ts` 读 `data/pronunciation/...`，但该目录**不在 Docker image 内**（dev 开发机 fs `.gitignore` 忽略，无 COPY 也无 mount）
- ❌ `/cdn` static route 在 production serve 不到 mp3：`apps/api/cdn-mock/` 在 repo 仅 `.gitkeep` 占位

PR-D 目标：让 release 用户**真能**播例句 mp3 + 听单词发音。

---

## 1. 三个 scope 选项（D1 决策点）

| 选项 | 改动范围 | release 流量去哪 | 估时 |
|---|---|---|---|
| **A: 全 COS** | audio + pronunciation 都上 COS；ingest 重写 url；pronunciation controller 改 redirect / mobile 直拼 COS URL；server `/cdn` route 删 | COS（CDN-friendly，未来真接 CDN 边缘节点零成本切） | 3-4d |
| **B: server volume mount** ⭐ 推荐 | docker-compose 加 volumes mount `cdn-mock` + `data/pronunciation` 到 container；ingest cdnOrigin 改 `https://api.<your-domain>/cdn`；mobile 0 改动；pronunciation controller 0 改动 | 自家 server（nginx-proxy 反代） | 1-1.5d |
| **C: 混合 — audio 走 COS / pronunciation 走 server volume** | A + B 各取一半：audio mp3 是大头流量上 COS；pronunciation wav 数据小留 server | COS（audio）+ server（pronunciation） | 2.5d |

### 1.1 Option A 详（全 COS）

- `partial_publish.py` 上传 audio mp3 到 COS（路径 `audio/v1/{kind}s/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3`）
- `ingest-audio-assets.ts` cdnOrigin 改 COS public-base
- pronunciation wav 一次性批量上传到 COS（路径 `pronunciation/{locale}/{voice}/v1/{firstLetter}/{word}.wav`）
- pronunciation controller：3 选 1
  - (a) 改成 302 redirect 到 COS URL（保 API 形态，client 透明）
  - (b) 删 controller，mobile 端 `PronunciationService` 直拼 COS URL（少一跳，但 server 失去 fail-fast 404 信号）
  - (c) 改成查表（PG 加 `pronunciation_assets` 表）+ 返 metadata（不直 redirect），mobile 拿 url 后 GET COS
- server `/cdn` static route 删除，`apps/api/main.ts` line 39-50 整段去
- mobile：取决于 (a)(b)(c) 选择
  - (a) `PronunciationService._baseUrl/...` HTTP 客户端要 follow redirect（http package 默认 follow，OK）
  - (b) `PronunciationService` 重构（baseUrl + path 模板拼 COS URL）；ApiClient 不动；ExampleAudioService 不动（已经走 metadata API 拿 url）
  - (c) `PronunciationService` 像 `ExampleAudioService` 一样先调 API 拿 metadata 再 GET COS

**优点**：
- release 流量都不走 app server（带宽友好）
- 与 manifest 模式一致
- 未来真接 CDN（如腾讯云 CDN over COS）零代码切

**缺点**：
- 范围最大；需要：(1) audio pipeline 改上传 (2) pronunciation 一次性批量上传 (3) pronunciation controller / mobile 一段重构
- 一次性 ingest 重传几千 mp3 + 几万 wav（流量 + 时间）
- pronunciation 数据 `data/pronunciation/` 实测 dev 机有 en-GB + en-US 多 voice，文件多
- 改动密集，sub-smoke 真机回归面广

### 1.2 Option B 详（server volume mount）⭐ 推荐

- 用户现有 `docker-compose.yml`（PR-C Phase 0 配的）加 2 行 volumes:
  ```yaml
  api:
    image: meow-api:latest
    volumes:
      - /var/lib/meow/cdn-mock:/app/cdn-mock:ro
      - /var/lib/meow/data/pronunciation:/app/data/pronunciation:ro
    # ...
  ```
- 用户一次性把开发机的 `cdn-mock/` + `data/pronunciation/` 通过 `rsync` / `scp` 同步到 server `/var/lib/meow/...`
- `ingest-audio-assets.ts` 默认 `cdnOrigin` 改 `https://api.<your-domain>/cdn`（指向 server 自家 nginx-proxy）；保留 `--cdn-origin` 参数允许 dev override
- 一次性运行 ingest 重写 PG `audio_assets.url`（用户跑命令）
- `apps/api/main.ts` `/cdn` static route 保留（serve mounted `/app/cdn-mock`）
- pronunciation controller 0 改动（`/app/data/pronunciation/...` mounted 真存在）
- mobile **0 改动**（baseUrl 已 β + 走 metadata 拿 url + url 已是 https）

**优点**：
- 改动最小（~30 行 ingest + docker-compose 2 行）
- mobile 0 改动
- pronunciation controller 0 改动
- server `/cdn` 保留（与 manifest pipeline 经 COS 不同，audio 留在 server-side static）
- 利用已有 nginx-proxy + acme-companion HTTPS

**缺点**：
- 流量都跑 app server 上（带宽消耗）
- server 磁盘多占（audio mp3 几百 MB，pronunciation 几百 MB）
- 真要接 CDN 时还要一轮迁移（PR-E 候选）

### 1.3 Option C 详（混合）

- audio mp3 走 COS（同 Option A audio 部分）
- pronunciation wav 走 server volume mount（同 Option B pronunciation 部分）
- 理由：audio 是大头流量（每次播例句都拉 mp3）；pronunciation 访问相对低频（学习页 + 评估页才用）

**估时**: 比 A 少 0.5-1d（pronunciation 不动），比 B 多 1d（audio 接 COS）。

---

## 2. 推荐：Option B（理由）

1. **改动最小**：docker-compose 2 行 + ingest 1 行 default + 一次性 rsync；mobile 0 改动；pronunciation controller 0 改动
2. **风险最小**：mobile 端 release smoke F1-F4 不再有 expected fail；F2 audio metadata.url 直接 https://api.<your-domain>/cdn/...；F3 mp3 GET 200；F4 pronunciation wav GET 200
3. **可演进**：未来用户量起来，audio mp3 真要接 CDN，单独 PR-E 做（不阻塞当前发布）
4. **对齐 PR-C C2 决策**：HTTPS = 自家 nginx-proxy + acme-companion；audio/pronunciation 也走同一条 https 链路一致

放弃 A/C 理由：
- A: pronunciation controller 重构 + mobile `PronunciationService` 重构 = 范围爆炸；ingest 一次性上传几万 wav 文件流量 + 时间 burst 大
- C: 比 A 少一半但仍要做 audio COS 上传 + ingest 重写；不如 B 一刀切再演进

---

## 3. 改动清单（基于 Option B；A/C 见 §1）

### 3.1 用户操作（~20 min）

| 项 | 输出 |
|---|---|
| 一次性把开发机 `cdn-mock/` rsync 到 server `/var/lib/meow/cdn-mock` | rsync 命令 |
| 一次性把开发机 `data/pronunciation/` rsync 到 server `/var/lib/meow/data/pronunciation` | rsync 命令 |
| `docker-compose.yml` 加 2 行 volumes mount + restart api container | 部署目录文件改 |
| 验证 `https://api.<your-domain>/cdn/<known-mp3>` 返 200 + 正确 Content-Type | curl |
| 验证 `https://api.<your-domain>/api/v1/pronunciation/<known-word>?locale=en-US&voice=am_michael` 返 200 + audio/wav | curl |
| 一次性运行 `ingest-audio-assets.ts --cdn-origin https://api.<your-domain>/cdn` 重写 PG `audio_assets.url`（如 PG 已有 `http://10.0.2.2:3000/cdn/...` 数据） | npm script |

### 3.2 代码改动

| 文件 | 改动 |
|---|---|
| `apps/api/scripts/ingest-audio-assets.ts` | `--cdn-origin` default 从 `'http://10.0.2.2:3000/cdn'` 改 `'https://api.<your-domain>/cdn'`（**用户域名占位**；plan 加 dotenv 支持，从 `.env` 读 `AUDIO_CDN_ORIGIN` 替代 hardcode）|
| `apps/api/scripts/audio_pipeline/partial_publish.py` | **不改**；继续写 `local://cdn/...` placeholder（ingest 一致性） |
| `apps/api/scripts/repipe-audio-urls.ts` (新) | one-shot 工具：扫 PG `audio_assets` 表，把 url 字段从 `http://10.0.2.2:3000/cdn/...` 重写为 `${AUDIO_CDN_ORIGIN}/...`；幂等；dry-run / commit 双模 |
| `apps/api/.env.example` | + `AUDIO_CDN_ORIGIN=https://api.<your-domain>/cdn` |
| `apps/api/scripts/content_pipeline/README.md` | + PR-D 章节（rsync 步骤 + repipe 工具用法 + Option B / A / C 决策） |
| `docs/design/pr-d-scope.md` (新) | 本文档 |
| `docs/design/pr-d-plan.md` (新) | step-by-step |

### 3.3 不动（zero diff vs PR-C head）

- `apps/api/src/main.ts`（`/cdn` static route 保留）
- `apps/api/src/controllers/pronunciation.controller.ts`（路径硬编不动；mounted volume 透明）
- `apps/api/src/controllers/audio-assets.controller.ts`（仍 SELECT FROM audio_assets pass-through 拿 url）
- `apps/api/src/controllers/content-manifest.controller.ts`（PR-C 已稳定）
- 任何 mobile 文件（β 已切 baseUrl + apiV1Base）
- `apps/api/Dockerfile`（PR-C 已加；Option B 不需要 COPY cdn-mock/data/pronunciation 因为走 volume mount）

---

## 4. 估时

```
用户操作         : 20 min (rsync + docker-compose 改 + 验证 + 重 ingest)
代码改动         : 0.5d   (ingest cdnOrigin default + repipe-audio-urls.ts + README)
sub-smoke 真机   : 30 min (F2/F3/F4 现在应全 PASS)
─────────────────────────────────
合计             : 1d (我做) + 50 min (你做)
```

带 50% buffer 估 1.5d。

---

## 5. 风险

| 风险 | 缓解 |
|---|---|
| `data/pronunciation/` rsync 文件数量大（几万 wav）→ 同步耗时 | 用户后台 rsync；不阻塞代码改动；rsync 增量同步友好 |
| `cdn-mock/` mp3 文件数大（几千） | 同上 |
| `repipe-audio-urls.ts` 误改 PG 数据 | dry-run 默认；commit 模式必传 `--commit` flag；用 transaction（rollback safe）|
| server 磁盘不够（audio + pronunciation 总计可能 1GB+）| Phase 0 先 `du -sh` 估算；不够先扩容 |
| nginx-proxy serve 大量静态文件性能 | nginx 静态文件 serve 是其强项（10K+ req/s 单核）；早期用户量小不是瓶颈 |
| rsync 同步过程中 server 不一致（部分文件已传，部分没传）| `rsync --delay-updates` 或 `rsync 到临时目录 + mv` 原子切换 |
| `audio_assets.url` 重写后客户端缓存仍是旧 URL → 客户端缓存命中 | 客户端按 audio_id 缓存，不按 url；audio_id 不变 → 缓存仍可用；URL 仅是当前 fetch 路径，不影响 `audio_file_cache` 表 |

---

## 6. 不做（明示边界）

- ❌ audio mp3 接真 CDN（PR-E 候选；用户量起来再做）
- ❌ pronunciation wav 接 COS（用户量起来再做）
- ❌ 改 `pronunciation.controller.ts` 内部逻辑（路径解析 + 权限校验保留）
- ❌ 改 `audio-assets.controller.ts`（仍 pass-through audio_assets.url）
- ❌ mobile 端任何代码改动（β 已处理）
- ❌ 给 audio_assets 加 `version` 字段或迁移（重写 url 是 in-place UPDATE）

---

## 7. 提交策略

按 phase 拆 commit（沿用 PR-A/B/C 风格）：

```
docs(v0.3-pr-d): scope v0.1 + plan v0.1 (Option B 推荐; A/C 备选)
docs(v0.3-pr-d): scope/plan v0.2 (吸收评审 if any)
feat(v0.3-pr-d): Phase 0 — docker-compose volumes + rsync 文档
feat(v0.3-pr-d): Phase 1 — ingest-audio-assets cdnOrigin default 改 + repipe-audio-urls.ts
feat(v0.3-pr-d): Phase 2 — README PR-D 章节
Merge feat/v0.3-pr-d-... → v0.3 PR-D audio asset 接通 (Option B; ~1d)
```

---

## 8. 验收清单（基于 Option B）

- [ ] 用户 rsync `cdn-mock/` 到 server `/var/lib/meow/cdn-mock` 完成
- [ ] 用户 rsync `data/pronunciation/` 到 server `/var/lib/meow/data/pronunciation` 完成
- [ ] `docker-compose.yml` 加 volumes mount + api container restart 成功
- [ ] `curl https://api.<your-domain>/cdn/<known-mp3-path>` 返 200 + audio/mpeg
- [ ] `curl 'https://api.<your-domain>/api/v1/pronunciation/abandon?locale=en-US&voice=am_michael'` 返 200 + audio/wav
- [ ] `ingest-audio-assets.ts --cdn-origin https://api.<domain>/cdn` 重 ingest 成功（dry-run 验证后 commit）
- [ ] PG `audio_assets.url` 全部以 `https://api.<your-domain>/cdn/` 开头（或 `https://*.cos.*.myqcloud.com/` 如未来切 COS）
- [ ] `apps/api/scripts/repipe-audio-urls.ts` 新建 + 单元测试 / dry-run smoke
- [ ] README PR-D 章节
- [ ] PR_DESCRIPTION_PR-D.md 写到 user dir
- [ ] **sub-smoke F1-F4 真机全过**（PR-C 后留下的 expected fail 现在应全 PASS）：
  - [ ] F1 (β baseUrl): release ApiClient 业务接口 200，host = `api.<your-domain>`
  - [ ] F2 (β baseUrl): release ExampleAudioService metadata API 200；**断言** url **不**含 10.0.2.2（含 `api.<your-domain>` 或 COS host）
  - [ ] F3 (PR-D 关键): F2 metadata.url GET → 200 + audio/mpeg（PR-C 时 expected timeout 现在应 PASS）
  - [ ] F4 (PR-D 关键): release PronunciationService → API 200 + wav GET 200（PR-C 时 expected 404 现在应 PASS）
- [ ] flutter analyze: 0 new issues（mobile 0 改动，预期同 PR-C）
- [ ] flutter test: 1202/1202 全过（预期）

---

## 9. PR-D 之后候选

| 优先级 | 候选 | 触发 |
|---|---|---|
| 中 | **PR-E**: audio mp3 接 COS（Option A audio 部分迁移） | 用户量起 / app server 带宽吃紧 |
| 低 | pronunciation wav 接 COS | 同上 |
| 低 | 真 CDN（腾讯云 CDN over COS） | 用户量起 / 海外用户 |
| 低 | 观测性埋点（v0.4 §7.3）| 同 PR-C 候选 |

---

## 附录 A: PR-C → PR-D 关系

PR-C v0.3 §0.5.1 caveat 三处声明 release 用户**仍不能**：
1. 真播例句 mp3 → PR-D Option B 解
2. 真听单词发音 wav → PR-D Option B 解
3. `/cdn` static route 服 mp3 → PR-D Option B 通过 volume mount 让该目录在 container 内有内容

PR-D 完成后这 3 条 caveat 全部解除，PR-C R4-2/R4-3 揭示的预存架构债务闭合。
