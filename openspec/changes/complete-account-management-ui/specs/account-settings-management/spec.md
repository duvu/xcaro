## ADDED Requirements

### Requirement: Private Account Settings Data
The system SHALL provide a private account-settings surface for the signed-in user that loads their current account fields, verification state, and security actions without exposing another user's private account data.

#### Scenario: Signed-in user opens account settings
- **WHEN** an authenticated user opens the account-management surface in the app
- **THEN** the client loads and displays the signed-in user's private account data, including username, email, editable profile fields, and current email-verification status

#### Scenario: Unauthenticated user reaches account settings route
- **WHEN** a user without a valid session reaches an account-management route
- **THEN** the app redirects to login or registration and does not request private account data

### Requirement: Private Profile Editing
The system SHALL let the signed-in user edit their own supported profile fields in app, including full name, avatar URL, date of birth, phone number, and bio, with clear validation and refreshed account state after save.

#### Scenario: User saves valid profile changes
- **WHEN** an authenticated user submits valid supported profile fields from the account-management UI
- **THEN** the server persists only the editable fields for that user and the client refreshes the displayed private account state

#### Scenario: User submits invalid profile data
- **WHEN** an authenticated user submits invalid profile data such as malformed avatar URL or invalid phone format
- **THEN** the save is rejected and the client shows actionable validation feedback without presenting the changes as saved

### Requirement: Password Change
The system SHALL let the signed-in user change their password from the app using a security flow that requires the current password and reports success or failure clearly.

#### Scenario: User changes password successfully
- **WHEN** an authenticated user submits the correct current password and a valid new password
- **THEN** the server updates the password and the client shows a success state without changing another user's credentials

#### Scenario: User enters incorrect current password
- **WHEN** an authenticated user submits an incorrect current password in the change-password flow
- **THEN** the password is not changed and the client shows an actionable error

### Requirement: Email Change And Reverification
The system SHALL let the signed-in user change their email address in app with password confirmation and SHALL require reverification of the new email address.

#### Scenario: User changes email successfully
- **WHEN** an authenticated user submits a new email address and the correct password
- **THEN** the server updates the email, marks the account email as unverified, issues a new verification token, and the client shows pending-verification state for the new email

#### Scenario: User submits an already-used email
- **WHEN** an authenticated user tries to change email to an address already used by another account
- **THEN** the email change is rejected and the client shows an actionable error

### Requirement: Verification And Session Actions
The system SHALL expose verification-resend and logout actions from the account-management UI.

#### Scenario: Unverified user resends verification
- **WHEN** an authenticated user with an unverified email requests another verification email from account settings
- **THEN** the system sends or reissues the verification email and the client shows success or error feedback for that request

#### Scenario: User logs out from account settings
- **WHEN** an authenticated user chooses logout from the account-management UI
- **THEN** the app clears the authenticated session and returns the user to an unauthenticated entry flow
