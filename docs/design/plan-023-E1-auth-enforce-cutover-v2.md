# Plan: 需求 23 Phase E1 — AUTH_ENFORCE=true 切流 (v2)

**Plan Version:** v2（v1 → v2 大重写，吸收两份外部评审）
**Status:** draft（待用户确认）
**Branch:** `feature/user-auth`
**性质:** **operations / deployment plan**

**前序:** A/B/C/D + β.5b/c + audit §6 残留 + Phase G

**关联:**
- [plan-023-用户系统与用户数据隔离-v2.md](plan-023-用户系统与用户数据隔离-v2.md) §1.1 / §10 D13
- [plan-023-E1-auth-enforce-cutover-v1.md](plan-023-E1-auth-enforce-cutover-v1.md)（前一版，本文重写）
- [audits/prd-§9-acceptance-coverage.md](audits/prd-§9-acceptance-coverage.md) Phase G 产出，本 plan 的 readiness gate

**日期:** 2026-05-11

---

## 0. v2 重写说明

v1 收到两份外部评审，**16 项指控经 grep 核实全部成立**。其中：

- **4 项需新代码（E1 前置 prerequisite，必须先修）**：
  - PR-E0.1: mobile backup baseUrl 硬编码 → 改 apiV1Base
  - PR-E0.2: BackupController.storeBackup 副作用清理（不再触发 saveToDisk）
  - PR-E0.3: assertProductionAuthEnforce 单测（4 case）
  - PR-E0.4: /auth/guest load test 脚本

- **12 项 plan-level 修订**:
  - readiness gate 增补：epoch in-flight 验证、G4 migration replay、β.5c 全字段对账、Phase F 状态
  - D6 加 verification 方法（应用市场 + 埋点）
  - sign-off 三阶段拆分（E1 PR 完成 / staging cutover 完成 / production operator sign-off）
  - 监控阈值收紧（/auth/login 30% → 10-15%）
  - 监控数据源明示（不能只有指标名）
  - dev 环境 AUTH_ENFORCE 策略
  - JWT_SECRET 生成/存储/轮换流程
  - migration apply 命令明示
  - rollback 数据脏审计 SQL
  - audit §6 数字口径统一（与 Phase G 输出一致：16/18 ✓ caveat 2）
  - commit .env 操作改为 env vars / IaC playbook（.env gitignore）
  - E2 推 Phase F 与 D6 不处理的内部冲突澄清

### v2 主要变化

| 维度 | v1 | v2 |
|------|----|----|
| 切流前必备 PR | 0（全部 Phase G 完成即可） | **4 个 prerequisite PR**（PR-E0.1~E0.4） |
| Readiness gate 项数 | 18 | **27**（补 9 项：epoch / G4 / β.5c 全字段 / Phase F 状态 / load test / assertion 单测 / UI 文案 / migration runner / baseUrl 排除） |
| D6 老客户端处理 | "假设无老 App 流通" 无 verify | **D6 必须有 3 种 verify 方法之一通过才能进 staging** |
| Sign-off | 1 个 "需求 23 完整闭环" | **3 阶段**：E1 PR 合并完成 / staging soak 通过 / production operator sign-off |
| 监控数据源 | 仅指标名 | **每个指标明示数据源**（log 查询语法 / APM / 移动端埋点） |
| commit .env | "commit 改动" ❌ | **改 .env.example + IaC / k8s secret，禁止 commit 真 .env** |
| 监控阈值 /auth/login | 30% | **10-15%**（30% 已经是严重 incident） |

v1 保留为历史版本。

---

## 1. Phase E1 真实 scope（v2 严格定义）

### 1.1 Phase E1 三阶段拆分（v2 评审采纳 R1 P2#6）

