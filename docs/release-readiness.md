# PlayVerse Release Readiness Checklist

Use this checklist before merging or shipping an MVP release candidate. Each row
must be marked `Pass`, `Fail`, or `N/A`, with evidence linked in
[`RELEASE_EVIDENCE.md`](RELEASE_EVIDENCE.md) or the PR description.

## Status Legend

| Status | Meaning |
|---|---|
| Pass | The gate was executed and met the expected result. |
| Fail | The gate was executed and found a release blocker. |
| N/A | The gate cannot run in the current environment and the limitation is documented. |

## Server Gate

| Gate | Expected Result | Status | Required Evidence |
|---|---|---:|---|
| Go dependency/build validation | `go build ./...` exits 0 from `server/`. | Pass | See [`RELEASE_EVIDENCE.md`](RELEASE_EVIDENCE.md). |
| Go vet validation | `go vet ./...` exits 0 from `server/`, or findings are documented with owner/impact. | Pass | Fixed missing WS test helper and keyed Mongo sort literals. |
| Go tests | `go test ./...` exits 0 from `server/`, or failures are documented as pre-existing blockers. | Pass | See [`RELEASE_EVIDENCE.md`](RELEASE_EVIDENCE.md). |
| Auth/email verification review | Register, login, refresh, logout, verify email, and resend verification paths have no release-blocking TODOs or obvious panic paths. | Pass | API smoke register returned `201`; SMTP absence logged as non-fatal. |
| WebSocket gameplay/chat review | Room creation/joining, moves, resign, disconnect cleanup, and chat validation have no release-blocking TODOs or obvious defects. | Pass | Fixed hub join/leave broadcast deadlock and drained queued test messages. |
| Leaderboard/cache/rate-limit review | Elo, leaderboard, Redis cache, and rate limiter paths degrade safely and have no release-blocking TODOs. | Pass | Leaderboard returned `200` with Redis available and unavailable. |

## Client Gate

| Gate | Expected Result | Status | Required Evidence |
|---|---|---:|---|
| Flutter dependency resolution | `flutter pub get` exits 0 from `client/`. | Pass | See [`RELEASE_EVIDENCE.md`](RELEASE_EVIDENCE.md). |
| Flutter analyzer | `flutter analyze` exits with zero errors; high-impact warnings are fixed or documented. | Pass | Analyzer reports `No issues found!`. |
| Flutter tests | `flutter test` exits 0 from `client/`. | Pass | Widget smoke and AI tests pass. |
| Android release build | `flutter build apk --release` or agreed app bundle command exits 0, or exact blocker is documented. | Pass | Built `client/build/app/outputs/flutter-apk/app-release.apk` with JDK 21. |
| App assets | Launcher PNGs, splash assets, SVGs, and registered asset paths exist and generator commands are current. | Pass | PNG/SVG validation passed; generators previously executed. |
| Store-critical config | App name, version/build number, Android namespace/application ID, signing placeholders, icons, splash, and permission-sensitive config are reviewed. | Pass | Package ID documented; release build debug-signs if no local keystore. |

## Deployment Gate

| Gate | Expected Result | Status | Required Evidence |
|---|---|---:|---|
| Compose infrastructure | `docker compose -f server/docker-compose.yml up -d mongodb redis` starts MongoDB and Redis or records environment blocker. | Pass | MongoDB and Redis containers started. |
| Server local startup | Go server starts with documented local environment values and connects to MongoDB; Redis initializes when available. | Pass | Server started on smoke ports `18080` and `18081`. |
| Health endpoint | `GET /api/health` returns `200` and `{"status":"ok"}`. | Pass | Smoke response recorded in [`RELEASE_EVIDENCE.md`](RELEASE_EVIDENCE.md). |
| Public endpoint smoke | Auth and leaderboard public endpoints return expected success or validation responses without panic. | Pass | Leaderboard `200`; register `201` with SMTP missing logged non-fatally. |
| Protected endpoint smoke | Profile/game endpoints without Bearer token return authentication errors and no protected data. | Pass | `/api/games` returned `401` without token. |
| Redis degradation | With Redis stopped or unreachable, core health/auth/game APIs remain available or exact blocker is documented. | Pass | Bad Redis port still allowed health and leaderboard `200`. |
| Deploy workflow assumptions | GHCR/SSH secrets, target directory, compose command, image name, and rollback procedure are documented. | Pass | See deployment notes in [`RELEASE_EVIDENCE.md`](RELEASE_EVIDENCE.md). |

