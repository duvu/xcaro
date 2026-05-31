class AppConfig {
  // URLs
  static const String _apiBaseUrl = 'http://10.113.213.9:8080/api';
  static const String _wsBaseUrl = 'ws://10.113.213.9:8080/api/ws';

  // API endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String profileEndpoint = '/users/profile';
  static const String gamesEndpoint = '/games';
  static const String gameCatalogEndpoint = '/games/catalog';
  static const String defaultGameType = 'caro';

  // WebSocket events
  static const String createRoomEvent = 'create_room';
  static const String joinRoomEvent = 'join_room';
  static const String joinRoomByCodeEvent = 'join_room_by_code';
  static const String rejoinRoomEvent = 'rejoin_room';
  static const String leaveRoomEvent = 'leave_room';
  static const String moveEvent = 'make_move';
  static const String resignEvent = 'resign';
  static const String chatEvent = 'chat_message';
  static const String gameStateEvent = 'game_state';
  static const String gameOverEvent = 'game_over';
  static const String quickMatchRequestEvent = 'quick_match_request';
  static const String quickMatchFoundEvent = 'quick_match_found';
  static const String quickMatchCancelEvent = 'quick_match_cancel';
  static const String quickMatchCancelledEvent = 'quick_match_cancelled';
  static const String quickMatchTimeoutEvent = 'quick_match_timeout';
  static const String errorEvent = 'error';
  static const String pingEvent = 'ping';
  static const String pongEvent = 'pong';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
  static const String offlineStatsKey = 'offline_stats';

  // Game settings
  static const int boardSize = 15;
  static const int winCondition = 5;
  static const Duration moveTimeout = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 3);

  // Environment
  static const bool isDevelopment = true;

  // Cấu hình cho môi trường production
  static String get productionApiBaseUrl => 'https://api.playverse.app/api';
  static String get productionWsBaseUrl => 'wss://api.playverse.app/ws';

  // Lấy URL dựa vào môi trường
  static String get baseUrl =>
      isDevelopment ? _apiBaseUrl : productionApiBaseUrl;
  static String get wsUrl => isDevelopment ? _wsBaseUrl : productionWsBaseUrl;

  // Các cấu hình khác
  static const int maxUsernameLength = 30;
  static const int minUsernameLength = 3;
  static const int minPasswordLength = 6;
  static const int maxBioLength = 500;
  static const int maxFullNameLength = 100;
}
