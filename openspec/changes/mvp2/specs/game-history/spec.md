## MODIFIED Requirements

### Requirement: Game Record Persistence
The system SHALL persist a record of every completed online game to MongoDB, now including Elo delta for both players.

#### Scenario: Rated game saved with Elo delta
- **WHEN** an online game ends with a winner or draw (not forfeit)
- **THEN** server writes a `GameRecord` document containing `{ id, playerX, playerO, winner, result, moves, duration, createdAt, elo_delta_x, elo_delta_o }`

#### Scenario: Forfeited game saved without Elo delta
- **WHEN** a game ends due to disconnect forfeit
- **THEN** server writes the game record with `elo_delta_x: 0, elo_delta_o: 0` — no rating change

---

### Requirement: User Stats Display
The system SHALL display Elo rating in addition to aggregate win/loss/draw statistics for the logged-in user on the Home screen.

#### Scenario: Stats with Elo shown on Home screen
- **WHEN** the Home screen mounts and the user is authenticated
- **THEN** client displays total wins, losses, draws, and current Elo rating

#### Scenario: Stats endpoint returns Elo
- **WHEN** client calls `GET /api/games/stats?userId=`
- **THEN** response includes `{ wins, losses, draws, elo_rating, rank }`
