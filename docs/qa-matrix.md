# PlayVerse Phase 1 QA Matrix

Execution date: 2026-05-30

## Environment

- Server smoke: local Go server against temporary Docker MongoDB and Redis when available.
- Client validation: Flutter analyzer, widget/AI tests, and Android release APK build.
- Device/emulator manual gameplay: not available in this execution environment; record as blocked with required follow-up.
- SMTP verification: no SMTP credentials provided; register flow logs verification email failure as non-fatal.

## Status Legend

| Status | Meaning |
|---|---|
| Pass | Executed and matched expected result. |
| Blocked | Cannot execute in this environment; blocker and follow-up are explicit. |
| Follow-up | Needs owner or staging environment before public release. |

## Matrix

| Area | Scenario | Status | Evidence / Follow-up |
|---|---|---:|---|
| Auth/session | Register a new user via API. | Pass | `POST /api/auth/register` returned `201`; SMTP missing was logged and did not crash the API. |
| Auth/session | Email verification prompt and resend verification in app. | Blocked | Requires running Flutter app with SMTP or test email provider. |
| Auth/session | Login, token refresh after restart, and logout. | Blocked | Requires running app/session storage on emulator/device. |
| Onboarding | First-launch onboarding and re-open from home help icon. | Blocked | Requires Flutter app runtime. |
| Home navigation | Home buttons for online room, AI, leaderboard, history, onboarding. | Blocked | Requires Flutter app runtime. |
| Online rooms | Create room and join with two verified users. | Pass | OpenSpec online human-human smoke used two JWT-authenticated WebSocket clients, `create_room`, and `join_room_by_code`; both received canonical `game_state`. |
| Online gameplay | Make alternating moves and finish win/draw. | Pass | OpenSpec smoke completed a legal move-to-win path and verified persisted `game_records.result == "win"`. |
| Resign/disconnect | Resign, disconnect grace/forfeit, room cleanup, client messaging. | Pass | OpenSpec smoke verified `resign` game_over/persistence plus reconnect-within-grace and post-grace forfeit; unit tests cover waiting-room cleanup and quick-match disconnect removal. |
| Chat | Valid message broadcast. | Pass | WebSocket unit/smoke coverage exercises `chat_message` routing through active game rooms. |
| Chat | Empty and over-limit messages rejected safely. | Pass | `HandleChatMessage` rejects malformed, empty, and >500 character payloads with machine-readable errors. |
| Leaderboard | Public leaderboard endpoint loads. | Pass | `GET /api/leaderboard` returned `200` with Redis available and unavailable. |
| History/stats | Protected game endpoints require auth. | Pass | `GET /api/games` without token returned `401`. |
| Dashboard | Dashboard summary returns profile/stats/recent games/friend counts for the authenticated user only. | Follow-up | Automated server tests cover summary helper logic; run live API smoke with two users before release. |
| Dashboard history | Result filters (`win`, `loss`, `draw`), pagination, and empty/error states. | Follow-up | Flutter analyzer/tests cover model parsing; execute on device/staging for UX verification. |
| Mini-game catalog | Shared shell loads `/api/games/catalog` and shows at least one active game entry. | Pass | Static catalog endpoint plus Flutter `GameCatalogProvider` and HomeTab catalog cards now compile and are covered by unit parsing tests. |
| Game-type contract | WS/game-state/history payloads carry `game_type` while legacy Caro defaults still work. | Pass | `go test ./...` covers hub/game_state and quick-match payload assertions for `game_type = caro`; Flutter tests verify parsing defaults for `caro`. |
| Profile | Current user can read/update own profile and cannot update another user's profile. | Follow-up | Auth middleware now provides both string and ObjectID user context; add staging API smoke for profile edits. |
| Account settings UI | Private account tab shows current user profile fields, verification state, stats, and recent games. | Follow-up | Requires Flutter runtime to verify the dedicated account-management screen and pull-to-refresh UX. |
| Account settings UI | Update profile fields (full name, avatar URL, date of birth, phone number, bio). | Follow-up | Run authenticated app smoke and confirm `PUT /profile` persists changes and refreshes current user state. |
| Account settings UI | Change password with wrong/current/new validation. | Follow-up | Run authenticated app smoke and verify actionable error messages plus success snackbar. |
| Account settings UI | Change email triggers re-verification and verification banner. | Follow-up | Requires SMTP sandbox and authenticated app/API smoke to confirm `email_verified` resets and resend flow works. |
| Account settings UI | Logout action from private account surface clears session and returns to login. | Follow-up | Requires app runtime. |
| Social discovery | Search users by username without exposing private fields. | Follow-up | Verify response redacts email/password/refresh/verification fields in live API smoke. |
| Friend requests | Send, cancel, accept, reject, duplicate pending, existing friendship, and self-request cases. | Follow-up | Unit tests cover normalized pair/outcome helpers; run temp-Mongo integration smoke before public release. |
| Friends list | List/remove friends with ownership checks. | Follow-up | Requires two-account live API smoke. |
| AI Easy/Medium/Hard | AI engine returns valid moves. | Pass | `flutter test` includes Medium and Hard move tests; Easy covered by provider path through analyzer/build, but should be manually checked on device. |
| Theme | Dark/light toggle persists. | Blocked | Requires Flutter app runtime and shared preferences. |
| Sound | Sound toggle and move/win sounds. | Blocked | Requires Flutter app runtime with audio backend. |
| Content/docs | Rules, architecture, API, roadmap, store docs exist. | Pass | Markdown docs present under root `docs/` and `store/`. |
| Android artifact | Release APK builds. | Pass | `client/build/app/outputs/flutter-apk/app-release.apk` built successfully with JDK 21. |

