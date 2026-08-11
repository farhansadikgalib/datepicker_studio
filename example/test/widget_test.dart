import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the demo page opens the sheet and applies a range', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // The page already hosts an inline picker, so count before opening.
    final inlineCount = find.byType(DateRangePickerView).evaluate().length;

    await tester.tap(find.text('Bottom sheet'));
    await tester.pumpAndSettle();
    expect(
      find.byType(DateRangePickerView),
      findsNWidgets(inlineCount + 1),
      reason: 'the sheet adds one more picker',
    );

    // Target the sheet's chip specifically: the inline picker below also has
    // a preset row and comes first in the widget tree.
    await tester.tap(
      find.descendant(
        of: find.byType(DateRangePickerView).last,
        matching: find.text('Last 7 Days'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.textContaining('7 days'), findsWidgets);
  });

  testWidgets('the inline summary appears after scrolling to it', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Nothing selected'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing selected'), findsOneWidget);
  });
}
