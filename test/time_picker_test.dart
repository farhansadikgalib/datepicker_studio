import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a button that opens [DateRangePickerTime], appending whatever the
/// picker resolves to onto [holder] once it closes.
Future<void> _pumpOpener(
  WidgetTester tester,
  List<TimeOfDay?> holder, {
  TimeOfDay initial = const TimeOfDay(hour: 9, minute: 30),
  TimePickerStyle? style,
  bool? use24HourFormat,
  int minuteInterval = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                holder.add(
                  await DateRangePickerTime(
                    context,
                    initialTime: initial,
                    style: style,
                    use24HourFormat: use24HourFormat,
                    minuteInterval: minuteInterval,
                  ),
                );
              },
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
  group('DateRangePickerTime', () {
    testWidgets('returns the initial time when confirmed untouched', (
      tester,
    ) async {
      final holder = <TimeOfDay?>[];
      await _pumpOpener(
        tester,
        holder,
        initial: const TimeOfDay(hour: 9, minute: 30),
      );

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(holder.single, const TimeOfDay(hour: 9, minute: 30));
    });

    testWidgets('cancel resolves to null', (tester) async {
      final holder = <TimeOfDay?>[];
      await _pumpOpener(tester, holder);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(holder.single, isNull);
    });

    testWidgets('the AM/PM toggle shifts the result into the afternoon', (
      tester,
    ) async {
      final holder = <TimeOfDay?>[];
      await _pumpOpener(
        tester,
        holder,
        initial: const TimeOfDay(hour: 9, minute: 30),
      );

      await tester.tap(find.text('PM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(holder.single, const TimeOfDay(hour: 21, minute: 30));
    });

    testWidgets('24-hour mode hides the AM/PM toggle', (tester) async {
      final holder = <TimeOfDay?>[];
      await _pumpOpener(
        tester,
        holder,
        use24HourFormat: true,
        initial: const TimeOfDay(hour: 14, minute: 0),
      );

      expect(find.text('AM'), findsNothing);
      expect(find.text('PM'), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(holder.single, const TimeOfDay(hour: 14, minute: 0));
    });

    testWidgets('snaps the initial minute to the interval', (tester) async {
      final holder = <TimeOfDay?>[];
      await _pumpOpener(
        tester,
        holder,
        initial: const TimeOfDay(hour: 10, minute: 7),
        minuteInterval: 15,
      );

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 7 is closest to 0 among 0/15/30/45.
      expect(holder.single, const TimeOfDay(hour: 10, minute: 0));
    });

    testWidgets('a custom style paints the confirm button in the accent', (
      tester,
    ) async {
      final holder = <TimeOfDay?>[];
      const accent = Color(0xFF0D9488);
      await _pumpOpener(
        tester,
        holder,
        style: TimePickerStyle.from(accent: accent),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final background = button.style?.backgroundColor?.resolve({});
      expect(background, accent);
    });
  });
}
