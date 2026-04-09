# Cursor Round Summary — P2 Phase 2D

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Implemented **P2 Phase 2D: Coins Spending + Inventory Truth**.

Specifically:
- Added `CatalogItem`, `OwnedItem`, `InventoryState`, `PurchaseResultStatus`, `PurchaseErrorCode` types
- Added dev catalog (5 items: 3 outfits, 2 room items)
- Added `purchaseItem()` to DevStore with coins deduction, level check, ownership check, idempotency
- Updated `getBalanceSnapshot()` to subtract `coinsSpent`
- Created `ShopController` (`GET /shop/catalog`, `POST /shop/purchases`)
- Created `InventoryController` (`GET /me/inventory`)
- Added Flutter API models and methods: `getShopCatalog()`, `getInventory()`, `purchaseItem()`
- Created minimal `InventoryPage` at `/inventory` route
- Added inventory entry button to Meow Home (replaced outfit/room placeholders)
- Added 10 e2e tests for catalog/inventory/purchase
- Added 4 Flutter model parse tests
- All 11 unit + 59 e2e + 40 Flutter tests pass

---

## 2. What changed

### New files:
- `apps/api/src/controllers/shop.controller.ts`
- `apps/api/src/controllers/inventory.controller.ts`
- `apps/mobile/lib/features/inventory/inventory_page.dart`

### Modified files:
- `apps/api/src/domain/types.ts` — Added CatalogItem, OwnedItem, InventoryState, PurchaseResultStatus, PurchaseErrorCode
- `apps/api/src/domain/dev-store.ts` — Added catalog, ownedItems, coinsSpent; getCatalog(), getInventory(), purchaseItem(); updated getBalanceSnapshot(), reset()
- `apps/api/src/controllers/index.ts` — Export shop + inventory controllers
- `apps/api/src/routes/routes.module.ts` — Register ShopController + InventoryController
- `apps/api/test/app.e2e-spec.ts` — Added 10 shop/inventory/purchase tests
- `apps/mobile/lib/core/api/api_client.dart` — Added shop/inventory methods + 6 new model classes
- `apps/mobile/lib/core/router/app_router.dart` — Added /inventory route
- `apps/mobile/lib/features/meow_home/meow_home_page.dart` — Replaced outfit/room buttons with inventory entry
- `apps/mobile/test/api_client_test.dart` — Added 4 Phase 2D model tests
- `apps/mobile/test/meow_home_page_test.dart` — Updated mock + button test
- `apps/mobile/test/today_page_test.dart` — Updated mock

---

## 3. What is already true now

- `GET /api/v1/shop/catalog` returns 5 active dev items
- `GET /api/v1/me/inventory` returns owned items + coins balance
- `POST /api/v1/shop/purchases` handles purchase with full validation:
  - Coins balance check
  - Level requirement check
  - Already-owned check
  - Idempotency replay protection
- Coins spending is real: `getBalanceSnapshot()` subtracts purchased amounts
- `GET /me/secondary-summary` coins balance is consistent with inventory
- Flutter has API bridge + minimal inventory/shop page
- Meow Home has entry to inventory page

---

## 4. What is still blocked

- Equip flow (toggle equipped state, apply to cat avatar)
- Room placement system
- Full shop UI with categories/tabs/visuals
- Complex pricing / discounts / limited items
- Interaction button (still placeholder)

---

## 5. What must be done next

**Phase 3 is now ready.** The truth layer is in place. Phase 3 scope:

1. **Equip flow** — `POST /me/inventory/:item_id/equip` to toggle equipped state
2. **Cat avatar with equipped items** — Meow Home renders which items are equipped
3. **Room view** — Show owned room items, maybe a simple grid
4. **Shop page** — Full visual shop with catalog cards (builds on current minimal page)

Alternatively, if the team wants a smaller step:
- Phase 3A: equip truth + minimal visual feedback
- Phase 3B: full shop/room UI

---

## 6. What not to touch

- Do NOT change coins earning rules (reward ledger)
- Do NOT add complex pricing / discounts
- Do NOT add item stacking
- Do NOT change main mechanism rules
- Do NOT freeze catalog prices

---

## 7. Files to read first

1. `apps/api/src/domain/types.ts` — CatalogItem, OwnedItem, InventoryState, PurchaseErrorCode
2. `apps/api/src/domain/dev-store.ts` — catalog array, purchaseItem(), getInventory(), getBalanceSnapshot() coins deduction
3. `apps/api/src/controllers/shop.controller.ts` — catalog + purchase endpoints
4. `apps/api/src/controllers/inventory.controller.ts` — inventory read endpoint
5. `apps/mobile/lib/features/inventory/inventory_page.dart` — minimal readiness UI
6. `docs/R4_P2_phase2D_implementation_report_v0.1.md` — full design details

---

## 8. Current risks

1. **In-memory store**: All state still in-memory. Server restart wipes purchases and inventory.
2. **Catalog hardcoded**: 5 items hardcoded in DevStore. Adding items requires code change. Acceptable for MVP.
3. **No equip visual**: Items can be purchased but not equipped or visually applied. This is by design (Phase 3 scope).
4. **EXP dual-source**: Still tracked separately (reward + feed). Level computation uses total but sources not unified.
5. **Mood formula interaction**: Unchanged from Phase 2A (consuming fish_treats affects balance-based mood component).

---

## 9. Recommended next prompt focus

> "Implement Phase 3A: Equip flow (POST equip/unequip endpoint + equipped state truth + Meow Home avatar reflects equipped items). Follow the controlled-slice approach."
