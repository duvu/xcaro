## Context

PlayVerse is already more than a single gameplay loop. The Flutter app has a persistent shell with Home, History, Leaderboard, Friends, and Profile surfaces, and the Go backend already owns auth, profile, social, dashboard, leaderboard, reports, and WebSocket gameplay transport. However, the actual game runtime is still Caro-shaped: the online room state hardcodes a 15x15 board and X/O turns in [`server/internal/ws/room.go`](file:///home/beou/IdeaProjects/playverse/server/internal/ws/room.go), the client game flow assumes Caro board semantics, and `game_records` still represent one game domain rather than a platform of games.

The migration must preserve current Caro behavior and current social/dashboard investment while making it practical to add a second mini-game. That means minimizing rewrites, avoiding premature service extraction, and introducing platform boundaries only where the repository is currently too Caro-specific.

## Goals / Non-Goals

**Goals:**
- Convert PlayVerse from a single-game product shape into a platform that can host multiple mini-games in one Flutter app and one Go deployable.
- Preserve backward compatibility for existing Caro players, records, routes, and WebSocket flows during the migration.
- Separate shared platform responsibilities (auth, shell, social, dashboard, history, leaderboard, transport, persistence) from game-specific responsibilities (rules, state, AI, rendering, move payloads).
- Make history, ratings, and leaderboards game-aware so new games can ship without corrupting Caro progression.
- Define a phased migration plan that allows the team to prove the abstractions by adding a second game after Caro is successfully migrated.

**Non-Goals:**
- No microservice split for gameplay, dashboard, or social in the initial migration.
- No full client rewrite or replacement of Flutter Provider with another state-management stack.
- No immediate redesign of all UI surfaces; the first step is architectural migration with compatible behavior.
- No requirement to solve server-restart persistence for active online rooms in the same change.
- No commitment to unified cross-game ranking beyond explicit future support; per-game ranking is the primary target.

## Decisions

### Keep one Flutter app and one Go modular monolith

PlayVerse should remain one client app and one backend deployable. The repository already has strong shared-platform assets: auth, social, dashboard, leaderboard, history, and a stable shell. Splitting services now would add deployment, auth propagation, observability, and data-ownership complexity before the codebase has even separated Caro-specific logic from platform logic.

Alternative considered: split gameplay runtime into a dedicated service now. Rejected because the dominant problem is domain coupling inside the current repo, not scaling boundaries.

### Introduce `game_type` as the primary cross-layer game identity

The migration should add a stable `game_type` (starting with `caro`) across REST, WebSocket, database records, client game routing, and platform catalog entries. Legacy clients that omit `game_type` continue to imply `caro`.

Alternative considered: infer the game from route names or room structures only. Rejected because that keeps the current Caro-specific contract hidden and makes generic history/leaderboard/catalog behavior harder.

### Separate platform runtime from game engines

Shared runtime concerns stay platform-owned: matchmaking, room lifecycle, reconnect grace periods, chat transport, player identity, persistence orchestration, and envelope routing. Game modules own rules, state transitions, move validation, win/draw detection, game-specific serialization, and optional AI/offline support.

Alternative considered: keep all game logic in `internal/ws.Room` and branch per game. Rejected because it would centralize all future game complexity inside the transport/runtime package and make testing much harder.

### Use a game catalog plus client game adapters

The Flutter app should grow into a mini-game hub. Shared shell screens remain shared, but game-specific screens/providers move under per-game modules or adapters. Home evolves into a game catalog/lobby rather than a Caro-only action grid.

Alternative considered: create separate Flutter apps or deeply copy/paste screens per game. Rejected because the product goal is one mini-game platform with shared player identity and shared retention surfaces.

### Evolve persistence instead of replacing it

MongoDB should remain the backing store. Existing `game_records` gain `game_type` and forward-compatible fields while old Caro records are backfilled to `game_type = "caro"`. Ratings move toward per-game storage, but legacy Caro leaderboard behavior remains available during transition.

Alternative considered: split every game into separate collections immediately. Rejected because one generalized record model plus selective indexes is simpler for the first migration, and MongoDB can tolerate additive schema evolution well.

### Default old APIs to Caro-compatible behavior

Current `/api` and `/api/ws` flows should continue working for existing Caro clients, while new `/api/v1` or additive query/payload fields can express multi-game-aware behavior. Compatibility should be explicit in docs and tests.

Alternative considered: rename everything to generic routes in one breaking sweep. Rejected because it would force a synchronized rewrite of client and server at the worst possible phase of the migration.

## Risks / Trade-offs

- **Caro compatibility regressions** → Keep legacy Caro defaults in REST/WS contracts and require compatibility tests before any route or payload changes ship.
- **Over-generalized engine interfaces** → Define only the abstractions needed for Caro and the next mini-game; avoid a speculative plugin framework.
- **Mixed old/new rating models** → Maintain Caro-compatible leaderboard output while gradually introducing per-game rating sources and backfill jobs.
- **Schema drift in MongoDB** → Keep a strict core envelope (`game_type`, players, result, created_at, etc.) and confine game-specific payloads to dedicated fields.
- **Home/dashboard UX becoming muddled** → Preserve current shell tabs and introduce a game catalog as a focused hub instead of scattering game entry points across unrelated screens.

## Migration Plan

1. Document the platform contract: `game_type`, catalog semantics, compatible REST/WS envelopes, and per-game record/rating direction.
2. Add additive schema support for `game_type` and per-game stats while defaulting existing behavior to `caro`.
3. Refactor client code into shared shell plus `caro` module boundaries without changing current gameplay behavior.
4. Extract Caro engine logic from `internal/ws` into a game-specific module while preserving transport/runtime behavior.
5. Make history, dashboard, and leaderboard game-aware with Caro defaults for legacy clients.
6. Add one second mini-game to validate the architecture before removing legacy assumptions.
7. Deprecate or alias old Caro-only routes only after the new platform contract is proven stable.

Rollback strategy: because the migration is additive-first, rollback should usually mean disabling the new catalog/game-aware paths while leaving Caro compatibility routes and Caro records intact.

## Open Questions

- Which second game should be used to validate the abstraction: another turn-based board game, a reaction game, or a puzzle game?
- Should global “all games” progression exist, or should ranking remain strictly per game for the first platform release?
- Should the initial game catalog be static code configuration, or does product need server-driven catalog metadata immediately?
- How much game-specific replay/state retention is needed in `game_records` for non-board games?
