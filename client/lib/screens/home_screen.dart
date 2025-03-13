import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../models/game.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    await context.read<GameProvider>().loadGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XCaro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, _) {
          if (gameProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final games = gameProvider.myGames;
          if (games == null || games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có trận đấu nào'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      gameProvider.createGame();
                      Navigator.pushNamed(context, '/game');
                    },
                    child: const Text('Tạo trận mới'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadGames,
            child: ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return ListTile(
                  title: Text('Trận đấu #${game.id}'),
                  subtitle: Text(
                    game.players.length == 1
                        ? 'Đang chờ đối thủ'
                        : 'Đấu với ${game.players[1].username}',
                  ),
                  trailing: game.players.length == 1
                      ? const Text('Đang chờ')
                      : Text(
                          game.status == 'finished'
                              ? 'Đã kết thúc'
                              : 'Đang diễn ra',
                        ),
                  onTap: () {
                    gameProvider.joinGame(game.id);
                    Navigator.pushNamed(context, '/game');
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<GameProvider>().createGame();
          Navigator.pushNamed(context, '/game');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
