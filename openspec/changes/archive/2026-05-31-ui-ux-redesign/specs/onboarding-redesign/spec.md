# Onboarding Redesign Spec

## Overview

Redesign the onboarding `PageView` slides to use SVG illustrations and the PlayVerse design system.

## Requirements

### OB-1: Illustrated slides
- Each of the 4 `PageView` slides must display an SVG illustration centred above the text.
- Slide 1 (Luật chơi): `SvgPicture.asset('assets/images/board.svg')` at 200×200.
- Slide 2 (Chơi online): `SvgPicture.asset('assets/images/board.svg')` at 180×180 with a stone row hint overlaid.
- Slide 3 (Chơi với máy): `SvgPicture.asset('assets/images/stone_black.svg')` at 100×100 + `Icon(Icons.smart_toy, size: 48)` side by side.
- Slide 4 (Bảng xếp hạng): `SvgPicture.asset('assets/images/win_overlay.svg')` at 200×60 above leaderboard icon.

### OB-2: Typography
- Slide title: `AppTextStyles.headlineMedium`, centred.
- Slide body: `AppTextStyles.bodyLarge`, centred, max 3 lines with ellipsis.

### OB-3: Page indicator
- Replace default `DotsIndicator` (if any) or plain `Row` with `AnimatedContainer` dots.
- Active dot: `width: 24, height: 8, borderRadius: 4, color: AppColors.primary`.
- Inactive dot: `width: 8, height: 8, borderRadius: 4, color: AppColors.primary.withValues(alpha:0.3)`.
- Transition duration: 200ms.

### OB-4: Navigation buttons
- "Tiếp theo" / "Hoàn thành" button uses `AppTheme` `ElevatedButton` style (navy, full-width).
- "Bỏ qua" text button top-right (if not on last slide).
- Consistent with overall button style from design system.

### OB-5: Background
- Each slide background uses `AppTheme` surface colour (adapts light/dark automatically).
- No custom gradient backgrounds per slide (keep it simple).

## Acceptance Criteria

- All 4 slides display SVG illustrations correctly.
- Page indicator animates between active/inactive dots as user swipes.
- Buttons use `AppTheme` styling.
- `flutter analyze` 0 issues after applying this capability.
