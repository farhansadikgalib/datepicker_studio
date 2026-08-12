// ignore_for_file: non_constant_identifier_names — pickers use the
// DateRangePicker* PascalCase family by design.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'month_picker_grid.dart';
import 'theme.dart';
import 'year_grid.dart';

/// Shows a compact month picker and resolves to the first day of the chosen
/// month, or `null` when dismissed.
///
/// A year header with prev/next arrows sits above the twelve-month grid; months
/// outside [minDate]/[maxDate] are disabled.
///
/// ```dart
/// final month = await DateRangePickerMonth(context, initialMonth: DateTime(2026, 8));
/// ```
Future<DateTime?> DateRangePickerMonth(
  BuildContext context, {
  DateTime? initialMonth,
  DateTime? minDate,
  DateTime? maxDate,
  DateRangePickerTheme? theme,
  String? locale,
  String title = 'Select month',
}) {
  final resolved = (theme ?? const DateRangePickerTheme()).resolve(context);
  final loc = locale ?? Localizations.maybeLocaleOf(context)?.toString();
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _MonthPickerDialog(
      initialMonth: initialMonth ?? DateTime.now(),
      minDate: minDate,
      maxDate: maxDate,
      theme: resolved,
      locale: loc,
      title: title,
    ),
  );
}

/// Shows a scrollable year picker and resolves to the chosen year, or `null`
/// when dismissed.
///
/// [firstYear]/[lastYear] default to 100 years back and 10 years forward.
Future<int?> DateRangePickerYear(
  BuildContext context, {
  int? initialYear,
  int? firstYear,
  int? lastYear,
  DateRangePickerTheme? theme,
  String title = 'Select year',
}) {
  final resolved = (theme ?? const DateRangePickerTheme()).resolve(context);
  final now = DateTime.now();
  return showDialog<int>(
    context: context,
    builder: (context) {
      return _PickerShell(
        theme: resolved,
        title: title,
        child: YearGrid(
          firstYear: firstYear ?? now.year - 100,
          lastYear: lastYear ?? now.year + 10,
          selectedYear: initialYear ?? now.year,
          theme: resolved,
          height: 300,
          onYearSelected: (year) => Navigator.of(context).pop(year),
        ),
      );
    },
  );
}

/// A titled, rounded dialog surface shared by the month and year pickers.
class _PickerShell extends StatelessWidget {
  final DateRangePickerTheme theme;
  final String title;
  final Widget child;
  final Widget? headerTrailing;

  const _PickerShell({
    required this.theme,
    required this.title,
    required this.child,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.surfaceRadius!),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.monthTitleStyle)),
                ?headerTrailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime? minDate;
  final DateTime? maxDate;
  final DateRangePickerTheme theme;
  final String? locale;
  final String title;

  const _MonthPickerDialog({
    required this.initialMonth,
    required this.minDate,
    required this.maxDate,
    required this.theme,
    required this.locale,
    required this.title,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  bool get _canPrev => widget.minDate == null || _year > widget.minDate!.year;
  bool get _canNext => widget.maxDate == null || _year < widget.maxDate!.year;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final selectedMonth = _year == widget.initialMonth.year
        ? widget.initialMonth.month
        : 0;

    return _PickerShell(
      theme: theme,
      title: DateFormat.y(widget.locale).format(DateTime(_year)),
      headerTrailing: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: theme.primaryColor,
            onPressed: _canPrev ? () => setState(() => _year--) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: theme.primaryColor,
            onPressed: _canNext ? () => setState(() => _year++) : null,
          ),
        ],
      ),
      child: MonthPickerGrid(
        year: _year,
        selectedMonth: selectedMonth,
        minDate: widget.minDate,
        maxDate: widget.maxDate,
        theme: theme,
        height: 200,
        locale: widget.locale,
        onMonthSelected: (month) =>
            Navigator.of(context).pop(DateTime(_year, month)),
      ),
    );
  }
}
