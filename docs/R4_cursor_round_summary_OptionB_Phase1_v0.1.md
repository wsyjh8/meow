# Cursor Round Summary — Option B, Phase 1

**Handoff document for the next Cursor session.**

---

## 1. This round did what

Implemented **Option B Phase 1: Global Theme + Shared Components**. No page restructuring.

- Created full design token system (MeowColors, MeowRadius, MeowSpacing, MeowTextStyles, MeowShadows)
- Created MeowTheme.light with custom ThemeData for all Material components
- Created 5 shared widget components (MeowCard, MeowChip, ResourceBadge, PreviewContainer, MeowCardWarm)
- Created animation utilities (MeowFadeIn, MeowAnimatedNumber, MeowAnimatedProgress, MeowBounceButton, breathing controller, soft page route)
- Updated app.dart to use MeowTheme.light
- Updated router to use soft fade+slide page transitions
- All 44 Flutter tests pass, 0 errors on analyze

---

## 2. What theme / design tokens now exist

| Category | Tokens |
|---|---|
| Colors | 20+ (primary/secondary/background/surface/text/status/companion/UI) |
| Radius | xs(8) sm(12) md(16) lg(20) xl(24) pill(999) |
| Spacing | xs(4) sm(8) md(12) lg(16) xl(20) xxl(24) xxxl(32) |
| Text styles | headline, title, subtitle, body, bodySmall, caption, label, number |
| Shadows | card (light), cardHover (medium), none |
| Theme | MeowTheme.light — full ThemeData (AppBar, Card, Button, Chip, SnackBar, Dialog, Progress, Divider, Icon) |

**Color palette**: Cream background (#FFF8F0) + warm orange primary (#FF8C42) + soft pink secondary (#FFB5C2) + warm brown text (#3D2C1E)

---

## 3. What shared components now exist

| Component | File | Purpose | Reused in |
|---|---|---|---|
| MeowCard | `shared/widgets/meow_card.dart` | Rounded card with shadow | All pages |
| MeowCardWarm | Same file | Warm-tinted variant | Companion areas |
| MeowChip | `shared/widgets/meow_chip.dart` | Status tag with 7 variants | Level, mood, status badges |
| ResourceBadge | `shared/widgets/resource_badge.dart` | Coins/fish/exp display | Resource bars |
| PreviewContainer | `shared/widgets/preview_container.dart` | Gradient top area | Meow Home, Customize |

---

## 4. What animation utilities now exist

| Utility | Type | Use Case |
|---|---|---|
| MeowFadeIn | Implicit (TweenAnimationBuilder) | Cards appearing on load |
| MeowAnimatedNumber | Implicit (IntTween) | Coins/exp number changes |
| MeowAnimatedProgress | Implicit (TweenAnimationBuilder) | EXP/level progress bar |
| MeowBounceButton | Explicit (AnimationController) | Button press micro-feedback |
| createBreathingController | Explicit (repeat) | Cat avatar gentle pulsing |
| meowPageRoute / router | PageRouteBuilder | Soft fade+slide transitions |

**Zero external dependencies.** All pure Flutter built-in.

---

## 5. What pages were lightly touched

| Page | Change | Scope |
|---|---|---|
| `app.dart` | Theme applied | Minimal — just ThemeData swap |
| `app_router.dart` | Page transition | Minimal — _buildPage uses PageRouteBuilder |

No page structures were changed. No business logic was touched.

---

## 6. What is still not touched

- Meow Home page structure (Phase 2)
- Today page structure (Phase 3)
- Customize page structure (Phase 4)
- Companion copy content (Phase 5)
- Backend API/DB (none)
- Study/Review/Session/CheckIn pages (not in B1 scope)

---

## 7. What must be done next

**Phase 2: Meow Home Redesign** — The biggest and highest-risk phase.

Key approach:
1. Import shared components (MeowCard, MeowChip, ResourceBadge, PreviewContainer)
2. Use MeowAnimatedNumber for resource display
3. Use MeowAnimatedProgress for EXP bar
4. Use createBreathingController for cat avatar
5. Use MeowBounceButton for feed/interact buttons
6. Rewrite layout top-to-bottom: cat focal → resource bar → Growth Card → actions → companion copy → equipped

---

## 8. What not to touch

- Don't change shared/theme.dart color values without verifying all-page cascade
- Don't add external animation packages
- Don't change API contract
- Don't expand catalog items

---

## 9. Files / modules to read first

1. `apps/mobile/lib/shared/theme.dart` — Full design token system
2. `apps/mobile/lib/shared/animations.dart` — Animation utilities
3. `apps/mobile/lib/shared/widgets/` — All 4 widget files
4. `apps/mobile/lib/shared/shared.dart` — Barrel export
5. `apps/mobile/lib/app/app.dart` — Theme application
6. `apps/mobile/lib/core/router/app_router.dart` — Page transition

---

## 10. Current risks

1. **Theme cascade on unrestructured pages**: Today, Meow Home, Customize now get new button/card/chip styles but their internal layout is still old. May look "half-upgraded" until Phase 2-4.
2. **Meow Home rewrite complexity**: 648 lines of business logic + UI. Phase 2 is the highest-risk phase.
