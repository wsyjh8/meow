# R4_P3_3_Rating_Mapping_Matrix_v0.1

- **Owner:** Room 4
- **Project:** 背单词喵喵 App
- **Type:** execution draft — rating mapping matrix
- **Status:** Phase A draft
- **Date:** 2026-04-09
- **Basis:** R1_to_R4_P3_3_Execution_Handoff_v0.1.md

---

## 1. Three-Layer Contract (from governance freeze)

The 4-button system is always separated into three layers:

| Layer | Content | Frozen? |
|-------|---------|---------|
| **Display Layer** | Two-character Chinese UI text (e.g., 不认识 / 模糊 / 记得 / 秒答) | **CANDIDATE ONLY** — final wording pending Room 3 + Room 5 freeze |
| **Semantic Layer (Canonical Rating Key)** | `again \| hard \| good \| easy` | **FROZEN** (governance contract) |
| **Adapter Layer (FSRS Grade Int)** | `1 \| 2 \| 3 \| 4` | **FROZEN** (governance contract) |

**Rules:**
- Chinese copy changes do **NOT** affect canonical keys or FSRS grades
- FSRS grade integers do **NOT** appear in the cloud API
- UI copy (Chinese text) is **NOT** persisted to DB, API, or local repo
- Canonical keys are the internal contract boundary between UI and service layers

---

## 2. Rating Mapping Matrix

| UI Slot | UI Candidate Copy | Canonical Key | FSRS Grade Int | Page Scope | Local Write Target | Study Cloud Binary | Review Cloud Binary |
|---------|------------------|--------------|---------------|-----------|-------------------|-------------------|---------------------|
| Slot 1 (leftmost) | 不认识 **(CANDIDATE)** | `again` | `1` | Study + Review | `FsrsService.rateCard(wordId, ReviewRating.again)` → `card_states` + `review_logs` | `'forgot'` → `StudyService.submitStudyAttempt()` | `'incorrect'` → `ApiClient.submitReviewAttempt()` |
| Slot 2 | 模糊 **(CANDIDATE)** | `hard` | `2` | Study + Review | `FsrsService.rateCard(wordId, ReviewRating.hard)` → `card_states` + `review_logs` | `'forgot'` → `StudyService.submitStudyAttempt()` | `'incorrect'` → `ApiClient.submitReviewAttempt()` |
| Slot 3 | 记得 **(CANDIDATE)** | `good` | `3` | Study + Review | `FsrsService.rateCard(wordId, ReviewRating.good)` → `card_states` + `review_logs` | `'know'` → `StudyService.submitStudyAttempt()` | `'correct'` → `ApiClient.submitReviewAttempt()` |
| Slot 4 (rightmost) | 秒答 **(CANDIDATE)** | `easy` | `4` | Study + Review | `FsrsService.rateCard(wordId, ReviewRating.easy)` → `card_states` + `review_logs` | `'know'` → `StudyService.submitStudyAttempt()` | `'correct'` → `ApiClient.submitReviewAttempt()` |

---

## 3. Binary Mapping Rules

### StudyPage
```
again | hard  →  actionResult = 'forgot'
good  | easy  →  actionResult = 'know'
```

### ReviewPage
```
again | hard  →  actionResult = 'incorrect'
good  | easy  →  actionResult = 'correct'
```

These mappings are applied at call time in each page's `_onRate()` method. They are **NOT** persisted. The local FSRS layer receives the full `ReviewRating` enum value (all 4 grades). The cloud layer receives only the binary string.

---

## 4. Slot Order Invariant

The UI slot order (`again=Slot1`, `hard=Slot2`, `good=Slot3`, `easy=Slot4`, left-to-right) **MUST be identical** in StudyPage and ReviewPage.

This invariant is enforced by both pages consuming the same `defaultRatingConfigs` list from `rating_buttons.dart` without reordering or filtering.

```
// defaultRatingConfigs order in rating_buttons.dart (verified):
[again("不认识"), hard("模糊"), good("记得"), easy("秒答")]
```

Neither page may reorder, filter, or reverse this list in Phase B.

---

## 5. Candidate Copy Note

The labels in `defaultRatingConfigs` at the time of Phase B implementation:
- `again` → "不认识" (sublabel: "重来")
- `hard` → "模糊" (sublabel: "有点印象")
- `good` → "记得" (sublabel: "想了一下")
- `easy` → "秒答" (sublabel: "很简单")

These are **in-code candidates**. A comment is added wherever the button is rendered:

```dart
// P3.3: 4-button rating. CANDIDATE labels — final wording pending Room 3 + Room 5 freeze.
```

Room 4 does **NOT** modify these labels in Phase B, and does **NOT** hardcode alternative labels.

---

## 6. What Is NOT Mapped This Round

| Feature | Status |
|---------|--------|
| `previewDurations` (interval preview below buttons) | Deferred — `FsrsService.previewSchedule()` available but not called |
| `session_progress_summary` | Deferred |
| `refresh_hints` | Deferred — SpecHomePage not refreshed after submit |
| `card_result_type` distinction (new_word / review_item) | Deferred |
| `next_due_at` | Deferred |
| Final Chinese button text | Pending Room 3 + Room 5 freeze |
