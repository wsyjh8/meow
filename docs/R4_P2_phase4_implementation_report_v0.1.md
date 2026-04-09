# P2 Phase 4 Implementation Report — Secondary State Persistence Hardening

**Date**: 2026-04-03
**Phase**: P2 Phase 4
**Status**: Complete

---

## 1. Scope

This round makes all secondary mechanism state survive server restarts:

> Write to memory + save to disk -> Restart -> Load from disk -> Endpoints behave identically

This is **NOT** a production database migration. This is a minimal MVP file-backed persistence layer that eliminates the "restart = lose everything" risk.

---

## 2. Persistence Approach

**File-backed JSON snapshot store.**

- `DevStorePersistence` class in `apps/api/src/domain/persistence.ts`
- Reads/writes a single JSON file containing all mutable DevStore state
- Atomic write: writes to `.tmp` file first, then renames to target path
- Default path: `apps/api/data/dev-store-state.json`
- Configurable via `DEV_STORE_PERSIST_DIR` and `DEV_STORE_PERSIST_FILENAME` env vars
- Data directory added to `.gitignore`

Why this approach:
- Zero new dependencies
- No database setup required
- Easy to inspect/debug (human-readable JSON)
- Adequate for single-user MVP
- Easy to replace later with real DB

---

## 3. Persisted State

All mutable DevStore fields are serialized:

### Main mechanism state
- `studyAttempts`, `reviewGroups`, `reviewAttempts`
- `sourceEvents`, `rewardLedgerItems`, `settlements`
- `sessions`, `checkIns`, `streakRecord`, `learningDays`
- `todayStates`

### P2 secondary mechanism state
- `feedRecords`, `feedMoodAccumulated`, `feedExpAccumulated`, `feedBondAccumulated`
- `ownedItems`, `coinsSpent`
- `equippedOutfit`, `equippedRoom`

### Idempotency keys
- All `idempotencyKeys` entries

This means after restart:
- Coins balance is correct (earned - spent all persisted)
- Owned items are present
- Equipped state is intact
- Feed history and pet state (mood/exp/bond/level) are preserved
- Idempotency keys prevent duplicate write ops

---

## 4. Save/Load/Reset Mechanism

### Load (startup)
- `DevStore` constructor calls `loadFromDisk()`
- If file exists, `hydrate()` restores all state from snapshot
- If file doesn't exist, store starts with defaults (empty state)

### Save (on write)
- Every state-mutating method calls `saveToDisk()` after mutation
- Save points: `submitStudyAttempt`, `submitReviewAttempt`, `createSettlement`, `startSession`, `finishSession`, `checkIn`, `feedCat`, `purchaseItem`, `equipItem`, `unequipItem`, `setIdempotencyKey`

### Reset (testing)
- `reset()` clears in-memory state AND deletes the persistence file
- Ensures test isolation — each test starts clean

---

## 5. Assumptions (temporary, not frozen)

1. `Assumption (temporary, not frozen): file-backed JSON persistence is a minimal MVP approach. Production requires a real database.`
2. `Assumption (temporary, not frozen): single-user, single-process. No concurrent write handling.`
3. `Assumption (temporary, not frozen): all state is saved on every write. No batching or debouncing.`
4. `Assumption (temporary, not frozen): idempotency keys are persisted indefinitely within the file. No TTL or cleanup mechanism.`

## 6. Blockers

- `Blocked if touched: production database migration plan`
- `Blocked if touched: multi-user concurrent access`
- `Blocked if touched: cloud sync / multi-device conflict resolution`
- `Blocked if touched: idempotency key TTL / cleanup system`

---

## 7. Ready for Phase 5?

**Yes.** The MVP persistence layer is in place. State survives restarts. All existing functionality works unchanged.

Phase 5 candidates:
- Visual polish (real art for equipped items)
- Interaction action (still placeholder)
- Production database (SQLite / PostgreSQL)
- Content expansion (more catalog items)
- UX refinement
