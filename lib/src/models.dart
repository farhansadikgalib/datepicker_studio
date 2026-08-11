import 'package:flutter/material.dart';

import 'date_utils.dart';

/// An inclusive span of calendar days, optionally carrying a time of day.
///
/// The default constructor normalises both endpoints to midnight local time,
/// so day-precision comparisons behave predictably. In [DateRangeMode.dateTime]
/// the picker uses [PickedDateRange.withTime] instead, which preserves the
/// hours and minutes attached to each endpoint. In [DateRangeMode.single] and
/// [DateRangeMode.birthday] the picker still produces a range, with [start]
/// equal to [end].
@immutable
class PickedDateRange {
  /// First endpoint. Midnight unless built via [PickedDateRange.withTime].
  final DateTime start;

  /// Last endpoint, always on or after [start]. Midnight unless built via
  /// [PickedDateRange.withTime].
  final DateTime end;

  /// Whether the endpoints carry a meaningful time of day.
  ///
  /// `false` for ranges built the ordinary way, whose times are always
  /// midnight; `true` for those built by [PickedDateRange.withTime].
  final bool hasTime;

  PickedDateRange(DateTime start, DateTime end)
    : start = dateOnly(start.isAfter(end) ? end : start),
      end = dateOnly(start.isAfter(end) ? start : end),
      hasTime = false;

  /// A range whose endpoints keep their time of day.
  ///
  /// Ordering compares full timestamps rather than calendar days, so a range
  /// within a single day (09:00 → 17:00) sorts correctly.
  PickedDateRange.withTime(DateTime start, DateTime end)
    : start = start.isAfter(end) ? end : start,
      end = start.isAfter(end) ? start : end,
      hasTime = true;

  /// A range covering exactly one day.
  PickedDateRange.single(DateTime day) : this(day, day);

  /// Number of days covered, counting both endpoints. A single day is 1.
  int get days => inclusiveDayCount(start, end);

  /// Whether both endpoints fall on the same day.
  bool get isSingleDay => isSameDay(start, end);

  /// Whether [date] falls inside the range, inclusive of both endpoints.
  bool contains(DateTime date) => isWithin(date, start, end);

  /// Every day in the range, in order.
  List<DateTime> toList() =>
      List.generate(days, (i) => addDays(start, i), growable: false);

  /// Converts to Flutter's built-in [DateTimeRange].
  DateTimeRange toDateTimeRange() => DateTimeRange(start: start, end: end);

  /// Creates a [PickedDateRange] from Flutter's built-in [DateTimeRange].
  static PickedDateRange fromDateTimeRange(DateTimeRange range) =>
      PickedDateRange(range.start, range.end);

  /// Elapsed time between the endpoints.
  ///
  /// Only meaningful when [hasTime] is set; for a day-precision range this is
  /// whole days from midnight to midnight, which is one less than [days].
  Duration get duration => end.difference(start);

  /// Returns a copy with the given endpoints replaced, preserving [hasTime].
  PickedDateRange copyWith({DateTime? start, DateTime? end}) => hasTime
      ? PickedDateRange.withTime(start ?? this.start, end ?? this.end)
      : PickedDateRange(start ?? this.start, end ?? this.end);

  /// Returns a copy carrying the given times of day on each endpoint.
  PickedDateRange withTimes({TimeOfDay? startTime, TimeOfDay? endTime}) {
    DateTime apply(DateTime d, TimeOfDay? t) =>
        t == null ? d : DateTime(d.year, d.month, d.day, t.hour, t.minute);
    return PickedDateRange.withTime(
      apply(start, startTime),
      apply(end, endTime),
    );
  }

  /// Time of day on the start endpoint.
  TimeOfDay get startTime => TimeOfDay(hour: start.hour, minute: start.minute);

  /// Time of day on the end endpoint.
  TimeOfDay get endTime => TimeOfDay(hour: end.hour, minute: end.minute);

  /// Age in whole years at [on], defaulting to today.
  ///
  /// Intended for [DateRangeMode.birthday], where the range is a single day.
  /// Returns a negative value for a date in the future.
  int ageInYears([DateTime? on]) {
    final now = dateOnly(on ?? DateTime.now());
    final birth = dateOnly(start);
    var age = now.year - birth.year;
    // Not yet had this year's birthday.
    final had =
        now.month > birth.month ||
        (now.month == birth.month && now.day >= birth.day);
    if (!had) age -= 1;
    return age;
  }

