import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/game.dart';
import '../models/game_catalog.dart';
import '../models/game_stats.dart';
import '../models/dashboard_models.dart';

class ApiService {
  final Dio _dio;
  String? _accessToken;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
    ));
  }

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  String? get accessToken => _accessToken;

  /// Returns {access_token, refresh_token, user}
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final user = User.fromJson(response.data['user'] as Map<String, dynamic>);

      return {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user': user,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Returns {access_token, refresh_token, user}
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final user = User.fromJson(response.data['user'] as Map<String, dynamic>);

      return {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user': user,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Returns {access_token, refresh_token}
  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      return {
        'access_token': response.data['access_token'] as String,
        'refresh_token': response.data['refresh_token'] as String,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/profile');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> updateProfile({
    required String fullName,
    required String avatar,
    DateTime? dateOfBirth,
    required String phoneNumber,
    required String bio,
  }) async {
    try {
      await _dio.put('/profile', data: {
        'full_name': fullName,
        'avatar': avatar,
        'date_of_birth': dateOfBirth?.toUtc().toIso8601String(),
        'phone_number': phoneNumber,
        'bio': bio,
      });
      return getCurrentUser();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put('/profile/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      await _dio.put('/profile/email', data: {
        'new_email': newEmail,
        'password': password,
      });
      return getCurrentUser();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // best-effort
    }
  }

  Future<List<Game>> getGames(
      {int page = 1, int limit = 20, String? userId}) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };
      if (userId != null) queryParams['user_id'] = userId;
      final response = await _dio.get('/games', queryParameters: queryParams);
      return (response.data as List)
          .map((game) => Game.fromJson(game as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<GameCatalogEntry>> getGameCatalog() async {
    try {
      final response = await _dio.get(AppConfig.gameCatalogEndpoint);
      final data = response.data as Map<String, dynamic>;
      return (data['games'] as List<dynamic>? ?? const [])
          .map(
              (item) => GameCatalogEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<GameStats> getGameStats(String userId, {String? gameType}) async {
    try {
      final response = await _dio.get('/games/stats', queryParameters: {
        'user_id': userId,
        if (gameType != null && gameType.isNotEmpty) 'game_type': gameType,
      });
      return GameStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getLeaderboard({String? gameType}) async {
    try {
      final resp = await _dio.get('/leaderboard', queryParameters: {
        if (gameType != null && gameType.isNotEmpty) 'game_type': gameType,
      });
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final resp = await _dio.get('/users/$userId/profile');
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DashboardSummary> getDashboardSummary({String? gameType}) async {
    try {
      final response = await _dio.get('/dashboard/summary', queryParameters: {
        if (gameType != null && gameType.isNotEmpty) 'game_type': gameType,
      });
      return DashboardSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DashboardHistoryResponse> getDashboardHistory({
    int page = 1,
    int limit = 20,
    String? gameType,
    String? result,
    String? opponent,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get('/dashboard/history', queryParameters: {
        'page': page,
        'limit': limit,
        if (gameType != null && gameType.isNotEmpty) 'game_type': gameType,
        if (result != null && result.isNotEmpty) 'result': result,
        if (opponent != null && opponent.isNotEmpty) 'opponent': opponent,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      });
      return DashboardHistoryResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PlayerSummary>> searchPlayers({
    String query = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get('/social/players', queryParameters: {
        'q': query,
        'page': page,
        'limit': limit,
      });
      final data = response.data as Map<String, dynamic>;
      return (data['players'] as List<dynamic>? ?? const [])
          .map((item) => PlayerSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<FriendshipSummary>> getFriends() async {
    try {
      final response = await _dio.get('/social/friends');
      final data = response.data as Map<String, dynamic>;
      return (data['friends'] as List<dynamic>? ?? const [])
          .map((item) =>
              FriendshipSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<FriendRequestSummary>> getFriendRequests(
      {String box = 'incoming'}) async {
    try {
      final response = await _dio
          .get('/social/friend-requests', queryParameters: {'box': box});
      final data = response.data as Map<String, dynamic>;
      return (data['requests'] as List<dynamic>? ?? const [])
          .map((item) =>
              FriendRequestSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FriendRequestSummary> sendFriendRequest(String recipientId) async {
    try {
      final response = await _dio.post('/social/friend-requests', data: {
        'recipient_id': recipientId,
      });
      return FriendRequestSummary.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FriendshipSummary> acceptFriendRequest(String requestId) async {
    try {
      final response =
          await _dio.post('/social/friend-requests/$requestId/accept');
      return FriendshipSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _dio.post('/social/friend-requests/$requestId/reject');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _dio.post('/social/friend-requests/$requestId/cancel');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeFriend(String userId) async {
    try {
      await _dio.delete('/social/friends/$userId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> resendVerification() async {
    try {
      await _dio.post('/auth/resend-verification');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createRoom() async {
    try {
      final response = await _dio.post('/rooms');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> joinRoom(String code) async {
    try {
      final response = await _dio.post('/rooms/$code/join');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Game> createGame() async {
    try {
      final response = await _dio.post('/games');
      return Game.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Game> joinGame(String gameId) async {
    try {
      final response = await _dio.post('/games/$gameId/join');
      return Game.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Game> makeMove(String gameId, int x, int y) async {
    try {
      final response = await _dio.post('/games/$gameId/move', data: {
        'x': x,
        'y': y,
      });
      return Game.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> submitReport(
      String reportedUserId, String gameId, String reason) async {
    try {
      await _dio.post('/reports', data: {
        'reported_user_id': reportedUserId,
        'game_id': gameId,
        'reason': reason,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> submitErrorReport({
    required String platform,
    required String version,
    required String errorType,
    required String message,
    String? stackTrace,
  }) async {
    try {
      final st = stackTrace;
      await _dio.post('/errors', data: {
        'platform': platform,
        'version': version,
        'error_type': errorType,
        'message': message,
        if (st != null)
          'stack_trace': st.length > 4096 ? st.substring(0, 4096) : st,
      });
    } catch (_) {
      // fire-and-forget: ignore network errors to avoid cascading failures
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại sau.';
  }
}
