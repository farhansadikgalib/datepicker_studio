// ignore_for_file: non_constant_identifier_names — pickers use the
// DateRangePicker* PascalCase family by design.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import 'time_picker_style.dart';

/// Shows a wheel-based picker for a [Duration] and resolves to the chosen value,
/// or `null` when dismissed.
///
/// Presents an hours wheel (0…[maxHours]) and a minutes wheel stepping by
/// [minuteInterval], styled from [style] exactly like [DateRangePickerTime].
///
/// ```dart
/// final d = await DateRangePickerDuration(
///   context,
///   initialDuration: const Duration(hours: 1, minutes: 30),
///   minuteInterval: 5,
/// );
/// ```
Future<Duration?> DateRangePickerDuration(
  BuildContext context, {
  Duration initialDuration = Duration.zero,
  TimePickerStyle? style,
  int minuteInterval = 1,
  int maxHours = 23,
  String title = 'Select duration',
  String hoursLabel = 'hours',
  String minutesLabel = 'min',
  String cancelLabel = 'Cancel',
  String confirmLabel = 'OK',
}) {
  final resolved = (style ?? const TimePickerStyle()).resolve(context);
  return showDialog<Duration>(
    context: context,
    builder: (context) => _DurationPicker(
      initialDuration: initialDuration,
      style: resolved,
      minuteInterval: minuteInterval < 1 ? 1 : minuteInterval,
      maxHours: maxHours < 0 ? 0 : maxHours,
      title: title,
      hoursLabel: hoursLabel,
      minutesLabel: minutesLabel,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
    ),
  );
}

class _DurationPicker extends StatefulWidget {
  final TimePickerStyle style;
  final Duration initialDuration;
  final int minuteInterval;
  final int maxHours;
  final String title;
  final String hoursLabel;
  final String minutesLabel;
  final String cancelLabel;
  final String confirmLabel;

  const _DurationPicker({
    required this.style,
    required this.initialDuration,
    required this.minuteInterval,
    required this.maxHours,
    required this.title,
    required this.hoursLabel,
    required this.minutesLabel,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  @override
  State<_DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<_DurationPicker> {
  late int _hours;
  late int _minutes;
  late final List<int> _hourValues;
  late final List<int> _minuteValues;
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  TimePickerStyle get _style => widget.style;
  double get _extent => _style.itemExtent!;

  @override
  void initState() {
    super.initState();
    _hourValues = [for (var h = 0; h <= widget.maxHours; h++) h];
    _minuteValues = [for (var m = 0; m < 60; m += widget.minuteInterval) m];

    _hours = widget.initialDuration.inHours.clamp(0, widget.maxHours);
    _minutes = _nearestMinute(widget.initialDuration.inMinutes.remainder(60));

    _hourCtrl = FixedExtentScrollController(
      initialItem: _hourValues.indexOf(_hours),
    );
    _minuteCtrl = FixedExtentScrollController(
      initialItem: _minuteValues.indexOf(_minutes),
    );
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  int _nearestMinute(int m) {
    var best = _minuteValues.first;
    for (final v in _minuteValues) {
      if ((v - m).abs() < (best - m).abs()) best = v;
    }
    return best;
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
            SizedBox(
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
                        values: _hourValues,
                        selected: _hours,
                        onChanged: (i) =>
                            setState(() => _hours = _hourValues[i]),
                      ),
                      _unit(widget.hoursLabel),
                      const SizedBox(width: 12),
                      _wheel(
                        controller: _minuteCtrl,
                        values: _minuteValues,
                        selected: _minutes,
                        pad: true,
                        onChanged: (i) =>
                            setState(() => _minutes = _minuteValues[i]),
                      ),
                      _unit(widget.minutesLabel),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _actions(s),
          ],
        ),
      ),
    );
  }

  Widget _unit(String label) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _style.mutedColor,
      ),
    ),
  );

  Widget _wheel({
    required FixedExtentScrollController controller,
    required List<int> values,
    required int selected,
    required ValueChanged<int> onChanged,
    bool pad = false,
  }) {
    final s = _style;
    return SizedBox(
      width: 56,
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
          onSelectedItemChanged: (i) {
            HapticFeedback.selectionClick();
            onChanged(i);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: values.length,
            builder: (context, i) {
              final v = values[i];
              return Center(
                child: Text(
                  pad ? v.toString().padLeft(2, '0') : v.toString(),
                  style: s.valueStyle?.copyWith(
                    color: v == selected ? s.accentColor : s.textColor,
                    fontWeight: v == selected
                        ? FontWeight.w700
                        : s.valueStyle?.fontWeight,
                  ),
                ),
              );
            },
          ),
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
            onPressed: () => Navigator.of(
              context,
            ).pop(Duration(hours: _hours, minutes: _minutes)),
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
