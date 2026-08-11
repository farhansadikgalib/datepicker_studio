import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  DateRangePickerConfig config = const DateRangePickerConfig(),
  DateRangePickerTheme? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 900,
          child: DateRangePickerView(
            initialMonth: DateTime(2026, 8),
            config: config,
            theme: theme,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('individual preset visibility', () {
    testWidgets('all five show by default', (tester) async {
      await _pump(tester);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
    });

    testWidgets('Last 7 Days can be hidden on its own', (tester) async {
      await _pump(
        tester,
        config: const DateRangePickerConfig(showLast7DaysPreset: false),
      );

      expect(find.text('Last 7 Days'), findsNothing);
      // The rest of the row survives.
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
    });

    testWidgets('Today can be hidden on its own', (tester) async {
      await _pump(
        tester,
        config: const DateRangePickerConfig(showTodayPreset: false),
      );

      expect(find.text('Today'), findsNothing);
      expect(find.text('Last 7 Days'), findsOneWidget);
    });

    testWidgets('each remaining chip can be hidden', (tester) async {
      await _pump(
        tester,
        config: const DateRangePickerConfig(
          showThisWeekPreset: false,
          showThisMonthPreset: false,
          showLast30DaysPreset: false,
        ),
      );

      expect(find.text('This Week'), findsNothing);
      expect(find.text('This Month'), findsNothing);
      expect(find.text('Last 30 Days'), findsNothing);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
    });

    testWidgets('hiding every chip removes the row entirely', (tester) async {
      await _pump(
        tester,
        config: const DateRangePickerConfig(
          showTodayPreset: false,
          showThisWeekPreset: false,
          showThisMonthPreset: false,
          showLast7DaysPreset: false,
          showLast30DaysPreset: false,
        ),
      );

      expect(find.text('Today'), findsNothing);
      expect(find.text('Last 30 Days'), findsNothing);
    });

    testWidgets('an explicit presets list ignores the toggles', (tester) async {
      await _pump(
        tester,
        config: DateRangePickerConfig(
          // The toggle says hide, but an explicit list wins.
          showLast7DaysPreset: false,
          presets: [DateRangePreset.lastDays(7)],
        ),
      );

      expect(find.text('Last 7 Days'), findsOneWidget);
    });

    testWidgets('a hidden chip still works when toggled back on', (
      tester,
    ) async {
      await _pump(
        tester,
        config: const DateRangePickerConfig(showLast7DaysPreset: true),
      );
      expect(find.text('Last 7 Days'), findsOneWidget);
    });

    test('defaults() drops only the chips that are turned off', () {
      final all = DateRangePreset.defaults();
      expect(all.length, 5);

      final trimmed = DateRangePreset.defaults(
        showLast7Days: false,
        showToday: false,
      );
      expect(trimmed.map((p) => p.label), [
        'This Week',
        'This Month',
        'Last 30 Days',
      ]);

      expect(
        DateRangePreset.defaults(
          showToday: false,
          showThisWeek: false,
          showThisMonth: false,
          showLast7Days: false,
          showLast30Days: false,
        ),
        isEmpty,
      );
    });
  });

  group('button radii', () {
    /// Corner radius resolved off the first matching button's [ButtonStyle].
    double radiusOf(WidgetTester tester, Finder button) {
      final style = switch (tester.widget(button)) {
        ElevatedButton(:final style) => style,
        OutlinedButton(:final style) => style,
        TextButton(:final style) => style,
        _ => null,
      };
      final resolved = style?.shape?.resolve({}) as RoundedRectangleBorder?;
      return (resolved!.borderRadius as BorderRadius).topLeft.x;
    }

    testWidgets('action buttons default to radius 10', (tester) async {
      await _pump(tester);

      expect(radiusOf(tester, find.byType(ElevatedButton)), 10);
      expect(radiusOf(tester, find.byType(OutlinedButton)), 10);
    });

    testWidgets('buttonRadius overrides both action buttons', (tester) async {
      await _pump(tester, theme: const DateRangePickerTheme(buttonRadius: 28));

      expect(radiusOf(tester, find.byType(ElevatedButton)), 28);
      expect(radiusOf(tester, find.byType(OutlinedButton)), 28);
    });

    testWidgets('buttonRadius reaches the Clear button too', (tester) async {
      await _pump(
        tester,
        config: const DateRangePickerConfig(showClearButton: true),
        theme: const DateRangePickerTheme(buttonRadius: 4),
      );

      expect(radiusOf(tester, find.byType(TextButton)), 4);
    });

    testWidgets('buttonPadding changes the button height', (tester) async {
      await _pump(tester);
      final defaultHeight = tester.getRect(find.byType(ElevatedButton)).height;

      await _pump(tester, theme: const DateRangePickerTheme(buttonPadding: 24));
      final tallHeight = tester.getRect(find.byType(ElevatedButton)).height;

      expect(tallHeight, greaterThan(defaultHeight));
    });

    testWidgets('chipRadius shapes the preset chips', (tester) async {
      await _pump(tester, theme: const DateRangePickerTheme(chipRadius: 2));

      final chip = tester.widget<Material>(
        find
            .ancestor(of: find.text('Today'), matching: find.byType(Material))
            .first,
      );
      expect((chip.borderRadius as BorderRadius).topLeft.x, 2);
    });

    testWidgets('chipColor and chipBorderColor are independent of the range', (
      tester,
    ) async {
      await _pump(
        tester,
        theme: const DateRangePickerTheme(
          rangeColor: Color(0xFF111111),
          chipColor: Color(0xFF222222),
          chipBorderColor: Color(0xFF333333),
        ),
      );

      final chip = tester.widget<Material>(
        find
            .ancestor(of: find.text('Today'), matching: find.byType(Material))
            .first,
      );
      expect(chip.color, const Color(0xFF222222));

      final container = tester.widget<Container>(
        find
            .ancestor(of: find.text('Today'), matching: find.byType(Container))
            .first,
      );
      final border = (container.decoration as BoxDecoration).border as Border;
      expect(border.top.color, const Color(0xFF333333));
    });

    testWidgets('chipColor falls back to rangeColor when unset', (
      tester,
    ) async {
      await _pump(
        tester,
        theme: const DateRangePickerTheme(rangeColor: Color(0xFF444444)),
      );

      final chip = tester.widget<Material>(
        find
            .ancestor(of: find.text('Today'), matching: find.byType(Material))
            .first,
      );
      expect(chip.color, const Color(0xFF444444));
    });

    testWidgets('timeFieldRadius follows buttonRadius unless set', (
      tester,
    ) async {
      await _pump(
        tester,
        config: const DateRangePickerConfig(mode: DateRangeMode.dateTime),
        theme: const DateRangePickerTheme(buttonRadius: 18),
      );

      final field = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(TimeRow),
              matching: find.byType(Container),
            )
            .first,
      );
      final radius =
          (field.decoration as BoxDecoration).borderRadius as BorderRadius;
      expect(radius.topLeft.x, 18);
    });

    testWidgets('timeFieldRadius can be set on its own', (tester) async {
      await _pump(
        tester,
        config: const DateRangePickerConfig(mode: DateRangeMode.dateTime),
        theme: const DateRangePickerTheme(buttonRadius: 18, timeFieldRadius: 3),
      );

      final field = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(TimeRow),
              matching: find.byType(Container),
            )
            .first,
      );
      final radius =
          (field.decoration as BoxDecoration).borderRadius as BorderRadius;
      expect(radius.topLeft.x, 3);
    });
  });
}
