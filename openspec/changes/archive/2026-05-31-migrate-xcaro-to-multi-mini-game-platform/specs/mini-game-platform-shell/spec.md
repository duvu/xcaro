## ADDED Requirements

### Requirement: Shared app shell SHALL host multiple mini-games
The system SHALL provide one authenticated Flutter shell that can host multiple mini-games while preserving shared Home, History, Leaderboard, Friends, and Profile surfaces.

#### Scenario: Home evolves into game hub
- **WHEN** an authenticated player opens the app home experience
- **THEN** the system SHALL present a game catalog or game hub that can launch the current Caro experience and future mini-games from the same shell

#### Scenario: Shared tabs remain platform-owned
- **WHEN** a player navigates to History, Leaderboard, Friends, or Profile
- **THEN** those surfaces SHALL remain part of the shared app shell rather than being copied into each game module

### Requirement: Client game modules SHALL be isolated behind a platform registry
The client SHALL isolate game-specific screens, providers, and rendering logic behind a game registry or equivalent routing contract keyed by `game_type`.

#### Scenario: Existing Caro module registers as first game
- **WHEN** the platform initializes its game registry
- **THEN** the current Caro implementation SHALL be registered as the `caro` game module without requiring a separate app

#### Scenario: New mini-game adds without changing shell contract
- **WHEN** a second mini-game is added
- **THEN** it SHALL be introduced through the same registry contract and shared shell without replacing auth, social, history, or leaderboard infrastructure

### Requirement: Shared shell SHALL support game-aware views
Shared shell surfaces SHALL support game-aware filtering or scoping where history, leaderboard, or dashboard data differs by game.

#### Scenario: History is scoped by game type
- **WHEN** a player views history from the shared shell
- **THEN** the system SHALL support filtering or grouping records by `game_type`

#### Scenario: Leaderboard is scoped by game type
- **WHEN** a player views leaderboard data for a specific game
- **THEN** the system SHALL return rankings that correspond to that `game_type` rather than mixing all games into one default leaderboard
