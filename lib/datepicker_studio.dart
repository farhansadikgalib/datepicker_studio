/// A themeable, dependency-light date picker toolkit for Flutter.
///
/// Four entry points share one calendar engine:
///
/// * [showDateRangeSheet] — modal bottom sheet, best on phones.
/// * [showDateRangeDialog] — centred dialog, best on tablet and desktop.
/// * [DateRangePickerView] — the calendar itself, for embedding inline.
/// * [DateRangeField] — a tappable form field wrapping either modal.
///
/// ```dart
/// final range = await showDateRangeSheet(
///   context,
///   config: DateRangePickerConfig(
///     minDate: DateTime(2020),
///     maxDate: DateTime.now(),
///     maxRangeLength: 90,
///   ),
/// );
/// ```
library;

export 'src/date_range_field.dart'
    show DateRangeField, DateRangePickerPresentation;
export 'src/date_range_picker_view.dart' show DateRangePickerView;
export 'src/models.dart'
    show
        DateRangeMode,
        DateRangePickerConfig,
        DateRangePickerLabels,
        DateRangePreset,
        PickedDateRange;
export 'src/month_grid.dart' show MonthGrid;
export 'src/month_picker_grid.dart' show MonthPickerGrid;
export 'src/presentation.dart' show showDateRangeDialog, showDateRangeSheet;
export 'src/theme.dart' show DateRangePickerTheme;
export 'src/time_row.dart' show TimeRow;
