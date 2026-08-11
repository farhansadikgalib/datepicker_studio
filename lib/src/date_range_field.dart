import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'presentation.dart';
import 'theme.dart';

/// How a [DateRangeField] presents the picker when tapped.
enum DateRangePickerPresentation {
  /// Slide up from the bottom. Best on phones.
  sheet,

  /// Centre of the screen. Best on tablet, desktop, and web.
  dialog,
}

/// A read-only text field that opens the picker when tapped.
///
/// Drops into an existing form without any state wiring of your own:
///
/// ```dart
/// DateRangeField(
///   value: _range,
///   onChanged: (r) => setState(() => _range = r),
///   decoration: const InputDecoration(labelText: 'Reporting period'),
/// )
/// ```
class DateRangeField extends StatelessWidget {
  /// Currently selected range, or `null` when empty.
  final PickedDateRange? value;

  /// Fires when the user confirms a new range, or clears it via the trailing
  /// clear button.
  final ValueChanged<PickedDateRange?> onChanged;

  /// Behavioural options passed to the picker.
  final DateRangePickerConfig config;

  /// Visual options passed to the picker.
  final DateRangePickerTheme? theme;

  /// Field decoration. Defaults to an outlined field with a calendar icon.
  final InputDecoration? decoration;

  /// Text shown when [value] is `null`.
  final String hintText;

  /// Date format for each endpoint. Uses `intl` skeleton syntax.
  final String dateFormat;

  /// Text placed between the two endpoints.
  final String separator;

  /// Whether the field is interactive.
  final bool enabled;

  /// Whether to show a clear button once a range is selected.
  final bool showClearButton;

  /// Which surface the picker opens in.
  final DateRangePickerPresentation presentation;

  const DateRangeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.config = const DateRangePickerConfig(),
    this.theme,
    this.decoration,
    this.hintText = 'Select date range',
    this.dateFormat = 'dd MMM yyyy',
    this.separator = '  →  ',
    this.enabled = true,
    this.showClearButton = true,
    this.presentation = DateRangePickerPresentation.sheet,
  });

  /// The field's display text, or `null` when nothing is selected.
  String? _formatted(BuildContext context) {
    final range = value;
    if (range == null) return null;
    final locale =
        config.locale ?? Localizations.maybeLocaleOf(context)?.toString();
    final format = DateFormat(dateFormat, locale);
    if (config.mode == DateRangeMode.single || range.isSingleDay) {
      return format.format(range.start);
    }
    return '${format.format(range.start)}$separator${format.format(range.end)}';
  }

  Future<void> _open(BuildContext context) {
    // The future is built before any await, so `context` is never used across
    // an async gap here.
    final future = switch (presentation) {
      DateRangePickerPresentation.sheet => DateRangePickerSheet(
        context,
        initialRange: value,
        config: config,
        theme: theme,
      ),
      DateRangePickerPresentation.dialog => showDateRangeDialog(
        context,
        initialRange: value,
        config: config,
        theme: theme,
      ),
    };
    return future.then((picked) {
      if (picked != null) onChanged(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = _formatted(context);
    final base =
        decoration ??
        const InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
        );

    return InkWell(
      onTap: enabled ? () => _open(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: base.copyWith(
          enabled: enabled,
          // Let InputDecorator own the placeholder so it coordinates with a
          // floating label instead of painting on top of it.
          hintText: base.hintText ?? hintText,
          suffixIcon:
              base.suffixIcon ??
              (showClearButton && value != null && enabled
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: config.labels.clear,
                      onPressed: () => onChanged(null),
                    )
                  : null),
        ),
        isEmpty: text == null,
        child: text == null
            ? null
            : Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
