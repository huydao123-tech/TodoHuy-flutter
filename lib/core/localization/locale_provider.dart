import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

const String _kLocaleKey = 'user_selected_locale';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

final currentAppLanguageProvider = Provider<AppLanguage>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLanguage.fromCode(locale.languageCode);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('vi')) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kLocaleKey);
      if (code != null && (code == 'vi' || code == 'en')) {
        state = Locale(code);
      }
    } catch (e) {
      debugPrint('[LocaleNotifier] Failed to load locale from preferences: $e');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state == newLocale) return;
    state = newLocale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleKey, newLocale.languageCode);
    } catch (e) {
      debugPrint('[LocaleNotifier] Failed to save locale to preferences: $e');
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    await setLocale(Locale(language.code));
  }

  Future<void> toggleLanguage() async {
    if (state.languageCode == 'vi') {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('vi'));
    }
  }
}
