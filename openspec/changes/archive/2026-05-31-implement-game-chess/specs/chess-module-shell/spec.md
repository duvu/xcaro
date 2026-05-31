## ADDED Requirements

### Requirement: Chess game module registered
The system SHALL register a `chessGameModule` constant in `client/lib/games/chess/chess_module.dart` and MUST include it in `GameRegistry.modules`.

#### Scenario: Chess appears in catalog
- **WHEN** the server catalog returns an entry with `game_type: "chess"`
- **THEN** the home screen shows a Chess card in the game selector
- **AND** `GameRegistry.find("chess")` returns `chessGameModule`

### Requirement: Online chess screen
`chess_game_screen.dart` SHALL render the chess board for online play using the `fen` field from the `game_state` WebSocket payload.

#### Scenario: Board renders from FEN
- **WHEN** the client receives `game_state` with `game_type: "chess"` and a `fen` field
- **THEN** the chess board displays the correct position as described by the FEN

#### Scenario: Legal move highlighting
- **WHEN** the player taps a piece they own
- **THEN** legal destination squares are highlighted

#### Scenario: Promotion dialog
- **WHEN** a player drags/taps a pawn to the back rank
- **THEN** a promotion picker dialog appears; selected piece is included in the `make_move` payload as `promotion`

#### Scenario: Check indicator
- **WHEN** the active player's king is in check
- **THEN** the king square is visually highlighted (e.g., red border or overlay)

### Requirement: Offline chess AI screen
`chess_ai_game_screen.dart` SHALL handle offline AI chess with the same AI difficulty selection flow as the existing Caro AI screen.

#### Scenario: Difficulty selection
- **WHEN** user navigates to `/chess_ai_game`
- **THEN** a difficulty picker is shown (Easy/Medium/Hard) before the game starts

#### Scenario: AI move animation
- **WHEN** the AI computes its move
- **THEN** a loading indicator is shown, then the piece animates to the target square

### Requirement: Waiting state for chess online
While waiting for an opponent in a chess room, the board SHALL be shown in initial position and the room code MUST be displayed.

#### Scenario: Chess room waiting
- **WHEN** a user creates a chess room and no opponent has joined
- **THEN** chess board renders starting position, room code shown, waiting banner visible

### Requirement: Navigation consistency
Chess game actions (resign, leave, report) SHALL use the same UI patterns as Caro online games.

#### Scenario: Resign in chess
- **WHEN** the player taps resign and confirms
- **THEN** `resign` WebSocket event sent with `game_type: "chess"`; server broadcasts `game_over`
