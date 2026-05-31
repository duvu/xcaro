import 'package:flutter/material.dart';

import '../models/dashboard_models.dart';
import '../services/api_service.dart';

class SocialProvider extends ChangeNotifier {
  final ApiService _apiService;

  SocialProvider(this._apiService);

  DashboardSummary? _summary;
  final List<PlayerSummary> _players = [];
  final List<FriendshipSummary> _friends = [];
  final List<FriendRequestSummary> _incoming = [];
  final List<FriendRequestSummary> _outgoing = [];
  bool _loading = false;
  String? _error;

  DashboardSummary? get summary => _summary;
  List<PlayerSummary> get players => List.unmodifiable(_players);
  List<FriendshipSummary> get friends => List.unmodifiable(_friends);
  List<FriendRequestSummary> get incoming => List.unmodifiable(_incoming);
  List<FriendRequestSummary> get outgoing => List.unmodifiable(_outgoing);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    await _run(() async {
      _summary = await _apiService.getDashboardSummary();
    });
  }

  Future<void> loadSocial({String query = ''}) async {
    await _run(() async {
      final results = await Future.wait([
        _apiService.searchPlayers(query: query),
        _apiService.getFriends(),
        _apiService.getFriendRequests(box: 'incoming'),
        _apiService.getFriendRequests(box: 'outgoing'),
      ]);
      _players
        ..clear()
        ..addAll(results[0] as List<PlayerSummary>);
      _friends
        ..clear()
        ..addAll(results[1] as List<FriendshipSummary>);
      _incoming
        ..clear()
        ..addAll(results[2] as List<FriendRequestSummary>);
      _outgoing
        ..clear()
        ..addAll(results[3] as List<FriendRequestSummary>);
    });
  }

  Future<void> sendRequest(String userId) async {
    await _run(() async {
      await _apiService.sendFriendRequest(userId);
      await loadSocial();
    });
  }

  Future<void> acceptRequest(String requestId) async {
    await _run(() async {
      await _apiService.acceptFriendRequest(requestId);
      await loadSocial();
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await _run(() async {
      await _apiService.rejectFriendRequest(requestId);
      await loadSocial();
    });
  }

  Future<void> cancelRequest(String requestId) async {
    await _run(() async {
      await _apiService.cancelFriendRequest(requestId);
      await loadSocial();
    });
  }

  Future<void> removeFriend(String userId) async {
    await _run(() async {
      await _apiService.removeFriend(userId);
      await loadSocial();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
