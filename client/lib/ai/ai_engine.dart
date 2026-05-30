import 'board_evaluator.dart';

enum AiDifficulty { easy, medium, hard }

class AiEngine {
  static const int depth = 3;

  static Map<String, int> bestMove(
    List<List<int>> board,
    int aiPlayer, {
    AiDifficulty difficulty = AiDifficulty.medium,
  }) {
    final candidates = _getCandidates(board, difficulty);
    if (candidates.isEmpty) return {'x': 7, 'y': 7};

    int searchDepth;
    switch (difficulty) {
      case AiDifficulty.easy:
        searchDepth = 1;
        break;
      case AiDifficulty.medium:
        searchDepth = 3;
        break;
      case AiDifficulty.hard:
        searchDepth = 5;
        break;
    }

    int bestScore = -999999999;
    Map<String, int> best = candidates.first;
    final deadline = DateTime.now().add(const Duration(milliseconds: 900));

    for (final move in candidates) {
      if (difficulty == AiDifficulty.hard && DateTime.now().isAfter(deadline)) {
        break;
      }
      final x = move['x']!;
      final y = move['y']!;
      board[x][y] = aiPlayer;
      final score = minimax(
          board, searchDepth - 1, -999999999, 999999999, false, aiPlayer);
      board[x][y] = 0;
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    return best;
  }

  static List<Map<String, int>> _getCandidates(
      List<List<int>> board, AiDifficulty difficulty) {
    final all = getCandidateMoves(board);
    switch (difficulty) {
      case AiDifficulty.easy:
        all.shuffle();
        return all.take(10).toList();
      case AiDifficulty.medium:
        return all.length > 20 ? all.sublist(0, 20) : all;
      case AiDifficulty.hard:
        final scored = all.map((m) {
          board[m['x']!][m['y']!] = 1;
          final s = evaluateBoard(board, 1).abs();
          board[m['x']!][m['y']!] = 0;
          return MapEntry(m, s);
        }).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return scored.take(15).map((e) => e.key).toList();
    }
  }

  static int minimax(List<List<int>> board, int d, int alpha, int beta,
      bool maximizing, int aiPlayer) {
    final opponent = aiPlayer == 1 ? 2 : 1;
    final eval = evaluateBoard(board, aiPlayer);

    if (d == 0 || eval.abs() >= 1000000) return eval;

    final candidates = getCandidateMoves(board);
    if (candidates.isEmpty) return eval;

    if (maximizing) {
      int maxEval = -999999999;
      for (final move in candidates) {
        board[move['x']!][move['y']!] = aiPlayer;
        final e = minimax(board, d - 1, alpha, beta, false, aiPlayer);
        board[move['x']!][move['y']!] = 0;
        if (e > maxEval) maxEval = e;
        if (e > alpha) alpha = e;
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999999;
      for (final move in candidates) {
        board[move['x']!][move['y']!] = opponent;
        final e = minimax(board, d - 1, alpha, beta, true, aiPlayer);
        board[move['x']!][move['y']!] = 0;
        if (e < minEval) minEval = e;
        if (e < beta) beta = e;
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  /// Get cells adjacent to existing stones (up to 20 candidates).
  static List<Map<String, int>> getCandidateMoves(List<List<int>> board) {
    const size = 15;
    final Set<String> seen = {};
    final List<Map<String, int>> candidates = [];

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] != 0) {
          for (int dr = -2; dr <= 2; dr++) {
            for (int dc = -2; dc <= 2; dc++) {
              final nr = r + dr;
              final nc = c + dc;
              if (nr >= 0 &&
                  nr < size &&
                  nc >= 0 &&
                  nc < size &&
                  board[nr][nc] == 0) {
                final key = '$nr,$nc';
                if (!seen.contains(key)) {
                  seen.add(key);
                  candidates.add({'x': nr, 'y': nc});
                }
              }
            }
          }
        }
      }
    }

    // If board is empty, play center
    if (candidates.isEmpty) {
      candidates.add({'x': 7, 'y': 7});
    }

    // Limit to 20 for performance
    if (candidates.length > 20) {
      return candidates.sublist(0, 20);
    }
    return candidates;
  }
}
