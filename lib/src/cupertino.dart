// ignore_for_file: non_constant_identifier_names — pickers use the
// DateRangePicker* PascalCase family by design.
import 'package:flutter/cupertino.dart';
// The calendar engine uses a few Material widgets (IconButton, Divider), so a
// transparent Material host is needed inside the Cupertino popup.
import 'package:flutter/material.dart' show Material, MaterialType;

import 'date_range_picker_view.dart';
import 'models.dart';
import 'theme.dart';

/// Builds a [DateRangePickerTheme] that matches iOS system colours for the
/// given [brightness], so the calendar reads as native on Apple platforms.
///
/// Pass [primary] to override the accent (defaults to iOS system blue).
DateRangePickerTheme cupertinoDateRangePickerTheme({
  Brightness brightness = Brightness.light,
  Color primary = const Color(0xFF007AFF),
}) {
  final dark = brightness == Brightness.dark;
  final background = dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  final text = dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  final muted = dark ? const Color(0xFF98989F) : const Color(0xFF8E8E93);
  final border = dark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6);

  return DateRangePickerTheme(
    primaryColor: primary,
    onPrimaryColor: const Color(0xFFFFFFFF),
    backgroundColor: background,
    textColor: text,
    mutedTextColor: muted,
    borderColor: border,
    rangeColor: primary.withValues(alpha: dark ? 0.24 : 0.14),
    onRangeColor: primary,
    todayColor: primary,
    disabledColor: muted.withValues(alpha: 0.5),
    surfaceRadius: 14,
    dayRadius: 999,
    buttonRadius: 12,
    chipRadius: 999,
    dayExtent: 40,
  );
}

/// Presents the date range picker in an iOS-style modal that slides up from the
/// bottom, with a Cancel/Done toolbar, and resolves to the confirmed
/// [PickedDateRange] or `null`.
///
/// Unless [theme] is given, an iOS palette is derived from the ambient
/// brightness via [cupertinoDateRangePickerTheme]. Drop it into a
/// `CupertinoApp` or a `MaterialApp` alike.
///
/// ```dart
/// final range = await DateRangePickerCupertino(context);
/// ```
Future<PickedDateRange?> DateRangePickerCupertino(
  BuildContext context, {
  PickedDateRange? initialRange,
  DateTime? initialMonth,
  DateRangePickerConfig config = const DateRangePickerConfig(),
  DateRangePickerTheme? theme,
  String title = '',
  String cancelLabel = 'Cancel',
  String doneLabel = 'Done',
}) {
  final brightness =
      CupertinoTheme.maybeBrightnessOf(context) ??
      MediaQuery.maybePlatformBrightnessOf(context) ??
      Brightness.light;
  final resolved =
      theme ?? cupertinoDateRangePickerTheme(brightness: brightness);

  return showCupertinoModalPopup<PickedDateRange>(
    context: context,
    builder: (popupContext) => _CupertinoDateRangeSheet(
      initialRange: initialRange,
      initialMonth: initialMonth,
      config: config,
      theme: resolved,
      title: title,
      cancelLabel: cancelLabel,
      doneLabel: doneLabel,
    ),
  );
}

class _CupertinoDateRangeSheet extends StatefulWidget {
  final PickedDateRange? initialRange;
  final DateTime? initialMonth;
  final DateRangePickerConfig config;
  final DateRangePickerTheme theme;
  final String title;
  final String cancelLabel;
  final String doneLabel;

  const _CupertinoDateRangeSheet({
    required this.initialRange,
    required this.initialMonth,
    required this.config,
    required this.theme,
    required this.title,
    required this.cancelLabel,
    required this.doneLabel,
  });

  @override
  State<_CupertinoDateRangeSheet> createState() =>
      _CupertinoDateRangeSheetState();
}

class _CupertinoDateRangeSheetState extends State<_CupertinoDateRangeSheet> {
  PickedDateRange? _current;
  String? _error;

  @override
  void initState() {
    super.initState();
    _current = widget.initialRange;
  }

  bool get _canDone => _current != null && _error == null;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final radius = Radius.circular(theme.surfaceRadius ?? 14);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: radius),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toolbar(theme),
              Container(height: 1, color: theme.borderColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DateRangePickerView(
                  initialRange: widget.initialRange,
                  initialMonth: widget.initialMonth,
                  config: widget.config,
                  theme: theme,
                  showActions: false,
                  onChanged: (r) => setState(() => _current = r),
                  onError: (e) => setState(() => _error = e),
                  onApply: (r) => Navigator.of(context).pop(r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbar(DateRangePickerTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              widget.cancelLabel,
              style: TextStyle(color: theme.primaryColor, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onPressed: _canDone
                ? () => Navigator.of(context).pop(_current)
                : null,
            child: Text(
              widget.doneLabel,
              style: TextStyle(
                color: _canDone ? theme.primaryColor : theme.mutedTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
