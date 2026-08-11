import 'package:datepicker_studio/src/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dateOnly', () {
    test('strips the time component', () {
      expect(
        dateOnly(DateTime(2026, 3, 14, 23, 59, 59)),
        DateTime(2026, 3, 14),
      );
    });
  });

  group('isSameDay', () {
    test('ignores time of day', () {
      expect(
        isSameDay(DateTime(2026, 3, 14, 9), DateTime(2026, 3, 14, 21)),
        isTrue,
      );
    });

    test('is false across a day boundary', () {
      expect(isSameDay(DateTime(2026, 3, 14), DateTime(2026, 3, 15)), isFalse);
    });

    test('is false when either side is null', () {
      expect(isSameDay(null, DateTime(2026, 3, 14)), isFalse);
      expect(isSameDay(DateTime(2026, 3, 14), null), isFalse);
    });
  });

  group('daysInMonth', () {
    test('handles 30- and 31-day months', () {
      expect(daysInMonth(2026, 1), 31);
      expect(daysInMonth(2026, 4), 30);
    });

    test('handles leap and non-leap February', () {
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2000, 2), 29);
      expect(daysInMonth(1900, 2), 28);
    });
  });

  group('addMonths', () {
    test('clamps the day to the target month length', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    });

    test('crosses year boundaries in both directions', () {
      expect(addMonths(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 15));
      expect(addMonths(DateTime(2026, 1, 15), -1), DateTime(2025, 12, 15));
      expect(addMonths(DateTime(2026, 6, 10), -18), DateTime(2024, 12, 10));
    });

    test('is a no-op for zero', () {
      expect(addMonths(DateTime(2026, 6, 10), 0), DateTime(2026, 6, 10));
    });
  });

  group('monthsBetween', () {
    test('counts whole months regardless of day', () {
      expect(monthsBetween(DateTime(2026, 1, 31), DateTime(2026, 3, 1)), 2);
      expect(monthsBetween(DateTime(2026, 3, 1), DateTime(2026, 1, 31)), -2);
    });
  });

  group('inclusiveDayCount', () {
    test('counts a single day as one', () {
      expect(inclusiveDayCount(DateTime(2026, 5, 4), DateTime(2026, 5, 4)), 1);
    });

    test('counts both endpoints', () {
      expect(inclusiveDayCount(DateTime(2026, 5, 1), DateTime(2026, 5, 7)), 7);
    });

    test('is order independent', () {
      expect(inclusiveDayCount(DateTime(2026, 5, 7), DateTime(2026, 5, 1)), 7);
    });

    test('spans a leap day', () {
      expect(inclusiveDayCount(DateTime(2024, 2, 28), DateTime(2024, 3, 1)), 3);
    });
  });

  group('addDays', () {
    test('moves forward and backward across month ends', () {
      expect(addDays(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 1));
      expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    });

    test('round-trips', () {
      final d = DateTime(2026, 7, 15);
      expect(addDays(addDays(d, 30), -30), d);
    });
  });

  group('isWithin', () {
    final min = DateTime(2026, 1, 10);
    final max = DateTime(2026, 1, 20);

    test('includes both bounds', () {
      expect(isWithin(DateTime(2026, 1, 10), min, max), isTrue);
      expect(isWithin(DateTime(2026, 1, 20), min, max), isTrue);
    });

    test('excludes outside days', () {
      expect(isWithin(DateTime(2026, 1, 9), min, max), isFalse);
      expect(isWithin(DateTime(2026, 1, 21), min, max), isFalse);
    });

    test('treats null bounds as unbounded', () {
      expect(isWithin(DateTime(1990, 1, 1), null, max), isTrue);
      expect(isWithin(DateTime(2090, 1, 1), min, null), isTrue);
    });

    test('ignores time of day at the bounds', () {
      expect(isWithin(DateTime(2026, 1, 20, 23, 30), min, max), isTrue);
    });
  });

  group('clampDate', () {
    test('pulls out-of-range dates to the nearest bound', () {
      final min = DateTime(2026, 1, 10);
      final max = DateTime(2026, 1, 20);
      expect(clampDate(DateTime(2026, 1, 1), min, max), min);
      expect(clampDate(DateTime(2026, 2, 1), min, max), max);
      expect(clampDate(DateTime(2026, 1, 15), min, max), DateTime(2026, 1, 15));
    });
  });

  group('startOfWeek', () {
    // 2026-08-12 is a Wednesday.
    final wednesday = DateTime(2026, 8, 12);

    test('resolves a Monday-first week', () {
      expect(startOfWeek(wednesday, DateTime.monday), DateTime(2026, 8, 10));
    });

    test('resolves a Sunday-first week', () {
      expect(startOfWeek(wednesday, DateTime.sunday), DateTime(2026, 8, 9));
    });

    test('is idempotent on the first day itself', () {
      final monday = DateTime(2026, 8, 10);
      expect(startOfWeek(monday, DateTime.monday), monday);
    });
  });
}
