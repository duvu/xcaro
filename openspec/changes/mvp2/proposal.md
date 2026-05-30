## Why

MVP1 shipped a working XCaro product: players can register, play online with real-time move sync, play against a single-difficulty AI, and browse their game history. The remaining gap is **engagement and polish** — features that turn a working app into one players return to. MVP2 closes the highest-value remaining items from the backlog: social chat, a competitive leaderboard, opponent profiles, multi-difficulty AI, email-based account verification, and the production infrastructure (rate limiting, Redis caching, CI/CD) needed to run at scale with confidence.

## What Changes

- **In-game chat**: real-time text chat between opponents during an online match, over the existing WebSocket connection
- **Leaderboard**: global and friends ranking by win rate and rating (Elo-based); replaces the simple wins/losses/draws counter
- **Opponent profile view**: tap on an opponent's name to see their stats, win rate, and recent games
- **Multi-difficulty AI**: Easy / Medium / Hard levels; Easy = shallow random search, Hard = depth-5 threat-space search
- **Email verification**: send a verification email on register; block login until verified (or allow play but badge the account)
- **Tutorial / onboarding**: guided first-game overlay explaining Gomoku rules and controls
- **Rate limiting**: protect auth and game API endpoints from abuse
- **Redis caching**: cache leaderboard and player stats; reduce MongoDB load
- **CI/CD pipeline**: GitHub Actions — lint + test on PR, build + deploy on merge to main

## Capabilities

### New Capabilities

- `in-game-chat`: Real-time text chat between two opponents during an active online game, over the existing WS connection; messages scoped to the room and not persisted beyond the session
- `leaderboard`: Global ranked list of players by Elo rating; personal rank display on Home screen; weekly reset option post-MVP
- `opponent-profile`: Public profile page showing a player's avatar, win/loss/draw counts, rating, and last 5 games; reachable from game result screen and leaderboard
- `multi-difficulty-ai`: Three AI difficulty levels — Easy (depth 1, random candidate), Medium (depth 3, current), Hard (depth 5, full TSS); user-selectable before starting an AI game
- `email-verification`: Verification email sent on registration; unverified accounts are flagged; verified status unlocks online play
- `onboarding-tutorial`: First-launch modal (or tap "?" anytime) explaining Gomoku rules, win condition, and basic controls with animated examples
- `rate-limiting`: Per-IP and per-user rate limits on auth and game endpoints using a sliding-window algorithm (token bucket with Redis)
- `redis-caching`: Cache leaderboard results (TTL 5 min), player stats (TTL 2 min); invalidate on game completion
- `ci-cd-pipeline`: GitHub Actions workflows: PR check (lint, unit tests, build), merge-to-main deploy (build Docker image, push to registry, deploy via docker-compose)

### Modified Capabilities

- `ai-opponent`: Add difficulty selection — Easy/Medium/Hard — replacing the single implicit difficulty. The spec must describe how difficulty maps to search depth and candidate generation strategy.
- `game-history`: Leaderboard and rating data surfaces on the history list (show rating change per game). Stats endpoint now returns Elo rating in addition to wins/losses/draws.

## Impact

- **Client**: `screens/ai_game_screen.dart` (difficulty picker), `screens/home_screen.dart` (leaderboard entry, rating), new `screens/leaderboard_screen.dart`, `screens/opponent_profile_screen.dart`, `screens/onboarding_screen.dart`; `widgets/game_board.dart` (chat overlay); `providers/` (leaderboard, chat, profile providers)
- **Server**: `internal/auth/` (email verification flow), `internal/ws/` (chat message routing in room), new `internal/leaderboard/` package, new `internal/email/` package; all rate-limited endpoints
- **Database**: `users` collection gains `email_verified`, `elo_rating` fields; `game_records` gains `elo_delta_x`, `elo_delta_o`; new `leaderboard` view/aggregation
- **Infrastructure**: Redis added to `docker-compose.yml`; GitHub Actions YAML files; email SMTP config (env var)
- **Dependencies (server)**: `go-redis/redis/v9`, email library (e.g. `jordan-wright/email` or `wneessen/go-mail`)
- **Dependencies (client)**: no new packages needed
