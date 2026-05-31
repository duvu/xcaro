class GameModule {
  final String gameType;
  final String createRoomRoute;
  final String joinRoomRoute;
  final String aiRoute;
  final bool supportsOnline;
  final bool supportsAI;

  const GameModule({
    required this.gameType,
    required this.createRoomRoute,
    required this.joinRoomRoute,
    required this.aiRoute,
    required this.supportsOnline,
    required this.supportsAI,
  });
}
