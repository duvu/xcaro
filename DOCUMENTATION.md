# PlayVerse Technical Documentation

PlayVerse is a cross-platform Gomoku (Caro) application featuring real-time multiplayer capabilities, WebRTC-powered voice/video communication, and a high-performance backend. This document serves as the primary technical reference for developers, contributors, and maintainers.

## Project Overview

PlayVerse combines a modern Flutter frontend with a robust Go backend to deliver a seamless gaming experience. It supports multiple game modes, including local PvP and player vs. computer (AI) matches, while providing a foundation for global online play.

### Core Architecture

```text
       +---------------------------------------+
       |            Client (Flutter)           |
       |  (Flame Engine, Provider, WebSocket)  |
       +-------------------+-------------------+
                           |
           HTTP/JSON       |       WebSocket/WebRTC
      (Auth, Game CRUD)    |    (Game State, Signaling)
                           |
       +-------------------+-------------------+
       |            Server (Go)                |
       |     (Gin, Gorilla WS, MongoDB)        |
       +-------------------+-------------------+
                           |
               +-----------+-----------+
               |        Database       |
               |       (MongoDB)       |
               +-----------------------+
```

### Tech Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Frontend** | Flutter / Dart | Cross-platform UI framework |
| **Game Engine** | Flame | 2D game engine for Flutter |
| **State Management** | Provider | Reactive state management |
| **Backend** | Go (Golang) | High-performance server-side language |
| **Web Framework** | Gin | Lightweight HTTP web framework |
| **Database** | MongoDB | Document-oriented NoSQL database |
| **Real-time** | WebSocket | Bi-directional communication |
| **Multimedia** | WebRTC | Peer-to-peer audio/video signaling |
| **Authentication** | JWT | JSON Web Tokens for secure access |
| **Containerization** | Docker | Environment consistency and deployment |

---

## Client Architecture (Flutter)

The client is built using Flutter, ensuring a unified codebase for Android, iOS, Web, and Desktop. It leverages the Flame engine for game board rendering and confetti effects.

### Directory Structure

```text
client/lib/
├── main.dart                 # App entry, MultiProvider setup, routing
├── game_board.dart           # Core game logic (ChangeNotifier)
├── audio_manager.dart        # Sound effect management
├── game/
│   └── caro_game.dart        # Flame game engine integration
├── models/                   # Data structures (User, Game, ChatMessage)
├── providers/                # Business logic (Auth, Game, Offline)
├── screens/                  # UI Screens (Login, Home, Game)
├── services/                 # Infrastructure (API, WS, Storage)
├── config/                   # Environment and app configuration
└── widgets/                  # Reusable UI components
```

### Key Modules

*   **Flame Game Integration**: `caro_game.dart` manages the rendering lifecycle of the game board, ensuring smooth performance across devices.
*   **State Management**: `Provider` handles authentication states and real-time game updates, decoupling UI from business logic.
*   **Service Layer**: `websocket_service.dart` maintains a persistent connection to the server, handling event dispatching and automatic reconnection logic.

---

## Server Architecture (Go)

The backend is designed for high concurrency using Go's goroutines. It follows a clean architecture pattern to separate transport, business logic, and data access.

### Directory Structure

```text
server/
├── cmd/server/main.go        # Application entry point
├── internal/
│   ├── auth/                 # JWT, Middleware, Login/Register handlers
│   ├── game/                 # Game CRUD and session management
│   └── ws/                   # WebSocket hub, room logic, and events
├── pkg/models/               # Shared domain models
├── Dockerfile                # Server container definition
└── docker-compose.yml        # Multi-container orchestration
```

### Key Components

*   **WebSocket Hub**: `hub.go` manages active rooms and broadcasts messages to connected clients.
*   **Auth Middleware**: Validates JWTs for both REST endpoints and WebSocket upgrades.
*   **MongoDB Driver**: Utilizes connection pooling to handle database operations efficiently.

---

## API Reference

### REST Endpoints

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| POST | `/api/auth/register` | Create a new user account | No |
| POST | `/api/auth/login` | Authenticate and get JWT | No |
| POST | `/api/games` | Initialize a new game session | Yes |
| GET | `/api/games/:id` | Fetch current game state | Yes |
| POST | `/api/games/:id/join` | Join an existing game room | Yes |
| POST | `/api/games/:id/move` | Submit a move (row, col) | Yes |
| GET | `/api/health` | Check system and DB status | No |

### WebSocket Protocol

**Endpoint**: `ws://<host>:<port>/api/ws?token=<JWT>`

Messages use a JSON format:
```json
{
  "type": "event_name",
  "room_id": "optional_id",
  "payload": { ... }
}
```

**Common Event Types**:
*   `game_state`: Syncs the full board and player stats.
*   `game_move`: Broadcasts a new move to all participants.
*   `chat_message`: Handles in-game communication.
*   `offer`/`answer`/`ice-candidate`: WebRTC signaling for voice/video.

---

## Data Models

### User
```json
{
  "id": "string",
  "username": "string",
  "created_at": "timestamp"
}
```

### Game State
```json
{
  "id": "string",
  "players": ["player_id_1", "player_id_2"],
  "board": [[...]],
  "current_turn": "player_id",
  "status": "active|finished",
  "winner": "player_id|null"
}
```

---

## Security Model

1.  **Authentication**: All sensitive operations require a valid JWT passed via the `Authorization` header or WebSocket query parameter.
2.  **Password Safety**: User passwords are encrypted using `bcrypt` before storage.
3.  **Communication**: WebRTC traffic is peer-to-peer and utilizes E2E encryption.
4.  **Backend Hardening**: WebSocket connections implement a 60s inactivity timeout with mandatory ping/pong keepalives. Message size is capped at 512KB.

---

## Setup & Development

### Prerequisites
*   Flutter SDK ≥ 3.0
*   Go 1.23
*   MongoDB (local instance or Atlas)

### Local Setup

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-repo/playverse.git
    cd playverse
    ```

2.  **Server Setup**:
    *   Create a `.env` file from `.env.example`.
    *   Run `cd server && go run cmd/server/main.go`.

3.  **Client Setup**:
    *   Run `cd client && flutter pub get`.
    *   Start the app: `flutter run`.

### Docker Deployment
```bash
docker-compose up --build
```

---

## Roadmap

### High Priority
*   Implement rate limiting for API and WebSocket.
*   Add automated unit and integration tests.
*   Generate Swagger/OpenAPI documentation.

### Medium Priority
*   Persistent chat history in MongoDB.
*   Global leaderboard and player profiles.
*   Undo/redo move functionality.

### Low Priority
*   TURN server for WebRTC reliability.
*   Spectator mode for ongoing games.
*   CI/CD pipelines using GitHub Actions.

---

## Contributing

We welcome contributions! Please follow these steps:
1.  Fork the repository.
2.  Create a feature branch.
3.  Ensure your code passes all linting and tests.
4.  Submit a Pull Request with a clear description of changes.

## License

This project is licensed under the MIT License.
