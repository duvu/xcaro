# Game Board Redesign Spec

## Overview

Replace the flat GridView board with an SVG-backed board, gradient stone painter, star points, and a winning-line overlay.

## Requirements

### BOARD-1: SVG board background
- `GameBoard` widget must render `SvgPicture.asset('assets/images/board.svg')` as the board background.
- The SVG must fill the board square exactly (use `fit: BoxFit.fill`).
- The stone overlay (grid of tappable cells) must be positioned on top of the SVG via a `Stack`.

### BOARD-2: Cell size and layout
- Cell size calculation stays: `(screenWidth - 32) / 15`, clamped to `[20.0, 40.0]`.
- The overlay grid must be an absolute-positioned `GridView.builder` with `NeverScrollableScrollPhysics`.
- Cell backgrounds must be `Colors.transparent` (SVG already provides the background).
- Cell borders removed — no `Border.all(...)` on cells.

### BOARD-3: Stone painter (CustomPainter)
- Create `_StonePainter` extending `CustomPainter`.
- Black stone: `RadialGradient` from `Color(0xFF3D3D3D)` at center offset `(-0.3, -0.3)` to `Color(0xFF0D0D0D)`.
- White stone: `RadialGradient` from `Color(0xFFFFFFFF)` at center offset `(-0.3, -0.3)` to `Color(0xFFB0B0B0)` + `BoxShadow(blurRadius: 3, color: Colors.black26)` simulated via `Paint..maskFilter`.
- Stone fills 80% of cell area (margin: 10% each side).
- Remove the letter text ("X"/"O") from inside the stone — colour alone identifies player.
- Keep `ScaleTransition(scale: _scale)` animation (150ms, easeOut) on stone appearance.

### BOARD-4: Star points
- When a cell is empty, if its coordinates match one of the 5 standard star points `{(3,3),(3,11),(7,7),(11,3),(11,11)}` (0-indexed), draw a small filled circle at cell center.
- Star point colour: `AppColors.boardBackground` darkened by 40% (simulate natural board dot).
- Star point radius: 3dp.

### BOARD-5: Winning-line overlay
- `GameBoard` accepts an optional `List<(int, int)>? winningCells` parameter.
- When `winningCells != null` and length == 5, draw a `CustomPaint` overlay connecting the centers of the 5 cells with a line.
- Line style: `color: AppColors.secondary` (gold), `strokeWidth: 4`, `strokeCap: StrokeCap.round`.
- Animate the line in: `AnimationController` 400ms, `Tween<double>(begin: 0, end: 1)`, draw progressively (partial path based on animation value).

### BOARD-6: No breaking API changes
- `GameBoard` public API stays `(board, onTap, canTap)` — add `winningCells` as optional named parameter.
- All existing callers (`OnlineGameView`, `OfflineGameView`, `AiGameScreen`) remain unchanged unless they want to pass `winningCells`.

## Acceptance Criteria

- Board renders with SVG background visible.
- Black and white stones are visually distinct circles with gradient shading.
- Star points visible at the 5 standard positions on an empty board.
- Winning-line animates in gold after a 5-in-a-row win.
- `flutter analyze` 0 issues.
- Stone placement animation still fires on each new move.
