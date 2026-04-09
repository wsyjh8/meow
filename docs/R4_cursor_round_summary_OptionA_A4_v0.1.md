# Cursor Round Summary — Option A, A4

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Implemented **Option A A4: PostgreSQL Cutover + Regression**.

- Extracted `IDevStorePersistence` interface from `DevStorePersistence`
- Created `PgDevStorePersistence` — full PG implementation of load/save/clear
- Created `persistence-factory.ts` — env-based single switch point (`PERSISTENCE_BACKEND`)
- Updated DevStore constructor to use factory (accepts interface injection for tests)
- Added `initAsync()` for PG async load on startup
- Added maintenance mode support (`MAINTENANCE_MODE` env, health endpoint)
- Added test env setup to force JSON backend for test isolation
- Fixed `review_group_items` FK issue (no `user_id` column — uses parent join delete)
- Verified PG load/save roundtrip works
- All 127 tests pass, PG smoke verified

---

## 2. What now runs on PG truth

When `PERSISTENCE_BACKEND=pg` (default):
- **ALL** DevStore state reads from PG on startup
- **ALL** DevStore state writes to PG on every mutation
- Today, secondary summary, inventory, equipment, feed, purchase, study, review, session, check-in, settlement, idempotency — ALL through PG
- Zero mixed source — single adapter per DevStore instance

---

## 3. What still remains in legacy compatibility

- `DevStorePersistence` (JSON file adapter) — available as fallback when `PERSISTENCE_BACKEND=json`
- `dev-store-state.json` — not read/written when PG is active
- E2e/unit tests use JSON backend via `test/jest-env-setup.ts`
- Import script (`scripts/db/import-json.ts`) — still available for JSON→PG migration
- `scripts/db/test-pg-load.ts` + `check-columns.ts` — dev verification scripts

---

## 4. What must be done next

**A5 — Cleanup Compatibility Layer:**
1. Remove `DevStorePersistence` JSON adapter (or mark as dev-only utility)
2. Remove `PERSISTENCE_BACKEND` env switch (PG becomes the only backend)
3. Remove `test/jest-env-setup.ts` JSON forcing (tests use test PG DB)
4. Clean up `data/dev-store-state.json`
5. Remove `scripts/db/check-columns.ts` and `test-pg-load.ts` dev scripts
6. Final smoke + regression

---

## 5. What not to touch

- Do NOT change DevStore business logic
- Do NOT change API response formats
- Do NOT remove PG persistence adapter
- Do NOT remove `db:migrate` / `db:seed` scripts
- Do NOT change the schema without a new migration

---

## 6. Files / modules to read first

1. `apps/api/src/infrastructure/postgres/pg-persistence.ts` — THE PG adapter (load/save/clear)
2. `apps/api/src/domain/persistence-factory.ts` — Single switch point
3. `apps/api/src/domain/persistence.ts` — `IDevStorePersistence` interface
4. `apps/api/src/domain/dev-store.ts` — Constructor now uses factory, `initAsync()` for PG
5. `apps/api/test/jest-env-setup.ts` — Forces JSON for tests
6. `apps/api/.env` — `PERSISTENCE_BACKEND=pg` is the active config
7. `apps/api/src/controllers/health.controller.ts` — Maintenance mode + persistence info

---

## 7. Current risks

1. **PG save is fire-and-forget**: `save()` calls `saveAsync()` but doesn't await. If PG write fails, in-memory state is correct but PG is stale. Error is logged but not propagated.
2. **Full snapshot save**: Every mutation saves the entire snapshot (delete all + re-insert). At dev scale this is fine. At production scale with many records, this needs optimization (incremental writes).
3. **Tests use JSON, not PG**: E2e tests validate business logic against JSON backend. PG backend is verified by the load/save roundtrip test and import validation, but not by the full e2e suite.

---

## 8. Recommended next prompt focus

> "Implement Option A A5: Cleanup Compatibility Layer. Remove JSON fallback as the default. Make tests run against PG test database. Clean up dev scripts. Final smoke and regression."
