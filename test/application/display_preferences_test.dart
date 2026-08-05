import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/display_preferences.dart';
import 'package:kurashilog/application/use_cases/settings_use_case.dart';

void main() {
  test('formats metric and imperial distances consistently', () {
    expect(formatDistance(999, DistanceUnit.km), '999m');
    expect(formatDistance(1500, DistanceUnit.km), '1.5km');
    expect(formatDistance(0, DistanceUnit.mi), '0.0mi');
    expect(formatDistance(100, DistanceUnit.mi), '0.1mi');
    expect(formatDistance(1609, DistanceUnit.mi), '1.0mi');
    expect(formatDistance(-1, DistanceUnit.km), '0m');
    expect(formatDistance(-1, DistanceUnit.mi), '0.0mi');
  });

  test('orders week labels and boundaries by preference', () {
    expect(weekLabels(WeekStart.monday).first, '月');
    expect(weekLabels(WeekStart.sunday).first, '日');
    final sunday = DateTime(2026, 8, 2);
    expect(calendarLeadingBlanks(sunday, WeekStart.sunday), 0);
    expect(calendarLeadingBlanks(sunday, WeekStart.monday), 6);
    expect(
      startOfWeek(DateTime(2026, 8, 5), WeekStart.monday),
      DateTime(2026, 8, 3),
    );
    expect(
      startOfWeek(DateTime(2026, 8, 5), WeekStart.sunday),
      DateTime(2026, 8, 2),
    );
  });
}
