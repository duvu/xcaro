import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_catalog_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../services/api_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool showAsTab;

  const LeaderboardScreen({super.key, this.showAsTab = false});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String? _loadedGameType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLeaderboard();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final selectedGameType =
        Provider.of<GameCatalogProvider>(context).selectedGameType;
    if (_loadedGameType != selectedGameType) {
      _loadedGameType = selectedGameType;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchLeaderboard();
      });
    }
  }

  void _fetchLeaderboard() {
    context.read<LeaderboardProvider>().fetchLeaderboard(
          context.read<ApiService>(),
          gameType: context.read<GameCatalogProvider>().selectedGameType,
        );
  }

  @override
  Widget build(BuildContext context) {
    final body = Consumer<LeaderboardProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return ErrorStateWidget(
            message: 'Không thể tải bảng xếp hạng\n${provider.error!}',
            onRetry: _fetchLeaderboard,
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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: provider.entries.length,
          itemBuilder: (context, index) {
            final entry = provider.entries[index];
            return _LeaderboardCard(
              entry: entry,
              rank: index + 1,
            );
          },
        );
      },
    );

    if (widget.showAsTab) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bảng xếp hạng', style: AppTextStyles.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Game: ${context.watch<GameCatalogProvider>().selectedGame?.name ?? 'PlayVerse'}',
                  style: AppTextStyles.labelLarge,
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bảng xếp hạng')),
      body: body,
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final dynamic entry;
  final int rank;

  const _LeaderboardCard({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: AppSpacing.sm),
            Hero(
              tag: 'avatar_${entry.username}',
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                backgroundImage:
                    entry.avatar.isNotEmpty ? NetworkImage(entry.avatar) : null,
                child: entry.avatar.isEmpty
                    ? Text(
                        entry.username.isNotEmpty
                            ? entry.username[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: isTop3 ? 14 : 12,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
        title: Text(
          entry.username,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${entry.gamesPlayed} trận',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            '${entry.eloRating} Elo',
            style:
                AppTextStyles.labelLarge.copyWith(color: AppColors.secondary),
          ),
        ),
        onTap: () => Navigator.pushNamed(
          context,
          '/opponent_profile',
          arguments: entry.username,
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 20));
    } else if (rank == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 20));
    } else if (rank == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 20));
    }
    return SizedBox(
      width: 28,
      child: Text(
        '#$rank',
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600),
      ),
    );
  }
}