| 阶段 | 类型 | 完成标志 |
|------|------|---------|
| **E1-Phase A** | Prerequisite 代码 fix | PR-E0.1~E0.4 全部 merge |
| **E1-Phase B** | Plan / Doc 修订 | plan v2 + readiness gate + playbook 全完成 |
| **E1-Phase C** | Staging cutover + soak | staging AUTH_ENFORCE=true e2e + 24h soak 通过 |
| **E1-Phase D** | Production operator handoff | playbook 交付 + on-call ready；**生产实际切流由用户操作，不在 model scope** |

⚠️ **「需求 23 完整闭环」的精确定义**：E1-Phase A+B+C 完成 + Phase G 通过 + production operator sign-off（user 手动完成 §5 playbook）。

### 1.2 在范围

| 子项 | 类型 | 工作量 |
|------|------|--------|
| **PR-E0.1** mobile backup baseUrl 硬编码 → apiV1Base | code | 1h |
| **PR-E0.2** BackupController.storeBackup 副作用清理 | code | 1h |
| **PR-E0.3** assertProductionAuthEnforce 4-case 单测 | code | 0.5h |
| **PR-E0.4** /auth/guest load test 脚本 + 跑一次 | code+ops | 2h |
| E1.1 readiness 验证（27 项 gate） | doc 验收 | 1h |
| E1.2 staging cutover（修 env vars + 严格模式 e2e） | 实操 | 2h |
| E1.3 staging soak（24h 监控） | 等待+观察 | 24h elapsed / 1h active |
| E1.4 production playbook + monitoring + rollback 文档 | doc | 2h |

**Claude active 总工时：~10h**（v1 估 5h）。新增 4 个 prerequisite PR 是主要增量。

### 1.3 不在范围（v2 收紧）

- **Production 实际切流操作**（仅 playbook，用户手动）
- 移动端强制升级 UX（min_app_version 拦截）——**v2 明示不做**：D6 决定后 E2 永久从 plan v2 §1.1 移除（与 D6 "不处理" 对齐，解决 v1 内部表态冲突）
- 灰度切流（D2 已决一次性）
- Phase F UX 文案细节（如有 Phase F 残余）

---

## 2. 决策点（D1-D9，v2 — D1-D5 不变，D6 加 verify，新增 D7-D9）

> **D1-D5 同 v1（用户已拍板）**：24h soak / 一次性切流 / rollback 阈值 / 监控矩阵 / 周二三上午 10:00。

### D6 — 老客户端处理（**v2 加 verification 方法**，评审采纳 R2 P1#2）

**推荐：(a) 不处理**，但**进入 staging cutover 之前必须用以下 3 种方法之一 verify "无老 App 流通"**：

1. **应用市场版本查询**：登录应用市场后台（应用宝 / 华为 / iOS App Store Connect），看历史发布版本。最早发布版本的 build 时间应在 Phase B commit `9d992c8`（2026-05-10）之后。如果有更早版本 → 必须改 (b)。
2. **移动端埋点版本分布**（如已接入 analytics）：拉过去 7 天 DAU 的 app_version 分布。出现 `< X.Y.Z`（Phase B 发布版本号）的活跃用户占比 → 必须改 (b)。
3. **零发布证明**：如果项目尚未发布到任何应用市场（只有内测 / TestFlight），并且所有内测设备都装了 Phase B 之后版本 → (a) 可行。

任一 verify 路径达成才能进 E1.2 staging cutover。**不允许"凭印象认为没有老 App"**。

### D7 — Dev 环境 AUTH_ENFORCE 策略（**v2 新增**，评审采纳 R2 漏 6）

**推荐：dev 默认 AUTH_ENFORCE=false，但 e2e 一律 AUTH_ENFORCE=true 跑。**

- dev 本地保留 permissive 不影响开发流；
- e2e CI 默认 AUTH_ENFORCE=true 防止 silent fallback bug；
- 文档化：开发新功能时如果有 `repositories.xxx()` 调用 → 必须显式从 AuthGuard 拿 user.id 传入，permissive fallback 不是 production behavior。

### D8 — JWT_SECRET 管理（**v2 新增**，评审采纳 R2 漏 14）

**生成命令**（明示在 playbook）：
```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
# 96 字符 hex（48 bytes），远超 16 字符最低要求
```

