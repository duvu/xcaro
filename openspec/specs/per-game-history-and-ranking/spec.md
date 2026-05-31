# per-game-history-and-ranking Specification

## Purpose
TBD - created by archiving change migrate-xcaro-to-multi-mini-game-platform. Update Purpose after archive.
## Requirements
### Requirement: Completed game records SHALL be game-aware
The system SHALL store completed game records with a `game_type` and enough structured metadata to support per-game history, results, and future mini-game expansion.

#### Scenario: Existing Caro records migrate safely
- **WHEN** the platform migrates old completed Caro records
- **THEN** those records SHALL be recognized as `game_type = caro` without losing existing result or rating information

#### Scenario: New game records remain queryable
- **WHEN** a new mini-game persists a completed match
- **THEN** the resulting record SHALL include the game identity and core participant/result metadata needed for history and leaderboard queries

### Requirement: History and dashboard SHALL support per-game queries
The system SHALL support dashboard and history responses that can scope results, summaries, and recent activity by `game_type`.

#### Scenario: Dashboard summary can scope current game
- **WHEN** a player requests dashboard summary data for a specific `game_type`
- **THEN** the system SHALL return stats and recent activity that correspond to that game scope

#### Scenario: History filters by game and outcome
- **WHEN** a player filters their history by `game_type`, result, opponent, or date range
- **THEN** the system SHALL return only records matching the requested filters and ownership rules

### Requirement: Rankings SHALL evolve to per-game semantics
The system SHALL support per-game ranking and rating behavior so one mini-game does not overwrite or misrepresent another game’s progression.

#### Scenario: Caro leaderboard stays compatible during transition
- **WHEN** an existing Caro client requests current leaderboard behavior
- **THEN** the system SHALL continue to return a Caro-compatible ranking view during the migration period

#### Scenario: New game ranking is isolated
- **WHEN** a new mini-game introduces rating or leaderboard behavior
- **THEN** that ranking data SHALL be stored and queried independently from Caro’s ranking data unless an explicit cross-game leaderboard is defined

