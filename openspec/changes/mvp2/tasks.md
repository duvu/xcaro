## 1. Infrastructure Setup

- [x] 1.1 Add `go-redis/redis/v9` to `go.mod` and `go.sum`
- [x] 1.2 Add email library (`wneessen/go-mail`) to `go.mod`
- [x] 1.3 Create `internal/cache/redis.go` — Redis client initialisation, `Get`, `Set`, `Del` helpers with fail-open error handling
- [x] 1.4 Update `docker-compose.yml` to add `redis:7-alpine` service; add `REDIS_URL`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM` env vars to server service
- [x] 1.5 Create `cmd/migrate/main.go` — one-time script to set `elo_rating: 1200`, `email_verified: true` on all existing users

## 2. Email Verification (Server)

- [x] 2.1 Add `EmailVerified bool`, `EmailVerifyToken string`, `EmailVerifyExpiresAt time.Time` fields to `pkg/models/user.go` User struct
- [x] 2.2 Create `internal/email/service.go` — `SendVerificationEmail(to, token string) error` using SMTP env vars
- [x] 2.3 Update `internal/auth/service.go` Register: generate 32-byte hex token, hash it, store in user, call `email.SendVerificationEmail`; set `EmailVerified: false` on new users
- [x] 2.4 Add `VerifyEmail(ctx, token string) error` to auth service: find user by token hash, check expiry, set `EmailVerified: true`, clear token fields
- [x] 2.5 Add `ResendVerification(ctx, userID) error` to auth service: generate new token, update DB, resend email
- [x] 2.6 Add `GET /api/auth/verify-email` and `POST /api/auth/resend-verification` handlers + routes
- [x] 2.7 Update WS `join_room` / `create_room` handlers: check `EmailVerified`; return `email_not_verified` error if false

## 3. Rate Limiting (Server)

- [x] 3.1 Create `internal/middleware/rate_limit.go` — `RateLimiter(limit int, window time.Duration)` Gin middleware using Redis token bucket; fail-open if Redis unavailable
- [x] 3.2 Apply rate limiter to `POST /api/auth/login` and `POST /api/auth/register` (5 req/min/IP)
- [x] 3.3 Apply rate limiter to all `/api/games/*` routes (60 req/min/user)
- [x] 3.4 Apply rate limiter to WS upgrade endpoint (10 req/min/IP)

## 4. Elo Rating (Server)

- [x] 4.1 Add `EloRating int` (default 1200) to `pkg/models/user.go` User struct; add `EloDeltaX int` and `EloDeltaO int` to `pkg/models/game_record.go` GameRecord struct
- [x] 4.2 Create `internal/elo/calculator.go` — `Calculate(ratingA, ratingB int, result float64) (newA, newB int)` using K=32 standard formula
- [x] 4.3 Update game-over path in `internal/ws/room.go`: if game is rated (not forfeit, both players human), call `elo.Calculate`, update user ratings in MongoDB, set delta fields on `GameRecord`
- [x] 4.4 Invalidate leaderboard and player stats Redis cache keys after each Elo update

## 5. Leaderboard (Server + Client)

- [x] 5.1 Create `internal/leaderboard/handler.go` — `GET /api/leaderboard?limit=50`: check Redis cache, fallback to MongoDB `$sort + $limit` on `elo_rating`, cache result with 5-min TTL, return with `X-Cache` header
- [x] 5.2 Add `GET /api/users/:id/profile` handler: return username, avatar, elo_rating, rank, wins, losses, draws, last 5 game records
- [x] 5.3 Register leaderboard and profile routes in `cmd/server/main.go`
- [x] 5.4 Update `GET /api/games/stats` response to include `elo_rating` and `rank`
- [x] 5.5 Create `lib/providers/leaderboard_provider.dart` — fetch and hold leaderboard list
- [x] 5.6 Create `lib/screens/leaderboard_screen.dart` — scrollable ranked list; tap player → navigate to profile
- [x] 5.7 Create `lib/screens/opponent_profile_screen.dart` — shows avatar, rating, stats, last 5 games
- [x] 5.8 Update `HomeScreen` stats widget: show Elo rating + rank alongside wins/losses/draws
- [x] 5.9 Add "Leaderboard" nav entry to Home screen

## 6. In-Game Chat (Server + Client)

- [x] 6.1 Add `EventChatMessage = "chat_message"` constant to `internal/ws/events.go`
- [x] 6.2 Update WS message router in `internal/ws/client.go`: route `chat_message` → validate content (non-empty, ≤500 chars), broadcast to room with sender_id + timestamp
- [x] 6.3 Create `lib/providers/chat_provider.dart` — holds `List<ChatMessage>` for current room, appends on WS `chat_message` event
- [x] 6.4 Update `GameScreen`: add chat icon button in app bar; sliding chat panel (AnimatedContainer) beneath the board; `TextField` + send button; display messages with sender name + timestamp
- [x] 6.5 Wire `ChatProvider` to `WebSocketService` `chat_message` events in `GameProvider` or `ChatProvider`

## 7. Multi-Difficulty AI (Client)

- [x] 7.1 Add `AiDifficulty` enum (`easy`, `medium`, `hard`) to `lib/ai/ai_engine.dart`
- [x] 7.2 Update `AiEngine.bestMove(board, aiPlayer, difficulty)`: Easy = depth 1 + 10 random candidates; Medium = depth 3 + top 20 proximity (current); Hard = depth 5 + threat-space candidates + 1s timeout fallback
- [x] 7.3 Update `AiIsolate.computeAiMove(board, aiPlayer, difficulty)` to pass difficulty through
- [x] 7.4 Add difficulty picker bottom sheet to `AiGameScreen` shown before game starts (Easy/Medium/Hard radio buttons)
- [x] 7.5 Store selected difficulty in `OfflineAiProvider`; pass to `computeAiMove` each turn

## 8. Email Verification (Client)

- [x] 8.1 After register success, show a "Check your email" screen/dialog prompting verification before online play
- [x] 8.2 When server returns `email_not_verified` error on join/create room, show inline banner: "Please verify your email" with a "Resend" button
- [x] 8.3 Add `ApiService.resendVerification()` calling `POST /api/auth/resend-verification`

## 9. Onboarding Tutorial (Client)

- [x] 9.1 Create `lib/screens/onboarding_screen.dart` — 4-step PageView: What is Gomoku / Place a stone / Win condition (5-in-a-row animated) / Get started; "Got it!" button on last page sets `shared_preferences` key `onboarding_complete: true`
- [x] 9.2 In `main.dart` startup routing: after auth check, if `!prefs.getBool('onboarding_complete')` → show `OnboardingScreen`, then Home
- [x] 9.3 Add "How to play" option in settings that navigates to `OnboardingScreen` (bypasses flag check)

## 10. CI/CD (DevOps)

- [x] 10.1 Create `.github/workflows/pr.yml` — triggers on PR to `main`; jobs: `server-check` (`go vet`, `go test ./...`), `client-check` (`flutter analyze`, `flutter test`)
- [x] 10.2 Create `.github/workflows/deploy.yml` — triggers on push to `main`; jobs: build Docker image, push to GHCR (`ghcr.io/<owner>/playverse-server:latest` + SHA tag), SSH deploy with `docker-compose pull && docker-compose up -d`
- [x] 10.3 Create `server/Dockerfile` (if not exists) with multi-stage build: `golang:1.21-alpine` builder → `alpine:latest` runtime
- [x] 10.4 Document required GitHub Actions secrets in `README.md`: `GHCR_TOKEN`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST`, `DEPLOY_USER`

## 11. Redis Caching Integration Tests + Unit Tests

- [x] 11.1 Write unit tests for `elo/calculator.go`: test win/loss/draw outcomes with known rating pairs
- [x] 11.2 Write unit tests for `middleware/rate_limit.go`: mock Redis, verify 429 after limit exceeded, verify fail-open on Redis error
- [x] 11.3 Write unit test for `AiEngine` difficulty levels: verify Hard AI beats Easy AI in a forced sequence
