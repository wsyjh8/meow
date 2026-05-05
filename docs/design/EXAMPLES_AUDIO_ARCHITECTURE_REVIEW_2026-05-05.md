# 例句 + 例句音频架构现状 & 演进选项 —— 同行评审请求

- **Date:** 2026-05-05
- **Status:** Review request (not a design doc)
- **Audience:** 多个独立 AI 评审窗口，每个窗口独立给意见，不要互相参考
- **Reviewer task:** 读完后回答文末 §6 的 4 个具体问题；可以反对作者方案、提出第三种思路

## 0. 阅读前需要的最小上下文

**项目**：背单词喵喵（Flutter mobile + NestJS API + PostgreSQL）。MVP 阶段，**solo 独立开发，无真实用户**。

**架构基线**：`docs/design/DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md`（r7）—— 长期目标态文档，三层物理隔离（静态内容 / 用户状态 / 设备运行态），stable_id 跨端引用，content_manifest 分发静态包。

**当前进度**：P0（stable_id）/ P1（词条统一）/ P2.1（例句音频 MVP）/ P2.2.A+C（单词音频通道）已落地；P2.2.B 等 Codex 出 word audio；P3 / P4 / P5 未开工。

**本文要解决的问题**：作者跑通了模拟器端到端（点喇叭能听到 af_bella 的英文 TTS），现在问题是 **"为后续持续加例句和例句音频，当前结构合不合适？"**。作者已经写了一个改造路径建议，但希望多个独立 AI 评审挑刺。

---

## 1. 当前架构（实测过的事实，不是设计稿）

### 1.1 例句文本的存储与分发

```
权威源 (cloud truth)              App 实际读取的源
───────────────────                ──────────────────
PostgreSQL `examples` 表           apps/mobile/assets/words/{book-001,zk,gk}.json
  └─ 10140 行                        └─ bundle 进 APK 的 JSON 文件
     stable_id (28 char)               (每个文件 1-2.4 MB)
     word_id, en, cn, sense
                                     ↓ WordbookLoader.loadIfNeeded()
                                       (按 contentVersion 触发重导入)
                                     ↓
                                     drift `example_sentences` 表
                                     (设备本地 SQLite)
```

**关键事实**：
- **App 学习页的例句来自 bundled JSON，不来自 cloud API**。`/api/v1/books/:bookId/words` API 存在但 App 没用它做例句来源
- PG 里的 examples 是为了 audio_assets 的外键 + 后端做内容审计用的
- contentVersion 在 JSON 里硬编码（当前是 '4'），bump 一次就触发 App 全量重导

### 1.2 例句音频的存储与分发

```
权威源 (cloud truth)              App 实际播放的源
───────────────────                ──────────────────
PostgreSQL `audio_assets` 表       HTTP fetch via API
  └─ 2263 行 (status='ready')         /api/v1/examples/:stable_id/audio
     id (audio_id, 28 char)            └─ 返回 { audio_id, url, checksum, ... }
     target_id = examples.stable_id    ↓
     url, checksum_sha256, ...        UrlSource(url) → audioplayers 流播
                                       ↓
mock CDN (apps/api/cdn-mock/)        本地缓存 (drift `audio_file_cache`)
  └─ NestJS useStaticAssets 挂 /cdn   └─ {appDocs}/audio/{audio_id}.mp3
     /audio/v1/examples/{locale}/        + drift row tracking LRU
     {voice}/{audio_version}/
     {shard:2}/{audio_id}.mp3
```

**关键事实**：
- 音频走 cloud-fetch → 缓存 → 本地播放，**不 bundle 进 APK**
- 例句的 audio_id 是 `sha256_24(canonical_json([target_kind, target_id, locale, voice, format, audio_version]))`
- App 不算 hash，不拼 URL（DB §3.4 §6.2.2 强制）
- 当前覆盖率：**2263 / 10140 = 22.3%**（其余 7877 例句没有音频，UI 自动隐藏播放按钮）

