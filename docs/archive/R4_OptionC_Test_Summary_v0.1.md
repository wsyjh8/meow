# Option C Test Summary v0.1

**Date**: 2026-04-05
**Phase**: C5 — Test & Closeout (Final)

---

## 1. Full Regression Results

| Suite | Count | Status |
|---|---|---|
| Flutter widget | 80 | All pass |
| Flutter analyze | 60 info | 0 errors, 0 warnings |
| Backend unit | 16 | All pass |
| Backend e2e | 75 | All pass |
| **Total** | **171** | **All pass** |

---

## 2. Tests by Option C Phase

| Phase | Tests | Type | File |
|---|---|---|---|
| C1 | 6 | Flutter widget | `today_page_test.dart` (CTA state matrix) |
| C2 | 4 | Flutter widget | `today_page_test.dart` (review boundary) |
| C3 | 3 | Backend e2e | `app.e2e-spec.ts` (stats_summary) |
| C4 | 3 | Flutter widget | `today_page_test.dart` (truth-boundary) |
| **Total C new** | **16** | | |

---

## 3. Coverage by Close Bar Item

### CB-OC-001: Today CTA Winner
| Test | What |
|---|---|
| CTA shows review continuation | Active group → "继续本组复习" |
| CTA shows review-first | Pending review → "先去复习" |
| CTA shows new word learning | No review → "开始今日学习" |
| CTA shows goal completed | All done → "今日目标已完成" |
| Session info-only | Session card has no competing CTA |
| Only one primary CTA | Single `today-primary-study-cta` key |

### CB-OC-002: Review Continuation
| Test | What |
|---|---|
| Goals card shows group count | "复习组" label (not item count) |
| Review progress note | Group done but daily not met → note shown |
| No note when daily met | Goal completed → no progress note |
| CTA falls through | All groups done → new words CTA |

### CB-OC-003: Statistics
| Test | What |
|---|---|
| stats_summary in response | Object with correct fields |
| learning_days independent | check_in does not increment learning_days |
| Existing fields intact | All secondary-summary fields still present |

### CB-OC-004: Streak Truth-Boundary
| Test | What |
|---|---|
| check_in ≠ learning_day | Checked-in but not learning day → separate display |
| Streak basis labeled | Streak chip contains "(签到)" |
| learning_day ≠ streak basis | Even with learning_day=true, streak labeled "(基于签到)" |

### CB-OC-005: Candidate vs Active
| Check | Result |
|---|---|
| `today_primary_action` used in code? | NO — only in comments documenting absence |
| BR v0.1.7 rules implemented? | NO |
| OptionC UI layout used? | NO — existing page structure |
| Stats contract assumed? | NO — additive field only |

### CB-OC-006: Regression
| Prior work | Status |
|---|---|
| P1 main mechanism | ✅ 75 e2e pass |
| P2 secondary mechanism | ✅ Feed/level/companion tests pass |
| Option A persistence | ✅ No persistence changes |
| Option B visual polish | ✅ Theme untouched |
| B2-1/B2-2 customize | ✅ 14 customize tests pass |
| B2-3 change_highlights | ✅ 5 e2e + 9 widget tests pass |

---

## 4. Risk Classification

| Risk | Level | Details |
|---|---|---|
| Candidate BR v0.1.7 treated as active | None | Verified: not used |
| Future streak basis implemented | None | Verified: not implemented |
| Copy drift (future dev adds unlabeled streak) | Minor | C4 added basis labels; future PR review needed |
| todayReviewPending always 0 | Minor | Backend sets to 0 by default; C2 CTA fallback handles this |
| Stats total counts only (no per-period) | Non-blocking | Acceptable for summary-first |
| learning_days undercount | Non-blocking | Historical data may be incomplete |
