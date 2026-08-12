import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'date_range_controller.dart';
import 'date_utils.dart';
import 'models.dart';
import 'month_grid.dart';
import 'month_picker_grid.dart';
import 'theme.dart';
import 'time_row.dart';
import 'year_grid.dart';

/// Which grid the picker body is currently showing.
enum _PickerStep { years, months, days }

/// The calendar itself, without any surrounding sheet or dialog.
///
/// Embed this to place the picker inline in a page, a sidebar, or your own
/// container. For the standard modal presentations use `DateRangePickerSheet`
/// or `DateRangePickerPopup`, which wrap this widget.
///
/// ```dart
/// DateRangePickerView(
///   initialRange: range,
///   config: const DateRangePickerConfig(minRangeLength: 2),
///   onChanged: (r) => setState(() => range = r),
///   showActions: false,
/// )
/// ```
class DateRangePickerView extends StatefulWidget {
  /// Selection to open with. Endpoints outside the configured bounds are
  /// clamped into range.
  final PickedDateRange? initialRange;

  /// Month shown first. Defaults to the start of [initialRange], else today.
  final DateTime? initialMonth;

  /// Behavioural options.
  final DateRangePickerConfig config;

  /// Visual options. Unset fields resolve from the ambient [ThemeData].
  final DateRangePickerTheme? theme;

  /// Optional controller for reading and driving the selection imperatively.
  final DateRangePickerController? controller;

  /// Fires on every selection change, including partial ones — the range is
  /// null while only the first endpoint has been chosen.
  final ValueChanged<PickedDateRange?>? onChanged;

  /// Fires when the user confirms, via the Apply button or
  /// [DateRangePickerConfig.autoApply].
  final ValueChanged<PickedDateRange>? onApply;

  /// Fires when the user dismisses without confirming.
  final VoidCallback? onCancel;

  /// Selection to open with in [DateRangeMode.multiple].
  final PickedDates? initialDates;

  /// Fires on every toggle in [DateRangeMode.multiple].
  final ValueChanged<PickedDates>? onDatesChanged;

  /// Fires when the user confirms in [DateRangeMode.multiple].
  final ValueChanged<PickedDates>? onDatesApply;

  /// Fires when the focused month changes — by swiping, the nav arrows, the
  /// year/month grids, or [DateRangePickerController.goToMonth].
  final ValueChanged<DateTime>? onMonthChanged;

  /// Fires when the completed selection's validity changes, with the error
  /// message (from [DateRangePickerConfig.labels]) or `null` when it becomes
  /// valid. Useful for enabling an external submit button.
  final ValueChanged<String?>? onError;

  /// Whether to render the Cancel/Apply row. Turn off when embedding the
  /// picker inline and driving it from [onChanged].
  final bool showActions;

  const DateRangePickerView({
    super.key,
    this.initialRange,
    this.initialMonth,
    this.config = const DateRangePickerConfig(),
    this.theme,
    this.controller,
    this.onChanged,
    this.onApply,
    this.onCancel,
    this.onMonthChanged,
    this.onError,
    this.initialDates,
    this.onDatesChanged,
    this.onDatesApply,
    this.showActions = true,
  });

  @override
  State<DateRangePickerView> createState() => _DateRangePickerViewState();
}

class _DateRangePickerViewState extends State<DateRangePickerView> {
  /// Page index 0 maps to [_baseMonth]; higher indices are later months.
  static const int _initialPage = 1200;

  late PageController _pageController;
  late DateTime _baseMonth;
  late DateTime _focusedMonth;

  DateTime? _start;
  DateTime? _end;
  DateTime? _hovered;
  bool _selectingEnd = false;

