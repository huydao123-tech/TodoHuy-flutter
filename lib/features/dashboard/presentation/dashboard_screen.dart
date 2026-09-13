import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Đang kiểm tra bản cập nhật...'),
          ],
        ),
        duration: Duration(seconds: 2),
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
            'Ứng dụng đang ở phiên bản mới nhất (${info.currentVersion.split("+").first})',
          ),
          backgroundColor: Colors.green[700],
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
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week_outlined),
            activeIcon: Icon(Icons.calendar_view_week),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Việc phụ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sticky_note_2_outlined),
            activeIcon: Icon(Icons.sticky_note_2),
            label: 'Ghi chú',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 0:
        return AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              color: AppColors.text,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text(
            'WeekLoop',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 20),
          ),
          backgroundColor: AppColors.bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        );
      case 1:
        return AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              color: AppColors.text,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text(
            'Đầu việc phụ',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          backgroundColor: AppColors.bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        );
      case 2:
      default:
        return AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              color: AppColors.text,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text(
            'Ghi chú',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          backgroundColor: AppColors.bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        );
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const PlannerScreen();
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
          onPressed: () => _showAddTaskSheet(),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        );
      case 1:
        return null;
      case 2:
      default:
        return FloatingActionButton(
          heroTag: 'notes-fab',
          onPressed: () => _openNoteEditor(context),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.edit_note),
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
        title: const Text('Sửa tên nhóm công việc'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên nhóm mới...',
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
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
        title: const Text('Xóa nhóm công việc?'),
        content: Text('Nhóm "${group.name}" sẽ được chuyển vào thùng rác và có thể khôi phục sau.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
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
    final user = ref.watch(authRepositoryProvider).currentUser;
    final taskGroupsAsync = ref.watch(taskGroupsProvider);

    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── User Header ─────────────────────────────────────────
            Container(
              color: AppColors.accent,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0].toUpperCase()
                          : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'U')),
                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Task Groups ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  const Text(
                    'NHÓM CÔNG VIỆC',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showAddGroupSheet,
                    child: const Icon(Icons.add, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            taskGroupsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (groups) {
                if (groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GestureDetector(
                      onTap: _showAddGroupSheet,
                      child: const Text(
                        '+ Thêm nhóm mới',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
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
                      contentPadding: const EdgeInsets.only(left: 16, right: 8),
                      leading: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: groupColor, shape: BoxShape.circle),
                      ),
                      title: Text(g.name, style: const TextStyle(fontSize: 14, color: AppColors.text)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Sửa tên',
                            onPressed: () => _editTaskGroup(context, g),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Xóa nhóm',
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

            const Divider(color: AppColors.border),

            // ─── Resources & Trash ────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.textMuted, size: 22),
              title: const Text('Tài liệu & Link', style: TextStyle(color: AppColors.text, fontSize: 14)),
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
              leading: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 22),
              title: const Text('Thùng rác', style: TextStyle(color: AppColors.text, fontSize: 14)),
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
              leading: const Icon(Icons.system_update_alt_rounded, color: AppColors.textMuted, size: 22),
              title: const Text('Kiểm tra bản cập nhật', style: TextStyle(color: AppColors.text, fontSize: 14)),
              onTap: () => _manualCheckUpdate(context),
            ),

            const Spacer(),
            const Divider(color: AppColors.border),

            // ─── Logout ───────────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.textMuted, size: 22),
              title: const Text('Đăng xuất', style: TextStyle(color: AppColors.text, fontSize: 14)),
              onTap: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (mounted) context.go('/login');
              },
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
                    icon: const Icon(Icons.add, size: 16, color: AppColors.accent),
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
                onTap: () => setState(() => _selectedColorIndex = i),
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
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
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
