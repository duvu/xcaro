class AppConfig {
  static const String apiBaseUrl = 'http://localhost:8080/api';
  static const String wsBaseUrl = 'ws://localhost:8080/ws';

  // API endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String profileEndpoint = '/users/profile';
  static const String gamesEndpoint = '/games';

  // WebSocket events
  static const String joinRoomEvent = 'join_room';
  static const String leaveRoomEvent = 'leave_room';
  static const String moveEvent = 'move';
  static const String chatEvent = 'chat';
  static const String gameOverEvent = 'game_over';

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
  static String get productionApiBaseUrl => 'https://api.xcaro.com/api';
  static String get productionWsBaseUrl => 'wss://api.xcaro.com/ws';

  // Lấy URL dựa vào môi trường
  static String get baseUrl =>
      isDevelopment ? apiBaseUrl : productionApiBaseUrl;
  static String get wsUrl => isDevelopment ? wsBaseUrl : productionWsBaseUrl;
}
