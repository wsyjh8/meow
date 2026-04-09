# Option C — C3 Result v0.1

**Date**: 2026-04-05
**Phase**: C3 — Statistics Minimal Spec
**Path**: C3-A (summary-first, no independent page)

---

## 1. Statistics Current Mapping

| Display | Data source | Truth boundary |
|---|---|---|
| 学习天数 (learning days) | `stats_summary.total_learning_days` | Based on `learning_day` records ONLY |
| 已学单词 (words learned) | `stats_summary.total_words_learned` | Study attempts with action_result='know' |
| 复习组 (review groups) | `stats_summary.total_review_groups_completed` | Completed review groups count |
| 签到 (check-ins) | `stats_summary.total_check_ins` | Check-in records (independent from learning_day) |
| 连续 N 天 (streak) | `stats_summary.current_streak` | Labeled "(基于签到)" — basis = check_in |

---

## 2. Path Selection

**Path C3-A** because:
- C0: minimal stats summary contract = NOT PRESENT
- No Room 1 pin on independent minimal page
- Conservative: summary card in Meow Home only

---

## 3. "学习天数 = learning_day" Boundary

| Display | ✅ Correct source | ❌ NOT sourced from |
|---|---|---|
| 学习天数 | `learningDays.filter(d => d.learning_day)` | check_ins count |
| 学习天数 | Per-day effective study (know/correct) | streak count |
| 签到 | `checkIns.length` | learning_day |
| 连续天数 | `streak.current_streak` (check_in basis) | learning_day |

Backend implementation in `buildStatsSummary()`:
```typescript
total_learning_days: this.learningDays.filter(d => d.learning_day).length
total_check_ins: this.checkIns.length  // separate
```

---

## 4. Stats Entry / Summary Shape

- **Location**: Meow Home page, section 7 (before Actions)
- **Format**: `MeowCard` with "📊 学习概览" header
- **Layout**: 4-column grid (学习天数 / 已学单词 / 复习组 / 签到) + streak row
- **Empty state**: If `stats_summary` is null (old backend), card hidden
- **NOT**: independent page, timeline, trend chart, BI dashboard

---

## 5. Pending Boundaries

| Item | Status |
|---|---|
| Independent statistics page | Pending — not pinned |
| Trend analysis / charts | Pending — not in scope |
| Stats contract clarification | NOT PRESENT — not assumed |
| Future streak basis switch | Pending — C4 will harden current basis |
| Weekly/monthly aggregation | Pending — only total counts |

---

## 6. Biggest Remaining Risks

1. **Stats are total counts**: No per-day/week/month breakdown. Acceptable for summary-first.
2. **learning_day retroactive accuracy**: If backend `updateLearningDay()` wasn't called for past days, `total_learning_days` may undercount. This is a data completeness issue, not a C3 boundary issue.
3. **Stats card position**: Placed after Equipped Display, before Actions. Room 5 may want different positioning.
