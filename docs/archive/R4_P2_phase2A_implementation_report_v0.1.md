# P2 Phase 2A Implementation Report — Feed Truth + Fish Treat Consumption + Minimal Pet-State Update

**Date**: 2026-04-03
**Phase**: P2 Phase 2A
**Status**: Complete

---

## 1. Scope

This round implements the **minimum viable feed action chain**:

> Resource available -> Consume fish_treat -> Update minimal pet-state -> Page reflects result

This is **NOT** broad Phase 2. This is a controlled, truth-first slice that:
- Establishes a real `POST /api/v1/me/feed` endpoint
- Deducts `fish_treats` via backend truth (not client-side)
- Updates `mood` and `exp` with minimal dev rules
- Upgrades the Meow Home feed button from placeholder to real action
- Handles insufficient resources gracefully
- Protects against duplicate deduction via idempotency
- Applies basic anti-spam limits

---

## 2. Feed Endpoint Design

### Endpoint
`POST /api/v1/me/feed`

### Request
```json
{
  "feed_item_type": "fish_treat"
}
```
Header: `X-Idempotency-Key` (required)

### Response (success)
```json
{
  "feed_result": {
    "status": "succeeded",
    "consumed_item": "fish_treat",
    "consumed_amount": 1,
    "mood_delta": 4,
    "exp_delta": 2,
    "already_exists": false
  },
  "secondary_summary": { ... }
}
```

### Response (insufficient)
```json
{
  "feed_result": {
    "status": "insufficient_resource",
    "error_code": "FISH_TREATS_NOT_ENOUGH",
    "consumed_item": null,
    "consumed_amount": 0
  },
  "secondary_summary": { ... }
}
```

---

## 3. Fish Treat Consumption Rules

- Each feed consumes **1 fish_treat**
- Deduction tracked via `FeedRecord` in backend store
- `getBalanceSnapshot()` subtracts total consumed from earned total
- Cannot deduct below zero
- Idempotency key prevents duplicate deduction on replay

---

## 4. Pet-State Minimal Update Rules

### Assumption (temporary, not frozen):
Current Phase 2A feed uses the following as a **minimal development rule**, not a frozen growth balance:

| Feed # (per day) | Fish Treat Cost | Mood Delta | EXP Delta | Bond Delta |
|---|---|---|---|---|
| 1-3 | 1 | +4 | +2 | +1 |
| 4+ | 1 | +1 | 0 | 0 |

### What is updated:
- `mood` — accumulated from feed deltas, capped at 100
- `exp` — accumulated from feed deltas, shown in secondary summary
- `bond` — accumulated from feed deltas (first 3 feeds only)

### What is NOT updated:
- `level` — still derives from reward-ledger exp only; feed exp does NOT trigger level-up
- `energy` — unchanged by feeding

### Level Handling: **Option A (recommended, implemented)**
- `exp` accumulates from feeding
- `level` does NOT auto-change from feed exp
- Level-up is deferred to a future controlled slice

---

## 5. Anti-Spam / Rate Limiting

- **First 3 feeds per day**: full benefit (+4 mood, +2 exp, +1 bond)
- **4th feed onward**: resource consumed but reduced benefit (+1 mood only)
- This prevents unlimited EXP farming while still allowing resource consumption
- Rule is per `local_date` (server date)

Assumption (temporary, not frozen): This anti-spam cap is a minimal dev safeguard, not a frozen growth balance.

---

## 6. Idempotency

- `X-Idempotency-Key` header is required
- Same key replays return `already_exists: true` without re-deducting
- Key is stored via existing `devStore.setIdempotencyKey()` mechanism
- Works identically to study/review/session/check-in idempotency

---

## 7. Assumptions (temporary, not frozen)

1. `Assumption (temporary, not frozen): current Phase 2A feed uses +4 mood and +2 exp as a minimal development rule based on the current MVP secondary numbers draft, not as a frozen growth balance.`
2. `Assumption (temporary, not frozen): bond +1 per feed is a temporary dev rule for Phase 2A.`
3. `Assumption (temporary, not frozen): anti-spam cap of 3 full-benefit feeds per day is a minimal dev safeguard, not a frozen growth balance.`
4. `Assumption (temporary, not frozen): feed exp does NOT trigger level-up in this slice.`
5. `Assumption (temporary, not frozen): only fish_treat is available as feed_item_type in Phase 2A.`

## 8. Blockers

- `Blocked if touched: complete level-up system`
- `Blocked if touched: complete growth curve`
- `Blocked if touched: inventory / owned-item / equip truth`
- `Blocked if touched: outfit / room domain`
- `Blocked if touched: companion copy hooks`
- `Blocked if touched: free interaction button real revenue`

---

## 9. Ready for Next Slice?

**Yes.** Phase 2A is complete. The system now has:
- A real feed action chain with backend truth
- Resource consumption that is trackable and idempotent
- Minimal pet-state updates that are controlled and capped
- UI that reflects real backend state

Recommended next slice candidates:
1. Level-up minimal rules (if exp accumulation warrants it)
2. Interaction action (similar pattern to feed)
3. Daily welcome / post-feed companion copy (lightweight)
