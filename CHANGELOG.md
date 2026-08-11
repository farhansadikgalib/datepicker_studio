## 1.0.0

Initial release.

**Entry points** — four presentations over one calendar engine: `showDateRangeSheet`
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