**存储位置**：
- staging: 环境变量管理（如 docker compose env_file 或 k8s secret）
- production: 同上 + 与 staging 严格分离（不复用）

**轮换流程**（v1 未明示）：
- 不在切流期内轮换（避免引入额外风险）
- 切流稳定后（>30 天）按需轮换：新 secret 推到所有 backend 实例 → rolling restart → 旧 token 一律 401 → 用户重新登录
- 不做 dual-secret rotation（KISS）

### D9 — Migration 010 apply 流程（**v2 新增**，评审采纳 R2 漏 11）

```bash
# Migration runner（项目现有）：
cd apps/api && npm run db:migrate

# 状态查询：
cd apps/api && npm run db:migrate:status
# 期望: 010_backup_snapshots in "Applied"

# Production apply 流程：
# 1. 切流前一天，连 production DB 跑 npm run db:migrate
# 2. 确认 backup_snapshots 表存在 + index 已建
# 3. 失败 rollback: npm run db:migrate:down 回退 010
```

---

## 3. Phase E1 Prerequisite PR 详细范围（**v2 新增**）

### 3.1 PR-E0.1 — Mobile backup baseUrl 硬编码 → apiV1Base（评审采纳 R1 P1#2）

**问题：** 移动端 backup 上传 / 恢复 / 自动备份路径硬编码 `http://10.0.2.2:3000/api/v1`（Android emulator 本机映射 IP）：
- `settings_page.dart:89 / 159 / 494`（3 处）
- `auto_backup_service.dart:41`（1 处）

生产环境必然连不上。

**改动：**

1. 全部 4 处改为引用 `apiV1Base`（已通过 `--dart-define=API_BASE=...` 编译时注入）：
   ```dart
   import '../../core/config/api_base.dart';
   // ...
   final uploader = BackupUploadService(baseUrl: apiV1Base, ...);
   ```

2. 单测 / widget test 增加：assert backup service 用的是 apiV1Base 而非硬编码。

**验收：** grep `10.0.2.2` 在 `apps/mobile/lib/` 0 命中。

### 3.2 PR-E0.2 — BackupController.storeBackup 副作用清理（评审采纳 R1 P1#1）

**问题：** Phase D `BackupController` 同时调 `persistence.saveBackupForUser(user.id, ...)` AND `devStore.storeBackup(...)`。后者内部 `saveToDisk()` 用 `this.userId`（默认 dev-user-001）触发错误的 PG persist 链路 — 即 plan D v2 §0 自己识别的 P0。

代码 `backup.controller.ts:106-130` 注释承认是"故意保留"，但实际产生副作用。

**改动方案 A（推荐）**：BackupController 只调 `persistence.saveBackupForUser`，**移除** `devStore.storeBackup` 调用。
- 配套：`devStore.getLatestBackupMeta` / `getBackupSnapshot` 已被 BackupController 旁路（plan D PR-D-β），删除后 in-memory map 不再被读 → 可保留 map（避免大范围 ripple）但加 deprecation 注释。

**改动方案 B**：保留 storeBackup 但让它**不再触发 saveToDisk**：加 `internalOnly: true` flag。

**推荐 A**：彻底切断错误链路，符合 plan D §0 「BackupController 旁路 dev-store」的设计意图。

**验收：**
- BackupController 上传备份 → PG `backup_snapshots` 行存在 ✓
- BackupController 上传备份 → 不触发额外 `pg-persistence.saveAsync(dev-user-001)` 调用（捕获日志验证）
- 测试：`backup_e2e_test.ts` 上传非 dev 用户备份，确认 PG 中 `backup_snapshots` row user_id 与 token user 一致

### 3.3 PR-E0.3 — assertProductionAuthEnforce 单测（评审采纳 R2 P1#3）

**问题：** 函数在 `auth.guard.ts:92` 定义、`main.ts:12` 调用，但 grep 全 `apps/api/test/` 0 单测命中。Staging 环境 NODE_ENV != production，assertion 永远是 no-op — 切流前对它正确性 0 验证。

