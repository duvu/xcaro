# Phase 2 Public Beta — Design

## Current State

The XCaro MVP (Phase 1 validated) provides: JWT auth, WS-based online rooms identified by a 6-character code, in-game chat, AI opponent, Elo leaderboard, email verification, Redis caching, rate limiting, and CI/CD. The client has no matchmaking, no sharing, no empty-state widgets, no error tracking, and logging is stdlib `log.Printf`. There is no server metrics surface.

## Goals

| Goal | Rationale |
|---|---|
| Quick match queue | Remove manual room-code exchange; let two players connect in seconds. |
| Room invite share | Let a host share a room to a friend via any app (WhatsApp, clipboard, etc.). |
| UX polish (empty/error states) | Blank lists and silent failures create confusion in real user sessions. |
| Mute chat | Give players agency over disruptive chat without leaving the room. |
| Player report | Basic abuse-flagging that feeds into the existing admin ban flow. |
| Structured logging | Production incidents on a live service need structured, filterable logs. |
| Operational metrics | Know active rooms, connected clients, game rate, and failed logins at a glance. |
| Crash / error tracking | Surface uncaught Flutter exceptions before users give up silently. |

## Non-Goals

- No ranked/unranked queue distinction (Phase 4).
- No FCM push notifications (separate change; requires platform credentials).
- No friend system (Phase 3).
- No moderation dashboard UI (admin API endpoint is enough for Phase 2).
- No full telemetry platform (Prometheus/Grafana); a simple JSON endpoint suffices.

## Architecture Decisions

### 1. Quick Match Queue

**Decision**: in-process queue in the WS hub (`matchQueue []*Client`) protected by the existing `h.mu`. No external message broker needed at Phase 2 scale.

- Client sends WS message `{ "type": "quick_match_request" }` on the shared WS connection.
- Hub checks `matchQueue`. If empty, enqueues the client. If a waiting client exists, pops it, creates a `Room` with a random 6-char code, and sends `quick_match_found` to both clients with `{ "room_id": ..., "room_code": ..., "color": ... }`.
- Client transitions directly to the game screen on receiving `quick_match_found`.
- Cancel: client sends `{ "type": "quick_match_cancel" }` or disconnects; hub removes from queue and sends `quick_match_cancelled` to the cancelling client.
- Queue entry expires after 60 seconds; hub sends `quick_match_timeout` and removes the entry.
- REST endpoint `POST /api/ws/queue/join` and `DELETE /api/ws/queue/leave` are also provided for clients that need to join/leave via HTTP before WS is connected.
- No Elo band matching in Phase 2; any two players are matched. Elo-banded matching is Phase 4.

### 2. Room Invite Share

**Decision**: Flutter `share_plus` package. The room code is shared as plain text with a deep-link prefix.

- `CreateRoomScreen` gains a "Share" `IconButton` that calls `Share.shareXFiles([])` with a text payload: `Tham gia phòng XCaro của mình: xcaro://room/<code>` or a fallback plain-code text.
- Deep-link handling (routing user directly to JoinRoomScreen with pre-filled code) is a future task; Phase 2 only sends the share sheet.
- No new server API needed.

### 3. UX Polish — Empty and Error States

**Decision**: create a shared `EmptyStateWidget(icon, title, subtitle, [action])` and `ErrorStateWidget(message, [onRetry])` used across all list/async screens.

Screens to update:
- `LeaderboardScreen` — empty when no players; error on fetch failure.
- `HistoryScreen` — empty first-time user; error on fetch failure.
- `OpponentProfileScreen` — error if profile not found.
- `HomeScreen` — empty recent games list; WS connection status badge.
- `JoinRoomScreen` — error when room code not found or full.
- `CreateRoomScreen` — pending/waiting state with share button.

Onboarding: update copy in `OnboardingScreen` pages 2–3 to mention room code sharing and the new quick match button.

Disconnect/expiry messaging: `GameScreen` already shows a dialog on `game_over` WS event. Improve the disconnect reason string mapping (`forfeit`, `timeout`, `opponent_disconnected`) to human-readable Vietnamese text.

### 4. Mute Chat

**Decision**: client-side only. A boolean flag in `GameProvider` (or `ChatProvider`). When muted, the chat panel renders an overlay "Chat đã tắt tiếng" and incoming `chat_message` WS events are not displayed. The flag is not persisted and resets per game session. No server change needed.

- `GameScreen` chat icon button toggles mute state.
- `ChatBox` widget receives a `isMuted` prop.

