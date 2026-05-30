## Why

XCaro is a Gomoku (Caro) game built with Flutter and Go. The current codebase has the skeleton in place — Flutter client, Go server, WebSocket infrastructure — but key features needed for a releasable MVP are incomplete or missing: user authentication is unfinished, the online multiplayer game loop is not fully wired end-to-end, and the AI opponent lacks playable difficulty levels. MVP1 closes these gaps so we have a shippable product players can actually use.

## What Changes

- **Complete user authentication flow**: finalize login/register screens, JWT access + refresh token lifecycle, and persistent session storage on the client
- **End-to-end online multiplayer**: room creation/joining, real-time game state sync over WebSocket, win/draw/resign detection, and graceful disconnect handling
- **AI opponent (single difficulty)**: implement a playable AI using a heuristic minimax (or threat-space search) algorithm — enough to make solo play fun
- **Game history persistence**: store completed games in MongoDB; allow users to view their win/loss record on the home screen
- **Polished core UI**: finalize the Home, Game, and Result screens; add move animations and the existing sound effects; add dark/light theme toggle

## Capabilities

### New Capabilities

- `user-auth`: Account registration, login, JWT access+refresh token flow, and persistent session — covers both client screens and server auth API
- `online-multiplayer`: Room lifecycle (create, join, spectate), real-time move sync via WebSocket, turn enforcement, end-game detection (win/draw/timeout/resign), and disconnect recovery
- `ai-opponent`: Single-player vs computer mode using heuristic AI; single difficulty level sufficient for MVP
- `game-history`: Server-side storage of completed game records; client-side stats display (wins, losses, draws)
- `core-ui-polish`: Move animations, sound effect integration, dark/light theme, and responsive layout on mobile

### Modified Capabilities

<!-- None — no existing specs to modify -->

## Impact

- **Client**: `providers/auth_provider.dart`, `screens/login.dart`, `screens/home.dart`, `screens/game.dart`, `services/api_service.dart`, `services/websocket_service.dart`, `game_board.dart`, `audio_manager.dart`
- **Server**: `internal/auth/` (refresh token endpoint), `internal/game/` (game CRUD + history), `internal/ws/` (room management, disconnect handling)
- **Database (MongoDB)**: new `games` collection for history; `users` collection refresh token field
- **Dependencies**: no new major dependencies anticipated; Flame engine already in pubspec
