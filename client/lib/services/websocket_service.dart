import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class WebSocketService {
  final SharedPreferences _prefs;
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  bool _isConnected = false;

  WebSocketService(this._prefs);

  Stream<Map<String, dynamic>> get onMessage => _controller.stream;
  bool get isConnected => _isConnected;

  void connect() {
    if (_channel != null) return;

    final token = _prefs.getString(AppConfig.tokenKey);
    if (token == null) return;

    try {
      final uri = Uri.parse('${AppConfig.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            final data = jsonDecode(message) as Map<String, dynamic>;
            _controller.add(data);
          }
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(AppConfig.reconnectDelay, () {
      disconnect();
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void joinRoom(String gameId) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'event': AppConfig.joinRoomEvent,
      'data': {'gameId': gameId},
    }));
  }

  void leaveRoom(String gameId) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'event': AppConfig.leaveRoomEvent,
      'data': {'gameId': gameId},
    }));
  }

  void makeMove(String gameId, int row, int col) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'event': AppConfig.moveEvent,
      'data': {
        'gameId': gameId,
        'row': row,
        'col': col,
      },
    }));
  }

  void sendChatMessage(String gameId, String content) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'event': AppConfig.chatEvent,
      'data': {
        'gameId': gameId,
        'content': content,
      },
    }));
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
