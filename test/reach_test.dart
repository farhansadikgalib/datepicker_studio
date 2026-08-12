import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpOpener<T>(
  WidgetTester tester,
  List<T?> holder,
  Future<T?> Function(BuildContext context) open, {
  Size size = const Size(400, 800),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
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
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('DateRangePickerLabels.forLocale', () {
    test('returns a translated bundle for a known language', () {
      final es = DateRangePickerLabels.forLocale('es');
      expect(es.cancel, 'Cancelar');
      expect(es.apply, 'Aplicar');
      expect(es.daysSelected(3), '3 días seleccionados');

      final de = DateRangePickerLabels.forLocale('de_DE');
      expect(de.cancel, 'Abbrechen');
      expect(de.age(1), '1 Jahr');
    });

    test('falls back to English for an unknown language', () {
      final xx = DateRangePickerLabels.forLocale('xx');
      expect(xx.cancel, 'Cancel');
    });

    test('copyWith overrides individual strings', () {
      final labels = DateRangePickerLabels.forLocale(
        'fr',
      ).copyWith(apply: 'Valider');
      expect(labels.apply, 'Valider');
      expect(labels.cancel, 'Annuler');
    });
  });

  group('DateRangePickerTimeRange', () {
    testWidgets('returns the initial start/end when confirmed', (tester) async {
      final holder = <StudioTimeRange?>[];
      await _pumpOpener(
        tester,
        holder,
        (context) => DateRangePickerTimeRange(
          context,
          initialStart: const TimeOfDay(hour: 9, minute: 0),
          initialEnd: const TimeOfDay(hour: 17, minute: 30),
          minuteInterval: 30,
        ),
      );

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(holder.single?.start, const TimeOfDay(hour: 9, minute: 0));
      expect(holder.single?.end, const TimeOfDay(hour: 17, minute: 30));
    });

    testWidgets('cancel resolves to null', (tester) async {
      final holder = <StudioTimeRange?>[];
      await _pumpOpener(
        tester,
        holder,
        (context) => DateRangePickerTimeRange(context),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(holder.single, isNull);
    });
  });

  group('DateRangePickerAdaptive', () {
    testWidgets('uses a dialog on a wide screen', (tester) async {
      final holder = <PickedDateRange?>[];
      await _pumpOpener(
        tester,
        holder,
        (context) => DateRangePickerAdaptive(context),
        size: const Size(900, 700),
      );
      // The dialog path wraps the picker in a Dialog.
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('uses a bottom sheet on a narrow screen', (tester) async {
      final holder = <PickedDateRange?>[];
      await _pumpOpener(
        tester,
        holder,
        (context) => DateRangePickerAdaptive(context),
        size: const Size(360, 700),
      );
      // A modal sheet, not a Dialog.
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(DateRangePickerView), findsOneWidget);
    });
  });
}
