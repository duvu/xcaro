import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../games/game_registry.dart';
import '../config/app_config.dart';
import '../models/game_catalog.dart';
import '../providers/auth_provider.dart';
import '../providers/game_catalog_provider.dart';
import '../providers/game_provider.dart';
import '../models/game_stats.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/player_stats_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'quick_match_waiting_screen.dart';

/// The home tab content inside MainScaffold.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  GameStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final catalogProvider = context.read<GameCatalogProvider>();
    final gameProvider = context.read<GameProvider>();
    final auth = context.read<AuthProvider>();
    final apiService = context.read<ApiService>();

    try {
      await gameProvider.loadGames();
    } catch (_) {}
    try {
      await catalogProvider.loadCatalog();
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
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<GameCatalogProvider>();
    final user = auth.currentUser;
    final ws = context.read<WebSocketService>();
    final selectedGame = catalog.selectedGame;
    final selectedModule =
        GameRegistry.find(selectedGame?.gameType ?? AppConfig.defaultGameType);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          // WS chip — hidden when connected, slides in when disconnected
          StreamBuilder<bool>(
            stream: ws.isConnectedStream,
            initialData: ws.isConnected,
            builder: (context, snap) {
              final connected = snap.data ?? false;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                height: connected ? 0 : 36,
                child: ClipRect(
                  child: Container(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.circle,
                            size: 8, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Đang kết nối lại...',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Stats card
          if (_stats != null && user != null)
            PlayerStatsCard(
              stats: _stats!,
              username: user.username,
            ),
          if (_stats == null && user != null)
            const Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Text('Mini game', style: AppTextStyles.titleLarge),
          ),

          if (catalog.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: LinearProgressIndicator(),
            )
          else if (catalog.games.isNotEmpty)
            SizedBox(
              height: 140,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final game = catalog.games[index];
                  return _GameCatalogCard(
                    game: game,
                    selected: game.gameType == catalog.selectedGameType,
                    onTap: () {
                      catalog.selectGame(game.gameType);
                      ws.setCurrentGameType(game.gameType);
                    },
                  );
                },
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemCount: catalog.games.length,
              ),
            ),

          // 2×2 action grid
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.6,
              children: [
                _ActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'Tạo phòng',
                  onTap: () {
                    if (!_supportsSelected(selectedGame, online: true)) {
                      _showComingSoon(context);
                      return;
                    }
                    ws.setCurrentGameType(
                        selectedGame?.gameType ?? AppConfig.defaultGameType);
                    Navigator.pushNamed(context,
                        selectedModule?.createRoomRoute ?? '/create_room');
                  },
                ),
                _ActionCard(
                  icon: Icons.login,
                  label: 'Vào phòng',
                  onTap: () {
                    if (!_supportsSelected(selectedGame, online: true)) {
                      _showComingSoon(context);
                      return;
                    }
                    ws.setCurrentGameType(
                        selectedGame?.gameType ?? AppConfig.defaultGameType);
                    Navigator.pushNamed(
                        context, selectedModule?.joinRoomRoute ?? '/join_room');
                  },
                ),
                _ActionCard(
                  icon: Icons.computer,
                  label: 'Chơi với máy',
                  color: AppColors.success,
                  onTap: () {
                    if (!_supportsSelected(selectedGame, ai: true)) {
                      _showComingSoon(context);
                      return;
                    }
                    ws.setCurrentGameType(
                        selectedGame?.gameType ?? AppConfig.defaultGameType);
                    Navigator.pushNamed(
                        context, selectedModule?.aiRoute ?? '/ai_game');
                  },
                ),
                _ActionCard(
                  icon: Icons.bolt,
                  label: 'Tìm đối thủ',
                  color: AppColors.secondary,
                  textColor: AppColors.primary,
                  onTap: () {
                    final ws = context.read<WebSocketService>();
                    if (!ws.isConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Đang kết nối lại máy chủ, vui lòng thử lại.'),
                        ),
                      );
                      return;
                    }
                    if (!_supportsSelected(selectedGame, online: true)) {
                      _showComingSoon(context);
                      return;
                    }
                    context.read<GameProvider>().resetOnlineGameState();
                    ws.requestQuickMatch(
                        gameType: selectedGame?.gameType ??
                            AppConfig.defaultGameType);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QuickMatchWaitingScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Games list header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Text('Trận đấu gần đây', style: AppTextStyles.titleLarge),
          ),

          // Games list
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              if (gameProvider.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final games = gameProvider.myGames;
              if (games == null || games.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.sports_esports,
                  title: 'Chưa có trận đấu nào',
                  subtitle: 'Tạo phòng hoặc tìm đối thủ nhanh để bắt đầu!',
                  actionLabel: 'Tạo phòng',
                  onAction: () => Navigator.pushNamed(context, '/create_room'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return _GameListCard(
                    gameId: game.id,
                    opponentName: game.players.length > 1
                        ? game.players[1].username
                        : 'Đang chờ đối thủ',
                    status: game.status,
                    onTap: () {
                      gameProvider.joinGame(game.id);
                      Navigator.pushNamed(context, '/online_game');
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  bool _supportsSelected(GameCatalogEntry? game,
      {bool online = false, bool ai = false}) {
    if (game == null) return false;
    if (online && !game.supportsOnline) return false;
    if (ai && !game.supportsAI) return false;
    return game.isActive;
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Game này chưa sẵn sàng trong bản hiện tại.'),
      ),
    );
  }
}

/// Kept for backward-compat where HomeScreen is still referenced directly.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const MainScaffoldProxy();
}

/// A thin proxy that renders MainScaffold when HomeScreen route is pushed.
class MainScaffoldProxy extends StatelessWidget {
  const MainScaffoldProxy({super.key});

  @override
  Widget build(BuildContext context) {
    // Import here to avoid circular references — MainScaffold imports HomeTab.
    return const _MainScaffoldInline();
  }
}

// Inline simple nav scaffold that HomeScreen can use when navigated to directly
class _MainScaffoldInline extends StatefulWidget {
  const _MainScaffoldInline();

  @override
  State<_MainScaffoldInline> createState() => _MainScaffoldInlineState();
}

class _MainScaffoldInlineState extends State<_MainScaffoldInline> {
  @override
  Widget build(BuildContext context) {
    // Delegate to the proper MainScaffold defined in main_scaffold.dart
    // We just push replacement to avoid double scaffold
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Private widgets
// ──────────────────────────────────────────────────────────

class _GameCatalogCard extends StatelessWidget {
  final GameCatalogEntry game;
  final bool selected;
  final VoidCallback onTap;

  const _GameCatalogCard({
    required this.game,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.18)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.secondary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(game.name, style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              game.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium,
            ),
            const Spacer(),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _GameTag(label: game.gameType),
                if (game.supportsOnline) const _GameTag(label: 'Online'),
                if (game.supportsAI) const _GameTag(label: 'AI'),
                if (game.supportsOffline) const _GameTag(label: 'Offline'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTag extends StatelessWidget {
  final String label;

  const _GameTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color? textColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;
    final labelColor = textColor ?? Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: labelColor, size: 28),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(color: labelColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameListCard extends StatelessWidget {
  final String gameId;
  final String opponentName;
  final String status;
  final VoidCallback onTap;

  const _GameListCard({
    required this.gameId,
    required this.opponentName,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.sports_esports, color: Colors.white, size: 20),
        ),
        title: Text('vs $opponentName', style: AppTextStyles.bodyLarge),
        subtitle: Text(
          status == 'finished' ? 'Đã kết thúc' : 'Đang diễn ra',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: onTap,
      ),
    );
  }
}
