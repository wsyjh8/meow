# Production Cutover Playbook — `AUTH_ENFORCE=true` (需求 23 Phase E1.4)

**Plan:** [plan-023-E1-auth-enforce-cutover-v2.md](../plan-023-E1-auth-enforce-cutover-v2.md)
**Related:** [BR-USER-001](../BR-USER-001_v0.1.0_full.md) §C, [audits/prd-§9-acceptance-coverage.md](../audits/prd-§9-acceptance-coverage.md)
**Audience:** on-call operator running the production AUTH_ENFORCE=true cutover
**Estimated duration:** ~3 hours active + 24 h soak elapsed

> ⚠️ This playbook is **prepared by Claude**. The production execution is
> done by a human operator. Anywhere a step says "run", read it as
> "operator runs"; Claude does not have hands on production env vars,
> DB credentials, or deploy pipelines.

---

## 0. Scope of this playbook

Flip `AUTH_ENFORCE=true` in **production**. Staging cutover is a separate
exercise (plan v2 §5) and must complete before this playbook runs.

| Stage | Owner | Where |
|-------|-------|-------|
| E1-Phase A (PR-E0.1–E0.4 merge) | Claude (done) | `feature/user-auth` |
| E1-Phase B (plan + docs) | Claude (done) | `docs/design/` |
| E1-Phase C (staging cutover + 24h soak) | Operator | staging env |
| **E1-Phase D (production cutover + 24h soak)** | **Operator (this playbook)** | **production env** |

Production cutover requires E1-Phase C green. **Do not start this
playbook if staging soak failed or hasn't run for 24 h.**

---

## 1. Pre-cutover checklist (plan v2 §6.1)

Complete each line before scheduling the cutover slot. Tick everything;
any one un-ticked item is a no-go.

### 1.1 Code + tests

- [ ] PR-E0.1 / E0.2 / E0.3 / E0.4 all merged to `main` (or the deploy
  branch the production pipeline tracks).
- [ ] CI green on the head commit: `apps/api && npm run build` 0 errors,
  `npm run test` ≥ 21 / 21 pass, `npm run test:e2e:pg --runInBand`
  ≥ 102 / 102 pass.
- [ ] Mobile `flutter test` ≥ 1244 / 1244 pass on the head commit.

### 1.2 Database

- [ ] Production DB has migration 010 applied (plan v2 D9):
  ```bash
  cd apps/api && npm run db:migrate:status   # connected to PROD DB
  # expect: 010_backup_snapshots in "Applied"
  ```
- [ ] If migration 010 is NOT applied, run `npm run db:migrate` against
  prod **the day before** cutover, not during the cutover window.
- [ ] `EXPLAIN ANALYZE` on the guest lookup hits the device_id index:
  ```bash
  psql "$PROD_DATABASE_URL" -c "
    EXPLAIN ANALYZE
      SELECT id, account_type FROM users
       WHERE device_id = 'any-real-id' AND account_type = 'guest'
       ORDER BY created_at ASC LIMIT 1;
  "
  # expect: 'Index Scan using idx_users_device_id' (NOT 'Seq Scan')
  ```

### 1.3 Secrets

- [ ] Production `JWT_SECRET` is set in the prod secret store
  (k8s Secret / docker-compose `env_file` / pm2 ecosystem / IaC vault).
  Generate fresh per plan v2 D8:
  ```bash
  node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
  # → 96 hex chars; paste into the prod secret store, NOT into git.
  ```
- [ ] Production `JWT_SECRET` is **not** the same string as staging.
- [ ] Production `JWT_SECRET` is **not** committed to git anywhere
  (`grep -r "JWT_SECRET" $(git rev-parse --show-toplevel)` should return
  only references in `.env.example` / docs).
- [ ] Production `DATABASE_URL` is the production DB, not staging.

### 1.4 D6 — no old clients in the wild (plan v2 §2 D6)

Pick **at least one** verification path; check the box and keep evidence.

- [ ] **App store version listing**: every published build on App Store
  Connect / 应用宝 / 华为 / etc. is dated ≥ Phase B commit `9d992c8`
  (2026-05-10). Screenshot the version list.
- [ ] **Analytics version distribution**: pull the last 7 days of DAU
  `app_version` breakdown; 0 % of users are on a pre-Phase-B build.
  Attach the query + result.
- [ ] **Zero-release proof**: project is unpublished (no app store
  release / only internal TestFlight) and every internal device has
  been re-installed on Phase B+.

If none of the three is provable: **stop**. Either ship a Phase B+ build
to every existing channel first, or add a rate-limit middleware that
quietly degrades old-client login attempts. Do not flip the flag and
hope.

