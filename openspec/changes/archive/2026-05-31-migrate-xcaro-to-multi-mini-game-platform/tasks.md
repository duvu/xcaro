## 1. Platform Contract And Architecture

- [x] 1.1 Document the target one-app, one-server mini-game platform architecture in docs and design artifacts, including why the repo stays a modular monolith.
- [x] 1.2 Define the shared `game_type` contract across REST, WebSocket, client registry, and persisted game records with explicit Caro compatibility defaults.
- [x] 1.3 Define the game catalog and game registry contracts that let the Flutter shell host multiple mini-games while keeping shared Home/History/Leaderboard/Friends/Profile surfaces.

## 2. Backend Runtime Boundaries

- [x] 2.1 Extract or introduce a platform-owned game runtime boundary that separates room lifecycle, matchmaking, reconnect, chat, and persistence orchestration from game-specific rules.
- [x] 2.2 Move Caro-specific rule/state logic out of `server/internal/ws/room.go` into a dedicated Caro game module or engine boundary.
- [x] 2.3 Add additive server route and payload support for `game_type` while preserving legacy Caro route and WebSocket behavior.

## 3. Persistence, History, And Ranking

- [x] 3.1 Evolve `game_records` to store `game_type` and forward-compatible participant/result metadata without breaking current Caro reads.
- [x] 3.2 Introduce or define per-game rating/stat storage so leaderboard and progression can be scoped by game.
- [x] 3.3 Update dashboard, history, and leaderboard APIs to support per-game queries with Caro-compatible defaults during migration.

## 4. Flutter Platform Shell And Game Modules

- [x] 4.1 Refactor the Flutter app into shared shell/platform modules plus a dedicated `caro` game module boundary.
- [x] 4.2 Evolve the home experience into a game hub or catalog while preserving current Caro entry points during migration.
- [x] 4.3 Introduce client-side game registry or adapter contracts so future mini-games can plug into navigation, session handling, and rendering without copying the entire shell.

## 5. Compatibility And Migration

- [x] 5.1 Preserve existing Caro client compatibility for room creation, join-by-code, quick match, gameplay state, and game-over handling while platform abstractions are added.
- [x] 5.2 Backfill or alias existing Caro history and ranking data so migrated records resolve to `game_type = caro`.
- [x] 5.3 Define a phased rollout plan that proves the abstractions by adding a second mini-game only after Caro runs through the new platform contracts.

## 6. Documentation And Verification

- [x] 6.1 Update architecture and API documentation for game catalog, `game_type`, platform/game boundaries, and compatibility guarantees.
- [x] 6.2 Add verification coverage for backward-compatible Caro flows plus at least one future-facing multi-game contract path.
- [x] 6.3 Run server/client verification commands and record any unrelated pre-existing failures separately from migration work.
