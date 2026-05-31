import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_catalog_provider.dart';
import '../services/api_service.dart';
import '../models/dashboard_models.dart';
import '../models/game_stats.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/player_stats_card.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class HistoryScreen extends StatefulWidget {
  final bool showAsTab;

  const HistoryScreen({super.key, this.showAsTab = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<DashboardGameRecord> _games = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  GameStats? _stats;
  String? _resultFilter;
  String? _error;
  String? _loadedGameType;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final selectedGameType =
        Provider.of<GameCatalogProvider>(context).selectedGameType;
    if (_loadedGameType != selectedGameType) {
      _loadedGameType = selectedGameType;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadInitial();
      });
    }
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
      final gameType = context.read<GameCatalogProvider>().selectedGameType;
      final summary = await api.getDashboardSummary(gameType: gameType);
      final history = await api.getDashboardHistory(
        page: 1,
        limit: 20,
        gameType: gameType,
        result: _resultFilter,
      );
      setState(() {
        _error = null;
        _games.clear();
        _stats = GameStats(
          wins: summary.stats.wins,
          losses: summary.stats.losses,
          draws: summary.stats.draws,
          eloRating: summary.stats.eloRating,
          rank: summary.stats.rank,
        );
        final games = history.games;
        _games.addAll(games);
        _page = 2;
        _hasMore = history.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final gameType = context.read<GameCatalogProvider>().selectedGameType;
      final history = await api.getDashboardHistory(
        page: _page,
        limit: 20,
        gameType: gameType,
        result: _resultFilter,
      );
      setState(() {
        _error = null;
        _games.addAll(history.games);
        _page++;
        _hasMore = history.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setFilter(String? value) {
    setState(() {
      _resultFilter = value;
      _page = 1;
      _hasMore = true;
      _games.clear();
    });
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Game: ${context.watch<GameCatalogProvider>().selectedGame?.name ?? 'PlayVerse'}',
              style: AppTextStyles.labelLarge,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Stats card
        if (_stats != null)
          PlayerStatsCard(
            stats: _stats!,
            username: 'Bạn',
          )
        else
          const SizedBox.shrink(),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              _FilterChip(
                label: 'Tất cả',
                selected: _resultFilter == null,
                onSelected: () => _setFilter(null),
              ),
              _FilterChip(
                label: 'Thắng',
                selected: _resultFilter == 'win',
                onSelected: () => _setFilter('win'),
              ),
              _FilterChip(
                label: 'Thua',
                selected: _resultFilter == 'loss',
                onSelected: () => _setFilter('loss'),
              ),
              _FilterChip(
                label: 'Hòa',
                selected: _resultFilter == 'draw',
                onSelected: () => _setFilter('draw'),
              ),
            ],
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),

        // Games list
        Expanded(
          child: _games.isEmpty && !_loading
              ? EmptyStateWidget(
                  icon: Icons.history,
                  title: 'Chưa có trận đấu nào',
                  subtitle: 'Tham gia một trận để bắt đầu hành trình của bạn!',
                  actionLabel: 'Tạo phòng',
                  onAction: () => Navigator.pushNamed(context, '/create_room'),
                )
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
                    String result = 'Thua';
                    Color resultColor = Colors.blue;
                    IconData resultIcon = Icons.sports_esports;

                    if (game.outcome == 'draw') {
                      result = 'Hòa';
                      resultColor = Colors.orange;
                      resultIcon = Icons.handshake;
                    } else if (game.outcome == 'win') {
                      result = 'Thắng';
                      resultColor = Colors.green;
                      resultIcon = Icons.emoji_events;
                    } else {
                      resultColor = Colors.red;
                      resultIcon = Icons.close;
                    }

                    return _HistoryCard(
                      opponent: game.opponent ?? 'Đối thủ',
                      result: result,
                      resultColor: resultColor,
                      resultIcon: resultIcon,
                      date:
                          '${game.createdAt.day}/${game.createdAt.month}/${game.createdAt.year}',
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.showAsTab) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child:
                Text('Lịch sử trận đấu', style: AppTextStyles.headlineMedium),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử trận đấu')),
      body: body,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String opponent;
  final String result;
  final Color resultColor;
  final IconData resultIcon;
  final String date;

  const _HistoryCard({
    required this.opponent,
    required this.result,
    required this.resultColor,
    required this.resultIcon,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: resultColor.withValues(alpha: 0.15),
          child: Icon(resultIcon, color: resultColor, size: 20),
        ),
        title: Text('vs $opponent', style: AppTextStyles.bodyLarge),
        subtitle: Text(date,
            style:
                AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
        trailing: Chip(
          label: Text(
            result,
            style: AppTextStyles.labelSmall
                .copyWith(color: resultColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: resultColor.withValues(alpha: 0.1),
          side: BorderSide(color: resultColor.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}
