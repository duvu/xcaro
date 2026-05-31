import 'package:flutter/material.dart';
import '../models/game_stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Shared horizontal stats card used on Home, History, and Profile screens.
/// Shows avatar | username | Elo | Rank | W/L/D totals.
class PlayerStatsCard extends StatelessWidget {
  final GameStats stats;
  final String username;
  final String? avatarUrl;
  final VoidCallback? onTap;

  const PlayerStatsCard({
    super.key,
    required this.stats,
    required this.username,
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    AppColors.secondary.withValues(alpha: 0.2),
                backgroundImage:
                    avatarUrl != null && avatarUrl!.isNotEmpty
                        ? NetworkImage(avatarUrl!)
                        : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Text(
                        username.isNotEmpty
                            ? username[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.titleLarge
                            .copyWith(color: AppColors.secondary),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: AppTextStyles.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _Pill(
                          label: '${stats.eloRating} Elo',
                          color: AppColors.secondary,
                        ),
                        if (stats.rank > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _Pill(
                            label: '#${stats.rank}',
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // W/L/D
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatRow(
                      label: 'T', value: stats.wins, color: Colors.green),
                  _StatRow(
                      label: 'B', value: stats.losses, color: Colors.red),
                  _StatRow(
                      label: 'H', value: stats.draws, color: Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall
            .copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: Colors.grey.shade600)),
        const SizedBox(width: 4),
        Text('$value',
            style: AppTextStyles.labelLarge
                .copyWith(color: color)),
      ],
    );
  }
}
