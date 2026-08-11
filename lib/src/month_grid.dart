import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'date_utils.dart';
import 'models.dart';
import 'theme.dart';

/// How a single day cell should be painted.
enum _DayFill { none, range, edge }

/// One month of day cells, including the weekday header row.
///
/// This is a pure presentation widget: it holds no selection state and simply
/// renders the [start]/[end] it is given, reporting taps and hovers upward.
class MonthGrid extends StatelessWidget {
  /// Any date within the month to render.
  final DateTime month;
  final DateTime? start;
  final DateTime? end;

  /// Endpoint being previewed under the pointer while the second endpoint is
  /// still unchosen. Drives the hover range on desktop and web.
  final DateTime? hovered;

  final DateRangePickerConfig config;
  final DateRangePickerTheme theme;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime?> onDayHover;

  /// Whether the second endpoint is being chosen, which enables hover preview.
  final bool selectingEnd;

  const MonthGrid({
    super.key,
    required this.month,
    required this.start,
    required this.end,
    required this.hovered,
    required this.config,
    required this.theme,
    required this.onDayTap,
    required this.onDayHover,
    required this.selectingEnd,
  });

  /// Whether [day] can be selected given bounds, the predicate, and — while
  /// choosing the second endpoint — [DateRangePickerConfig.maxRangeLength].
  bool _isSelectable(DateTime day) {
    if (!isWithin(day, config.minDate, config.maxDate)) return false;
    if (config.selectableDayPredicate?.call(day) == false) return false;

    final max = config.maxRangeLength;
    if (max != null &&
        selectingEnd &&
        start != null &&
        config.mode == DateRangeMode.range &&
        inclusiveDayCount(start!, day) > max) {
      return false;
    }
    return true;
  }

  /// The endpoints to paint, substituting [hovered] for the missing end so the
  /// range fills in live as the pointer moves.
  (DateTime?, DateTime?) get _effectiveRange {
    if (end != null || start == null) return (start, end);
    if (!selectingEnd || hovered == null) return (start, end);
    final h = dateOnly(hovered!);
    final s = dateOnly(start!);
    return h.isBefore(s) ? (h, s) : (s, h);
  }

  @override
  Widget build(BuildContext context) {
    final (rangeStart, rangeEnd) = _effectiveRange;
    final total = daysInMonth(month.year, month.month);
    final first = DateTime(month.year, month.month, 1);

    // Blank cells before the 1st, honouring the configured first weekday.
    final leading = (first.weekday - config.firstDayOfWeek + 7) % 7;
    final rows = ((leading + total) / 7).ceil();
    final today = dateOnly(DateTime.now());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WeekdayHeader(config: config, theme: theme),
        const SizedBox(height: 4),
        for (var row = 0; row < rows; row++)
          Row(
            children: List.generate(7, (col) {
              final dayNum = row * 7 + col - leading + 1;
              if (dayNum < 1 || dayNum > total) {
                return Expanded(child: SizedBox(height: theme.dayExtent));
              }

              final day = DateTime(month.year, month.month, dayNum);
              final isStart = isSameDay(day, rangeStart);
              final isEnd = isSameDay(day, rangeEnd);
              final inRange =
                  rangeStart != null &&
                  rangeEnd != null &&
                  day.isAfter(dateOnly(rangeStart)) &&
                  day.isBefore(dateOnly(rangeEnd));

              return Expanded(
                child: _DayCell(
                  day: day,
                  label: '$dayNum',
                  fill: (isStart || isEnd)
                      ? _DayFill.edge
                      : inRange
                      ? _DayFill.range
                      : _DayFill.none,
                  // Only bridge the gap to a neighbour that is itself filled,
                  // so the connector never leaks past the range's edges.
                  extendLeft: (inRange || (isEnd && !isStart)) && col != 0,
                  extendRight: (inRange || (isStart && !isEnd)) && col != 6,
                  isToday: config.highlightToday && isSameDay(day, today),
                  enabled: _isSelectable(day),
                  theme: theme,
                  onTap: () => onDayTap(day),
                  onHover: onDayHover,
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final DateRangePickerConfig config;
  final DateRangePickerTheme theme;

  const _WeekdayHeader({required this.config, required this.theme});

  @override
  Widget build(BuildContext context) {
    final locale =
        config.locale ?? Localizations.maybeLocaleOf(context)?.toString();
    final format = DateFormat.E(locale);
    // 2024-01-01 was a Monday, giving a stable anchor for weekday names.
    final monday = DateTime(2024, 1, 1);

    return Row(
      children: List.generate(7, (i) {
        final day = addDays(monday, (config.firstDayOfWeek - 1 + i) % 7);
        return Expanded(
          child: Center(
            child: Text(
              format.format(day),
              style: theme.weekdayStyle,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final String label;
  final _DayFill fill;
  final bool extendLeft;
  final bool extendRight;
  final bool isToday;
  final bool enabled;
  final DateRangePickerTheme theme;
  final VoidCallback onTap;
  final ValueChanged<DateTime?> onHover;

  const _DayCell({
    required this.day,
    required this.label,
    required this.fill,
    required this.extendLeft,
    required this.extendRight,
    required this.isToday,
    required this.enabled,
    required this.theme,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final isEdge = fill == _DayFill.edge;
    final inRange = fill == _DayFill.range;

    final Color foreground;
    if (isEdge) {
      foreground = theme.onPrimaryColor!;
    } else if (!enabled) {
      foreground = theme.disabledColor!;
    } else if (inRange) {
      foreground = theme.onRangeColor!;
    } else {
      foreground = theme.textColor!;
    }

    final radius = Radius.circular(theme.dayRadius!);
    final height = theme.dayExtent!;

    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: isEdge || inRange,
      label: DateFormat.yMMMMd(
        Localizations.maybeLocaleOf(context)?.toString(),
      ).format(day),
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => enabled ? onHover(day) : null,
        onExit: (_) => onHover(null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The band spans the full cell width so adjacent in-range cells
                // join seamlessly; on an edge cell it covers only the half
                // facing the rest of the range, leaving the outer half clear
                // for the rounded pill.
                final width = constraints.maxWidth;
                final inset = ((width - height) / 2).clamp(0.0, width / 2);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (inRange || (isEdge && (extendLeft || extendRight)))
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: extendLeft ? 0 : inset + height / 2,
                            right: extendRight ? 0 : inset + height / 2,
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: theme.rangeColor,
                          ),
                        ),
                      ),
                    // The rounded pill itself.
                    // The endpoint pill, and the day number itself. In-range
                    // cells draw no box of their own — the band behind them
                    // already supplies the fill.
                    Container(
                      width: height,
                      height: height,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isEdge ? theme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.all(radius),
                        border: isToday && !isEdge
                            ? Border.all(color: theme.todayColor!, width: 1.4)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: theme.dayStyle?.copyWith(
                          color: foreground,
                          fontWeight: isEdge
                              ? FontWeight.w700
                              : isToday
                              ? FontWeight.w600
                              : FontWeight.w400,
                          // Struck-through reads as "unavailable" without
                          // relying on colour alone.
                          decoration: enabled
                              ? TextDecoration.none
                              : TextDecoration.lineThrough,
                          decorationColor: theme.disabledColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
