import 'package:flutter/material.dart';

import 'theme.dart';

/// The start/end time fields shown below the calendar in
/// [DateRangeMode.dateTime].
///
/// Each field opens the platform time picker, snapping the result to
/// [minuteInterval].
class TimeRow extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  /// Hidden when the picker is in single-endpoint mode.
  final bool showEndTime;

  final String startLabel;
  final String endLabel;
  final int minuteInterval;
  final bool? use24HourFormat;
  final DateRangePickerTheme theme;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;

  const TimeRow({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.showEndTime,
    required this.startLabel,
    required this.endLabel,
    required this.minuteInterval,
    required this.use24HourFormat,
    required this.theme,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  /// Rounds [time] to the nearest allowed increment, rolling 60 back to 00.
  TimeOfDay _snap(TimeOfDay time) {
    if (minuteInterval <= 1) return time;
    final snapped =
        ((time.minute + minuteInterval / 2) ~/ minuteInterval) * minuteInterval;
    return snapped >= 60
        ? TimeOfDay(hour: (time.hour + 1) % 24, minute: 0)
        : TimeOfDay(hour: time.hour, minute: snapped);
  }

  Future<void> _pick(
    BuildContext context,
    TimeOfDay current,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: use24HourFormat == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: use24HourFormat),
              child: child!,
            ),
    );
    if (picked != null) onChanged(_snap(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: _TimeField(
              label: startLabel,
              time: startTime,
              theme: theme,
              use24HourFormat: use24HourFormat,
              onTap: () => _pick(context, startTime, onStartChanged),
            ),
          ),
          if (showEndTime) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                label: endLabel,
                time: endTime,
                theme: theme,
                use24HourFormat: use24HourFormat,
                onTap: () => _pick(context, endTime, onEndChanged),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final DateRangePickerTheme theme;
  final bool? use24HourFormat;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.time,
    required this.theme,
    required this.use24HourFormat,
    required this.onTap,
  });

  /// Formats [time], honouring an explicit 24-hour override when one is given
  /// and otherwise deferring to the locale's convention.
  String _format(BuildContext context) {
    final use24 =
        use24HourFormat ?? MediaQuery.alwaysUse24HourFormatOf(context);
    if (!use24) return time.format(context);
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _format(context);

    final radius = BorderRadius.circular(theme.timeFieldRadius!);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: theme.borderColor!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.headerLabelStyle),
                  const SizedBox(height: 2),
                  Text(
                    formatted,
                    style: theme.headerValueStyle?.copyWith(
                      color: theme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.schedule_rounded, size: 18, color: theme.mutedTextColor),
          ],
        ),
      ),
    );
  }
}
