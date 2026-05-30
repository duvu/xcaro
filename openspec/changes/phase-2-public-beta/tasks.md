# Phase 2: Public Beta — Tasks

## 1. Server Infrastructure

- [x] 1.1 `server/internal/metrics/metrics.go`: Create Metrics struct with atomic counters (active_ws_connections, total_games_created, total_moves_made, active_queue_size, http_requests_total) and singleton Get() + NewHandler()
- [x] 1.2 `server/internal/reports/handler.go`: Create Report model (reporter_id, reported_user_id, game_id, reason, created_at) and POST /api/reports handler with rate limit 3/hr/user
- [x] 1.3 `server/internal/reports/router.go`: RegisterRoutes() to mount POST /api/reports under auth middleware
- [x] 1.4 `server/internal/errors/handler.go`: Create ErrorReport model (platform, version, error_type, message, stack_trace, created_at) and POST /api/errors handler with rate limit 10/hr/IP
- [x] 1.5 `server/internal/errors/router.go`: RegisterRoutes() to mount POST /api/errors as public endpoint

## 2. Server — Quick Match Queue

- [x] 2.1 `server/internal/ws/events.go`: Add EventQuickMatchRequest, EventQuickMatchFound, EventQuickMatchCancelled, EventQuickMatchTimeout constants
- [x] 2.2 `server/internal/ws/hub.go`: Add matchQueue []string field; implement EnqueueQuickMatch(clientID string), DequeueQuickMatch(clientID string), processMatchQueue() — if 2+ players in queue, pop two, create room, send EventQuickMatchFound to both with room code
- [x] 2.3 `server/internal/ws/hub.go`: Start 60-second timeout goroutine per queued player; on timeout send EventQuickMatchTimeout and dequeue
- [x] 2.4 `server/internal/ws/client.go`: Route incoming "quick_match_request" WS message to hub.EnqueueQuickMatch; route "quick_match_cancel" to hub.DequeueQuickMatch
- [x] 2.5 `server/internal/ws/hub.go`: Update metrics.Get().ActiveQueueSize on every enqueue/dequeue

## 3. Server — Structured Logging

- [x] 3.1 `server/cmd/server/main.go`: Replace log.Printf setup with slog.New(slog.NewJSONHandler(os.Stdout, nil)) in production; text handler if DEBUG=true env var; set as default logger with slog.SetDefault
- [x] 3.2 `server/internal/auth/service.go`: Replace log.Printf calls with slog.InfoContext / slog.ErrorContext with fields: user_id, email, event=register/login/logout/refresh/verify/resend
- [x] 3.3 `server/internal/ws/hub.go` and `room.go`: Replace log.Printf with slog.InfoContext with fields: room_id, client_id, event=room_created/joined/move/game_over/disconnect/forfeit
- [x] 3.4 `server/internal/leaderboard/handler.go`: Add slog.InfoContext on cache hit/miss with field: cache_hit=true/false
- [x] 3.5 `server/internal/elo/calculator.go`: Add slog.InfoContext on Elo update with fields: winner_id, loser_id, delta_w, delta_l

## 4. Server — Operational Metrics Endpoint

- [x] 4.1 `server/cmd/server/main.go`: Mount GET /api/metrics under RequireRole("admin") middleware; handler returns JSON of metrics.Get() snapshot; increment metrics.Get().HttpRequestsTotal in a Gin middleware on each request
- [x] 4.2 `server/internal/ws/hub.go`: Increment metrics.Get().ActiveWsConnections on client register, decrement on unregister; increment TotalGamesCreated on room creation; increment TotalMovesMade on valid move

## 5. Server — Player Report

- [x] 5.1 `server/cmd/server/main.go`: Call reports.RegisterRoutes(router, db) to mount POST /api/reports
- [x] 5.2 `server/internal/reports/handler.go`: Validate reported_user_id exists (lookup users collection), reason required and max 500 chars; insert into reports collection; return 201 on success, 400 on validation fail, 429 on rate limit
- [x] 5.3 `server/internal/middleware/ratelimit.go`: Add UserRateLimiter(key string, limit int, window time.Duration) helper reusable by reports and errors handlers

## 6. Server — Crash Error Endpoint

- [x] 6.1 `server/cmd/server/main.go`: Call errors.RegisterRoutes(router, db) to mount POST /api/errors (public, no auth required)
- [x] 6.2 `server/internal/errors/handler.go`: Validate platform ∈ {android, ios, web}, version non-empty, message non-empty; insert into errors collection; return 201 on success, 400 on validation fail, 429 on rate limit; log error receipt with slog

## 7. Client — Quick Match

- [x] 7.1 `client/lib/screens/quick_match_waiting_screen.dart`: New screen with CircularProgressIndicator, "Finding opponent..." text, Cancel button; listens to GameProvider.quickMatchState; transitions to GameScreen on EventQuickMatchFound
- [x] 7.2 `client/lib/providers/game_provider.dart`: Add quickMatchState enum (idle/waiting/found/timeout), handleQuickMatchFound(), handleQuickMatchTimeout(); on found, set room code and switch to inGame state
- [x] 7.3 `client/lib/services/websocket_service.dart`: Route incoming "quick_match_found", "quick_match_timeout" to GameProvider handlers
- [x] 7.4 `client/lib/screens/home_screen.dart`: Add "Quick Match" button below Create Room; on press, send WS message "quick_match_request" and Navigator.push QuickMatchWaitingScreen

