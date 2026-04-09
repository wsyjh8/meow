# Option A — Import Validation Report v0.1

**Date**: 2026-04-03
**Phase**: A3
**Snapshot**: `apps/api/data/dev-store-state.json` (4.4KB)

---

## 1. Import Summary

| Table | Imported | Skipped | Errors |
|---|---|---|---|
| users | 0 | 1 (already seeded) | 0 |
| word_books | 0 | 1 (already seeded) | 0 |
| words | 0 | 1 (already seeded) | 0 |
| shop_catalog_items | 0 | 1 (already seeded) | 0 |
| user_book_settings | 0 | 1 (already seeded) | 0 |
| study_attempts | 0 | 1 (FK violation*) | 0 |
| review_groups | 0 | 0 | 0 |
| review_group_items | 0 | 0 | 0 |
| review_attempts | 0 | 0 | 0 |
| daily_goal_progress | 1 | 0 | 0 |
| session_records | 0 | 0 | 0 |
| check_in_records | 0 | 0 | 0 |
| learning_day_facts | 1 | 0 | 0 |
| streak_records | 0 | 1 (no change) | 0 |
| reward_source_events | 1 | 0 | 0 |
| reward_ledger | 2 | 0 | 0 |
| settlements | 1 | 0 | 0 |
| idempotency_keys | 1 | 0 | 0 |
| secondary_wallets | 1 | 0 | 0 |
| feed_events | 0 | 0 | 0 |
| inventory_items | 0 | 0 | 0 |
| equipment_slots | 0 | 0 | 0 |
| purchase_records | 0 | 1 (derived) | 0 |

**Total imported: 8 rows. Total tables: 23.**

*FK violation: JSON contains a study attempt referencing `word-learning-day-001` — a test-generated word ID not in the seed word pool. This is a known test artifact, not a real data loss.

---

## 2. Validation Results

| Check | Result | Detail |
|---|---|---|
| study_attempts count | **FAIL** | JSON=1, PG=0 (FK violation on test artifact word) |
| review_groups count | PASS | JSON=0, PG=0 |
| review_attempts count | PASS | JSON=0, PG=0 |
| sessions count | PASS | JSON=0, PG=0 |
| check_ins count | PASS | JSON=0, PG=0 |
| learning_days count | PASS | JSON=1, PG=1 |
| source_events count | PASS | JSON=1, PG=1 |
| reward_ledger count | PASS | JSON=2, PG=2 |
| settlements count | PASS | JSON=1, PG=1 |
| feed_events count | PASS | JSON=0, PG=0 |
| inventory_items count | PASS | JSON=0, PG=0 |
| idempotency_keys count | PASS | JSON=1, PG=1 |
| coins_balance parity | PASS | JSON=2, PG=2 |
| fish_treats_balance parity | PASS | JSON=0, PG=0 |
| feed_mood_accumulated | PASS | JSON=0, PG=0 |
| feed_exp_accumulated | PASS | JSON=0, PG=0 |
| feed_bond_accumulated | PASS | JSON=0, PG=0 |
| equipment_slots count | PASS | JSON=0, PG=0 |

**Result: 17/18 passed.**

---

## 3. Known Differences

| # | Difference | Severity | Blocks A4? | Resolution |
|---|---|---|---|---|
| D-001 | study_attempts: 1 JSON record with `word-learning-day-001` not imported | Low | **No** | Test artifact — references a word ID not in the production word pool. Will not occur in real usage. When DevStore is replaced by PG (A4), new study attempts will only reference valid word IDs. |
| D-002 | purchase_records: not explicitly imported | Low | **No** | Purchase records are reconstructable from inventory_items + secondary_wallets.coins_spent. No data loss. |

---

## 4. A4 Readiness Assessment

**All critical parity checks pass:**
- Coins balance: aligned
- Fish treats balance: aligned
- Pet state accumulators: aligned
- Equipment: aligned
- Reward ledger: aligned
- Idempotency keys: aligned
- Settlements: aligned

**The study_attempts FK violation is a non-blocking test artifact.**

**Verdict: Ready for A4.**
