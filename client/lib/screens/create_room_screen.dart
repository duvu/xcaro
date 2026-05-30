import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  bool _loading = false;
  String? _roomCode;
  String? _error;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    final ws = context.read<WebSocketService>();
    _wsSub = ws.onMessage.listen((msg) {
      final type = msg['type'] as String?;
      if (type == 'room_created') {
        setState(() {
          _roomCode = msg['payload']?['code'] as String?;
          _loading = false;
        });
      } else if (type == 'game_state') {
        // Opponent joined, navigate to game
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
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final result = await api.createRoom();
      setState(() {
        _roomCode = result['code'] as String?;
        _loading = false;
      });
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
      appBar: AppBar(title: const Text('Tạo phòng')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline,
                  size: 80, color: Colors.deepPurple),
              const SizedBox(height: 24),
              if (_roomCode == null) ...[
                ElevatedButton.icon(
                  onPressed: _loading ? null : _createRoom,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  label: const Text('Tạo phòng mới'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                  ),
                ),
              ] else ...[
                const Text('Mã phòng của bạn:', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple),
                  ),
                  child: Text(
                    _roomCode!,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Share invite button
                OutlinedButton.icon(
                  onPressed: () => Share.share(
                    'Tham gia phòng XCaro của mình: $_roomCode\nxcaro://room/$_roomCode',
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Chia sẻ mã phòng'),
                ),
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Đang chờ đối thủ...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
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
