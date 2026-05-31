## Why

PlayVerse ships a full feature set — auth, online multiplayer, AI, leaderboard, chat, quick match, crash tracking — but the UI is a raw Material scaffold with inconsistent colours, no visual identity, and a board that renders stones as flat coloured circles with letters. Players encounter a fragmented experience: seven scattered AppBar icon buttons on the home screen, no typography scale, hardcoded `Colors.green` / `Colors.deepPurple` / `Colors.amber` throughout, and a game board that looks like a prototype. A redesign now, before the public beta opens, will reduce player churn from first-impression UX and make the product credible enough for the Play Store and App Store.

## What Changes

- **Design system**: introduce a centralised `AppTheme` with a brand colour palette (navy `#1A2035`, gold `#D4AF37`, neutral greys), a shared `TextTheme` using `Nunito` / `Roboto`, a `BorderRadius` token set, and an `AppColors` constants file. Replace every hardcoded colour reference across 13 screens and 4 widgets.
- **Auth screens** (login + register): replace the plain `Column` centre layout with a branded splash-art header (SVG board motif + logo wordmark), card container for the form, and unified input decoration.
- **Home / lobby screen**: replace the five-icon AppBar overflow with a bottom `NavigationBar` (Home / History / Leaderboard / Profile). Move action buttons into a `_LobbyActionGrid` with icon-card tiles. Surface the WS status chip as a subtle inline pill, not a full-width banner.
- **Game board**: use the existing SVG board asset (`assets/images/board.svg`), render it as a `CustomPaint` background. Replace the flat `Container` stones with gradient `CustomPainter` stones matching `stone_black.svg` / `stone_white.svg`. Add star-point dots at standard Gomoku positions. Add a winning-line highlight overlay using `win_overlay.svg`.
- **In-game HUD**: replace the plain `_TurnIndicator` band with an animated avatar-chip pair showing both players' names and a pulse indicator for the active player. Move resign/exit/chat into a slide-up bottom sheet menu.
- **Social screens** (leaderboard, history, opponent profile): replace flat `ListTile` rows with `Card` components, add rank-badge colour coding (gold/silver/bronze for top 3), add a win-rate progress bar to the profile screen.
- **Onboarding**: replace the plain `PageView` text slides with illustrated steps using the SVG game assets.
- **Micro-interactions**: add `AnimatedSwitcher` transitions between screens and `Hero` animations for profile avatars.

## Capabilities

### New Capabilities

- `design-system`: centralised `AppTheme`, `AppColors`, `AppTextStyles`, `AppSpacing` — shared by all screens. Establishes the visual language.
- `auth-screens-redesign`: branded login and register screens with header illustration, card form container, and consistent input styling.
- `home-lobby-redesign`: bottom navigation, lobby action grid, compact WS status pill.
- `game-board-redesign`: SVG-backed board, gradient stone painter, star points, winning-line overlay.
- `game-hud-redesign`: player chip HUD, animated turn indicator, bottom-sheet game menu.
- `social-screens-redesign`: card-based leaderboard/history, rank badges, win-rate bar on profile.
- `onboarding-redesign`: illustrated onboarding steps using SVG assets.

### Modified Capabilities

_(none — this change does not alter spec-level behaviour, only visual presentation)_

## Impact

- **Client**: all 13 screen files and 4 widget files will be modified. `client/lib/` gains `theme/app_theme.dart`, `theme/app_colors.dart`, `theme/app_text_styles.dart`, `theme/app_spacing.dart`. `pubspec.yaml` gains `google_fonts: ^6.0.0` for Nunito. No new runtime deps beyond fonts.
- **Assets**: existing SVG assets at `client/assets/images/` are used for the board and stones. No new image assets required beyond what Phase 1 project-docs-assets already added.
- **API / server**: no server changes. UI-only change.
- **Tests**: widget smoke test in `client/test/widget_test.dart` may need selectors updated after visual restructure. No logic tests affected.
- **Navigation**: bottom navigation replaces the five AppBar icon shortcuts. Route names and navigation logic are unchanged; only the triggering widget changes.
