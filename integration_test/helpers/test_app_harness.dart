import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:todohuy/core/theme/app_colors.dart';
import 'package:todohuy/features/auth/data/auth_repository.dart';
import 'package:todohuy/features/auth/presentation/forgot_password_screen.dart';
import 'package:todohuy/features/auth/presentation/login_screen.dart';
import 'package:todohuy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:todohuy/features/notes/data/note_model.dart';
import 'package:todohuy/features/notes/data/notes_repository.dart';
import 'package:todohuy/features/planner/data/planner_repository.dart';
import 'package:todohuy/features/planner/data/weekly_goal_model.dart';
import 'package:todohuy/features/planner/data/work_item_model.dart';
import 'package:todohuy/features/resources/data/resource_model.dart';
import 'package:todohuy/features/resources/data/resources_repository.dart';
import 'package:todohuy/features/side_tasks/data/side_task_model.dart';
import 'package:todohuy/features/side_tasks/data/side_tasks_repository.dart';
import 'package:todohuy/features/task_groups/data/task_group_model.dart';
import 'package:todohuy/features/task_groups/data/task_group_repository.dart';

// ignore: subtype_of_sealed_class
class MockUser extends Mock implements User {
  @override
  String get uid => 'test-user-id';
  @override
  String? get email => 'test@example.com';
  @override
  String? get displayName => 'Huy Đào';
}

class FakeAuthRepository extends Mock implements AuthRepository {
  User? _user;
  final _controller = StreamController<User?>.broadcast();

  FakeAuthRepository({bool authenticated = false}) {
    if (authenticated) {
      _user = MockUser();
    }
  }

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    _user = MockUser();
    _controller.add(_user);
  }

  @override
  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    _user = MockUser();
    _controller.add(_user);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Simulated success
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}

class FakeTaskGroupRepository extends Mock implements TaskGroupRepository {
  final List<TaskGroupModel> activeGroups;
  final List<TaskGroupModel> archivedGroups;
  late final StreamController<List<TaskGroupModel>> _activeController;
  late final StreamController<List<TaskGroupModel>> _archivedController;

  FakeTaskGroupRepository({
    List<TaskGroupModel>? initialActive,
    List<TaskGroupModel>? initialArchived,
  })  : activeGroups = initialActive ?? [],
        archivedGroups = initialArchived ?? [] {
    _activeController = StreamController<List<TaskGroupModel>>.broadcast();
    _archivedController = StreamController<List<TaskGroupModel>>.broadcast();
  }

  @override
  Stream<List<TaskGroupModel>> watchActiveTaskGroups(String userId) {
    scheduleMicrotask(() => _activeController.add(List.unmodifiable(activeGroups)));
    return _activeController.stream;
  }

  @override
  Stream<List<TaskGroupModel>> watchArchivedTaskGroups(String userId) {
    scheduleMicrotask(() => _archivedController.add(List.unmodifiable(archivedGroups)));
    return _archivedController.stream;
  }

  @override
  Future<void> createTaskGroup(String userId, String name, String color, int displayOrder,
      {TaskGroupType type = TaskGroupType.MAIN}) async {
    final group = TaskGroupModel(
      id: 'tg-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      color: color,
      displayOrder: displayOrder,
      isArchived: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    activeGroups.add(group);
    _activeController.add(List.unmodifiable(activeGroups));
  }

  @override
  Future<void> archiveTaskGroup(String userId, String groupId) async {
    final idx = activeGroups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final g = activeGroups.removeAt(idx);
      final archived = TaskGroupModel(
        id: g.id,
        name: g.name,
        type: g.type,
        color: g.color,
        displayOrder: g.displayOrder,
        isArchived: true,
        archivedAt: DateTime.now(),
        createdAt: g.createdAt,
        updatedAt: DateTime.now(),
      );
      archivedGroups.add(archived);
      _activeController.add(List.unmodifiable(activeGroups));
      _archivedController.add(List.unmodifiable(archivedGroups));
    }
  }

