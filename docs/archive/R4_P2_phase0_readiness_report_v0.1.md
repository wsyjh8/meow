# R4 P2 Phase 0 Readiness Report v0.1

## 0. Header

| Field | Value |
|-------|-------|
| Title | R4 P2 Phase 0 Readiness Report |
| Owner | Room 4 |
| Scope | P2 Phase 0 readiness |
| Date | 2026-04-03 |
| Status | ready for Room 4 execution |

## 1. Executive Summary

Current repo is **partially ready** to enter P2 Phase 1, but **not ready to jump straight into Meow Home feature work without a minimum secondary read model / bridge layer**.

- Biggest blocker: `coins / fish_treats / exp` exist as reward ledger facts, but there is **no stable backend balance truth or secondary summary API** that a cat-home page can safely consume.
- Biggest reusable asset: P1 already has a working **reward settlement chain + today aggregation + session/check-in/streak facts + Flutter/API test skeleton**.

## 2. Current reusable facts from P1

The following P1 facts already exist and can be reused by P2:

### Rewards / settlements

- `RewardType = 'coins' | 'fish_treats' | 'exp'` exists in backend domain types: `apps/api/src/domain/types.ts`.
- Settlement entity and two-layer structure (`source event` + `reward_items`) exist in `apps/api/src/domain/types.ts`.
- Reward settlement creation is implemented in `apps/api/src/domain/dev-store.ts`.
- Reward placeholder issuance already happens for:
  - `effective_new_word` -> `coins` + `exp`
  - `review_group_completed` -> `coins` + `fish_treats`
- Manual settlement endpoints already exist:
  - `POST /api/v1/settlements/learning-rounds`
  - `GET /api/v1/settlements/:sourceEventId`
- Study / review submission already bridge into settlement creation inside:
  - `apps/api/src/controllers/study-attempts.controller.ts`
  - `apps/api/src/controllers/review-attempts.controller.ts`

### Balances / reward visibility

- Today aggregation already exposes `last_reward_settlement`, but **only as summary metadata**:
  - `source_event_id`
  - `reward_settlement_status`
- Flutter `ApiClient` already parses:
  - `TodayState.lastRewardSettlement`
  - `SettlementInfo`
  - `RewardItemInfo`
- Today page already shows a neutral settlement status card and explicitly avoids equating display with到账.

### Session / check-in / streak

- Session facts exist as stable backend truth:
  - `session_status`
  - `session_validation_status`
  - `effective_learning_count`
  - `effective_review_count`
- Check-in, learning day, and streak are already modeled as separate facts.
- Today aggregation already returns:
  - `has_checked_in_today`
  - `learning_day_today`
  - `current_streak`
  - `streak_basis_type`
  - `session_started_today`
  - `session_valid_today`

### Today aggregation touchpoints

- `GET /api/v1/me/today` is the current main aggregation read point.
- Existing Today read model already acts as the safest current cross-feature summary object.
- Existing Today page already links to `/study` and `/review`, so it is the most natural current entry hub to later add a Meow Home / secondary entry.

### Existing summary objects

- Backend:
  - `TodayState`
  - `Settlement`
  - `Session`
  - `StreakRecord`
  - `LearningDayRecord`
- Flutter:
  - `TodayState`
  - `LastRewardSettlement`
  - `SettlementInfo`
  - `RewardItemInfo`
  - `SessionInfo`
  - `CheckInResult`

## 3. Secondary mechanism implementation map

### 3.1 Meow Home landing

- Status: `Missing`
- Existing evidence:
  - No `meow_home`, `cat_home`, `pet_home`, `companion`, or equivalent feature directory under `apps/mobile/lib/features`.
  - Current router only exposes `/`, `/study`, `/review`, `/session`, `/check-in`, `/settlement`.
- Recommended landing:
  - Flutter: `apps/mobile/lib/features/meow_home/`
  - Router entry: `apps/mobile/lib/core/router/app_router.dart`
  - API model extension point: `apps/mobile/lib/core/api/api_client.dart`
- Can enter next batch directly: `Partially`
  - UI shell can start, but only after minimum secondary summary contract is defined.

### 3.2 Reward carry-over / reward visibility

- Status: `Partial`
- Existing evidence:
  - Reward settlement is created and queryable.
  - Today aggregation exposes only `last_reward_settlement`.
  - Study/review pages already show settlement status feedback.
