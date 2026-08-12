// ignore_for_file: non_constant_identifier_names — pickers use the
// DateRangePicker* PascalCase family by design.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import 'time_picker_style.dart';

/// A start/end pair returned by [DateRangePickerTimeRange].
typedef StudioTimeRange = ({TimeOfDay start, TimeOfDay end});

/// Shows a wheel-based picker for a start and end time, resolving to a
/// [StudioTimeRange], or `null` when dismissed.
///
/// A single dialog carries a Start/End segmented control above shared hour and
/// minute wheels, styled from [style] like [DateRangePickerTime].
///
/// ```dart
/// final range = await DateRangePickerTimeRange(
///   context,
///   initialStart: const TimeOfDay(hour: 9, minute: 0),
///   initialEnd: const TimeOfDay(hour: 17, minute: 0),
/// );
/// if (range != null) print('${range.start} → ${range.end}');
/// ```
Future<StudioTimeRange?> DateRangePickerTimeRange(
  BuildContext context, {
  TimeOfDay initialStart = const TimeOfDay(hour: 9, minute: 0),
  TimeOfDay initialEnd = const TimeOfDay(hour: 17, minute: 0),
  TimePickerStyle? style,
  int minuteInterval = 1,
  bool? use24HourFormat,
  String startLabel = 'Start',
  String endLabel = 'End',
  String cancelLabel = 'Cancel',
  String confirmLabel = 'OK',
}) {
  final use24 = use24HourFormat ?? MediaQuery.alwaysUse24HourFormatOf(context);
  final resolved = (style ?? const TimePickerStyle()).resolve(context);
  return showDialog<StudioTimeRange>(
    context: context,
    builder: (context) => _TimeRangePicker(
      style: resolved,
      initialStart: initialStart,
      initialEnd: initialEnd,
      minuteInterval: minuteInterval < 1 ? 1 : minuteInterval,
      use24Hour: use24,
      startLabel: startLabel,
      endLabel: endLabel,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
    ),
  );
}

class _TimeRangePicker extends StatefulWidget {
  final TimePickerStyle style;
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final int minuteInterval;
  final bool use24Hour;
  final String startLabel;
  final String endLabel;
  final String cancelLabel;
  final String confirmLabel;

  const _TimeRangePicker({
    required this.style,
    required this.initialStart,
    required this.initialEnd,
    required this.minuteInterval,
    required this.use24Hour,
    required this.startLabel,
    required this.endLabel,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  @override
  State<_TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<_TimeRangePicker> {
  late int _startHour, _startMinute, _endHour, _endMinute;
  bool _editingStart = true;

  late final List<int> _hours;
  late final List<int> _minutes;
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  TimePickerStyle get _style => widget.style;
  double get _extent => _style.itemExtent!;
  bool get _use24 => widget.use24Hour;

  int get _hour => _editingStart ? _startHour : _endHour;
  int get _minute => _editingStart ? _startMinute : _endMinute;
  bool get _isAm => _hour < 12;

  @override
  void initState() {
    super.initState();
    _minutes = [for (var m = 0; m < 60; m += widget.minuteInterval) m];
    _hours = _use24
        ? [for (var h = 0; h < 24; h++) h]
        : [12, for (var h = 1; h < 12; h++) h];

    _startHour = widget.initialStart.hour;
    _startMinute = _nearestMinute(widget.initialStart.minute);
    _endHour = widget.initialEnd.hour;
    _endMinute = _nearestMinute(widget.initialEnd.minute);

    _hourCtrl = FixedExtentScrollController(
      initialItem: _hours.indexOf(_displayHour(_startHour)),
    );
    _minuteCtrl = FixedExtentScrollController(
      initialItem: _minutes.indexOf(_startMinute),
    );
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  int _nearestMinute(int m) {
    var best = _minutes.first;
    for (final v in _minutes) {
      if ((v - m).abs() < (best - m).abs()) best = v;
    }
    return best;
  }

  int _displayHour(int hour24) {
    if (_use24) return hour24;
    final h = hour24 % 12;
    return h == 0 ? 12 : h;
  }

  int _wrap(int index, int length) => ((index % length) + length) % length;

  void _setActiveHour(int hour24) {
    if (_editingStart) {
      _startHour = hour24;
    } else {
      _endHour = hour24;
    }
  }

  void _setActiveMinute(int minute) {
    if (_editingStart) {
      _startMinute = minute;
    } else {
      _endMinute = minute;
    }
  }

  void _onHourChanged(int rawIndex) {
    final display = _hours[_wrap(rawIndex, _hours.length)];
    HapticFeedback.selectionClick();
    setState(() {
      if (_use24) {
        _setActiveHour(display);
      } else {
        final base = display % 12;
        _setActiveHour(_isAm ? base : base + 12);
      }
    });
  }

  void _onMinuteChanged(int rawIndex) {
    HapticFeedback.selectionClick();
    setState(
      () => _setActiveMinute(_minutes[_wrap(rawIndex, _minutes.length)]),
    );
  }

  void _setPeriod(bool am) {
    if (am == _isAm) return;
    HapticFeedback.selectionClick();
    setState(() => _setActiveHour(am ? _hour - 12 : _hour + 12));
  }

  void _switchEndpoint(bool editingStart) {
    if (editingStart == _editingStart) return;
    setState(() => _editingStart = editingStart);
    _hourCtrl.jumpToItem(_hours.indexOf(_displayHour(_hour)));
    _minuteCtrl.jumpToItem(_minutes.indexOf(_minute));
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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _endpointToggle(s),
            const SizedBox(height: 18),
            _wheels(s),
            if (!_use24) ...[const SizedBox(height: 16), _periodToggle(s)],
            const SizedBox(height: 22),
            _actions(s),
          ],
        ),
      ),
    );
  }

