import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/models/comparison.dart';
import 'package:kurashilog/domain/models/life_report_card.dart';

void main() {
  final period = LocalDateRange(
    startInclusive: LocalDate(2024, 1, 1),
    endExclusive: LocalDate(2025, 1, 1),
    timeZoneId: 'Asia/Tokyo',
  );

  test('EvidenceRef keeps only stable references and period context', () {
    final evidence = EvidenceRef(
      period: period,
      metricKey: 'visit-count',
      clusterKeys: const <String>['cluster:1'],
      sourceKeys: const <String>['source:1'],
    );

    expect(evidence.period, period);
    expect(evidence.metricKey, 'visit-count');
    expect(evidence.clusterKeys, <String>['cluster:1']);
    expect(evidence.sourceKeys, <String>['source:1']);
  });

  test('EvidenceRef rejects evidence without a stable reference', () {
    expect(() => EvidenceRef(period: period), throwsArgumentError);
  });

  test('LifeReportCard preserves structured facts and quality contract', () {
    final card = LifeReportCard(
      id: 'coverage:2024',
      kind: LifeReportCardKind.coverage,
      headline: '記録期間',
      supportingFacts: const <ReportFact>[
        ReportFact(label: '記録日数', value: '120', unit: '日'),
      ],
      period: period,
      comparisonQuality: ComparisonQuality.comparable,
      confidence: ReportConfidence.fact,
      evidence: EvidenceRef(period: period, metricKey: 'coverage'),
      privacyState: ReportPrivacyState.visible,
    );

    expect(card.supportingFacts, hasLength(1));
    expect(card.comparisonQuality, ComparisonQuality.comparable);
    expect(card.confidence, ReportConfidence.fact);
    expect(card.evidence.metricKey, 'coverage');
  });

  test('LifeReportCard requires evidence for the same period', () {
    final otherPeriod = LocalDateRange(
      startInclusive: LocalDate(2025, 1, 1),
      endExclusive: LocalDate(2026, 1, 1),
      timeZoneId: 'Asia/Tokyo',
    );

    expect(
      () => LifeReportCard(
        id: 'coverage:mismatched-period',
        kind: LifeReportCardKind.coverage,
        headline: 'Coverage',
        period: period,
        comparisonQuality: ComparisonQuality.insufficient,
        confidence: ReportConfidence.fact,
        evidence: EvidenceRef(period: otherPeriod, metricKey: 'coverage'),
      ),
      throwsArgumentError,
    );
  });

  test('LifeReportCard rejects a blank identity or unavailable reason', () {
    expect(
      () => LifeReportCard(
        id: ' ',
        kind: LifeReportCardKind.coverage,
        headline: 'Coverage',
        period: period,
        comparisonQuality: ComparisonQuality.insufficient,
        confidence: ReportConfidence.fact,
        evidence: EvidenceRef(period: period, metricKey: 'coverage'),
      ),
      throwsArgumentError,
    );

    expect(
      () => LifeReportCard(
        id: 'coverage:empty',
        kind: LifeReportCardKind.coverage,
        headline: 'Coverage',
        period: period,
        comparisonQuality: ComparisonQuality.insufficient,
        confidence: ReportConfidence.fact,
        evidence: EvidenceRef(period: period, metricKey: 'coverage'),
        unavailableReason: ' ',
      ),
      throwsArgumentError,
    );
  });
}
