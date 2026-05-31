## Context

PlayVerse is a Flutter/Go modular mini-game platform. Caro (Gomoku 15×15) is the first game module. The platform introduced a `game_type` contract during `migrate-xcaro-to-multi-mini-game-platform`: rooms carry `GameType`, the WebSocket hub validates via `IsSupportedGameType`, and `caro.ApplyMove` is dispatched from `room.ApplyMove`. The client has `GameModule`, `GameRegistry`, and `GameCatalogProvider`. Chess must plug into these seams as a second game module.

Current integration points:
- `server/internal/games/catalog.go`: `GameTypeCaro`, `DefaultCatalog()`, `IsSupportedGameType()` — extend for `chess`
- `server/internal/games/caro/engine.go`: `ApplyMove(board *[15][15]int, player, x, y int)` returning `MoveOutcome{WinningCells,Draw}` — chess needs a different signature
- `server/internal/ws/room.go`: `Room{Board [15][15]int, GameType string}`, `ApplyMove(userID, x, y int)` delegates to caro engine — needs chess branch
- `server/internal/ws/client.go`: `make_move` reads `x,y int` from payload — needs `from,to,promotion` for chess
- `client/lib/games/game_registry.dart`: `modules = [caroGameModule]` — add `chessGameModule`
- `client/lib/ai/ai_engine.dart`: Caro-specific minimax — chess AI needs separate implementation

## Goals / Non-Goals

**Goals:**
- Server-authoritative chess move validation, legal move enumeration, check/checkmate/stalemate/draw detection
- FEN string as canonical chess state representation in `game_state` payload for chess rooms
- Online human-vs-human Chess via existing WebSocket hub (same create/join/quick-match/resign/chat flow as Caro)
- Offline AI Chess (Easy/Medium/Hard) client-side, mirroring existing Caro AI pattern
- Chess game module registered in `GameRegistry` and visible in the game catalog
- Per-game chess Elo in `user_game_ratings` (same mechanism as Caro)
- Backward-compatible: existing Caro rooms and clients unaffected

**Non-Goals:**
- Spectator mode, game replay, opening book, endgame tablebase
- External UCI engine integration (Stockfish etc.) — too heavy for this platform
- Chess tournaments, variants (Chess960, etc.)
- Time controls beyond turn-based play
- Custom chess piece artwork / animated moves (use a chess board widget with standard pieces)

## Decisions

### 1. Chess engine: `github.com/notnil/chess` wrapped behind internal package

**Decision**: Use `github.com/notnil/chess` as the underlying chess rules library, wrapped behind `server/internal/games/chess/engine.go`. The rest of the server (hub, room) depends only on the internal package interface, not on the external library directly.

**Rationale**: Chess move validation is deceptively large — check avoidance, castling constraints, en passant timing, promotion, stalemate/checkmate all have subtle edge cases. Because the server is authoritative, a bug in move validation is a game-integrity bug, not a UI bug. `github.com/notnil/chess` is a well-tested, MIT-licensed Go library that handles FEN, PGN, and all legal move generation correctly. Wrapping it behind our internal package preserves the ability to swap implementations later without touching hub/room code. (Oracle recommendation: use the library, not in-house.)

### 2. Chess state: FEN string in payload, separate from Caro's `[15][15]int` board

**Decision**: Chess rooms carry state as a FEN string. The `game_state` payload includes `"fen"` key (for chess) and `"board"` key (for caro). The existing `Room.Board [caro.BoardSize][caro.BoardSize]int` is Caro-specific; chess rooms use a `Room.FEN string` field instead.

**Rationale**: FEN encodes the entire chess position (pieces + castling rights + en passant + half-move clock + side to move) in one string. Serializing 64 squares as a 2D array would work too, but FEN is the industry standard, parseable by any chess library, and matches what existing chess board Flutter widgets expect.

**Implementation**: `Room` gains `FEN string` alongside `Board`. When `GameType == "chess"`, `ApplyMove` uses `FEN`; when `"caro"`, uses `Board`. `toGameStateLocked` emits the relevant field.

### 3. Polymorphic `make_move` payload

**Decision**: `make_move` WebSocket payload accepts either `{x,y}` (Caro) or `{from,to,promotion}` (Chess) depending on `game_type` of the room. The server routes by `room.GameType` inside `Room.ApplyMove`.

**Rationale**: Keeps the `make_move` event name stable. From the hub's perspective, `HandleMakeMove(client, x, y, from, to, promotion)` receives all possible fields; only the fields relevant to the current game type are used. The client sends the correct payload shape for its active game type.

### 4. Chess AI: client-side minimax, no server involvement

**Decision**: Chess AI lives in `client/lib/ai/chess/` as Dart/Flutter code, mirroring the Caro `AiEngine` pattern (minimax + alpha-beta + time limit). The server only validates moves (same as online); offline AI games never touch the server.

**Rationale**: Consistent with Caro AI pattern. The server remains a pure game-state authority for online play; AI is a client concern. Depth: Easy=1, Medium=2, Hard=3 (chess tree is much wider than Caro; depth 3 is already tactically meaningful with alpha-beta). Time cap: 900ms (same as Caro).

### 5. Flutter chess board widget: `squares` package

**Decision**: Use `squares` on pub.dev for the chessboard widget. It supports custom piece themes, legal move highlighting, and FEN-based state rendering.

**Alternative considered**: `flutter_chess_board` (older, less maintained). `squares` has active maintenance and FEN support.

### 6. Backward compatibility in `room.go` and `hub.go`

**Decision**: `Room.MakeMove(userID, x, y, from, to, promotion)` — add the chess-specific parameters with zero defaults; Caro path ignores them. Existing tests pass unchanged. `client.go` reads all possible fields and passes them; Caro rooms ignore `from/to/promotion`, chess rooms ignore `x/y`.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| In-house chess engine may have edge-case legal move bugs | Seed with a comprehensive test suite covering castling, en passant, promotion, check detection |
| Room struct grows with both Board and FEN fields | Acceptable: only one is non-zero per room; no persistence of both |
| Client chess AI might be slow on low-end devices | 900ms time cap + depth cap; run in Dart isolate (same as Caro's `ai_isolate.dart`) |
| `squares` package major version change breaks API | Pin version in `pubspec.yaml`; isolate in `chess_board_widget.dart` |
| Chess Elo vs Caro Elo are separate — UX confusion | Design decision; per-game ratings are a feature, not a bug |

## Migration Plan

1. Server: add chess engine → extend catalog/hub/room (no DB migration needed; `game_records` already has `game_type` field)
2. Client: add chess module/screens/AI → register in GameRegistry → catalog auto-shows Chess
3. Existing Caro routes, rooms, AI, leaderboard: unaffected
4. Deploy server before client release (new game_type unknown to old clients → catalog shows Chess only after client update)

## Open Questions

- Should chess quick-match be enabled from day one? (Proposed: yes, same as Caro)
- Draw offers (player can offer a draw)? (Proposed: no for now — only automatic draws: 50-move rule, stalemate, insufficient material)
- Pawn promotion choice UI: auto-queen or picker? (Proposed: picker dialog on client, defaults to queen if promotion not specified in online play)
