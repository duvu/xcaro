# PlayVerse Game Rules

## Overview: What Is Gomoku / Caro?

PlayVerse is a digital version of Gomoku, also known in Vietnam as Caro or "five in a row." Two players place stones on a square board and try to build an unbroken line of five stones before the opponent does.

## Board

PlayVerse uses a 15×15 grid. Moves are placed on grid cells in the app. Each cell can hold one stone, and a stone cannot be moved after it is placed.

## Objective

Be the first player to place five of your stones in a continuous row.

Winning lines can be:

- Horizontal
- Vertical
- Diagonal from top-left to bottom-right
- Diagonal from bottom-left to top-right

## Turns

- Black / X moves first.
- White / O moves second.
- Players alternate turns.
- You can only place a stone on an empty cell.

## Win Condition

PlayVerse uses a straightforward Gomoku rule: five or more stones in a row wins. There is no overline restriction, so a line of six or more still counts as a win.

## Draw Condition

The game is a draw when every cell on the 15×15 board is filled and neither player has five in a row.

## PlayVerse Controls

### Create an Online Room

1. Sign in to your account.
2. Choose **Create Room** from the home screen.
3. Share the generated room code with your opponent.
4. Wait for the opponent to join, then play when it is your turn.

### Join an Online Room

1. Sign in to your account.
2. Choose **Join Room**.
3. Enter the room code from your opponent.
4. Wait for the game board to load.

### Play Against AI

1. Choose **Play vs AI** from the home screen.
2. Select a difficulty: Easy, Medium, or Hard.
3. Place your stones as usual; the AI responds automatically.

### Use In-Game Chat

During online games, open the chat panel from the game screen to send short messages to your opponent. Chat is live and tied to the current room.

### View Leaderboard and Profiles

Use the leaderboard from the home screen to view ranked players by Elo rating. Tap a player to view their public profile and recent game summary.

## Tips for Beginners

1. **Block immediate threats.** If your opponent has four in a row with an open end, block it right away.
2. **Build two-way threats.** A line that can be extended from both ends is much stronger than a closed line.
3. **Control the center.** Early central moves create more diagonal, horizontal, and vertical options.
4. **Look for forks.** Try to create two threats at once so your opponent can only block one.
5. **Do not chase only one line.** Mix attack and defense; a single tunnel-vision attack is easy to block.

---

## Chess

### Overview

Chess is one of the world's oldest strategy board games. Two players control armies of 16 pieces each on an 8×8 board. White moves first. The goal is to checkmate the opponent's king.

### Pieces (White / Black)

| Piece | Symbol | Move |
|-------|--------|------|
| King | K / k | One square in any direction |
| Queen | Q / q | Any distance, any direction |
| Rook | R / r | Any distance, horizontally or vertically |
| Bishop | B / b | Any distance, diagonally |
| Knight | N / n | "L"-shape: 2+1 squares, jumps over pieces |
| Pawn | P / p | Forward one square (two from starting rank); captures diagonally one square |

### Special Rules

- **Castling**: King and unmoved rook swap — king moves two squares toward rook, rook jumps to the other side. Requires no pieces between them and neither has moved previously, and the king is not in check.
- **En passant**: A pawn that has just advanced two squares can be captured as if it only moved one square, on the very next move.
- **Promotion**: A pawn reaching the far rank promotes to a Queen, Rook, Bishop, or Knight (Queen is default in PlayVerse).
- **Check**: The king is threatened. The player must resolve the check.
- **Checkmate**: The king is in check and cannot escape → game over, the threatening player wins.
- **Stalemate**: A player has no legal moves but is not in check → draw.

### Draw Conditions

- Stalemate
- Fifty-move rule (no pawn move or capture in 50 moves)
- Insufficient material
- Agreement (not available in PlayVerse online)

### PlayVerse AI Difficulty Levels (Chess)

| Difficulty | AI Search Depth | Character |
|-----------|----------------|-----------|
| Easy | 1 ply | Makes legal moves, often random |
| Medium | 2 ply | Considers captures and threats one move ahead |
| Hard | 3 ply | Looks two full moves ahead with alpha-beta pruning |

### Online Mode

In online Chess, moves are validated server-side using the `notnil/chess` Go library. The board state is exchanged as a FEN (Forsyth-Edwards Notation) string. Illegal moves are rejected with an `illegal_move` error code; the board does not change. Both players must be authenticated and email-verified.
