import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/game.dart';
import '../models/game_stats.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Game> _games = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  GameStats? _stats;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;
      if (userId != null) {
        final stats = await api.getGameStats(userId);
        setState(() => _stats = stats);
      }
      final games = await api.getGames(page: 1, limit: 20, userId: userId);
      setState(() {
        _games.addAll(games);
        _page = 2;
        _hasMore = games.length == 20;
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;
      final games = await api.getGames(page: _page, limit: 20, userId: userId);
      setState(() {
        _games.addAll(games);
        _page++;
        _hasMore = games.length == 20;
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử trận đấu')),
      body: Column(
        children: [
          if (_stats != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(label: 'Thắng', value: _stats!.wins, color: Colors.green),
                  _StatChip(label: 'Thua', value: _stats!.losses, color: Colors.red),
                  _StatChip(label: 'Hòa', value: _stats!.draws, color: Colors.orange),
                ],
              ),
            ),
          Expanded(
            child: _games.isEmpty && !_loading
                ? const Center(child: Text('Chưa có trận đấu nào'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _games.length + (_loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _games.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final game = _games[index];
                      final auth = context.read<AuthProvider>();
                      final myId = auth.currentUser?.id;
                      final isWinner = game.winner?.id == myId;
                      final isDraw =
                          game.status == 'finished' && game.winner == null;
                      String result = 'Đang diễn ra';
                      Color resultColor = Colors.blue;
                      if (game.status == 'finished') {
                        if (isDraw) {
                          result = 'Hòa';
                          resultColor = Colors.orange;
                        } else if (isWinner) {
                          result = 'Thắng';
                          resultColor = Colors.green;
                        } else {
                          result = 'Thua';
                          resultColor = Colors.red;
                        }
                      }
                      final opponentName = game.players
                          .where((p) => p.id != myId)
                          .map((p) => p.username)
                          .firstOrNull ?? 'Đối thủ';
                      return ListTile(
                        leading: Icon(Icons.sports_esports,
                            color: resultColor),
                        title: Text('vs $opponentName'),
                        subtitle: Text(
                            '${game.createdAt.day}/${game.createdAt.month}/${game.createdAt.year}'),
                        trailing: Text(
                          result,
                          style: TextStyle(
                              color: resultColor, fontWeight: FontWeight.bold),
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

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
