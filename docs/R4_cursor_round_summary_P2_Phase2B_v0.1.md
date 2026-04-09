# Cursor Round Summary — P2 Phase 2B

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Implemented **P2 Phase 2B: minimal EXP→Level truth + upgrade feedback**.

Specifically:
- Replaced placeholder level formula with real threshold table (Lv1-Lv10)
- Made `level` derive from **total EXP** (reward ledger + feed accumulated)
- Added `growth_feedback` object to feed response with level-up detection
- Added `GrowthFeedback` model to Flutter `ApiClient`
- Added minimal upgrade dialog in Meow Home when feed triggers level-up
- Added `computeLevelFromExp()` unit tests (11 tests)
- Added e2e tests for level truth and growth feedback (4 tests)
- Added Flutter widget tests for level-up dialog (2 tests)
- All 11 unit tests, 43 e2e tests, and 31 Flutter tests pass

---

## 2. What changed

### New files:
- `apps/api/src/domain/level.spec.ts` — Unit tests for `computeLevelFromExp`

### Modified files:
- `apps/api/src/domain/dev-store.ts` — Added `LEVEL_THRESHOLDS`, `computeLevelFromExp()`, `getTotalExp()`, updated `getCatSummary()` to use threshold table, updated `feedCat()` to detect and return level-up, exported level helpers
- `apps/api/src/controllers/feed.controller.ts` — Added `growth_feedback` to feed response
- `apps/api/test/app.e2e-spec.ts` — Added 4 level/growth_feedback e2e tests
- `apps/mobile/lib/core/api/api_client.dart` — Added `GrowthFeedback` model, added `growthFeedback` to `FeedResponse`
- `apps/mobile/lib/features/meow_home/meow_home_page.dart` — Added `_showLevelUpDialog()`, updated `_feedCat` to check for level-up
- `apps/mobile/test/meow_home_page_test.dart` — Added `growthFeedback` to default mock, added 2 level-up dialog tests

### New docs:
- `docs/R4_P2_phase2B_implementation_report_v0.1.md`
- `docs/R4_cursor_round_summary_P2_Phase2B_v0.1.md` (this file)

---

## 3. What is already true now

- Level is computed from total EXP using a real threshold table (Lv1-Lv10)
- `secondary_summary.cat_summary.level` reflects true level from backend
- Feed response includes `growth_feedback` with `leveled_up` / `previous_level` / `current_level`
- Meow Home shows a minimal upgrade dialog when feed triggers level-up
- Idempotent replay does NOT re-trigger level-up feedback
- Level caps at Lv10 (EXP continues accumulating)
- All existing feed / fish_treat / mood / bond / anti-spam logic is intact
- The full learn→reward→feed→level-up loop is functional end-to-end

---

## 4. What is still blocked

- Complete growth curve / progression rewards
- Level-up unlock tree (rooms, outfits, items)
- Inventory / owned-item / equip truth
- Companion copy hooks / daily greeting / welcome text
- Complex level-up animation
- Interaction action (still placeholder)
- Multi-cat system
- Social / ranking / sharing

---

## 5. What must be done next

Candidates for next controlled slice(s):

1. **Interaction action** — Similar to feed pattern. Consume nothing (or small resource), give small mood/bond. Complete the two-button interaction set in Meow Home.
2. **Companion copy** — Lightweight: post-feed response text, daily greeting. No complex dialogue tree.
3. **Energy rules refinement** — Currently `energy` is a simple threshold. May need tuning.
4. **Feed item variety** — Other consumables beyond fish_treat (requires inventory thinking).

Or if all controlled slices are done, assess readiness for **broad Phase 2 remainder**.

---

## 6. What not to touch

- Do NOT expand level-up into a full progression/unlock system
- Do NOT add outfit/room/inventory domain
- Do NOT change main mechanism reward rules
- Do NOT freeze growth numbers — all current values are temporary dev rules
- Do NOT add companion dialogue system
- Do NOT change anti-spam rules without explicit instruction

---

## 7. Files to read first

1. `apps/api/src/domain/dev-store.ts` — `LEVEL_THRESHOLDS`, `computeLevelFromExp()`, `getTotalExp()`, `getCatSummary()`, `feedCat()`
2. `apps/api/src/controllers/feed.controller.ts` — `growth_feedback` in response
3. `apps/api/src/domain/level.spec.ts` — Level computation unit tests
4. `apps/mobile/lib/core/api/api_client.dart` — `GrowthFeedback` model
5. `apps/mobile/lib/features/meow_home/meow_home_page.dart` — `_showLevelUpDialog()`, `_feedCat()` level-up check
6. `docs/R4_P2_phase2B_implementation_report_v0.1.md` — Implementation details and threshold table

---

## 8. Current risks

1. **Mood formula interaction** (carried from Phase 2A): `getCatSummary()` mood still depends on `fish_treats * 5` from balance. Consuming fish treats reduces this component. This is a known bridge-level truth artifact.

2. **EXP dual-source persists**: Total EXP = reward ledger exp + feed exp accumulated. These are tracked separately. If a future change resets one source but not the other, level could become inconsistent. Unification into a single EXP ledger would eliminate this risk.

3. **Level cap**: Level caps at Lv10. If content or testing requires higher levels, the threshold table needs extending.

4. **In-memory store**: All state still in-memory. Server restart wipes everything.

---

## 9. Recommended next prompt focus

> "Implement P2 Phase 2C: interaction action (similar to feed pattern, placeholder→real) OR assess readiness for broad Phase 2 remainder with a scope review."
