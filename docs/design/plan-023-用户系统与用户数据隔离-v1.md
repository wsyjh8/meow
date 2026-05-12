# 需求 23 实施计划：用户系统与用户数据隔离 v1

**Plan Version:** v1
**Status:** draft（待用户确认）
**对应 PRD:** `docs/design/prd-023-用户系统与用户数据隔离-v1.md`
**Branch:** `feature/user-auth`
**作者:** Claude Code（AI 开发者）
**日期:** 2026-05-09

---

## 0. 阅读须知

PRD v1 是按"老系统假设"写的（无鉴权、单用户开发态、所有表都没 user_id）。**实际现状摸完底之后发现 PRD 的一个核心假设不准确**，本计划据此调整：

| 维度 | PRD 假设 | 实际现状 |
|------|---------|---------|
| 后端 DB 是否有 user_id | 假设没有 | **已经全有**（20+ 张表都已带 `user_id VARCHAR(64) REFERENCES users(id)` 和索引） |
| 后端是否有 users 表 | 假设没有 | **已存在**（仅 nickname/timezone/locale，无任何鉴权字段） |
| 后端鉴权 | 无 | 无（确认） |
| 后端 user 上下文 | 无 | 全靠硬编码常量 `DEV_USER_ID = 'dev-user-001'` 注入 |
| 移动端 drift 表是否有 user_id | 假设没有 | **确认没有**（全是 device-local，drift v12） |
| 移动端是否有 device_id | 不知道 | 已存在（SharedPreferences `device_unique_id`，UUID v4） |
| 移动端登录页 / 状态管理 | 无 | 无（确认，纯 StatefulWidget） |

**关键含义：**

- 后端的"加 user_id 列 + 加 user_id FK"工作几乎已经做完。本轮真正的工作是**填上鉴权**和**把 `dev-user-001` 改成从请求里解析出来**。
- 移动端是真正的从零开始：要加登录页、要加 user_id 列、要做账号上下文、要做绑定迁移。**这部分占本需求 70% 工作量。**
- API 路由已经全部用 `/me/*` 前缀，结构也已经准备好接 user 上下文。

---

## 1. 实施总策略

### 1.1 切分原则

按"独立可上线 / 独立可回滚"切分，每个 Phase 独立有意义、不留半成品：

```
Phase A — 后端鉴权地基（API + DB）
  ├── A1: users 表加鉴权字段 + 注册/登录/登出 API + JWT
  ├── A2: AuthGuard + CurrentUser decorator + 全部 /me/* 路由接 user 上下文
  └── A3: 拆掉 dev-store 硬编码 DEV_USER_ID（保留 dev fallback 但要显式开关）

Phase B — 移动端身份层（Mobile, 不动 drift schema）
  ├── B1: 本地 token 存储 + ApiClient 注入 Authorization
  ├── B2: 登录 / 注册 / 游客 / 退出登录 UI（与现有 SpecShell 集成）
  └── B3: 我的页 / 设置页加账号区

Phase C — 移动端本地数据隔离（drift schema 大改）
  ├── C1: drift schema v13: 全表加 user_id + 当前用户 sentinel 'guest-local'
  ├── C2: 仓库层 / 查询层全部按 currentUserId 过滤
  └── C3: 退出登录 / 切换账号上下文清空（逻辑切，不删数据）

Phase D — 游客绑定与迁移
  ├── D1: 游客本地 user_id = 设备 guest 标识（确定性，不重复）
  ├── D2: 绑定 API：服务端把 guest_user_id 的数据 owner 改写为正式 user_id（事务）
  └── D3: 移动端绑定流程 + 失败回滚保留游客数据

Phase E — 验收与硬纪律
  ├── E1: 集成测试：用户 A / B 隔离、FSRS 隔离、奖励隔离
  ├── E2: 集成测试：游客绑定不丢数据
  └── E3: 安全测试：未登录拒访、跨用户拒访、token 过期
```

每个 Phase 自己一个 PR / 一组 PR。每 Phase 结束都能上线（不阻塞继续上线后续 Phase）。

