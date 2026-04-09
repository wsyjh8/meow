# P2 Phase 3 Implementation Report — Basic Outfit / Room (Minimal Equip Flow + UI)

**Date**: 2026-04-03
**Phase**: P2 Phase 3
**Status**: Complete

---

## 1. Scope

This round completes the **minimum viable equip flow and outfit/room UI**:

> Purchase item -> Own it -> Equip it -> See it in Meow Home

This is **NOT** a full shop system, room placement, or visual polish round. This is the final P2 piece:
- Equipped-state truth (backend, per-slot)
- Equip/unequip endpoints with idempotency
- Customize page (combined outfit + room, with buy/equip/equipped states)
- Meow Home reflects equipped items via `equipped_preview`
- Secondary summary includes `equipped_preview` for sync

---

## 2. Equipped-State Truth Design

### Storage
Two maps in DevStore: `equippedOutfit` and `equippedRoom`, each `Record<string, string | null>` (slot -> item_id).

### Endpoint
`GET /api/v1/me/equipment`

```json
{
  "equipped_snapshot": {
    "outfit": { "head": "cat_hat_red", "neck": null },
    "room": { "decor": "room_lamp_warm" }
  }
}
```

Rules:
- One item per slot
- Null = nothing equipped in that slot
- Outfit and room tracked separately

---

## 3. Equip Endpoint Design

### Equip
`POST /api/v1/me/equipment/equip`

Request: `{ "item_id": "cat_hat_red" }` + `X-Idempotency-Key` header

Validation:
- Item must exist in catalog
- Item must be owned
- Idempotency: same key replay returns `already_exists: true`

Behavior:
- Sets item in its slot (from catalog `slot` field)
- Replaces any previous item in the same slot
- Updates `equipped` flag on OwnedItem records
- Returns updated `equipped_snapshot`

Error codes: `ITEM_NOT_OWNED`, `ITEM_NOT_FOUND`

### Unequip
`POST /api/v1/me/equipment/unequip`

Same validation. Clears the slot if the specified item is currently equipped there.

---

## 4. Outfit / Room UI Structure

### Route: `/customize` (CustomizePage)

Combined view with two sections:
- **装扮** (Outfit) — lists outfit items from catalog
- **小窝** (Room) — lists room items from catalog

Each item shows one of three states:
- **未拥有**: orange "购买" button with price
- **已拥有**: green "装备" button
- **已装备**: orange "已装备" tag (disabled)

Top: coins balance card. Actions trigger purchase or equip via API, with loading protection.

---

## 5. Meow Home Sync

**Method: equipped_preview in secondary summary (Option A)**

`GET /api/v1/me/secondary-summary` now includes:
```json
"equipped_preview": {
  "head": "cat_hat_red",
  "neck": null,
  "decor": "room_lamp_warm"
}
```

Meow Home renders a "当前装扮" card when any slot has a non-null value. Shows `slot: item_id` for each equipped item.

Returning from Customize page triggers a summary refresh to pick up changes.

---

## 6. Assumptions (temporary, not frozen)

1. `Assumption (temporary, not frozen): equipped state is slot-based with one item per slot. No multi-equip or layering.`
2. `Assumption (temporary, not frozen): equipping automatically replaces previous item in same slot. No confirmation dialog.`
3. `Assumption (temporary, not frozen): equipped_preview in secondary summary is a flat merge of outfit + room slots. No visual rendering in this phase.`
4. `Assumption (temporary, not frozen): room items use simple slot-based equip (same as outfit). No coordinate-based placement.`
5. `Assumption (temporary, not frozen): catalog items and prices are minimal dev data, not frozen.`

## 7. Blockers

- `Blocked if touched: room coordinate placement system`
- `Blocked if touched: visual avatar layered rendering`
- `Blocked if touched: complex shop UI with tabs/categories`
- `Blocked if touched: item stacking / duplicates`
- `Blocked if touched: item rarity / discount / limited-time events`

---

## 8. Ready for Phase 4?

**P2 is now functionally complete.** The full secondary motivation loop works:

1. Learn words -> earn coins/fish_treats/exp
2. Feed cat -> gain mood/exp -> level up
3. See companion responses based on activity
4. Buy items from shop with earned coins
5. Equip items -> see changes in Meow Home

**Phase 4 scope** would likely be one of:
- Visual polish / real art assets for equipped items
- More catalog items / content expansion
- Interaction action (still placeholder)
- Persistence layer (replace in-memory DevStore with real DB)
- Performance / UX refinement round
