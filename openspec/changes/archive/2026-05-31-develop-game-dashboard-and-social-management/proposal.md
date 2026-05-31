## Why

PlayVerse already has authentication, online play, game records, stats, leaderboard, and profile surfaces, but they are scattered across gameplay-oriented screens and APIs. A dedicated game dashboard/social management capability will make account onboarding, history review, and friend relationships visible as a cohesive player experience while aligning with the roadmap's Phase 3 engagement goals.

The dashboard/management backend should not be split into a separate service yet. The current Go server already owns users, auth, game records, leaderboard, and online presence; a modular monolith keeps data consistency and operations simple while preserving future extraction boundaries.

## What Changes

- Introduce a player dashboard experience in the existing Flutter app that consolidates registration/login entry, profile summary, game history/statistics, leaderboard shortcuts, and social/friend actions.
- Add friend management: discover players by username/profile, send/cancel/accept/reject friend requests, remove friends, list friends, and prevent self/duplicate relationships.
- Extend history management so users can review and filter their completed games from dashboard/profile contexts with clear empty/error/loading states.
- Add backend social/friends REST APIs in the existing Go server using the same JWT authentication, MongoDB user/game-record data, and role/ownership checks.
- Keep dashboard/social management in the game server deployable for now, but define module boundaries and API contracts so `friends/social` or `dashboard/admin` can be extracted later if scaling, security, or team ownership requires it.
- Document dashboard/social APIs, authorization rules, persistence indexes, and the service-separation decision.

## Capabilities

### New Capabilities
- `game-dashboard-management`: Player-facing dashboard, account entry, profile summary, history management, and navigation over existing game/account data.
- `social-friends`: Friend discovery and friend request/friendship lifecycle, including duplicate/self-request prevention and privacy-safe friend lists.
- `dashboard-service-boundary`: Architectural contract for keeping dashboard/social management in the current game server as a modular monolith with future extraction criteria.

### Modified Capabilities

None. `openspec/specs/` is currently empty, so this change introduces new canonical capability specs rather than modifying existing ones.

## Impact

- Flutter client: `client/lib/main.dart`, `client/lib/screens/main_scaffold.dart`, `client/lib/screens/home_screen.dart`, `client/lib/screens/history_screen.dart`, `client/lib/screens/opponent_profile_screen.dart`, new or updated dashboard/friends widgets/screens/providers, and `client/lib/services/api_service.dart`.
- Go server: new internal friends/social package or clearly bounded route/service files, `server/cmd/server/main.go` route registration, existing auth/profile/game history handlers, MongoDB indexes/collections for friend requests and friendships.
- APIs: authenticated REST endpoints for dashboard summary/history and friend request lifecycle; no direct coupling to WebSocket gameplay internals except optional invite/presence integration through explicit service interfaces.
- Documentation/tests: API docs, architecture docs, QA matrix, server unit/integration tests for authorization and friend lifecycle, Flutter widget/provider tests for dashboard and friends flows.
- No new deployable service or database is required in the initial implementation.
