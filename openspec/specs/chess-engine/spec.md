# chess-engine Specification

## Purpose
TBD - created by archiving change implement-game-chess. Update Purpose after archive.
## Requirements
### Requirement: Go chess engine package
The system SHALL provide a pure Go package `server/internal/games/chess` for server-authoritative chess move validation and game termination detection. It MUST accept a FEN string as input state and return the resulting FEN plus outcome on success, or a machine-readable error on illegal move.

#### Scenario: Legal move accepted
- **WHEN** `ApplyMove(fen, from, to, promotion)` is called with a legal move in standard algebraic from/to (e.g., `"e2"→"e4"`)
- **THEN** returns updated FEN string, empty `MoveOutcome`, nil error

#### Scenario: Illegal move rejected
- **WHEN** `ApplyMove` is called with a move that leaves the king in check, moves to an occupied friendly square, or is otherwise not legal
- **THEN** returns `ErrIllegalMove` with code `illegal_move`

#### Scenario: Out-of-bounds square rejected
- **WHEN** `from` or `to` is not a valid square name (`"a1"`–`"h8"`)
- **THEN** returns `ErrInvalidSquare` with code `invalid_square`

### Requirement: Checkmate detection
The engine MUST detect checkmate when the active player has no legal moves and their king is in check.

#### Scenario: Checkmate returned in outcome
- **WHEN** a move results in the opponent having no legal moves and their king in check
- **THEN** `MoveOutcome.Checkmate == true`, `MoveOutcome.Winner` set to the moving player

### Requirement: Stalemate and draw detection
The engine MUST detect stalemate, insufficient material, and the 50-move rule.

#### Scenario: Stalemate
- **WHEN** the active player has no legal moves and the king is not in check
- **THEN** `MoveOutcome.Draw == true`, `MoveOutcome.DrawReason == "stalemate"`

#### Scenario: 50-move rule
- **WHEN** the FEN half-move clock reaches 100 (50 moves each)
- **THEN** `MoveOutcome.Draw == true`, `MoveOutcome.DrawReason == "fifty_moves"`

#### Scenario: Insufficient material
- **WHEN** only kings remain (or king vs bishop/knight)
- **THEN** `MoveOutcome.Draw == true`, `MoveOutcome.DrawReason == "insufficient_material"`

### Requirement: Special moves
The engine MUST correctly handle all special chess moves: castling, en passant, and pawn promotion.

#### Scenario: Kingside castling
- **WHEN** `from="e1" to="g1"` and castling rights allow
- **THEN** king and rook move correctly, FEN castling rights updated

#### Scenario: En passant
- **WHEN** `from` and `to` match the en passant target square from FEN
- **THEN** capturing pawn moves diagonally, captured pawn removed

#### Scenario: Pawn promotion
- **WHEN** pawn reaches the back rank with `promotion` field set to `"q"/"r"/"b"/"n"`
- **THEN** pawn replaced by specified piece; defaults to queen if promotion field empty

### Requirement: FEN serialization round-trip
The engine MUST produce valid FEN strings. A FEN string produced by the engine SHALL be parseable back into a semantically equivalent game state.

#### Scenario: FEN round-trip
- **WHEN** a valid FEN is parsed and serialized back to FEN
- **THEN** the resulting FEN is semantically identical (same position, rights, clocks)

