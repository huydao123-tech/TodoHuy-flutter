import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/theme/theme_mode_sheet.dart';
import '../../../core/utils/week_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../../planner/data/planner_repository.dart';
import '../../planner/data/work_item_model.dart';
import '../../task_groups/data/task_group_model.dart';
import '../../task_groups/data/task_group_repository.dart';
import '../../task_groups/presentation/trash_sheet.dart';
import '../../resources/presentation/resources_sheet.dart';
import '../../notes/presentation/note_editor_sheet.dart';
import '../../planner/presentation/planner_screen.dart';
import 'widgets/side_panel_tab.dart';
import '../../notes/presentation/notes_screen.dart';
import '../../../core/updater/app_updater.dart';
import '../../../core/updater/update_dialog.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/language_switch_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdateOnStartup();
    });
  }

  Future<void> _checkUpdateOnStartup() async {
    final info = await AppUpdater.checkForUpdate();
    if (info.hasUpdate && mounted) {
      UpdateDialog.show(context, info);
    }
  }

  Future<void> _manualCheckUpdate(BuildContext context) async {
    Navigator.pop(context);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(l10n.checkingForUpdates),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    final info = await AppUpdater.checkForUpdate();
    if (!context.mounted) return;

    if (info.hasUpdate) {
      UpdateDialog.show(context, info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.appUpToDate(info.currentVersion.split("+").first),
          ),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        selectedItemColor: AppColors.accent,
        unselectedItemColor: context.appTextMutedColor,
        backgroundColor: context.cardBgColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, letterSpacing: -0.2),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11.5, letterSpacing: -0.2),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_view_week_outlined),
            activeIcon: const Icon(Icons.calendar_view_week),
            label: context.l10n.planner,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.check_circle_outline),
            activeIcon: const Icon(Icons.check_circle),
            label: context.l10n.sideTasks,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sticky_note_2_outlined),
            activeIcon: const Icon(Icons.sticky_note_2),
            label: context.l10n.notes,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = context.l10n;
    final user = ref.watch(authRepositoryProvider).currentUser;
    final initial = (user?.displayName?.isNotEmpty == true
        ? user!.displayName![0].toUpperCase()
        : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'W'));

    String title;
    String subtitle;
    switch (_currentIndex) {
      case 0:
        title = l10n.appName;
        subtitle = l10n.tagline;
        break;
      case 1:
        title = l10n.sideTasksTitle;
        subtitle = l10n.isVietnamese ? 'Ghi nhanh việc lặt vặt' : 'Quick side tasks';
        break;
      case 2:
      default:
        title = l10n.notes;
        subtitle = l10n.isVietnamese ? 'Ý tưởng & Tài liệu' : 'Ideas & Documents';
        break;
    }

    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          color: context.appTextColor,
          tooltip: 'Menu',
          onPressed: () {
            HapticFeedback.lightImpact();
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: context.appTextColor,
              fontSize: 19,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.appTextMutedColor,
            ),
          ),
        ],
      ),
      backgroundColor: context.scaffoldBgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: Icon(
            context.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: context.appTextColor,
            size: 20,
          ),
          tooltip: context.l10n.themeMode,
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(themeModeProvider.notifier).toggleTheme(context);
          },
        ),
        Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Scaffold.of(context).openDrawer();
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.2), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return PlannerScreen(onAddGroup: _showAddGroupSheet);
      case 1:
        return const SidePanelTab();
      case 2:
      default:
        return const NotesScreen();
    }
  }

  Widget? _buildFab() {
    switch (_currentIndex) {
      case 0:
        // On planner tab: FAB opens add-task sheet
        return FloatingActionButton(
          heroTag: 'planner-fab',
          onPressed: () {
            HapticFeedback.lightImpact();
            _showAddTaskSheet();
          },
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, size: 28),
        );
      case 1:
        return null;
      case 2:
      default:
        return FloatingActionButton(
          heroTag: 'notes-fab',
          onPressed: () {
            HapticFeedback.lightImpact();
            _openNoteEditor(context);
          },
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.edit_note, size: 28),
        );
    }
  }

  void _openNoteEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NoteEditorSheet(),
    );
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(
        onAddGroup: () {
          Navigator.pop(context);
          _showAddGroupSheet();
        },
      ),
    );
  }

  void _showAddGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGroupSheet(),
    );
  }

  Future<void> _editTaskGroup(BuildContext context, TaskGroupModel group) async {
    final controller = TextEditingController(text: group.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sửa tên nhóm công việc', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên nhóm mới...',
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != group.name) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        await ref.read(taskGroupRepositoryProvider).updateTaskGroup(
          user.uid,
          group.id,
          {'name': newName},
        );
      }
    }
  }

  Future<void> _deleteTaskGroup(BuildContext context, TaskGroupModel group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa nhóm công việc?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text('Nhóm "${group.name}" sẽ được chuyển vào thùng rác và có thể khôi phục sau.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        await ref.read(taskGroupRepositoryProvider).archiveTaskGroup(user.uid, group.id);
      }
    }
  }

  Widget _buildDrawer() {
    final l10n = context.l10n;
    final user = ref.watch(authRepositoryProvider).currentUser;
    final taskGroupsAsync = ref.watch(taskGroupsProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Drawer(
      backgroundColor: context.cardBgColor,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Linear Style User Profile Header ────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.appBorderColor, width: 0.8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0].toUpperCase()
                          : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'U')),
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Người dùng',
                          style: TextStyle(
                            color: context.appTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(color: context.appTextMutedColor, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Task Groups Section ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 6),
              child: Row(
                children: [
                  Text(
                    'NHÓM CÔNG VIỆC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.appTextMutedColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 20, color: AppColors.accent),
                    tooltip: 'Tạo nhóm mới',
                    visualDensity: VisualDensity.compact,
                    onPressed: _showAddGroupSheet,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  taskGroupsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (groups) {
                      if (groups.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: InkWell(
                            onTap: _showAddGroupSheet,
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '+ Thêm nhóm đầu tiên',
                                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: groups.map((g) {
                          Color groupColor;
                          try {
                            groupColor = Color(int.parse(g.color.replaceAll('#', '0xff')));
                          } catch (_) {
                            groupColor = AppColors.accent;
                          }
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                            leading: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: groupColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: groupColor.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            title: Text(
                              g.name,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.appTextColor),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textFaint),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  tooltip: 'Sửa tên',
                                  onPressed: () => _editTaskGroup(context, g),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.archive_outlined, size: 16, color: AppColors.textFaint),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  tooltip: 'Lưu trữ vào thùng rác',
                                  onPressed: () => _deleteTaskGroup(context, g),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.pop(context),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: context.appBorderColor, height: 1),
                  ),

                  // ─── Tools & Utilities ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 12, 6),
                    child: Text(
                      l10n.utilitiesSection,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.appTextMutedColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    leading: const Icon(Icons.bookmark_border_rounded, color: AppColors.textSecondary, size: 20),
                    title: Text(l10n.resourcesAndLinks, style: TextStyle(color: context.appTextColor, fontSize: 14, fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const ResourcesSheet(),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
                    title: Text(l10n.trash, style: TextStyle(color: context.appTextColor, fontSize: 14, fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const TrashSheet(),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    leading: const Icon(Icons.language_rounded, color: AppColors.textSecondary, size: 20),
                    title: Text(l10n.language, style: TextStyle(color: context.appTextColor, fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? AppColors.darkSurfaceSubtle : AppColors.bgAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.appBorderColor, width: 0.8),
                      ),
                      child: Text(
                        ref.watch(currentAppLanguageProvider) == AppLanguage.vi ? '🇻🇳 Tiếng Việt' : '🇬🇧 English',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showLanguageSelectionSheet(context);
                    },
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    leading: Icon(
                      currentThemeMode == ThemeMode.dark
                          ? Icons.dark_mode_rounded
                          : (currentThemeMode == ThemeMode.light ? Icons.light_mode_rounded : Icons.brightness_auto_rounded),
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    title: Text(l10n.theme, style: TextStyle(color: context.appTextColor, fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? AppColors.darkSurfaceSubtle : AppColors.bgAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.appBorderColor, width: 0.8),
                      ),
                      child: Text(
                        currentThemeMode == ThemeMode.dark
                            ? '🌙 ${l10n.darkTheme}'
                            : (currentThemeMode == ThemeMode.light ? '☀️ ${l10n.lightTheme}' : '📱 ${l10n.systemTheme}'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showThemeModeSelectionSheet(context);
                    },
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    leading: const Icon(Icons.system_update_alt_rounded, color: AppColors.textSecondary, size: 20),
                    title: Text(l10n.checkForUpdates, style: TextStyle(color: context.appTextColor, fontSize: 14, fontWeight: FontWeight.w500)),
                    onTap: () => _manualCheckUpdate(context),
                  ),
                ],
              ),
            ),

            Divider(color: context.appBorderColor, height: 1),

            // ─── Logout & Version ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                title: Text(l10n.logout, style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: const Text('v1.2.0', style: TextStyle(color: AppColors.textFaint, fontSize: 11)),
                onTap: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (mounted) context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Add Task Bottom Sheet ──────────────────────────────────────────────
class _AddTaskSheet extends ConsumerStatefulWidget {
  final VoidCallback onAddGroup;

  const _AddTaskSheet({required this.onAddGroup});

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _contentController = TextEditingController();
  String? _selectedGroupId;
  bool _isSaving = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save(String weekStartDate) async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    if (_selectedGroupId == null) return;

    setState(() => _isSaving = true);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      try {
        final item = WorkItemModel(
          id: '',
          taskGroupId: _selectedGroupId!,
          weekStartDate: weekStartDate,
          content: content,
          status: WorkItemStatus.TODO,
          note: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(plannerRepositoryProvider).addWorkItem(user.uid, item);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final taskGroupsAsync = ref.watch(taskGroupsProvider);
    final selectedWeek = ref.watch(selectedWeekProvider);
    final weekStartStr =
        '${selectedWeek.year}-${selectedWeek.month.toString().padLeft(2, '0')}-${selectedWeek.day.toString().padLeft(2, '0')}';

    return taskGroupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (groups) {
        if (groups.isEmpty) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có nhóm công việc',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn cần tạo ít nhất một nhóm công việc trước khi thêm công việc.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: widget.onAddGroup,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tạo nhóm mới',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }

        // Default to first group if none selected or if selected is not in list
        if (_selectedGroupId == null ||
            !groups.any((g) => g.id == _selectedGroupId)) {
          _selectedGroupId = groups.first.id;
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thêm công việc',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  TextButton.icon(
                    onPressed: widget.onAddGroup,
                    icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.accent),
                    label: const Text('Nhóm mới',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Group dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedGroupId,
                decoration: InputDecoration(
                  labelText: 'Nhóm công việc',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  fillColor: AppColors.bgAlt,
                  filled: true,
                ),
                items: groups.map((g) {
                  Color gColor;
                  try {
                    gColor = Color(int.parse(g.color.replaceAll('#', '0xff')));
                  } catch (_) {
                    gColor = AppColors.accent;
                  }
                  return DropdownMenuItem(
                    value: g.id,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: gColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Text(g.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGroupId = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung công việc...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: AppColors.bgAlt,
                  filled: true,
                ),
                onSubmitted: (_) => _isSaving ? null : _save(weekStartStr),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSaving ? null : () => _save(weekStartStr),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Thêm công việc',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Quick Add Group Bottom Sheet ─────────────────────────────────────────────
class _AddGroupSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddGroupSheet> createState() => _AddGroupSheetState();
}

class _AddGroupSheetState extends ConsumerState<_AddGroupSheet> {
  final _nameController = TextEditingController();
  int _selectedColorIndex = 0;
  bool _isSaving = false;

  static const _colors = AppColors.groupColors;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      final colorValue = _colors[_selectedColorIndex];
      final hexColor = '#${colorValue.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      try {
        final groups = await ref.read(taskGroupsProvider.future);
        final nextOrder = groups.isEmpty ? 1 : (groups.map((g) => g.displayOrder).reduce((a, b) => a > b ? a : b) + 1);
        await ref.read(taskGroupRepositoryProvider).createTaskGroup(
          user.uid,
          name,
          hexColor,
          nextOrder,
        );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Thêm nhóm mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Tên nhóm công việc...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              fillColor: AppColors.bgAlt,
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Màu nhóm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_colors.length, (i) {
              final isSelected = _selectedColorIndex == i;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedColorIndex = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: 12),
                  width: isSelected ? 36 : 30,
                  height: isSelected ? 36 : 30,
                  decoration: BoxDecoration(
                    color: _colors[i],
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: _colors[i].withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Tạo nhóm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
