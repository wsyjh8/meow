# Option A.1 Hardening Test Summary v0.1

**Date**: 2026-04-04
**Phase**: H1

---

## 1. Write Controllers with Degraded-State Gating

| Controller | Write Method | Gated? | Tested? |
|---|---|---|---|
| StudyAttemptsController | submitStudyAttempt | Yes (middleware) | Yes — maintenance, read_only |
| ReviewAttemptsController | submitReviewAttempt | Yes (middleware) | Yes — maintenance |
| SessionsController | startSession | Yes (middleware) | Yes — maintenance |
| SessionsController | finishSession | Yes (middleware) | Yes — temporarily_unavailable |
| CheckInsController | checkIn | Yes (middleware) | Yes — maintenance, temporarily_unavailable |
| SettlementsController | createSettlement | Yes (middleware) | Yes — maintenance |
| FeedController | feed | Yes (middleware) | Yes — maintenance, temporarily_unavailable |
| ShopController | purchase | Yes (middleware) | Yes — maintenance, read_only |
| EquipmentController | equip | Yes (middleware) | Yes — maintenance |
| EquipmentController | unequip | Yes (middleware) | Yes — maintenance |

**10/10 write methods gated. 10/10 tested with at least one degraded state.**

---

## 2. Test Coverage by Degraded State

| State | Env Var | Error Code | Tests |
|---|---|---|---|
| Maintenance | `MAINTENANCE_MODE=true` | `MAINTENANCE_MODE_ACTIVE` | 13 tests (9 write blocks + state-no-advance + no-rewards + reads-allowed + health) |
| Read-only | `READ_ONLY_MODE=true` | `READ_ONLY_MODE_ACTIVE` | 3 tests (study block + purchase block + health) |
| Temporarily unavailable | `TEMPORARILY_UNAVAILABLE=true` | `TEMPORARILY_UNAVAILABLE` | 4 tests (feed block + session block + check-in block + health) |
| Normal | (none) | N/A | 2 tests (writes work + health ok) |

**Total: 22 H1 tests**

---

## 3. Verified Guarantees

| Guarantee | How Verified |
|---|---|
| No fake success | All blocked writes return 503, not 200 |
| No generic error | Error code is specific (not INTERNAL_SERVER_ERROR) |
| No state advancement | Today state unchanged after blocked study attempt |
| No reward generation | Coins unchanged after blocked settlement |
| Reads allowed | 5 GET endpoints verified accessible during maintenance |
| Retryable flag | All degraded responses include `retryable: true` |
| Details object | All responses include `details.maintenance`, `details.read_only`, `details.temporarily_unavailable` |

---

## 4. Paths Not Yet Covered by Additional Testing

| Path | Status | Notes |
|---|---|---|
| Session finish during read_only | Not explicitly tested | Middleware covers it (global), but no dedicated test |
| Settlement during temporarily_unavailable | Not explicitly tested | Same |
| Equip/unequip during read_only | Not explicitly tested | Same |

These are covered by the global middleware, so they are functionally gated. Dedicated tests can be added if needed.

---

## 5. Remaining Technical Debt

| # | Debt | Severity |
|---|---|---|
| TD-01 | Degraded state is env-based only (not runtime-toggleable) | Low |
| TD-02 | Full snapshot save (from Option A) | Medium |
| TD-03 | Single-user model | Low |

---

## 6. H2 — PG-Path E2E Regression (20 tests)

### PG-path tests (`npm run test:e2e:pg`)

