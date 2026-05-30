# Quick Match Queue Spec

## Overview

Allow two players to be matched automatically without exchanging a room code.

## Requirements

### Server — Hub Queue

- `Hub` MUST maintain a `matchQueue []*Client` slice protected by `h.mu`.
- When client sends `{ "type": "quick_match_request" }`:
  - If `matchQueue` is empty, add client to queue; send `{ "type": "quick_match_waiting" }` back to the client.
  - If `matchQueue` has one entry, pop it, create a `Room` with a new random 6-char code, assign `PlayerX` to the waiting client and `PlayerO` to the requesting client, send `{ "type": "quick_match_found", "payload": { "room_id": "...", "room_code": "...", "color": "X"|"O" } }` to both clients.
- A queued client entry MUST expire after 60 seconds. On expiry, remove from queue and send `{ "type": "quick_match_timeout" }`.
- When client sends `{ "type": "quick_match_cancel" }` or disconnects, remove from queue and send `{ "type": "quick_match_cancelled" }` to that client only.
- A client MUST NOT be in the queue more than once simultaneously.
- `EventQuickMatchRequest`, `EventQuickMatchFound`, `EventQuickMatchWaiting`, `EventQuickMatchCancelled`, `EventQuickMatchTimeout` MUST be defined in `internal/ws/events.go`.

### Server — REST Fallback (Optional)

- `POST /api/ws/queue/join` (authenticated): enqueue the calling user for quick match; returns `200` with `{ "status": "waiting" }` or `201` with match payload if immediately paired.
- `DELETE /api/ws/queue/leave` (authenticated): dequeue the calling user; returns `204`.

### Client — Quick Match Button

- `HomeScreen` MUST show a "Chơi ngay" (Quick Match) `ElevatedButton.icon` alongside the existing Create/Join/AI buttons.
- Pressing it opens a `QuickMatchScreen` (or bottom sheet) that:
  - Sends `quick_match_request` over the existing `WebSocketService`.
  - Shows a spinner with text "Đang tìm đối thủ...".
  - Shows a cancel button that sends `quick_match_cancel`.
  - On receiving `quick_match_found`, navigates to `GameScreen` with the matched room.
  - On receiving `quick_match_timeout`, shows an error toast and closes.
- If the WS is not connected when the button is pressed, show a snackbar "Không thể kết nối. Thử lại sau."

## Acceptance Criteria

- Two authenticated connected clients both pressing Quick Match are paired within 5 seconds.
- If only one client is in the queue and 60 seconds elapse, they receive `quick_match_timeout` and the queue is cleared for their slot.
- Cancelling removes the client from the queue and they receive `quick_match_cancelled`.
- Disconnection during wait removes the client from the queue without error.
- No client can be matched against itself.
