## ADDED Requirements

### Requirement: App Icon
The system SHALL provide a branded app icon for all required platform sizes and variants.

#### Scenario: Android adaptive icon displayed
- **WHEN** the app is installed on an Android device
- **THEN** the app icon displays the PlayVerse stone motif on a navy (`#1A2035`) background as an adaptive icon, rendering correctly on all launcher shapes (circle, square, squircle)

#### Scenario: iOS icon displayed
- **WHEN** the app is installed on an iOS device
- **THEN** the 1024×1024 source icon is correctly sized for all required iOS icon slots (App Store, Home Screen, Spotlight, Settings)

#### Scenario: Icon source file present
- **WHEN** the project is checked out and dependencies installed
- **THEN** `client/assets/icons/icon.png` exists as the 1024×1024 source and `dart run flutter_launcher_icons` can generate all platform variants without error

---

### Requirement: Native Splash Screen
The system SHALL display a branded splash screen on app launch rather than the default Flutter white flash.

#### Scenario: Splash screen shown on cold start
- **WHEN** the app is launched from a cold start on Android or iOS
- **THEN** a full-screen splash is shown with navy background and centered PlayVerse logo/wordmark; the splash is dismissed once the Flutter engine is ready

#### Scenario: Splash generation from config
- **WHEN** `dart run flutter_native_splash:create` is run in the `client/` directory
- **THEN** the command exits 0 and the generated platform files are present in `android/` and `ios/`
