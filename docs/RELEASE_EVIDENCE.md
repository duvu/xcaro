# XCaro Phase 1 Release Evidence

Date: 2026-05-30

Change: `phase-1-stabilization-release-readiness`

## Go Server Validation

Commands run from `server/`:

```bash
go build ./...
go vet ./...
go test ./...
```

Final result: pass.

Fixes made during validation:

- Added `Hub.GetClientCount` for existing WebSocket hub tests.
- Moved `JoinRoom` and `LeaveRoom` broadcasts outside the hub write lock to avoid self-deadlock through `BroadcastToRoom`.
- Drained queued join events in `internal/ws/hub_test.go` before asserting chat broadcast behavior.
- Replaced unkeyed MongoDB `bson.D` sort literals with keyed `primitive.E` entries in game service queries.

Reviewed server areas: auth, email verification, WebSocket rooms, chat, leaderboard, Redis cache, and rate limiting. No remaining release-blocking TODOs were found in those paths.

## Flutter Client Validation

Commands run from `client/`:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 flutter build apk --release
```

Final result:

- `flutter pub get`: pass.
- `flutter analyze`: pass, `No issues found!`.
- `flutter test`: pass, `All tests passed!` for widget smoke and AI tests.
- Android release APK: pass, built `client/build/app/outputs/flutter-apk/app-release.apk` at 22.8 MB.

Fixes made during validation:

- Replaced stale counter widget test with a current login-screen smoke test.
- Migrated Android Gradle configuration to the current Flutter plugin-loader style.
- Updated Android Gradle Plugin to `8.7.0`, Gradle wrapper to `8.10.2`, Kotlin plugin to `1.8.22`, Java compatibility to 11, and pinned NDK `27.0.12077973`.
- Allowed local release builds to debug-sign when `xcaro-key.jks` is absent; this APK is suitable for internal validation only, not store upload.
- Removed release-path debug prints, fixed superclass callback calls, unused code, deprecated `withOpacity` usage touched by analyzer, and other analyzer findings.

Asset validation:

- `assets/icons/icon.png`: valid PNG, 1024x1024.
- `assets/icons/icon_foreground.png`: valid PNG, 512x512.
- `assets/images/stone_black.svg`, `stone_white.svg`, `board.svg`, `win_overlay.svg`: SVG files present and registered.

## Deployment Smoke Testing

Infrastructure command from repo root:

```bash
docker compose -f server/docker-compose.yml up -d mongodb redis
```

Result: MongoDB and Redis containers started.

Server smoke command used local-only values:

```bash
PORT=18080 \
MONGODB_URI='mongodb://admin:secret@localhost:27017/xcaro?authSource=admin' \
DB_NAME='xcaro_smoke' \
JWT_SECRET='local-smoke-secret-with-release-length' \
REDIS_URL='redis://localhost:6379' \
APP_URL='http://localhost:18080' \
go run ./cmd/server
```

Smoke results:

- `GET /api/health`: `200`, `{"status":"ok"}`.
- `GET /api/leaderboard`: `200`.
- `GET /api/games` without token: `401`.
- `POST /api/auth/register`: `201`; SMTP was not configured and email sending failed non-fatally in logs.

Redis degradation smoke:

```bash
PORT=18081 REDIS_URL='redis://localhost:6399' go run ./cmd/server
```

Result: health and leaderboard endpoints still returned `200` with Redis unreachable.

## CI/CD And Deploy Assumptions

Reviewed `.github/workflows/pr.yml` and `.github/workflows/deploy.yml`.

- PR workflow runs Go vet/test and Flutter analyze/test.
- Deploy workflow builds the server Docker image and pushes to GHCR.
- Required secrets: `GHCR_TOKEN`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST`, `DEPLOY_USER`.
- Deploy target assumption: SSH to target host, `cd ~/xcaro`, then `docker-compose pull && docker-compose up -d`.
- Rollback note: retain previous GHCR image tag/SHA and run `docker-compose pull && docker-compose up -d` after pinning the prior image tag in the target compose file.

## Secret Review

Reviewed:

- `server/.env.example`
- `server/docker-compose.yml`
- `.github/workflows/pr.yml`
- `.github/workflows/deploy.yml`
- `README.md`
- `CONTRIBUTING.md`
- `docs/*.md`

Findings: no real credentials found. `server/docker-compose.yml` contains local-only MongoDB password `secret` and JWT placeholder `xcaro-jwt-secret-key-2024`; these are not production values and must be replaced in deployed environments.

## Repository Hygiene

Final hygiene commands from repo root:

```bash
git status --short
git ls-files --others --exclude-standard
```

Result: only intentional source, documentation, OpenSpec, and configuration changes are visible. Local generated outputs remain ignored, including `client/build/` and `client/android/app/.cxx/` from the Android release build.

## QA Matrix

Manual QA matrix: [`qa-matrix.md`](qa-matrix.md).

Executed directly in this environment:

- API health, leaderboard, protected endpoint auth enforcement, and registration smoke checks.
- Flutter widget/AI tests.
- Android release APK build.

Blocked in this environment:

- Two-device online gameplay.
- Verified email flow with SMTP sandbox.
- Real device/emulator checks for onboarding, navigation, chat, theme, and sound.

## Go / No-Go Decision

Decision: **go for internal review and staging setup**, **not yet go for public beta/store release**.

Reasons:

- Automated server/client gates are green.
- Local API smoke and Redis degradation checks pass.
- Android APK builds for internal validation.
- Public release still needs owner confirmation for Android package ID, release signing, SMTP sandbox/production credentials, deploy host provisioning, and real device E2E QA.
