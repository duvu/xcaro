# Auth Screens Redesign Spec

## Overview

Redesign `login_screen.dart` and `register_screen.dart` to use the XCaro visual identity established by the design system.

## Requirements

### AUTH-1: Branded header
- Both screens must display a `Container` spanning the top ~35% of the screen height.
- The header background must use a gradient from `AppColors.primary` to a slightly lighter navy shade.
- The header must contain: a centred `SvgPicture.asset('assets/images/board.svg')` at 80×80, a `Text('XCaro')` in `AppTextStyles.displayLarge` (white), and a tagline `Text('Cờ Gomoku Online')` in `AppTextStyles.bodyMedium` (white 70% opacity).

### AUTH-2: Form card
- The form content must be wrapped in a `Card` with `BorderRadius.circular(AppSpacing.radiusLg)` and elevation 4.
- The card must overlap the header by at least 16dp (using a `Stack` + `Positioned` or `Transform.translate`).
- The card background must be `AppTheme` surface colour (adapts to dark/light mode).

### AUTH-3: Input decoration
- All `TextFormField` / `TextField` inputs must use the shared `InputDecorationTheme` from `AppTheme` (filled, rounded, no explicit `border: OutlineInputBorder()` override).
- Login username field: `prefixIcon: Icon(Icons.person_outline)`.
- Login password field: `prefixIcon: Icon(Icons.lock_outline)`, `suffixIcon` toggle for show/hide password.
- Register fields get matching prefix icons (person, email, lock, lock_check).

### AUTH-4: Button hierarchy
- Primary action (`Đăng Nhập` / `Đăng Ký`): full-width `ElevatedButton` using `AppTheme` button style (navy, rounded).
- Secondary action (navigate to register/login): `TextButton` with `AppColors.primary` text.
- Tertiary action (`Chơi không cần đăng nhập`): `OutlinedButton.icon` with `Icons.play_arrow`, positioned below a `Divider`.

### AUTH-5: Loading state
- While `_isLoading` is true, the primary button shows `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)` instead of text.
- All form fields must be disabled (not just the button) during loading.

### AUTH-6: No AppBar on auth screens
- Both screens must have `appBar: null` (no AppBar visible).
- Back navigation handled via the header area or a subtle back icon at top-left corner overlaid on the header.

## Acceptance Criteria

- Login and register screens render correctly in both light and dark modes.
- Password show/hide toggle works on both screens.
- Form validation messages are still visible and use `AppTheme` error colour.
- `flutter analyze` 0 issues after applying this capability.
