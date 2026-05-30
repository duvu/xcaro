## ADDED Requirements

### Requirement: Game Record Persistence
The system SHALL persist a record of every completed online game to MongoDB.

#### Scenario: Game saved on completion
- **WHEN** a game ends (win, draw, resign, or forfeit)
- **THEN** server writes a `GameRecord` document containing `{ id, playerX, playerO, winner, result, moves, duration, createdAt }` to the `games` collection

#### Scenario: Abandoned game not saved
- **WHEN** a room expires before the game starts
- **THEN** no game record is written

---

### Requirement: User Stats Display
The system SHALL display aggregate win/loss/draw statistics for the logged-in user on the Home screen.

#### Scenario: Stats loaded on home screen
- **WHEN** the Home screen mounts and the user is authenticated
- **THEN** client calls `GET /api/games/stats` and displays the user's total wins, losses, and draws

#### Scenario: No games played
- **WHEN** the user has no completed games
- **THEN** Home screen displays "No games yet. Play your first game!"

---

### Requirement: Game History List
The system SHALL allow users to browse a paginated list of their past games.

#### Scenario: View history
- **WHEN** user navigates to the History screen
- **THEN** client fetches `GET /api/games?userId=&page=1&limit=20` and displays a list of past games with date, opponent, and result

#### Scenario: Load more
- **WHEN** user scrolls to the bottom of the history list
- **THEN** client fetches the next page and appends results to the list
