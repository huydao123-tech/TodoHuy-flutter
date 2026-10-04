import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/week_helper.dart';
import '../../task_groups/data/task_group_model.dart';
import '../data/planner_repository.dart';
import 'widgets/goal_card.dart';
import '../../../core/localization/app_localizations.dart';

class WeekGridMobile extends ConsumerStatefulWidget {
  final VoidCallback? onAddGroup;

  const WeekGridMobile({super.key, this.onAddGroup});

  @override
  ConsumerState<WeekGridMobile> createState() => _WeekGridMobileState();
}

class _WeekGridMobileState extends ConsumerState<WeekGridMobile> {
  late PageController _pageController;
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
    HapticFeedback.lightImpact();
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
        // ─── Things 3 / Linear Week Navigator Bar ─────────────────────
        _buildWeekNavBar(baseWeek, today),

        // ─── PageView: 3 weeks ──────────────────────────────────────────
        Expanded(
          child: taskGroupsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5),
            ),
            error: (err, _) => Center(
              child: Text('Lỗi: $err', style: const TextStyle(color: Colors.red)),
            ),
            data: (groups) {
              return PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  final offset = page - _initialPage;
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
    final l10n = context.l10n;
    final offset = _currentPage - _initialPage;
    final displayedWeek = today.add(Duration(days: 7 * offset));
    final weekStr = _weekRangeLabel(displayedWeek);
    final isCurrentWeek = displayedWeek == today;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorderColor, width: 0.8),
        boxShadow: const [AppColors.softShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _navigatePage(-1),
            icon: Icon(Icons.chevron_left_rounded, color: context.appTextMutedColor, size: 22),
            tooltip: l10n.previousWeek,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: context.subtleBgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          InkWell(
            onTap: isCurrentWeek ? null : _goToCurrentWeek,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isCurrentWeek ? AppColors.accent : AppColors.textFaint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCurrentWeek ? l10n.currentWeek : (displayedWeek.isBefore(today) ? l10n.pastWeek : l10n.upcomingWeek),
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrentWeek ? AppColors.accent : context.appTextMutedColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        weekStr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.appTextColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (!isCurrentWeek) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.backToToday,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _navigatePage(1),
            icon: Icon(Icons.chevron_right_rounded, color: context.appTextMutedColor, size: 22),
            tooltip: l10n.nextWeek,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: context.subtleBgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekPage(List<TaskGroupModel> groups, String weekStr, bool isPast) {
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.calendar_view_week_rounded,
                  size: 36,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chưa có nhóm công việc nào',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.appTextColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tạo nhóm đầu tiên (như Công việc, Học tập, Dự án...) để bắt đầu lên kế hoạch tuần này.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextMutedColor, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: widget.onAddGroup,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tạo nhóm đầu tiên', style: TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      _initialPage,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }
}