### 5. Player Report

**Decision**: lightweight report to a `reports` MongoDB collection. No review UI in Phase 2 — admins query via MongoDB directly or via a future admin panel.

- New model `Report { id, reporterID, reportedUserID, gameID, reason, details, createdAt }`.
- New REST endpoint `POST /api/reports` (authenticated, rate-limited 3/hour/user).
- `GameScreen` shows a "Report" option in the game menu / three-dot menu.
- Client sends `{ "reported_user_id": ..., "game_id": ..., "reason": "abuse|spam|bot", "details": "..." }`.
- Server validates, inserts to `reports` collection, returns `201`. No email or push sent in Phase 2.

### 6. Structured Logging

**Decision**: use Go stdlib `log/slog` (available since Go 1.21, in use with Go 1.23). No new dependency.

- Replace all `log.Printf(...)` calls with `slog.Info(...)`, `slog.Error(...)` with structured key-value pairs.
- Log subsystems and fields:
  - auth: `event=register/login/logout/verify/refresh`, `user_id`, `email` (no PII passwords/tokens), `ip`.
  - ws room: `event=room_create/join/leave/game_start/game_over/resign/disconnect`, `room_id`, `user_id`.
  - chat: `event=chat_message`, `room_id`, `user_id`, `len=<message-length>`.
  - leaderboard: `event=elo_update`, `user_id`, `delta`, `new_elo`.
  - errors: `event=error`, `subsystem`, `error`.
- In `main.go`, set `slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))` so output is line-delimited JSON.
- Development: set `slog.NewTextHandler` when `GIN_MODE != release`.

### 7. Operational Metrics

**Decision**: simple in-process counters exposed as a JSON endpoint. No Prometheus dependency in Phase 2.

- New `internal/metrics/` package with `Metrics` struct: `ActiveRooms int64`, `ConnectedClients int64`, `CompletedGames int64`, `FailedLogins int64` using `sync/atomic`.
- Hub increments/decrements `ActiveRooms` and `ConnectedClients` on room create/close and client connect/disconnect.
- Auth handler increments `FailedLogins` on failed login.
- Game service increments `CompletedGames` on game end.
- New endpoint `GET /api/metrics` (admin-only auth middleware): returns JSON snapshot.
- Flutter `HomeScreen`: adds a WS connection status chip (Connected/Reconnecting) using the existing `WebSocketService` state.

### 8. Crash / Error Tracking

**Decision**: custom `FlutterErrorObserver` in `main.dart` that catches `FlutterError.onError` and `PlatformDispatcher.instance.onError`. Errors are formatted and sent to a new server endpoint `POST /api/errors` (authenticated, rate-limited).

- Server side: `internal/errors/` package with `ErrorReport` model and a simple insert to MongoDB `error_reports` collection. No external sink.
- This avoids requiring Firebase/Sentry credentials in Phase 2; can be replaced later.
- `FlutterError.onError` captures widget build errors; `PlatformDispatcher.instance.onError` captures async uncaught errors.
- Reports include: `platform`, `appVersion`, `error`, `stackTrace` (truncated at 4KB).

## Risks and Tradeoffs

| Risk | Mitigation |
|---|---|
| In-process queue lost on server restart | Acceptable for Phase 2; client shows timeout and user re-queues. Phase 4 adds persistent queue. |
| `share_plus` deep-link not handled yet | Phase 2 only sends the share text; deep-link routing is a follow-up. |
| Error reports may contain PII in stack traces | Truncate at 4KB; exclude auth tokens from capture; document in privacy policy. |
| `slog` migration may miss some log calls | Run `grep -r 'log\.Print' server/` as a post-migration lint check. |

## Migration / Rollout Notes

- All changes are additive. No database migration needed beyond two new MongoDB collections (`reports`, `error_reports`).
- `slog` migration is a refactor of internal server code; no API surface changes.
- `share_plus` adds one new Flutter dependency; `flutter pub get` is required.
- Quick match queue uses no new external services; can be deployed in the same container.

## Open Questions

1. Should `quick_match_cancel` also remove the opponent if they were found but the game has not started? (Resolved: yes; send `opponent_cancelled` and discard the room.)
2. Should player reports be anonymous from the reportee's perspective? (Resolved: yes; server stores reporter but client UI does not expose reporter identity.)
3. Should crash error reports require the user to be authenticated? (Resolved: yes for Phase 2; unauthenticated error sink is a future capability.)
