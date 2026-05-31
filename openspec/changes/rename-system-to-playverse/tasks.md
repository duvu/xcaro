## 1. Go Server Module Rename

- [x] 1.1 Run `go mod edit -module github.com/duvu/playverse/server` in `server/` to update `go.mod` module declaration
- [x] 1.2 Replace all import path prefixes in `server/**/*.go` from `github.com/duvu/xcaro/server` to `github.com/duvu/playverse/server` (use `find`/`sed` or `gofmt -r`)
- [x] 1.3 Run `go build ./...` from `server/` to confirm zero build errors after module rename
- [x] 1.4 Run `go test ./...` from `server/` to confirm all tests still pass

## 2. Server Display Strings And API Docs

- [x] 2.1 Update email subject in `server/internal/email/service.go` from "XCaro" to "PlayVerse"
- [x] 2.2 Update Swagger title to "PlayVerse API" and contact email in `server/docs/swagger.json`
- [x] 2.3 Update `server/docs/swagger.yaml` title and contact email to match
- [x] 2.4 Update `server/docs/docs.go` inline swagger JSON string to match (title, contact email)
- [x] 2.5 Update `server/docker-compose.yml` service/container names if they reference "xcaro"
- [x] 2.6 Update `server/README.md` title and any prose references from XCaro to PlayVerse

## 3. Flutter Package Name And Display Strings

- [x] 3.1 Update `client/pubspec.yaml` `name:` from `xcaro` to `playverse`
- [x] 3.2 Update `client/lib/main.dart` — change `title: 'XCaro'` to `title: 'PlayVerse'` and any other hard-coded "XCaro" strings
- [x] 3.3 Update `client/lib/screens/main_scaffold.dart` — change navigation bar "XCaro" text to "PlayVerse"
- [x] 3.4 Update doc comments in `client/lib/theme/app_colors.dart`, `app_text_styles.dart`, `app_theme.dart` from "XCaro" to "PlayVerse"
- [x] 3.5 Update any remaining "XCaro" strings in `client/lib/screens/` files (register, login, game, leaderboard, history, create_room, etc.) and `client/lib/config/app_config.dart`, `client/lib/models/game_catalog.dart`
- [x] 3.6 Update any "XCaro" references in `client/test/*.dart` test files

## 4. Android Platform Files

- [x] 4.1 Update `applicationId` and `namespace` in `client/android/app/build.gradle` to `vn.x51.game2d.playverse`
- [x] 4.2 Update app label in `client/android/app/src/main/AndroidManifest.xml` to "PlayVerse"
- [x] 4.3 Move Kotlin source from `client/android/app/src/main/kotlin/com/example/xcaro/` to `client/android/app/src/main/kotlin/com/example/playverse/` and update `package com.example.xcaro` declaration in `MainActivity.kt` to `package com.example.playverse`

## 5. iOS And macOS Platform Files

- [x] 5.1 Update `client/ios/Runner/Info.plist` — set `CFBundleDisplayName` to "PlayVerse" and `CFBundleName` to "playverse"
- [x] 5.2 Update bundle identifiers in `client/ios/Runner.xcodeproj/project.pbxproj` from `com.example.xcaro` / `vn.x51.game2d.xcaro` to `vn.x51.game2d.playverse`
- [x] 5.3 Update `client/macos/Runner/Configs/AppInfo.xcconfig` — set `PRODUCT_NAME = PlayVerse` and `PRODUCT_BUNDLE_IDENTIFIER = vn.x51.game2d.playverse`
- [x] 5.4 Update bundle identifiers in `client/macos/Runner.xcodeproj/project.pbxproj` to `vn.x51.game2d.playverse`
- [x] 5.5 Update `client/macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` if it references "xcaro"

## 6. Linux, Windows, And Web Platform Files

- [x] 6.1 Update `client/linux/CMakeLists.txt` — `APPLICATION_ID` to `vn.x51.game2d.playverse` and project name to `playverse`
- [x] 6.2 Update `client/linux/my_application.cc` — any hard-coded "xcaro" window title strings
- [x] 6.3 Update `client/windows/CMakeLists.txt` — project name and binary name to `playverse`
- [x] 6.4 Update `client/windows/runner/main.cpp` and `Runner.rc` — window title / version resource strings from "xcaro" to "PlayVerse"
- [x] 6.5 Update `client/web/manifest.json` — `name` and `short_name` to "PlayVerse"

## 7. Project Docs, README, And Store Listings

- [x] 7.1 Update `README.md` top-level heading and description to "PlayVerse"
- [x] 7.2 Update `CONTRIBUTING.md`, `GAME_RULES.md`, `DOCUMENTATION.md`, `publishing.md` — replace "XCaro" with "PlayVerse"
- [x] 7.3 Update `docs/api.md`, `docs/architecture.md`, `docs/ROADMAP.md`, `docs/qa-matrix.md`, `docs/release-readiness.md`, `docs/WEBSOCKET_INTEGRATION.md` — replace product name references
- [x] 7.4 Update `store/app-store.md`, `store/play-store.md` — product name and bundle ID references
- [x] 7.5 Update prose references in existing OpenSpec change artifacts (`openspec/changes/*/proposal.md`, `design.md`, `specs/*/spec.md`) that mention "XCaro" as product name

## 8. Verification

- [x] 8.1 Run `go build ./...` and `go test ./...` from `server/` — expect clean build and all tests pass
- [x] 8.2 Run `flutter pub get` and `flutter analyze` from `client/` — expect no errors
- [x] 8.3 Run `flutter test` from `client/` — expect all tests pass
- [x] 8.4 Confirm `rg -r "xcaro\|XCaro" --glob "*.go" --glob "*.dart" --glob "*.yaml" --glob "*.json" --glob "*.md" --glob "*.gradle" --glob "*.plist" --glob "*.xcconfig" client/ server/` returns zero matches (excluding this OpenSpec change directory)
