import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class OpponentProfileScreen extends StatefulWidget {
  const OpponentProfileScreen({super.key});

  @override
  State<OpponentProfileScreen> createState() => _OpponentProfileScreenState();
}

class _OpponentProfileScreenState extends State<OpponentProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    _fetchProfile(userId);
  }

  Future<void> _fetchProfile(String userId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await context.read<ApiService>().getUserProfile(userId);
      if (mounted) setState(() => _profile = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ người chơi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _ProfileBody(profile: _profile!),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _ProfileBody({required this.profile});

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
    final winRate = total > 0 ? (wins / total * 100).toStringAsFixed(1) : '0.0';
    final lastGames = profile['last_games'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage:
                avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(username,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Text('$elo Elo  •  Hạng #$rank',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'Thắng', value: '$wins', color: Colors.green),
              _Stat(label: 'Thua', value: '$losses', color: Colors.red),
              _Stat(label: 'Hòa', value: '$draws', color: Colors.orange),
              _Stat(label: 'Tỉ lệ thắng', value: '$winRate%', color: Colors.blue),
            ],
          ),
          const SizedBox(height: 24),
          if (lastGames.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('5 trận gần nhất',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
            ),
            const SizedBox(height: 8),
            ...lastGames.take(5).map((g) {
              final game = g as Map<String, dynamic>;
              final result = game['result'] as String? ?? '';
              final opponent = game['opponent'] as String? ?? '';
              final date = game['date'] as String? ?? '';
              return ListTile(
                dense: true,
                leading: Icon(
                  result == 'win'
                      ? Icons.emoji_events
                      : result == 'loss'
                          ? Icons.close
                          : Icons.handshake,
                  color: result == 'win'
                      ? Colors.green
                      : result == 'loss'
                          ? Colors.red
                          : Colors.orange,
                ),
                title: Text('vs $opponent'),
                trailing: Text(date),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
