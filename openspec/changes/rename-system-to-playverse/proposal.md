## Why

The system has grown beyond a single Caro game into a multi-mini-game platform with social features, a dashboard, friends, leaderboard, and a pluggable game module architecture. The current name "XCaro" reflects only the original game and no longer describes what the product is. "PlayVerse" communicates the full scope — a small universe of games you can play — and works across languages without translation.

## What Changes

- Display name changed from "XCaro" to "PlayVerse" in every user-visible surface: Flutter app title, window title, navigation bar, onboarding/auth screens, web manifest, iOS/macOS bundle display name, email subject lines, Swagger API docs, server README.
- Flutter package name updated in `pubspec.yaml` from `xcaro` to `playverse`.
- **BREAKING**: Go module path updated from `github.com/duvu/xcaro/server` to `github.com/duvu/playverse/server` and all import paths updated throughout the server codebase.
- Android `applicationId` and `namespace` updated from `vn.x51.game2d.xcaro` to `vn.x51.game2d.playverse`.
- iOS/macOS bundle identifier updated from `com.example.xcaro` / `vn.x51.game2d.xcaro` to `vn.x51.game2d.playverse`.
- Web manifest `name` and `short_name` updated.
- Linux/Windows/macOS `CMakeLists.txt` and Xcode config `PRODUCT_NAME` / `PRODUCT_BUNDLE_IDENTIFIER` updated.
- Kotlin entry-point package updated from `com.example.xcaro` to `com.example.playverse`.
- Server email subject lines updated (`Verify your PlayVerse email`).
- Internal code comments/doc comments updated (`Brand colour palette for XCaro` → `PlayVerse`).
- `README.md`, `CONTRIBUTING.md`, `docs/` files updated for the new name.
- OpenSpec change descriptions and existing change artifacts that mention "XCaro" updated for the new name.
- `server/docker-compose.yml` and env references updated.
- Swagger/OpenAPI `title` and `contact.email` updated.

## Capabilities

### New Capabilities

- `system-rename`: Rename all user-visible strings, package identifiers, module paths, and project-file references from XCaro/xcaro to PlayVerse/playverse across the entire monorepo.

### Modified Capabilities

_(None — this is a pure rename; no spec-level behavioral requirements change.)_

## Impact

**Flutter client:**
- `client/pubspec.yaml` — package name
- `client/lib/main.dart` — `title: 'XCaro'`, window/app title strings
- `client/lib/screens/main_scaffold.dart` — nav bar title
- `client/lib/screens/register_screen.dart`, `login_screen.dart`, `game_screen.dart`, `leaderboard_screen.dart`, `history_screen.dart`, `create_room_screen.dart` — any hard-coded brand strings
- `client/lib/theme/app_colors.dart`, `app_text_styles.dart`, `app_theme.dart` — doc comments
- `client/lib/models/game_catalog.dart` — any brand string
- `client/lib/config/app_config.dart` — any brand string
- `client/android/app/build.gradle` — `applicationId`, `namespace`
- `client/android/app/src/main/AndroidManifest.xml` — app label
- `client/android/app/src/main/kotlin/com/example/xcaro/MainActivity.kt` — package declaration (rename file to `com/example/playverse/`)
- `client/ios/Runner/Info.plist` — `CFBundleDisplayName`, `CFBundleName`
- `client/ios/Runner.xcodeproj/project.pbxproj` — bundle identifiers
- `client/macos/Runner/Configs/AppInfo.xcconfig` — `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`
- `client/macos/Runner.xcodeproj/project.pbxproj` — bundle identifiers
- `client/macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` — scheme name if present
- `client/linux/CMakeLists.txt` — `APPLICATION_ID`, project name
- `client/windows/CMakeLists.txt` — project/binary name
- `client/windows/runner/main.cpp`, `Runner.rc` — window title / version strings
- `client/web/manifest.json` — `name`, `short_name`
- `client/test/*.dart` — any hard-coded brand strings

**Go server:**
- `server/go.mod` — module path `github.com/duvu/xcaro/server` → `github.com/duvu/playverse/server`
- All `*.go` files under `server/` — import path prefix updates (can be done with `find`/`sed` or `go mod edit`)
- `server/internal/email/service.go` — email subject line
- `server/docs/swagger.json`, `server/docs/swagger.yaml`, `server/docs/docs.go` — API title, contact email
- `server/docker-compose.yml` — service name / container name if xcaro-named
- `server/README.md` — title

**Docs / project root:**
- `README.md`, `CONTRIBUTING.md`, `GAME_RULES.md`, `DOCUMENTATION.md`, `publishing.md`
- `docs/api.md`, `docs/architecture.md`, `docs/ROADMAP.md`, `docs/qa-matrix.md`, `docs/release-readiness.md`, `docs/WEBSOCKET_INTEGRATION.md`
- `store/app-store.md`, `store/play-store.md`
- `openspec/changes/*/proposal.md`, `design.md`, `specs/*/spec.md` — brand references in prose

**No behavioral changes:** No API contracts, WebSocket protocol, database schemas, or game logic change.
