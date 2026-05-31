import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/game_stats.dart';
import '../widgets/player_stats_card.dart';
import '../widgets/error_state_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class OpponentProfileScreen extends StatefulWidget {
  /// Provide [userId] to show a specific user's profile directly (tab usage).
  final String? userId;

  /// If true, hide the AppBar (used when embedded in MainScaffold tab).
  final bool showAsTab;

  const OpponentProfileScreen({
    super.key,
    this.userId,
    this.showAsTab = false,
  });

  @override
  State<OpponentProfileScreen> createState() => _OpponentProfileScreenState();
}

class _OpponentProfileScreenState extends State<OpponentProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _sendingFriendRequest = false;
  String? _error;
  String? _friendMessage;
  String? _resolvedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeArgs = ModalRoute.of(context)?.settings.arguments as String?;
    final id = widget.userId ?? routeArgs ?? '';
    if (id != _resolvedUserId) {
      _resolvedUserId = id;
      _fetchProfile(id);
    }
  }

  Future<void> _fetchProfile(String userId) async {
    if (userId.isEmpty) {
      // Current user own profile — try loading via AuthProvider
      final auth = context.read<AuthProvider>();
      final myId = auth.currentUser?.id;
      if (myId == null || myId.isEmpty) {
        setState(() {
          _loading = false;
          _profile = null;
        });
        return;
      }
      return _fetchProfile(myId);
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<ApiService>().getUserProfile(userId);
      if (mounted) setState(() => _profile = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendFriendRequest() async {
    final userId = _resolvedUserId;
    if (userId == null || userId.isEmpty || widget.showAsTab) return;
    setState(() {
      _sendingFriendRequest = true;
      _friendMessage = null;
    });
    try {
      await context.read<ApiService>().sendFriendRequest(userId);
      if (mounted) {
        setState(() => _friendMessage = 'Đã gửi lời mời kết bạn');
      }
    } catch (e) {
      if (mounted) setState(() => _friendMessage = e.toString());
    } finally {
      if (mounted) setState(() => _sendingFriendRequest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ErrorStateWidget(
        message: 'Không thể tải hồ sơ\n$_error',
        onRetry: () => _fetchProfile(_resolvedUserId ?? ''),
      );
    } else if (_profile == null) {
      body = const Center(child: Text('Không tìm thấy hồ sơ'));
    } else {
      body = _ProfileBody(
        profile: _profile!,
        isOwnProfile: widget.showAsTab,
        friendMessage: _friendMessage,
        sendingFriendRequest: _sendingFriendRequest,
        onSendFriendRequest: _sendFriendRequest,
      );
    }

    if (widget.showAsTab) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Text('Hồ sơ của tôi', style: AppTextStyles.headlineMedium),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ người chơi')),
      body: body,
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final Map<String, dynamic> profile;
  final bool isOwnProfile;
  final String? friendMessage;
  final bool sendingFriendRequest;
  final VoidCallback onSendFriendRequest;

  const _ProfileBody({
    required this.profile,
    this.isOwnProfile = false,
    this.friendMessage,
    required this.sendingFriendRequest,
    required this.onSendFriendRequest,
  });

  @override
  Widget build(BuildContext context) {
    final username = profile['username'] as String? ?? '';
    final avatar = profile['avatar'] as String? ?? '';
    final elo = (profile['elo_rating'] as num?)?.toInt() ?? 1200;
    final rank = (profile['rank'] as num?)?.toInt() ?? 0;
    final wins = (profile['wins'] as num?)?.toInt() ?? 0;
    final losses = (profile['losses'] as num?)?.toInt() ?? 0;
    final draws = (profile['draws'] as num?)?.toInt() ?? 0;
    final total = wins + losses + draws;
    final winRate = total > 0 ? wins / total : 0.0;
    final winRateLabel = '${(winRate * 100).toStringAsFixed(1)}%';
    final lastGames = profile['last_games'] as List<dynamic>? ?? [];

    final stats = GameStats(
        wins: wins, losses: losses, draws: draws, eloRating: elo, rank: rank);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Avatar with Hero animation
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Hero(
                  tag: 'avatar_$username',
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                    backgroundImage:
                        avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty
                        ? Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.displayLarge
                                .copyWith(color: AppColors.secondary),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(username, style: AppTextStyles.headlineMedium),
                Text(
                  '$elo Elo  •  Hạng #$rank',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.grey.shade600),
                ),
                if (!isOwnProfile) ...[
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed:
                        sendingFriendRequest ? null : onSendFriendRequest,
                    icon: sendingFriendRequest
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add),
                    label: const Text('Kết bạn'),
                  ),
                  if (friendMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(friendMessage!),
                    ),
                ],
              ],
            ),
          ),

          // PlayerStatsCard for overview
          PlayerStatsCard(
            stats: stats,
            username: username,
            avatarUrl: avatar,
          ),

          // Win rate bar
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tỉ lệ thắng',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.grey.shade600)),
                    Text(winRateLabel,
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.green)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: LinearProgressIndicator(
                    value: winRate,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ],
            ),
          ),

          // Last games section
          if (lastGames.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('5 trận gần nhất', style: AppTextStyles.titleLarge),
              ),
            ),
            ...lastGames.take(5).map((g) {
              final game = g as Map<String, dynamic>;
              final result = game['result'] as String? ?? '';
              final opponent = game['opponent'] as String? ?? '';
              final date = game['date'] as String? ?? '';
              Color rc = result == 'win'
                  ? Colors.green
                  : result == 'loss'
                      ? Colors.red
                      : Colors.orange;
              IconData ri = result == 'win'
                  ? Icons.emoji_events
                  : result == 'loss'
                      ? Icons.close
                      : Icons.handshake;
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: rc.withValues(alpha: 0.15),
                    child: Icon(ri, color: rc, size: 16),
                  ),
                  title: Text('vs $opponent', style: AppTextStyles.bodyMedium),
                  trailing: Text(date,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: Colors.grey.shade600)),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }
}
