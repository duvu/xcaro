import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/leaderboard_provider.dart';
import '../services/api_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<LeaderboardProvider>()
          .fetchLeaderboard(context.read<ApiService>());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
      ),
      body: Consumer<LeaderboardProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return ErrorStateWidget(
              message: 'Không thể tải bảng xếp hạng\n${provider.error!}',
              onRetry: () =>
                  provider.fetchLeaderboard(context.read<ApiService>()),
            );
          }
          if (provider.entries.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.leaderboard,
              title: 'Chưa có người chơi',
              subtitle: 'Hãy là người đầu tiên lên bảng xếp hạng!',
            );
          }
          return ListView.builder(
            itemCount: provider.entries.length,
            itemBuilder: (context, index) {
              final entry = provider.entries[index];
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '#${entry.rank}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: entry.rank <= 3
                              ? Colors.amber
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundImage: entry.avatar.isNotEmpty
                          ? NetworkImage(entry.avatar)
                          : null,
                      child: entry.avatar.isEmpty
                          ? Text(entry.username.isNotEmpty
                              ? entry.username[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                  ],
                ),
                title: Text(entry.username),
                subtitle: Text('${entry.gamesPlayed} trận'),
                trailing: Text(
                  '${entry.eloRating} Elo',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/opponent_profile',
                  arguments: entry.username,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