### 1.5 Load test (plan v2 §3.4 + §6.1)

- [ ] `apps/api/scripts/load-test-auth-guest.ts` ran against a
  production-shape DB:
  ```bash
  BASE_URL=https://staging-or-prodshape.example.com \
  TARGET_RPS=1000 DURATION_SECONDS=60 CONCURRENCY=100 \
    npm run load:auth-guest
  ```
  - [ ] Verdict line read `✓ baseline met` (exit code 0).
  - [ ] If verdict broke baseline, plan §3.4 fallback in place
    (rate-limit middleware OR PG vertical scale OR async insert).
- [ ] During the load run, `pg_stat_user_tables.deadlocks` for `users`
  did NOT increase:
  ```bash
  psql "$DATABASE_URL" -c "
    SELECT deadlocks FROM pg_stat_user_tables WHERE relname='users';
  "
  ```

### 1.6 Monitoring

The seven metrics in plan v2 §5.4 must each have a working query / dashboard
**before** cutover, with a query screenshot or saved dashboard URL:

- [ ] /me/* 401 count: log aggregator query saved.
- [ ] /auth/login 401 rate: log aggregator query saved.
- [ ] /auth/guest RPS: log aggregator query saved.
- [ ] /me/* 5xx rate: APM dashboard or exception filter counter.
- [ ] Response time P95: APM dashboard.
- [ ] Mobile 401 modal-shown event: analytics dashboard.
- [ ] Business DAU: PG query saved.

Each query should be **already returning data** for the 7-day baseline
window. A query that returns nothing during baseline will also return
nothing during cutover — that's invisible failure mode.

### 1.7 Slot scheduling

- [ ] Cutover window scheduled for a low-traffic period (plan D5: Tue/Wed
  10:00 AM local time recommended).
- [ ] On-call operator + a backup operator on Slack / on the call for
  the first 4 h of the soak.
- [ ] Rollback authority pre-cleared: the operator can flip the flag
  back without escalation.

---

## 2. Cutover steps

> Wall-clock budget: **15 minutes for the flip + smoke test**.
> Followed by the 24-hour soak (passive, watching dashboards every 4 h).

### 2.1 Snapshot baseline metrics

Right before flipping, record current values of the 7 monitored metrics.
This becomes the "pre-cutover baseline" you compare against during soak.

```bash
# Example: write to /tmp/cutover-baseline-<date>.txt for the post-mortem.
date -u; \
  psql "$DATABASE_URL" -c "SELECT COUNT(DISTINCT user_id) FROM session_records WHERE created_at > now() - interval '24h';"; \
  # ... add log-aggregator queries here
```

### 2.2 Flip the environment variable

Pick the section that matches your deploy stack:

#### 2.2.a Docker compose

```yaml
# docker-compose.production.yml
services:
  api:
    environment:
      - AUTH_ENFORCE=true   # was: false
```

```bash
docker compose -f docker-compose.production.yml up -d --no-deps api
```

#### 2.2.b Kubernetes

```yaml
# k8s/production/deployment.yaml
spec:
  template:
    spec:
      containers:
        - name: api
          env:
            - name: AUTH_ENFORCE
              value: "true"
```

```bash
kubectl apply -f k8s/production/deployment.yaml
kubectl rollout status deployment/api -n production --timeout=5m
```

The deployment rolls one replica at a time; old replicas keep serving with
AUTH_ENFORCE=false until terminated. There is no hard cutover instant —
during a rolling restart some requests will still hit a permissive replica
for ~30 s. That's fine; the goal is "every replica enforces within 5 min".

#### 2.2.c Bare metal / pm2

```bash
# Edit ecosystem.config.js (or pm2 env file) on every API host:
#   env_production: { AUTH_ENFORCE: 'true' }
pm2 reload api --update-env
```

`--update-env` is required; `pm2 restart` alone keeps the old env.

### 2.3 Post-flip smoke (T+0 → T+10 min)

Run these against the production API in order. Stop and roll back on the
first unexpected response.

```bash
# 1. Missing token must 401 (was 200/permissive before flip)
curl -s -o /dev/null -w "no-token: %{http_code}\n" \
  https://api.example.com/api/v1/me/today
# expect: no-token: 401

# 2. Invalid token must 401
curl -s -o /dev/null -w "bad-token: %{http_code}\n" \
  https://api.example.com/api/v1/me/today \
  -H "Authorization: Bearer not-a-real-jwt"
# expect: bad-token: 401

# 3. Fresh guest signup still works
curl -s https://api.example.com/api/v1/auth/guest \
  -H "Content-Type: application/json" \
  -d '{"device_id":"cutover-smoke-1"}' | head -c 200; echo
# expect: { user: { id, ... }, token: "ey..." }

# 4. Token from #3 works against /me/today
TOKEN=$(curl -s https://api.example.com/api/v1/auth/guest \
  -H "Content-Type: application/json" \
  -d '{"device_id":"cutover-smoke-2"}' | python -c "import sys,json;print(json.load(sys.stdin)['token'])")
curl -s -o /dev/null -w "valid-token: %{http_code}\n" \
  https://api.example.com/api/v1/me/today \
  -H "Authorization: Bearer $TOKEN"
# expect: valid-token: 200

# 5. assertProductionAuthEnforce did NOT block startup (server is up)
curl -s -o /dev/null -w "health: %{http_code}\n" \
  https://api.example.com/api/v1/health
# expect: health: 200
```

If any line returns an unexpected status → §4 Rollback.

### 2.4 Mobile smoke (T+10 → T+15 min)

- [ ] Open the production build on a real device. App must reach the home
  screen (existing token still valid) **and** /me/today must populate
  with the user's data, not the default empty state.
- [ ] Force-logout via the app's Settings → "退出登录"; confirm the app
  drops to the guest landing screen and re-issues a guest token
  automatically.
- [ ] Trigger a backup via Settings; confirm "立即备份" returns success.
- [ ] Trigger a restore via Settings (if applicable); confirm restore
  banner appears and resolves.

If any of these fails → §4 Rollback.

---

## 3. Soak (T+15 min → T+24 h)

Check the 7 dashboards from §1.6 every **4 hours** for the first 24 h.
Pager any metric that crosses the threshold for **5 minutes continuous**:

| Metric | Source | Threshold |
|--------|--------|-----------|
| /me/* 401 count | log aggregator | baseline × 10, 5 min |
| /auth/login 401 rate | log aggregator | > 10–15 %, 5 min |
| /auth/guest RPS | log aggregator | baseline × 5 |
| /me/* 5xx rate | APM | > 1 %, 5 min |
| Response time P95 | APM | baseline × 2, 10 min |
| Mobile 401-modal-shown | analytics | > baseline + 50 % |
| Business DAU | PG query | < pre-cutover × 70 % |

**Baseline** = 7-day rolling average (plan §5.4 evaluation R2 漏 16);
take the snapshot from §2.1 as your immediate reference.

A spike on /auth/guest is expected in the first hour — every existing app
re-asks for a guest token when its old session is rejected. If the spike
falls back to baseline × 1.5 within the first 2 hours, that's normal.

### 3.1 Post-cutover 24 h soak checklist

At the 24-h mark, before declaring success:

- [ ] All 7 dashboards within threshold for the past 24 h.
- [ ] No incident pages (Sentry / PagerDuty / Slack alerts) tied to auth.
- [ ] DAU within 90 % of pre-cutover (some legit drop is fine; > 30 % drop
  needs a post-mortem).
- [ ] Customer support inbox: no spike in "I can't log in" / "my data is
  gone" tickets.
- [ ] PR-E0.2 invariant: PG query confirms zero rows written to
  business tables with `user_id = 'dev-user-001'` during the cutover
  window (run §6.2 SQL from plan, scoped to the cutover timestamp).

If everything passes → §5 Sign-off.

---

## 4. Rollback (≤ 5 min)

Rollback means flipping the env var back to `false` and restarting. It is
**always safe to roll back** — no schema change, no data migration. The
only risk is silent data pollution by clients that fell back to a permissive
identity during the window. Run §4.2 audit afterwards.

### 4.1 Flip back

| Deploy stack | Command |
|--------------|---------|
| Docker compose | `AUTH_ENFORCE=false` in `docker-compose.production.yml`, then `docker compose -f docker-compose.production.yml up -d --no-deps api` |
| Kubernetes | Patch deployment env back to `"false"`: `kubectl set env deployment/api -n production AUTH_ENFORCE=false`, then `kubectl rollout status deployment/api -n production --timeout=5m` |
| pm2 | Edit `ecosystem.config.js` env_production.AUTH_ENFORCE back to `'false'`, then `pm2 reload api --update-env` |

Verify with §2.3 step 1: a missing-token request should now return 200
(or whatever permissive's default is — typically falls back to
`DEV_FALLBACK_USER_ID`).

### 4.2 Data-pollution audit (plan v2 §6.2 SQL)

After rollback, identify any rows written during the cutover window that
landed under `dev-user-001` instead of a real user. Replace the two
timestamp placeholders with the **actual cutover and rollback wall-clock
times**:

```sql
WITH cutover_window AS (
  SELECT
    'YYYY-MM-DD HH:MM:SS+TZ'::timestamptz AS cutover_at,
    'YYYY-MM-DD HH:MM:SS+TZ'::timestamptz AS rollback_at
)
SELECT
  'study_attempts' AS table_name, user_id, COUNT(*) AS row_count
  FROM study_attempts, cutover_window
 WHERE created_at BETWEEN cutover_at AND rollback_at
 GROUP BY user_id

UNION ALL

SELECT 'review_attempts', user_id, COUNT(*)
  FROM review_attempts, cutover_window
 WHERE created_at BETWEEN cutover_at AND rollback_at
 GROUP BY user_id

UNION ALL

SELECT 'reward_ledger', user_id, COUNT(*)
  FROM reward_ledger, cutover_window
 WHERE created_at BETWEEN cutover_at AND rollback_at
 GROUP BY user_id

UNION ALL

SELECT 'settlements', user_id, COUNT(*)
  FROM settlements, cutover_window
 WHERE created_at BETWEEN cutover_at AND rollback_at
 GROUP BY user_id

UNION ALL

SELECT 'feed_events', user_id, COUNT(*)
  FROM feed_events, cutover_window
 WHERE created_at BETWEEN cutover_at AND rollback_at
 GROUP BY user_id

UNION ALL

SELECT 'inventory_items', user_id, COUNT(*)
  FROM inventory_items, cutover_window
 WHERE owned_at BETWEEN cutover_at AND rollback_at
 GROUP BY user_id

UNION ALL

SELECT 'session_records', user_id, COUNT(*)
  FROM session_records, cutover_window
 WHERE started_at BETWEEN cutover_at AND rollback_at
 GROUP BY user_id

UNION ALL

SELECT 'backup_snapshots', user_id, COUNT(*)
  FROM backup_snapshots, cutover_window
 WHERE uploaded_at BETWEEN cutover_at AND rollback_at
 GROUP BY user_id

ORDER BY 1, 3 DESC;
```

**Read this output as:**
- A spike in `user_id = 'dev-user-001'` rows means a client bypassed the
  token (e.g. a stale client config) and the server fell back to dev id.
  Possibly merge / delete those rows before the next cutover attempt.
- A real user_id with unexpectedly high `row_count` could also indicate
  duplicate writes from a client retry storm. Check 401-modal-shown
  analytics around the same window for correlation.

Document the SQL output, root-cause analysis, and any cleanup actions in a
post-mortem in `docs/design/playbooks/` before scheduling a retry.

---

## 5. Sign-off

Two-stage:

### 5.1 Operator sign-off (writes a one-line update)

```
[E1.4 cutover] AUTH_ENFORCE=true in production at YYYY-MM-DD HH:MM TZ.
24-h soak completed YYYY-MM-DD HH:MM TZ, all 7 metrics within threshold.
No incident pages. DAU at NN % of pre-cutover.
```

### 5.2 Need 23 完整闭环 confirmation

Adds the operator update to:
- `plan-023-用户系统与用户数据隔离-v2.md` §14 (实施进度 — add the cutover
  date)
- `plan-023-E1-auth-enforce-cutover-v2.md` §7.3 (Production operator
  sign-off)
- `audits/prd-§9-acceptance-coverage.md` §9 (mark Phase E1 done)

Once those three references are updated, 需求 23 完整闭环 is achieved
(plan v2 §7.3 final clause).

---

## 6. Appendix — quick-reference numbers

| What | Value |
|------|-------|
| JWT TTL | 30 days (plan D3) |
| JWT_SECRET min length | 16 chars (`auth.service.ts:43`); 96 hex recommended (D8) |
| Min DB migrations | 008 (users + auth), 009 (uniqueness), 010 (backup_snapshots) |
| /auth/guest baseline | 1000 RPS, 60s, p95 < 500ms, error rate < 1% |
| Soak duration | 24 h |
| Rollback time SLA | ≤ 5 min |
| DAU drop tolerance | < 30 % vs pre-cutover 24 h average |
| Pre-cutover monitoring lead | 7-day rolling average |

---

> 📌 **Maintainer note:** this playbook is prepared by Claude per plan
> §6.1–6.2. The production execution is owned by the on-call operator.
> If the playbook needs updating mid-cutover (e.g. a step doesn't match
> the deploy stack), edit the file in a follow-up PR — do not patch it
> live from the cutover terminal.
