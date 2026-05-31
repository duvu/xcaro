## ADDED Requirements

### Requirement: Modular Monolith Deployment
The system SHALL implement dashboard/social management in the existing game server deployable for the initial release.

#### Scenario: Dashboard API is deployed
- **WHEN** dashboard/social management ships
- **THEN** it is served by the existing Go server process using existing authentication, MongoDB, Redis/cache where applicable, and deployment pipeline

#### Scenario: No separate service required
- **WHEN** the dashboard/social change is implemented
- **THEN** no additional backend deployable, service discovery, cross-service auth propagation, or separate database is required

### Requirement: Bounded Server Modules
The system SHALL keep dashboard/social code in explicit server modules with stable boundaries from gameplay and WebSocket internals.

#### Scenario: Friend API uses gameplay data
- **WHEN** friend or dashboard code needs game history, stats, leaderboard, presence, or invite information
- **THEN** it accesses that data through documented service interfaces or route-level contracts rather than direct mutation of WebSocket hub state

#### Scenario: Developer adds social route
- **WHEN** a new social or dashboard route is added
- **THEN** it is registered under a clearly named authenticated route group and uses social/dashboard handlers instead of unrelated auth/game handlers

### Requirement: Authorization And Privacy Boundary
The system SHALL enforce authentication, ownership, and role checks consistently across dashboard/social APIs.

#### Scenario: User accesses own dashboard data
- **WHEN** an authenticated user requests dashboard, history, profile, or friend data for themselves
- **THEN** the server authorizes the request and returns only fields allowed for that user

#### Scenario: User accesses another user's private dashboard data
- **WHEN** an authenticated non-admin user requests another user's private history, friend requests, or profile management data
- **THEN** the server denies the request and returns no private data

### Requirement: Future Extraction Criteria
The system SHALL document clear criteria for splitting dashboard/social management into a separate backend service later.

#### Scenario: Extraction is evaluated
- **WHEN** dashboard/social traffic, security posture, team ownership, release cadence, or scaling characteristics diverge materially from gameplay
- **THEN** the team can use documented criteria to decide whether to extract a bounded context

#### Scenario: Extraction is not justified
- **WHEN** dashboard/social management shares auth, user data, game records, and deployment cadence with gameplay
- **THEN** the system remains a modular monolith and avoids service-split overhead

### Requirement: API And Operational Documentation
The system SHALL document dashboard/social API contracts, module boundaries, data indexes, and operational expectations.

#### Scenario: Developer reviews dashboard architecture
- **WHEN** a developer reads architecture documentation
- **THEN** they can identify dashboard/social route groups, persistence ownership, dependencies, and forbidden couplings

#### Scenario: QA validates dashboard/social flows
- **WHEN** QA reviews test documentation
- **THEN** it includes registration/login, dashboard summary, history filters, friend request lifecycle, authorization failures, and service-boundary assumptions
