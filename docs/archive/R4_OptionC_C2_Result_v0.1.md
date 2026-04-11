# Option C — C2 Result v0.1

**Date**: 2026-04-05
**Phase**: C2 — Review Continuation / Minimal Review Boundary
**Path**: C2-A (current frozen + active API, no review summary clarification)

---

## 1. Review Continuation Current Mapping

| State | Today CTA (C1) | Review Group Card | Review Progress Note |
|---|---|---|---|
| Active group, remaining > 0 | "继续本组复习 (剩余N词)" | Shows "当前复习组 · 剩余N词" | Hidden |
| No active group, todayReviewPending > 0 | "先去复习" | Hidden | Hidden |
| Group done, daily target not met | "继续学习" (new words) | Hidden | "已完成 N/M 组复习 · 进行中" |
| All review groups done + daily met | "今日目标已完成" | Hidden | Hidden |

---

## 2. Path Selection

**Path C2-A** because:
- C0 Entry Sync Result: review/group summary clarification = NOT PRESENT
- C1 did not add any Room 1 pinned review summary block
- Conservative path: use existing `TodayState` fields only

---

## 3. "本组完成 ≠ 今日复习完成" Boundary

### Backend (already correct, NOT changed)
- `submitReviewAttempt()` increments `today_review_completed` counter on group completion
- `daily_goal_status` only becomes 'completed' when BOTH new + review targets met
- E2e test explicitly verifies this (frozen rule)

### Frontend (C2 changes)
| Layer | Before C2 | After C2 |
|---|---|---|
| Review page completion | "本组复习已完成，但今日任务可能还未完成" | "本组复习已完成，今日复习进度已更新。是否还有后续任务，以今日目标为准。" |
| Today Goals Card label | "🔄 复习" | "🔄 复习组" (clarifies group-count unit) |
| Today review section | Only shows active group card | Shows active group card OR review progress note |
| Today review progress note | Did not exist | "已完成 N/M 组复习 · 进行中" when partial |

---

## 4. Readiness Handling

- **Next-group readiness**: NOT determined by UI. No local remaining count → next group logic.
- When active group exists → show continuation. When not → backend decides via `todayReviewPending`.
- Progress note shows only group-count progress from backend fields.
- **No UI-fabricated readiness inference.**

---

## 5. Pending Boundaries

| Item | Status |
|---|---|
| Complete SRS | Pending — not implemented |
| Group size / interval algorithm | Pending — fixed at 3 |
| Review priority engine | Pending — only main-factor (has active group → continue) |
| Review/group summary contract | NOT PRESENT — not assumed |
| Next-group readiness algorithm | Pending — only backend todayReviewPending used |

---

## 6. Biggest Remaining Risks

1. **todayReviewTarget accuracy**: Currently set to 1 on group creation. If target needs to be > 1 (multiple groups per day), the progress note and Goals Card would need backend to set correct target.
2. **No review progress for zero-group-day**: If no group was ever created today, review progress shows 0/0 or is hidden. Acceptable for MVP.
3. **Group completion clear logic**: When backend clears `active_review_group_id` after completion, the Today page correctly falls through. But if the clear doesn't happen (edge case), the card might linger.
