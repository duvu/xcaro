## ADDED Requirements

### Requirement: Local deployment smoke test
The project SHALL define a local deployment smoke test using Docker Compose for infrastructure and the Go server.

#### Scenario: Compose services start
- **WHEN** the smoke test runs `docker compose -f server/docker-compose.yml up -d mongodb redis`
- **THEN** MongoDB and Redis start successfully and expose the ports expected by the server configuration

#### Scenario: Server starts with documented env
- **WHEN** the server starts with variables from `server/.env.example` adapted for local testing
- **THEN** it connects to MongoDB, initializes Redis when available, registers routes, and serves the health endpoint

### Requirement: Health and API smoke checks
The project SHALL define smoke checks for critical HTTP endpoints.

#### Scenario: Public endpoints respond
- **WHEN** the running server is probed
- **THEN** `/api/health`, `/api/leaderboard`, `/api/auth/register`, `/api/auth/login`, and `/api/auth/refresh` return expected success or validation responses without panic

#### Scenario: Protected endpoints enforce auth
- **WHEN** protected game/profile endpoints are called without a Bearer token
- **THEN** the server returns an authentication error rather than exposing protected data

### Requirement: Redis degradation smoke check
The project SHALL verify behavior when Redis is unavailable.

#### Scenario: Redis unavailable does not break core service
- **WHEN** Redis is stopped or `REDIS_URL` is unreachable during smoke testing
- **THEN** leaderboard/cache/rate-limit code degrades according to the MVP2 fail-open design and core auth/game endpoints remain available

### Requirement: Deployment workflow review
The project SHALL verify deployment workflow assumptions before release.

#### Scenario: Deploy workflow prerequisites are documented
- **WHEN** the deploy workflow is reviewed
- **THEN** required GHCR and SSH secrets, server working directory, Docker Compose command, image name, and rollback notes are documented for the release operator
