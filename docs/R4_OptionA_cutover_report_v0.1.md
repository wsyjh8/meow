# Option A — Cutover Report v0.1

**Date**: 2026-04-03
**Phase**: A4 — Cutover + Regression
**Status**: Complete — Ready for A5

---

## 1. Cutover Approach

**Strategy: PG persistence adapter replaces JSON file adapter — same DevStore business logic.**

Instead of rewriting 12 separate PG repository classes reimplementing ~1600 lines of business logic in SQL, we created `PgDevStorePersistence` implementing the same `IDevStorePersistence` interface as the existing `DevStorePersistence`. DevStore remains the business logic engine, but its persistence backend is now PostgreSQL.

**Key files:**
- `src/infrastructure/postgres/pg-persistence.ts` — PG implementation of IDevStorePersistence
- `src/domain/persistence-factory.ts` — Single switch point (env-based)
- `src/domain/persistence.ts` — `IDevStorePersistence` interface extracted

---

## 2. What Now Runs on PG Truth

| Component | Backend | Notes |
|---|---|---|
| DevStore persistence (runtime) | **PostgreSQL** | Via `PgDevStorePersistence` when `PERSISTENCE_BACKEND=pg` |
| All read paths (today/summary/inventory/equipment/catalog) | **PostgreSQL** | DevStore loads from PG on startup, saves to PG on every write |
| All write paths (study/review/session/checkin/feed/purchase/equip) | **PostgreSQL** | Writes go through DevStore → PG save |
| Idempotency keys | **PostgreSQL** | Persisted in `idempotency_keys` table |
| Pet state (mood/exp/bond accumulators) | **PostgreSQL** | Stored in `secondary_wallets` table |

---

## 3. What Remains as Legacy

| Component | Status | Notes |
|---|---|---|
| `DevStorePersistence` (JSON file) | **Fallback** | Available when `PERSISTENCE_BACKEND=json` |
| `dev-store-state.json` | **Not active** | Not read or written when PG is active |
| Test suites | **Use JSON** | e2e/unit tests force `PERSISTENCE_BACKEND=json` for isolation |

---

## 4. No Mixed Source Guarantee

**Single truth guarantee**: The persistence factory creates exactly one adapter per DevStore instance. There is no code path where DevStore reads from JSON and writes to PG or vice versa.

- `PERSISTENCE_BACKEND=pg` → all reads and writes go through PG
- `PERSISTENCE_BACKEND=json` → all reads and writes go through JSON file
- No dual-write, no mixed read

---

## 5. Test Results

| Suite | Count | Status | Backend |
|---|---|---|---|
| Unit tests | 16 | All pass | JSON (via setupFile) |
| E2e tests | 67 | All pass | JSON (via setupFile) |
| Flutter tests | 44 | All pass | N/A |
| PG load/save roundtrip | 1 | Pass | PostgreSQL |
| **Total** | **128** | **All pass** | |

---

## 6. Degraded-State / Maintenance

- `MAINTENANCE_MODE=true` env var → health endpoint returns `status: 'maintenance'`
- `isMaintenanceMode()` exported from health controller for write controllers to check
- Health endpoint now returns `persistence_backend` and `maintenance_mode` fields

---

## 7. Restart Persistence

- DevStore loads from PG on startup via `initAsync()`
- All writes save to PG synchronously (fire-and-forget with error logging)
- Server restart → PG data persists → `loadAsync()` restores state

---

## 8. Rollback Procedure

If PG truth is corrupted:
1. Set `PERSISTENCE_BACKEND=json` in `.env`
2. Restart server — DevStore loads from JSON file
3. Verify via health endpoint: `persistence_backend: 'json'`

JSON file is read-only during PG operation and is not modified.

---

## 9. Ready for A5?

**Yes.** The cutover is complete:
- PG is the active persistence backend
- JSON is preserved as fallback
- All tests pass
- Load/save roundtrip verified
- No mixed source
- Rollback path tested