**改动：** `apps/api/src/auth/__tests__/auth-guard.spec.ts`（新增 unit test 文件，或加到现有 e2e 之外）：

```ts
describe('assertProductionAuthEnforce', () => {
  let originalNodeEnv: string | undefined;
  let originalAuthEnforce: string | undefined;

  beforeEach(() => {
    originalNodeEnv = process.env.NODE_ENV;
    originalAuthEnforce = process.env.AUTH_ENFORCE;
  });
  afterEach(() => {
    process.env.NODE_ENV = originalNodeEnv;
    process.env.AUTH_ENFORCE = originalAuthEnforce;
  });

  it('production + AUTH_ENFORCE=true → no throw', () => {
    process.env.NODE_ENV = 'production';
    process.env.AUTH_ENFORCE = 'true';
    expect(() => assertProductionAuthEnforce()).not.toThrow();
  });

  it('production + AUTH_ENFORCE=false → throw', () => {
    process.env.NODE_ENV = 'production';
    process.env.AUTH_ENFORCE = 'false';
    expect(() => assertProductionAuthEnforce()).toThrow();
  });

  it('development + AUTH_ENFORCE=true → no throw', () => {
    process.env.NODE_ENV = 'development';
    process.env.AUTH_ENFORCE = 'true';
    expect(() => assertProductionAuthEnforce()).not.toThrow();
  });

  it('development + AUTH_ENFORCE=false → no throw', () => {
    process.env.NODE_ENV = 'development';
    process.env.AUTH_ENFORCE = 'false';
    expect(() => assertProductionAuthEnforce()).not.toThrow();
  });
});
```

**验收：** `npm run test` 4 case 全过。

### 3.4 PR-E0.4 — /auth/guest load test（评审采纳 R2 P2#7）

**问题：** v1 §7 风险表把 /auth/guest 突发流量列为风险 + "假设撑得住"——但没 verify。切流瞬间所有老客户端 / 重启的 App 都会重新拿 guest token，可能瞬时高并发。

**改动：** 新增 `apps/api/scripts/load-test-auth-guest.ts`（或用 k6 / autocannon）：

```ts
// pseudo: 1000 RPS for 60s
const concurrency = 100;
const duration = 60;
const targetRPS = 1000;
// POST /auth/guest with random device_id
```

**验收 baseline：**
- /auth/guest p95 < 500ms @ 1000 RPS 60s
- users 表写入无 deadlock / serialization conflict
- PG `idx_users_device_id` 索引使用率高（EXPLAIN ANALYZE 抽查）

**如果 baseline 不达标 → 加 rate-limit middleware**（同 IP 100 req/min），或扩 PG。

---

## 4. Readiness Gate（v2 — 27 项，扩展评审采纳）

切流前**每条必须 ✅**。任何 ❌ 停下问用户。

### 4.1 E1 Prerequisite（4 项，PR-E0.1~E0.4 完成）

- [ ] PR-E0.1 merge：mobile backup baseUrl 0 处 `10.0.2.2` 硬编码
- [ ] PR-E0.2 merge：BackupController 不再触发 devStore.storeBackup → saveToDisk
- [ ] PR-E0.3 merge：assertProductionAuthEnforce 4-case 单测全过
- [ ] PR-E0.4 跑过：/auth/guest @ 1000 RPS p95 < 500ms

### 4.2 Phase G 产出（5 项，v2 评审采纳 R1 P1#3 + R2 P2#5）

- [ ] `audits/prd-§9-acceptance-coverage.md` 7 节全 ✅（**audit §6 数字与之一致：16/18 + 2 caveat 已记录**，v1 写"全 18"错误，v2 修）
- [ ] `BR-USER-001_v0.1.0_full.md` 4 条 BR 落地
- [ ] plan v2 末尾「实施进度」表所有 phase 有 commit hash
- [ ] **G4 验证**：drift v12→v13 真实数据样本回放测试通过（dev / staging snapshot）
- [ ] **G4 验证**：sqflite v1 历史数据兼容（Phase C PR-C-α `_createTables` strip 后 fresh install 路径）

