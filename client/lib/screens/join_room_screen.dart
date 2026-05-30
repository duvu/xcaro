import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      if (type == 'game_state') {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/online_game');
        }
      } else if (type == 'error') {
        final code = msg['payload']?['code'] as String?;
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
            _error = msg['payload']?['message'] as String? ?? 'Mã phòng không hợp lệ';
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
      final api = context.read<ApiService>();
      await api.joinRoom(code);
      // Wait for WS game_state to navigate
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Tham gia'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
