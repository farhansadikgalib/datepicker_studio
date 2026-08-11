/// A themeable, dependency-light date picker toolkit for Flutter.
///
/// Four entry points share one calendar engine:
///
/// * [DateRangePickerSheet] — modal bottom sheet, best on phones.
/// * [showDateRangeDialog] — centred dialog, best on tablet and desktop.
/// * [DateRangePickerView] — the calendar itself, for embedding inline.
/// * [DateRangeField] — a tappable form field wrapping either modal.
///
/// ```dart
/// final range = await DateRangePickerSheet(
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
export 'src/presentation.dart' show DateRangePickerSheet, showDateRangeDialog;
export 'src/theme.dart' show DateRangePickerTheme;
export 'src/time_picker_sheet.dart' show showStudioTimePicker;
export 'src/time_picker_style.dart' show TimePickerStyle;
export 'src/time_row.dart' show TimeRow;
