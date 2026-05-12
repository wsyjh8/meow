# Plan: 需求 23 Phase E1 — AUTH_ENFORCE=true 切流

**Plan Version:** v1
**Status:** draft（待用户确认）
**Branch:** `feature/user-auth`
**实施模型:** Opus 4.7 1M context Max
**性质:** **operational / deployment plan**，非 code design plan

**前序:** A/B/C/D + β.5b/c + audit §6 残留 + Phase G（PRD §9 对照表 + BR-USER-001 + plan 终版）

**关联:**
- [plan-023-用户系统与用户数据隔离-v2.md](plan-023-用户系统与用户数据隔离-v2.md) §1.1 Phase E1 / §10 D13
- [audits/prd-§9-acceptance-coverage.md](audits/prd-§9-acceptance-coverage.md)（Phase G 产出，本 plan 的 readiness gate）
- [plan-023-D-backup-restore-closure-v2.md](plan-023-D-backup-restore-closure-v2.md) §9 闭环定义

**日期:** 2026-05-11

---

## 0. Context

A-D + β.5b/c + audit 残留 + Phase G 全部完成后，**唯一没切换的就是 `AUTH_ENFORCE` 环境变量**。

| 当前状态 | 切流后 |
|---------|-------|
| `AUTH_ENFORCE=false`（permissive mode）| `AUTH_ENFORCE=true`（strict mode）|
| 无 token / 错 token → fallback `DEV_FALLBACK_USER_ID` | 无 token / 错 token → **401 UNAUTHENTICATED** |
| 老客户端（不带 Authorization）仍工作（写到 dev-user-001）| 老客户端**所有 /me/* 立即 401** |
| `assertProductionAuthEnforce` 启动时不强制 | production startup 必断言 `AUTH_ENFORCE=true`（D13）|

**这是需求 23 真正的"上线"** —— A-D 是把切流前置条件做齐，E1 是按下开关。

### 为什么需要独立 plan（非 code plan）

代码改动极少（`.env` 一行），但操作不可逆 + 多决策点 + 影响所有用户：
- staging 切流是真实操（model 跑 e2e + 监控）
- production 切流是用户实操（凭 playbook 操作）
- 失败时间窗口的 rollback 行为必须预先定义
- 监控指标必须预先列出

CLAUDE.md §3.3 范围纪律 + §3.4 温柔体验 + §4.4 改对外 API 核心语义 — 这三条都被 E1 触碰。所以 E1 走完整 plan 流程。

---

## 1. Phase E1 scope

### 1.1 在范围

| 子项 | 类型 | 工作量 |
|------|------|--------|
| E1.1 readiness 验证（PRD §9 + BR-USER-001 + e2e baseline） | doc 验收 | 0.5h |
| E1.2 staging cutover（修 `.env` + 严格模式跑全套 e2e） | 实操 | 2h |
| E1.3 staging soak（监控 24h 业务表现） | 等待 + 观察 | 24h elapsed / 0.5h active |
| E1.4 production cutover playbook（仅文档） | doc | 1h |
| E1.5 rollback procedure（仅文档） | doc | 0.5h |
| E1.6 监控指标 + 告警阈值（文档） | doc | 0.5h |

Claude 实际 active 工作: **~4-5h**（不含 soak elapsed）。

### 1.2 不在范围（硬边界）

| 不在范围 | 归属 |
|---------|------|
| **生产环境实际切流操作** | 用户手动执行 playbook（model 没 prod credentials） |
| 任何代码改动（除 `.env` 一行） | 如果 staging e2e 失败 → **停下来回前面 phase 修**，不要在 E1 PR 里改业务代码 |
| 老移动端强制升级 UX（min_app_version 拦截 / 升级提示）| Phase F（如果产品决定需要） |
| 灰度切流 / Canary 部署 | 推荐一次性切，详见 D2 |
| 多租户 / 多 environment 隔离 | 不在需求 23 范围 |
| 用户主动恢复云端数据 UI | Phase F UX |

---

## 2. 决策点（D1-D6，待用户拍板）

### D1 — Staging soak 时长

**选项：**
- (a) 0h（切完立即上 prod）
- (b) 24h
- (c) 72h
- (d) 1 周

**推荐：(b) 24h**。
- 0h 太冒进，e2e 是合成流量不能完全等价真实流量
- 72h+ 过于保守，staging 流量低 soak 再长收益递减
- 24h 含一个完整日夜周期 + 各时段流量分布，足以暴露最常见 regression

### D2 — 生产切流策略

**选项：**
- (a) 一次性切流（所有用户立即受影响）
- (b) 灰度切流（按用户百分比逐步切）
- (c) Canary 部署（先切单个 backend 实例）

**推荐：(a) 一次性切流**。
- 灰度需要请求路由层支持（按 user_id hash 决定 AUTH_ENFORCE flag），当前架构无此机制——临时加成本高
- 切流的失败模式是"401 风暴"，灰度不能减轻（受影响的 X% 用户照样体感 401）
- Rollback 速度（env 改回 false + restart）足够快，一次性切的代价可接受

### D3 — Rollback 触发阈值

**触发条件（任一即 rollback）：**
- 401 错误率 > 5%（持续 5 分钟）
- /me/* 5xx 错误率 > 1%（持续 5 分钟）
- 平均响应时间 > basline × 2（持续 10 分钟）
- 业务关键指标降级：日活学习用户数 < 切流前 1 天的 70%（小时级对比）
- 用户投诉显著增长（运营反馈，非自动告警）

**Rollback 操作：** 见 §5。

### D4 — 监控指标矩阵

| 类型 | 指标 | 告警阈值 |
|------|------|---------|
| Auth | 401 总数（/me/* 路由）| 当前 baseline × 10 持续 5 min |
| Auth | /auth/login 失败率 | > 30% 持续 5 min（可能 token 验证 bug） |
| Auth | /auth/guest 调用数 | 当前 baseline × 5（老客户端被强制重新拿 guest token） |
| Backend | /me/* 5xx 率 | > 1% 持续 5 min |
| Backend | Response time P95 | > baseline × 2 持续 10 min |
| Mobile | 401 弹窗触发数 | 上升超过 50%（埋点）|
| Business | 日活学习用户数 | < 切流前 1 天 70% |

监控来源（按现有运维栈选其一）：
- application log 聚合（ELK / Loki）
- 后端 NestJS exception filter 输出
- 移动端崩溃 / 401 埋点（如有）
- PG slow query log

### D5 — 切流时间窗口

**推荐：周二/周三 上午 10:00 北京时间**（工作日 + 非高峰）：
- 周一上午刚周末后状态高，bug 容易出
- 周末 + 周五下午切流问题难追责（运营值班少）
- 上午有完整工作日时间处理 incident

**避免：**
- 月底 / 季度末（业务关键时段）
- 国家法定假日前 1 天
- 晚上 / 周末

### D6 — 老移动端客户端处理

**场景：** 用户没升级 App，老客户端不带 Authorization → 401。

**选项：**
- (a) 不处理，让老客户端体感 401，UI 引导重启 App / 重登
- (b) 后端 `min_app_version` 拦截：太老的客户端返特定错误码，UI 强制升级
- (c) 给老客户端一个过渡期（保留 `AUTH_ENFORCE=lenient` 中间状态）

**推荐：(a) 不处理**。
- Phase B 已给所有 ApiClient 装上 AuthHttpClient（commit 5d83936），新版客户端会带 token
- Phase F 之前的老版本 mobile（pre-Phase B 9d992c8）确实会 401，但这是少数 dev 测试设备
- 真实生产用户大概率都安装新版（如果还没发布过老版本，那 (a) 零代价）

**前置确认：** 这条假设当前没有「已发布的、不带 Authorization 的老 App」流通在外。如果有，必须改 (b)。

---

## 3. Readiness checklist（E1.1，gate 验证）

切流前**每条必须 ✅**。任何 ❌ 停下问用户，回前面 phase 补。

### 3.1 Phase G 产出已就位

- [ ] `docs/design/audits/prd-§9-acceptance-coverage.md` 7 节全 ✅
- [ ] `docs/design/BR-USER-001_v0.1.0_full.md` 4 条 BR 落地
- [ ] plan v2 末尾「实施进度」表所有 phase 有 commit hash

### 3.2 后端能力层就绪

- [ ] `apps/api/src/main.ts:assertProductionAuthEnforce()` 函数存在并在 bootstrap 调用
- [ ] `apps/api/src/auth/auth.guard.ts` AuthGuard 完整 + `ensureUserLoaded` 钩入（β.5b 落地）
- [ ] `ApiClient.setDefaultHttpClient` 链路在 mobile 全部 18+ 调用点生效（Phase B hot-fix）
- [ ] dev-store `loadingByUser` map 防并发重复 load（β.5b）
- [ ] `pg-persistence.ts` `loadBackupForUser` / `saveBackupForUser` 旁路 dev-store（Phase D PR-D-β）
- [ ] DevStoreSnapshot 含 `ownedItemsByUser` / `equippedOutfitByUser` / `equippedRoomByUser` / `walletByUser`（β.5c）
- [ ] audit §6 全 18 个 owner-check 路径 e2e 覆盖

### 3.3 e2e baseline（严格模式预热）

执行：
```
cd apps/api && AUTH_ENFORCE=true npm run test:e2e:pg
```

- [ ] 全套 e2e pass（数字 ≥ A-D 累计完成的 baseline，待 G.1 实测填入）
- [ ] 0 个用例因为 permissive fallback 被掩盖错误

### 3.4 移动端 baseline

```
cd apps/mobile && flutter test
```

- [ ] 全套 mobile test pass
- [ ] flutter analyze 0 errors

### 3.5 staging environment 准备

- [ ] staging 数据库已 apply migration 008/009/010
- [ ] staging `JWT_SECRET` 已设（≥ 16 chars）
- [ ] staging `DATABASE_URL` 指向独立 staging DB（不是 prod / dev）
- [ ] 监控接入 staging：D4 指标已配告警

---

## 4. Staging cutover（E1.2 + E1.3）

### 4.1 实操步骤

1. **修 .env**：
   ```bash
   # apps/api/.env (staging)
   AUTH_ENFORCE=true   # was: false
   # 其他不动
   ```

2. **重启 staging API server**：
   ```bash
   # 按 staging 的部署方式触发重启
   # 如果用 docker compose:
   docker compose restart api
   ```

3. **启动期验证**：
   - 进程能正常起，没被 `assertProductionAuthEnforce` 抛出（如果 NODE_ENV=production 必须 AUTH_ENFORCE=true，staging 通常 NODE_ENV != production 所以不触发）
   - 日志看到 `JWT_SECRET` ok，无 `'JWT_SECRET is missing'` 报错

4. **冒烟测试（按这个顺序，每步必须过）**：
   ```bash
   # a) 无 token /me/* → 401
   curl -i $STAGING/api/v1/me/today
   # 期望: 401 + error_code: UNAUTHENTICATED

   # b) /auth/guest 拿 token
   TOKEN=$(curl -s -X POST $STAGING/api/v1/auth/guest \
     -H 'Content-Type: application/json' \
     -d '{"device_id":"e1-smoke-test-001"}' | jq -r .token)
   echo $TOKEN  # 应当是 valid JWT

   # c) 用 token /me/today
   curl -i $STAGING/api/v1/me/today -H "Authorization: Bearer $TOKEN"
   # 期望: 200

   # d) 伪造 token → 401
   curl -i $STAGING/api/v1/me/today -H 'Authorization: Bearer fake.token.here'
   # 期望: 401
   ```

5. **跑严格模式全套 e2e**：
   ```bash
   cd apps/api && AUTH_ENFORCE=true npm run test:e2e:pg 2>&1 | tail -10
   ```
   期望：全 pass。**任何失败 → 停止 staging soak，回前面 phase 修 bug，不要在 E1 PR 改业务代码**。

6. **commit `.env` 改动**：
   ```
   chore(req-23): Phase E1 — staging cutover AUTH_ENFORCE=true

   - apps/api/.env: AUTH_ENFORCE=false → true (staging only)
   - apps/api/.env.example: 加注释 "production must be true; staging
     recommended to be true to catch regressions early"
   - Staging smoke test passed: 401 / token / login round-trip / e2e
   - Soak window opened: 2026-05-11 10:00 CST, planned soak 24h
   ```

### 4.2 Soak 期间（E1.3，24h elapsed）

**每 4h 检查一次** D4 监控指标：

- 401 rate
- /me/* 5xx rate
- response time P95
- /auth/login 失败率
- 业务关键：DAU / 日活学习用户数

**如果命中 D3 任一 rollback 触发条件 → 立即 rollback**（按 §5）。

**Soak 通过条件：** 24h 内所有指标在 baseline ± 容忍范围内，无 incident，无关键用户投诉。

---

## 5. Production cutover playbook（E1.4，仅文档，不实操）

⚠️ 本节是给**用户手动操作**的 playbook，model 不直接动 production。

### 5.1 Pre-cutover checklist（切流前 1 天）

- [ ] staging soak 已通过 24h（§4.2 验收）
- [ ] production DB 已 apply migration 008/009/010
- [ ] production `JWT_SECRET` 已设（≥ 32 chars 随机，**不要复用 staging 的**）
- [ ] production 监控 + 告警已接入（D4 指标）
- [ ] On-call 工程师确认在切流时间窗口可用
- [ ] Rollback runbook 已演练过（§5.4）
- [ ] 用户通知（如有 maintenance 通知机制）

### 5.2 Cutover 操作（切流当天）

1. **T-0**：修 production `.env`：
   ```bash
   AUTH_ENFORCE=true
   ```

2. **T+0**：触发 production API rolling restart（按现有部署方式）。

3. **T+1min**：启动期验证：
   - 所有 instances 启动成功（无 `assertProductionAuthEnforce` 抛错）
   - 健康检查 endpoint `/api/v1/health` 通过

4. **T+5min**：冒烟测试（用预备的 production test account / 真实用户）：
   - 老 token（切流前 30 分钟内拿的）能正常请求 → 200
   - 新 /auth/guest 拿 token 流程正常 → 200

5. **T+15min**：观察 D4 指标。任何超阈值 → §5.4 rollback。

6. **T+1h**：第一次正式 checkpoint。指标正常 → 继续观察。

7. **T+24h**：宣告切流成功。

### 5.3 Cutover 期间用户体验

- 持有有效 token 的客户端：**无感**（请求继续 200）
- 老版本客户端（不带 Authorization）：**所有 /me/* 立即 401** → 客户端 UI 走 401 → tokenExpired 流程，弹"登录已过期"
- 已登录但 token 过期的用户：本来就会 401，行为不变
- 新装客户端：走 AuthBootstrap → /auth/guest → 正常

### 5.4 Rollback 程序

任何 D3 触发条件命中：

1. **T-0**：改 production `.env`：
   ```bash
   AUTH_ENFORCE=false   # 回退
   ```

2. **T+0**：触发 rolling restart。

3. **T+3min**：全 instances 重启完成 → permissive 模式恢复 → 401 风暴停止。

4. **T+15min**：D4 指标回到 baseline → 确认 rollback 成功。

5. **Post-mortem**：保留 incident log + metrics 快照，分析根因，回前面 phase 修 → 重做 Phase G readiness gate → 重新调度切流时间窗口。

**Rollback 不可耻，是预案。** 用户教育：切流首次失败是常见的，关键是快速 detect + revert。

---

## 6. 监控 + 告警（E1.6）

按 D4 的 7 个指标配置。具体接入方式按现有运维栈：

- **ELK / Loki / similar**: 日志聚合 + alert rules
- **Prometheus / Grafana**: 时序指标 dashboard
- **NestJS exception filter**: 401 / 5xx 计数器
- **Mobile crashlytics**: 客户端 401 / 崩溃埋点

切流前 1 天**所有告警必须已就绪并通过演练**。

---

## 7. 风险矩阵

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 老客户端 401 风暴 | 中 | 影响老用户体验 | D6: 假设无老客户端流通；如有需 (b) min_app_version 拦截 |
| Staging 覆盖不到的真实流量场景 | 中 | 切流后才发现 bug | 24h soak + rollback procedure 完备 |
| /auth/guest 突发流量（老客户端被强制重新拿 token）| 高 | /auth/guest endpoint 限流 | 切流前确认 endpoint 无 rate limit + DB 写入能撑 |
| JWT_SECRET 配置错（staging 复用到 prod 等）| 低 | 凭据泄漏 | §5.1 checklist 强制 prod 独立 secret |
| Rollback 时数据脏 | 低 | 部分请求落到错 user | rollback 后人工审计 1 小时窗口的写入 |
| β.5b lazy-load 在生产真实并发下性能不达预期 | 低 | response time 退化 | D4 监控 + rollback |
| Phase G 漏列了某个 PRD §9 验收项 | 低 | 切流后才暴露 | Phase G 严格 ✅ gate |
| 监控告警未及时触发 | 中 | 错过 rollback 窗口 | 切流前演练 D4 告警链路 |

---

## 8. Sign-off

Phase E1 完成后宣告 **需求 23 完整闭环达成**：

- ✅ A: 后端 auth 能力 + dev-store partition
- ✅ B: 移动端身份层 + ApiClient wiring
- ✅ C: 移动端本地 partition + drift v13 + pending-local-guest migration
- ✅ D: backup/restore user-scoped + PG 持久化
- ✅ β.5b/c: 后端 lazy-load + snapshot 扩字段
- ✅ Audit §6 全 18 e2e
- ✅ G: PRD §9 对照 + BR-USER-001 + plan 终版
- ✅ **E1: production AUTH_ENFORCE=true 切流 + 24h soak 通过**

需求 23 PRD 全部 9 节验收 ✅。

---

## 9. 估时

| 阶段 | Claude active | Elapsed |
|------|--------------|---------|
| E1.1 readiness 验证 | 0.5h | 0.5h |
| E1.2 staging cutover 实操 | 2h | 2h |
| E1.3 staging soak | 0.5h（每 4h 检查 ×6）| 24h |
| E1.4 production playbook 文档 | 1h | 1h |
| E1.5 rollback procedure 文档 | 0.5h | 0.5h |
| E1.6 监控告警文档 | 0.5h | 0.5h |
| **E1 active 总工时** | **~5h** | |
| **E1 elapsed 总时间** | | **~3 天**（含 staging soak） |

production 切流是用户自己操作，按 §5 playbook，elapsed ~24h（含 prod soak）。

---

## 10. 下一步

请用户确认：

1. **D1-D6 六个决策点**（推荐方案是否 OK）
   - D1 staging soak 24h
   - D2 一次性切流
   - D3 rollback 阈值
   - D4 监控指标矩阵
   - D5 切流时间窗口（周二/三上午 10:00 北京时间）
   - D6 老客户端不处理（假设无老版本流通）

2. 是否同意先做 **E1.1 readiness 验证** 作为 Phase E1 启动锚点（验证 Phase G 产出 + e2e baseline）

3. 是否同意 staging soak 24h 起步（如要调整给出新时长）

4. **D6 关键 prerequisite**：当前是否有"已发布的、不带 Authorization 的老 App"在外流通？如果有，D6 必须改 (b)，引入 `min_app_version` 拦截机制

确认后按 E1.1 → E1.2 → E1.3 → E1.4-6 顺序实施。production cutover 由用户手动按 §5 playbook 执行。
