# PlayVerse Architecture

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

## Mini-Game Platform Direction

PlayVerse now evolves as a one-app, one-server mini-game platform rather than a
single-game product. The active migration keeps the existing Flutter shell,
social/dashboard/history/leaderboard modules, and Go modular monolith, while
introducing a shared `game_type` contract and a static game catalog that starts
with `caro`.

Boundary rules for this migration:

- shared platform concerns stay in the shell/server platform layers: auth,
  profile, dashboard, social, history, leaderboard, transport, matchmaking,
  reconnect, and persistence orchestration;
- game-specific rules move behind per-game modules, starting with a dedicated
  Caro engine under `server/internal/games/caro`;
- legacy clients that omit `game_type` continue to mean `caro`;
- a second mini-game should be added only after Caro runs successfully through
  the new platform contract.

## Flutter Client Architecture

The active Flutter project is `client/`.

Key layers:

- `lib/main.dart` wires providers and named routes.
- `lib/providers/` stores app state with Provider/ChangeNotifier:
  - authentication/session state
  - online game state
  - offline AI game state
  - leaderboard/profile state
  - dashboard/social state
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
3. Select database from `DB_NAME` (default `playverse`).
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
- `internal/games`: platform game catalog and shared game-type contract.
- `internal/ws`: WebSocket Hub, Client, Room lifecycle, realtime moves, chat,
  resign/disconnect handling, game-over persistence.
- `internal/leaderboard`: leaderboard cache, player profile, avatar update.
- `internal/social`: dashboard summary/history BFF endpoints plus player
  discovery, friend requests, and friendship management.
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
  `game_type`, Elo deltas, optional participant/rating metadata, and timestamps.
- `user_game_ratings`: per-game rating documents keyed by `user_id` and
  `game_type` for future non-Caro leaderboards.
- `friend_requests`: pending/accepted/rejected/cancelled requests with
  requester, recipient, normalized `pair_key`, status, and timestamps.
- `friendships`: accepted normalized user pairs with unique `pair_key` and
  timestamps for friend-list lookup/removal.

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
  "type": "join_room_by_code",
  "game_type": "caro",
  "payload": { "code": "ABC123" }
}
```

### Main Event Types

Client-to-server events currently handled:

- `create_room`
- `join_room_by_code`
- `rejoin_room`
- `leave_room`
- `quick_match_request`
- `quick_match_cancel`
- `make_move`
- `resign`
- `game_move` (legacy compatibility only)
- `chat_message`
- `ping`

Server-to-client events currently emitted:

- `game_state`
- `game_over`
- `quick_match_found`
- `quick_match_cancelled`
- `quick_match_timeout`
- `player_join`
- `player_leave`
- `chat_message`
- `error`
- `pong`

### Room Lifecycle

1. Player creates a room with `create_room` or joins by code with
   `join_room_by_code`. Legacy clients may omit `game_type`, which defaults to
   `caro`.
2. Server assigns X/O symbols and broadcasts `game_state`.
3. Players send `make_move`; server validates turn, occupancy, and game status.
4. Server detects win/draw/resign/disconnect timeout.
5. Server persists a `game_records` document tagged by `game_type` and
   broadcasts `game_over`.
6. Completed online games update Elo ratings, including resign/forfeit outcomes.

Rooms expire after inactivity and disconnected players have a grace period before
forfeit.

## Dashboard And Social Boundary

Dashboard and social management stay in the existing Go server as a modular
monolith. This keeps registration, profile, history, leaderboard, and friendship
data close to the existing MongoDB collections while avoiding a premature second
deployable, database, or event bus.

Boundary rules:

- Dashboard/social APIs are authenticated REST routes under `/api/dashboard` and
  `/api/social`.
- The module may read `users`, `game_records`, `friend_requests`, and
  `friendships` only through its own service/repository code.
- It must not import or mutate `internal/ws` Hub/Room internals. Friend invites
  or presence should be added through an explicit interface or event later.
- Public discovery/profile summaries must not expose email, password hash,
  refresh tokens, verification tokens, or ban internals.

Future extraction criteria:

- dashboard/social traffic or release cadence differs materially from gameplay;
- a separate moderation/admin team needs independent ownership;
- social graph storage/querying needs a different database or search backend;
- compliance or privacy boundaries require separate deployment controls.

Until one of those conditions is true, the modular-monolith boundary is the
recommended architecture.

## Elo Rating System

PlayVerse uses a standard K=32 Elo calculation:

```text
expected = 1 / (1 + 10^((opponentRating - playerRating) / 400))
newRating = rating + 32 * (actualScore - expected)
```

Scores:

- win: `1.0`
- draw: `0.5`
- loss: `0.0`

Elo is updated for completed online games when both players are known. Game
records store `elo_delta_x` and `elo_delta_o`.

## Operational Notes

- Redis is optional at runtime. If it cannot connect, cache helpers and rate
  limiting fail open.
- Email verification requires SMTP env vars. Without SMTP configuration,
  registration still creates the account, but verification email delivery fails.
- The Docker Compose stack defines `mongodb`, `redis`, and `playverse-server`.
- Swagger files exist under `server/docs/`, but this repository also keeps a
  handwritten API reference in `docs/api.md`.
