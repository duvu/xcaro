# Phase 2: Public Beta

## Why

Phase 1 stabilization validated that the XCaro MVP builds, tests, and deploys cleanly. Phase 2 makes the product usable by real beta users: it removes the friction of manual room codes, gives players richer online context through polished UX states, adds the infrastructure to debug and monitor a live service, and introduces lightweight moderation so beta sessions remain civil.

## What Changes

- Add **quick match queue** so players can be paired automatically without exchanging a room code.
- Add **room invite sharing** so a host can share a deep-link or code directly from the game screen.
- Add **polished empty and error states** across leaderboard, history, profile, and room screens so the app never shows a blank or unhandled error.
- Improve **first-launch tutorial copy** and add clearer instructions for online play and room sharing.
- Improve **room expiry and disconnect messaging** so players see actionable text instead of silent failures.
- Add **mute chat** per game session so players can suppress unwanted messages without leaving.
- Add **basic player report flow** so abuse can be flagged and reviewed by admins.
- Add **structured backend logs** for auth, rooms, games, chat, and leaderboard updates so production incidents can be debugged.
- Track **basic operational metrics**: active rooms, connected WebSocket clients, completed games, and failed logins exposed via a `/api/metrics` endpoint (admin-only).
- Add **Flutter crash and error tracking** via a lightweight error observer that logs to the existing backend or a third-party sink.

## Capabilities

New capabilities created in this change:

- `quick-match-queue` — server-side matchmaking queue + client UI
- `room-invite-share` — share sheet / deep-link for room codes
- `ux-polish` — empty states, error states, tutorial copy, disconnect messages
- `mute-chat` — per-session chat mute toggle
- `player-report` — in-game report flow + admin review endpoint
- `structured-logging` — server-side structured log output for all subsystems
- `operational-metrics` — server-side metrics endpoint + client health awareness
- `crash-error-tracking` — Flutter error observer + uncaught exception reporting

## Impact

- **Server**: new WS event `quick_match_request` / `quick_match_found`; new REST endpoint `POST /api/ws/queue`; new `GET /api/metrics` (admin); structured log output; report endpoint `POST /api/reports`; no breaking changes to existing auth, room, game, or leaderboard APIs.
- **Client**: new `QuickMatchScreen` or home-screen button; share sheet in `CreateRoomScreen`; `MuteProvider` for per-session chat mute; in-game report dialog; onboarding copy updates; empty/error state widgets across all major list screens; error observer in `main.dart`.
- **Dependencies**: server may add `slog` (stdlib Go 1.21+, already available via go 1.23); client adds `share_plus` and possibly `firebase_crashlytics` or a lightweight error sink.
- **No breaking changes** to existing APIs, WS protocol envelope, or database schema. All additions are additive.
