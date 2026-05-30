## ADDED Requirements

### Requirement: Google Play Store Listing
The project SHALL include a `store/play-store.md` file containing the complete text metadata for a Google Play Store submission.

#### Scenario: Play Store metadata file present
- **WHEN** a publisher opens `store/play-store.md`
- **THEN** the file contains: app title (≤30 chars), short description (≤80 chars), full description (≤4000 chars), content rating justification, keywords, and a "What's New" changelog for the current release

---

### Requirement: Apple App Store Listing
The project SHALL include a `store/app-store.md` file containing the complete text metadata for an Apple App Store submission.

#### Scenario: App Store metadata file present
- **WHEN** a publisher opens `store/app-store.md`
- **THEN** the file contains: app name (≤30 chars), subtitle (≤30 chars), promotional text (≤170 chars), description (≤4000 chars), keywords (≤100 chars total), support URL placeholder, and privacy policy URL placeholder

---

### Requirement: Screenshot Guidance
The project SHALL document which screenshots to capture for store submissions.

#### Scenario: Screenshot guide present
- **WHEN** a publisher reads `store/screenshots.md`
- **THEN** the file lists the 5 required screenshot scenes (home screen, game board mid-play, AI difficulty picker, leaderboard, in-game chat), the device frame sizes needed (6.7" Android, 6.5" iOS), and brief captions for each
