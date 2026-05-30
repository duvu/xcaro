import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../models/game.dart';
import '../models/user.dart';
import 'chat_provider.dart';

class GameProvider extends ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService _wsService;
  final ChatProvider chatProvider;

  List<Game>? _myGames;
  Game? _currentGame;
  bool _isLoading = false;

  // Online game state from WS
  List<List<int>> _board = List.generate(15, (_) => List.filled(15, 0));
  String? _currentTurn; // player id whose turn it is
  User? _playerX;
  User? _playerO;
  bool _gameOver = false;
  String? _winner; // 'X', 'O', 'draw', 'disconnect'
  String? _roomCode;

  StreamSubscription? _wsSubscription;

  GameProvider(this._apiService, this._wsService, this.chatProvider) {
    _wsSubscription = _wsService.onMessage.listen(_onWsMessage);
  }

  List<Game>? get myGames => _myGames;
  Game? get currentGame => _currentGame;
  bool get isLoading => _isLoading;
  List<List<int>> get board => _board;
  String? get currentTurn => _currentTurn;
  User? get playerX => _playerX;
  User? get playerO => _playerO;
  bool get gameOver => _gameOver;
  String? get winner => _winner;
  String? get roomCode => _roomCode;

  void _onWsMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    final payload = msg['payload'] as Map<String, dynamic>?;

    if (type == 'game_state' && payload != null) {
      _applyGameState(payload);
    } else if (type == 'game_over' && payload != null) {
      _applyGameOver(payload);
    } else if (type == 'room_created' && payload != null) {
      _roomCode = payload['code'] as String?;
      notifyListeners();
    } else if (type == 'chat_message' && payload != null) {
      chatProvider.addMessage(payload);
    }
  }

  void _applyGameState(Map<String, dynamic> payload) {
    final rawBoard = payload['board'];
    if (rawBoard != null) {
      _board = (rawBoard as List)
          .map((row) => (row as List).map((c) => c as int).toList())
          .toList();
    }
    _currentTurn = payload['current_turn'] as String?;
    if (payload['player_x'] != null) {
      _playerX = User.fromJson(payload['player_x'] as Map<String, dynamic>);
    }
    if (payload['player_o'] != null) {
      _playerO = User.fromJson(payload['player_o'] as Map<String, dynamic>);
    }
    _gameOver = false;
    _winner = null;
    notifyListeners();
  }

  void _applyGameOver(Map<String, dynamic> payload) {
    _gameOver = true;
    _winner = payload['winner'] as String?;
    // Apply final board if provided
    final rawBoard = payload['board'];
    if (rawBoard != null) {
      _board = (rawBoard as List)
          .map((row) => (row as List).map((c) => c as int).toList())
          .toList();
    }
    notifyListeners();
  }

  void makeMove(int x, int y) {
    _wsService.makeMove(x, y);
  }

  Future<void> loadGames() async {
    _isLoading = true;
    notifyListeners();
    try {
      _myGames = await _apiService.getGames();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGame() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentGame = await _apiService.createGame();
      if (_myGames != null) {
        _myGames!.add(_currentGame!);
      }
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinGame(String gameId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentGame = await _apiService.joinGame(gameId);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentGame() {
    _currentGame = null;
    _gameOver = false;
    _winner = null;
    _roomCode = null;
    notifyListeners();
  }

  void resetOnlineGameState() {
    _board = List.generate(15, (_) => List.filled(15, 0));
    _currentTurn = null;
    _playerX = null;
    _playerO = null;
    _gameOver = false;
    _winner = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}
