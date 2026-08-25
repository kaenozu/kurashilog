import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/use_cases/insight_evidence_use_case.dart';
import '../../domain/models/insight.dart';
import '../day_detail/day_detail_screen.dart';

class InsightEvidenceScreen extends ConsumerWidget {
  const InsightEvidenceScreen({
    super.key,
    required this.yearMonth,
    required this.insight,
  });

  final String yearMonth;
  final InsightData insight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evidence = ref.watch(
      _insightEvidenceProvider((yearMonth: yearMonth, insight: insight)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('気づきの根拠')),
      body: evidence.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('根拠を読み込めませんでした')),
        data: (data) => _EvidenceBody(insight: insight, data: data),
      ),
    );
  }
}

final _insightEvidenceProvider = FutureProvider.autoDispose
    .family<InsightEvidenceData, ({String yearMonth, InsightData insight})>(
      (ref, input) => ref
          .watch(insightEvidenceUseCaseProvider)
          .load(yearMonth: input.yearMonth, insight: input.insight),
    );

class _EvidenceBody extends StatelessWidget {
  const _EvidenceBody({required this.insight, required this.data});

  final InsightData insight;
  final InsightEvidenceData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(insight.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(insight.body),
        const SizedBox(height: 16),
        Text(data.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          '表示する日付だけを示します。地点名や座標はここでは表示しません。',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (data.localDates.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('この気づきに対応する日別記録は見つかりませんでした。'),
            ),
          )
        else ...[
          Text('対象の記録日', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final date in data.localDates)
            Card(
              child: ListTile(
                title: Text(_dateLabel(date)),
                subtitle: const Text('日別タイムラインで確認'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DayDetailScreen(localDate: date),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _dateLabel(String localDate) {
    final parts = localDate.split('-');
    if (parts.length != 3) return localDate;
    return '${int.parse(parts[0])}年${int.parse(parts[1])}月${int.parse(parts[2])}日';
  }
}
