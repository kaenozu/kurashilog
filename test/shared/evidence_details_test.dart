import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kurashilog/domain/models/insight.dart';
import 'package:kurashilog/shared/evidence_details.dart';

void main() {
  testWidgets('evidence details shows safe labels without stable references', (
    tester,
  ) async {
    const evidence = [
      InsightEvidence(
        type: 'cluster',
        reference: 'cluster:private-internal-key',
        level: InsightEvidenceLevel.fact,
      ),
      InsightEvidence(
        type: 'metric',
        reference: 'outing-days',
        level: InsightEvidenceLevel.weakInference,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EvidenceDetails(evidence: evidence)),
      ),
    );

    expect(find.text('地点の集計'), findsOneWidget);
    expect(find.text('指標の集計'), findsOneWidget);
    expect(find.text('記録から直接計算'), findsOneWidget);
    expect(find.text('弱い推定（断定しません）'), findsOneWidget);
    expect(find.textContaining('private-internal-key'), findsNothing);
    expect(find.text('outing-days'), findsNothing);
  });
}
