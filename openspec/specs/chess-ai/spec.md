# chess-ai Specification

## Purpose
TBD - created by archiving change implement-game-chess. Update Purpose after archive.
## Requirements
### Requirement: Chess AI difficulty levels
The system SHALL provide client-side chess AI at three difficulty levels (Easy, Medium, Hard) using minimax with alpha-beta pruning. The AI MUST run in a Dart isolate to prevent UI blocking.

#### Scenario: Easy AI makes a legal move quickly
- **WHEN** the AI is at Easy difficulty
- **THEN** it uses search depth 1, returns a legal move within 200ms

#### Scenario: Hard AI is stronger than Easy
- **WHEN** tested over 10 games Easy vs Hard
- **THEN** Hard wins at least 8 games (statistical strength validation in tests is optional; enforce only that moves are legal and within time)

#### Scenario: AI respects time budget
- **WHEN** Hard AI searches
- **THEN** it returns a move within 900ms regardless of position complexity (enforced by deadline in isolate)

### Requirement: Offline chess game flow
Players SHALL be able to start an offline chess game against AI from the home screen without network connectivity.

#### Scenario: Start offline chess
- **WHEN** user selects Chess from catalog, taps AI button, selects difficulty
- **THEN** chess board renders starting position, AI plays as Black on its turn

#### Scenario: Player move in offline game
- **WHEN** the player taps a piece and a valid destination square
- **THEN** move is validated client-side, board updates, AI calculates and plays response

#### Scenario: Checkmate in offline game
- **WHEN** the game reaches checkmate
- **THEN** game-over dialog shown with win/loss/draw result; offer rematch or exit

### Requirement: Chess AI uses standard material evaluation
The chess AI MUST evaluate positions using piece values and basic positional heuristics.

#### Scenario: Material counting
- **WHEN** AI evaluates a position
- **THEN** uses piece values: pawn=100, knight=320, bishop=330, rook=500, queen=900, king=20000

