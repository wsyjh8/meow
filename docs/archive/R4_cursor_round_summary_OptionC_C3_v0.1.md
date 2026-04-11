# Cursor Round Summary — Option C, C3

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Completed **Option C / C3 / Statistics minimal spec**. Not C4-C5.

- Verified C2 gate: `ready for C3 = YES`
- Added `StatsSummary` type + `buildStatsSummary()` to backend
- Added `stats_summary` to `GET /me/secondary-summary` response
- Added `StatsSummaryData` model to Flutter with optional parsing
- Added "学习概览" summary card to Meow Home
- Enforced "学习天数 = learning_day" (NOT check_in, NOT streak)
- 3 new e2e tests, all 168 tests pass

---

## 2. Whether C2 truly allowed C3

**YES.** C2 Status explicitly states `Ready for C3`.

---

## 3. Which path (A or B) was used

**Path C3-A** (summary-first, no independent page). Because:
- C0: minimal stats summary contract = NOT PRESENT
- No Room 1 pin on independent page
- Conservative: summary card in Meow Home only

---

## 4. How statistics minimal spec now works

- Backend `buildStatsSummary()` computes from existing data arrays:
  - `total_learning_days` = `learningDays.filter(d => d.learning_day).length`
  - `total_words_learned` = study attempts with know
  - `total_review_groups_completed` = completed groups
  - `total_check_ins` = check-in count (SEPARATE from learning_days)
  - `current_streak` + `streak_basis` = as-is from streak record
- Frontend `StatsSummaryData` parses from `secondary-summary` (optional)
- Meow Home shows "📊 学习概览" card with 4 stats + streak row
- Streak explicitly labeled "(基于签到)"

---

## 5. What truth boundary was kept

- 学习天数 = learning_day ONLY (not check_in, not streak)
- 签到 count is separate and independent
- Streak labeled with its basis "(基于签到)"
- No conflation between check_in / learning_day / streak
- No candidate stats contract assumed
- No independent page created

---

## 6. What is still not done

| Phase | Status |
|---|---|
| C4: Streak truth-boundary hardening | Pending |
| C5: Test & closeout | Pending |

---

## 7. What must be done next

**C4: Streak truth-boundary hardening.** Should:
1. Audit all streak/check_in/learning_day wording across pages
2. Ensure `streak_basis_type = check_in` is consistently communicated
3. Ensure future stance (learning_day basis) is NOT implemented as current fact
4. Add truth-boundary tests

---

## 8. What not to touch

- Don't create independent statistics page
- Don't implement trend analysis or charts
- Don't change streak basis from check_in to learning_day
- Don't assume stats contract clarification is pinned
- Don't expand stats card into full product

---

## 9. Files / modules to read first

1. `apps/api/src/domain/types.ts` — `StatsSummary` interface
2. `apps/api/src/domain/dev-store.ts` — `buildStatsSummary()` method
3. `apps/mobile/lib/core/api/api_client.dart` — `StatsSummaryData` class
4. `apps/mobile/lib/features/meow_home/meow_home_page.dart` — `_buildStatsSummaryCard()`
5. `apps/api/test/app.e2e-spec.ts` — "stats_summary in secondary summary" tests

---

## 10. Current blockers / assumptions / risks

- `Assumption (temporary, not frozen): Stats are total counts only (no per-day/week/month)`
- `Assumption (temporary, not frozen): Stats card positioned in Meow Home section 7 (Room 5 may adjust)`
- `Assumption (temporary, not frozen): streak_basis remains check_in throughout Option C`
- `Blocked if touched: Don't create independent stats page without Room 1 pin`
- `Blocked if touched: Don't flip streak basis or conflate learning_day with check_in`
- Risk: `total_learning_days` may undercount if `updateLearningDay()` wasn't called for all past days
- Risk: Stats card display depends on `stats_summary != null` — old backend without C3 returns null → card hidden

---

## 11. Whether ready for C4

**YES.** Stats summary-first landed, learning_day boundary enforced, check_in/streak/learning_day clearly separated, 168 tests pass.