  @override
  bool operator ==(Object other) {
    if (other is! PickedDateRange) return false;
    if (other.hasTime != hasTime) return false;
    // A timed range compares to the minute; a plain one ignores time entirely.
    return hasTime
        ? other.start.isAtSameMomentAs(start) && other.end.isAtSameMomentAs(end)
        : isSameDay(other.start, start) && isSameDay(other.end, end);
  }

  @override
  int get hashCode => hasTime
      ? Object.hash(start, end, true)
      : Object.hash(dateOnly(start), dateOnly(end), false);

  @override
  String toString() {
    String fmt(DateTime d) {
      final iso = d.toIso8601String();
      return hasTime
          ? iso.substring(0, 16).replaceFirst('T', ' ')
          : iso.split('T').first;
    }

    return 'PickedDateRange(${fmt(start)} → ${fmt(end)})';
  }
}

/// What the picker lets the user select.
enum DateRangeMode {
  /// Two endpoints forming a span. The default.
  range,

  /// One day. The result is a [PickedDateRange] whose endpoints are equal.
  single,

  /// A date of birth, entered year first.
  ///
  /// Opens on the year grid and drills down through month to day, since
  /// paging month-by-month to a distant year is impractical. Defaults
  /// [DateRangePickerConfig.maxDate] to today and shows the resulting age.
  /// Produces a single-day range, like [single].
  birthday,

  /// A span with a time of day on each endpoint.
  ///
  /// Dates are picked on the calendar as usual, then a time row below it sets
  /// the hours and minutes. The result is a [PickedDateRange] built with
  /// [PickedDateRange.withTime], so its endpoints are not midnight-normalised.
  dateTime,
}

/// A one-tap shortcut shown above the action buttons, such as "Last 7 Days".
@immutable
class DateRangePreset {
  /// Text shown on the chip.
  final String label;

  /// Builds the range to apply, given the current date at tap time.
  ///
  /// Returning a range that falls partly outside the configured bounds is safe:
  /// the picker clamps it before applying.
  final PickedDateRange Function(DateTime now) build;

  const DateRangePreset({required this.label, required this.build});

  /// The current day.
  static DateRangePreset today([String label = 'Today']) => DateRangePreset(
    label: label,
    build: (now) => PickedDateRange.single(now),
  );

  /// The day before the current day.
  static DateRangePreset yesterday([String label = 'Yesterday']) =>
      DateRangePreset(
        label: label,
        build: (now) => PickedDateRange.single(addDays(now, -1)),
      );

  /// The current week so far, starting at [firstDayOfWeek].
  static DateRangePreset thisWeek({
    String label = 'This Week',
    int firstDayOfWeek = DateTime.monday,
  }) => DateRangePreset(
    label: label,
    build: (now) => PickedDateRange(startOfWeek(now, firstDayOfWeek), now),
  );

  /// The seven days ending on the previous [firstDayOfWeek].
  static DateRangePreset lastWeek({
    String label = 'Last Week',
    int firstDayOfWeek = DateTime.monday,
  }) => DateRangePreset(
    label: label,
    build: (now) {
      final start = addDays(startOfWeek(now, firstDayOfWeek), -7);
      return PickedDateRange(start, addDays(start, 6));
    },
  );

  /// The first of the current month through today.
  static DateRangePreset thisMonth([String label = 'This Month']) =>
      DateRangePreset(
        label: label,
        build: (now) => PickedDateRange(DateTime(now.year, now.month, 1), now),
      );

  /// The whole of the previous calendar month.
  static DateRangePreset lastMonth([String label = 'Last Month']) =>
      DateRangePreset(
        label: label,
        build: (now) {
          final start = DateTime(now.year, now.month - 1, 1);
          return PickedDateRange(
            start,
            DateTime(
              start.year,
              start.month,
              daysInMonth(start.year, start.month),
            ),
          );
        },
      );

  /// January 1st of the current year through today.
  static DateRangePreset thisYear([String label = 'This Year']) =>
      DateRangePreset(
        label: label,
        build: (now) => PickedDateRange(DateTime(now.year, 1, 1), now),
      );

