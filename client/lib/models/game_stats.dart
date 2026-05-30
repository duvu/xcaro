class GameStats {
  final int wins;
  final int losses;
  final int draws;
  final int eloRating;
  final int rank;

  const GameStats({
    required this.wins,
    required this.losses,
    required this.draws,
    this.eloRating = 1200,
    this.rank = 0,
  });

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      eloRating: (json['elo_rating'] as num?)?.toInt() ?? 1200,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }

  int get total => wins + losses + draws;
}
