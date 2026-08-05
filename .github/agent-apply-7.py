from pathlib import Path
import subprocess

Path('lib/application/display_preferences.dart').write_text('''import 'use_cases/settings_use_case.dart';

const double metersPerMile = 1609.344;

String formatDistance(int meters, DistanceUnit unit) {
  final safeMeters = meters < 0 ? 0 : meters;
  if (unit == DistanceUnit.mi) {
    final miles = safeMeters / metersPerMile;
    return miles < 0.1
        ? '${safeMeters}m'
        : '${miles.toStringAsFixed(1)}mi';
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
  return DateTime(date.year, date.month, date.day).subtract(Duration(days: offset));
}
''', encoding='utf-8')

settings = Path('lib/application/use_cases/settings_use_case.dart')
text = settings.read_text(encoding='utf-8')
text = text.replace('enum DistanceUnit { km, m }', 'enum DistanceUnit { km, mi }', 1)
text = text.replace(
    "distanceUnit: du?.value == 'm' ? DistanceUnit.m : DistanceUnit.km,",
    "distanceUnit: du?.value == 'mi' ? DistanceUnit.mi : DistanceUnit.km,",
    1,
)
text = text.replace(
    "value == DistanceUnit.m ? 'm' : 'km',",
    "value == DistanceUnit.mi ? 'mi' : 'km',",
    1,
)
settings.write_text(text, encoding='utf-8')

providers = Path('lib/application/providers.dart')
text = providers.read_text(encoding='utf-8')
old = '''final dashboardUseCaseProvider = Provider<DashboardUseCase>(
  (ref) => DashboardUseCase(
    repository: ref.watch(repositoryProvider),
    analysis: ref.watch(analysisCoordinatorProvider),
  ),
);
'''
new = '''final dashboardUseCaseProvider = Provider<DashboardUseCase>(
  (ref) => DashboardUseCase(
    repository: ref.watch(repositoryProvider),
    analysis: ref.watch(analysisCoordinatorProvider),
    settings: ref.watch(settingsUseCaseProvider),
  ),
);
'''
if text.count(old) != 1:
    raise SystemExit('dashboard provider block not found')
text = text.replace(old, new, 1)
marker = '''final settingsUseCaseProvider = Provider<SettingsUseCase>(
  (ref) => SettingsUseCase(repository: ref.watch(repositoryProvider)),
);
'''
addition = marker + '''
final appSettingsProvider = FutureProvider<AppSettingsData>(
  (ref) => ref.watch(settingsUseCaseProvider).load(),
);
'''
if text.count(marker) != 1:
    raise SystemExit('settings provider marker not found')
text = text.replace(marker, addition, 1)
providers.write_text(text, encoding='utf-8')

use_case = Path('lib/application/use_cases/dashboard_use_case.dart')
text = use_case.read_text(encoding='utf-8')
text = text.replace(
    "import '../analysis/analysis_coordinator.dart';\n",
    "import '../analysis/analysis_coordinator.dart';\nimport '../display_preferences.dart';\n",
    1,
)
text = text.replace(
    "import '../repositories/kurashilog_repository.dart';\n",
    "import '../repositories/kurashilog_repository.dart';\nimport 'settings_use_case.dart';\n",
    1,
)
text = text.replace(
    '''    required this.analysis,
    this.freshness = const FreshnessService(),
''',
    '''    required this.analysis,
    required this.settings,
    this.freshness = const FreshnessService(),
''',
    1,
)
text = text.replace(
    '''  final AnalysisCoordinator analysis;
  final FreshnessService freshness;
''',
    '''  final AnalysisCoordinator analysis;
  final SettingsUseCase settings;
  final FreshnessService freshness;
''',
    1,
)
text = text.replace(
    '''    final metrics = _buildHomeMetrics(monthly, previous);
''',
    '''    final displaySettings = await settings.load();
    final metrics = _buildHomeMetrics(
      monthly,
      previous,
      displaySettings.distanceUnit,
    );
''',
    1,
)
text = text.replace(
    '''  List<MetricCardData> _buildHomeMetrics(
    MonthlySummaryData? current,
    MonthlySummaryData? previous,
  ) {
''',
    '''  List<MetricCardData> _buildHomeMetrics(
    MonthlySummaryData? current,
    MonthlySummaryData? previous,
    DistanceUnit distanceUnit,
  ) {
''',
    1,
)
text = text.replace('        value: _km(current.distanceM),', '        value: formatDistance(current.distanceM, distanceUnit),', 1)
old_tail = '''
  String _km(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters}m';
}
'''
if text.count(old_tail) != 1:
    raise SystemExit('dashboard _km tail not found')
