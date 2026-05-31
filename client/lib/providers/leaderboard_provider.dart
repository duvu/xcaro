import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class LeaderboardEntry {
  final int rank;
  final String username;
  final String avatar;
  final int eloRating;
  final int gamesPlayed;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.avatar,
    required this.eloRating,
    required this.gamesPlayed,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        username: json['username'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '',
        eloRating: (json['elo_rating'] as num?)?.toInt() ?? 1200,
        gamesPlayed: (json['games_played'] as num?)?.toInt() ?? 0,
      );
}

class LeaderboardProvider extends ChangeNotifier {
  List<LeaderboardEntry> _entries = [];
  bool _loading = false;
  String? _error;

  List<LeaderboardEntry> get entries => _entries;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchLeaderboard(ApiService api, {String? gameType}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await api.getLeaderboard(gameType: gameType);
      _entries = (data['leaderboard'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
