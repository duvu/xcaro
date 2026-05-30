## ADDED Requirements

### Requirement: Release gate checklist
The project SHALL maintain a release gate checklist that defines all required checks before the MVP is considered ready to merge or ship.

#### Scenario: Gate is documented
- **WHEN** the Phase 1 stabilization work is complete
- **THEN** the repository contains a release readiness checklist covering server checks, client checks, CI/CD checks, environment checks, artifact hygiene, and manual QA sign-off

#### Scenario: Gate has explicit pass/fail criteria
- **WHEN** a maintainer reviews the checklist
- **THEN** every gate item has a clear expected result and can be marked pass, fail, or not applicable

### Requirement: Server quality gate
The server SHALL pass Go build, vet, and test commands required for release readiness.

#### Scenario: Server checks pass
- **WHEN** release readiness verification is run from `server/`
- **THEN** `go build ./...`, `go vet ./...`, and `go test ./...` complete successfully or any pre-existing failure is explicitly documented with owner and impact

### Requirement: Client quality gate
The Flutter client SHALL pass dependency resolution, static analysis, and test commands required for release readiness.

#### Scenario: Client checks pass
- **WHEN** release readiness verification is run from `client/`
- **THEN** `flutter pub get`, `flutter analyze`, and `flutter test` complete with zero errors, and any remaining warnings are documented by severity

### Requirement: Artifact hygiene gate
The repository SHALL exclude local session state, build output, and unintended generated artifacts from release commits.

#### Scenario: No ignored local artifacts are tracked
- **WHEN** release readiness verification checks Git status
- **THEN** `.omo/`, `.serena/`, `client/build/`, and other local-only outputs are not staged or tracked

#### Scenario: Generated release assets are intentional
- **WHEN** generated icon, splash, or platform asset files are present
- **THEN** the release checklist records why they are required and which generator command produced them

### Requirement: Secret hygiene gate
The project SHALL verify that release configuration templates contain placeholders only and do not expose real credentials.

#### Scenario: Environment templates are safe
- **WHEN** release readiness verification inspects `.env.example`, Docker Compose environment blocks, workflow files, and documentation
- **THEN** no real token, password, private key, SMTP credential, production JWT secret, or deploy key is committed

### Requirement: PR hardening summary
The release gate SHALL produce a concise PR hardening summary for reviewers.

#### Scenario: Reviewer summary exists
- **WHEN** Phase 1 work is ready for review
- **THEN** reviewers can read a summary listing checked subsystems, commands run, manual flows exercised, known risks, and remaining follow-up items
