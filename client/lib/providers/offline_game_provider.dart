import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/user.dart';
import '../services/local_storage_service.dart';
import '../models/chat_message.dart' as chat;
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class OfflineGameProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  Game? _currentGame;
  User? _currentUser;
  User? _computer;
  bool _isLoading = false;
  String? _error;
  List<List<String>> _board = List.generate(3, (_) => List.filled(3, ''));
  String _currentPlayer = 'X';
  String? _winner;
  bool _isGameOver = false;
  List<chat.ChatMessage> _messages = [];
  final _uuid = const Uuid();

  OfflineGameProvider(this._storage) {
    _init();
  }

  Game? get currentGame => _currentGame;
  User? get currentUser => _currentUser;
  User? get computer => _computer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<List<String>> get board => _board;
  String get currentPlayer => _currentPlayer;
  String? get winner => _winner;
  bool get isGameOver => _isGameOver;
  List<chat.ChatMessage> get messages => _messages;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _storage.getUser();
      if (user != null) {
        _currentUser = user;
      } else {
        _currentUser = User(
          id: 'offline_user',
          username: 'Người chơi',
          email: 'offline@example.com',
          role: 'player',
          isBanned: false,
          gamesPlayed: 0,
          gamesWon: 0,
          rating: 1000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      _computer = User(
        id: 'computer',
        username: 'Máy tính',
        email: 'computer@example.com',
        role: 'player',
        isBanned: false,
        gamesPlayed: 0,
        gamesWon: 0,
        rating: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startNewGame() async {
    _currentGame = Game(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      players: [_currentUser!, _computer!],
      currentPlayer: _currentUser!,
      board: List.generate(15, (_) => List.filled(15, '')),
      status: 'playing',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> makeMove(int x, int y) async {
    if (_currentGame == null || _currentGame!.status != 'playing') return;

    // Kiểm tra lượt chơi
    if (_currentGame!.currentPlayer != _currentUser) return;

    // Kiểm tra ô đã được đánh chưa
    if (_currentGame!.board[x][y] != '') return;

    // Đánh cờ
    final newBoard = List<List<String>>.from(
      _currentGame!.board.map((row) => List<String>.from(row)),
    );
    newBoard[x][y] = 'X';

    _currentGame = Game(
      id: _currentGame!.id,
      players: _currentGame!.players,
      currentPlayer: _computer!,
      board: newBoard,
      status: 'playing',
      createdAt: _currentGame!.createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Kiểm tra thắng
    if (_checkWin(x, y)) {
      _currentGame = Game(
        id: _currentGame!.id,
        players: _currentGame!.players,
        currentPlayer: _currentGame!.currentPlayer,
        board: _currentGame!.board,
        status: 'finished',
        winner: _currentUser,
        createdAt: _currentGame!.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return;
    }

    // Kiểm tra hòa
    if (_checkDraw()) {
      _currentGame = Game(
        id: _currentGame!.id,
        players: _currentGame!.players,
        currentPlayer: _currentGame!.currentPlayer,
        board: _currentGame!.board,
        status: 'finished',
        createdAt: _currentGame!.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return;
    }

    // Máy tính đánh
    await Future.delayed(const Duration(milliseconds: 500));
    _makeComputerMove();
  }

  void _makeComputerMove() {
    if (_currentGame == null || _currentGame!.status != 'playing') return;

    // Tìm nước đi tốt nhất
    final move = _findBestMove();
    if (move != null) {
      final newBoard = List<List<String>>.from(
        _currentGame!.board.map((row) => List<String>.from(row)),
      );
      newBoard[move.x][move.y] = 'O';

      _currentGame = Game(
        id: _currentGame!.id,
        players: _currentGame!.players,
        currentPlayer: _currentUser!,
        board: newBoard,
        status: 'playing',
        createdAt: _currentGame!.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();

      // Kiểm tra thắng
      if (_checkWin(move.x, move.y)) {
        _currentGame = Game(
          id: _currentGame!.id,
          players: _currentGame!.players,
          currentPlayer: _currentGame!.currentPlayer,
          board: _currentGame!.board,
          status: 'finished',
          winner: _computer,
          createdAt: _currentGame!.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
        return;
      }

      // Kiểm tra hòa
      if (_checkDraw()) {
        _currentGame = Game(
          id: _currentGame!.id,
          players: _currentGame!.players,
          currentPlayer: _currentGame!.currentPlayer,
          board: _currentGame!.board,
          status: 'finished',
          createdAt: _currentGame!.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }

  bool _checkWin(int x, int y) {
    final directions = [
      [1, 0], // ngang
      [0, 1], // dọc
      [1, 1], // chéo xuống
      [1, -1], // chéo lên
    ];

    final player = _currentGame!.board[x][y];

    for (final direction in directions) {
      var count = 1;

      // Kiểm tra theo hướng thuận
      var i = x + direction[0];
      var j = y + direction[1];
      while (i >= 0 &&
          i < 15 &&
          j >= 0 &&
          j < 15 &&
          _currentGame!.board[i][j] == player) {
        count++;
        i += direction[0];
        j += direction[1];
      }

      // Kiểm tra theo hướng ngược
      i = x - direction[0];
      j = y - direction[1];
      while (i >= 0 &&
          i < 15 &&
          j >= 0 &&
          j < 15 &&
          _currentGame!.board[i][j] == player) {
        count++;
        i -= direction[0];
        j -= direction[1];
      }

      if (count >= 5) return true;
    }

    return false;
  }

  bool _checkDraw() {
    for (var i = 0; i < 15; i++) {
      for (var j = 0; j < 15; j++) {
        if (_currentGame!.board[i][j] == '') return false;
      }
    }
    return true;
  }

  Move? _findBestMove() {
    // Tìm nước đi tốt nhất cho máy tính
    // TODO: Implement AI algorithm
    return null;
  }

  // Kết thúc game
  Future<void> _endGame({String? winnerId}) async {
    if (_currentGame == null) return;

    _currentGame = Game(
      id: _currentGame!.id,
      players: _currentGame!.players,
      currentPlayer: _currentGame!.currentPlayer,
      board: _currentGame!.board,
      status: 'finished',
      winner: winnerId == 'offline_user' ? _currentUser : _computer,
      createdAt: _currentGame!.createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Cập nhật thống kê
    if (winnerId == 'offline_user') {
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
    _currentGame = null;
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

class Move {
  final int x;
  final int y;

  Move(this.x, this.y);
}
