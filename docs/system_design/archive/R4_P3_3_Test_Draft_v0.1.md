# R4_P3_3_Test_Draft_v0.1

- **Owner:** Room 4
- **Project:** 背单词喵喵 App
- **Type:** execution draft — test plan
- **Status:** Phase A draft
- **Date:** 2026-04-09
- **Basis:** R1_to_R4_P3_3_Execution_Handoff_v0.1.md

---

## 1. Home Entry Tests

### T-HOME-001: "背单词" entry visible in SpecHomePage
- **Given:** App opens; `/me/today` and secondary summary succeed (or fail gracefully)
- **When:** SpecHomePage renders
- **Then:** A widget with text "背单词" is visible in the scrollable content
- **Constraint:** The widget must have a non-null `onTap` (must be tappable)

### T-HOME-002: "背单词" entry navigates to StudyPage
- **Given:** SpecHomePage is rendered
- **When:** User taps the "背单词" entry
- **Then:** Navigator pushes `/study`; StudyPage loads (AppBar shows "学习新词")
- **Constraint:** No intermediate page, modal, or dialog appears

### T-HOME-003: Existing "继续学习" hero card not silently broken
- **Given:** SpecHomePage renders
- **When:** User taps the existing "继续学习" / "今日任务" hero card
- **Then:** Navigation to `/study` still works as before

### T-HOME-004: "5分钟快速复习" entry unchanged
- **Given:** SpecHomePage renders
- **When:** User taps "5 分钟快速复习" outlined card
- **Then:** Navigation to `/review` still works; ReviewPage loads

---

## 2. 4-Button Order Tests

### T-BTN-001: StudyPage slot order is again/hard/good/easy (left-to-right)
- **Given:** StudyPage renders a word card
- **When:** 4 rating buttons are visible
- **Then:** Button slot order: `[0]=again`, `[1]=hard`, `[2]=good`, `[3]=easy`
- **Implementation note:** Enforced via `defaultRatingConfigs` list order: `[again, hard, good, easy]`

### T-BTN-002: ReviewPage slot order is again/hard/good/easy (left-to-right)
- **Same as T-BTN-001** but for ReviewPage
- **Constraint:** Order MUST be identical to StudyPage; no page-specific reordering

### T-BTN-003: Button order stable after submit
- **Given:** A rating is submitted and the next word/card loads
- **When:** Next word's 4 buttons render
- **Then:** Slot order is still `again / hard / good / easy`

---

## 3. Throttle Tests

### T-THROTTLE-001: StudyPage — rapid taps submit only once
- **Given:** StudyPage shows a word; `_isSubmitting = false`
- **When:** User taps "记得" (good) twice in rapid succession
- **Then:**
  - `_onRate()` executes once (first tap)
  - Second tap is a no-op (guard check `_isSubmitting == true` → return)
  - Only one row inserted into `review_logs` for this word/session
  - Buttons re-enable after first submission completes

### T-THROTTLE-002: ReviewPage — rapid taps submit only once
- **Same as T-THROTTLE-001** but for ReviewPage
- **Constraint:** Cloud API (`submitReviewAttempt`) called exactly once per word item per tap cycle

### T-THROTTLE-003: Buttons visually disabled during submission
- **Given:** `_isSubmitting = true`
- **When:** `FsrsRatingButtons` renders with `enabled: false`
- **Then:**
  - Each `_RatingButton` renders with `color.withValues(alpha: 0.4)` (semi-transparent)
  - `InkWell.onTap = null` (non-interactive)

---

## 4. Cloud Bridge Tests

### T-BRIDGE-001: review_group continuation works after 4-button submit
- **Given:** ReviewPage loads review_group with ≥2 items; first item shown
- **When:** User rates item 1 (any rating)
- **Then:**
  - `ApiClient.submitReviewAttempt()` called with binary-mapped `actionResult`
  - `_loadReviewGroup()` called
  - Next item in group is shown (or group completion state if it was the last)

