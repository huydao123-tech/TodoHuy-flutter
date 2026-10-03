import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../side_tasks/data/side_tasks_repository.dart';
import '../../../side_tasks/data/side_task_model.dart';

class SidePanelTab extends ConsumerStatefulWidget {
  const SidePanelTab({super.key});

  @override
  ConsumerState<SidePanelTab> createState() => _SidePanelTabState();
}

class _SidePanelTabState extends ConsumerState<SidePanelTab> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final Set<String> _completingTaskIds = {};

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addSideTask() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      HapticFeedback.lightImpact();
      await ref.read(sideTasksRepositoryProvider).addSideTask(user.uid, text);
      _controller.clear();
    }
  }

  void _completeAndRemoveTask(String userId, SideTaskModel task) {
    if (_completingTaskIds.contains(task.id)) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _completingTaskIds.add(task.id);
    });

    // Provide a brief, satisfying visual feedback (350ms) before deletion
    Future.delayed(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      await ref.read(sideTasksRepositoryProvider).deleteSideTask(userId, task.id);
      _completingTaskIds.remove(task.id);

      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.isVietnamese
                  ? 'Đã hoàn thành và xóa "${task.name}"'
                  : 'Completed & deleted "${task.name}"',
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: l10n.isVietnamese ? 'HOÀN TÁC' : 'UNDO',
              textColor: AppColors.accent,
              onPressed: () {
                ref.read(sideTasksRepositoryProvider).addSideTask(
                      userId,
                      task.name,
                      isDone: false,
                    );
              },
            ),
          ),
        );
      }
    });
  }

  void _editTask(String userId, SideTaskModel task) async {
    final l10n = context.l10n;
    final editController = TextEditingController(text: task.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editSideTask),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.isVietnamese ? 'Nội dung việc...' : 'Task content...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, editController.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != task.name) {
      await ref.read(sideTasksRepositoryProvider).updateSideTaskName(userId, task.id, newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sideTasksAsync = ref.watch(sideTasksProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Column(
      children: [
        const SizedBox(height: 8),

        // ─── Task List ────────────────────────────────────────────────
        Expanded(
          child: sideTasksAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent),
            ),
            error: (err, stack) => Center(child: Text('Lỗi: $err', style: const TextStyle(color: Colors.red))),
            data: (tasks) {
              // Only display active tasks (not yet completed/deleted)
              final activeTasks = tasks.where((task) => !task.isDone || _completingTaskIds.contains(task.id)).toList();

              if (activeTasks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.task_alt_rounded, size: 32, color: AppColors.accent),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.isVietnamese
                              ? 'Tuyệt vời! Không còn việc phụ nào.'
                              : 'All caught up! No side tasks.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.isVietnamese
                              ? 'Nhập việc cần làm vào ô bên dưới để ghi nhanh.'
                              : 'Enter a task in the field below for quick capture.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: activeTasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = activeTasks[index];
                  final isCompleting = _completingTaskIds.contains(task.id) || task.isDone;

                  return Dismissible(
                    key: Key(task.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            l10n.isVietnamese ? 'Xóa' : 'Delete',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (_) {
                      if (user != null) {
                        HapticFeedback.mediumImpact();
                        ref.read(sideTasksRepositoryProvider).deleteSideTask(user.uid, task.id);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.isVietnamese
                                  ? 'Đã xóa "${task.name}"'
                                  : 'Deleted "${task.name}"',
                            ),
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: l10n.isVietnamese ? 'HOÀN TÁC' : 'UNDO',
                              textColor: AppColors.accent,
                              onPressed: () {
                                ref.read(sideTasksRepositoryProvider).addSideTask(
                                      user.uid,
                                      task.name,
                                      isDone: false,
                                    );
                              },
                            ),
                          ),
                        );
                      }
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: isCompleting ? 0.4 : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCompleting ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border,
                            width: 0.8,
                          ),
                          boxShadow: const [AppColors.softShadow],
                        ),
                        child: InkWell(
                          onTap: () {
                            if (user != null) {
                              _completeAndRemoveTask(user.uid, task);
                            }
                          },
                          onLongPress: () {
                            if (user != null) {
                              _editTask(user.uid, task);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isCompleting,
                                  activeColor: AppColors.accent,
                                  shape: const CircleBorder(),
                                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.8),
                                  onChanged: (_) {
                                    if (user != null) {
                                      _completeAndRemoveTask(user.uid, task);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: isCompleting ? FontWeight.normal : FontWeight.w500,
                                      decoration: isCompleting ? TextDecoration.lineThrough : null,
                                      decorationColor: AppColors.textMuted,
                                      color: isCompleting ? AppColors.textMuted : AppColors.text,
                                      height: 1.3,
                                    ),
                                    child: Text(task.name),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textFaint),
                                  splashRadius: 18,
                                  onPressed: () {
                                    if (user != null) {
                                      _editTask(user.uid, task);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // ─── Linear Style Bottom Quick Capture Dock ───────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0
                ? MediaQuery.of(context).viewInsets.bottom + 10
                : 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(fontSize: 14, color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: l10n.sideTaskInputHint,
                      hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13.5),
                      prefixIcon: const Icon(Icons.add_task_rounded, color: AppColors.textFaint, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _addSideTask(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _addSideTask,
                  tooltip: l10n.isVietnamese ? 'Thêm' : 'Add',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

