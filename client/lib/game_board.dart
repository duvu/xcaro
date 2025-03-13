import 'package:flutter/material.dart';
import 'dart:math' as Math;

enum GameMode { pvp, pvc }

class GameBoard extends ChangeNotifier {
  static const int size = 15;
  final List<List<String>> _board;
  String _currentPlayer = 'X';
  String _lastPlayer = '';
  bool _isGameOver = false;
  GameMode _gameMode = GameMode.pvp;
  int _thinkingTimePlayer1 = 0;
  int _thinkingTimePlayer2 = 0;
  int _moveCount = 0;
  int _xMoves = 0;
  int _oMoves = 0;
  DateTime? _lastMoveTime;

  GameBoard()
      : _board = List.generate(size, (_) => List.generate(size, (_) => ''));

  List<List<String>> get board => _board;
  GameMode get gameMode => _gameMode;
  String get currentPlayer => _currentPlayer;
  String get lastPlayer => _lastPlayer;
  bool get isGameOver => _isGameOver;
  int get thinkingTimePlayer1 => _thinkingTimePlayer1;
  int get thinkingTimePlayer2 => _thinkingTimePlayer2;
  int get moveCount => _moveCount;
  int get xThinkingTime => _thinkingTimePlayer1;
  int get oThinkingTime => _thinkingTimePlayer2;
  int get xMoves => _xMoves;
  int get oMoves => _oMoves;

  Function(int fromRow, int fromCol, int toRow, int toCol)? _animationCallback;

  void setAnimationCallback(
      Function(int fromRow, int fromCol, int toRow, int toCol) callback) {
    _animationCallback = callback;
  }

  void setGameMode(GameMode mode) {
    _gameMode = mode;
    resetGame();
  }

  String getCellValue(int row, int col) {
    if (row >= 0 && row < size && col >= 0 && col < size) {
      return _board[row][col];
    }
    return '';
  }

  bool makeMove(int row, int col) {
    if (row < 0 ||
        row >= size ||
        col < 0 ||
        col >= size ||
        _board[row][col].isNotEmpty ||
        _isGameOver) {
      return false;
    }

    final now = DateTime.now();
    if (_lastMoveTime != null) {
      final thinkingTime = now.difference(_lastMoveTime!).inMilliseconds;
      if (_currentPlayer == 'X') {
        _thinkingTimePlayer1 += thinkingTime;
      } else {
        _thinkingTimePlayer2 += thinkingTime;
      }
    }
    _lastMoveTime = now;

    _board[row][col] = _currentPlayer;
    _lastPlayer = _currentPlayer;
    _moveCount++;
    if (_currentPlayer == 'X') {
      _xMoves++;
    } else {
      _oMoves++;
    }

    if (checkWin(row, col)) {
      _isGameOver = true;
      notifyListeners();
      return true;
    }

    if (checkDraw()) {
      _isGameOver = true;
      notifyListeners();
      return true;
    }

    _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
    notifyListeners();

    // Nếu đang chơi với máy và đến lượt máy (O)
    if (_gameMode == GameMode.pvc && _currentPlayer == 'O' && !_isGameOver) {
      Future.delayed(const Duration(milliseconds: 500), () {
        final aiMove = _getAIMove();
        if (aiMove != null) {
          makeMove(aiMove[0], aiMove[1]);
        }
      });
    }

    return true;
  }

  bool checkWin(int row, int col) {
    final directions = [
      [0, 1], // horizontal
      [1, 0], // vertical
      [1, 1], // diagonal
      [1, -1], // anti-diagonal
    ];

    for (final direction in directions) {
      int count = 1;
      final value = _board[row][col];

      // Check forward
      var r = row + direction[0];
      var c = col + direction[1];
      while (
          r >= 0 && r < size && c >= 0 && c < size && _board[r][c] == value) {
        count++;
        r += direction[0];
        c += direction[1];
      }

      // Check backward
      r = row - direction[0];
      c = col - direction[1];
      while (
          r >= 0 && r < size && c >= 0 && c < size && _board[r][c] == value) {
        count++;
        r -= direction[0];
        c -= direction[1];
      }

      if (count >= 5) return true;
    }
    return false;
  }

  bool checkDraw() {
    return _moveCount >= size * size;
  }

