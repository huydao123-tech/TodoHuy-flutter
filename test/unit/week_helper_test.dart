import 'package:flutter_test/flutter_test.dart';
import 'package:todohuy/core/utils/week_helper.dart';

void main() {
  group('WeekHelper Tests', () {
    test('getStartOfWeek returns Monday of the current week', () {
      // 2026-09-13 is a Sunday (weekday = 7)
      final sunday = DateTime(2026, 9, 13);
      final monday = WeekHelper.getStartOfWeek(sunday);

      expect(monday.year, 2026);
      expect(monday.month, 9);
      expect(monday.day, 7);
      expect(monday.weekday, DateTime.monday);
    });

    test('getStartOfWeek returns same day if date is already Monday', () {
      final monday = DateTime(2026, 9, 7);
      final result = WeekHelper.getStartOfWeek(monday);

      expect(result.year, 2026);
      expect(result.month, 9);
      expect(result.day, 7);
      expect(result.weekday, DateTime.monday);
    });

    test('getEndOfWeek returns Sunday of the current week', () {
      final wednesday = DateTime(2026, 9, 9);
      final sunday = WeekHelper.getEndOfWeek(wednesday);

      expect(sunday.year, 2026);
      expect(sunday.month, 9);
      expect(sunday.day, 13);
      expect(sunday.weekday, DateTime.sunday);
    });

    test('formatWeekRange formats correctly dd/MM - dd/MM', () {
      final wednesday = DateTime(2026, 9, 9);
      final range = WeekHelper.formatWeekRange(wednesday);

      expect(range, '07/09 - 13/09');
    });

    test('getStartOfWeek handles month rollover correctly', () {
      // 2026-10-01 is a Thursday
      final thursday = DateTime(2026, 10, 1);
      final monday = WeekHelper.getStartOfWeek(thursday);

      // Start of week should be in September (2026-09-28)
      expect(monday.year, 2026);
      expect(monday.month, 9);
      expect(monday.day, 28);
      expect(monday.weekday, DateTime.monday);
    });

    test('getStartOfWeek handles year rollover correctly', () {
      // 2026-01-01 is a Thursday
      final newYear = DateTime(2026, 1, 1);
      final monday = WeekHelper.getStartOfWeek(newYear);

      // Monday should be in 2025-12-29
      expect(monday.year, 2025);
      expect(monday.month, 12);
      expect(monday.day, 29);
      expect(monday.weekday, DateTime.monday);
    });

    test('toWeekStartStr returns formatted YYYY-MM-DD for the Monday of that week', () {
      final wednesday = DateTime(2026, 9, 9);
      final weekStartStr = WeekHelper.toWeekStartStr(wednesday);
      expect(weekStartStr, '2026-09-07');
    });
  });
}
