## MODIFIED Requirements

### Requirement: Profile Management Surface
The system SHALL expose a private account-management surface from the dashboard for the signed-in user while preserving server-side authorization for profile updates and keeping public opponent profiles separate from private account controls.

#### Scenario: User views own account from dashboard
- **WHEN** an authenticated user opens the profile dashboard tab
- **THEN** the client displays the user's private account fields, verification status, stats, rank, recent games, and account-management actions

#### Scenario: User updates own profile
- **WHEN** an authenticated user submits valid profile changes
- **THEN** the server persists only fields that user is authorized to edit and the dashboard refreshes the displayed private account state

#### Scenario: User views another player's profile
- **WHEN** an authenticated user opens another player's profile from leaderboard, friends, or history flows
- **THEN** the client displays only that player's public profile fields and does not expose private account-management actions

#### Scenario: User attempts unauthorized profile update
- **WHEN** a user attempts to update another user's profile through dashboard APIs
- **THEN** the server rejects the request with an authorization error and no profile data is changed
