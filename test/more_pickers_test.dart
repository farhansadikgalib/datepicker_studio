import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _dayCell(String number) =>
    find.descendant(of: find.byType(MonthGrid), matching: find.text(number));

/// Pumps a button that opens [open] and records its result into [holder].
Future<void> _pumpOpener<T>(
  WidgetTester tester,
  List<T?> holder,
  Future<T?> Function(BuildContext context) open,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async => holder.add(await open(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('week mode', () {
    testWidgets('one tap selects the whole week', (tester) async {
      PickedDateRange? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: DateRangePickerView(
                initialMonth: DateTime(2026, 8),
                config: const DateRangePickerConfig(mode: DateRangeMode.week),
                onChanged: (r) => changed = r,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_dayCell('15'));
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(changed!.days, 7);
      expect(changed!.start.weekday, DateTime.monday);
      expect(changed!.contains(DateTime(2026, 8, 15)), isTrue);
    });
  });

  group('DateRangePickerDuration', () {
    testWidgets('returns the initial duration when confirmed', (tester) async {
      final holder = <Duration?>[];
      await _pumpOpener(
        tester,
        holder,
        (context) => DateRangePickerDuration(
          context,
          initialDuration: const Duration(hours: 1, minutes: 30),
          minuteInterval: 15,
        ),
      );

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(holder.single, const Duration(hours: 1, minutes: 30));
    });

    testWidgets('cancel resolves to null', (tester) async {
      final holder = <Duration?>[];
      await _pumpOpener(
        tester,
        holder,
        (context) => DateRangePickerDuration(context),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(holder.single, isNull);
    });
  });

  group('DateRangePickerMonth', () {
    testWidgets('returns the first day of the tapped month', (tester) async {
      final holder = <DateTime?>[];
      await _pumpOpener(
        tester,
        holder,
        (context) =>
            DateRangePickerMonth(context, initialMonth: DateTime(2026, 8)),
      );

      // Month grid shows abbreviated names; tap March.
      await tester.tap(find.text('Mar'));
      await tester.pumpAndSettle();
      expect(holder.single, DateTime(2026, 3));
    });

    testWidgets('year arrows move between years', (tester) async {
      final holder = <DateTime?>[];
      await _pumpOpener(
        tester,
        holder,
        (context) =>
            DateRangePickerMonth(context, initialMonth: DateTime(2026, 8)),
      );

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jan'));
      await tester.pumpAndSettle();
      expect(holder.single, DateTime(2027, 1));
    });
  });

  group('DateRangePickerYear', () {
    testWidgets('returns the tapped year', (tester) async {
      final holder = <int?>[];
      await _pumpOpener(
        tester,
        holder,
        (context) => DateRangePickerYear(context, initialYear: 2026),
      );

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      expect(holder.single, 2026);
    });
  });
}
