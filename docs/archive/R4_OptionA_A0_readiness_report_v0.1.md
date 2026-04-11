# Option A — A0 Readiness Report

**Date**: 2026-04-03
**Phase**: Option A, A0 (Preflight)
**Status**: Complete — Ready for A1

---

## 1. Scope

This round is a preflight check for Option A (Production Persistence Hardening). No code was changed. The goals were:
- Map current persistence architecture
- Assess PostgreSQL local readiness
- Propose repo structure for A1-A5
- Identify blockers, assumptions, risks
- Confirm readiness to start A1

---

## 2. Current Persistence Architecture

### 2.1 Where state lives
All mutable state lives in a **single class**: `DevStore` (`apps/api/src/domain/dev-store.ts`).

It is exported as a **singleton**: `export const devStore = new DevStore()`.

**12 controllers** import this singleton directly via `import { devStore } from '../domain'` and call methods on it. There is **zero abstraction** between controllers and the concrete store.

### 2.2 Persistence mechanism
`DevStorePersistence` (`apps/api/src/domain/persistence.ts`) provides file-backed JSON save/load:
- **File path**: `apps/api/data/dev-store-state.json` (configurable via `DEV_STORE_PERSIST_DIR` / `DEV_STORE_PERSIST_FILENAME`)
- **Load**: On `DevStore` construction
- **Save**: After every state-mutating method (14 save points)
- **Reset**: Clears both memory and file (used by tests)
- **Atomic write**: tmp file + rename

### 2.3 Snapshot shape (DevStoreSnapshot)
All persisted state in a single flat JSON:

| Field | Domain | Type |
|---|---|---|
| `studyAttempts` | Main/Study | `any[]` |
| `reviewGroups` | Main/Review | `any[]` |
| `reviewAttempts` | Main/Review | `any[]` |
| `sourceEvents` | Reward | `any[]` |
| `rewardLedgerItems` | Reward | `any[]` |
| `settlements` | Reward | `any[]` |
| `sessions` | Session | `any[]` |
| `checkIns` | Check-in | `any[]` |
| `streakRecord` | Streak | `any \| null` |
| `learningDays` | Learning | `any[]` |
| `todayStates` | Today | `Record<string, any>` |
| `feedRecords` | Feed | `any[]` |
| `feedMoodAccumulated` | Feed/Pet | `number` |
| `feedExpAccumulated` | Feed/Pet | `number` |
| `feedBondAccumulated` | Feed/Pet | `number` |
| `ownedItems` | Inventory | `any[]` |
| `coinsSpent` | Inventory | `number` |
| `equippedOutfit` | Equipment | `Record<string, string \| null>` |
| `equippedRoom` | Equipment | `Record<string, string \| null>` |
| `idempotencyKeys` | Cross-cutting | `Record<string, any>` |

Note: The snapshot types are all `any[]` — typed only at the DevStore class level via private fields.

### 2.4 DevStore public methods used by controllers

**Read methods** (~15):
`getTodayState()`, `getNextNewWord()`, `getActiveReviewGroup()`, `getOrCreateReviewGroup()`, `getIdempotencyKey()`, `getSession()`, `getCheckInForDate()`, `getOrCreateStreak()`, `getSecondarySummary()`, `getCatalog()`, `getInventory()`, `getEquippedSnapshot()`, `getSettlementBySourceEventId()`, `hasReviewGroupCompletedEvent()`, `getTotalExp()`

**Write methods** (~15):
`submitStudyAttempt()`, `submitReviewAttempt()`, `createOrGetSourceEvent()`, `createSettlement()`, `startSession()`, `finishSession()`, `checkIn()`, `feedCat()`, `purchaseItem()`, `equipItem()`, `unequipItem()`, `setIdempotencyKey()`, `updateTodayState()`, `updateLearningDay()`

### 2.5 Static/readonly data in DevStore
- `wordPool` (30 hardcoded words)
- `catalog` (5 hardcoded shop items)
- `catProfile` (nickname, baseMood, baseBond)
- `LEVEL_THRESHOLDS` (Lv1-10)
- `userId` = `'dev-user-001'`

---

## 3. PostgreSQL Local Readiness

### 3.1 Current DB dependencies
**None.** `package.json` has zero database-related packages. No PostgreSQL driver, no ORM, no query builder, no migration tool.

### 3.2 No .env file exists
No `.env` or `.env.example` in the repo. Environment variables are read inline in `ConfigService` and `DevStorePersistence`.

### 3.3 Minimum required for A1

**System prerequisites:**
- PostgreSQL server (local or Docker)
- A database created (e.g., `meow_dev`)

**NPM packages needed (A1/A2):**
- `pg` (node-postgres) — PostgreSQL client
- A migration tool (see recommendation below)

