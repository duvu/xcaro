## Why

PlayVerse should let two remote human players complete a full Caro match through the game server, not only on the same device. The repository already has Flutter client screens and Go WebSocket/server foundations, so this change turns online human-vs-human play into an explicit, testable capability.

## What Changes

- Add a server-authoritative online human-vs-human game mode over the Go game server WebSocket.
- Support authenticated room creation, room joining by code, optional quick-match entry, and clear client state transitions from lobby to active game.
- Synchronize board state, turns, game-over events, resign/forfeit outcomes, chat-adjacent room events, and error messages to both players in real time.
- Validate moves on the server so clients cannot play out of turn, overwrite cells, or continue after a game is over.
- Handle disconnect/reconnect with a bounded grace period and clean up abandoned rooms.
- Persist completed online games so history, stats, and Elo/leaderboard behavior remain consistent with existing product expectations.

## Capabilities

### New Capabilities
- `online-multiplayer`: Server-authoritative online human-vs-human Caro sessions through the game server, including room lifecycle, real-time move sync, end-game handling, reconnect/forfeit behavior, and client lobby/game integration.

### Modified Capabilities
- None. `openspec/specs/` is currently empty, so this change introduces the online multiplayer contract as a new capability.

## Impact

- **Client**: Flutter online entry points and state management in `client/lib/screens/home_screen.dart`, `client/lib/screens/create_room_screen.dart`, `client/lib/screens/join_room_screen.dart`, `client/lib/screens/quick_match_waiting_screen.dart`, `client/lib/screens/game_screen.dart`, `client/lib/providers/game_provider.dart`, and `client/lib/services/websocket_service.dart`.
- **Server**: Go WebSocket room/match handling in `server/internal/ws/`, game persistence in `server/internal/game/`, route registration in `server/cmd/server/main.go`, and related auth/email-verification guards.
- **Docs/specs**: Update OpenSpec requirements for the online room protocol, server-authoritative game state, reconnect/cleanup semantics, and verification steps.
- **Validation**: Server unit tests, Flutter analyzer/tests where available, and an end-to-end smoke path with two authenticated clients connected to the running game server.
