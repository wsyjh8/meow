# Option B Status v0.1

**Date**: 2026-04-04
**Current phase**: Phase 5 — Companion Copy Expansion + B1 Closeout
**Status**: B1 Complete — Recommending Close

---

## 1. Current Round: B1 Only

The first round of Option B defaults to **B1** only. B2 is a future candidate, NOT auto-included.

### B1 Includes (Phase 1-5)

| Phase | Scope | Key Files |
|---|---|---|
| Phase 1 | Global theme + shared widgets | `app.dart`, NEW `shared/theme.dart`, NEW `shared/widgets/*`, NEW `shared/animations.dart` |
| Phase 2 | Meow Home redesign | `meow_home_page.dart` (648 lines — full rewrite) |
| Phase 3 | Today Companion Card + CTA | `today_page.dart` (493 lines — major rework) |
| Phase 4 | Customize/Catalog upgrade | `customize_page.dart` (283 lines — major rework) |
| Phase 5 | Companion copy small expansion + closeout | `dev-store.ts` (getCompanionResponse) |

### B2 Excluded This Round

| Item | Why Excluded |
|---|---|
| Catalog expansion 5→14 | Needs backend seed + possible PG changes |
| companion_response typing (response_type, source_fact_tags) | New API contract — sync patch required |
| change_highlights[] backend field | New API field |
| Interaction backend API (cooldown, mood/bond impact) | New business rules — Room 2/3 review |
| High-fidelity art assets | Needs art production pipeline |

---

## 2. Interaction Boundary (HARD)

B1 interaction is **pure frontend local feedback only**.

**Allowed:**
- More specific button label (e.g., "摸摸它" instead of "互动")
- Button style enhancement (colors, shape, icon)
- Click micro-feedback (scale animation, ripple)
- Random companion response text displayed locally
- Button cooldown visual (frontend timer, no backend state)

**NOT Allowed:**
- New backend endpoint
- Mood / bond / reward changes from interaction
- Typed interaction payload
- Cooldown state persisted to backend
- Interaction history tracking
- Any business fact created by interaction

---

## 3. Catalog Boundary (HARD)

Catalog expansion is **B2 candidate only**.

**B1 allowed:**
- Visual upgrade of existing 5 items (card layout, icons, status badges)
- Better three-state display (unowned/owned/equipped)
- Tabs/segmented control for organization

**NOT Allowed:**
- Adding new items to catalog
- New slot types
- New price tiers
- New level-lock rules
- New currency types

---

## 4. Done Bar (B1 Close Criteria)

All of these must be met for B1 to close:

1. ✅ Global theme applied — warm colors, rounded corners, "slightly cute" feel
2. ✅ Meow Home redesigned — cat is page focal point with breathing animation, resource bar, Growth Card, status bubble
3. ✅ Today Companion Card upgraded — warmer visuals, doesn't overpower main CTA
4. ✅ Customize three-state clear — unowned/owned/equipped visually distinct, top preview area, tabs
5. ✅ Interaction button has visible frontend response — not just "coming soon"
6. ✅ Companion copy small expansion visible — at least 8 greeting variants
7. ✅ `flutter test` passes (widget tests updated for new structure)
8. ✅ `flutter analyze` 0 errors
9. ✅ Backend tests unaffected (no API changes)

---

## 5. Code Impact Analysis

### Files to be Modified

| File | Lines | Impact Level | Phase |
|---|---|---|---|
| `apps/mobile/lib/app/app.dart` | 23 | Full rewrite (theme) | Phase 1 |
| `apps/mobile/lib/shared/shared.dart` | 1 | Becomes export barrel | Phase 1 |
| `apps/mobile/lib/features/meow_home/meow_home_page.dart` | 648 | **Full rewrite** | Phase 2 |
| `apps/mobile/lib/features/today/today_page.dart` | 493 | Major rework | Phase 3 |
| `apps/mobile/lib/features/customize/customize_page.dart` | 283 | Major rework | Phase 4 |
| `apps/api/src/domain/dev-store.ts` | ~50 lines in getCompanionResponse | Small patch | Phase 5 |

### New Files to Create

| File | Purpose | Phase |
|---|---|---|
| `apps/mobile/lib/shared/theme.dart` | Color palette, text styles, card theme | Phase 1 |
| `apps/mobile/lib/shared/widgets/meow_card.dart` | Shared rounded card component | Phase 1 |
| `apps/mobile/lib/shared/widgets/meow_chip.dart` | Status tag/chip component | Phase 1 |
| `apps/mobile/lib/shared/animations.dart` | Shared animation utilities | Phase 1 |

### Tests to Update

| Test File | Lines | Why |
|---|---|---|
| `test/meow_home_page_test.dart` | 686 | Keys, text, structure all change |
| `test/today_page_test.dart` | 166 | Companion Card structure change |
| `test/app_test.dart` | 10 | Theme change verification |

### Files NOT Touched

| File | Why |
|---|---|
| `core/api/api_client.dart` | No API changes in B1 |
| `core/router/app_router.dart` | No routing changes |
| `features/study/study_page.dart` | Learning page unchanged in B1 |
| `features/review/review_page.dart` | Review page unchanged in B1 |
| `features/session/session_page.dart` | Session page unchanged in B1 |
| `features/check_in/check_in_page.dart` | Minor style only if time permits |
| `features/settlement/settlement_page.dart` | Still placeholder |
| `features/inventory/inventory_page.dart` | Superseded by customize page |
| All backend files (except companion copy) | No backend changes |

---

## 6. Assumptions

1. `Assumption (temporary, not frozen): B1 uses pure Flutter built-in animations, no external packages (Lottie/Rive).`
2. `Assumption (temporary, not frozen): Interaction button is pure frontend, no backend API.`
3. `Assumption (temporary, not frozen): Catalog stays at 5 items, visual upgrade only.`
4. `Assumption (temporary, not frozen): Art assets use emoji + styled text + color blocks as placeholders.`
5. `Assumption (temporary, not frozen): Widget tests will be updated to match new UI structure.`

## 7. Blockers

None for Phase 1 start.

## 8. Risks

1. **Meow Home full rewrite** (648 lines) — highest risk, most complex page. Need to preserve all business logic while redesigning UI.
2. **Widget test updates** — 686 lines of meow_home_page_test.dart will need significant updates to match new Key names and structure.
3. **Theme cascade** — changing global theme affects all pages, including those not being redesigned in B1. May need spot fixes.

## 9. Phase 1 Complete

### Delivered
- `shared/theme.dart` — MeowColors (20+ tokens), MeowRadius, MeowSpacing, MeowTextStyles, MeowShadows, MeowTheme.light
- `shared/animations.dart` — MeowFadeIn, MeowAnimatedNumber, MeowAnimatedProgress, MeowBounceButton, createBreathingController, meowPageRoute
- `shared/widgets/meow_card.dart` — MeowCard, MeowCardWarm
- `shared/widgets/meow_chip.dart` — MeowChip with 7 variants
- `shared/widgets/resource_badge.dart` — ResourceBadge (compact + full)
- `shared/widgets/preview_container.dart` — PreviewContainer (gradient top area)
- `app.dart` — Now uses MeowTheme.light
- `app_router.dart` — Soft page transitions (fade + slide)

### Test results
- flutter test: 44/44 pass
- flutter analyze: 22 info hints, 0 errors

### Ready for Phase 2
**Yes.** Visual foundation is in place. Phase 2 (Meow Home redesign) can use all shared components.
