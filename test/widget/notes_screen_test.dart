import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todohuy/features/notes/data/note_model.dart';
import 'package:todohuy/features/notes/data/notes_repository.dart';
import 'package:todohuy/features/notes/presentation/notes_screen.dart';

void main() {
  Widget buildTestableWidget({List<NoteModel> notes = const []}) {
    return ProviderScope(
      overrides: [
        notesProvider.overrideWith((ref) => Stream.value(notes)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: NotesScreen(),
        ),
      ),
    );
  }

  group('NotesScreen Widget Tests', () {
    testWidgets('renders search bar, category chips and empty state', (tester) async {
      await tester.pumpWidget(buildTestableWidget(notes: []));
      await tester.pumpAndSettle();

      // Search field
      expect(find.byType(TextField), findsOneWidget);

      // Category chips
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Ý tưởng'), findsOneWidget);
      expect(find.text('Công việc'), findsOneWidget);

      // Empty state
      expect(find.text('Chưa có ghi chú nào.\nNhấn + để tạo ghi chú đầu tiên.'), findsOneWidget);
    });

    testWidgets('renders notes and filters by category', (tester) async {
      final notes = [
        NoteModel(
          id: 'n-1',
          title: 'Ý tưởng start-up',
          content: 'Làm app Todo siêu đỉnh',
          color: 'blue:Ý tưởng:💡',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NoteModel(
          id: 'n-2',
          title: 'Họp với sếp',
          content: 'Báo cáo tiến độ tuần',
          color: 'red:Công việc:💼',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(notes: notes));
      await tester.pumpAndSettle();

      // Initially 'Tất cả' shows both
      expect(find.text('Ý tưởng start-up'), findsOneWidget);
      expect(find.text('Họp với sếp'), findsOneWidget);

      // Tap 'Công việc' chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Công việc'));
      await tester.pumpAndSettle();

      // Only 'Họp với sếp' is visible
      expect(find.text('Họp với sếp'), findsOneWidget);
      expect(find.text('Ý tưởng start-up'), findsNothing);
    });

    testWidgets('filters notes using search input', (tester) async {
      final notes = [
        NoteModel(
          id: 'n-1',
          title: 'Học từ vựng IELTS',
          content: '50 từ mỗi ngày',
          color: 'green:Học tập:📚',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NoteModel(
          id: 'n-2',
          title: 'Đi siêu thị',
          content: 'Mua rau quả',
          color: 'yellow:Cá nhân:🛒',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(notes: notes));
      await tester.pumpAndSettle();

      // Type in search bar
      await tester.enterText(find.byType(TextField), 'IELTS');
      await tester.pumpAndSettle();

      // Only IELTS note should match
      expect(find.text('Học từ vựng IELTS'), findsOneWidget);
      expect(find.text('Đi siêu thị'), findsNothing);
    });
  });
}