### 4.3 后端能力层（7 项）

- [ ] `assertProductionAuthEnforce` 在 main.ts bootstrap 调用（PR-E0.3 同时验证）
- [ ] AuthGuard.canActivate 含 `await devStore.ensureUserLoaded(user.id)`（β.5b）
- [ ] dev-store `loadingByUser` Map 防并发重复 load（β.5b）
- [ ] pg-persistence `loadBackupForUser` / `saveBackupForUser` / `clearBackupForUser` 三方法存在
- [ ] BackupController 仅通过 pg-persistence 操作 backup（PR-E0.2 验证）
- [ ] **DevStoreSnapshot 含 plan A4-β §3.1/3.2/3.3 全部 partition 字段**（评审采纳 R2 P2#6）—— 包括但不限于：13 个数组 partition、3 个 Map partition、7 个单值 partition（含 `userDailyNewTarget`、`catProfile` 若已落地）、β.5c 的 ownedItems/equippedOutfit/equippedRoom/wallet
- [ ] dev-store serialize/hydrate 对所有 *ByUser 字段双向往返单测通过

### 4.4 移动端身份层（5 项）

- [ ] ApiClient.setDefaultHttpClient 在 main.dart 启动调用（Phase B hot-fix `5d83936`）
- [ ] **AuthHttpClient.send 含 epoch capture + RequestStaleException**（评审采纳 R2 P1#1 — Phase C γ `1584440` 已实施，readiness 必显式 verify）
- [ ] `today_page.dart` / `meow_home_page.dart` 含 `didChangeDependencies` epoch 重置（Phase C γ）
- [ ] AuthBootstrap 启动顺序：SharedPreferences → AuthBootstrap → ApiClient.setDefaultHttpClient → LocalDatabase → AppDatabase（Phase B 落地）
- [ ] **UI 文案符合 PRD §7**（手动 review profile 退出确认 / 游客绑定提示 / 我的页账号状态，无恐吓式文案）（评审采纳 R2 P2#10）

### 4.5 Audit §6 e2e（2 项，v2 改用 Phase G 输出口径）

- [ ] **audit §6 cross-user e2e 用例数 = 16**（β.7 12 + α 落 6 - 重叠 2 = 16；详见 `controller-auth-audit.md` §6 v1.2 修订）
- [ ] **caveat 2 项已在 prd-§9-acceptance-coverage.md §3 记录**（lottery 真隔离硬化 + local-batch 路径细化）

> v1 写"全 18 个 owner-check 路径 e2e 覆盖"与 Phase G 输出 16/18 冲突。v2 采纳 Phase G 数字 + 接受 2 项 caveat（功能上 cross-user 写入已无路径，仅测试形式上未到 100%）。

### 4.6 Staging 环境（4 项）

- [ ] staging DB apply migration 008/009/010（D9 命令）+ status 显示全部 applied
- [ ] staging `JWT_SECRET` 已设（≥ 32 chars 随机，**与 production 不同**）
- [ ] staging `DATABASE_URL` 独立（不连 dev / 不连 production）
- [ ] staging 监控告警接入（§5 D4 7 个指标）

### 4.7 严格模式 baseline（2 项）

- [ ] `cd apps/api && AUTH_ENFORCE=true npm run test:e2e:pg` 全 pass
- [ ] `cd apps/mobile && flutter test` 全 pass

### 4.8 D6 老客户端 verify（必通过 1 项）

- [ ] 应用市场版本查询通过 ✓
- [ ] 或：移动端埋点版本分布 0 老版本活跃用户 ✓
- [ ] 或：零发布证明（仅内测设备，全部装 Phase B+） ✓

### 4.9 Phase F 状态对账（**v2 新增**，评审采纳 R2 P2#4）

