import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../integration_test/helpers/test_app_harness.dart';

void main() {
  group('Auth Flow E2E Integration Tests', () {
    testWidgets('Complete login, signup tab switch, and forgot password flow', (tester) async {
      final authRepo = FakeAuthRepository(authenticated: false);
      final router = createTestRouter(initialLocation: '/login');

      await tester.pumpWidget(
        createTestApp(
          router: router,
          authRepo: authRepo,
        ),
      );
      await tester.pumpAndSettle();

      // ─── Step 1: Verify Login Screen & Brand Name ─────────────────────
      expect(find.text('WeekLoop'), findsOneWidget);
      expect(find.text('Đăng Nhập'), findsWidgets);
      expect(find.text('Đăng Ký'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);

      // ─── Step 2: Tab Toggle to Sign Up ──────────────────────────────
      await tester.tap(find.text('Đăng Ký'));
      await tester.pumpAndSettle();

      // Full name and Confirm password fields should now appear
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Xác nhận lại mật khẩu'), findsOneWidget);
      // 'Quên mật khẩu?' is hidden on Sign Up tab
      expect(find.text('Quên mật khẩu?'), findsNothing);

      // Switch back to Login tab (first occurrence is tab, button is second)
      await tester.tap(find.text('Đăng Nhập').first);
      await tester.pumpAndSettle();
      expect(find.text('Quên mật khẩu?'), findsOneWidget);

      // ─── Step 3: Forgot Password Navigation & Recovery ─────────────
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'reset@weekloop.app');
      await tester.pumpAndSettle();

      // Tap 'Quên mật khẩu?'
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();

      // Should be on ForgotPasswordScreen
      expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
      expect(find.text('reset@weekloop.app'), findsOneWidget);

      // Submit reset request
      final sendButton = find.text('Gửi link đặt lại');
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Confirmation state should appear
      expect(find.text('Kiểm tra email của bạn'), findsOneWidget);
      expect(find.text('Gửi lại'), findsOneWidget);
      expect(find.text('Quay lại Đăng nhập'), findsOneWidget);

      // Tap 'Quay lại Đăng nhập' to return to LoginScreen
      await tester.tap(find.text('Quay lại Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('WeekLoop'), findsOneWidget);

      // ─── Step 4: Login to Dashboard ────────────────────────────────
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'user@weekloop.app');
      await tester.enterText(fields.at(1), 'password123');
      await tester.pumpAndSettle();

      final loginButton = find.widgetWithText(FilledButton, 'Đăng Nhập');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify routed to DashboardScreen
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Planner'), findsOneWidget);
      expect(find.text('Việc phụ'), findsOneWidget);
      expect(find.text('Ghi chú'), findsOneWidget);
    });
  });
}
