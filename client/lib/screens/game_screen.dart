import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/offline_game_provider.dart';
import '../services/local_storage_service.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('XCaro'),
        actions: [
          if (!isAuthenticated)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Đăng nhập'),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthProvider>().logout();
              },
            ),
        ],
      ),
      body: !isAuthenticated
          ? ChangeNotifierProvider(
              create: (context) => OfflineGameProvider(
                context.read<LocalStorageService>(),
              ),
              child: const OfflineGameView(),
            )
          : const OnlineGameView(),
    );
  }
}

class OfflineGameView extends StatelessWidget {
  const OfflineGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineGameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.currentGame == null) {
          return Center(
            child: ElevatedButton(
              onPressed: () => gameProvider.createGame(),
              child: const Text('Bắt đầu chơi'),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: GameBoard(
                board: gameProvider.currentGame!.board,
                onTap: (x, y) => gameProvider.makeMove(x, y),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Lượt: ${gameProvider.currentGame!.currentTurn == gameProvider.currentGame!.creator.id ? "X" : "O"}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (gameProvider.currentGame!.isFinished)
                    Text(
                      gameProvider.currentGame!.winner == null
                          ? 'Hòa!'
                          : 'Người thắng: ${gameProvider.currentGame!.winner == gameProvider.currentGame!.creator.id ? "X" : "O"}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ElevatedButton(
                    onPressed: () => gameProvider.createGame(),
                    child: const Text('Chơi lại'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class OnlineGameView extends StatelessWidget {
  const OnlineGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final game = gameProvider.currentGame;
        if (game == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => gameProvider.createGame(),
                  child: const Text('Tạo phòng mới'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                  child: const Text('Danh sách phòng'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: GameBoard(
                board: game.board,
                onTap: (x, y) => gameProvider.makeMove(x, y),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Lượt: ${game.currentTurn == game.creator.id ? "X" : "O"}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (game.isFinished)
                    Text(
                      game.winner == null
                          ? 'Hòa!'
                          : 'Người thắng: ${game.winner == game.creator.id ? "X" : "O"}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ElevatedButton(
                    onPressed: () {
                      gameProvider.clearCurrentGame();
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: const Text('Thoát'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