text = text.replace(old_tail, '\n}\n', 1)
use_case.write_text(text, encoding='utf-8')

settings_screen = Path('lib/features/settings/settings_screen.dart')
text = settings_screen.read_text(encoding='utf-8')
text = text.replace('final settings = ref.watch(_settingsProvider);', 'final settings = ref.watch(appSettingsProvider);', 1)
text = text.replace('value: DistanceUnit.m, label: Text(\'m\')', "value: DistanceUnit.mi, label: Text('mi')", 1)
text = text.replace('ref.invalidate(_settingsProvider);', 'ref.invalidate(appSettingsProvider);\n                        ref.read(dashboardRefreshProvider.notifier).state++;', 2)
text = text.replace('ref.invalidate(_settingsProvider);', 'ref.invalidate(appSettingsProvider);', 1)
provider_block = '''
final _settingsProvider = FutureProvider.autoDispose<AppSettingsData>(
  (ref) => ref.watch(settingsUseCaseProvider).load(),
);
'''
text = text.replace(provider_block, '', 1)
settings_screen.write_text(text, encoding='utf-8')

calendar = Path('lib/features/calendar/calendar_screen.dart')
text = calendar.read_text(encoding='utf-8')
text = text.replace(
    "import '../../application/providers.dart';\n",
    "import '../../application/display_preferences.dart';\nimport '../../application/providers.dart';\nimport '../../application/use_cases/settings_use_case.dart';\n",
    1,
)
text = text.replace(
    '''    final hasData = ref.watch(repositoryHasDataProvider);
''',
    '''    final hasData = ref.watch(repositoryHasDataProvider);
    final weekStart = ref.watch(appSettingsProvider).valueOrNull?.weekStart ??
        WeekStart.monday;
''',
    1,
)
text = text.replace(
    '          return _CalendarBody(month: month, days: days);',
    '          return _CalendarBody(month: month, days: days, weekStart: weekStart);',
    1,
)
text = text.replace(
    '''class _CalendarBody extends ConsumerWidget {
  const _CalendarBody({required this.month, required this.days});

  final String month;
  final Map<String, bool> days;

  static const _weekLabels = ['月', '火', '水', '木', '金', '土', '日'];
''',
    '''class _CalendarBody extends ConsumerWidget {
  const _CalendarBody({
    required this.month,
    required this.days,
    required this.weekStart,
  });

  final String month;
  final Map<String, bool> days;
  final WeekStart weekStart;
''',
    1,
)
text = text.replace(
    '''    final firstWeekday = DateTime(y, m, 1).weekday;
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final today = DateTime.now();
    final leadingBlanks = firstWeekday - 1;
''',
    '''    final firstDay = DateTime(y, m, 1);
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final today = DateTime.now();
    final leadingBlanks = calendarLeadingBlanks(firstDay, weekStart);
''',
    1,
)
text = text.replace('    for (final label in _weekLabels) {', '    for (final label in weekLabels(weekStart)) {', 1)
calendar.write_text(text, encoding='utf-8')

