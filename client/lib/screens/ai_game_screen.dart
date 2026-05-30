import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offline_ai_provider.dart';
import '../ai/ai_engine.dart';

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

          final turnText = provider.aiThinking
              ? 'Máy đang suy nghĩ...'
              : provider.currentTurn == 1
                  ? 'Lượt của bạn (X)'
                  : 'Lượt của máy (O)';

          final cellSize =
              ((MediaQuery.of(context).size.width - 32) / 15).clamp(20.0, 40.0);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: provider.currentTurn == 1
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.aiThinking)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    if (provider.aiThinking) const SizedBox(width: 8),
                    Text(turnText,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Chip(label: Text(diffLabel)),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: cellSize * 15,
                    height: cellSize * 15,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 15,
                      ),
                      itemCount: 225,
                      itemBuilder: (context, index) {
                        final x = index ~/ 15;
                        final y = index % 15;
                        final val = provider.board[x][y];
                        return _AiCell(
                          value: val,
                          onTap: provider.gameOver || provider.aiThinking
                              ? null
                              : () => provider.makeMove(x, y),
                        );
                      },
                    ),
                  ),
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

class _AiCell extends StatefulWidget {
  final int value;
  final VoidCallback? onTap;

  const _AiCell({required this.value, this.onTap});

  @override
  State<_AiCell> createState() => _AiCellState();
}

class _AiCellState extends State<_AiCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  int _prevValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.value != 0) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_AiCell old) {
    super.didUpdateWidget(old);
    if (widget.value != 0 && _prevValue == 0) {
      _controller.forward(from: 0.0);
    }
    _prevValue = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.value == 1 ? Colors.blue : Colors.red;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          color: Colors.amber.shade50,
        ),
        child: widget.value == 0
            ? null
            : Center(
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
