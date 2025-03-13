import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/game.dart';

class GameProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Game>? _myGames;
  Game? _currentGame;
  bool _isLoading = false;

  GameProvider(this._apiService);

  List<Game>? get myGames => _myGames;
  Game? get currentGame => _currentGame;
  bool get isLoading => _isLoading;

  Future<void> loadGames() async {
    _isLoading = true;
    notifyListeners();

    try {
      _myGames = await _apiService.getGames();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGame() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentGame = await _apiService.createGame();
      if (_myGames != null) {
        _myGames!.add(_currentGame!);
      }
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinGame(String gameId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentGame = await _apiService.joinGame(gameId);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> makeMove(int x, int y) async {
    if (_currentGame == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentGame = await _apiService.makeMove(_currentGame!.id, x, y);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentGame() {
    _currentGame = null;
    notifyListeners();
  }
}
