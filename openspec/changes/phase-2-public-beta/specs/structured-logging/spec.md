# Spec: Structured Logging

## Purpose

Replace ad-hoc `log.Printf` calls with structured, filterable JSON log lines so production incidents can be triaged efficiently.

## Requirements

### Configuration

- **LOG-S-1**: In `cmd/server/main.go`, when `GIN_MODE == "release"` (or `os.Getenv("LOG_FORMAT") == "json"`), set `slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo})))`.
- **LOG-S-2**: Otherwise (development), use `slog.NewTextHandler` for human-readable output.
- **LOG-S-3**: Do not add a new dependency. `log/slog` is part of the Go standard library since Go 1.21 and is available with the project's Go 1.23 toolchain.

### Auth Subsystem (`internal/auth/`)

- **LOG-A-1**: On successful register: `slog.Info("auth.register", "user_id", ..., "email", emailMasked)`. Mask email as `u***@domain`.
- **LOG-A-2**: On successful login: `slog.Info("auth.login", "user_id", ..., "ip", ...)`.
- **LOG-A-3**: On failed login (wrong password): `slog.Warn("auth.login_failed", "email", emailMasked, "ip", ...)`.
- **LOG-A-4**: On token refresh: `slog.Info("auth.refresh", "user_id", ...)`.
- **LOG-A-5**: On logout: `slog.Info("auth.logout", "user_id", ...)`.
- **LOG-A-6**: On email verification: `slog.Info("auth.email_verified", "user_id", ...)`.
- **LOG-A-7**: On rate limit exceeded in auth routes: `slog.Warn("auth.rate_limited", "ip", ...)`.

### WebSocket / Room Subsystem (`internal/ws/`)

- **LOG-WS-1**: On room create: `slog.Info("room.create", "room_id", ..., "user_id", ...)`.
- **LOG-WS-2**: On player join: `slog.Info("room.join", "room_id", ..., "user_id", ...)`.
- **LOG-WS-3**: On game start (two players in room): `slog.Info("game.start", "room_id", ..., "player_black", ..., "player_white", ...)`.
- **LOG-WS-4**: On game over: `slog.Info("game.over", "room_id", ..., "winner", ..., "reason", ...)`.
- **LOG-WS-5**: On resign: `slog.Info("game.resign", "room_id", ..., "user_id", ...)`.
- **LOG-WS-6**: On disconnect forfeit: `slog.Info("game.forfeit", "room_id", ..., "disconnected_user_id", ...)`.
- **LOG-WS-7**: On chat message: `slog.Info("chat.message", "room_id", ..., "user_id", ..., "len", len(msg))`. Do NOT log message content.
- **LOG-WS-8**: On quick match request/cancel/found/timeout (Phase 2 additions): log with event key matching the WS event name.

### Leaderboard / Elo Subsystem

- **LOG-ELO-1**: On Elo update: `slog.Info("elo.update", "user_id", ..., "delta", ..., "new_elo", ...)`.

### Error Handling

- **LOG-ERR-1**: Replace all `log.Printf("error ...")` with `slog.Error("...", "subsystem", ..., "error", err)`.
- **LOG-ERR-2**: Run `grep -r 'log\.Print' server/` as part of the final task to confirm migration is complete.

## Acceptance Criteria

- `go build ./...` passes after the migration.
- Running the server in `GIN_MODE=release` and registering a user produces a JSON log line with `event=auth.register`, `user_id`, and masked email.
- No `log.Printf` calls remain in `internal/` packages (only `log.Fatal` for startup errors is permitted).
