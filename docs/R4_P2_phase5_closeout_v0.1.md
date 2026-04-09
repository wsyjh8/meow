# P2 Phase 5 Closeout — Smoke / Bug / Blocker / Regression

**Date**: 2026-04-03
**Phase**: P2 Phase 5
**Status**: Complete — No active blockers

---

## 1. Scope

This round is a formal smoke / regression / bug & blocker closeout for all P2 work (Phase 1A through Phase 4). No new features were added. No code changes were made.

---

## 2. Smoke Summary

### S-001 Main mechanism → secondary mechanism acceptance
**Result: PASS**
- e2e: study attempt → settlement → secondary summary shows updated coins/exp/fish_treats
- e2e: settlement creates source events and reward ledger items correctly
- e2e: today aggregation includes last_reward_settlement
- Coverage: 15+ e2e tests covering this chain

### S-002 Feed loop
**Result: PASS**
- e2e: feed with sufficient fish_treats succeeds, deducts correctly
- e2e: feed with insufficient fish_treats returns FISH_TREATS_NOT_ENOUGH
- e2e: idempotent replay does not double-deduct
- e2e: anti-spam cap applies after 3 feeds/day
- e2e: secondary summary reflects feed state changes
- Coverage: 5 e2e tests

### S-003 Companion response
**Result: PASS**
- e2e: companion_response included in secondary summary
- e2e: default greeting when no check-in/learning
- e2e: checked-in greeting after check-in
- e2e: learning greeting after effective study
- e2e: streak node response is null for non-node streaks
- e2e: existing summary fields not disrupted
- Coverage: 6 e2e tests

### S-004 Purchase loop
**Result: PASS**
- e2e: catalog returns 5 active items with correct schema
- e2e: empty inventory initially
- e2e: purchase succeeds with sufficient coins and level
- e2e: COINS_NOT_ENOUGH on insufficient balance
- e2e: ITEM_LEVEL_LOCKED when level too low
- e2e: ITEM_ALREADY_OWNED on duplicate purchase
- e2e: idempotent replay does not duplicate
- e2e: ITEM_NOT_FOUND for invalid item
- e2e: secondary summary coins decrease after purchase
- Coverage: 10 e2e tests

### S-005 Equipment loop
**Result: PASS**
- e2e: empty equipped snapshot initially
- e2e: equip owned item succeeds
- e2e: snapshot updates after equip
- e2e: different slot items can coexist
- e2e: ITEM_NOT_OWNED for unowned item
- e2e: idempotent replay is safe
- e2e: equipped_preview in secondary summary
- e2e: full chain (purchase → equip → snapshot → summary) consistent
- Coverage: 8 e2e tests

### S-006 Persistence loop
**Result: PASS**
- unit: purchase survives simulated restart
- unit: equipment survives simulated restart
- unit: feed/growth state survives simulated restart
- unit: idempotency key survives simulated restart
- unit: reset clears persistence file
- Coverage: 5 unit tests

---

## 3. Regression Summary

### R-001 Secondary summary regression: PASS
- All fields present: coins, fish_treats, exp, cat_summary, companion_response, equipped_preview

### R-002 Feed regression: PASS
- success/insufficient/idempotency/anti-spam all verified in e2e

### R-003 Growth regression: PASS
- exp→level threshold table verified in 11 unit tests
- growth_feedback leveled_up/not-leveled verified in e2e
- idempotent replay does not re-trigger level-up

### R-004 Purchase/inventory regression: PASS
- catalog/inventory/purchase contracts intact
- all error codes verified

### R-005 Equip regression: PASS
- equip/unequip/snapshot/summary sync all verified

### R-006 Persistence regression: PASS
- restart survival verified for purchase, equipment, feed/growth, idempotency

### R-007 UI regression: PASS
- flutter test: 44/44 passed
- flutter analyze: 0 errors, 0 warnings, 19 info-level hints (pre-existing)
- Meow Home, feed, level-up, companion copy, customize all covered by widget tests

---

## 4. Bug List

### Blocker
None.

### Major Bug
None.

### Minor Bug
None found in automated testing.

### Non-blocking Cleanup Issues

