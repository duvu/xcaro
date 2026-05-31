## Why

PlayVerse already has backend account APIs, but the authenticated app UI only exposes registration, login, logout, and a mostly read-only profile tab. Players cannot fully manage their own profile, password, email, avatar, or verification state from the app, which creates a broken self-service experience.

## What Changes

- Add a complete in-app account settings experience inside the existing authenticated Flutter shell.
- Add client flows for viewing and updating private profile fields, changing password, updating email, resending email verification, and logging out from a consistent account surface.
- Align backend account-management behavior where needed so the app can safely support these flows, including correct private-profile fetch/update wiring, email-change reverification behavior, and clear user-facing validation errors.
- Reuse the existing dashboard/profile navigation instead of creating a separate app or backend service.

## Capabilities

### New Capabilities
- `account-settings-management`: private account settings, security, and verification-management flows for the signed-in user.

### Modified Capabilities
- `game-dashboard-management`: expand the existing profile dashboard tab from summary-centric behavior into a full account-management surface with actionable edit and security entry points.

## Impact

- Affected client code: `client/lib/services/api_service.dart`, `client/lib/providers/auth_provider.dart`, profile/dashboard screens, routing, account form widgets/models, and Flutter tests.
- Affected server code: `server/internal/auth/`, `server/internal/leaderboard/handler.go` if avatar update is reused, related route wiring, and possibly Swagger/API docs if responses or validation contracts need tightening.
- Affected docs and QA: account-management API docs, UX/QA matrices, verification-state behavior, and regression coverage for authenticated dashboard/profile flows.
