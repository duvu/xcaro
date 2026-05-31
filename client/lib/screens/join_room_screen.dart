import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    final ws = context.read<WebSocketService>();
    _wsSub = ws.onMessage.listen((msg) {
      final type = msg['type'] as String?;
      final payload = msg['payload'] is Map<String, dynamic>
          ? msg['payload'] as Map<String, dynamic>
          : null;

      if (type == AppConfig.gameStateEvent) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/online_game');
      } else if (type == AppConfig.errorEvent && payload != null) {
        if (!mounted) return;
        final code = payload['code'] as String?;
        if (code == 'email_not_verified') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Vui lòng xác minh email để chơi online'),
                action: SnackBarAction(
                  label: 'Gửi lại',
                  onPressed: () =>
                      context.read<ApiService>().resendVerification(),
                ),
              ),
            );
            setState(() => _loading = false);
          }
        } else {
          setState(() {
            _error = _errorMessage(code, payload['message'] as String?);
            _loading = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Mã phòng phải có 6 ký tự');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ws = context.read<WebSocketService>();
      if (!ws.isConnected) {
        throw Exception('Đang kết nối lại máy chủ, vui lòng thử lại.');
      }
      ws.sendJoinRoom(code);
      // Wait for WS game_state to navigate.
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _errorMessage(String? code, String? fallback) {
    switch (code) {
      case 'room_not_found':
        return 'Không tìm thấy phòng';
      case 'room_full':
        return 'Phòng đã đủ người';
      case 'already_queued':
        return 'Bạn đang trong hàng đợi tìm đối thủ';
      default:
        return fallback ?? 'Mã phòng không hợp lệ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tham gia phòng')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã phòng (6 ký tự)',
                  border: OutlineInputBorder(),
                  hintText: 'Nhập mã phòng...',
                ),
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _joinRoom(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loading ? null : _joinRoom,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Tham gia'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