| # | Title | Severity | Area | Description | Recommended Action |
|---|---|---|---|---|---|
| C-001 | Dead `/inventory` route | Cleanup | Flutter Router | `/inventory` route exists in AppRouter but no UI navigates to it (replaced by `/customize` in Phase 3). `InventoryPage` still exists as a file. | Remove route and page, or keep as debug-only entry. Low priority. |
| C-002 | Interaction button placeholder | Cleanup | Meow Home | "互动" button is still a placeholder (`_showComingSoon`). Not a bug — it was explicitly out of scope. | Address if interaction action is planned for a future phase. |
| C-003 | `console.log` in persistence load | Cleanup | DevStore | `[DevStore] State restored from disk.` logs on every test that creates a DevStore with existing data. Noisy in test output. | Suppress in test environment or make log level configurable. |
| C-004 | 19 info-level flutter analyze hints | Cleanup | Flutter tests | Pre-existing `prefer_const_constructors` and `prefer_const_literals_to_create_immutables` hints in test files. | Fix in a cleanup pass. Not urgent. |

---

## 5. Blocker List

**No active blocker for current P2 MVP closeout judgment.**

All P2 original scope items are implemented and verified:
1. Meow Home + reward visibility — done
2. Feed + pet-state update — done
3. Growth (EXP→Level) — done
4. Companion copy — done
5. Coins spending + inventory — done
6. Basic outfit/room (equip flow) — done
7. Persistence — done
8. Smoke/regression — done (this document)

---

## 6. Assumptions (consolidated)

1. `Assumption (temporary, not frozen): feed rules (+4 mood, +2 exp, +1 bond for first 3/day) are minimal dev rules, not frozen growth balance.`
2. `Assumption (temporary, not frozen): anti-spam cap of 3 full-benefit feeds per day is a minimal dev safeguard.`
3. `Assumption (temporary, not frozen): level thresholds (Lv1-10) follow MVP secondary numbers draft, adjustable.`
4. `Assumption (temporary, not frozen): level caps at Lv10.`
5. `Assumption (temporary, not frozen): companion response strings and trigger rules are minimal development copy, not a frozen narrative system.`
6. `Assumption (temporary, not frozen): streak nodes fixed at 3/7/14/30.`
7. `Assumption (temporary, not frozen): all copy hardcoded in backend. No remote config/CMS.`
8. `Assumption (temporary, not frozen): catalog items and prices are minimal dev data, not a frozen price table.`
9. `Assumption (temporary, not frozen): no item stacking in MVP.`
10. `Assumption (temporary, not frozen): equipped field is slot-based, one item per slot, no layering.`
11. `Assumption (temporary, not frozen): room items use slot-based equip, no coordinate placement.`
12. `Assumption (temporary, not frozen): file-backed JSON persistence is minimal MVP. Production requires real database.`
13. `Assumption (temporary, not frozen): single-user, single-process. No concurrent write handling.`
14. `Assumption (temporary, not frozen): idempotency keys persisted indefinitely, no TTL.`
15. `Assumption (temporary, not frozen): EXP dual-source (reward ledger + feed accumulated) tracked separately.`
16. `Assumption (temporary, not frozen): mood formula includes fish_treats*5 from balance — known bridge-level artifact.`

---

## 7. Regression Entry Notes

### Tests that must regress every round
- `npm test` (16 unit tests: level computation + persistence)
- `npm run test:e2e` (67 e2e tests: all endpoint chains)
- `flutter test` (44 widget tests: all pages + model parsing)
- `flutter analyze` (must be 0 errors, 0 warnings)

### Most fragile chains
1. **Secondary summary shape**: Any new field added to SecondarySummary requires updating the `toEqual` shape test in e2e AND the Flutter `fromJson` parser.
2. **Coins balance consistency**: coins earned (reward ledger) minus coins spent (purchases) minus fish_treats consumed (feeds) — three separate deduction paths must all be correct.
3. **Persistence ↔ test isolation**: `reset()` must clear both memory and disk. If a test forgets reset, stale state leaks to the next test.

### Changes most likely to break P2
- Adding fields to SecondarySummary without updating tests
- Changing BalanceSnapshot computation
- Changing DevStore constructor signature
- Modifying persistence file format without migration

---

## 8. Ready for Phase 6?

**Yes.** P2 MVP is functionally complete, persisted, and verified. No active blockers. Phase 6 can be:
- P2 final close (formal Room 1 sign-off)
- Next major phase (production DB, visual polish, interaction action, or new feature area)
