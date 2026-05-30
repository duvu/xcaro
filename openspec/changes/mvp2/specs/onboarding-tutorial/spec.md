## ADDED Requirements

### Requirement: First-Launch Onboarding
The system SHALL display a tutorial overlay on the user's first launch after login that explains Gomoku rules and controls.

#### Scenario: First launch tutorial shown
- **WHEN** an authenticated user opens the app for the first time (no `onboarding_complete` flag in local storage)
- **THEN** a full-screen tutorial modal is shown with animated steps: (1) what is Gomoku, (2) how to place a stone, (3) win condition (5 in a row), (4) "Got it!" dismiss button

#### Scenario: Tutorial not shown on subsequent launches
- **WHEN** the user has previously dismissed the tutorial
- **THEN** tutorial is NOT shown on app start; `onboarding_complete: true` is stored in `shared_preferences`

---

### Requirement: Help / Tutorial Re-access
The system SHALL allow users to re-view the tutorial at any time from the settings screen.

#### Scenario: Re-open tutorial
- **WHEN** user taps "How to play" in the settings screen
- **THEN** the tutorial modal is displayed regardless of `onboarding_complete` flag