**Environment variables needed:**
```
DATABASE_URL=postgresql://user:password@localhost:5432/meow_dev
```
Or individual:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=meow_dev
DB_USER=meow
DB_PASSWORD=<secret>
```

### 3.4 Recommended technology stack

**Recommendation: `pg` (node-postgres) + raw SQL migrations + Knex for query building (optional)**

Rationale:
- **Against full ORM** (TypeORM/Prisma): Too heavy for current project size. Would require major restructuring of the DevStore pattern. Prisma's schema-first approach conflicts with the incremental migration plan.
- **Against Drizzle**: Newer, less battle-tested. Extra complexity for no current benefit.
- **For raw `pg` + SQL migrations**: Minimal dependencies. Full control. Easy to understand. Matches the "don't over-engineer" project principle. Migration files are plain SQL, easy to review.
- **Knex as optional addition**: Provides query builder if raw SQL gets verbose, plus built-in migration runner. Lightweight. Can be added in A2 if needed.

**Simplest viable path for A1:**
1. `npm install pg @types/pg` (just the driver)
2. Create a connection pool module
3. Define repository interfaces
4. Implement PostgreSQL adapters in A2

---

## 4. Repo Structure — Suggested Landing Spots for A1–A5

```
apps/api/src/
├── domain/
│   ├── types.ts                    # (existing) domain types
│   ├── dev-store.ts                # (existing) in-memory store — becomes legacy adapter
│   ├── persistence.ts              # (existing) JSON persistence — becomes legacy
│   ├── repository/                 # NEW (A1): repository interfaces
│   │   ├── index.ts
│   │   ├── study.repository.ts     # interface for study domain
│   │   ├── review.repository.ts    # interface for review domain
│   │   ├── reward.repository.ts    # interface for reward domain
│   │   ├── session.repository.ts   # interface for session/check-in domain
│   │   ├── secondary.repository.ts # interface for feed/pet/inventory/equipment
│   │   └── idempotency.repository.ts
│   └── dev-store-adapter.ts        # NEW (A1): wraps DevStore behind repository interfaces
├── infrastructure/                  # NEW (A2+)
│   ├── database/
│   │   ├── connection.ts           # pg pool setup
│   │   ├── migrations/             # SQL migration files
│   │   │   ├── 001_initial_schema.sql
│   │   │   └── ...
│   │   └── migrate.ts              # migration runner
│   └── postgres/                    # (A2+): PostgreSQL repository implementations
│       ├── pg-study.repository.ts
│       ├── pg-review.repository.ts
│       └── ...
├── config/
│   ├── config.service.ts           # (existing) — extend with DB config
│   └── ...
├── controllers/                     # (existing) — update imports in A4
└── ...
```

### Migration files location
`apps/api/src/infrastructure/database/migrations/`

### Import / export tools
`apps/api/src/infrastructure/database/import-json.ts` (A3)
`apps/api/src/infrastructure/database/export-snapshot.ts` (optional rollback tool)

### Readiness / maintenance indicators
`apps/api/src/infrastructure/database/health.ts` — DB connection health check (A4)

---

## 5. A1 Pre-Start Checklist

| # | Item | Status | Action |
|---|---|---|---|
| 1 | Repo code read and understood | Done | This report |
| 2 | PostgreSQL server available locally | **User must confirm** | Install PG or use Docker |
| 3 | Database created | **User must do** | `createdb meow_dev` |
| 4 | `.env` or `.env.example` with DB_URL | **A1 will create** | — |
| 5 | `pg` package installed | **A1 will do** | `npm install pg @types/pg` |
| 6 | Repository interfaces defined | **A1 scope** | — |
| 7 | DevStore adapter wrapping interfaces | **A1 scope** | — |
| 8 | All 127 tests still passing | **Confirmed** | 16+67+44 = 127 pass |

---

## 6. Blockers

### For A0 completion
**No blocker.** A0 is complete.

### For A1 start
**One prerequisite**: User must have PostgreSQL accessible locally (installed or Docker). Room 4 cannot verify this — user confirmation needed.

If PostgreSQL is not yet available:
- `No blocker for starting A1 after A0, provided PostgreSQL is locally accessible.`
- A1's first sub-step (repository interfaces) does not require a running PG instance — only A2 (schema/migration) needs it.

---

## 7. Assumptions

1. `Assumption (temporary, not frozen): A1 will use pg (node-postgres) as the PostgreSQL driver, not a full ORM.`
2. `Assumption (temporary, not frozen): migrations will be plain SQL files with a simple runner, not an ORM migration framework.`
3. `Assumption (temporary, not frozen): DevStore remains the active truth source until A4 cutover. A1 only adds interfaces.`
4. `Assumption (temporary, not frozen): single-user model persists through Option A. Multi-user is a separate future concern.`
5. `Assumption (temporary, not frozen): A1 repository interfaces will cover all ~30 DevStore public methods used by controllers.`

---

## 8. Risks

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| R-001 | Repository interface mismatch | If interfaces don't match DevStore's actual behavior, A2-A4 will be painful | A1 must extract interfaces directly from reading DevStore method signatures |
| R-002 | Controller tight coupling | 12 controllers import `devStore` singleton directly — switching to injected services requires touching every controller | Plan for A4 to be a systematic controller-by-controller update |
| R-003 | DevStoreSnapshot `any[]` types | JSON snapshot uses `any[]` — no type safety on restore. PG migration must enforce proper types | A2 schema must be derived from domain `types.ts`, not from snapshot |
| R-004 | Derived state (mood, level, balance) | Current DevStore computes mood/level/balance from raw data on read. PG version needs to decide: store derived values or recompute on query | Decision needed in A2 — recommend recompute for truth, cache for performance |

---

## 9. Recommended A1 First Cut

### What to do in A1
1. **Create `.env.example`** with `DATABASE_URL` placeholder
2. **Install `pg` + `@types/pg`**
3. **Create `src/domain/repository/` directory** with interfaces extracted from DevStore's public method signatures
4. **Create `src/domain/dev-store-adapter.ts`** that wraps the existing DevStore singleton behind these interfaces
5. **Update one controller** (recommend: `SecondarySummaryController`) to use the interface instead of direct `devStore` import — as proof-of-concept
6. **Verify all 127 tests still pass** — the adapter should be transparent

### Why this is the right first cut
- It creates the abstraction seam without changing behavior
- It proves the interface design works before writing any SQL
- It keeps DevStore as the live backend (no risk of data loss)
- It makes A2 (PG implementation) a clean parallel implementation exercise
- The proof-of-concept controller switch validates the wiring pattern

### What NOT to do in A1
- Do NOT write any SQL schema
- Do NOT create migration files
- Do NOT install PostgreSQL-specific migration tools
- Do NOT attempt to run against a real database
- Do NOT change any API response format
