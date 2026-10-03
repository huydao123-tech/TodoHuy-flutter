import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

/// Listens to auth state changes and notifies GoRouter to refresh routes
class RouterNotifier extends ChangeNotifier {
  final AuthRepository _authRepo;
  StreamSubscription<User?>? _subscription;

  RouterNotifier(this._authRepo) {
    try {
      _subscription = _authRepo.authStateChanges.listen((_) {
        notifyListeners();
      });
    } catch (_) {
      // In case authStateChanges is not stubbed in unit/widget tests
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Dynamic GoRouter provider supporting auto-session persistence & auth guards.
/// If user is already logged in on this device, the app boots directly to `/`
/// without requiring the user to log in again.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final notifier = RouterNotifier(authRepo);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: authRepo.currentUser != null ? '/' : '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = authRepo.currentUser;
      final matched = state.matchedLocation;
      final isAuthRoute = matched == '/login' || matched == '/forgot-password';

      // Not logged in: only allow auth screens (/login, /forgot-password)
      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      // Logged in: if currently on an auth screen, redirect to home
      if (isAuthRoute) {
        return '/';
      }

      return null;
    },
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
});

/// Fallback static router instance for backward compatibility
final goRouter = GoRouter(
  initialLocation: '/login',
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
