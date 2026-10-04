import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/week_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../data/planner_repository.dart';
import '../data/work_item_model.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final WorkItemModel workItem;
  final Color groupColor;
  final String groupName;
  final String weekStartDate;
  final bool isPast;

  const TaskDetailSheet({
    super.key,
    required this.workItem,
    this.groupColor = AppColors.accent,
    this.groupName = '',
    this.weekStartDate = '',
    this.isPast = false,
  });

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  late TextEditingController _contentController;
  late TextEditingController _noteController;
  late WorkItemStatus _selectedStatus;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.workItem.content);
    _noteController = TextEditingController(text: widget.workItem.note);
    _selectedStatus = widget.workItem.status;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      try {
        await ref.read(plannerRepositoryProvider).updateWorkItem(
          user.uid,
          widget.workItem.id,
          {
            'content': _contentController.text.trim(),
            'note': _noteController.text.trim(),
            'status': _selectedStatus.name,
            'updatedAt': FieldValue.serverTimestamp(),
          },
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: Text('Bạn có chắc muốn xóa "${widget.workItem.content}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isDeleting = true);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      try {
        await ref.read(plannerRepositoryProvider).deleteWorkItem(user.uid, widget.workItem.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
    if (mounted) setState(() => _isDeleting = false);
  }

  Future<void> _moveToWeek(String targetWeek, String weekLabel) async {
    setState(() => _isMoving = true);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      final messenger = ScaffoldMessenger.of(context);
      final oldWeek = widget.workItem.weekStartDate;
      final taskContent = widget.workItem.content;
      try {
        await ref.read(plannerRepositoryProvider).moveWorkItemToWeek(
          user.uid,
          widget.workItem.id,
          targetWeek,
        );
        if (mounted) {
          Navigator.pop(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text('Đã dời "$taskContent" sang $weekLabel'),
              action: SnackBarAction(
                label: 'Hoàn tác',
                onPressed: () async {
                  await ref.read(plannerRepositoryProvider).moveWorkItemToWeek(
                    user.uid,
                    widget.workItem.id,
                    oldWeek,
                  );
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
    if (mounted) setState(() => _isMoving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentWeekStart = WeekHelper.getStartOfWeek(DateTime.now());
    final currentWeekStr = WeekHelper.toWeekStartStr(currentWeekStart);
    final nextWeekStr = WeekHelper.toWeekStartStr(currentWeekStart.add(const Duration(days: 7)));
    final isPast = widget.isPast ||
        (widget.weekStartDate.isNotEmpty && widget.weekStartDate.compareTo(currentWeekStr) < 0);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: group label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.groupColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.groupColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: widget.groupColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.groupName,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.groupColor),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 8),

                    if (isPast)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: context.subtleBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.appBorderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 18, color: AppColors.textMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.pastWeekTaskNotice,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ─── Task Content ──────────────────────────────────
                    TextField(
                      controller: _contentController,
                      enabled: !isPast,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.appTextColor),
                      decoration: const InputDecoration(
                        hintText: 'Tên công việc...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                    ),

                    const SizedBox(height: 20),

                    // ─── Status Selector ───────────────────────────────
                    const Text('Trạng thái', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    _buildStatusSelector(isPast),

                    const SizedBox(height: 20),

                    // ─── Note ──────────────────────────────────────────
                    const Text('Ghi chú', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: context.subtleBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.appBorderColor),
                      ),
                      child: TextField(
                        controller: _noteController,
                        enabled: !isPast,
                        maxLines: 6,
                        minLines: 3,
                        style: TextStyle(fontSize: 14, color: context.appTextColor, height: 1.5),
                        decoration: const InputDecoration(
                          hintText: 'Ghi chú thêm...',
                          hintStyle: TextStyle(color: AppColors.textFaint),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ─── Action Buttons ────────────────────────────────
                    if (isPast) ...[
                      Row(
                        children: [
                          // Delete button
                          OutlinedButton.icon(
                            onPressed: (_isDeleting || _isMoving) ? null : _delete,
                            icon: _isDeleting
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.delete_outline, size: 18),
                            label: Text(context.l10n.delete),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            tooltip: 'Tùy chọn khác',
                            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
                            onSelected: (targetWeek) => _moveToWeek(
                              targetWeek,
                              targetWeek == currentWeekStr ? 'tuần này' : 'tuần sau',
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: nextWeekStr,
                                child: Row(
                                  children: [
                                    const Icon(Icons.next_plan_outlined, size: 18, color: AppColors.accent),
                                    const SizedBox(width: 8),
                                    Text(context.l10n.moveToNextWeek),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            onPressed: (_isDeleting || _isMoving) ? null : () => _moveToWeek(currentWeekStr, 'tuần này'),
                            icon: _isMoving
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.redo_rounded, size: 18),
                            label: Text(context.l10n.moveToCurrentWeek),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      Row(
                        children: [
                          // Delete button
                          OutlinedButton.icon(
                            onPressed: (_isDeleting || _isMoving || _isSaving) ? null : _delete,
                            icon: _isDeleting
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.delete_outline, size: 18),
                            label: Text(context.l10n.delete),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Move to next week quick option
                          PopupMenuButton<String>(
                            tooltip: context.l10n.moveToNextWeek,
                            icon: const Icon(Icons.schedule_send_outlined, color: AppColors.textMuted, size: 20),
                            onSelected: (targetWeek) => _moveToWeek(targetWeek, 'tuần sau'),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: nextWeekStr,
                                child: Row(
                                  children: [
                                    const Icon(Icons.next_plan_outlined, size: 18, color: AppColors.accent),
                                    const SizedBox(width: 8),
                                    Text(context.l10n.moveToNextWeek),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Save button
                          FilledButton.icon(
                            onPressed: (_isSaving || _isMoving || _isDeleting) ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_outlined, size: 18),
                            label: Text(context.l10n.save),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusSelector(bool isPast) {
    return Row(
      children: WorkItemStatus.values.map((status) {
        final isSelected = _selectedStatus == status;
        final (label, color) = switch (status) {
          WorkItemStatus.TODO => ('Cần làm', AppColors.textSecondary),
          WorkItemStatus.IN_PROGRESS => ('Đang làm', AppColors.groupColors[2]),
          WorkItemStatus.DONE => ('Đã xong', AppColors.accent),
        };

        Widget statusIndicator;
        switch (status) {
          case WorkItemStatus.TODO:
            statusIndicator = Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFCBD5E1),
                  width: 1.8,
                ),
              ),
            );
            break;
          case WorkItemStatus.IN_PROGRESS:
            statusIndicator = Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.8),
                color: const Color(0xFFFEF3C7),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF59E0B),
                ),
              ),
            );
            break;
          case WorkItemStatus.DONE:
            statusIndicator = Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accent : const Color(0xFFE2E8F0),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.check_rounded,
                color: isSelected ? Colors.white : AppColors.textMuted,
                size: 13,
              ),
            );
            break;
        }

        return Expanded(
          child: GestureDetector(
            onTap: isPast ? null : () {
              HapticFeedback.selectionClick();
              setState(() => _selectedStatus = status);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.1) : context.subtleBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : context.appBorderColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  statusIndicator,
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? color : AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
