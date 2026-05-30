import 'package:flutter/foundation.dart';
import '../ai/ai_isolate.dart';
import '../ai/ai_engine.dart';

/// Manages a local AI game (no server).
/// Player = 1 (human, X), AI = 2 (O).
class OfflineAiProvider extends ChangeNotifier {
  static const int boardSize = 15;

  List<List<int>> _board =
      List.generate(boardSize, (_) => List.filled(boardSize, 0));
  int _currentTurn = 1; // 1 = human, 2 = AI
  bool _gameOver = false;
  int? _winner; // 1, 2, or 0 for draw
  bool _aiThinking = false;
  AiDifficulty _difficulty = AiDifficulty.medium;

  List<List<int>> get board => _board;
  int get currentTurn => _currentTurn;
  bool get gameOver => _gameOver;
  int? get winner => _winner;
  bool get aiThinking => _aiThinking;
  AiDifficulty get difficulty => _difficulty;

  void setDifficulty(AiDifficulty d) {
    _difficulty = d;
    notifyListeners();
  }

  void resetGame() {
    _board = List.generate(boardSize, (_) => List.filled(boardSize, 0));
    _currentTurn = 1;
    _gameOver = false;
    _winner = null;
    _aiThinking = false;
    notifyListeners();
  }

  Future<void> makeMove(int x, int y) async {
    if (_gameOver) return;
    if (_currentTurn != 1) return; // only human turn
    if (_board[x][y] != 0) return;

    _board[x][y] = 1;
    notifyListeners();

    if (_checkWin(x, y)) {
      _gameOver = true;
      _winner = 1;
      notifyListeners();
      return;
    }
    if (_checkDraw()) {
      _gameOver = true;
      _winner = 0;
      notifyListeners();
      return;
    }

    _currentTurn = 2;
    _aiThinking = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final move = await computeAiMove(_board, 2, difficulty: _difficulty);
      final ax = move['x']!;
      final ay = move['y']!;
      _board[ax][ay] = 2;

      if (_checkWin(ax, ay)) {
        _gameOver = true;
        _winner = 2;
      } else if (_checkDraw()) {
        _gameOver = true;
        _winner = 0;
      } else {
        _currentTurn = 1;
      }
    } catch (_) {
      _currentTurn = 1;
    } finally {
      _aiThinking = false;
      notifyListeners();
    }
  }

  bool _checkWin(int x, int y) {
    final player = _board[x][y];
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (final d in dirs) {
      int count = 1;
      // forward
      int r = x + d[0], c = y + d[1];
      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize &&
          _board[r][c] == player) {
        count++;
        r += d[0];
        c += d[1];
      }
      // backward
      r = x - d[0];
      c = y - d[1];
      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize &&
          _board[r][c] == player) {
        count++;
        r -= d[0];
        c -= d[1];
      }
      if (count >= 5) return true;
    }
    return false;
  }

  bool _checkDraw() {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (_board[r][c] == 0) return false;
      }
    }
    return true;
  }
}

