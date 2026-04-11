# Option A.1 Hardening Status v0.1

**Date**: 2026-04-04
**Current phase**: H3 — Fire-and-Forget PG Save Hardening (Final)
**Status**: All H1-H3 Complete — Option A.1 Ready for Close Judgment

---

## 1. Current Phase: H1

H1 (maintenance / degraded-state gating) is complete. All three system window states — `maintenance`, `read_only`, `temporarily_unavailable` — are now enforced on all write paths via unified middleware.

---

## 2. Implemented Range

### Degraded-state middleware
- `MaintenanceGuardMiddleware` enhanced to check 3 independent env vars
- `MAINTENANCE_MODE=true` → code `MAINTENANCE_MODE_ACTIVE`
- `READ_ONLY_MODE=true` → code `READ_ONLY_MODE_ACTIVE`
- `TEMPORARILY_UNAVAILABLE=true` → code `TEMPORARILY_UNAVAILABLE`
- All return HTTP 503 with structured envelope: `{ ok: false, error: { code, message, retryable: true, details: { maintenance, read_only, temporarily_unavailable } } }`
- GET/HEAD/OPTIONS always pass through

### Write paths gated (all POST endpoints)
- Study attempt submission
- Review attempt submission
- Session start / finish
- Check-in
- Settlement creation
- Feed
- Purchase
- Equip / Unequip

### Health endpoint updated
- Shows `status` reflecting active degraded state
- Shows `write_blocked` boolean
- Shows `degraded_state` object with all three flags

---

## 3. Not Yet Implemented

| Item | Phase | Notes |
|---|---|---|
| PG-path e2e regression | H2 | PG regression tests exist from focused patch; H2 may extend |
| Fire-and-forget PG save hardening | H3 | Serialized save chain exists from focused patch; H3 may refine |

---

## 4. Assumptions

1. `Assumption (temporary, not frozen): degraded state is env-based, not runtime-toggleable without restart.`
2. `Assumption (temporary, not frozen): all three states use the same HTTP 503 status code.`
3. `Assumption (temporary, not frozen): middleware applies to all routes globally, not per-controller.`

---

## 5. Blockers

None for H2 start.

---

## 6. Bug List

None found. All 22 H1 tests pass.

---

## 7. Test Results

| Suite | Count | Status |
|---|---|---|
| H1 degraded-state tests | 22 | All pass |
| Unit tests | 16 | All pass |
| JSON e2e tests | 67 | All pass |
| PG e2e tests | 10 | All pass |
| Flutter tests | 44 | All pass |
| **Total** | **159** | **All pass** |

---

## 8. Ready for H2?

**Yes.** Maintenance / degraded-state gating is enforced on all write paths. H2 can proceed with PG-path e2e regression hardening.

---

## 9. H2 — PG-Path E2E / Regression (Complete)

### Implemented
- Expanded PG regression from 10 → 20 tests
- New coverage: inventory read, equipment read, unequip, review group + attempt, session start/finish, learning round→settlement→today chain, idempotency (settlement + purchase), review group completion→settlement, companion response
- All tests run with `PERSISTENCE_BACKEND=pg` against real meow_dev database
- Test DB isolation: `devStore.reset()` clears PG user data before each test

### Test DB strategy
- Uses meow_dev database (same as dev, reset per test via clearAsync)
- `beforeEach` calls `devStore.reset()` + 500ms wait for PG clear
- Static seed data (words, catalog, user) preserved; user state cleared
- `npm run test:e2e:pg` runs the PG lane independently

### Test results
| Suite | Count | Status |
|---|---|---|
| PG regression | 20 | All pass |
| Unit | 16 | All pass |
| JSON e2e | 67 | All pass |
| H1 degraded-state | 22 | All pass |
| Flutter | 44 | All pass |
| **Total** | **169** | **All pass** |

### Still JSON-only (not blocking H3)
- The 67 JSON e2e tests cover full business logic breadth
- PG lane now covers the highest-priority chains
- Remaining JSON-only coverage is not a blocker — it validates business logic independent of backend

## 10. Ready for H3?

**Yes.** PG-path regression is in the main automation lane. 20 PG tests covering all core read/write chains pass.

---

## 11. H3 — Fire-and-Forget PG Save Hardening (Complete)

### What was already in place (from Focused Closeout Patch)
- Serialized save chain (`saveToDisk()` → `saveChain` promise)
- `saveToDiskAsync()` awaits chain and throws on failure
- `ensurePersisted()` in repositories adapter
- 10 write controller methods call `await repositories.ensurePersisted()`

### What H3 added
- `PersistenceFailureError` custom error class for structured failure wrapping
- `PersistenceFailureFilter` global exception filter — catches persistence errors and returns structured 500 with `PERSISTENCE_FAILURE` code
- `devStore.saveToDiskAsync()` now wraps errors in `PersistenceFailureError`
- 12 H3 tests: 6 normal success, 1 error structure, 4 ensurePersisted verification, 1 documentation

### How it works
1. Controller calls business logic (DevStore method)
2. DevStore method calls `saveToDisk()` which queues async PG save
3. Controller calls `await repositories.ensurePersisted()`
4. `ensurePersisted()` → `saveToDiskAsync()` → awaits save chain
5. If PG save failed → throws `PersistenceFailureError`
6. `PersistenceFailureFilter` catches it → returns `{ ok: false, error: { code: "PERSISTENCE_FAILURE", retryable: true } }`
7. If PG save succeeded → controller returns normal success response

### Failure response structure
```json
{
  "ok": false,
  "error": {
    "code": "PERSISTENCE_FAILURE",
    "message": "The operation completed in memory but failed to persist to database. The result should not be trusted.",
    "retryable": true,
    "details": {
      "persistence_failed": true,
      "original_error": "<PG error message>"
    }
  }
}
```

### Test results
| Suite | Count | Status |
|---|---|---|
| H3 save hardening | 12 | All pass |
| Unit | 16 | All pass |
| JSON e2e | 67 | All pass |
| PG regression | 20 | All pass |
| H1 degraded-state | 22 | All pass |
| Flutter | 44 | All pass |
| **Total** | **181** | **All pass** |

### Remaining technical debt
- Full snapshot save (delete-all + re-insert) — Medium — future optimization
- Single-user model — Low — future phase

## 12. Option A.1 Close Judgment

**All 3 hardening items complete:**
1. H1: Maintenance/degraded-state gating — 22 tests, all write paths covered
2. H2: PG-path regression — 20 tests, all core business chains on PG
3. H3: Save hardening — 12 tests, all write paths confirmed persist-before-success

**Recommendation: Option A.1 is ready for close.**
