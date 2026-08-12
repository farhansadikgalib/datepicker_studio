import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _dayCell(String number) =>
    find.descendant(of: find.byType(MonthGrid), matching: find.text(number));

void main() {
  group('PickedDates', () {
    test('normalises, de-duplicates, and sorts', () {
      final dates = PickedDates([
        DateTime(2026, 8, 12, 9),
        DateTime(2026, 8, 5),
        DateTime(2026, 8, 12), // duplicate day
      ]);
      expect(dates.count, 2);
      expect(dates.dates.first, DateTime(2026, 8, 5));
      expect(dates.dates.last, DateTime(2026, 8, 12));
    });

    test('toggle adds then removes a day', () {
      var d = PickedDates.empty();
      d = d.toggle(DateTime(2026, 8, 5));
      expect(d.contains(DateTime(2026, 8, 5)), isTrue);
      d = d.toggle(DateTime(2026, 8, 5));
      expect(d.contains(DateTime(2026, 8, 5)), isFalse);
    });

    test('equality is day-precision and order-independent', () {
      expect(
        PickedDates([DateTime(2026, 8, 5), DateTime(2026, 8, 12)]),
        PickedDates([DateTime(2026, 8, 12), DateTime(2026, 8, 5, 3)]),
      );
    });

    test('JSON round-trips', () {
      final d = PickedDates([DateTime(2026, 8, 5), DateTime(2026, 8, 12)]);
      expect(PickedDates.fromJson(d.toJson()), d);
    });
  });

  group('multiple mode in the view', () {
    testWidgets('each tap toggles a day and reports the set', (tester) async {
      PickedDates? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: DateRangePickerView(
                initialMonth: DateTime(2026, 8),
                config: const DateRangePickerConfig(
                  mode: DateRangeMode.multiple,
                ),
                onDatesChanged: (d) => changed = d,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_dayCell('5'));
      await tester.pumpAndSettle();
      await tester.tap(_dayCell('12'));
      await tester.pumpAndSettle();
      expect(changed!.count, 2);

      // Tapping 5 again removes it.
      await tester.tap(_dayCell('5'));
      await tester.pumpAndSettle();
      expect(changed!.count, 1);
      expect(changed!.contains(DateTime(2026, 8, 12)), isTrue);
    });
  });

  group('DateRangePickerMultiple', () {
    testWidgets('returns the applied set', (tester) async {
      final holder = <PickedDates?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async => holder.add(
                    await DateRangePickerMultiple(
                      context,
                      initialMonth: DateTime(2026, 8),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(_dayCell('9'));
      await tester.pumpAndSettle();
      await tester.tap(_dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(holder.single?.count, 2);
    });
  });
}
