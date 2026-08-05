import 'use_cases/settings_use_case.dart';

const double metersPerMile = 1609.344;

String formatDistance(int meters, DistanceUnit unit) {
  final safeMeters = meters < 0 ? 0 : meters;
  if (unit == DistanceUnit.mi) {
    return '${(safeMeters / metersPerMile).toStringAsFixed(1)}mi';
  }
  return safeMeters >= 1000
      ? '${(safeMeters / 1000).toStringAsFixed(1)}km'
      : '${safeMeters}m';
}

List<String> weekLabels(WeekStart start) => start == WeekStart.sunday
    ? const ['日', '月', '火', '水', '木', '金', '土']
    : const ['月', '火', '水', '木', '金', '土', '日'];

int calendarLeadingBlanks(DateTime firstDay, WeekStart start) {
  final weekday = firstDay.weekday;
  return start == WeekStart.sunday ? weekday % 7 : weekday - 1;
}

DateTime startOfWeek(DateTime date, WeekStart start) {
  final offset = calendarLeadingBlanks(date, start);
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: offset));
}
