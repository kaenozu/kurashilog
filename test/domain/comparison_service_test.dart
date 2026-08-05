import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/models/comparison.dart';
import 'package:kurashilog/domain/services/comparison_service.dart';

void main() {
  const zone = 'Asia/Tokyo';

  LocalDateRange range(
    int startYear,
    int startMonth,
    int startDay,
    int endYear,
    int endMonth,
    int endDay, {
    String timeZoneId = zone,
  }) => LocalDateRange(
    startInclusive: LocalDate(startYear, startMonth, startDay),
    endExclusive: LocalDate(endYear, endMonth, endDay),
    timeZoneId: timeZoneId,
  );

  PeriodCoverage coverage({
    required int expected,
    required int represented,
    int? reliable,
    int? active,
  }) => PeriodCoverage(
    expectedDays: expected,
    representedDays: represented,
    reliableDays: reliable ?? represented,
    activeDays: active ?? represented,
  );

  group('LocalDate and LocalDateRange', () {
    test('rejects invalid dates and empty time-zone identifiers', () {
      expect(() => LocalDate(2025, 2, 29), throwsArgumentError);
      expect(
        () => LocalDateRange(
          startInclusive: LocalDate(2026, 1, 1),
          endExclusive: LocalDate(2026, 1, 2),
          timeZoneId: '  ',
        ),
        throwsArgumentError,
      );
    });

    test('uses calendar arithmetic across leap day and DST periods', () {
      expect(LocalDate(2024, 2, 28).addDays(1), LocalDate(2024, 2, 29));
      expect(LocalDate(2024, 2, 28).addDays(2), LocalDate(2024, 3, 1));

      final dstRange = range(
        2026,
        3,
        7,
        2026,
        3,
        10,
        timeZoneId: 'America/New_York',
      );
      expect(dstRange.calendarDays, 3);
      expect(dstRange.contains(LocalDate(2026, 3, 9)), isTrue);
      expect(dstRange.contains(LocalDate(2026, 3, 10)), isFalse);
    });

    test('supports one-day and empty ranges explicitly', () {
      expect(range(2026, 1, 1, 2026, 1, 2).calendarDays, 1);
      final empty = range(2026, 1, 1, 2026, 1, 1);
      expect(empty.isEmpty, isTrue);
      expect(empty.calendarDays, 0);
    });

    test('builds leap-month and cross-year winter presets', () {
      expect(
        LocalDateRange.month(year: 2024, month: 2, timeZoneId: zone)
            .calendarDays,
        29,
      );
      expect(
        LocalDateRange.month(year: 2025, month: 2, timeZoneId: zone)
            .calendarDays,
        28,
      );
      final winter = LocalDateRange.season(
        seasonYear: 2025,
        season: ComparisonSeason.winter,
        timeZoneId: zone,
      );
      expect(winter.startInclusive, LocalDate(2025, 12, 1));
      expect(winter.endExclusive, LocalDate(2026, 3, 1));
    });
  });

  group('ComparisonPeriodAligner', () {
    const aligner = ComparisonPeriodAligner();

    test('keeps exact requested ranges unchanged', () {
      final a = range(2026, 1, 1, 2026, 2, 1);
      final b = range(2025, 3, 1, 2025, 4, 1);
      final result = aligner.align(
        ComparisonRequest(
          periodA: a,
          periodB: b,
          alignment: ComparisonAlignment.exact,
        ),
      );
      expect(result.effectiveA, a);
      expect(result.effectiveB, b);
      expect(result.warnings, isEmpty);
    });

    test('partial-year comparison uses the same elapsed calendar days', () {
      final result = aligner.align(
        ComparisonRequest(
          periodA: range(2026, 1, 1, 2026, 8, 6),
          periodB: range(2025, 1, 1, 2026, 1, 1),
          alignment: ComparisonAlignment.sameElapsedDays,
        ),
      );
      expect(result.effectiveA.calendarDays, 217);
      expect(result.effectiveB.calendarDays, 217);
      expect(result.effectiveB.endExclusive, LocalDate(2025, 8, 6));
    });

    test('leap-year elapsed alignment is symmetric and explained', () {
      final request = ComparisonRequest(
        periodA: range(2024, 1, 1, 2024, 3, 1),
        periodB: range(2023, 1, 1, 2024, 1, 1),
        alignment: ComparisonAlignment.sameElapsedDays,
      );
      final forward = aligner.align(request);
      final reverse = aligner.align(request.reversed());

      expect(forward.effectiveA.calendarDays, 60);
      expect(forward.effectiveB.calendarDays, 60);
      expect(forward.effectiveB.endExclusive, LocalDate(2023, 3, 2));
      expect(
        forward.warnings,
        contains(ComparisonWarningCode.leapDayClamped),
      );
      expect(reverse.effectiveA, forward.effectiveB);
      expect(reverse.effectiveB, forward.effectiveA);
      expect(reverse.warnings, forward.warnings);
    });

    test('normalizes month and season presets from each start date', () {
      final month = aligner.align(
        ComparisonRequest(
          periodA: range(2024, 2, 15, 2024, 2, 20),
          periodB: range(2025, 2, 3, 2025, 2, 8),
          alignment: ComparisonAlignment.sameMonth,
        ),
      );
      expect(month.effectiveA.calendarDays, 29);
      expect(month.effectiveB.calendarDays, 28);

      final season = aligner.align(
        ComparisonRequest(
          periodA: range(2025, 12, 20, 2026, 1, 5),
          periodB: range(2024, 1, 10, 2024, 2, 10),
          alignment: ComparisonAlignment.sameSeason,
        ),
      );
      expect(season.effectiveA.startInclusive, LocalDate(2025, 12, 1));
      expect(season.effectiveA.endExclusive, LocalDate(2026, 3, 1));
      expect(season.effectiveB.startInclusive, LocalDate(2023, 12, 1));
      expect(season.effectiveB.endExclusive, LocalDate(2024, 3, 1));
    });

    test('empty ranges remain explicit and produce a warning', () {
      final result = aligner.align(
        ComparisonRequest(
          periodA: range(2026, 1, 1, 2026, 1, 1),
          periodB: range(2025, 1, 1, 2025, 2, 1),
          alignment: ComparisonAlignment.sameElapsedDays,
        ),
      );
      expect(result.effectiveA.isEmpty, isTrue);
      expect(result.warnings, contains(ComparisonWarningCode.emptyPeriod));
    });
  });

  group('ComparisonQualityPolicy', () {
    const policy = ComparisonQualityPolicy();

    test('marks well-covered balanced periods comparable', () {
      final a = range(2026, 1, 1, 2026, 1, 31);
      final b = range(2025, 1, 1, 2025, 1, 31);
      final result = policy.evaluate(
        periodA: a,
        periodB: b,
        coverageA: coverage(expected: 30, represented: 28),
        coverageB: coverage(expected: 30, represented: 27),
      );
      expect(result.quality, ComparisonQuality.comparable);
      expect(
        result.warnings,
        isNot(contains(ComparisonWarningCode.insufficientCoverage)),
      );
    });

    test('marks medium coverage reference-only without directional certainty', () {
      final result = policy.evaluate(
        periodA: range(2026, 1, 1, 2026, 1, 31),
        periodB: range(2025, 1, 1, 2025, 1, 31),
        coverageA: coverage(expected: 30, represented: 18),
        coverageB: coverage(expected: 30, represented: 21),
      );
      expect(result.quality, ComparisonQuality.referenceOnly);
    });

    test('marks low coverage and empty periods insufficient', () {
      final low = policy.evaluate(
        periodA: range(2026, 1, 1, 2026, 1, 31),
        periodB: range(2025, 1, 1, 2025, 1, 31),
        coverageA: coverage(expected: 30, represented: 10),
        coverageB: coverage(expected: 30, represented: 28),
      );
      expect(low.quality, ComparisonQuality.insufficient);
      expect(
        low.warnings,
        contains(ComparisonWarningCode.insufficientCoverage),
      );
      expect(
        low.warnings,
        contains(ComparisonWarningCode.coverageImbalance),
      );

      final empty = policy.evaluate(
        periodA: range(2026, 1, 1, 2026, 1, 1),
        periodB: range(2025, 1, 1, 2025, 1, 2),
        coverageA: coverage(expected: 0, represented: 0),
        coverageB: coverage(expected: 1, represented: 1),
      );
      expect(empty.quality, ComparisonQuality.insufficient);
      expect(empty.warnings, contains(ComparisonWarningCode.emptyPeriod));
    });

    test('warns when weekday composition is materially different', () {
      final result = policy.evaluate(
        periodA: range(2026, 8, 3, 2026, 8, 8), // Monday to Friday
        periodB: range(2026, 8, 8, 2026, 8, 10), // Saturday and Sunday
        coverageA: coverage(expected: 5, represented: 5),
        coverageB: coverage(expected: 2, represented: 2),
      );
      expect(
        result.warnings,
        contains(ComparisonWarningCode.weekdayCompositionMismatch),
      );
    });
  });

  group('MetricComparator', () {
    const comparator = MetricComparator();
    final fullCoverage = coverage(expected: 10, represented: 10);
    final evidence = ComparisonEvidence(
      level: MetricEvidenceLevel.normalizedFact,
      sourceRefs: const <String>['timeline-import:fixture'],
      periodRefs: const <String>['A', 'B'],
    );

    test('separates raw and normalized values and reverses symmetrically', () {
      final forward = comparator.compare(
        id: ComparisonMetricId.visitCount,
        a: MetricValue(
          raw: 100,
          perRepresentedDay: 10,
          unit: 'visits',
          contributingDays: 10,
          coverage: fullCoverage,
        ),
        b: MetricValue(
          raw: 80,
          perRepresentedDay: 8,
          unit: 'visits',
          contributingDays: 10,
          coverage: fullCoverage,
        ),
        periodQuality: ComparisonQuality.comparable,
        evidence: evidence,
      );
      final reverse = comparator.compare(
        id: ComparisonMetricId.visitCount,
        a: forward.b,
        b: forward.a,
        periodQuality: ComparisonQuality.comparable,
        evidence: evidence,
      );

      expect(forward.rawDelta, 20);
      expect(forward.normalizedDelta, 2);
      expect(forward.percentageDelta, closeTo(2 / 9, 0.000001));
      expect(reverse.rawDelta, -forward.rawDelta!);
      expect(reverse.normalizedDelta, -forward.normalizedDelta!);
      expect(reverse.percentageDelta, -forward.percentageDelta!);
      expect(reverse.quality, forward.quality);
      expect(reverse.evidence, same(evidence));
    });

    test('does not invent percentages for zero denominators', () {
      final result = comparator.compare(
        id: ComparisonMetricId.movementDistance,
        a: MetricValue(
          raw: 0,
          perRepresentedDay: 0,
          unit: 'm',
          contributingDays: 10,
          coverage: fullCoverage,
        ),
        b: MetricValue(
          raw: 0,
          perRepresentedDay: 0,
          unit: 'm',
          contributingDays: 10,
          coverage: fullCoverage,
        ),
        periodQuality: ComparisonQuality.comparable,
        evidence: evidence,
      );
      expect(result.rawDelta, 0);
      expect(result.normalizedDelta, 0);
      expect(result.percentageDelta, isNull);
    });

    test('keeps unavailable metrics null instead of converting them to zero', () {
      final result = comparator.compare(
        id: ComparisonMetricId.activityRadius,
        a: MetricValue(
          raw: null,
          perRepresentedDay: null,
          unit: 'm',
          contributingDays: 0,
          coverage: fullCoverage,
        ),
        b: MetricValue(
          raw: 1200,
          perRepresentedDay: 120,
          unit: 'm',
          contributingDays: 10,
          coverage: fullCoverage,
        ),
        periodQuality: ComparisonQuality.comparable,
        evidence: evidence,
      );
      expect(result.rawDelta, isNull);
      expect(result.normalizedDelta, isNull);
      expect(result.percentageDelta, isNull);
      expect(result.quality, ComparisonQuality.insufficient);
    });
  });

  test('comparison request filters blank exclusions and is immutable', () {
    final request = ComparisonRequest(
      periodA: range(2026, 1, 1, 2026, 2, 1),
      periodB: range(2025, 1, 1, 2025, 2, 1),
      alignment: ComparisonAlignment.exact,
      metrics: const <ComparisonMetricId>{ComparisonMetricId.visitCount},
      excludedClusterIds: const <String>{' private-home ', '', 'work'},
    );
    expect(request.excludedClusterIds, <String>{'private-home', 'work'});
    expect(
      () => request.excludedClusterIds.add('another'),
      throwsUnsupportedError,
    );
    expect(request.reversed().periodA, request.periodB);
  });
}
