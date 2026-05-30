## ADDED Requirements

### Requirement: Flutter release validation
The client SHALL define the commands required to validate a release candidate.

#### Scenario: Standard Flutter checks pass
- **WHEN** release validation runs in `client/`
- **THEN** `flutter pub get`, `flutter analyze`, and `flutter test` complete successfully with zero errors

#### Scenario: Android release build succeeds
- **WHEN** release validation runs the Android release build command
- **THEN** Flutter produces a release APK or app bundle without build errors

### Requirement: High-impact analyzer cleanup
The client SHALL address analyzer findings that are likely to cause release defects or review friction.

#### Scenario: High-impact warnings are removed or documented
- **WHEN** `flutter analyze` reports warnings or infos
- **THEN** unused imports, unused variables, missing required superclass calls, deprecated APIs with straightforward replacements, and debug prints are fixed or explicitly documented as deferred with justification

### Requirement: App asset validation
The client SHALL verify launcher icon, splash, and registered assets before release.

#### Scenario: Asset files are valid and registered
- **WHEN** asset validation runs
- **THEN** launcher PNGs have expected dimensions, SVG assets are parseable, registered asset paths exist, and `flutter_launcher_icons` / `flutter_native_splash` generator commands complete successfully when rerun

### Requirement: Store-critical client configuration
The client SHALL validate basic store-critical app metadata and platform configuration before release.

#### Scenario: Store metadata is reviewed
- **WHEN** release validation reviews client configuration
- **THEN** app name, version/build number, Android application ID TODOs, icons, splash, and permission-sensitive settings are identified as ready or explicitly listed as release blockers
