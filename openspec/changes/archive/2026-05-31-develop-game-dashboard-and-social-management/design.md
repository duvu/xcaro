## Context

PlayVerse is a Flutter client plus Go Gin/MongoDB/Redis backend. The current product already includes JWT auth, registration/login, email verification, profile data, game records/history/stats, leaderboard, online WebSocket play, chat, and opponent profiles. The Flutter app already has a lightweight dashboard shell through `MainScaffold` with Home, History, Leaderboard, and Profile tabs, but social/friend management is not implemented and history/profile management is not presented as a cohesive dashboard capability.

The roadmap's Phase 3 engagement work explicitly calls for richer history, progression, friend requests, friend invites to rooms, and friend online status. This change should build on existing server ownership of users and game records rather than introducing a new backend service prematurely.

## Goals / Non-Goals

**Goals:**
- Provide a cohesive player dashboard in the existing Flutter app for account entry, profile summary, game history/statistics, leaderboard shortcuts, and social/friend actions.
- Add authenticated backend APIs for friend discovery, friend request lifecycle, friend lists, and friendship removal.
- Improve history management from dashboard/profile contexts with filters, loading/empty/error states, and stable pagination over existing game records.
- Keep dashboard/social management in the current Go server deployable with explicit module and route boundaries.
- Define future extraction criteria so dashboard/social code can become a separate service only when product or operational pressure justifies it.

**Non-Goals:**
- No separate dashboard backend service in the initial implementation.
- No separate database or cross-service event bus for friends/history.
- No tournament/clan/guild system, feed, direct messaging, or full moderation console.
- No replacement of the existing Flutter Provider architecture or existing auth token model.
- No direct coupling from dashboard REST APIs into WebSocket gameplay internals; room invites/presence must use explicit interfaces.

## Decisions

### Keep dashboard/social backend in the game server deployable

Use the existing Go server for dashboard and social management. The server already owns auth, profile, game records, leaderboard, and online gameplay identity. Splitting now would introduce duplicated auth propagation, shared database ownership concerns, deployment overhead, and consistency risks without a clear scaling or team-boundary payoff.

Alternative considered: create a separate dashboard/management service immediately. Rejected for initial scope because the feature is primarily another API/client surface over data already owned by the game server.

### Use modular monolith boundaries

Add a bounded `friends` or `social` server module with handler/service/repository layers and route group `/api/friends` (or `/api/social/friends`). Keep it independent from `internal/ws` except through narrow interfaces for optional presence or room invite metadata. Reuse auth middleware for identity and ownership checks.

Alternative considered: add friend methods directly into auth or game handlers. Rejected because it would blur account, social, and gameplay responsibilities and make later extraction harder.

### Store friend requests and friendships explicitly

Use MongoDB collections such as `friend_requests` and `friendships` with indexes for requester/recipient/status and unique normalized user pairs. Store request status (`pending`, `accepted`, `rejected`, `cancelled`) and timestamps. Enforce self-request and duplicate relationship prevention at both service and index layers.

Alternative considered: embed friends directly on user documents. Rejected because request lifecycle, pagination, and uniqueness constraints become harder as social data grows.

### Extend the existing Flutter dashboard shell

Use the existing authenticated `MainScaffold` as the dashboard foundation. Add dashboard/social widgets/screens/providers instead of creating a separate Flutter app. History/profile views should remain reachable as tabs and gain friend-related actions where relevant.

Alternative considered: separate management dashboard app. Rejected for player-facing dashboard scope; a separate admin-only web console can be revisited later if admin workflows diverge.

### Preserve REST/WS separation

Friend request and dashboard management operations should use authenticated REST APIs. WebSocket gameplay remains for room/game state. Friend room invites or online status can consume read-only presence/invite interfaces but must not require dashboard code to mutate hub state directly.

## Risks / Trade-offs

- Modular monolith can become tangled → enforce package boundaries, route groups, service interfaces, and tests that do not import `internal/ws` directly from friends code.
- Friend duplicate/race conditions → enforce unique normalized pair indexes and handle duplicate-key errors as idempotent user-facing responses.
- Privacy leaks in discovery/profile views → return minimal public profile fields and require ownership/friendship checks for private history details.
- Dashboard query load could grow → add indexes for game records and friend collections, paginate all list endpoints, and cache only read-heavy summaries if needed.
- Future extraction may be harder if boundaries are not documented → add architecture docs and extraction criteria as implementation deliverables.

## Migration Plan

1. Add social/friends data model and indexes with backward-compatible migrations or startup index creation.
2. Add server APIs behind existing JWT auth middleware; keep all new endpoints additive.
3. Add Flutter service/provider methods and dashboard/friend screens behind existing authenticated navigation.
4. Update docs and QA matrix for dashboard/social flows and architecture decision.
5. Roll out without a deployable split. Rollback is disabling/hiding new dashboard/friend routes/screens while leaving existing gameplay/auth/history intact.

## Open Questions

- Should friend discovery be exact-username only for the first release, or include fuzzy search/autocomplete?
- Should users be able to hide their online status or game history from non-friends?
- Should friend invites to rooms be in the initial implementation or a follow-up after basic friendships ship?
- What admin/moderator actions are required for abuse handling beyond existing reports and bans?
