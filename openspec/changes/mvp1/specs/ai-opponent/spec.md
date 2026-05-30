## ADDED Requirements

### Requirement: AI Game Mode
The system SHALL offer a single-player mode where the user plays against a computer opponent.

#### Scenario: Start AI game
- **WHEN** user selects "Play vs Computer" from the Home screen
- **THEN** client initialises a local game session with the user as Player X and the AI as Player O (no server connection required)

---

### Requirement: AI Move Computation
The system SHALL compute AI moves using a heuristic minimax algorithm with alpha-beta pruning, run in a background Dart Isolate.

#### Scenario: AI computes move
- **WHEN** it is the AI's turn
- **THEN** the AI computes its move within 500ms and places it on the board without blocking the UI thread

#### Scenario: AI move on full board
- **WHEN** the board is full (draw condition)
- **THEN** AI does not attempt to make a move; game ends in draw

---

### Requirement: AI Board Evaluation
The system SHALL evaluate board positions using a pattern-score table covering five-in-a-row threats.

#### Scenario: Blocking opponent win
- **WHEN** the opponent has four in a row with an open end
- **THEN** AI places its move to block the five-in-a-row within the current search depth

#### Scenario: Taking winning move
- **WHEN** AI itself has four in a row with an open end
- **THEN** AI places the winning move, ending the game

---

### Requirement: AI Search Depth
The system SHALL use a fixed search depth of 3 for MVP.

#### Scenario: Depth limit respected
- **WHEN** the AI is computing a move
- **THEN** minimax search does not exceed depth 3; move is returned within 500ms on mid-range mobile hardware
