# Cursor Round Summary — Option A, A5

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Completed **Option A A5: Compatibility Cleanup + Persistence Closeout**.

- Hardened persistence factory: missing `DATABASE_URL` now throws error (no silent JSON fallback)
- Created `scripts/db/backup.ts` — exports PG state to JSON file
- Created `scripts/db/restore.ts` — restores PG from backup JSON
- Added npm scripts: `db:backup`, `db:restore`
- Ran backup → restore → verify rehearsal (PASS)
- Verified all 127 tests pass
- Produced persistence test matrix (15 items, 13 PASS, 2 available)
- Produced final closeout document with close recommendation

---

## 2. What still exists in JSON tooling

| Item | Purpose | Active? |
|---|---|---|
| `DevStorePersistence` class | Test isolation + emergency fallback | Only when `PERSISTENCE_BACKEND=json` (explicit) |
| `test/jest-env-setup.ts` | Forces JSON for test isolation | Yes (tests only) |
| `scripts/db/import-json.ts` | One-time JSON→PG migration tool | Retained |
| `data/dev-store-state.json` | Legacy snapshot (read-only) | Not written to during PG operation |
| `scripts/db/backup.ts` | Export PG to JSON | New (A5) |
| `scripts/db/restore.ts` | Restore PG from JSON | New (A5) |

---

## 3. What is now fully PG runtime truth

**Everything.** When `PERSISTENCE_BACKEND=pg` (default):
- All DevStore state reads from PG on startup
- All DevStore mutations save to PG
- Today, secondary summary, inventory, equipment, feed, purchase, study, review, session, check-in, settlement, idempotency — ALL through PG
- No JSON writes occur during normal operation
- Missing DATABASE_URL causes startup error (not silent fallback)

---

## 4. What technical debt remains

| # | Debt | Severity |
|---|---|---|
| TD-01 | Full snapshot save (delete-all + re-insert on every mutation) | Medium |
| TD-02 | Fire-and-forget PG save (async, not awaited) | Medium |
| TD-03 | Tests use JSON backend, not PG | Low |
| TD-04 | Maintenance mode not gating write controllers | Low |
| TD-05 | Single-user model (hardcoded dev-user-001) | Low |

---

## 5. What Room 1 should decide next

1. **Accept Option A close** — all A0-A5 slices complete
2. **Choose next direction**:
   - Incremental PG writes (performance optimization)
   - E2e tests on PG (test fidelity)
   - Multi-user support (production readiness)
   - New feature phase (visual polish, social, etc.)

---

## 6. What not to touch

- Do NOT remove `PgDevStorePersistence` — it's the active runtime truth
- Do NOT change `PERSISTENCE_BACKEND` default from `'pg'`
- Do NOT remove migration/seed infrastructure
- Do NOT modify schema without new migration files
- Do NOT add business logic to JSON tooling scripts

---

## 7. Files / modules to read first

1. `apps/api/src/domain/persistence-factory.ts` — Hardened factory (A5)
2. `apps/api/src/infrastructure/postgres/pg-persistence.ts` — PG adapter
3. `apps/api/scripts/db/backup.ts` — Backup script (A5)
4. `apps/api/scripts/db/restore.ts` — Restore script (A5)
5. `docs/R4_OptionA_final_closeout_v0.1.md` — Close recommendation
6. `docs/R4_OptionA_persistence_test_matrix_v0.1.md` — Test coverage

---

## 8. Current risks

1. **Full snapshot save**: At dev scale fine. Production with many records needs incremental writes.
2. **Tests don't validate PG path**: Business logic tested via JSON. PG path verified via roundtrip only. Risk: PG adapter bug not caught by e2e tests.
3. **Fire-and-forget save**: If PG write fails, in-memory state is correct but PG diverges. Logged but not propagated.

---

## 9. Recommended next prompt focus

> "Room 1 has reviewed Option A closeout. Decision: [accept close]. Next direction: [incremental PG writes / e2e on PG / multi-user / new feature phase]."
