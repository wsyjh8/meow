# Meow — 背单词 + 云养猫

> 学习驱动型轻养成产品

## 项目定位

- **主机制**：背单词学习
- **副机制**：猫猫陪伴、奖励承接、轻成长反馈
- **原则**：副机制不压过主学习链路

## 当前阶段

- **Stage**: MVP Readiness
- **Sub-stage**: Stage 4 — Implementation Kickoff (Phase 0: Repo Bootstrap)

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

## 快速启动

### Backend

```bash
cd apps/api
npm install
npm run start:dev
```

访问 `http://localhost:3000/api/v1/health` 验证。

### Docker

```bash
docker compose up --build
```

启动 NestJS API 和 PostgreSQL。API 会等待 PostgreSQL 就绪，自动执行
pending migrations，然后监听 `http://localhost:3000`。

常用命令：

```bash
docker compose logs -f api
docker compose down
docker compose down -v
```

### Mobile (Flutter)

```bash
cd apps/mobile
flutter pub get
flutter run
```

## 已冻结规则

详见 [docs/baseline-summary.md](docs/baseline-summary.md)。

## 开发原则

1. 先搭骨架，再落业务
2. 先主机制，再副机制
3. 先可运行，再扩细节
4. 不做过度工程化
5. 不在未冻结规则上偷拍板

## License

MIT