  Widget _endpointToggle(TimePickerStyle s) {
    Widget tab(String label, String value, bool active) => Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _switchEndpoint(value == 'start'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? s.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            '$label · ${_format(value == 'start' ? _startTime : _endTime)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? s.onAccentColor : s.mutedColor,
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: s.bandColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab(widget.startLabel, 'start', _editingStart),
          const SizedBox(width: 4),
          tab(widget.endLabel, 'end', !_editingStart),
        ],
      ),
    );
  }

  TimeOfDay get _startTime => TimeOfDay(hour: _startHour, minute: _startMinute);
  TimeOfDay get _endTime => TimeOfDay(hour: _endHour, minute: _endMinute);

  String _format(TimeOfDay t) {
    final m = t.minute.toString().padLeft(2, '0');
    if (_use24) return '${t.hour.toString().padLeft(2, '0')}:$m';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '$h:$m';
  }

  Widget _wheels(TimePickerStyle s) {
    return SizedBox(
      height: _extent * 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
              _wheel(
                controller: _hourCtrl,
                values: _hours,
                selected: _displayHour(_hour),
                pad: _use24,
                onChanged: _onHourChanged,
              ),
              Text(':', style: s.valueStyle?.copyWith(color: s.mutedColor)),
              _wheel(
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
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required List<int> values,
    required int selected,
    required bool pad,
    required ValueChanged<int> onChanged,
  }) {
    final s = _style;
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
              for (final v in values)
                Center(
                  child: Text(
                    pad ? v.toString().padLeft(2, '0') : v.toString(),
                    style: s.valueStyle?.copyWith(
                      color: v == selected ? s.accentColor : s.textColor,
                      fontWeight: v == selected
                          ? FontWeight.w700
                          : s.valueStyle?.fontWeight,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodToggle(TimePickerStyle s) {
    Widget btn(String label, bool active) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _setPeriod(label == 'AM'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: active ? s.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active ? s.onAccentColor : s.mutedColor,
          ),
        ),
      ),
    );

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: s.bandColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [btn('AM', _isAm), btn('PM', !_isAm)],
        ),
      ),
    );
  }

  Widget _actions(TimePickerStyle s) {
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
            onPressed: () =>
                Navigator.of(context).pop((start: _startTime, end: _endTime)),
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