### T-BRIDGE-002: review_group completion detection preserved
- **Given:** ReviewPage loads review_group with 1 remaining item
- **When:** User rates the last item
- **Then:**
  - `result.groupCompleted == true` → group completion UI shown
  - Settlement snackbar shown if `result.settlement != null`
  - This flow is unchanged from v0.2.1 behavior

### T-BRIDGE-003: FSRS bridge failure does not block review continuation
- **Given:** ReviewPage shows an item whose `wordId` has NO `card_states` row
- **When:** User rates the item
- **Then:**
  - Cloud submit (`Step 5`) succeeds
  - `FsrsService.rateCard()` throws (no card row)
  - Exception caught silently inside `try { } catch (_) { }`
  - Review proceeds to next item; no error UI shown for the bridge failure

### T-BRIDGE-004: Binary mapping correct for all 4 ratings in ReviewPage
- `again` → cloud receives `actionResult = 'incorrect'`
- `hard` → cloud receives `actionResult = 'incorrect'`
- `good` → cloud receives `actionResult = 'correct'`
- `easy` → cloud receives `actionResult = 'correct'`

### T-BRIDGE-005: Binary mapping correct for all 4 ratings in StudyPage
- `again` → StudyService receives `actionResult = 'forgot'`
- `hard` → StudyService receives `actionResult = 'forgot'`
- `good` → StudyService receives `actionResult = 'know'`
- `easy` → StudyService receives `actionResult = 'know'`

---

## 5. No False Success Tests

### T-FALSE-001: No "已掌握" text after rating in StudyPage
- **Given:** User taps any rating button in StudyPage
- **Then:** No UI element contains "已掌握", "学习完成", "奖励", or "到账"
- **Note:** The existing "已掌握 ✓" snackbar is REMOVED in Phase B

### T-FALSE-002: No "已完成" text after rating in ReviewPage unless group actually complete
- **Given:** User taps any rating button when `result.groupCompleted == false`
- **Then:** No UI element implies the review session is fully done
- **Exception:** When `result.groupCompleted == true`, the completion state is accurate and intentional

---

## 6. Regression Tests

### T-REGRESS-001: StudyService still accepts 'forgot' and 'know'
- **Given:** Phase B maps `again/hard → 'forgot'`, `good/easy → 'know'`
- **Then:** These are the same values `StudyService.submitStudyAttempt()` has always received
- **No regression** — binary values unchanged

### T-REGRESS-002: /me/today cloud contract unaffected
- **Given:** Phase B does not call any new cloud endpoints
- **Then:** SpecHomePage and TodayPage `/me/today` response behavior unchanged

### T-REGRESS-003: SpecHomePage pull-to-refresh still works
- **Given:** User pulls down on SpecHomePage
- **Then:** `_loadData()` runs; TodayState and SecondarySummary reload; no crash

---

## 7. FSRS Idempotency Tests

### T-FSRS-001: `initCardForWord` is idempotent
- **Given:** `card_states` already has a row for `wordId`
- **When:** `initCardForWord(wordId)` called again
- **Then:** No duplicate row inserted (internal `getSingleOrNull` check prevents it)
- **Then:** Returns existing `CardStateData`

### T-FSRS-002: `rateCard` writes exactly one `review_log` per call
- **Given:** `rateCard(wordId, ReviewRating.good)` called once
- **Then:** Exactly one row in `review_logs` for this `wordId` and current timestamp

---

## 8. Manual Verification Checklist

Run `flutter run` and verify manually:

- [ ] SpecHomePage: "背单词" card is visible, above "继续学习" card
- [ ] Tap "背单词": StudyPage opens (AppBar: "学习新词")
- [ ] StudyPage: 4 buttons visible, order = 不认识 / 模糊 / 记得 / 秒答
- [ ] Tap "记得": loading state, next word loads, no "已掌握" text
- [ ] Tap rapidly: only one submission (no double advance)
- [ ] Tap "5分钟快速复习": ReviewPage opens
- [ ] ReviewPage: 4 buttons visible, same order as StudyPage
- [ ] Tap a rating: next review item loads (or group completion shown)
- [ ] Pull-to-refresh on SpecHomePage: works without error
- [ ] Back navigation from StudyPage/ReviewPage: returns to SpecHomePage without crash
