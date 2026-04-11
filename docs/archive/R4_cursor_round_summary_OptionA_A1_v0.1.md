# Cursor Round Summary — Option A, A1

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Implemented **Option A A1: Persistence Abstraction**.

- Created 8 repository interface files covering all 12 domain areas
- Created `dev-store-adapter.ts` with 12 adapter classes wrapping DevStore behind interfaces
- Refactored all 12 controllers to use `repositories.*` instead of `devStore.*` directly
- Created `.env.example` with DATABASE_URL placeholder
- Zero controllers now import `devStore` directly
- All 127 tests pass with zero breakage

---

## 2. What is already true now

- **Abstraction seam exists**: Controllers depend on interfaces, not concrete store
- **DevStore is unchanged**: All business logic still in DevStore, just accessed via adapter layer
- **repositories object**: Single import point with typed repository access (e.g., `repositories.study.getNextNewWord()`)
- **127 tests pass**: refactoring is verified transparent
- **A2 can proceed**: PG implementations can be written against the same interfaces without touching controllers

---

## 3. What still directly depends on JSON store

- `dev-store-adapter.ts` imports `devStore` singleton — this is the planned bridge
- `DevStore` itself still uses `DevStorePersistence` for JSON file I/O
- e2e tests use `devStore.reset()` for test isolation
- Unit tests (level.spec.ts, persistence.spec.ts) use DevStore directly

These will be addressed in A4 (cutover) and A5 (cleanup).

---

## 4. What was abstracted

| Domain | Interface | Adapter | Controllers using it |
|---|---|---|---|
| Study | IStudyRepository | DevStoreStudyAdapter | study-attempts |
| Review | IReviewRepository | DevStoreReviewAdapter | review-groups, review-attempts |
| Reward | IRewardRepository | DevStoreRewardAdapter | settlements, study-attempts, review-attempts |
| Session | ISessionRepository | DevStoreSessionAdapter | sessions |
| CheckIn | ICheckInRepository | DevStoreCheckInAdapter | check-ins, today, study-attempts, review-attempts |
| Today | ITodayRepository | DevStoreTodayAdapter | today, check-ins, study-attempts, review-attempts |
| Feed | IFeedRepository | DevStoreFeedAdapter | feed |
| Catalog | ICatalogRepository | DevStoreCatalogAdapter | shop |
| Inventory | IInventoryRepository | DevStoreInventoryAdapter | shop, inventory |
| Equipment | IEquipmentRepository | DevStoreEquipmentAdapter | equipment |
| SecSummary | ISecondarySummaryRepository | DevStoreSecondarySummaryAdapter | secondary-summary, feed |
| Idempotency | IIdempotencyRepository | DevStoreIdempotencyAdapter | all write controllers |

---

## 5. What must be done next

**A2 — Schema / Migration / Seed:**
1. `npm install pg @types/pg`
2. Create `src/infrastructure/database/connection.ts` — PG pool
3. Create `src/infrastructure/database/migrations/001_initial_schema.sql`
4. Create PG repository implementations (same interfaces)
5. Seed static data (words, catalog)

Recommended A2 first tables: `idempotency_keys`, `reward_source_events`, `reward_ledger`, `study_attempts` — the write-heavy truth paths.

---

## 6. What not to touch

- Do NOT modify DevStore business logic
- Do NOT change API response shapes
- Do NOT start cutover (A4) before A2+A3 are done
- Do NOT remove the DevStore adapter until A5

---

## 7. Files / modules to read first

1. `apps/api/src/domain/repository/` — All 8 interface files
2. `apps/api/src/domain/dev-store-adapter.ts` — Adapter + repositories object
3. `apps/api/src/domain/index.ts` — Updated exports
4. `apps/api/src/controllers/` — All 12 now use `repositories`
5. `apps/api/.env.example` — DB config placeholder

---

## 8. Current risks

1. **Adapter is thin delegation**: Each adapter method just calls DevStore. If DevStore API changes, adapter must change too. This is expected — it's a bridge.
2. **No NestJS DI**: `repositories` is a plain module singleton, not injected via NestJS providers. This is simpler but means swapping implementations requires changing the adapter file, not DI config. Acceptable for A2-A4 scope.
3. **e2e tests still use `devStore.reset()`**: Test isolation depends on the DevStore singleton. When switching to PG (A4), tests will need a DB transaction/rollback pattern or test DB reset.

---

## 9. Recommended next prompt focus

> "Implement Option A A2: Schema / Migration / Seed. Install pg, create database connection, write initial SQL schema, seed static data (words, catalog). Create PG repository implementations for the highest-priority interfaces. Do NOT cutover controllers yet."

**User action needed**: Copy `.env.example` to `.env` and fill in your PostgreSQL password at `YOUR_PASSWORD_HERE`. Also create the database: `createdb meow_dev`.
