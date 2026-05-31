## ADDED Requirements

### Requirement: Chess room creation and joining
Authenticated users SHALL be able to create or join a chess room using the same WebSocket flow as Caro by passing `game_type: "chess"` in the `create_room` or `join_room_by_code` payload.

#### Scenario: Create chess room
- **WHEN** a user sends `create_room` with `game_type: "chess"`
- **THEN** a room is created with `GameType="chess"`, initial FEN for starting position, and `game_state` payload includes `"fen"` key

#### Scenario: Join chess room
- **WHEN** a second user sends `join_room_by_code` with a valid chess room code
- **THEN** both players receive `game_state` with `started: true`, `"fen"` key, and their seat assignments

### Requirement: Chess move via WebSocket
Online chess moves MUST use the `make_move` event with `from`, `to`, and optional `promotion` fields.

#### Scenario: Valid chess move
- **WHEN** the active player sends `make_move` with `{from: "e2", to: "e4"}`
- **THEN** server validates via chess engine, broadcasts updated `game_state` with new FEN

#### Scenario: Illegal move rejected
- **WHEN** a player sends a move that is illegal (e.g., moving into check)
- **THEN** server sends `error` with code `illegal_move` only to the sender; room state unchanged

#### Scenario: Pawn promotion online
- **WHEN** a player sends `make_move` with a pawn reaching the back rank and `promotion: "q"`
- **THEN** server applies promotion, broadcasts updated FEN with queen on back rank

### Requirement: Chess game termination
Checkmate, stalemate, and draw conditions MUST be detected server-side and broadcast as `game_over`.

#### Scenario: Checkmate
- **WHEN** a move results in checkmate
- **THEN** `game_over` broadcast with `result: "win"`, `winner` = checkmating player's user ID

#### Scenario: Stalemate/draw
- **WHEN** stalemate, 50-move rule, or insufficient material occurs
- **THEN** `game_over` with `result: "draw"`, empty `winner`

### Requirement: Chess quick match
Quick match pairing SHALL work for chess with `game_type: "chess"` in the `quick_match_request` payload. Only chess-requesting clients MUST be paired together — cross-game-type pairing is forbidden.

#### Scenario: Two chess quick-match users paired
- **WHEN** two users both send `quick_match_request` with `game_type: "chess"`
- **THEN** they are paired into a chess room, both receive `quick_match_found` + initial chess `game_state`

#### Scenario: No cross-game pairing
- **WHEN** one user requests Caro and another requests Chess quick match
- **THEN** they are NOT paired; each waits for a same-game-type partner

### Requirement: Chess Elo and persistence
Completed online chess games MUST be persisted to `game_records` with `game_type: "chess"`. Elo SHALL be updated in `user_game_ratings` with `game_type: "chess"`.

#### Scenario: Win persisted
- **WHEN** a chess game ends by checkmate
- **THEN** `game_records` entry inserted with `game_type: "chess"`, `winner`, `result: "win"`, Elo deltas calculated and stored in `user_game_ratings` and `users.elo_rating`
