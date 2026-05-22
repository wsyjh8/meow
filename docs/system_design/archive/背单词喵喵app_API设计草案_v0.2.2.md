# 背单词喵喵 App API 设计草案 v0.2.2

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.2.2
- **Date:** 2026-04-12
- **Status:** incremental merged full baseline candidate / ready for Room 1 review
- **Role card:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.2`
- **Purpose:** 以 `背单词喵喵app_API设计草案_v0.2.1.md` 为 full baseline，增量吸收 `API_P3.2_BackupRestore_v0.1.md` 与 `P3.3.16` 已落地接口现实，形成新的单文件 full merged baseline candidate。

---

## 0. 文档定位

本稿不是：
- 对 `背单词喵喵app_API设计草案_v0.2.1.md` 的整份推倒重写
- 把所有 future routing / owner-shift / true-exit / baseline uplift judgment 直接写成 runtime truth
- 把 dev-only implemented reality 自动升格为长期 frozen public contract

本稿只做一件事：

> **在保留 `v0.2.1` full baseline 主结构的前提下，把已经影响联调、实现、测试与客户端接入判断的 API 代码事实，吸收到新的 full merged baseline candidate。**

### 0.1 本轮吸收范围
本轮只吸收以下两类已经落地、且需要进入 full API 文档的代码事实：

1. **P3.2 — Backup / Restore 增量**
   - `POST /me/backup`
   - `GET /me/backup/latest`
   - `GET /me/backup/latest/snapshot`
   - 设备字段 / 新 snapshot schema / 降级恢复说明

2. **P3.3.16 — Local Review Batch 增量**
   - `POST /review-attempts/local-batch`
   - 客户端 `submitLocalReviewBatch()` 接口现实
   - 非续习本地 FSRS 批量提交进入后端结算链

### 0.2 一句话原则
> **既不否认 `v0.2.1` 已收口的三类接口现实，也不让 P3.2 / P3.3.16 已落地的接口变化继续停留在 patch 附件里。**

---

## 1. 输入依据

### 1.1 当前治理层 / 运行层依据
- `ORG_v0.5.0.md`
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.2`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.3.0.md`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- `Main_updated_2026-04-10_v34.md`
- `STATUS_updated_2026-04-10_v32.md`

### 1.2 当前 runtime active basis（推进层已 pin）
- BR active: `BR-OPP-001_v0.2.15.md`
- DB active: `背单词喵喵app_DB设计草案_v0.2.1.md`
- API active: `背单词喵喵app_API设计草案_v0.2.1.md`
- UI active: `UI_SPEC_v0.3.5.md`

### 1.3 本轮 sync / review candidate inputs
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `API_P3.2_BackupRestore_v0.1.md`
- `DB_P3.2_BackupRestore_v0.1.md`
- `P3.3.16_Claude_res.md`
- `BR-OPP-001_v0.2.15.md`
- `UI_SPEC_v0.3.6.md`

### 1.4 吸收原则
1. 保留 `v0.2.1` 的 full baseline 主结构与三层阅读方式
2. 正式吸收 P3.2 backup / restore 相关 API reality
3. 正式吸收 P3.3.16 local review batch API reality
4. 不把 pending 的 owner shift / true exit / full cutover / active baseline uplift judgment 偷写成当前事实
5. **No silent contract drift**

---

## 2. 三层阅读方式

### Layer A — Runtime active reference
说明当前推进层已 pin 的 active API baseline 是什么。

### Layer B — Code-truth implemented reality
说明当前代码里真实已经存在、会影响客户端与服务端联调判断的 REST / 本地 service / 同步 flow 是什么。

### Layer C — Candidate contracts not fully implemented
说明当前仍在 pending、不得被误写成 runtime truth 的 API 契约或后续演进方向是什么。

---

## 3. Room 2 总判断

### 3.1 总结论
> **v0.2.2 继续采用 “incremental merged baseline” 路线。**

也就是：
- 保留 active API baseline 的引用位置
- 沿用 `v0.2.1` 的“三类接口现实”主骨架
- 把 P3.2 / P3.3.16 已落地接口变化吸收进 full 文档
- 保持对未 fully landed 契约的显式分层
- 不让 patch 文档长期替代 full API baseline

### 3.2 当前最重要的 API 架构判断
1. 当前 API 仍不是“只有云端 REST”
2. 仍需正式接受三类接口现实：
   - 云端 REST API
   - 本地端 service / client-side adapter
   - 同步 / backup / restore flows
3. P3.2 没有把系统改成 full sync 平台  
   它只把 backup upload / latest snapshot fetch / restore apply 边界做硬。
4. P3.3.16 没有把 `review_group` continuation 全部替换掉  
   它只新增了 **本地非续习 review batch → 后端结算链** 的接口现实。

---

## 4. Layer A — Runtime active reference

### 4.1 当前推进层已 pin 的 active API baseline
当前推进层 `Main / STATUS` 仍将以下文件视为 active runtime API baseline：
- `背单词喵喵app_API设计草案_v0.2.1.md`

### 4.2 本稿与 active baseline 的关系
> **本稿是推荐 next-step API full baseline candidate，不自动替代 active API baseline。**

---

## 5. Layer B — Code-truth implemented reality（云端 REST）

## 5.1 全局现实元信息

### 5.1.1 Base URL
当前代码现实：
- `/api/v1`

### 5.1.2 鉴权
当前代码现实：
- 无鉴权
- dev mode / 单用户开发态

### 5.1.3 响应格式
当前代码现实：
- 无统一信封
- 直接返回 data
- 错误由 HTTP status + filter 处理

### 5.1.4 Room 2 正式处理
以上 3 点当前继续统一归类为：
- implemented reality
- 但不自动升格为长期 frozen public contract

也就是说：
- 当前无鉴权 ≠ 长期永远无鉴权
- 当前 direct data response ≠ 长期永远不需要 envelope

## 5.2 当前已实现的云端 REST 端点（在 `v0.2.1` 基础上增量吸收）

### 5.2.1 系统 / 健康
- `GET /health`

### 5.2.2 学习
- `GET /me/new-words/next`
- `POST /me/new-words`

### 5.2.3 复习
- `GET /me/review-groups/next`
- `POST /review-attempts`
- `POST /review-attempts/local-batch` **（P3.3.16 新增）**

### 5.2.4 聚合
- `GET /me/today`

### 5.2.5 Session
- `POST /sessions`
- `POST /sessions/:id/finish`
- `GET /sessions/:id`

### 5.2.6 签到
- `POST /check-ins`
- `GET /check-ins/today`

### 5.2.7 结算 / 奖励 / 钱包 / 商店 / 副机制
- 延续 `v0.2.1` 已收口的相关端点现实
- 本轮不因 P3.2 / P3.3.16 重写其主结构
- 但 P3.3.16 新增 local batch 会进入既有后端结算链

### 5.2.8 Backup / restore（P3.2 增量吸收）
- `POST /me/backup`
- `GET /me/backup/latest`
- `GET /me/backup/latest/snapshot`

Room 2 正式表述：
- 以上 3 个端点已不应继续只存在于 patch 文档
- 它们是当前 code-truth implemented reality 的一部分
- 但它们仍属于 **manual backup / restore** 体系，不是 realtime sync API

---

## 6. Layer B — Backup / restore API reality（P3.2）

## 6.1 `POST /me/backup`
### 6.1.1 作用
上传当前设备的 full snapshot，供云端保存为 latest backup。

### 6.1.2 当前请求现实最小结构
当前请求 payload 至少围绕以下语义组织：
- `snapshot`
  - `schema_version = p3_2_snapshot_v1`
  - `exported_at`
  - `export_format`
  - `device`
    - `device_id`
    - `device_model`
  - `settings`
  - `progress`
    - `word_records`
    - `card_states`
    - 其他本地进度数据
- 顶层可带 `schema_version`

### 6.1.3 当前响应现实
成功时返回至少包含：
- `status = succeeded`
- `backup_id`
- `uploaded_at`
- `schema_version`
- `device_id`
- `device_model`

失败时当前现实仍可能返回业务失败载荷，例如：
- `status = failed`
- `error_code`
- `message`

### 6.1.4 Room 2 正式处理
- 当前 backup upload 已是 implemented reality
- 但其 latest-only 策略、失败返回语义与是否长期保持 `200 + status=failed`，当前仍不自动升格为长期 frozen contract

## 6.2 `GET /me/backup/latest`
### 6.2.1 作用
读取最新备份的元数据，而不是完整 snapshot 内容。

### 6.2.2 当前响应现实最小结构
有备份时最少包括：
- `backup_id`
- `schema_version`
- `uploaded_at`
- `snapshot_size`
- `status`
- `device_id`
- `device_model`

无备份时最少包括：
- `status = no_backup_yet`
- 相关字段为 `null`

### 6.2.3 当前语义边界
- `latest` 表示当前 latest backup metadata
- 不表示 restore 已发生
- 不表示当前设备已与 cloud 一致
- 不表示其他设备已同步完成

## 6.3 `GET /me/backup/latest/snapshot`
### 6.3.1 作用
返回最新完整 snapshot，供客户端在用户确认后执行 restore apply。

### 6.3.2 当前响应现实最小结构
有备份时最少包括：
- `status = available`
- `schema_version`
- `uploaded_at`
- `device_id`
- `device_model`
- `snapshot`

无备份时最少包括：
- `status = no_backup_found`
- `snapshot = null`

### 6.3.3 当前兼容性现实
当前恢复链可接受：
- `p3_2_snapshot_v1`
- `p3_1_snapshot_v2`（降级恢复）

### 6.3.4 Room 2 正式处理
- 当前 latest snapshot fetch 已是 implemented reality
- 但 restore apply 仍主要发生在客户端确认后的本地侧，不代表服务端已经提供完整 restore orchestration API

---

## 7. Layer B — Local review batch API reality（P3.3.16）

## 7.1 `POST /review-attempts/local-batch`
### 7.1.1 背景
P3.3.16 切入后，ReviewPage 的非续习路径允许由本地 FSRS 队列产出一批 review attempts，再整体提交给后端进入 final fact / settlement 链。  
该批次：
- 不要求已有云端 `reviewGroupId`
- 不等于 active continuation path
- 不代表 `review_group` 已退场

### 7.1.2 当前作用
提交本地来源的一批 review attempts，并由后端完成：
- attempt 接收
- 幂等判断
- 今日复习进度更新
- learning day 相关事实更新
- 奖励 / 结算链处理

### 7.1.3 当前请求现实最小结构
当前请求至少围绕以下语义组织：
- 批次级标识 / idempotency 信息
- 本地来源的 word attempts 集合
- 每个 attempt 的 word identity / rating / correctness / answered timing / local scheduling facts
- 必要的 client / batch context

### 7.1.4 当前响应现实最小语义
当前响应至少需要能表达：
- batch 是否 accepted
- 是否命中幂等 / duplicate
- 本次影响的最小结算 / 进度结果
- 是否完成本轮 local batch 提交

### 7.1.5 Room 2 正式处理
- 接受该端点为 implemented reality
- 接受客户端当前已存在 `submitLocalReviewBatch()` 接口现实
- 但不自动把它写成统一 review serving contract，也不写成 public API 的最终完成态

## 7.2 当前边界
### 7.2.1 本端点当前不代表
1. `review_group` continuation 统一切到 local batch
2. active continuation 不再依赖 cloud anchor
3. planner merge / unified planner 完成
4. final fact owner shift 完成
5. API core semantics 已整体重写

### 7.2.2 当前已知风险
1. 本地 batch 提交后若 backend 宕机，当次结算当前仍可能丢失
2. 当前没有“本地最终事实 fallback”型 contract
3. local batch route 已是 code-truth reality，但其长期命名、分层与是否扩张仍需后续判断

---

## 8. Layer B — 本地 service / client adapter reality

## 8.1 当前继续接受的本地侧接口现实
除云端 REST 外，当前客户端 / 本地 service 仍是 API 现实的一部分。  
当前已应正式接受：
- 本地 backup export / import orchestration
- 本地 snapshot apply
- 客户端 `submitLocalReviewBatch()` 调用适配

### 8.1.1 本地 restore apply 语义
Room 2 当前正式接受：
- fetch snapshot success ≠ restore success
- 用户确认后本地 apply success，才改变本机 runtime state
- restore 仍是 manual-only flow

### 8.1.2 Local review batch 的客户端接口现实
当前移动端代码现实已存在：
- `LocalWordAttempt`
- `submitLocalReviewBatch()`

Room 2 正式处理：
- 它们属于当前 client adapter / local service reality
- 但不自动升格为 SDK-level frozen public contract

---

## 9. Layer C — Candidate contracts not fully implemented

### 9.1 Backup / restore 方向当前仍未升格为 full sync contract
以下内容当前仍不得写成已实现事实：
1. real-time sync
2. background sync
3. multi-device merge
4. conflict auto-resolution
5. backup success = sync success
6. snapshot fetch = restore completed

### 9.2 Local review batch 方向当前仍未升格的内容
以下内容当前仍不得写成已实现事实：
1. `review_group` true exit
2. active continuation 全面切 local source
3. homepage review route fully switched
4. planner-aware auto-routing runtime
5. final fact owner shift
6. active API baseline uplift beyond documented delta

### 9.3 当前全局现实但未冻结的 API 元信息
1. 无鉴权
2. direct data response
3. latest-only backup model
4. `local-batch` route naming
5. 失败响应 shape 的长期稳定性

---

## 10. Room 2 本轮建议写回

### 10.1 建议吸收进 full baseline 的内容
以下内容建议由 Room 1 在合适轮次吸收进 next-step API baseline：
1. 3 个 backup / latest snapshot 端点
2. `p3_2_snapshot_v1` + device fields + `card_states`
3. `POST /review-attempts/local-batch`
4. 客户端 `submitLocalReviewBatch()` 接口现实
5. local batch 进入既有后端结算链的 API 语义

### 10.2 本轮不建议静默升格的内容
以下内容当前仍不建议静默升格：
1. `review_group` true exit
2. unified planner / merged serving contract
3. full sync / merge platform narrative
4. final fact owner shift
5. 对所有 dev-mode 实现细节的长期 public contract 固化

---

## 11. 结论

> **`v0.2.2` 的价值，不是把 API 文档改成另一套，而是把 `v0.2.1` 之后已经真实影响客户端接入和后端联调的 P3.2 / P3.3.16 接口现实，正式并回 full baseline。**

当前 Room 2 judgment 是：
- 三类接口现实主骨架不变
- backup / restore 端点已应进入主 API 文档
- local review batch 已成为已落地接口现实
- 但 `review_group` true exit、full sync 化叙事、fact owner shift 与更大范围的 API uplift 仍不得偷写成当前事实
