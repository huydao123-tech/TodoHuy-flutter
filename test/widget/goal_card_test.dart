import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todohuy/features/auth/data/auth_repository.dart';
import 'package:todohuy/features/planner/data/planner_repository.dart';
import 'package:todohuy/features/planner/data/work_item_model.dart';
import 'package:todohuy/features/planner/presentation/widgets/goal_card.dart';
import 'package:todohuy/features/task_groups/data/task_group_model.dart';
import 'package:todohuy/features/task_groups/data/task_group_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}
class MockPlannerRepository extends Mock implements PlannerRepository {}
class MockTaskGroupRepository extends Mock implements TaskGroupRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUser mockUser;
  late MockPlannerRepository mockPlannerRepository;
  late MockTaskGroupRepository mockTaskGroupRepository;

  final testGroup = TaskGroupModel(
    id: 'g-1',
    name: 'Học tiếng Anh',
    type: TaskGroupType.MAIN,
    color: '#16A34A',
    displayOrder: 1,
    isArchived: false,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUser = MockUser();
    mockPlannerRepository = MockPlannerRepository();
    mockTaskGroupRepository = MockTaskGroupRepository();

    when(() => mockUser.uid).thenReturn('user-123');
    when(() => mockAuthRepository.currentUser).thenReturn(mockUser);
  });

  Widget buildTestableWidget({
    required TaskGroupModel group,
    required String weekStartDate,
    bool isPast = false,
    List<WorkItemModel> items = const [],
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        plannerRepositoryProvider.overrideWithValue(mockPlannerRepository),
        taskGroupRepositoryProvider.overrideWithValue(mockTaskGroupRepository),
        workItemsForWeekProvider(weekStartDate).overrideWith((ref) => Stream.value(items)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoalCard(
              group: group,
              weekStartDate: weekStartDate,
              isPast: isPast,
            ),
          ),
        ),
      ),
    );
  }

  group('GoalCard Widget Tests', () {
    testWidgets('renders group name and work items correctly', (tester) async {
      final items = [
        WorkItemModel(
          id: 'w-1',
          taskGroupId: 'g-1',
          weekStartDate: '2026-09-07',
          content: 'Luyện nghe 30 phút',
          status: WorkItemStatus.TODO,
          note: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        WorkItemModel(
          id: 'w-2',
          taskGroupId: 'other-group',
          weekStartDate: '2026-09-07',
          content: 'Công việc nhóm khác',
          status: WorkItemStatus.TODO,
          note: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(
        group: testGroup,
        weekStartDate: '2026-09-07',
        items: items,
      ));

      await tester.pumpAndSettle();

      // Check group name rendered
      expect(find.text('Học tiếng Anh'), findsOneWidget);

      // Check item in this group rendered
      expect(find.text('Luyện nghe 30 phút'), findsOneWidget);

      // Check item in other group is NOT rendered inside this card
      expect(find.text('Công việc nhóm khác'), findsNothing);

      // Check input row exists for current week
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders empty state message when group has no items', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        group: testGroup,
        weekStartDate: '2026-09-07',
        items: [],
      ));

      await tester.pumpAndSettle();

      expect(find.text('Học tiếng Anh'), findsOneWidget);
      expect(find.text('Chưa có công việc nào. Thêm công việc bên dưới...'), findsOneWidget);
    });

    testWidgets('renders past week badge and disables input when isPast is true', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        group: testGroup,
        weekStartDate: '2026-08-31',
        isPast: true,
        items: [],
      ));

      await tester.pumpAndSettle();

      // 'Tuần cũ' label should appear
      expect(find.text('Tuần cũ'), findsOneWidget);

      // Add task row should be disabled / not present
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('shows delete button and tapping it opens confirm dialog', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        group: testGroup,
        weekStartDate: '2026-09-07',
        items: [],
      ));

      await tester.pumpAndSettle();

      // Tap delete icon button
      final deleteFinder = find.byIcon(Icons.delete_outline);
      expect(deleteFinder, findsOneWidget);
      await tester.tap(deleteFinder);
      await tester.pumpAndSettle();

      // Dialog confirmation must appear
      expect(find.text('Xóa nhóm công việc?'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
    });
  });
}
