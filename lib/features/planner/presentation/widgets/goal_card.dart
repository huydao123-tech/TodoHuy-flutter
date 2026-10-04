import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/week_helper.dart';
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
  final _addFocusNode = FocusNode();
  final _addFieldKey = GlobalKey();
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
    HapticFeedback.lightImpact();
    final next = _nextStatus(item.status);
    await ref.read(plannerRepositoryProvider).updateWorkItemStatus(userId, item.id, next);
  }

  // DONE → TODO requires a long-press to avoid accidental un-completion.
  void _onStatusTap(String userId, WorkItemModel item) {
    if (item.status == WorkItemStatus.DONE) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhấn giữ để đặt lại trạng thái'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _cycleStatus(userId, item);
  }

  void _onStatusLongPress(String userId, WorkItemModel item) {
    if (item.status == WorkItemStatus.DONE) {
      _cycleStatus(userId, item);
    }
  }

  Future<void> _quickMoveToCurrentWeek(String userId, WorkItemModel item) async {
    HapticFeedback.lightImpact();
    final currentWeekStr = WeekHelper.toWeekStartStr(DateTime.now());
    final oldWeek = item.weekStartDate;
    try {
      await ref.read(plannerRepositoryProvider).moveWorkItemToWeek(
        userId,
        item.id,
        currentWeekStr,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã dời "${item.content}" sang tuần này'),
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () async {
                await ref.read(plannerRepositoryProvider).moveWorkItemToWeek(
                  userId,
                  item.id,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _focusAddField() {
    _addFocusNode.requestFocus();
    final ctx = _addFieldKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
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
      _addFocusNode.unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingTask = false);
    }
  }

  Future<void> _deleteTaskGroup(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa nhóm công việc?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text('Nhóm "${widget.group.name}" sẽ được chuyển vào thùng rác.'),
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

    if (confirm == true && mounted) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        await ref.read(taskGroupRepositoryProvider).archiveTaskGroup(user.uid, widget.group.id);
      }
    }
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    // Shared work items stream for this week
    final itemsAsync = ref.watch(workItemsForWeekProvider(widget.weekStartDate));
    final allItems = itemsAsync.valueOrNull ?? const <WorkItemModel>[];
    final groupItems = allItems.where((i) => i.taskGroupId == widget.group.id).toList();
    final incompleteCount = groupItems.where((i) => i.status != WorkItemStatus.DONE).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorderColor, width: 0.8),
        boxShadow: const [AppColors.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Card Header ───────────────────────────────────────────
          _buildHeader(incompleteCount, groupItems.length),

          Divider(height: 1, color: context.appBorderColor),

          // ─── Work Items List ────────────────────────────────────────
          itemsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Lỗi: $err', style: const TextStyle(color: Colors.red)),
            ),
            data: (items) {
              final currentGroupItems = items.where((i) => i.taskGroupId == widget.group.id).toList();
              return _buildItemsList(user.uid, currentGroupItems);
            },
          ),

          // ─── Add task input (disabled for past weeks) ───────────────
          if (!widget.isPast) _buildAddTaskRow(user.uid),
        ],
      ),
    );
  }

  Widget _buildHeader(int incompleteCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _groupColor.withValues(alpha: widget.isPast ? 0.04 : 0.06),
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
              boxShadow: [
                BoxShadow(
                  color: _groupColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
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
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (widget.isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.subtleBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appBorderColor),
              ),
              child: Text('Tuần cũ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.appTextMutedColor)),
            )
          else ...[
            if (totalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.subtleBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appBorderColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  incompleteCount == 0 ? '✓ Xong' : '$incompleteCount còn lại',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: incompleteCount == 0 ? AppColors.accent : _groupColor,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 20, color: AppColors.accent),
              tooltip: 'Thêm công việc',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: context.subtleBgColor,
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(30, 30),
              ),
              onPressed: _focusAddField,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: _groupColor.withValues(alpha: 0.7), size: 20),
              tooltip: 'Xóa nhóm',
              visualDensity: VisualDensity.compact,
              onPressed: () => _deleteTaskGroup(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList(String userId, List<WorkItemModel> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 48, color: AppColors.borderSubtle),
      itemBuilder: (context, idx) {
        final item = items[idx];
        final isDone = item.status == WorkItemStatus.DONE;
        return InkWell(
          onTap: () => _openDetailSheet(context, item),
          splashColor: AppColors.accent.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Status cycle button
                GestureDetector(
                  onTap: widget.isPast ? null : () => _onStatusTap(userId, item),
                  onLongPress: widget.isPast ? null : () => _onStatusLongPress(userId, item),
                  child: _statusIcon(item.status),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
                      color: isDone ? context.appTextMutedColor : context.appTextColor,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: context.appTextMutedColor,
                      height: 1.3,
                    ),
                  ),
                ),
                // Trailing: note indicator or quick move button or chevron
                if (item.note.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.sticky_note_2_outlined, size: 15, color: AppColors.textFaint),
                  ),
                if (widget.isPast && !isDone)
                  IconButton(
                    icon: const Icon(Icons.redo_rounded, size: 18, color: AppColors.accent),
                    tooltip: context.l10n.moveToCurrentWeek,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(28, 28),
                    ),
                    onPressed: () => _quickMoveToCurrentWeek(userId, item),
                  )
                else ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textFaint),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTaskRow(String userId) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.appBorderColor, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.add_rounded, size: 20, color: AppColors.textFaint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: _addFieldKey,
              controller: _addController,
              focusNode: _addFocusNode,
              style: TextStyle(fontSize: 14, color: context.appTextColor),
              decoration: const InputDecoration(
                hintText: 'Thêm công việc...',
                hintStyle: TextStyle(color: AppColors.textFaint, fontSize: 13.5),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _isAddingTask ? null : _addTask(userId),
            ),
          ),
          if (_isAddingTask)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
          else
            IconButton(
              icon: const Icon(Icons.arrow_upward_rounded, size: 18, color: AppColors.accent),
              tooltip: 'Thêm',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(28, 28),
              ),
              onPressed: () => _addTask(userId),
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
