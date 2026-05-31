# UI/UX Redesign — Design Document

## Goals

- Establish a consistent visual identity across all 13 screens and 4 widgets.
- Make the game board feel like a real Gomoku board, not a prototype grid.
- Reduce navigation cognitive load by moving secondary actions off the AppBar.
- Zero new gameplay changes — this is a pure visual/UX layer.
- Keep `flutter analyze` at 0 issues after the change.

## Non-Goals

- No new features, API routes, or state management changes.
- No deep link or routing changes (routes stay identical).
- No performance regressions (do not add heavy dependencies).

---

## 1. Design System (`theme/`)

### File structure
```
client/lib/theme/
  app_colors.dart       # Colour palette constants
  app_text_styles.dart  # TextTheme + named styles
  app_spacing.dart      # Spacing/radius tokens
  app_theme.dart        # ThemeData light + dark (imports above)
```

### Colour palette
| Token | Light value | Dark value | Usage |
|---|---|---|---|
| `primary` | `#1A2035` (navy) | `#2D3A5C` | AppBar, primary buttons |
| `secondary` | `#D4AF37` (gold) | `#E8C84A` | Rank badges, highlights, win overlay |
| `surface` | `#FFFFFF` | `#121212` | Screen background |
| `surfaceContainer` | `#F5F5F5` | `#1E1E1E` | Cards, list backgrounds |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` | Text on primary |
| `error` | `#D32F2F` | `#EF5350` | Error states |
| `success` | `#388E3C` | `#66BB6A` | Win state, connected chip |
| `warning` | `#F57C00` | `#FFA726` | Draw, disconnected chip |
| `boardBackground` | `#DCB97A` | `#C8A060` | Game board surface |
| `stoneBlack` | `#1A1A1A` | `#0D0D0D` | Black stone |
| `stoneWhite` | `#F0F0F0` | `#E8E8E8` | White stone |

### Typography
- Font: `Nunito` (Google Fonts) — chosen for its rounded forms that suit a board game app.
- Fallback: system default (no flutter_analyze issue if google_fonts fails).
- Scale:
  - `displayLarge` 32/bold — splash logo
  - `headlineMedium` 24/semibold — screen titles
  - `titleLarge` 18/semibold — card titles, player names
  - `bodyLarge` 16/regular — list items, descriptions
  - `bodyMedium` 14/regular — subtitles, secondary
  - `labelLarge` 14/semibold — button labels
  - `labelSmall` 11/medium — stat labels, chips

### Spacing tokens (`AppSpacing`)
```dart
static const double xs = 4;
static const double sm = 8;
static const double md = 16;
static const double lg = 24;
static const double xl = 32;
static const double radius = 12;       // card radius
static const double radiusLg = 20;    // bottom sheet, dialog
static const double radiusFull = 100; // chips, avatars
```

### ThemeData decisions
- `useMaterial3: true` (already set, keep).
- Replace `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` with hand-crafted `ColorScheme` built from the palette above.
- `AppBarTheme`: `backgroundColor = primary`, `foregroundColor = onPrimary`, `elevation = 0`, `centerTitle = false`.
- `ElevatedButtonTheme`: `shape = RoundedRectangleBorder(borderRadius: AppSpacing.radius)`, `padding = EdgeInsets.symmetric(vertical: 14)`.
- `InputDecorationTheme`: `border = OutlineInputBorder(borderRadius: AppSpacing.radius)`, `filled = true`, `fillColor = surfaceContainer`.
- `CardTheme`: `elevation = 2`, `shape = RoundedRectangleBorder(borderRadius: AppSpacing.radius)`.
- `ListTileTheme`: use `Card` wrapper where the item needs elevation.

---

## 2. Auth Screens Redesign

