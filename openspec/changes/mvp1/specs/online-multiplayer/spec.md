## ADDED Requirements

### Requirement: Room Creation
The system SHALL allow authenticated users to create a game room.

#### Scenario: Create room
- **WHEN** user taps "Create Room"
- **THEN** server creates a new room with a unique 6-character code, adds the creator as Player X, and returns the room code to the client

---

### Requirement: Room Joining
The system SHALL allow a second player to join an existing room by code.

#### Scenario: Successful join
- **WHEN** user enters a valid room code and taps "Join"
- **THEN** server adds the user as Player O, broadcasts `game_state` event to both players, and game begins

#### Scenario: Room not found
- **WHEN** user enters a code that does not correspond to an active room
- **THEN** server returns error; client displays "Room not found"

#### Scenario: Room full
- **WHEN** user attempts to join a room that already has two players
- **THEN** server returns error; client displays "Room is full"

---

### Requirement: Real-time Move Sync
The system SHALL propagate moves to both players in real time via WebSocket.

#### Scenario: Valid move
- **WHEN** the active player sends a `make_move` message with valid coordinates
- **THEN** server validates the move, updates game state, broadcasts `game_state` to all room clients, and advances the turn

#### Scenario: Move on occupied cell
- **WHEN** a player sends a move to an already-occupied cell
- **THEN** server returns an `error` message to that client only; game state is unchanged

#### Scenario: Move out of turn
- **WHEN** a player sends a move when it is not their turn
- **THEN** server returns an `error` message; game state is unchanged

---

### Requirement: End-Game Detection
The system SHALL automatically detect win, draw, and resign conditions.

#### Scenario: Win detection (5 in a row)
- **WHEN** a move creates 5 consecutive same-player marks horizontally, vertically, or diagonally
- **THEN** server broadcasts `game_over` with `winner` set to the winning player's ID

#### Scenario: Draw detection (board full)
- **WHEN** all 225 cells (15×15) are filled with no winner
- **THEN** server broadcasts `game_over` with `winner: null` and `result: "draw"`

#### Scenario: Resign
- **WHEN** a player sends a `resign` message
- **THEN** server broadcasts `game_over` with the opponent as winner

---

### Requirement: Disconnect Recovery
The system SHALL handle player disconnects gracefully with a reconnection grace period.

#### Scenario: Reconnect within grace period
- **WHEN** a player disconnects and reconnects within 30 seconds using the same auth token
- **THEN** server restores the player to the room and broadcasts current `game_state`

#### Scenario: Reconnect timeout
- **WHEN** a disconnected player fails to reconnect within 30 seconds
- **THEN** server broadcasts `game_over` with the remaining player as winner and marks the disconnected player as forfeit

---

### Requirement: Room Expiry
The system SHALL clean up empty rooms after an inactivity period.

#### Scenario: Empty room cleanup
- **WHEN** a room has had zero connected players for 5 minutes
- **THEN** server removes the room from memory and marks any associated game record as abandoned
