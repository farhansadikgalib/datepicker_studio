import 'package:flutter/material.dart';

/// Visual configuration for the picker.
///
/// Every field is nullable: anything left `null` is resolved from the ambient
/// [ThemeData] at build time, so the picker looks at home in a Material app
/// without configuration. Use [DateRangePickerTheme.from] to build one from a
/// small number of brand colours, or the constructor for full control.
@immutable
class DateRangePickerTheme {
  /// Fill of the selected start/end cells, the header's active value, and the
  /// primary action button.
  final Color? primaryColor;

  /// Content colour drawn on top of [primaryColor].
  final Color? onPrimaryColor;

  /// Fill of the days strictly between the selected endpoints.
  final Color? rangeColor;

  /// Text colour for days inside the range.
  final Color? onRangeColor;

  /// Background of the sheet, dialog, or inline surface.
  final Color? backgroundColor;

  /// Default day-number and title text colour.
  final Color? textColor;

  /// Secondary text colour used for weekday headers, labels, and captions.
  final Color? mutedTextColor;

  /// Colour of days outside [DateRangePickerConfig.minDate]/`maxDate` or
  /// rejected by a `selectableDayPredicate`.
  final Color? disabledColor;

  /// Colour of dividers and outlines.
  final Color? borderColor;

  /// Ring drawn around today when it is not otherwise selected.
  final Color? todayColor;

  /// Corner radius of the sheet or dialog surface.
  final double? surfaceRadius;

  /// Corner radius of a day cell. Defaults to a full circle.
  final double? dayRadius;

  /// Corner radius of the Cancel, Apply, and Clear buttons. Defaults to 10.
  final double? buttonRadius;

  /// Corner radius of the preset chips. Defaults to a full pill.
  final double? chipRadius;

  /// Corner radius of the time fields in [DateRangeMode.dateTime].
  /// Defaults to [buttonRadius].
  final double? timeFieldRadius;

  /// Vertical padding inside the action buttons. Defaults to 13.
  final double? buttonPadding;

  /// Fill of the preset chips. Defaults to [rangeColor].
  final Color? chipColor;

  /// Outline of the preset chips. Defaults to a 35% tint of [primaryColor].
  final Color? chipBorderColor;

  /// Height of a single day cell.
  final double? dayExtent;

  /// Text style of the "November 2026" month title.
  final TextStyle? monthTitleStyle;

  /// Text style of the Su/Mo/Tu column headers.
  final TextStyle? weekdayStyle;

  /// Base text style of day numbers. Colour and weight are overridden per
  /// state, so set size and font family here.
  final TextStyle? dayStyle;

  /// Text style for the From/To captions in the header.
  final TextStyle? headerLabelStyle;

  /// Text style for the From/To values in the header.
  final TextStyle? headerValueStyle;

  /// Text style for preset chips and action buttons.
  final TextStyle? chipStyle;

  /// Padding around the picker body.
  final EdgeInsetsGeometry? padding;

  const DateRangePickerTheme({
    this.primaryColor,
    this.onPrimaryColor,
    this.rangeColor,
    this.onRangeColor,
    this.backgroundColor,
    this.textColor,
    this.mutedTextColor,
    this.disabledColor,
    this.borderColor,
    this.todayColor,
    this.surfaceRadius,
    this.dayRadius,
    this.buttonRadius,
    this.chipRadius,
    this.timeFieldRadius,
    this.buttonPadding,
    this.chipColor,
    this.chipBorderColor,
    this.dayExtent,
    this.monthTitleStyle,
    this.weekdayStyle,
    this.dayStyle,
    this.headerLabelStyle,
    this.headerValueStyle,
    this.chipStyle,
    this.padding,
  });

  /// Builds a full theme from one or two brand colours.
  ///
  /// [rangeColor] defaults to a 12% tint of [primary], which reads well on
  /// light surfaces; pass it explicitly for dark backgrounds.
  factory DateRangePickerTheme.from({
    required Color primary,
    Color onPrimary = Colors.white,
    Color? rangeColor,
    Color? background,
  }) {
    return DateRangePickerTheme(
      primaryColor: primary,
      onPrimaryColor: onPrimary,
      rangeColor: rangeColor ?? primary.withValues(alpha: 0.12),
      onRangeColor: primary,
      backgroundColor: background,
    );
  }

  /// A flat, low-chrome preset: gently squared day cells, chips, and buttons.
  ///
  /// Colours still resolve from the ambient [ThemeData]; pass [primary] to
  /// override the accent.
  factory DateRangePickerTheme.minimal({Color? primary}) =>
      DateRangePickerTheme(
        primaryColor: primary,
        surfaceRadius: 12,
        dayRadius: 8,
        chipRadius: 8,
        buttonRadius: 8,
      );

  /// A soft preset: fully-rounded pills everywhere and a large surface radius.
  factory DateRangePickerTheme.rounded({Color? primary}) =>
      DateRangePickerTheme(
        primaryColor: primary,
        surfaceRadius: 28,
        dayRadius: 999,
        chipRadius: 999,
        buttonRadius: 999,
      );

