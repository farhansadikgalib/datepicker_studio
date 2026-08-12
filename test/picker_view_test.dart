import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the picker on a fixed month so day-number taps are unambiguous.
Future<void> pumpPicker(
  WidgetTester tester, {
  PickedDateRange? initialRange,
  DateTime? initialMonth,
  DateRangePickerConfig config = const DateRangePickerConfig(),
  ValueChanged<PickedDateRange?>? onChanged,
  ValueChanged<PickedDateRange>? onApply,
  VoidCallback? onCancel,
  bool showActions = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: DateRangePickerView(
            initialRange: initialRange,
            initialMonth: initialMonth ?? DateTime(2026, 8),
            config: config,
            onChanged: onChanged,
            onApply: onApply,
            onCancel: onCancel,
            showActions: showActions,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Finds a day cell by its number, ignoring identically-numbered text
/// elsewhere in the tree such as the year grid.
Finder dayCell(String number) =>
    find.descendant(of: find.byType(MonthGrid), matching: find.text(number));

void main() {
  group('selection', () {
    testWidgets('first tap sets the start and clears the end', (tester) async {
      PickedDateRange? changed;
      var callCount = 0;
      await pumpPicker(
        tester,
        onChanged: (r) {
          changed = r;
          callCount++;
        },
      );

      await tester.tap(dayCell('10'));
      await tester.pumpAndSettle();

      // A half-open range reports null, but the callback still fires.
      expect(callCount, 1);
      expect(changed, isNull);
      expect(find.text('10 Aug 2026'), findsOneWidget);
    });

    testWidgets('second tap completes the range', (tester) async {
      PickedDateRange? changed;
      await pumpPicker(tester, onChanged: (r) => changed = r);

      await tester.tap(dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('15'));
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(changed!.start, DateTime(2026, 8, 10));
      expect(changed!.end, DateTime(2026, 8, 15));
      expect(changed!.days, 6);
    });

    testWidgets('tapping before the anchor swaps the endpoints', (
      tester,
    ) async {
      PickedDateRange? changed;
      await pumpPicker(tester, onChanged: (r) => changed = r);

      await tester.tap(dayCell('20'));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('5'));
      await tester.pumpAndSettle();

      expect(changed!.start, DateTime(2026, 8, 5));
      expect(changed!.end, DateTime(2026, 8, 20));
    });

    testWidgets('a third tap restarts the range', (tester) async {
      PickedDateRange? changed;
      await pumpPicker(tester, onChanged: (r) => changed = r);

      await tester.tap(dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('15'));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('20'));
      await tester.pumpAndSettle();

      // The new anchor leaves the range incomplete again.
      expect(changed, isNull);
      expect(find.text('20 Aug 2026'), findsOneWidget);
    });

    testWidgets('initialRange is shown on open', (tester) async {
      await pumpPicker(
        tester,
        initialRange: PickedDateRange(
          DateTime(2026, 8, 4),
          DateTime(2026, 8, 9),
        ),
      );

      expect(find.text('04 Aug 2026'), findsOneWidget);
      expect(find.text('09 Aug 2026'), findsOneWidget);
      expect(find.text('6 days selected'), findsOneWidget);
    });
  });

  group('range band', () {
    testWidgets('in-range cells paint a band spanning the full cell width', (
      tester,
    ) async {
      await pumpPicker(
        tester,
        initialRange: PickedDateRange(
          DateTime(2026, 8, 10),
          DateTime(2026, 8, 14),
        ),
      );

      // The band is the Stack's only plain coloured Container; the endpoint
      // pill carries a BoxDecoration instead.
      Rect bandOf(String day) {
        final stack = find
            .ancestor(of: dayCell(day), matching: find.byType(Stack))
            .first;
        final band = find.descendant(
          of: stack,
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.color != null,
          ),
        );
        expect(band, findsOneWidget, reason: 'day $day should paint a band');
        return tester.getRect(band);
      }

      Rect cellOf(String day) => tester.getRect(
        find.ancestor(of: dayCell(day), matching: find.byType(Stack)).first,
      );

      // Adjacent in-range bands must meet exactly, or the range renders as
      // disconnected blocks instead of one bar.
      expect(
        bandOf('12').right,
        moreOrLessEquals(bandOf('13').left, epsilon: 0.5),
        reason: 'adjacent in-range bands must touch',
      );

      // An endpoint cell fills only the half facing the rest of the range,
      // starting at the cell centre where the pill sits. The old code inset by
      // half the pill instead of half the cell, so on cells wider than the
      // pill the band started early and poked out past the rounded end.
      final startCell = cellOf('10');
      expect(
        bandOf('10').left,
        moreOrLessEquals(startCell.center.dx, epsilon: 0.5),
        reason: 'the start band must begin at the cell centre',
      );
      expect(
        bandOf('10').right,
        moreOrLessEquals(startCell.right, epsilon: 0.5),
        reason: 'the start band must run to the cell edge',
      );

      final endCell = cellOf('14');
      expect(
        bandOf('14').left,
        moreOrLessEquals(endCell.left, epsilon: 0.5),
        reason: 'the end band must begin at the cell edge',
      );
      expect(
        bandOf('14').right,
        moreOrLessEquals(endCell.center.dx, epsilon: 0.5),
        reason: 'the end band must stop at the cell centre',
      );
    });
  });

  group('single mode', () {
    testWidgets('one tap produces a one-day range', (tester) async {
      PickedDateRange? changed;
      await pumpPicker(
        tester,
        config: const DateRangePickerConfig(mode: DateRangeMode.single),
        onChanged: (r) => changed = r,
      );

      await tester.tap(dayCell('12'));
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(changed!.isSingleDay, isTrue);
      expect(changed!.start, DateTime(2026, 8, 12));
    });

    testWidgets('hides the From/To header split', (tester) async {
      await pumpPicker(
        tester,
        config: const DateRangePickerConfig(mode: DateRangeMode.single),
      );
      expect(find.text('From'), findsNothing);
      expect(find.text('To'), findsNothing);
    });
  });

  group('bounds', () {
    testWidgets('days outside min/max cannot be selected', (tester) async {
      PickedDateRange? changed;
      var callCount = 0;
      await pumpPicker(
        tester,
        config: DateRangePickerConfig(
          minDate: DateTime(2026, 8, 10),
          maxDate: DateTime(2026, 8, 20),
        ),
        onChanged: (r) {
          changed = r;
          callCount++;
        },
      );

      await tester.tap(dayCell('5'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(callCount, 0);

      await tester.tap(dayCell('25'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(callCount, 0);

      await tester.tap(dayCell('12'));
      await tester.pumpAndSettle();
      expect(callCount, 1);
      expect(changed, isNull); // start only
    });

    testWidgets('selectableDayPredicate blocks matching days', (tester) async {
      var callCount = 0;
      await pumpPicker(
        tester,
        config: DateRangePickerConfig(
          // Block weekends.
          selectableDayPredicate: (day) =>
              day.weekday != DateTime.saturday &&
              day.weekday != DateTime.sunday,
        ),
        onChanged: (_) => callCount++,
      );

      // 2026-08-15 is a Saturday; 2026-08-17 is a Monday.
      await tester.tap(dayCell('15'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(callCount, 0);

      await tester.tap(dayCell('17'));
      await tester.pumpAndSettle();
      expect(callCount, 1);
    });

    testWidgets('initialRange outside bounds is clamped', (tester) async {
      await pumpPicker(
        tester,
        initialRange: PickedDateRange(
          DateTime(2026, 8, 1),
          DateTime(2026, 8, 28),
        ),
        config: DateRangePickerConfig(
          minDate: DateTime(2026, 8, 10),
          maxDate: DateTime(2026, 8, 20),
        ),
      );

      expect(find.text('10 Aug 2026'), findsOneWidget);
      expect(find.text('20 Aug 2026'), findsOneWidget);
    });
  });

  group('range length limits', () {
    testWidgets('maxRangeLength disables days beyond the limit', (
      tester,
    ) async {
      PickedDateRange? changed;
      await pumpPicker(
        tester,
        config: const DateRangePickerConfig(maxRangeLength: 5),
        onChanged: (r) => changed = r,
      );

      await tester.tap(dayCell('10'));
      await tester.pumpAndSettle();

      // Day 20 is 11 days out, past the 5-day cap.
      await tester.tap(dayCell('20'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(changed, isNull);

      // Day 14 is exactly 5 days inclusive.
      await tester.tap(dayCell('14'));
      await tester.pumpAndSettle();
      expect(changed!.days, 5);
    });

    testWidgets('minRangeLength blocks Apply and shows a message', (
      tester,
    ) async {
      PickedDateRange? applied;
      await pumpPicker(
        tester,
        config: const DateRangePickerConfig(minRangeLength: 5),
        onApply: (r) => applied = r,
      );

      await tester.tap(dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('12'));
      await tester.pumpAndSettle();

      // 10 → 12 is only 3 days, so Apply stays disabled.
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(find.text('Select at least 5 days'), findsOneWidget);

      // Restart and pick a compliant range: 10 → 16 is 7 days.
      await tester.tap(dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('16'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(applied, isNotNull);
      expect(applied!.days, 7);
    });
  });

  group('presets', () {
    testWidgets('custom presets replace the defaults', (tester) async {
      await pumpPicker(
        tester,
        config: DateRangePickerConfig(
          presets: [DateRangePreset.lastDays(90), DateRangePreset.thisYear()],
        ),
      );

      expect(find.text('Last 90 Days'), findsOneWidget);
      expect(find.text('This Year'), findsOneWidget);
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('an empty list hides the chip row', (tester) async {
      await pumpPicker(
        tester,
        config: const DateRangePickerConfig(presets: []),
      );
      expect(find.text('Today'), findsNothing);
      expect(find.text('This Month'), findsNothing);
    });

    testWidgets('tapping a preset applies its range', (tester) async {
      PickedDateRange? changed;
      await pumpPicker(
        tester,
        config: DateRangePickerConfig(presets: [DateRangePreset.lastDays(7)]),
        onChanged: (r) => changed = r,
      );

      await tester.tap(find.text('Last 7 Days'));
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(changed!.days, 7);
    });

    testWidgets('a preset outside bounds is clamped', (tester) async {
      PickedDateRange? changed;
      final today = DateTime.now();
      await pumpPicker(
        tester,
        config: DateRangePickerConfig(
          minDate: DateTime(today.year, today.month, today.day),
          presets: [DateRangePreset.lastDays(30)],
        ),
        onChanged: (r) => changed = r,
      );

      await tester.tap(find.text('Last 30 Days'));
      await tester.pumpAndSettle();

      // The 30-day window starts before minDate, so it collapses to today.
      expect(changed!.days, 1);
    });
  });

  group('actions', () {
    testWidgets('Apply is disabled until the range is complete', (
      tester,
    ) async {
      await pumpPicker(tester);

      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );

      await tester.tap(dayCell('10'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );

      await tester.tap(dayCell('15'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('Cancel invokes onCancel', (tester) async {
      var cancelled = false;
      await pumpPicker(tester, onCancel: () => cancelled = true);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
    });

    testWidgets('autoApply fires without the Apply button', (tester) async {
      PickedDateRange? applied;
      await pumpPicker(
        tester,
        config: const DateRangePickerConfig(autoApply: true),
        onApply: (r) => applied = r,
      );

      await tester.tap(dayCell('10'));
      await tester.pumpAndSettle();
      expect(applied, isNull);

      await tester.tap(dayCell('15'));
      await tester.pumpAndSettle();
      expect(applied, isNotNull);
      expect(applied!.days, 6);
    });

    testWidgets('Clear resets the selection', (tester) async {
      PickedDateRange? changed = PickedDateRange.single(DateTime(2026, 8, 1));
      await pumpPicker(
        tester,
        initialRange: PickedDateRange(
          DateTime(2026, 8, 4),
          DateTime(2026, 8, 9),
        ),
        config: const DateRangePickerConfig(showClearButton: true),
        onChanged: (r) => changed = r,
      );

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(changed, isNull);
      expect(find.text('--'), findsNWidgets(2));
    });

    testWidgets('showActions: false hides the button row', (tester) async {
      await pumpPicker(tester, showActions: false);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });
  });

  group('navigation', () {
    testWidgets('chevrons move between months', (tester) async {
      await pumpPicker(tester);
      expect(find.text('August 2026'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      expect(find.text('July 2026'), findsOneWidget);
    });

    testWidgets('chevrons disable at the configured bounds', (tester) async {
      await pumpPicker(
        tester,
        config: DateRangePickerConfig(
          minDate: DateTime(2026, 8, 1),
          maxDate: DateTime(2026, 8, 31),
        ),
      );

      final prev = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_left_rounded),
          matching: find.byType(IconButton),
        ),
      );
      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right_rounded),
          matching: find.byType(IconButton),
        ),
      );

      expect(prev.onPressed, isNull);
      expect(next.onPressed, isNull);
    });

    testWidgets('the month title opens and closes the year grid', (
      tester,
    ) async {
      await pumpPicker(tester);

      await tester.tap(find.text('August 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Select year'), findsOneWidget);
      expect(find.byType(MonthGrid), findsNothing);

      await tester.tap(find.text('2028'));
      await tester.pumpAndSettle();
      expect(find.text('August 2028'), findsOneWidget);
      expect(find.byType(MonthGrid), findsWidgets);
    });

    testWidgets('a year jump actually moves the day grid, not just the title', (
      tester,
    ) async {
      await pumpPicker(tester);

      await tester.tap(find.text('August 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2028'));
      await tester.pumpAndSettle();

      // The PageView is unmounted while the year grid shows, so the controller
      // cannot be driven; without rebasing its origin it would restore the old
      // page and leave the grid on the original year behind a correct title.
      expect(find.text('August 2028'), findsOneWidget);
      expect(
        tester.widget<MonthGrid>(find.byType(MonthGrid).first).month,
        DateTime(2028, 8),
        reason: 'the rendered month must follow the title',
      );
    });

    testWidgets('enableYearPicker: false keeps the title inert', (
      tester,
    ) async {
      await pumpPicker(
        tester,
        config: const DateRangePickerConfig(enableYearPicker: false),
      );

      await tester.tap(find.text('August 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Select year'), findsNothing);
    });
  });

  group('configuration', () {
    testWidgets('firstDayOfWeek reorders the weekday header', (tester) async {
      await pumpPicker(
        tester,
        config: const DateRangePickerConfig(firstDayOfWeek: DateTime.sunday),
      );

      final headers = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(MonthGrid),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .take(7)
          .toList();

      expect(headers.first, 'Sun');
    });

    testWidgets('custom labels are rendered', (tester) async {
      await pumpPicker(
        tester,
        config: const DateRangePickerConfig(
          labels: DateRangePickerLabels(
            from: 'Desde',
            to: 'Hasta',
            apply: 'Aplicar',
            cancel: 'Cancelar',
          ),
        ),
      );

      expect(find.text('Desde'), findsOneWidget);
      expect(find.text('Hasta'), findsOneWidget);
      expect(find.text('Aplicar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('showHeader and showDayCount can be turned off', (
      tester,
    ) async {
      await pumpPicker(
        tester,
        initialRange: PickedDateRange(
          DateTime(2026, 8, 4),
          DateTime(2026, 8, 9),
        ),
        config: const DateRangePickerConfig(
          showHeader: false,
          showDayCount: false,
        ),
      );

      expect(find.text('From'), findsNothing);
      expect(find.text('6 days selected'), findsNothing);
    });

    testWidgets('a custom header format is applied', (tester) async {
      await pumpPicker(
        tester,
        initialRange: PickedDateRange(
          DateTime(2026, 8, 4),
          DateTime(2026, 8, 9),
        ),
        config: const DateRangePickerConfig(headerDateFormat: 'yyyy-MM-dd'),
      );
      expect(find.text('2026-08-04'), findsOneWidget);
      expect(find.text('2026-08-09'), findsOneWidget);
    });
  });

  group('modal entry points', () {
    testWidgets('the sheet returns the applied range', (tester) async {
      PickedDateRange? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DateRangePickerSheet(
                    context,
                    initialMonth: DateTime(2026, 8),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerView), findsOneWidget);

      await tester.tap(dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.start, DateTime(2026, 8, 10));
      expect(result!.end, DateTime(2026, 8, 15));
    });

    testWidgets('cancelling the sheet resolves to null', (tester) async {
      PickedDateRange? result = PickedDateRange.single(DateTime(2026, 1, 1));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DateRangePickerSheet(
                    context,
                    initialMonth: DateTime(2026, 8),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('the dialog returns the applied range', (tester) async {
      PickedDateRange? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DateRangePickerPopup(
                    context,
                    initialMonth: DateTime(2026, 8),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('3'));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result!.days, 5);
    });
  });

  group('DateRangeField', () {
    testWidgets('shows the hint when empty and the range when set', (
      tester,
    ) async {
      PickedDateRange? value;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => DateRangeField(
                value: value,
                onChanged: (r) => setState(() => value = r),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Select date range'), findsOneWidget);

      await tester.tap(find.byType(DateRangeField));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(dayCell('12'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(value, isNotNull);
      expect(value!.days, 3);
      // The formatted range is now shown in place of the placeholder.
      expect(find.textContaining('→'), findsOneWidget);
    });

    testWidgets('the clear button empties the field', (tester) async {
      PickedDateRange? value = PickedDateRange(
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 5),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => DateRangeField(
                value: value,
                onChanged: (r) => setState(() => value = r),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(value, isNull);
      expect(find.text('Select date range'), findsOneWidget);
    });
  });
}
