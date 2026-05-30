/// Board evaluator for Gomoku (15x15).
/// Player 1 = 1 (X), Player 2 = 2 (O), empty = 0.
library;

const Map<String, int> patternScores = {
  'five': 1000000,
  'open_four': 100000,
  'closed_four': 10000,
  'open_three': 5000,
  'closed_three': 500,
  'open_two': 100,
};

int evaluateBoard(List<List<int>> board, int player) {
  final opponent = player == 1 ? 2 : 1;
  return _scoreForPlayer(board, player) - _scoreForPlayer(board, opponent);
}

int _scoreForPlayer(List<List<int>> board, int player) {
  int score = 0;
  const size = 15;
  final directions = [
    [0, 1], // horizontal
    [1, 0], // vertical
    [1, 1], // diagonal
    [1, -1], // anti-diagonal
  ];

  for (final dir in directions) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        // Scan lines of 6 to detect patterns
        score += _evaluateLine(board, r, c, dir[0], dir[1], player);
      }
    }
  }
  return score;
}

int _evaluateLine(
    List<List<int>> board, int startR, int startC, int dr, int dc, int player) {
  const size = 15;
  // Collect a window of 6 cells
  final cells = <int>[];
  for (int i = 0; i < 6; i++) {
    final r = startR + dr * i;
    final c = startC + dc * i;
    if (r < 0 || r >= size || c < 0 || c >= size) return 0;
    cells.add(board[r][c]);
  }

  int playerCount = cells.where((v) => v == player).length;
  int emptyCount = cells.where((v) => v == 0).length;
  int opponentCount = 6 - playerCount - emptyCount;

  if (opponentCount > 0) return 0; // blocked by opponent
  if (playerCount == 5) return patternScores['five']!;
  if (playerCount == 4 && emptyCount == 2) return patternScores['open_four']!;
  if (playerCount == 4 && emptyCount == 1) return patternScores['closed_four']!;
  if (playerCount == 3 && emptyCount == 3) return patternScores['open_three']!;
  if (playerCount == 3 && emptyCount == 2) {
    return patternScores['closed_three']!;
  }
  if (playerCount == 2 && emptyCount >= 4) return patternScores['open_two']!;
  return 0;
}
