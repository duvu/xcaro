import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class LocalStorageService {
  static const String _userKey = 'user';
  static const String _offlineStatsKey = 'offline_stats';
  static const _tokenKey = 'token';
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // Lưu thông tin người dùng
  Future<void> saveUser(User user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Lấy thông tin người dùng
  User? getUser() {
    final userJson = _prefs.getString(_userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  // Lưu thống kê offline
  Future<void> saveOfflineStats({
    required int gamesPlayed,
    required int gamesWon,
    required int score,
  }) async {
    await _prefs.setInt('${_offlineStatsKey}_played', gamesPlayed);
    await _prefs.setInt('${_offlineStatsKey}_won', gamesWon);
    await _prefs.setInt('${_offlineStatsKey}_score', score);
  }

  // Lấy thống kê offline
  Map<String, int> getOfflineStats() {
    return {
      'gamesPlayed': _prefs.getInt('${_offlineStatsKey}_played') ?? 0,
      'gamesWon': _prefs.getInt('${_offlineStatsKey}_won') ?? 0,
      'score': _prefs.getInt('${_offlineStatsKey}_score') ?? 0,
    };
  }

  // Cập nhật thống kê offline
  Future<void> updateOfflineStats({bool isWin = false}) async {
    final stats = getOfflineStats();
    await saveOfflineStats(
      gamesPlayed: stats['gamesPlayed']! + 1,
      gamesWon: stats['gamesWon']! + (isWin ? 1 : 0),
      score: stats['score']! + (isWin ? 10 : 0),
    );
  }

  // Xóa tất cả dữ liệu
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    await _prefs.remove(_tokenKey);
  }

  Future<void> saveUsername(String username) async {
    await _prefs.setString('username', username);
  }

  String? getUsername() {
    return _prefs.getString('username');
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}
