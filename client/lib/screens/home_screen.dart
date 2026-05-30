import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_stats.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../widgets/empty_state_widget.dart';
import 'quick_match_waiting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final gameProvider = context.read<GameProvider>();
    final auth = context.read<AuthProvider>();
    final apiService = context.read<ApiService>();

    try {
      await gameProvider.loadGames();
    } catch (_) {}
    try {
      final userId = auth.currentUser?.id;
      if (userId != null) {
        final stats = await apiService.getGameStats(userId);
        if (mounted) setState(() => _stats = stats);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('XCaro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.pushNamed(context, '/onboarding'),
            tooltip: 'Hướng dẫn chơi',
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
            tooltip: 'Bảng xếp hạng',
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Đổi theme',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: 'Lịch sử',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // WS connection status chip
          StreamBuilder<bool>(
            stream: context.read<WebSocketService>().isConnectedStream,
            initialData: context.read<WebSocketService>().isConnected,
            builder: (context, snap) {
              final connected = snap.data ?? false;
              return Container(
                width: double.infinity,
                color: connected
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.circle,
                        size: 10,
                        color: connected ? Colors.green : Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      connected ? 'Đã kết nối' : 'Đang kết nối lại...',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
          // Stats row
          if (_stats != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                      label: 'Thắng', value: _stats!.wins, color: Colors.green),
                  _StatItem(
                      label: 'Thua', value: _stats!.losses, color: Colors.red),
                  _StatItem(
                      label: 'Hòa', value: _stats!.draws, color: Colors.orange),
                  _StatItemText(
                      label: 'Elo',
                      value: '${_stats!.eloRating}',
                      color: Colors.purple),
                  if (_stats!.rank > 0)
                    _StatItemText(
                        label: 'Hạng',
                        value: '#${_stats!.rank}',
                        color: Colors.indigo),
                ],
              ),
            ),
          // Action buttons — row 1
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/create_room'),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo phòng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/join_room'),
                    icon: const Icon(Icons.login),
                    label: const Text('Vào phòng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/ai_game'),
                    icon: const Icon(Icons.computer),
                    label: const Text('Chơi với máy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Action buttons — row 2: Quick Match
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context
                      .read<WebSocketService>()
                      .send({'type': 'quick_match_request', 'payload': {}});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const QuickMatchWaitingScreen()),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Tìm đối thủ nhanh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
          // Games list
          Expanded(
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, _) {
                if (gameProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final games = gameProvider.myGames;
                if (games == null || games.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.sports_esports,
                    title: 'Chưa có trận đấu nào',
                    subtitle:
                        'Tạo phòng hoặc tìm đối thủ nhanh để bắt đầu!',
                    actionLabel: 'Tạo phòng',
                    onAction: () =>
                        Navigator.pushNamed(context, '/create_room'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      return ListTile(
                        leading: const Icon(Icons.sports_esports),
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
                          Navigator.pushNamed(context, '/online_game');
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StatItemText extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItemText(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
