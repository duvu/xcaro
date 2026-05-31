## Why

PlayVerse already has the foundations of a shared game platform: one Flutter app shell, one Go modular monolith, authentication, profiles, history, leaderboard, social/friends, and online realtime play. The current system is still tightly coupled to Caro-specific state, routes, records, and UI flows, which makes adding a second mini-game expensive and risky.

Now is the right time to migrate because the repository has already accumulated platform-level capabilities beyond a single game. Converting PlayVerse into a multi-mini-game platform will let the product grow through additional games while preserving one app, one backend, shared player identity, shared social graph, and shared engagement surfaces.

## What Changes

- Introduce a platform-level game catalog and `game_type` contract so the app, backend, WebSocket runtime, and persistence can identify which game a room, record, leaderboard, or history entry belongs to.
- Refactor the current Caro implementation into the first game module (`caro`) inside a broader mini-game platform architecture instead of treating Caro as the entire product.
- Generalize room/session runtime boundaries so shared transport, matchmaking, reconnect, chat, and persistence stay platform-owned while per-game move validation, state evolution, and result logic move into game-specific engines.
- Evolve history, leaderboard, ratings, and dashboard data from global Caro assumptions into per-game views with backward-compatible defaults for existing Caro clients and records.
- Extend the Flutter shell into a mini-game hub that keeps shared Home/History/Leaderboard/Friends/Profile surfaces while introducing a game catalog and game-specific adapters/modules.
- Document migration compatibility rules, platform boundaries, and phased rollout so the repository can add a second game without a rewrite or early microservice split.

## Capabilities

### New Capabilities
- `mini-game-platform-shell`: Shared app shell, game catalog, and navigation model for hosting multiple mini-games in one Flutter app.
- `game-runtime-abstraction`: Generic room/session runtime, `game_type` contract, and per-game engine boundaries for online/offline gameplay.
- `per-game-history-and-ranking`: Per-game records, ratings, leaderboard, dashboard, and history behavior with backward-compatible Caro defaults.

### Modified Capabilities

None. `openspec/specs/` is currently empty, so this migration introduces new canonical capability specs rather than modifying existing spec folders.

## Impact

- Flutter client: [`client/lib/main.dart`](file:///home/beou/IdeaProjects/playverse/client/lib/main.dart), [`client/lib/screens/main_scaffold.dart`](file:///home/beou/IdeaProjects/playverse/client/lib/screens/main_scaffold.dart), [`client/lib/screens/home_screen.dart`](file:///home/beou/IdeaProjects/playverse/client/lib/screens/home_screen.dart), game/session providers, WebSocket transport, and new game catalog/adapter modules.
- Go server: [`server/cmd/server/main.go`](file:///home/beou/IdeaProjects/playverse/server/cmd/server/main.go), [`server/internal/ws/`](file:///home/beou/IdeaProjects/playverse/server/internal/ws), game/history/leaderboard/dashboard/social packages, and new platform/game engine boundaries.
- Persistence: `game_records` schema evolution, per-game rating/stat storage, optional game catalog metadata, and migration/backfill of existing Caro records to `game_type = "caro"`.
- APIs/protocols: additive REST and WebSocket contracts carrying `game_type` while preserving legacy Caro-compatible defaults.
- Documentation/tests: architecture docs, API docs, QA matrix, migration notes, and verification for compatibility plus second-game readiness.
