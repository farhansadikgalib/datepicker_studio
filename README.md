# datepicker_studio

A themeable date picker toolkit for Flutter — range, single, birthday, and date-time modes across a bottom sheet, dialog, inline calendar, and form field.

Depends only on `intl`.

```yaml
dependencies:
  datepicker_studio: ^1.0.0
```

## Quick start

```dart
import 'package:datepicker_studio/datepicker_studio.dart';

final range = await showDateRangeSheet(context);   // null if cancelled
print('${range?.start} → ${range?.end} (${range?.days} days)');
```

Presets, month paging, a year picker, and a day count are on by default, and colours come from your `ThemeData`.

## Entry points

| | Use for |
|---|---|
| `showDateRangeSheet(context)` | Modal bottom sheet — phones |
| `showDateRangeDialog(context)` | Centred dialog — tablet, desktop, web |
| `DateRangePickerView(...)` | Inline, in your own layout |
| `DateRangeField(...)` | Tappable read-only form field |

```dart
// Inline, driven by onChanged instead of an Apply button
DateRangePickerView(showActions: false, onChanged: (r) => setState(() => _range = r))

// Form field
DateRangeField(value: _range, onChanged: (r) => setState(() => _range = r))
```

## Modes

```dart
DateRangeMode.range      // default: a span
DateRangeMode.single     // one day
DateRangeMode.birthday   // year → month → day, maxDate defaults to today
DateRangeMode.dateTime   // span + a time on each endpoint
```

**birthday** opens on the year grid so reaching 1985 is three taps, and shows the age:

```dart
final dob = await showDateRangeSheet(
  context,
  config: const DateRangePickerConfig(mode: DateRangeMode.birthday),
);
dob?.ageInYears();   // 36
```

**dateTime** adds a time field per endpoint, and the result carries real hours and minutes:

```dart
final shift = await showDateRangeSheet(
  context,
  config: const DateRangePickerConfig(
    mode: DateRangeMode.dateTime,
    minuteInterval: 15,      // :00 :15 :30 :45
    use24HourFormat: true,   // defaults to the locale
  ),
);
shift!.start;      // 2026-08-05 09:30
shift.duration;    // 8:15:00
```

`hasTime` tells the two apart — every other mode is midnight-normalised, and a timed range never compares equal to an untimed one.

## Configuration

All behaviour lives on `DateRangePickerConfig`:

| Option | Default | Effect |
|---|---|---|
| `mode` | `range` | See above |
| `minDate` / `maxDate` | unbounded | Out-of-range days are struck through |
| `minRangeLength` / `maxRangeLength` | none | Length limits in days, inclusive |
| `selectableDayPredicate` | none | Per-day filter for holidays, weekends, bookings |
| `firstDayOfWeek` | `monday` | First calendar column |
| `visibleMonths` | `1` | Months side by side; collapses on narrow screens |
| `autoApply` | `false` | Confirm without the Apply button |
| `presets` | five chips | `[]` hides the row entirely |
| `showTodayPreset` / `showLast7DaysPreset` / … | `true` | Hide individual default chips |
| `locale` | ambient | Month and weekday names |
| `enableYearPicker` / `enableSwipe` | `true` | Tap the title for years; swipe to page |
| `showHeader` / `showDayCount` / `showClearButton` | `true`/`true`/`false` | Chrome toggles |
| `minuteInterval` / `use24HourFormat` | `1` / locale | `dateTime` mode only |

```dart
DateRangePickerConfig(
  minDate: DateTime(2024),
  maxDate: DateTime.now(),
  maxRangeLength: 90,
  selectableDayPredicate: (d) =>          // weekdays only
      d.weekday != DateTime.saturday && d.weekday != DateTime.sunday,
)
```

## Presets

Built in: `today`, `yesterday`, `thisWeek`, `lastWeek`, `thisMonth`, `lastMonth`, `thisYear`, `lastDays(n)`, `nextDays(n)`. All are clamped to `minDate`/`maxDate` automatically.

```dart
// Custom chips — build is just a function of "now"
presets: [
  DateRangePreset.lastDays(7),
  DateRangePreset(
    label: 'Q1',
    build: (now) => PickedDateRange(DateTime(now.year), DateTime(now.year, 3, 31)),
  ),
]

// Or keep the default row and drop one chip
DateRangePickerConfig(showLast7DaysPreset: false)
```

Toggles apply only to the default row; an explicit `presets` list is used as given.

## Theming

Unset fields resolve from `Theme.of(context)`, so light and dark work out of the box.

```dart
theme: DateRangePickerTheme.from(primary: const Color(0xFF0D9488))   // one colour

theme: const DateRangePickerTheme(                                   // or all of them
  primaryColor: Color(0xFF4F46E5),   // endpoints, active header, Apply
  rangeColor: Color(0x1A4F46E5),     // the in-between band
  todayColor: Color(0xFFFBBF24),     // today's ring
  buttonRadius: 26,                  // Cancel / Apply / Clear
  chipRadius: 4,                     // preset chips
  dayExtent: 44,
)
```

Colours: `primaryColor`, `onPrimaryColor`, `rangeColor`, `onRangeColor`, `backgroundColor`, `textColor`, `mutedTextColor`, `disabledColor`, `borderColor`, `todayColor`, `chipColor`, `chipBorderColor`.

Shape and text: `surfaceRadius`, `dayRadius`, `buttonRadius`, `chipRadius`, `timeFieldRadius`, `buttonPadding`, `dayExtent`, `padding`, plus six `TextStyle` slots.

## Localisation

Month and weekday names follow the ambient locale or `config.locale`. UI strings are plain fields:

```dart
DateRangePickerConfig(
  locale: 'de',
  labels: DateRangePickerLabels(
    from: 'Von',
    to: 'Bis',
    apply: 'Übernehmen',
    daysSelected: (d) => '$d Tage ausgewählt',
  ),
)
```

## PickedDateRange

```dart
range.start / range.end     // sorted; midnight unless hasTime
range.days                  // inclusive count — a single day is 1
range.duration              // elapsed time between endpoints
range.hasTime               // true only in dateTime mode
range.startTime / endTime   // TimeOfDay on each endpoint
range.ageInYears()          // whole years since start
range.isSingleDay
range.contains(day)
range.toList()              // every day in the range
range.toDateTimeRange()     // Flutter's built-in type
```

Endpoints are sorted, so `PickedDateRange(later, earlier)` is safe.

## Example

A runnable demo of every entry point and mode lives in [`example/`](example/lib/main.dart).

## License

MIT © [Farhan Sadik Galib](https://farhansadikgalib.com)
