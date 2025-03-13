import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/local_storage_service.dart';
import '../models/user.dart';
import '../models/game.dart';

class ApiService {
  final Dio _dio;
  final LocalStorageService _storage;

  ApiService(this._storage)
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<User> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      final token = response.data['token'] as String;
      await _storage.saveToken(token);

      final user = User.fromJson(response.data['user']);
      await _storage.saveUser(user);

      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> register(String username, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
      });

      final token = response.data['token'] as String;
      await _storage.saveToken(token);

      final user = User.fromJson(response.data['user']);
      await _storage.saveUser(user);

      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      final user = User.fromJson(response.data);
      await _storage.saveUser(user);
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      await _storage.clear();
    }
  }

  Future<List<Game>> getGames() async {
    try {
      final response = await _dio.get('/games');
      return (response.data as List)
          .map((game) => Game.fromJson(game))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Game> createGame() async {
    try {
      final response = await _dio.post('/games');
      return Game.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Game> joinGame(String gameId) async {
    try {
      final response = await _dio.post('/games/$gameId/join');
      return Game.fromJson(response.data);
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
      return Game.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response!.data['message'] != null) {
      return e.response!.data['message'];
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại sau.';
  }
}
