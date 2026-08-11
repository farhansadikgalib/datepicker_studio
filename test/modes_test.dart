import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _dayCell(String number) => find.descendant(
  of: find.byType(MonthGrid),
  matching: find.text(number),
);

Future<void> _pump(
  WidgetTester tester, {
  required DateRangePickerConfig config,
  PickedDateRange? range,
  DateTime? initialMonth,
  ValueChanged<PickedDateRange?>? onChanged,
  ValueChanged<PickedDateRange>? onApply,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: DateRangePickerView(
            initialMonth: initialMonth ?? DateTime(2026, 8),
            initialRange: range,
            config: config,
            onChanged: onChanged,
            onApply: onApply,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('birthday mode', () {
    const config = DateRangePickerConfig(mode: DateRangeMode.birthday);

    testWidgets('opens on the year grid rather than the calendar', (
      tester,
    ) async {
      await _pump(tester, config: config);

      expect(find.text('Select year'), findsOneWidget);
      expect(find.byType(MonthGrid), findsNothing);
    });

    testWidgets('drills year → month → day', (tester) async {
      PickedDateRange? changed;
      await _pump(tester, config: config, onChanged: (r) => changed = r);

      // Year step. The grid is lazy and opens near today, so scroll back.
      await tester.scrollUntilVisible(
        find.text('1990'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('1990'));
      await tester.pumpAndSettle();
      expect(find.byType(MonthPickerGrid), findsOneWidget);
      expect(find.text('1990'), findsOneWidget); // title shows the year

      // Month step.
      await tester.tap(find.text('Jun'));
      await tester.pumpAndSettle();
      expect(find.byType(MonthGrid), findsWidgets);
      expect(find.text('June 1990'), findsOneWidget);

      // Day step.
      await tester.tap(_dayCell('15'));
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(changed!.start, DateTime(1990, 6, 15));
      expect(changed!.isSingleDay, isTrue);
    });

    testWidgets('future dates are not selectable by default', (tester) async {
      final future = DateTime.now().add(const Duration(days: 365));
      await _pump(
        tester,
        config: config,
        range: PickedDateRange.single(DateTime(1990, 6, 15)),
        initialMonth: DateTime(future.year, future.month),
      );

      // maxDate defaults to today, so a year ahead is out of bounds.
      final title = find.textContaining('${future.year}');
      expect(title, findsWidgets);

      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(next.onPressed, isNull, reason: 'cannot page past today');
    });

    testWidgets('an explicit maxDate overrides the today default', (
      tester,
    ) async {
      await _pump(
        tester,
        config: DateRangePickerConfig(
          mode: DateRangeMode.birthday,
          maxDate: DateTime(2030, 12, 31),
        ),
        range: PickedDateRange.single(DateTime(2026, 8, 10)),
      );

      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(next.onPressed, isNotNull);
    });

    testWidgets('shows the age for the chosen date', (tester) async {
      final now = DateTime.now();
      // A birthday already passed this year, so the age is exact.
      final birth = DateTime(now.year - 30, 1, 1);
      await _pump(
        tester,
        config: config,
        range: PickedDateRange.single(birth),
      );

      expect(find.text('Age 30'), findsOneWidget);
    });

    testWidgets('an existing selection skips straight to the calendar', (
      tester,
    ) async {
      await _pump(
        tester,
        config: config,
        range: PickedDateRange.single(DateTime(1990, 6, 15)),
      );

      expect(find.text('Select year'), findsNothing);
      expect(find.byType(MonthGrid), findsWidgets);
    });

    testWidgets('months outside the bounds are disabled', (tester) async {
      await _pump(
        tester,
        config: DateRangePickerConfig(
          mode: DateRangeMode.birthday,
          maxDate: DateTime(1990, 6, 30),
          firstYear: 1980,
          lastYear: 1990,
        ),
      );

      await tester.tap(find.text('1990'));
      await tester.pumpAndSettle();

      // July onward is past the June 30 bound.
      await tester.tap(find.text('Dec'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(MonthPickerGrid), findsOneWidget, reason: 'no drill');

      await tester.tap(find.text('Jun'));
      await tester.pumpAndSettle();
      expect(find.byType(MonthGrid), findsWidgets);
    });
  });

  group('ageInYears', () {
    test('counts a birthday already passed this year', () {
      final range = PickedDateRange.single(DateTime(1990, 1, 1));
      expect(range.ageInYears(DateTime(2026, 6, 1)), 36);
    });

    test('does not count a birthday still ahead this year', () {
      final range = PickedDateRange.single(DateTime(1990, 12, 31));
      expect(range.ageInYears(DateTime(2026, 6, 1)), 35);
    });

    test('counts the birthday itself', () {
      final range = PickedDateRange.single(DateTime(1990, 6, 1));
      expect(range.ageInYears(DateTime(2026, 6, 1)), 36);
    });

    test('handles a leap-day birthday', () {
      final range = PickedDateRange.single(DateTime(2000, 2, 29));
      expect(range.ageInYears(DateTime(2026, 2, 28)), 25);
      expect(range.ageInYears(DateTime(2026, 3, 1)), 26);
    });

    test('is negative for a future date', () {
      final range = PickedDateRange.single(DateTime(2030, 1, 1));
      expect(range.ageInYears(DateTime(2026, 6, 1)), lessThan(0));
    });
  });

  group('dateTime mode', () {
    const config = DateRangePickerConfig(mode: DateRangeMode.dateTime);

    testWidgets('shows a time field per endpoint', (tester) async {
      await _pump(tester, config: config);

      expect(find.byType(TimeRow), findsOneWidget);
      expect(find.text('Start time'), findsOneWidget);
      expect(find.text('End time'), findsOneWidget);
    });

    testWidgets('attaches the default times to the picked range', (
      tester,
    ) async {
      PickedDateRange? changed;
      await _pump(tester, config: config, onChanged: (r) => changed = r);

      await tester.tap(_dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(_dayCell('14'));
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(changed!.hasTime, isTrue);
      expect(changed!.start, DateTime(2026, 8, 10, 9, 0));
      expect(changed!.end, DateTime(2026, 8, 14, 17, 0));
    });

    testWidgets('honours custom initial times', (tester) async {
      PickedDateRange? changed;
      await _pump(
        tester,
        config: const DateRangePickerConfig(
          mode: DateRangeMode.dateTime,
          initialStartTime: TimeOfDay(hour: 8, minute: 30),
          initialEndTime: TimeOfDay(hour: 22, minute: 45),
        ),
        onChanged: (r) => changed = r,
      );

      await tester.tap(_dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(_dayCell('11'));
      await tester.pumpAndSettle();

      expect(changed!.start, DateTime(2026, 8, 10, 8, 30));
      expect(changed!.end, DateTime(2026, 8, 11, 22, 45));
    });

    testWidgets('an initial timed range round-trips its times', (tester) async {
      await _pump(
        tester,
        config: config,
        range: PickedDateRange.withTime(
          DateTime(2026, 8, 4, 11, 15),
          DateTime(2026, 8, 9, 19, 45),
        ),
      );

      // 11:15 and 19:45 rendered in the ambient 12-hour locale.
      expect(find.textContaining('11:15'), findsOneWidget);
      expect(find.textContaining('7:45'), findsOneWidget);
    });

    testWidgets('a 24-hour override formats both fields', (tester) async {
      await _pump(
        tester,
        config: const DateRangePickerConfig(
          mode: DateRangeMode.dateTime,
          use24HourFormat: true,
        ),
        range: PickedDateRange.withTime(
          DateTime(2026, 8, 4, 11, 15),
          DateTime(2026, 8, 9, 19, 45),
        ),
      );

      expect(find.text('11:15'), findsOneWidget);
      expect(find.text('19:45'), findsOneWidget);
    });

    testWidgets('single + dateTime shows only the start field', (tester) async {
      await _pump(
        tester,
        config: const DateRangePickerConfig(
          mode: DateRangeMode.dateTime,
        ).copyWith(mode: DateRangeMode.dateTime),
      );

      expect(find.text('Start time'), findsOneWidget);
      expect(find.text('End time'), findsOneWidget);
    });

    testWidgets('rejects a minuteInterval that does not divide 60', (
      tester,
    ) async {
      expect(
        () => DateRangePickerConfig(minuteInterval: 7),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DateRangePickerConfig(minuteInterval: 15),
        returnsNormally,
      );
    });
  });

  group('PickedDateRange with time', () {
    test('withTime preserves hours and minutes', () {
      final range = PickedDateRange.withTime(
        DateTime(2026, 8, 4, 9, 30),
        DateTime(2026, 8, 4, 17, 15),
      );

      expect(range.hasTime, isTrue);
      expect(range.start.hour, 9);
      expect(range.end.minute, 15);
    });

    test('orders endpoints by full timestamp within one day', () {
      final range = PickedDateRange.withTime(
        DateTime(2026, 8, 4, 17, 0),
        DateTime(2026, 8, 4, 9, 0),
      );

      expect(range.start.hour, 9);
      expect(range.end.hour, 17);
    });

    test('duration reflects the times', () {
      final range = PickedDateRange.withTime(
        DateTime(2026, 8, 4, 9, 0),
        DateTime(2026, 8, 4, 17, 30),
      );
      expect(range.duration, const Duration(hours: 8, minutes: 30));
    });

    test('the plain constructor still normalises to midnight', () {
      final range = PickedDateRange(
        DateTime(2026, 8, 4, 9, 30),
        DateTime(2026, 8, 9, 17, 15),
      );

      expect(range.hasTime, isFalse);
      expect(range.start, DateTime(2026, 8, 4));
      expect(range.end, DateTime(2026, 8, 9));
    });

    test('timed and untimed ranges are never equal', () {
      final timed = PickedDateRange.withTime(
        DateTime(2026, 8, 4),
        DateTime(2026, 8, 9),
      );
      final plain = PickedDateRange(DateTime(2026, 8, 4), DateTime(2026, 8, 9));

      expect(timed, isNot(plain));
    });

    test('timed equality compares to the minute', () {
      final a = PickedDateRange.withTime(
        DateTime(2026, 8, 4, 9, 0),
        DateTime(2026, 8, 4, 17, 0),
      );
      final b = PickedDateRange.withTime(
        DateTime(2026, 8, 4, 9, 0),
        DateTime(2026, 8, 4, 17, 0),
      );
      final c = PickedDateRange.withTime(
        DateTime(2026, 8, 4, 9, 0),
        DateTime(2026, 8, 4, 17, 30),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('withTimes attaches times to an untimed range', () {
      final range = PickedDateRange(
        DateTime(2026, 8, 4),
        DateTime(2026, 8, 9),
      ).withTimes(
        startTime: const TimeOfDay(hour: 8, minute: 15),
        endTime: const TimeOfDay(hour: 20, minute: 45),
      );

      expect(range.hasTime, isTrue);
      expect(range.start, DateTime(2026, 8, 4, 8, 15));
      expect(range.end, DateTime(2026, 8, 9, 20, 45));
    });

    test('copyWith preserves the timed flag', () {
      final timed = PickedDateRange.withTime(
        DateTime(2026, 8, 4, 9, 0),
        DateTime(2026, 8, 9, 17, 0),
      );
      expect(timed.copyWith(end: DateTime(2026, 8, 10, 18, 0)).hasTime, isTrue);

      final plain = PickedDateRange(DateTime(2026, 8, 4), DateTime(2026, 8, 9));
      expect(plain.copyWith(end: DateTime(2026, 8, 10)).hasTime, isFalse);
    });

    test('toString includes the time only when present', () {
      expect(
        PickedDateRange.withTime(
          DateTime(2026, 8, 4, 9, 0),
          DateTime(2026, 8, 4, 17, 0),
        ).toString(),
        contains('09:00'),
      );
      expect(
        PickedDateRange(
          DateTime(2026, 8, 4),
          DateTime(2026, 8, 9),
        ).toString(),
        isNot(contains(':')),
      );
    });
  });
}
