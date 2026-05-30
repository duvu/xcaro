## 1. Server — Authentication

- [x] 1.1 Add `refreshToken` and `refreshTokenExpiresAt` fields to the `User` model in `pkg/models/`
- [x] 1.2 Implement `POST /api/auth/register` — validate input, hash password, create user, return access + refresh tokens
- [x] 1.3 Implement `POST /api/auth/login` — verify credentials, issue access + refresh tokens, store refresh token in DB
- [x] 1.4 Implement `POST /api/auth/refresh` — validate refresh token, rotate it, return new access token
- [x] 1.5 Implement `POST /api/auth/logout` — invalidate refresh token in MongoDB
- [x] 1.6 Add JWT middleware to protect game and WebSocket endpoints

## 2. Client — Authentication

- [x] 2.1 Add `flutter_secure_storage` dependency to `pubspec.yaml`
- [x] 2.2 Implement `AuthProvider`: load refresh token on startup, auto-refresh access token, expose `isAuthenticated` state
- [x] 2.3 Wire Login screen to `POST /api/auth/login`; store refresh token in secure storage on success
- [x] 2.4 Wire Register screen to `POST /api/auth/register`; handle field-level validation errors
- [x] 2.5 Implement startup routing: if valid refresh token → refresh → Home; else → Login
- [x] 2.6 Implement Logout: clear storage, call `/api/auth/logout`, navigate to Login

## 3. Server — Online Multiplayer

- [x] 3.1 Define WebSocket message envelope `{ "type": string, "payload": object }` and all message type constants
- [x] 3.2 Implement Room struct with player slots, game state (15×15 board), and turn tracker
- [x] 3.3 Implement `join_room` handler — create or join room by code; broadcast `game_state` when both players connected
- [x] 3.4 Implement `make_move` handler — validate turn, validate cell empty, update board, broadcast `game_state`
- [x] 3.5 Implement win detection (5-in-a-row check) and draw detection (board full) after each move
- [x] 3.6 Implement `resign` handler — broadcast `game_over` with opponent as winner
- [x] 3.7 Implement disconnect grace period (30s timer); forfeit game on timeout
- [x] 3.8 Implement room expiry: garbage-collect rooms empty for 5 minutes

## 4. Client — Online Multiplayer

- [x] 4.1 Build Create Room screen: tap "Create" → call API, display room code, wait for opponent WebSocket event
- [x] 4.2 Build Join Room screen: enter code, validate, connect WebSocket, receive initial `game_state`
- [x] 4.3 Wire `GameProvider` to WebSocket: handle `game_state` and `game_over` events, update board state
- [x] 4.4 Enforce turn UI: disable board taps when it is not the current player's turn
- [x] 4.5 Show end-game dialog (win / lose / draw / forfeit) on `game_over` event with rematch/home options
- [x] 4.6 Implement reconnect logic in `websocket_service.dart`: on disconnect, attempt reconnect with back-off for 30s

## 5. Client — AI Opponent

- [x] 5.1 Implement board evaluation function with pattern-score table (five, open-four, closed-four, open-three, etc.)
- [x] 5.2 Implement minimax with alpha-beta pruning at depth 3 in a Dart class `AiEngine`
- [x] 5.3 Run `AiEngine.bestMove(board)` in a Dart `Isolate`; receive result via `ReceivePort`
- [x] 5.4 Add "Play vs Computer" option on Home screen; initialise local game session without server
- [x] 5.5 Trigger AI move automatically after user's move with a brief visual delay (300ms) for UX

## 6. Server — Game History

- [x] 6.1 Define `GameRecord` struct/model with fields: `id, playerX, playerO, winner, result, moves, duration, createdAt`
- [x] 6.2 Write game record to `games` MongoDB collection on all game-end paths (win/draw/resign/forfeit)
- [x] 6.3 Implement `GET /api/games?userId=&page=&limit=` — paginated game history for a user
- [x] 6.4 Implement `GET /api/games/stats?userId=` — return aggregate wins, losses, draws

## 7. Client — Game History

- [x] 7.1 Call `GET /api/games/stats` on Home screen mount; display wins/losses/draws summary widget
- [x] 7.2 Build History screen with paginated list of past games (date, opponent, result)
- [x] 7.3 Implement infinite scroll / "load more" on History screen

## 8. Client — Core UI Polish

- [x] 8.1 Add scale-in animation (≤150ms) for stone placement using Flutter `AnimatedWidget` or `AnimationController`
- [x] 8.2 Wire existing sound assets to `AudioManager`: play move sound on each stone placed, win sound on game end
- [x] 8.3 Add sound toggle setting; persist preference with `shared_preferences`
- [x] 8.4 Implement `ThemeProvider` with dark/light `ThemeData`; persist selection with `shared_preferences`
- [x] 8.5 Add theme toggle to Settings screen; verify full app re-render on switch
- [x] 8.6 Verify game board renders correctly at 360dp width; adjust cell sizes if needed (min 20×20dp tap targets)

## 9. Testing & Integration

- [x] 9.1 Write unit tests for `AiEngine` evaluation function and minimax (verify blocking and winning moves)
- [x] 9.2 Write unit tests for server win/draw detection logic
- [x] 9.3 Integration test: register → login → create room → join room → play to completion → check game record saved
- [x] 9.4 Integration test: disconnect during game → reconnect within 30s → game resumes
- [x] 9.5 Manual smoke test on Android and iOS: auth flow, online game, AI game, history screen
