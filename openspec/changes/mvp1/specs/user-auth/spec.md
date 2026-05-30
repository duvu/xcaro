## ADDED Requirements

### Requirement: User Registration
The system SHALL allow new users to create an account with a unique username and password.

#### Scenario: Successful registration
- **WHEN** user submits a valid username, email, and password (min 8 chars)
- **THEN** server creates the user, returns a 201 response with access token and refresh token

#### Scenario: Duplicate username
- **WHEN** user submits a username that already exists
- **THEN** server returns 409 Conflict with a descriptive error message

#### Scenario: Invalid input
- **WHEN** user submits a password shorter than 8 characters or missing email
- **THEN** server returns 400 Bad Request with field-level validation errors

---

### Requirement: User Login
The system SHALL allow registered users to authenticate and receive JWT tokens.

#### Scenario: Successful login
- **WHEN** user submits correct username and password
- **THEN** server returns 200 with `accessToken` (15 min TTL) and `refreshToken` (7 day TTL)

#### Scenario: Invalid credentials
- **WHEN** user submits wrong password or unknown username
- **THEN** server returns 401 Unauthorized

---

### Requirement: Access Token Refresh
The system SHALL allow clients to obtain a new access token using a valid refresh token without re-login.

#### Scenario: Valid refresh token
- **WHEN** client calls `POST /api/auth/refresh` with a valid, unexpired refresh token
- **THEN** server returns a new access token and a rotated refresh token; the old refresh token is invalidated

#### Scenario: Expired or invalid refresh token
- **WHEN** client calls refresh with an expired or unknown refresh token
- **THEN** server returns 401; client MUST redirect user to login screen

---

### Requirement: Persistent Session
The system SHALL persist the refresh token securely on the client across app restarts.

#### Scenario: App restart with valid session
- **WHEN** user restarts the app and a valid refresh token exists in secure storage
- **THEN** `AuthProvider` automatically refreshes the access token and routes user to Home screen without requiring re-login

#### Scenario: App restart with expired session
- **WHEN** user restarts the app and the refresh token is expired or missing
- **THEN** app routes user to the Login screen

---

### Requirement: Logout
The system SHALL allow users to log out, invalidating their session.

#### Scenario: Logout
- **WHEN** user taps Logout
- **THEN** client clears secure storage, server invalidates the refresh token in MongoDB, user is redirected to Login screen
