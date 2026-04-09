# P3 — Main Mechanism Deepening: Final Closeout Summary

**Date**: 2026-04-06
**Owner**: Room 4
**Status**: P3 Complete — Recommend close

---

## 0. One-line

> P3 deepened CTA, Review, Statistics, and Streak boundaries without breaking existing truth layers or smuggling in unconfirmed contracts.

---

## 1. What P3 Did (Phase by Phase)

### Phase 0 — Baseline-safe Entry / Guard / Test Seam
- Hardened `TodayState.fromJson` (8 fields crash-safe with null defaults)
- Created `P3FeatureGuard` compile-time constants (5 flags, all `false`)
- Created shared test fixtures (`P3JsonFixtures`, `P3ModelFixtures`)
- Created 19 guard regression tests + 4 backend guard e2e tests
- **No features. Only safety layer.**

### Phase 1 — CTA Deepening
- Added `TodayPrimaryAction` contract to backend (`action` + `reason`)
- Backend `computeTodayPrimaryAction()` — 4-priority decision-support
- Frontend `TodayPrimaryActionData.tryParse()` — strict parsing (unknown/incomplete = null)
- Today CTA: contract-driven when present, Option C baseline when absent
- Reason line displayed as weak supporting hint
- `priority_band` / `blocking_condition` explicitly NOT implemented
- 4 widget tests + 1 e2e test

### Phase 2 — Review Structured Deepening
- Added `ReviewSummary` contract to backend (group progress, daily progress, readiness)
- Backend `computeReviewSummary()` — aggregates from existing truth layers
- Frontend `ReviewSummaryData.tryParse()` — strict parsing
- Today page: review deeper block shows group + daily progress, falls back to C2 when absent
- Review page: enhanced completion messaging with 3-layer boundary text
- `active_group_completed` is **never** displayed as "today review complete"
- `next_group_readiness` is backend-driven, not inferred from remaining count
- 9 parsing tests + 3 e2e tests

### Phase 3 — Statistics Decision Path
- Chose **Path A: summary-first** (no independent statistics page)
- Hardened stats summary card: empty state, unavailable state, normal state
- Added truth-boundary sub-labels: "有效学习日" for learning_days, "独立于学习日" for check_ins
- Streak in stats explicitly labeled "(基于签到)"
- 9 regression tests (summary-first safety + state matrix)

### Phase 4 — Streak Decision Preparation
- Created `StreakDisplay` shared helper — centralized streak label formatting
- Replaced 4 inline streak label duplications with shared helper
- Added `P3FeatureGuard.isStreakExplanationEnabled = false` — future explanation seam
- No streak basis switch. No backfill. No "learning_day-based streak" copy.
- 8 regression tests (display helper + truth-boundary)

---

## 2. What P3 Did NOT Do

| Item | Status | Why |
|---|---|---|
| Switch `streak_basis_type` to `learning_day` | Not done | Room 1 has not pinned |
| Create `/statistics` route or independent page | Not done | Room 1 has not pinned |
| Implement `priority_band` / `blocking_condition` | Not done | Not in Phase 1 scope |
| Implement complete SRS / review priority engine | Not done | Not in P3 scope |
| Create backfill / grace period for streak | Not done | Not in P3 scope |
| Treat candidate BR v0.1.7 as active | Not done | Governance discipline |
| Treat candidate UI OptionC spec as active | Not done | Governance discipline |

---

## 3. Close Bar

| # | Check | Result |
|---|---|---|
| 1 | P3 Phase 0–4 all completed | ✅ |
| 2 | No candidate input treated as active truth | ✅ |
| 3 | No new route / contract / business surface smuggled in | ✅ |
| 4 | All 230 tests pass | ✅ |
| 5 | Runtime truth not polluted by future stance | ✅ |
| 6 | CTA single-winner preserved | ✅ |
| 7 | Continuation-first preserved | ✅ |
| 8 | Summary-first preserved | ✅ |
| 9 | learning_day / check_in / streak separated | ✅ |
| 10 | streak_basis_type = check_in preserved | ✅ |

---

## 4. Test Summary

| Suite | Count | Status |
|---|---|---|
| Flutter widget tests | 132 | All pass |
| Flutter analyze | 67 info | 0 errors |
| Backend unit tests | 16 | All pass |
| Backend e2e tests | 82 | All pass |
| **Total** | **230** | **All pass** |

### Tests added during P3

