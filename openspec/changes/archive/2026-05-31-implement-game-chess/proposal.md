## Why

PlayVerse launched as a multi-mini-game platform with Caro as the first game; Chess is the natural second module — universally understood, strategically deep, and widely expected in any board-game platform. Adding Chess validates the `game_type` contract built during platform migration and expands the audience beyond Caro players.

## What Changes

- New Go engine package `server/internal/games/chess` implementing server-authoritative move validation, check/checkmate/stalemate detection, and FEN-based state serialization.
- Extended `Room` and WebSocket protocol to carry chess-specific move payloads (`from`, `to`, `promotion`) alongside the existing `game_type` contract; `make_move` payload becomes polymorphic per game type.
- `server/internal/games/catalog.go` and `IsSupportedGameType` updated to include `chess`.
- New Flutter game module `client/lib/games/chess/` with `ChessModule`, routes `/chess_game` (online), `/chess_ai_game` (offline AI).
- New Flutter screens: `chess_game_screen.dart` for online play and `chess_ai_game_screen.dart` for offline AI.
- Client-side chess AI (minimax + alpha-beta, Easy/Medium/Hard) in `client/lib/ai/chess/` — mirrors the Caro AI pattern; server is authoritative for online games only.
- `GameRegistry.modules` extended with `chessGameModule`.
- Per-game Elo rating for `chess` stored in `user_game_ratings` with `game_type=chess` — same mechanism as Caro.
- `docs/GAME_RULES.md`, API docs, and QA matrix updated for Chess.

## Capabilities

### New Capabilities

- `chess-engine`: Server-side move validation, legal move generation, check/checkmate/stalemate/draw detection, FEN state serialization.
- `chess-online`: Online human-vs-human Chess via existing WebSocket room/hub infrastructure with polymorphic move payload.
- `chess-ai`: Offline AI opponent (Easy/Medium/Hard) via client-side minimax with alpha-beta pruning.
- `chess-module-shell`: Flutter game module registration, routing, board rendering, and piece interaction for Chess.

### Modified Capabilities

- `online-multiplayer`: The `make_move` WebSocket payload now accepts `from`/`to`/`promotion` fields in addition to `x`/`y`; server routes by `game_type`.

## Impact

**Server:**
- `server/internal/games/catalog.go` — add `GameTypeChess`, `DefaultCatalog`, `IsSupportedGameType`
- `server/internal/games/chess/engine.go` — new chess engine package
- `server/internal/ws/room.go` — polymorphic `ApplyMove` dispatch by `room.GameType`; chess board state via FEN string
- `server/internal/ws/client.go` — `make_move` payload parsing extended for chess moves
- `server/internal/ws/hub.go` — `game_state` payload includes FEN for chess rooms

**Flutter client:**
- `client/lib/games/chess/chess_module.dart` — new module constant
- `client/lib/games/game_registry.dart` — add `chessGameModule`
- `client/lib/ai/chess/` — chess AI engine files
- `client/lib/screens/chess_game_screen.dart` — online chess UI
- `client/lib/screens/chess_ai_game_screen.dart` — offline AI chess UI
- `client/lib/main.dart` — routes `/chess_game`, `/chess_ai_game`
- `client/pubspec.yaml` — add `flutter_chess_board` or equivalent Flutter chess widget package

**Dependencies:**
- Server: `github.com/notnil/chess` Go library for chess rules/FEN/move validation (MIT license); wrapped behind internal package
- Client: pub.dev chess board widget (e.g., `squares` package for flexible board rendering)

**Persistence/Elo:**
- `game_records` collection gains chess game entries with `game_type=chess`
- `user_game_ratings` gains per-user chess Elo entries
