import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
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
  bool _started = false;
  bool _gameOver = false;
  String? _winner; // 'X', 'O', 'draw', 'disconnect'
  String? _result; // 'resign', 'forfeit', 'draw', 'win', 'loss'
  String? _roomId;
  String? _roomCode;
  String _gameType = AppConfig.defaultGameType;
  String? _lastErrorCode;
  String? _lastErrorMessage;
  List<List<int>>? _winningCells; // list of [row, col] pairs
  String? _fen; // current FEN for chess games

  // Chat mute (client-side, session-scoped)
  bool _chatMuted = false;

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
  bool get started => _started;
  bool get gameOver => _gameOver;
  String? get winner => _winner;
  String? get result => _result;
  String? get roomId => _roomId;
  String? get roomCode => _roomCode;
  String get gameType => _gameType;
  bool get hasOnlineRoom =>
      _roomId != null || _roomCode != null || _currentGame != null;
  String? get lastErrorCode => _lastErrorCode;
  String? get lastErrorMessage => _lastErrorMessage;
  bool get chatMuted => _chatMuted;
  List<List<int>>? get winningCells => _winningCells;
  String? get fen => _fen;

  void _onWsMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    final payload = _mapValue(msg['payload']);

    if (type == AppConfig.gameStateEvent && payload != null) {
      _applyGameState(payload);
    } else if (type == AppConfig.gameOverEvent && payload != null) {
      _applyGameOver(payload);
    } else if (type == AppConfig.quickMatchFoundEvent && payload != null) {
      handleQuickMatchFound(payload);
    } else if (type == AppConfig.quickMatchTimeoutEvent ||
        type == AppConfig.quickMatchCancelledEvent) {
      _lastErrorCode = type;
      _lastErrorMessage = type == AppConfig.quickMatchTimeoutEvent
          ? 'Không tìm được đối thủ. Thử lại sau.'
          : 'Đã huỷ tìm đối thủ.';
      notifyListeners();
    } else if (type == AppConfig.errorEvent && payload != null) {
      _lastErrorCode = payload['code'] as String?;
      _lastErrorMessage = payload['message'] as String?;
      notifyListeners();
    } else if (type == AppConfig.chatEvent && payload != null) {
      chatProvider.addMessage(payload);
    }
  }

  void _applyGameState(Map<String, dynamic> payload, {bool notify = true}) {
    _roomId = _stringValue(payload['room_id']) ?? _roomId;
    _roomCode = _stringValue(payload['room_code']) ??
        _stringValue(payload['code']) ??
        _roomCode;
    _gameType = _stringValue(payload['game_type']) ?? _gameType;

    final rawBoard = payload['board'];
    if (rawBoard != null) {
      _board = _parseBoard(rawBoard);
    }

    // FEN for chess games
    final rawFen = _stringValue(payload['fen']);
    if (rawFen != null && rawFen.isNotEmpty) {
      _fen = rawFen;
    }

    final players = _mapValue(payload['players']);
    final playerXPayload = payload['player_x'] ?? players?['x'];
    final playerOPayload = payload['player_o'] ?? players?['o'];
    final playerX = _onlineUserFromPayload(playerXPayload);
    final playerO = _onlineUserFromPayload(playerOPayload);
    if (playerX != null) {
      _playerX = playerX;
    }
    if (playerO != null) {
      _playerO = playerO;
    }

    _started = payload['started'] == true ||
        payload['status'] == 'active' ||
        payload['status'] == 'finished';
    _gameOver = payload['game_over'] == true || payload['status'] == 'finished';
    _winner = _stringValue(payload['winner']);
    _result = _stringValue(payload['result']);

    final currentTurn = _stringValue(payload['current_turn']);
    if (currentTurn != null && currentTurn.isNotEmpty) {
      _currentTurn = currentTurn;
    } else {
      final turn = _intValue(payload['turn']);
      if (turn == 1) {
        _currentTurn = _playerX?.id;
      } else if (turn == 2) {
        _currentTurn = _playerO?.id;
      }
    }

    final rawWinCells = payload['winning_cells'];
    if (rawWinCells != null) {
      _winningCells = _parseCells(rawWinCells);
    } else if (!_gameOver) {
      _winningCells = null;
    }

    _lastErrorCode = null;
    _lastErrorMessage = null;
    _wsService.setCurrentRoom(roomId: _roomId, roomCode: _roomCode);
    if (notify) notifyListeners();
  }

  void _applyGameOver(Map<String, dynamic> payload) {
    _applyGameState(payload, notify: false);
    _gameOver = true;
    _winner = _stringValue(payload['winner']);
    _result = _stringValue(payload['result']);
    notifyListeners();
  }

  /// Called when quick_match_found is received; sets roomCode and resets board.
  void handleQuickMatchFound(Map<String, dynamic> payload) {
    final gameState = _mapValue(payload['game_state']);
    if (gameState != null) {
      _applyGameState(gameState, notify: false);
    }
    _roomId = _stringValue(payload['room_id']) ?? _roomId;
    _roomCode = _stringValue(payload['room_code']) ?? _roomCode;
    _result = null;
    _winner = null;
    _gameOver = false;
    _started = true;
    _lastErrorCode = null;
    _lastErrorMessage = null;
    _wsService.setCurrentRoom(roomId: _roomId, roomCode: _roomCode);
    notifyListeners();
  }

  Map<String, dynamic>? _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  String? _stringValue(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  List<List<int>> _parseBoard(Object rawBoard) {
    if (rawBoard is! List) return _board;

    return rawBoard.map((row) {
      if (row is! List) return List<int>.filled(15, 0);
      return row.map((cell) => _intValue(cell) ?? 0).toList();
    }).toList();
  }

  List<List<int>> _parseCells(Object rawCells) {
    if (rawCells is! List) return const [];

    return rawCells
        .whereType<List>()
        .map((cell) => cell.map((value) => _intValue(value) ?? 0).toList())
        .toList();
  }

  User? _onlineUserFromPayload(Object? raw) {
    final data = _mapValue(raw);
    if (data == null) return null;

    final id = _stringValue(data['id']) ?? _stringValue(data['user_id']);
    if (id == null) return null;

    final now = DateTime.now();
    final username = _stringValue(data['username']) ?? id;
    return User(
      id: id,
      username: username,
      email: _stringValue(data['email']) ?? '',
      role: _stringValue(data['role']) ?? 'player',
      emailVerified: data['email_verified'] == true,
      isBanned: data['is_banned'] == true,
      gamesPlayed: _intValue(data['games_played']) ?? 0,
      gamesWon: _intValue(data['games_won']) ?? 0,
      rating: _intValue(data['rating']) ?? 1000,
      createdAt: now,
      updatedAt: now,
    );
  }

  void toggleChatMute() {
    _chatMuted = !_chatMuted;
    notifyListeners();
  }

  void makeMove(int x, int y) {
    _wsService.makeMove(x, y, gameType: _gameType);
  }

  void makeChessMove(String from, String to, {String? promotion}) {
    _wsService.makeChessMove(from, to,
        promotion: promotion, gameType: _gameType);
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
    _roomId = null;
    _gameType = AppConfig.defaultGameType;
    _gameOver = false;
    _winner = null;
    _result = null;
    _roomCode = null;
    _started = false;
    _winningCells = null;
    _fen = null;
    _wsService.clearCurrentRoom();
    chatProvider.clear();
    notifyListeners();
  }

  void resetOnlineGameState() {
    _board = List.generate(15, (_) => List.filled(15, 0));
    _currentTurn = null;
    _playerX = null;
    _playerO = null;
    _started = false;
    _gameOver = false;
    _winner = null;
    _result = null;
    _roomId = null;
    _roomCode = null;
    _gameType = AppConfig.defaultGameType;
    _winningCells = null;
    _fen = null;
    _lastErrorCode = null;
    _lastErrorMessage = null;
    _wsService.clearCurrentRoom();
    chatProvider.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}