day = Path('lib/features/day_detail/day_detail_screen.dart')
text = day.read_text(encoding='utf-8')
text = text.replace(
    "import '../../application/providers.dart';\n",
    "import '../../application/display_preferences.dart';\nimport '../../application/providers.dart';\nimport '../../application/use_cases/settings_use_case.dart';\n",
    1,
)
text = text.replace(
    '''    final data = ref.watch(_dayDetailProvider(localDate));
''',
    '''    final data = ref.watch(_dayDetailProvider(localDate));
    final distanceUnit =
        ref.watch(appSettingsProvider).valueOrNull?.distanceUnit ?? DistanceUnit.km;
''',
    1,
)
text = text.replace('          return _TimelineBody(data: d);', '          return _TimelineBody(data: d, distanceUnit: distanceUnit);', 1)
text = text.replace(
    '''class _TimelineBody extends StatelessWidget {
  const _TimelineBody({required this.data});

  final DayDetailData data;
''',
    '''class _TimelineBody extends StatelessWidget {
  const _TimelineBody({required this.data, required this.distanceUnit});

  final DayDetailData data;
  final DistanceUnit distanceUnit;
''',
    1,
)
text = text.replace("'移動距離 合計 ${_km(data.totalDistanceM)}'", "'移動距離 合計 ${formatDistance(data.totalDistanceM, distanceUnit)}'", 1)
text = text.replace(
    '''            isLast: i == data.entries.length - 1,
''',
    '''            isLast: i == data.entries.length - 1,
            distanceUnit: distanceUnit,
''',
    1,
)
text = text.replace(
    '''  String _km(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters}m';
}

class _TimelineRow extends ConsumerWidget {
''',
    '''}

class _TimelineRow extends ConsumerWidget {
''',
    1,
)
text = text.replace(
    '''    required this.isLast,
  });
''',
    '''    required this.isLast,
    required this.distanceUnit,
  });
''',
    1,
)
text = text.replace(
    '''  final bool isLast;
''',
    '''  final bool isLast;
  final DistanceUnit distanceUnit;
''',
    1,
)
text = text.replace('if (entry.distanceM != null) _km(entry.distanceM!),', 'if (entry.distanceM != null) formatDistance(entry.distanceM!, distanceUnit),', 1)
text = text.replace(
    '''
  String _km(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters}m';

  String _activityLabel''',
    '''
  String _activityLabel''',
    1,
)
day.write_text(text, encoding='utf-8')

month = Path('lib/features/month_story/month_story_screen.dart')
text = month.read_text(encoding='utf-8')
text = text.replace(
    "import '../../application/providers.dart';\n",
    "import '../../application/display_preferences.dart';\nimport '../../application/providers.dart';\nimport '../../application/use_cases/settings_use_case.dart';\n",
    1,
)
text = text.replace(
    '''    final data = ref.watch(_monthStoryProvider(_month));
''',
    '''    final data = ref.watch(_monthStoryProvider(_month));
    final distanceUnit =
        ref.watch(appSettingsProvider).valueOrNull?.distanceUnit ?? DistanceUnit.km;
''',
    1,
)
text = text.replace('        data: (d) => _StoryBody(data: d),', '        data: (d) => _StoryBody(data: d, distanceUnit: distanceUnit),', 1)
text = text.replace(
    '''class _StoryBody extends StatelessWidget {
  const _StoryBody({required this.data});

  final MonthStoryData data;
''',
    '''class _StoryBody extends StatelessWidget {
  const _StoryBody({required this.data, required this.distanceUnit});

  final MonthStoryData data;
  final DistanceUnit distanceUnit;
''',
    1,
)
text = text.replace('_km(monthly.distanceM),', 'formatDistance(monthly.distanceM, distanceUnit),', 1)
text = text.replace(
    '''
  String _km(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters}m';

  String _formatMonth''',
    '''
  String _formatMonth''',
    1,
)
month.write_text(text, encoding='utf-8')

Path('test/application/display_preferences_test.dart').write_text('''import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/display_preferences.dart';
import 'package:kurashilog/application/use_cases/settings_use_case.dart';

void main() {
  test('formats metric and imperial distances consistently', () {
    expect(formatDistance(999, DistanceUnit.km), '999m');
    expect(formatDistance(1500, DistanceUnit.km), '1.5km');
    expect(formatDistance(1609, DistanceUnit.mi), '1.0mi');
    expect(formatDistance(-1, DistanceUnit.km), '0m');
  });

  test('orders week labels and boundaries by preference', () {
    expect(weekLabels(WeekStart.monday).first, '月');
    expect(weekLabels(WeekStart.sunday).first, '日');
    final sunday = DateTime(2026, 8, 2);
    expect(calendarLeadingBlanks(sunday, WeekStart.sunday), 0);
    expect(calendarLeadingBlanks(sunday, WeekStart.monday), 6);
    expect(startOfWeek(DateTime(2026, 8, 5), WeekStart.monday), DateTime(2026, 8, 3));
    expect(startOfWeek(DateTime(2026, 8, 5), WeekStart.sunday), DateTime(2026, 8, 2));
  });
}
''', encoding='utf-8')

Path('.github/workflows/ci.yml').write_bytes(
    subprocess.check_output(['git', 'show', 'origin/main:.github/workflows/ci.yml'])
)
Path(__file__).unlink(missing_ok=True)
