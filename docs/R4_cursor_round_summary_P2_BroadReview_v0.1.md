# Cursor Round Summary — P2 Broad Review / Closeout

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Conducted a **P2 broad review / implementation status closeout**. No code was changed. This was a review-only round that:

- Read and verified all backend endpoints, domain types, dev-store methods, and Flutter pages
- Confirmed all tests pass (11 unit + 49 e2e + 36 Flutter)
- Assessed each P2 phase slice against its original scope
- Evaluated Phase 3 readiness against concrete prerequisites
- Produced a structured judgment on whether to proceed to Phase 2D or Phase 3

---

## 2. What is already true now

### Backend (NestJS)
- **10 controllers** registered: Health, Today, StudyAttempts, ReviewGroups, ReviewAttempts, Sessions, CheckIns, Settlements, SecondarySummary, Feed
- **Domain types**: Word, StudyAttempt, ReviewGroup, ReviewAttempt, RewardSourceEvent, RewardLedgerItem, Settlement, TodayState, BalanceSnapshot, CatSummary, CompanionResponse, SecondarySummary, FeedRecord, Session, CheckInRecord, StreakRecord, LearningDayRecord
- **DevStore**: in-memory singleton with full state for all domain entities, feed records, feed accumulators, level computation
- **Key endpoints**: `GET /me/today`, `POST /me/new-words`, `GET /me/review-groups/next`, `POST /review-attempts`, `POST /settlements/learning-rounds`, `GET /me/secondary-summary`, `POST /me/feed`, `POST /sessions`, `POST /sessions/:id/finish`, `POST /check-ins`

### Flutter
- **7 routes**: today, study, review, session, check-in, settlement, meow-home
- **ApiClient**: 10 methods covering all endpoints + response models
- **Meow Home**: cat profile, resources, companion copy, real feed button, level-up dialog, placeholder interact/outfit/room buttons

### Test coverage
- 11 unit tests (level computation)
- 49 e2e tests (all endpoints + feed + level-up + companion response)
- 36 Flutter widget tests (pages + feed + level-up + companion copy)

---

## 3. What broad Phase 2 actually achieved

| Goal | Status |
|---|---|
| Meow Home | Done |
| Reward visibility | Done |
| Basic feed | Done |
| Cat growth (EXP/Level) | Done |
| Basic outfit system | NOT DONE (no truth layer) |
| Companion copy | Done |
| Check-in/Session visibility in secondary | Partial (via companion copy, not dedicated UI) |
| Smoke/bug status | Done (all tests pass) |

**Score: 6/8 fully done, 1 partial, 1 not done.**

---

## 4. Why Phase 3 is NOT ready

Phase 3 requires basic outfit / room / decoration. This needs:
1. Inventory model — does not exist
2. Owned-item truth — does not exist
3. Equipped-state truth — does not exist
4. Coins spending logic — does not exist (coins only accumulate)
5. Purchase flow with idempotency — does not exist
6. Outfit catalog — does not exist
7. Room domain state — does not exist

**0 of 7 prerequisites met.** Jumping to Phase 3 would mean building truth layer + UI in a single oversized round, violating the controlled-slice approach.

---

## 5. What must be done next

**Phase 2D: Coins Spending + Inventory Truth**

Recommended scope:
- `POST /api/v1/me/shop/purchase` — buy item with coins, idempotent, balance check
- `OwnedItem` / `InventoryRecord` types in domain
- Minimal outfit catalog (3-5 hardcoded dev items)
- `GET /api/v1/me/inventory` — list owned items
- No equip flow (Phase 3)
- No room system (Phase 3)
- Tests for purchase success, insufficient coins, idempotency, inventory read

After Phase 2D, Phase 3 can safely build equip flow + outfit UI + room on top of real truth.

---

## 6. What not to touch

- Do NOT start Phase 3 without inventory/purchase truth layer
- Do NOT add outfit/room UI without backend domain
- Do NOT change main mechanism reward rules
- Do NOT freeze growth numbers or companion copy
- Do NOT add push/notification/social systems
- Do NOT expand level beyond Lv10 without explicit instruction

---

## 7. Files to read first

For the next session:
1. `apps/api/src/domain/types.ts` — All domain types (look for what's missing: no Inventory, no OwnedItem, no PurchaseRecord)
2. `apps/api/src/domain/dev-store.ts` — Full state store (look at `getBalanceSnapshot()` for coins — no spending deduction exists)
3. `apps/api/src/controllers/feed.controller.ts` — Model for how a resource-consuming endpoint works (pattern to follow for purchase)
4. `apps/mobile/lib/features/meow_home/meow_home_page.dart` — Current UI (outfit/room buttons are placeholders)
5. `docs/R4_P2_broad_review_closeout_v0.1.md` — This review's full analysis

---

## 8. Current risks

1. **Scope creep into Phase 3**: Without Phase 2D, there's temptation to start outfit UI with placeholder truth. This has been the source of problems before (placeholder becomes assumed-truth).

2. **EXP dual-source**: Total EXP = reward ledger + feed accumulated, tracked separately. If a future change resets one source but not the other, level becomes inconsistent.

3. **Mood formula interaction**: Consuming fish treats reduces balance-based mood component (`fish_treats * 5`) while adding feed mood delta. Net effect can sometimes be negative. Known bridge-level artifact.

4. **In-memory store**: All state in DevStore is in-memory. Server restart wipes everything. Acceptable for MVP but limits real testing.

5. **Interaction button**: Still a placeholder. Minor but visible incomplete element.

---

## 9. Recommended next prompt focus

> "Implement P2 Phase 2D: Coins Spending + Minimal Inventory Truth. Create purchase endpoint with idempotency/balance-check, OwnedItem type, minimal outfit catalog (3-5 dev items), inventory read endpoint. Do NOT build equip flow, room system, or outfit UI — those are Phase 3."
