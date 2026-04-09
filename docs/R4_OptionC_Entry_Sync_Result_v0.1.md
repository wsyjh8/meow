# Option C — Entry Sync Result v0.1

**Date**: 2026-04-05
**Phase**: C0 — Entry Sync / Active-Version Pin Check
**Purpose**: Factual mapping of active truth vs candidate input for Option C

---

## 1. Active Truth vs Candidate Input Matrix

| Category | Document | Status | Notes |
|---|---|---|---|
| Main Mechanism PRD | `背单词喵喵app_主机制prd_v0.3.md` | **Runtime active** | Unchanged |
| Secondary Mechanism PRD | `背单词喵喵app_副机制prd_v_0.md` | **Runtime active** | Unchanged |
| Project Rules | `PROJECT_RULES_MASTER_v0.3.1.md` | **Runtime active** | Unchanged |
| BR / Rules | `BR-OPP-001_v0.1.5.md` | **Runtime active** | Current active BR baseline per Room 1 |
| BR / Rules | `BR-OPP-001_v0.1.7.md` | **Candidate only** | Room 3 sync patch for Option C, ready for Room 1 review. NOT replacing v0.1.5 |
| DB Design | `背单词喵喵app_DB设计草案_v0.1.4.md` | **Runtime active** | Current active DB baseline |
| API Design | `背单词喵喵app_API设计草案_v0.1.3.md` | **Runtime active** | Current active API baseline |
| UI Spec | `UI_SPEC_OptionB_v0.1.2.md` | **Runtime active** | Current runtime active UI baseline |
| UI Spec | `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` | **Candidate only** | Room 5 Option C UI input. NOT replacing OptionB v0.1.2 |
| UI Spec | `UI_SPEC_v0.1.4.md` | **Retained reference** | Option A / persistence guardrail reference |
| Plan / Test | `plan_v0.1.2.md` | **Runtime active** | Current plan baseline |
| Plan / Test | `TEST_PLAN_v0.1.2.md` | **Runtime active** | Current test baseline |
| Room 1 Handoff | `R1_OptionC_Formal_Handoff_Pack_v0.1.md` | **Candidate only** | Room 1 handoff for Option C |
| Room 2 Preflight | `R2_OptionC_MainMechanism_Preflight_v0.1.1.md` | **Candidate only** | "Go with contract-first clarification" judgment |
| Room 4 Plan | `R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md` | **Candidate only** | Room 4 planning input |
| Room 4 Phases | `optionc_phases.md` | **Candidate only** | Room 4 phase map for Cursor |

---

## 2. Very Small Clarifications Status Matrix

| # | Clarification | Status | Evidence | Implication |
|---|---|---|---|---|
| 1 | Today decision-support block (`today_primary_action` or equivalent) | **NOT PRESENT** | `TodayState` in `types.ts` (lines 158-186) has no decision-support field. `TodayController` returns raw state. Frontend `today_page.dart` (lines 187-191) decides CTA purely from `dailyGoalStatus` 3-branch. | C1 must use Path C1-A (conservative): build CTA winner from existing fields only |
| 2 | Review/group summary contract (continuation priority, readiness) | **NOT PRESENT** | `getOrCreateReviewGroup()` returns existing active group or creates new. No continuation-priority logic. `ReviewGroupsController` returns group with `remaining_count` but no readiness/progress summary. | C2 must use Path C2-A: use existing `active_review_group_id` + `active_review_group_remaining` only |
| 3 | Minimal stats summary contract (stats endpoint, learning_days_count) | **NOT PRESENT** | No statistics page in Flutter. No `/me/stats` endpoint. No `learning_days_count` field anywhere. Only `learning_day_today` boolean exists in TodayState. | C3 must use Path C3-A: summary-first using existing fields, no independent page |

---

## 3. Code Reality vs Governance Truth Risk Points

### R-C0-001: Candidate BR v0.1.7 vs active v0.1.5
- `BR-OPP-001_v0.1.7.md` contains Option C rules (single strongest CTA, continuation-first, etc.) that align with implementation direction
- But it is **NOT pinned** by Room 1 as runtime active BR
- **Risk**: C1-C4 implementors treat v0.1.7 rules as mandatory
- **Mitigation**: Use only rules independently derivable from `baseline-summary.md` frozen rules + current active API fields

