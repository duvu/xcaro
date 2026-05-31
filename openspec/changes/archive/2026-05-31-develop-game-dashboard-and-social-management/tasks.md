## 1. Architecture And API Contract

- [x] 1.1 Document the dashboard/social modular-monolith decision in architecture docs, including future extraction criteria and forbidden WebSocket hub coupling.
- [x] 1.2 Define dashboard/social REST API contracts for dashboard summary, history filters, player discovery, friend requests, friendships, and friend removal.
- [x] 1.3 Register authenticated dashboard/social route groups in the existing Go server without adding a new deployable service.

## 2. Server Social Data Model

- [x] 2.1 Add MongoDB models/collections for friend requests and friendships with requester, recipient, normalized user pair, status, and timestamps.
- [x] 2.2 Add indexes for pending request lookup, user friend lists, and unique normalized friendship/request pairs.
- [x] 2.3 Implement repository methods for create request, update request status, list incoming/outgoing requests, list friends, and remove friendship.

## 3. Server Friend And Discovery APIs

- [x] 3.1 Implement privacy-safe player discovery by username/public profile fields without exposing private user data.
- [x] 3.2 Implement send/cancel/accept/reject friend request endpoints with self-request, duplicate pending request, and duplicate friendship prevention.
- [x] 3.3 Implement friend list and remove-friend endpoints with ownership checks.
- [x] 3.4 Return machine-readable validation and authorization errors for friend lifecycle failures.

## 4. Server Dashboard And History APIs

- [x] 4.1 Implement or align an authenticated dashboard summary endpoint that returns profile summary, stats/rank, recent games, and friend/request counts.
- [x] 4.2 Add history filtering/pagination support for own games by result, opponent, and date range while preserving ownership/privacy checks.
- [x] 4.3 Add profile update/read behavior needed by the dashboard and ensure users cannot update another user's profile.

## 5. Flutter Dashboard Integration

- [x] 5.1 Add API service methods for dashboard summary, history filters, player discovery, friend requests, friend lists, and friend removal.
- [x] 5.2 Add client models/providers for dashboard summary and friend request/friendship state.
- [x] 5.3 Extend the existing `MainScaffold` dashboard shell with friend/social entry points without replacing existing Home/History/Leaderboard/Profile routes.
- [x] 5.4 Update history UI to support filters, pagination, loading, empty, and actionable error states.
- [x] 5.5 Update profile/opponent profile UI to show friendship status and allowed friend actions.
- [x] 5.6 Add friend discovery, incoming/outgoing requests, and friends list screens or widgets.

## 6. Friend Game Integration

- [x] 6.1 Surface friend status and optional room invite entry points from profile/friends UI without direct client coupling to WebSocket hub internals.
- [x] 6.2 Ensure friend/dashboard features continue to work when room invite or online presence integration is unavailable.

## 7. Documentation And QA

- [x] 7.1 Update API documentation with dashboard/social endpoints, request/response examples, and error codes.
- [x] 7.2 Update QA matrix with registration/login, dashboard summary, history filters, profile update, friend request lifecycle, authorization failures, and duplicate/self-request cases.
- [x] 7.3 Add server tests for friend repository/service/handler flows, authorization failures, duplicate prevention, and dashboard/history privacy.
- [x] 7.4 Add Flutter tests for dashboard provider state, history filter UI, friend request UI states, and profile friendship actions.
- [x] 7.5 Run `go test ./...`, `flutter analyze`, and `flutter test`; record any unrelated pre-existing failures separately.
