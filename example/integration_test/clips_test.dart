import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Drives each overview item through a selection flow, saving a numbered frame
/// after every step. The driver writes them to disk; a Dart/PIL step downstream
/// stitches each `<clip>_NN.png` group into `<clip>.gif`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture clips', (tester) async {
    await binding.convertFlutterSurfaceToImage();

    Future<void> settle() =>
        tester.pumpAndSettle(const Duration(milliseconds: 300));

    Future<void> frame(String name) async {
      await settle();
      await binding.takeScreenshot(name);
    }

    Future<void> tapText(String label, {bool last = false}) async {
      final f = last ? find.text(label).last : find.text(label).first;
      await tester.tap(f, warnIfMissed: false);
      await settle();
    }

    // Tap a day *inside the open modal's* calendar. The modal route is pushed
    // after home, so its MonthGrid is last in the tree — this disambiguates the
    // day number from the always-alive inline calendar on the home page.
    Future<void> tapDay(String d) async {
      final grids = find.byType(MonthGrid);
      final cell = grids.evaluate().isNotEmpty
          ? find.descendant(of: grids.last, matching: find.text(d))
          : find.text(d);
      await tester.tap(cell.last, warnIfMissed: false);
      await settle();
    }

    Future<void> open(String label) async {
      final f = find.text(label).first;
      await tester.ensureVisible(f);
      await settle();
      await tester.tap(f, warnIfMissed: false);
      await settle();
    }

    // Close any lingering modal so the next clip starts from a clean home.
    Future<void> goHome() async {
      for (var i = 0; i < 4; i++) {
        var acted = false;
        for (final l in const ['Cancel', 'Done']) {
          final f = find.text(l);
          if (f.evaluate().isNotEmpty) {
            await tester.tap(f.first, warnIfMissed: false);
            await settle();
            acted = true;
          }
        }
        if (!acted) break;
      }
    }

    // Run one clip in isolation; a failure never sinks the others.
    Future<void> clip(String name, Future<void> Function() body) async {
      try {
        await body();
      } catch (e) {
        debugPrint('clip "$name" failed: $e');
      }
      await goHome();
    }

    await tester.pumpWidget(const ExampleApp());
    await settle();

    // 1 — range bottom sheet: tap two days, apply.
    await clip('range', () async {
      await open('Bottom sheet');
      await frame('range_00');
      await tapDay('9');
      await frame('range_01');
      await tapDay('18');
      await frame('range_02');
      await tapText('Apply');
      await frame('range_03');
    });

    // 2 — dialog, two months: a span (collapses to one month on a phone).
    await clip('dialog', () async {
      await open('Dialog, two months');
      await frame('dialog_00');
      await tapDay('6');
      await frame('dialog_01');
      await tapDay('24');
      await frame('dialog_02');
      await tapText('Apply');
      await frame('dialog_03');
    });

    // 3 — Cupertino modal: pick a span, Done.
    await clip('cupertino', () async {
      await open('Cupertino');
      await frame('cupertino_00');
      await tapDay('9');
      await frame('cupertino_01');
      await tapDay('18');
      await frame('cupertino_02');
      await tapText('Done');
      await frame('cupertino_03');
    });

    // 4 — single date: one tap auto-applies.
    await clip('single', () async {
      await open('Single date');
      await frame('single_00');
      await tapDay('15');
      await frame('single_01');
    });

    // 5 — birthday: year -> month -> day.
    await clip('birthday', () async {
      await open('Birthday');
      await frame('birthday_00');
      await tester.scrollUntilVisible(
        find.text('2000'),
        -140,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 40,
      );
      await settle();
      await tapText('2000');
      await frame('birthday_01');
      await tapText('Jun');
      await frame('birthday_02');
      await tapDay('15');
      await frame('birthday_03');
      if (find.text('Apply').evaluate().isNotEmpty) await tapText('Apply');
      await frame('birthday_04');
    });

    // 6 — date + time: a span, times on each end.
    await clip('datetime', () async {
      await open('Date + time');
      await frame('datetime_00');
      await tapDay('10');
      await frame('datetime_01');
      await tapDay('20');
      await frame('datetime_02');
    });

    // 7 — multiple dates: toggle several.
    await clip('multiple', () async {
      await open('Multiple dates');
      await frame('multiple_00');
      for (final d in const ['4', '9', '14', '20', '26']) {
        await tapDay(d);
        await frame('multiple_${d.padLeft(2, '0')}');
      }
      if (find.text('Apply').evaluate().isNotEmpty) await tapText('Apply');
      await frame('multiple_99');
    });

    // 8 — month picker.
    await clip('month', () async {
      await open('Month');
      await frame('month_00');
      await tapText('Mar');
      await frame('month_01');
    });

    // 9 — year picker.
    await clip('year', () async {
      await open('Year');
      await frame('year_00');
      await tester.scrollUntilVisible(
        find.text('2030'),
        140,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 40,
      );
      await settle();
      await tapText('2030');
      await frame('year_01');
    });

    // 10 — time wheel: drag it.
    await clip('time', () async {
      await open('Time');
      await frame('time_00');
      final wheel = find.byType(ListWheelScrollView).first;
      for (var i = 1; i <= 3; i++) {
        await tester.drag(wheel, const Offset(0, -60));
        await frame('time_0$i');
      }
    });

    // 11 — duration wheel: drag it.
    await clip('duration', () async {
      await open('Duration');
      await frame('duration_00');
      final wheel = find.byType(ListWheelScrollView).first;
      for (var i = 1; i <= 3; i++) {
        await tester.drag(wheel, const Offset(0, -60));
        await frame('duration_0$i');
      }
    });
  });
}
