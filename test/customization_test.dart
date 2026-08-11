import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every colour slot set to a distinct value, so a mix-up between two of them
/// shows up as a failed lookup rather than a coincidental match.
const _theme = DateRangePickerTheme(
  primaryColor: Color(0xFFEE0001),
  onPrimaryColor: Color(0xFFEE0002),
  rangeColor: Color(0xFFEE0003),
  onRangeColor: Color(0xFFEE0004),
  backgroundColor: Color(0xFFEE0005),
  textColor: Color(0xFFEE0006),
  mutedTextColor: Color(0xFFEE0007),
  disabledColor: Color(0xFFEE0008),
  borderColor: Color(0xFFEE0009),
  todayColor: Color(0xFFEE000A),
);

Finder _dayCell(String number) =>
    find.descendant(of: find.byType(MonthGrid), matching: find.text(number));

/// Colour actually painted behind a day cell's pill.
Color? _pillColor(WidgetTester tester, String day) {
  final stack = find
      .ancestor(of: _dayCell(day), matching: find.byType(Stack))
      .first;
  final pill = find
      .descendant(
        of: stack,
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      )
      .first;
  final decoration = tester.widget<Container>(pill).decoration as BoxDecoration;
  return decoration.color;
}

/// Colour of a day cell's rendered text.
Color? _dayTextColor(WidgetTester tester, String day) =>
    tester.widget<Text>(_dayCell(day)).style?.color;

Future<void> _pump(
  WidgetTester tester, {
  DateRangePickerConfig config = const DateRangePickerConfig(),
  PickedDateRange? range,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: DateRangePickerView(
            initialMonth: DateTime(2026, 8),
            initialRange: range,
            theme: _theme,
            config: config,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('every colour slot is honoured', () {
    testWidgets('endpoints use primary/onPrimary', (tester) async {
      await _pump(
        tester,
        range: PickedDateRange(DateTime(2026, 8, 10), DateTime(2026, 8, 14)),
      );

      expect(_pillColor(tester, '10'), _theme.primaryColor);
      expect(_pillColor(tester, '14'), _theme.primaryColor);
      expect(_dayTextColor(tester, '10'), _theme.onPrimaryColor);
      expect(_dayTextColor(tester, '14'), _theme.onPrimaryColor);
    });

    testWidgets('in-range days use rangeColor/onRangeColor', (tester) async {
      await _pump(
        tester,
        range: PickedDateRange(DateTime(2026, 8, 10), DateTime(2026, 8, 14)),
      );

      final band = find
          .descendant(
            of: find
                .ancestor(of: _dayCell('12'), matching: find.byType(Stack))
                .first,
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.color != null,
            ),
          )
          .first;

      expect(tester.widget<Container>(band).color, _theme.rangeColor);
      expect(_dayTextColor(tester, '12'), _theme.onRangeColor);
    });

    testWidgets('unselected days use textColor', (tester) async {
      await _pump(tester);
      expect(_dayTextColor(tester, '20'), _theme.textColor);
    });

    testWidgets('out-of-bounds days use disabledColor', (tester) async {
      await _pump(
        tester,
        config: DateRangePickerConfig(minDate: DateTime(2026, 8, 15)),
      );
      expect(_dayTextColor(tester, '10'), _theme.disabledColor);
    });

    testWidgets('today uses todayColor for its ring', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: DateRangePickerView(theme: _theme),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final today = DateTime.now();
      final stack = find
          .ancestor(of: _dayCell('${today.day}'), matching: find.byType(Stack))
          .first;
      final pill = find
          .descendant(
            of: stack,
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration,
            ),
          )
          .first;
      final border =
          (tester.widget<Container>(pill).decoration as BoxDecoration).border;

      expect(border, isNotNull);
      expect((border as Border).top.color, _theme.todayColor);
    });

    testWidgets('weekday headers use mutedTextColor', (tester) async {
      await _pump(tester);
      final mon = tester.widget<Text>(
        find.descendant(of: find.byType(MonthGrid), matching: find.text('Mon')),
      );
      expect(mon.style?.color, _theme.mutedTextColor);
    });

    testWidgets('the sheet surface uses backgroundColor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DateRangePickerSheet(context, theme: _theme),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final surface = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(DateRangePickerView),
              matching: find.byType(Container),
            )
            .last,
      );
      expect(
        (surface.decoration as BoxDecoration).color,
        _theme.backgroundColor,
      );
    });
  });

  group('custom date ranges', () {
    testWidgets('a fully custom preset applies its own range', (tester) async {
      PickedDateRange? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: DateRangePickerView(
                initialMonth: DateTime(2026, 8),
                onChanged: (r) => changed = r,
                config: DateRangePickerConfig(
                  presets: [
                    DateRangePreset(
                      label: 'Fiscal Q3',
                      build: (now) => PickedDateRange(
                        DateTime(now.year, 7, 1),
                        DateTime(now.year, 9, 30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fiscal Q3'));
      await tester.pumpAndSettle();

      expect(changed!.start, DateTime(DateTime.now().year, 7, 1));
      expect(changed!.end, DateTime(DateTime.now().year, 9, 30));
    });

    testWidgets('a custom preset is clamped to the configured bounds', (
      tester,
    ) async {
      PickedDateRange? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: DateRangePickerView(
                initialMonth: DateTime(2026, 8),
                onChanged: (r) => changed = r,
                config: DateRangePickerConfig(
                  minDate: DateTime(DateTime.now().year, 8, 1),
                  maxDate: DateTime(DateTime.now().year, 8, 31),
                  presets: [
                    DateRangePreset(
                      label: 'Whole year',
                      build: (now) => PickedDateRange(
                        DateTime(now.year, 1, 1),
                        DateTime(now.year, 12, 31),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Whole year'));
      await tester.pumpAndSettle();

      expect(changed!.start, DateTime(DateTime.now().year, 8, 1));
      expect(changed!.end, DateTime(DateTime.now().year, 8, 31));
    });

    testWidgets('presets can be mixed with built-ins', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: DateRangePickerView(
                initialMonth: DateTime(2026, 8),
                config: DateRangePickerConfig(
                  presets: [
                    DateRangePreset.today(),
                    DateRangePreset.lastDays(45),
                    DateRangePreset(
                      label: 'Since launch',
                      build: (now) =>
                          PickedDateRange(DateTime(2024, 3, 5), now),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Last 45 Days'), findsOneWidget);
      expect(find.text('Since launch'), findsOneWidget);
    });
  });
}
