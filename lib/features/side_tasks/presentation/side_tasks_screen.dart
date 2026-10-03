import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../data/side_tasks_repository.dart';
import '../../../core/localization/app_localizations.dart';

class SideTasksScreen extends ConsumerStatefulWidget {
  const SideTasksScreen({super.key});

  @override
  ConsumerState<SideTasksScreen> createState() => _SideTasksScreenState();
}

class _SideTasksScreenState extends ConsumerState<SideTasksScreen> {
  final _controller = TextEditingController();

  void _addSideTask() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      await ref.read(sideTasksRepositoryProvider).addSideTask(user.uid, text);
      _controller.clear();
    }
  }

  final Set<String> _completingTaskIds = {};

  void _completeAndRemoveTask(String userId, String taskId, String taskName) {
    if (_completingTaskIds.contains(taskId)) return;

    setState(() {
      _completingTaskIds.add(taskId);
    });

    Future.delayed(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      await ref.read(sideTasksRepositoryProvider).deleteSideTask(userId, taskId);
      _completingTaskIds.remove(taskId);

      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.isVietnamese
                  ? 'Đã hoàn thành và xóa "$taskName"'
                  : 'Completed & deleted "$taskName"',
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: l10n.isVietnamese ? 'HOÀN TÁC' : 'UNDO',
              onPressed: () {
                ref.read(sideTasksRepositoryProvider).addSideTask(
                      userId,
                      taskName,
                      isDone: false,
                    );
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sideTasksAsync = ref.watch(sideTasksProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sideTasksScreenTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: l10n.sideTaskInputHint,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _addSideTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addSideTask,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: sideTasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(child: Text(l10n.noSideTasksEmpty));
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isDone = task.isDone || _completingTaskIds.contains(task.id);
                    return ListTile(
                      leading: Checkbox(
                        value: isDone,
                        onChanged: (val) {
                          if (user != null) {
                            _completeAndRemoveTask(user.uid, task.id, task.name);
                          }
                        },
                      ),
                      title: Text(
                        task.name,
                        style: TextStyle(
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                            onPressed: () async {
                              final controller = TextEditingController(text: task.name);
                              final newName = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n.editSideTask),
                                  content: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: const InputDecoration(hintText: 'Nội dung việc...'),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                                    TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(l10n.save)),
                                  ],
                                ),
                              );
                              if (newName != null && newName.isNotEmpty && newName != task.name && user != null) {
                                ref.read(sideTasksRepositoryProvider).updateSideTaskName(user.uid, task.id, newName);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () {
                              if (user != null) {
                                ref.read(sideTasksRepositoryProvider).deleteSideTask(user.uid, task.id);
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
      ),
    );
  }
}