  /// Which grid the body is showing. Birthday mode walks year → month → day.
  _PickerStep _step = _PickerStep.days;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  /// The caller's config with birthday mode's implicit upper bound applied,
  /// so bounds checks, clamping, and the day grid all agree.
  DateRangePickerConfig get _config {
    final config = widget.config;
    if (config.mode != DateRangeMode.birthday || config.maxDate != null) {
      return config;
    }
    return config.copyWith(maxDate: dateOnly(DateTime.now()));
  }

  /// Whether the mode yields one day rather than a span.
  bool get _isSingle =>
      _config.mode == DateRangeMode.single ||
      _config.mode == DateRangeMode.birthday;

  bool get _isBirthday => _config.mode == DateRangeMode.birthday;
  bool get _hasTime => _config.mode == DateRangeMode.dateTime;
  bool get _isWeek => _config.mode == DateRangeMode.week;
  bool get _isMulti => _config.mode == DateRangeMode.multiple;
  bool get _showYearGrid => _step == _PickerStep.years;

  /// Individually-chosen days in [DateRangeMode.multiple].
  PickedDates _multi = PickedDates.empty();

  @override
  void initState() {
    super.initState();
    _multi = widget.initialDates ?? PickedDates.empty();
    _applyInitialSelection();

    final anchor =
        widget.initialMonth ??
        _start ??
        clampDate(DateTime.now(), _config.minDate, _config.maxDate);
    _focusedMonth = DateTime(anchor.year, anchor.month);
    _baseMonth = addMonths(_focusedMonth, -_initialPage);
    _pageController = PageController(initialPage: _initialPage);

    // Birthday entry starts at the year, since paging to a distant one is
    // impractical. An existing selection skips straight to the day grid.
    if (_isBirthday && widget.initialRange == null) {
      _step = _PickerStep.years;
    }

    if (_hasTime) {
      final initial = widget.initialRange;
      _startTime = initial != null && initial.hasTime
          ? initial.startTime
          : _config.initialStartTime;
      _endTime = initial != null && initial.hasTime
          ? initial.endTime
          : _config.initialEndTime;
    }

    _attachController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant DateRangePickerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRange != oldWidget.initialRange) {
      setState(_applyInitialSelection);
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      _attachController(widget.controller);
    }
  }

  /// Installs this state's command hooks on [controller] so external callers
  /// can read and drive the selection.
  void _attachController(DateRangePickerController? controller) {
    controller?.attach(
      read: () => _currentRange,
      write: _selectRange,
      goToMonth: _goToMonth,
      readMonth: () => _focusedMonth,
    );
  }

  /// Applies an externally supplied selection (or clears it), clamping and
  /// scrolling the calendar to match. Drives [DateRangePickerController].
  void _selectRange(PickedDateRange? range) {
    setState(() {
      if (range == null) {
        _start = null;
        _end = null;
      } else {
        _start = clampDate(range.start, _config.minDate, _config.maxDate);
        _end = _isSingle
            ? _start
            : clampDate(range.end, _config.minDate, _config.maxDate);
        if (_hasTime && range.hasTime) {
          _startTime = range.startTime;
          _endTime = range.endTime;
        }
      }
      _selectingEnd = false;
      _hovered = null;
    });
    if (_start != null) _goToMonth(DateTime(_start!.year, _start!.month));
    _notifyChanged();
  }

  void _applyInitialSelection() {
    final initial = widget.initialRange;
    if (initial == null) {
      _start = null;
      _end = null;
      _selectingEnd = false;
      return;
    }
    _start = clampDate(initial.start, _config.minDate, _config.maxDate);
    _end = _isSingle
        ? _start
        : clampDate(initial.end, _config.minDate, _config.maxDate);
    _selectingEnd = false;
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- selection

  void _onDayTap(DateTime day) {
    if (_isMulti) {
      setState(() => _multi = _multi.toggle(day));
      widget.onDatesChanged?.call(_multi);
      return;
    }
    setState(() {
      if (_isWeek) {
        // One tap picks the whole week, clamped into any configured bounds.
        final weekStart = startOfWeek(day, _config.firstDayOfWeek);
        _start = clampDate(weekStart, _config.minDate, _config.maxDate);
        _end = clampDate(
          addDays(weekStart, 6),
          _config.minDate,
          _config.maxDate,
        );
        _selectingEnd = false;
      } else if (_isSingle) {
        _start = day;
        _end = day;
        _selectingEnd = false;
      } else if (!_selectingEnd || _start == null) {
        // Starting a fresh range: the tapped day becomes the anchor.
        _start = day;
        _end = null;
        _selectingEnd = true;
      } else {
        // Closing the range. A tap before the anchor flips the endpoints
        // rather than rejecting the gesture.
        if (day.isBefore(_start!)) {
          _end = _start;
          _start = day;
        } else {
          _end = day;
        }
        _selectingEnd = false;
      }
      _hovered = null;
    });

    _notifyChanged();
    _maybeAutoApply();
  }

  void _applyPreset(DateRangePreset preset) {
    final built = preset.build(DateTime.now());
    final start = clampDate(built.start, _config.minDate, _config.maxDate);
    final end = clampDate(built.end, _config.minDate, _config.maxDate);

    setState(() {
      _start = start;
      _end = _isSingle ? start : end;
      _selectingEnd = false;
      _hovered = null;
    });
    _goToMonth(DateTime(start.year, start.month));
    _notifyChanged();
    _maybeAutoApply();
  }

  void _clear() {
    setState(() {
      _start = null;
      _end = null;
      _selectingEnd = false;
      _hovered = null;
      _multi = PickedDates.empty();
    });
    if (_isMulti) widget.onDatesChanged?.call(_multi);
    _notifyChanged();
  }

  /// The last validation message pushed to [onError], so it only fires on a
  /// change rather than every rebuild.
  String? _lastError;

  void _notifyChanged() {
    final range = _currentRange;
    widget.onChanged?.call(range);
    widget.controller?.notify();

    final error = range == null ? null : _validate(range);
    if (error != _lastError) {
      _lastError = error;
      widget.onError?.call(error);
    }
  }

  void _maybeAutoApply() {
    if (!_config.autoApply) return;
    final range = _currentRange;
    if (range != null && _validate(range) == null) {
      widget.onApply?.call(range);
    }
  }

  PickedDateRange? get _currentRange {
    if (_start == null) return null;
    if (_isSingle) return PickedDateRange.single(_start!);
    if (_end == null) return null;
    if (_hasTime) {
      return PickedDateRange(
        _start!,
        _end!,
      ).withTimes(startTime: _startTime, endTime: _endTime);
    }
    return PickedDateRange(_start!, _end!);
  }

  /// Returns an error message if [range] violates the length constraints.
  String? _validate(PickedDateRange range) {
    if (_isSingle) return null;
    final labels = _config.labels;
    final min = _config.minRangeLength;
    final max = _config.maxRangeLength;
    if (min != null && range.days < min) return labels.rangeTooShort(min);
    if (max != null && range.days > max) return labels.rangeTooLong(max);
    return null;
  }

  void _confirm() {
    if (_isMulti) {
      if (_multi.isNotEmpty) widget.onDatesApply?.call(_multi);
      return;
    }
    final range = _currentRange;
    if (range == null || _validate(range) != null) return;
    widget.onApply?.call(range);
  }

  // ----------------------------------------------------------------- paging

  DateTime _monthForPage(int page) => addMonths(_baseMonth, page);

  void _goToMonth(DateTime month) {
    final target = monthsBetween(_baseMonth, month);
    if (!_pageController.hasClients) {
      // The PageView is unmounted — the year or month grid is showing — so the
      // controller cannot be driven. Rebase the page origin on the target
      // month instead, otherwise the controller would restore its previous
      // page when the calendar remounts and silently undo the jump.
      setState(() {
        _focusedMonth = month;
        _baseMonth = addMonths(month, -_initialPage);
        _pageController.dispose();
        _pageController = PageController(initialPage: _initialPage);
      });
      widget.onMonthChanged?.call(month);
      return;
    }
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// Whether paging by [delta] months would leave the configured bounds.
  bool _canPage(int delta) {
    final target = addMonths(_focusedMonth, delta);
    final min = _config.minDate;
    final max = _config.maxDate;
    if (delta < 0 && min != null) {
      return monthsBetween(DateTime(min.year, min.month), target) >= 0;
    }
    if (delta > 0 && max != null) {
      // The last visible month must not pass the bound in multi-month layouts.
      final last = addMonths(target, _resolvedVisibleMonths - 1);
      return monthsBetween(last, DateTime(max.year, max.month)) >= 0;
    }
    return true;
  }

  int _resolvedVisibleMonths = 1;

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final theme = (widget.theme ?? const DateRangePickerTheme()).resolve(
      context,
    );
    final labels = _config.labels;
    final locale =
        _config.locale ?? Localizations.maybeLocaleOf(context)?.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Multi-month layouts need room; collapse to one below ~600px so the
        // same config works on phone and tablet.
        final maxByWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth / 300).floor().clamp(1, 4)
            : 1;
        _resolvedVisibleMonths = _config.visibleMonths.clamp(1, maxByWidth);

        return Padding(
          padding: theme.padding!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The From/To header has no meaning for a set of loose days.
              if (_config.showHeader && !_isMulti) ...[
                _buildHeader(theme, labels, locale),
                const SizedBox(height: 10),
                Divider(height: 1, color: theme.borderColor),
                const SizedBox(height: 6),
              ],
              _buildNavigation(theme, locale),
              const SizedBox(height: 4),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: switch (_step) {
                  _PickerStep.years => _buildYearGrid(theme),
                  _PickerStep.months => _buildMonthGrid(theme, locale),
                  _PickerStep.days => _buildCalendar(theme),
                },
              ),
              if (_hasTime && _step == _PickerStep.days)
                TimeRow(
                  startTime: _startTime ?? _config.initialStartTime,
                  endTime: _endTime ?? _config.initialEndTime,
                  showEndTime: !_isSingle,
                  startLabel: labels.startTime,
                  endLabel: labels.endTime,
                  minuteInterval: _config.minuteInterval,
                  use24HourFormat: _config.use24HourFormat,
                  theme: theme,
                  onStartChanged: (t) {
                    setState(() => _startTime = t);
                    _notifyChanged();
                  },
                  onEndChanged: (t) {
                    setState(() => _endTime = t);
                    _notifyChanged();
                  },
                ),
              if (_config.showDayCount) _buildStatusLine(theme, labels),
              if (_presets.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPresets(theme),
              ],
              if (widget.showActions) ...[
                const SizedBox(height: 14),
                _buildActions(theme, labels),
              ],
            ],
          ),
        );
      },
    );
  }

  List<DateRangePreset> get _presets =>
      _config.presets ??
      DateRangePreset.defaults(
        firstDayOfWeek: _config.firstDayOfWeek,
        showToday: _config.showTodayPreset,
        showThisWeek: _config.showThisWeekPreset,
        showThisMonth: _config.showThisMonthPreset,
        showLast7Days: _config.showLast7DaysPreset,
        showLast30Days: _config.showLast30DaysPreset,
      );

  Widget _buildHeader(
    DateRangePickerTheme theme,
    DateRangePickerLabels labels,
    String? locale,
  ) {
    final format = DateFormat(_config.headerDateFormat, locale);
    String fmt(DateTime? d) => d == null ? labels.empty : format.format(d);

    if (_isSingle) {
      return Center(
        child: Text(
          fmt(_start),
          style: theme.headerValueStyle?.copyWith(
            color: _start != null ? theme.primaryColor : theme.mutedTextColor,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _HeaderField(
            label: labels.from,
            value: fmt(_start),
            active: !_selectingEnd && _start != null,
            theme: theme,
          ),
        ),
        Container(width: 1, height: 34, color: theme.borderColor),
        Expanded(
          child: _HeaderField(
            label: labels.to,
            value: fmt(_end),
            active: _selectingEnd || _end != null,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigation(DateRangePickerTheme theme, String? locale) {
    final format = DateFormat(_config.monthTitleFormat, locale);
    final title = _resolvedVisibleMonths > 1
        ? '${format.format(_focusedMonth)} — '
              '${format.format(addMonths(_focusedMonth, _resolvedVisibleMonths - 1))}'
        : format.format(_focusedMonth);

    final onDays = _step == _PickerStep.days;
    final canPrev = onDays && _canPage(-1);
    final canNext = onDays && _canPage(1);

    return Row(
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
          enabled: canPrev,
          theme: theme,
          onPressed: () => _pageController.previousPage(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          ),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _config.enableYearPicker
                ? () => setState(
                    () => _step = _step == _PickerStep.days
                        ? _PickerStep.years
                        : _PickerStep.days,
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      switch (_step) {
                        _PickerStep.years => _config.labels.selectYear,
                        _PickerStep.months => '${_focusedMonth.year}',
                        _PickerStep.days => title,
                      },
                      style: theme.monthTitleStyle,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_config.enableYearPicker)
                    Icon(
                      _showYearGrid
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      size: 20,
                      color: theme.mutedTextColor,
                    ),
                ],
              ),
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
          enabled: canNext,
          theme: theme,
          onPressed: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }

  /// Height of the calendar body, fixed at six rows plus the weekday header so
  /// the surface does not resize when paging between months of unequal length.
  double _calendarHeight(DateRangePickerTheme theme) =>
      theme.dayExtent! * 6 + 28;

  Widget _buildCalendar(DateRangePickerTheme theme) {
    return SizedBox(
      height: _calendarHeight(theme),
      child: PageView.builder(
        controller: _pageController,
        physics: _config.enableSwipe
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        onPageChanged: (page) {
          setState(() => _focusedMonth = _monthForPage(page));
          widget.onMonthChanged?.call(_focusedMonth);
        },
        itemBuilder: (context, page) {
          final month = _monthForPage(page);
          if (_resolvedVisibleMonths == 1) {
            return _monthGrid(month, theme);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _resolvedVisibleMonths; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: _monthGrid(addMonths(month, i), theme)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _monthGrid(DateTime month, DateRangePickerTheme theme) {
    return MonthGrid(
      month: month,
      start: _start,
      end: _end,
      hovered: _hovered,
      config: _config,
      theme: theme,
      selectingEnd: _selectingEnd && !_isSingle,
      selectedDays: _isMulti ? _multi.dates.toSet() : null,
      onDayTap: _onDayTap,
      onDayHover: (day) {
        if (!_selectingEnd || _isSingle) return;
        if (isSameDay(day, _hovered)) return;
        setState(() => _hovered = day);
      },
    );
  }

  Widget _buildYearGrid(DateRangePickerTheme theme) {
    final now = DateTime.now();
    final firstYear =
        _config.firstYear ?? _config.minDate?.year ?? now.year - 100;
    final lastYear =
        _config.lastYear ??
        _config.maxDate?.year ??
        (_isBirthday ? now.year : now.year + 10);

    return YearGrid(
      firstYear: firstYear,
      lastYear: lastYear < firstYear ? firstYear : lastYear,
      selectedYear: _focusedMonth.year,
      theme: theme,
      height: _calendarHeight(theme),
      onYearSelected: (year) {
        // Birthday entry drills down to the month; every other mode jumps
        // straight back to the calendar.
        setState(
          () => _step = _isBirthday ? _PickerStep.months : _PickerStep.days,
        );
        _goToMonth(DateTime(year, _focusedMonth.month));
      },
    );
  }

  Widget _buildMonthGrid(DateRangePickerTheme theme, String? locale) {
    return MonthPickerGrid(
      year: _focusedMonth.year,
      selectedMonth: _focusedMonth.month,
      minDate: _config.minDate,
      maxDate: _config.maxDate,
      theme: theme,
      height: _calendarHeight(theme),
      locale: locale,
      onMonthSelected: (month) {
        setState(() => _step = _PickerStep.days);
        _goToMonth(DateTime(_focusedMonth.year, month));
      },
    );
  }

  Widget _buildStatusLine(
    DateRangePickerTheme theme,
    DateRangePickerLabels labels,
  ) {
    final range = _currentRange;
    // Surface a constraint violation as soon as the selection is complete,
    // so a disabled Apply button always comes with a reason.
    final error = range == null ? null : _validate(range);
    final String summary;
    if (_isMulti) {
      summary = _multi.isEmpty ? '' : labels.daysSelected(_multi.count);
    } else if (range == null) {
      summary = '';
    } else if (_isBirthday) {
      summary = labels.age(range.ageInYears());
    } else if (_isSingle) {
      summary = '';
    } else {
      summary = labels.daysSelected(range.days);
    }
    final text = error ?? summary;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Text(
          text,
          key: ValueKey(text),
          textAlign: TextAlign.center,
          style: theme.headerLabelStyle?.copyWith(
            color: error != null
                ? Theme.of(context).colorScheme.error
                : theme.mutedTextColor,
            fontWeight: error != null ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPresets(DateRangePickerTheme theme) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final preset = _presets[i];
          return _PresetChip(
            label: preset.label,
            theme: theme,
            onTap: () => _applyPreset(preset),
          );
        },
      ),
    );
  }

  Widget _buildActions(
    DateRangePickerTheme theme,
    DateRangePickerLabels labels,
  ) {
    final range = _currentRange;
    final canApply = _isMulti
        ? _multi.isNotEmpty
        : range != null && _validate(range) == null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(theme.buttonRadius!),
    );
    final padding = EdgeInsets.symmetric(vertical: theme.buttonPadding!);

    return Row(
      children: [
        if (_config.showClearButton) ...[
          Expanded(
            child: TextButton(
              onPressed: (_isMulti ? _multi.isEmpty : _start == null)
                  ? null
                  : _clear,
              style: TextButton.styleFrom(
                foregroundColor: theme.mutedTextColor,
                shape: shape,
                padding: padding,
              ),
              child: Text(labels.clear, style: theme.chipStyle),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primaryColor,
              side: BorderSide(color: theme.borderColor!, width: 1.4),
              shape: shape,
              padding: padding,
            ),
            child: Text(
              labels.cancel,
              style: theme.chipStyle?.copyWith(color: theme.primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: canApply ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.onPrimaryColor,
              disabledBackgroundColor: theme.primaryColor!.withValues(
                alpha: 0.35,
              ),
              disabledForegroundColor: theme.onPrimaryColor!.withValues(
                alpha: 0.7,
              ),
              elevation: 0,
              shape: shape,
              padding: padding,
            ),
            child: Text(
              labels.apply,
              style: theme.chipStyle?.copyWith(color: theme.onPrimaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderField extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final DateRangePickerTheme theme;

  const _HeaderField({
    required this.label,
    required this.value,
    required this.active,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: theme.headerLabelStyle),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.headerValueStyle?.copyWith(
            color: active ? theme.primaryColor : theme.mutedTextColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final DateRangePickerTheme theme;
  final VoidCallback onPressed;

  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.theme,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 26,
        color: enabled ? theme.primaryColor : theme.disabledColor,
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final DateRangePickerTheme theme;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(theme.chipRadius!);
    return Material(
      color: theme.chipColor,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: theme.chipBorderColor!),
          ),
          child: Text(label, style: theme.chipStyle),
        ),
      ),
    );
  }
}
