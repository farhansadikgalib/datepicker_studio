// ignore_for_file: non_constant_identifier_names — pickers use the
// DateRangePicker* PascalCase family by design.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import 'time_picker_style.dart';

/// Shows the package's own time picker and resolves to the chosen [TimeOfDay],
/// or `null` when dismissed.
///
/// Unlike the platform `showTimePicker`, this presents a pair of scrollable
/// wheels for the hour and minute sharing one selection band, with a compact
/// AM/PM toggle beside them. Everything is coloured from [style]; pass
/// [TimePickerStyle.from] for a one-colour setup or [TimePickerStyle.fromTheme]
/// to match a calendar. The minute wheel only offers multiples of
/// [minuteInterval].
///
/// When [use24HourFormat] is null the ambient locale's convention is used.
Future<TimeOfDay?> DateRangePickerTime(
  BuildContext context, {
  required TimeOfDay initialTime,
  TimePickerStyle? style,
  int minuteInterval = 1,
  bool? use24HourFormat,
  String title = 'Select time',
  String cancelLabel = 'Cancel',
  String confirmLabel = 'OK',
}) {
  final use24 = use24HourFormat ?? MediaQuery.alwaysUse24HourFormatOf(context);
  final resolved = (style ?? const TimePickerStyle()).resolve(context);
  return showDialog<TimeOfDay>(
    context: context,
    builder: (context) => _StudioTimePicker(
      initialTime: initialTime,
      style: resolved,
      minuteInterval: minuteInterval < 1 ? 1 : minuteInterval,
      use24Hour: use24,
      title: title,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
    ),
  );
}

class _StudioTimePicker extends StatefulWidget {
  /// A style with every field already resolved to a non-null value.
  final TimePickerStyle style;
  final TimeOfDay initialTime;
  final int minuteInterval;
  final bool use24Hour;
  final String title;
  final String cancelLabel;
  final String confirmLabel;

  const _StudioTimePicker({
    required this.style,
    required this.initialTime,
    required this.minuteInterval,
    required this.use24Hour,
    required this.title,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  @override
  State<_StudioTimePicker> createState() => _StudioTimePickerState();
}

class _StudioTimePickerState extends State<_StudioTimePicker> {
  /// Hour of day, 0–23; the single source of truth for the selection.
  late int _hour;
  late int _minute;

  /// Wheel value lists. Hours are the display values (0–23 or 1–12); minutes
  /// are every allowed increment.
  late final List<int> _hours;
  late final List<int> _minutes;

  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  TimePickerStyle get _style => widget.style;
  double get _extent => _style.itemExtent!;
  bool get _use24 => widget.use24Hour;
  bool get _isAm => _hour < 12;

  @override
  void initState() {
    super.initState();
    _minutes = [for (var m = 0; m < 60; m += widget.minuteInterval) m];
    _hours = _use24
        ? [for (var h = 0; h < 24; h++) h]
        : [12, for (var h = 1; h < 12; h++) h];

    _hour = widget.initialTime.hour;
    _minute = _nearestMinute(widget.initialTime.minute);

    _hourCtrl = FixedExtentScrollController(
      initialItem: _hours.indexOf(_hourDisplay),
    );
    _minuteCtrl = FixedExtentScrollController(
      initialItem: _minutes.indexOf(_minute),
    );
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  /// Snaps an arbitrary minute to the closest allowed increment.
  int _nearestMinute(int m) {
    var best = _minutes.first;
    for (final v in _minutes) {
      if ((v - m).abs() < (best - m).abs()) best = v;
    }
    return best;
  }

  /// The current hour as it appears on the wheel (1–12 in 12-hour mode).
  int get _hourDisplay {
    if (_use24) return _hour;
    final h = _hour % 12;
    return h == 0 ? 12 : h;
  }

  /// Loops a raw wheel index into the value list's range.
  int _wrap(int index, int length) => ((index % length) + length) % length;

  void _onHourChanged(int rawIndex) {
    final display = _hours[_wrap(rawIndex, _hours.length)];
    HapticFeedback.selectionClick();
    setState(() {
      if (_use24) {
        _hour = display;
      } else {
        final base = display % 12; // 12 → 0
        _hour = _isAm ? base : base + 12;
      }
    });
  }

  void _onMinuteChanged(int rawIndex) {
    HapticFeedback.selectionClick();
    setState(() => _minute = _minutes[_wrap(rawIndex, _minutes.length)]);
  }

  void _setPeriod(bool am) {
    if (am == _isAm) return;
    HapticFeedback.selectionClick();
    setState(() => _hour = am ? _hour - 12 : _hour + 12);
  }

  /// Animates [controller] so the value at list index [target] lands in the
  /// centre, taking the shortest path around the looping wheel.
  void _tapToSelect(
    FixedExtentScrollController controller,
    int target,
    int length,
  ) {
    if (!controller.hasClients) return;
    final current = controller.selectedItem;
    var delta = target - _wrap(current, length);
    if (delta > length / 2) delta -= length;
    if (delta < -length / 2) delta += length;
    if (delta == 0) return;
    controller.animateToItem(
      current + delta,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Dialog(
      backgroundColor: s.backgroundColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(s.borderRadius!),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.title.isNotEmpty) ...[
              Text(widget.title, style: s.titleStyle),
              const SizedBox(height: 20),
            ],
            _buildWheels(s),
            const SizedBox(height: 24),
            _buildActions(s),
          ],
        ),
      ),
    );
  }

