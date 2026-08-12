/// A themeable, dependency-light date picker toolkit for Flutter.
///
/// Four entry points share one calendar engine:
///
/// * [DateRangePickerSheet] — modal bottom sheet, best on phones.
/// * [DateRangePickerPopup] — centred dialog, best on tablet and desktop.
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

export 'src/cupertino.dart'
    show cupertinoDateRangePickerTheme, DateRangePickerCupertino;
export 'src/date_range_controller.dart' show DateRangePickerController;
export 'src/date_range_field.dart'
    show DateRangeField, DateRangePickerPresentation;
export 'src/date_range_form_field.dart' show DateRangeFormField;
export 'src/date_range_picker_view.dart' show DateRangePickerView;
export 'src/duration_picker.dart' show DateRangePickerDuration;
export 'src/month_year_picker.dart'
    show DateRangePickerMonth, DateRangePickerYear;
export 'src/models.dart'
    show
        DateRangeMode,
        DateRangePickerConfig,
        DateRangePickerLabels,
        DateRangePreset,
        DayCellDetails,
        PickedDateRange,
        PickedDates;
export 'src/month_grid.dart' show MonthGrid;
export 'src/month_picker_grid.dart' show MonthPickerGrid;
export 'src/presentation.dart'
    show
        DateRangePickerSheet,
        DateRangePickerPopup,
        DateRangePickerAdaptive,
        DateRangePickerMultiple;
export 'src/theme.dart' show DateRangePickerTheme;
export 'src/time_picker_sheet.dart' show DateRangePickerTime;
export 'src/time_picker_style.dart' show TimePickerStyle;
export 'src/time_range_picker.dart'
    show DateRangePickerTimeRange, StudioTimeRange;
export 'src/time_row.dart' show TimeRow;