  /// The last [days] days, ending today and including it.
  static DateRangePreset lastDays(int days, {String? label}) => DateRangePreset(
    label: label ?? 'Last $days Days',
    build: (now) => PickedDateRange(addDays(now, -(days - 1)), now),
  );

  /// The next [days] days, starting today and including it.
  static DateRangePreset nextDays(int days, {String? label}) => DateRangePreset(
    label: label ?? 'Next $days Days',
    build: (now) => PickedDateRange(now, addDays(now, days - 1)),
  );

  /// The default chip row: Today, This Week, This Month, Last 7 and 30 days.
  ///
  /// Each chip can be dropped individually, so a row can be trimmed without
  /// rebuilding the whole list:
  ///
  /// ```dart
  /// // Everything except the Last 7 Days and Today chips.
  /// DateRangePreset.defaults(showLast7Days: false, showToday: false)
  /// ```
  static List<DateRangePreset> defaults({
    int firstDayOfWeek = DateTime.monday,
    bool showToday = true,
    bool showThisWeek = true,
    bool showThisMonth = true,
    bool showLast7Days = true,
    bool showLast30Days = true,
  }) => [
    if (showToday) today(),
    if (showThisWeek) thisWeek(firstDayOfWeek: firstDayOfWeek),
    if (showThisMonth) thisMonth(),
    if (showLast7Days) lastDays(7),
    if (showLast30Days) lastDays(30),
  ];
}

/// User-facing strings, so the picker can be localised without a dependency on
/// `intl` message catalogs.
@immutable
class DateRangePickerLabels {
  /// Caption above the start date in the header.
  final String from;

  /// Caption above the end date in the header.
  final String to;

  /// Placeholder shown before a date has been chosen.
  final String empty;

  /// Dismiss button text.
  final String cancel;

  /// Confirm button text.
  final String apply;

  /// Text of the button that clears the current selection.
  final String clear;

  /// Title shown while the year grid is open.
  final String selectYear;

  /// Title shown while the month grid is open in [DateRangeMode.birthday].
  final String selectMonth;

  /// Caption above the start endpoint's time.
  final String startTime;

  /// Caption above the end endpoint's time.
  final String endTime;

  /// Builds the "40 years old" summary shown in [DateRangeMode.birthday].
  /// Return an empty string to hide it.
  final String Function(int years) age;

  /// Builds the "5 days selected" summary. Return an empty string to hide it.
  final String Function(int days) daysSelected;

  /// Message shown when the selection exceeds `maxRangeLength`.
  final String Function(int maxDays) rangeTooLong;

  /// Message shown when the selection is shorter than `minRangeLength`.
  final String Function(int minDays) rangeTooShort;

  const DateRangePickerLabels({
    this.from = 'From',
    this.to = 'To',
    this.empty = '--',
    this.cancel = 'Cancel',
    this.apply = 'Apply',
    this.clear = 'Clear',
    this.selectYear = 'Select year',
    this.selectMonth = 'Select month',
    this.startTime = 'Start time',
    this.endTime = 'End time',
    this.age = _defaultAge,
    this.daysSelected = _defaultDaysSelected,
    this.rangeTooLong = _defaultTooLong,
    this.rangeTooShort = _defaultTooShort,
  });

  static String _defaultAge(int years) =>
      years == 1 ? '1 year old' : '$years years old';

  static String _defaultDaysSelected(int days) =>
      days == 1 ? '1 day selected' : '$days days selected';

  static String _defaultTooLong(int max) =>
      'Select at most ${max == 1 ? '1 day' : '$max days'}';

  static String _defaultTooShort(int min) =>
      'Select at least ${min == 1 ? '1 day' : '$min days'}';
}

/// Behavioural configuration shared by every entry point.
@immutable
class DateRangePickerConfig {
  /// Whether the picker selects a span or a single day.
  final DateRangeMode mode;

  /// Earliest selectable day, inclusive. Days before it are shown greyed out.
  final DateTime? minDate;

  /// Latest selectable day, inclusive. Days after it are shown greyed out.
  final DateTime? maxDate;

