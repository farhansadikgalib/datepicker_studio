// Compile-checks the code samples in README.md. Not behavioural — if this file
// stops compiling, a snippet in the README is wrong.
import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PickedDateRange? _range;

void main() {
  test('README snippets compile', () {
    // "Show it your way"
    DateRangePickerView(showActions: false, onChanged: (r) => _range = r);
    DateRangeField(value: _range, onChanged: (r) => _range = r);

    // "Pick something else"
    const DateRangePickerConfig(mode: DateRangeMode.single);
    const DateRangePickerConfig(mode: DateRangeMode.birthday);
    const DateRangePickerConfig(mode: DateRangeMode.dateTime);
    const DateRangePickerConfig(
      mode: DateRangeMode.dateTime,
      minuteInterval: 15,
    );

    // "Common recipes"
    DateRangePickerConfig(
      minDate: DateTime.now().subtract(const Duration(days: 365)),
      maxDate: DateTime.now(),
    );
    DateRangePickerConfig(
      selectableDayPredicate: (day) =>
          day.weekday != DateTime.saturday && day.weekday != DateTime.sunday,
    );
    const DateRangePickerConfig(minRangeLength: 2, maxRangeLength: 30);
    const DateRangePickerConfig(autoApply: true);
    const DateRangePickerConfig(visibleMonths: 2);

    // "Preset chips"
    const DateRangePickerConfig(showLast7DaysPreset: false);
    const DateRangePickerConfig(presets: []);
    DateRangePickerConfig(
      presets: [
        DateRangePreset.lastDays(90),
        DateRangePreset(
          label: 'Q1',
          build: (now) =>
              PickedDateRange(DateTime(now.year), DateTime(now.year, 3, 31)),
        ),
      ],
    );
    // Every preset named as "ready-made" must exist.
    DateRangePreset.today();
    DateRangePreset.yesterday();
    DateRangePreset.thisWeek();
    DateRangePreset.lastWeek();
    DateRangePreset.thisMonth();
    DateRangePreset.lastMonth();
    DateRangePreset.thisYear();
    DateRangePreset.lastDays(7);
    DateRangePreset.nextDays(7);

    // "Make it yours"
    DateRangePickerTheme.from(primary: Colors.teal);
    const DateRangePickerTheme(
      primaryColor: Color(0xFF4F46E5),
      rangeColor: Color(0x1A4F46E5),
      todayColor: Color(0xFFFBBF24),
      dayRadius: 10,
      buttonRadius: 26,
      dayExtent: 44,
    );

    // "Localisation"
    DateRangePickerConfig(
      locale: 'en',
      labels: DateRangePickerLabels(
        from: 'From',
        to: 'To',
        apply: 'Apply',
        cancel: 'Cancel',
        daysSelected: (d) => d == 1 ? '1 day selected' : '$d days selected',
      ),
    );

    // The README presents those as the defaults — keep that honest.
    const defaults = DateRangePickerLabels();
    expect(defaults.from, 'From');
    expect(defaults.to, 'To');
    expect(defaults.apply, 'Apply');
    expect(defaults.cancel, 'Cancel');
    expect(defaults.daysSelected(1), '1 day selected');
    expect(defaults.daysSelected(8), '8 days selected');

    // "What you get back"
    final range = PickedDateRange(DateTime(2026, 8, 5), DateTime(2026, 8, 12));
    range.start;
    range.end;
    range.days;
    range.duration;
    range.contains(DateTime(2026, 8, 6));
    range.toList();
    range.toDateTimeRange();
    range.hasTime;
    range.startTime;
    range.endTime;
    range.ageInYears();
    range.isSingleDay;

    // The README quotes these two results — keep them honest.
    expect(range.days, 8);
    expect(
      PickedDateRange.withTime(
        DateTime(2026, 8, 5, 9, 30),
        DateTime(2026, 8, 5, 17, 45),
      ).duration,
      const Duration(hours: 8, minutes: 15),
    );
  });
}
