// Compile-checks the code samples in README.md. Not behavioural — if this file
// stops compiling, a snippet in the README is wrong.
import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PickedDateRange? _range;

void main() {
  test('README snippets compile', () {
    // Configuration sample.
    DateRangePickerConfig(
      minDate: DateTime(2024),
      maxDate: DateTime.now(),
      maxRangeLength: 90,
      selectableDayPredicate: (d) =>
          d.weekday != DateTime.saturday && d.weekday != DateTime.sunday,
    );

    // Modes.
    const DateRangePickerConfig(mode: DateRangeMode.birthday);
    const DateRangePickerConfig(
      mode: DateRangeMode.dateTime,
      minuteInterval: 15,
      use24HourFormat: true,
    );

    // Presets.
    DateRangePickerConfig(
      presets: [
        DateRangePreset.lastDays(7),
        DateRangePreset(
          label: 'Q1',
          build: (now) =>
              PickedDateRange(DateTime(now.year), DateTime(now.year, 3, 31)),
        ),
      ],
    );
    const DateRangePickerConfig(showLast7DaysPreset: false);

    // Theming.
    DateRangePickerTheme.from(primary: const Color(0xFF0D9488));
    const DateRangePickerTheme(
      primaryColor: Color(0xFF4F46E5),
      rangeColor: Color(0x1A4F46E5),
      todayColor: Color(0xFFFBBF24),
      buttonRadius: 26,
      chipRadius: 4,
      dayExtent: 44,
    );

    // Localisation.
    DateRangePickerConfig(
      locale: 'de',
      labels: DateRangePickerLabels(
        from: 'Von',
        to: 'Bis',
        apply: 'Übernehmen',
        daysSelected: (d) => '$d Tage ausgewählt',
      ),
    );

    // PickedDateRange surface.
    final range = PickedDateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 9));
    range.start;
    range.end;
    range.days;
    range.duration;
    range.hasTime;
    range.startTime;
    range.endTime;
    range.ageInYears();
    range.isSingleDay;
    range.contains(DateTime(2026, 8, 5));
    range.toList();
    range.toDateTimeRange();

    // Widget entry points.
    DateRangePickerView(
      showActions: false,
      onChanged: (r) => _range = r,
    );
    DateRangeField(value: _range, onChanged: (r) => _range = r);

    expect(true, isTrue);
  });
}
