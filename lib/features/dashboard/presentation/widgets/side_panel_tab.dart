import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../side_tasks/data/side_tasks_repository.dart';

class SidePanelTab extends ConsumerStatefulWidget {
  const SidePanelTab({super.key});

  @override
  ConsumerState<SidePanelTab> createState() => _SidePanelTabState();
}

class _SidePanelTabState extends ConsumerState<SidePanelTab> {
  final _controller = TextEditingController();
  String _filter = 'All'; // 'All', 'Todo', 'Done'

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
    final sideTasksAsync = ref.watch(sideTasksProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              _buildFilterChip('All', 'Tất cả'),
              const SizedBox(width: 8),
              _buildFilterChip('Todo', 'Chưa xong'),
              const SizedBox(width: 8),
              _buildFilterChip('Done', 'Đã xong'),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        // Task List
        Expanded(
          child: sideTasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Lỗi: $err')),
            data: (tasks) {
              final filteredTasks = tasks.where((task) {
                if (_filter == 'Todo') return !task.isDone;
                if (_filter == 'Done') return task.isDone;
                return true;
              }).toList();

              if (filteredTasks.isEmpty) {
                return const Center(child: Text('Không có công việc nào.', style: TextStyle(color: AppColors.textMuted)));
              }

              return ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Dismissible(
                    key: Key(task.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: AppColors.groupColors[4], // Red
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      if (user != null) {
                        ref.read(sideTasksRepositoryProvider).deleteSideTask(user.uid, task.id);
                      }
                    },
                    child: ListTile(
                      leading: Checkbox(
                        value: task.isDone,
                        activeColor: AppColors.accent,
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
                          color: task.isDone ? AppColors.textMuted : AppColors.text,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        // Add Task Input
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Thêm việc lặt vặt...',
                    hintStyle: const TextStyle(color: AppColors.textFaint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    fillColor: AppColors.bgAlt,
                    filled: true,
                  ),
                  onSubmitted: (_) => _addSideTask(),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: AppColors.accent,
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _addSideTask,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterValue, String label) {
    final isSelected = _filter == filterValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = filterValue);
        }
      },
      selectedColor: AppColors.accent.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.accent : AppColors.textMuted,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.accent : AppColors.border,
      ),
      backgroundColor: Colors.white,
    );
  }
}
