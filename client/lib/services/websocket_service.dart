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
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 6;
  bool _disposed = false;

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<bool> get isConnectedStream => _connectedController.stream;
  bool get isConnected => _isConnected;

  void setToken(String? token) {
    _accessToken = token;
  }

  void connect() {
    if (_channel != null) return;
    if (_accessToken == null) return;

    try {
      final uri = Uri.parse('${AppConfig.wsUrl}?token=$_accessToken');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectedController.add(true);

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            final data = jsonDecode(message) as Map<String, dynamic>;
            _messageController.add(data);
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
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectTimer?.cancel();

    final delaySeconds = min(pow(2, _reconnectAttempts).toInt(), 30);
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _channel?.sink.close();
      _channel = null;
      connect();

      // After reconnect: re-authenticate and re-join room if needed
      if (_isConnected && _accessToken != null) {
        _sendAuth();
        if (_currentRoomId != null) {
          rejoinRoom(_currentRoomId!);
        }
      }
    });
  }

  void _sendAuth() {
    if (!_isConnected || _accessToken == null) return;
    _channel?.sink.add(jsonEncode({
      'type': 'auth',
      'payload': {'token': _accessToken},
    }));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void joinRoom(String gameId) {
    _currentRoomId = gameId;
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'type': AppConfig.joinRoomEvent,
      'payload': {'gameId': gameId},
    }));
  }

  void rejoinRoom(String gameId) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'type': 'rejoin_room',
      'payload': {'gameId': gameId},
    }));
  }

  void leaveRoom(String gameId) {
    _currentRoomId = null;
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'type': AppConfig.leaveRoomEvent,
      'payload': {'gameId': gameId},
    }));
  }

  void makeMove(int x, int y) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'type': 'make_move',
      'payload': {'x': x, 'y': y},
    }));
  }

  void createRoom() {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'type': 'create_room',
      'payload': {},
    }));
  }

  void sendJoinRoom(String code) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'type': 'join_room_by_code',
      'payload': {'code': code},
    }));
  }

  void sendChatMessage(String gameId, String content) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'type': AppConfig.chatEvent,
      'payload': {'gameId': gameId, 'content': content},
    }));
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
