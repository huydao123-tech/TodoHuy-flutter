import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todohuy/features/auth/data/auth_repository.dart';
import 'package:todohuy/features/side_tasks/data/side_task_model.dart';
import 'package:todohuy/features/side_tasks/data/side_tasks_repository.dart';
import 'package:todohuy/features/side_tasks/presentation/side_tasks_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}
class MockSideTasksRepository extends Mock implements SideTasksRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUser mockUser;
  late MockSideTasksRepository mockSideTasksRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUser = MockUser();
    mockSideTasksRepository = MockSideTasksRepository();

    when(() => mockUser.uid).thenReturn('user-123');
    when(() => mockAuthRepository.currentUser).thenReturn(mockUser);
  });

  Widget buildTestableWidget({List<SideTaskModel> tasks = const []}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        sideTasksRepositoryProvider.overrideWithValue(mockSideTasksRepository),
        sideTasksProvider.overrideWith((ref) => Stream.value(tasks)),
      ],
      child: const MaterialApp(
        home: SideTasksScreen(),
      ),
    );
  }

  group('SideTasksScreen Widget Tests', () {
    testWidgets('renders input bar and empty state message when list is empty', (tester) async {
      await tester.pumpWidget(buildTestableWidget(tasks: []));
      await tester.pumpAndSettle();

      expect(find.text('Việc phụ (Lặt vặt)'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Chưa có việc phụ nào.'), findsOneWidget);
    });

    testWidgets('renders tasks with checkboxes and action buttons', (tester) async {
      final tasks = [
        SideTaskModel(
          id: 'st-1',
          name: 'Mua tài liệu học tập',
          isDone: false,
          createdAt: DateTime.now(),
        ),
        SideTaskModel(
          id: 'st-2',
          name: 'Gửi email báo cáo',
          isDone: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(tasks: tasks));
      await tester.pumpAndSettle();

      expect(find.text('Mua tài liệu học tập'), findsOneWidget);
      expect(find.text('Gửi email báo cáo'), findsOneWidget);

      // Check for checkboxes
      expect(find.byType(Checkbox), findsNWidgets(2));

      // Check for edit icons (pencil)
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));

      // Check for delete icons (trash)
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('tapping edit button opens edit dialog', (tester) async {
      final tasks = [
        SideTaskModel(
          id: 'st-1',
          name: 'Sửa bóng đèn',
          isDone: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(tasks: tasks));
      await tester.pumpAndSettle();

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Sửa việc phụ'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Lưu'), findsOneWidget);
    });
  });
}
