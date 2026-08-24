import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_system.dart';
import '../../application/providers.dart';
import '../../application/use_cases/dashboard_use_case.dart';
import '../../domain/models/data_quality.dart';
import '../../domain/models/insight.dart';
import '../../domain/models/summaries.dart';
import '../../shared/evidence_details.dart';
import '../../shared/widgets.dart';
import '../import_timeline/import_flow_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final dashboard = ref.watch(_dashboardProvider(month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('くらしログ'),
        actions: [
          IconButton(
            tooltip: 'タイムラインを取り込む',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportFlowScreen()),
              );
            },
          ),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (data) => _HomeBody(dashboard: data),
      ),
    );
  }
}

final _dashboardProvider = FutureProvider.autoDispose
    .family<DashboardData, String>((ref, month) {
      ref.watch(dashboardRefreshProvider);
      return ref.watch(dashboardUseCaseProvider).loadHome(selectedMonth: month);
    });

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.dashboard});

  final DashboardData dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!dashboard.hasData) {
      return _EmptyHome(
        onImport: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ImportFlowScreen()));
        },
      );
    }

    final theme = Theme.of(context);
    final freshness = dashboard.freshness;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(dashboardRefreshProvider.notifier).state++;
        await ref.read(_dashboardProvider(dashboard.selectedMonth).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              QualityBadge(quality: freshness.quality),
              const Spacer(),
              IconButton(
                tooltip: '前月を見る',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shiftMonth(ref, -1),
              ),
              IconButton(
                tooltip: '翌月を見る',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shiftMonth(ref, 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          JournalSectionHeader(
            eyebrow: '生活記録誌',
            title: dashboard.monthLabel,
            supportingText: '記録から見える、今月の暮らし',
          ),
          if (freshness.quality == DataQuality.low ||
              freshness.quality == DataQuality.quiteLow ||
              freshness.quality == DataQuality.historyOnly) ...[
            const SizedBox(height: 12),
            _StaleBanner(
              quality: freshness.quality,
              staleDays: freshness.staleDays,
              onImport: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportFlowScreen()),
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          if (dashboard.metrics.isNotEmpty)
            JournalCard(
              kind: JournalCardKind.hero,
              title: '今月の暮らし',
              subtitle: '集計された事実を、前月との違いと一緒に確認できます',
              semanticLabel: '今月の暮らし。${dashboard.monthLabel}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MetricCard(
                    icon: _iconFor(dashboard.metrics.first.icon),
                    label: dashboard.metrics.first.label,
                    value: dashboard.metrics.first.value,
                    deltaLabel: dashboard.metrics.first.deltaLabel,
                    note: dashboard.metrics.first.note,
                  ),
                  if (dashboard.metrics.length > 1) ...[
                    const SizedBox(height: KurashilogSpacing.md),
                    Wrap(
                      spacing: KurashilogSpacing.sm,
                      runSpacing: KurashilogSpacing.sm,
                      children: [
                        for (final metric in dashboard.metrics.skip(1))
                          _MiniMetric(metric: metric),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          if (dashboard.metrics.isNotEmpty)
            const SizedBox(height: KurashilogSpacing.lg),
          const JournalSectionHeader(
            title: '小さな事実',
            supportingText: '数字の意味を、読みやすい単位でまとめています',
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('カレンダーで見る'),
              subtitle: Text(
                '今月の外出した日: '
                '${dashboard.heatmap.values.where((value) => value == 1).length} 日',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ref.read(appTabProvider.notifier).state = 1,
            ),
          ),
          const SizedBox(height: 16),
          if (dashboard.insights.isNotEmpty) ...[
            const SizedBox(height: KurashilogSpacing.md),
            const JournalSectionHeader(
              title: '気づき',
              supportingText: '変化の根拠を確認して、解釈を自分で決められます',
            ),
            const SizedBox(height: KurashilogSpacing.sm),
            for (final insight in dashboard.insights)
              Padding(
                padding: const EdgeInsets.only(bottom: KurashilogSpacing.sm),
                child: JournalCard(
                  kind: JournalCardKind.insight,
                  title: insight.title,
                  subtitle: insight.severity.label,
                  semanticLabel: '${insight.title}。${insight.body}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insight.body),
                      if (insight.evidence.isNotEmpty) ...[
                        const SizedBox(height: KurashilogSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _showEvidence(context, insight),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text('根拠を確認'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'まだ気づきを生成できるデータ量がありません。\n'
                  'データを取り込むと、生活の変化が見つかります。',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _showEvidence(BuildContext context, InsightData insight) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: EvidenceDetails(evidence: insight.evidence),
        ),
      ),
    );
  }

  void _shiftMonth(WidgetRef ref, int delta) {
    final parts = ref.read(selectedMonthProvider).split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final shifted = DateTime(year, month + delta);
    ref.read(selectedMonthProvider.notifier).state =
        '${shifted.year.toString().padLeft(4, '0')}-'
        '${shifted.month.toString().padLeft(2, '0')}';
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 24),
        EmptyState(
          icon: Icons.map_outlined,
          title: 'まだデータがありません',
          message:
              'Google マップのタイムラインから書き出した JSON を\n'
              '取り込むと、生活の変化を分析できます。\n'
              'データは端末内だけで処理されます。',
          action: FilledButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.file_upload),
            label: const Text('取り込む'),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('書き出し方法'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Google マップを開き、プロフィール →「タイムライン」を選択\n'
                '2. 右上のメニュー（⋮）→「設定とプライバシー」→「データを書き出す」\n'
                '3. 書き出された ZIP の中の「Records.json」をアプリへ\n'
                '   「共有」またはファイル選択で渡してください',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.metric});

  final MetricCardData metric;

  @override
  Widget build(BuildContext context) {
    return JournalCard(
      kind: JournalCardKind.mini,
      title: metric.label,
      semanticLabel: '${metric.label} ${metric.value}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(metric.icon), size: 20),
          const SizedBox(width: KurashilogSpacing.xs),
          Text(metric.value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({
    required this.quality,
    required this.staleDays,
    required this.onImport,
  });

  final DataQuality quality;
  final int staleDays;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.update, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'データが $staleDays 日更新されていません',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quality == DataQuality.quiteLow ||
                          quality == DataQuality.historyOnly
                      ? '現在の傾向の精度が低下しています。再エクスポートして更新してください。'
                      : '最新の記録を取り込むと、より正確な分析ができます。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(onPressed: onImport, child: const Text('更新')),
        ],
      ),
    );
  }
}

JournalCardKind journalKindForMetric(MetricIcon icon) => switch (icon) {
  MetricIcon.walking => JournalCardKind.hero,
  MetricIcon.route => JournalCardKind.mini,
  MetricIcon.place => JournalCardKind.mini,
  MetricIcon.explore => JournalCardKind.mini,
};

IconData _iconFor(MetricIcon icon) => switch (icon) {
  MetricIcon.walking => Icons.directions_walk,
  MetricIcon.route => Icons.route,
  MetricIcon.place => Icons.place,
  MetricIcon.explore => Icons.explore,
};
