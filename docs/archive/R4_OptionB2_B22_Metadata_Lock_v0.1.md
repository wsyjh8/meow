# Option B2 B2-2 Metadata Lock v0.1

**Date**: 2026-04-04
**Updated**: B2-2D closeout — final lock

---

## 1. Original 5 Items

| item_id | item_type | slot | name | coin_price | level_required |
|---|---|---|---|---:|---:|
| cat_hat_red | outfit | head | 红色小帽子 | 60 | 1 |
| cat_bow_blue | outfit | neck | 蓝色蝴蝶结 | 80 | 2 |
| cat_scarf_pink | outfit | neck | 粉色围巾 | 100 | 3 |
| room_lamp_warm | room_item | decor | 暖光小台灯 | 120 | 3 |
| room_rug_soft | room_item | floor | 柔软小地毯 | 150 | 4 |

## 2. New 5 Items (LOCKED)

| item_id | item_type | slot | name | coin_price | level_required | emoji |
|---|---|---|---|---:|---:|---|
| cat_hat_straw | outfit | head | 草编小草帽 | 90 | 2 | 👒 |
| cat_bow_yellow | outfit | neck | 向日葵领结 | 110 | 3 | 🌻 |
| cat_scarf_stripe | outfit | neck | 条纹暖围巾 | 130 | 4 | 🧶 |
| room_plant_small | room_item | decor | 小盆栽绿植 | 100 | 2 | 🌿 |
| room_cushion_cloud | room_item | floor | 云朵小靠垫 | 140 | 3 | ☁️ |

---

## 3. Semantic Reuse Verification (B2-2D final)

| Check | Result |
|---|---|
| New slot introduced? | **NO** |
| New currency introduced? | **NO** |
| New state machine? | **NO** |
| New purchase/equip rules? | **NO** |
| New item_type? | **NO** |
| New API endpoint? | **NO** |
| New API field? | **NO** |

---

## 4. Contract Consumption Summary (B2-2D final)

### Fields consumed across B2-2

| Enhancement (phase) | API fields consumed | Source |
|---|---|---|
| Catalog display (B2-2B) | item_id, item_type, slot, name, coin_price, required_level | GET /shop/catalog |
| Emoji mapping (B2-2A) | item_id → static _itemEmoji map | Frontend static |
| Three-state display (B2-2B) | inventory.owned_items[].item_id, equipment.outfit/room | GET inventory + equipment |
| Slot-based preview (B2-2C) | equipment.outfit, equipment.room | GET /me/equipment |
| Empty slot indicators (B2-2C) | slot keys (head, neck, decor, floor) | Frontend static + equipment null check |
| Owned/total ratio (B2-2C) | catalog.items.length, inventory.owned_items.length | GET catalog + inventory |
| Equipped count (B2-2C) | equipment non-null slot count | GET /me/equipment |
| Save-up cue (B2-2C) | catalog.coin_price, inventory.coins_balance | GET catalog + inventory |
| Compare hints (B2-2C) | equipment slot values, catalog.name, inventory.coins_balance | GET all three |
| Slot label (B2-2C) | catalog.slot | GET /shop/catalog |

### Gaps discovered?

**None.** All features fully supported by existing fields.

### Patch needed?

**No. Confirmed across all 4 phases (A→B→C→D).**

---

## 5. Truth Boundary Final Verification (B2-2D)

| Content type | User-facing language | Misreadable as backend truth? |
|---|---|---|
| "已装备" chip | Confirmatory | ✅ Correct — backed by equipment snapshot |
| "已拥有" chip | Confirmatory | ✅ Correct — backed by inventory |
| "将替换当前 X" | Suggestive hint | ✅ Safe — uses "将" (will), not "已" (did) |
| "买后可替换 X" | Suggestive preview | ✅ Safe — uses "可" (could), conditional |
| "买后直接装上~" | Suggestive preview | ✅ Safe — preview hint, not confirmation |
| "还差 X 金币" | Informational | ✅ Safe — factual calculation |
| "空闲槽位，装上就生效~" | Suggestive hint | ✅ Safe — invitational language |
| "再攒一点就能入手~" | Motivational hint | ✅ Safe — not a promise |
| Style hints | Static copy | ✅ Safe — pure frontend decoration |

**No truth boundary violations found.**
