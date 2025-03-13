import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/user.dart';
import '../services/local_storage_service.dart';
import '../models/chat_message.dart' as chat;
import 'package:uuid/uuid.dart';

class OfflineGameProvider with ChangeNotifier {
  final LocalStorageService _storage;
  Game? _currentGame;
  bool _isLoading = false;
  String? _error;
  List<List<String>> _board = List.generate(3, (_) => List.filled(3, ''));
  String _currentPlayer = 'X';
  String? _winner;
  bool _isGameOver = false;
  List<chat.ChatMessage> _messages = [];
  final _uuid = const Uuid();

  OfflineGameProvider(this._storage);

  Game? get currentGame => _currentGame;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<List<String>> get board => _board;
  String get currentPlayer => _currentPlayer;
  String? get winner => _winner;
  bool get isGameOver => _isGameOver;
  List<chat.ChatMessage> get messages => _messages;

  // Tạo game mới với máy
  Future<void> createGame() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _storage.getUser() ??
          const User(
            id: 'user',
            username: 'Người chơi',
          );

      final computer = const User(
        id: 'computer',
        username: 'Máy',
      );

      _currentGame = Game(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        creator: user,
        opponent: computer,
        board: List.generate(15, (_) => List.filled(15, 0)),
        isFinished: false,
        currentTurn: user.id,
        createdAt: DateTime.now(),
      );

      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Người chơi đánh
  Future<void> makeMove(int x, int y) async {
    if (_currentGame == null ||
        _currentGame!.isFinished ||
        _currentGame!.board[x][y] != 0) {
      return;
    }

    // Người chơi đánh
    final newBoard = List<List<int>>.from(
      _currentGame!.board.map((row) => List<int>.from(row)),
    );
    newBoard[x][y] = 1;

    var isFinished = _checkWin(newBoard, x, y, 1);
    var winner = isFinished ? _currentGame!.creator.id : null;

    if (!isFinished) {
      // Máy đánh
      final move = _findBestMove(newBoard);
      if (move != null) {
        newBoard[move.$1][move.$2] = 2;
        isFinished = _checkWin(newBoard, move.$1, move.$2, 2);
        if (isFinished) {
          winner = _currentGame!.opponent!.id;
        }
      } else {
        isFinished = true; // Hòa
      }
    }

    _currentGame = Game(
      id: _currentGame!.id,
      creator: _currentGame!.creator,
      opponent: _currentGame!.opponent,
      board: newBoard,
      isFinished: winner != null || isFinished,
      winner: winner,
      currentTurn:
          winner != null || isFinished ? '' : _currentGame!.currentTurn,
      createdAt: _currentGame!.createdAt,
    );

    notifyListeners();
  }

  bool _checkWin(List<List<int>> board, int x, int y, int player) {
    // Kiểm tra hàng ngang
    var count = 0;
    for (var i = 0; i < board.length; i++) {
      if (board[x][i] == player) {
        count++;
        if (count == 5) return true;
      } else {
        count = 0;
      }
    }

    // Kiểm tra hàng dọc
    count = 0;
    for (var i = 0; i < board.length; i++) {
      if (board[i][y] == player) {
        count++;
        if (count == 5) return true;
      } else {
        count = 0;
      }
    }

    // Kiểm tra đường chéo chính
    count = 0;
    var minDiag = min(x, y);
    var startX = x - minDiag;
    var startY = y - minDiag;
    while (startX < board.length && startY < board.length) {
      if (board[startX][startY] == player) {
        count++;
        if (count == 5) return true;
      } else {
        count = 0;
      }
      startX++;
      startY++;
    }

    // Kiểm tra đường chéo phụ
    count = 0;
    minDiag = min(x, board.length - 1 - y);
    startX = x - minDiag;
    startY = y + minDiag;
    while (startX < board.length && startY >= 0) {
      if (board[startX][startY] == player) {
        count++;
        if (count == 5) return true;
      } else {
        count = 0;
      }
      startX++;
      startY--;
    }

    return false;
  }

  (int, int)? _findBestMove(List<List<int>> board) {
    final moves = <(int, int)>[];
    for (var i = 0; i < board.length; i++) {
      for (var j = 0; j < board.length; j++) {
        if (board[i][j] == 0) {
          moves.add((i, j));
        }
      }
    }

    if (moves.isEmpty) return null;

    // Tìm nước đi có thể thắng
    for (final move in moves) {
      board[move.$1][move.$2] = 2;
      if (_checkWin(board, move.$1, move.$2, 2)) {
        board[move.$1][move.$2] = 0;
        return move;
      }
      board[move.$1][move.$2] = 0;
    }

    // Chặn nước đi có thể thua
    for (final move in moves) {
      board[move.$1][move.$2] = 1;
      if (_checkWin(board, move.$1, move.$2, 1)) {
        board[move.$1][move.$2] = 0;
        return move;
      }
      board[move.$1][move.$2] = 0;
    }

    // Chọn ngẫu nhiên
    return moves[Random().nextInt(moves.length)];
  }

  // Kết thúc game
  Future<void> _endGame({String? winner}) async {
    if (_currentGame == null) return;

    _currentGame = Game(
      id: _currentGame!.id,
      creator: _currentGame!.creator,
      opponent: _currentGame!.opponent,
      board: _currentGame!.board,
      isFinished: true,
      winner: winner,
      currentTurn: '',
      createdAt: _currentGame!.createdAt,
    );
    notifyListeners();

    // Cập nhật thống kê
    if (winner == 'offline_user') {
      await _storage.updateOfflineStats(isWin: true);
    } else {
      await _storage.updateOfflineStats(isWin: false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetGame() {
    _board = List.generate(3, (_) => List.filled(3, ''));
    _currentPlayer = 'X';
    _winner = null;
    _isGameOver = false;
    _messages.clear();
    notifyListeners();
  }

  void addMessage(String content) {
    _messages.add(chat.ChatMessage(
      id: _uuid.v4(),
      sender: 'Người chơi',
      content: content,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