### 1.2 边界确认（不偷偷扩写）

按 PRD section 4，本轮**不做**：
- 实时双向同步、多设备 merge
- 第三方登录（邮箱密码 only）
- 忘记密码（v1 暂不做，写在已知缺口）
- 第二次绑定 / 解绑账号
- 复杂权限 / 角色

按 PRD section 6，本轮**保持**：
- 本地优先 + 手动备份边界（不变）
- 登录 ≠ 自动同步、备份 ≠ 多设备一致、恢复才改本地

---

## 2. DB 变更设计

> **本节是 CLAUDE.md §2.5 强制要求的设计文档段落，写代码前等用户确认。**

### 2.1 后端 PostgreSQL 变更

#### 2.1.1 `users` 表加鉴权字段

**migration 008_user_auth.sql（新增）**

```sql
ALTER TABLE users
  ADD COLUMN email VARCHAR(255) UNIQUE,             -- 正式用户唯一标识；游客为 NULL
  ADD COLUMN password_hash VARCHAR(255),            -- bcrypt；游客为 NULL
  ADD COLUMN account_type VARCHAR(16) NOT NULL DEFAULT 'guest',
    -- 'guest' | 'registered'
  ADD COLUMN bound_from_guest_id VARCHAR(64),       -- 绑定来源；记录可追溯
  ADD COLUMN last_login_at TIMESTAMPTZ;

CREATE UNIQUE INDEX idx_users_email_lower
  ON users (LOWER(email)) WHERE email IS NOT NULL;
```

**字段用途：**
- `email`：正式账号唯一标识。游客为 NULL。区分大小写按业界惯例统一 lower。
- `password_hash`：bcrypt cost=12（参考默认）。游客为 NULL。
- `account_type`：明确账号类型，约束逻辑用：guest 不能登录 / 不允许重复绑定。
- `bound_from_guest_id`：绑定后记录原游客 id，便于审计和数据回溯。
- `last_login_at`：仅记录，不做安全用途。

#### 2.1.2 不动现有 `users(id)` 主键格式

继续用 `VARCHAR(64) PRIMARY KEY`。游客用 `guest-<uuid>`，正式用户用 `user-<uuid>`，前缀仅做人眼区分用，业务不依赖。

#### 2.1.3 不新增表（refresh token 表暂不做）

v1 用单 access token（JWT）+ 长有效期（30 天），不引入 refresh token 表。理由：
- v1 不做多设备同步，不需要复杂 session 管理。
- 退出登录走客户端清 token 即可，服务端不维护黑名单。
- 后续如果要加，再 008 → 009 增量。

#### 2.1.4 `bound_from_guest_id` 可选清理

绑定后**不删除**原 guest user 行，仅在 users 表保留一条 `account_type='guest'` 的"已迁移"记录（可选打 `migrated_at` 标）。删除会破坏外键完整性，且无收益。

---

### 2.2 移动端 drift 变更（**这是本轮工作的大头**）

#### 2.2.1 schema 升级到 v13

drift 当前 v12。本轮做 **migration v12 → v13**。

**变更：**

给以下表全部加 `user_id TEXT NOT NULL`（drift 里用 `TextColumn`）：

| drift 表 | 当前 | v13 后 |
|---------|------|--------|
| `wordRecords` | 无 user_id | + user_id |
| `wordbookProgress` | 无 user_id | + user_id |
| `dailyCheckins` | 无 user_id | + user_id |
| `customWordbooks` | 无 user_id | + user_id |
| `vocabularyNotebook` | 无 user_id | + user_id |
| `cardStates` (FSRS) | 无 user_id | + user_id |
| `reviewLogs` (FSRS) | 无 user_id | + user_id |
| `sessions` | 无 user_id | + user_id |
| `reviewRecords` | 无 user_id | + user_id |
| `audioFileCache` | 无 user_id | **不加**（公共缓存，跨用户共享） |
| `presetWordbooks` / `wordEntries` / `wordBookAssignments` / `exampleSentences` / `wordForms` / `wordRelations` / `wordPhrases` / `morphemeEntries` / `wordMorphemeMatches` / `contentPackageStates` | 无 user_id | **不加**（公共内容层，按 PRD §5.2） |

