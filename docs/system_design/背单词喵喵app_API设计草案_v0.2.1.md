# 背单词喵喵 App API 设计草案 v0.2.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.2.1
- **Date:** 2026-04-08
- **Status:** reconciled baseline candidate / ready for Room 1 review
- **Role card:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Purpose:** 基于当前推进层 SSOT、`v0.2.0` 代码反读稿、`v0.1.4` 候选回写稿与 `R2_v0.2.0_CodeTruth_Reconciliation_Checklist_v0.1.md`，重做一版真正可被 Room 1 判断是否 pin 的 Room 2 API 候选基线。

---

## 0. 文档定位

本稿不是：
- `背单词喵喵app_API设计草案_v0.2.0.md` 的直接通过版
- `背单词喵喵app_API设计草案_v0.1.4.md` 的继续 patch 版
- Room 1 已 pin 的 active API baseline

本稿只做一件事：

> **把当前 API 技术事实拆成 3 层并收口成单文件候选基线：**
> 1. Runtime active reference
> 2. Code-truth implemented reality
> 3. Candidate contracts not fully implemented

---

## 1. 输入依据

### 1.1 当前治理层 / 运行层依据
- `ORG_v0.3.1.md`
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `room1_v0.2.0.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- `Main_updated_2026-04-07_v17.md`
- `STATUS_updated_2026-04-07_v16.md`

### 1.2 当前 runtime active basis（推进层已 pin）
- BR active: `BR-OPP-001_v0.1.7.md`
- DB active: `背单词喵喵app_DB设计草案_v0.1.4.md`
- API active: `背单词喵喵app_API设计草案_v0.1.3.md`

### 1.3 当前 sync / review candidate inputs
- `背单词喵喵app_API设计草案_v0.1.4.md`
- `背单词喵喵app_DB设计草案_v0.1.5.md`
- `背单词喵喵app_API设计草案_v0.2.0.md`
- `背单词喵喵app_DB设计草案_v0.2.0.md`
- `R2_v0.2.0_CodeTruth_Reconciliation_Checklist_v0.1.md`
- `BR-OPP-001_v0.2.1.md`
- `UI_SPEC_v0.2.1.md`

### 1.4 吸收原则
1. 吸收 `v0.2.0` 的 code-truth implemented reality
2. 不把 `v0.2.0` 直接当成唯一正式 API 基线
3. 保留 `v0.1.4` 已收口但未 fully landed 的 candidate contracts
4. No silent contract drift

---

## 2. 三层阅读方式

### Layer A — Runtime active reference
说明当前推进层已 pin 的 active API baseline 是什么。

### Layer B — Code-truth implemented reality
说明当前代码里真实已经存在的 REST / 本地 Service / 同步 flow 是什么。

### Layer C — Candidate contracts not fully implemented
说明 Room 2 / Room 3 / Room 1 已收口，但代码还未 fully landed 的 API 契约是什么。

---

## 3. Room 2 总判断

### 3.1 总结论
> **v0.2.1 采用 “reconciled baseline” 路线。**

也就是：
- 保留 active API baseline 的引用位置
- 正式吸收 `v0.2.0` 的代码现实
- 显式保留 `v0.1.4` 中仍有价值的 candidate contracts
- 清掉 `v0.1.4` 里的旧 P2 metadata、旧 Base URL、旧 auth、旧 envelope 假设

### 3.2 当前最重要的 API 架构判断
1. 当前 API 已不是“只有云端 REST”
2. 必须正式接受三类接口现实：
   - 云端 REST API
   - 本地端 Service 层
   - 同步 flows
3. 当前系统的真实边界是：
   - 云端负责 today 聚合 / review_group / 奖励 / 商店 / 签到 / 结算
   - 本地负责 FSRS / review logs / local settings / 部分学习运行态
   - backup / restore 是混合 flow
4. 当前仍不是：
   - full sync
   - background sync
   - merge platform

---

## 4. Layer A — Runtime active reference

### 4.1 当前推进层已 pin 的 active API baseline
当前推进层 `Main / STATUS` 仍将以下文件视为 active runtime API baseline：
- `背单词喵喵app_API设计草案_v0.1.3.md`

### 4.2 本稿与 active baseline 的关系
> **本稿是推荐 next-step API baseline candidate，不自动替代 active API baseline。**

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
以上 3 点当前统一归类为：
- implemented reality
- 但不自动升格为长期 frozen technical contract

也就是说：
- 当前无鉴权 ≠ 永远无鉴权
- 当前 direct data response ≠ 永远不再需要统一 envelope

## 5.2 当前已实现的云端 REST 端点（Room 2 正式吸收）

### 5.2.1 系统 / 健康
- `GET /health`

### 5.2.2 学习
- `GET /me/new-words/next`
- `POST /me/new-words`

### 5.2.3 复习
- `GET /me/review-groups/next`
- `POST /review-attempts`

### 5.2.4 聚合
- `GET /me/today`

### 5.2.5 Session
- `POST /sessions`
- `POST /sessions/:id/finish`
- `GET /sessions/:id`

### 5.2.6 签到
- `POST /check-ins`
- `GET /check-ins/today`

### 5.2.7 结算
- `POST /settlements/learning-rounds`
- `GET /settlements/:sourceEventId`

### 5.2.8 二级激励 / 商店 / 装备
- `GET /me/secondary-summary`
- `POST /me/feed`
- `GET /shop/catalog`
- `POST /shop/purchases`
- `GET /me/inventory`
- `GET /me/equipment`
- `POST /me/equipment/equip`
- `POST /me/equipment/unequip`

### 5.2.9 设置 / 备份 / 词库
- `PUT /me/settings/daily-goal`
- `POST /me/backup`
- `GET /me/backup/latest`
- `GET /me/backup/latest/snapshot`
- `GET /books/:bookId/words`

## 5.3 当前已实现但必须特别标注的现实差异

### 5.3.1 `daily_goal`
当前代码现实：
- `PUT /me/settings/daily-goal` 已实现
- 云端更新范围偏向 `1–100`

本稿中的正式表述：
- 这是 implemented reality
- 但它与 P3.1 delta 中 `daily_goal local-first + 1–500 recommendation` 存在分歧
- 因此当前必须被视为：
  - implemented divergence
  - pending reconciliation item

### 5.3.2 `/me/today`
当前代码现实：
- 返回结构比旧文档更扁平
- 已包含 `today_primary_action`、`review_summary` 等更强聚合字段

本稿中的正式表述：
- 这些字段属于 implemented reality
- 但是否把其中所有字段都升格为长期 frozen contract，仍需服从 BR / Room 1 pin

---

## 6. Layer B — Code-truth implemented reality（本地 Service + 同步）

## 6.1 当前必须正式记录的本地 Service reality
当前代码现实中，本地至少已存在以下服务层：
1. `StudyService`
2. `FsrsService`
3. `SessionBuilder`
4. `WordCacheService`
5. `LocalSettingsService`
6. `LocalProgressRepository`
7. `BackupUploadService`
8. `BackupRestoreService`

这些对象当前应被写入 Room 2 API 基线，作为：
- 本地接口 reality
- 双端架构现实的一部分

## 6.2 当前必须正式记录的同步 flows
当前至少要明确存在 3 类 flow：
1. 学习记录同步
2. backup upload
3. backup snapshot fetch / restore flow

### 6.2.1 Room 2 正式判断
- 这些属于 implemented / partly implemented mixed reality
- 文档里必须保留它们
- 但不能把它们误写成：
  - full sync
  - background sync
  - merge

---

## 7. Layer C — Candidate contracts not fully implemented

## 7.1 P3.1 backup / restore 候选 API 契约
以下内容在 `v0.1.4` 中已经被 Room 2 写回，当前必须继续保留：
1. 更完整 latest backup metadata contract
2. `POST /me/backups/latest/restore-precheck`
3. `POST /me/backups/latest/download`
4. `POST /me/backups/latest/restore-apply`
5. upload / download / restore success semantics 分层
6. overwrite safety / checksum / versioning / restore safety

### 7.1.1 当前状态
- `restore-precheck` / `download` / `restore-apply` 在 `v0.2.0` 中被标成 pending
- 本稿将其保留为：
  - approved candidate contracts
  - not fully landed

### 7.1.2 Room 2 正式表述
这些 contract 不能因为当前代码未 fully landed 就在 `v0.2.1` 中消失。

## 7.2 `daily_goal` 的 local-first 候选 API 边界
Room 2 继续保留以下内容为 candidate contract：
1. `daily_goal` 本地即时生效
2. 不回溯重算历史日
3. 进入 backup snapshot 的是 `settings.daily_goal`
4. restore 可能覆盖最小设置层

### 7.2.1 当前状态
- 代码 reality：云端有 `PUT /me/settings/daily-goal`
- candidate contract：仍强调 local-first 方向

### 7.2.2 Room 2 处理方式
本稿不强行裁定二者谁最终胜出，而是显式写为：
- implemented divergence
- pending reconciliation item

## 7.3 仍未冻结的核心 Pending
以下内容继续保留为 Pending：
1. auth 最终方案
2. response envelope 最终方案
3. `latest-only restore` 是否长期 frozen
4. 完整 stats summary contract
5. 完整 SRS / review priority / CTA winner 的最终 API 收口

---

## 8. Room 2 推荐的 reconciled API 口径

## 8.1 对接口面的正式分类

### A. Runtime active-backed + implemented
- P2 主学习 / review / session / check-in / settlement / secondary minimal API

### B. Implemented reality that must be absorbed
- `/api/v1`
- no auth (dev mode)
- direct data response
- `PUT /me/settings/daily-goal`
- `POST /me/backup`
- `GET /me/backup/latest`
- `GET /me/backup/latest/snapshot`
- `GET /health`
- `GET /check-ins/today`
- `GET /books/:bookId/words`
- 本地 Service 层
- 同步 flows

### C. Candidate contracts not fully implemented
- `restore-precheck`
- `download` / `restore-apply` 的完整分层 contract
- 更完整 latest backup metadata contract
- `daily_goal` local-first API boundary
- 统一 envelope 的未来恢复方案
- auth 正式化方案

---

## 9. 当前必须修正的旧稿残留（已在 v0.2.1 处理）

本稿相对于 `v0.1.4` 已正式处理：
1. 删除旧 P2 metadata 残留
2. 不再把旧 Base URL / Bearer token / response envelope 写成当前事实
3. 不再把 backup path 单复数写错
4. 把 `PUT /me/settings/daily-goal` 已实现现实正式吸收
5. 把 restore-precheck / download / restore-apply 改成：
   - candidate contract
   - current code pending

---

## 10. Room 1 吸收建议（Main / Status）

若 Room 1 接受本稿，建议吸收为：

1. **Evidence**
   - Room 2 已交付 `API v0.2.1`，完成了 API 代码现实与候选契约的三层整合。

2. **Decision（建议待审）**
   - `API v0.2.1` 作为 next-step Room 2 API baseline candidate。
   - 在 Room 1 未进一步 pin 前，runtime active 仍保持 `API v0.1.3`。
   - 后续若要 pin 新 active API baseline，优先 pin `v0.2.1`，而不是直接 pin `v0.2.0`。

3. **Status**
   - Room 2 已完成 API code-truth reconciliation。
   - 下一步若继续推进，应由 Room 1 判断是否采用 `v0.2.1` 作为新 active / review basis。

---

## 11. Room 2 最终一句话

> **`API v0.2.1` 不是“继续 patch 旧稿”，也不是“代码即唯一真相”；它是当前项目最适合被 Room 1 审核与 pin 的 Room 2 整合候选基线。**