### Login screen
- Remove explicit `AppBar` (back button at top-left is enough).
- Top 35% of screen: `Container` with navy gradient, centred SVG logo + "PlayVerse" wordmark + tagline "Cờ Gomoku Online".
- Bottom 65%: `Card` with `BorderRadius.circular(AppSpacing.radiusLg)` lifted up into the header (negative top margin trick via `Stack`). Contains the form.
- Input fields use `AppTheme` `InputDecorationTheme` with prefix icons (`Icons.person`, `Icons.lock`).
- Primary `ElevatedButton` full-width for "Đăng Nhập".
- `TextButton` for "Chưa có tài khoản? Đăng ký ngay" stays below.
- "Chơi không cần đăng nhập" → moved to a `TextButton.icon` with `Icons.play_arrow` below the divider.

### Register screen
- Same header + card layout as login for visual consistency.
- Form fields same as current (username, email, password, confirm).
- Remove `AppConfig` import concern — keep validation logic intact, only reskin the `InputDecoration`.

---

## 3. Home / Lobby Redesign

### Navigation architecture change
Replace the 5-icon AppBar overflow with a **bottom `NavigationBar`** (Material 3):
```
[🏠 Trang chủ] [📋 Lịch sử] [🏆 Xếp hạng] [👤 Hồ sơ]
```
- Wrap `HomeScreen`, `HistoryScreen`, `LeaderboardScreen`, `OpponentProfileScreen` (self) in a `_MainScaffold` shell that owns the `NavigationBar`.
- `_MainScaffold` uses `IndexedStack` to preserve state across tabs.
- AppBar retains: title "PlayVerse", theme toggle (right), help icon (right).
- Remove history/leaderboard/logout icons from AppBar — those are now in the nav bar or profile tab.

### Lobby action grid
Replace the three-button row + one full-width button with a **2×2 action card grid**:
```
[🎮 Tạo phòng]    [🔑 Vào phòng]
[🤖 Chơi với máy] [⚡ Tìm đối thủ]
```
Each card: `Card` with navy gradient header icon, white body with label, slight elevation.

### Stats header
Replace the `primaryContainer` bar with a horizontal `PlayerStatsCard` component:
```
Avatar | Username  | Elo: 1200 | Rank: #42
         W: 12  L: 8  D: 3
```
Tap → profile tab.

### WS connection status
Replace the full-width `Container` banner with a small `Chip` in the AppBar subtitle or below the stats card. Connected: green dot, not shown. Disconnected: orange pill "Đang kết nối lại...".

---

## 4. Game Board Redesign

### Board background
Use `SvgPicture.asset('assets/images/board.svg')` as the board background via a `Stack`:
```dart
Stack(
  children: [
    SvgPicture.asset('assets/images/board.svg', fit: BoxFit.fill),
    _StoneGridOverlay(board, onTap, canTap),
  ],
)
```
Remove `Colors.amber.shade50` cell fill and `Border.all(Colors.grey.shade400)` — the SVG already draws the grid lines.

### Stone painter
Replace `Container(color: color, shape: BoxShape.circle)` with `CustomPaint(painter: _StonePainter(isBlack))`:
- Black stone: radial gradient from `#3D3D3D` (top-left highlight) to `#0D0D0D` (bottom-right).
- White stone: radial gradient from `#FFFFFF` (top-left) to `#B0B0B0` (bottom-right) + subtle drop shadow.
- Remove the letter ("X"/"O") from the stone — identify by stone colour only.
- Keep `ScaleTransition` animation (150ms, easeOut) on stone placement.

### Star points
Add the 5 standard Gomoku star points: `(3,3)`, `(3,11)`, `(7,7)`, `(11,3)`, `(11,11)` (0-indexed on a 15×15 board). Draw as small filled circles in the empty-cell layer before stones.

### Winning line
When `gameProvider.gameOver` is true and `winner != null`, calculate the winning sequence from `board` and draw a `CustomPaint` line overlay that connects the 5-in-a-row cells. Use gold colour `#D4AF37`, `strokeWidth: 4`, `StrokeCap.round`.

