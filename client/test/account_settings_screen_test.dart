import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playverse/models/dashboard_models.dart';
import 'package:playverse/models/user.dart';
import 'package:playverse/providers/auth_provider.dart';
import 'package:playverse/screens/account_settings_screen.dart';
import 'package:playverse/services/api_service.dart';
import 'package:playverse/services/websocket_service.dart';
import 'package:provider/provider.dart';

class _FakeApiService extends ApiService {
  @override
  Future<DashboardSummary> getDashboardSummary({String? gameType}) async {
    return DashboardSummary(
      profile: const PlayerSummary(
        id: 'u1',
        username: 'alice',
        avatar: null,
        bio: 'Bio',
        eloRating: 1240,
        rank: 7,
        friendStatus: 'self',
      ),
      stats: const DashboardStats(
        gameType: 'caro',
        wins: 10,
        losses: 3,
        draws: 2,
        eloRating: 1240,
        rank: 7,
      ),
      recentGames: [
        DashboardGameRecord(
          id: 'g1',
          gameType: 'caro',
          roomId: 'r1',
          result: 'win',
          winner: 'u1',
          opponent: 'bob',
          outcome: 'win',
          createdAt: DateTime(2026, 5, 31),
        ),
      ],
      friendCount: 3,
      incomingRequestCount: 1,
      outgoingRequestCount: 2,
    );
  }
}

void main() {
  testWidgets('Account settings shows verification banner and summary data',
      (WidgetTester tester) async {
    final apiService = _FakeApiService();
    final wsService = WebSocketService();
    final authProvider = AuthProvider(apiService, wsService);
    authProvider.setCurrentUser(
      User(
        id: 'u1',
        username: 'alice',
        email: 'alice@example.com',
        role: 'player',
        emailVerified: false,
        isBanned: false,
        gamesPlayed: 12,
        gamesWon: 10,
        rating: 1240,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(home: AccountSettingsScreen(showAsTab: true)),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Email chưa được xác minh'), findsOneWidget);
    expect(find.text('Quản lý tài khoản'), findsWidgets);
    expect(find.text('alice@example.com'), findsOneWidget);
    expect(find.text('Bạn bè: 3'), findsOneWidget);
  });
}