  @override
  Future<void> restoreTaskGroup(String userId, String groupId) async {
    final idx = archivedGroups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final g = archivedGroups.removeAt(idx);
      final restored = TaskGroupModel(
        id: g.id,
        name: g.name,
        type: g.type,
        color: g.color,
        displayOrder: g.displayOrder,
        isArchived: false,
        createdAt: g.createdAt,
        updatedAt: DateTime.now(),
      );
      activeGroups.add(restored);
      _activeController.add(List.unmodifiable(activeGroups));
      _archivedController.add(List.unmodifiable(archivedGroups));
    }
  }
}

class FakePlannerRepository extends Mock implements PlannerRepository {
  final FakeTaskGroupRepository taskGroupRepo;
  final List<WorkItemModel> workItems;
  final Map<String, StreamController<List<WorkItemModel>>> _weekControllers = {};

  FakePlannerRepository({
    required this.taskGroupRepo,
    List<WorkItemModel>? initialItems,
  }) : workItems = initialItems ?? [];

  StreamController<List<WorkItemModel>> _getWeekController(String weekStartDate) {
    return _weekControllers.putIfAbsent(weekStartDate, () => StreamController<List<WorkItemModel>>.broadcast());
  }

  void _notifyWeek(String weekStartDate) {
    final items = workItems.where((i) => i.weekStartDate == weekStartDate).toList();
    _getWeekController(weekStartDate).add(List.unmodifiable(items));
  }

  @override
  Stream<List<TaskGroupModel>> watchTaskGroups(String userId) {
    return taskGroupRepo.watchActiveTaskGroups(userId);
  }

  @override
  Stream<List<WorkItemModel>> watchWorkItemsForWeek(String userId, String weekStartDate) {
    final ctrl = _getWeekController(weekStartDate);
    scheduleMicrotask(() => _notifyWeek(weekStartDate));
    return ctrl.stream;
  }

  @override
  Stream<List<WeeklyGoalModel>> watchWeeklyGoalsForWeek(String userId, String weekStartDate) {
    return Stream.value([]);
  }

  @override
  Future<void> addWorkItem(String userId, WorkItemModel item) async {
    final newItem = WorkItemModel(
      id: 'wi-${DateTime.now().millisecondsSinceEpoch}',
      taskGroupId: item.taskGroupId,
      weekStartDate: item.weekStartDate,
      content: item.content,
      status: item.status,
      note: item.note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    workItems.add(newItem);
    _notifyWeek(item.weekStartDate);
  }

  @override
  Future<void> updateWorkItemStatus(String userId, String itemId, WorkItemStatus status) async {
    final idx = workItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final current = workItems[idx];
      workItems[idx] = WorkItemModel(
        id: current.id,
        taskGroupId: current.taskGroupId,
        weekStartDate: current.weekStartDate,
        content: current.content,
        status: status,
        note: current.note,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
      _notifyWeek(current.weekStartDate);
    }
  }

  @override
  Future<void> deleteWorkItem(String userId, String itemId) async {
    final idx = workItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final week = workItems[idx].weekStartDate;
      workItems.removeAt(idx);
      _notifyWeek(week);
    }
  }
}

class FakeSideTasksRepository extends Mock implements SideTasksRepository {
  final List<SideTaskModel> tasks;
  late final StreamController<List<SideTaskModel>> _controller;

  FakeSideTasksRepository({List<SideTaskModel>? initialTasks})
      : tasks = initialTasks ?? [] {
    _controller = StreamController<List<SideTaskModel>>.broadcast();
  }

  @override
  Stream<List<SideTaskModel>> watchSideTasks(String userId) {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(tasks)));
    return _controller.stream;
  }

  @override
  Future<void> addSideTask(String userId, String name, {bool isDone = false}) async {
    final t = SideTaskModel(
      id: 'st-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isDone: isDone,
      createdAt: DateTime.now(),
    );
    tasks.insert(0, t);
    _controller.add(List.unmodifiable(tasks));
  }

  @override
  Future<void> toggleSideTaskCompletion(String userId, String taskId, bool isDone) async {
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final cur = tasks[idx];
      tasks[idx] = SideTaskModel(
        id: cur.id,
        name: cur.name,
        isDone: isDone,
        createdAt: cur.createdAt,
      );
      _controller.add(List.unmodifiable(tasks));
    }
  }

  @override
  Future<void> deleteSideTask(String userId, String taskId) async {
    tasks.removeWhere((t) => t.id == taskId);
    _controller.add(List.unmodifiable(tasks));
  }
}

