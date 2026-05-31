## Context

The codebase was originally created as "XCaro" — a single Caro board game. It has since grown into a multi-mini-game platform with social features, friends, a dashboard, per-game history/leaderboard, and a pluggable game module architecture. The name "XCaro" appears in:

- Flutter app display title, window title, and web manifest
- Flutter `pubspec.yaml` package name (`xcaro`)
- Android `applicationId` / `namespace` (`vn.x51.game2d.xcaro`)
- iOS/macOS bundle identifiers (`com.example.xcaro`, `vn.x51.game2d.xcaro`)
- Linux/Windows/macOS CMake project names and binary names
- Kotlin `MainActivity` package (`com.example.xcaro`)
- Go module path (`github.com/duvu/xcaro/server`) and all derived import paths (~30+ Go files)
- Server email subject lines, Swagger API title, docker-compose service names
- Docs, README, CONTRIBUTING, store listings, and OpenSpec change prose

"PlayVerse" is chosen: brand-friendly, language-neutral, communicates the multi-game universe concept, and scales to future game additions.

## Goals / Non-Goals

**Goals:**
- Replace every user-visible "XCaro"/"xcaro" string with "PlayVerse"/"playverse" consistently across Flutter client, Go server, native platform configs, docs, and store listings.
- Update Go module path and all import paths without breaking the build.
- Update Android/iOS/macOS/Linux/Windows platform identifiers consistently.
- Rename Kotlin source file directory from `com/example/xcaro/` to `com/example/playverse/`.
- Keep all behavioral contracts (APIs, WebSocket protocol, database schemas, game logic) completely unchanged.

**Non-Goals:**
- Changing domain or deployment URLs (server host, API endpoints remain the same path structure).
- Updating third-party service accounts (Firebase, App Store Connect, Play Console) — listed as manual follow-up tasks.
- Changing any game logic, auth flow, or database schema.
- Enforcing a new brand identity or redesigning UI beyond text string changes.

## Decisions

**Go module path: update `go.mod` + bulk import rewrite.**
Run `go mod edit -module github.com/duvu/playverse/server` then replace all import path prefixes with `sed` or `find`/`go fix`. Test with `go build ./...` and `go test ./...`. This is the safest and most complete approach; no Go files are left with stale imports.

**Android: update `applicationId`/`namespace` in `build.gradle`, rename Kotlin source tree.**
The Kotlin source at `app/src/main/kotlin/com/example/xcaro/` must be moved to `com/example/playverse/` and the `package` declaration updated in `MainActivity.kt`. The `AndroidManifest.xml` label attribute is updated to "PlayVerse".

**iOS/macOS: update `AppInfo.xcconfig` and `project.pbxproj`.**
`AppInfo.xcconfig` `PRODUCT_NAME` and `PRODUCT_BUNDLE_IDENTIFIER` are the canonical source; `project.pbxproj` entries that hardcode bundle IDs are updated to match. `Info.plist` `CFBundleDisplayName` and `CFBundleName` updated. Using xcconfig as the single source of truth is consistent with the current project structure.

**Flutter `pubspec.yaml` package name: update to `playverse`.**
This affects `dart pub` resolution and any relative package imports; however this project uses path-style imports within the same package, so no import rewrites are required in Dart beyond the package name declaration itself.

**Swagger/OpenAPI docs: regenerate after updating `@title` annotation in Go source or update the generated files directly.**
Since the project already has generated `server/docs/swagger.json`, `swagger.yaml`, and `docs.go`, update them directly rather than relying on a `swag init` re-run (which requires swag CLI and may not be available). The `docs.go` Go file also contains the swagger JSON as a string constant — update it alongside the JSON/YAML files.

**Docs and OpenSpec artifacts: update prose references, not structured identifiers.**
`openspec/specs/` is currently empty; existing change `*.md` files reference "XCaro" only in prose/comments. Update them with simple string replacement. Do not alter task checkbox states, capability names, or requirement identifiers.

## Risks / Trade-offs

- **Build breakage if import paths are missed:** Mitigated by running `go build ./...` and `go test ./...` after the Go module rename.
- **Android signing / Play Console mismatch:** Changing `applicationId` means the app is treated as a *new* app by Google Play. Existing installs cannot be updated over-the-air. Documented as manual follow-up; this change only updates code — Play Console migration is out of scope.
- **iOS/macOS provisioning profile invalidation:** Similarly, bundle ID change invalidates existing provisioning profiles. Manual follow-up in Apple Developer Portal.
- **`flutter pub get` / gradle sync required after rename:** Noted in tasks; any developer must run these after pulling the change.
- **OpenSpec existing change prose:** Some archived/in-progress change documents mention "XCaro" in prose; updating prose is low-risk (no functional contracts change).

## Migration Plan

1. Update Go module path and all server import paths first (server builds independently).
2. Update Flutter `pubspec.yaml`, Android, iOS/macOS, Linux, Windows, web platform files.
3. Update Flutter display strings (title, nav bar, theme comments).
4. Update docs, README, store listings, email templates, swagger.
5. Run `go build ./... && go test ./...` and `flutter analyze && flutter test` to confirm clean.
6. Manual follow-up (out of scope): re-upload iOS/Android apps under new bundle/app IDs to stores if desired, update provisioning profiles.

## Open Questions

- Should `vn.x51.game2d.xcaro` be changed to `vn.x51.game2d.playverse` for Android/iOS, or use a fresh identifier like `app.playverse.game`? → **Decision**: use `vn.x51.game2d.playverse` to stay consistent with existing namespace convention and minimize provisioning complexity.
- Should the GitHub repository be renamed from `xcaro` to `playverse`? → **Out of scope** for this change; GitHub repo rename is a separate one-click operation with redirect support.
