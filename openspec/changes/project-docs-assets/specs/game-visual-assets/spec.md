## ADDED Requirements

### Requirement: SVG Stone Assets
The system SHALL provide vector SVG assets for game stones and register them in pubspec.yaml.

#### Scenario: Stone SVGs present and registered
- **WHEN** the Flutter app builds
- **THEN** `client/assets/images/stone_black.svg` and `client/assets/images/stone_white.svg` exist, are valid SVG files showing a circular stone with a subtle radial gradient, and are referenced under `flutter.assets` in `pubspec.yaml`

---

### Requirement: Board Asset
The system SHALL provide a vector SVG asset for the 15×15 Gomoku board grid.

#### Scenario: Board SVG present and registered
- **WHEN** the Flutter app builds
- **THEN** `client/assets/images/board.svg` exists, shows a 15×15 grid with star points at the standard Gomoku positions (center + 4 corners of the inner 11×11), and is registered in `pubspec.yaml`

---

### Requirement: flutter_svg Dependency
The system SHALL declare `flutter_svg` as a runtime dependency in `client/pubspec.yaml`.

#### Scenario: flutter_svg added to pubspec
- **WHEN** `flutter pub get` is run in the `client/` directory
- **THEN** `flutter_svg` resolves without conflict and `SvgPicture.asset()` can load the stone and board assets at runtime

---

### Requirement: Audio Asset Descriptors
The project SHALL document the required sound effects in `client/assets/sounds/README.md` so a sound designer can source or create the files.

#### Scenario: Audio descriptor file present
- **WHEN** a developer opens `client/assets/sounds/README.md`
- **THEN** the file describes each required sound: `place_stone.mp3` (short tap ~100ms), `win.mp3` (fanfare ~2s), `lose.mp3` (descending tone ~1.5s), `draw.mp3` (neutral chime ~1s), `button_tap.mp3` (UI feedback ~50ms); includes recommended source (freesound.org, CC0 license), file format (MP3 + OGG for web), and expected file size (<50KB each)