主键 / UNIQUE 约束随之改造（凡是涉及"某个用户对某个词的状态"的，UNIQUE 改为 `(user_id, word_id, ...)`）。

**对 `cardStates` 这类核心表举例：**

```dart
// v12:  PRIMARY KEY (word_id)  或  UNIQUE (word_id)
// v13:  UNIQUE (user_id, word_id)
```

#### 2.2.2 v12 → v13 数据迁移

设备本地已有数据（单设备开发态用户的进度），需要全部归到一个**确定性**的 guest_user_id 下。

**迁移逻辑：**

```
1. 读 / 生成 device_unique_id（已存在）
2. 派生 local guest_user_id = "guest-local-" + device_unique_id  // 确定性，多次升级不会变
3. UPDATE 所有需要加 user_id 的表 SET user_id = local_guest_user_id WHERE user_id IS NULL
4. 把 NOT NULL 约束加上
```

迁移失败的处理：drift 的 migration 是事务性的，失败回滚到 v12，App 进不了主页则提示"升级失败，请联系支持"——不破坏用户数据。

> **关键约束：** local guest_user_id 必须是确定性的（基于 device_id 派生），不能每次启动都变。否则升级一次数据全丢。

#### 2.2.3 SharedPreferences 增量

新增 keys：
- `auth_access_token`（JWT，登录后写入；退出登录清空）
- `auth_current_user_id`（当前 active 用户 id；游客时是本地 guest 派生 id；登录后是服务端返回的正式 user_id）
- `auth_account_type`（'guest' | 'registered'）

旧的 settings 类 keys（`settings_daily_goal` 等）需要**带 user_id 命名空间**。改造方案：
- 新增 `LocalSettingsService.forUser(userId)` 工厂方法
- 内部 key 拼接为 `u_${userId}_settings_daily_goal` 等
- 老 key 在 v13 升级时按"当前 device 派生的 guest user_id"做一次性迁移

---

## 3. API 变更设计

### 3.1 新增接口

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 注册 | POST | `/auth/register` | body: `{ email, password }` → `{ user, token }` |
| 登录 | POST | `/auth/login` | body: `{ email, password }` → `{ user, token }` |
| 游客起号 | POST | `/auth/guest` | body: `{ device_id }` → `{ user, token }`（同 device_id 幂等） |
| 当前用户 | GET | `/auth/me` | Authorization 头 → `{ user }` |
| 登出 | POST | `/auth/logout` | 客户端清 token 即可；服务端目前 no-op，保留接口位 |
| 游客绑定 | POST | `/auth/bind` | Authorization=guest_token, body: `{ email, password }` → `{ user, token }` |

**返回 user 对象格式：**
```json
{
  "id": "user-xxx",
  "email": "...",          // guest 为 null
  "nickname": "...",
  "account_type": "guest" | "registered",
  "created_at": "...",
  "bound_from_guest_id": "..."  // 仅绑定来的正式账号会有
}
```

### 3.2 修改接口

**所有 `/me/*` 路由**：
- 加 `AuthGuard`（默认全 require auth；游客 token 也算 authed）
- 注入 `@CurrentUser() user` 或读 `req.user.id`
- 把当前所有内部仍调用 `repositories.x.getXxx()` 的代码改为 `repositories.x.getXxx(userId)`
- `dev-store.ts` / `pg-persistence.ts` 内部所有 `DEV_USER_ID` 常量去掉，改为方法入参或 ctor 注入

**核心语义不变**——这点对照 CLAUDE.md §4.4，不算"改对外 API 核心语义"，因为路由、参数、响应结构都不变，只是补上原本就该带的鉴权。

### 3.3 鉴权方案

- JWT（HS256），密钥放 env `JWT_SECRET`
- Payload：`{ sub: user_id, type: 'guest'|'registered', iat, exp }`
- 有效期：30 天
- 头部：`Authorization: Bearer <token>`
- 错误码：`401 UNAUTHENTICATED`（无 token / 无效 / 过期），`403 FORBIDDEN`（跨用户访问，理论上前述 user_id 过滤已经能挡）