---

## 5. In-Game HUD Redesign

### Player chip header
Replace `_TurnIndicator` band with a `_PlayerHUD` widget:
```
[X avatar  Player A  ●active] ────  [Player B  avatar O]
```
- Two `_PlayerChip` widgets in a `Row` with `spaceBetween`.
- Active player chip has `BoxShadow` glow in primary colour + animated pulsing border.
- Stone colour swatch (small black/white circle) next to each name.

### Bottom sheet game menu
Replace the bottom `Row(chat icon + exit button)` with a `FloatingActionButton` (menu icon).
Tapping opens a `showModalBottomSheet`:
```
──────────────
  💬 Chat
  🏳️ Đầu hàng
  🚪 Thoát
──────────────
```
Chat icon is still a quick toggle (stays as current `IconButton` in the action row but moves into the HUD bar).

---

## 6. Social Screens Redesign

### Leaderboard
- Replace `ListView` + `ListTile` with `ListView` + `Card` items.
- Top 3 entries get special rank badge: 🥇🥈🥉 with gold/silver/bronze border.
- Entry card: avatar (CircleAvatar 40px) | rank + username + games played | Elo rating (large, right).
- Add `EloChangeChip` (shows `+12` or `-8` for recent match delta, pulled from leaderboard API if available).

### History screen
- Same `Card` treatment for list items.
- Result chip (Thắng/Thua/Hòa) as a `Chip` with colour-coded background, not plain `Text`.
- Stats row → use `PlayerStatsCard` (shared component from lobby redesign).

### Opponent profile screen
- Hero avatar (80px CircleAvatar with gold border for top-10 players).
- Win-rate `LinearProgressIndicator` bar: `wins / (wins + losses + draws)`.
- Stats row uses shared `PlayerStatsCard`.
- Recent games: compact `Card` list (up to 5 items).

---

## 7. Onboarding Redesign

- Each of the 4 `PageView` slides gets an SVG illustration centred above the text:
  - Slide 1 (board rules): `board.svg` at 200×200.
  - Slide 2 (online play): use `board.svg` with stone overlay hint.
  - Slide 3 (AI mode): `stone_black.svg` + robot icon composite.
  - Slide 4 (leaderboard): `win_overlay.svg`.
- Typography follows `AppTextStyles`.
- Page indicator dots use `AnimatedContainer` resize (active dot = wide pill).

---

## 8. Micro-Interactions

- `AnimatedSwitcher` wrapping the `IndexedStack` in `_MainScaffold` for smooth tab transitions.
- `Hero` tag on `CircleAvatar` in leaderboard list → opponent profile screen.
- `AnimatedContainer` on WS status chip (hidden when connected, slides in when disconnected).
- Stone placement animation already exists (`ScaleTransition 150ms`) — keep as-is.

---

## 9. Risk and Tradeoffs

| Risk | Mitigation |
|---|---|
| `google_fonts` download fails on first run | Fonts cached after first run; offline fallback to system font |
| SVG board rendering performance on low-end devices | `SvgPicture` renders to a cached `Picture` — acceptable for 15×15 static SVG |
| Widget test selectors break after restructure | Update `widget_test.dart` to match new structure |
| `NavigationBar` shell adds complexity | `IndexedStack` avoids rebuild; shell is straightforward |
| Bottom sheet replaces exit button — players may miss it | FAB is prominent; add tooltip "Menu trò chơi" |

---

## 10. Migration Plan

1. Add `google_fonts` dep to `pubspec.yaml`.
2. Create `client/lib/theme/` files.
3. Update `main.dart` `ThemeData` to use `AppTheme`.
4. Per-screen: update colours + typography only (no logic changes).
5. `GameBoard` widget: SVG background + stone painter (biggest visual change).
6. `HomeScreen`: add `_MainScaffold`, action grid.
7. Run `flutter analyze` → 0 issues. Run `flutter test`. Run release build check.