  void resetGame() {
    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        _board[i][j] = '';
      }
    }
    _currentPlayer = 'X';
    _lastPlayer = '';
    _isGameOver = false;
    _moveCount = 0;
    _thinkingTimePlayer1 = 0;
    _thinkingTimePlayer2 = 0;
    _xMoves = 0;
    _oMoves = 0;
    _lastMoveTime = null;
    notifyListeners();
  }

  void completeAnimation() {
    // This method is called when any animation completes
    // You can add any post-animation logic here
  }

  // Đánh giá trạng thái bàn cờ
  int _evaluateBoard() {
    int score = 0;

    // Đánh giá theo hàng
    for (int i = 0; i < size; i++) {
      for (int j = 0; j <= size - 5; j++) {
        int xCount = 0;
        int oCount = 0;
        int emptyCount = 0;

        for (int k = 0; k < 5; k++) {
          if (_board[i][j + k] == 'X')
            xCount++;
          else if (_board[i][j + k] == 'O')
            oCount++;
          else
            emptyCount++;
        }

        score += _evaluateSequence(xCount, oCount, emptyCount);
      }
    }

    // Đánh giá theo cột
    for (int i = 0; i <= size - 5; i++) {
      for (int j = 0; j < size; j++) {
        int xCount = 0;
        int oCount = 0;
        int emptyCount = 0;

        for (int k = 0; k < 5; k++) {
          if (_board[i + k][j] == 'X')
            xCount++;
          else if (_board[i + k][j] == 'O')
            oCount++;
          else
            emptyCount++;
        }

        score += _evaluateSequence(xCount, oCount, emptyCount);
      }
    }

    // Đánh giá đường chéo chính
    for (int i = 0; i <= size - 5; i++) {
      for (int j = 0; j <= size - 5; j++) {
        int xCount = 0;
        int oCount = 0;
        int emptyCount = 0;

        for (int k = 0; k < 5; k++) {
          if (_board[i + k][j + k] == 'X')
            xCount++;
          else if (_board[i + k][j + k] == 'O')
            oCount++;
          else
            emptyCount++;
        }

        score += _evaluateSequence(xCount, oCount, emptyCount);
      }
    }

    // Đánh giá đường chéo phụ
    for (int i = 0; i <= size - 5; i++) {
      for (int j = 4; j < size; j++) {
        int xCount = 0;
        int oCount = 0;
        int emptyCount = 0;

        for (int k = 0; k < 5; k++) {
          if (_board[i + k][j - k] == 'X')
            xCount++;
          else if (_board[i + k][j - k] == 'O')
            oCount++;
          else
            emptyCount++;
        }

        score += _evaluateSequence(xCount, oCount, emptyCount);
      }
    }

    return score;
  }

  // Đánh giá một dãy 5 ô
  int _evaluateSequence(int xCount, int oCount, int emptyCount) {
    // Nếu có cả X và O trong dãy, không có giá trị
    if (xCount > 0 && oCount > 0) return 0;

    // Thắng
    if (oCount == 5) return 10000;
    if (xCount == 5) return -10000;

    // Sắp thắng
    if (oCount == 4 && emptyCount == 1) return 1000;
    if (xCount == 4 && emptyCount == 1) return -1000;

    // Tấn công
    if (oCount == 3 && emptyCount == 2) return 100;
    if (xCount == 3 && emptyCount == 2) return -100;

    if (oCount == 2 && emptyCount == 3) return 10;
    if (xCount == 2 && emptyCount == 3) return -10;

    if (oCount == 1 && emptyCount == 4) return 1;
    if (xCount == 1 && emptyCount == 4) return -1;

    return 0;
  }

  // Lấy nước đi của máy
  List<int>? _getAIMove() {
    // Nếu là nước đầu tiên, đánh vào giữa bàn cờ
    if (_moveCount == 0) {
      return [size ~/ 2, size ~/ 2];
    }

    // Tìm phạm vi cần xét dựa trên các nước đã đánh
    int minRow = size, maxRow = 0, minCol = size, maxCol = 0;
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (_board[i][j].isNotEmpty) {
          minRow = Math.min(minRow, Math.max(0, i - 2));
          maxRow = Math.min(size - 1, Math.max(maxRow, i + 2));
          minCol = Math.min(minCol, Math.max(0, j - 2));
          maxCol = Math.min(size - 1, Math.max(maxCol, j + 2));
        }
      }
    }

    // Nếu không tìm thấy phạm vi, sử dụng toàn bộ bàn cờ
    if (minRow > maxRow) {
      minRow = 0;
      maxRow = size - 1;
      minCol = 0;
      maxCol = size - 1;
    }

    int bestScore = -10000;
    List<int>? bestMove;

    // Đánh giá các nước đi trong phạm vi
    for (int i = minRow; i <= maxRow; i++) {
      for (int j = minCol; j <= maxCol; j++) {
        if (_board[i][j].isEmpty) {
          _board[i][j] = 'O';
          int score = _evaluateBoard();
          _board[i][j] = '';

          if (score > bestScore) {
            bestScore = score;
            bestMove = [i, j];
          }
        }
      }
    }

    return bestMove;
  }
}
