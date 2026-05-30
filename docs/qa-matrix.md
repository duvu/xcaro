# XCaro Phase 1 QA Matrix

Execution date: 2026-05-30

## Environment

- Server smoke: local Go server against Docker Compose MongoDB and Redis.
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
| Online rooms | Create room and join with two verified users. | Blocked | Requires two app clients or WebSocket E2E harness plus verified users. |
| Online gameplay | Make alternating moves and finish win/draw. | Blocked | Requires two app clients or WebSocket E2E harness. |
| Resign/disconnect | Resign, disconnect grace/forfeit, room cleanup, client messaging. | Blocked | Requires WebSocket E2E harness or two app clients. |
| Chat | Valid message broadcast. | Blocked | Requires online room E2E. |
| Chat | Empty and over-limit messages rejected safely. | Blocked | Requires online room E2E. |
| Leaderboard | Public leaderboard endpoint loads. | Pass | `GET /api/leaderboard` returned `200` with Redis available and unavailable. |
| History/stats | Protected game endpoints require auth. | Pass | `GET /api/games` without token returned `401`. |
| AI Easy/Medium/Hard | AI engine returns valid moves. | Pass | `flutter test` includes Medium and Hard move tests; Easy covered by provider path through analyzer/build, but should be manually checked on device. |
| Theme | Dark/light toggle persists. | Blocked | Requires Flutter app runtime and shared preferences. |
| Sound | Sound toggle and move/win sounds. | Blocked | Requires Flutter app runtime with audio backend. |
| Content/docs | Rules, architecture, API, roadmap, store docs exist. | Pass | Markdown docs present under root `docs/` and `store/`. |
| Android artifact | Release APK builds. | Pass | `client/build/app/outputs/flutter-apk/app-release.apk` built successfully with JDK 21. |

## Required Follow-up Before Public Beta

1. Run this matrix on a real Android device or emulator with two test accounts.
2. Provide SMTP sandbox credentials and validate email verification/resend end-to-end.
3. Add an automated WebSocket E2E harness for room, move, chat, resign, and disconnect flows.
4. Confirm production Android application ID and release signing material.
