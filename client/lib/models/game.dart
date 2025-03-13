import 'user.dart';

class Game {
  final String id;
  final User creator;
  final User? opponent;
  final List<List<int>> board;
  final bool isFinished;
  final String? winner;
  final String currentTurn;
  final DateTime createdAt;

  Game({
    required this.id,
    required this.creator,
    this.opponent,
    required this.board,
    required this.isFinished,
    this.winner,
    required this.currentTurn,
    required this.createdAt,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String,
      creator: User.fromJson(json['creator'] as Map<String, dynamic>),
      opponent: json['opponent'] != null
          ? User.fromJson(json['opponent'] as Map<String, dynamic>)
          : null,
      board: (json['board'] as List<dynamic>)
          .map((row) =>
              (row as List<dynamic>).map((cell) => cell as int).toList())
          .toList(),
      isFinished: json['isFinished'] as bool,
      winner: json['winner'] as String?,
      currentTurn: json['currentTurn'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator': creator.toJson(),
      'opponent': opponent?.toJson(),
      'board': board,
      'isFinished': isFinished,
      'winner': winner,
      'currentTurn': currentTurn,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool canJoin(String userId) {
    return !isFinished && opponent == null && creator.id != userId;
  }

  bool canPlay(String userId) {
    return !isFinished &&
        opponent != null &&
        currentTurn == userId &&
        (creator.id == userId || opponent!.id == userId);
  }

  String? getWinnerName() {
    if (!isFinished || winner == null) return null;
    if (winner == creator.id) return creator.username;
    if (opponent != null && winner == opponent!.id) return opponent!.username;
    return null;
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