### 1.3 当前发布管线（4 个脚本）

| 脚本 | 输入 | 输出 | 何时用 |
|---|---|---|---|
| `partial_publish.py --kind=example` | WAV 文件夹 (`tmp/wav/*.wav`) | cdn-mock + audio_assets.jsonl + examples.json | Codex 出 WAV 时 |
| `partial_publish.py --kind=word` | WAV 文件夹 | cdn-mock + audio_assets.jsonl | P2.2.B（Codex word 时） |
| `ingest_external_mp3s.py` | MP3 文件夹（已组织好） | cdn-mock + audio_assets.jsonl | Codex 直接出 MP3 时 |
| `ingest-audio-assets.ts` | examples.json + audio_assets.jsonl | PG `examples` + `audio_assets` + `content_manifest` 三张表 | 上面任一脚本之后 |

**典型一次例句新增的完整步骤**：
1. LLM 改/加 wordbook source data
2. `npx ts-node scripts/export-wordbook-json.ts` → 重导出 `apps/mobile/assets/words/*.json`
3. **手动 bump `contentVersion`** 到下一个数字
4. Codex pipeline 跑 TTS → WAV
5. `partial_publish.py --kind=example` → 生成 cdn-mock + jsonl
6. `ingest-audio-assets.ts` → 写 PG
7. 重新 build APK + 发布给用户（**因为 bundled JSON 改了**）
8. 用户更新 App → WordbookLoader 看到新 contentVersion → 全量重导例句

### 1.4 测试覆盖情况

- API e2e: 148 / 148 通过（含 `test:e2e:pg` PG 后端 20 个）
- Mobile：1172 通过 / 1 失败（pre-existing study_sections 失败，与本议题无关）
- 三端 byte-identical hash fixtures（Python / TypeScript / Dart）：42 / 42 通过

---

## 2. 已暴露的具体问题（带数字）

### 问题 1：例句更新需要发新 APK，节奏与音频不对称

| 资产 | 改一处的"用户拿到"路径 | 时间成本 |
|---|---|---|
| 例句**音频** | ingest 一行命令 → 用户重启即新 | 分钟级 |
| 例句**文本** | bundled JSON 改 → bump version → 重 build APK → 应用商店审核 → 用户更新 | 数天 |

**实际后果**（即使现在还没用户）：
- 想紧急修一句翻译错 → 必须发 APK
- A/B 不同例句 → 不可能
- 按用户难度推不同例句 → 不可能
- 三本词书 JSON 已经 940KB + 2.25MB + 2.40MB = **5.6 MB**（整个 APK 一大块），全 bundle CET-4 全量例句还要更大

### 问题 2：4 个脚本，文档分散

刚才作者把 `partial_publish.py` 和 `ingest_external_mp3s.py` 几乎走了一遍才搞清楚关系。新人接手 / 自己 3 个月后回来，估计会再迷糊一次。

### 问题 3：Stale 资产堆积（已观测）

刚做了一次 ingest：用户 host 上 `D:/code/AI/startUp/meow/mp3/` 里有 9221 个 mp3，**只有 2289 个能匹配当前 wordbook 例句**（mp3 是 Codex 之前几版 wordbook 内容生成的，stable_id 已变），剩下 **6932 个 stale 文件**。当前 ingest 脚本不主动 GC，stale 文件原地堆。

云上正式 CDN 后这是真金白银（R2 / S3 按 GB 计费）。

### 问题 4：例句和音频"完整度"不一致

App 看到的例句：100%（bundled）  
对应有 ready 音频的：22.3%

→ UI 上大量例句没有喇叭按钮。MVP 灰按钮策略可接受，但**用户需要持续看到不一致状态**。

### 问题 5：DB v0.3.0 §1.5 / §4.7 设计了但没接

设计稿原话：

> §1.5 静态内容 = 内容包 + manifest，不是裸 CDN 文件。所有 CDN 分发的静态内容（音频元数据、字典、**例句包**）必须通过 `content_manifest` 控制：版本、checksum、最小 App 版本、激活状态。

