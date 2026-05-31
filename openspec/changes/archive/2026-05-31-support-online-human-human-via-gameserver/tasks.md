## 1. Protocol Contract

- [x] 1.1 `server/internal/ws/events.go`: Normalize online play event constants for create room, join by code, rejoin, quick match, make move, resign, game state, game over, and error payloads.
- [x] 1.2 `client/lib/config/app_config.dart`: Align Dart event-name constants with the server WebSocket protocol.
- [x] 1.3 `docs/WEBSOCKET_INTEGRATION.md`: Update the online human-vs-human protocol examples to match the implemented JSON envelope and current event names.

## 2. Server Room Lifecycle

- [x] 2.1 `server/internal/ws/handler.go`: Ensure `/api/ws` authenticates JWT connections and associates each WebSocket client with user ID and username.
- [x] 2.2 `server/internal/ws/client.go`: Route incoming create-room, join-by-code, rejoin, quick-match, make-move, resign, and chat messages to the hub with validated payload shapes.
- [x] 2.3 `server/internal/ws/hub.go`: Return machine-readable error codes for email-not-verified, room-not-found, room-full, invalid-payload, no-active-room, and game-already-over cases.
- [x] 2.4 `server/internal/ws/hub.go`: Ensure room creation generates unique 6-character codes, assigns Player X, stores the room, and sends canonical `game_state` including room ID and room code.
- [x] 2.5 `server/internal/ws/hub.go`: Ensure join-by-code assigns Player O, starts the game when both seats are filled, supports same-user rejoin, and rejects third players.

## 3. Server Game Authority

- [x] 3.1 `server/internal/ws/room.go`: Verify move validation covers board bounds, occupied cells, current turn, active game state, and player membership.
- [x] 3.2 `server/internal/ws/hub.go`: Broadcast canonical `game_state` after every accepted move and return error-only-to-sender for rejected moves.
- [x] 3.3 `server/internal/ws/room.go`: Ensure win, draw, resign, and forfeit results populate final board, winner, result, and winning cells where available.
- [x] 3.4 `server/internal/ws/room.go`: Persist completed online human-vs-human games and trigger existing stats/Elo/history updates without persisting abandoned waiting rooms.

## 4. Reconnect, Queue, And Cleanup

- [x] 4.1 `server/internal/ws/hub.go`: Ensure disconnect timers reserve a seat for 30 seconds and cancel safely when the same user reconnects.
- [x] 4.2 `server/internal/ws/hub.go`: Ensure reconnect after the grace period results in `forfeit`, broadcasts `game_over`, and persists the completed game.
- [x] 4.3 `server/internal/ws/hub.go`: Prevent duplicate quick-match queue entries and self-matching for the same user identity.
- [x] 4.4 `server/internal/ws/hub.go`: Ensure quick-match timeout, cancellation, and disconnect paths remove queued clients and update queue metrics/state.
- [x] 4.5 `server/internal/ws/hub.go`: Ensure empty rooms older than 5 minutes are removed from `gameRooms` and code mappings.

## 5. Flutter Client Flow

- [x] 5.1 `client/lib/services/websocket_service.dart`: Send create-room, join-by-code, rejoin, quick-match, make-move, resign, and leave messages using the normalized protocol.
- [x] 5.2 `client/lib/services/websocket_service.dart`: Reconnect with exponential backoff and rejoin the current online room after a successful reconnect.
- [x] 5.3 `client/lib/providers/game_provider.dart`: Treat every server `game_state` payload as canonical for board, room code, players, current turn, result, and winning cells.
- [x] 5.4 `client/lib/providers/game_provider.dart`: Handle `game_over`, `quick_match_found`, `quick_match_timeout`, `quick_match_cancelled`, and `error` events without corrupting local state.
- [x] 5.5 `client/lib/screens/create_room_screen.dart`: Show created room code, waiting-for-opponent state, connection errors, and transition to game when both players are present.
- [x] 5.6 `client/lib/screens/join_room_screen.dart`: Submit room codes through the WebSocket protocol and show room-not-found, room-full, and email-not-verified errors.
- [x] 5.7 `client/lib/screens/quick_match_waiting_screen.dart`: Show waiting, cancellation, timeout, and match-found transitions for quick-match entry.
- [x] 5.8 `client/lib/screens/game_screen.dart`: Render server-authoritative online board state, current turn, valid local move submission, and final win/loss/draw/resign/forfeit outcomes.

## 6. Verification

- [x] 6.1 `server/internal/ws/`: Add or update unit tests for create room, join room, duplicate/full-room rejection, move validation, game over, disconnect reconnect, quick-match pairing, and queue timeout/cancel paths.
- [x] 6.2 `client/test/`: Add or update provider/service tests for WebSocket event handling, canonical state application, quick-match events, reconnect state, and error handling where practical.
- [x] 6.3 `server/`: Run `go test ./...` and fix regressions caused by the online multiplayer changes.
- [x] 6.4 `client/`: Run `flutter analyze` and `flutter test` and fix regressions caused by the online multiplayer changes.
- [x] 6.5 Running app/server: Execute a two-verified-user smoke path for create room, join room, legal moves to game over, and persisted history/stat result.
- [x] 6.6 Running app/server: Execute quick-match smoke path when enabled, including timeout/cancel behavior and a completed matched game.