## 8. Client — Room Invite Share

- [x] 8.1 `client/pubspec.yaml`: Add `share_plus: ^10.0.0` dependency
- [x] 8.2 `client/lib/screens/create_room_screen.dart`: Import share_plus; after room is created and code is visible, add Share button that calls Share.share("Join my XCaro game! Code: \$code\nxcaro://room/\$code")
- [x] 8.3 `client/lib/screens/create_room_screen.dart`: Show "Waiting for opponent..." below code with LinearProgressIndicator; Share button visible throughout waiting state

## 9. Client — UX Polish

- [x] 9.1 `client/lib/widgets/empty_state_widget.dart`: Create EmptyStateWidget(icon, title, subtitle, actionLabel?, onAction?) — card with centered icon + text + optional button
- [x] 9.2 `client/lib/widgets/error_state_widget.dart`: Create ErrorStateWidget(message, onRetry?) — card with error icon + message + optional Retry button
- [x] 9.3 `client/lib/screens/leaderboard_screen.dart`: Replace plain empty list with EmptyStateWidget("No players yet", "Be the first to play!"); wrap FutureBuilder error branch with ErrorStateWidget(onRetry: reload)
- [x] 9.4 `client/lib/screens/history_screen.dart`: Replace empty list with EmptyStateWidget("No games yet", "Play your first match!"); wrap load error with ErrorStateWidget
- [x] 9.5 `client/lib/screens/opponent_profile_screen.dart` (or profile screen): Wrap error state with ErrorStateWidget; add loading skeleton or CircularProgressIndicator while fetching
- [x] 9.6 `client/lib/screens/join_room_screen.dart`: Add ErrorStateWidget inline below text field when join fails (invalid code, room full, game in progress)
- [x] 9.7 `client/lib/screens/home_screen.dart`: Add WS connection status chip (green dot "Connected" / red dot "Reconnecting…") using WebSocketService.connectionStatus stream
- [x] 9.8 `client/lib/screens/game_screen.dart`: Map game_over reason codes to human strings (resign→"Opponent resigned", disconnect_forfeit→"Opponent disconnected", draw→"It's a draw!"); show in end-game dialog
- [x] 9.9 `client/lib/screens/onboarding_screen.dart`: Improve tutorial copy on page 2/3 ("Create a room or join with a code" → clearer instructions with room code visual example)

## 10. Client — Mute Chat

- [x] 10.1 `client/lib/providers/game_provider.dart`: Add bool chatMuted = false; toggleChatMute() method; expose via Provider
- [x] 10.2 `client/lib/widgets/chat_box.dart`: Add mute toggle icon button in chat header; when muted, show semi-transparent overlay "Chat muted" over chat messages area; messages still received, just not shown

## 11. Client — Player Report

- [x] 11.1 `client/lib/services/api_service.dart`: Add submitReport(String reportedUserId, String gameId, String reason) POST /api/reports; returns Future<void>; throws on non-201
- [x] 11.2 `client/lib/screens/game_screen.dart`: Add kebab/overflow menu with "Report player" option in AppBar actions; on tap, show dialog with reason text field (max 500 chars) and Submit button; call ApiService.submitReport; show SnackBar "Report submitted"

## 12. Client — Crash/Error Tracking

- [x] 12.1 `client/pubspec.yaml`: Add `package_info_plus: ^8.0.0` dependency
- [x] 12.2 `client/lib/services/api_service.dart`: Add submitErrorReport({required String platform, required String version, required String errorType, required String message, String? stackTrace}) POST /api/errors; fire-and-forget (catch and ignore network errors)
- [x] 12.3 `client/lib/main.dart`: In main(), call WidgetsFlutterBinding.ensureInitialized(); set FlutterError.onError to log + call ApiService.submitErrorReport; set PlatformDispatcher.instance.onError to catch uncaught isolate errors + call submitErrorReport; wrap runApp in runZonedGuarded for zone errors
- [x] 12.4 `client/lib/main.dart`: Load PackageInfo.fromPlatform() once at startup; store version string in a global/singleton for use by error reporter

## 13. Server — go.mod / Build Verification

- [x] 13.1 `server/`: Run `go build ./...` and `go vet ./...`; fix any import or lint issues introduced by new packages
- [x] 13.2 `server/`: Run `go test ./internal/ws/... ./internal/reports/... ./internal/errors/...`; add minimal test for EnqueueQuickMatch + processMatchQueue pairing logic if no test file exists

## 14. Client — pub get / Analyze / Test Verification

- [x] 14.1 `client/`: Run `flutter pub get`; verify share_plus and package_info_plus resolve
- [x] 14.2 `client/`: Run `flutter analyze`; fix any new issues introduced by Phase 2 changes; target 0 errors
- [x] 14.3 `client/`: Run `flutter test`; verify existing AI and widget tests still pass

## 15. OpenSpec Completion

- [x] 15.1 Mark all tasks `[x]` in this file after verification passes
