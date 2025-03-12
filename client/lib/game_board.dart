import 'package:flutter/foundation.dart';
import 'dart:math';
import 'audio_manager.dart';

enum GameMode { pvp, pvc }

class GameBoard extends ChangeNotifier {
  static const int size = 15;
  static const int centerZoneSize = 5;
  final AudioManager audioManager = AudioManager();
  Map<String, String> _infiniteBoard = {};
  String _currentPlayer = 'X';
  String _lastPlayer = '';
  bool _isGameOver = false;
  GameMode _gameMode = GameMode.pvp;
  bool _isFirstMove = true;
  double _currentOffsetX = 0;
  double _currentOffsetY = 0;
  double _targetOffsetX = 0;
  double _targetOffsetY = 0;
  bool _isAnimating = false;
  int _initialRow = -1;
  int _initialCol = -1;
  Function? _onAnimationComplete;

  // Thêm biến để theo dõi phạm vi bàn cờ thực tế
  int _minRow = 0;
  int _maxRow = size - 1;
  int _minCol = 0;
  int _maxCol = size - 1;

  // Thời gian suy nghĩ của mỗi người chơi (ms)
  int _xThinkingTime = 0;
  int _oThinkingTime = 0;
  DateTime? _lastMoveTime;

  // Số nước đi của mỗi người chơi
  int _xMoves = 0;
  int _oMoves = 0;

  String getCellValue(int row, int col) {
    return _infiniteBoard['$row,$col'] ?? '';
  }

  void setCellValue(int row, int col, String value) {
    if (value.isEmpty) {
      _infiniteBoard.remove('$row,$col');
    } else {
      _infiniteBoard['$row,$col'] = value;
      // Cập nhật phạm vi bàn cờ
      _minRow = min(_minRow, row);
      _maxRow = max(_maxRow, row);
      _minCol = min(_minCol, col);
      _maxCol = max(_maxCol, col);
    }
  }

