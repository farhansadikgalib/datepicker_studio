## 2.0.0

**Breaking** — `showDateRangeSheet` is renamed to `DateRangePickerSheet`. Update
call sites; the signature is otherwise unchanged.

**Custom time picker** — the `dateTime` mode now opens the package's own
wheel-based time picker (`showStudioTimePicker`) instead of the platform dialog,
also exported as a standalone single time picker. Hour and minute wheels share
one continuous selection band with a compact AM/PM toggle beside them; the
minute wheel honours `minuteInterval`. Wheel ticks and the AM/PM toggle give
haptic feedback, and tapping any off-centre value scrolls it into the selection.

**Fully themeable time picker** — a new `TimePickerStyle` customises every colour
(accent, band, text, surface, borders), the corner radius, wheel row height, and
text styles. Build one from a single colour with `TimePickerStyle.from(accent:)`,
match a calendar with `TimePickerStyle.fromTheme(...)`, or leave it unset to
resolve from the ambient `ThemeData`.

**Nicer sheet** — the bottom sheet gains a soft lifted shadow, a refined drag
handle, a rounder lip, and keyboard-aware padding.

**Refined copy** — the `birthday` age summary now reads "40 years old" (singular
"1 year old") instead of "Age 40". Override it via `DateRangePickerLabels.age`.

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
