## ADDED Requirements

### Requirement: Move Animation
The system SHALL animate stone placement on the board.

#### Scenario: Stone placed
- **WHEN** a move is made (by user, opponent, or AI)
- **THEN** the stone appears with a scale-in animation (duration ≤ 150ms); no frame drops below 60fps during animation

---

### Requirement: Sound Effects
The system SHALL play audio feedback on game events.

#### Scenario: Move sound
- **WHEN** any stone is placed
- **THEN** a short tap/click sound plays immediately

#### Scenario: Win sound
- **WHEN** the game ends with a winner
- **THEN** a win fanfare sound plays

#### Scenario: Sound disabled
- **WHEN** user toggles sound off in settings
- **THEN** no audio plays for subsequent game events; preference is persisted across sessions

---

### Requirement: Dark / Light Theme
The system SHALL support dark and light color themes switchable by the user.

#### Scenario: Toggle theme
- **WHEN** user toggles the theme in settings
- **THEN** the entire app re-renders with the selected theme immediately

#### Scenario: Theme persisted
- **WHEN** user restarts the app
- **THEN** the previously selected theme is restored

---

### Requirement: Responsive Mobile Layout
The system SHALL render correctly on common Android and iOS screen sizes (360dp–430dp width).

#### Scenario: Game board on small screen
- **WHEN** the app runs on a 360dp-wide device
- **THEN** the game board is fully visible without horizontal scrolling, and all interactive cells are at least 20×20dp tap targets
