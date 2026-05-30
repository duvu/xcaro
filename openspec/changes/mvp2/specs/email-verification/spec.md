## ADDED Requirements

### Requirement: Verification Email on Registration
The system SHALL send a verification email containing a time-limited link when a new user registers.

#### Scenario: Verification email sent
- **WHEN** user successfully registers
- **THEN** server generates a 32-byte hex token, stores its hash in `users.email_verify_token` with 24h expiry, and sends an email to the registered address with link `GET /api/auth/verify-email?token=<token>`

#### Scenario: SMTP failure
- **WHEN** the SMTP service is unavailable at registration time
- **THEN** registration still succeeds and server logs the email failure; user can request a resend

---

### Requirement: Email Verification Endpoint
The system SHALL verify a user's email address when they click the verification link.

#### Scenario: Valid verification token
- **WHEN** client calls `GET /api/auth/verify-email?token=<token>` and the token is valid and unexpired
- **THEN** server sets `users.email_verified = true`, clears the token fields, returns 200

#### Scenario: Expired token
- **WHEN** client calls the verify endpoint with an expired token
- **THEN** server returns 400 with message "verification link expired"; user is prompted to request a new link

#### Scenario: Invalid token
- **WHEN** client calls the verify endpoint with an unknown token
- **THEN** server returns 400 with message "invalid verification link"

---

### Requirement: Online Play Blocked for Unverified Users
The system SHALL block unverified users from creating or joining online rooms.

#### Scenario: Unverified user tries to play online
- **WHEN** an unverified user attempts to create or join an online room
- **THEN** server rejects the WebSocket `join_room` / `create_room` message with error `{ "code": "email_not_verified", "message": "Please verify your email to play online" }`

#### Scenario: Verified user plays normally
- **WHEN** a verified user attempts to join a room
- **THEN** server allows the request; game proceeds as normal

---

### Requirement: Resend Verification Email
The system SHALL allow users to request a new verification email if the original expired.

#### Scenario: Resend request
- **WHEN** authenticated user calls `POST /api/auth/resend-verification`
- **THEN** server generates a new token (invalidates old), sends a new email, returns 200

#### Scenario: Already verified
- **WHEN** a verified user calls resend
- **THEN** server returns 400 with message "email already verified"
