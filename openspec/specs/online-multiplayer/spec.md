# online-multiplayer Specification

## Purpose
TBD - created by archiving change support-online-human-human-via-gameserver. Update Purpose after archive.
## Requirements
### Requirement: Authenticated WebSocket Access
The system SHALL require an authenticated WebSocket connection before a user can create, join, quick-match, or play an online human-vs-human game.

#### Scenario: Authenticated connection succeeds
- **WHEN** a client connects to the game server WebSocket with a valid JWT for an active user
- **THEN** the server accepts the connection and associates the connection with that user's identity

#### Scenario: Missing or invalid token is rejected
- **WHEN** a client connects to the game server WebSocket without a valid JWT
- **THEN** the server rejects the connection or sends an `error` event and does not allow room actions

#### Scenario: Unverified user cannot play online
- **WHEN** an authenticated but email-unverified user attempts to create, join, or quick-match into an online room
- **THEN** the server sends an `error` event with code `email_not_verified` and the user is not added to a room or queue

---

### Requirement: Room Creation
The system SHALL allow an authenticated verified user to create a server-hosted online room for a human opponent.

#### Scenario: Create room successfully
- **WHEN** a verified user sends a create-room request over the WebSocket
- **THEN** the server creates a room with a unique 6-character room code, assigns the creator as Player X, and sends canonical `game_state` containing the room identifier and room code

#### Scenario: Room code is unique
- **WHEN** the server generates a room code that already maps to an active room
- **THEN** the server generates another code before publishing the room to clients

#### Scenario: Creator waits for opponent
- **WHEN** a room has only Player X connected
- **THEN** the client shows a waiting state and the server does not allow moves until Player O joins

---

### Requirement: Room Joining By Code
The system SHALL allow a second authenticated verified user to join an active room by room code.

#### Scenario: Join room successfully
- **WHEN** a verified second user submits a valid active room code
- **THEN** the server assigns that user as Player O, marks the game started, and broadcasts `game_state` to both players

#### Scenario: Room not found
- **WHEN** a user submits a code that does not map to an active room
- **THEN** the server sends an `error` event with code `room_not_found` and the client displays a join failure message

#### Scenario: Room full
- **WHEN** a third user submits the code for a room that already has Player X and Player O
- **THEN** the server sends an `error` event with code `room_full` and does not add the user to the room

#### Scenario: Existing player rejoins room
- **WHEN** Player X or Player O reconnects and joins the room using the same authenticated user identity
- **THEN** the server restores that player to the existing seat and sends the latest canonical `game_state`

---

### Requirement: Quick Match Pairing
The system SHALL optionally allow authenticated verified users to be paired automatically without exchanging a room code.

#### Scenario: First quick-match user waits
- **WHEN** a verified user sends `quick_match_request` and no other user is waiting
- **THEN** the server queues that user and sends a waiting event or waiting state to that client

#### Scenario: Second quick-match user is paired
- **WHEN** a verified user sends `quick_match_request` while another eligible user is waiting
- **THEN** the server removes both users from the queue, creates a room, assigns Player X and Player O, sends `quick_match_found` to both clients, and broadcasts the initial `game_state`

#### Scenario: Quick-match wait times out
- **WHEN** a user remains unmatched for 60 seconds
- **THEN** the server removes that user from the queue and sends `quick_match_timeout`

#### Scenario: Quick-match cancel removes user
- **WHEN** a queued user sends `quick_match_cancel` or disconnects before pairing
- **THEN** the server removes that user from the queue and does not match them later

#### Scenario: User cannot match self
- **WHEN** a user already in the quick-match queue sends another quick-match request from the same identity
- **THEN** the server does not pair the user with themselves or create a duplicate queue entry

---

### Requirement: Server-Authoritative Move Validation
The system SHALL validate every online move on the server before updating or broadcasting game state.

#### Scenario: Valid move updates both players
- **WHEN** the current player sends `make_move` with empty board coordinates inside the 15×15 board
- **THEN** the server records the mark, advances the turn, and broadcasts canonical `game_state` to both players

#### Scenario: Move out of turn is rejected
- **WHEN** a player sends `make_move` while it is not their turn
- **THEN** the server sends an `error` event with code `not_your_turn` to that player and leaves game state unchanged

#### Scenario: Occupied cell is rejected
- **WHEN** a player sends `make_move` for a cell that already contains a mark
- **THEN** the server sends an `error` event with code `cell_occupied` to that player and leaves game state unchanged

#### Scenario: Out-of-bounds move is rejected
- **WHEN** a player sends `make_move` with coordinates outside the board
- **THEN** the server sends an `error` event with code `invalid_coordinates` to that player and leaves game state unchanged

#### Scenario: Post-game move is rejected
- **WHEN** any player sends `make_move` after the room is already in a game-over state
- **THEN** the server sends an `error` event with code `game_already_over` and leaves final game state unchanged