  /// A dense preset for tight layouts: smaller day cells and buttons.
  factory DateRangePickerTheme.compact({Color? primary}) =>
      DateRangePickerTheme(
        primaryColor: primary,
        surfaceRadius: 14,
        dayExtent: 34,
        buttonPadding: 9,
      );

  /// Fills every unset field from [context]'s [ColorScheme] and [TextTheme].
  DateRangePickerTheme resolve(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    final resolvedPrimary = primaryColor ?? scheme.primary;
    final resolvedText = textColor ?? scheme.onSurface;
    final resolvedMuted =
        mutedTextColor ?? scheme.onSurfaceVariant.withValues(alpha: 0.9);

    return DateRangePickerTheme(
      primaryColor: resolvedPrimary,
      onPrimaryColor: onPrimaryColor ?? scheme.onPrimary,
      rangeColor: rangeColor ?? resolvedPrimary.withValues(alpha: 0.12),
      onRangeColor: onRangeColor ?? resolvedPrimary,
      backgroundColor: backgroundColor ?? scheme.surface,
      textColor: resolvedText,
      mutedTextColor: resolvedMuted,
      disabledColor: disabledColor ?? resolvedText.withValues(alpha: 0.32),
      borderColor: borderColor ?? scheme.outlineVariant,
      todayColor: todayColor ?? resolvedPrimary,
      surfaceRadius: surfaceRadius ?? 20,
      dayRadius: dayRadius ?? 999,
      buttonRadius: buttonRadius ?? 10,
      chipRadius: chipRadius ?? 999,
      // Time fields sit beside the action buttons, so they follow their shape.
      timeFieldRadius: timeFieldRadius ?? buttonRadius ?? 10,
      buttonPadding: buttonPadding ?? 13,
      chipColor:
          chipColor ?? rangeColor ?? resolvedPrimary.withValues(alpha: 0.12),
      chipBorderColor:
          chipBorderColor ?? resolvedPrimary.withValues(alpha: 0.35),
      dayExtent: dayExtent ?? 40,
      monthTitleStyle:
          monthTitleStyle ??
          text.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: resolvedText,
          ),
      weekdayStyle:
          weekdayStyle ??
          text.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: resolvedMuted,
          ),
      dayStyle: dayStyle ?? text.bodyMedium,
      headerLabelStyle:
          headerLabelStyle ??
          text.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: resolvedMuted,
          ),
      headerValueStyle:
          headerValueStyle ??
          text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      chipStyle:
          chipStyle ??
          text.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: resolvedPrimary,
          ),
      padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 12),
    );
  }

  /// Returns a copy with the given fields replaced.
  DateRangePickerTheme copyWith({
    Color? primaryColor,
    Color? onPrimaryColor,
    Color? rangeColor,
    Color? onRangeColor,
    Color? backgroundColor,
    Color? textColor,
    Color? mutedTextColor,
    Color? disabledColor,
    Color? borderColor,
    Color? todayColor,
    double? surfaceRadius,
    double? dayRadius,
    double? buttonRadius,
    double? chipRadius,
    double? timeFieldRadius,
    double? buttonPadding,
    Color? chipColor,
    Color? chipBorderColor,
    double? dayExtent,
    TextStyle? monthTitleStyle,
    TextStyle? weekdayStyle,
    TextStyle? dayStyle,
    TextStyle? headerLabelStyle,
    TextStyle? headerValueStyle,
    TextStyle? chipStyle,
    EdgeInsetsGeometry? padding,
  }) {
    return DateRangePickerTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      rangeColor: rangeColor ?? this.rangeColor,
      onRangeColor: onRangeColor ?? this.onRangeColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      mutedTextColor: mutedTextColor ?? this.mutedTextColor,
      disabledColor: disabledColor ?? this.disabledColor,
      borderColor: borderColor ?? this.borderColor,
      todayColor: todayColor ?? this.todayColor,
      surfaceRadius: surfaceRadius ?? this.surfaceRadius,
      dayRadius: dayRadius ?? this.dayRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      timeFieldRadius: timeFieldRadius ?? this.timeFieldRadius,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      chipColor: chipColor ?? this.chipColor,
      chipBorderColor: chipBorderColor ?? this.chipBorderColor,
      dayExtent: dayExtent ?? this.dayExtent,
      monthTitleStyle: monthTitleStyle ?? this.monthTitleStyle,
      weekdayStyle: weekdayStyle ?? this.weekdayStyle,
      dayStyle: dayStyle ?? this.dayStyle,
      headerLabelStyle: headerLabelStyle ?? this.headerLabelStyle,
      headerValueStyle: headerValueStyle ?? this.headerValueStyle,
      chipStyle: chipStyle ?? this.chipStyle,
      padding: padding ?? this.padding,
    );
  }
}
