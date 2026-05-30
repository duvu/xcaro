# Room Invite Share Spec

## Overview

Allow a room host to share their room code to other apps or clipboard so friends can join without manually typing a code.

## Requirements

### Client — Share Sheet

- `CreateRoomScreen` MUST show an `IconButton(icon: Icons.share)` after a room has been created and the room code is displayed.
- Pressing the share button MUST invoke `Share.share(text)` from the `share_plus` package with the payload:
  ```
  Tham gia phòng XCaro của mình! Mã phòng: <CODE>
  xcaro://room/<CODE>
  ```
- The share button MUST be disabled/hidden before a room code is received from the server.
- `share_plus` MUST be added to `client/pubspec.yaml` as a runtime dependency.

### Client — Copy to Clipboard Fallback

- Alongside the share button, MUST show a `IconButton(icon: Icons.copy)` that copies only the room code to the clipboard and shows a `SnackBar("Đã sao chép mã phòng")`.

### Server

- No server changes are required. Room codes are already generated and returned via WS `game_state` events.

### Future (Not in Phase 2)

- Deep-link routing (`xcaro://room/<code>` launches the app to `JoinRoomScreen` pre-filled) is deferred to a future change.

## Acceptance Criteria

- Tapping share on a created room opens the native share sheet with the room code and link text.
- Tapping copy copies only the 6-char code and shows a confirmation snackbar.
- Share and copy buttons are not visible before the room code is received.
- `flutter analyze` reports no new issues from `share_plus` usage.
