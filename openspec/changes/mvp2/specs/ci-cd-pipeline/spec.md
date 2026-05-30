## ADDED Requirements

### Requirement: PR Validation Workflow
The system SHALL automatically run linting, unit tests, and build checks on every pull request to the main branch.

#### Scenario: PR check passes
- **WHEN** a pull request is opened or updated targeting the `main` branch
- **THEN** GitHub Actions runs: `go vet ./...`, `go test ./...` (server), `flutter analyze` (client), `flutter test` (client); all must pass for the PR check to be green

#### Scenario: PR check fails
- **WHEN** any step in the PR workflow fails
- **THEN** the PR check is marked failed; GitHub blocks merge if branch protection is enabled

---

### Requirement: Deploy Workflow
The system SHALL automatically build and deploy the server on every push to the main branch.

#### Scenario: Successful deploy
- **WHEN** a commit is pushed to `main`
- **THEN** GitHub Actions builds the Docker image for the server, pushes it to GHCR with tag `latest` and the commit SHA, SSHs into the deploy server, runs `docker-compose pull && docker-compose up -d`

#### Scenario: Build failure stops deploy
- **WHEN** the Docker build step fails
- **THEN** the deploy step is skipped; no broken image is pushed or deployed

---

### Requirement: Environment Secret Management
The CI/CD workflow SHALL use GitHub Actions secrets for all sensitive values.

#### Scenario: Secrets used in workflows
- **WHEN** the deploy workflow runs
- **THEN** all credentials (GHCR token, SSH key, server host) are read from GitHub Actions secrets, never hardcoded in workflow YAML
