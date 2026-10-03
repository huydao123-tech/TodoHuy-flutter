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
                    return ListTile(
                      leading: Checkbox(
                        value: task.isDone,
                        onChanged: (val) {
                          if (user != null && val != null) {
                            ref.read(sideTasksRepositoryProvider).toggleSideTaskCompletion(user.uid, task.id, val);
                          }
                        },
                      ),
                      title: Text(
                        task.name,
                        style: TextStyle(
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                          color: task.isDone ? Colors.grey : null,
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
