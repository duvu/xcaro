# XCaro Sound Effect Requirements

This directory is reserved for short, lightweight game sounds. Prefer sourcing
or exporting each sound as both MP3 and OGG for broad platform/web support.

Recommended source: [freesound.org](https://freesound.org/) with a CC0 license.
Keep each final file under 50 KB where practical.

| File | Trigger | Duration | Style |
|---|---|---:|---|
| `place_stone.mp3` / `place_stone.ogg` | Every successful stone placement | ~100 ms | Soft wooden tap/click, subtle and non-metallic |
| `win.mp3` / `win.ogg` | Local player wins | ~2 s | Bright, triumphant fanfare without harsh peaks |
| `lose.mp3` / `lose.ogg` | Local player loses | ~1.5 s | Gentle descending tone, not punitive |
| `draw.mp3` / `draw.ogg` | Game ends in draw | ~1 s | Neutral chime, calm resolution |
| `button_tap.mp3` / `button_tap.ogg` | Button and menu taps | ~50 ms | Light UI click, quieter than stone placement |

Implementation note: existing code currently loads `assets/sounds/move.wav` and
`assets/sounds/win.wav`. Keep those files until the audio manager is updated to
the final filenames above.
