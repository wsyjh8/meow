# P2 Phase 2D Implementation Report — Coins Spending + Inventory Truth

**Date**: 2026-04-03
**Phase**: P2 Phase 2D
**Status**: Complete

---

## 1. Scope

This round establishes the **minimum truth layer for coins spending and inventory**, enabling Phase 3 (outfit/room UI) to build on real backend ground:

> Catalog exists -> User can purchase with coins -> Inventory tracks owned items -> Balance consistent across summary and inventory

This is **NOT** Phase 3. No equip flow, no room placement, no full shop UI. This is the truth-layer foundation.

---

## 2. Catalog Design

### Endpoint
`GET /api/v1/shop/catalog`

### Dev catalog (5 items)

| item_id | item_type | slot | name | coin_price | required_level |
|---|---|---|---|---:|---:|
| cat_hat_red | outfit | head | 红色小帽子 | 60 | 1 |
| cat_bow_blue | outfit | neck | 蓝色蝴蝶结 | 80 | 2 |
| cat_scarf_pink | outfit | neck | 粉色围巾 | 100 | 3 |
| room_lamp_warm | room_item | decor | 暖光小台灯 | 120 | 3 |
| room_rug_soft | room_item | floor | 柔软小地毯 | 150 | 4 |

Assumption (temporary, not frozen): Catalog items, prices, and level requirements are minimal dev data, not a frozen price table.

---

## 3. Inventory Truth Design

### Endpoint
`GET /api/v1/me/inventory`

### Response
```json
{
  "owned_items": [
    {
      "item_id": "cat_hat_red",
      "item_type": "outfit",
      "slot": "head",
      "owned_at": "2026-04-03T12:00:00Z",
      "equipped": false
    }
  ],
  "coins_balance": 140
}
```

- `owned_items`: backend truth array of all items the user owns
- `coins_balance`: real-time coins balance (earned minus spent)
- `equipped`: pre-reserved boolean field for Phase 3 equip flow (always `false` in Phase 2D)

---

## 4. Purchase Endpoint Design

### Endpoint
`POST /api/v1/shop/purchases`

### Request
```json
{ "item_id": "cat_hat_red" }
```
Header: `X-Idempotency-Key` (required)

### Success response
```json
{
  "purchase_result": {
    "status": "succeeded",
    "item_id": "cat_hat_red",
    "coins_spent": 60,
    "already_exists": false
  },
  "inventory": { "owned_items": [...], "coins_balance": 140 }
}
```

### Error codes
| Code | Condition |
|---|---|
| COINS_NOT_ENOUGH | Balance < coin_price |
| ITEM_ALREADY_OWNED | Already in owned_items |
| ITEM_NOT_FOUND | item_id not in active catalog |
| ITEM_LEVEL_LOCKED | User level < required_level |

---

## 5. Coins Spending Consistency

- `coinsSpent` tracked as a single accumulator in DevStore
- `getBalanceSnapshot()` subtracts `coinsSpent` from reward-earned coins
- Both `GET /me/secondary-summary` and `GET /me/inventory` read from the same `getBalanceSnapshot()`, ensuring consistency
- Purchase success is verified by checking inventory and secondary summary show matching reduced coins

---

## 6. Flutter Implementation

- `ApiClient`: added `getShopCatalog()`, `getInventory()`, `purchaseItem()`
- Models: `CatalogResponse`, `CatalogItemData`, `InventoryStateData`, `OwnedItemData`, `PurchaseResponse`, `PurchaseResultData`
- Minimal readiness UI: `InventoryPage` at `/inventory` route — shows coins balance, owned items, catalog with purchase buttons
- Meow Home: replaced outfit/room placeholder buttons with a single "收藏与商店" entry that navigates to inventory page

---

## 7. Assumptions (temporary, not frozen)

1. `Assumption (temporary, not frozen): catalog items and prices are minimal dev data, not a frozen price table.`
2. `Assumption (temporary, not frozen): no item stacking in MVP. Each item can only be owned once.`
3. `Assumption (temporary, not frozen): equipped field is pre-reserved as false. Equip flow is Phase 3.`
4. `Assumption (temporary, not frozen): coins spending only happens through purchases. No other spending path exists yet.`

## 8. Blockers

- `Blocked if touched: equip flow (Phase 3)`
- `Blocked if touched: room placement system (Phase 3)`
- `Blocked if touched: full shop UI with categories/tabs (Phase 3)`
- `Blocked if touched: complex pricing / discounts / limited items`

---

## 9. Ready for Phase 3?

**Yes.** The Phase 3 prerequisites are now met:

| Prerequisite | Status |
|---|---|
| Inventory model (owned items) | Done |
| Coins spending logic | Done |
| Purchase flow with idempotency | Done |
| Catalog (item definitions) | Done (5 dev items) |
| Equipped-state container | Done (pre-reserved as `false`) |
| Room domain state | Minimal (room_item in catalog, no placement yet) |

Phase 3 can now safely build equip flow + outfit/room UI on top of real truth.
