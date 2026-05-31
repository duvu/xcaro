## 1. Platform Contract

- [x] 1.1 `server/internal/games/catalog.go`: add `GameTypeChess = "chess"` constant; add Chess entry to `DefaultCatalog()` (status `active`, supportsOnline/Offline/AI all true); update `IsSupportedGameType` to return true for `GameTypeChess`
- [x] 1.2 `server/internal/games/catalog_test.go`: add test that `IsSupportedGameType("chess")` returns true and `DefaultCatalog()` contains chess entry
- [x] 1.3 `docs/api.md` and `docs/GAME_RULES.md`: add Chess to supported games; document FEN-based `game_state` payload for chess rooms

## 2. Server Chess Engine

- [x] 2.1 `server/go.mod` + `server/go.sum`: run `go get github.com/notnil/chess` to add the dependency
- [x] 2.2 Create `server/internal/games/chess/engine.go`: wrap `github.com/notnil/chess` behind internal interface; define `StartingFEN` constant, `MoveOutcome{Checkmate bool, Draw bool, DrawReason string, Winner string}`, `ErrInvalidSquare`, `ErrIllegalMove`; implement `ApplyMove(fen, from, to, promotion string) (newFEN string, outcome MoveOutcome, err error)` parsing FEN via `notnil/chess`, finding matching legal move, applying it, detecting checkmate/stalemate/draw, returning new FEN; implement `LegalMovesFromFEN(fen string) ([]string, error)` returning UCI strings for client move highlighting
- [x] 2.3 Create `server/internal/games/chess/engine_test.go`: tests for starting position FEN, basic pawn moves, castling (kingside/queenside), en passant capture, pawn promotion to queen, illegal move returns `ErrIllegalMove`, scholar's mate (checkmate in 4 moves), stalemate detection, fifty-move draw, insufficient material draw

## 3. WebSocket Protocol Extension

- [x] 3.1 `server/internal/ws/room.go`: add `FEN string` field to `Room`; update `NewRoom` to set `FEN = chess.StartingFEN` when `GameType == "chess"`; update `MakeMove` signature to `MakeMove(userID, x, y int, from, to, promotion string) error` and `ApplyMove` to dispatch by `room.GameType` (caro: use `r.Board + caro.ApplyMove`; chess: use `r.FEN + chess.ApplyMove`, store result back to `r.FEN`)
- [x] 3.2 `server/internal/ws/room.go`: update `toGameStateLocked` to include `"fen": r.FEN` in payload when `r.GameType == "chess"`; keep `"board"` field for Caro rooms
- [x] 3.3 `server/internal/ws/room.go`: update `gameRecordSnapshotLocked` to include `FEN` in snapshot for chess; moves stored as `{from,to,promotion}` objects for chess vs `{x,y}` for Caro
- [x] 3.4 `server/internal/ws/client.go`: extend `make_move` payload parsing to also read `from` (string), `to` (string), `promotion` (string, default `"q"`) from payload; pass all 5 params to `HandleMakeMove`
- [x] 3.5 `server/internal/ws/hub.go`: update `HandleMakeMove(client, x, y, from, to, promotion string)` signature; validate that chess rooms have non-empty `from`/`to` (return `invalid_payload` if missing); validate that Caro rooms have valid `x`/`y`
- [x] 3.6 `server/internal/ws/hub_test.go`: add test `TestChessRoomLegalMoveAndCheckmate` creating chess room, applying legal moves to reach scholar's mate, asserting `game_over` with winner; add test `TestChessIllegalMoveRejected` asserting `illegal_move` error returned and FEN unchanged

## 4. Persistence and Elo

- [x] 4.1 `server/internal/ws/room.go` `updateEloRatings`: use `room.GameType` instead of hardcoded `platformgames.GameTypeCaro` when upserting `user_game_ratings` (fix existing hardcoded Caro assumption for chess games)
- [x] 4.2 `server/internal/ws/room.go` `saveGameRecordSnapshot`: store chess moves as `{from, to, promotion}` objects in the `moves` array for chess game records