  /// Additional per-day filter, called for every rendered cell within bounds.
  ///
  /// Return `false` to disable the day — useful for blacking out weekends,
  /// holidays, or already-booked dates. Keep it cheap: it runs once per visible
  /// cell per build.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// Shortest allowed selection, in days, counting both endpoints.
  ///
  /// Applies only in [DateRangeMode.range]. Selections shorter than this leave
  /// the confirm button disabled and surface [DateRangePickerLabels.rangeTooShort].
  final int? minRangeLength;

  /// Longest allowed selection, in days, counting both endpoints.
  ///
  /// Days beyond the limit are disabled while picking the second endpoint, so
  /// an over-long range cannot be formed in the first place.
  final int? maxRangeLength;

  /// First column of the calendar, using [DateTime] weekday constants
  /// (1 = Monday … 7 = Sunday). Defaults to Monday.
  final int firstDayOfWeek;

  /// Locale used to format month names and weekday initials, e.g. `'de'`.
  /// Falls back to the ambient [Localizations] locale, then to English.
  final String? locale;

  /// Chips shown above the action buttons. Pass an empty list to hide the row.
  ///
  /// When null the default row is used, filtered by [showTodayPreset],
  /// [showLast7DaysPreset], and their siblings.
  final List<DateRangePreset>? presets;

  /// Whether the default row includes the Today chip.
  ///
  /// Ignored when [presets] is set explicitly, since that list is used as-is.
  final bool showTodayPreset;

  /// Whether the default row includes the This Week chip.
  final bool showThisWeekPreset;

  /// Whether the default row includes the This Month chip.
  final bool showThisMonthPreset;

  /// Whether the default row includes the Last 7 Days chip.
  final bool showLast7DaysPreset;

  /// Whether the default row includes the Last 30 Days chip.
  final bool showLast30DaysPreset;

  /// Strings shown in the UI.
  final DateRangePickerLabels labels;

  /// Whether to show the From/To header.
  final bool showHeader;

  /// Whether to show the "5 days selected" summary under the grid.
  final bool showDayCount;

  /// Whether to show a button that clears the current selection.
  final bool showClearButton;

  /// Whether tapping the month title opens a year grid.
  final bool enableYearPicker;

  /// Whether the grid can be swiped horizontally to change month.
  final bool enableSwipe;

  /// Whether to draw an outline around today when it is not selected.
  final bool highlightToday;

  /// Number of months shown side by side. Values above 1 suit tablets and
  /// desktop; the layout falls back to a single month if width is tight.
  final int visibleMonths;

  /// Date format for the header values. Uses `intl` skeleton syntax.
  final String headerDateFormat;

  /// Format for the month title. Uses `intl` skeleton syntax.
  final String monthTitleFormat;

  /// Whether the confirm action fires as soon as a complete selection is made,
  /// skipping the Apply button.
  final bool autoApply;

  /// Earliest year offered by the year picker. Defaults to `minDate`'s year,
  /// or 100 years before today.
  final int? firstYear;

  /// Latest year offered by the year picker. Defaults to `maxDate`'s year,
  /// or 10 years after today.
  final int? lastYear;

  /// Minute increment offered by the time fields in [DateRangeMode.dateTime].
  ///
  /// For example `15` offers :00, :15, :30, and :45. Must divide 60 evenly.
  final int minuteInterval;

  /// Whether the time fields use a 24-hour clock. Defaults to the ambient
  /// locale's convention via [MediaQuery.alwaysUse24HourFormatOf].
  final bool? use24HourFormat;

  /// Time applied to the start endpoint before the user picks one.
  final TimeOfDay initialStartTime;

  /// Time applied to the end endpoint before the user picks one.
  final TimeOfDay initialEndTime;

