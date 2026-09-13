import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todohuy/features/auth/data/auth_repository.dart';
import 'package:todohuy/main.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('TodoHuyApp smoke test: boots to LoginScreen successfully', (tester) async {
    final mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.currentUser).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
        child: const TodoHuyApp(),
      ),
    );

    // Initial pump
    await tester.pumpAndSettle();

    // Verify LoginScreen is mounted with tabs
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Đăng Nhập'), findsWidgets);
    expect(find.text('Đăng Ký'), findsWidgets);
  });
}
