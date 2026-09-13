import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todohuy/features/notes/data/note_model.dart';
import 'package:todohuy/features/planner/data/work_item_model.dart';
import 'package:todohuy/features/resources/data/resource_model.dart';
import 'package:todohuy/features/side_tasks/data/side_task_model.dart';
import 'package:todohuy/features/task_groups/data/task_group_model.dart';

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  group('WorkItemModel Tests', () {
    test('toFirestore serializes correctly', () {
      final now = DateTime(2026, 9, 13, 10, 0);
      final item = WorkItemModel(
        id: 'item-1',
        taskGroupId: 'group-1',
        weekStartDate: '2026-09-07',
        content: 'Học unit test',
        status: WorkItemStatus.IN_PROGRESS,
        note: 'Cần hoàn thành trước 12h',
        createdAt: now,
        updatedAt: now,
      );

      final map = item.toFirestore();
      expect(map['taskGroupId'], 'group-1');
      expect(map['weekStartDate'], '2026-09-07');
      expect(map['content'], 'Học unit test');
      expect(map['status'], 'IN_PROGRESS');
      expect(map['note'], 'Cần hoàn thành trước 12h');
      expect((map['createdAt'] as Timestamp).toDate(), now);
      expect((map['updatedAt'] as Timestamp).toDate(), now);
    });

    test('fromFirestore deserializes correctly with status mapping', () {
      final doc = MockDocumentSnapshot();
      when(() => doc.id).thenReturn('item-123');
      when(() => doc.data()).thenReturn({
        'taskGroupId': 'group-1',
        'weekStartDate': '2026-09-07',
        'content': 'Viết test cases',
        'status': 'DONE',
        'note': 'Đã hoàn thành',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 10)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 11)),
      });

      final item = WorkItemModel.fromFirestore(doc);
      expect(item.id, 'item-123');
      expect(item.taskGroupId, 'group-1');
      expect(item.content, 'Viết test cases');
      expect(item.status, WorkItemStatus.DONE);
      expect(item.note, 'Đã hoàn thành');
    });

    test('fromFirestore handles defaults when fields are missing', () {
      final doc = MockDocumentSnapshot();
      when(() => doc.id).thenReturn('item-empty');
      when(() => doc.data()).thenReturn(<String, dynamic>{});

      final item = WorkItemModel.fromFirestore(doc);
      expect(item.id, 'item-empty');
      expect(item.taskGroupId, '');
      expect(item.content, '');
      expect(item.status, WorkItemStatus.TODO);
      expect(item.note, '');
    });
  });

  group('TaskGroupModel Tests', () {
    test('toFirestore serializes correctly', () {
      final now = DateTime(2026, 9, 13);
      final group = TaskGroupModel(
        id: 'tg-1',
        name: 'Học IELTS',
        type: TaskGroupType.MAIN,
        color: '#16A34A',
        displayOrder: 1,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );

      final map = group.toFirestore();
      expect(map['name'], 'Học IELTS');
      expect(map['type'], 'MAIN');
      expect(map['color'], '#16A34A');
      expect(map['displayOrder'], 1);
      expect(map['isArchived'], false);
    });

    test('fromFirestore deserializes correctly with SIDE type', () {
      final doc = MockDocumentSnapshot();
      when(() => doc.id).thenReturn('tg-side');
      when(() => doc.data()).thenReturn({
        'name': 'Việc ngoài',
        'type': 'SIDE',
        'color': '#3B82F6',
        'displayOrder': 2,
        'isArchived': true,
      });

      final group = TaskGroupModel.fromFirestore(doc);
      expect(group.id, 'tg-side');
      expect(group.name, 'Việc ngoài');
      expect(group.type, TaskGroupType.SIDE);
      expect(group.isArchived, true);
    });
  });

  group('NoteModel Tests', () {
    test('parses composite color correctly (colorId:category:icon)', () {
      final note = NoteModel(
        id: 'n-1',
        title: 'Ý tưởng app',
        content: 'Nội dung ghi chú...',
        color: 'blue:Công việc:💼',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.colorId, 'blue');
      expect(note.category, 'Công việc');
      expect(note.icon, '💼');
    });

    test('falls back to defaults if color string is incomplete', () {
      final note = NoteModel(
        id: 'n-2',
        title: 'Ghi chú đơn giản',
        content: '',
        color: 'red',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.colorId, 'red');
      expect(note.category, 'Ý tưởng');
      expect(note.icon, '📝');
    });

    test('toFirestore and fromFirestore match', () {
      final doc = MockDocumentSnapshot();
      when(() => doc.id).thenReturn('n-3');
      when(() => doc.data()).thenReturn({
        'title': 'Họp team',
        'content': 'Thứ hai 9h',
        'color': 'yellow:Dự án:🚀',
      });

      final note = NoteModel.fromFirestore(doc);
      expect(note.title, 'Họp team');
      expect(note.colorId, 'yellow');
      expect(note.category, 'Dự án');
      expect(note.icon, '🚀');

      final map = note.toFirestore();
      expect(map['title'], 'Họp team');
      expect(map['color'], 'yellow:Dự án:🚀');
    });
  });

  group('SideTaskModel Tests', () {
    test('toFirestore and fromFirestore serialize accurately', () {
      final doc = MockDocumentSnapshot();
      when(() => doc.id).thenReturn('st-1');
      when(() => doc.data()).thenReturn({
        'name': 'Mua cà phê',
        'isDone': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 12)),
      });

      final task = SideTaskModel.fromFirestore(doc);
      expect(task.id, 'st-1');
      expect(task.name, 'Mua cà phê');
      expect(task.isDone, true);

      final map = task.toFirestore();
      expect(map['name'], 'Mua cà phê');
      expect(map['isDone'], true);
    });
  });

  group('ResourceModel Tests', () {
    test('serializes with and without taskGroupId', () {
      final resWithGroup = ResourceModel(
        id: 'r-1',
        title: 'Tài liệu Flutter',
        link: 'https://flutter.dev',
        description: 'Docs chính thức',
        taskGroupId: 'group-fl',
        createdAt: DateTime.now(),
      );
      final mapWithGroup = resWithGroup.toFirestore();
      expect(mapWithGroup['taskGroupId'], 'group-fl');

      final resGeneral = ResourceModel(
        id: 'r-2',
        title: 'Google',
        link: 'https://google.com',
        description: '',
        taskGroupId: null,
        createdAt: DateTime.now(),
      );
      final mapGeneral = resGeneral.toFirestore();
      expect(mapGeneral['taskGroupId'], isNull);
    });
  });
}
