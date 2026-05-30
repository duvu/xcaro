## MODIFIED Requirements

### Requirement: AI Game Mode
The system SHALL offer a single-player mode where the user plays against a computer opponent at a selected difficulty level.

#### Scenario: Select difficulty before game
- **WHEN** user taps "Play vs Computer" from the Home screen
- **THEN** a difficulty picker is shown with three options: Easy, Medium, Hard

#### Scenario: Start AI game at chosen difficulty
- **WHEN** user selects a difficulty and taps "Start"
- **THEN** client initialises a local game session with the selected difficulty passed to `AiEngine`

---

## MODIFIED Requirements

### Requirement: AI Move Computation
The system SHALL compute AI moves at configurable depth based on the selected difficulty, run in a background Dart Isolate.

#### Scenario: Easy AI move (depth 1)
- **WHEN** it is the AI's turn and difficulty is Easy
- **THEN** AI evaluates only depth-1 moves from a random subset of 10 candidate cells and plays within 200ms

#### Scenario: Medium AI move (depth 3)
- **WHEN** it is the AI's turn and difficulty is Medium
- **THEN** AI uses minimax depth-3 with alpha-beta pruning, top 20 proximity candidates, completes within 500ms

#### Scenario: Hard AI move (depth 5)
- **WHEN** it is the AI's turn and difficulty is Hard
- **THEN** AI uses minimax depth-5 with threat-space candidate prioritisation; completes within 1s; if 1s timeout is reached, returns the best move found so far

#### Scenario: AI move on full board
- **WHEN** the board is full (draw condition)
- **THEN** AI does not attempt to make a move; game ends in draw
