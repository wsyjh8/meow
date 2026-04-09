# Baseline Summary

> 背单词 + 云养猫 — Stage 4 / P1 Bootstrap

## 产品方向

**学习驱动型轻养成产品**

- **主机制**: 背单词学习
- **副机制**: 猫猫陪伴、奖励承接、轻成长反馈
- **原则**: 副机制不压过主学习链路

## 当前阶段

- **Stage**: MVP Readiness
- **Sub-stage**: Stage 4 — Implementation Kickoff
- **Phase**: Phase 0 — Repo Bootstrap

## 已冻结规则 (Frozen Rules)

以下规则已冻结，后续实现必须严格遵守：

### 1. review_group 最小合同

- 后端生成、后端持有
- 同一用户同一时刻只允许一个 active group
- 本组完成只推进今日复习进度
- 本组完成不自动等于今日复习完成
- 允许同一 active group 跨 Session 延续
- 同一 group 不得重复完成、重复结算、重复发奖

### 2. check_in / learning_day / streak 关系

- `check_in`、`learning_day`、`streak` 是三类独立事实
- `check_in=true` 不自动等于 `learning_day=true`
- `learning_day=true` 不自动等于 `streak` 延续
- 当前 MVP 下 `streak` **按 `check_in` 驱动**
- 自然日统一按用户时区折算出的 `local_date`

### 3. 页面 / 结算边界

- 结算触发 ≠ 奖励到账
- 本组完成 ≠ 今日完成
- 签到成功 ≠ learning day 成立
- Session ended ≠ valid session completed

### 4. 关键状态命名 (Canonical Terms)

统一使用以下命名：

- `daily_goal_status`
- `session_validation_status`
- `reward_settlement_status`

## Pending 规则 (未冻结 / Blocked)

以下内容当前仍是 **pending**，不得在代码中偷偷写死：

1. `review_group` 的 group size
2. `review_group` 的分组算法
3. review priority 算法
4. 完整 SRS
5. 熟练度 / 掌握阈值算法
6. 今日页主 CTA winner 详细仲裁
7. 统计页完整规格
8. 未来是否把 `streak` basis 从 `check_in` 改成 `learning_day` 或组合条件

## 技术栈

| 部分 | 技术 |
|------|------|
| Backend | Node.js + TypeScript + NestJS |
| Frontend | Flutter (Dart) |

## Repo 结构

```
meow/
├── apps/
│   ├── api/          # NestJS 后端服务
│   └── mobile/       # Flutter 移动客户端
├── docs/             # 项目文档
├── scripts/          # 启动/工具脚本
├── README.md
├── .gitignore
└── .editorconfig
```

## 主链路模块位置 (预留)

Backend routes/controllers 已为以下主链路预留位置：

- `today` — 今日页聚合读取
- `study-attempts` — 新词学习提交
- `review-groups` — review_group 管理
- `review-attempts` — 复习提交
- `sessions` — Session 启动/finish/validation
- `check-ins` — 签到
- `settlements` — 结算层

## 开发原则

1. 先搭骨架，再落业务
2. 先主机制，再副机制
3. 先可运行，再扩细节
4. 不做过度工程化
5. 不在未冻结规则上偷拍板

## 下一步

Phase 1 将实现 P1 主机制最小可运行闭环。
