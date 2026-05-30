## Context

XCaro has a Flutter client (Flame + Provider) and a Go backend (Gin + Gorilla WebSocket + MongoDB). The existing code has screens, routes, and service stubs in place, but the auth flow is incomplete (no refresh token, no persistent session), the online multiplayer game loop is partially wired, the AI opponent is absent, and game history is not persisted. This design covers how to close those gaps for MVP1.

Stack: Flutter/Dart (client), Go 1.21+ (server), MongoDB (storage), WebSocket (real-time), JWT (auth).

## Goals / Non-Goals

**Goals:**
- Production-ready auth: register, login, access + refresh JWT, persistent session via secure local storage
- Full online multiplayer loop: room CRUD, real-time move sync, win/draw/timeout/resign, disconnect recovery
- Playable AI opponent (single difficulty, heuristic-based)
- Game history stored in MongoDB and surfaced on the client home screen
- Core UI polish: animations, sound, dark/light theme

**Non-Goals:**
- Multiple AI difficulty levels (post-MVP)
- Chat in game (post-MVP)
- Leaderboard / ranking system (post-MVP)
- Spectator mode (post-MVP)
- OAuth2 / social login (post-MVP)
- WebRTC voice/video (post-MVP)

## Decisions

### 1. JWT: Access + Refresh Token Pair

**Decision**: Issue a short-lived access token (15 min) and a long-lived refresh token (7 days) stored in MongoDB. The client stores the refresh token in `flutter_secure_storage` and the access token in memory only.

**Rationale**: Refresh tokens allow seamless re-auth without re-login while limiting exposure if an access token leaks. Storing refresh tokens server-side enables revocation.

**Alternative considered**: Single long-lived token — simpler but insecure; rotation not possible.

### 2. WebSocket Room Protocol

**Decision**: Use a JSON message envelope `{ "type": string, "payload": object }` over a single WebSocket connection per client. Server-side `Hub` maintains a `map[roomID]Room`, each Room has a `map[userID]Client`.

**Message types**: `join_room`, `leave_room`, `make_move`, `game_state`, `game_over`, `error`, `ping/pong`.

**Rationale**: Simple, debuggable, aligns with existing `hub.go` pattern. No need for binary protocol at MVP scale.

**Alternative considered**: Separate WebSocket per room — harder to manage reconnection and authentication.

### 3. AI Algorithm: Threat-Space Search (TSS) with Heuristic Scoring

**Decision**: Implement a single-threaded minimax with alpha-beta pruning (depth 3–4) plus a threat-space search shortcut for forcing sequences. Evaluate board using a pattern-score table (open-four, closed-four, open-three, etc.).

**Rationale**: TSS is standard for Gomoku AI; depth 3-4 is fast enough (<200ms per move on mobile), strong enough to be fun, and straightforward to implement in Dart without external packages.

**Alternative considered**: Random move / greedy heuristic — too easy, not engaging. Full MCTS — overkill for MVP.

### 4. Game History: MongoDB `games` Collection

**Decision**: On game end (any outcome), server writes a `GameRecord` document: `{ id, playerX, playerO, winner, moves: [{x,y,player}], duration, createdAt }`. Client fetches paginated history via `GET /api/games?userId=&page=&limit=`.

**Rationale**: Document store fits the variable-length `moves` array naturally. Simple append-only write.

### 5. Client State Management: Keep Provider, Add `AuthProvider` Lifecycle

**Decision**: Add `AuthProvider` responsible for token lifecycle (load from storage on startup, auto-refresh, logout). `GameProvider` subscribes to WebSocket events and updates board state. No new state management library.

**Rationale**: Provider is already in the codebase; introducing Riverpod or Bloc for MVP adds churn without clear benefit.

## Risks / Trade-offs

- **Disconnect handling complexity** → Mitigation: implement a 30-second reconnect grace period server-side; if the player doesn't reconnect, forfeit the game. Keep reconnect logic in `websocket_service.dart`.
- **AI computation on main isolate** → Mitigation: run AI search in a Dart `Isolate` to avoid jank; pass board state as plain data.
- **MongoDB connection pooling under load** → Mitigation: use the official Go driver's default pool (100 connections); acceptable for MVP traffic.
- **Refresh token revocation on multiple devices** → Accepted trade-off: MVP supports single active session per user (new login invalidates old refresh token). Multi-device is post-MVP.

## Migration Plan

1. **Server**: add `refreshToken` field to `users` collection (no migration needed, MongoDB schema-flexible); add `games` collection (new, no migration).
2. **Client**: `flutter_secure_storage` added to `pubspec.yaml`. On first launch after update, users must re-login (no existing session to migrate).
3. **Deployment**: update `docker-compose.yml` environment variables for JWT secret and token TTLs. No breaking API changes to existing endpoints; new endpoints are additive.
4. **Rollback**: revert server binary; existing users lose refresh token but can re-login. Game history data is kept but not displayed.

## Open Questions

- Should the AI move be computed client-side or server-side? (Proposal assumes client-side Dart Isolate — confirm before implementing `ai-opponent` spec.)
- Maximum board size for Gomoku: 15×15 (standard) or 19×19 (Go board)? Recommend locking to 15×15 for MVP.
- Room expiry: how long should an empty room persist before being garbage-collected? Suggest 5 minutes.
