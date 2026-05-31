## Context

PlayVerse already supports authenticated account APIs on the Go backend: registration, login, logout, refresh, private profile read/update, password change, email change, email verification, and verification resend. The Flutter app only exposes registration, login, logout, and a read-oriented profile tab that reuses the public opponent-profile screen for the signed-in user.

Current client/server constraints discovered from the codebase:
- The authenticated shell already has a dedicated profile tab in `MainScaffold`, so account management should stay inside the existing app shell.
- `AuthProvider` already owns session bootstrap, refresh-token storage, and logout flow, so account-management UI should reuse it rather than introducing a second auth state source.
- The backend profile update contract already supports `full_name`, `avatar`, `date_of_birth`, `phone_number`, and `bio`.
- The backend also exposes `PUT /profile/password`, `PUT /profile/email`, `POST /auth/resend-verification`, and `PUT /users/avatar`.
- Current backend email-update behavior changes the email but does not reset verification state or trigger a new verification email, so “full” in-app account management needs backend alignment as well as Flutter UI work.

## Goals / Non-Goals

**Goals:**
- Add a private account-management surface for the signed-in user inside the existing Flutter dashboard/profile experience.
- Let users edit their own profile fields in app and immediately see refreshed account state.
- Let users change password and update email from in-app security flows with clear validation and success/error feedback.
- Show email-verification state in the account UI and support resend-verification from the same surface.
- Provide a consistent logout action from the account/settings area instead of scattering it across unrelated screens.
- Align backend behavior where needed so account-management flows are secure and coherent for the app UI.

**Non-Goals:**
- Account deletion or GDPR/export workflows.
- Admin user-management tools.
- Binary avatar upload/storage infrastructure; avatar management remains URL-based in this change.
- Redesigning public opponent-profile behavior beyond what is needed to separate private account management from public profile viewing.

## Decisions

### 1. Use a dedicated private account-management surface instead of reusing the public opponent-profile screen
The current profile tab points at `OpponentProfileScreen`, which is primarily a public viewer with social actions. The signed-in user needs private fields, verification state, password/email actions, and logout controls that do not belong in a public-profile viewer.

Decision:
- Keep public player profiles for viewing other users.
- Add a dedicated authenticated account screen (or account/settings flow rooted from the existing profile tab) for the signed-in user.

Alternative considered:
- Extending `OpponentProfileScreen` for both public and private use.
- Rejected because it mixes private account controls with public profile viewing and would complicate authorization-aware UI behavior.

### 2. Reuse existing backend account endpoints, but tighten email-change behavior for in-app correctness
The backend already exposes the core account-management endpoints. Reusing them minimizes scope and keeps the change inside the current modular monolith. However, the current email-update path only swaps the email field and does not force reverification.

Decision:
- Add Flutter API methods and forms on top of the existing `/profile`, `/profile/password`, `/profile/email`, and `/auth/resend-verification` routes.
- Adjust backend email-change behavior so changing email clears `email_verified`, generates a new verification token, and sends a new verification email.

Alternative considered:
- Keep the current backend behavior and treat email change as immediately trusted.
- Rejected because it breaks verification-state UX and weakens account-security expectations.

### 3. Treat avatar as part of profile editing, not a separate media-upload feature
The codebase already supports avatar as a URL field in the user model and profile update request. There is also a dedicated avatar endpoint, but no storage/upload pipeline exists.

Decision:
- Use URL-based avatar editing as part of the private profile form for this change.
- Keep any avatar-only endpoint as optional implementation detail, not the primary UX contract.

Alternative considered:
- Add file picker/upload/storage support now.
- Rejected because it introduces a new media pipeline and is outside the minimum account-management scope.

### 4. Make account UI explicitly show verification and security state
Registration already tells users to verify email, and online flows already surface resend-verification from unrelated screens. Full account management should centralize these states.

Decision:
- Show verification status on the account surface.
- Add explicit resend-verification action there.
- Show email/pending-verification messaging after email changes.

Alternative considered:
- Keep verification actions hidden inside gameplay error states only.
- Rejected because it creates fragmented account UX and poor discoverability.

### 5. Keep AuthProvider as the single source of truth for private account state
`AuthProvider` already owns the current user and session lifecycle. Account mutations should refresh or merge that state rather than introducing a parallel provider that can drift.

Decision:
- Extend client account flows through `ApiService` and `AuthProvider`.
- Refresh `currentUser` after successful profile/email changes so the authenticated shell reflects the latest private account state.

Alternative considered:
- Build account management entirely outside `AuthProvider`.
- Rejected because it risks stale session/user state across tabs.

## Risks / Trade-offs

- **[Backend email-change semantics are incomplete]** → Update the server behavior in the same change so the UI does not present a false “verified” state after email changes.
- **[Current profile-update API behaves like full replace for editable fields]** → Ensure the UI submits a complete account payload from loaded state, or tighten backend update semantics during implementation.
- **[Public and private profile flows can drift]** → Keep public opponent profile viewing and private account settings as separate screens with clearly different responsibilities.
- **[Avatar UX is limited to URL input]** → Document URL-based avatar editing as the supported scope for now and defer uploads to a later change.
- **[Security-sensitive forms need careful validation/error UX]** → Use explicit current-password confirmation, field-level validation, and actionable success/error messages for password/email flows.

## Migration Plan

1. Align backend account semantics first, especially email-change reverification behavior and any response-shape tightening needed by the client.
2. Add client API methods and AuthProvider refresh hooks.
3. Introduce the private account-management UI in the existing authenticated shell.
4. Add/update docs and QA coverage for account-management scenarios.

Rollback strategy:
- Revert the new client account UI routes/surfaces if needed.
- Because this change reuses existing account endpoints, rollback is mostly UI-first unless backend email-change behavior is tightened; in that case, revert the paired server behavior together.

## Open Questions

- Should account settings live directly in the profile tab root, or should the profile tab show a summary page that links to deeper edit/security screens?
- Do we want to keep the dedicated `PUT /users/avatar` route in active client use, or standardize all private profile edits on `PUT /profile`?
- Should a successful password change keep the current session active, or should the product later require re-login across devices as a separate security change?
