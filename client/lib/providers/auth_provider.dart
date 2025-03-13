import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final LocalStorageService _storage;
  User? _currentUser;
  bool _isLoading = false;

  AuthProvider(this._apiService, this._storage) {
    _init();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = _storage.getToken();
      if (token != null) {
        _currentUser = await _apiService.getCurrentUser();
      }
    } catch (e) {
      await _storage.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _apiService.register(username, email, password);
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
      _currentUser = await _apiService.login(username, password);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      _currentUser = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