### 3.4 不改的接口

`/admin/*`、`/maintenance/*`、`/health` 这类系统接口不接 AuthGuard。

`/wordbooks`、`/words`、`/audio-assets` 这类公共内容接口不接 AuthGuard（按 PRD §5.2，是公共内容层）。

---

## 4. 移动端架构变更

### 4.1 当前用户上下文（Rule 1：唯一）

新增 `lib/core/auth/` 目录：

```
lib/core/auth/
  ├── auth_state.dart            # 当前用户的 immutable snapshot
  ├── auth_controller.dart       # ChangeNotifier，唯一持有 currentUser
  ├── auth_storage.dart          # token / current_user_id 的持久化
  ├── auth_api.dart              # /auth/* 接口客户端
  └── auth_bootstrap.dart        # 启动时恢复 auth state
```

**架构选择**：项目当前没用 Provider/BLoC/Riverpod，全是 StatefulWidget。本轮**最小化破坏**：用 `ChangeNotifier` + `InheritedNotifier` 暴露 currentUser，所有需要的页面用 `AuthScope.of(context)` 读。这种方式在 Flutter 里轻量、无新依赖、和 StatefulWidget 兼容。

### 4.2 ApiClient 改造

`lib/core/api/api_client.dart` 加 token 注入：

```dart
class ApiClient {
  final AuthStorage _authStorage;
  // ...
  Future<http.Response> _send(...) async {
    final token = await _authStorage.readToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    // ...
  }
  // 处理 401: 通知 AuthController 切到游客 / 弹登录
}
```

### 4.3 启动流程（auth_bootstrap）

```
App 启动
  ↓
读 auth_storage：有 token 吗？
  ├── 有 → GET /auth/me 验证
  │       ├── 200 → 进入 currentUser 上下文
  │       └── 401 → 清 token，转游客
  └── 无 → 创建本地 guest user_id（确定性派生），
          调 POST /auth/guest 拿 guest token，
          失败也允许进入（离线游客模式：仅本地写）
```

> **离线游客**是关键容错：没网也得能用。token 拿不到不阻塞 App 启动，本地数据用 local guest_user_id 写入，等有网时再 backfill。

### 4.4 退出登录与切换账号（Rule 5：不串数据）

退出登录的实现：
1. 清 `auth_access_token`
2. AuthController 切回"未登录"状态
3. **不删任何本地数据**（按 PRD section 8 失败原则的扩展）
4. 重新初始化为本地游客上下文（同启动流程）

切换账号 = 退出 + 登录的串联流程，**App 必须先把所有 page 的 in-memory state 销毁重建**。最简实现：登录成功后 `Navigator.pushNamedAndRemoveUntil('/home')`，把 widget 树重建一遍。

### 4.5 仓库层改造

drift 的所有 DAO 查询全部加 `userId` 入参：

```dart
// 改之前：
Future<List<WordRecord>> getAllLearned() => 
  (select(wordRecords)..where((r) => r.learned.equals(true))).get();

// 改之后：
Future<List<WordRecord>> getAllLearned(String userId) =>
  (select(wordRecords)
    ..where((r) => r.userId.equals(userId) & r.learned.equals(true)))
  .get();
```

调用侧（页面 / 服务）从 `AuthScope.of(context).currentUser.id` 取 userId 传入。

---

## 5. 游客绑定方案（Rule 4：不丢数据）

### 5.1 游客本地 user_id 派生

```
local_guest_user_id = "guest-local-" + sha256(device_unique_id)[0..32]
```

确定性、稳定、跨升级不变、不可猜测。

### 5.2 服务端游客 user_id

游客调 `POST /auth/guest { device_id }`：
- 服务端按 `(device_id)` 查是否已有 guest 用户，有则返回
- 没有则创建 `users` 行，`account_type='guest'`，`id='guest-' + uuid()`
- 返回 token

**关键：服务端 guest_user_id ≠ 本地 local_guest_user_id**。本地数据是按 local_guest_user_id 写入的，跟服务端没关系。绑定时才上行。

