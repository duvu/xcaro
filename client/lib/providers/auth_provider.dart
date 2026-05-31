import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService _wsService;
  final FlutterSecureStorage _secureStorage;

  User? _currentUser;
  String? _accessToken;
  bool _isLoading = false;

  static const _refreshTokenKey = 'refresh_token';

  AuthProvider(this._apiService, this._wsService)
      : _secureStorage = const FlutterSecureStorage() {
    _init();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get accessToken => _accessToken;

  void _activateSession(String? accessToken) {
    _apiService.setAccessToken(accessToken);
    _wsService.setToken(accessToken);
    if (accessToken != null) {
      _wsService.connect();
    }
  }

  void _clearSession() {
    _accessToken = null;
    _currentUser = null;
    _apiService.setAccessToken(null);
    _wsService.setToken(null);
    _wsService.disconnect();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken != null) {
        final tokens = await _apiService.refreshToken(refreshToken);
        _accessToken = tokens['access_token'];
        final newRefreshToken = tokens['refresh_token'];
        if (newRefreshToken != null) {
          await _secureStorage.write(
              key: _refreshTokenKey, value: newRefreshToken);
        }
        _activateSession(_accessToken);
        _currentUser = await _apiService.getCurrentUser();
      }
    } catch (e) {
      await _secureStorage.delete(key: _refreshTokenKey);
      _clearSession();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.register(username, email, password);
      _accessToken = result['access_token'] as String;
      final refreshToken = result['refresh_token'] as String;
      _currentUser = result['user'] as User;
      _activateSession(_accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.login(username, password);
      _accessToken = result['access_token'] as String;
      final refreshToken = result['refresh_token'] as String;
      _currentUser = result['user'] as User;
      _activateSession(_accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User> refreshCurrentUser() async {
    final user = await _apiService.getCurrentUser();
    _currentUser = user;
    notifyListeners();
    return user;
  }

  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (_) {
      // best-effort
    } finally {
      await _secureStorage.delete(key: _refreshTokenKey);
      _clearSession();
      _isLoading = false;
      notifyListeners();
    }
  }
}
