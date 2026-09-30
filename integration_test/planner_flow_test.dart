import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todohuy/core/utils/week_helper.dart';
import 'package:todohuy/features/planner/data/work_item_model.dart';
import 'package:todohuy/features/task_groups/data/task_group_model.dart';
import 'helpers/test_app_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runPlannerFlowTests();
}

void runPlannerFlowTests() {
  group('Planner Flow E2E Integration Tests', () {
    testWidgets('Weekly planning, inline task addition, status cycle, long-press protection, and drawer/trash flow', (tester) async {
      final now = DateTime.now();
      final startOfWeek = WeekHelper.getStartOfWeek(now);
      final currentWeekStr =
          '${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}';

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

      final archivedGroup = TaskGroupModel(
        id: 'group-archived',
        name: 'Nhóm cũ đã xóa',
        type: TaskGroupType.MAIN,
        color: '#EF4444',
        displayOrder: 1,
        isArchived: true,
        archivedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 2)),
      );

      final authRepo = FakeAuthRepository(authenticated: true);
      final taskGroupRepo = FakeTaskGroupRepository(
        initialActive: [testGroup],
        initialArchived: [archivedGroup],
      );
      final plannerRepo = FakePlannerRepository(
        taskGroupRepo: taskGroupRepo,
        initialItems: [
          WorkItemModel(
            id: 'item-1',
            taskGroupId: 'group-work',
            weekStartDate: currentWeekStr,
            content: 'Nhiệm vụ mẫu ban đầu',
            status: WorkItemStatus.TODO,
            note: '',
            createdAt: now,
            updatedAt: now,
          ),
        ],
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

      // ─── Step 1: Verify Initial Dashboard & GoalCard ────────────────
      expect(find.text('WeekLoop'), findsOneWidget);
      expect(find.text('Dự án Mobile'), findsOneWidget);
      expect(find.text('Nhiệm vụ mẫu ban đầu'), findsOneWidget);

      // ─── Step 2: Add Work Item via Inline Field ─────────────────────
      final addField = find.widgetWithText(TextField, 'Thêm công việc...');
      expect(addField, findsOneWidget);

      await tester.enterText(addField, 'Viết Integration Test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify new item appears in the list
      expect(find.text('Viết Integration Test'), findsOneWidget);

      // ─── Step 3: Status Cycle & Long-press Protection ───────────────
      final uncheckedIcons = find.byIcon(Icons.radio_button_unchecked);
      expect(uncheckedIcons, findsWidgets);

      // Tap to cycle TODO -> IN_PROGRESS
      await tester.tap(uncheckedIcons.first);
      await tester.pumpAndSettle();

      // Find IN_PROGRESS icon (hourglass_top_rounded)
      final inProgressFinder = find.byIcon(Icons.hourglass_top_rounded);
      expect(inProgressFinder, findsOneWidget);

      // Tap again to cycle IN_PROGRESS -> DONE
      await tester.tap(inProgressFinder);
      await tester.pumpAndSettle();

      // Find DONE icon (check_circle)
      final doneIcon = find.byIcon(Icons.check_circle);
      expect(doneIcon, findsWidgets);

      // Single tap on DONE item should NOT uncomplete — shows warning SnackBar
      await tester.tap(doneIcon.first);
      await tester.pumpAndSettle();
      expect(find.text('Nhấn giữ để đặt lại trạng thái'), findsOneWidget);

      // Long press on DONE item to reset back to TODO
      await tester.longPress(doneIcon.first);
      await tester.pumpAndSettle();

      // ─── Step 4: Open Drawer & Navigate to TrashSheet ───────────────
      final menuButton = find.byIcon(Icons.menu);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Verify Drawer contents
      expect(find.text('NHÓM CÔNG VIỆC'), findsOneWidget);
      expect(find.text('Tài liệu & Link'), findsOneWidget);
      expect(find.text('Thùng rác'), findsOneWidget);

      // Tap 'Thùng rác'
      await tester.tap(find.text('Thùng rác'));
      await tester.pumpAndSettle();

      // Verify TrashSheet contents
      expect(find.text('Thùng rác'), findsWidgets);
      expect(find.text('Các nhóm trong thùng rác sẽ bị xóa vĩnh viễn sau 30 ngày.'), findsOneWidget);
      expect(find.text('Nhóm cũ đã xóa'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Khôi phục'), findsOneWidget);

      // Close TrashSheet by tapping background barrier or back
      Navigator.of(tester.element(find.text('Nhóm cũ đã xóa'))).pop();
      await tester.pumpAndSettle();
    });
  });
}