当前实现：
- 音频元数据（audio_assets）→ 走了 manifest ✅
- 字典（forms / relations / phrases / morphemes）→ 进 enrichment_v2.db bundled ❌（P0 时为速度妥协）
- **例句包**→ 进 wordbook JSON bundled ❌（P0 时为速度妥协）

设计稿没替换，只是实现 lag。后续音频生成 / 例句生成都在加深这个 lag。

---

## 3. 作者的演进路径建议（评审重点：这套合不合理？）

按"该不该现在做"分三档：

### 🟢 现在收口（半天）

**(A) 脚本合并 + 文档化**
- 把 `partial_publish.py` 和 `ingest_external_mp3s.py` 统一到一个 `pipeline.py`，subcommands: `wav-to-cdn` / `mp3-to-cdn` / `gc-stale`
- 加 `apps/api/scripts/audio_pipeline/README.md` 写清两条调用路径

**(B) Stale 资产 GC**
- ingest 收口时扫 cdn-mock 里 audio_id 不在 audio_assets 表的文件
- 默认打印 ("6932 stale files; run --gc to delete")，加 `--gc` 才删

### 🟡 半年内做（2-3 天）

**(C) 例句搬到 CDN 包，与音频对齐发布周期**

具体：
- 例句不再进 `apps/mobile/assets/words/*.json` 的 `examples` 字段
- 加 `package_kind='examples'` 到 content_manifest，按 book 切包
- App 启动 / contentVersion 变化时拉 `/api/v1/content/manifest?since=...` → 下载 `examples-{book}.jsonl.gz` → 解包导入本地 drift 表
- 词书的"骨架"（wordId / wordText / meaning / phonetic）继续 bundle，**只把 examples 字段单独拆出走 CDN**
- 兼容期：APK 里的 bundled examples 留作 fallback 一两版本后删除

收益：
- 加例句 / 改翻译不用发 APK
- APK 减 5.6 MB 多
- 跨用户个性化例句池可以做（按词频 / 难度选）

**(D) Pipeline 单笔事务化**
- 当前是"先 LLM 出例句 → 改 wordbook → 再让 Codex 跑音频"两步分开，stable_id 漂移就出现 stale（已经 6932 个）
- 合并为：`generate_examples.py word_id=abandon` → LLM 出例句 + 算 stable_id + TTS + 一个事务写入所有目标
- 旧 stable_id 标 superseded（GC 留窗口）

### 🔴 现在不用做

- 真实 CDN（R2 / S3）替换 mock —— 等部署
- Per-user example overrides —— P3 sync_outbox 之后
- 多 voice 例句切换 —— PD-T-012 决定后

### 作者的最终建议

**如果只能挑一件事现在做**：(C) 例句 CDN 化。

理由：现在还没用户，搬动代价最小；每多一条例句、每多一次修订，技术债加深。

---

## 4. 反方观点（作者主动列）

为了避免 echo chamber，作者列出**反对自己方案的可能论据**，请评审认真考虑：

### 反对 (C) 的可能理由

1. **首启体验代价**：例句搬 CDN 后，用户首次启动 / 首次进新词书需要拉网。弱网 / 离线场景体验恶化。当前 bundled 方案至少保证"装完 App 就能用"。
2. **MVP 阶段过早优化**：还没用户，APK 里 bundled 几 MB 没人喊。等用户量到一定规模再搬不晚。
3. **CDN 费用**：mock 阶段不要钱，但搬到真实 CDN 后例句包请求次数 = 用户数 × 词书数，并非小数。
4. **复杂度上升**：要加 manifest 拉取 + 包下载 + 校验 + 解包 + 导入 + 失败回退 + 增量更新一整套，不是 2-3 天能干完的。
5. **审核风险**：如果用户首启时拉的例句包里有审核敏感词（恋爱 / 宗教 / 政治例句），App Store 审核风险。bundled 方案至少审核时是固定内容。

