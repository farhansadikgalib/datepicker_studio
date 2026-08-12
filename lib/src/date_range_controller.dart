import 'package:flutter/widgets.dart';

import 'models.dart';

/// Drives a [DateRangePickerView] imperatively.
///
/// Attach one to the view via its `controller` argument, then call the methods
/// below to read or change the selection from outside — a toolbar button,
/// a keyboard shortcut, or a test:
///
/// ```dart
/// final controller = DateRangePickerController();
/// // ...
/// DateRangePickerView(controller: controller, onChanged: ...);
/// // elsewhere:
/// controller.setRange(PickedDateRange(a, b));
/// controller.goToMonth(DateTime(2027, 1));
/// controller.clear();
/// ```
///
/// The controller is a [ChangeNotifier]: it notifies its listeners whenever the
/// attached view's selection changes, so widgets that only need to react to the
/// value can `AnimatedBuilder`/`ListenableBuilder` on it instead of threading
/// `onChanged` through their state.
///
/// Remember to [dispose] it when the owning widget is disposed.
class DateRangePickerController extends ChangeNotifier {
  // Hooks the attached view installs. Null while detached, so every public
  // method is a safe no-op before the view mounts.
  PickedDateRange? Function()? _read;
  ValueChanged<PickedDateRange?>? _write;
  ValueChanged<DateTime>? _goToMonth;
  DateTime Function()? _readMonth;

  /// Whether a view is currently attached and the commands below take effect.
  bool get isAttached => _read != null;

  /// The view's current selection, or `null` when nothing (or only a partial
  /// range) is selected. Returns `null` while detached.
  PickedDateRange? get value => _read?.call();

  /// The month the calendar is currently focused on, or `null` while detached.
  DateTime? get focusedMonth => _readMonth?.call();

  /// Replaces the selection. Pass `null` to clear it, same as [clear].
  ///
  /// Endpoints outside the picker's configured bounds are clamped. The calendar
  /// scrolls to the new selection.
  void setRange(PickedDateRange? range) => _write?.call(range);

  /// Clears the current selection.
  void clear() => _write?.call(null);

  /// Scrolls the calendar to [month] without changing the selection.
  void goToMonth(DateTime month) => _goToMonth?.call(month);

  /// Jumps to the same month in [year].
  void goToYear(int year) {
    final month = _readMonth?.call();
    if (month != null) _goToMonth?.call(DateTime(year, month.month));
  }

  /// Scrolls to the month containing today.
  void goToToday() {
    final now = DateTime.now();
    _goToMonth?.call(DateTime(now.year, now.month));
  }

  // ---- internal wiring, called only by the view ----

  /// @nodoc
  void attach({
    required PickedDateRange? Function() read,
    required ValueChanged<PickedDateRange?> write,
    required ValueChanged<DateTime> goToMonth,
    required DateTime Function() readMonth,
  }) {
    _read = read;
    _write = write;
    _goToMonth = goToMonth;
    _readMonth = readMonth;
  }

  /// @nodoc
  void detach() {
    _read = null;
    _write = null;
    _goToMonth = null;
    _readMonth = null;
  }

  /// @nodoc
  void notify() => notifyListeners();
}
