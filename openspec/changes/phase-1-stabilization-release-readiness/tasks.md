## 1. Release Gate Documentation

- [x] 1.1 Create `docs/release-readiness.md` with server, client, deployment, artifact hygiene, secret hygiene, and PR hardening gates
- [x] 1.2 Add pass/fail/not-applicable columns and expected evidence for every release gate item
- [x] 1.3 Document known release blockers and deferred non-blockers, including Android application ID, deployment host assumptions, and SMTP availability
- [x] 1.4 Update `docs/ROADMAP.md` Phase 1 section to link to the release-readiness checklist

## 2. Server Automated Validation

- [x] 2.1 Run `go build ./...` from `server/` and record result in release evidence
- [x] 2.2 Run `go vet ./...` from `server/` and fix or document any findings
- [x] 2.3 Run `go test ./...` from `server/` and fix or document any failures
- [x] 2.4 Review auth, email verification, WebSocket room, chat, leaderboard, Redis cache, and rate-limit server paths for release-blocking TODOs or obvious defects
- [x] 2.5 Add or update minimal Go tests only for release-blocking gaps found during validation

## 3. Client Automated Validation

- [x] 3.1 Run `flutter pub get` from `client/` and record result in release evidence
- [x] 3.2 Run `flutter analyze` from `client/`; fix high-impact warnings such as unused imports, unused variables, missing superclass calls, debug prints in release paths, and straightforward deprecated API replacements
- [x] 3.3 Run `flutter test` from `client/` and fix or document any failures
- [x] 3.4 Run Android release build (`flutter build apk --release` or agreed app bundle command) and record produced artifact path or exact blocker
- [x] 3.5 Validate launcher icon, splash, and registered asset paths; rerun `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create` only if needed
- [x] 3.6 Review `client/android/app/build.gradle` for store-critical TODOs and document required package/application ID decision

## 4. Deployment Smoke Testing

- [x] 4.1 Start MongoDB and Redis with `docker compose -f server/docker-compose.yml up -d mongodb redis` and record container health/status
- [x] 4.2 Start the Go server with documented local environment variables and record startup result
- [x] 4.3 Probe `/api/health` and record expected response
- [x] 4.4 Probe public auth/leaderboard endpoints and protected profile/game endpoints with curl or script; verify validation/auth responses are safe
- [x] 4.5 Stop or disable Redis and verify cache/rate-limit paths fail open without breaking core health/auth/game API access
- [x] 4.6 Review `.github/workflows/deploy.yml` assumptions and document required GHCR/SSH secrets, target directory, compose command, and rollback notes

## 5. End-to-End Manual QA Matrix

- [x] 5.1 Create `docs/qa-matrix.md` covering auth, email verification, token refresh, logout, onboarding, home navigation, online rooms, gameplay, resign, disconnect, chat, leaderboard, history, AI difficulties, theme, and sound
- [x] 5.2 Execute auth/session QA: register, verification prompt, resend verification, login, token refresh after restart, and logout
- [x] 5.3 Execute online gameplay QA with two verified users: create room, join room, make moves, complete win/draw, verify game-over state and stats/leaderboard update
- [x] 5.4 Execute resign/disconnect QA and verify correct game-over reason, room cleanup, and client messaging
- [x] 5.5 Execute chat QA for valid, empty, and over-limit messages
- [x] 5.6 Execute AI QA for Easy, Medium, and Hard modes on emulator/device where available, or document the environment blocker
- [x] 5.7 Execute navigation/content QA for onboarding, leaderboard, opponent profile, history, settings/how-to-play, theme, and sound controls

## 6. PR Hardening and Evidence

- [x] 6.1 Run `git status --short` and `git ls-files --others --exclude-standard`; verify no local session state, build output, or unintended artifacts remain untracked/staged
- [x] 6.2 Review `server/.env.example`, `server/docker-compose.yml`, workflows, and docs for real secrets; replace with placeholders or document local-only values
- [x] 6.3 Create `docs/RELEASE_EVIDENCE.md` summarizing commands run, manual QA results, environment, blockers, deferred warnings, and go/no-go decision
- [x] 6.4 Update README or CONTRIBUTING release section with the canonical Phase 1 validation commands if missing
- [x] 6.5 Run final verification commands (`go build ./...`, `go vet ./...`, `go test ./...`, `flutter analyze`, `flutter test`) and record final status
- [x] 6.6 Mark Phase 1 OpenSpec tasks complete only after evidence files and final verification are updated
