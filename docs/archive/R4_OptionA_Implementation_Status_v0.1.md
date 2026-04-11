# Option A Implementation Status v0.1

**Date**: 2026-04-04
**Current slice**: A5 + Focused Closeout Patch
**Status**: Option A Complete — All review items closed — Ready for Room 1 Close Judgment

---

## 1. Current Slice: A1

A1 (Persistence Abstraction) is complete. All 12 controllers now access state through repository interfaces backed by DevStore adapters, instead of importing the `devStore` singleton directly.

---

## 2. Implemented Range

### Repository interfaces (8 files)
- `IStudyRepository` — word lookup, study attempt submission
- `IReviewRepository` — review group lifecycle, review attempt submission
- `IRewardRepository` — source events, settlements, balance snapshot
- `ISessionRepository` — session start/finish/query
- `ICheckInRepository` — check-in, streak, learning day
- `ITodayRepository` — today state aggregation
- `IFeedRepository`, `ICatalogRepository`, `IInventoryRepository`, `IEquipmentRepository`, `ISecondarySummaryRepository` — all secondary mechanism
- `IIdempotencyRepository` — cross-cutting idempotency

### DevStore adapter (1 file)
- `dev-store-adapter.ts` — 12 adapter classes implementing all interfaces, delegating to `devStore` singleton
- Exported as `repositories` object with typed fields

### Controller refactoring (10 controller files)
All 12 controllers changed from `import { devStore } from '../domain'` to `import { repositories } from '../domain'`:
- `today.controller.ts`
- `secondary-summary.controller.ts`
- `study-attempts.controller.ts`
- `review-attempts.controller.ts`
- `review-groups.controller.ts`
- `sessions.controller.ts`
- `check-ins.controller.ts`
- `settlements.controller.ts`
- `feed.controller.ts`
- `shop.controller.ts`
- `inventory.controller.ts`
- `equipment.controller.ts`

### Configuration
- `.env.example` created with DATABASE_URL placeholder

---

## 2b. A2 Implemented Range

### PostgreSQL infrastructure
- `pg` + `@types/pg` installed
- `src/infrastructure/postgres/client.ts` — connection pool (singleton Pool from DATABASE_URL)
- `src/infrastructure/postgres/health.ts` — PG health check (connectivity + migration status)
- `src/infrastructure/postgres/migrate.ts` — migration runner (up/down/status, SQL file based, `_migrations` tracking table)
- `src/infrastructure/postgres/index.ts` — exports

### Migration system
- SQL files in `src/infrastructure/postgres/migrations/`
- `_migrations` table tracks applied migrations
- `npm run db:migrate` / `db:migrate:down` / `db:migrate:status`
- Transactional: each migration runs in BEGIN/COMMIT with ROLLBACK on failure

### Schema (001_initial_schema.sql) — 25 tables
**Static/base**: users, word_books, user_book_settings, words, shop_catalog_items
**Main mechanism**: study_attempts, user_word_progress, review_groups, review_group_items, review_attempts, daily_goal_progress, session_records, check_in_records, learning_day_facts, streak_records
**Reward/settlement**: reward_source_events, reward_ledger, settlements, idempotency_keys
**Secondary mechanism**: secondary_wallets, pet_profiles, feed_events, inventory_items, equipment_slots, purchase_records

### Seed
- `npm run db:seed` — idempotent dev seed (ON CONFLICT DO NOTHING)
- Seeds: 1 dev user, 1 word book, 1 user_book_setting, 30 words, 5 catalog items, pet profile, secondary wallet, streak record

### Key constraints
- UNIQUE: user_book_settings(user_id, book_id), user_word_progress(user_id, word_id), review_group_items(review_group_id, word_id), daily_goal_progress(user_id, local_date), check_in_records(user_id, local_date), learning_day_facts(user_id, local_date), streak_records(user_id), reward_source_events(event_type, source_ref_id), settlements(source_event_id), secondary_wallets(user_id), pet_profiles(user_id), inventory_items(user_id, item_id), equipment_slots(user_id, slot, item_type), idempotency_keys(key)
- Foreign keys on all user_id, word_id, book_id, item_id references
- Indexes on user-based, date-based, status-based, and lookup queries

