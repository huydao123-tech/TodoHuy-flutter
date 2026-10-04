import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_localizations.dart';
import 'app_colors.dart';
import 'theme_mode_provider.dart';

Future<void> showThemeModeSelectionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const ThemeModeSelectionSheet(),
  );
}

class ThemeModeSelectionSheet extends ConsumerWidget {
  const ThemeModeSelectionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentMode = ref.watch(themeModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: context.appBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.themeMode,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.appTextColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildOption(
            context: context,
            title: l10n.lightTheme,
            subtitle: context.l10n.isVietnamese ? 'Tông màu sáng sạch sẽ' : 'Clean light appearance',
            icon: Icons.light_mode_rounded,
            isSelected: currentMode == ThemeMode.light,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _buildOption(
            context: context,
            title: l10n.darkTheme,
            subtitle: context.l10n.isVietnamese ? 'Dễ chịu cho mắt ban đêm' : 'Easy on the eyes at night',
            icon: Icons.dark_mode_rounded,
            isSelected: currentMode == ThemeMode.dark,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _buildOption(
            context: context,
            title: l10n.systemTheme,
            subtitle: context.l10n.isVietnamese ? 'Tự động theo cài đặt thiết bị' : 'Matches device settings',
            icon: Icons.brightness_auto_rounded,
            isSelected: currentMode == ThemeMode.system,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
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
    required IconData icon,
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
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : (context.isDarkMode ? AppColors.darkSurfaceSubtle : AppColors.bgAlt),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : context.appBorderColor,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : context.appBorderColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : context.appTextMutedColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.accent : context.appTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appTextMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
