# 需求 23 实施计划：用户系统与用户数据隔离 v2

**Plan Version:** v2（v1 → v2 是大重写，不是补丁）
**Status:** draft（待用户确认）
**对应 PRD:** `docs/design/prd-023-用户系统与用户数据隔离-v1.md`
**前序版本:** `docs/design/plan-023-用户系统与用户数据隔离-v1.md`
**Branch:** `feature/user-auth`
**作者:** Claude Code（AI 开发者）
**日期:** 2026-05-09

---

## 0. v2 重写说明

v1 收到两份外部 review，逐条核实后认定多数指控成立。v2 修复以下 9 类问题：

| # | v1 缺陷 | v2 修复 |
|---|---------|--------|
| F1 | "所有 /me/* 加 auth, 其他不加"分法错误（5 个用户写路由不在 /me/* 下） | §4 重做控制器逐个审计 |
| F2 | §2.1.4 vs §5.3 自相矛盾（guest 行保留 vs 同行升级） | §3.1 / §6.2 二选一确定为「同行升级 + 不留 guest 行」 |
| F3 | 后端 dev-store 是 in-memory 单例数组，不是简单换入参就能多用户化 | §5 增加 user-scoped repository / 切换持久层时机 |
| F4 | 漏了 raw sqflite `LocalDatabase`（meow_progress.db v1，5 张表） | §7.1 把 raw sqflite 也纳入 v2→v? 迁移 |
| F5 | 漏了 `progress_*` / `backup_*` / `room_canvas_layout_v1` 等 SharedPreferences 全局键 | §7.3 全 SP 键审计 |
| F6 | 备份导出 / 恢复是全表 full replace，多用户化后会跨用户串数据 / 删数据 | §8 备份恢复重做 |
| F7 | `idempotency_keys` PK / `reward_source_events` UNIQUE 未带 user_id | §3.2 唯一约束审计与 migration |
| F8 | 30 天 token 过期切游客 = 用户感知数据消失 | §6.4 401 处理硬纪律「绝不切游客」 |
| F9 | local_guest vs server_guest 双 ID 统一时机不明 | §6.3 改为单 ID（server_guest_user_id），离线用占位临时 ID |

v1 的优点保留：「同行升级」绑定大方向（避免业务表 user_id 改写）、ChangeNotifier+InheritedNotifier 不引新依赖、dev_user_001 保留 + DEV_BYPASS_TOKEN 旁路、决策点拍板机制。

---

## 1. 更新后的现状摸底（替换 v1 §0 表）

逐条核实后，准确版本：

| 维度 | v1 错误声明 | v2 实际 |
|------|------------|---------|
| 后端 DB | "所有表都已带 user_id" | **大部分表带，但唯一约束有缺口**：`idempotency_keys` PK 是全局 `key`、`reward_source_events` UNIQUE `(event_type, source_ref_id)` 不含 user_id |
| 后端控制器 | "所有 API 都用 /me/*" | **23 个控制器中 13 个 `/me/*`，10 个不带 `/me/*`**。其中 `sessions` / `review-attempts` / `shop/purchases` / `settlements` / `check-ins` 是用户写路由 |
| 后端 user 上下文 | "靠 DEV_USER_ID 常量注入" | **更糟**：`dev-store.ts` 是 module-level 单例 + in-memory 数组（`learnedWordsByBook: Map<...>` 等），状态在内存共享；PG persistence 也是整份 snapshot 读写到 `dev-user-001` |
| 移动端本地 DB | "drift v12，全设备共享" | **两套并行 DB**：① `LocalDatabase`（**raw sqflite** version=1，5 张表：word_records/wordbook_progress/daily_checkins/custom_wordbooks/vocabulary_notebook）② `AppDatabase`（drift v12，20 张表）。两套并存于同一 `meow_progress.db` 文件 |
| 移动端 SharedPreferences | "settings_* 全局" | **三类用户数据全局键**：① `settings_*`（LocalSettingsService）② `progress_*`（LocalProgressRepository：5 个 key）③ `backup_*`（backup metadata）④ `room_canvas_layout_v1`（家具布局） |
| 移动端备份 | "device_id 透传，user_id 在后端隐式" | 备份导出是**全表导出**，恢复是**全表 delete + replace**（[snapshot_export_service.dart](apps/mobile/lib/core/storage/snapshot_export_service.dart)、[backup_restore_service.dart:144](apps/mobile/lib/core/storage/backup_restore_service.dart) `_applySnapshot`）。多用户化后必须改为 per-user 过滤 |
| 移动端登录 / 鉴权 | "无" | 确认无（保留 v1 结论） |
| 移动端 device_id | "已存在，UUID v4" | 确认（保留 v1 结论） |

---

## 2. 总策略：Phase 重排

v1 把 Phase A（后端鉴权）放最前导致 review 2 #1 指出的问题：A 单独上线时，老客户端没 token → /me/* 大量 401。v2 重排为 **"先做能力再切流"**：

```
Phase 0 — 现状审计文档落档（不动代码）
  └── 输出 controller-auth-audit.md / db-uniqueness-audit.md / sp-keys-audit.md

Phase A — 后端 auth 能力（不强制鉴权，feature flag off）
  ├── A1: users 表 migration 008（加鉴权字段）+ 唯一约束 migration 009（idempotency / reward_source_events）
  ├── A2: 实现 /auth/* 接口（注册、登录、guest、bind）+ JWT
  ├── A3: AuthGuard 实现并加载，**默认 allow（看 env AUTH_ENFORCE）**
  └── A4: 把 dev-store 单例的 user-scoped 状态从 module 拆为 per-user store map

Phase B — 移动端身份层（拿 token 但不鉴权）
  ├── B1: AuthController + AuthStorage + AuthScope
  ├── B2: ApiClient 注入 Authorization 头（无 token 也能继续，AUTH_ENFORCE=off 时后端容忍）
  ├── B3: 启动时调 /auth/guest 拿 server_guest_user_id（决定性单 ID 来源，见 §6.3）
  ├── B4: 登录 / 注册 / 退出 UI 与现有 SpecShell 集成
  └── B5: 我的页 / 设置页加账号区
   ※ 上线即可：用户感觉无变化，仍是单用户体验，但 token 流已经跑通。

Phase C — 移动端本地数据隔离（**最大风险点**）
  ├── C1: raw sqflite LocalDatabase 升级 v1 → v2（5 张表加 user_id）
  ├── C2: drift v12 → v13（20 张表中的用户行为表加 user_id；公共内容层不动）
  ├── C3: SharedPreferences key 改造为 user-scoped 命名空间
  ├── C4: 仓库层 / DAO / 全部查询带 currentUserId 过滤
  ├── C5: 切换账号时 in-flight 请求取消 + cache 销毁（epoch 计数器机制，见 §6.6）
  └── C6: 老数据迁移到 server_guest_user_id（同时清理本地占位 pending-local-guest）
   ※ 上线即可：仍是单用户视角，但本地全部 user-scoped。

Phase D — 备份/恢复 per-user 改造
  ├── D1: snapshot_export 限定当前 user_id
  ├── D2: backup_restore 限定当前 user_id（只删当前 user 数据，不影响其他 user 行）
  └── D3: 远端 snapshot 文件名 / 路径带 user_id

Phase E — 强制鉴权切流（终于把 AUTH_ENFORCE 打开）
  ├── E1: 在 staging 把 AUTH_ENFORCE=on，全量回归
  ├── E2: 移动端强制升级（强升提示）
  └── E3: 生产 AUTH_ENFORCE=on

Phase F — 游客绑定流程（前几阶段已经把 server_guest_user_id 跑通，这一阶段做绑定 UI/事务）
  ├── F1: 绑定 UI + /auth/bind 调用
  ├── F2: 服务端事务（同行升级 users）+ 失败回滚
  └── F3: 客户端不一致重试机制（auth_pending_local_migration 标记）

Phase G — 验收测试
  ├── G1: 用户 A / B 隔离集成测试
  ├── G2: 游客绑定不丢数据测试
  ├── G3: 401 / token 过期 / 跨用户访问安全测试
  └── G4: drift v12→v13 / sqflite v1→v2 真实数据样本回放测试
```

**关键差异 vs v1：**
- v1 是「A→B→C→D→E」线性切上线；v2 是「能力先就位 → 全栈一起上线 → 最后切流」。
- AUTH_ENFORCE feature flag 是 v2 新增的关键机关：先让能力跑通再切强校验，避免老客户端断流。

---

## 3. DB 变更设计（后端）

> **CLAUDE.md §2.5 强制：写代码前需用户确认**

### 3.1 migration 008：users 表加鉴权字段

```sql
ALTER TABLE users
  ADD COLUMN email VARCHAR(255) UNIQUE,             -- 正式用户唯一标识；游客为 NULL
  ADD COLUMN password_hash VARCHAR(255),            -- bcrypt cost=12；游客为 NULL
  ADD COLUMN account_type VARCHAR(16) NOT NULL DEFAULT 'guest',
    -- 'guest' | 'registered'
  ADD COLUMN device_id VARCHAR(128),                -- guest 起号时 device 标识；可空
  ADD COLUMN last_login_at TIMESTAMPTZ;

-- email lower-case 唯一
CREATE UNIQUE INDEX idx_users_email_lower
  ON users (LOWER(email)) WHERE email IS NOT NULL;

-- guest 起号幂等查询索引
CREATE INDEX idx_users_device_id
  ON users (device_id) WHERE account_type = 'guest';
```

**v1 → v2 字段变化：**
- ❌ 删 `bound_from_guest_id`：v2 选「同行升级」（见 §6.2），同一行 users，没有"原 guest 行"了，这个字段没有载体
- ✅ 加 `device_id`：解决 review 2 #3 / v1 §5.2 "guest 起号幂等查询无字段可用"问题

**user_id 前缀策略修正（解决 review 1 §1.3 / review 2 #4 矛盾）：**

绑定后 users.id 不变（同行升级），不承诺前缀语义。也就是说：「绑定后的正式账号仍然以 `guest-...` 为 id」是**可接受的事实**，前端不依赖 id 前缀做任何业务判断。文档里需要明示。

### 3.2 migration 009：唯一约束补 user_id

```sql
-- idempotency_keys：PK 改为 (user_id, key)
ALTER TABLE idempotency_keys DROP CONSTRAINT idempotency_keys_pkey;
ALTER TABLE idempotency_keys ADD PRIMARY KEY (user_id, key);

-- reward_source_events：UNIQUE 加 user_id
ALTER TABLE reward_source_events DROP CONSTRAINT reward_source_events_event_type_source_ref_id_key;
ALTER TABLE reward_source_events ADD UNIQUE (user_id, event_type, source_ref_id);
```

**风险：** 如果生产已有数据，dev-user-001 的 key 单一用户唯一，不会冲突；改 PK 会丢失原 PK 约束的查询计划，跑前先 EXPLAIN 一下读写热点确认无影响。

**审计完整列表（待 Phase 0 输出 db-uniqueness-audit.md）：** 还要看其他表的 UNIQUE 是否漏 user_id。已知存疑的：`check_in_records` UNIQUE、`learning_day_facts` UNIQUE、`daily_goal_progress` UNIQUE。Phase 0 时逐条扫，必要时纳入 009。

### 3.3 不引入 refresh_tokens 表（保持 v1 结论）

v1 的 D3：30 天 access token，不做 refresh。但 v2 增加配套硬纪律见 §6.4。

---

## 4. API 变更设计（控制器逐条审计）

v1 漏了"非 /me/* 路由也是用户写"的事实。v2 给完整审计表：

### 4.1 路由审计表

| 控制器 | 路径 | 性质 | v2 决策 |
|--------|------|------|--------|
| AuthController | `/auth/*` | 新增 | **新增**：register/login/guest/bind/me/logout |
| HealthController | `/health` | 系统 | 公开 |
| WordsController | `/books`, `/books/:id/words` | 内容 | 公开 |
| AudioAssetsController | `/examples`, `/words` | 内容 | 公开 |
| PronunciationController | `/pronunciation` | 内容 | 公开 |
| ContentManifestController | `/content` | 内容 | 公开 |
| TodayController | `/me/today` | 用户读 | **AuthGuard, current user** |
| MeWordsController | `/me/words` | 用户读 | **AuthGuard** |
| SettingsController | `/me/settings` | 用户读写 | **AuthGuard** |
| BackupController | `/me/backup` | 用户读写 | **AuthGuard** |
| StudyAttemptsController | `/me/new-words` | 用户写 | **AuthGuard** |
| TaskAttemptsController | `/me/task-attempts` | 用户写 | **AuthGuard** |
| ReviewGroupsController | `/me/review-groups` | 用户读写 | **AuthGuard** |
| DailyTasksController | `/me/daily-tasks` | 用户读 | **AuthGuard** |
| FeedController | `/me/feed` | 用户写 | **AuthGuard** |
| InventoryController | `/me/inventory` | 用户读 | **AuthGuard** |
| EquipmentController | `/me/equipment` | 用户写 | **AuthGuard** |
| LotteryController | `/me/lottery-boxes` | 用户写 | **AuthGuard** |
| SecondarySummaryController | `/me/secondary-summary` | 用户读 | **AuthGuard** |
| **SessionsController** | `/sessions` | **用户写** | **AuthGuard**（路径保留，不改前缀，避免破坏客户端） |
| **ReviewAttemptsController** | `/review-attempts` | **用户写** | **AuthGuard**（同上） |
| **CheckInsController** | `/check-ins` | **用户写** | **AuthGuard**（同上） |
| **SettlementsController** | `/settlements` | **用户写** | **AuthGuard**（同上） |
| **ShopController** | `/shop/catalog` | 内容读 | 公开 |
| **ShopController** | `/shop/purchases` | **用户写** | **AuthGuard**（细粒度路由级，不是控制器级） |

**关键决定：** 不改路由前缀（不把 `/sessions` 改成 `/me/sessions`），原因：
- 改路由是 CLAUDE.md §4.4 "改对外 API 核心语义"，必须停下上报
- 改路由会破坏所有现存客户端（包括正在跑的 dev/staging）
- 鉴权需求与路径前缀正交，AuthGuard 可以加在任何控制器 / 方法上

`/shop` 控制器同时有公开（catalog）和用户写（purchases），AuthGuard 必须**方法级**而非控制器级。

### 4.2 AuthGuard 实现要点

```typescript
@Injectable()
export class AuthGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const enforce = process.env.AUTH_ENFORCE === 'true';

    const token = extractBearerToken(req);
    if (!token) {
      if (!enforce) {
        // Phase A~D：fallback 到 dev-user-001
        req.user = { id: process.env.DEV_FALLBACK_USER_ID ?? 'dev-user-001', type: 'registered' };
        return true;
      }
      throw new UnauthorizedException();
    }
    const payload = verifyJwt(token);
    req.user = { id: payload.sub, type: payload.type };
    return true;
  }
}
```

**`AUTH_ENFORCE` 默认 false**，只有 Phase E 切流时改 true。生产环境：**Phase E 之后必须 hard-coded 拒绝 false**（启动期断言 `NODE_ENV === 'production' ⇒ AUTH_ENFORCE === 'true'`），见 D13。

### 4.3 新增 /auth/* 接口（保留 v1 §3.1 设计，不变）

`/auth/register` `/auth/login` `/auth/guest` `/auth/me` `/auth/logout` `/auth/bind`，请求/响应见 v1 §3.1。

`/auth/guest` 实现细节：按 `users.device_id == :device_id AND account_type='guest'` 查找，命中返回原 token，未命中创建。device_id 由客户端传入（移动端 SharedPreferences 那个 UUID v4）。

---

## 5. 后端 dev-store / repositories 的多用户化（v1 严重漏项）

v1 假定「把 DEV_USER_ID 改成入参」就完工。实际不是。

`dev-store.ts` 是 **module-level 实例 + 内存数组**，所有用户的状态混在同一 Map 里（按 user_id 分桶但桶是单例）。如果两个用户同时请求，会读写同一份 Map / Array，并发安全也没人管过。

### 5.1 短期方案（Phase A 内）

PG persistence backend (`PERSISTENCE_BACKEND=pg`) 已经按 `user_id` 字段过滤，不存在内存共享问题。**强制 dev/staging/prod 全部走 PG**：

```env
# .env / .env.example 的 default
PERSISTENCE_BACKEND=pg
```

`dev-store.ts` 仅在 `PERSISTENCE_BACKEND=json` 或单测环境下使用，并显式打 `@deprecated` 注释。本地 e2e 测试如果还要走 in-memory，要改造为 per-user store map（见 5.2）。

### 5.2 中期方案（Phase A 内做一半）

把 dev-store 内的状态结构从 `Map<book_id, ...>` 之类改为 `Map<user_id, Map<book_id, ...>>`。这是机械改造，体力活但不复杂。

> 这是 v2 新增的工作量，v1 没估到。

### 5.3 controllers 改造模式

```typescript
// before:
@Get()
getToday() {
  return repositories.today.getTodayState();
}

// after:
@Get()
@UseGuards(AuthGuard)
getToday(@CurrentUser() user: { id: string }) {
  return repositories.today.getTodayState(user.id);
}
```

`@CurrentUser()` 是新加的 param decorator。每个 repository 的 method signature 都加 `userId` 入参（约 30+ 处）。

---

## 6. 移动端架构变更

### 6.1 当前用户上下文（不变 v1）

`lib/core/auth/` 模块、ChangeNotifier+InheritedNotifier 暴露 currentUser。架构选择保留 v1。

### 6.2 游客绑定的 user_id 策略（解决 v1 §2.1.4 vs §5.3 矛盾）

**最终方案：同行升级，绑定后 users.id 不变，不留 guest 行，前缀仅作为人眼标记不参与业务判断。**

绑定流程（修正版）：

```sql
BEGIN;
  -- 校验邮箱不重复
  SELECT 1 FROM users WHERE LOWER(email) = LOWER($1) AND account_type='registered'
    -- 如有命中，ROLLBACK + 返回 EMAIL_TAKEN
  ;

  -- 同行升级（注意 id 保持不变）
  UPDATE users SET
    email = $1,
    password_hash = $2,
    account_type = 'registered',
    last_login_at = NOW(),
    updated_at = NOW()
  WHERE id = $current_guest_user_id AND account_type = 'guest';
  -- 如果影响行数 != 1，ROLLBACK + 返回 GUEST_NOT_FOUND
COMMIT;
```

**关键：** `users.id` 整个生命周期不变 → 业务表 `user_id` 列**不需要改写** → 绑定是 O(1) 操作 → 不存在"绑定中途失败让数据半迁移"的服务端事务。

### 6.3 单一 user_id 来源（解决 review 1 §2.2 / v1 §5.2 双 ID 模糊）

v1 引入了 `local_guest_user_id`（设备派生）和 `server_guest_user_id`（服务端给）两个 id，没说清统一时机。v2 简化为单 ID：

```
启动:
  ├── SharedPreferences `auth_current_user_id` 有值
  │   └── 用之，进入主流程
  └── 无值
      ├── 有网 → POST /auth/guest { device_id } → 拿 server_guest_user_id
      │         → 写入 SharedPreferences → 进入主流程
      └── 无网 → 写入 `pending-local-guest`（占位）→ 进入主流程
                ↓ 后续每次启动都尝试调 /auth/guest，成功后做一次 ID 替换:
                  UPDATE 所有 user-scoped 表 SET user_id = server_guest_id
                  WHERE user_id = 'pending-local-guest'
                此 UPDATE 是 idempotent，单次事务，失败可重试。
```

**好处：** 任何时候本地数据 user_id 都 ∈ {`pending-local-guest`, server_guest_id, registered_user_id}，不存在两份并存。

**派生 device_id 的位置：** drift migration 在 onUpgrade 回调里跑，需要 device_id。Phase B 启动流程必须保证：device_id 可用 → drift 打开 → 才能跑 migration。具体时序见 §7.4。

### 6.4 401 处理硬纪律（解决 review 1 §2.1）

```dart
// ApiClient 收到 401 时：
1. 清 SharedPreferences `auth_access_token`
2. **保留** `auth_current_user_id` 和 `auth_account_type`
3. 通知 AuthController：状态从 'authed' → 'token_expired'
4. UI 弹"登录已过期，请重新登录"，重登后 token 拿到、user_id 不变
5. **绝不切游客**，绝不用 server_guest_user_id 替换 registered_user_id
```

如果用户主动选择"以游客身份继续"（罕见路径），那是显式操作，不是 401 的隐式后果，不属于本红线。

### 6.5 退出登录纪律（保留 v1）

= 清 token + 清 `auth_current_user_id` + 切到游客上下文（重新走 §6.3 启动流程拿 server_guest_id）+ **不删任何本地数据**。

### 6.6 切换账号 in-flight 请求处理（解决 review 1 §2.3）

引入 `AuthEpoch`：

```dart
class AuthController extends ChangeNotifier {
  int _epoch = 0;
  int get epoch => _epoch;
  void switchUser(...) {
    _epoch++;
    // ...
    notifyListeners();
  }
}

// ApiClient 发请求时：
final reqEpoch = authController.epoch;
final response = await _client.send(...);
if (authController.epoch != reqEpoch) {
  // 用户已切换，丢弃响应
  throw RequestStaleException();
}
```

切换账号的具体步骤：
1. AuthController.epoch++
2. 取消所有 in-flight 请求（http.Client 替换为新实例）
3. 销毁所有 ChangeNotifier listener / drift stream subscription（per-page lifecycle）
4. `Navigator.pushAndRemoveUntil`，跳到正确根路由（**注意：v1 写错的 `/home` 实际是 `/`，路由名见 [app_router.dart](apps/mobile/lib/core/router/app_router.dart)；以代码为准**）

---

## 7. 移动端本地数据全量审计（v1 重大漏项）

### 7.1 Raw sqflite `LocalDatabase`（v1 完全漏掉）

文件：[apps/mobile/lib/core/storage/local_database.dart](apps/mobile/lib/core/storage/local_database.dart) version=1, 5 张表。

升级 v1 → v2：

```dart
// onUpgrade(oldVersion=1, newVersion=2):
//   全表加 user_id：word_records / wordbook_progress / daily_checkins
//                   / custom_wordbooks / vocabulary_notebook
//   方法：CREATE 新表 + INSERT SELECT * FROM 老表 + 写 user_id 默认值
//        + DROP 老表 + RENAME 新表
//   user_id 默认值：从 SharedPreferences 读取 server_guest_user_id；
//                  若不存在（极端情况），写 'pending-local-guest'
```

SQLite 的 ALTER TABLE 不支持加 NOT NULL 列且改 UNIQUE 约束（review 2 #6 是对的）。所以这里必须走"创建新表 + 拷贝 + 删除老表"的迁移模式。代码量不大但事务化要做对，失败要可回滚。

### 7.2 drift `AppDatabase` v12 → v13

20 张表里**只给用户行为表加 user_id**，公共内容层不动。复用 v1 §2.2.1 的清单（保持不变）：

加 user_id 的表：wordRecords*、wordbookProgress*、dailyCheckins*、customWordbooks*、vocabularyNotebook*、cardStates、reviewLogs、sessions、reviewRecords

(*) 表：drift 也有同名表，与 raw sqflite 重叠（这是历史遗留——v1 也没把这点摸清）。drift 的这些表如果实际**没在用**（数据只在 raw sqflite 里），那加 user_id 是空操作；但仍要加列以保持 schema 一致。Phase 0 审计要确认：哪些表 drift 在用、哪些表 sqflite 在用、是否有同名重叠。

**不加 user_id 的表**：audioFileCache（公共缓存）、presetWordbooks/wordEntries/wordBookAssignments/exampleSentences/wordForms/wordRelations/wordPhrases/morphemeEntries/wordMorphemeMatches/contentPackageStates（PRD §5.2 公共内容层）

drift v12→v13 走 drift 标准 migration。drift 的 `Migrator` 内部会按需做 table rebuild（drift 已封装 SQLite 限制），相对 raw sqflite 更安全，但仍要写真实数据回放测试（按 D5 决策）。

### 7.3 SharedPreferences key 全审计

审计三类用户数据全局键：

| 来源 | 现有 key | v2 处理 |
|------|----------|---------|
| LocalSettingsService | `settings_daily_goal` / `settings_sound_enabled` / `settings_theme` / `settings_notification_time` / `settings_desired_retention` / `settings_active_wordbook` / `settings_manifest_sync_enabled` | 改为 `u_${userId}_settings_*` |
| LocalProgressRepository | `progress_word_records` / `progress_wordbook_progress` / `progress_daily_checkins` / `progress_custom_wordbooks` / `progress_vocabulary_notebook` | 改为 `u_${userId}_progress_*`；**且需考虑：这些 key 与 raw sqflite 表是否重复？**Phase 0 审计 |
| BackupUploadService | `backup_latest_status` / `backup_latest_id` / `backup_latest_uploaded_at` / `backup_latest_schema_version` | 改为 `u_${userId}_backup_*` |
| RoomCanvasStorage | `room_canvas_layout_v1` | 改为 `u_${userId}_room_canvas_layout_v1` |
| DeviceInfoService | `device_unique_id` | **不改**（device 级，跨用户共享） |
| AuthStorage | `auth_access_token` / `auth_current_user_id` / `auth_account_type` | 全局**单值**（同时只能有一个 active user） |

迁移时机：当用户首次拿到 server_guest_user_id 时，做一次 SP key namespace 化迁移。迁移失败要可重试（标记 `auth_pending_sp_migration`）。

### 7.4 启动时序（v2 新增）

```
App.main() 启动:
  ↓
  1. WidgetsFlutterBinding.ensureInitialized()
  2. SharedPreferences.getInstance() — 拿 device_id（已存在生成）
  3. AuthBootstrap.run()
     ├── 读 auth_current_user_id
     │   ├── 有 → 进入 step 4，用此 id
     │   └── 无 → 调 /auth/guest（有网）或写 'pending-local-guest'（无网），进入 step 4
     └── 试图刷新 token（如有 access_token）
  4. LocalDatabase.initialize() — 跑 v1→v2 migration（用 step 3 拿到的 user_id 给老数据落 user_id）
  5. AppDatabase.initialize() — drift 跑 v12→v13 migration（同上）
  6. SP namespace 迁移（如未做过）
  7. runApp(MeowApp())
```

每一步失败都不能让 App 进不了主页：失败标记 + 主页能看到 + 后台重试。

---

## 8. 备份/恢复 per-user 改造（v1 漏项）

### 8.1 当前问题

[snapshot_export_service.dart:69](apps/mobile/lib/core/storage/snapshot_export_service.dart) `_buildSnapshot` 直接 `_db.getAllWordRecords()` / `_db.getAllFromTable('card_states')`，是全表导出。
[backup_restore_service.dart:144](apps/mobile/lib/core/storage/backup_restore_service.dart) `_applySnapshot` 是 `replaceAllWordRecords` / `replaceAllInTable`，全表替换。

多用户后会出问题：用户 A 备份导出会拿到 B 的数据，A 恢复会清掉 B 的本地数据。

### 8.2 改造方案

```dart
// snapshot_export
Future<Map> _buildSnapshot(String userId) async {
  final wordRecords = await _db.getAllWordRecordsForUser(userId);  // WHERE user_id = ?
  // ...
}

// backup_restore
Future<void> _applySnapshot(Map snapshot, String userId) async {
  // 仅删当前 userId 的行，再插回
  await _db.deleteWordRecordsForUser(userId);
  await _db.insertWordRecords(snapshot['progress']['word_records']);
  // ...
}
```

`replaceAllInTable` 这种全表 API 全部弃用，改 `replaceForUser`。

### 8.3 远端 snapshot 路径

后端备份路径必须含 user_id（看 `BackupController` 的 controller 路径）。如果当前是 `/me/backup`，由 AuthGuard 解析的 user_id 决定，自然分用户。但如果后端存储路径里只用了文件名 hash，需要改成 `<user_id>/<snapshot_id>` 这样的命名空间。Phase 0 审计 BackupController 现状。

---

## 9. 风险与已知缺口

| 风险 | v2 缓解 |
|------|--------|
| sqflite v1→v2 + drift v12→v13 双库 migration 同步失败 | 按 §7.4 时序，sqflite 失败回滚 v1，drift 失败回滚 v12，两库独立事务；提供 `导出本地数据` 降级出口 |
| 派生 device_id 的 SharedPreferences 在用户"清除应用数据但不卸载"时被重置 → user_id 变 → 数据失联 | server_guest_user_id 是服务端 ID，不依赖 device_id 派生，"重新发现"机制：拿到新 device_id 后调 /auth/guest 时，服务端按 device_id 查到原 guest，返回原 user_id。**前提是用户曾经联网过一次**。完全离线 + 清数据 = 数据无法找回，**这是已知缺口，写在 README** |
| AUTH_ENFORCE 切流后 dev/staging 容易回落到关闭状态 | 启动期断言 + 监控告警；CI lint 检查 production env 文件 |
| 服务端绑定成功 + 客户端本地 SP/drift/sqflite 部分迁移失败 | 拆为多阶段标记：`auth_pending_local_drift_migration` / `auth_pending_local_sqflite_migration` / `auth_pending_sp_migration`，每个 idempotent 可重试 |
| 同行升级后业务表 user_id 列保留 `guest-...` 前缀，前端误以为用户仍是游客 | 文档明示前缀不参与业务判断；前端用 `account_type` 字段判断 |
| 本地 raw sqflite 与 drift 同名表重叠（word_records / wordbook_progress / daily_checkins / custom_wordbooks / vocabulary_notebook） | Phase 0 审计：哪个是 truth；推荐答案"raw sqflite 是 truth，drift 同名表为空或迁移用"，然后 v2 之后逐步只保留一份 |
| 30 天 access token 用户需重登 | UX 上接受；如不可接受 → D12 选 refresh token |
| Phase E 切流时老客户端被强升 | 强升提示 + 一段过渡期保留旧 token 兼容 |

---

## 10. 决策点（v2 增补，需用户确认）

v1 D1~D7 保留：

- **D1** 忘记密码 v1 不做。
- **D2** 仅邮箱密码，不接第三方。
- **D3** JWT 30 天，无 refresh。
- **D4** `dev-user-001` 保留 + DEV_BYPASS_TOKEN 旁路。
- **D5** drift v13 user_id 加在用户行为表（§7.2 清单）。
- **D6** 游客本地 user_id 来源 = server 给（§6.3 单 ID 方案），离线占位 `pending-local-guest`。
- **D7** 登出绝不删本地数据。

v2 新增 D8~D15：

- **D8** v1 不做邮箱验证（注册即可登录）。OK?
- **D9** 密码策略：最短 8、最长 64、不强制复杂度。OK?
- **D10** 速率限制：注册同 IP 5/小时、登录失败 10 次/分钟锁 5 分钟。OK?
- **D11** **token 过期处理：保留 `auth_current_user_id`，仅清 token，弹重登。绝不切游客**（§6.4）。OK?
- **D12** 30 天 token 过期 = 用户每月强制重登。如不可接受需做 refresh token，本轮加任务 → 计划再扩。如可接受 → 保持。**默认建议保持**。OK?
- **D13** AUTH_ENFORCE 在 production 启动期断言为 true。OK?
- **D14** 新 BR 文件命名沿用 `BR-USER-001_v0.1.0_full.md` 形式，目录 `docs/design/`。OK?
  - ✅ **2026-05-11 落地**：[`./BR-USER-001_v0.1.0_full.md`](./BR-USER-001_v0.1.0_full.md)（Phase G commit；含 4 条 BR：身份规则 / 绑定规则 / 退出切换规则 / 数据归属规则）。
- **D15** **不改路由前缀**（不把 `/sessions` 改成 `/me/sessions`），AuthGuard 加在控制器/方法级，避免破坏客户端（§4.1）。OK?

v2 新增 D16：

- **D16** 同行升级后 users.id 保留 `guest-...` 前缀（前端不依赖前缀语义）。OK?

---

## 11. 文档 patch 计划修正（解决 review 1 §1.4）

按 D14 待确认结果，文档 patch 准确路径：

- `docs/system_design/背单词喵喵app_API设计草案_v0.2.3.md` → 增加 `/auth/*` 章节、控制器逐条 auth 标注（§4.1 表）、AUTH_ENFORCE feature flag
- `docs/system_design/背单词喵喵app_DB设计草案_v0.2.3.md` → migration 008/009、users 字段说明、唯一约束变更
- `docs/design/BR-USER-001_v0.1.0_full.md`（新建，沿用 BR-OPP 命名约定）→ 用户身份规则、游客绑定规则、退出/切换规则、数据归属规则
- `docs/design/UI_SPEC_v0.2.0.md` 或 archive 中最新版（待 D14 确认）→ 登录/注册/我的页/退出确认对话框 SPEC

---

## 12. 交付清单（每 Phase）

按 CLAUDE.md §6：受影响文件清单 / 改动摘要 / 测试命令+结果 / 已知问题 / 是否触碰核心契约 / 文档 patch。

---

## 13. 下一步

请用户确认：

1. v2 总体方向是否 OK（特别是 Phase 重排 + AUTH_ENFORCE 切流机制）
2. D1~D16 决策点逐条 OK 或修改
3. 是否同意先做 **Phase 0 现状审计**输出三份审计文档（controller-auth-audit.md / db-uniqueness-audit.md / sp-keys-audit.md），再正式开 Phase A。Phase 0 不改代码、纯审计落档，可作为后续 PR 的依据。

不在本计划阶段写代码。按 CLAUDE.md §2.5，DB / API 设计需先取得用户确认。

---

## 14. 实施进度（2026-05-11 完成）

按 commit 顺序列出所有阶段；commit hash 来自 `feature/user-auth` 分支 `git log --oneline` 实测；测试基线在该 commit 完成后所跑的 e2e/单测套件计数。

| Phase | 子阶段 | Commit | 测试基线 | 完成日期 |
|-------|--------|--------|---------|---------|
| Phase 0 | 三份审计文档（controller-auth / db-uniqueness / sp-keys）落档 | `62ea590` | 静态文档 | 2026-05-09 |
| A1-A3 | migrations 008/009 + `/auth/*` 6 接口 + AuthGuard + AUTH_ENFORCE flag | `5547a85` | 62/62 backend e2e（auth 7 + app baseline） | 2026-05-09 |
| A4-α | repositories 接 userId + AuthGuard 接 17 controllers + audit §6 初步 owner-check | `1991be7` | 68/68 backend e2e（+6 isolation 用例） | 2026-05-09 |
| A4-β.1+β.2 | withUser async-guard + 错误码统一 + backup per-user partition (P0) | `52c1a30` | 70/70 backend e2e（+2 backup isolation） | 2026-05-10 |
| A4-β.3-β.6 | dev-store 23 *ByUser maps + idempotency Map per-user + pg-persistence userId | `3833c25` | 70/70 backend e2e（无新用例，内部重构） | 2026-05-10 |
| A4-β.7+β.8 | audit §6 isolation e2e 补全 + plan β.8 文档 | `78eec7c` | 76/76 backend e2e（+6 isolation：idempotency 真测 / today / balance / review-group / inventory / lottery / fishing） | 2026-05-10 |
| A4-β.9 | review 评审 hot-fix（userDailyNewTarget partition + catProfile.nickname per-user + source_ref_id/session_id cross-user check） | `a4b1627` | 79/79 backend e2e（+3 isolation：source_ref_id / session_id / settings daily_new_target） | 2026-05-10 |
| Phase B | 移动端身份层（AuthStorage + AuthController + UI + AuthHttpClient） | `9d992c8` | 1218/1218 mobile unit | 2026-05-10 |
| Phase B hot-fix | 评审采纳（ApiClient wiring / logout 切 guest / 网络 ≠ tokenExpired / placeholder） | `5d83936` | 1218/1218 mobile unit | 2026-05-10 |
| Phase C PR-C-α | drift v13 user-scoped partition schema（9 张表 + 3 UNIQUE 复合 key） | `6d33cbe` | mobile drift migration test + 1218/1218 unit | 2026-05-10 |
| Phase C-α tidy | 后端 e2e state-resilience + analyzer infos | `3ce5ec0` | backend e2e green | 2026-05-10 |
| Phase C PR-C-β | user-scoped DAOs + repositories + SpMigrator（pre-C → `u_<userId>_*`） | `d93279d` | mobile unit + 新增 SpMigrator/DAO 隔离用例 | 2026-05-10 |
| Phase C PR-C-γ | epoch race guard + pending-local-guest migration | `1584440` | 1212/1212 mobile（epoch 用例 + pending migrator 用例） | 2026-05-10 |
| Phase C PR-C-δ | `phase_c_e2e_test.dart` 14 用例 T1-T14 + 集成 handoff | `4d3cb3a` | mobile +14 e2e（T3 SpMigrator / T4 UNIQUE / T5 DAO / T6 service / T7 logout / T8 same-row / T14 schema） | 2026-05-10 |
| Phase D PR-D-α | mobile backup auth client（AuthHttpClient wiring）+ 10MB body limit | `83726ec` | mobile `backup_auth_header_test.dart` + backend body limit e2e | 2026-05-10 |
| Phase D PR-D-β | backup PG 持久化（migration 010 + `backup_snapshots`）+ BackupController 旁路 dev-store + user_id 校验 | `aaefffc` | backend +`backup-persistence.e2e-spec.ts` ~10 用例（D-T1/T2/T3/T4/T6/T8/T10/T14） | 2026-05-10 |
| Phase D PR-D-γ | restore 无条件 user_id 覆盖 + 6-entity pollution 客户端校验 | `2f32510` | mobile `backup_restore_hardening_test.dart` + 强制覆盖用例 | 2026-05-10 |
| Phase D PR-D-δ | `phase_d_e2e_test.dart` 4 用例（D-T7 / D-T11 / D-T13 / D-T14）+ multi-account coexistence | `4c679a9` | mobile +4 e2e + backend D-T13/D-T14 backup-persistence 用例 | 2026-05-10 |
| β.5b + β.5c + audit §6 残留 | dev-store ensureUserLoaded lazy-load + ownedItems/equipped/wallet *ByUser snapshot + pg-persistence per-user persist + 4 cross-user 404 e2e | `34a67df` | 101/101 backend e2e（auth-isolation 27 + auth 7 + backup-persistence 12 + pg-regression 55） | 2026-05-11 |
| Phase G | 文档收尾（PRD §9 验收对照 + BR-USER-001 + plan 实施进度 + audit v1.2 修订） | _(本 commit)_ | 静态文档（无新业务测试） | 2026-05-11 |

### 14.1 验收闭环

PRD §9 七节 32 项验收逐条对照表见 [`./audits/prd-§9-acceptance-coverage.md`](./audits/prd-§9-acceptance-coverage.md)。Phase G commit 时表内**全部 ✅**（0 ⚠️ / 0 ❌）。

### 14.2 不在本闭环（独立后续 PR）

- **Phase E1**：staging → production 翻 `AUTH_ENFORCE=true` flag（plan v2 §2 / D13）。当前 production assertion 已生效（`main.ts:12`），但 staging 默认未开 enforce。
- **Phase F**：跨设备绑定流程 UI 触发归属（plan-023-D-v2 §1.2 明示不在 Phase D 范围）。
- **β.6 cosmetic refactor**：彻底去 withUser、给所有 ~50 个 dev-store 公共方法显式加 userId 参数（A4-β.9 决策保留 withUser 作为 binding 入口，纯 cosmetic 不阻塞 §9）。
- **Audit §6 e2e 100% 硬化**：当前 ~89%（16/18 方法路径），剩 2 项是 lottery 跨用户「真隔离」和 review-attempts/local-batch 子用例细化，功能上已无 cross-user 写入路径。

### 14.3 BR / 审计 落档

| 文档 | 状态 |
|------|------|
| [`./audits/controller-auth-audit.md`](./audits/controller-auth-audit.md) | v1.2（Phase G 修订记录） |
| [`./audits/db-uniqueness-audit.md`](./audits/db-uniqueness-audit.md) | v1.2（Phase G 修订记录） |
| [`./audits/sp-keys-audit.md`](./audits/sp-keys-audit.md) | v1.2（Phase G 修订记录） |
| [`./audits/prd-§9-acceptance-coverage.md`](./audits/prd-§9-acceptance-coverage.md) | v1.0（Phase G 新建，本节验收门票） |
| [`./BR-USER-001_v0.1.0_full.md`](./BR-USER-001_v0.1.0_full.md) | v0.1.0（Phase G 新建，落地 D14） |
| [`./plan-023-A4-beta-v1.md`](./plan-023-A4-beta-v1.md) | complete |
| [`./plan-023-C-mobile-local-partition-v2.md`](./plan-023-C-mobile-local-partition-v2.md) | complete |
| [`./plan-023-D-backup-restore-closure-v2.md`](./plan-023-D-backup-restore-closure-v2.md) | complete |
| [`./plan-023-C-mobile-local-partition-v1.md`](./plan-023-C-mobile-local-partition-v1.md) | ⚠️ Superseded by v2 |
| [`./plan-023-D-backup-restore-closure-v1.md`](./plan-023-D-backup-restore-closure-v1.md) | ⚠️ Superseded by v2 |
