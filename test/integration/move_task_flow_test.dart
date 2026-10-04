import 'package:flutter_test/flutter_test.dart';
import 'package:todohuy/core/utils/week_helper.dart';
import 'package:todohuy/features/planner/data/work_item_model.dart';
import 'package:todohuy/features/task_groups/data/task_group_model.dart';
import '../../integration_test/helpers/test_app_harness.dart';

void main() {
  group('Move Task to Current Week Tests', () {
    testWidgets('Move task from past week to current week via TaskDetailSheet', (tester) async {
      final now = DateTime.now();
      final currentWeekStart = WeekHelper.getStartOfWeek(now);
      final currentWeekStr = WeekHelper.toWeekStartStr(currentWeekStart);
      final pastWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      final pastWeekStr = WeekHelper.toWeekStartStr(pastWeekStart);

      final testGroup = TaskGroupModel(
        id: 'group-work',
        name: 'Dự án Mobile',
        type: TaskGroupType.MAIN,
        color: '#16A34A',
        displayOrder: 0,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );

      final pastItem = WorkItemModel(
        id: 'item-past-1',
        taskGroupId: 'group-work',
        weekStartDate: pastWeekStr,
        content: 'Task chưa xong tuần trước',
        status: WorkItemStatus.TODO,
        note: 'Ghi chú tuần trước',
        createdAt: pastWeekStart,
        updatedAt: pastWeekStart,
      );

      final authRepo = FakeAuthRepository(authenticated: true);
      final taskGroupRepo = FakeTaskGroupRepository(
        initialActive: [testGroup],
        initialArchived: [],
      );
      final plannerRepo = FakePlannerRepository(
        taskGroupRepo: taskGroupRepo,
        initialItems: [pastItem],
      );

      final router = createTestRouter(initialLocation: '/');

      await tester.pumpWidget(
        createTestApp(
          router: router,
          authRepo: authRepo,
          taskGroupRepo: taskGroupRepo,
          plannerRepo: plannerRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Current week is empty of tasks initially
      expect(find.text('Task chưa xong tuần trước'), findsNothing);

      // Navigate to previous week by tapping the previous week chevron
      final prevWeekButton = find.byTooltip('Tuần trước');
      expect(prevWeekButton, findsOneWidget);
      await tester.tap(prevWeekButton);
      await tester.pumpAndSettle();

      // Verify we are now on the past week and the item is visible
      expect(find.text('TUẦN ĐÃ QUA'), findsOneWidget);
      expect(find.text('Task chưa xong tuần trước'), findsOneWidget);

      // Tap on the task row to open TaskDetailSheet
      await tester.tap(find.text('Task chưa xong tuần trước'));
      await tester.pumpAndSettle();

      // Verify the past week notice is shown
      expect(find.text('Công việc thuộc tuần cũ. Bạn có thể dời sang tuần này để tiếp tục thực hiện.'), findsOneWidget);

      // Scroll down in the sheet to reveal action buttons
      await tester.drag(find.text('Trạng thái'), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verify the 'Dời sang tuần này' button is present
      final moveButton = find.text('Dời sang tuần này');
      expect(moveButton, findsOneWidget);

      // Tap 'Dời sang tuần này'
      await tester.tap(moveButton);
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation is displayed
      expect(find.text('Đã dời "Task chưa xong tuần trước" sang tuần này'), findsOneWidget);

      // Verify repository has updated the task's weekStartDate to current week
      final updatedItem = plannerRepo.workItems.firstWhere((i) => i.id == 'item-past-1');
      expect(updatedItem.weekStartDate, currentWeekStr);

      // Navigate back to current week
      final backToTodayButton = find.text('Về hôm nay');
      if (backToTodayButton.evaluate().isNotEmpty) {
        await tester.tap(backToTodayButton);
        await tester.pumpAndSettle();
      }

      // Verify the task is now visible in the current week!
      expect(find.text('TUẦN HIỆN TẠI'), findsOneWidget);
      expect(find.text('Task chưa xong tuần trước'), findsOneWidget);
    });

    testWidgets('Quick move task from past week to current week via row action and undo', (tester) async {
      final now = DateTime.now();
      final currentWeekStart = WeekHelper.getStartOfWeek(now);
      final currentWeekStr = WeekHelper.toWeekStartStr(currentWeekStart);
      final pastWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      final pastWeekStr = WeekHelper.toWeekStartStr(pastWeekStart);

      final testGroup = TaskGroupModel(
        id: 'group-work',
        name: 'Dự án Mobile',
        type: TaskGroupType.MAIN,
        color: '#16A34A',
        displayOrder: 0,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );

      final pastItem = WorkItemModel(
        id: 'item-past-quick',
        taskGroupId: 'group-work',
        weekStartDate: pastWeekStr,
        content: 'Task cần chuyển nhanh',
        status: WorkItemStatus.TODO,
        note: '',
        createdAt: pastWeekStart,
        updatedAt: pastWeekStart,
      );

      final authRepo = FakeAuthRepository(authenticated: true);
      final taskGroupRepo = FakeTaskGroupRepository(
        initialActive: [testGroup],
        initialArchived: [],
      );
      final plannerRepo = FakePlannerRepository(
        taskGroupRepo: taskGroupRepo,
        initialItems: [pastItem],
      );

      final router = createTestRouter(initialLocation: '/');

      await tester.pumpWidget(
        createTestApp(
          router: router,
          authRepo: authRepo,
          taskGroupRepo: taskGroupRepo,
          plannerRepo: plannerRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to previous week
      await tester.tap(find.byTooltip('Tuần trước'));
      await tester.pumpAndSettle();

      // Find quick move button on the row
      final quickMoveButton = find.byTooltip('Dời sang tuần này');
      expect(quickMoveButton, findsOneWidget);

      // Tap quick move
      await tester.tap(quickMoveButton);
      await tester.pumpAndSettle();

      // Verify SnackBar and item updated to current week
      expect(find.text('Đã dời "Task cần chuyển nhanh" sang tuần này'), findsOneWidget);
      expect(plannerRepo.workItems.firstWhere((i) => i.id == 'item-past-quick').weekStartDate, currentWeekStr);

      // Tap Undo (Hoàn tác)
      final undoButton = find.text('Hoàn tác');
      expect(undoButton, findsOneWidget);
      await tester.tap(undoButton);
      await tester.pumpAndSettle();

      // Verify item moved back to past week
      expect(plannerRepo.workItems.firstWhere((i) => i.id == 'item-past-quick').weekStartDate, pastWeekStr);
    });
  });
}
