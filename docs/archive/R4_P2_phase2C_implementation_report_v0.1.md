# P2 Phase 2C Implementation Report — Companion Copy / Daily Response

**Date**: 2026-04-03
**Phase**: P2 Phase 2C
**Status**: Complete

---

## 1. Scope

This round implements the **minimum viable companion response system**:

> Backend generates copy based on current factual state -> Secondary summary includes companion_response -> Meow Home renders it lightly

This is **NOT** a full copy CMS, remote config, or narrative system. This is a controlled slice that:
- Adds `companion_response` to the secondary summary contract
- Generates `daily_greeting`, `post_learning_response`, `streak_node_response` from backend facts
- Renders them in Meow Home with light, warm UI
- Does NOT introduce push/notifications, complex dialogue trees, or remote copy management

---

## 2. Companion Response Contract

### Added to `GET /api/v1/me/secondary-summary`

```json
{
  "companion_response": {
    "daily_greeting": "今天也来陪陪我吧~",
    "post_learning_response": null,
    "streak_node_response": null
  }
}
```

### Field rules:
- `daily_greeting`: always present (string)
- `post_learning_response`: string or null (null when no relevant learning activity)
- `streak_node_response`: string or null (null when streak is not at a node)

---

## 3. Copy Trigger Rules

Assumption (temporary, not frozen): companion response strings and trigger rules in Phase 2C are minimal development copy rules based on current factual states, not a frozen narrative/copy system.

### daily_greeting

| Condition | Copy |
|---|---|
| Has effective learning today (`learning_day_today=true`) | 今天见到你真开心~ |
| Has checked in but no learning | 签到收到啦，今天要不要再学一点？ |
| Neither checked in nor learned | 今天也来陪陪我吧~ |

Priority: learning > check-in > default.

### post_learning_response

| Condition | Copy |
|---|---|
| `session_valid_today=true` | 刚刚那段专注时间很棒~ |
| `learning_day_today=true` AND `daily_goal_status=completed` | 今天的任务完成啦，我为你骄傲~ |
| `learning_day_today=true` AND `daily_goal_status=partially_completed/in_progress` | 已经做得不错了，再来一点点吧~ |
| Otherwise | null |

Priority: session_valid > goal_completed > partial > null.

### streak_node_response

| Streak Value | Copy |
|---|---|
| 3 | 连续 3 天了，小小的坚持也很了不起~ |
| 7 | 一周啦！你和我都在进步~ |
| 14 | 两周不间断，我越来越喜欢你了~ |
| 30 | 30 天！你是最棒的伙伴~ |
| Other | null |

---

## 4. UI Implementation

### Meow Home companion copy section
- Placed at the top of the content area, before the cat profile card
- Uses a soft orange-tinted card with rounded corners
- Daily greeting: pet icon + text
- Post-learning response: sparkle icon + lighter text (when present)
- Streak node response: fire icon + badge-style container (when present)
- Null fields do not occupy space
- Entire section absent when `companion_response` is null (backward compatible)

---

## 5. Assumptions (temporary, not frozen)

1. `Assumption (temporary, not frozen): companion response strings and trigger rules in Phase 2C are minimal development copy rules based on current factual states, not a frozen narrative/copy system.`
2. `Assumption (temporary, not frozen): streak nodes are fixed at 3/7/14/30 as a minimal development rule. Additional nodes and custom thresholds are deferred.`
3. `Assumption (temporary, not frozen): all copy is hardcoded in the backend store. Remote config / CMS is not part of this slice.`
4. `Assumption (temporary, not frozen): companion copy only responds to factual states. It does not create, assert, or modify any business facts.`

## 6. Blockers

- `Blocked if touched: full copy CMS / remote config / AB testing`
- `Blocked if touched: push / notification system`
- `Blocked if touched: complex dialogue tree / narrative system`
- `Blocked if touched: inventory / room / outfit truth`
- `Blocked if touched: recall / "I miss you" system`

---

## 7. Ready for Broad Phase 2 Remainder / Next Stage?

**Phase 2C is complete.** The secondary mechanism now has:
- Real feed action with resource consumption
- Real EXP -> Level truth with upgrade feedback
- Companion copy that responds to learning activity, check-in, and streaks

The core P2 secondary motivation loop is now functionally complete:
- Learn -> Earn rewards -> Feed cat -> Gain EXP/mood -> Level up -> See companion responses

**Remaining for broad Phase 2:**
1. Interaction action (placeholder button, not yet real)
2. Energy rules refinement
3. Coins spending (currently coins accumulate but have no spend path)

**Assessment:** Ready for broad Phase 2 remainder if scope is defined, OR can continue controlled slices for interaction/spending.
