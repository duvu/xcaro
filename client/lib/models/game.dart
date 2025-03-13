import 'user.dart';

class Game {
  final String id;
  final List<User> players;
  final User currentPlayer;
  final List<List<String>> board;
  final String status;
  final User? winner;
  final DateTime createdAt;
  final DateTime updatedAt;

  Game({
    required this.id,
    required this.players,
    required this.currentPlayer,
    required this.board,
    required this.status,
    this.winner,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String,
      players: (json['players'] as List<dynamic>)
          .map((player) => User.fromJson(player as Map<String, dynamic>))
          .toList(),
      currentPlayer:
          User.fromJson(json['currentPlayer'] as Map<String, dynamic>),
      board: (json['board'] as List<dynamic>)
          .map((row) =>
              (row as List<dynamic>).map((cell) => cell as String).toList())
          .toList(),
      status: json['status'] as String,
      winner: json['winner'] != null
          ? User.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'players': players.map((player) => player.toJson()).toList(),
      'currentPlayer': currentPlayer.toJson(),
      'board': board,
      'status': status,
      'winner': winner?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool canJoin(String userId) {
    return status == 'waiting' && !players.any((player) => player.id == userId);
  }

  bool canPlay(String userId) {
    return status == 'playing' &&
        currentPlayer.id == userId &&
        players.any((player) => player.id == userId);
  }

  String? getWinnerName() {
    if (status != 'finished' || winner == null) return null;
    return winner!.username;
  }
}

class ChatMessage {
  final String id;
  final User sender;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.toJson(),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