| # | Chain | Test | Status |
|---|---|---|---|
| PG-01 | Today read | GET /me/today valid structure | PASS |
| PG-02 | Summary read | GET /me/secondary-summary valid structure | PASS |
| PG-03 | Purchase→inventory | Purchase + inventory read + summary coins | PASS |
| PG-04 | Equip→equipment | Equip + snapshot + summary preview | PASS |
| PG-05 | Feed→summary | Feed + exp increase | PASS |
| PG-06 | Study+settlement | Study attempt + settlement + coins | PASS |
| PG-07 | Check-in+streak | Check-in + streak + today state | PASS |
| PG-08 | Inventory read | Empty inventory structure | PASS |
| PG-09 | Equipment read | Empty equipment structure | PASS |
| PG-10 | Unequip | Purchase + equip + unequip | PASS |
| PG-11 | Review group+attempt | Create group + submit attempt | PASS |
| PG-12 | Session start/finish | Start + read + finish | PASS |
| PG-13 | Learning round→today | Study → today progress → summary | PASS |
| PG-14 | Idem: settlement | Replay same key → no double reward | PASS |
| PG-15 | Idem: purchase | Replay same key → no duplicate item | PASS |
| PG-16 | Review completion→settlement | All items → settlement → fish treats | PASS |
| PG-17 | Companion response | Greeting changes after check-in | PASS |
| PG-18 | Maintenance: block write | POST /me/feed → 503 | PASS |
| PG-19 | Maintenance: allow read | GET today + summary → 200 | PASS |
| PG-20 | Maintenance: health | Health shows maintenance status | PASS |

### Test DB strategy
- Database: meow_dev (localhost:5432)
- Isolation: `devStore.reset()` before each test (clears PG user state via `clearAsync`)
- Static data preserved: users, words, catalog, pet_profile, wallet, streak (seeded)
- PG tests run via `npm run test:e2e:pg` (separate jest config, no JSON forcing)

### Chains still JSON-only
- 67 JSON e2e tests covering full P1/P2 business logic breadth
- These validate business rules independent of persistence backend
- Not blocking H3 — they serve as logic regression, PG tests serve as persistence regression

---

## 7. H3 — Save Hardening Tests (12 tests)

### Save hardening tests (`npm run test:e2e:h3`)

| # | Test | Status |
|---|---|---|
| SH-01 | Feed normal save → success | PASS |
| SH-02 | Purchase normal save → success | PASS |
| SH-03 | Study attempt normal save → success | PASS |
| SH-04 | Check-in normal save → success | PASS |
| SH-05 | Equip normal save → success | PASS |
| SH-06 | Settlement normal save → success | PASS |
| SH-07 | PersistenceFailureError wraps correctly | PASS |
| SH-08 | Review attempt has ensurePersisted | PASS |
| SH-09 | Session start has ensurePersisted | PASS |
| SH-10 | Session finish has ensurePersisted | PASS |
| SH-11 | Unequip has ensurePersisted | PASS |
| SH-12 | 10/10 write methods documented with ensurePersisted | PASS |

### High-value write paths — persistence confirmed

| Controller | Method | ensurePersisted? | Tested? |
|---|---|---|---|
| StudyAttemptsController | submitStudyAttempt | Yes | SH-03 |
| ReviewAttemptsController | submitReviewAttempt | Yes | SH-08 |
| SessionsController | startSession | Yes | SH-09 |
| SessionsController | finishSession | Yes | SH-10 |
| CheckInsController | checkIn | Yes | SH-04 |
| SettlementsController | createSettlement | Yes | SH-06 |
| FeedController | feed | Yes | SH-01 |
| ShopController | purchase | Yes | SH-02 |
| EquipmentController | equip | Yes | SH-05 |
| EquipmentController | unequip | Yes | SH-11 |

**10/10 high-value write methods confirmed.**

### Failure propagation
- `PersistenceFailureError` wraps PG errors with structured metadata
- `PersistenceFailureFilter` global filter catches and returns `{ ok: false, error: { code: "PERSISTENCE_FAILURE" } }`
- Request returns 500, not 200 — UI cannot mistake this for success

### Complete test totals (all suites)

| Suite | Command | Count | Backend |
|---|---|---|---|
| Unit | `npm test` | 16 | N/A |
| JSON e2e | `npm run test:e2e` | 67 | JSON |
| PG regression | `npm run test:e2e:pg` | 20 | PG |
| H1 degraded-state | `npm run test:e2e:h1` | 22 | JSON |
| H3 save hardening | `npm run test:e2e:h3` | 12 | JSON |
| Flutter | `flutter test` | 44 | N/A |
| **Total** | | **181** | |