- Gap:
  - No backend balance snapshot for `coins`, `fish_treats`, `exp`.
  - No dedicated reward balance read model.
  - No secondary-facing aggregation that converts raw reward ledger into durable current totals.
- Recommended landing:
  - Backend domain extension: `apps/api/src/domain/types.ts`
  - Backend read-model logic: `apps/api/src/domain/dev-store.ts`
  - Aggregation/controller bridge: likely extend `apps/api/src/controllers/today.controller.ts` or add a dedicated secondary summary controller
  - Flutter read model: `apps/mobile/lib/core/api/api_client.dart`
- Can enter next batch directly: `No, bridge first`

### 3.3 Feed action

- Status: `Missing`
- Existing evidence:
  - No `feed` action, endpoint, model, button placeholder, or inventory consumption logic found.
- Recommended landing:
  - Backend controller: `apps/api/src/controllers/` new feed-related controller
  - Backend domain logic: `apps/api/src/domain/dev-store.ts`
  - Flutter feature: `apps/mobile/lib/features/meow_home/` or `apps/mobile/lib/features/feed/`
- Can enter next batch directly: `Blocked`

### 3.4 Growth state

- Status: `Missing`
- Existing evidence:
  - No `mood`, `bond`, `energy`, `level`, `nickname`, cat summary, or companion state model found.
  - `exp` exists only as reward item type, not as current accumulated pet-facing state.
- Recommended landing:
  - Backend secondary domain state in `apps/api/src/domain/types.ts` + `apps/api/src/domain/dev-store.ts`
  - Secondary summary API or Today extension
  - Flutter model layer in `apps/mobile/lib/core/api/api_client.dart`
- Can enter next batch directly: `Blocked`

### 3.5 Outfit / inventory / room

- Status: `Missing`
- Existing evidence:
  - No `inventory`, `owned_items`, `shop`, `outfit`, `room`, `decoration`, or equip state found in current repo structure.
- Recommended landing:
  - Flutter feature directories:
    - `apps/mobile/lib/features/outfit/`
    - `apps/mobile/lib/features/room/`
  - Backend domain/inventory state:
    - `apps/api/src/domain/types.ts`
    - `apps/api/src/domain/dev-store.ts`
- Can enter next batch directly: `Blocked`

### 3.6 Daily companionship / copy / response

- Status: `Missing`
- Existing evidence:
  - No greeting hooks, response copy hooks, daily welcome abstraction, or growth prompt modal placeholder found.
  - Current copy is mostly page-local UI text only.
- Recommended landing:
  - Flutter feature or shared secondary copy layer:
    - `apps/mobile/lib/features/meow_home/`
    - or `apps/mobile/lib/shared/`
  - Backend optional response summary source if copy depends on factual state
- Can enter next batch directly: `Blocked`

## 4. Batch-readiness judgment

### Batch 1 — 奖励承接 + 喵喵主页

- Judgment: `Partially ready`
- Reason:
  - Reward settlement facts exist.
  - Today aggregation exists.
  - Router and feature structure are simple enough to add a new page.
  - But current repo lacks stable `coins / fish_treats / exp` totals and lacks cat-home summary truth.
- Need first:
  - Minimum backend secondary summary contract
  - Stable balance/read-model for `coins / fish_treats / exp`
  - Decision on whether Phase 1 uses `GET /me/today` extension or a dedicated secondary summary endpoint

### Batch 2 — 喂猫与成长

- Judgment: `Blocked`
- Reason:
  - No feed domain state
  - No fish-treat consumption logic
  - No pet state (`mood / bond / energy / level`)
  - `exp` is not yet accumulated into a growth model
- Need first:
  - Secondary entity/state definitions
  - Current totals/read model
  - Minimal feed command contract

### Batch 3 — 基础装扮

- Judgment: `Blocked`
- Reason:
  - No inventory model
  - No owned/equipped state
  - No coins spending logic beyond reward issuance
- Need first:
  - Inventory domain
  - Purchase/equip rules
  - Secondary summary/read model

### Batch 4 — 每日陪伴反馈

- Judgment: `Blocked`
- Reason:
  - No companion response layer
  - No copy hooks
  - No growth / reward / streak event-to-copy bridge
- Need first:
  - Define which factual triggers feed copy
  - Add minimal response surface in secondary summary or UI composition layer

### Batch 5 — smoke / bug 收口

