import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/websocket_service.dart';

class QuickMatchWaitingScreen extends StatefulWidget {
  const QuickMatchWaitingScreen({super.key});

  @override
  State<QuickMatchWaitingScreen> createState() =>
      _QuickMatchWaitingScreenState();
}

class _QuickMatchWaitingScreenState extends State<QuickMatchWaitingScreen> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    final wsService = context.read<WebSocketService>();
    _sub = wsService.onMessage.listen(_onMessage);
  }

  void _onMessage(Map<String, dynamic> msg) {
    if (!mounted) return;
    final type = msg['type'] as String?;
    if (type == 'quick_match_found') {
      final payload = msg['payload'] as Map<String, dynamic>? ?? {};
      context.read<GameProvider>().handleQuickMatchFound(payload);
      Navigator.pushReplacementNamed(context, '/online_game');
    } else if (type == 'quick_match_timeout') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không tìm được đối thủ. Thử lại sau.')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _cancel() {
    context
        .read<WebSocketService>()
        .send({'type': 'quick_match_cancel', 'payload': {}});
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm đối thủ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text('Đang tìm đối thủ...', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Tối đa 60 giây',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _cancel,
              icon: const Icon(Icons.close),
              label: const Text('Huỷ'),
            ),
          ],
        ),
      ),
    );
  }
}
