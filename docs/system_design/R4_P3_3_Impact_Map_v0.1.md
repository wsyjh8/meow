# R4_P3_3_Impact_Map_v0.1

- **Owner:** Room 4
- **Project:** 背单词喵喵 App
- **Type:** execution draft — impact map
- **Status:** Phase A draft
- **Date:** 2026-04-09
- **Basis:** R1_to_R4_P3_3_Execution_Handoff_v0.1.md

---

## 1. Affected Pages

| Page | File | Change Type | Change Summary |
|------|------|-------------|----------------|
| SpecHomePage | `spec/pages/home_page.dart` | UI delta | Add `_buildStudyEntry()` — dedicated "背单词" labeled `SpecCardHero` navigating to `/study`; inserted between `_buildMochiCard()` and existing `_buildMainCTA()` |
| StudyPage | `features/study/study_page.dart` | Submit flow + UI | Replace 2-button Row with `FsrsRatingButtons`; add `FsrsService` init; add `_isSubmitting` guard; add `_onRate()` method; remove "已掌握 ✓" snackbar |
| ReviewPage | `features/review/review_page.dart` | Submit flow + UI bridge | Replace 2-button Row with `FsrsRatingButtons`; add `FsrsService` init; add `_isSubmitting` guard; add `_onRate()` method with cloud-first + FSRS bridge pattern |

**Pages NOT affected this round:**
- `TodayPage` — no change; historical entrypoint preserved
- `SessionPage` — no change
- `SpecShell` / tab structure — no change
- `AppRouter` — no change; `/study → StudyPage` and `/review → ReviewPage` already correct

---

## 2. Affected Local Services and Infrastructure

| Component | File | Impact |
|-----------|------|--------|
| `FsrsService` | `core/memory/fsrs_service.dart` | **Consumed** from StudyPage and ReviewPage for `initCardForWord` + `rateCard`. No changes to FsrsService itself. |
| `StudyService` | `core/services/study_service.dart` | **Consumed** from StudyPage `_onRate()` with binary mapping ('know'/'forgot'). No changes to StudyService itself. |
| `AppDatabase` | `core/storage/drift/app_database.dart` | **Instantiated** as `AppDatabase()` in `initState` of StudyPage and ReviewPage. No schema changes. No new tables. |
| `LocalDatabase` | `core/storage/local_database.dart` | Already used by StudyPage via StudyService. No changes. |
| `FsrsRatingButtons` | `core/memory/widgets/rating_buttons.dart` | **Consumed** by StudyPage and ReviewPage. No changes to the widget itself. |
| `ReviewRating` enum | `core/memory/review_rating.dart` | **Consumed** as the callback type for `onRate`. No changes. |
| `defaultRatingConfigs` | `core/memory/widgets/rating_buttons.dart` | Labels (不认识/模糊/记得/秒答) remain as **CANDIDATES ONLY**. Not frozen this round. |
| `ApiClient` | `core/api/api_client.dart` | ReviewPage continues calling `submitReviewAttempt()` and `getNextReviewGroup()`. No changes to ApiClient. |

---

## 3. Cloud Contracts — Must Not Break

| Contract | Endpoint / Object | P3.3 Impact |
|----------|-------------------|-------------|
| `/me/today` | `ApiClient.getToday()` | **No change.** SpecHomePage continues calling for task card data. |
| `review_group` | `ApiClient.getNextReviewGroup()` | **No change.** ReviewPage still acquires its word queue from cloud review_group. |
| `submitReviewAttempt()` | `actionResult: 'correct'/'incorrect'` | **No change.** Binary mapping preserved: `again/hard → 'incorrect'`, `good/easy → 'correct'`. |
| `submitStudyAttempt()` | `actionResult: 'know'/'forgot'` | **No change.** Binary mapping preserved: `again/hard → 'forgot'`, `good/easy → 'know'`. |
| Idempotency key pattern | `'review-{groupId}-{wordId}'` | **No change.** Preserved exactly in ReviewPage `_onRate()`. |
| Group completion / settlement | `result.groupCompleted` + `result.settlement` | **No change.** ReviewPage completion flow and settlement snackbar preserved as-is. |

**API schema is NOT extended this round.** Cloud binary mapping (correct/incorrect, know/forgot) is preserved unchanged.

---

## 4. New Test Surface

| Test ID | Area | Description |
|---------|------|-------------|
| T-HOME-001 | Home entry visible | SpecHomePage renders a widget with "背单词" text |
| T-HOME-002 | Home entry routes correctly | Tapping "背单词" entry navigates to `/study` (StudyPage) |
| T-HOME-003 | Existing CTA not broken | Existing "继续学习" hero card still navigates to `/study` |
| T-HOME-004 | Review entry unchanged | "5分钟快速复习" still navigates to `/review` |
| T-BTN-001 | 4-button order (Study) | Slot order: again(1) / hard(2) / good(3) / easy(4), left-to-right |
| T-BTN-002 | 4-button order (Review) | Same slot order as StudyPage — must be identical |
| T-BTN-003 | Order stability | Button order unchanged after a rating is submitted and next card loads |
| T-THROTTLE-001 | Throttle (Study) | Rapid taps → only first submission processed; second tap no-ops |
| T-THROTTLE-002 | Throttle (Review) | Same for ReviewPage; cloud API called exactly once per word item |
| T-THROTTLE-003 | Buttons visually disabled | During submit, buttons have alpha 0.4 and `onTap = null` |
| T-BRIDGE-001 | Review continuation | review_group next item loads after 4-button submit |
| T-BRIDGE-002 | Group completion | `result.groupCompleted == true` → completion UI + settlement snackbar |
| T-BRIDGE-003 | FSRS bridge failure non-blocking | If card_states row missing, rateCard throws → caught silently → review continues |
| T-BRIDGE-004 | Binary mapping (Review) | again/hard → 'incorrect'; good/easy → 'correct' reaching cloud API |
| T-FALSE-001 | No false mastery (Study) | No "已掌握" / "已完成" / "奖励到账" text after rating |
| T-FALSE-002 | No false completion (Review) | No "完成" text unless group actually `groupCompleted == true` |
| T-FSRS-001 | initCardForWord idempotent | Calling twice for same wordId does not create duplicate card_states row |
| T-FSRS-002 | rateCard writes one review_log | Exactly one INSERT into review_logs per `rateCard()` call |
| T-REGRESS-001 | StudyService binary values | `submitStudyAttempt()` still accepts 'forgot' and 'know' |
| T-REGRESS-002 | /me/today unaffected | SpecHomePage today card data unchanged by Phase B |
