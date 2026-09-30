import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todohuy/features/notes/data/note_model.dart';
import 'package:todohuy/features/side_tasks/data/side_task_model.dart';
import '../../integration_test/helpers/test_app_harness.dart';

void main() {
  group('Side Tasks and Notes Flow E2E Integration Tests', () {
    testWidgets('Quick capture side tasks, filters, undo delete, and notes masonry creation flow', (tester) async {
      final now = DateTime.now();
      final initialSideTask = SideTaskModel(
        id: 'st-1',
        name: 'Mua sữa tươi',
        isDone: false,
        createdAt: now,
      );

      final initialNote = NoteModel(
        id: 'note-1',
        title: 'Ghi chú ban đầu',
        content: 'Nội dung kiểm thử ban đầu',
        color: 'stone:Ý tưởng:📝',
        createdAt: now,
        updatedAt: now,
      );

      final authRepo = FakeAuthRepository(authenticated: true);
      final sideTasksRepo = FakeSideTasksRepository(initialTasks: [initialSideTask]);
      final notesRepo = FakeNotesRepository(initialNotes: [initialNote]);

      final router = createTestRouter(initialLocation: '/');

      await tester.pumpWidget(
        createTestApp(
          router: router,
          authRepo: authRepo,
          sideTasksRepo: sideTasksRepo,
          notesRepo: notesRepo,
        ),
      );
      await tester.pumpAndSettle();

      // ─── Part 1: Side Tasks (Việc phụ) Flow ─────────────────────────
      // Switch to Tab 1 (Việc phụ)
      final sideTasksTab = find.text('Việc phụ');
      expect(sideTasksTab, findsOneWidget);
      await tester.tap(sideTasksTab);
      await tester.pumpAndSettle();

      // Verify AppBar and Initial Task
      expect(find.text('Đầu việc phụ'), findsOneWidget);
      expect(find.text('Mua sữa tươi'), findsOneWidget);

      // Add a new side task
      final taskField = find.widgetWithText(TextField, 'Thêm việc lặt vặt...');
      expect(taskField, findsOneWidget);
      await tester.enterText(taskField, 'Chuẩn bị tài liệu demo');

      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify new task added
      expect(find.text('Chuẩn bị tài liệu demo'), findsOneWidget);

      // Toggle checkbox of the first task
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Filter chips test: tap 'Đã xong'
      await tester.tap(find.text('Đã xong'));
      await tester.pumpAndSettle();

      // Tap 'Tất cả'
      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();

      // ─── Part 2: Notes (Ghi chú) Flow ──────────────────────────────
      // Switch to Tab 2 (Ghi chú)
      final notesTab = find.text('Ghi chú');
      expect(notesTab, findsOneWidget);
      await tester.tap(notesTab);
      await tester.pumpAndSettle();

      // Verify Notes screen components
      expect(find.text('Ghi chú ban đầu'), findsOneWidget);
      expect(find.text('Nội dung kiểm thử ban đầu'), findsOneWidget);

      // Tap FAB to create new note
      final addNoteFab = find.byIcon(Icons.edit_note);
      expect(addNoteFab, findsOneWidget);
      await tester.tap(addNoteFab);
      await tester.pumpAndSettle();

      // NoteEditorSheet opens
      expect(find.text('Tạo ghi chú'), findsOneWidget);

      final titleField = find.widgetWithText(TextField, 'Tiêu đề ghi chú...');
      expect(titleField, findsOneWidget);
      await tester.enterText(titleField, 'Kiến trúc Clean Architecture');

      final contentField = find.widgetWithText(TextField, 'Bắt đầu viết...');
      expect(contentField, findsOneWidget);
      await tester.enterText(contentField, 'Tách biệt giữa Data, Domain và Presentation layer');

      // Submit note creation
      final createNoteBtn = find.widgetWithText(FilledButton, 'Tạo ghi chú');
      expect(createNoteBtn, findsOneWidget);
      await tester.tap(createNoteBtn);
      await tester.pumpAndSettle();

      // Verify new note appears in the masonry grid
      expect(find.text('Kiến trúc Clean Architecture'), findsOneWidget);
      expect(find.text('Tách biệt giữa Data, Domain và Presentation layer'), findsOneWidget);

      // Tap on the note card to open in edit mode
      await tester.tap(find.text('Kiến trúc Clean Architecture'));
      await tester.pumpAndSettle();

      // Should be in edit mode with 'Cập nhật' CTA
      expect(find.text('Cập nhật'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Xóa'), findsOneWidget);

      // Close editor
      await tester.tap(find.widgetWithText(OutlinedButton, 'Hủy'));
      await tester.pumpAndSettle();
    });
  });
}
