# Option C — C1 Result v0.1

**Date**: 2026-04-05
**Phase**: C1 — Today CTA Winner
**Path**: C1-A (conservative, no new contract patch)

---

## 1. Today CTA Current Mapping

| Priority | Condition | Label | Icon | Route | Accent |
|---|---|---|---|---|---|
| 1 | `activeReviewGroupId != null` AND `activeReviewGroupRemaining > 0` | 继续本组复习 (剩余N词) | 🔄 | review | info (blue) |
| 2 | `todayReviewPending > 0` (no active group) | 先去复习 | 🔄 | review | info (blue) |
| 3 | `dailyGoalStatus == 'completed'` | 今日目标已完成 ✅ | 📚 | study | success (green) |
| 4 | `dailyGoalStatus == 'not_started'` | 开始今日学习 | 📚 | study | primary (orange) |
| 4b | Other (partially_completed, in_progress) | 继续学习 | 📚 | study | primary (orange) |

Resolution logic: `_resolveCtaWinner(TodayState state)` → `_CtaWinner` (label, icon, route, accentColor, reason)

---

## 2. Path Selection

**Path C1-A** selected because:
- C0 Entry Sync Result clearly states all three clarifications = NOT PRESENT
- `today_primary_action` does not exist in codebase
- No decision-support block from backend
- Conservative path uses only existing active `TodayState` fields

---

## 3. Fallback / Loading / Empty / Error Handling

| Scenario | Behavior |
|---|---|
| Loading | CircularProgressIndicator (unchanged) |
| Error | Error state with retry button (unchanged) |
| No active group + no pending review | Falls to Priority 3 or 4 (new words) |
| All fields null/default | Falls to Priority 4 (new words) |
| Session active but no review | Session stays subordinate, CTA = new words |

---

## 4. Session Placement

- Session card remains at **section 5** (below CTA, goals, review info, check-in)
- Session card is **info-only**: shows "今日已有有效 Session" or "Session 进行中"
- **No competing CTA button** in Session card
- Session never overrides the primary CTA winner

---

## 5. Pending Boundaries

| Item | Status |
|---|---|
| `go_review` vs `go_new_words` detailed scoring | Pending — not implemented |
| `session_pending` in unified CTA arbitration | Pending — Session stays subordinate |
| `reason` enumeration full set | Pending — only `_CtaWinner.reason` for testing |
| Complete loading/error CTA copy strategy | Pending — basic fallback only |
| `today_primary_action` as active contract | NOT PRESENT — not assumed |

---

## 6. Biggest Remaining Risks

1. **Review-pending heuristic**: `todayReviewPending > 0` as CTA trigger depends on backend accurately computing pending review count. If backend always sets this to 0, Priority 2 never fires.
2. **CTA copy not final**: Labels like "先去复习" are functional but may need Room 5 polish.
3. **No backend validation of CTA decision**: Frontend resolves CTA from existing fields. If fields are stale or incorrect, CTA could mislead. This is acceptable for Path C1-A but would be resolved by Path C1-B (decision-support block).
