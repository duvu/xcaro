class GameCatalogEntry {
  final String gameType;
  final String name;
  final String description;
  final String status;
  final int minPlayers;
  final int maxPlayers;
  final bool supportsOnline;
  final bool supportsOffline;
  final bool supportsAI;

  const GameCatalogEntry({
    required this.gameType,
    required this.name,
    required this.description,
    required this.status,
    required this.minPlayers,
    required this.maxPlayers,
    required this.supportsOnline,
    required this.supportsOffline,
    required this.supportsAI,
  });

  factory GameCatalogEntry.fromJson(Map<String, dynamic> json) {
    return GameCatalogEntry(
      gameType: json['game_type'] as String? ?? 'caro',
      name: json['name'] as String? ?? 'PlayVerse',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      minPlayers: json['min_players'] as int? ?? 1,
      maxPlayers: json['max_players'] as int? ?? 2,
      supportsOnline: json['supports_online'] == true,
      supportsOffline: json['supports_offline'] == true,
      supportsAI: json['supports_ai'] == true,
    );
  }

  bool get isActive => status == 'active';
}
