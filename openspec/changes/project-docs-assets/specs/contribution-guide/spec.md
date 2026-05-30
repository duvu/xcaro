## ADDED Requirements

### Requirement: Contribution Guide
The project SHALL include a `CONTRIBUTING.md` file at the repo root that onboards new contributors.

#### Scenario: Contributor can set up the project
- **WHEN** a developer reads `CONTRIBUTING.md` and follows the setup section
- **THEN** they can run the server (`go run ./cmd/server`) and client (`flutter run`) locally without additional guidance

#### Scenario: PR workflow is documented
- **WHEN** a contributor wants to submit a pull request
- **THEN** `CONTRIBUTING.md` explains: branch naming (`feature/`, `fix/`, `docs/`), commit message format, PR checklist (tests pass, lint clean, task checked), and review process

#### Scenario: Coding conventions documented
- **WHEN** a contributor writes new code
- **THEN** `CONTRIBUTING.md` references Go style (gofmt, no exported unexported symbols), Dart/Flutter style (flutter format, Provider pattern), and naming conventions for WS event types and MongoDB collections
