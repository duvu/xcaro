## Context

PlayVerse now has MVP1/MVP2-level functionality across the Flutter client and Go backend: JWT refresh-token auth, email verification, WebSocket rooms, move sync, chat, AI difficulties, history, Elo leaderboard, Redis caching/rate limiting, Docker Compose, GitHub Actions, app icons/splash, and documentation. The next roadmap phase is stabilization and release readiness, not new product behavior.

The current codebase already contains basic automated checks:

- `.github/workflows/pr.yml` runs `go vet ./...`, `go test ./...`, `flutter analyze`, and `flutter test`.
- Server tests exist for Elo and rate-limit behavior, with some WebSocket hub tests.
- Client tests exist for AI difficulty behavior.
- `server/docker-compose.yml` defines MongoDB, Redis, and the server service.
- `server/Dockerfile` builds the Go server binary.

Known stabilization concerns from discovery:

- `flutter analyze` previously completed with zero errors but many warnings/infos; Phase 1 should target high-impact warnings instead of cosmetic churn.
- Docker Compose currently includes placeholder/weak local secrets such as `JWT_SECRET=playverse-jwt-secret-key-2024`; this is acceptable for local development only and must be called out in release checks.
- The deploy workflow assumes `~/playverse` on the target host and `docker-compose` availability.
- Store-critical Android configuration still contains the default application ID TODO in `client/android/app/build.gradle`.
- The MVP PR is large and includes generated assets, broad backend/client changes, and prior `feature/websocket` history; reviewers need a subsystem-based checklist.

## Goals / Non-Goals

**Goals:**

- Define a release gate that maintainers can run before merging or shipping.
- Add a manual QA matrix for critical MVP user flows.
- Add deployment smoke-test instructions for server, MongoDB, Redis, and critical HTTP endpoints.
- Add client release validation for Flutter checks, Android release build, generated assets, and store-critical configuration.
- Identify and fix/document only high-impact analyzer/lint issues that affect release quality.
- Produce evidence files/checklists that make Phase 1 repeatable.

**Non-Goals:**

- No new gameplay features.
- No redesign of auth, WebSocket, AI, leaderboard, chat, or caching architecture.
- No broad refactor of old code unless required to pass release checks.
- No requirement to eliminate every informational analyzer message if it does not affect release quality.
- No production deployment or push unless explicitly requested during apply.

## Decisions

### Decision 1: Use documentation-backed release gates instead of adding a new test framework first

Phase 1 should create a concrete checklist and smoke scripts/docs using existing tooling: Go, Flutter, Docker Compose, curl, and GitHub Actions.

**Rationale:** The immediate risk is not absence of a framework; it is the lack of a repeatable, reviewed go/no-go process for a large MVP. Existing commands already cover many automated checks.

**Alternative considered:** Add a full E2E test framework immediately. Deferred because browser/device/WebSocket automation setup could expand scope and delay stabilization.

### Decision 2: Split validation into server, client, deployment, and manual QA surfaces

Implementation should keep evidence grouped by subsystem:

- Server automated checks and smoke checks.
- Client automated checks and release build checks.
- Docker/deploy environment checks.
- Manual QA matrix for real user flows.

**Rationale:** This matches how reviewers and release operators will reason about risk. It also allows small follow-up fixes to be isolated.

**Alternative considered:** One monolithic release checklist. Rejected because it becomes hard to assign owners and track partial progress.

### Decision 3: Fix only high-impact analyzer findings during Phase 1

High-impact findings include unused imports/variables, missing superclass calls, debug prints in release paths, deprecated APIs with straightforward replacements, and warnings that obscure real future issues.

**Rationale:** Analyzer output previously had many warnings/infos but zero errors. Fixing every style warning risks unrelated churn. Phase 1 should remove release-relevant noise and document deferred cleanup.

**Alternative considered:** Require `flutter analyze` to produce no warnings/infos. Rejected as too broad for stabilization and likely to create cosmetic refactors.

### Decision 4: Treat local secrets and deployment assumptions as release blockers unless documented

Local examples may keep placeholder credentials, but the release checklist must explicitly verify that production secrets come from the deployment environment and are not committed.

**Rationale:** Auth, SMTP, Redis, MongoDB, and GHCR/SSH deployment are all sensitive surfaces.

**Alternative considered:** Change Docker Compose to use only env-file interpolation now. This may be a good follow-up but is not required for the proposal unless apply reveals it is the smallest safe fix.

### Decision 5: Manual QA requires real surfaces, not source inspection

During implementation, manual QA tasks should use the real interface for each surface:

- HTTP/service checks through a running server.
- Flutter behavior through emulator/device where available, or documented limitation if unavailable.
- WebSocket flows through a real WS client/script against the running service.
- Release build through `flutter build`.

**Rationale:** The main stabilization risk is integration behavior across client/server/stateful services, which source inspection cannot prove.

## Risks / Trade-offs

- **Large existing PR history may obscure Phase 1 changes** → Keep Phase 1 artifacts and future implementation changes small and grouped.
- **Manual QA can be environment-dependent** → Record exact environment, commands, and any unavailable checks in the release evidence.
- **Docker Compose healthcheck may need image-specific command updates** → Treat failing healthcheck as a smoke-test finding and fix minimally during apply.
- **Flutter Android release build may expose signing/application ID gaps** → Document blockers separately from debug/test readiness.
- **Redis/SMTP may be unavailable locally** → Validate graceful degradation for Redis and document SMTP limitations with resend/email verification checks.

## Migration Plan

1. Add release-readiness docs/checklists and any minimal scripts needed to run smoke checks.
2. Run server automated checks and fix only failures introduced by current MVP work.
3. Run client automated checks/build validation and fix high-impact analyzer/build issues.
4. Run local service smoke tests with MongoDB and Redis through Docker Compose.
5. Run manual QA matrix or document unavailable real-device checks with exact blockers.
6. Update release evidence and mark Phase 1 tasks complete.

Rollback is straightforward because Phase 1 is primarily documentation, checklists, scripts, and minimal fixes. If a fix creates regressions, revert that fix independently and keep the release evidence showing the blocker.

## Open Questions

- Which exact Android package/application ID should be used for the first public release?
- Should the first release target APK, app bundle, or both?
- Is a staging server available for deployment smoke testing, or should Phase 1 use local Docker Compose only?
- Are SMTP credentials available for a real email verification smoke test, or should email sending be validated with documented test doubles/log evidence?
