# Option C — C4 Result v0.1

**Date**: 2026-04-05
**Phase**: C4 — Streak Truth-Boundary Hardening
**Path**: C4-A (current frozen, no basis switch)

---

## 1. check_in / learning_day / streak Current Mapping

| Fact | Meaning | Display term | NOT equal to |
|---|---|---|---|
| `check_in = true` | User tapped sign-in today | "已签到" | learning_day |
| `learning_day = true` | At least 1 know/correct today | "有效学习日" / "学习天数" | check_in or streak |
| `streak` (current_streak) | Consecutive days of check_in | "连续N天 (基于签到)" | learning_day count |

---

## 2. Path Selection

**Path C4-A** because:
- C0: future streak-basis switch = NOT PRESENT / candidate only
- C1/C2/C3: no Room 1 pin on streak-basis contract
- Conservative: harden current frozen relationships only

---

## 3. Future Stance Handling

| Expression | Status |
|---|---|
| "当前连续天数基于签到" | ✅ Kept as current fact |
| "未来可能改为按学习日" | ✅ Allowed as direction (if needed) |
| "已切到按学习日连续" | ❌ Prohibited — NOT implemented |
| "学习天数就是 streak" | ❌ Prohibited — NOT true |

No future stance found implemented as current fact in any page.

---

## 4. Pages / Helpers / Copy Modified

| File | Change | Why |
|---|---|---|
| `today_page.dart` line 518 | Streak chip: "🔥 连续N天" → "🔥 连续N天(签到)" | C4: add basis label for consistency |
| `meow_home_page.dart` line 552 | Streak chip: "🔥 N天连续" → "🔥 N天连续(签到)" | C4: add basis label for consistency |

### NOT changed (already correct)
- Today check-in/streak section: already has "(基于签到)" label
- Meow Home stats card: already has "(基于签到)" label
- Check-in page: already has "连续天数基于签到计算" explanation
- Backend: no changes needed (streak logic already correct)
- Variable names: no misleading names found (grep: 0 matches for learningStreak etc.)

---

## 5. Pending Boundaries

| Item | Status |
|---|---|
| streak_basis_type switch to learning_day | Pending — not implemented |
| check_in + learning_day combination basis | Pending — not implemented |
| Backfill / grace period | Pending — not implemented |
| Historical streak migration | Pending — not implemented |

---

## 6. Biggest Remaining Risks

1. **Copy drift**: Future development might add streak-related text without the "(签到)" basis label. C5 should do final audit.
2. **Backend streak logic assumption**: `getOrCreateStreak()` hardcodes `streak_basis_type: 'check_in'`. If someone changes this without updating UI, the labels would be wrong.
3. **Stats summary dependency**: Stats card reads `streak_basis` from backend — if backend changes basis without UI update, the label would lag.
