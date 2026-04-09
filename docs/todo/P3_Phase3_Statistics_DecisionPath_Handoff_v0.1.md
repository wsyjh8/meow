# OPP-001 / 背单词喵喵 App — Room 4 → Cursor
# P3 Phase 3（Statistics Decision Path）Implementation Handoff v0.1

- **From:** Room 4（Eng + QA + Debug Tech Lead）
- **To:** Cursor
- **Date:** 2026-04-06
- **Status:** ready to execute
- **Chosen path for this round:** **Path A — keep `summary-first`**
- **Why this path:** Room 4 default / recommended path is conservative `summary-first` unless Room 1 explicitly pins an independent minimal statistics page. This round, you must implement the `summary-first` strengthening path only.

---

## 0. Read this first

You cannot read our project docs, so this handoff is the full execution source for this phase.

Your job is **not** to build a new statistics page.
Your job is to make the current **summary-first statistics expression** more stable, clearer, and better guarded, while keeping all truth boundaries intact.

This phase is intentionally smaller than a “new page” feature.
It is a **statistics decision-path phase**, and for this round the decision is:

> **Keep `summary-first`; do NOT create an independent statistics page.**

---

## 1. Frozen truth you must obey

These are hard constraints for this phase:

1. Statistics remains **summary-first**.
2. Do **not** create a new statistics route.
3. Do **not** create a new first-level navigation / tab.
4. Do **not** expand this into a BI / analytics product.
5. “Learning days” must be based on **`learning_day`**, not `check_in`, not `streak`, and not any local inference.
6. Current `streak` display still follows the current active basis = **`check_in`**.
7. Frontend must not locally infer missing historical data, missing summary metrics, or missing completion truth.
8. If a metric is absent / delayed / unavailable, fall back safely and neutrally.

---

## 2. What this phase is trying to achieve

Strengthen the current statistics summary path so that:

1. Statistics summary is clearer and more internally consistent.
2. `learning_day / check_in / streak` are not mixed up.
3. Summary loading / empty / error / unavailable behavior is explicit.
4. The app does not accidentally grow a half-built standalone stats page.
5. Existing active Option C behavior remains safe if data is incomplete.

In one line:

> **Make the current summary-first statistics path harder to misread, not broader.**

---

## 3. In scope

You may do the following:

### A. Strengthen the existing summary block / summary card / summary entry
Use the current statistics summary surface that already exists in the app.
Improve only within the current summary-first path.

Allowed work:
- Make labels and grouping clearer
- Make metric ordering consistent
- Make summary rendering more robust when some metrics are missing
- Strengthen loading / empty / error / unavailable states
- Strengthen truth-boundary display rules

### B. Harden metric meaning in the UI
Ensure the current summary area clearly separates:
- `learning_days`
- `current_streak`
- today / recent completion summary

Rules:
- `learning_days` must never be rendered from `check_in`
- `learning_days` must never be rendered from `streak`
- `current_streak` must not be re-labeled as learning days
- if only check-in data exists but learning-day data does not, do not fabricate learning days

### C. Strengthen contract-absence and degraded handling
You may add or tighten:
- strict parsing
- null guards
- fallback rendering
- safe hidden states for absent metrics
- summary skeleton / loading placeholders
- neutral unavailable messaging

### D. Add / update tests
You must add tests that prove:
- summary-first remains the only path
- no new route appears
- no new first-level navigation appears
- `learning_day / check_in / streak` do not get mixed
- missing metrics do not crash the UI
- fallback behavior is stable

---

## 4. Explicitly out of scope

You must **not** do any of the following:

1. Do not add a new `/statistics` page route.
2. Do not add a new tab / first-level nav item.
3. Do not create empty chart shells just to “prepare for later”.
4. Do not create a half-built standalone stats page hidden behind dead code.
5. Do not invent local historical calculations when backend summary is missing.
6. Do not backfill missing metrics from check-in or streak.
7. Do not change runtime `streak` basis.
8. Do not add mastery / retention / accuracy / deep trend analytics.
9. Do not introduce a new DB or API contract unless absolutely necessary for parsing existing active data. Prefer **zero backend contract change**.
10. Do not auto-open Phase 4.

