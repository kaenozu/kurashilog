import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/display_preferences.dart';
import '../../application/providers.dart';
import '../../application/use_cases/settings_use_case.dart';
import '../../application/use_cases/dashboard_use_case.dart';
import '../../domain/models/insight.dart';
import '../../shared/widgets.dart';

/// 月間ストーリー（設計書 SC-05 / FR-050）。
class MonthStoryScreen extends ConsumerStatefulWidget {
  const MonthStoryScreen({super.key, required this.yearMonth});

  final String yearMonth;

  @override
  ConsumerState<MonthStoryScreen> createState() => _MonthStoryScreenState();
}

class _MonthStoryScreenState extends ConsumerState<MonthStoryScreen> {
  late String _month;

  @override
  void initState() {
    super.initState();
    _month = widget.yearMonth;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_monthStoryProvider(_month));
    final distanceUnit =
        ref.watch(appSettingsProvider).valueOrNull?.distanceUnit ??
        DistanceUnit.km;

    return Scaffold(
      appBar: AppBar(
        title: const Text('月間ストーリー'),
        actions: [
          IconButton(
            tooltip: '前月',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _shift(-1),
          ),
          IconButton(
            tooltip: '翌月',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _shift(1),
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (d) => _StoryBody(data: d, distanceUnit: distanceUnit),
      ),
    );
  }

  void _shift(int delta) {
    final parts = _month.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = DateTime(y, m + delta, 1);
    setState(() {
      _month =
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}';
    });
  }
}

final _monthStoryProvider = FutureProvider.autoDispose
    .family<MonthStoryData, String>((ref, month) {
      ref.watch(dashboardRefreshProvider);
      return ref.watch(dashboardUseCaseProvider).monthStory(month);
    });

class _StoryBody extends StatelessWidget {
  const _StoryBody({required this.data, required this.distanceUnit});

  final MonthStoryData data;
  final DistanceUnit distanceUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthly = data.monthly;
    if (monthly == null) {
      return const EmptyState(
        icon: Icons.auto_stories_outlined,
        title: 'この月の記録がありません',
        message: '他の月を選ぶか、データを取り込んでください。',
      );
    }
    final prev = data.previousMonthly;
    final monthLabel = _formatMonth(data.yearMonth);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          monthLabel,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'この月の生活のまとめです。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _pill(
              theme,
              '外出日数',
              '${monthly.outingDays}日',
              _delta(prev?.outingDays, monthly.outingDays),
            ),
            _pill(
              theme,
              '移動距離',
              formatDistance(monthly.distanceM, distanceUnit),
              _deltaPercent(prev?.distanceM, monthly.distanceM),
            ),
            _pill(
              theme,
              '訪れた地点',
              '${monthly.uniqueClusters}か所',
              _delta(prev?.uniqueClusters, monthly.uniqueClusters),
            ),
            _pill(theme, '新規地点', '${monthly.newClusters}か所', null),
          ],
        ),
        const SizedBox(height: 16),
        if (monthly.maxDistanceDate != null)
          Card(
            child: ListTile(
              leading: Icon(
                Icons.local_fire_department,
                color: theme.colorScheme.tertiary,
              ),
              title: const Text('最大移動日'),
              subtitle: Text(
                '${_formatDate(monthly.maxDistanceDate!)} に最も移動しました',
              ),
            ),
          ),
        if (data.newClusterNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('新しい場所', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in data.newClusterNames.take(8))
                        Chip(
                          label: Text(name),
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.place, size: 16),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (data.insights.isNotEmpty) ...[
          Text('この月の変化', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final insight in data.insights) _insightCard(theme, insight),
        ] else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'この月は大きな変化は見つかりませんでした。',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }

  Widget _pill(ThemeData theme, String label, String value, String? delta) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          if (delta != null)
            Text(
              delta,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
        ],
      ),
    );
  }

  Widget _insightCard(ThemeData theme, InsightData insight) {
    final scheme = theme.colorScheme;
    final attention = insight.severity == InsightSeverity.attention;
    return Card(
      child: ListTile(
        leading: Icon(
          attention ? Icons.star : Icons.lightbulb_outline,
          color: attention ? scheme.tertiary : scheme.primary,
        ),
        title: Text(insight.title, style: theme.textTheme.titleSmall),
        subtitle: Text(insight.body),
        isThreeLine: true,
      ),
    );
  }

  String? _delta(int? prev, int cur) {
    if (prev == null) return null;
    final d = cur - prev;
    if (d == 0) return '前月と同数';
    return '前月比 ${d > 0 ? '+' : ''}$d';
  }

  String? _deltaPercent(int? prev, int cur) {
    if (prev == null || prev == 0) return null;
    final ratio = (cur - prev) / prev * 100;
    final r = ratio.round();
    if (r == 0) return '前月と同程度';
    return '前月比 ${r > 0 ? '+' : ''}$r%';
  }

  String _formatMonth(String ym) {
    final parts = ym.split('-');
    return '${int.parse(parts[0])}年${int.parse(parts[1])}月';
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    return '${int.parse(parts[1])}月${int.parse(parts[2])}日';
  }
}
