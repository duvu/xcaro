# Social Screens Redesign Spec

## Overview

Redesign leaderboard, history, and opponent profile screens with Card-based layouts, rank badges, and win-rate indicators.

## Requirements

### SOCIAL-1: Leaderboard card items
- Replace `ListTile` with a custom `_LeaderboardCard` widget inside a `Card`.
- Card contains: rank badge (left), `CircleAvatar` 44px (centre-left), username + games-played text (middle), Elo rating large (right).
- Rank badge: `Container` 32×32 with `BoxDecoration(shape: BoxShape.circle)`.
  - Rank 1: gold background `AppColors.secondary`, "🥇" or "#1".
  - Rank 2: `Color(0xFFC0C0C0)` silver, "#2".
  - Rank 3: `Color(0xFFCD7F32)` bronze, "#3".
  - Rank 4+: `AppColors.surfaceContainer` background, `Text('#N', style: labelSmall)`.
- Tap navigates to opponent profile (unchanged).

### SOCIAL-2: History card items
- Replace `ListTile` with `_HistoryCard` in a `Card`.
- Card left: result `Chip(label: Text(result), backgroundColor: resultColor.withValues(alpha:.15), labelStyle: TextStyle(color: resultColor, fontWeight: bold))`.
- Card centre: "vs OpponentName" in `titleLarge`, date in `bodyMedium grey`.
- Card right: none (remove redundant trailing text).
- History uses `PlayerStatsCard` at the top instead of the bare stats row.

### SOCIAL-3: Opponent profile redesign
- Hero `CircleAvatar(radius: 40)` wrapped in `Hero(tag: 'avatar-${entry.username}')` for transition from leaderboard.
- Gold border ring on avatar for top-10 Elo players (`BoxDecoration(border: Border.all(color: AppColors.secondary, width: 3))`).
- Win-rate `LinearProgressIndicator`: `value = wins / max(1, wins+losses+draws)`, `color: AppColors.success`, `backgroundColor: AppColors.surfaceContainer`.
- Stats row: W/L/D/Elo in `PlayerStatsCard`.
- Recent 5 games compact list: `_HistoryCard` items (smaller, no padding).
- Logout button (for self-profile) or no logout (for opponent profile) — check `isSelf` flag.

### SOCIAL-4: Hero animation
- `CircleAvatar` in `LeaderboardScreen._LeaderboardCard` must be wrapped in `Hero(tag: 'avatar-${entry.username}')`.
- `CircleAvatar` in `OpponentProfileScreen` header must be wrapped in matching `Hero(tag: 'avatar-${username}')`.

### SOCIAL-5: PlayerStatsCard shared component
- `PlayerStatsCard` (defined in home-lobby spec) is imported and used in `HistoryScreen` and `OpponentProfileScreen`.
- No duplication of the stat display logic.

## Acceptance Criteria

- Top-3 leaderboard entries display gold/silver/bronze badges.
- History result chips are colour-coded and distinguishable.
- Opponent profile shows win-rate bar with correct percentage.
- Hero animation fires on leaderboard → profile navigation.
- `flutter analyze` 0 issues.
