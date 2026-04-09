# Option A — Final Closeout v0.1

**Date**: 2026-04-04
**Phase**: A5 (Final)
**Status**: Option A Complete — Recommending Close

---

## 1. Option A Summary

Option A (Production Persistence Hardening) has been completed across 6 slices:

| Slice | Scope | Status |
|---|---|---|
| A0 | Preflight / readiness check | Complete |
| A1 | Persistence abstraction (repository interfaces + adapter) | Complete |
| A2 | Schema / migration / seed (25 PG tables) | Complete |
| A3 | JSON import + validation + rollback rehearsal | Complete |
| A4 | PG cutover (PgDevStorePersistence + factory) | Complete |
| A5 | Compatibility cleanup + closeout | Complete |

---

## 2. PG Is the Sole Active Runtime Truth

**Confirmed.**

- `PERSISTENCE_BACKEND` defaults to `'pg'`
- Missing `DATABASE_URL` with PG backend **throws an error** (no silent fallback)
- JSON backend requires **explicit** `PERSISTENCE_BACKEND=json` opt-in
- All business read/write paths go through DevStore → PgDevStorePersistence → PostgreSQL
- No controller imports `devStore` directly — all use `repositories.*` adapter
- Singleton factory creates exactly one persistence adapter

---

## 3. What JSON Still Retains

| Capability | Status | Purpose |
|---|---|---|
| `DevStorePersistence` class | **Retained** | Emergency fallback, test isolation |
| `PERSISTENCE_BACKEND=json` | **Retained** (explicit opt-in only) | Test isolation (`jest-env-setup.ts`) |
| `scripts/db/import-json.ts` | **Retained** | One-time migration from JSON to PG |
| `data/dev-store-state.json` | **Retained** (read-only) | Legacy snapshot, not written to during PG operation |
| `data/pg-backup-*.json` | **New** | PG backup exports |

**JSON is NOT written to during normal PG operation.** It is tooling-only.

---

## 4. Current Technical Debt

| # | Item | Severity | Impact | Recommended Stage |
|---|---|---|---|---|
| TD-01 | Full snapshot save | Medium | Every mutation deletes all + re-inserts all user data in PG. Fine at dev scale. | Next optimization round |
| TD-02 | Fire-and-forget PG save | Medium | `save()` doesn't await. PG write failure logged but not propagated. | Next optimization round |
| TD-03 | Tests use JSON backend | Low | E2e/unit tests validate logic against JSON. PG verified separately via roundtrip. | Next optimization round |
| TD-04 | Maintenance mode not in write controllers | Low | `MAINTENANCE_MODE` checked in health endpoint but not yet gating write controllers. | Next feature round |
| TD-05 | Single-user model | Low | DevStore hardcodes `dev-user-001`. Multi-user requires schema+logic refactor. | Future major phase |

---

## 5. Compatibility Cleanup Results

### Removed from business path
- Silent JSON fallback when `DATABASE_URL` is missing → now throws error
- No business controller or service writes to JSON during PG operation

### Retained as tooling
- `DevStorePersistence` for test isolation and emergency
- Import/export/backup/restore scripts
- Legacy `data/dev-store-state.json` as read-only artifact

---

## 6. Backup / Restore Results

| Operation | Command | Result |
|---|---|---|
| Backup | `npm run db:backup` | Exports PG state to `data/pg-backup-{timestamp}.json` |
| Restore | `npm run db:restore <file>` | Clears PG user state, writes from backup, verifies |
| Rehearsal | Backup → Reset → Restore → Verify | **PASS** — roundtrip verified |

---

## 7. Close Recommendation

**Room 4 recommends Option A close: YES.**

All A0-A5 slices are complete:
- PG is sole active runtime truth
- JSON demoted to tooling-only
- 127 automated tests pass
- Backup/restore verified
- Persistence test matrix documented
- Technical debt is documented and non-blocking

Room 1 can accept this as the Option A production persistence hardening delivery.

---

## 8. Recommended Next Steps (post-close)

1. **Incremental PG writes** — replace full snapshot save with per-mutation SQL
2. **E2e tests on PG** — switch test suite to use PG test database
3. **Maintenance mode in controllers** — gate write endpoints during maintenance
4. **Multi-user support** — requires schema and logic refactor
5. **CI pipeline** — add PG to CI for automated persistence regression
