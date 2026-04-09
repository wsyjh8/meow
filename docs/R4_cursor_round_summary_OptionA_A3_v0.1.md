# Cursor Round Summary — Option A, A3

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Implemented **Option A A3: JSON Import + Validation + Rollback Rehearsal**.

- Created `scripts/db/import-json.ts` — reads DevStore JSON snapshot, imports into PG tables in correct FK order (23 tables), outputs import report
- Built inline validation: 18 parity checks covering row counts, balances, pet state, equipment, streak, idempotency
- Ran import against live JSON snapshot: 8 rows imported, 17/18 checks pass
- 1 known non-blocking fail: study_attempt with test-artifact word_id (FK violation)
- Rollback rehearsal: `db:reset` cleanly returns to seed state, JSON untouched
- Added npm scripts: `db:import`, `db:import:validate`
- All 127 existing tests pass (zero breakage)

---

## 2. What was imported

From `apps/api/data/dev-store-state.json` (4.4KB):
- 1 daily_goal_progress row
- 1 learning_day_fact row
- 1 reward_source_event
- 2 reward_ledger items
- 1 settlement
- 1 idempotency_key
- 1 secondary_wallet update (accumulators)
- Static data (users, words, catalog) already present from seed — skipped

---

## 3. What was validated

| Check | Result |
|---|---|
| Coins balance parity | PASS (JSON=2, PG=2) |
| Fish treats balance parity | PASS (JSON=0, PG=0) |
| Feed mood/exp/bond accumulated | PASS (all zeros match) |
| Equipment slots count | PASS (both 0) |
| Reward ledger count | PASS (JSON=2, PG=2) |
| Settlements count | PASS |
| Idempotency keys count | PASS |
| Study attempts count | FAIL (JSON=1, PG=0 — test artifact FK violation) |

**17/18 checks pass. The 1 failure is non-blocking (test artifact word_id).**

---

## 4. What still stays on DevStore runtime truth

- **ALL controllers** still read/write through DevStore via repositories adapter (A1)
- PG contains a parallel copy of the data but is NOT used at runtime
- DevStore JSON file continues to be the single source of truth until A4 cutover

---

## 5. What must be done next

**A4 — Cutover & Regression:**
1. Write PG repository implementations for all interfaces (same signatures as DevStore adapters)
2. Switch `repositories` object from DevStore adapters to PG adapters
3. Run all 127 tests against PG backend
4. Verify all API endpoints return identical results
5. Mark DevStore as legacy/fallback

Recommended A4 first cut:
- Start with read-only paths: `SecondarySummaryRepository`, `TodayRepository`, `CatalogRepository`
- Then switch write paths: `StudyRepository`, `RewardRepository`, `IdempotencyRepository`
- Finally switch secondary: `FeedRepository`, `InventoryRepository`, `EquipmentRepository`

---

## 6. What not to touch

- Do NOT modify the JSON persistence layer
- Do NOT switch any controller to read from PG until A4
- Do NOT change API response formats
- Do NOT change DevStore business logic

---

## 7. Files / modules to read first

1. `apps/api/scripts/db/import-json.ts` — Import script with validation
2. `docs/R4_OptionA_import_manifest_v0.1.md` — Import order and conflict strategy
3. `docs/R4_OptionA_import_validation_report_v0.1.md` — Parity check results
4. `docs/R4_OptionA_rollback_rehearsal_v0.1.md` — Rollback procedure and rehearsal results
5. `apps/api/src/infrastructure/postgres/migrations/001_initial_schema.sql` — PG schema
6. `apps/api/src/domain/repository/` — Interfaces that PG repositories must implement

---

## 8. Current risks

1. **PG repository implementations don't exist yet**: A4 needs to write ~12 PG adapter classes implementing the A1 interfaces. This is the largest remaining work.
2. **Test DB strategy**: A4 tests will need to run against PG. Need either a separate test DB or transaction-rollback isolation.
3. **Study attempt FK**: The test-artifact word `word-learning-day-001` exists in JSON but not in the word pool. When A4 switches to PG, study attempts will only accept valid word IDs (this is correct behavior).

---

## 9. Recommended next prompt focus

> "Implement Option A A4: Cutover & Regression. Write PG repository implementations for all A1 interfaces. Switch the repositories object from DevStore adapters to PG adapters. Run all 127 tests against PG backend. Verify API parity. Keep DevStore as fallback until A5."