---

## 5. Recommended implementation approach

### Step 1 — Find the current summary-first statistics surface
Search the mobile codebase for the current statistics summary UI used from Today or related summary areas.
You are looking for the existing summary card / block / entry, not a standalone page.

### Step 2 — Audit current metric sources
For each displayed statistics metric, identify:
- where it comes from
- whether it is already stable active data
- whether the current UI is incorrectly inferring or conflating anything

Build a short local checklist during implementation:
- Is this metric backend-provided?
- If absent, what is the fallback?
- Can this be confused with another fact?

### Step 3 — Normalize the summary-first rendering path
Refactor only as much as needed so the current summary path is:
- stable
- readable
- null-safe
- boundary-safe

### Step 4 — Implement the state matrix
At minimum, make sure the current summary surface can handle:
- normal
- loading
- empty
- error
- unavailable / delayed / contract-not-present

Behavior rules:
- **normal:** show only confirmed available summary metrics
- **loading:** show summary skeleton / placeholder only
- **empty:** neutral “learn a little first, then come back” style state
- **error:** neutral error + safe fallback to Today
- **unavailable / delayed:** do not fake completion or trends; show neutral limited-state summary

### Step 5 — Add regression tests
Add targeted tests for:
- summary-first path remains active
- no route / nav expansion happened
- learning days are not derived from check-in
- learning days are not derived from streak
- streak still displays as current streak only
- missing stats fields hide or degrade safely

---

## 6. If you need tiny code changes, prefer these areas

Because you can inspect the repo directly, use the real file names you find. In general, prefer changing only:

1. Existing Today summary / statistics summary UI files
2. Existing parsing / model files for Today summary data
3. Existing shared UI components used by the current summary block
4. Existing mobile tests around Today / summary rendering

Avoid touching:
- route declarations (unless only verifying no new route is added)
- DB schema
- API endpoint shape
- navigation architecture

If you discover the current statistics summary is impossible to strengthen without a new contract, **stop and report blocker** instead of inventing one.

---

## 7. Strong truth-boundary rules

Treat these as hard assertions:

1. `learning_days != check_in_count`
2. `learning_days != current_streak`
3. `current_streak` is still current streak, not learning-day streak
4. displayed summary is not the same as “fresh backend truth” if data is delayed
5. absent metrics must degrade to hidden / neutral / unavailable, not fabricated values

---

## 8. Test requirements

You must deliver code + tests together.

### Required test groups

#### G1 — Summary-first safety
- verifies current summary-first path still exists
- verifies no standalone statistics route was introduced
- verifies no new first-level navigation item was introduced

#### G2 — Truth-boundary regression
- verifies learning days are not rendered from check-in-only data
- verifies learning days are not rendered from streak-only data
- verifies streak label/value stays in streak semantics

#### G3 — State matrix regression
- loading state safe
- empty state safe
- error state safe
- unavailable / missing summary metrics safe

#### G4 — Contract absence / partial data regression
- partial summary payload does not crash
- absent metrics hide safely or show neutral unavailable state
- no fake trend / fake total is created locally

### Self-test requirement
Run the relevant mobile tests and any impacted static analysis.
If there are backend tests impacted by parsing or shared contract assumptions, run those too.

---

## 9. Completion bar

This phase is only complete if all of the following are true:

1. Statistics stays `summary-first`.
2. No new route / first-level navigation / standalone page shell is introduced.
3. `learning_day / check_in / streak` are clearly separated.
4. Missing or delayed summary data degrades safely.
5. Tests prove the above.
6. You stop at Phase 3 and do not begin Phase 4.

---

## 10. Delivery format back to Room 4

When you reply, use this structure:

### 10.1 Code summary
- file-by-file changes
- what each change does

### 10.2 Behavior summary
- normal behavior
- loading / empty / error / unavailable behavior
- how `learning_day / check_in / streak` are kept separate

### 10.3 Test summary
- commands run
- total tests / pass count
- analysis / lint result if run

### 10.4 Risk / follow-up
- any blocker found
- any area that still needs Room 1 pin
- confirmation that you did **not** open Phase 4

