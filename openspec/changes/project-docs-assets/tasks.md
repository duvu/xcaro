## 1. App Icon & Splash Screen

- [x] 1.1 Add `flutter_launcher_icons: ^0.13.0` and `flutter_native_splash: ^2.4.0` to `client/pubspec.yaml` under `dev_dependencies`
- [x] 1.2 Add `flutter_svg: ^2.0.0` to `client/pubspec.yaml` under `dependencies`
- [x] 1.3 Create `client/assets/icons/` directory; add a 1024×1024 PNG icon (`icon.png`) — navy background `#1A2035` with a white filled circle (stone) centered, with "X" lettermark in gold `#FFD700` (generate as a simple SVG rendered to PNG, or create directly as PNG)
- [x] 1.4 Add `flutter_launcher_icons` config section to `client/pubspec.yaml`:
  ```yaml
  flutter_launcher_icons:
    android: true
    ios: true
    image_path: "assets/icons/icon.png"
    adaptive_icon_background: "#1A2035"
    adaptive_icon_foreground: "assets/icons/icon_foreground.png"
    min_sdk_android: 21
  ```
- [x] 1.5 Create `client/assets/icons/icon_foreground.png` — transparent background, centered stone + "X" motif (512×512 safe-zone for adaptive icon)
- [x] 1.6 Add `flutter_native_splash` config to `client/pubspec.yaml`:
  ```yaml
  flutter_native_splash:
    color: "#1A2035"
    image: assets/icons/icon.png
    android: true
    ios: true
    android_12:
      color: "#1A2035"
      image: assets/icons/icon.png
  ```
- [x] 1.7 Run `dart run flutter_launcher_icons` in `client/` and verify it exits 0 with no errors
- [x] 1.8 Run `dart run flutter_native_splash:create` in `client/` and verify it exits 0

## 2. Game Visual Assets (SVG)

