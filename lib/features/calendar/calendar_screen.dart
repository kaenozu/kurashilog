import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../shared/widgets.dart';
import '../day_detail/day_detail_screen.dart';
import '../month_story/month_story_screen.dart';

/// カレンダーヒートマップ（設計書 SC-06 / FR-040）。
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dashboardRefreshProvider);
    final month = ref.watch(selectedMonthProvider);
    final daily = ref.watch(_monthlyDaysProvider(month));
    final hasData = ref.watch(repositoryHasDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
        actions: [
          IconButton(
            tooltip: '前月',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _shift(ref, -1),
          ),
          IconButton(
            tooltip: '翌月',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _shift(ref, 1),
          ),
        ],
      ),
      body: daily.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (days) {
          if (!hasData) {
            return const EmptyState(
              icon: Icons.calendar_month,
              title: 'データがありません',
              message: 'タイムライン JSON を取り込むと、外出の記録が表示されます。',
            );
          }
          return _CalendarBody(month: month, days: days);
        },
      ),
    );
  }

  void _shift(WidgetRef ref, int delta) {
    final parts = ref.read(selectedMonthProvider).split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = DateTime(y, m + delta, 1);
    ref.read(selectedMonthProvider.notifier).state =
        '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}';
  }
}

final _monthlyDaysProvider =
    FutureProvider.autoDispose.family<Map<String, bool>, String>((ref, month) async {
  final repo = ref.watch(repositoryProvider);
  final parts = month.split('-');
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final daysInMonth = DateTime(y, m + 1, 0).day;
  final rows = await repo.dailySummariesBetween(
    '$month-01',
    '$month-${daysInMonth.toString().padLeft(2, '0')}',
  );
  return {for (final r in rows) r.localDate: r.outingFlag};
});

final repositoryHasDataProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return await repo.countVisits() > 0;
});

class _CalendarBody extends ConsumerWidget {
  const _CalendarBody({required this.month, required this.days});

  final String month;
  final Map<String, bool> days;

  static const _weekLabels = ['月', '火', '水', '木', '金', '土', '日'];
  static const _weekStartsMonday = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final parts = month.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final firstWeekday = DateTime(y, m, 1).weekday; // 1=Mon .. 7=Sun
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final today = DateTime.now();

    final leadingBlanks = _weekStartsMonday ? firstWeekday - 1 : firstWeekday % 7;

    final cells = <Widget>[];
    for (final label in _weekLabels) {
      cells.add(Center(
        child: Text(label, style: theme.textTheme.labelSmall),
      ));
    }
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final dateStr = '$month-${d.toString().padLeft(2, '0')}';
      final outing = days[dateStr] ?? false;
      final hasRecord = days.containsKey(dateStr);
      final isToday = today.year == y && today.month == m && today.day == d;
      cells.add(_DayCell(
        day: d,
        outing: outing,
        hasRecord: hasRecord,
        isToday: isToday,
        onTap: hasRecord
            ? () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DayDetailScreen(localDate: dateStr),
                ));
              }
            : null,
      ));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('$y年$m月',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
              tooltip: '月間ストーリー',
              icon: const Icon(Icons.auto_stories_outlined),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MonthStoryScreen(yearMonth: month),
                ));
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.9,
          children: cells,
        ),
        const SizedBox(height: 16),
        // 凡例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(theme, color: theme.colorScheme.surfaceContainerHighest),
            const SizedBox(width: 4),
            Text('記録なし', style: theme.textTheme.bodySmall),
            const SizedBox(width: 16),
            _legendDot(theme, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text('外出あり', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'タップするとその日のタイムラインを開きます。',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _legendDot(ThemeData theme, {required Color color}) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.outing,
    required this.hasRecord,
    required this.isToday,
    this.onTap,
  });

  final int day;
  final bool outing;
  final bool hasRecord;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = !hasRecord
        ? scheme.surfaceContainerHighest
        : outing
            ? scheme.primary
            : scheme.primaryContainer;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: scheme.outline, width: 1.5) : null,
        ),
        child: Text(
          '$day',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: !hasRecord ? scheme.onSurfaceVariant : scheme.onPrimary,
                fontWeight: isToday ? FontWeight.w800 : null,
              ),
        ),
      ),
    );
  }
}
