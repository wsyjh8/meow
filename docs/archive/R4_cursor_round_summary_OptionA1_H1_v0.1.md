# Cursor Round Summary — Option A.1, H1

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Implemented **Option A.1 H1: Maintenance / Degraded-State Gating**.

- Enhanced `MaintenanceGuardMiddleware` to check 3 independent env-based states
- `MAINTENANCE_MODE`, `READ_ONLY_MODE`, `TEMPORARILY_UNAVAILABLE` each produce distinct error codes
- Middleware registered globally — covers all POST/PUT/PATCH/DELETE endpoints
- Updated health endpoint to show all three degraded states
- Added 22 H1 e2e tests covering all write paths and all degraded states
- All 159 tests pass (16 unit + 67 JSON e2e + 22 H1 + 10 PG e2e + 44 Flutter)

---

## 2. What write paths are now gated

**All 10 write controller methods across 8 controllers:**
- study submit, review submit, session start/finish, check-in, settlement
- feed, purchase, equip, unequip

Gating is via global NestJS middleware — no per-controller if/else needed.

---

## 3. What degraded-state semantics are now enforced

| Env Var | Error Code | HTTP | Retryable |
|---|---|---|---|
| `MAINTENANCE_MODE=true` | `MAINTENANCE_MODE_ACTIVE` | 503 | Yes |
| `READ_ONLY_MODE=true` | `READ_ONLY_MODE_ACTIVE` | 503 | Yes |
| `TEMPORARILY_UNAVAILABLE=true` | `TEMPORARILY_UNAVAILABLE` | 503 | Yes |

All responses include structured `{ ok: false, error: { code, message, retryable, details } }`.

---

## 4. What is still not covered

- Degraded state is env-based only (requires process restart to toggle)
- Some degraded-state + specific-endpoint combos don't have dedicated tests (covered by global middleware)
- H2 (PG-path regression) and H3 (save hardening) are not started

---

## 5. What must be done next

**H2 — PG-path e2e / regression**: Expand PG backend tests to cover more business chains. Current PG e2e has 10 tests from focused patch.

**H3 — fire-and-forget save hardening**: Serialized save chain already exists; H3 may refine edge cases.

---

## 6. What not to touch

- Do NOT remove `MaintenanceGuardMiddleware` — it's the unified write gating seam
- Do NOT change the 503 status code or response structure
- Do NOT make degraded state bypass-able per controller
- Do NOT start H2/H3 without instruction

---

## 7. Files / modules to read first

1. `apps/api/src/middleware/maintenance.guard.ts` — The gating middleware (3 states, helpers exported)
2. `apps/api/src/controllers/health.controller.ts` — Health endpoint with degraded state info
3. `apps/api/test/degraded-state.e2e-spec.ts` — 22 H1 tests
4. `apps/api/src/app.module.ts` — Where middleware is registered globally

---

## 8. Current risks

1. **Env-based only**: Toggling degraded state requires setting env vars + restart. No runtime API to toggle.
2. **No UI integration**: Flutter doesn't yet parse the 503 degraded-state responses (would need work if shown to users).

---

## 9. Recommended next prompt focus

> "Implement Option A.1 H2: PG-path e2e / regression hardening. Expand PG backend test coverage for key business chains."
