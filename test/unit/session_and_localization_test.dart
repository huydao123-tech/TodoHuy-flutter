import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todohuy/core/localization/app_localizations.dart';
import 'package:todohuy/core/localization/language_switch_button.dart';
import 'package:todohuy/features/auth/data/auth_repository.dart';
import 'package:todohuy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:todohuy/features/notes/data/notes_repository.dart';
import 'package:todohuy/features/planner/data/planner_repository.dart';
import 'package:todohuy/features/side_tasks/data/side_tasks_repository.dart';
import 'package:todohuy/features/task_groups/data/task_group_repository.dart';
import 'package:todohuy/main.dart';

// ignore: subtype_of_sealed_class
class MockUser extends Mock implements User {
  @override
  String get uid => 'user-session-123';
  @override
  String? get email => 'persisted_user@weekloop.app';
  @override
  String? get displayName => 'Huy Dao';
}

class MockAuthRepository extends Mock implements AuthRepository {}
class MockTaskGroupRepository extends Mock implements TaskGroupRepository {}
class MockPlannerRepository extends Mock implements PlannerRepository {}
class MockSideTasksRepository extends Mock implements SideTasksRepository {}
class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Session Persistence (Lưu phiên đăng nhập)', () {
    testWidgets('When already logged in on device, boots directly to Dashboard without login screen', (tester) async {
      final mockAuthRepo = MockAuthRepository();
      final mockUser = MockUser();
      final mockTaskGroupRepo = MockTaskGroupRepository();
      final mockPlannerRepo = MockPlannerRepository();
      final mockSideTasksRepo = MockSideTasksRepository();
      final mockNotesRepo = MockNotesRepository();

      when(() => mockAuthRepo.currentUser).thenReturn(mockUser);
      when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockTaskGroupRepo.watchActiveTaskGroups(any())).thenAnswer((_) => Stream.value([]));
      when(() => mockPlannerRepo.watchTaskGroups(any())).thenAnswer((_) => Stream.value([]));
      when(() => mockSideTasksRepo.watchSideTasks(any())).thenAnswer((_) => Stream.value([]));
      when(() => mockNotesRepo.watchNotes(any())).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            taskGroupRepositoryProvider.overrideWithValue(mockTaskGroupRepo),
            plannerRepositoryProvider.overrideWithValue(mockPlannerRepo),
            sideTasksRepositoryProvider.overrideWithValue(mockSideTasksRepo),
            notesRepositoryProvider.overrideWithValue(mockNotesRepo),
          ],
          child: const TodoHuyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify user is directly on DashboardScreen
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      // Login screen elements should NOT be present
      expect(find.widgetWithText(FilledButton, 'Đăng Nhập'), findsNothing);
    });

    testWidgets('When not logged in on device, boots to LoginScreen', (tester) async {
      final mockAuthRepo = MockAuthRepository();
      when(() => mockAuthRepo.currentUser).thenReturn(null);
      when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
          child: const TodoHuyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify user is on LoginScreen
      expect(find.text('WeekLoop'), findsOneWidget);
      expect(find.text('Đăng Nhập'), findsWidgets);
      expect(find.text('Đăng Ký'), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });
  });

  group('Multi-language & Language Selection (Tiếng Anh & Đổi ngôn ngữ)', () {
    test('AppLocalizations returns correct translation strings for vi and en', () {
      const vi = AppLocalizations(Locale('vi'));
      const en = AppLocalizations(Locale('en'));

      expect(vi.login, 'Đăng Nhập');
      expect(en.login, 'Log In');

      expect(vi.signUp, 'Đăng Ký');
      expect(en.signUp, 'Sign Up');

      expect(vi.language, 'Ngôn ngữ');
      expect(en.language, 'Language');

      expect(vi.selectLanguage, 'Chọn ngôn ngữ');
      expect(en.selectLanguage, 'Select Language');

      expect(vi.sideTasks, 'Việc phụ');
      expect(en.sideTasks, 'Side Tasks');

      expect(vi.notes, 'Ghi chú');
      expect(en.notes, 'Notes');

      expect(vi.logout, 'Đăng xuất');
      expect(en.logout, 'Log out');
    });

    testWidgets('Tapping English language pill switches LoginScreen UI to English', (tester) async {
      final mockAuthRepo = MockAuthRepository();
      when(() => mockAuthRepo.currentUser).thenReturn(null);
      when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
          child: const TodoHuyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initially Vietnamese
      expect(find.text('Đăng Nhập'), findsWidgets);
      expect(find.text('Đăng Ký'), findsOneWidget);
      expect(find.text('🇻🇳 VI'), findsOneWidget);
      expect(find.text('🇬🇧 EN'), findsOneWidget);

      // Tap EN pill to switch to English
      await tester.tap(find.text('🇬🇧 EN'));
      await tester.pumpAndSettle();

      // Verify UI is now in English
      expect(find.text('Log In'), findsWidgets);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // Tap VI pill to switch back to Vietnamese
      await tester.tap(find.text('🇻🇳 VI'));
      await tester.pumpAndSettle();

      // Verify UI is back in Vietnamese
      expect(find.text('Đăng Nhập'), findsWidgets);
      expect(find.text('Đăng Ký'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
    });

    testWidgets('Saved language preference in SharedPreferences is loaded on startup', (tester) async {
      // Simulate user previously chose English
      SharedPreferences.setMockInitialValues({'user_selected_locale': 'en'});

      final mockAuthRepo = MockAuthRepository();
      when(() => mockAuthRepo.currentUser).thenReturn(null);
      when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
          child: const TodoHuyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should automatically boot in English
      expect(find.text('Log In'), findsWidgets);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Language selection sheet displays both Vietnamese and English options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('vi'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showLanguageSelectionSheet(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn ngôn ngữ'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });
  });
}