class FakeNotesRepository extends Mock implements NotesRepository {
  final List<NoteModel> notes;
  late final StreamController<List<NoteModel>> _controller;

  FakeNotesRepository({List<NoteModel>? initialNotes})
      : notes = initialNotes ?? [] {
    _controller = StreamController<List<NoteModel>>.broadcast();
  }

  @override
  Stream<List<NoteModel>> watchNotes(String userId) {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(notes)));
    return _controller.stream;
  }

  @override
  Future<void> addNote(String userId, NoteModel note) async {
    final n = NoteModel(
      id: 'note-${DateTime.now().millisecondsSinceEpoch}',
      title: note.title,
      content: note.content,
      color: note.color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notes.insert(0, n);
    _controller.add(List.unmodifiable(notes));
  }

  @override
  Future<void> updateNote(String userId, String noteId, Map<String, dynamic> data) async {
    final idx = notes.indexWhere((n) => n.id == noteId);
    if (idx != -1) {
      final cur = notes[idx];
      notes[idx] = NoteModel(
        id: cur.id,
        title: data['title'] ?? cur.title,
        content: data['content'] ?? cur.content,
        color: data['color'] ?? cur.color,
        createdAt: cur.createdAt,
        updatedAt: DateTime.now(),
      );
      _controller.add(List.unmodifiable(notes));
    }
  }

  @override
  Future<void> deleteNote(String userId, String noteId) async {
    notes.removeWhere((n) => n.id == noteId);
    _controller.add(List.unmodifiable(notes));
  }
}

class FakeResourcesRepository extends Mock implements ResourcesRepository {
  final List<ResourceModel> resources;
  late final StreamController<List<ResourceModel>> _controller;

  FakeResourcesRepository({List<ResourceModel>? initialResources})
      : resources = initialResources ?? [] {
    _controller = StreamController<List<ResourceModel>>.broadcast();
  }

  @override
  Stream<List<ResourceModel>> watchResources(String userId) {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(resources)));
    return _controller.stream;
  }

  @override
  Future<void> addResource(String userId, String title, String link, String description, String? taskGroupId) async {
    final r = ResourceModel(
      id: 'res-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      link: link,
      description: description,
      taskGroupId: taskGroupId,
      createdAt: DateTime.now(),
    );
    resources.add(r);
    _controller.add(List.unmodifiable(resources));
  }

  @override
  Future<void> deleteResource(String userId, String resourceId) async {
    resources.removeWhere((r) => r.id == resourceId);
    _controller.add(List.unmodifiable(resources));
  }
}

/// Helper function to create an isolated GoRouter instance for testing
GoRouter createTestRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => ForgotPasswordScreen(
          initialEmail: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
}

/// Builds a testable app wrapped in ProviderScope with specified overrides
Widget createTestApp({
  required GoRouter router,
  required FakeAuthRepository authRepo,
  FakeTaskGroupRepository? taskGroupRepo,
  FakePlannerRepository? plannerRepo,
  FakeSideTasksRepository? sideTasksRepo,
  FakeNotesRepository? notesRepo,
  FakeResourcesRepository? resourcesRepo,
}) {
  PackageInfo.setMockInitialValues(
    appName: 'WeekLoop',
    packageName: 'com.example.todohuy',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );

  final tg = taskGroupRepo ?? FakeTaskGroupRepository();
  final pl = plannerRepo ?? FakePlannerRepository(taskGroupRepo: tg);
  final st = sideTasksRepo ?? FakeSideTasksRepository();
  final nt = notesRepo ?? FakeNotesRepository();
  final rs = resourcesRepo ?? FakeResourcesRepository();

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
      taskGroupRepositoryProvider.overrideWithValue(tg),
      plannerRepositoryProvider.overrideWithValue(pl),
      sideTasksRepositoryProvider.overrideWithValue(st),
      notesRepositoryProvider.overrideWithValue(nt),
      resourcesRepositoryProvider.overrideWithValue(rs),
    ],
    child: MaterialApp.router(
      title: 'WeekLoop',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
    ),
  );
}
