## ADDED Requirements

### Requirement: Public Player Profile
The system SHALL provide a public profile page for any player, showing their stats and recent game history.

#### Scenario: View opponent profile
- **WHEN** user taps an opponent's username (on the game result screen or leaderboard)
- **THEN** app navigates to a profile page showing: avatar, username, Elo rating, global rank, wins/losses/draws, win rate %, and last 5 games

#### Scenario: Profile data fetched
- **WHEN** client calls `GET /api/users/:id/profile`
- **THEN** server returns `{ username, avatar, elo_rating, rank, games_played, wins, losses, draws, recent_games: [{id, result, opponent, created_at}] }`

#### Scenario: Profile not found
- **WHEN** client requests a profile for a non-existent user ID
- **THEN** server returns 404; client displays "Player not found"

---

### Requirement: Self Profile Edit
The system SHALL allow the authenticated user to update their avatar URL from the profile/settings screen.

#### Scenario: Update avatar
- **WHEN** user submits a new avatar URL
- **THEN** server validates URL format, updates `users.avatar`, returns 200; client refreshes the profile display
