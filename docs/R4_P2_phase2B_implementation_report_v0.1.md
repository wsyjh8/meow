# P2 Phase 2B Implementation Report — Minimal EXP→Level Truth + Upgrade Feedback

**Date**: 2026-04-03
**Phase**: P2 Phase 2B
**Status**: Complete

---

## 1. Scope

This round implements the **minimum viable EXP→Level truth and upgrade feedback**:

> Total EXP (reward + feed) → Level computed by backend → Upgrade feedback on feed → UI reflects real level

This is **NOT** a complete growth system. This is a controlled slice that:
- Replaces the placeholder `Math.floor(exp/10)+1` level formula with a real threshold table
- Makes `level` derive from **total accumulated EXP** (reward ledger + feed)
- Adds `growth_feedback` to the feed response with level-up detection
- Shows a minimal upgrade dialog in Meow Home when feed triggers a level-up
- Does NOT add unlock trees, inventory, outfits, rooms, or progression rewards

---

## 2. Level Truth Design

### Total EXP
Level is computed from **total accumulated EXP**, which includes:
- EXP from reward ledger (earned via study/review settlements)
- EXP from feeding (accumulated via `feedExpAccumulated`)

This is exposed as `getTotalExp()` in DevStore.

### Level Computation
```typescript
function computeLevelFromExp(totalExp: number): number
```

Uses a threshold table lookup. Iterates `LEVEL_THRESHOLDS` and returns the highest level whose `cumulative_exp` the total EXP meets or exceeds. Caps at Lv10.

---

## 3. Level Threshold Table

Assumption (temporary, not frozen): current Phase 2B level thresholds follow the current MVP secondary numbers draft for Lv1-Lv10, and can still be adjusted by future numeric balancing if Room 1 re-pins the numbers baseline.

| Level | Cumulative EXP Required |
|---|---|
| 1 | 0 |
| 2 | 20 |
| 3 | 50 |
| 4 | 90 |
| 5 | 145 |
| 6 | 215 |
| 7 | 305 |
| 8 | 420 |
| 9 | 565 |
| 10 | 745 |

- Beyond Lv10: EXP continues to accumulate, level stays at 10.
- Below Lv2 threshold (0-19 EXP): Level = 1.

---

## 4. Growth Feedback Contract

### In feed response
When feed succeeds, the response now includes `growth_feedback`:

```json
{
  "feed_result": { ... },
  "growth_feedback": {
    "leveled_up": true,
    "previous_level": 1,
    "current_level": 2
  },
  "secondary_summary": { ... }
}
```

Rules:
- `leveled_up: true` only when this specific feed action caused the level to increase
- Idempotent replay returns `leveled_up: false` (no re-trigger)
- Insufficient resource returns `growth_feedback: null`
- `previous_level` and `current_level` always reflect the real state

### In secondary summary
`cat_summary.level` now reflects the real level computed from total EXP.

---

## 5. What Was NOT Changed

- `energy` — unchanged, still derives from total EXP threshold (>= 20 → high)
- `inventory` — does not exist, not touched
- `outfit / room` — does not exist, not touched
- Main mechanism rules — not touched
- Feed consumption rules — unchanged from Phase 2A
- Anti-spam rules — unchanged from Phase 2A

---

## 6. Assumptions (temporary, not frozen)

1. `Assumption (temporary, not frozen): current Phase 2B level thresholds follow the current MVP secondary numbers draft for Lv1-Lv10, and can still be adjusted by future numeric balancing if Room 1 re-pins the numbers baseline.`
2. `Assumption (temporary, not frozen): level caps at Lv10 for Phase 2B. Expansion beyond Lv10 is deferred.`
3. `Assumption (temporary, not frozen): level-up does not trigger any unlock, reward, or progression side-effect in this slice.`
4. `Assumption (temporary, not frozen): the upgrade dialog is minimal text-only, no animation or complex UI.`

## 7. Blockers

- `Blocked if touched: complete growth curve / progression rewards`
- `Blocked if touched: level-up unlock tree (rooms, outfits, items)`
- `Blocked if touched: inventory / owned-item / equip truth`
- `Blocked if touched: companion copy hooks / welcome text`
- `Blocked if touched: complex level-up animation chain`

---

## 8. Ready for Next Slice / Broad Phase 2?

**Phase 2B is complete.** The system now has:
- Real level truth derived from backend EXP
- Level-up detection on feed
- Minimal upgrade feedback in UI
- All existing feed/resource/mood/bond logic intact

**Assessment for broad Phase 2 remainder:**
The core secondary mechanism loop is now functional:
- Learn words → earn rewards → get fish treats → feed cat → gain EXP/mood → level up

What remains for broad Phase 2 completion:
1. Interaction action (currently placeholder)
2. Companion copy / daily greeting (currently none)
3. Energy rules refinement (currently basic threshold)

These can be done as additional controlled slices or bundled if scope is clear.
