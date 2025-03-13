import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String? avatar;
  final int score;
  final int gamesPlayed;
  final int gamesWon;
  final int wins;
  final int losses;
  final int draws;

  const User({
    required this.id,
    required this.username,
    this.avatar,
    this.score = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String?,
      score: json['score'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'score': score,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'wins': wins,
      'losses': losses,
      'draws': draws,
    };
  }

  @override
  List<Object?> get props =>
      [id, username, avatar, score, gamesPlayed, gamesWon, wins, losses, draws];

  User copyWith({
    String? id,
    String? username,
    String? avatar,
    int? score,
    int? gamesPlayed,
    int? gamesWon,
    int? wins,
    int? losses,
    int? draws,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      score: score ?? this.score,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
    );
  }
}
