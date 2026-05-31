import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectedController = StreamController<bool>.broadcast();
  Timer? _reconnectTimer;
  bool _isConnected = false;
  String? _accessToken;
  String? _currentRoomId;
  String? _currentRoomCode;
  String _currentGameType = AppConfig.defaultGameType;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 6;
  bool _disposed = false;
  bool _manualDisconnect = false;

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<bool> get isConnectedStream => _connectedController.stream;
  bool get isConnected => _isConnected;

  void setToken(String? token) {
    _accessToken = token;
  }

  void setCurrentRoom({String? roomId, String? roomCode}) {
    if (roomId != null && roomId.isNotEmpty) {
      _currentRoomId = roomId;
    }
    if (roomCode != null && roomCode.isNotEmpty) {
      _currentRoomCode = roomCode;
    }
  }

  void clearCurrentRoom() {
    _currentRoomId = null;
    _currentRoomCode = null;
  }

  void setCurrentGameType(String gameType) {
    if (gameType.isEmpty) return;
    _currentGameType = gameType;
  }

  void connect() {
    if (_channel != null) return;
    if (_accessToken == null) return;

    try {
      _manualDisconnect = false;
      final uri = Uri.parse('${AppConfig.wsUrl}?token=$_accessToken');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectedController.add(true);

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            final decoded = jsonDecode(message);
            if (decoded is Map<String, dynamic>) {
              _syncRoomFromMessage(decoded);
              _messageController.add(decoded);
            }
          }
        },
        onError: (error) {
          _isConnected = false;
          _connectedController.add(false);
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _connectedController.add(false);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _connectedController.add(false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    if (_manualDisconnect) return;
    if (_accessToken == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectTimer?.cancel();

    final delaySeconds = min(pow(2, _reconnectAttempts).toInt(), 30);
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _channel?.sink.close();
      _channel = null;
      connect();

      if (_isConnected) {
        rejoinCurrentRoom();
      }
    });
  }

  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectedController.add(false);
  }

  void _send(String type, Map<String, dynamic> payload) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'type': type,
      'payload': payload,
    }));
  }

  void _syncRoomFromMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final payload = message['payload'];
    if (payload is! Map<String, dynamic>) return;

    if (type == AppConfig.gameStateEvent ||
        type == AppConfig.gameOverEvent ||
        type == AppConfig.quickMatchFoundEvent) {
      _syncRoomFromPayload(payload);

      final gameState = payload['game_state'];
      if (gameState is Map<String, dynamic>) {
        _syncRoomFromPayload(gameState);
      }
    }
  }

  void _syncRoomFromPayload(Map<String, dynamic> payload) {
    final roomId = payload['room_id'];
    if (roomId is String && roomId.isNotEmpty) {
      _currentRoomId = roomId;
    }

    final roomCode = payload['room_code'] ?? payload['code'];
    if (roomCode is String && roomCode.isNotEmpty) {
      _currentRoomCode = roomCode;
    }

    final gameType = payload['game_type'];
    if (gameType is String && gameType.isNotEmpty) {
      _currentGameType = gameType;
    }
  }

  void joinRoom(String code) {
    sendJoinRoom(code);
  }

  void rejoinRoom(String roomId, {String? gameType}) {
    setCurrentRoom(roomId: roomId);
    _send(AppConfig.rejoinRoomEvent,
        {'room_id': roomId, 'game_type': gameType ?? _currentGameType});
  }

  void rejoinCurrentRoom() {
    if (_currentRoomId != null) {
      _send(AppConfig.rejoinRoomEvent,
          {'room_id': _currentRoomId, 'game_type': _currentGameType});
      return;
    }

    if (_currentRoomCode != null) {
      _send(AppConfig.rejoinRoomEvent,
          {'code': _currentRoomCode, 'game_type': _currentGameType});
    }
  }

  void leaveRoom([String? roomId, String? gameType]) {
    final payload = <String, dynamic>{};
    final targetRoomId = roomId ?? _currentRoomId;
    if (targetRoomId != null) {
      payload['room_id'] = targetRoomId;
    }
    payload['game_type'] = gameType ?? _currentGameType;
    _send(AppConfig.leaveRoomEvent, payload);
    clearCurrentRoom();
  }

  void makeMove(int x, int y, {String? gameType}) {
    _send(AppConfig.moveEvent,
        {'x': x, 'y': y, 'game_type': gameType ?? _currentGameType});
  }

  void makeChessMove(String from, String to,
      {String? promotion, String? gameType}) {
    final payload = <String, dynamic>{
      'from': from,
      'to': to,
      'game_type': gameType ?? _currentGameType,
    };
    if (promotion != null) payload['promotion'] = promotion;
    _send(AppConfig.moveEvent, payload);
  }

  void createRoom({String? gameType}) {
    final selectedGameType = gameType ?? _currentGameType;
    setCurrentGameType(selectedGameType);
    _send(AppConfig.createRoomEvent, {'game_type': selectedGameType});
  }

  void sendJoinRoom(String code, {String? gameType}) {
    final selectedGameType = gameType ?? _currentGameType;
    setCurrentRoom(roomCode: code);
    setCurrentGameType(selectedGameType);
    _send(AppConfig.joinRoomByCodeEvent,
        {'code': code, 'game_type': selectedGameType});
  }

  void requestQuickMatch({String? gameType}) {
    final selectedGameType = gameType ?? _currentGameType;
    setCurrentGameType(selectedGameType);
    _send(AppConfig.quickMatchRequestEvent, {'game_type': selectedGameType});
  }

  void cancelQuickMatch() {
    _send(AppConfig.quickMatchCancelEvent, {});
  }

  void resign() {
    _send(AppConfig.resignEvent, {'game_type': _currentGameType});
  }

  void sendChatMessage(String content) {
    _send(AppConfig.chatEvent, {'content': content});
  }

  void send(Map<String, dynamic> message) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode(message));
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _messageController.close();
    _connectedController.close();
  }
}
