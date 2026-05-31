import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offline_ai_provider.dart';
import '../ai/ai_engine.dart';
import '../widgets/game_board.dart';
import '../models/user.dart';
import '../widgets/player_hud.dart';

class AiGameScreen extends StatelessWidget {
  const AiGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OfflineAiProvider(),
      child: const _AiGameView(),
    );
  }
}

class _AiGameView extends StatefulWidget {
  const _AiGameView();

  @override
  State<_AiGameView> createState() => _AiGameViewState();
}

class _AiGameViewState extends State<_AiGameView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDifficultySheet());
  }

  void _showDifficultySheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _DifficultySheet(
        provider: context.read<OfflineAiProvider>(),
        onSelected: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEndDialog(BuildContext context, OfflineAiProvider provider) {
    final winner = provider.winner;
    String message;
    if (winner == 1) {
      message = 'Bạn thắng! 🎉';
    } else if (winner == 2) {
      message = 'Máy thắng! 🤖';
    } else {
      message = 'Hòa! 🤝';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Kết thúc'),
          content: Text(message, style: const TextStyle(fontSize: 20)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                provider.resetGame();
                _showDifficultySheet();
              },
              child: const Text('Chơi lại'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Trang chủ'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chơi với máy (AI)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OfflineAiProvider>().resetGame();
              _showDifficultySheet();
            },
          ),
        ],
      ),
      body: Consumer<OfflineAiProvider>(
        builder: (context, provider, _) {
          if (provider.gameOver) {
            _showEndDialog(context, provider);
          }

          final diffLabel = switch (provider.difficulty) {
            AiDifficulty.easy => 'Dễ',
            AiDifficulty.medium => 'Trung bình',
            AiDifficulty.hard => 'Khó',
          };

          // Build pseudo User objects for PlayerHud
          final playerUser = User.fromJson(const {
            'id': '1',
            'username': 'Bạn',
            'email': '',
            'role': 'user',
            'is_banned': false,
            'games_played': 0,
            'games_won': 0,
            'rating': 1000,
            'created_at': '2024-01-01T00:00:00.000Z',
            'updated_at': '2024-01-01T00:00:00.000Z',
          });
          final aiUser = User.fromJson({
            'id': '2',
            'username': 'AI ($diffLabel)',
            'email': '',
            'role': 'user',
            'is_banned': false,
            'games_played': 0,
            'games_won': 0,
            'rating': 1000,
            'created_at': '2024-01-01T00:00:00.000Z',
            'updated_at': '2024-01-01T00:00:00.000Z',
          });
          final currentTurnId =
              provider.currentTurn == 1 ? '1' : '2';

          // Convert int board to String board for GameBoard
          final stringBoard = provider.board
              .map((row) => row
                  .map((v) => v == 1
                      ? 'X'
                      : v == 2
                          ? 'O'
                          : '')
                  .toList())
              .toList();

          return Column(
            children: [
              // PlayerHud with pulsing-glow on active player
              PlayerHud(
                playerX: playerUser,
                playerO: aiUser,
                currentTurnId: provider.aiThinking ? null : currentTurnId,
                myId: '1',
              ),
              // AI thinking indicator
              if (provider.aiThinking)
                const LinearProgressIndicator(),
              Expanded(
                child: GameBoard(
                  board: stringBoard,
                  onTap: (x, y) => provider.makeMove(x, y),
                  canTap: (x, y) =>
                      !provider.gameOver && !provider.aiThinking,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DifficultySheet extends StatefulWidget {
  final OfflineAiProvider provider;
  final VoidCallback onSelected;

  const _DifficultySheet({required this.provider, required this.onSelected});

  @override
  State<_DifficultySheet> createState() => _DifficultySheetState();
}

class _DifficultySheetState extends State<_DifficultySheet> {
  late AiDifficulty _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.provider.difficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Chọn độ khó',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          RadioListTile<AiDifficulty>(
            title: const Text('Dễ'),
            subtitle: const Text('AI tư duy nông, dễ thắng'),
            value: AiDifficulty.easy,
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v!),
          ),
          RadioListTile<AiDifficulty>(
            title: const Text('Trung bình'),
            subtitle: const Text('AI cân bằng'),
            value: AiDifficulty.medium,
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v!),
          ),
          RadioListTile<AiDifficulty>(
            title: const Text('Khó'),
            subtitle: const Text('AI tư duy sâu, thử thách'),
            value: AiDifficulty.hard,
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v!),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.provider.setDifficulty(_selected);
              widget.onSelected();
            },
            child: const Text('Bắt đầu'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
