# Cursor Round Summary — Option A.1, H3

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Implemented **Option A.1 H3: Fire-and-forget PG save hardening**.

- Created `PersistenceFailureError` custom error class for structured failure wrapping
- Created `PersistenceFailureFilter` global exception filter returning `PERSISTENCE_FAILURE` code
- Updated `saveToDiskAsync()` to wrap errors in `PersistenceFailureError`
- Registered `PersistenceFailureFilter` globally in `main.ts`
- Added 12 H3 tests: 6 normal success, 1 error structure, 4 ensurePersisted verification, 1 documentation
- All 181 tests pass across all suites

---

## 2. What high-value writes now require confirmed PG persistence

**All 10 write controller methods** call `await repositories.ensurePersisted()` before returning success:

| Controller | Method |
|---|---|
| StudyAttemptsController | submitStudyAttempt |
| ReviewAttemptsController | submitReviewAttempt |
| SessionsController | startSession |
| SessionsController | finishSession |
| CheckInsController | checkIn |
| SettlementsController | createSettlement |
| FeedController | feed |
| ShopController | purchase |
| EquipmentController | equip |
| EquipmentController | unequip |

---

## 3. What failure semantics are now enforced

When PG save fails:
- `devStore.saveToDiskAsync()` throws `PersistenceFailureError`
- `PersistenceFailureFilter` catches it and returns HTTP 500 with:
```json
{
  "ok": false,
  "error": {
    "code": "PERSISTENCE_FAILURE",
    "message": "The operation completed in memory but failed to persist to database.",
    "retryable": true,
    "details": { "persistence_failed": true }
  }
}
```
- UI can distinguish "persistence failure" from "user error" or "maintenance mode"
- No fake success possible

---

## 4. What is still not covered

- **Full snapshot save** (delete-all + re-insert): Still the save strategy. Medium tech debt. Future optimization.
- **Single-user model**: Low. Future phase.
- **PG pool cleanup in PG tests**: Jest "did not exit" warning. Cosmetic.

---

## 5. What must be done next

**Option A.1 is complete.** All 3 hardening items (H1+H2+H3) are done.

Room 1 should decide:
1. Accept Option A.1 close
2. Choose next direction: incremental PG writes / new feature phase / production deployment prep

---

## 6. What not to touch

- Do NOT remove `PersistenceFailureFilter` — it's the structured error handler
- Do NOT remove `ensurePersisted()` from write controllers
- Do NOT revert to fire-and-forget save
- Do NOT change the serialized save chain

---

## 7. Files / modules to read first

1. `apps/api/src/middleware/persistence-failure.filter.ts` — PersistenceFailureError + filter
2. `apps/api/src/domain/dev-store.ts` — `saveToDiskAsync()` with PersistenceFailureError wrapping
3. `apps/api/test/save-hardening.e2e-spec.ts` — 12 H3 tests
4. `docs/R4_OptionA1_Hardening_Status_v0.1.md` — Full H1-H3 status
5. `docs/R4_OptionA1_Hardening_Test_Summary_v0.1.md` — Complete test matrix

---

## 8. Current risks

1. **Full snapshot save at scale**: Every mutation does delete-all + re-insert. Fine for dev. Needs optimization for production scale.
2. **Shared dev DB for PG tests**: meow_dev used by both dev server and PG tests. Low risk in single-user mode.

---

## 9. Recommended next prompt focus

> "Room 1 accepts Option A.1 close. All 3 hardening items (H1: degraded-state gating, H2: PG regression, H3: save hardening) are complete. 181 tests pass. Next direction: [incremental PG writes / new feature phase / production deployment prep]."
