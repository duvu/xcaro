## Context

MVP1 delivered the core XCaro stack: Flutter/Dart client (Flame + Provider), Go backend (Gin + Gorilla WebSocket + MongoDB), JWT auth with refresh tokens, real-time 15×15 Gomoku multiplayer, depth-3 AI opponent, and game history. MVP2 adds the engagement layer on top of that foundation without replacing any MVP1 work.

Key existing constraints: Go module `github.com/duvu/xcaro/server`, WebSocket message envelope `{ "type", "payload" }`, 15×15 board, MongoDB document store, `just_audio` + `flutter_secure_storage` already in pubspec.

## Goals / Non-Goals

**Goals:**
- In-game chat scoped to active WS room (no persistence)
- Elo-based rating system + leaderboard (global top-N)
- Public opponent profile pages
- AI difficulty picker (Easy/Medium/Hard)
- Email verification on registration
- Onboarding tutorial overlay (first launch)
- Rate limiting on auth + game endpoints
- Redis caching (leaderboard, player stats)
- GitHub Actions CI/CD (lint/test on PR, deploy on merge)

**Non-Goals:**
- Friends list / social graph (post-MVP)
- Spectator mode (post-MVP)
- Replay viewer / PGN export (post-MVP)
- Push notifications (post-MVP)
- Weekly leaderboard reset (post-MVP)
- Chat persistence (ephemeral only)

## Decisions

### 1. In-Game Chat: Reuse Existing WS Room, No Persistence

**Decision**: Route `chat_message` WS messages through the existing room hub. Server validates message (non-empty, ≤500 chars), broadcasts to room. No DB write — messages are ephemeral.

**Rationale**: Zero new infrastructure. WS connection already open; adding a message type is the minimal change. Persistence adds GDPR/moderation complexity — deferred.

**Alternative**: Separate WebSocket channel or HTTP polling — unnecessary complexity.

### 2. Elo Rating: Calculated Server-Side on Game End

**Decision**: On every game-end path in the WS hub, compute Elo delta (K=32, standard formula) for both players, update `users.elo_rating`, store `elo_delta_x` and `elo_delta_o` in `game_records`. Default starting Elo: 1200. AI games and forfeits do not affect rating.

**Rationale**: Server-authoritative rating prevents cheating. Standard K=32 is appropriate for a game with moderate match frequency. Starting at 1200 is the chess convention.

**Alternative**: Separate rating service — overkill at MVP2 scale.

### 3. Leaderboard: MongoDB Aggregation + Redis Cache

**Decision**: `GET /api/leaderboard?limit=50` runs a MongoDB `$sort + $limit` on `users.elo_rating`. Result cached in Redis with 5-minute TTL. On game end, invalidate the leaderboard key. Player stats cache TTL: 2 minutes.

**Rationale**: Leaderboard query is expensive at scale but rarely changes. Redis with short TTL gives freshness with minimal DB load. Full real-time leaderboard updates are not required at MVP.

**Alternative**: Materialized view in MongoDB — harder to invalidate on arbitrary game ends.

### 4. Email Verification: SMTP with Time-Limited Token

**Decision**: On registration, generate a random 32-byte hex token, store hashed in `users.email_verify_token` + `users.email_verify_expires_at` (24h TTL). Send `GET /api/auth/verify-email?token=xxx` link via SMTP. Unverified users can log in but cannot create/join online rooms (server rejects with 403 + `reason:"email_not_verified"`). No online game penalty for AI or offline modes.

**Rationale**: Balances friction (block online play, not all play) with usability (user can explore the app before verifying). Time-limited token prevents stale links.

**Alternative**: Verify before any login — too aggressive, high drop-off risk.

### 5. Rate Limiting: Token Bucket in Redis Middleware

**Decision**: Implement a Gin middleware using Redis as the token bucket store. Limits:
- Auth endpoints (`/api/auth/login`, `/api/auth/register`): 5 requests / minute / IP
- Game endpoints (`/api/games/*`): 60 requests / minute / user
- WebSocket upgrade: 10 / minute / IP

**Rationale**: Redis-backed token bucket is stateless across server instances (ready for horizontal scaling). Gin middleware is the natural extension point.

### 6. AI Difficulty: Depth + Candidate Generation Per Level

| Level | Search Depth | Candidate Moves |
|---|---|---|
| Easy | 1 | random 10 from all empty adjacent cells |
| Medium | 3 | top 20 by naive proximity score (current) |
| Hard | 5 | threat-space candidates (forcing moves first) |

**Decision**: `AiEngine.bestMove(board, aiPlayer, difficulty)` accepts the difficulty enum. Isolate call passes it through. Difficulty stored in the `OfflineAiProvider` / `AiGameScreen` state.

### 7. CI/CD: GitHub Actions, Two Workflows

- **PR check** (`.github/workflows/pr.yml`): `go vet`, `go test ./...`, `flutter analyze`, `flutter test`
- **Deploy** (`.github/workflows/deploy.yml`): on push to `main` — build Docker image, push to GHCR, SSH into server, `docker-compose pull && docker-compose up -d`

## Risks / Trade-offs

- **Redis single point of failure** → Mitigation: if Redis is unreachable, fall back to uncached DB query (don't crash). Rate limiter fails open (allow request) to preserve availability.
- **SMTP deliverability** → Mitigation: use a transactional email service (SendGrid/SES) via SMTP relay configured by env var; log failures but don't block registration.
- **Elo accuracy with small samples** → Accepted: Elo is noisy with few games. Add a "provisional" flag after <10 games — post-MVP concern.
- **Hard AI performance on old phones** → Mitigation: depth-5 with TSS candidate pruning; already running in Dart `Isolate`. Add 1s timeout: if no result within 1s, return best move found so far.

## Migration Plan

1. **MongoDB**: add `elo_rating` (default 1200), `email_verified` (default false), `email_verify_token`, `email_verify_expires_at` to `users` — flexible schema, no migration script needed. Add `elo_delta_x`, `elo_delta_o` to `game_records` — new fields, backward-compatible.
2. **Redis**: add to `docker-compose.yml` as a new service `redis:7-alpine`. Server reads `REDIS_URL` env var; falls back gracefully if absent.
3. **Existing users**: all existing users get `elo_rating: 1200`, `email_verified: true` (retroactively, via a one-time migration script in `cmd/migrate/main.go`) so they aren't locked out of online play.
4. **Client**: no breaking changes to existing screens; new screens added additively.
5. **Rollback**: remove Redis service and revert rate-limit middleware; existing game flow unaffected.

## Open Questions

- Should the leaderboard be paginated (top-50 default) or infinite scroll? Recommend top-50 first page, load more on demand.
- Should chat messages be limited to emoji reactions as well as text, or text-only for MVP2? Recommend text-only.
- SMTP provider: use env-var-configurable SMTP host so the deployer can plug in SendGrid/SES/local relay. No hardcoded provider.
