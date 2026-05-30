## Why

XCaro has a complete MVP1+MVP2 feature set but lacks the surrounding project scaffolding that makes it presentable to users, contributors, and app stores. Without an icon, splash screen, documentation, and contribution guidelines the project cannot be published or onboarded to by new developers.

## What Changes

- Add Flutter app icon and splash screen (configured via `flutter_launcher_icons` + `flutter_native_splash`) with a clean Gomoku-themed design
- Create `GAME_RULES.md` explaining Gomoku rules for players new to the game
- Write `docs/architecture.md` covering the system design (client-server, auth, WebSocket, data model) and `docs/api.md` as a concise REST endpoint reference
- Add `CONTRIBUTING.md` with setup guide, coding conventions, PR workflow, and branch strategy
- Create `store/` directory with Play Store and App Store listing text, screenshots metadata, and a feature graphic description
- Add SVG vector game assets: stone icons (black/white), board theme, win-line overlay; configure as Flutter assets; add placeholder sound effect descriptors

## Capabilities

### New Capabilities

- `app-icon-splash`: Flutter app icon (1024×1024 adaptive) and native splash screen using brand colors and Gomoku stone motif
- `game-documentation`: Markdown docs covering Gomoku rules (GAME_RULES.md) and in-repo developer architecture + API reference docs
- `contribution-guide`: CONTRIBUTING.md with setup, coding conventions, branch strategy, and PR checklist
- `store-assets`: Textual store listing content (title, descriptions, keywords, changelogs) for Google Play and Apple App Store in `store/`
- `game-visual-assets`: SVG vector assets for game stones, board lines, win overlay; Flutter asset registration; placeholder audio descriptors

### Modified Capabilities

<!-- None — all new -->

## Impact

- `client/pubspec.yaml`: new dev dependencies (`flutter_launcher_icons`, `flutter_native_splash`), new asset paths
- `client/assets/`: new subdirectories `icons/`, `images/`, `sounds/`
- Root-level: new `CONTRIBUTING.md`, `GAME_RULES.md`
- `docs/`: new `architecture.md`, `api.md`
- `store/`: new directory with listing text files
- No backend changes; no breaking changes to existing screens
