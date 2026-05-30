# UX Polish Spec

## Overview

Replace blank lists, silent errors, and generic text with informative empty states, error states, and improved copy across all major screens.

## Requirements

### Shared Widgets

- Create `client/lib/widgets/empty_state.dart` with `EmptyStateWidget({ required IconData icon, required String title, String? subtitle, Widget? action })`.
- Create `client/lib/widgets/error_state.dart` with `ErrorStateWidget({ required String message, VoidCallback? onRetry })`.
- Both widgets MUST be centered, vertically padded, use `Theme.of(context).colorScheme` colors, and require no external dependencies.

### Screen-Level Empty and Error States

- `LeaderboardScreen`:
  - Empty: show `EmptyStateWidget(icon: Icons.leaderboard, title: "Chưa có ai trên bảng xếp hạng", subtitle: "Chơi một trận để xuất hiện!")`.
  - Error: show `ErrorStateWidget(message: "Không tải được bảng xếp hạng", onRetry: _loadData)`.
- `HistoryScreen`:
  - Empty: show `EmptyStateWidget(icon: Icons.history, title: "Chưa có lịch sử", subtitle: "Kết quả các trận đấu sẽ hiển thị ở đây.")`.
  - Error: show `ErrorStateWidget(message: "Không tải được lịch sử", onRetry: _loadData)`.
- `OpponentProfileScreen`:
  - Error (user not found / API error): show `ErrorStateWidget(message: "Không tìm thấy người chơi này", onRetry: _loadProfile)`.
- `HomeScreen` (recent games list):
  - Empty: replace current `Text('Chưa có trận đấu nào')` with `EmptyStateWidget(icon: Icons.sports_esports, title: "Chưa có trận đấu nào", subtitle: "Tạo phòng hoặc nhập mã để bắt đầu!")`.
- `JoinRoomScreen`:
  - Room not found / full: show inline `ErrorStateWidget` below the code input, not a dialog.

### Onboarding Copy

- Update `OnboardingScreen` page 2 (online play instructions) to mention: "Tạo phòng và chia sẻ mã phòng với bạn bè, hoặc nhấn **Chơi ngay** để tìm đối thủ tự động."
- Update `OnboardingScreen` page 3 (room code instructions) to include an image/icon hint for the share button.

### Disconnect and Expiry Messaging

- `GameScreen` WS `game_over` handler MUST map `reason` field to human-readable Vietnamese text:
  - `"forfeit"` → "Đối thủ đã bỏ cuộc do mất kết nối"
  - `"timeout"` → "Phòng đã hết thời gian"
  - `"opponent_disconnected"` → "Đối thủ đã mất kết nối"
  - `"resign"` → "Đối thủ đã đầu hàng"
  - Unrecognized reason → show the raw reason string.

### Connection Status Chip

- `HomeScreen` MUST show a small `Chip` near the top of the body (below the stats row) indicating WS connection state:
  - Connected: green `Chip(label: Text("Trực tuyến"), avatar: Icon(Icons.wifi, color: Colors.green))`.
  - Disconnected/reconnecting: yellow `Chip(label: Text("Đang kết nối lại..."), avatar: CircularProgressIndicator(strokeWidth: 2))`.
- Source the connection state from `WebSocketService.isConnected` (expose as a `ValueNotifier<bool>` or equivalent).

## Acceptance Criteria

- All five screens show the correct empty state when their list/data is empty.
- All five screens show the error state with a retry button when the network call fails.
- `OnboardingScreen` pages 2 and 3 mention quick match and share button in the copy.
- `GameScreen` shows human-readable Vietnamese text for all four disconnect/resign/forfeit/timeout reason codes.
- Connection status chip on `HomeScreen` reflects live WS connection state.
- `flutter analyze` reports no new issues.
