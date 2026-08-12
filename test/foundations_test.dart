import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _dayCell(String number) =>
    find.descendant(of: find.byType(MonthGrid), matching: find.text(number));

Future<void> _pumpView(
  WidgetTester tester, {
  DateRangePickerController? controller,
  DateRangePickerConfig config = const DateRangePickerConfig(),
  ValueChanged<DateTime>? onMonthChanged,
  ValueChanged<String?>? onError,
  ValueChanged<PickedDateRange?>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: DateRangePickerView(
            initialMonth: DateTime(2026, 8),
            controller: controller,
            config: config,
            onMonthChanged: onMonthChanged,
            onError: onError,
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PickedDateRange JSON', () {
    test('round-trips a plain range', () {
      final range = PickedDateRange(
        DateTime(2026, 8, 5),
        DateTime(2026, 8, 12),
      );
      final restored = PickedDateRange.fromJson(range.toJson());
      expect(restored, range);
      expect(restored.hasTime, isFalse);
    });

    test('round-trips a timed range to the minute', () {
      final range = PickedDateRange.withTime(
        DateTime(2026, 8, 5, 9, 30),
        DateTime(2026, 8, 5, 17, 45),
      );
      final restored = PickedDateRange.fromJson(range.toJson());
      expect(restored, range);
      expect(restored.hasTime, isTrue);
      expect(restored.startTime, const TimeOfDay(hour: 9, minute: 30));
    });

    test('defaults hasTime to false when the key is absent', () {
      final restored = PickedDateRange.fromJson({
        'start': '2026-08-05T00:00:00.000',
        'end': '2026-08-12T00:00:00.000',
      });
      expect(restored.hasTime, isFalse);
    });
  });

  group('theme & style presets', () {
    test('DateRangePickerTheme presets set their signature radii', () {
      expect(DateRangePickerTheme.minimal().dayRadius, 8);
      expect(DateRangePickerTheme.rounded().surfaceRadius, 28);
      expect(DateRangePickerTheme.compact().dayExtent, 34);
      expect(
        DateRangePickerTheme.rounded(
          primary: const Color(0xFF00FF00),
        ).primaryColor,
        const Color(0xFF00FF00),
      );
    });

    test('TimePickerStyle presets set their signature values', () {
      expect(TimePickerStyle.minimal().borderRadius, 12);
      expect(TimePickerStyle.rounded().itemExtent, 50);
      expect(TimePickerStyle.compact().borderRadius, 14);
    });
  });

  group('DateRangePickerController', () {
    testWidgets('reads and sets the selection', (tester) async {
      final controller = DateRangePickerController();
      addTearDown(controller.dispose);

      await _pumpView(tester, controller: controller);
      expect(controller.value, isNull);
      expect(controller.isAttached, isTrue);

      controller.setRange(
        PickedDateRange(DateTime(2026, 8, 5), DateTime(2026, 8, 12)),
      );
      await tester.pumpAndSettle();

      expect(controller.value?.start, DateTime(2026, 8, 5));
      expect(controller.value?.end, DateTime(2026, 8, 12));
    });

    testWidgets('clear() empties the selection', (tester) async {
      final controller = DateRangePickerController();
      addTearDown(controller.dispose);

      await _pumpView(tester, controller: controller);
      controller.setRange(PickedDateRange.single(DateTime(2026, 8, 5)));
      await tester.pumpAndSettle();
      expect(controller.value, isNotNull);

      controller.clear();
      await tester.pumpAndSettle();
      expect(controller.value, isNull);
    });

    testWidgets('notifies listeners on selection change', (tester) async {
      final controller = DateRangePickerController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await _pumpView(tester, controller: controller);
      controller.setRange(PickedDateRange.single(DateTime(2026, 8, 9)));
      await tester.pumpAndSettle();

      expect(notifications, greaterThan(0));
    });

    testWidgets('goToMonth moves the focused month', (tester) async {
      final controller = DateRangePickerController();
      addTearDown(controller.dispose);

      await _pumpView(tester, controller: controller);
      expect(controller.focusedMonth, DateTime(2026, 8));

      controller.goToMonth(DateTime(2027, 1));
      await tester.pumpAndSettle();
      expect(controller.focusedMonth, DateTime(2027, 1));
    });

    test('commands are safe no-ops while detached', () {
      final controller = DateRangePickerController();
      addTearDown(controller.dispose);
      expect(controller.isAttached, isFalse);
      expect(controller.value, isNull);
      expect(controller.focusedMonth, isNull);
      // Should not throw.
      controller.setRange(PickedDateRange.single(DateTime(2026, 1, 1)));
      controller.clear();
      controller.goToToday();
    });
  });

  group('view callbacks', () {
    testWidgets('onMonthChanged fires when navigating', (tester) async {
      DateTime? month;
      final controller = DateRangePickerController();
      addTearDown(controller.dispose);

      await _pumpView(
        tester,
        controller: controller,
        onMonthChanged: (m) => month = m,
      );
      controller.goToMonth(DateTime(2027, 3));
      await tester.pumpAndSettle();

      expect(month, DateTime(2027, 3));
    });

    testWidgets('onError reports and clears constraint violations', (
      tester,
    ) async {
      final errors = <String?>[];
      await _pumpView(
        tester,
        config: const DateRangePickerConfig(minRangeLength: 5),
        onError: (e) => errors.add(e),
      );

      // A 2-day range is too short → an error surfaces.
      await tester.tap(_dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(_dayCell('11'));
      await tester.pumpAndSettle();
      expect(errors.last, isNotNull);

      // Extending it past the minimum clears the error.
      await tester.tap(_dayCell('10'));
      await tester.pumpAndSettle();
      await tester.tap(_dayCell('20'));
      await tester.pumpAndSettle();
      expect(errors.last, isNull);
    });
  });

  group('DateRangeFormField', () {
    testWidgets('validates and saves through a Form', (tester) async {
      final formKey = GlobalKey<FormState>();
      PickedDateRange? saved;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: DateRangeFormField(
                initialValue: PickedDateRange.single(DateTime(2026, 8, 5)),
                validator: (r) => r == null ? 'required' : null,
                onSaved: (r) => saved = r,
              ),
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(saved, isNotNull);
    });

    testWidgets('surfaces the validator message as error text', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: DateRangeFormField(
                validator: (r) => r == null ? 'Pick a period' : null,
              ),
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Pick a period'), findsOneWidget);
    });
  });
}
