# Option A — Rollback Rehearsal v0.1

**Date**: 2026-04-03
**Phase**: A3

---

## 1. Snapshot Used

- JSON source: `apps/api/data/dev-store-state.json` (4.4KB, last modified during P2 Phase 4+)
- PG target: `meow_dev` database on localhost:5432

---

## 2. When to Rollback

Rollback is triggered if:
1. Any balance parity check FAILS (coins, fish_treats)
2. Idempotency key count diverges (risk of duplicate writes)
3. Equipment or inventory state contradicts JSON truth
4. Import introduces structural corruption
5. A4 cutover reveals runtime behavior divergence

---

## 3. Rollback Procedure

### Full DB reset (return to clean seed state)
```bash
npm run db:reset
```
This runs: `migrate down` → `migrate up` → `seed`

Result: PG returns to seed-only state (static data, no user activity).

### JSON truth remains untouched
The import script is **read-only** on the JSON file. It never modifies `dev-store-state.json`. The DevStore continues to be the runtime truth source until A4 cutover.

---

## 4. Rehearsal Results

### Test 1: Full reset after import
1. Ran `npm run db:import:validate` — imported 8 rows, 17/18 checks passed
2. Ran `npm run db:reset`
3. Verified: `study_attempts` = 0, `words` = 30 (clean seed state)
4. **Result: PASS** — DB returned to clean state

### Test 2: Re-import after reset
1. After reset, ran `npm run db:import:validate` again
2. Import completed successfully (idempotent for already-present seed data)
3. Validation results identical to first run
4. **Result: PASS** — Import is repeatable

### Test 3: Existing tests unaffected
1. Ran `npm test` — 16/16 passed
2. Ran `npm run test:e2e` — 67/67 passed
3. Ran `flutter test` — 44/44 passed
4. **Result: PASS** — Import infrastructure does not affect runtime tests

---

## 5. Rollback Point Trustworthiness

| Aspect | Trustworthy? | Notes |
|---|---|---|
| PG can return to clean state | Yes | `db:reset` verified |
| JSON truth is never modified | Yes | Import is read-only on JSON |
| Import is repeatable | Yes | ON CONFLICT handling verified |
| Runtime tests unaffected | Yes | 127/127 pass after import |
| Existing API behavior unchanged | Yes | Controllers still use DevStore |

**Conclusion: Rollback point is trustworthy. Safe to proceed to A4.**
