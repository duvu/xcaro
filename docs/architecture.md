# XCaro Architecture

## System Overview

```text
┌──────────────────────────────┐
│        Flutter App           │
│ Provider state + screens     │
│ REST API + WebSocket client  │
└──────────────┬───────────────┘
               │ HTTPS / WS
┌──────────────▼───────────────┐
│          Go Server           │
│ Gin routes + JWT middleware  │
│ WebSocket Hub + Rooms        │
│ Elo, auth, leaderboard       │
└───────┬──────────────┬───────┘
        │              │
┌───────▼───────┐ ┌────▼─────┐
│   MongoDB     │ │  Redis   │
│ users, games  │ │ cache +  │
│ game_records  │ │ limits   │
└───────────────┘ └──────────┘
```

The Flutter app owns UI and client state. The Go server owns authentication,
online room coordination, persisted game records, Elo rating updates, and public
leaderboard/profile data. MongoDB is the source of truth. Redis is an optional
cache/rate-limit backend; if Redis is unavailable the server degrades gracefully.

## Flutter Client Architecture

The active Flutter project is `client/`.

Key layers:

- `lib/main.dart` wires providers and named routes.
- `lib/providers/` stores app state with Provider/ChangeNotifier:
  - authentication/session state
  - online game state
  - offline AI game state
  - leaderboard/profile state
  - chat state
  - theme state
- `lib/services/` wraps REST and WebSocket communication.
- `lib/screens/` contains route-level UI such as login/register, home, game,
  AI game, history, leaderboard, opponent profile, onboarding, room creation,
  and room joining.
- `lib/ai/` contains the client-side minimax AI and isolate entrypoint.

### Routing

The app uses named routes and Provider wiring from `main.dart`. Startup checks
the persisted onboarding flag and authentication/session state before showing
the home screen or auth flow.

### WebSocket Lifecycle

Online play uses `WebSocketService` to connect to the server, listen for JSON
messages, and dispatch events into providers. The server sends messages in this
envelope shape:

```json
{
  "type": "game_state",
  "payload": {}
}
```

The client reacts to game-state, game-over, and chat events. Moves, room joins,
resign actions, and chat messages are sent back through the same envelope style.

## Go Server Architecture

The server entrypoint is `server/cmd/server/main.go`.

Startup flow:

1. Load `.env` with `godotenv`.
2. Connect to MongoDB from `MONGODB_URI`.
3. Select database from `DB_NAME` (default `xcaro`).
4. Initialize Redis cache from `REDIS_URL`.
5. Create auth, game, WebSocket, and leaderboard handlers.
6. Register Gin routes under `/api`.
7. Run the HTTP server on `PORT` (default `8080`).

### Router Layers

- Public routes: health, Swagger, register/login/refresh/verify-email,
  leaderboard.
- JWT-protected routes: logout, profile, game APIs, WebSocket endpoints,
  resend verification, public opponent profile, avatar update.
- Admin-intended routes: admin user listing, role update, ban, unban.
- Permission-intended game routes: protected game endpoints use the game create
  permission middleware plus per-user rate limiting.

### Main Server Packages

- `internal/auth`: registration, login, refresh/logout, profile updates, admin
  user operations, email verification, JWT middleware.
- `internal/game`: HTTP game endpoints, history/stats, game record retrieval.
- `internal/ws`: WebSocket Hub, Client, Room lifecycle, realtime moves, chat,
  resign/disconnect handling, game-over persistence.
- `internal/leaderboard`: leaderboard cache, player profile, avatar update.
- `internal/elo`: K=32 Elo calculation.
- `internal/cache`: optional Redis client helpers.
- `internal/middleware`: Redis-backed rate limiting.
- `internal/email`: SMTP verification email delivery.

## Data Model

Primary MongoDB collections:

- `users`: account profile, password hash, refresh token, verification state,
  Elo rating, roles/permissions, avatar, ban status.
- `games`: HTTP-created game documents.
- `game_records`: completed online game records, moves, winner, duration,
  Elo deltas, and timestamps.

Redis keys include:

- `leaderboard:top50` for leaderboard cache.
- `stats:<userID>` for user stats cache invalidation.
- `rate_limit:<scope>:<key>` for request counters.

## Authentication Flow

1. User registers with username/email/password.
2. Server hashes the password with bcrypt.
3. Server creates a 24-hour email verification token and sends a verification
   link by SMTP when configured.
4. Login returns:
   - access token (JWT, 24-hour TTL in current code)
   - refresh token (JWT, 7-day TTL)
   - user payload
5. The client stores the refresh token securely and keeps the access token in
   memory.
6. On app startup, the client attempts refresh to restore the session.
7. Logout clears the stored refresh token server-side and client-side.

Protected REST routes expect:

```http
Authorization: Bearer <access_token>
```

## WebSocket Protocol

### Envelope

```json
{
  "type": "join_room",
  "payload": {}
}
```

### Main Event Types

Client-to-server events currently handled:

- `join_room`
- `make_move`
- `resign`
- `game_move`
- `chat_message`
- `ping`

Server-to-client events currently emitted:

- `game_state`
- `game_over`
- `player_join`
- `player_leave`
- `chat_message`
- `error`
- `pong`

### Room Lifecycle

1. Player creates a room or joins by room code.
2. Server assigns X/O symbols and broadcasts `game_state`.
3. Players send `make_move`; server validates turn, occupancy, and game status.
4. Server detects win/draw/resign/disconnect timeout.
5. Server persists a `game_records` document and broadcasts `game_over`.
6. Completed online non-forfeit games update Elo ratings.

Rooms expire after inactivity and disconnected players have a grace period before
forfeit.

## Elo Rating System

XCaro uses a standard K=32 Elo calculation:

```text
expected = 1 / (1 + 10^((opponentRating - playerRating) / 400))
newRating = rating + 32 * (actualScore - expected)
```

Scores:

- win: `1.0`
- draw: `0.5`
- loss: `0.0`

Elo is updated only for completed online games that are not resign/forfeit
outcomes. Game records store `elo_delta_x` and `elo_delta_o`.

## Operational Notes

- Redis is optional at runtime. If it cannot connect, cache helpers and rate
  limiting fail open.
- Email verification requires SMTP env vars. Without SMTP configuration,
  registration still creates the account, but verification email delivery fails.
- The Docker Compose stack defines `mongodb`, `redis`, and `xcaro-server`.
- Swagger files exist under `server/docs/`, but this repository also keeps a
  handwritten API reference in `docs/api.md`.
