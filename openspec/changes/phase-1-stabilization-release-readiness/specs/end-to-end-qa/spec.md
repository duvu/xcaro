## ADDED Requirements

### Requirement: Manual QA matrix
The project SHALL define a manual end-to-end QA matrix for critical MVP user flows.

#### Scenario: QA matrix covers critical flows
- **WHEN** the QA matrix is reviewed
- **THEN** it includes auth, email verification, token refresh, logout, online room creation, room joining, move sync, resign, disconnect handling, chat, leaderboard, game history, AI difficulty, onboarding, and app restart/session restore

### Requirement: Auth flow QA
The QA matrix SHALL verify user account flows from registration through logout.

#### Scenario: Registration and verification flow
- **WHEN** a tester registers a new account
- **THEN** the app shows a verification prompt, the server creates an unverified user, resend verification is available, and online room access is blocked until verification succeeds

#### Scenario: Token refresh and logout flow
- **WHEN** a tester restarts the app with a stored refresh token
- **THEN** the app restores the session or returns to login on invalid refresh, and logout clears local session state

### Requirement: Online gameplay QA
The QA matrix SHALL verify online room lifecycle and real-time gameplay between two users.

#### Scenario: Full online game completes
- **WHEN** two verified users create/join a room and play until win or draw
- **THEN** both clients receive synchronized game state, correct turn state, final result dialog, game record persistence, and leaderboard/stat updates for rated non-forfeit games

#### Scenario: Resign and disconnect behavior
- **WHEN** a player resigns or disconnects long enough to trigger forfeit behavior
- **THEN** both clients receive a game-over event with the correct reason and the room is cleaned up according to server rules

### Requirement: Chat QA
The QA matrix SHALL verify in-game chat validation and delivery.

#### Scenario: Chat messages deliver
- **WHEN** a player sends a non-empty chat message within the size limit
- **THEN** all clients in the room receive the message with sender and timestamp

#### Scenario: Invalid chat is rejected
- **WHEN** a player sends an empty or over-limit message
- **THEN** the server rejects it without broadcasting invalid content

### Requirement: AI gameplay QA
The QA matrix SHALL verify all AI difficulty modes on a real device or emulator.

#### Scenario: AI difficulties are playable
- **WHEN** a tester starts Easy, Medium, and Hard AI games
- **THEN** each mode produces valid moves, keeps the UI responsive, and reaches a valid win/draw/end state

### Requirement: Content and navigation QA
The QA matrix SHALL verify non-gameplay screens that are part of the MVP release.

#### Scenario: Supporting screens load
- **WHEN** a tester opens onboarding, home stats, leaderboard, opponent profile, history, settings/how-to-play, and theme/sound controls
- **THEN** each screen loads without crash and shows either valid data or a clear empty/error state
