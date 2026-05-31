import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:playverse/screens/login_screen.dart';
import 'package:playverse/providers/auth_provider.dart';
import 'package:playverse/services/api_service.dart';
import 'package:playverse/services/websocket_service.dart';

void main() {
  testWidgets('Login screen renders primary auth actions',
      (WidgetTester tester) async {
    final apiService = ApiService();
    final wsService = WebSocketService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(apiService, wsService),
          ),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pump();

    // The branded header and form should render
    expect(find.text('Đăng Nhập'), findsWidgets);
    expect(find.text('Chưa có tài khoản? Đăng ký ngay'), findsOneWidget);
    expect(find.text('Chơi không cần đăng nhập'), findsOneWidget);
  });
}
