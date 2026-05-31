class PlayerSummary {
  final String id;
  final String username;
  final String? avatar;
  final String? bio;
  final int eloRating;
  final int rank;
  final String friendStatus;
  final String? friendRequestId;

  const PlayerSummary({
    required this.id,
    required this.username,
    this.avatar,
    this.bio,
    required this.eloRating,
    required this.rank,
    required this.friendStatus,
    this.friendRequestId,
  });

  factory PlayerSummary.fromJson(Map<String, dynamic> json) {
    return PlayerSummary(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      eloRating: (json['elo_rating'] as num?)?.toInt() ?? 1200,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      friendStatus: json['friend_status'] as String? ?? 'none',
      friendRequestId: json['friend_request_id'] as String?,
    );
  }
}

class DashboardGameRecord {
  final String id;
  final String gameType;
  final String roomId;
  final String result;
  final String? winner;
  final String? opponent;
  final String outcome;
  final DateTime createdAt;

  const DashboardGameRecord({
    required this.id,
    required this.gameType,
    required this.roomId,
    required this.result,
    this.winner,
    this.opponent,
    required this.outcome,
    required this.createdAt,
  });

  factory DashboardGameRecord.fromJson(Map<String, dynamic> json) {
    return DashboardGameRecord(
      id: json['id'] as String? ?? '',
      gameType: json['game_type'] as String? ?? 'caro',
      roomId: json['room_id'] as String? ?? '',
      result: json['result'] as String? ?? '',
      winner: json['winner'] as String?,
      opponent: json['opponent'] as String?,
      outcome: json['outcome'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class DashboardStats {
  final String gameType;
  final int wins;
  final int losses;
  final int draws;
  final int eloRating;
  final int rank;

  const DashboardStats({
    required this.gameType,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.eloRating,
    required this.rank,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      gameType: json['game_type'] as String? ?? 'caro',
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      eloRating: (json['elo_rating'] as num?)?.toInt() ?? 1200,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardSummary {
  final PlayerSummary profile;
  final DashboardStats stats;
  final List<DashboardGameRecord> recentGames;
  final int friendCount;
  final int incomingRequestCount;
  final int outgoingRequestCount;

  const DashboardSummary({
    required this.profile,
    required this.stats,
    required this.recentGames,
    required this.friendCount,
    required this.incomingRequestCount,
    required this.outgoingRequestCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      profile: PlayerSummary.fromJson(
          json['profile'] as Map<String, dynamic>? ?? const {}),
      stats: DashboardStats.fromJson(
          json['stats'] as Map<String, dynamic>? ?? const {}),
      recentGames: (json['recent_games'] as List<dynamic>? ?? const [])
          .map((record) =>
              DashboardGameRecord.fromJson(record as Map<String, dynamic>))
          .toList(),
      friendCount: (json['friend_count'] as num?)?.toInt() ?? 0,
      incomingRequestCount:
          (json['incoming_request_count'] as num?)?.toInt() ?? 0,
      outgoingRequestCount:
          (json['outgoing_request_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardHistoryResponse {
  final List<DashboardGameRecord> games;
  final int page;
  final int limit;
  final bool hasMore;

  const DashboardHistoryResponse({
    required this.games,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory DashboardHistoryResponse.fromJson(Map<String, dynamic> json) {
    return DashboardHistoryResponse(
      games: (json['games'] as List<dynamic>? ?? const [])
          .map((record) =>
              DashboardGameRecord.fromJson(record as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}

class FriendRequestSummary {
  final String id;
  final String status;
  final String requesterId;
  final String recipientId;
  final PlayerSummary requester;
  final PlayerSummary recipient;
  final DateTime createdAt;

  const FriendRequestSummary({
    required this.id,
    required this.status,
    required this.requesterId,
    required this.recipientId,
    required this.requester,
    required this.recipient,
    required this.createdAt,
  });

  factory FriendRequestSummary.fromJson(Map<String, dynamic> json) {
    return FriendRequestSummary(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      requesterId: json['requester_id'] as String? ?? '',
      recipientId: json['recipient_id'] as String? ?? '',
      requester: PlayerSummary.fromJson(
          json['requester'] as Map<String, dynamic>? ?? const {}),
      recipient: PlayerSummary.fromJson(
          json['recipient'] as Map<String, dynamic>? ?? const {}),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class FriendshipSummary {
  final PlayerSummary friend;
  final DateTime createdAt;

  const FriendshipSummary({required this.friend, required this.createdAt});

  factory FriendshipSummary.fromJson(Map<String, dynamic> json) {
    return FriendshipSummary(
      friend: PlayerSummary.fromJson(
          json['friend'] as Map<String, dynamic>? ?? const {}),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