- [x] 2.1 Create `client/assets/images/` directory (if it doesn't exist)
- [x] 2.2 Create `client/assets/images/stone_black.svg` — 100×100 viewBox, dark stone: filled circle `#1A1A2E` with subtle radial highlight `#4A4A6A` at top-left
- [x] 2.3 Create `client/assets/images/stone_white.svg` — 100×100 viewBox, light stone: filled circle `#F0EAD6` with subtle radial shadow `#D0C8B0` at bottom-right
- [x] 2.4 Create `client/assets/images/board.svg` — 700×700 viewBox, 15×15 grid of lines on cream background `#DCB97A`; add star point dots at standard positions: (3,3), (3,7), (3,11), (7,3), (7,7), (7,11), (11,3), (11,7), (11,11) — zero-indexed from top-left
- [x] 2.5 Create `client/assets/images/win_overlay.svg` — a semi-transparent golden line/rect overlay for highlighting the winning 5 stones
- [x] 2.6 Register all image assets in `client/pubspec.yaml` under `flutter.assets`:
  ```yaml
  assets:
    - assets/images/stone_black.svg
    - assets/images/stone_white.svg
    - assets/images/board.svg
    - assets/images/win_overlay.svg
    - assets/icons/icon.png
  ```
- [x] 2.7 Run `flutter pub get` and `flutter analyze` in `client/` — verify 0 errors

## 3. Audio Asset Descriptors

- [x] 3.1 Create `client/assets/sounds/` directory
- [x] 3.2 Create `client/assets/sounds/README.md` documenting required sound effects:
  - `place_stone.mp3` — soft tap/click, ~100ms, triggered on every stone placement
  - `win.mp3` — triumphant fanfare, ~2s, triggered on win screen
  - `lose.mp3` — descending tone, ~1.5s, triggered on loss screen
  - `draw.mp3` — neutral chime, ~1s, triggered on draw screen
  - `button_tap.mp3` — UI click feedback, ~50ms, triggered on button taps
  - Recommended source: freesound.org (CC0 license); format: MP3 + OGG; max size 50KB each
- [x] 3.3 Add `assets/sounds/` directory registration to `client/pubspec.yaml` assets list (even if empty, so it's ready for audio files)

## 4. Game Rules Documentation

- [x] 4.1 Create `GAME_RULES.md` at the repo root with the following sections:
  - **Overview**: What is Gomoku / Caro?
  - **Board**: 15×15 grid, intersections
  - **Objective**: First to get 5 stones in a row (horizontal, vertical, or diagonal)
  - **Turns**: Players alternate; Black (X) goes first
  - **Win Condition**: Exactly 5 or more in a row counts (no overline rule in PlayVerse)
  - **Draw Condition**: Board is full with no winner
  - **PlayVerse Controls**: How to create a room, join a room, play vs AI, use chat, view leaderboard
  - **Tips for beginners**: 3-5 strategic tips

## 5. Developer Documentation

- [x] 5.1 Create `docs/` directory at repo root (if not exists)
- [x] 5.2 Create `docs/architecture.md` with sections:
  - **System Overview** (ASCII diagram: Flutter App ↔ Go Server ↔ MongoDB + Redis)
  - **Flutter Client Architecture**: Provider state management tree, screen routing, WebSocket lifecycle
  - **Go Server Architecture**: Gin router layers, WS Hub + Room model, MongoDB collections (`users`, `game_records`)
  - **Authentication Flow**: Register → JWT access (15min) + refresh (7day) → auto-refresh on startup
  - **WebSocket Protocol**: Message envelope `{type, payload}`, event types list, room lifecycle (create → join → play → game_over)
  - **Elo Rating System**: K=32, calculation formula, when updated (online non-forfeit games only)
- [x] 5.3 Create `docs/api.md` as a REST API reference. For each endpoint include: method, path, auth (🔓/🔐), brief description, request body (key fields), response (key fields). Cover:
  - Auth: POST /register, POST /login, POST /refresh, POST /logout, GET /verify-email, POST /resend-verification
  - Profile: GET /profile, PUT /profile, PUT /profile/password
  - Games: GET /games/records, GET /games/records/stats
  - Leaderboard: GET /leaderboard
  - Users: GET /users/:id/profile
  - WebSocket: GET /ws (upgrade), message types table

## 6. Contribution Guide

- [x] 6.1 Create `CONTRIBUTING.md` at the repo root with sections:
  - **Prerequisites**: Go 1.23+, Flutter 3.x, Docker (for MongoDB + Redis), `just_audio` dependencies note
  - **Local Setup**: Step-by-step — clone, `cp server/.env.example server/.env`, `docker-compose up -d`, `go run ./cmd/server`, `flutter run`
  - **Project Structure**: Quick map of `server/internal/`, `client/lib/` directories
  - **Branch Naming**: `feature/<name>`, `fix/<name>`, `docs/<name>`, `chore/<name>`
  - **Commit Format**: Conventional Commits — `feat:`, `fix:`, `docs:`, `test:`, `chore:`
  - **PR Checklist**: Tests pass (`go test ./...`, `flutter test`), lint clean (`go vet`, `flutter analyze`), task checked in tasks.md, no secrets committed
  - **Go Style**: `gofmt`-formatted, exported functions documented, error handling (no silent ignores)
  - **Dart/Flutter Style**: `flutter format`, Provider for state (no `setState` in complex widgets), named routes
  - **Adding WS Event Types**: Where to add constants (`internal/ws/events.go`), how to route in client.go
- [x] 6.2 Create `server/.env.example` file documenting all required env vars:
  ```
  MONGODB_URI=mongodb://admin:secret@localhost:27017/playverse?authSource=admin
  DB_NAME=playverse
  PORT=8080
  JWT_SECRET=change-me-in-production
  REDIS_URL=redis://localhost:6379
  SMTP_HOST=
  SMTP_PORT=587
  SMTP_USER=
  SMTP_PASS=
  SMTP_FROM=noreply@playverse.com
  APP_URL=http://localhost:8080
  ```

## 7. Store Listing Assets

- [x] 7.1 Create `store/` directory at repo root
- [x] 7.2 Create `store/play-store.md` with:
  - **Title** (≤30 chars): `PlayVerse - Gomoku Online`
  - **Short Description** (≤80 chars): `Play Gomoku online or vs AI. Ranked matches, chat, leaderboard. Free!`
  - **Full Description** (≤4000 chars): 4–6 paragraphs covering gameplay, online multiplayer, AI difficulty, Elo ranking, chat feature, and technical quality
  - **Content Rating**: Everyone (no violence, no adult content)
  - **Keywords**: gomoku, caro, five in a row, board game, strategy, online multiplayer, ai
  - **What's New (v1.0.0)**: Initial release changelog
- [x] 7.3 Create `store/app-store.md` with:
  - **Name** (≤30 chars): `PlayVerse – Gomoku Online`
  - **Subtitle** (≤30 chars): `Strategy Board Game`
  - **Promotional Text** (≤170 chars): Seasonal/timely blurb
  - **Description** (≤4000 chars): Same tone as Play Store but formatted for App Store
  - **Keywords** (≤100 chars total): comma-separated
  - **Support URL**: `https://github.com/<owner>/playverse/issues`
  - **Privacy Policy URL**: placeholder
- [x] 7.4 Create `store/screenshots.md` documenting 5 required screenshot scenes with captions and device size requirements (6.7" Android, 6.5" iOS)
