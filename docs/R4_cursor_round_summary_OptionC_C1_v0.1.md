# Cursor Round Summary — Option C, C1

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Completed **Option C / C1 / Today CTA winner**. Not C2-C5.

- Verified C0 gate: `ready for C1 = YES`, Path C1-A
- Implemented single-strong-CTA with 4-priority winner logic
- Downgraded review group card to info-only (no competing button)
- Session confirmed as subordinate (info-only, section 5)
- Added 6 new widget tests for CTA state matrix
- All 161 tests pass (73 Flutter + 16 unit + 72 e2e)

---

## 2. Whether C0 truly allowed C1

**YES.** C0 output (`R4_OptionC_Status_v0.1.md` section 8) explicitly states:
> "YES — Path C1-A (conservative, no new contract patch)."

All three clarifications = NOT PRESENT → conservative path required.

---

## 3. Which path (A or B) was used

**Path C1-A (conservative).** Because:
- `today_primary_action` does not exist in codebase
- No decision-support block from backend
- All three very small clarifications = NOT PRESENT per C0

---

## 4. How Today CTA winner now works

`_resolveCtaWinner(TodayState)` returns `_CtaWinner` with priority:
1. Active review group (remaining > 0) → "继续本组复习 (剩余N词)" → review route
2. Pending review (no active group) → "先去复习" → review route
3. Goal completed → "今日目标已完成 ✅" → study route
4. Default → "开始今日学习" / "继续学习" → study route

Single `ElevatedButton` with key `today-primary-study-cta` — only one at any time.

---

## 5. What truth boundary was kept

- CTA winner uses ONLY existing `TodayState` active fields
- No `today_primary_action` assumed
- No candidate BR v0.1.7 rules used
- No candidate UI OptionC layout used
- Session is info-only, never overrides CTA
- Review group card is info-only (competing button removed)

---

## 6. What is still not done

| Phase | Status |
|---|---|
| C2: Review continuation / minimal review boundary | Pending |
| C3: Statistics minimal spec | Pending |
| C4: Streak truth-boundary hardening | Pending |
| C5: Test & closeout | Pending |

---

## 7. What must be done next

**C2: Review continuation / minimal review boundary.** Focus on:
- "本组完成 ≠ 今日复习完成" state separation
- `next group readiness` page/logic承接
- Review priority at main-factor level only (not full SRS)
- Corresponding tests

---

## 8. What not to touch

- Don't change CTA winner to use unpinned `today_primary_action`
- Don't implement complete CTA algorithm (scoring, reason set)
- Don't start statistics or streak hardening
- Don't modify backend business logic
- Don't create new endpoints

---

## 9. Files / modules to read first

1. `apps/mobile/lib/features/today/today_page.dart` — `_resolveCtaWinner()`, `_CtaWinner`, `_buildPrimaryCTA()` (C1 changes)
2. `apps/mobile/test/today_page_test.dart` — 6 new C1 CTA state matrix tests
3. `apps/api/src/domain/dev-store.ts` — `getOrCreateReviewGroup()`, review-related methods (C2 target)
4. `apps/api/src/domain/types.ts` — `TodayState`, `ReviewGroup` types
5. `docs/R4_OptionC_Entry_Sync_Result_v0.1.md` — C1-C5 readiness table

---

## 10. Current blockers / assumptions / risks

- `Assumption (temporary, not frozen): todayReviewPending > 0 accurately reflects backend's review-needed state`
- `Assumption (temporary, not frozen): CTA copy ("先去复习", "继续本组复习") is functional, not final Room 5 polish`
- `Assumption (temporary, not frozen): conservative path C1-A is sufficient without decision-support block`
- `Blocked if touched: Don't assume today_primary_action exists`
- `Blocked if touched: Don't use BR v0.1.7 rules as active truth`
- Risk: `todayReviewPending` might always be 0 in some code paths — C2 should verify this
- Risk: CTA labels are functional Chinese but may need Room 5 copy review

---

## 11. Whether ready for C2

**YES.** CTA winner landed, review-continuation-first established, Session subordinated, 161 tests pass, no scope creep.
