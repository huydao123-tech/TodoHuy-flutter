import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: AppColors.border,
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

                    // ─── Task Content ──────────────────────────────────
                    TextField(
                      controller: _contentController,
                      enabled: !widget.isPast,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
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
                    _buildStatusSelector(),

                    const SizedBox(height: 20),

                    // ─── Note ──────────────────────────────────────────
                    const Text('Ghi chú', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _noteController,
                        enabled: !widget.isPast,
                        maxLines: 6,
                        minLines: 3,
                        style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.5),
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
                    if (!widget.isPast) ...[
                      Row(
                        children: [
                          // Delete button
                          OutlinedButton.icon(
                            onPressed: _isDeleting ? null : _delete,
                            icon: _isDeleting
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Xóa'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                          const Spacer(),
                          // Save button
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_outlined, size: 18),
                            label: const Text('Lưu'),
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

  Widget _buildStatusSelector() {
    return Row(
      children: WorkItemStatus.values.map((status) {
        final isSelected = _selectedStatus == status;
        final (label, icon, color) = switch (status) {
          WorkItemStatus.TODO => ('Cần làm', Icons.radio_button_unchecked, AppColors.textMuted),
          WorkItemStatus.IN_PROGRESS => ('Đang làm', Icons.hourglass_top_rounded, AppColors.groupColors[2]),
          WorkItemStatus.DONE => ('Đã xong', Icons.check_circle, AppColors.accent),
        };
        return Expanded(
          child: GestureDetector(
            onTap: widget.isPast ? null : () => setState(() => _selectedStatus = status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.12) : AppColors.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: isSelected ? color : AppColors.textFaint),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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
