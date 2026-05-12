# `apps/api/scripts/`

Operator + maintenance scripts that run outside the NestJS app process. Each
file documents its own contract in the top JSDoc — this README is the index.

| Script | Purpose | npm shortcut |
|--------|---------|--------------|
| `db/import-json.ts` | Bulk-import JSON content into PG (词条 / 例句) | `db:import` |
| `db/backup.ts` | Snapshot the `meow_dev` schema (used by ops; not the per-user backup feature) | `db:backup` |
| `db/restore.ts` | Restore from `db:backup` output | `db:restore` |
| `ingest-audio-assets.ts` | Ingest mp3 / wav files into `audio_assets` rows | (manual) |
| `cos-sync-helper.ts` | Tencent COS push helper used by other scripts | (manual) |
| `sync-audio-mp3-to-cos.ts` | Push existing `audio_assets` mp3 files to COS | (manual) |
| `sync-pronunciation-to-cos.ts` | Push pronunciation wav files to COS | (manual) |
| `upload-examples-mp3-to-cos.ts` | One-off example-sentence COS upload | (manual) |
| `upload-words-mp3-to-cos.ts` | One-off word-audio COS upload | (manual) |
| `convert-word-manifest.ts` | Convert Kokoro jsonl → `audio_assets` schema | (manual) |
| `repipe-audio-urls.ts` | Re-ingest existing `audio_assets.url` rows to a new origin | (manual) |
| `export-cet4-json.ts` / `export-wordbook-json.ts` | Export PG content to versioned JSON snapshots | (manual) |
| `import-cet4.ts` | Import CET-4 wordbook from JSON snapshot | (manual) |
| **`load-test-auth-guest.ts`** | **/auth/guest burst load test (Phase E1 prerequisite)** | **`load:auth-guest`** |

---

## `load-test-auth-guest.ts` — Phase E1 cutover baseline

**Plan reference:** [plan-023-E1-auth-enforce-cutover-v2.md](../../../docs/design/plan-023-E1-auth-enforce-cutover-v2.md) §3.4.

### Why we have this

AUTH_ENFORCE=true cutover (Phase E1) will trigger a burst of `/auth/guest`
calls because every app cold start without a valid token issues a new guest
session. Plan v1 §7 listed this as a risk but said "we assume it holds";
plan v2 makes the assumption explicit and verifiable.

The script measures the endpoint at the planned worst case (1000 RPS for
60 s) before the cutover ever runs. If the baseline doesn't hold, plan §3.4
specifies a fallback: rate-limit middleware (same-IP, 100 req/min). The
rate limit is **not** in the project yet — it's gated on the load test
result.

### Usage

```bash
# Production-shape soak (matches plan §3.4 acceptance):
BASE_URL=https://api.example.com \
TARGET_RPS=1000 \
DURATION_SECONDS=60 \
CONCURRENCY=100 \
  npm run load:auth-guest

# Local dev smoke (verify the script itself works at all):
TARGET_RPS=10 DURATION_SECONDS=5 CONCURRENCY=4 \
  npm run load:auth-guest

# Default (no env vars) is the production-shape config.
```

### Baseline (plan §3.4 acceptance)

The script declares pass/fail at end-of-run against:

| Metric        | Threshold        |
|---------------|------------------|
| p95 latency   | **< 500 ms**     |
| error rate    | **< 1 %**        |
| achieved RPS  | **≥ 90 % of `TARGET_RPS`** |
| `users` table | no deadlock / serialization conflict in PG logs during the run |
| PG plan       | `idx_users_device_id` used by `findGuestByDevice` query (`EXPLAIN ANALYZE` spot-check on a few `device_id`s) |

The first three are checked automatically (exit code 0 = pass, 1 = baseline
broken). The last two require ops-side observation:

```bash
# PG deadlock / serialization conflict check (run during + immediately
# after the load test):
psql "$DATABASE_URL" -c "
  SELECT relname, deadlocks
    FROM pg_stat_user_tables
   WHERE relname = 'users';
"

# Index usage spot-check (run before flipping AUTH_ENFORCE in production):
psql "$DATABASE_URL" -c "
  EXPLAIN ANALYZE
    SELECT id, email, nickname, account_type, device_id
      FROM users
     WHERE device_id = 'load-w0-<paste a real id from the load run>'
       AND account_type = 'guest'
     ORDER BY created_at ASC
     LIMIT 1;
"
# Expect: 'Index Scan using idx_users_device_id'.
```

### Where to run

- **Local dev**: 10 RPS smoke against `start:dev` to verify the script
  runs (script author did this once before commit).
- **Staging**: full 1000 RPS / 60 s against the staging API. This is part
  of the E1 readiness gate (plan §4.1).
- **Production-shape DB**: plan §6.1 requires the load test to run against
  a DB whose size / row-count matches production. If staging DB is
  significantly smaller than prod, use `pg_dump` from prod into a pre-prod
  PG instance for this run.
- **Never** from a developer laptop targeting production directly.

### What this script is NOT

- Not a JWT-verification microbenchmark — the issued token is unused; we're
  measuring `users` insert / lookup throughput end-to-end.
- Not a rate-limit test — there's no middleware to test yet.
- Not a replacement for full APM during the soak. Use it as a one-shot gate
  before flipping AUTH_ENFORCE.

### If the baseline fails

Plan §3.4 fallback options, in order of preference:

1. **Rate-limit middleware**: same-IP 100 req/min. Cheap to add, but biases
   against legitimate office-shared-NAT traffic.
2. **PG vertical scale**: more compute / memory for the `users` table writes.
3. **Decouple guest creation**: queue + async insert so the API responds
   immediately with a pre-generated id. Higher complexity, only do if
   (1) and (2) don't suffice.

Don't flip AUTH_ENFORCE=true until one of these is in place.
