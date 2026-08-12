import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

InkWell _fieldInkWell(WidgetTester tester) => tester.widget<InkWell>(
  find.ancestor(
    of: find.byType(InputDecorator),
    matching: find.byType(InkWell),
  ),
);

void main() {
  group('DateRangeField customization', () {
    testWidgets('applies a custom borderRadius to the tap ripple', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateRangeField(
              value: null,
              onChanged: (_) {},
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );

      expect(_fieldInkWell(tester).borderRadius, BorderRadius.circular(20));
    });

    testWidgets('rounds the default outline with borderRadius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateRangeField(
              value: null,
              onChanged: (_) {},
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      );

      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      final border = decorator.decoration.border as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('applies a custom textStyle to the value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateRangeField(
              value: PickedDateRange(
                DateTime(2026, 8, 5),
                DateTime(2026, 8, 12),
              ),
              onChanged: (_) {},
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(
        find.byWidgetPredicate((w) => w is Text && w.style?.fontSize == 22),
      );
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('a caller-supplied border wins over borderRadius', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateRangeField(
              value: null,
              onChanged: (_) {},
              borderRadius: BorderRadius.circular(20),
              decoration: const InputDecoration(border: UnderlineInputBorder()),
            ),
          ),
        ),
      );

      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(decorator.decoration.border, isA<UnderlineInputBorder>());
      // The ripple still follows borderRadius.
      expect(_fieldInkWell(tester).borderRadius, BorderRadius.circular(20));
    });
  });

  group('DateRangeFormField customization', () {
    testWidgets('forwards borderRadius to the field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateRangeFormField(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );

      expect(_fieldInkWell(tester).borderRadius, BorderRadius.circular(16));
    });
  });
}
