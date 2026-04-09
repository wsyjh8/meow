# Cursor Round Summary — Option A, A0

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Conducted **Option A A0: Local Readiness & Execution Boundary Check**. No code was changed. This was a preflight round that:

- Read all persistence-related code (DevStore, DevStorePersistence, snapshot shape)
- Mapped all 12 controllers' DevStore dependencies (~30 method calls)
- Confirmed zero DB dependencies in package.json
- Confirmed no .env files exist
- Verified all 127 tests pass (16 unit + 67 e2e + 44 Flutter)
- Proposed repo structure for A1-A5
- Recommended technology stack (pg + raw SQL migrations)
- Identified the recommended A1 first cut

---

## 2. What is already true now

- All P2 state lives in `DevStore` singleton, persisted to JSON via `DevStorePersistence`
- 12 controllers import `devStore` directly — zero abstraction layer
- DevStore has ~30 public methods (15 read, 15 write)
- Snapshot uses `any[]` types — proper typing only in DevStore class fields
- Static data (wordPool, catalog, catProfile, levelThresholds) is hardcoded in DevStore
- All 127 tests pass, repo is healthy

---

## 3. What is still unclear

- Whether the user has PostgreSQL installed/accessible locally (Docker or native)
- The user's preferred DB credentials (needed for `.env`)
- Whether Knex is desired as a query builder, or raw `pg` is preferred

---

## 4. What blocks A1 / what does not block A1

**Does NOT block A1:**
- A1's main deliverable (repository interfaces + DevStore adapter) does NOT require a running PostgreSQL instance
- Package installation (`pg`, `@types/pg`) and interface definition can proceed immediately

**Blocks A2 (but not A1):**
- PostgreSQL server must be accessible for A2 (schema creation, migration, seed)
- `.env` with `DATABASE_URL` must be configured for A2

---

## 5. What must be done next

**A1 — Persistence Abstraction** (recommended scope):
1. Create `.env.example` with `DATABASE_URL` placeholder
2. `npm install pg @types/pg`
3. Create `src/domain/repository/` with interfaces extracted from DevStore methods
4. Create `src/domain/dev-store-adapter.ts` wrapping DevStore behind interfaces
5. Update one controller (SecondarySummaryController) as proof-of-concept
6. Verify all 127 tests still pass

---

## 6. What not to touch

- Do NOT write SQL schema in A1
- Do NOT create migration files in A1
- Do NOT attempt DB connection in A1
- Do NOT change API response formats
- Do NOT modify DevStore behavior
- Do NOT restructure controllers beyond the one PoC

---

## 7. Files / modules to read first

1. `apps/api/src/domain/dev-store.ts` — THE central file. All state, all methods, all persistence hooks
2. `apps/api/src/domain/persistence.ts` — JSON load/save adapter
3. `apps/api/src/domain/types.ts` — Domain type definitions (source of truth for PG schema in A2)
4. `apps/api/src/controllers/` — All 12 controllers, each imports `devStore` directly
5. `apps/api/package.json` — Zero DB deps currently
6. `docs/R4_OptionA_A0_readiness_report_v0.1.md` — This round's full analysis

---

## 8. Current risks

1. **Controller tight coupling**: 12 controllers all import the singleton directly. Switching to injected services requires touching every file (planned for A4).
2. **Snapshot `any[]` types**: JSON persistence has no type safety at the serialization boundary. Must not carry this weakness into PG.
3. **Derived state complexity**: mood, level, balance are computed on-read from raw data. PG version must decide compute vs store strategy.
4. **PostgreSQL availability**: User must confirm PG is accessible before A2 can start.

---

## 9. Recommended next prompt focus

> "Implement Option A A1: Persistence Abstraction. Create repository interfaces in `src/domain/repository/`, create DevStore adapter, install `pg` + `@types/pg`, create `.env.example`, update SecondarySummaryController as PoC. Do NOT write SQL or connect to a real database."

**User action needed before A2**: Confirm PostgreSQL is accessible and provide the `DATABASE_URL` or credentials for `.env`.
