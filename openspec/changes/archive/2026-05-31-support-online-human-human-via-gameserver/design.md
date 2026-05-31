## Context

PlayVerse is a Flutter/Dart client with a Go game server using Gin, Gorilla WebSocket, MongoDB, JWT auth, and existing online-play code paths. Current repository artifacts show:

- `server/internal/ws/` already defines a `Hub`, `Room`, `WSMessage` envelope, room codes, `make_move`, `resign`, reconnect timers, quick-match queue hooks, and room cleanup.
- `client/lib/services/websocket_service.dart` owns the WebSocket connection and reconnection attempts.
- `client/lib/providers/game_provider.dart` applies `game_state`, `game_over`, and chat events into Flutter UI state.
- `openspec/specs/` is empty, while older changes describe online multiplayer behavior. This change creates the explicit current contract for online human-vs-human play through the game server.

The implementation should therefore harden and align existing client/server paths instead of introducing a separate networking stack.

## Goals / Non-Goals

**Goals:**

- Let two authenticated human players create/join or quick-match into a server-hosted Caro room.
- Keep the game server authoritative for room membership, turn order, move validity, win/draw/resign/forfeit results, and persisted game records.
- Use the existing JSON WebSocket envelope `{ "type", "room_id", "payload" }` for real-time sync.
- Keep the Flutter client responsive to connection state, waiting states, error events, game-state updates, and game-over outcomes.
- Provide testable behavior for room lifecycle, move validation, reconnect/forfeit, cleanup, and a two-client smoke path.

**Non-Goals:**

- Spectator mode, replay, tournaments, ranked matchmaking bands, or multi-room chat history.
- WebRTC voice/video changes; these remain separate from the game-server move protocol.
- Multi-instance room coordination through Redis or a message broker.
- Replacing Provider state management or changing the existing REST auth/profile/game APIs beyond what online play requires.

## Decisions

### 1. Use one authenticated WebSocket connection per client

Clients connect to the existing protected `/api/ws` endpoint with a JWT token, then send room and game intents over the shared WebSocket. The server responds with `game_state`, `game_over`, `quick_match_*`, and `error` events.

**Rationale:** The current Go server and Flutter client already use this pattern. One connection simplifies reconnect, auth, and event ordering.

**Alternative considered:** A separate WebSocket per room or REST polling for moves. That adds lifecycle complexity and increases latency without a product benefit for turn-based Caro.

### 2. Keep server-authoritative room and move state

The client sends intents (`create_room`, `join_room_by_code`, `quick_match_request`, `make_move`, `resign`), while `Hub`/`Room` validates permissions and broadcasts canonical state.

**Rationale:** Server authority prevents out-of-turn moves, occupied-cell overwrites, and post-game moves. It also gives a single point to persist history/Elo effects.

**Alternative considered:** Client-authoritative state with peer reconciliation. Rejected because it is cheat-prone and harder to test.

### 3. Store active rooms in memory for this change

Use the existing `Hub` maps for connected clients, room codes, game rooms, and quick-match queue entries. Persist only completed game records and resulting stats/rating changes.

**Rationale:** The current deployment model is a single game-server process. In-memory active rooms are fast and adequate for MVP-scale online play.

**Alternative considered:** Persist every board update to MongoDB or coordinate rooms through Redis. Deferred until multi-instance deployment is required.

### 4. Preserve the current Flutter layering

`WebSocketService` remains the transport/reconnect layer; `GameProvider` remains the UI-facing online game state layer; screens issue high-level actions through those services/providers.

**Rationale:** This matches existing code and avoids introducing a new state-management library for one feature.

**Alternative considered:** A dedicated `OnlineGameProvider`. That may be useful later, but for this change it would duplicate state already present in `GameProvider`.

### 5. Reconnect with a bounded grace period

If a player disconnects mid-game, the server reserves their seat for 30 seconds. Reconnecting with the same authenticated user restores them to the room and sends the latest `game_state`; missing the window ends the game by forfeit.

**Rationale:** This handles normal mobile network interruptions while keeping opponents from waiting indefinitely.

**Alternative considered:** Immediate forfeit or unlimited reconnect. Immediate forfeit is too harsh; unlimited reconnect is abusable and blocks cleanup.

### 6. Return machine-readable errors

Online-play failures should emit `error` events with stable codes, plus localized/client-friendly messages where possible. Required cases include invalid token, email not verified, room not found, room full, invalid move, not player's turn, no active room, and game already over.

**Rationale:** Screens can show precise messages and tests can assert stable codes without depending on translated text.

**Alternative considered:** Free-text errors only. Rejected because they are brittle for UI and automation.

## Risks / Trade-offs

- **In-memory rooms do not survive server restart** → Persist completed games only in this change and document restart as ending active rooms; move Redis-backed room state to a future scale-out change.
- **Single-process matchmaking cannot work across multiple server instances** → Keep deployment single-instance or sticky for online rooms until external coordination is added.
- **Protocol drift between Go constants and Dart handlers** → Centralize event names in existing constants/config and add tests/smoke scripts that exercise real event payloads.
- **Reconnect races can double-seat a user or forfeit after successful reconnect** → Stop and remove disconnect timers while holding room locks before broadcasting restored state.
- **Email verification can block online QA accounts** → Include verified test-account setup in manual smoke steps and ensure server returns a dedicated `email_not_verified` code.
- **Client may show stale local board state after reconnect** → Treat server `game_state` as canonical and overwrite local online board/provider state on every received state event.

## Migration Plan

1. No database migration is required for active rooms; existing user/game collections continue to be used.
2. Implement or align server protocol behavior first so old clients either keep working or receive explicit `error` events.
3. Update Flutter online screens/provider handling to consume the canonical payloads.
4. Deploy server before client when possible; rollback by reverting the server/client feature changes together if protocol compatibility breaks.
5. Validate with unit tests and a two-client smoke run against the running server before release.

## Open Questions

- Should active games be marked abandoned or simply dropped when the server process restarts?
- Is a 30-second reconnect grace period the desired product value, or should mobile builds use a longer period?
- Should quick-match be required for this change or treated as optional if create/join-by-code is complete first?