### R-C0-002: Candidate UI OptionC vs active OptionB
- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` defines Today CTA layout, review priority, stats minimal spec
- But the active UI baseline remains `UI_SPEC_OptionB_v0.1.2.md`
- **Risk**: C1 follows OptionC UI layout without governance authorization
- **Mitigation**: C1 must work within the existing Today page structure (`today_page.dart`), not introduce new layout from candidate spec

### R-C0-003: Three clarifications not present → conservative paths only
- None of the three very small clarifications exist in code
- **Risk**: C1/C2/C3 write code against a `today_primary_action` field or stats endpoint that doesn't exist
- **Mitigation**: Each phase verifies: "Does the field/endpoint I need actually exist in `types.ts` and the relevant controller?" If not → conservative path

### R-C0-004: `streak_basis_type` type placeholder could be misread
- `StreakRecord` type definition includes `streak_basis_type: 'check_in' | 'learning_day'` (types.ts line 422)
- Runtime value is always `'check_in'` (hardcoded in `getOrCreateStreak()`)
- **Risk**: C4 implementor sees the `'learning_day'` type variant and assumes the switch is ready
- **Mitigation**: C4 must explicitly assert that `'learning_day'` is a type-level placeholder. No switch allowed without Room 1 pin.

### R-C0-005: Frozen rules in `baseline-summary.md` align with Option C direction
- `baseline-summary.md` already has frozen rules matching Option C goals: review_group contract, check_in/learning_day/streak independence, page/settlement boundaries
- **Implication**: C1-C4 can safely use these frozen rules as implementation basis, even without v0.1.7 pin
- **NOT a risk** — this is the safe foundation for conservative paths

---

## 4. C1-C5 Readiness Table

| Phase | Ready? | Path | Active Fields Available | Unpinned Dependencies | Risk |
|---|---|---|---|---|---|
| **C1: Today CTA Winner** | **YES** | C1-A conservative | `daily_goal_status`, `active_review_group_id`, `active_review_group_status`, `active_review_group_remaining`, `today_review_pending` | `today_primary_action` not present; BR v0.1.7 not pinned; OptionC UI not pinned | MEDIUM |
| **C2: Review Continuation** | **YES** | C2-A current frozen | `active_review_group_id`, `active_review_group_status`, `active_review_group_remaining`, `getOrCreateReviewGroup()` | Review summary contract not present; no readiness logic | MEDIUM |
| **C3: Statistics** | **CONDITIONAL** | C3-A summary-first | `learning_day_today` (boolean), `current_streak`, `has_checked_in_today`, `todayNewCompleted`, `todayReviewCompleted` | Stats endpoint not present; independent page not pinned | LOW |
| **C4: Streak Hardening** | **YES** | Direct hardening | `streak_basis_type` (always 'check_in'), `current_streak`, `has_checked_in_today`, `learning_day_today` | Future basis switch not decided; BR v0.1.7 direction clauses not pinned | LOW |
| **C5: Closeout** | **BLOCKED** | — | All fields | Requires C1-C4 completion | N/A |

### C1 Conservative CTA Winner Logic (Path C1-A)

Based on existing active fields in `TodayState`:

1. `active_review_group_id != null` AND `active_review_group_remaining > 0` → **"继续本组复习"** (continuation-first)
2. `today_review_pending > 0` (no active group but backend confirms pending review) → **"先去复习"**
3. `daily_goal_status == 'completed'` → **"今日目标已完成 ✅"**
4. Otherwise → **"开始今日学习" / "继续学习"** (based on `daily_goal_status`)

This uses ONLY fields confirmed present in `TodayState` (types.ts lines 158-186).

---

## 5. Gap Classification Summary

| Gap | Classification | Impact |
|---|---|---|
| BR v0.1.7 not pinned | Candidate only, wait for Room 1 pin | Non-fatal: Path A exists |
| UI OptionC not pinned | Candidate only, wait for Room 1 pin | Non-fatal: Path A exists |
| Today decision-support not present | Not present | C1 uses conservative CTA winner |
| Review summary not present | Not present | C2 uses existing active group fields |
| Stats contract not present | Not present | C3 uses summary-first with existing fields |
| Independent stats page not pinned | Non-blocking issue (NB-OC-001) | C3 defaults to summary block only |
| Future streak basis switch | Non-blocking issue (NB-OC-002) | C4 only hardens current `check_in` basis |
