import 'dart:collection';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/game_catalog.dart';
import '../services/api_service.dart';

class GameCatalogProvider extends ChangeNotifier {
  final ApiService _apiService;

  GameCatalogProvider(this._apiService);

  final List<GameCatalogEntry> _games = [];
  bool _isLoading = false;
  String? _error;
  String _selectedGameType = AppConfig.defaultGameType;

  UnmodifiableListView<GameCatalogEntry> get games =>
      UnmodifiableListView(_games);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedGameType => _selectedGameType;

  GameCatalogEntry? get selectedGame {
    for (final game in _games) {
      if (game.gameType == _selectedGameType) return game;
    }
    return _games.isNotEmpty ? _games.first : null;
  }

  Future<void> loadCatalog() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final items = await _apiService.getGameCatalog();
      _games
        ..clear()
        ..addAll(items);
      if (_games.isNotEmpty &&
          !_games.any((game) => game.gameType == _selectedGameType)) {
        _selectedGameType = _games.first.gameType;
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectGame(String gameType) {
    _selectedGameType = gameType;
    notifyListeners();
  }
}