### 反对 (D) Pipeline 单笔化的可能理由

1. **LLM + TTS 在不同机器上跑** —— LLM 用云 API，TTS 现在用本地 kokoro。强行一个 pipeline 把它们绑死，部署灵活性下降。
2. **TTS 可能失败 / 缓慢** —— 一个例句失败导致整批 abort 不合理；现在两阶段反而是优势。
3. **6932 stale 不是天大事** —— 加一个 GC 命令就解决了，不用动 pipeline 结构。

### 第三种可能（不是 A B C D 之外的方案）

- **例句不上 CDN，直接走 API 实时拉**：每个词学习时打 `/api/v1/words/:id/examples` 拿 5 条。无 manifest，无包概念，最简单。代价：每次学习触发网络。
- **例句进字典包**：把 examples 塞进 enrichment_v2.db 那个 bundled SQLite seed，统一 bundle 路径。复用现有 EnrichmentBootstrap。
- **完全不变**：bundled JSON 工作得很好，"等真出问题再说"。

---

## 5. 数字 / 文件路径速查（评审引用方便）

```
PG audio_assets ready 行数:                     2263
PG examples 行数:                              10140
当前例句覆盖率:                              22.3%
bundled wordbook JSON 总大小:               5.6 MB
mock CDN 当前 MP3 数:                          2289
host 上 stale MP3:                            6932
hash fixture 跨端通过数:                     42/42
mobile 测试 pass:                          1172/1173
API e2e 测试 pass:                           148/148

设计稿:        docs/design/DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md (r7)
管线脚本:      apps/api/scripts/audio_pipeline/{partial_publish,ingest_external_mp3s,reference}.py
                apps/api/scripts/ingest-audio-assets.ts
API 控制器:    apps/api/src/controllers/audio-assets.controller.ts
mobile 服务:   apps/mobile/lib/core/audio/{example_audio_service,word_audio_service,audio_cache_repository}.dart
mobile loader: apps/mobile/lib/core/memory/wordbook_loader.dart
bundled 资产:  apps/mobile/assets/words/{book-001,zk,gk}.json
mock CDN 根:   apps/api/cdn-mock/audio/v1/examples/...
```

---

## 6. 评审请回答的具体问题

> 不要面面俱到，针对下面 4 个挑你觉得有把握的回答。第 4 个必答。

**Q1**：作者识别的 5 个问题（§2），有哪个判断错了？或者漏了哪个更严重的问题？

**Q2**：(A) (B) 立刻收口的 2 件事（脚本合并 + GC），值不值得现在做？还是连这点工作量也是 bikeshedding？

**Q3**：(C) 例句 CDN 化方案，作者认为"现在做最划算"。反方观点 §4 列了 5 条可能反对理由。**评审给出独立判断**：现在做、半年后做、还是干脆不做？理由要具体到 §4 哪条（或新理由）。

**Q4**（必答）：如果你是作者，下一周（5 个工作日）会优先动哪一件事？给一个**单选**的推荐 + 一句话理由。可选项：
- (A) + (B) 脚本收口
- (C) 例句 CDN 化
- (D) Pipeline 单笔化
- 第三种方案（指出是哪种）
- 都不做，去推 P3 用户写型上云
- 都不做，去推 P2.3 例句多 voice
- 都不做，原地等 Codex 把 word audio + 剩余 78% 例句音频出全

**Q5**（可选加分）：如果作者打算长期做这个项目（5 年起），架构上还有哪个**根本性误区**值得现在就改？

---

## 7. 给评审者的元说明

- 作者**已经倾向 (C)**，但说服力可能不够。请独立判断，不必客气
- 评审写的内容会直接给 6 个 AI 评审同时看，每个独立写一份。最后作者综合
- 不要假设作者懂某个领域 —— 如果反对，请把推理链条写完整
- 引用文件路径用 §5 的速查表里的，不要瞎编
