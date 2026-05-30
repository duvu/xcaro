## Context

XCaro is a fully-featured Flutter Gomoku game with Go backend (MVP1+MVP2 complete): JWT auth, WebSocket multiplayer, AI opponent, Elo leaderboard, in-game chat. The codebase is production-ready but lacks the surrounding scaffolding expected of a published mobile app: there is no app icon (uses default Flutter icon), no splash screen, no documentation beyond a basic README, and no store listing materials. This change adds all the missing "first impression" and developer-experience assets.

Key existing constraints:
- Flutter SDK ~3.x, Dart; assets referenced in `client/pubspec.yaml`
- Existing `client/assets/` directory structure
- Brand identity: "XCaro" — Gomoku (五目並べ) with Vietnamese flavor
- Color palette: to be established (recommend dark navy `#1A2035` background, gold `#FFD700` accent stones)

## Goals / Non-Goals

**Goals:**
- App icon + adaptive icon (Android) + iOS icon (1024×1024 source) via `flutter_launcher_icons`
- Splash screen via `flutter_native_splash` (branded, consistent with icon)
- SVG vector assets for game stones (black/white) and board; registered in pubspec.yaml
- Placeholder audio file descriptors (spec describes what sounds are needed; actual audio files sourced separately)
- Comprehensive user-facing game rules document (`GAME_RULES.md`)
- Developer architecture and API reference docs (`docs/architecture.md`, `docs/api.md`)
- Contribution guide (`CONTRIBUTING.md`) for open-source onboarding
- Store listing text for Google Play and Apple App Store (`store/` directory)

**Non-Goals:**
- Animated splash screen (static only for MVP)
- Actual binary audio files (AI cannot generate audio; descriptors guide a sound designer)
- Custom font embedding (system font is adequate)
- Localization of docs (English only for now)
- Screenshot automation (manual screenshots are sufficient at this stage)

## Decisions

### 1. Icon Generation: flutter_launcher_icons Package

**Decision**: Use `flutter_launcher_icons` (dev dependency) with a single `assets/icons/icon.png` source (1024×1024). Configure adaptive icon for Android with foreground layer + navy background color.

**Rationale**: Standard community tool; handles all platform icon variants from one source. SVG not supported by the tool, so generate PNG from SVG at build time (or provide PNG directly).

**Alternative**: Manual per-platform icon creation — error-prone, tedious.

### 2. Splash Screen: flutter_native_splash

**Decision**: Use `flutter_native_splash` package. White/navy background with centered XCaro logo. Removes the ugly default white flash on Android.

**Rationale**: Single declarative config, platform-agnostic generation.

### 3. Vector Assets: SVG via flutter_svg

**Decision**: Ship stone/board assets as `.svg` files in `client/assets/images/`. Add `flutter_svg` dependency (already commonly available). Register paths in pubspec.yaml.

**Rationale**: SVG scales perfectly on all DPIs. Gomoku stones and board lines are simple geometric shapes that compress well as SVG.

**Alternative**: PNG sprites at multiple resolutions — larger bundle size, harder to maintain.

### 4. Audio Descriptors: README-style spec, no binaries

**Decision**: Create `client/assets/sounds/README.md` describing each required sound (filename, trigger, duration, style). Actual `.mp3`/`.ogg` files to be sourced from free sound libraries (freesound.org) by a developer following the spec.

**Rationale**: AI cannot generate audio. Specifying what is needed unblocks a sound designer without blocking the rest of development.

### 5. Docs Structure

| Document | Location | Audience |
|---|---|---|
| Game rules | `GAME_RULES.md` (root) | Players |
| Architecture | `docs/architecture.md` | Developers |
| API reference | `docs/api.md` | Integrators |
| Contribution | `CONTRIBUTING.md` (root) | Contributors |
| Store listing | `store/play-store.md`, `store/app-store.md` | Marketing / Store submitter |

### 6. Store Listing: Text-Only Metadata Files

**Decision**: Create Markdown files with the complete store listing text (title, short/full description, keywords, what's new). Screenshots are left as a manual step with guidance on what to capture.

**Rationale**: Text assets are the highest-effort part of store submission and can be prepared in code review. Screenshot generation requires a running device.

## Risks / Trade-offs

- **Icon PNG requirement**: `flutter_launcher_icons` needs a PNG source, not SVG. → Mitigation: provide a simple SVG and document the `rsvg-convert`/Inkscape command to produce the PNG, OR provide the PNG directly as a generated asset (simple geometric design).
- **flutter_svg dependency**: adds ~200KB to app bundle. → Acceptable trade-off for DPI-independence.
- **Store listing accuracy**: text written now may need updating when features change. → Mark changelogs with version tags; update as part of release process.

## Migration Plan

1. Add dev dependencies to `client/pubspec.yaml` (`flutter_launcher_icons`, `flutter_native_splash`)
2. Create SVG assets and run `dart run flutter_launcher_icons` + `dart run flutter_native_splash:create`
3. Verify icons appear on Android emulator and iOS simulator
4. Doc files are purely additive — no migration needed