| Phase F 子项 | 状态 | 引用 |
|-------------|------|------|
| F1 绑定 UI + /auth/bind 调用 | ✅ 已隐式完成（Phase B `9d992c8` AuthFormPage bind mode + AuthController.bindCurrentGuest） | |
| F2 服务端事务（同行升级 users） | ✅ 已隐式完成（A2 `5547a85` auth.service bindGuest） | |
| F3 客户端不一致重试机制 | ✅ Phase C γ `1584440` PendingGuestMigrator 实现 | |
| F4 备份后 UI 触发恢复 | ⚠️ **不在需求 23 范围**（用户主动触发，UX 文案 Phase F 自主完成时再做） | |

→ **Phase F 实质完成 F1-F3，F4 非阻塞**。E1 切流后宣告 Phase F = 完成。

---

## 5. Staging Cutover（E1.2 + E1.3）

### 5.1 切流操作（v2 — 改 env vars / IaC，不 commit .env，评审采纳 R1 P1#4）

⚠️ **不要 `git add apps/api/.env`** — .env 已 gitignore，应通过 deploy 平台改环境变量：

**Docker compose:**
```yaml
# docker-compose.staging.yml
services:
  api:
    environment:
      - AUTH_ENFORCE=true   # was: false
```

**K8s:**
```yaml
# k8s/staging/deployment.yaml
env:
  - name: AUTH_ENFORCE
    value: "true"
```

**裸机 / pm2:**
```bash
# 修 ecosystem.config.js 或对应 env file
# 触发 pm2 restart
```

**项目可 commit 的内容**（属于 PR-E0.5，纯文档型）：
- `apps/api/.env.example`：加 production guidance 注释 `# 切流后, production MUST be true; staging recommended true to catch regressions early`
- 此 plan 文档本身

### 5.2 冒烟测试（同 v1，不变）

略，见 v1 §4.1 step 4。

### 5.3 严格模式跑全套 e2e

```bash
cd apps/api && AUTH_ENFORCE=true npm run test:e2e:pg
```

**任何失败 → 停 staging soak，回前面 phase 修。不要在 E1 PR 改业务代码。**

### 5.4 Soak 期间监控（v2 监控数据源明示，评审采纳 R1 P2#5）

每 4h 检查一次：

