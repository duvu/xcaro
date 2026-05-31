import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/websocket_service.dart';

/// Chess lobby: supports both creating a new room and joining by code.
class ChessJoinScreen extends StatefulWidget {
  const ChessJoinScreen({super.key});

  @override
  State<ChessJoinScreen> createState() => _ChessJoinScreenState();
}

class _ChessJoinScreenState extends State<ChessJoinScreen> {
  bool _loading = false;
  String? _roomCode;
  String? _error;
  final _codeController = TextEditingController();
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    final ws = context.read<WebSocketService>();
    _wsSub = ws.onMessage.listen(_onWsMessage);
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    final payload = msg['payload'] is Map<String, dynamic>
        ? msg['payload'] as Map<String, dynamic>
        : null;

    if (type == AppConfig.gameStateEvent && payload != null) {
      final gameType = payload['game_type'] as String?;
      if (gameType != null && gameType != 'chess') return;

      final code = payload['room_code'] as String? ??
          payload['code'] as String? ??
          _roomCode;
      final started = payload['started'] == true ||
          payload['status'] == 'active' ||
          payload['status'] == 'finished';
      if (!mounted) return;
      setState(() {
        _roomCode = code;
        _loading = false;
      });
      if (started) {
        Navigator.pushReplacementNamed(context, '/chess_online');
      }
    } else if (type == AppConfig.errorEvent && payload != null) {
      final code = payload['code'] as String?;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _mapError(code, payload['message'] as String?);
      });
      if (code == 'email_not_verified') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng xác minh email trước.')),
        );
      }
    }
  }

  String _mapError(String? code, String? serverMsg) {
    switch (code) {
      case 'room_not_found':
        return 'Không tìm thấy phòng.';
      case 'room_full':
        return 'Phòng đã đủ người.';
      case 'email_not_verified':
        return 'Bạn chưa xác minh email.';
      default:
        return serverMsg ?? 'Có lỗi xảy ra.';
    }
  }

  void _createRoom() {
    final ws = context.read<WebSocketService>();
    if (!ws.isConnected) {
      setState(() => _error = 'Đang kết nối lại máy chủ, thử lại sau.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    ws.createRoom(gameType: 'chess');
  }

  void _joinRoom() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mã phòng.');
      return;
    }
    final ws = context.read<WebSocketService>();
    if (!ws.isConnected) {
      setState(() => _error = 'Đang kết nối lại máy chủ, thử lại sau.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    ws.sendJoinRoom(code, gameType: 'chess');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cờ Vua Online')),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  if (_roomCode != null) ...[
                    const Text('Đang chờ đối thủ...'),
                    const SizedBox(height: 8),
                    Text('Mã phòng: $_roomCode',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Chia sẻ mã này cho đối thủ.'),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() {
                        _loading = false;
                        _roomCode = null;
                      }),
                      child: const Text('Huỷ'),
                    ),
                  ] else
                    const Text('Đang kết nối...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Tạo phòng mới',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo phòng'),
                    onPressed: _createRoom,
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Tham gia bằng mã phòng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã phòng (6 ký tự)',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Tham gia'),
                    onPressed: _joinRoom,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
    );
  }
}
