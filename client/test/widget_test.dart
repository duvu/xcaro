import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xcaro/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders primary auth actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('Đăng Nhập'), findsWidgets);
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Chưa có tài khoản? Đăng ký ngay'), findsOneWidget);
  });
}
