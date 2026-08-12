/// Internal date helpers. All comparisons in this package are day-precision:
/// times of day are deliberately ignored so that a value produced by
/// `DateTime.now()` compares equal to a midnight-normalised calendar cell.
library;

/// Strips the time component, returning midnight local time on the same day.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Whether [a] and [b] fall on the same calendar day.
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Whether [a] and [b] fall in the same calendar month.
bool isSameMonth(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month;
}

/// Number of days in the given month.
int daysInMonth(int year, int month) {
  // Day 0 of the following month is the last day of this one.
  return DateTime(year, month + 1, 0).day;
}

/// Adds [months] to [date], clamping the day to the target month's length so
/// that e.g. Jan 31 + 1 month yields Feb 28/29 rather than overflowing to March.
DateTime addMonths(DateTime date, int months) {
  final total = date.year * 12 + (date.month - 1) + months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final day = date.day.clamp(1, daysInMonth(year, month));
  return DateTime(year, month, day);
}

/// Whole months between [a] and [b], ignoring the day of month.
int monthsBetween(DateTime a, DateTime b) =>
    (b.year - a.year) * 12 + (b.month - a.month);

/// Inclusive day count between two dates, ignoring time of day.
///
/// Computed via UTC to sidestep daylight-saving transitions, which can make a
/// local-time day shorter or longer than 24 hours.
int inclusiveDayCount(DateTime start, DateTime end) {
  final s = DateTime.utc(start.year, start.month, start.day);
  final e = DateTime.utc(end.year, end.month, end.day);
  return e.difference(s).inDays.abs() + 1;
}

/// Adds [days] to [date] at day precision, immune to DST shifts.
DateTime addDays(DateTime date, int days) {
  final utc = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).add(Duration(days: days));
  return DateTime(utc.year, utc.month, utc.day);
}

/// Whether [day] falls within the inclusive range [start]..[end].
bool isWithin(DateTime day, DateTime? start, DateTime? end) {
  final d = dateOnly(day);
  if (start != null && d.isBefore(dateOnly(start))) return false;
  if (end != null && d.isAfter(dateOnly(end))) return false;
  return true;
}

/// Clamps [day] into the inclusive range [min]..[max].
DateTime clampDate(DateTime day, DateTime? min, DateTime? max) {
  var d = dateOnly(day);
  if (min != null && d.isBefore(dateOnly(min))) d = dateOnly(min);
  if (max != null && d.isAfter(dateOnly(max))) d = dateOnly(max);
  return d;
}

/// The start of the week containing [date], where [firstDayOfWeek] uses
/// [DateTime] weekday constants (1 = Monday … 7 = Sunday).
DateTime startOfWeek(DateTime date, int firstDayOfWeek) {
  final delta = (date.weekday - firstDayOfWeek + 7) % 7;
  return addDays(dateOnly(date), -delta);
}

/// The ISO-8601 week number (1–53) of [date].
///
/// Week 1 is the week containing the year's first Thursday, so the number is
/// derived from the Thursday of [date]'s week — independent of the calendar's
/// configured first day.
int isoWeekNumber(DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  // Thursday of this ISO week fixes both the week-year and the week index.
  final thursday = d.add(Duration(days: 4 - d.weekday));
  final firstJan = DateTime.utc(thursday.year, 1, 1);
  return (thursday.difference(firstJan).inDays / 7).floor() + 1;
}