---

### Requirement: Game Completion
The system SHALL detect and broadcast online game completion for win, draw, resign, and forfeit outcomes.

#### Scenario: Five-in-a-row win
- **WHEN** a valid move creates five consecutive marks for one player horizontally, vertically, or diagonally
- **THEN** the server marks the game over and broadcasts `game_over` with the winner, final board, result, and winning cells when available

#### Scenario: Board draw
- **WHEN** all 225 cells are filled without a winner
- **THEN** the server marks the game over and broadcasts `game_over` with draw result and no winner

#### Scenario: Player resigns
- **WHEN** a player sends `resign` during an active online game
- **THEN** the server marks the opponent as winner and broadcasts `game_over` with result `resign`

#### Scenario: Completed game is persisted
- **WHEN** an online game reaches a terminal win, draw, resign, or forfeit state
- **THEN** the server persists the completed game record so history, stats, and leaderboard behavior can reflect the match

---

### Requirement: Disconnect Recovery And Forfeit
The system SHALL provide a bounded reconnect window for players who disconnect during an active online game.

#### Scenario: Reconnect within grace period
- **WHEN** a disconnected player reconnects with the same authenticated user identity within 30 seconds
- **THEN** the server restores the player to their original seat, cancels the disconnect timer, and sends the latest `game_state`

#### Scenario: Reconnect grace period expires
- **WHEN** a disconnected player does not reconnect within 30 seconds
- **THEN** the server marks the game over with result `forfeit`, assigns the connected opponent as winner, persists the game, and broadcasts `game_over`

#### Scenario: Disconnect before game starts
- **WHEN** a waiting room creator disconnects before a second player joins
- **THEN** the server eventually cleans up the room without creating a completed game record

---

### Requirement: Room Cleanup
The system SHALL clean up abandoned online rooms so stale room codes cannot be reused indefinitely.

#### Scenario: Empty stale room is removed
- **WHEN** a room has no connected players and has been inactive for at least 5 minutes
- **THEN** the server removes the room and room-code mapping from active memory

#### Scenario: Removed room cannot be joined
- **WHEN** a user submits the code for a cleaned-up room
- **THEN** the server sends an `error` event with code `room_not_found`

---

### Requirement: Client Online Game Experience
The system SHALL provide a Flutter client flow that lets two humans start, play, and finish an online game through the game server.

#### Scenario: Create-room flow reaches waiting state
- **WHEN** a user chooses Create Room in the client and the server returns a room code
- **THEN** the client displays the room code and a waiting-for-opponent state until another player joins

#### Scenario: Join-room flow enters active game
- **WHEN** a user enters a valid room code and receives `game_state` with both players present
- **THEN** the client navigates to or updates the game screen with the server board, player assignments, and current turn

#### Scenario: Client applies server game state
- **WHEN** the client receives `game_state`
- **THEN** it treats that payload as canonical and updates board, current turn, player identities, room code, and game-over flags accordingly

#### Scenario: Client shows game-over outcome
- **WHEN** the client receives `game_over`
- **THEN** it displays the final board and a clear win, loss, draw, resign, or forfeit outcome for the local user

#### Scenario: Client displays actionable errors
- **WHEN** the client receives an online-play `error` event
- **THEN** it displays a user-facing message appropriate to the error code without mutating local game state as if the action succeeded

---

### Requirement: End-To-End Online Smoke Validation
The system SHALL be verifiable with a two-human-client smoke path against a running game server.

#### Scenario: Two clients complete a game by room code
- **WHEN** two verified users connect to the server, one creates a room, the other joins by code, and they play legal moves until a win or draw
- **THEN** both clients receive matching final `game_over` state and the server records the completed match

#### Scenario: Two clients complete quick match when enabled
- **WHEN** two verified users request quick match and then play legal moves until a win or draw
- **THEN** both clients receive `quick_match_found`, matching game-state updates, matching final `game_over` state, and a completed server record

### Requirement: Polymorphic make_move payload
The `make_move` WebSocket event payload MUST be extended to support chess moves (`from`, `to`, `promotion`) alongside existing Caro moves (`x`, `y`). The server SHALL route move handling based on `room.GameType`.

#### Scenario: Caro make_move unchanged
- **WHEN** a Caro room receives `make_move` with `{x: 7, y: 7}`
- **THEN** behavior is identical to before this change — `from/to/promotion` fields are ignored

#### Scenario: Chess make_move with from/to
- **WHEN** a chess room receives `make_move` with `{from: "e2", to: "e4"}`
- **THEN** server dispatches to chess engine; `x/y` fields are ignored

#### Scenario: Missing required chess move fields
- **WHEN** a chess room receives `make_move` without `from` or `to`
- **THEN** server returns `error` with code `invalid_payload` to the sender

