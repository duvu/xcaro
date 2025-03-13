import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offline_game_provider.dart';

class OfflineGameScreen extends StatelessWidget {
  const OfflineGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineProvider = context.watch<OfflineGameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chơi với máy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              offlineProvider.resetGame();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Game board
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final row = index ~/ 3;
                final col = index % 3;
                final value = offlineProvider.board[row][col];

                return GestureDetector(
                  onTap: () {
                    if (!offlineProvider.isGameOver && value.isEmpty) {
                      offlineProvider.makeMove(row, col);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Game status
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  offlineProvider.isGameOver
                      ? 'Trò chơi kết thúc: ${offlineProvider.winner ?? 'Hòa'}'
                      : 'Lượt của: ${offlineProvider.currentPlayer}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (offlineProvider.isGameOver)
                  ElevatedButton(
                    onPressed: () {
                      offlineProvider.resetGame();
                    },
                    child: const Text('Chơi lại'),
                  ),
              ],
            ),
          ),

          // Chat box
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: offlineProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = offlineProvider.messages[index];
                      return ListTile(
                        title: Text(message.content),
                        subtitle: Text(message.sender),
                      );
                    },
                  ),
                ),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      offlineProvider.addMessage(value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
