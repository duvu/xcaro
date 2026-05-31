# Home / Lobby Redesign Spec

## Overview

Replace the AppBar icon overflow and flat button row with a bottom navigation shell and a card-based lobby action grid.

## Requirements

### LOBBY-1: MainScaffold shell
- Create `client/lib/screens/main_scaffold.dart` with a `_MainScaffold` `StatefulWidget`.
- `_MainScaffold` owns a `NavigationBar` with 4 destinations: Home (index 0), History (index 1), Leaderboard (index 2), Profile (index 3).
- Body uses `IndexedStack` with children `[HomeTab, HistoryScreen, LeaderboardScreen, SelfProfileScreen]`.
- `SelfProfileScreen` = `OpponentProfileScreen` loaded with the current user's own username.
- `_MainScaffold` is the destination for the `/home` route. Existing sub-screen routes remain unchanged.

### LOBBY-2: AppBar simplification
- `HomeTab` AppBar retains: title "PlayVerse", theme toggle `IconButton`, help/onboarding `IconButton`.
- Remove: history, leaderboard, logout icons from AppBar. Logout moves to profile tab.
- Logout action: `IconButton(Icons.logout)` in `SelfProfileScreen` AppBar.

### LOBBY-3: Lobby action grid
- Replace the two button rows with a `GridView` of 4 `_ActionCard` widgets (2 columns, fixed aspect ratio ~1.2).
- `_ActionCard(icon, label, color, onTap)`: `Card` with gradient header icon on navy background, `Text` label at bottom.
- Cards: Tạo phòng (`Icons.add_circle`, navy), Vào phòng (`Icons.door_back_door`, navy), Chơi với máy (`Icons.smart_toy`, forest green), Tìm đối thủ (`Icons.bolt`, deep purple).

### LOBBY-4: PlayerStatsCard
- Create `client/lib/widgets/player_stats_card.dart` with `PlayerStatsCard(stats, user)` widget.
- Displays: `CircleAvatar` 48px, username `titleLarge`, Elo chip, rank chip, W/L/D inline stats.
- Used in HomeTab (replaces the `primaryContainer` stats row) and HistoryScreen (replaces the stats bar).
- Tapping navigates to the profile tab (or pushes profile route if called from other screens).

### LOBBY-5: WS connection chip
- Replace the full-width orange/green `Container` banner with a small `AnimatedContainer` `Chip`.
- When connected: chip is hidden (zero height, animated out).
- When disconnected: chip slides in below AppBar — orange background, "Đang kết nối lại..." text, 12dp font.
- Transition duration: 300ms.

### LOBBY-6: Recent games list
- Keep `RefreshIndicator` + `ListView` for recent games.
- Replace plain `ListTile` with a `_GameListCard` `Card` showing: result chip (Thắng/Thua/Hòa), opponent username, date, Elo delta if available.
- `EmptyStateWidget` stays unchanged.

## Acceptance Criteria

- `NavigationBar` correctly switches between 4 tabs with `IndexedStack` (state preserved).
- Action grid shows 4 cards in a 2-column grid on screens ≥360dp wide.
- WS chip animates in/out based on `WebSocketService.isConnectedStream`.
- `flutter analyze` 0 issues.
