import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

/// Grid of the twelve months, used as the middle step of the
/// [DateRangeMode.birthday] drill-down.
class MonthPickerGrid extends StatelessWidget {
  /// Year the months belong to, used to disable months outside the bounds.
  final int year;

  /// Currently focused month, 1-12.
  final int selectedMonth;

  /// Earliest selectable day, or null when unbounded.
  final DateTime? minDate;

  /// Latest selectable day, or null when unbounded.
  final DateTime? maxDate;

  final DateRangePickerTheme theme;
  final ValueChanged<int> onMonthSelected;

  /// Height of the grid, matched to the calendar it replaces.
  final double height;

  /// Locale used for month names.
  final String? locale;

  const MonthPickerGrid({
    super.key,
    required this.year,
    required this.selectedMonth,
    required this.minDate,
    required this.maxDate,
    required this.theme,
    required this.onMonthSelected,
    required this.height,
    this.locale,
  });

  /// Whether any day of [month] falls within the configured bounds.
  bool _isSelectable(int month) {
    final firstOfMonth = DateTime(year, month, 1);
    final lastOfMonth = DateTime(year, month + 1, 0);
    if (minDate != null && lastOfMonth.isBefore(minDate!)) return false;
    if (maxDate != null && firstOfMonth.isAfter(maxDate!)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat.MMM(locale);

    return SizedBox(
      height: height,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: theme.dayExtent!,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final selected = month == selectedMonth;
          final enabled = _isSelectable(month);

          return Material(
            color: selected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: enabled ? () => onMonthSelected(month) : null,
              child: Center(
                child: Text(
                  format.format(DateTime(year, month)),
                  style: theme.dayStyle?.copyWith(
                    color: !enabled
                        ? theme.disabledColor
                        : selected
                        ? theme.onPrimaryColor
                        : theme.textColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
