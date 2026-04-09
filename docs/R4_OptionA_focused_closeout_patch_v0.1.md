# Option A — Focused Closeout Patch Report v0.1

**Date**: 2026-04-04
**Type**: Focused closeout patch (not a new phase)
**Source**: Cross-room review of Option A closeout

---

## 1. Review Source

Other rooms reviewed the Option A closeout and identified issues. Room 4 assessed and accepted 3 items as within Option A scope.

## 2. Accepted Review Items

| # | Issue | Why It's In Scope |
|---|---|---|
| Patch-01 | Maintenance/read_only/temporarily_unavailable not in write controllers | Strong assertion #3.2 requires degraded-state semantics on writes |
| Patch-02 | Fire-and-forget PG save allows "success returned but truth not persisted" | Strong assertion #3.1 requires PG truth to be confirmed before success |
| Patch-03 | Automated tests don't prove PG path works for key business chains | A4 cutover requires regression proof on PG truth |

## 3. What Was Fixed

### Patch-01: Maintenance Guard in Write Controllers
- Created `MaintenanceGuardMiddleware` as NestJS middleware
- Registered globally in `AppModule` — blocks ALL POST/PUT/PATCH/DELETE when `MAINTENANCE_MODE=true`
- Returns HTTP 503 with structured `MAINTENANCE_MODE_ACTIVE` error
- Includes `retryable: true`, `maintenance: true`, `read_only: true`, `temporarily_unavailable: true`
- GET/HEAD/OPTIONS pass through (reads allowed during maintenance)
- **3 tests**: maintenance blocks writes, allows reads, health shows status

### Patch-02: Confirmed Persistence Before Success Return
- Changed `saveToDisk()` from fire-and-forget to serialized save chain
- Added `saveToDiskAsync()` that awaits the chain and throws on failure
- Added `ensurePersisted()` to repositories adapter
- Updated all 10 write controller methods across 8 files to `await repositories.ensurePersisted()`
- If PG save fails, controller propagates error (NestJS returns 500)
- **Guarantee**: successful API response = PG truth confirmed

### Patch-03: PG Backend E2E Regression
- Created `test/pg-regression.e2e-spec.ts` with 10 tests running on real PG
- Separate jest config `test/jest-pg-e2e.json` (doesn't force JSON)
- `npm run test:e2e:pg` command
- Covers: today read, secondary summary read, purchase→inventory, equip→equipment, feed→summary, study+settlement, check-in+streak, maintenance mode (3 tests)

## 4. Code Changes

### New files
- `apps/api/src/middleware/maintenance.guard.ts`
- `apps/api/src/middleware/persist-guard.ts`
- `apps/api/test/pg-regression.e2e-spec.ts`
- `apps/api/test/jest-pg-e2e.json`

### Modified files
- `apps/api/src/app.module.ts` — registered MaintenanceGuardMiddleware
- `apps/api/src/controllers/health.controller.ts` — imports from middleware
- `apps/api/src/domain/persistence.ts` — added `saveAsync?` to interface
- `apps/api/src/domain/dev-store.ts` — serialized save chain, `saveToDiskAsync()`
- `apps/api/src/domain/dev-store-adapter.ts` — added `ensurePersisted()`
- `apps/api/src/infrastructure/postgres/pg-persistence.ts` — public `saveAsync`, SAVEPOINT-based FK-safe inserts
- `apps/api/src/controllers/feed.controller.ts` — async + ensurePersisted
- `apps/api/src/controllers/shop.controller.ts` — async + ensurePersisted
- `apps/api/src/controllers/equipment.controller.ts` — async + ensurePersisted (x2)
- `apps/api/src/controllers/study-attempts.controller.ts` — async + ensurePersisted
- `apps/api/src/controllers/review-attempts.controller.ts` — async + ensurePersisted
- `apps/api/src/controllers/sessions.controller.ts` — async + ensurePersisted (x2)
- `apps/api/src/controllers/check-ins.controller.ts` — async + ensurePersisted
- `apps/api/src/controllers/settlements.controller.ts` — async + ensurePersisted
- `apps/api/package.json` — added `test:e2e:pg` script
- `apps/api/test/jest-e2e.json` — narrowed testRegex to avoid matching PG tests

## 5. Test Results

| Suite | Count | Status |
|---|---|---|
| Unit tests | 16 | All pass |
| JSON e2e tests | 67 | All pass |
| PG e2e tests | 10 | All pass |
| Flutter tests | 44 | All pass |
| **Total** | **137** | **All pass** |

## 6. Close Judgment Change

**No change. Option A close recommendation remains YES.**

All 3 review items are now closed. The remaining technical debt (full snapshot save, single-user model) was already documented and is explicitly out of this patch scope.
