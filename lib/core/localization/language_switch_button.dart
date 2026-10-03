import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import 'app_localizations.dart';
import 'locale_provider.dart';

/// A compact, premium pill button for switching languages (e.g. on LoginScreen).
class LanguagePillToggle extends ConsumerWidget {
  const LanguagePillToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(currentAppLanguageProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            context: context,
            label: '🇻🇳 VI',
            isActive: currentLang == AppLanguage.vi,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(localeProvider.notifier).setLanguage(AppLanguage.vi);
            },
          ),
          const SizedBox(width: 2),
          _buildItem(
            context: context,
            label: '🇬🇧 EN',
            isActive: currentLang == AppLanguage.en,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(localeProvider.notifier).setLanguage(AppLanguage.en);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.accent : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Helper modal to show language selection in Drawer or Settings.
Future<void> showLanguageSelectionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _LanguageSelectionSheet(),
  );
}

class _LanguageSelectionSheet extends ConsumerWidget {
  const _LanguageSelectionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentLang = ref.watch(currentAppLanguageProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.selectLanguage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildOption(
            context: context,
            title: 'Tiếng Việt',
            subtitle: 'Mặc định (Default)',
            flag: '🇻🇳',
            isSelected: currentLang == AppLanguage.vi,
            onTap: () {
              ref.read(localeProvider.notifier).setLanguage(AppLanguage.vi);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _buildOption(
            context: context,
            title: 'English',
            subtitle: 'English language',
            flag: '🇬🇧',
            isSelected: currentLang == AppLanguage.en,
            onTap: () {
              ref.read(localeProvider.notifier).setLanguage(AppLanguage.en);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.08) : AppColors.bgAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.accent : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 22)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textFaint, size: 22),
          ],
        ),
      ),
    );
  }
}
