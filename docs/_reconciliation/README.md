# 文档对齐 — 元信息

## 基本信息

| 项 | 值 |
|---|---|
| 对齐时间 | 2026-04-08 |
| 基准 commit | `bface75` (refactor/architecture 分支) |
| 执行依据 | `tasks/doc-reconciliation-playbook.md` |

## 技术栈快照

| 端 | 技术 |
|---|---|
| 云端 | NestJS 10 + TypeScript 5.1 + PostgreSQL（pg 驱动，无 ORM） |
| 本地端 | Flutter (Dart >=3.0) + sqflite（旧）+ drift（新）+ SharedPreferences |
| SRS | `fsrs` v2.0.1（FSRS-6，纯 Dart，本地端） |
| Monorepo | `apps/api/`（云端）+ `apps/mobile/`（本地端） |

## 代码规模

| 维度 | 云端 | 本地端 |
|------|------|--------|
| Endpoint / Service | 26 REST | 8 service |
| DB 表 | 25 PG | 8 SQLite + 5 SP key |
| 页面 | — | 14 |
| Migration | 2 SQL | drift v1→v2 |

## 旧文档

| 文档 | 路径 | 大小 |
|------|------|------|
| BR | `docs/design/BR-OPP-001_v0.1.9_full.md` | 71 KB |
| UI Spec | `docs/design/UI_SPEC_v0.1.4.md` | 51 KB |
| API | `docs/design/背单词喵喵app_API设计草案_v0.1.4.md` | 54 KB |
| DB | `docs/design/背单词喵喵app_DB设计草案_v0.1.5.md` | 68 KB |

## 双端架构

- 同步模式：**本地优先（local-first）**
- 学习记录：SQLite 立即写 → 后台 fire-and-forget 同步
- 词库缓存：一次性从 API 分页下载
- 备份：手动触发，全量快照，full replace restore
- 鉴权：无（dev 模式，单用户 dev-user-001）

## 已知疑点（Phase 0 发现）

1. 两套本地 DB 并存（raw sqflite + drift），同文件 `meow_progress.db`
2. 云端 `user_word_progress` 表疑似未使用（旧 SRS 遗留？）
3. 云端 review_groups naive 算法与本地 FSRS 并存
4. 备份/恢复未包含 FSRS 3 张新表
5. `local_progress_repository.dart` SharedPreferences 存储与 SQLite 重叠
