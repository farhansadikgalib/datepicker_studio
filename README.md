<p align="center">
  <img src="assets/logo.png" alt="datepicker_studio logo" width="160" height="160">
</p>

<h1 align="center">datepicker_studio</h1>

<p align="center">
  A date picker for Flutter that matches your app's theme.<br>
  Ranges, single days, birthdays, and date-times — as a sheet, dialog, inline calendar, or field.
</p>

<p align="center">
  <a href="https://pub.dev/packages/datepicker_studio"><img src="https://img.shields.io/pub/v/datepicker_studio.svg" alt="pub package"></a>
  <a href="https://pub.dev/packages/datepicker_studio/score"><img src="https://img.shields.io/pub/points/datepicker_studio" alt="pub points"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT license"></a>
</p>

---

- **4 modes** — range, single day, birthday, date + time
- **4 ways to show it** — bottom sheet, dialog, inline, form field
- **Themed by default** — follows your `ThemeData` in light and dark
- **Rules that hold** — min/max dates, length limits, per-day filters
- **Preset chips** — nine built in, or write your own
- **One dependency** — `intl`, pulled in automatically

## Quick start

```yaml
dependencies:
  datepicker_studio: ^2.0.0
```

```dart
import 'package:datepicker_studio/datepicker_studio.dart';

final range = await DateRangePickerSheet(context);   // null if cancelled

print('${range?.start} → ${range?.end}');   // 2026-08-05 → 2026-08-12
print('${range?.days} days');               // 8 days
```

That's the whole setup — preset chips, month swiping, a year picker, and your app's colours, out of the box.

Three other ways to show it:

```dart
showDateRangeDialog(context);                                    // tablet, desktop, web
DateRangePickerView(showActions: false, onChanged: (r) => ...)   // inline
DateRangeField(value: _range, onChanged: (r) => ...)             // form field
```

Need just a time? The same custom wheel picker is available on its own:

```dart
final time = await showStudioTimePicker(
  context,
  initialTime: TimeOfDay.now(),
  style: TimePickerStyle.from(accent: Colors.indigo),   // colours are yours
  minuteInterval: 5,
);
```

## Modes

Set with `config: DateRangePickerConfig(mode: DateRangeMode.birthday)`.

| Mode | Gives you |
|---|---|
| `range` | A span. The default. |
| `single` | One day |
| `birthday` | Opens on the year grid, blocks future dates, adds `range.ageInYears()` |
| `dateTime` | A time on each end — `range.start` → `2026-08-05 09:30`, `range.duration` → `8:15:00` |

## Options

```dart
DateRangePickerConfig(
  minDate: DateTime.now().subtract(const Duration(days: 365)),
  maxDate: DateTime.now(),
  maxRangeLength: 30,
  selectableDayPredicate: (day) =>          // no weekends
      day.weekday != DateTime.saturday && day.weekday != DateTime.sunday,
)
```

| Option | Does |
|---|---|
| `minDate` / `maxDate` | Bounds; outside days are greyed out |
| `minRangeLength` / `maxRangeLength` | Length limits, enforced while picking |
| `selectableDayPredicate` | Per-day filter — weekends, holidays, booked dates |
| `autoApply` | Close as soon as they've chosen |
| `visibleMonths` | Months side by side; collapses on narrow screens |
| `firstDayOfWeek` | First calendar column |
| `minuteInterval` | Time steps in `dateTime` mode — `15` gives `:00 :15 :30 :45` |
| `presets` | Chip row; `[]` hides it |
| `showTodayPreset` / `showLast7DaysPreset` / … | Hide individual default chips |
| `locale` / `labels` | Language for names and buttons |
| `enableYearPicker` / `enableSwipe` | Tap the title for years; swipe to page |
| `showHeader` / `showDayCount` / `showClearButton` | Chrome toggles |

## Presets

Today, This Week, This Month, Last 7 Days, and Last 30 Days show by default — hide one with `showLast7DaysPreset: false`, or bring your own:

```dart
presets: [
  DateRangePreset.lastDays(90),
  DateRangePreset(
    label: 'Q1',
    build: (now) => PickedDateRange(DateTime(now.year), DateTime(now.year, 3, 31)),
  ),
]
```

Built in: `today`, `yesterday`, `thisWeek`, `lastWeek`, `thisMonth`, `lastMonth`, `thisYear`, `lastDays(n)`, `nextDays(n)`. Anything outside your bounds is trimmed to fit.

## Theming

Skip the theme and it follows your app, light or dark.

```dart
theme: DateRangePickerTheme.from(primary: Colors.teal)   // one colour

theme: const DateRangePickerTheme(                       // or full control
  primaryColor: Color(0xFF4F46E5),   // selected days, Apply button
  rangeColor: Color(0x1A4F46E5),     // the bar between them
  todayColor: Color(0xFFFBBF24),     // ring around today
  dayRadius: 10,                     // square-ish days
  buttonRadius: 26,                  // pill buttons
)
```

12 colour slots, 7 radii, and 6 text styles in all — see `DateRangePickerTheme`.

## Localisation

Month and weekday names follow the device locale. Every UI string is a plain field you can override:

```dart
DateRangePickerConfig(
  locale: 'en',
  labels: DateRangePickerLabels(
    from: 'From',        // defaults shown — pass any language
    to: 'To',
    apply: 'Apply',
    cancel: 'Cancel',
    daysSelected: (d) => d == 1 ? '1 day selected' : '$d days selected',
  ),
)
```

## Result

```dart
range.start / range.end    // first and last day; end is never before start
range.days                 // 8 — counts both ends, so one day is 1
range.duration             // time between the ends
range.contains(someDay)
range.toList()             // every day in the range
range.toDateTimeRange()    // Flutter's built-in type
```

Also: `hasTime`, `startTime`, `endTime`, `ageInYears()`, `isSingleDay`.

---

<p align="center">
  MIT © <a href="https://farhansadikgalib.com">Farhan Sadik Galib</a>
</p>
