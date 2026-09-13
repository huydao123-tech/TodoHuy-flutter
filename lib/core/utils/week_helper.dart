import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Helper class for weekly calculations
class WeekHelper {
  static DateTime getStartOfWeek(DateTime date) {
    int daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  static DateTime getEndOfWeek(DateTime date) {
    return getStartOfWeek(date).add(const Duration(days: 6));
  }

  static String formatWeekRange(DateTime date) {
    final start = getStartOfWeek(date);
    final end = getEndOfWeek(date);
    final format = DateFormat('dd/MM');
    return '${format.format(start)} - ${format.format(end)}';
  }
}

// State provider for selected week
final selectedWeekProvider = StateProvider<DateTime>((ref) => WeekHelper.getStartOfWeek(DateTime.now()));
