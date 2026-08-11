import 'package:flutter/material.dart';

import 'date_range_picker_view.dart';
import 'models.dart';
import 'theme.dart';

/// Shows the picker in a modal bottom sheet.
///
/// Resolves to the confirmed [PickedDateRange], or `null` if the user cancels
/// or dismisses the sheet by dragging it away.
///
/// ```dart
/// final range = await DateRangePickerSheet(context);
/// if (range != null) print('${range.start} → ${range.end} (${range.days}d)');
/// ```
// ignore: non_constant_identifier_names
Future<PickedDateRange?> DateRangePickerSheet(
  BuildContext context, {

  /// Selection to open with.
  PickedDateRange? initialRange,

  /// Month shown first. Defaults to the start of [initialRange], else today.
  DateTime? initialMonth,

  /// Behavioural options.
  DateRangePickerConfig config = const DateRangePickerConfig(),

  /// Visual options. Unset fields resolve from the ambient [ThemeData].
  DateRangePickerTheme? theme,

  /// Fires on every change while the sheet is open, including partial
  /// selections. Use it to live-preview behind the sheet.
  ValueChanged<PickedDateRange?>? onChanged,

  /// Whether tapping the scrim dismisses the sheet.
  bool isDismissible = true,

  /// Whether the sheet can be dragged away.
  bool enableDrag = true,

  /// Whether to show the drag handle above the header.
  bool showDragHandle = true,

  /// Scrim colour behind the sheet.
  Color? barrierColor,

  /// Route settings for observers and deep links.
  RouteSettings? routeSettings,
}) {
  return showModalBottomSheet<PickedDateRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    routeSettings: routeSettings,
    builder: (sheetContext) => _SheetSurface(
      theme: theme,
      showDragHandle: showDragHandle,
      child: DateRangePickerView(
        initialRange: initialRange,
        initialMonth: initialMonth,
        config: config,
        theme: theme,
        onChanged: onChanged,
        onApply: (range) => Navigator.of(sheetContext).pop(range),
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    ),
  );
}

/// Shows the picker in a centred dialog — the better fit for tablet, desktop,
/// and web, especially with [DateRangePickerConfig.visibleMonths] above 1.
///
/// Resolves to the confirmed [PickedDateRange], or `null` if dismissed.
Future<PickedDateRange?> showDateRangeDialog(
  BuildContext context, {

  /// Selection to open with.
  PickedDateRange? initialRange,

  /// Month shown first. Defaults to the start of [initialRange], else today.
  DateTime? initialMonth,

  /// Behavioural options.
  DateRangePickerConfig config = const DateRangePickerConfig(),

  /// Visual options. Unset fields resolve from the ambient [ThemeData].
  DateRangePickerTheme? theme,

  /// Fires on every change while the dialog is open.
  ValueChanged<PickedDateRange?>? onChanged,

  /// Whether tapping outside dismisses the dialog.
  bool barrierDismissible = true,

  /// Widest the dialog may grow. Raise it for multi-month layouts.
  double maxWidth = 420,

  /// Route settings for observers and deep links.
  RouteSettings? routeSettings,
}) {
  return showDialog<PickedDateRange>(
    context: context,
    barrierDismissible: barrierDismissible,
    routeSettings: routeSettings,
    builder: (dialogContext) {
      final resolved = (theme ?? const DateRangePickerTheme()).resolve(
        dialogContext,
      );
      return Dialog(
        backgroundColor: resolved.backgroundColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(resolved.surfaceRadius!),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            child: DateRangePickerView(
              initialRange: initialRange,
              initialMonth: initialMonth,
              config: config,
              theme: theme,
              onChanged: onChanged,
              onApply: (range) => Navigator.of(dialogContext).pop(range),
              onCancel: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        ),
      );
    },
  );
}

/// Rounded surface, drag handle, and safe-area padding for the sheet.
class _SheetSurface extends StatelessWidget {
  final DateRangePickerTheme? theme;
  final bool showDragHandle;
  final Widget child;

  const _SheetSurface({
    required this.theme,
    required this.showDragHandle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = (theme ?? const DateRangePickerTheme()).resolve(context);
    // A slightly larger top radius than the surface default reads as a more
    // deliberate, modern sheet lip.
    final topRadius = Radius.circular((resolved.surfaceRadius ?? 20) + 4);
    // Grow with the keyboard so a focused field is never covered.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        borderRadius: BorderRadius.vertical(top: topRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDragHandle)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 2),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: resolved.mutedTextColor?.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
