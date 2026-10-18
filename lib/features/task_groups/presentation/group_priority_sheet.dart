import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../data/task_group_model.dart';
import '../data/task_group_repository.dart';

class GroupPrioritySheet extends ConsumerStatefulWidget {
  final List<TaskGroupModel> groups;

  const GroupPrioritySheet({super.key, required this.groups});

  @override
  ConsumerState<GroupPrioritySheet> createState() => _GroupPrioritySheetState();
}

class _GroupPrioritySheetState extends ConsumerState<GroupPrioritySheet> {
  late final List<TaskGroupModel> _groups = List.of(widget.groups);
  bool _saving = false;
  String? _error;

  void _reorder(int oldIndex, int newIndex) {
    if (_saving) return;
    setState(() {
      _groups.insert(newIndex, _groups.removeAt(oldIndex));
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      setState(() => _error = l10n.isVietnamese
          ? 'Vui lòng đăng nhập lại.'
          : 'Please sign in again.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(taskGroupRepositoryProvider).reorderTaskGroups(
            user.uid,
            _groups.map((group) => group.id).toList(),
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.isVietnamese
              ? 'Không lưu được thứ tự. Vui lòng thử lại.'
              : 'Could not save the order. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.isVietnamese ? 'Sắp xếp ưu tiên' : 'Group priority',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.isVietnamese
                  ? 'Kéo nhóm ưu tiên cao lên đầu. Thứ tự áp dụng cho tất cả các tuần.'
                  : 'Drag higher priority groups to the top. This order applies to all weeks.'),
              const SizedBox(height: 12),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: _groups.length,
                  onReorderItem: _reorder,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return ListTile(
                      key: ValueKey(group.id),
                      contentPadding: const EdgeInsets.only(left: 4),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.accent.withValues(alpha: 0.1),
                        child: Text('${index + 1}',
                            style: const TextStyle(color: AppColors.accent)),
                      ),
                      title: Text(group.name),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        enabled: !_saving,
                        child: Semantics(
                          label: l10n.isVietnamese
                              ? 'Kéo để sắp xếp ${group.name}'
                              : 'Drag to reorder ${group.name}',
                          child: const SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(Icons.drag_handle_rounded)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
