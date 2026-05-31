# Contributing to PlayVerse

Thanks for helping improve PlayVerse. This guide covers the local workflow, project
layout, and quality checks expected before opening a pull request.

## Prerequisites

- Go 1.23+
- Flutter 3.x with Android Studio or Xcode for device builds
- Docker and Docker Compose for MongoDB + Redis
- Platform audio dependencies required by `just_audio` when running on desktop
  targets

## Local Setup

1. Clone the repository and enter the project directory.
2. Copy the server environment template:

   ```bash
   cp server/.env.example server/.env
   ```

3. Start MongoDB and Redis from the server compose file:

   ```bash
   docker compose -f server/docker-compose.yml up -d mongodb redis
   ```

4. Start the Go API server:

   ```bash
   cd server
   go mod download
   go run ./cmd/server
   ```

5. In another terminal, start the Flutter app:

   ```bash
   cd client
   flutter pub get
   flutter run
   ```

## Project Structure

- `server/cmd/server/` — Go server entrypoint and route wiring
- `server/internal/auth/` — registration, login, JWT, profile, roles, email verification
- `server/internal/game/` — game HTTP APIs and persisted history/stat endpoints
- `server/internal/ws/` — WebSocket hub, clients, room lifecycle, realtime moves, chat
- `server/internal/leaderboard/` — Elo leaderboard, public profile, avatar endpoints
- `server/internal/cache/` — Redis client helpers
- `server/internal/middleware/` — rate limiting and access-control middleware
- `client/lib/providers/` — Provider/ChangeNotifier state objects
- `client/lib/services/` — REST and WebSocket service wrappers
- `client/lib/screens/` — route-level Flutter screens
- `client/lib/ai/` — Gomoku AI evaluation, minimax, and isolate entrypoint
- `client/assets/` — audio, icons, and visual assets

## Branch Naming

Use short, descriptive branch names:

- `feature/<name>` for new features
- `fix/<name>` for bug fixes
- `docs/<name>` for documentation-only changes
- `chore/<name>` for maintenance and tooling work

## Commit Format

Use Conventional Commits:

- `feat: add leaderboard screen`
- `fix: reject out-of-turn websocket moves`
- `docs: document local setup`
- `test: cover elo draw calculation`
- `chore: update ci workflow`

## Pull Request Checklist

- [ ] Server tests pass: `go test ./...`
- [ ] Server vet passes: `go vet ./...`
- [ ] Flutter tests pass: `flutter test`
- [ ] Flutter analysis has no errors: `flutter analyze`
- [ ] Relevant OpenSpec task checkboxes are updated in `tasks.md`
- [ ] No secrets, tokens, `.env` files, or generated credentials are committed
- [ ] New API or WebSocket behavior is documented when applicable

## Phase 1 Release Validation

Before merging a release candidate, update `docs/RELEASE_EVIDENCE.md` and run:

```bash
cd server
go build ./...
go vet ./...
go test ./...
```

```bash
cd client
flutter pub get
flutter analyze
flutter test
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 flutter build apk --release
```

For local API smoke testing, start infrastructure first:

```bash
docker compose -f server/docker-compose.yml up -d mongodb redis
```

Then run the server with local-only environment values from `server/.env.example` and probe `/api/health`, `/api/leaderboard`, and a protected endpoint without a bearer token.

## Go Style

- Run `gofmt` on changed Go files.
- Keep handlers small and delegate business logic to package services where an
  existing service layer is present.
- Document exported functions and types.
- Return and log errors deliberately; do not silently ignore failures.
- Keep MongoDB and Redis access bounded by request contexts.

## Dart/Flutter Style

- Run `flutter format` on changed Dart files.
- Use Provider/ChangeNotifier for shared state.
- Avoid `setState` for complex cross-screen or service-backed state.
- Prefer named routes and existing navigation patterns.
- Keep widgets focused; extract reusable widgets only when they are reused or
  materially improve readability.

## Adding WebSocket Event Types

1. Add the event constant in `server/internal/ws/events.go`.
2. Route incoming messages in `server/internal/ws/client.go`.
3. Implement room/hub behavior in `server/internal/ws/room.go` or
   `server/internal/ws/hub.go`.
4. Add matching client handling in `client/lib/services/websocket_service.dart`
   and the relevant provider.
5. Document the new event in `docs/api.md`.
