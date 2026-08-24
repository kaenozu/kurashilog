import 'package:flutter/material.dart';

import '../domain/models/insight.dart';

/// 説明可能性のための匿名化済み根拠一覧。
///
/// stable reference 自体は表示せず、内部IDや原本をUIへ漏らさない。
class EvidenceDetails extends StatelessWidget {
  const EvidenceDetails({super.key, required this.evidence});

  final List<InsightEvidence> evidence;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('根拠', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in evidence)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_iconFor(item.type)),
            title: Text(_labelFor(item.type)),
            subtitle: Text(_levelLabel(item.level)),
          ),
      ],
    );
  }

  IconData _iconFor(String type) => switch (type) {
    'cluster' => Icons.place_outlined,
    'metric' => Icons.insights_outlined,
    'source' => Icons.receipt_long_outlined,
    _ => Icons.fact_check_outlined,
  };

  String _labelFor(String type) => switch (type) {
    'cluster' => '地点の集計',
    'metric' => '指標の集計',
    'source' => '記録の集計',
    _ => '匿名化された集計',
  };

  String _levelLabel(InsightEvidenceLevel level) => switch (level) {
    InsightEvidenceLevel.fact => '記録から直接計算',
    InsightEvidenceLevel.weakInference => '弱い推定（断定しません）',
    InsightEvidenceLevel.userConfirmed => 'ユーザー確認済み',
  };
}
