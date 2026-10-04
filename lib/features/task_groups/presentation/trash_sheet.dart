import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../task_groups/data/task_group_repository.dart';

String _daysAgoLabel(DateTime? archivedAt) {
  if (archivedAt == null) return 'Vừa xóa';
  final days = DateTime.now().difference(archivedAt).inDays;
  if (days <= 0) return 'Đã xóa hôm nay';
  return 'Đã xóa $days ngày trước';
}

class TrashSheet extends ConsumerWidget {
  const TrashSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final archivedStream = user != null
        ? ref.watch(taskGroupRepositoryProvider).watchArchivedTaskGroups(user.uid)
        : const Stream.empty();

    return Container(
      decoration: BoxDecoration(
        color: context.scaffoldBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                            color: context.appBorderColor, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.delete_outline, color: context.appTextMutedColor),
                        const SizedBox(width: 10),
                        Text('Thùng rác',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.appTextColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Các nhóm đã xóa. Khôi phục hoặc xóa vĩnh viễn.',
                      style: TextStyle(fontSize: 12, color: context.appTextMutedColor),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Các nhóm trong thùng rác sẽ bị xóa vĩnh viễn sau 30 ngày.',
                              style: TextStyle(fontSize: 12, color: context.appTextMutedColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.appBorderColor),

              Expanded(
                child: StreamBuilder(
                  stream: archivedStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groups = snapshot.data ?? [];
                    if (groups.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_sweep_outlined,
                                size: 52, color: context.appTextFaintColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text('Thùng rác trống',
                                style: TextStyle(color: context.appTextMutedColor, fontSize: 15)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: context.appBorderColor),
                      itemBuilder: (context, i) {
                        final group = groups[i];
                        Color groupColor;
                        try {
                          groupColor = Color(int.parse(group.color.replaceAll('#', '0xff')));
                        } catch (_) {
                          groupColor = AppColors.accent;
                        }
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: groupColor, shape: BoxShape.circle),
                          ),
                          title: Text(
                            group.name,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600, color: context.appTextColor),
                          ),
                          subtitle: Text(
                            _daysAgoLabel(group.archivedAt),
                            style: TextStyle(fontSize: 12, color: context.appTextMutedColor),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Restore (primary action)
                              FilledButton(
                                onPressed: () async {
                                  if (user != null) {
                                    await ref
                                        .read(taskGroupRepositoryProvider)
                                        .restoreTaskGroup(user.uid, group.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã khôi phục "${group.name}"')));
                                    }
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Khôi phục'),
                              ),
                              const SizedBox(width: 4),
                              // Permanent delete
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                                tooltip: 'Xóa vĩnh viễn',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Xóa vĩnh viễn?'),
                                      content: Text(
                                          'Tất cả công việc trong "${group.name}" sẽ bị mất. Không thể hoàn tác.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Hủy')),
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Xóa hẳn',
                                                style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && user != null) {
                                    await ref
                                        .read(taskGroupRepositoryProvider)
                                        .permanentDeleteTaskGroup(user.uid, group.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
