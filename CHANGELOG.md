## 1.1.0

**Breaking — unified picker naming.** Every entry point now belongs to the
`DateRangePicker*` family, so typing `DateRangePicker` autocompletes them all.
Rename call sites:

| Old | New |
|---|---|
| `showDateRangeSheet` | `DateRangePickerSheet` |
| `showDateRangeDialog` | `DateRangePickerPopup` |
| `showDateRangePickerAdaptive` | `DateRangePickerAdaptive` |
| `showCupertinoDateRangePicker` | `DateRangePickerCupertino` |
| `showMultiDatePicker` | `DateRangePickerMultiple` |
| `showMonthPicker` | `DateRangePickerMonth` |
| `showYearPicker` | `DateRangePickerYear` |
| `showDurationPicker` | `DateRangePickerDuration` |
| `showStudioTimePicker` | `DateRangePickerTime` |
| `showStudioTimeRangePicker` | `DateRangePickerTimeRange` |

The dialog picker is `DateRangePickerPopup` (not `…Dialog`) to avoid colliding
with Flutter's own `DateRangePickerDialog`. Signatures and behaviour are
otherwise identical.

### Custom time picker

The `dateTime` mode opens the package's own wheel-based time picker
(`DateRangePickerTime`) instead of the platform dialog, also exported as a
standalone single time picker. Hour and minute wheels share one continuous
selection band with a compact AM/PM toggle beside them; the minute wheel honours
`minuteInterval`. Wheel ticks and the AM/PM toggle give haptic feedback, and
tapping any off-centre value scrolls it into the selection.

A new `TimePickerStyle` customises every colour (accent, band, text, surface,
borders), the corner radius, wheel row height, and text styles. Build one from a
single colour with `TimePickerStyle.from(accent:)`, match a calendar with
`TimePickerStyle.fromTheme(...)`, or leave it unset to resolve from the ambient
`ThemeData`. Presets: `TimePickerStyle.minimal() / rounded() / compact()`.

### Developer-experience foundations

- **`DateRangePickerController`** — a `ChangeNotifier` you attach to
  `DateRangePickerView` to read and drive the selection imperatively: `setRange`,
  `clear`, `goToMonth`, `goToYear`, `goToToday`, plus `value` and `focusedMonth`.
- **`DateRangeFormField`** — a real `FormField<PickedDateRange>`, so a range
  participates in a `Form` with `validator`, `onSaved`, and auto-validation.
- **JSON serialization** — `PickedDateRange.toJson()` / `fromJson()` round-trip a
  selection (including `hasTime`) losslessly.
- **New view callbacks** — `onMonthChanged(DateTime)` and `onError(String?)`,
  alongside the existing `onChanged` / `onApply` / `onCancel`.
- **Theme presets** — `DateRangePickerTheme.minimal() / rounded() / compact()`.

### Calendar power features

Configured on `DateRangePickerConfig`:

- **`dayBuilder`** — fully override how any day cell is rendered while keeping the
  picker's tap/hover wiring, via a `DayCellDetails` (day, selected, in-range,
  today, disabled).
- **`eventLoader`** — supply events per day, drawn as up to three dots under the
  number.
- **`disabledRanges`** — a list of `DateTimeRange`s whose days can't be selected,
  layered over `selectableDayPredicate`.
- **`dayHighlightColor`** — a per-day background tint for holidays, deadlines, or
  weekends.
- **`showWeekNumbers`** — an ISO-8601 week-number column down the left of the grid.

### More pickers & modes

- **Week mode** — `DateRangeMode.week`: one tap selects the seven days of the week
  containing it, starting at `firstDayOfWeek`, as an ordinary `PickedDateRange`.
- **Multi-date mode** — `DateRangeMode.multiple` and the `PickedDates` result
  (sorted, de-duplicated, day-precision, with `toggle`/`contains`/JSON); drive it
  inline (`onDatesChanged`/`onDatesApply`) or via `DateRangePickerMultiple`.
- **`DateRangePickerDuration`** — a wheel-based picker returning a `Duration`
  (hours + minutes, `minuteInterval`, `maxHours`), styled from `TimePickerStyle`.
- **`DateRangePickerMonth`** — a compact month picker returning the first day of
  the chosen month, bounded by `minDate`/`maxDate`.
- **`DateRangePickerYear`** — a scrollable year picker returning the chosen year.
- **`DateRangePickerTimeRange`** — a single dialog with a Start/End toggle over
  shared wheels, returning a `StudioTimeRange` (`{start, end}`).
- **`DateRangePickerAdaptive`** — a bottom sheet on narrow layouts, a centred
  dialog past a `breakpoint`.

### Cupertino skin

`DateRangePickerCupertino` presents the picker in an iOS-style modal that slides
up from the bottom with a Cancel/Done toolbar (Done stays disabled until the
selection is valid). `cupertinoDateRangePickerTheme({brightness, primary})` builds
a matching iOS system-colour palette for light and dark, and works inside a
`CupertinoApp` or `MaterialApp`.

### Localisation

Prebuilt locale labels — `DateRangePickerLabels.forLocale('es'|'fr'|'de'|'pt'|
'it'|'tr'|'ar'|…)` with an English fallback, plus `copyWith` on labels for
per-string overrides.

### Polish

- The bottom sheet gains a soft lifted shadow, a refined drag handle, a rounder
  lip, and keyboard-aware padding.
- The `birthday` age summary now reads "40 years old" (singular "1 year old")
  instead of "Age 40". Override it via `DateRangePickerLabels.age`.

## 1.0.0

Initial release.

**Entry points** — four presentations over one calendar engine: `DateRangePickerSheet`
(modal bottom sheet), `showDateRangeDialog` (centred dialog), `DateRangePickerView`
(inline), and `DateRangeField` (a tappable form field).

**Modes** — `range`, `single`, `birthday` (year → month → day drill-down with an
age summary and `maxDate` defaulting to today), and `dateTime` (a span carrying a
time of day on each endpoint, with `minuteInterval` and `use24HourFormat`).

**Selection rules** — `minDate`/`maxDate` bounds, a `selectableDayPredicate` for
per-day filtering, and `minRangeLength`/`maxRangeLength` limits enforced while
selecting rather than rejected afterwards.

**Presets** — nine built-in shortcuts plus fully custom ones, each clamped to the
configured bounds. Individual default chips can be hidden via `showTodayPreset`,
`showLast7DaysPreset`, and their siblings.

**Theming** — twelve colour slots, seven radii including `buttonRadius`,
`chipRadius`, and `dayRadius`, plus six text styles. Every unset field resolves
from the ambient `ThemeData`, so light and dark work without configuration.

**Localisation** — configurable first day of week, locale, date formats, and all
UI strings via `DateRangePickerLabels`.

**Also** — horizontal month paging with swipe support, a tappable year grid,
multi-month layouts that collapse on narrow screens, hover range preview on
desktop and web, today highlighting, and semantics labels on day cells.

No dependency on `flutter_screenutil` or any state-management package; `intl` only.