- Judgment: `Partially ready`
- Reason:
  - Existing repo already has API e2e tests and Flutter model/widget tests.
  - Existing structure is suitable for adding batch-by-batch tests incrementally.
  - But there is no secondary smoke matrix yet because secondary features do not exist.
- Need first:
  - Secondary feature slices to land
  - Separate P2 smoke list that does not mix P1 rule bugs with P2承接 bugs

## 5. Active assumptions

- `Assumption (temporary, not frozen):` P2 Phase 1 should treat current reward ledger as reusable upstream truth, but not as final secondary-facing balance API.
- `Assumption (temporary, not frozen):` The safest first bridge is a minimal secondary summary read model, not direct UI-side aggregation over raw settlement history.
- `Assumption (temporary, not frozen):` `GET /api/v1/me/today` can be extended for Phase 1 only if payload growth stays small; otherwise a dedicated secondary summary endpoint is cleaner.
- `Assumption (temporary, not frozen):` Current reward amounts in `dev-store` are placeholder development values and must not be frozen as P2 product numbers.
- `Assumption (temporary, not frozen):` Session/check-in/streak should remain upstream motivational facts and not be rewritten by secondary mechanism work.

## 6. Active blockers

### Blocker 1: No stable balance truth for secondary currencies

- blocker title: No stable balance truth for `coins / fish_treats / exp`
- impact: Blocks Meow Home reward visibility, feed consumption, growth, and shop/inventory work
- why it blocks: Current repo can issue reward ledger items, but cannot answer "what is the user's current total balance?" as stable backend truth
- suggested next action: Add minimum backend balance/read-model contract before building P2 UI

### Blocker 2: No secondary summary object

- blocker title: No cat-home / companion summary read model
- impact: Blocks Batch 1 landing page and all downstream secondary views
- why it blocks: Current Today summary is learning-first and only exposes `last_reward_settlement`, not pet-facing status, balances, or growth state
- suggested next action: Define a minimal secondary summary object and decide whether it lives inside Today aggregation or a dedicated endpoint

### Blocker 3: EXP exists as reward type only, not as growth state

- blocker title: `exp` is issued but not accumulated into growth state
- impact: Blocks level-up, growth prompt, and visible companion progression
- why it blocks: There is no persisted `level`, `current_exp`, or unlock state to convert reward issuance into visible cat growth
- suggested next action: Introduce minimum growth state fields in backend domain before Batch 2

### Blocker 4: No inventory / ownership model

- blocker title: No inventory / owned-item truth
- impact: Blocks outfit, room, purchase, equip, and feed-item consumption flows
- why it blocks: Secondary consumables and cosmetic state currently have nowhere authoritative to live
- suggested next action: Keep Batch 3 blocked until a minimal inventory state shape is defined

### Blocker 5: Risk of frontend-only secondary illusion

- blocker title: Frontend can easily over-display beyond backend truth
- impact: High product risk for P2 trust and future rework
- why it blocks: Current repo already exposes enough reward fragments that UI could fake balances or pet state locally, but that would violate "backend truth first"
- suggested next action: Require backend-first summary fields for every P2 state shown as current truth

## 7. Recommended next step

Room 4 **should not start by directly building the Meow Home UI**. The repo is ready for **P2 Phase 1 only if Phase 1 starts with the minimum bridge/read-model slice first**.

### Recommended execution order

1. Add minimum backend secondary summary / balance truth.
2. Extend Flutter API model to consume that summary.
3. Add Meow Home route and lowest-fidelity page shell on top of that truth.

### Best first batch

Start with **Batch 1 only**, but treat it as:

- Step A: backend bridge/read model
- Step B: Flutter API model + route
- Step C: Meow Home MVP shell

### Best initial files to touch in Phase 1

- `apps/api/src/domain/types.ts`
- `apps/api/src/domain/dev-store.ts`
- `apps/api/src/controllers/today.controller.ts`
- `apps/mobile/lib/core/api/api_client.dart`
- `apps/mobile/lib/core/router/app_router.dart`
- `apps/mobile/lib/features/meow_home/` (new)

### Final recommendation

- Can Room 4 directly proceed with P2 Phase 1: `Yes, conditionally`
- Condition: the first implementation slice must be **minimum secondary truth + bridge**, not direct secondary feature rendering
- Must not do first: feed, growth, outfit, room, or copy systems before balance/summary truth exists
