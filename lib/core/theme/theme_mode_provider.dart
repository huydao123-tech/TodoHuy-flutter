import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'user_selected_theme_mode';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_kThemeModeKey);
      if (modeStr != null) {
        state = ThemeMode.values.firstWhere(
          (m) => m.name == modeStr,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      debugPrint('[ThemeModeNotifier] Failed to load theme mode: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    if (state == newMode) return;
    state = newMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeModeKey, newMode.name);
    } catch (e) {
      debugPrint('[ThemeModeNotifier] Failed to save theme mode: $e');
    }
  }

  Future<void> toggleTheme(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
