# R4_P3_3_Submit_Flow_Draft_v0.1

- **Owner:** Room 4
- **Project:** 背单词喵喵 App
- **Type:** execution draft — submit flow
- **Status:** Phase A draft
- **Date:** 2026-04-09
- **Basis:** R1_to_R4_P3_3_Execution_Handoff_v0.1.md

---

## 1. StudyPage 4-Button Submit Flow

### State variable added

```dart
bool _isSubmitting = false;
// Separate from existing _isLoading (which tracks word load).
// _isLoading: "next word is being fetched — show spinner"
// _isSubmitting: "rating is being submitted — disable buttons"
```

### `_onRate(ReviewRating rating)` — step sequence

```
Step 1: Guard check
  if (_isSubmitting || _currentWord == null) return;

Step 2: UI disable
  setState(() { _isSubmitting = true; _error = null; });

Step 3: FSRS card init (idempotent)
  await _fsrsService.initCardForWord(_currentWord!.wordId);
  // Creates card_states row if not exists (getSingleOrNull check inside).
  // No-op if row already exists.

Step 4: FSRS rating (local atomic write)
  await _fsrsService.rateCard(_currentWord!.wordId, rating);
  // Atomic transaction: INSERT review_logs (immutable) + UPDATE card_states.
  // This is the canonical local FSRS write.

Step 5: Binary mapping for cloud/local study record
  final binaryResult = (rating == ReviewRating.good || rating == ReviewRating.easy)
      ? 'know'
      : 'forgot';

Step 6: StudyService submit (local-first, async cloud sync)
  await _studyService.submitStudyAttempt(
    wordId: _currentWord!.wordId,
    bookId: _currentWord!.bookId,
    studyType: 'new',
    actionResult: binaryResult,
  );
  // StudyService writes to LocalDatabase (word_records) immediately.
  // Cloud API sync happens in the background (fire-and-forget).

Step 7: Load next word + re-enable
  await _loadNextWord();
  if (mounted) setState(() { _isSubmitting = false; });
```

### Error handling

| Failure point | Response |
|---------------|----------|
| Step 3 (`initCardForWord`) throws | `catch(e)` → set `_error = e.toString()`, set `_isSubmitting = false`. Show error UI. Do **NOT** advance to next word. |
| Step 4 (`rateCard`) throws | Same: catch, set `_error`, set `_isSubmitting = false`. Show error UI. Do **NOT** advance. |
| Step 6 (`submitStudyAttempt`) LocalDB write throws | Same pattern. Do **NOT** advance. |
| Cloud sync (background, inside StudyService) fails | StudyService handles internally (write queued locally). Does not surface to `_onRate()`. |

### Snackbar note

The **existing snackbar** in `_submitStudy()`:
```dart
// REMOVED — this text implies a result fact:
SnackBar(content: Text(actionResult == 'know' ? '已掌握 ✓' : '已标记模糊'))
```
This snackbar is **removed** in Phase B. The button click is a **rating input**, not a mastery confirmation. No replacement snackbar implying "already mastered" or "completed" is added.

### SpecHomePage refresh

NOT triggered in Phase B. `refresh_hints` contract not implemented. SpecHomePage's `/me/today` data refreshes on its own pull-to-refresh cycle.

---

## 2. ReviewPage 4-Button Submit Flow

### State variable added

```dart
bool _isSubmitting = false;
// Same pattern as StudyPage. Separate from _isLoading (group load spinner).
```

### `_onRate(ReviewRating rating)` — step sequence

```
Step 1: Guard check
  if (_isSubmitting || _currentItem == null || _reviewGroup == null) return;

Step 2: UI disable
  setState(() { _isSubmitting = true; _error = null; });

Step 3: Idempotency key (existing pattern preserved exactly)
  final idempotencyKey =
      'review-${_reviewGroup!.reviewGroupId}-${_currentItem!.wordId}';

Step 4: Binary mapping for cloud API (contract unchanged)
  final binaryResult = (rating == ReviewRating.good || rating == ReviewRating.easy)
      ? 'correct'
      : 'incorrect';

Step 5: Cloud submit — PRIMARY, must succeed
  final result = await _apiClient.submitReviewAttempt(
    reviewGroupId: _reviewGroup!.reviewGroupId,
    wordId: _currentItem!.wordId,
    actionResult: binaryResult,
    idempotencyKey: idempotencyKey,
  );
  setState(() { _groupCompleted = result.groupCompleted; });

Step 6: FSRS bridge — best-effort side-effect
  try {
    await _fsrsService.rateCard(_currentItem!.wordId, rating);
  } catch (_) {
    // Card may not exist in card_states if word was never studied in StudyPage.
    // Cloud result (Step 5) already committed. Silent failure is acceptable.
  }

Step 7: Settlement handling (existing logic, preserved exactly)
  if (result.groupCompleted && result.settlement != null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('本组完成！奖励状态：${result.settlement!.rewardSettlementStatus}'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

Step 8: Refresh group + re-enable
  await _loadReviewGroup();
  if (mounted) setState(() { _isSubmitting = false; });
```

### Error handling

| Failure point | Response |
|---------------|----------|
| Step 5 (`submitReviewAttempt`) throws | `catch(e)` → set `_error = e.toString()`, set `_isSubmitting = false`. Show error UI. Do **NOT** advance. FSRS bridge (Step 6) is **NOT** called. |
| Step 6 (`rateCard`) throws | Caught silently. Cloud submit already committed. Proceed to Step 7. |
| Step 8 (`_loadReviewGroup`) throws | Catch, set `_error`, set `_isSubmitting = false`. Existing group state shown. |

### review_group continuation contract

- Group completion detection (`result.groupCompleted`) preserved exactly as before
- Settlement snackbar logic preserved exactly as before
- Idempotency key format unchanged: `'review-{groupId}-{wordId}'`
- No change to `_loadReviewGroup()` behavior

---

## 3. Throttle / Debounce Strategy

Both pages use `_isSubmitting` boolean flag as the sole throttle mechanism:

```
On first button tap:
  _isSubmitting = true
  → FsrsRatingButtons renders with enabled: false
  → _RatingButton.onTap = null (non-interactive)
  → _RatingButton color rendered with alpha 0.4 (visual disabled state)

While _isSubmitting = true:
  Any subsequent tap calls _onRate() which immediately returns (guard at Step 1)
  No double-submission possible

On completion (success or error recovery):
  _isSubmitting = false
  → Buttons re-enable
```

No timer-based debounce is used. The `async/await` chain is the natural gate. The `enabled` prop on `FsrsRatingButtons` is the visual gate.

---

## 4. Mounted Guard

All `setState()` calls after any `await` are guarded with:

```dart
if (mounted) setState(...);
```

This prevents `setState()` after the page is disposed (e.g., user navigates away during a slow submit).

---

## 5. What Is NOT Implemented This Round

| Feature | Deferral Reason |
|---------|-----------------|
| `refresh_hints` | SpecHomePage not notified of submit events; contract not frozen |
| `previewDurations` | Interval preview below buttons deferred |
| `session_progress_summary` | Remaining count display deferred |
| `initCardForWord` in ReviewPage | Card may not exist; bridge failure is silent; full initialization deferred |
| `previewSchedule()` call | Schedule preview not shown this round |
