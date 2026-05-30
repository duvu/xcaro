import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/game.dart';
import '../models/game_stats.dart';

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
      final response = await _dio.get('/users/profile');
      return User.fromJson(response.data as Map<String, dynamic>);
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
      if (userId != null) queryParams['userId'] = userId;
      final response = await _dio.get('/games', queryParameters: queryParams);
      return (response.data as List)
          .map((game) => Game.fromJson(game as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<GameStats> getGameStats(String userId) async {
    try {
      final response =
          await _dio.get('/games/stats', queryParameters: {'userId': userId});
      return GameStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final resp = await _dio.get('/leaderboard');
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
