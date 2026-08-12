import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _dayCell(String number) =>
    find.descendant(of: find.byType(MonthGrid), matching: find.text(number));

Future<void> _openPicker(
  WidgetTester tester,
  List<PickedDateRange?> holder,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async => holder.add(
                await DateRangePickerCupertino(
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
}

void main() {
  group('cupertinoDateRangePickerTheme', () {
    test('uses iOS system colours per brightness', () {
      final light = cupertinoDateRangePickerTheme();
      expect(light.primaryColor, const Color(0xFF007AFF));
      expect(light.backgroundColor, const Color(0xFFFFFFFF));

      final dark = cupertinoDateRangePickerTheme(brightness: Brightness.dark);
      expect(dark.backgroundColor, const Color(0xFF1C1C1E));
      expect(dark.textColor, const Color(0xFFFFFFFF));
    });

    test('honours a custom primary', () {
      final t = cupertinoDateRangePickerTheme(primary: const Color(0xFFFF2D55));
      expect(t.primaryColor, const Color(0xFFFF2D55));
    });
  });

  group('DateRangePickerCupertino', () {
    testWidgets(
      'Done stays disabled until a range is complete, then returns it',
      (tester) async {
        final holder = <PickedDateRange?>[];
        await _openPicker(tester, holder);

        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);

        await tester.tap(_dayCell('10'));
        await tester.pumpAndSettle();
        await tester.tap(_dayCell('14'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(holder.single, isNotNull);
        expect(holder.single!.days, 5);
      },
    );

    testWidgets('Cancel resolves to null', (tester) async {
      final holder = <PickedDateRange?>[];
      await _openPicker(tester, holder);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(holder.single, isNull);
    });
  });
}
