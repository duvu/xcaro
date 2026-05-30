## Why

XCaro has accumulated a large MVP feature set across authentication, WebSocket multiplayer, AI, leaderboard, chat, Redis, email verification, CI/CD, and app assets. Before adding Phase 2 features, the project needs a focused stabilization pass that turns the current MVP from "implemented" into "release-ready" through repeatable validation, high-impact warning cleanup, deployment smoke testing, and documented go/no-go criteria.

## What Changes

- Add a release-readiness gate that defines the checks required before merging or shipping the MVP.
- Add a repeatable end-to-end QA plan covering auth, email verification, token refresh, online rooms, WebSocket gameplay, chat, leaderboard, history, AI difficulties, and app startup/onboarding.
- Add deployment smoke-test requirements for the Go server, MongoDB, Redis, Docker Compose, and health/API endpoints.
- Add client release-build validation requirements for Flutter dependency resolution, static analysis, tests, Android release build, icon/splash assets, and store-critical configuration.
- Add high-impact analyzer/lint cleanup scope for issues that affect maintainability or release quality, without forcing cosmetic cleanup of every informational warning.
- Add PR-hardening requirements for generated files, local build artifacts, environment templates, GitHub Actions configuration, and secret hygiene.

## Capabilities

### New Capabilities

- `release-readiness-gate`: Defines the pass/fail release gate for server, client, CI/CD, environment, artifact hygiene, and go/no-go documentation.
- `end-to-end-qa`: Defines the user-flow QA matrix for authentication, online gameplay, AI gameplay, chat, leaderboard, history, and onboarding.
- `deployment-smoke-testing`: Defines staging/local deployment validation for Docker Compose, server health, MongoDB, Redis, and critical API availability.
- `client-release-validation`: Defines Flutter release-readiness validation for dependencies, static analysis, tests, assets, and Android release build.

### Modified Capabilities

- None. There are no archived base specs in `openspec/specs/`; this change introduces stabilization and validation capabilities rather than changing existing product behavior.

## Impact

- **Client**: `client/pubspec.yaml`, `client/analysis_options.yaml`, `client/lib/**`, `client/test/**`, Android release build configuration, launcher/splash/generated assets.
- **Server**: `server/cmd/server/main.go`, `server/docker-compose.yml`, `server/Dockerfile`, `server/.env.example`, `server/internal/auth/**`, `server/internal/ws/**`, `server/internal/game/**`, `server/internal/leaderboard/**`, `server/internal/cache/**`, `server/internal/middleware/**`, `server/internal/email/**`.
- **CI/CD**: `.github/workflows/pr.yml`, `.github/workflows/deploy.yml`, GitHub Actions secrets documentation, branch/PR readiness checks.
- **Docs**: `docs/ROADMAP.md`, `docs/api.md`, `docs/architecture.md`, `CONTRIBUTING.md`, README release instructions, and any new release QA checklist produced during implementation.
- **Dependencies**: No new runtime dependency is expected. Implementation may add test-only scripts or documentation, but should prefer existing Go, Flutter, Docker, and shell tooling.