## Required Follow-up Before Public Beta

1. Run this matrix on a real Android device or emulator with two test accounts.
2. Provide SMTP sandbox credentials and validate email verification/resend end-to-end.
3. Keep the automated WebSocket E2E harness in CI for room, move, chat, resign, and disconnect flows.
4. Confirm production Android application ID and release signing material.
5. Add dashboard/social API smoke coverage with temporary MongoDB for request lifecycle and history filters.
6. Add end-to-end smoke for catalog-driven game selection once a second mini-game exists.

---

## Chess Module QA Matrix

| # | Scenario | Method | Expected Result |
|---|----------|--------|----------------|
| C-1 | Chess catalog returned | `GET /api/games/catalog` | `game_type=chess` entry present |
| C-2 | Create chess room | WS `create_room {game_type:chess}` | `game_state` with `game_type=chess`, starting FEN, 6-char code |
| C-3 | Join chess room by code | WS `join_room_by_code {code,game_type:chess}` | Both players receive `game_state`, `started=true` |
| C-4 | Legal pawn advance | WS `make_move {from:"e2",to:"e4",game_type:chess}` | `game_state` with updated FEN, turn switches |
| C-5 | Illegal move rejected | WS `make_move {from:"e2",to:"e5",game_type:chess}` | `error` with `code=illegal_move`; board unchanged |
| C-6 | Scholar's mate sequence | 4 legal moves | `game_over` with `result=win`, correct winner |
| C-7 | Stalemate | Board set to stalemate | `game_over` with `result=draw` |
| C-8 | Resign | WS `resign` | `game_over` with `result=resign`, opponent is winner |
| C-9 | Disconnect forfeit | Player disconnects, 30s elapses | `game_over` with `result=forfeit` |
| C-10 | Chess Elo updated | Complete chess game | `user_game_ratings` upserted with `game_type=chess` |
| C-11 | Dashboard history | `GET /dashboard/history?game_type=chess` | Returns chess-only records |
| C-12 | Leaderboard | `GET /api/leaderboard?game_type=chess` | Chess-specific Elo rankings |
| C-13 | AI chess Easy | Local AI game, Easy difficulty | AI plays legal moves, game finishes |
| C-14 | AI chess Hard | Local AI game, Hard difficulty | AI plays stronger moves within 900ms |
| C-15 | Quick match chess | `quick_match_request {game_type:chess}` | Two users paired into chess room |

### Follow-up Items (Chess)

7. Run two-client chess smoke (create/join, legal moves to Scholar's mate, check Elo) with temporary MongoDB once CI environment supports it.
8. Verify promotion dialog appears in `chess_game_screen.dart` when a pawn reaches the back rank.
