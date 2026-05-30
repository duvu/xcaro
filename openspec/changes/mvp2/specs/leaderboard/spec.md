## ADDED Requirements

### Requirement: Elo Rating Calculation
The system SHALL compute and persist Elo rating changes for both players at the end of every online game (win/loss/draw). AI games and forfeits SHALL NOT affect Elo.

#### Scenario: Win/loss rating update
- **WHEN** an online game ends with a winner
- **THEN** server computes Elo delta (K=32) for both players, updates `users.elo_rating`, and stores `elo_delta_x` and `elo_delta_o` in the game record

#### Scenario: Draw rating update
- **WHEN** an online game ends in a draw
- **THEN** server applies Elo draw formula (both players expected score approaches 0.5), updates ratings accordingly

#### Scenario: Forfeit/AI games excluded
- **WHEN** a game ends due to disconnect forfeit, or the game is an AI game
- **THEN** server does NOT update Elo ratings

---

### Requirement: Global Leaderboard
The system SHALL provide a ranked list of the top 50 players by Elo rating.

#### Scenario: Fetch leaderboard
- **WHEN** client calls `GET /api/leaderboard?limit=50`
- **THEN** server returns an array of players sorted descending by `elo_rating`, each with `rank`, `username`, `avatar`, `elo_rating`, `games_played`

#### Scenario: Leaderboard cached
- **WHEN** leaderboard is fetched within 5 minutes of the previous fetch
- **THEN** server returns the cached result from Redis without querying MongoDB

#### Scenario: Cache invalidated on game end
- **WHEN** an online game ends and Elo ratings change
- **THEN** server invalidates the leaderboard Redis cache key so the next fetch reflects updated ratings

---

### Requirement: Personal Rank Display
The client SHALL display the authenticated user's current Elo rating and global rank on the Home screen.

#### Scenario: Rank shown on Home screen
- **WHEN** user opens the Home screen and is authenticated
- **THEN** their current Elo rating and approximate global rank (e.g., "#42 — 1350 Elo") are displayed in the stats widget

#### Scenario: Rank updated after game
- **WHEN** user returns to the Home screen after completing a rated online game
- **THEN** the Elo rating and rank reflect the post-game values
