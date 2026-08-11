import 'package:flutter/material.dart';

import 'theme.dart';

/// Visual configuration for [showStudioTimePicker].
///
/// Every field is nullable: anything left `null` is resolved from the ambient
/// [ThemeData] at build time, so the picker looks at home without any setup.
/// Use [TimePickerStyle.from] to build one from a single accent colour, or
/// [TimePickerStyle.fromTheme] to match a calendar's [DateRangePickerTheme].
///
/// ```dart
/// showStudioTimePicker(
///   context,
///   initialTime: TimeOfDay.now(),
///   style: TimePickerStyle.from(accent: Colors.teal),
/// );
/// ```
@immutable
class TimePickerStyle {
  /// Colour of the centred (selected) value, the active AM/PM segment, and the
  /// confirm button. Also the default source of [bandColor].
  final Color? accentColor;

  /// Content colour drawn on top of [accentColor].
  final Color? onAccentColor;

  /// Surface behind the picker.
  final Color? backgroundColor;

  /// Colour of the unselected values in the wheels.
  final Color? textColor;

  /// Secondary colour for the title, the colon separator, and inactive
  /// controls.
  final Color? mutedColor;

  /// Fill of the centre selection band. Defaults to a 12% tint of
  /// [accentColor].
  final Color? bandColor;

  /// Outline of the cancel button. Defaults to the theme's outline.
  final Color? borderColor;

  /// Corner radius of the surface. Buttons and inner controls scale from it.
  final double? borderRadius;

  /// Height of a single wheel row and, by extension, the selection band.
  final double? itemExtent;

  /// Style of the title above the wheels. Set it to `null`-producing text to
  /// hide the title entirely by passing an empty `title`.
  final TextStyle? titleStyle;

  /// Base style of the wheel values. Colour and weight are overridden per
  /// state, so set size and font family here.
  final TextStyle? valueStyle;

  const TimePickerStyle({
    this.accentColor,
    this.onAccentColor,
    this.backgroundColor,
    this.textColor,
    this.mutedColor,
    this.bandColor,
    this.borderColor,
    this.borderRadius,
    this.itemExtent,
    this.titleStyle,
    this.valueStyle,
  });

  /// Builds a full style from a single accent colour.
  factory TimePickerStyle.from({
    required Color accent,
    Color onAccent = Colors.white,
    Color? background,
  }) {
    return TimePickerStyle(
      accentColor: accent,
      onAccentColor: onAccent,
      backgroundColor: background,
      bandColor: accent.withValues(alpha: 0.12),
    );
  }

  /// Derives a style that matches a calendar's [DateRangePickerTheme], so a
  /// time picker opened beside the calendar shares its palette.
  factory TimePickerStyle.fromTheme(DateRangePickerTheme theme) {
    return TimePickerStyle(
      accentColor: theme.primaryColor,
      onAccentColor: theme.onPrimaryColor,
      backgroundColor: theme.backgroundColor,
      textColor: theme.textColor,
      mutedColor: theme.mutedTextColor,
      bandColor: theme.rangeColor,
      borderColor: theme.borderColor,
      borderRadius: theme.surfaceRadius,
    );
  }

  /// Fills every unset field from [context]'s [ColorScheme] and [TextTheme].
  TimePickerStyle resolve(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final accent = accentColor ?? scheme.primary;
    final resolvedText = textColor ?? scheme.onSurface;
    final muted =
        mutedColor ?? scheme.onSurfaceVariant.withValues(alpha: 0.9);

    return TimePickerStyle(
      accentColor: accent,
      onAccentColor: onAccentColor ?? scheme.onPrimary,
      backgroundColor: backgroundColor ?? scheme.surface,
      textColor: resolvedText,
      mutedColor: muted,
      bandColor: bandColor ?? accent.withValues(alpha: 0.12),
      borderColor: borderColor ?? scheme.outlineVariant,
      borderRadius: borderRadius ?? 24,
      itemExtent: itemExtent ?? 48,
      titleStyle:
          titleStyle ??
          theme.textTheme.titleMedium?.copyWith(
            color: resolvedText,
            fontWeight: FontWeight.w700,
          ),
      valueStyle:
          valueStyle ?? const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
    );
  }

  /// Returns a copy with the given fields replaced.
  TimePickerStyle copyWith({
    Color? accentColor,
    Color? onAccentColor,
    Color? backgroundColor,
    Color? textColor,
    Color? mutedColor,
    Color? bandColor,
    Color? borderColor,
    double? borderRadius,
    double? itemExtent,
    TextStyle? titleStyle,
    TextStyle? valueStyle,
  }) {
    return TimePickerStyle(
      accentColor: accentColor ?? this.accentColor,
      onAccentColor: onAccentColor ?? this.onAccentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      mutedColor: mutedColor ?? this.mutedColor,
      bandColor: bandColor ?? this.bandColor,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      itemExtent: itemExtent ?? this.itemExtent,
      titleStyle: titleStyle ?? this.titleStyle,
      valueStyle: valueStyle ?? this.valueStyle,
    );
  }
}
