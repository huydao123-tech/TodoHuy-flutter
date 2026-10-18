import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todohuy/core/theme/app_colors.dart';
import 'package:todohuy/features/auth/data/auth_repository.dart';
import 'package:todohuy/features/task_groups/data/task_group_model.dart';
import 'package:todohuy/features/task_groups/data/task_group_repository.dart';
import 'package:todohuy/features/task_groups/presentation/group_priority_sheet.dart';

class MockAuth extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

class MockGroups extends Mock implements TaskGroupRepository {}

void main() {
  late MockAuth auth;
  late MockUser user;
  late MockGroups repository;
  final groups = List.generate(
      3,
      (index) => TaskGroupModel(
            id: 'g-$index',
            name: 'Nhóm $index',
            type: TaskGroupType.MAIN,
            color: '#16A34A',
            displayOrder: index + 1,
            isArchived: false,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ));

  setUp(() {
    auth = MockAuth();
    user = MockUser();
    repository = MockGroups();
    when(() => user.uid).thenReturn('u-1');
    when(() => auth.currentUser).thenReturn(user);
  });

  Future<void> openSheet(WidgetTester tester,
      {Brightness brightness = Brightness.light}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        taskGroupRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
          theme: ThemeData(
            brightness: brightness,
            bottomSheetTheme:
                const BottomSheetThemeData(backgroundColor: Colors.transparent),
          ),
          home: Scaffold(
              backgroundColor: Colors.pink,
              body: Builder(
                  builder: (context) => TextButton(
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => RepaintBoundary(
                            key: const ValueKey('priority-preview'),
                            child: GroupPrioritySheet(groups: groups),
                          ),
                        ),
                        child: const Text('Open'),
                      )))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets(
        'priority sheet paints an opaque surface in ${brightness.name} theme',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openSheet(tester, brightness: brightness);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('priority-preview')));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final pixels =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        final offset = ((image.height ~/ 2) * image.width + 4) * 4;
        final expected = brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface;
        expect(pixels.getUint8(offset), (expected.r * 255).round());
        expect(pixels.getUint8(offset + 1), (expected.g * 255).round());
        expect(pixels.getUint8(offset + 2), (expected.b * 255).round());
        expect(pixels.getUint8(offset + 3), 255);
        if (Platform.environment['PRIORITY_SCREENSHOTS'] == '1') {
          final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          final file = File('build/qa/priority-${brightness.name}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png.buffer.asUint8List());
        }
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dragging a group to the top saves the new order and closes',
      (tester) async {
    when(() => repository.reorderTaskGroups(any(), any()))
        .thenAnswer((_) async {});
    await openSheet(tester);
    final handles = find.byIcon(Icons.drag_handle_rounded);
    final gesture = await tester.startGesture(tester.getCenter(handles.last));
    for (var step = 0; step < 8; step++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pumpAndSettle();
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Nhóm 2')).dy,
        lessThan(tester.getTopLeft(find.text('Nhóm 0')).dy));
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    verify(() => repository.reorderTaskGroups('u-1', ['g-2', 'g-0', 'g-1']))
        .called(1);
    expect(find.byType(GroupPrioritySheet), findsNothing);
  });

  testWidgets('failed save keeps the order editable and supports retry',
      (tester) async {
    when(() => repository.reorderTaskGroups(any(), any()))
        .thenThrow(Exception('offline'));
    await openSheet(tester);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(
        find.text('Không lưu được thứ tự. Vui lòng thử lại.'), findsOneWidget);
    expect(find.byType(GroupPrioritySheet), findsOneWidget);
    when(() => repository.reorderTaskGroups(any(), any()))
        .thenAnswer((_) async {});
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupPrioritySheet), findsNothing);
  });

  testWidgets('moving the first group down saves the correct lower priority',
      (tester) async {
    when(() => repository.reorderTaskGroups(any(), any()))
        .thenAnswer((_) async {});
    await openSheet(tester);
    final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.drag_handle_rounded).first));
    for (var step = 0; step < 8; step++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pumpAndSettle();
    }
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    verify(() => repository.reorderTaskGroups('u-1', ['g-1', 'g-2', 'g-0']))
        .called(1);
  });

  testWidgets('dismissing without save does not change stored priority',
      (tester) async {
    await openSheet(tester);
    await tester.drag(
        find.byIcon(Icons.drag_handle_rounded).last, const Offset(0, -140));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(GroupPrioritySheet))).pop();
    await tester.pumpAndSettle();
    verifyNever(() => repository.reorderTaskGroups(any(), any()));
  });
}