  Widget _buildWheels(TimePickerStyle s) {
    return SizedBox(
      height: _extent * 5,
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // One continuous band under the hour and minute columns.
                IgnorePointer(
                  child: Container(
                    height: _extent,
                    decoration: BoxDecoration(
                      color: s.bandColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWheel(
                      s,
                      controller: _hourCtrl,
                      values: _hours,
                      selected: _hourDisplay,
                      pad: _use24,
                      onChanged: _onHourChanged,
                    ),
                    Text(
                      ':',
                      style: s.valueStyle?.copyWith(color: s.mutedColor),
                    ),
                    _buildWheel(
                      s,
                      controller: _minuteCtrl,
                      values: _minutes,
                      selected: _minute,
                      pad: true,
                      onChanged: _onMinuteChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_use24) ...[const SizedBox(width: 14), _buildPeriodToggle(s)],
        ],
      ),
    );
  }

  Widget _buildWheel(
    TimePickerStyle s, {
    required FixedExtentScrollController controller,
    required List<int> values,
    required int selected,
    required bool pad,
    required ValueChanged<int> onChanged,
  }) {
    // Fade the values away from the centre for depth without a hard edge.
    return SizedBox(
      width: 60,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.25, 0.75, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: _extent,
          perspective: 0.003,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          overAndUnderCenterOpacity: 0.4,
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildLoopingListDelegate(
            children: [
              for (var i = 0; i < values.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _tapToSelect(controller, i, values.length),
                  child: Center(
                    child: Text(
                      pad
                          ? values[i].toString().padLeft(2, '0')
                          : values[i].toString(),
                      style: s.valueStyle?.copyWith(
                        color: values[i] == selected
                            ? s.accentColor
                            : s.textColor,
                        fontWeight: values[i] == selected
                            ? FontWeight.w700
                            : s.valueStyle?.fontWeight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodToggle(TimePickerStyle s) {
    return Container(
      width: 58,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: s.bandColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _periodButton(s, 'AM', _isAm),
          const SizedBox(height: 4),
          _periodButton(s, 'PM', !_isAm),
        ],
      ),
    );
  }

  Widget _periodButton(TimePickerStyle s, String label, bool active) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _setPeriod(label == 'AM'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? s.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? s.onAccentColor : s.mutedColor,
          ),
        ),
      ),
    );
  }

  Widget _buildActions(TimePickerStyle s) {
    final buttonRadius = (s.borderRadius! * 0.5).clamp(10.0, 16.0);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );
    const padding = EdgeInsets.symmetric(vertical: 14);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: s.accentColor,
              side: BorderSide(color: s.borderColor!, width: 1.4),
              shape: shape,
              padding: padding,
            ),
            child: Text(
              widget.cancelLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(TimeOfDay(hour: _hour, minute: _minute)),
            style: FilledButton.styleFrom(
              backgroundColor: s.accentColor,
              foregroundColor: s.onAccentColor,
              shape: shape,
              padding: padding,
            ),
            child: Text(
              widget.confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
