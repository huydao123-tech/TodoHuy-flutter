import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/week_helper.dart';
import '../../task_groups/data/task_group_model.dart';
import '../data/planner_repository.dart';
import 'widgets/goal_card.dart';

class WeekGridMobile extends ConsumerStatefulWidget {
  const WeekGridMobile({super.key});

  @override
  ConsumerState<WeekGridMobile> createState() => _WeekGridMobileState();
}

class _WeekGridMobileState extends ConsumerState<WeekGridMobile> {
  late PageController _pageController;
  // We keep an offset to track which page we're on.
  // Page 1 = current week (center), 0 = prev week, 2 = next week.
  static const int _initialPage = 1;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = _initialPage;
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _weekForPage(DateTime baseWeek, int page) {
    final offset = page - _initialPage;
    return baseWeek.add(Duration(days: 7 * offset));
  }

  void _navigatePage(int delta) {
    final target = _currentPage + delta;
    if (target < 0) return;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseWeek = ref.watch(selectedWeekProvider);
    final taskGroupsAsync = ref.watch(taskGroupsProvider);
    final today = WeekHelper.getStartOfWeek(DateTime.now());

    return Column(
      children: [
        // ─── Week Navigator Bar ─────────────────────────────────────────
        _buildWeekNavBar(baseWeek, today),
        const Divider(height: 1, color: AppColors.border),

        // ─── PageView: 3 weeks ──────────────────────────────────────────
        Expanded(
          child: taskGroupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text('Lỗi: $err', style: const TextStyle(color: Colors.red)),
            ),
            data: (groups) {
              return PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  final offset = page - _initialPage;
                  // Update selectedWeek provider to match the displayed page
                  ref.read(selectedWeekProvider.notifier).state =
                      baseWeek.add(Duration(days: 7 * offset));
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, page) {
                  final weekForPage = _weekForPage(today, page);
                  final weekStr = _weekStartStr(weekForPage);
                  final isPast = weekForPage.isBefore(today);

                  return _buildWeekPage(groups, weekStr, isPast);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekNavBar(DateTime baseWeek, DateTime today) {
    final offset = _currentPage - _initialPage;
    final displayedWeek = today.add(Duration(days: 7 * offset));
    final weekStr = _weekRangeLabel(displayedWeek);
    final isCurrentWeek = displayedWeek == today;

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _navigatePage(-1),
            icon: const Icon(Icons.chevron_left, color: AppColors.textMuted),
            tooltip: 'Tuần trước',
          ),
          GestureDetector(
            onTap: isCurrentWeek ? null : _goToCurrentWeek,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCurrentWeek ? 'Tuần này' : 'Tuần khác',
                  style: TextStyle(
                    fontSize: 11,
                    color: isCurrentWeek ? AppColors.accent : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weekStr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (!isCurrentWeek) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _goToCurrentWeek,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Về hôm nay',
                            style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _navigatePage(1),
            icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            tooltip: 'Tuần sau',
          ),
        ],
      ),
    );
  }

  Widget _buildWeekPage(List<TaskGroupModel> groups, String weekStr, bool isPast) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 52, color: AppColors.textFaint.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            const Text(
              'Chưa có nhóm công việc nào.\nMở menu để thêm nhóm mới.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for FAB
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return GoalCard(
          key: ValueKey('${group.id}-$weekStr'),
          group: group,
          weekStartDate: weekStr,
          isPast: isPast,
        );
      },
    );
  }

  String _weekStartStr(DateTime weekStart) {
    return '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
  }

  String _weekRangeLabel(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(weekStart)} – ${fmt.format(end)}';
  }

  void _goToCurrentWeek() {
    // Jump back to page 1 (current week)
    _pageController.animateToPage(
      _initialPage,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }
}