---

## 3. Not Yet Implemented

### A3 Implemented Range

- `scripts/db/import-json.ts` — JSON→PG import script with ordered import (23 tables), conflict handling (ON CONFLICT), validation (18 parity checks)
- Import manifest, validation report, rollback rehearsal documented
- Import verified: 8 rows imported from live JSON snapshot, 17/18 parity checks pass
- 1 known non-blocking difference: study_attempt with test-artifact word_id (FK violation)
- Rollback rehearsal: `db:reset` successfully returns to clean seed state
- npm scripts: `db:import`, `db:import:validate`

## 3b. Not Yet Implemented

| Item | Phase | Notes |
|---|---|---|
| PG repository implementations | A4 | Interfaces ready (A1), schema ready (A2), import done (A3) |
| Cutover (switch controllers to PG) | A4 | |
| Remove legacy JSON store | A5 | |

---

## 4. Assumptions

1. `Assumption (temporary, not frozen): DevStore adapter is the sole active implementation of all repository interfaces until A4 cutover.`
2. `Assumption (temporary, not frozen): repositories object is a plain module-level singleton, not NestJS DI injected.`
3. `Assumption (temporary, not frozen): pg (node-postgres) + raw SQL migrations is the chosen stack.`
4. `Assumption (temporary, not frozen): single-user model persists through Option A.`
5. `Assumption (temporary, not frozen): migration runner is minimal custom code, not a framework. Adequate for current scale.`

---

## 5. Blockers

None for A4 start.

---

## 6. Bug List

None. All 127 tests pass after A1 refactoring.

---

## 7. Test Results

| Suite | Count | Status |
|---|---|---|
| Backend unit tests | 16 | All pass |
| Backend e2e tests | 67 | All pass |
| Flutter widget tests | 44 | All pass |
| Flutter analyze | 19 info | 0 errors, 0 warnings |
| **Total** | **127** | **All pass** |

---

## 8. Rollback Readiness

If A1 needs to be reverted:
- Restore controllers to import `devStore` directly instead of `repositories`
- Remove `src/domain/repository/` directory
- Remove `src/domain/dev-store-adapter.ts`
- Remove `.env.example`

The DevStore itself was NOT modified. Rollback is safe and mechanical.

---

## 9. Ready for A2?

**Yes.** The abstraction seam is in place. A2 can:
1. Install `pg` + `@types/pg`
2. Create `src/infrastructure/database/` with connection pool
3. Create migration files with schema
4. Implement PG repository classes that implement the same interfaces
5. All without touching any controller code

---

## 10. Focused Closeout Patch (post-A5)

### Patch scope
3 review items accepted as within Option A scope:

### Patch-01: Maintenance guard — CLOSED
- `MaintenanceGuardMiddleware` registered globally
- Blocks all POST/PUT/PATCH/DELETE when `MAINTENANCE_MODE=true`
- Returns HTTP 503 with structured `MAINTENANCE_MODE_ACTIVE` error
- GET requests pass through

### Patch-02: Confirmed persistence — CLOSED
- `saveToDisk()` now uses serialized save chain (no concurrent PG saves)
- `saveToDiskAsync()` awaits chain and throws on failure
- `ensurePersisted()` in repositories adapter, awaited by all 10 write controller methods
- Success return = PG confirmed

### Patch-03: PG backend regression — CLOSED
- 10 PG e2e tests in `test/pg-regression.e2e-spec.ts`
- Covers: today, summary, purchase, equip, feed, study+settlement, check-in, maintenance (3)
- `npm run test:e2e:pg` — all pass

### Remaining technical debt
- TD-01: Full snapshot save (delete-all + re-insert) — Medium — future optimization
- TD-05: Single-user model — Low — future phase
- TD-06: PG pool not closed in PG e2e (Jest warning) — Cosmetic

### Test totals after patch
| Suite | Count | Status |
|---|---|---|
| Unit | 16 | Pass |
| JSON e2e | 67 | Pass |
| PG e2e | 10 | Pass |
| Flutter | 44 | Pass |
| **Total** | **137** | **All pass** |
