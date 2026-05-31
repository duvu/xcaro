## ADDED Requirements

### Requirement: Flutter Display Name

The Flutter application SHALL display "PlayVerse" as the app title in every user-visible surface: MaterialApp title, window title, AppBar/NavigationBar labels, onboarding and auth screens.

#### Scenario: App title in OS task switcher

- **WHEN** a user views the app in the device task switcher or recent apps list
- **THEN** the app is shown as "PlayVerse"

#### Scenario: In-app navigation bar title

- **WHEN** a user is on the main scaffold
- **THEN** the navigation bar or AppBar shows "PlayVerse", not "XCaro"

---

### Requirement: Flutter Package Name

The Flutter `pubspec.yaml` package name SHALL be `playverse`.

#### Scenario: pubspec.yaml name field

- **WHEN** `client/pubspec.yaml` is read
- **THEN** `name: playverse` is present and `name: xcaro` does not exist

---

### Requirement: Android Application Identifier

The Android `applicationId` and `namespace` in `client/android/app/build.gradle` SHALL be `vn.x51.game2d.playverse`. The `AndroidManifest.xml` app label SHALL be "PlayVerse". The Kotlin source tree SHALL be moved from `com/example/xcaro/` to `com/example/playverse/` with the package declaration updated.

#### Scenario: Gradle applicationId

- **WHEN** `client/android/app/build.gradle` is read
- **THEN** `applicationId "vn.x51.game2d.playverse"` and `namespace "vn.x51.game2d.playverse"` are present

#### Scenario: MainActivity package declaration

- **WHEN** `client/android/app/src/main/kotlin/com/example/playverse/MainActivity.kt` is read
- **THEN** the file contains `package com.example.playverse` and no reference to `com.example.xcaro`

---

### Requirement: iOS And macOS Bundle Identifier

The iOS and macOS bundle identifier SHALL be `vn.x51.game2d.playverse`. `CFBundleDisplayName` SHALL be "PlayVerse" and `CFBundleName` SHALL be "playverse".

#### Scenario: iOS Info.plist display name

- **WHEN** `client/ios/Runner/Info.plist` is read
- **THEN** `CFBundleDisplayName` is "PlayVerse" and `CFBundleName` is "playverse"

#### Scenario: macOS AppInfo.xcconfig identifiers

- **WHEN** `client/macos/Runner/Configs/AppInfo.xcconfig` is read
- **THEN** `PRODUCT_NAME = PlayVerse` and `PRODUCT_BUNDLE_IDENTIFIER = vn.x51.game2d.playverse`

---

### Requirement: Web Manifest Name

The web `manifest.json` SHALL have `"name": "PlayVerse"` and `"short_name": "PlayVerse"`.

#### Scenario: Web manifest

- **WHEN** `client/web/manifest.json` is read
- **THEN** both `name` and `short_name` are "PlayVerse"

---

### Requirement: Linux And Windows Desktop Names

Linux `CMakeLists.txt` `APPLICATION_ID` SHALL be `vn.x51.game2d.playverse` and the project name SHALL be `playverse`. Windows `CMakeLists.txt` project and binary name SHALL be `playverse`.

#### Scenario: Linux CMake application ID

- **WHEN** `client/linux/CMakeLists.txt` is read
- **THEN** `set(APPLICATION_ID "vn.x51.game2d.playverse")` is present

#### Scenario: Windows CMake project name

- **WHEN** `client/windows/CMakeLists.txt` is read
- **THEN** `project(playverse` is present

---

### Requirement: Go Module Path

The Go module path in `server/go.mod` SHALL be `github.com/duvu/playverse/server`. All import paths in `server/**/*.go` files that previously used `github.com/duvu/xcaro/server` SHALL use `github.com/duvu/playverse/server`.

#### Scenario: go.mod module declaration

- **WHEN** `server/go.mod` is read
- **THEN** `module github.com/duvu/playverse/server` is present

#### Scenario: Go build succeeds after rename

- **WHEN** `go build ./...` is run from the `server/` directory after the module rename
- **THEN** the build succeeds with zero errors

#### Scenario: Go tests pass after rename

- **WHEN** `go test ./...` is run from the `server/` directory after the module rename
- **THEN** all tests pass

---

### Requirement: Server Email Subject

Server email notifications SHALL reference "PlayVerse" in subject lines and body text, not "XCaro".

#### Scenario: Verification email subject

- **WHEN** the server sends a verification email to a new user
- **THEN** the email subject contains "PlayVerse" and does not contain "XCaro"

---

### Requirement: Swagger API Documentation Title

The Swagger/OpenAPI documentation title SHALL be "PlayVerse API" and the contact email SHALL use a playverse domain.

#### Scenario: Swagger title

- **WHEN** `server/docs/swagger.json` or `server/docs/swagger.yaml` is read
- **THEN** the `title` field is "PlayVerse API"

---

### Requirement: Project Documentation And Store Listings

`README.md`, `CONTRIBUTING.md`, `GAME_RULES.md`, `DOCUMENTATION.md`, and all files under `docs/` and `store/` SHALL reference "PlayVerse" as the product name, not "XCaro".

#### Scenario: README title

- **WHEN** `README.md` is read
- **THEN** the top-level heading and description reference "PlayVerse"

#### Scenario: Docs and store listings

- **WHEN** any file under `docs/` or `store/` is read
- **THEN** the product is referred to as "PlayVerse" throughout

---

### Requirement: No Behavioral Regression

The rename SHALL NOT change any API contract, WebSocket protocol event name, database schema, or game logic. All existing `go test ./...` and `flutter test` tests SHALL continue to pass.

#### Scenario: Flutter tests pass

- **WHEN** `flutter analyze && flutter test` is run from `client/` after the rename
- **THEN** no errors are reported

#### Scenario: API behavior unchanged

- **WHEN** any API endpoint previously available under the XCaro server is called
- **THEN** the response is identical to pre-rename behavior (routes, payloads, error codes unchanged)
