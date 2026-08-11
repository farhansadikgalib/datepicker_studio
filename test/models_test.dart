import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PickedDateRange', () {
    test('normalises endpoints to midnight', () {
      final range = PickedDateRange(
        DateTime(2026, 5, 1, 14, 30),
        DateTime(2026, 5, 5, 9, 15),
      );
      expect(range.start, DateTime(2026, 5, 1));
      expect(range.end, DateTime(2026, 5, 5));
    });

    test('swaps reversed endpoints', () {
      final range = PickedDateRange(DateTime(2026, 5, 5), DateTime(2026, 5, 1));
      expect(range.start, DateTime(2026, 5, 1));
      expect(range.end, DateTime(2026, 5, 5));
    });

    test('counts days inclusively', () {
      expect(
        PickedDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 7)).days,
        7,
      );
      expect(PickedDateRange.single(DateTime(2026, 5, 1)).days, 1);
    });

    test('reports single-day ranges', () {
      expect(PickedDateRange.single(DateTime(2026, 5, 1)).isSingleDay, isTrue);
      expect(
        PickedDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 2)).isSingleDay,
        isFalse,
      );
    });

    test('contains is inclusive of both endpoints', () {
      final range = PickedDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 5));
      expect(range.contains(DateTime(2026, 5, 1)), isTrue);
      expect(range.contains(DateTime(2026, 5, 5)), isTrue);
      expect(range.contains(DateTime(2026, 5, 3)), isTrue);
      expect(range.contains(DateTime(2026, 4, 30)), isFalse);
      expect(range.contains(DateTime(2026, 5, 6)), isFalse);
    });

    test('toList enumerates every day in order', () {
      final days = PickedDateRange(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 3),
      ).toList();
      expect(days, [
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 2),
        DateTime(2026, 5, 3),
      ]);
    });

    test('round-trips through DateTimeRange', () {
      final range = PickedDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 9));
      expect(PickedDateRange.fromDateTimeRange(range.toDateTimeRange()), range);
    });

    test('equality ignores time of day', () {
      expect(
        PickedDateRange(DateTime(2026, 5, 1, 8), DateTime(2026, 5, 5, 20)),
        PickedDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 5)),
      );
    });

    test('copyWith replaces one endpoint', () {
      final range = PickedDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 5));
      expect(
        range.copyWith(end: DateTime(2026, 5, 9)).end,
        DateTime(2026, 5, 9),
      );
    });
  });

  group('DateRangePreset', () {
    final now = DateTime(2026, 8, 12); // A Wednesday.

    test('today spans a single day', () {
      final range = DateRangePreset.today().build(now);
      expect(range.days, 1);
      expect(range.start, DateTime(2026, 8, 12));
    });

    test('yesterday is the preceding day', () {
      expect(
        DateRangePreset.yesterday().build(now).start,
        DateTime(2026, 8, 11),
      );
    });

    test('thisWeek honours the first day of week', () {
      expect(
        DateRangePreset.thisWeek(
          firstDayOfWeek: DateTime.monday,
        ).build(now).start,
        DateTime(2026, 8, 10),
      );
      expect(
        DateRangePreset.thisWeek(
          firstDayOfWeek: DateTime.sunday,
        ).build(now).start,
        DateTime(2026, 8, 9),
      );
    });

    test('lastWeek is the seven days before this week', () {
      final range = DateRangePreset.lastWeek().build(now);
      expect(range.start, DateTime(2026, 8, 3));
      expect(range.end, DateTime(2026, 8, 9));
      expect(range.days, 7);
    });

    test('thisMonth starts on the 1st', () {
      final range = DateRangePreset.thisMonth().build(now);
      expect(range.start, DateTime(2026, 8, 1));
      expect(range.end, DateTime(2026, 8, 12));
    });

    test('lastMonth covers the whole previous month', () {
      final range = DateRangePreset.lastMonth().build(now);
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, DateTime(2026, 7, 31));
      expect(range.days, 31);
    });

    test('lastMonth crosses the year boundary', () {
      final range = DateRangePreset.lastMonth().build(DateTime(2026, 1, 15));
      expect(range.start, DateTime(2025, 12, 1));
      expect(range.end, DateTime(2025, 12, 31));
    });

    test('thisYear starts on Jan 1', () {
      expect(DateRangePreset.thisYear().build(now).start, DateTime(2026, 1, 1));
    });

    test('lastDays includes today', () {
      final range = DateRangePreset.lastDays(7).build(now);
      expect(range.days, 7);
      expect(range.end, DateTime(2026, 8, 12));
      expect(range.start, DateTime(2026, 8, 6));
    });

    test('nextDays starts today', () {
      final range = DateRangePreset.nextDays(3).build(now);
      expect(range.start, DateTime(2026, 8, 12));
      expect(range.end, DateTime(2026, 8, 14));
    });

    test('lastDays derives a default label', () {
      expect(DateRangePreset.lastDays(30).label, 'Last 30 Days');
      expect(DateRangePreset.lastDays(30, label: 'Month').label, 'Month');
    });

    test('defaults returns five chips', () {
      expect(DateRangePreset.defaults().length, 5);
    });
  });

  group('DateRangePickerConfig', () {
    test('rejects an invalid first day of week', () {
      expect(
        () => DateRangePickerConfig(firstDayOfWeek: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DateRangePickerConfig(firstDayOfWeek: 8),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a min length above the max', () {
      expect(
        () => DateRangePickerConfig(minRangeLength: 10, maxRangeLength: 5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects non-positive lengths and month counts', () {
      expect(
        () => DateRangePickerConfig(minRangeLength: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DateRangePickerConfig(visibleMonths: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith preserves untouched fields', () {
      const config = DateRangePickerConfig(
        maxRangeLength: 30,
        firstDayOfWeek: DateTime.sunday,
      );
      final copy = config.copyWith(maxRangeLength: 60);
      expect(copy.maxRangeLength, 60);
      expect(copy.firstDayOfWeek, DateTime.sunday);
    });
  });

  group('DateRangePickerLabels', () {
    test('pluralises the day count', () {
      const labels = DateRangePickerLabels();
      expect(labels.daysSelected(1), '1 day selected');
      expect(labels.daysSelected(5), '5 days selected');
    });

    test('accepts overrides', () {
      final labels = DateRangePickerLabels(
        apply: 'Fertig',
        daysSelected: (d) => '$d Tage',
      );
      expect(labels.apply, 'Fertig');
      expect(labels.daysSelected(3), '3 Tage');
    });
  });

  group('DateRangePickerTheme', () {
    testWidgets('resolve fills every field from the ambient theme', (
      tester,
    ) async {
      late DateRangePickerTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          home: Builder(
            builder: (context) {
              resolved = const DateRangePickerTheme().resolve(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.primaryColor, isNotNull);
      expect(resolved.onPrimaryColor, isNotNull);
      expect(resolved.rangeColor, isNotNull);
      expect(resolved.backgroundColor, isNotNull);
      expect(resolved.disabledColor, isNotNull);
      expect(resolved.dayExtent, isNotNull);
      expect(resolved.dayStyle, isNotNull);
      expect(resolved.padding, isNotNull);
    });

    testWidgets('explicit values survive resolve', (tester) async {
      late DateRangePickerTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              resolved = const DateRangePickerTheme(
                primaryColor: Color(0xFFEE0000),
                dayExtent: 52,
              ).resolve(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.primaryColor, const Color(0xFFEE0000));
      expect(resolved.dayExtent, 52);
    });

    test('from derives a range tint from the primary colour', () {
      final theme = DateRangePickerTheme.from(primary: const Color(0xFF3366FF));
      expect(theme.primaryColor, const Color(0xFF3366FF));
      expect(theme.rangeColor, isNotNull);
      expect(theme.onRangeColor, const Color(0xFF3366FF));
    });
  });
}