## Artifact And Repository Hygiene Gate

| Gate | Expected Result | Status | Required Evidence |
|---|---|---:|---|
| Git working tree review | `git status --short` and `git ls-files --others --exclude-standard` show only intentional files. | Pass | Reviewed during Phase 1 evidence pass. |
| Local artifact exclusion | `.omo/`, `.serena/`, `client/build/`, native build caches, and other local-only outputs are ignored and not staged. | Pass | `client/build/` and `client/android/app/.cxx/` remain ignored; APK output/native caches are not tracked. |
| Generated assets intentional | Generated launcher/splash/platform assets are explained and tied to generator commands. | Pass | Project docs/assets OpenSpec records generator commands. |
| OpenSpec task hygiene | Phase 1 tasks are marked complete only after verification/evidence is updated. | Pass | Marked after final evidence/verification update. |

## Secret Hygiene Gate

| Gate | Expected Result | Status | Required Evidence |
|---|---|---:|---|
| Environment template review | `server/.env.example` contains placeholders only and no real credentials. | Pass | Placeholder-only values reviewed. |
| Docker Compose local-only values | `server/docker-compose.yml` local passwords/JWT values are documented as non-production placeholders. | Pass | Local-only `admin:secret` and JWT placeholder documented. |
| Workflow secret usage | GitHub Actions uses `secrets.*` for GHCR and SSH credentials. | Pass | `GHCR_TOKEN`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST`, `DEPLOY_USER` used via secrets. |
| Docs secret scan | Release docs, README, CONTRIBUTING, and API docs contain no real tokens, private keys, SMTP credentials, or production JWT secrets. | Pass | Secret-like findings were placeholders/local dev values only. |

## PR Hardening Gate

| Gate | Expected Result | Status | Required Evidence |
|---|---|---:|---|
| Reviewer summary | PR/release evidence lists checked subsystems, commands run, manual flows exercised, known risks, and follow-up items. | Pass | See [`RELEASE_EVIDENCE.md`](RELEASE_EVIDENCE.md). |
| Large-change review aid | Large MVP changes are grouped by server, client, docs/assets, workflows, and generated files. | Pass | Evidence groups review areas and known PR scope risk. |
| Manual QA sign-off | Auth, online gameplay, chat, AI, navigation, theme, and sound flows are executed or environment blockers are explicit. | Pass | [`qa-matrix.md`](qa-matrix.md) records executed API smoke and blocked device flows. |

## Known Release Blockers To Resolve Or Accept Explicitly

| Item | Status | Release Impact | Required Decision |
|---|---|---|---|
| Android application ID/package ownership | Owner decision needed | `client/android/app/build.gradle` uses `vn.x51.game2d.playverse`; confirm it is the intended public package before store upload. | Product owner must approve or provide final ID before public store upload. |
| Android release signing placeholders | Internal build accepted | Local release build falls back to debug signing when `playverse-key.jks` is absent; artifact is not store-ready. | Provide signing config before Play Store/App Store release. |
| Deployment host assumptions | Open | `.github/workflows/deploy.yml` assumes `~/playverse` and `docker-compose` on the target host. | Release operator must provision target or update workflow. |
| SMTP availability | Open | Real email verification smoke test requires SMTP credentials; without them only UI/API fallback can be validated. | Provide test SMTP credentials or accept documented limitation. |
| Large PR scope | Open | PR includes broad MVP history and generated assets, increasing review risk. | Review by subsystem before merge. |

## Deferred Non-Blockers

| Item | Reason Deferred | Follow-up |
|---|---|---|
| Cosmetic analyzer infos | Phase 1 fixes only release-impacting warnings to avoid broad churn. | Schedule cleanup after MVP merge. |
| Full automated mobile E2E framework | Manual QA matrix is enough for Phase 1; automation can be added once flows stabilize. | Add integration tests in a later stabilization change. |
| Production deploy execution | This change validates deploy readiness but does not deploy without explicit request. | Run deploy after secrets/host are confirmed. |
| Real app store metadata finalization | Store drafts exist, but screenshots/privacy/support URLs need owner confirmation. | Complete before public store submission. |
