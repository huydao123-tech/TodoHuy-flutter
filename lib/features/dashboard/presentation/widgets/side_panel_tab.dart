import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../side_tasks/data/side_tasks_repository.dart';

class SidePanelTab extends ConsumerStatefulWidget {
  const SidePanelTab({super.key});

  @override
  ConsumerState<SidePanelTab> createState() => _SidePanelTabState();
}

class _SidePanelTabState extends ConsumerState<SidePanelTab> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _filter = 'All'; // 'All', 'Todo', 'Done'

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sideTasksAsync = ref.watch(sideTasksProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Column(
      children: [
        // ─── Things 3 / Linear Segmented Filter ───────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.bgAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                _buildSegmentItem('All', l10n.filterAll),
                _buildSegmentItem('Todo', l10n.filterTodo),
                _buildSegmentItem('Done', l10n.filterDone),
              ],
            ),
          ),
        ),

        // ─── Task List ────────────────────────────────────────────────
        Expanded(
          child: sideTasksAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent),
            ),
            error: (err, stack) => Center(child: Text('Lỗi: $err', style: const TextStyle(color: Colors.red))),
            data: (tasks) {
              final filteredTasks = tasks.where((task) {
                if (_filter == 'Todo') return !task.isDone;
                if (_filter == 'Done') return task.isDone;
                return true;
              }).toList();

              if (filteredTasks.isEmpty) {
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
                          _filter == 'Done'
                              ? 'Chưa có công việc nào hoàn thành.'
                              : (_filter == 'Todo'
                                  ? 'Tuyệt vời! Không còn việc tồn đọng.'
                                  : 'Không có công việc nào.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Nhập việc cần làm vào ô bên dưới để ghi nhanh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: filteredTasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    onDismissed: (_) {
                      if (user != null) {
                        HapticFeedback.mediumImpact();
                        ref.read(sideTasksRepositoryProvider).deleteSideTask(user.uid, task.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã xóa "${task.name}"'),
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'HOÀN TÁC',
                              textColor: AppColors.accent,
                              onPressed: () {
                                ref.read(sideTasksRepositoryProvider).addSideTask(
                                      user.uid,
                                      task.name,
                                      isDone: task.isDone,
                                    );
                              },
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 0.8),
                        boxShadow: const [AppColors.softShadow],
                      ),
                      child: InkWell(
                        onTap: () {
                          if (user != null) {
                            HapticFeedback.lightImpact();
                            ref.read(sideTasksRepositoryProvider).toggleSideTaskCompletion(
                                  user.uid,
                                  task.id,
                                  !task.isDone,
                                );
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Checkbox(
                                value: task.isDone,
                                activeColor: AppColors.accent,
                                shape: const CircleBorder(),
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.8),
                                onChanged: (val) {
                                  if (user != null && val != null) {
                                    HapticFeedback.lightImpact();
                                    ref.read(sideTasksRepositoryProvider).toggleSideTaskCompletion(
                                          user.uid,
                                          task.id,
                                          val,
                                        );
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: task.isDone ? FontWeight.normal : FontWeight.w500,
                                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                                    decorationColor: AppColors.textMuted,
                                    color: task.isDone ? AppColors.textMuted : AppColors.text,
                                    height: 1.3,
                                  ),
                                  child: Text(task.name),
                                ),
                              ),
                            ],
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
                      hintStyle: TextStyle(color: AppColors.textFaint, fontSize: 13.5),
                      prefixIcon: Icon(Icons.add_task_rounded, color: AppColors.textFaint, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  tooltip: 'Thêm',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentItem(String filterValue, String label) {
    final isSelected = _filter == filterValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            setState(() => _filter = filterValue);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.accent : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
