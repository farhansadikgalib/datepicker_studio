import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture screenshots', (tester) async {
    await binding.convertFlutterSurfaceToImage();

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    Future<void> tap(String label) async {
      final finder = find.text(label).first;
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    // Dismiss whatever modal is open, tolerant of timing.
    Future<void> dismiss() async {
      for (final label in const ['Cancel', 'Done']) {
        final f = find.text(label);
        if (f.evaluate().isNotEmpty) {
          await tester.tap(f.first, warnIfMissed: false);
          await tester.pumpAndSettle();
          return;
        }
      }
      // Fallback: tap the scrim above any bottom sheet.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // 1 — the demo home, everything at a glance.
    await shot('01_home');

    // 2 — range bottom sheet + the GIF: watch the highlight grow.
    await tap('Bottom sheet');
    await shot('gif_0');
    await tap('Today');
    await shot('gif_1');
    await tap('This Week');
    await shot('gif_2');
    await tap('This Month');
    await shot('02_range');
    await shot('gif_3');
    await tap('Apply');
    await shot('gif_4');

    // 5 — Cupertino iOS-style modal (captured early, from a clean home).
    await tap('Cupertino');
    await shot('05_cupertino');
    await dismiss();

    // 3 — birthday: opens on the year grid.
    await tap('Birthday');
    await shot('03_birthday');
    await dismiss();

    // 4 — date + time: a time on each endpoint.
    await tap('Date + time');
    await shot('04_datetime');
    await dismiss();

    // 6 — inline calendar with events + week numbers, driven by a chip.
    // Done last so no modal needs dismissing afterwards.
    await tap('Last 7 days');
    await tester.ensureVisible(find.byType(Card).last);
    await shot('06_inline');
  });
}