  List<List<String>> get board {
    List<List<String>> result =
        List.generate(size, (_) => List.filled(size, ''));
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        result[i][j] = getCellValue(i, j);
      }
    }
    return result;
  }

  String get currentPlayer => _currentPlayer;
  String get lastPlayer => _lastPlayer;
  bool get isGameOver => _isGameOver;
  GameMode get gameMode => _gameMode;
  double get currentOffsetX => _currentOffsetX;
  double get currentOffsetY => _currentOffsetY;
  bool get isAnimating => _isAnimating;

  // Getters cho thông tin người chơi
  int get xThinkingTime => _xThinkingTime;
  int get oThinkingTime => _oThinkingTime;
  int get xMoves => _xMoves;
  int get oMoves => _oMoves;

  void setGameMode(GameMode mode) {
    _gameMode = mode;
    resetGame();
  }

  void resetGame() {
    _infiniteBoard.clear();
    _currentPlayer = 'X';
    _lastPlayer = '';
    _isGameOver = false;
    _isFirstMove = true;
    _currentOffsetX = 0;
    _currentOffsetY = 0;
    _targetOffsetX = 0;
    _targetOffsetY = 0;
    _isAnimating = false;
    _initialRow = -1;
    _initialCol = -1;
    _xThinkingTime = 0;
    _oThinkingTime = 0;
    _xMoves = 0;
    _oMoves = 0;
    _lastMoveTime = null;
    notifyListeners();
  }

  bool _isOutsideCenterZone(int row, int col) {
    int centerRow = size ~/ 2;
    int centerStart = centerRow - centerZoneSize ~/ 2;
    int centerEnd = centerStart + centerZoneSize - 1;
    return row < centerStart ||
        row > centerEnd ||
        col < centerStart ||
        col > centerEnd;
  }

  void _centerBoard(int row, int col) {
    _initialRow = row;
    _initialCol = col;

    // Tính toán vị trí trung tâm của bàn cờ
    int centerRow = size ~/ 2; // 7 (vị trí giữa của bàn 15x15)
    int centerCol = size ~/ 2; // 7

    _targetOffsetX = (centerCol - col) * 40.0;
    _targetOffsetY = (centerRow - row) * 40.0;

    _isAnimating = true;
    setCellValue(row, col, 'X');

    if (_onAnimationComplete != null) {
      _onAnimationComplete!(row, col, centerRow, centerCol);
    }

    notifyListeners();
  }

  bool _checkWin(int row, int col, String player) {
    // Kiểm tra ngang
    int count = 1;
    int j = col - 1;
    while (j >= _minCol && getCellValue(row, j) == player) {
      count++;
      j--;
    }
    j = col + 1;
    while (j <= _maxCol && getCellValue(row, j) == player) {
      count++;
      j++;
    }
    if (count >= 5) return true;

    // Kiểm tra dọc
    count = 1;
    int i = row - 1;
    while (i >= _minRow && getCellValue(i, col) == player) {
      count++;
      i--;
    }
    i = row + 1;
    while (i <= _maxRow && getCellValue(i, col) == player) {
      count++;
      i++;
    }
    if (count >= 5) return true;

    // Kiểm tra chéo xuống
    count = 1;
    i = row - 1;
    j = col - 1;
    while (i >= _minRow && j >= _minCol && getCellValue(i, j) == player) {
      count++;
      i--;
      j--;
    }
    i = row + 1;
    j = col + 1;
    while (i <= _maxRow && j <= _maxCol && getCellValue(i, j) == player) {
      count++;
      i++;
      j++;
    }
    if (count >= 5) return true;

    // Kiểm tra chéo lên
    count = 1;
    i = row - 1;
    j = col + 1;
    while (i >= _minRow && j <= _maxCol && getCellValue(i, j) == player) {
      count++;
      i--;
      j++;
    }
    i = row + 1;
    j = col - 1;
    while (i <= _maxRow && j >= _minCol && getCellValue(i, j) == player) {
      count++;
      i++;
      j--;
    }
    if (count >= 5) return true;

    return false;
  }

  void _updateThinkingTime() {
    if (_lastMoveTime != null) {
      final now = DateTime.now();
      final thinkingTime = now.difference(_lastMoveTime!).inMilliseconds;
      if (currentPlayer == 'X') {
        _oThinkingTime += thinkingTime;
      } else {
        _xThinkingTime += thinkingTime;
      }
    }
    _lastMoveTime = DateTime.now();
  }

  void makeMove(int row, int col) {
    if (isGameOver) return;

    _updateThinkingTime();

    if (currentPlayer == 'X') {
      _xMoves++;
    } else {
      _oMoves++;
    }

    print('Attempting move at ($row, $col)');

    if (getCellValue(row, col).isNotEmpty) {
      print('Move failed - Cell already occupied');
      return;
    }

    if (_isGameOver) {
      print('Move failed - Game is over');
      return;
    }

    if (_isAnimating) {
      print('Move failed - Animation in progress');
      return;
    }

    if (_isFirstMove && _isOutsideCenterZone(row, col)) {
      print('First move outside center zone - Moving to center');
      _centerBoard(row, col);
      _isFirstMove = false;
      return;
    }

    print('Making move: $_currentPlayer at ($row, $col)');
    setCellValue(row, col, _currentPlayer);
    _isFirstMove = false;

    if (_checkWin(row, col, _currentPlayer)) {
      print('Game Over - Winner: $_currentPlayer');
      _lastPlayer = _currentPlayer;
      _isGameOver = true;
      audioManager.playWinSound();
      notifyListeners();
      return;
    }

    _lastPlayer = _currentPlayer;
    _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
    print('Next player: $_currentPlayer');
    notifyListeners();

    if (_gameMode == GameMode.pvc && _currentPlayer == 'O' && !_isGameOver) {
      print('AI turn - Calculating move...');
      Future.delayed(const Duration(milliseconds: 500), () {
        _makeComputerMove();
      });
    }
  }

  void _makeComputerMove() {
    if (_isGameOver) {
      print('❌ AI move cancelled - Game is over');
      return;
    }

    print('🔍 AI searching for best move...');

    // Tìm vùng cần quét cho AI
    int minSearchRow = 1000;
    int maxSearchRow = -1000;
    int minSearchCol = 1000;
    int maxSearchCol = -1000;

    _infiniteBoard.forEach((key, value) {
      final coords = key.split(',');
      final row = int.parse(coords[0]);
      final col = int.parse(coords[1]);
      minSearchRow = min(minSearchRow, row - 2);
      maxSearchRow = max(maxSearchRow, row + 2);
      minSearchCol = min(minSearchCol, col - 2);
      maxSearchCol = max(maxSearchCol, col + 2);
    });

    print(
        '🔍 Search area: ($minSearchRow,$minSearchCol) to ($maxSearchRow,$maxSearchCol)');

    // Mở rộng vùng tìm kiếm
    minSearchRow = max(_minRow, minSearchRow);
    maxSearchRow = min(_maxRow, maxSearchRow);
    minSearchCol = max(_minCol, minSearchCol);
    maxSearchCol = min(_maxCol, maxSearchCol);

    int bestRow = -1;
    int bestCol = -1;
    int bestScore = -1;

    // Tìm nước đi thắng ngay
    for (int i = minSearchRow; i <= maxSearchRow; i++) {
      for (int j = minSearchCol; j <= maxSearchCol; j++) {
        if (getCellValue(i, j).isEmpty) {
          setCellValue(i, j, 'O');
          if (_checkWin(i, j, 'O')) {
            bestRow = i;
            bestCol = j;
            setCellValue(i, j, '');
            break;
          }
          setCellValue(i, j, '');
        }
      }
      if (bestRow != -1) break;
    }

    // Chặn nước thắng của đối thủ
    if (bestRow == -1) {
      for (int i = minSearchRow; i <= maxSearchRow; i++) {
        for (int j = minSearchCol; j <= maxSearchCol; j++) {
          if (getCellValue(i, j).isEmpty) {
            setCellValue(i, j, 'X');
            if (_checkWin(i, j, 'X')) {
              bestRow = i;
              bestCol = j;
              setCellValue(i, j, '');
              break;
            }
            setCellValue(i, j, '');
          }
        }
        if (bestRow != -1) break;
      }
    }

    // Tìm nước đi tốt nhất
    if (bestRow == -1) {
      for (int i = minSearchRow; i <= maxSearchRow; i++) {
        for (int j = minSearchCol; j <= maxSearchCol; j++) {
          if (getCellValue(i, j).isEmpty) {
            int score = _evaluateMove(i, j);
            if (score > bestScore) {
              bestScore = score;
              bestRow = i;
              bestCol = j;
            }
          }
        }
      }
    }

    if (bestRow != -1 && bestCol != -1) {
      print('🤖 AI chose move at ($bestRow, $bestCol) with score: $bestScore');
      makeMove(bestRow, bestCol);
    } else {
      print('⚠️ AI could not find a valid move');
    }
  }

  int _evaluateMove(int row, int col) {
    int score = 0;

    setCellValue(row, col, 'O');

    score += _evaluateDirection(row, col, 0, 1);
    score += _evaluateDirection(row, col, 1, 0);
    score += _evaluateDirection(row, col, 1, 1);
    score += _evaluateDirection(row, col, 1, -1);

    score += 10 - (abs(row - size ~/ 2) + abs(col - size ~/ 2));

    score += _evaluateProximity(row, col);

    setCellValue(row, col, '');
    return score;
  }

  int _evaluateDirection(int row, int col, int dRow, int dCol) {
    int count = 1;
    int openEnds = 0;
    String player = 'O';

    int r = row + dRow;
    int c = col + dCol;
    while (r >= _minRow &&
        r <= _maxRow &&
        c >= _minCol &&
        c <= _maxCol &&
        getCellValue(r, c) == player) {
      count++;
      r += dRow;
      c += dCol;
    }
    if (r >= _minRow &&
        r <= _maxRow &&
        c >= _minCol &&
        c <= _maxCol &&
        getCellValue(r, c).isEmpty) {
      openEnds++;
    }

    r = row - dRow;
    c = col - dCol;
    while (r >= _minRow &&
        r <= _maxRow &&
        c >= _minCol &&
        c <= _maxCol &&
        getCellValue(r, c) == player) {
      count++;
      r -= dRow;
      c -= dCol;
    }
    if (r >= _minRow &&
        r <= _maxRow &&
        c >= _minCol &&
        c <= _maxCol &&
        getCellValue(r, c).isEmpty) {
      openEnds++;
    }

    if (count >= 4) return 1000;
    if (count == 3 && openEnds == 2) return 500;
    if (count == 3 && openEnds == 1) return 100;
    if (count == 2 && openEnds == 2) return 50;
    if (count == 2 && openEnds == 1) return 10;
    return count * openEnds;
  }

  int _evaluateProximity(int row, int col) {
    int score = 0;
    for (int i = max(_minRow, row - 2); i <= min(_maxRow, row + 2); i++) {
      for (int j = max(_minCol, col - 2); j <= min(_maxCol, col + 2); j++) {
        if (getCellValue(i, j).isNotEmpty) {
          score += 5;
        }
      }
    }
    return score;
  }

  void updateAnimation(double progress) {
    if (!_isAnimating) return;

    _currentOffsetX = _targetOffsetX * (1 - progress);
    _currentOffsetY = _targetOffsetY * (1 - progress);

    if (progress >= 1.0) {
      _isAnimating = false;

      int centerStart = (size - centerZoneSize) ~/ 2;
      int centerRow = centerStart + centerZoneSize ~/ 2;
      int centerCol = centerStart + centerZoneSize ~/ 2;

      setCellValue(_initialRow, _initialCol, '');
      setCellValue(centerRow, centerCol, 'X');

      _currentOffsetX = 0;
      _currentOffsetY = 0;
      _targetOffsetX = 0;
      _targetOffsetY = 0;
      _initialRow = -1;
      _initialCol = -1;
    }

    notifyListeners();
  }

  void completeAnimation() {
    if (!_isAnimating) {
      print('⚠️ Animation complete called but not animating');
      return;
    }

    print('✨ Completing animation');

    // Sử dụng vị trí trung tâm của bàn cờ
    int centerRow = size ~/ 2;
    int centerCol = size ~/ 2;

    setCellValue(_initialRow, _initialCol, '');
    setCellValue(centerRow, centerCol, 'X');
    print(
        '🎯 Moved piece from ($_initialRow,$_initialCol) to ($centerRow,$centerCol)');

    _isAnimating = false;
    _initialRow = -1;
    _initialCol = -1;

    _currentPlayer = 'O';
    print('👉 Next player: $_currentPlayer');

    if (_gameMode == GameMode.pvc && !_isGameOver) {
      print('🤖 AI turn - Calculating move...');
      Future.delayed(const Duration(milliseconds: 500), () {
        _makeComputerMove();
      });
    }

    notifyListeners();
  }

  void setAnimationCallback(Function callback) {
    _onAnimationComplete = callback;
  }

  int abs(int x) => x < 0 ? -x : x;

  @override
  void dispose() {
    audioManager.dispose();
    super.dispose();
  }
}
