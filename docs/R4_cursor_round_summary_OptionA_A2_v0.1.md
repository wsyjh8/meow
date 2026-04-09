# Cursor Round Summary — Option A, A2

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Implemented **Option A A2: Schema / Migration / Seed**.

- Installed `pg` + `@types/pg`
- Created PG connection pool (`client.ts`) reading `DATABASE_URL` from env
- Created migration runner (`migrate.ts`) with up/down/status, `_migrations` tracking table, transactional execution
- Created initial schema SQL (`001_initial_schema.sql`) with 25 business tables covering all domains
- Created idempotent dev seed (`dev-seed.ts`) matching DevStore static data exactly (30 words, 5 catalog items, dev user, pet profile, etc.)
- Created PG health check (`health.ts`)
- Added npm scripts: `db:migrate`, `db:migrate:down`, `db:migrate:status`, `db:seed`, `db:reset`
- Verified: migrate up → seed → rollback → re-migrate → re-seed all work
- All 127 existing tests still pass (zero breakage)

---

## 2. What schema / migration / seed now exists

### Tables (25)
**Static/base (5)**: users, word_books, words, user_book_settings, shop_catalog_items
**Main mechanism (10)**: study_attempts, user_word_progress, review_groups, review_group_items, review_attempts, daily_goal_progress, session_records, check_in_records, learning_day_facts, streak_records
**Reward (4)**: reward_source_events, reward_ledger, settlements, idempotency_keys
**Secondary (6)**: secondary_wallets, pet_profiles, feed_events, inventory_items, equipment_slots, purchase_records

### Key constraints
- 14 UNIQUE constraints on business-critical combinations
- Foreign keys on all cross-table references
- Indexes on user/date/status/lookup patterns

### Seed data
- 1 dev user (`dev-user-001`)
- 1 word book (CET-4) with 30 words (20 new + 10 review)
- 5 catalog items (3 outfit + 2 room_item)
- Pet profile, secondary wallet, streak record for dev user

### Commands
```bash
npm run db:migrate        # Apply pending migrations
npm run db:migrate:down   # Rollback last migration
npm run db:migrate:status # Show applied/pending
npm run db:seed           # Seed dev data (idempotent)
npm run db:reset          # Rollback + migrate + seed
```

---

## 3. What is still not connected to runtime truth

- **All controllers still use DevStore** via `repositories` adapter (A1 abstraction)
- **No PG repository implementations exist yet** — only interfaces (A1) and schema (A2)
- **No JSON data has been imported into PG** — only static seed data exists
- **Runtime reads/writes still go through JSON file** — PG is a parallel empty container

---

## 4. What must be done next

**A3 — JSON Import & Validation:**
1. Write import script that reads current DevStore JSON snapshot and inserts into PG tables
2. Validate row counts and key facts match between JSON and PG
3. Write PG repository implementations for highest-priority interfaces
4. Run parity checks (today summary, secondary summary, inventory should return identical results from both sources)

Recommended A3 first targets:
- Import `idempotency_keys`, `reward_source_events`, `reward_ledger`, `settlements` first (write-truth critical)
- Then `study_attempts`, `review_groups`, `review_attempts` (main mechanism)
- Then secondary state (`feed_events`, `inventory_items`, `equipment_slots`, etc.)

---

## 5. What not to touch

- Do NOT switch any controller to read from PG yet (that's A4)
- Do NOT write to PG from business logic yet
- Do NOT remove DevStore or JSON persistence
- Do NOT change API response formats
- Do NOT modify the schema without a new migration file

---

## 6. Files / modules to read first

1. `apps/api/src/infrastructure/postgres/migrations/001_initial_schema.sql` — THE schema
2. `apps/api/src/infrastructure/postgres/client.ts` — PG pool setup
3. `apps/api/src/infrastructure/postgres/migrate.ts` — Migration runner
4. `apps/api/src/infrastructure/postgres/seed/dev-seed.ts` — Dev seed
5. `apps/api/src/infrastructure/postgres/health.ts` — Health check
6. `apps/api/.env` — Database credentials (gitignored)
7. `apps/api/package.json` — New `db:*` scripts

---

## 7. Current risks

1. **Schema/DevStore alignment**: Schema was designed from `types.ts` and DevStore structure. If DevStore changes before A3 import, schema may need updates.
2. **Migration runner is custom**: Not a battle-tested framework. Adequate for current scale but may need hardening for production.
3. **No PG in test pipeline**: Existing tests don't touch PG at all. A3/A4 will need a test DB strategy (separate test database or transaction rollback pattern).

---

## 8. Recommended next prompt focus

> "Implement Option A A3: JSON Import & Validation. Write an import script that reads DevStore JSON snapshot and populates PG tables. Write PG repository implementations for idempotency, reward, study, review, and secondary domains. Validate parity between JSON and PG truth for key read paths. Do NOT switch controllers to PG yet."
