import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../task_groups/data/task_group_model.dart';
import '../../../task_groups/data/task_group_repository.dart';
import '../../data/planner_repository.dart';
import '../../data/work_item_model.dart';
import '../task_detail_sheet.dart';

class GoalCard extends ConsumerStatefulWidget {
  final TaskGroupModel group;
  final String weekStartDate;
  final bool isPast; // disable add/edit for past weeks

  const GoalCard({
    super.key,
    required this.group,
    required this.weekStartDate,
    this.isPast = false,
  });

  @override
  ConsumerState<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<GoalCard> {
  final _addController = TextEditingController();
  bool _isAddingTask = false;

  Color get _groupColor {
    try {
      return Color(int.parse(widget.group.color.replaceAll('#', '0xff')));
    } catch (_) {
      return AppColors.accent;
    }
  }

  // Cycle: TODO → IN_PROGRESS → DONE → TODO
  WorkItemStatus _nextStatus(WorkItemStatus current) {
    switch (current) {
      case WorkItemStatus.TODO:
        return WorkItemStatus.IN_PROGRESS;
      case WorkItemStatus.IN_PROGRESS:
        return WorkItemStatus.DONE;
      case WorkItemStatus.DONE:
        return WorkItemStatus.TODO;
    }
  }

  Widget _statusIcon(WorkItemStatus status) {
    switch (status) {
      case WorkItemStatus.TODO:
        return const Icon(Icons.radio_button_unchecked, color: AppColors.textFaint, size: 22);
      case WorkItemStatus.IN_PROGRESS:
        return Icon(Icons.hourglass_top_rounded, color: AppColors.groupColors[2], size: 22);
      case WorkItemStatus.DONE:
        return const Icon(Icons.check_circle, color: AppColors.accent, size: 22);
    }
  }

  Future<void> _cycleStatus(String userId, WorkItemModel item) async {
    final next = _nextStatus(item.status);
    await ref.read(plannerRepositoryProvider).updateWorkItemStatus(userId, item.id, next);
  }

  Future<void> _addTask(String userId) async {
    final content = _addController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isAddingTask = true);
    final newItem = WorkItemModel(
      id: '',
      taskGroupId: widget.group.id,
      weekStartDate: widget.weekStartDate,
      content: content,
      status: WorkItemStatus.TODO,
      note: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      await ref.read(plannerRepositoryProvider).addWorkItem(userId, newItem);
      _addController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
    if (mounted) setState(() => _isAddingTask = false);
  }

  Future<void> _deleteTaskGroup(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa nhóm công việc?'),
        content: const Text('Nhóm này sẽ được chuyển vào thùng rác và có thể khôi phục sau.'),
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
        await ref.read(taskGroupRepositoryProvider).archiveTaskGroup(user.uid, widget.group.id);
      }
    }
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    // Shared work items stream for this week
    final itemsAsync = ref.watch(workItemsForWeekProvider(widget.weekStartDate));

    return Opacity(
      opacity: widget.isPast ? 0.65 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: _groupColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Card Header ───────────────────────────────────────────
            _buildHeader(),

            const Divider(height: 1, color: AppColors.border),

            // ─── Work Items List ────────────────────────────────────────
            itemsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Lỗi: $err', style: const TextStyle(color: Colors.red)),
              ),
              data: (allItems) {
                final items = allItems.where((i) => i.taskGroupId == widget.group.id).toList();
                return _buildItemsList(user.uid, items);
              },
            ),

            // ─── Add task input (disabled for past weeks) ───────────────
            if (!widget.isPast) _buildAddTaskRow(user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _groupColor.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _groupColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.group.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: _groupColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (widget.isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('Tuần cũ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            )
          else
            IconButton(
              icon: Icon(Icons.delete_outline, color: _groupColor.withValues(alpha: 0.7), size: 20),
              tooltip: 'Xóa nhóm',
              visualDensity: VisualDensity.compact,
              onPressed: () => _deleteTaskGroup(context),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsList(String userId, List<WorkItemModel> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          widget.isPast ? 'Không có công việc nào.' : 'Chưa có công việc nào. Thêm công việc bên dưới...',
          style: const TextStyle(color: AppColors.textFaint, fontSize: 13, fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 48, color: AppColors.border),
      itemBuilder: (context, idx) {
        final item = items[idx];
        final isDone = item.status == WorkItemStatus.DONE;
        return InkWell(
          onTap: () => _openDetailSheet(context, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Status cycle button
                GestureDetector(
                  onTap: widget.isPast ? null : () => _cycleStatus(userId, item),
                  child: _statusIcon(item.status),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDone ? AppColors.textMuted : AppColors.text,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                ),
                // Trailing: note indicator or chevron
                if (item.note.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.notes, size: 16, color: AppColors.textFaint),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTaskRow(String userId) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.add, size: 20, color: AppColors.textFaint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _addController,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              decoration: const InputDecoration(
                hintText: 'Thêm công việc...',
                hintStyle: TextStyle(color: AppColors.textFaint, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _isAddingTask ? null : _addTask(userId),
            ),
          ),
          if (_isAddingTask)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else
            GestureDetector(
              onTap: () => _addTask(userId),
              child: const Icon(Icons.send_rounded, size: 18, color: AppColors.accent),
            ),
        ],
      ),
    );
  }

  void _openDetailSheet(BuildContext context, WorkItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDetailSheet(
        workItem: item,
        groupColor: _groupColor,
        groupName: widget.group.name,
        weekStartDate: widget.weekStartDate,
        isPast: widget.isPast,
      ),
    );
  }
}
