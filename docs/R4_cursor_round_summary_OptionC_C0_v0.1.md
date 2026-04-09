# Cursor Round Summary — Option C, C0

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Completed **Option C / C0 / Entry sync / active-version pin check**. This was an **audit-only round — zero code changes**. Not C1-C5.

- Audited all governance documents: active vs candidate classification
- Checked all 3 very small contract clarifications in codebase
- Verified code reality against governance truth
- Built C1-C5 readiness table with path recommendations
- Generated 3 deliverable docs

---

## 2. What is runtime active truth

| Category | Active Document |
|---|---|
| BR / Rules | `BR-OPP-001_v0.1.5.md` |
| DB Design | `背单词喵喵app_DB设计草案_v0.1.4.md` |
| API Design | `背单词喵喵app_API设计草案_v0.1.3.md` |
| UI Spec | `UI_SPEC_OptionB_v0.1.2.md` |
| PRD | `背单词喵喵app_主机制prd_v0.3.md` |

---

## 3. What is candidate only

| Document | Status |
|---|---|
| `BR-OPP-001_v0.1.7.md` | Candidate — Room 3 sync patch, NOT active |
| `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` | Candidate — Room 5 input, NOT active |
| `R1_OptionC_Formal_Handoff_Pack_v0.1.md` | Candidate — Room 1 handoff |
| `R2_OptionC_MainMechanism_Preflight_v0.1.1.md` | Candidate — Room 2 judgment |
| `R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md` | Candidate — Room 4 plan |
| `optionc_phases.md` | Candidate — Room 4 phase map |

**None of these are runtime active truth. Do not implement against them without Room 1 pin.**

---

## 4. Which clarifications are entered or not

| Clarification | Status |
|---|---|
| Today decision-support block (`today_primary_action`) | **NOT PRESENT** |
| Review/group summary contract | **NOT PRESENT** |
| Minimal stats summary contract | **NOT PRESENT** |

All three = not present in codebase. Conservative paths (Path A) required for all phases.

---

## 5. What the biggest misread risks are

1. **Candidate BR treated as active**: `BR-OPP-001_v0.1.7.md` has Option C rules but is NOT pinned. Don't implement v0.1.7-only rules.
2. **Candidate UI treated as active**: `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` defines new layouts but active baseline is still OptionB.
3. **Unpinned clarifications assumed present**: None of the 3 contract clarifications exist in code. Don't write code against `today_primary_action` or stats endpoints.
4. **`streak_basis_type` type misread**: The `'learning_day'` variant in the TypeScript type is a placeholder. Runtime is always `'check_in'`. Don't flip the switch.

---

## 6. What is still not decided

- Room 1 has not yet pinned BR v0.1.7 or UI OptionC spec
- Room 1 has not confirmed which (if any) of the 3 contract clarifications enter
- Independent statistics page is not pinned
- Future streak basis switch direction is pending

---

## 7. What must be done next

**C1: Today CTA Winner — Path C1-A (conservative).**

Conservative CTA winner logic using existing active fields:
1. `active_review_group_id != null` AND `remaining > 0` → "Continue review group" (continuation-first)
2. `today_review_pending > 0` (no active group) → "Start review"
3. `daily_goal_status == 'completed'` → "Today's goal completed"
4. Otherwise → "Start/continue word learning"

This requires modifying `today_page.dart` CTA section only, using existing `TodayState` fields.

---

## 8. What not to touch

- Don't treat BR v0.1.7 as active truth
- Don't treat UI OptionC spec as active baseline
- Don't create `today_primary_action` field
- Don't create stats endpoint
- Don't flip `streak_basis_type` to `'learning_day'`
- Don't modify backend business logic in C1
- Don't assume any contract clarification exists

---

## 9. Files / modules to read first

### For C1 (Today CTA Winner)
1. `apps/mobile/lib/features/today/today_page.dart` — Current CTA logic (lines 160-198)
2. `apps/api/src/domain/types.ts` — `TodayState` interface (lines 158-186)
3. `apps/api/src/controllers/today.controller.ts` — Today endpoint
4. `apps/api/src/domain/dev-store.ts` — `getTodayState()`, `getOrCreateReviewGroup()`
5. `docs/baseline-summary.md` — Frozen rules (review_group contract, check_in/streak independence)

### For C2 (Review Continuation)
6. `apps/api/src/controllers/review-groups.controller.ts` — Review endpoint
7. `apps/api/src/domain/dev-store.ts` — `getOrCreateReviewGroup()`, review-related methods

---

## 10. Current blockers / assumptions / risks

- `Assumption (temporary, not frozen): All C1-C4 phases proceed via conservative Path A`
- `Assumption (temporary, not frozen): streak_basis_type remains 'check_in' throughout Option C`
- `Assumption (temporary, not frozen): baseline-summary.md frozen rules are safe foundation for implementation`
- `Blocked if touched: Do not pin candidate inputs as active truth — Room 1 authority only`
- `Blocked if touched: Do not create today_primary_action, stats endpoint, or flip streak basis`
- Risk: If Room 1 pins v0.1.7 / OptionC UI mid-implementation, Path B may become available — but don't assume this
- Risk: C3 (statistics) is CONDITIONAL — only enters if Room 1 confirms statistics is in scope

---

## 11. Whether ready for C1

**YES.** Path C1-A (conservative, no new contract patch).

The existing `TodayState` fields (`daily_goal_status`, `active_review_group_id`, `active_review_group_remaining`, `today_review_pending`) are sufficient to implement a single-strongest-CTA with review-continuation-first, using only the current active API baseline and frozen rules from `baseline-summary.md`.