| 指标 | 数据源 | 阈值（v2 收紧） |
|------|--------|----------------|
| /me/* 401 总数 | log 聚合查询：`level=error path=/api/v1/me/* status=401` | baseline × 10 持续 5 min |
| /auth/login 失败率 | log 聚合：`/auth/login` 中 401 / total | **> 10% 持续 5 min**（v1 30% 太松，评审采纳 R2 监控点 13） |
| /auth/guest 调用数 | log 聚合：`path=/api/v1/auth/guest` count | baseline × 5 |
| /me/* 5xx 率 | 后端 NestJS exception filter 计数 / log | > 1% 持续 5 min |
| Response time P95 | log 中 `duration_ms` 字段 P95 | baseline × 2 持续 10 min |
| Mobile 401 弹窗触发数 | 移动端埋点 `auth_token_expired_modal_shown` event | > 切流前 baseline + 50% |
| 业务关键 DAU | DB query: `SELECT COUNT(DISTINCT user_id) FROM session_records WHERE created_at > now() - interval '24h'` | < 切流前 1 天 70% |

**Baseline 取样窗口（评审采纳 R2 漏 16）：** 切流前 7 天工作日平均（避免周末偏差）。

**监控数据源前置项**（4.6 staging 环境第 4 条）：以上 7 个指标的查询语法必须在切流前**在 staging 真跑过一次返回有效数据**，不能只是"假设接入"。

---

## 6. Production Cutover Playbook（E1.4，仅文档）

同 v1 §5，但加：

### 6.1 Pre-cutover checklist（v2 增项）

- [ ] **PR-E0.1~E0.4 已 merge 到 main**
- [ ] **PR-E0.4 load test 在 production-shape DB 上跑过**（如果 staging DB 远小于 prod，必须用 prod-shape 数据预跑）
- [ ] JWT_SECRET 用 D8 命令生成（96 字符 hex），与 staging 不复用，存 prod secret manager
- [ ] migration 010 在 production DB 已 apply（`npm run db:migrate:status` 显示 010 in Applied）
- [ ] D6 verification 在 production 流量上重新跑（埋点取最近 7 天 prod DAU app_version 分布）

### 6.2 Rollback 数据脏审计 SQL（v2 新增，评审采纳 R2 监控点 15）

```sql
-- 找切流-rollback 时间窗口内的写入异常
WITH cutover_window AS (
  SELECT
    '2026-MM-DD HH:MM:SS'::timestamptz AS cutover_at,
    '2026-MM-DD HH:MM:SS'::timestamptz AS rollback_at  -- 通常 cutover + 0~60min
)
SELECT
  'study_attempts' AS table_name,
  user_id, COUNT(*) AS row_count
FROM study_attempts, cutover_window
WHERE created_at BETWEEN cutover_at AND rollback_at
GROUP BY user_id

UNION ALL

SELECT 'review_attempts', user_id, COUNT(*) FROM review_attempts, cutover_window
WHERE created_at BETWEEN cutover_at AND rollback_at GROUP BY user_id

UNION ALL

SELECT 'reward_ledger', user_id, COUNT(*) FROM reward_ledger, cutover_window
WHERE created_at BETWEEN cutover_at AND rollback_at GROUP BY user_id

-- ... 按业务表扩展
ORDER BY 1, 3 DESC;
```

如果发现 `user_id = 'dev-user-001'` 突增（permissive 期间写入），说明 fallback 误生效，需排查。

---

## 7. Sign-off（v2 三阶段，评审采纳 R1 P2#6）

### 7.1 E1 PR 合并完成

- 4 个 prerequisite PR + plan v2 + readiness gate doc + playbook merge to feature/user-auth
- 测试基线 baseline 不破

### 7.2 Staging soak 通过

- staging AUTH_ENFORCE=true e2e 全 pass
- 24h soak 内监控无超阈值告警
- 任何 incident 已 post-mortem + 修复

### 7.3 Production operator sign-off

**这一项不在 model scope** — 由用户按 §6 playbook 手动执行：

- production AUTH_ENFORCE=true 上线
- 24h prod soak 通过
- 业务关键指标恢复 baseline
- 用户运营反馈无异常

**E1 sign-off 三段都通过 → 需求 23 完整闭环达成。**

---

## 8. 风险与缓解（v2 — 调整概率 + 新增）

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 老客户端 401 风暴 | **D6 未 verify 时高，verify 后低** | 严重 | D6 必须 verify 通过；§4.8 gate |
| /auth/guest 突发流量打挂 | **低**（PR-E0.4 load test verify） | 中 | PR-E0.4 baseline + rate-limit 后备 |
| Production assertProductionAuthEnforce 配置错 | **低**（PR-E0.3 单测覆盖） | 严重 | PR-E0.3 + production env vars 检查 |
| BackupController.storeBackup 副作用导致 dev-user 数据脏 | **低**（PR-E0.2 清理） | 中 | PR-E0.2 + §6.2 数据脏审计 SQL |
| Mobile baseUrl 误连 emulator IP 导致备份失效 | **零**（PR-E0.1 修） | 中 | PR-E0.1 + grep 验证 |
| epoch in-flight 串数据 | **零**（Phase C γ + §4.4 verify） | 严重 | §4.4 readiness 显式验证 |
| migration 010 在 production apply 失败 | 低 | 严重 | D9 命令 + rollback 流程 |
| Phase F 状态遗漏 | 零（§4.9 对账） | 中 | §4.9 状态表 |
| Staging 流量不能模拟 production 高 RPS | 中 | 切流后才发现性能 bug | PR-E0.4 load test 在 prod-shape DB 上跑（§6.1 checklist） |
| Rollback 数据脏审计无方法 | **零**（§6.2 SQL） | 中 | §6.2 SQL 明示 |
| 监控告警未及时触发 | 中 | 错过 rollback 窗口 | §5.4 数据源前置项 + 切流前演练 |

---

## 9. 估时（v2，含 prerequisite 4 PR）

| 阶段 | Claude active | Elapsed |
|------|--------------|---------|
| **PR-E0.1 mobile baseUrl** | 1h | 1h |
| **PR-E0.2 storeBackup 副作用** | 1h | 1h |
| **PR-E0.3 assertion 单测** | 0.5h | 0.5h |
| **PR-E0.4 load test 脚本+跑** | 2h | 2h |
| E1.1 readiness gate 27 项验证 | 1h | 1h |
| E1.2 staging cutover 实操 | 2h | 2h |
| E1.3 staging soak | 1h（每 4h 检查 ×6） | 24h |
| E1.4 production playbook + monitoring + rollback 文档 | 2h | 2h |
| **E1 active 总工时** | **~10.5h** | |
| **E1 elapsed 总时间** | | **~3.5 天**（含 staging soak） |

vs v1 估时 5h active / 3 天 elapsed — v2 加 4 个 prerequisite PR + 9 个 readiness gate 项，工时增 100%。

production operator sign-off（用户自己操作 §6 playbook）elapsed ~24h（含 prod soak），不算 Claude active。

---

## 10. 评审采纳记录

### Review 1（6 项全部采纳，0 拒）

| 评审项 | 处理 |
|--------|------|
| P1#1 backup storeBackup 副作用 | PR-E0.2 |
| P1#2 mobile baseUrl 硬编码 | PR-E0.1 |
| P1#3 audit §6 数字口径冲突 | §4.5 改 16/18 + caveat |
| P1#4 commit .env 不当 | §5.1 改 env vars / IaC |
| P2#5 监控指标只有名字 | §5.4 加数据源 |
| P2#6 sign-off 边界不清 | §7 三阶段拆分 |

### Review 2（10 项全部采纳，0 拒）

| 评审项 | 处理 |
|--------|------|
| P1#1 epoch readiness 漏 | §4.4 显式 verify |
| P1#2 D6 假设无 verify | D6 加 3 种 verify 方法 |
| P1#3 assertion 单测漏 | PR-E0.3 |
| P2#4 Phase F 含糊 | §4.9 状态对账 + §1.3 移除 E2 |
| P2#5 G4 漏 | §4.2 加 drift/sqflite replay |
| P2#6 β.5c 字段不全 | §4.3 引用 plan A4-β §3.1-3.3 |
| P2#7 /auth/guest load test | PR-E0.4 |
| P2#8 E2/D6 内部冲突 | §1.3 永久移除 E2 |
| 漏 6 dev 环境策略 | D7 新增 |
| 漏 10/11/14/15/16 | §5/§6 文档明示 |

### 拒绝项：**0**

所有评审项均成立无可拒。这表明 v1 plan 写得不够全面，v2 是必要修复后才进入实施。

---

## 11. 下一步

请用户确认：

1. **D6-D9 决策**（D6 verify 方法 / D7 dev 策略 / D8 secret 管理 / D9 migration runner）— D1-D5 v1 已拍板
2. **PR-E0.1~E0.4 4 个 prerequisite PR** 是否同意作为 E1 启动前必做
3. **Sign-off 三阶段拆分**（E1 PR / staging / production operator）
4. **D6 verify 路径**：你的项目状态是「未发布」/「已发布到内测」/「已发布到应用市场」中哪一种？决定走哪条 verify 路径

确认后按顺序：
```
PR-E0.1 (mobile baseUrl)
  ↓
PR-E0.2 (storeBackup 副作用) ∥ PR-E0.3 (assertion 单测)
  ↓
PR-E0.4 (load test)
  ↓
E1.1 readiness gate 27 项验证
  ↓
E1.2 staging cutover
  ↓
E1.3 24h soak
  ↓
E1.4 production playbook 交付
  ↓
[用户手动] Production cutover + 24h soak → 需求 23 完整闭环
```
