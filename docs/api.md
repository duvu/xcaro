# PlayVerse API Reference

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
| PUT | `/profile` | 🔐 | Update current user profile fields, including avatar URL, bio, phone, and date of birth. | `full_name`, `avatar`, optional `date_of_birth`, `phone_number`, `bio` | success message |
| PUT | `/profile/password` | 🔐 | Change password. | current password, new password | success message |
| PUT | `/profile/email` | 🔐 | Change email address, clear `email_verified`, create a new verification token, and send a new verification email. | `new_email`, `password` | success message |

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
| GET | `/games/catalog` | 🔓 | Return the current mini-game catalog for the shared app shell. | none | `games[]` with `game_type`, modes, support flags |
| POST | `/games` | 🛡️ | Create an HTTP game record. Game APIs are rate-limited 60/min/user. | game creation fields | game |
| GET | `/games` | 🛡️ | List games. | optional query params | games list |
| GET | `/games/:id` | 🛡️ | Get game by ID. | path `id` | game |
| POST | `/games/:id/join` | 🛡️ | Join an HTTP game. | player fields | updated game |
| POST | `/games/:id/move` | 🛡️ | Submit a move to an HTTP game. | player ID, row, col | updated game / move result |
| GET | `/games/:id/ws` | 🛡️ | Upgrade to WebSocket and join the specified HTTP game room. | WebSocket upgrade | WS stream |
| GET | `/games/history` | 🛡️ | Get user game history. | `user_id` query | games |
| GET | `/games/stats` | 🛡️ | Get user game stats, including Elo/rank. Legacy clients default to Caro; additive game-aware queries may pass `game_type`. | `user_id`, optional `game_type` query | stats |
| GET | `/games/records` | 🛡️ | Get paginated persisted completed game records. | `page`, `limit` query | records |
| GET | `/games/records/stats` | 🛡️ | Get aggregate completed-game record stats. | none / user context | stats |

## Leaderboard and Public Profiles

| Method | Path | Auth | Description | Request | Response |
|---|---|---|---|---|---|
| GET | `/leaderboard` | 🔓 | Return top 50 players by Elo. Defaults to Caro; future per-game rankings can pass `game_type`. Uses Redis cache with `X-Cache` header when available. | optional `game_type` query | leaderboard entries |
| GET | `/users/:id/profile` | 🔐 | Return a player's public profile, stats, rank, and recent games. | path `id` | public profile |
| PUT | `/users/avatar` | 🔐 | Update current user's avatar URL. | `avatar_url` | updated avatar/user |

## Dashboard and Social

All dashboard/social routes are authenticated REST APIs in the same Go server
deployable. They do not call the WebSocket hub directly; gameplay invites can be
added later through a narrow interface.

| Method | Path | Auth | Description | Request | Response |
|---|---|---|---|---|---|
| GET | `/dashboard/summary` | 🔐 | Return current user's public profile summary, win/loss/draw stats, rank, recent completed games, friend count, and pending request counts. Defaults to Caro; can scope to a game. | optional `game_type` query | `profile`, `stats`, `recent_games`, counts |
| GET | `/dashboard/history` | 🔐 | Return only the current user's completed online game records. Supports pagination and filters. Defaults to Caro; can scope to a game. | query `page`, `limit`, optional `game_type`, `result` (`win`, `loss`, `draw`, or raw result), `opponent`, `from`, `to` | `games`, `page`, `limit`, `has_more` |
| GET | `/social/players` | 🔐 | Privacy-safe player discovery by username. Private fields such as email, password hash, refresh tokens, and verification tokens are never returned. | query `q`, `page`, `limit` | `players` with `friend_status` |
| GET | `/social/friends` | 🔐 | List current user's friends. | none | `friends` |
| DELETE | `/social/friends/:user_id` | 🔐 | Remove an existing friendship owned by current user. | path `user_id` | success message |
| GET | `/social/friend-requests` | 🔐 | List pending friend requests. | query `box=incoming\|outgoing` | `requests` |
| POST | `/social/friend-requests` | 🔐 | Send friend request. Rejects self requests, duplicate pending requests, and existing friendships. | JSON `recipient_id` | friend request |
| POST | `/social/friend-requests/:id/accept` | 🔐 | Accept an incoming pending request and create a friendship. | path `id` | friendship |
| POST | `/social/friend-requests/:id/reject` | 🔐 | Reject an incoming pending request. | path `id` | success message |
| POST | `/social/friend-requests/:id/cancel` | 🔐 | Cancel an outgoing pending request. | path `id` | success message |

Machine-readable social error codes include `invalid_payload`,
`invalid_user_id`, `user_not_found`, `self_friend_request`,
`duplicate_request`, `already_friends`, `request_not_found`,
`friendship_not_found`, `invalid_box`, `invalid_from`, and `invalid_to`.

## WebSocket Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/ws` | 🔐 | Authenticated online multiplayer WebSocket. Rate-limited 10/min/IP. Native clients may pass the access token as `?token=...`; the access logger redacts token query values. |
| POST | `/ws/rooms/join` | 🔐 | Legacy HTTP helper for joining a room; new clients should use WebSocket `join_room_by_code`. |
| POST | `/ws/rooms/leave` | 🔐 | Legacy HTTP helper for leaving a room; new clients should use WebSocket `leave_room` or `resign`. |
| POST | `/ws/messages` | 🔐 | Legacy HTTP helper for sending a room message; new clients should use WebSocket `chat_message`. |
| GET | `/games/:id/ws` | 🛡️ | WebSocket connection scoped to an HTTP game ID. |

### WebSocket Message Envelope

```json
{
  "type": "make_move",
  "game_type": "caro",
  "payload": {
    "x": 7,
    "y": 7
  }
}
```

### Client-to-Server Events

| Type | Payload | Description |
|---|---|---|
| `create_room` | optional `game_type` | Create a room, become Player X, and receive a 6-character room code. Missing `game_type` defaults to `caro`. |
| `join_room_by_code` | `code`, optional `game_type` | Join an existing room as Player O. |
| `rejoin_room` | `room_id` or `code`, optional `game_type` | Restore an existing seat after reconnect. |
| `leave_room` | optional `room_id`, optional `game_type` | Leave a waiting room; in an active game this is treated as resignation. |
| `quick_match_request` | optional `game_type` | Enter the quick-match queue. |
| `quick_match_cancel` | none | Leave the quick-match queue. |
| `make_move` | `x`, `y`, optional `game_type` | Place a stone in the current room. |
| `resign` | optional `game_type` | Resign current game. |
| `game_move` | move payload | Legacy game-scoped move event; not used by the online human-human contract. |
| `chat_message` | `content` | Send in-room chat message. Content must be 1-500 chars. |
| `ping` | none | Application-level ping. |

### Server-to-Client Events

| Type | Payload | Description |
|---|---|---|
| `game_state` | `game_type`, board, players, turn, status | Current room/game state. |
| `game_over` | `game_type`, winner/status/reason | Final game result. |
| `quick_match_found` | `game_type`, `room_id`, `room_code`, `color`, `game_state` | Quick match paired two distinct users. |
| `quick_match_cancelled` | none | Current user left the quick-match queue. |
| `quick_match_timeout` | none | No opponent was found within the queue timeout. |
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
- WebSocket auth uses the protected Gin route group. Flutter/native clients may
  use `?token=<access_token>` only for WebSocket upgrades; normal REST routes
  require the `Authorization: Bearer <access_token>` header.
