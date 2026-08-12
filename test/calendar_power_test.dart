import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:datepicker_studio/src/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _dayCell(String number) =>
    find.descendant(of: find.byType(MonthGrid), matching: find.text(number));

Future<void> _pumpView(
  WidgetTester tester, {
  required DateRangePickerConfig config,
  ValueChanged<PickedDateRange?>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: DateRangePickerView(
            initialMonth: DateTime(2026, 8),
            config: config,
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('isoWeekNumber', () {
    test('week 1 contains the year\'s first Thursday', () {
      // 2026-01-01 is a Thursday → week 1.
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
      // 2025-12-29 (Mon) belongs to ISO week 1 of 2026.
      expect(isoWeekNumber(DateTime(2025, 12, 29)), 1);
    });

    test('mid-year weeks compute correctly', () {
      expect(isoWeekNumber(DateTime(2026, 8, 10)), 33);
    });
  });

  group('disabledRanges', () {
    testWidgets('blocks taps inside a disabled span', (tester) async {
      PickedDateRange? changed;
      await _pumpView(
        tester,
        config: DateRangePickerConfig(
          mode: DateRangeMode.single,
          disabledRanges: [
            DateTimeRange(
              start: DateTime(2026, 8, 10),
              end: DateTime(2026, 8, 15),
            ),
          ],
        ),
        onChanged: (r) => changed = r,
      );

      // 12 is inside the blocked span → tap is a no-op.
      await tester.tap(_dayCell('12'));
      await tester.pumpAndSettle();
      expect(changed, isNull);

      // 20 is outside → selectable.
      await tester.tap(_dayCell('20'));
      await tester.pumpAndSettle();
      expect(changed, isNotNull);
    });
  });

  group('dayBuilder', () {
    testWidgets('replaces the default cell and still reports taps', (
      tester,
    ) async {
      PickedDateRange? changed;
      await _pumpView(
        tester,
        config: DateRangePickerConfig(
          mode: DateRangeMode.single,
          dayBuilder: (context, details) =>
              Center(child: Text('D${details.day.day}')),
        ),
        onChanged: (r) => changed = r,
      );

      expect(find.text('D15'), findsOneWidget);
      await tester.tap(find.text('D15'));
      await tester.pumpAndSettle();
      expect(changed?.start.day, 15);
    });
  });

  group('week numbers', () {
    testWidgets('renders the ISO week column when enabled', (tester) async {
      await _pumpView(
        tester,
        config: const DateRangePickerConfig(showWeekNumbers: true),
      );
      // August 2026 spans ISO weeks 31–36; 33 is always present.
      expect(
        find.descendant(of: find.byType(MonthGrid), matching: find.text('33')),
        findsOneWidget,
      );
    });

    testWidgets('is absent by default', (tester) async {
      await _pumpView(tester, config: const DateRangePickerConfig());
      // A bare week number like 33 should not appear as its own cell.
      expect(
        find.descendant(of: find.byType(MonthGrid), matching: find.text('33')),
        findsNothing,
      );
    });
  });

  group('eventLoader', () {
    testWidgets('does not crash and keeps the day tappable', (tester) async {
      PickedDateRange? changed;
      await _pumpView(
        tester,
        config: DateRangePickerConfig(
          mode: DateRangeMode.single,
          eventLoader: (day) => day.day == 9 ? ['a', 'b'] : const [],
        ),
        onChanged: (r) => changed = r,
      );

      await tester.tap(_dayCell('9'));
      await tester.pumpAndSettle();
      expect(changed?.start.day, 9);
    });
  });
}