### 5.3 绑定流程

```
游客点"绑定账号"
  ↓
弹邮箱 + 密码表单
  ↓
POST /auth/bind  (Authorization=guest token, body={email, password})
  ↓
服务端事务：
  1. 校验 email 不重复
  2. UPDATE users SET account_type='registered', email=..., password_hash=...,
     bound_from_guest_id=<原 guest_id> WHERE id=<当前 guest_id>
  3. 返回新 token
  ↓
客户端：
  1. 拿到新 token，写入 storage
  2. 本地数据库：UPDATE 所有表 SET user_id=<新 user_id> WHERE user_id=<local_guest_user_id>
  3. AuthController 切到 registered 上下文
```

**关键约束（Rule 4）：**
- 服务端事务任一步失败 → 全部回滚 → 客户端继续保留游客状态 → 本地数据原样不动
- 客户端本地 UPDATE 失败 → **不能回滚服务端**（服务端已经把 guest 升级为 registered 了）→ 客户端必须有重试或可恢复机制：把"未完成本地迁移"标记落到 SharedPreferences，App 启动时重试

> 这里有个真实风险：服务端绑定成功但客户端本地迁移失败，重启后 token 是 registered 的但本地数据 user_id 还是 local_guest。这时启动流程要识别这个 inconsistency 并重试本地 UPDATE。

### 5.4 服务端是否需要数据迁移？

**v1 不需要**，因为本地优先架构下，服务端目前只存"备份快照"，不存日常学习数据。备份系统按 user_id 索引快照即可，guest 用户的备份在绑定后自动归入 registered 用户名下（因为 user_id 没变）。

---

## 6. 现有单用户数据迁移策略

### 6.1 后端 dev-user-001 的处理

后端 PostgreSQL 里目前所有数据都挂在 `users.id='dev-user-001'` 下。本轮处理：

**选项 A（推荐）：** 把 `dev-user-001` 直接当成"开发者本人的游客账号"保留，不动。AuthGuard 上线后，dev 环境下走专用 dev token（env `DEV_BYPASS_TOKEN`）映射到该 user。

**选项 B：** 上线 AuthGuard 时清掉 dev 数据。**不推荐**，会丢开发者本人的测试数据，违反 CLAUDE.md §3.3 "不静默加 destructive action"。

→ 方案：默认走 A，明确写在 .env.example 里 `DEV_BYPASS_TOKEN` 是仅开发环境可用的旁路。

### 6.2 移动端单设备已有数据

按 §2.2.2，drift v12→v13 自动归到 local_guest_user_id。用户感觉不到任何变化（游客起号也是同一份数据）。

---

## 7. 测试策略

### 7.1 后端

- **单测**：AuthService（注册、登录、token 校验、密码哈希）
- **集成测试**：
  - 用户 A 提交学习数据，用户 B `/me/today` 看不到 A 的数据
  - 未带 token 访问 `/me/*` → 401
  - 用户 A 的 token 无法读 / 写用户 B 的数据（因为 user_id 是从 token 解析的，构造不出来；但要测试 SQL 注入式越权）
  - 游客绑定：guest_user_id 升级为 registered 后，bound_from_guest_id 正确记录
  - token 过期 → 401

### 7.2 移动端

- **drift 迁移测试**：v12 → v13，old data 全部归到 local_guest_user_id，行数不丢
- **集成测试**：
  - 游客学 10 个词 → 绑定 → 仍能看到 10 个词
  - 用户 A 登录 → 退出 → 用户 B 登录 → 看不到 A 的数据
  - 退出登录后游客上下文是干净的（不串 A 数据）
  - 离线游客（无网启动）能正常学习
- **手动测试**：实机 Android（CLAUDE.md 提示用 flutter run + 浏览器验证 UI）

### 7.3 PRD §9 验收清单逐条对应

按 PRD 9.1 ~ 9.7 各小节写一份验收测试清单，作为 E1/E2/E3 阶段交付物。

---

## 8. 风险与已知缺口

