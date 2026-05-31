# Game HUD Redesign Spec

## Overview

Replace the plain turn-indicator band and bottom action row with a player-chip HUD and a bottom-sheet game menu.

## Requirements

### HUD-1: PlayerHUD widget
- Create `client/lib/widgets/player_hud.dart` with `PlayerHud(playerXName, playerOName, activePlayerId, myId)`.
- Renders two `_PlayerChip` side by side with a centred game clock or turn counter between them.
- `_PlayerChip(name, stoneColor, isActive)`: `Card` chip showing a small stone colour swatch + truncated name (max 12 chars + ellipsis) + active indicator.
- Active chip: adds a gold `BoxDecoration` border (2dp) and a pulsing glow via `AnimationController` (1s repeat, `withValues(alpha:)` oscillate 0.3→0.8).
- Inactive chip: grey border, no glow.

### HUD-2: Turn indicator removal
- Remove `_TurnIndicator` widget from `game_screen.dart`.
- Replace with `PlayerHud` widget at the top of the game column.

### HUD-3: Game menu FAB
- Replace the bottom `Row(chat icon, exit button)` with a `FloatingActionButton.small(icon: Icons.menu)` anchored bottom-right.
- Tapping shows `showModalBottomSheet` with `shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)))`.
- Bottom sheet items:
  - `ListTile(Icons.chat_bubble_outline, 'Chat')` → toggles `_chatOpen` state and closes sheet.
  - `ListTile(Icons.flag_outlined, 'Đầu hàng', textColor: AppColors.warning)` → existing resign flow.
  - `ListTile(Icons.exit_to_app, 'Thoát', textColor: AppColors.error)` → existing exit flow.

### HUD-4: Chat panel unchanged
- `_ChatPanel` widget remains as-is (collapsible, 250dp height, mute toggle, send field).
- It is toggled via the "Chat" item in the bottom sheet and the existing `_chatOpen` state.

### HUD-5: Offline game view parity
- `OfflineGameView` also replaces its `_TurnIndicator` with `PlayerHud` (pass static player names "Người chơi" / "Máy" for AI, "Bạn" / "Đối thủ" for offline 2P).

## Acceptance Criteria

- `PlayerHud` displays both player names and correct active-player highlight.
- Bottom sheet opens and closes correctly; each action triggers the correct behaviour.
- Pulsing glow animation runs only for the active player chip.
- `flutter analyze` 0 issues.
