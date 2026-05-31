# PlayVerse Product Roadmap

This roadmap is a working reference for implementing PlayVerse gradually after the MVP foundation. Keep each phase small enough to review, test, and release independently.

## Current State — Updated 2026-05-30

### ✅ Shipped (MVP1 + MVP2 + project-docs-assets)

- JWT authentication with refresh tokens and persistent sessions
- Online multiplayer rooms over WebSocket (room codes, move sync, win/draw/resign/forfeit)
- AI opponent mode (easy/medium/hard, Dart Isolate)
- Game history and paginated statistics
- Elo leaderboard with Redis 5-min TTL cache
- In-game chat
- Email verification with resend
- Redis caching and rate limiting (auth 5/min/IP, game 60/min/user)
- Opponent profiles and personal rank
- Multi-difficulty AI (depth 1/3/5 with time-bounded hard mode)
- App icons, splash screen, SVG game assets
- Documentation: architecture, API reference, game rules, contribution guide
- Store listing drafts (Play Store + App Store)
- CI/CD GitHub Actions: PR check (go vet/test + flutter analyze/test) and deploy workflow (GHCR + SSH)
- PR #1 open: https://github.com/duvu/playverse/pull/1

### ✅ Phase 1: Stabilization and Release Readiness — COMPLETE

OpenSpec change: `phase-1-stabilization-release-readiness` (34/34 tasks)

- `go build ./...`, `go vet ./...`, `go test ./...` — all pass
- `flutter analyze` — 0 issues after `dart fix --apply` + manual fixes
- `flutter test` — all pass
- Android release APK built (22.8 MB, JAVA_HOME=java-21)
- Docker Compose + local server smoke tests pass (MongoDB, Redis, health, auth, leaderboard, protected endpoints, Redis degradation)
- `docs/release-readiness.md` — gate checklist with pass/fail evidence
- `docs/RELEASE_EVIDENCE.md` — full verification log
- `docs/qa-matrix.md` — E2E QA matrix (automated pass; real-device flows blocked pending emulator/SMTP setup)
- Fixed: WS hub broadcast deadlock (JoinRoom/LeaveRoom), bson keyed literals, hub test drain helper
- Android Gradle upgraded: Gradle 8.10.2 / AGP 8.7.0 / Kotlin 1.8.22 / Java 11 target
- `.gitignore` updated: `.omo/`, `.serena/`, `client/build/`, `client/android/app/.cxx/`
- **Go/no-go:** ready for internal review and staging; not yet public beta (pending: package ID ownership, release signing key, SMTP, deploy host, real-device E2E)

Reference checklist: [`docs/release-readiness.md`](release-readiness.md).

## Phase 1: Stabilization and Release Readiness — ✅ COMPLETE

See **Current State** section above.

## Phase 2: Public Beta — ✅ COMPLETE

**Goal:** let real users play and expose UX, device, and network issues.

OpenSpec change: `phase-2-public-beta` (52/52 tasks)

### Scope

- [x] Quick match queue (server: in-process hub queue, WS events `quick_match_request/found/cancelled/timeout`)
- [x] Structured backend logs (`log/slog` JSON in release, text in dev — auth, WS, hub, client)
- [x] Operational metrics (`internal/metrics`, atomic counters, `GET /admin/metrics`)
- [x] Player report endpoint (`POST /api/reports`, 3/hr per user, MongoDB `reports` collection)
- [x] Crash/error tracking endpoint (`POST /api/errors`, 10/hr per IP, MongoDB `error_reports` collection)
- [x] Quick match waiting screen (Flutter — `QuickMatchWaitingScreen`, 60s timeout, cancel)
- [x] Room invite sharing with `share_plus` (deep-link `playverse://room/<code>`)
- [x] Polished empty states and error states (`EmptyStateWidget`, `ErrorStateWidget` — leaderboard, home screen)
- [x] WS connection status chip on home screen (StreamBuilder on `isConnectedStream`)
- [x] Improved disconnect/resign/forfeit messaging (`game_over` result field mapped to Vietnamese strings)
- [x] Mute chat toggle (client-side, session-scoped, `GameProvider.toggleChatMute()`)
- [x] Player report dialog in game screen (PopupMenuButton → AlertDialog → `POST /api/reports`)
- [x] Flutter crash/error observer in `main.dart` (`FlutterError.onError`, `runZonedGuarded`, `PlatformDispatcher.onError`)

### Exit Criteria

- 20–50 beta users can play online matches.
- Critical crash and network issues are identified and fixed.
- Backend logs are sufficient to debug production incidents.

## Phase 3: Engagement and Retention

**Goal:** give players reasons to return after the first few games.

### Scope

- Add weekly and monthly leaderboards.
- Add season reset and season winner history.
- Add win streak tracking.
- Add badges or achievements.
- Add player level based on games played and wins.
- Add game replay from stored move history.
- Add replay controls: step forward, step backward, autoplay, and jump to winning line.
- Add replay sharing by link or code.
- Add friend requests.
- Add friend invite to room.
- Add friend online status.

### Exit Criteria

- Players have visible progression.
- Leaderboard is meaningful beyond all-time Elo.
- Game history is useful for review, learning, and sharing.

## Phase 4: Competitive Mode

**Goal:** make online play fair enough for regular competitive use.

### Scope

- Add ranked and unranked queues.
- Match ranked players by Elo band.
- Add queue timeout fallback.
- Add provisional rating for new players.
- Add placement games.
- Separate ranked, casual, AI, and offline statistics.
- Add cooldowns for repeated resigns or disconnects.
- Add stricter per-room chat rate limits.
- Log suspicious behavior for moderation review.
- Add tournament brackets.
- Add scheduled tournament matches.
- Add tournament leaderboard.

### Exit Criteria

- Ranked matchmaking feels fair for normal play.
- Common abuse patterns have basic controls.
- Tournament mode can support small community events.

## Phase 5: Product Polish and Monetization Optionality

**Goal:** prepare PlayVerse as a polished consumer app without compromising fair play.

### Scope

- Add board themes.
- Add stone skins.
- Add sound pack options.
- Add haptic feedback.
- Add Vietnamese and English localization.
- Consider Korean and Japanese localization later.
- Add avatar upload.
- Add display name changes.
- Add profile banners or themes.
- Add cosmetic-only premium themes or packs if monetization is needed.

### Exit Criteria

- Store presentation feels polished.
- User profile and board customization improve identity and retention.
- Any monetization remains cosmetic-only and does not affect gameplay fairness.

## Suggested Implementation Order

1. Finish Phase 1 before adding new features.
2. Build Phase 2 as small, independently reviewable changes.
3. Prioritize observability before expanding the beta audience.
4. Add retention features only after core online play is stable.
5. Add ranked/tournament systems after enough real gameplay data exists.
6. Add monetization last, and keep it cosmetic-only.

## Roadmap Maintenance

- Update this file after each released phase.
- Move completed work into release notes or changelog entries.
- Keep future phases flexible based on player feedback and production data.
- Prefer small OpenSpec changes for each roadmap item instead of one large change.
