# XCaro API Reference

Base URL: `http://localhost:8080/api`

Auth legend:

- 🔓 Public
- 🔐 Requires `Authorization: Bearer <access_token>`
- 🛡️ Requires JWT plus admin role or game permission as declared by route middleware

## Auth

| Method | Path | Auth | Description | Request | Response |
|---|---|---|---|---|---|
| POST | `/auth/register` | 🔓 | Create account and send verification email when SMTP is configured. Rate-limited 5/min/IP. | `username`, `email`, `password` | `access_token`, `refresh_token`, `user` |
| POST | `/auth/login` | 🔓 | Login with credentials. Rate-limited 5/min/IP. | `username`, `password` | `access_token`, `refresh_token`, `user` |
| POST | `/auth/refresh` | 🔓 | Rotate/refresh access session from refresh token. | `refresh_token` | `access_token`, `refresh_token`, `user` |
| POST | `/auth/logout` | 🔐 | Clear stored refresh token for current user. | none | success message |
| GET | `/auth/verify-email?token=...` | 🔓 | Verify email from link token. | query `token` | success message |
| POST | `/auth/resend-verification` | 🔐 | Generate a new verification token and send another email. | none | success message |

## Profile

| Method | Path | Auth | Description | Request | Response |
|---|---|---|---|---|---|
| GET | `/profile` | 🔐 | Get current user profile. | none | user profile |
| PUT | `/profile` | 🔐 | Update current user profile fields. | profile fields | updated user |
| PUT | `/profile/password` | 🔐 | Change password. | current password, new password | success message |
| PUT | `/profile/email` | 🔐 | Change email address and reset verification. | `email` | updated user / success message |

## Admin Users

| Method | Path | Auth | Description | Request | Response |
|---|---|---|---|---|---|
| GET | `/admin/users` | 🛡️ | List users for administrators. | `page`, `limit` query params | paginated users |
| PUT | `/admin/users/:id/role` | 🛡️ | Update a user's role. | role fields | updated user |
| POST | `/admin/users/:id/ban` | 🛡️ | Ban a user. | optional reason | success message |
| POST | `/admin/users/:id/unban` | 🛡️ | Unban a user. | none | success message |

## Games

| Method | Path | Auth | Description | Request | Response |
|---|---|---|---|---|---|
| POST | `/games` | 🛡️ | Create an HTTP game record. Game APIs are rate-limited 60/min/user. | game creation fields | game |
| GET | `/games` | 🛡️ | List games. | optional query params | games list |
| GET | `/games/:id` | 🛡️ | Get game by ID. | path `id` | game |
| POST | `/games/:id/join` | 🛡️ | Join an HTTP game. | player fields | updated game |
| POST | `/games/:id/move` | 🛡️ | Submit a move to an HTTP game. | player ID, row, col | updated game / move result |
| GET | `/games/:id/ws` | 🛡️ | Upgrade to WebSocket and join the specified HTTP game room. | WebSocket upgrade | WS stream |
| GET | `/games/history` | 🛡️ | Get user game history. | `user_id` query | games |
| GET | `/games/stats` | 🛡️ | Get user game stats, including Elo/rank. | `user_id` query | stats |
| GET | `/games/records` | 🛡️ | Get paginated persisted completed game records. | `page`, `limit` query | records |
| GET | `/games/records/stats` | 🛡️ | Get aggregate completed-game record stats. | none / user context | stats |

## Leaderboard and Public Profiles

| Method | Path | Auth | Description | Request | Response |
|---|---|---|---|---|---|
| GET | `/leaderboard` | 🔓 | Return top 50 players by Elo. Uses Redis cache with `X-Cache` header when available. | none | leaderboard entries |
| GET | `/users/:id/profile` | 🔐 | Return a player's public profile, stats, rank, and recent games. | path `id` | public profile |
| PUT | `/users/avatar` | 🔐 | Update current user's avatar URL. | `avatar_url` | updated avatar/user |

## WebSocket Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/ws` | 🔐 | General WebSocket connection. Rate-limited 10/min/IP. |
| POST | `/ws/rooms/join` | 🔐 | Legacy HTTP helper for joining a room. |
| POST | `/ws/rooms/leave` | 🔐 | Legacy HTTP helper for leaving a room. |
| POST | `/ws/messages` | 🔐 | Legacy HTTP helper for sending a room message. |
| GET | `/games/:id/ws` | 🛡️ | WebSocket connection scoped to an HTTP game ID. |

### WebSocket Message Envelope

```json
{
  "type": "make_move",
  "payload": {
    "row": 7,
    "col": 7
  }
}
```

### Client-to-Server Events

| Type | Payload | Description |
|---|---|---|
| `join_room` | room code / room data | Join an online room. |
| `make_move` | `row`, `col` | Place a stone in the current room. |
| `resign` | optional room data | Resign current game. |
| `game_move` | move payload | Legacy game-scoped move event. |
| `chat_message` | `content` | Send in-room chat message. Content must be 1-500 chars. |
| `ping` | none | Application-level ping. |

### Server-to-Client Events

| Type | Payload | Description |
|---|---|---|
| `game_state` | board, players, turn, status | Current room/game state. |
| `game_over` | winner/status/reason | Final game result. |
| `player_join` | player info | A player joined. |
| `player_leave` | player info | A player left/disconnected. |
| `chat_message` | sender, content, timestamp | In-room chat broadcast. |
| `error` | `code`, `message` | Validation or room error. |
| `pong` | optional timestamp | Application-level pong. |

## Health and Docs

| Method | Path | Auth | Description | Response |
|---|---|---|---|---|
| GET | `/health` | 🔓 | Basic server health. | `{ "status": "ok" }` |
| GET | `/swagger/*any` | 🔓 | Swagger UI/static docs. | Swagger UI |

## Notes

- Routes listed here reflect `server/cmd/server/main.go`, which is the active
  router. Some helper routes in `internal/game/router.go` are not mounted.
- Protected endpoints expect Bearer JWT auth in the `Authorization` header.
- WebSocket auth also relies on the protected Gin route group, not a `token`
  query parameter.
