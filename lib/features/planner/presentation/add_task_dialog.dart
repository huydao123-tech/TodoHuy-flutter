import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../data/planner_repository.dart';
import '../data/work_item_model.dart';
import '../../../core/utils/week_helper.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  final String taskGroupId;
  final DateTime selectedWeek;

  const AddTaskDialog({
    super.key,
    required this.taskGroupId,
    required this.selectedWeek,
  });

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      final weekStartDate = WeekHelper.getStartOfWeek(widget.selectedWeek);
      // Ensure date only (YYYY-MM-DD format logically)
      final formattedWeek = "${weekStartDate.year}-${weekStartDate.month.toString().padLeft(2, '0')}-${weekStartDate.day.toString().padLeft(2, '0')}";

      final newItem = WorkItemModel(
        id: '', // Will be assigned by Firestore
        taskGroupId: widget.taskGroupId,
        weekStartDate: formattedWeek,
        content: content,
        status: WorkItemStatus.TODO,
        note: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await ref.read(plannerRepositoryProvider).addWorkItem(user.uid, newItem);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm công việc'),
      content: TextField(
        controller: _contentController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Nhập tên công việc...',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : const Text('Thêm'),
        ),
      ],
    );
  }
}
