<p align="center">
  <img src="assets/logo.png" alt="datepicker_studio logo" width="140" height="140">
</p>

<h1 align="center">datepicker_studio</h1>

<p align="center">
  A themeable date &amp; time picker toolkit for Flutter — range, single,
  birthday, date-time, week &amp; multi-date, as a sheet, dialog, inline calendar,
  field, or iOS modal.
</p>

<p align="center">
  <a href="https://pub.dev/packages/datepicker_studio"><img src="https://img.shields.io/pub/v/datepicker_studio.svg" alt="pub package"></a>
  <a href="https://pub.dev/packages/datepicker_studio/score"><img src="https://img.shields.io/pub/points/datepicker_studio" alt="pub points"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT license"></a>
</p>

---

## Install

```yaml
dependencies:
  datepicker_studio: ^1.1.0
```

```dart
import 'package:datepicker_studio/datepicker_studio.dart';

final range = await DateRangePickerSheet(context);   // null if cancelled
print('${range?.start} → ${range?.end} · ${range?.days} days');
```

Presets, month swiping, a year picker, and your app's colours — out of the box.

## Show it

```dart
DateRangePickerSheet(context);      // bottom sheet (phones)
DateRangePickerPopup(context);      // centred dialog (tablet / desktop / web)
DateRangePickerAdaptive(context);   // sheet or dialog, by screen width
DateRangePickerCupertino(context);  // iOS-style modal with Cancel/Done

DateRangePickerView(showActions: false, onChanged: (r) => …);  // inline widget
DateRangeField(value: _range, onChanged: (r) => …);            // tap-to-open field
DateRangeFormField(validator: (r) => r == null ? 'Required' : null);  // in a Form
```

Both fields are fully styleable — pass any `decoration`, plus `borderRadius` and `textStyle`:

```dart
DateRangeField(
  value: _range, onChanged: (r) => …,
  borderRadius: BorderRadius.circular(18),
  textStyle: const TextStyle(fontWeight: FontWeight.w600),
  decoration: const InputDecoration(labelText: 'Period', filled: true),
);
```

Drive the inline picker imperatively:

```dart
final c = DateRangePickerController();
DateRangePickerView(controller: c, onChanged: (r) => …);
c.setRange(DateRangePreset.lastDays(7).build(DateTime.now()));
c.goToMonth(DateTime(2027, 1));
c.clear();
```

## Modes

`config: DateRangePickerConfig(mode: DateRangeMode.birthday)`

| Mode | Gives you |
|---|---|
| `range` | A span (default) |
| `single` | One day |
| `birthday` | Year → month → day, blocks the future, `range.ageInYears()` |
| `dateTime` | A time on each end → `2026-08-05 09:30` |
| `week` | One tap selects the whole week |
| `multiple` | Toggle loose days → `PickedDates` |

## Standalone pickers

Each opens on its own and returns its own value (`null` if cancelled):

```dart
final time  = await DateRangePickerTime(context, initialTime: TimeOfDay.now()); // TimeOfDay?
final span  = await DateRangePickerTimeRange(context);                          // ({start, end})?
final dur   = await DateRangePickerDuration(context);                           // Duration?
final month = await DateRangePickerMonth(context);                             // DateTime?
final year  = await DateRangePickerYear(context);                              // int?
final dates = await DateRangePickerMultiple(context);                          // PickedDates?

if (time != null) print(time.format(context));   // 9:00 AM
```

Style the time-based pickers with `TimePickerStyle.from(accent: Colors.indigo)` (also `.rounded()` / `.minimal()` / `.compact()`), and set `minuteInterval` / `use24HourFormat` as needed.

## Options — `DateRangePickerConfig`

| Option | Does |
|---|---|
| `mode` | Selection mode (above). Default `range` |
| `minDate` / `maxDate` | Selectable bounds; outside days greyed |
| `minRangeLength` / `maxRangeLength` | Length limits, enforced while picking |
| `selectableDayPredicate` | Per-day filter (weekends, holidays, booked) |
| `disabledRanges` | Block whole `DateTimeRange`s |
| `firstDayOfWeek` | First column. Default Monday |
| `visibleMonths` | Months side by side; collapses when narrow |
| `autoApply` | Confirm on complete selection |
| `presets` | Chip row; `[]` hides it |
| `showTodayPreset` / `showThisWeekPreset` / `showThisMonthPreset` / `showLast7DaysPreset` / `showLast30DaysPreset` | Toggle each default chip |
| `showHeader` / `showDayCount` / `showClearButton` | Chrome toggles |
| `highlightToday` | Ring around today |
| `enableYearPicker` / `enableSwipe` | Tap title for years; swipe to page |
| `showWeekNumbers` | ISO-8601 week column |
| `dayBuilder` | Custom day cell (`DayCellDetails`) |
| `eventLoader` | Events per day, drawn as dots |
| `dayHighlightColor` | Per-day background tint |
| `firstYear` / `lastYear` | Year-grid bounds |
| `headerDateFormat` / `monthTitleFormat` | `intl` date skeletons |
| `minuteInterval` | Time steps in `dateTime` — `15` → `:00 :15 :30 :45` |
| `use24HourFormat` | Force a 24-hour clock |
| `initialStartTime` / `initialEndTime` | Default endpoint times |
| `locale` | Names and formats |
| `labels` | Every UI string (Localisation) |

## Presets

Today, This Week, This Month, Last 7 & Last 30 Days by default — hide one with `showLast7DaysPreset: false`, or bring your own:

```dart
presets: [
  DateRangePreset.lastDays(90),
  DateRangePreset(label: 'Q1', build: (now) =>
      PickedDateRange(DateTime(now.year), DateTime(now.year, 3, 31))),
]
```

Built in: `today`, `yesterday`, `thisWeek`, `lastWeek`, `thisMonth`, `lastMonth`, `thisYear`, `lastDays(n)`, `nextDays(n)` — clamped to your bounds.

## Theming

Skip it and it follows your app, light or dark. 12 colours, 7 radii, 6 text styles.

```dart
theme: DateRangePickerTheme.from(primary: Colors.teal)   // one colour
theme: DateRangePickerTheme.rounded()                    // or .minimal() / .compact()
```

`cupertinoDateRangePickerTheme()` mirrors the iOS palette for `DateRangePickerCupertino`.

## Localisation

Names follow the device locale; every string is overridable — use a built-in bundle (`en es fr de pt it tr ar`) or set fields:

```dart
labels: DateRangePickerLabels.forLocale('es')
labels: const DateRangePickerLabels(from: 'From', to: 'To', apply: 'Apply')
```

## Result

```dart
range.start / range.end     // ordered; end is never before start
range.days                  // inclusive count (one day = 1)
range.duration;             range.contains(day);
range.toList();             range.toDateTimeRange();   range.toJson();
range.hasTime;  range.startTime;  range.endTime;  range.ageInYears();  range.isSingleDay;
```

Multi-date returns `PickedDates` (`dates`, `count`, `contains`, `toggle`, `toJson`).

---

<p align="center">
  MIT © <a href="https://farhansadikgalib.com">Farhan Sadik Galib</a>
</p>