| Phase | Tests | Type |
|---|---|---|
| Phase 0 | 19 Flutter + 4 e2e | Guards, null-safety, feature flags |
| Phase 1 | 4 Flutter + 1 e2e | CTA contract present/absent |
| Phase 2 | 9 Flutter + 3 e2e | Review summary parsing + boundary |
| Phase 3 | 9 Flutter | Summary-first safety + state matrix |
| Phase 4 | 8 Flutter | Streak display helper + truth-boundary |
| **P3 total new** | **49 Flutter + 8 e2e = 57** | |

---

## 5. Files Created / Modified in P3

### New files
| File | Phase | Purpose |
|---|---|---|
| `apps/mobile/lib/core/guards/p3_feature_guard.dart` | P0 | Feature guard constants (5 flags, all false) |
| `apps/mobile/lib/core/guards/guards.dart` | P0 | Barrel export |
| `apps/mobile/lib/shared/helpers/streak_display.dart` | P4 | Centralized streak display helper |
| `apps/mobile/test/fixtures/p3_test_fixtures.dart` | P0 | Shared test fixtures |
| `apps/mobile/test/p3_phase0_guard_test.dart` | P0 | Guard + boundary regression tests (expanded P1-P4) |

### Modified files
| File | Phases | Changes |
|---|---|---|
| `apps/api/src/domain/types.ts` | P1, P2 | Added `TodayPrimaryAction`, `ReviewSummary`, `StatsSummary` types |
| `apps/api/src/domain/dev-store.ts` | P1, P2, C3 | Added `computeTodayPrimaryAction()`, `computeReviewSummary()`, `buildStatsSummary()` |
| `apps/mobile/lib/core/api/api_client.dart` | P0, P1, P2 | Null-safety hardening + `TodayPrimaryActionData` + `ReviewSummaryData` |
| `apps/mobile/lib/core/core.dart` | P0 | Added guards export |
| `apps/mobile/lib/features/today/today_page.dart` | P1, P2, P4 | CTA contract-driven + review deeper block + streak shared helper |
| `apps/mobile/lib/features/review/review_page.dart` | P2 | Enhanced 3-layer boundary messaging |
| `apps/mobile/lib/features/meow_home/meow_home_page.dart` | P3, P4 | Stats state matrix + streak shared helper |
| `apps/api/test/app.e2e-spec.ts` | P0, P1, P2 | Guard + contract presence e2e tests |
| `apps/mobile/test/today_page_test.dart` | P1, C2 | CTA contract + review boundary widget tests |

---

## 6. Backend Contract Changes in P3

| Field | Added to | Phase | Shape |
|---|---|---|---|
| `today_primary_action` | `GET /me/today` | P1 | `{ action, reason }` |
| `review_summary` | `GET /me/today` | P2 | `{ has_active_group, active_group_progress, active_group_completed, daily_review_progress, next_group_readiness }` |
| `stats_summary` | `GET /me/secondary-summary` | C3 (pre-P3) | `{ total_learning_days, total_words_learned, total_review_groups_completed, total_check_ins, current_streak, streak_basis }` |

All are **additive optional fields** on existing endpoints. No new endpoints created. No existing fields modified.

---

## 7. P3 Feature Guards (all false)

| Guard | Purpose | Value |
|---|---|---|
| `isStatisticsPageEnabled` | Independent stats route + nav | `false` |
| `isCTADecisionSupportEnabled` | CTA contract consumption (already active via Phase 1, guard retained for reference) | `false` |
| `isStreakBasisSwitchEnabled` | Streak basis switch to learning_day | `false` |
| `isReviewReadinessContractEnabled` | Deeper review readiness contract | `false` |
| `isStreakExplanationEnabled` | Future streak policy explanation block | `false` |

---

## 8. Residual Risk

| Risk | Level | Details |
|---|---|---|
| Copy polish needed | Non-blocking | Sub-labels ("有效学习日", "独立于学习日") are functional, Room 5 may refine |
| `todayReviewPending` may be 0 | Non-blocking | CTA falls through to new words safely |
| `learning_days` historical undercount | Non-blocking | Only counts days where `updateLearningDay()` was called |
| PG environment needs re-seed | Non-blocking | New items + contracts need `npm run db:seed` |

---

## 9. Recommendation

> **Close P3.** All 5 phases (0-4) complete, 230 tests pass, 10/10 close bar items pass, zero candidate inputs treated as active truth, zero scope creep. This is a clean, boundary-respecting delivery package.
