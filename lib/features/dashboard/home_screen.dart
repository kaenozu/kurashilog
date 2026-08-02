import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/use_cases/dashboard_use_case.dart';
import '../../domain/models/data_quality.dart';
import '../../domain/models/insight.dart';
import '../../domain/models/summaries.dart';
import '../../shared/widgets.dart';
import '../import_timeline/import_flow_screen.dart';

/// ホーム（設計書 SC-02 / 6.1 表示優先順位）。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refresh = ref.watch(dashboardRefreshProvider);
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
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ImportFlowScreen(),
              ));
            },
          ),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (d) => _HomeBody(dashboard: d, refresh: refresh),
      ),
    );
  }
}

final _dashboardProvider =
    FutureProvider.autoDispose.family<DashboardData, String>(
  (ref, month) => ref.watch(dashboardUseCaseProvider).loadHome(selectedMonth: month),
);

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.dashboard, required this.refresh});

  final DashboardData dashboard;
  final int refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 再読込トリガー
    ref.watch(dashboardRefreshProvider);

    if (!dashboard.hasData) {
      return _EmptyHome(
        onImport: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ImportFlowScreen(),
          ));
        },
      );
    }

    final theme = Theme.of(context);
    final freshness = dashboard.freshness;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(dashboardRefreshProvider.notifier).state++;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 鮮度バッジ（設計書 6.1 優先順位 2）
          Row(
            children: [
              QualityBadge(quality: freshness.quality),
              const Spacer(),
              if (dashboard.previousMonthly != null)
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
          Text(
            dashboard.monthLabel,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),

          // 古いデータの更新案内（設計書 7.3）
          if (freshness.quality == DataQuality.low ||
              freshness.quality == DataQuality.quiteLow) ...[
            const SizedBox(height: 12),
            _StaleBanner(
              quality: freshness.quality,
              staleDays: freshness.staleDays,
              onImport: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ImportFlowScreen(),
                ));
              },
            ),
          ],

          const SizedBox(height: 16),

          // メトリクスカード 4 枚（設計書 6.1 優先順位 3）
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final m in dashboard.metrics)
                MetricCard(
                  icon: _iconFor(m.icon),
                  label: m.label,
                  value: m.value,
                  deltaLabel: m.deltaLabel,
                  note: m.note,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // カレンダーへの導線（今月の外出サマリ）
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('カレンダーで見る'),
              subtitle: Text(
                '今月の外出した日: ${dashboard.heatmap.values.where((v) => v == 1).length} 日',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.read(appTabProvider.notifier).state = 1;
              },
            ),
          ),

          const SizedBox(height: 16),

          // インサイト（最大 3 件）
          if (dashboard.insights.isNotEmpty) ...[
            Text('気づき', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final insight in dashboard.insights)
              _InsightCard(
                title: insight.title,
                body: insight.body,
                attention: insight.severity == InsightSeverity.attention,
              ),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'まだ気づきを生成できるデータ量がありません。\nデータを取り込むと、生活の変化が見つかります。',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _shiftMonth(WidgetRef ref, int delta) {
    final parts = ref.read(selectedMonthProvider).split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = DateTime(y, m + delta, 1);
    ref.read(selectedMonthProvider.notifier).state =
        '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}';
  }
}

/// ホームの空状態（設計書 6.1 優先順位 1）。
class _EmptyHome extends ConsumerWidget {
  const _EmptyHome({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 24),
        EmptyState(
          icon: Icons.map_outlined,
          title: 'まだデータがありません',
          message:
              'Google マップのタイムラインから書き出した JSON を\n取り込むと、生活の変化を分析できます。\nデータは端末内だけで処理されます。',
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
                  'データが ${staleDays} 日更新されていません',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: scheme.onErrorContainer),
                ),
                const SizedBox(height: 2),
                Text(
                  quality == DataQuality.quiteLow
                      ? '現在の傾向の精度が低下しています。再エクスポートして更新してください。'
                      : '最新の記録を取り込むと、より正確な分析ができます。',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onErrorContainer),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onImport,
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.attention,
  });

  final String title;
  final String body;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final icon = attention ? Icons.star : Icons.lightbulb_outline;
    final color = attention ? scheme.tertiary : scheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// メトリクスアイコン対応表
IconData _iconFor(MetricIcon icon) => switch (icon) {
      MetricIcon.walking => Icons.directions_walk,
      MetricIcon.route => Icons.route,
      MetricIcon.place => Icons.place,
      MetricIcon.explore => Icons.explore,
    };