| 风险 | 缓解 |
|------|------|
| drift v12→v13 是大 schema 改动，迁移失败会让用户进不了 App | 迁移脚本完整事务化；写一份 v13 schema 的迁移测试，跑过往真实数据样本；提供 fallback 一键导出本地数据 |
| 服务端绑定成功 + 客户端本地 UPDATE 失败的不一致 | 启动时识别 `auth_pending_local_migration` 标记并重试；做 idempotent 的本地 UPDATE |
| `local_guest_user_id` 派生算法变了会让用户数据"丢失"（实际还在但查不到） | 派生算法确定，并在文档里写明"一旦上线不可改" |
| 已经有 dev_user_001 的开发者环境，AuthGuard 上线后接口全 401 | DEV_BYPASS_TOKEN 旁路 + .env.example 明示 |
| 第三方登录（微信 / Apple）的需求随时可能加进来 | v1 不做，但 users 表设计预留（email 可空，account_type 可扩展） |
| 忘记密码 v1 不做 | UI 上不放入口 / 放但 toast "暂未开放"；写在 README 已知缺口 |

### 8.1 必须停下来再确认的事项（按 CLAUDE.md §4 上报）

按 CLAUDE.md §4 触发条件，本计划触碰的：

1. ✅ 触碰 §4.1（新增表 / 改字段）：`users` 加 5 个字段（migration 008）
2. ✅ 触碰 §4.4（改对外 API 核心语义）：所有 `/me/*` 加鉴权——但这是从"无鉴权"补到"应有鉴权"，**语义上是补漏不是改语义**，仍向用户上报确认
3. ✅ 触碰 §4.5（migration / backfill）：drift v12→v13 全表加列 + backfill；后端 008 仅新增列，不需要 backfill
4. ❌ 不触碰 §4.2（奖励链路 / 幂等）
5. ❌ 不触碰 §4.3（状态机核心流转）
6. ❌ 不触碰 §4.6（BR / PRD 矛盾）
7. ❌ 不触碰 §4.7（UI SPEC 与 BR 矛盾）

**请用户先确认以下决策点：**

- **D1**：忘记密码 v1 不做，UI 隐藏入口。OK?
- **D2**：v1 仅邮箱密码，不接微信 / Apple 第三方。OK?
- **D3**：JWT 30 天，不做 refresh token。OK?
- **D4**：dev_user_001 数据保留，用 DEV_BYPASS_TOKEN 旁路开发环境。OK?
- **D5**：drift v13 在所有"用户行为表"加 user_id（按 §2.2.1 列表），公共内容层不动。OK?
- **D6**：游客本地 user_id 派生算法 = `"guest-local-" + sha256(device_id)[0..32]`，**一经发版不可改**。OK?
- **D7**：登出 = 清 token + 切上下文，**绝不删本地数据**。OK?

---

## 9. 交付物清单（每 Phase 结束后给的东西）

按 CLAUDE.md §6：

- 受影响文件清单
- 改动摘要（做了 / 没做）
- 测试命令 + 结果（`flutter test` / `npm run test` / `npm run test:e2e`）
- 已知问题
- 是否触碰核心契约（每个 Phase 都触碰，附文档 patch）

**文档 patch（同步更新）：**
- `docs/system_design/背单词喵喵app_API设计草案_v0.2.3.md` → 新增 `/auth/*` 章节、`/me/*` 加鉴权说明
- `docs/system_design/背单词喵喵app_DB设计草案_v0.2.3.md` → 新增 users 鉴权字段说明
- `docs/design/BR-OPP-001` → 增加 BR-USER-001 用户身份规则、BR-USER-002 游客绑定规则、BR-USER-003 退出 / 切换规则、BR-USER-004 数据归属规则
- `docs/design/UI_SPEC_v0.2.0.md` → 增加登录 / 注册 / 我的页 / 退出确认对话框 SPEC

---

## 10. 下一步

等用户确认本计划（重点是 §8.1 的 D1~D7），我再按 Phase 顺序进入实现。

不在本计划阶段写代码——按 CLAUDE.md §2.5，DB / API 设计需先取得用户确认。
