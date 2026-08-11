import 'package:flutter/material.dart';

import 'theme.dart';

/// Scrollable grid of years, shown when the month title is tapped.
class YearGrid extends StatelessWidget {
  final int firstYear;
  final int lastYear;
  final int selectedYear;
  final DateRangePickerTheme theme;
  final ValueChanged<int> onYearSelected;

  /// Height of the scroll area, matched to the calendar it replaces so the
  /// surface does not jump when toggling.
  final double height;

  const YearGrid({
    super.key,
    required this.firstYear,
    required this.lastYear,
    required this.selectedYear,
    required this.theme,
    required this.onYearSelected,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final count = lastYear - firstYear + 1;
    // Open with the selected year roughly centred: three rows above it.
    final initialRow = ((selectedYear - firstYear) ~/ 3 - 2).clamp(
      0,
      (count / 3).ceil(),
    );

    return SizedBox(
      height: height,
      child: GridView.builder(
        controller: ScrollController(
          initialScrollOffset: initialRow * (theme.dayExtent! + 12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: theme.dayExtent!,
        ),
        itemCount: count,
        itemBuilder: (context, index) {
          final year = firstYear + index;
          final selected = year == selectedYear;
          return Material(
            color: selected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onYearSelected(year),
              child: Center(
                child: Text(
                  '$year',
                  style: theme.dayStyle?.copyWith(
                    color: selected ? theme.onPrimaryColor : theme.textColor,
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
