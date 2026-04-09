# Option B Test Entry v0.1

**Date**: 2026-04-04
**Purpose**: Define test entry points for Option B Phase 1-5

---

## 1. Current Test Baseline

| Suite | Count | Status |
|---|---|---|
| Flutter widget tests | 44 | All pass |
| Flutter analyze | 19 info hints | 0 errors |
| Backend unit | 16 | All pass |
| Backend e2e (JSON) | 67 | All pass |
| Backend e2e (PG) | 20 | All pass |
| H1 degraded-state | 22 | All pass |
| H3 save hardening | 12 | All pass |
| **Total** | **181** | **All pass** |

---

## 2. Test Entry by Phase

### Phase 1: Global Theme + Shared Widgets

| What to Test | How | File |
|---|---|---|
| App theme applies correctly | Verify MaterialApp uses new ThemeData | `test/app_test.dart` |
| MeowCard renders with correct style | Widget test with expected border radius, colors | NEW `test/shared/meow_card_test.dart` |
| MeowChip renders states correctly | Widget test for each state variant | NEW `test/shared/meow_chip_test.dart` |
| Theme colors accessible | Unit test for color constants | NEW `test/shared/theme_test.dart` |

### Phase 2: Meow Home Redesign

| What to Test | How | File |
|---|---|---|
| Loading state renders | Keep existing test, update expected structure | `test/meow_home_page_test.dart` |
| Normal state shows cat, resources, growth | Update to check new layout keys | `test/meow_home_page_test.dart` |
| Feed button still works | Keep feed tests, update button key if needed | `test/meow_home_page_test.dart` |
| Level-up dialog still shows | Keep level-up tests | `test/meow_home_page_test.dart` |
| Companion copy displays | Keep companion tests, update card structure | `test/meow_home_page_test.dart` |
| Equipped items display | Keep equipped tests, update format | `test/meow_home_page_test.dart` |
| Interaction button responds | NEW test for frontend local feedback | `test/meow_home_page_test.dart` |
| Error state still works | Keep error/retry tests | `test/meow_home_page_test.dart` |

### Phase 3: Today Companion Card

| What to Test | How | File |
|---|---|---|
| Today page renders with Companion Card | Update expected structure | `test/today_page_test.dart` |
| Main CTA still primary visual | Verify CTA button prominence | `test/today_page_test.dart` |
| Companion Card doesn't overpower CTA | Visual hierarchy test | `test/today_page_test.dart` |

### Phase 4: Customize Upgrade

| What to Test | How | File |
|---|---|---|
| Three-state rendering | Verify unowned/owned/equipped visual | NEW or update tests |
| Top preview area exists | Widget test for preview section | NEW test |
| Tabs work correctly | Verify tab switching | NEW test |
| Purchase still works | Keep existing purchase flow | Existing tests |
| Equip/unequip still works | Keep existing equip flow | Existing tests |

### Phase 5: Companion Copy Expansion

| What to Test | How | File |
|---|---|---|
| Expanded greetings return valid strings | Backend unit test | `test/app.e2e-spec.ts` (existing companion tests) |
| Random selection works | Verify different greetings on multiple calls | Backend test |
| No greeting is empty/null | Verify all variants are non-empty | Backend test |

---

## 3. Guardrails That Must Be Continuously Regressed

| Guardrail | How Verified | Current Tests |
|---|---|---|
| Reads allowed during maintenance | H1 tests | 22 pass |
| Writes blocked during maintenance | H1 tests | 22 pass |
| PG persistence confirmed before success | H3 tests + PG e2e | 32 pass |
| No mixed source (PG/JSON) | PG e2e suite | 20 pass |
| `ensurePersisted()` in all write controllers | H3 documentation test | 12 pass |
| Feed insufficient resource handled | meow_home_page_test | Existing |
| Level-up only when threshold crossed | meow_home_page_test | Existing |
| Companion copy null-safe | meow_home_page_test | Existing |

---

## 4. Truth Boundaries UI Must Not Cross

| Boundary | Rule | Test Verification |
|---|---|---|
| `delayed snapshot ≠ fresh truth` | Never display stale data as current | Manual review during each phase |
| `pending reward ≠ 到账成功` | Only show confirmed settlements | Existing settlement tests |
| `interaction click ≠ business fact` | Interaction feedback is pure frontend | No backend call made — verified by test |
| `UI change ≠ backend confirmed` | All displayed state from API response | Widget tests mock API data, not local state |
| `maintenance mode = write rejected` | 503 structured response | H1 test suite |

---

## 5. Test Update Strategy

### Keep
- All backend tests (181) — B1 has no backend API changes
- API model parse tests — data structures unchanged
- PG regression tests — backend unaffected

### Update
- `meow_home_page_test.dart` — new Keys, new structure, new expectations
- `today_page_test.dart` — Companion Card structure change
- `app_test.dart` — theme verification

### Add
- Shared widget tests (MeowCard, MeowChip, theme)
- Interaction button frontend feedback test
- Customize tabs/preview tests

### Must Pass Before Each Phase Closes
```bash
flutter test          # All widget tests pass
flutter analyze       # 0 errors
npm test              # Backend unit tests unaffected
npm run test:e2e      # Backend e2e unaffected
```