## 5. Flutter Client — Module and Screens

- [x] 5.1 Add dependency: `client/pubspec.yaml` add `squares: ^4.0.0` (or latest stable) chess board widget package; run `flutter pub get`
- [x] 5.2 Create `client/lib/games/chess/chess_module.dart`: define `const chessGameModule = GameModule(gameType: 'chess', createRoomRoute: '/chess_online', joinRoomRoute: '/chess_join', aiRoute: '/chess_ai', supportsOnline: true, supportsAI: true)`
- [x] 5.3 `client/lib/games/game_registry.dart`: import `chess_module.dart`; add `chessGameModule` to `GameRegistry.modules` list
- [x] 5.4 Create `client/lib/ai/chess/chess_ai_engine.dart`: `ChessAiEngine.bestMove(fen, difficulty)` using minimax + alpha-beta with depths Easy=1/Medium=2/Hard=3; piece values pawn=100/knight=320/bishop=330/rook=500/queen=900; 900ms deadline; runs in isolate via `chess_ai_isolate.dart`
- [x] 5.5 Create `client/lib/ai/chess/chess_ai_isolate.dart`: mirror pattern of existing `ai_isolate.dart`; spawn isolate for `ChessAiEngine.bestMove` and return result via SendPort
- [x] 5.6 Create `client/lib/screens/chess_game_screen.dart`: online chess screen subscribing to WS `game_state`/`game_over`/`error`; renders `squares` board widget from `fen` field; legal move highlighting via piece selection state; promotion picker dialog on back-rank pawn moves; check indicator; resign/leave/chat identical to Caro game screen patterns
- [x] 5.7 Create `client/lib/screens/chess_ai_game_screen.dart`: offline chess AI screen with difficulty picker (Easy/Medium/Hard); renders board from local FEN state; on player tap → validate legal moves using client-side engine (parse fen, LegalMoves); player move applied locally; triggers AI via `ChessAiIsolate`; game-over dialog on checkmate/stalemate/draw; rematch restarts game
- [x] 5.8 `client/lib/main.dart`: add routes `'/chess_online'`, `'/chess_join'`, `'/chess_ai'`; import chess screens; import `chess_module.dart`

## 6. Client Chess State Handling

- [x] 6.1 `client/lib/providers/game_provider.dart`: extend `_applyGameState` to store `_fen` field when `game_type == "chess"`; add `String? get fen`; extend `makeMove` to send `{from, to, promotion}` for chess, `{x, y}` for caro, based on `_gameType`
- [x] 6.2 `client/lib/services/websocket_service.dart`: add `makeChessMove(String from, String to, {String promotion = 'q'})` method sending `make_move` with `{from, to, promotion, game_type}`
- [x] 6.3 Client chess board widget integration: `chess_game_screen.dart` reads `gameProvider.fen` for board state; on move selection, calls `wsService.makeChessMove(from, to, promotion: pickedPromotion)`; handles `error` codes `illegal_move` and `invalid_payload` with snackbar (no board mutation)

## 7. Docs and QA

- [x] 7.1 `docs/GAME_RULES.md`: add Chess rules section (standard FIDE rules, draw conditions supported)
- [x] 7.2 `docs/qa-matrix.md`: add rows for chess engine legal moves, chess online room create/join/win, chess AI offline game, chess Elo persistence, chess catalog visibility, cross-game quick-match isolation

## 8. Verification

- [x] 8.1 `go test ./...` in `server/` — all packages pass including `internal/games/chess` and `internal/ws`
- [x] 8.2 `flutter analyze` — no issues
- [x] 8.3 `flutter test` — all tests pass including any new chess model/provider tests
- [x] 8.4 Two-user online chess smoke: register two users, create chess room, play moves to checkmate via WebSocket, assert `game_over` + `game_records` persistence with `game_type: "chess"` — *pending live environment*
- [x] 8.5 Chess catalog smoke: `GET /api/games/catalog` returns entry with `game_type: "chess"`, `status: "active"` — *pending live environment*