  const DateRangePickerConfig({
    this.mode = DateRangeMode.range,
    this.minDate,
    this.maxDate,
    this.selectableDayPredicate,
    this.minRangeLength,
    this.maxRangeLength,
    this.firstDayOfWeek = DateTime.monday,
    this.locale,
    this.presets,
    this.showTodayPreset = true,
    this.showThisWeekPreset = true,
    this.showThisMonthPreset = true,
    this.showLast7DaysPreset = true,
    this.showLast30DaysPreset = true,
    this.labels = const DateRangePickerLabels(),
    this.showHeader = true,
    this.showDayCount = true,
    this.showClearButton = false,
    this.enableYearPicker = true,
    this.enableSwipe = true,
    this.highlightToday = true,
    this.visibleMonths = 1,
    this.headerDateFormat = 'dd MMM yyyy',
    this.monthTitleFormat = 'MMMM yyyy',
    this.autoApply = false,
    this.firstYear,
    this.lastYear,
    this.minuteInterval = 1,
    this.use24HourFormat,
    this.initialStartTime = const TimeOfDay(hour: 9, minute: 0),
    this.initialEndTime = const TimeOfDay(hour: 17, minute: 0),
  }) : assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday constant (1-7)',
       ),
       assert(
         minuteInterval >= 1 &&
             minuteInterval <= 60 &&
             60 % minuteInterval == 0,
         'minuteInterval must divide 60 evenly',
       ),
       assert(visibleMonths >= 1, 'visibleMonths must be at least 1'),
       assert(
         minRangeLength == null || minRangeLength >= 1,
         'minRangeLength must be at least 1',
       ),
       assert(
         maxRangeLength == null || maxRangeLength >= 1,
         'maxRangeLength must be at least 1',
       ),
       assert(
         minRangeLength == null ||
             maxRangeLength == null ||
             minRangeLength <= maxRangeLength,
         'minRangeLength cannot exceed maxRangeLength',
       );

  /// Returns a copy with the given fields replaced.
  DateRangePickerConfig copyWith({
    DateRangeMode? mode,
    DateTime? minDate,
    DateTime? maxDate,
    bool Function(DateTime day)? selectableDayPredicate,
    int? minRangeLength,
    int? maxRangeLength,
    int? firstDayOfWeek,
    String? locale,
    List<DateRangePreset>? presets,
    bool? showTodayPreset,
    bool? showThisWeekPreset,
    bool? showThisMonthPreset,
    bool? showLast7DaysPreset,
    bool? showLast30DaysPreset,
    DateRangePickerLabels? labels,
    bool? showHeader,
    bool? showDayCount,
    bool? showClearButton,
    bool? enableYearPicker,
    bool? enableSwipe,
    bool? highlightToday,
    int? visibleMonths,
    String? headerDateFormat,
    String? monthTitleFormat,
    bool? autoApply,
    int? firstYear,
    int? lastYear,
    int? minuteInterval,
    bool? use24HourFormat,
    TimeOfDay? initialStartTime,
    TimeOfDay? initialEndTime,
  }) {
    return DateRangePickerConfig(
      mode: mode ?? this.mode,
      minDate: minDate ?? this.minDate,
      maxDate: maxDate ?? this.maxDate,
      selectableDayPredicate:
          selectableDayPredicate ?? this.selectableDayPredicate,
      minRangeLength: minRangeLength ?? this.minRangeLength,
      maxRangeLength: maxRangeLength ?? this.maxRangeLength,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      locale: locale ?? this.locale,
      presets: presets ?? this.presets,
      showTodayPreset: showTodayPreset ?? this.showTodayPreset,
      showThisWeekPreset: showThisWeekPreset ?? this.showThisWeekPreset,
      showThisMonthPreset: showThisMonthPreset ?? this.showThisMonthPreset,
      showLast7DaysPreset: showLast7DaysPreset ?? this.showLast7DaysPreset,
      showLast30DaysPreset: showLast30DaysPreset ?? this.showLast30DaysPreset,
      labels: labels ?? this.labels,
      showHeader: showHeader ?? this.showHeader,
      showDayCount: showDayCount ?? this.showDayCount,
      showClearButton: showClearButton ?? this.showClearButton,
      enableYearPicker: enableYearPicker ?? this.enableYearPicker,
      enableSwipe: enableSwipe ?? this.enableSwipe,
      highlightToday: highlightToday ?? this.highlightToday,
      visibleMonths: visibleMonths ?? this.visibleMonths,
      headerDateFormat: headerDateFormat ?? this.headerDateFormat,
      monthTitleFormat: monthTitleFormat ?? this.monthTitleFormat,
      autoApply: autoApply ?? this.autoApply,
      firstYear: firstYear ?? this.firstYear,
      lastYear: lastYear ?? this.lastYear,
      minuteInterval: minuteInterval ?? this.minuteInterval,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      initialStartTime: initialStartTime ?? this.initialStartTime,
      initialEndTime: initialEndTime ?? this.initialEndTime,
    );
  }
}
