## 1. Backend Account Contract Alignment

- [x] 1.1 `server/internal/auth/service.go`: update email-change behavior so a successful email change resets `email_verified`, creates a new verification token/expiry, and triggers a new verification email for the new address
- [x] 1.2 `server/internal/auth/{handler.go,service.go}` and `server/pkg/models/user.go`: align private profile read/update, password-change, and email-change behavior for app UI use, including stable request/response handling and actionable validation errors
- [x] 1.3 `server/internal/leaderboard/handler.go` and route wiring in `server/cmd/server/main.go`: confirm whether avatar updates are handled through `PUT /profile`, `PUT /users/avatar`, or both, and keep own-account authorization intact

## 2. Client Account API And State

- [x] 2.1 `client/lib/services/api_service.dart`: add client methods for update profile, change password, update email, and any avatar-update call retained by the chosen backend contract
- [x] 2.2 `client/lib/providers/auth_provider.dart`: add a refresh/update path for `currentUser` after successful account mutations so private account data stays in sync across the authenticated shell
- [x] 2.3 `client/lib/models/user.dart` and any supporting form/model files: support account-edit payloads and state needed by the new UI flows

## 3. Private Account UI Surface

- [x] 3.1 Create a dedicated authenticated account-management screen/flow in `client/lib/screens/` and stop using the public `OpponentProfileScreen` as the signed-in user’s private account tab
- [x] 3.2 `client/lib/screens/main_scaffold.dart` and related routing: wire the profile tab to the new private account-management surface while preserving public opponent-profile routes elsewhere
- [x] 3.3 Implement editable private profile form UI for full name, avatar URL, date of birth, phone number, and bio with loading, validation, save, success, and failure states
- [x] 3.4 Add a consistent logout action from the account-management surface and remove reliance on unrelated gameplay screens for primary logout access

## 4. Security And Verification Flows

- [x] 4.1 Add change-password UI flow with current password, new password, confirmation, validation, and success/error feedback
- [x] 4.2 Add change-email UI flow with password confirmation, duplicate-email handling, and post-success pending-verification state
- [x] 4.3 Add email-verification status banner and resend-verification action to the private account-management surface, including already-verified and resend-failure feedback

## 5. Public/Private Profile Separation

- [x] 5.1 `client/lib/screens/opponent_profile_screen.dart`: keep public profile viewing focused on public stats/social actions and remove assumptions that it is the signed-in user’s private settings surface
- [x] 5.2 Account-management routing and UI states: ensure private account actions are only available for the signed-in user and never shown when viewing another player profile

## 6. Docs, Tests, And Verification

- [x] 6.1 `docs/api.md` and `docs/qa-matrix.md`: document the private account-management flows, verification-state behavior, and expected validation/error scenarios
- [x] 6.2 Add or update Go tests covering own-profile update, password change, email change with reverification, resend-verification, and authorization boundaries
- [x] 6.3 Add or update Flutter tests covering account screen rendering, profile save, password/email form validation, verification banner behavior, and logout flow
- [x] 6.4 Run `go test ./...`, `flutter analyze`, and `flutter test`
- [x] 6.5 Run an authenticated app smoke covering login, open account settings, edit profile, resend verification, change password/email, and logout
