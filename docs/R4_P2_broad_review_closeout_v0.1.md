# P2 Broad Review / Implementation Status Closeout

**Owner**: Room 4
**Scope**: P2 broad review / closeout
**Date**: 2026-04-03
**Status**: Review complete

---

## 1. Executive Summary

P2 has successfully delivered a functional secondary motivation loop. The core chain — **learn words -> earn rewards -> see rewards in Meow Home -> feed cat -> gain EXP/mood -> level up -> see companion responses** — is working end-to-end with backend truth.

However, **broad Phase 2 cannot be formally closed** because one original P2 scope item remains unaddressed: **basic outfit/decoration system** (item #5 in the P2 scope). This item requires inventory truth, coins spending, and outfit/room domain — none of which exist yet.

**Current biggest blocker**: No inventory/owned-item/equipped truth layer. No coins spending logic. These are hard prerequisites for the outfit system.

**Recommendation**: **Phase 2D (coins spending + inventory truth)** before Phase 3. Jumping to Phase 3 without the truth layer would create a hollow UI shell with no real backend support.

---

## 2. P2 Implemented Scope Snapshot

### Phase 1A — Secondary Summary / Balance Truth / Bridge Layer
**Status: Implemented**

What is true now:
- `GET /api/v1/me/secondary-summary` exists and returns stable `coins`, `fish_treats`, `exp`
- `BalanceSnapshot` computed from `RewardLedgerItem` entries with `status=succeeded`
- `CatSummary` (nickname, level, mood, bond, energy) derived from balance + feed state
- `CompanionResponse` (daily_greeting, post_learning_response, streak_node_response) included

What is still missing:
- Nothing for this slice's scope. Fully complete.

### Phase 1B — Meow Home MVP Shell + Reward Visibility + Transition
**Status: Implemented**

What is true now:
- `/meow-home` route registered in `AppRouter`
- `MeowHomePage` renders cat profile, resources (coins/fish_treats/exp), cat status
- Today page has two entry points to Meow Home (`today-meow-home-entry`, `today-meow-home-secondary-entry`)
- Settlement status visible on Today page with link to Meow Home

What is still missing:
- Nothing for this slice's scope. Fully complete.

### Phase 2A — Feed Truth + Fish-Treat Consumption + Minimal Pet-State Update
**Status: Implemented**

What is true now:
- `POST /api/v1/me/feed` exists with `FeedController`
- Fish treat deduction via backend truth (`FeedRecord` tracking, `getBalanceSnapshot()` subtracts consumed)
- Idempotency via `X-Idempotency-Key` (replay returns `already_exists: true`, no re-deduction)
- Anti-spam: first 3 feeds/day full benefit (+4 mood, +2 exp, +1 bond), 4th+ reduced (+1 mood only)
- Insufficient resource returns `FISH_TREATS_NOT_ENOUGH` with 200 status
- Meow Home feed button is real (loading/success/insufficient/error states)

What is still missing:
- Nothing for this slice's scope. Fully complete.

### Phase 2B — Minimal EXP→Level Truth + Upgrade Feedback
**Status: Implemented**

What is true now:
- `LEVEL_THRESHOLDS` table (Lv1-Lv10) with `computeLevelFromExp()`
- Level derived from total EXP (reward ledger + feed accumulated)
- `growth_feedback` in feed response: `leveled_up`, `previous_level`, `current_level`
- Idempotent replay does not re-trigger level-up
- Meow Home shows `AlertDialog` on level-up with warm copy
- Level capped at Lv10

What is still missing:
- Level-up does not trigger any unlock or reward (by design for this slice)
- No progression rewards or milestone bonuses

### Phase 2C — Companion Copy / Daily Response
**Status: Implemented**

What is true now:
- `CompanionResponse` type in domain
- `getCompanionResponse()` generates copy from factual state (check-in, learning_day, daily_goal_status, session_valid, streak)
- `daily_greeting`: 3 variants based on learning/check-in state
- `post_learning_response`: 3 variants based on session/goal completion (or null)
- `streak_node_response`: 4 node variants at streak 3/7/14/30 (or null)
- Meow Home renders companion copy in a soft card at page top
- Null fields gracefully hidden

What is still missing:
- Nothing for this slice's scope. Fully complete.

---

## 3. Broad Phase 2 Judgment

### Original P2 goals (from scope doc section 2):

| # | Goal | Status | Notes |
|---|---|---|---|
| 1 | Meow Home | **Done** | MVP shell + real data + companion copy |
| 2 | Reward visibility (Coins/Fish Treats/EXP) | **Done** | Backend truth, Meow Home renders |
| 3 | Basic feed | **Done** | Real endpoint, idempotent, anti-spam |
| 4 | Cat growth (EXP/Level) | **Done** | Threshold table, level-up feedback |
| 5 | Basic outfit/decoration system | **NOT DONE** | No inventory, no coins spending, no outfit domain |
| 6 | Daily greeting / completion response / streak response | **Done** | Companion copy system |
| 7 | Check-in/Session rewards visible in secondary mechanism | **Partial** | Check-in/streak/session_valid facts feed into companion copy; no dedicated "you earned X from session" UI |
| 8 | Minimal smoke/bug/blocker status | **Done** | All 49 e2e + 11 unit + 36 Flutter tests pass |

### Verdict

**Broad Phase 2: Mostly done but not fully closed.**

- 6 of 8 goals are fully met
- 1 is partially met (#7 — indirect visibility only)
- 1 is not met (#5 — basic outfit system)
- The missing item (#5) is the most structurally demanding — it requires truth layers that don't exist yet

---

## 4. Phase 3 Readiness Judgment

Phase 3 = basic outfit / room system.

### Minimum prerequisites for Phase 3:

| Prerequisite | Exists? | Notes |
|---|---|---|
| Inventory model (owned items) | **No** | No `OwnedItem` type, no inventory array in store |
| Equipped-state truth | **No** | No `EquippedState`, no active-outfit snapshot |
| Coins spending logic | **No** | Coins only accumulate; no deduction mechanism |
| Purchase flow truth | **No** | No purchase endpoint, no balance-check-and-deduct |
| Purchase idempotency | **No** | No purchase replay protection |
| Outfit catalog / item definitions | **No** | No outfit items defined |
| Room domain state | **No** | No room entity or state |

### Verdict

**Phase 3 is NOT ready.** Zero of seven prerequisites are met. Jumping directly to Phase 3 would require building the entire truth layer from scratch in a single round, which violates the controlled-slice approach that has worked well so far.

---

## 5. Recommended Next Step

### **Recommendation: Option A — Phase 2D (Coins Spending + Inventory Truth)**

**Why:**

1. **Truth-layer-first principle**: The outfit system needs coins spending and inventory. Building the truth layer first (without full UI) follows the same pattern that succeeded in Phase 2A-2C.

2. **Risk containment**: A Phase 2D slice for "coins spending + minimal inventory model" is a bounded, testable unit. Phase 3 (full outfit/room UI + equip flow) becomes much safer when the truth layer already exists.

3. **Avoiding hollow UI**: If we jump to Phase 3 now, we'd need to build truth + UI simultaneously, increasing the risk of placeholder-becomes-assumed-truth problems.

4. **Consistency**: Every P2 slice so far (1A→1B→2A→2B→2C) has followed "backend truth first, then UI." Phase 2D continues this pattern.

### Phase 2D recommended scope:
- `POST /api/v1/me/shop/purchase` — coins-based purchase with idempotency + balance check
- Minimal `OwnedItem` / `InventoryRecord` types
- Minimal outfit catalog (3-5 hardcoded items for dev)
- `GET /api/v1/me/inventory` — read owned items
- No equip flow yet (that's Phase 3)
- No room system yet (that's Phase 3)
- Tests for purchase success, insufficient coins, idempotency

---

## 6. Active Blockers

### B-Phase3-001: Inventory Truth
- **Impact**: Phase 3 cannot start without it
- **Why it blocks**: Outfit/room systems need to know what the user owns. No `OwnedItem` type or storage exists.
- **Next action**: Implement in Phase 2D

### B-Phase3-002: Purchase Truth
- **Impact**: Phase 3 cannot start without it
- **Why it blocks**: Buying outfits requires coins deduction with idempotency and balance validation. Currently coins only accumulate — there is no spending mechanism.
- **Next action**: Implement in Phase 2D

### B-Phase3-003: Outfit / Room Domain
- **Impact**: Phase 3 direct dependency
- **Why it blocks**: No outfit catalog, no equipped snapshot, no room state exists.
- **Next action**: Minimal catalog in Phase 2D, full equip/room in Phase 3

### B-Phase3-004: Interaction Button
- **Impact**: Low — cosmetic only
- **Why it blocks**: The "互动" button in Meow Home is still a placeholder (OutlinedButton with coming-soon snackbar). Not a Phase 3 blocker, but it's an unfinished P2 UI element.
- **Next action**: Can be addressed in Phase 2D or deferred

---

## 7. Active Assumptions

- `Assumption (temporary, not frozen): current feed uses +4 mood and +2 exp as a minimal development rule, not a frozen growth balance.`
- `Assumption (temporary, not frozen): anti-spam cap of 3 full-benefit feeds per day is a minimal dev safeguard, not a frozen growth balance.`
- `Assumption (temporary, not frozen): bond +1 per feed is a temporary dev rule.`
- `Assumption (temporary, not frozen): level thresholds follow the current MVP secondary numbers draft for Lv1-Lv10 and can be adjusted.`
- `Assumption (temporary, not frozen): level caps at Lv10. Expansion deferred.`
- `Assumption (temporary, not frozen): companion response strings and trigger rules are minimal development copy rules, not a frozen narrative/copy system.`
- `Assumption (temporary, not frozen): streak nodes are fixed at 3/7/14/30 as a minimal development rule.`
- `Assumption (temporary, not frozen): all copy is hardcoded in the backend store. Remote config / CMS is not part of current scope.`
- `Assumption (temporary, not frozen): EXP dual-source (reward ledger + feed accumulated) is tracked separately. Unification deferred.`
- `Assumption (temporary, not frozen): mood formula includes fish_treats*5 from balance, which creates interaction effects when fish_treats are consumed. This is a known bridge-level artifact.`
