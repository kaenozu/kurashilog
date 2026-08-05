import 'dart:math' as math;

import '../models/comparison.dart';

final class ComparisonQualityResult {
  factory ComparisonQualityResult({
    required ComparisonQuality quality,
    Iterable<ComparisonWarningCode> warnings =
        const <ComparisonWarningCode>[],
  }) => ComparisonQualityResult._(
    quality,
    Set<ComparisonWarningCode>.unmodifiable(warnings),
  );

  const ComparisonQualityResult._(this.quality, this.warnings);

  final ComparisonQuality quality;
  final Set<ComparisonWarningCode> warnings;
}

/// Resolves requested ranges to the exact ranges used by aggregation.
final class ComparisonPeriodAligner {
  const ComparisonPeriodAligner();

  PeriodAlignmentResult align(ComparisonRequest request) {
    return switch (request.alignment) {
      ComparisonAlignment.exact || ComparisonAlignment.milestone =>
        _result(request, request.periodA, request.periodB),
      ComparisonAlignment.sameElapsedDays => _sameElapsedDays(request),
      ComparisonAlignment.sameMonth => _sameMonth(request),
      ComparisonAlignment.sameSeason => _sameSeason(request),
    };
  }

  PeriodAlignmentResult _sameElapsedDays(ComparisonRequest request) {
    final a = request.periodA;
    final b = request.periodB;
    final warnings = <ComparisonWarningCode>{};
    if (a.isEmpty || b.isEmpty) {
      warnings.add(ComparisonWarningCode.emptyPeriod);
      return _result(request, a, b, warnings);
    }

    final elapsedDays = math.min(a.calendarDays, b.calendarDays);
    final effectiveA = a.copyWith(
      endExclusive: a.startInclusive.addDays(elapsedDays),
    );
    final effectiveB = b.copyWith(
      endExclusive: b.startInclusive.addDays(elapsedDays),
    );

    // Equal elapsed-day ranges can end on different month/day components when
    // only one year contains February 29. The ranges are still fair by day
    // count, but presentation should explain the calendar-date difference.
    if (effectiveA.endExclusive.month != effectiveB.endExclusive.month ||
        effectiveA.endExclusive.day != effectiveB.endExclusive.day) {
      warnings.add(ComparisonWarningCode.leapDayClamped);
    }
    return _result(request, effectiveA, effectiveB, warnings);
  }

  PeriodAlignmentResult _sameMonth(ComparisonRequest request) {
    final aStart = request.periodA.startInclusive;
    final bStart = request.periodB.startInclusive;
    return _result(
      request,
      LocalDateRange.month(
        year: aStart.year,
        month: aStart.month,
        timeZoneId: request.periodA.timeZoneId,
      ),
      LocalDateRange.month(
        year: bStart.year,
        month: bStart.month,
        timeZoneId: request.periodB.timeZoneId,
      ),
    );
  }

  PeriodAlignmentResult _sameSeason(ComparisonRequest request) {
    final (seasonA, seasonYearA) = _season(request.periodA.startInclusive);
    final (seasonB, seasonYearB) = _season(request.periodB.startInclusive);
    return _result(
      request,
      LocalDateRange.season(
        seasonYear: seasonYearA,
        season: seasonA,
        timeZoneId: request.periodA.timeZoneId,
      ),
      LocalDateRange.season(
        seasonYear: seasonYearB,
        season: seasonB,
        timeZoneId: request.periodB.timeZoneId,
      ),
    );
  }

  (ComparisonSeason, int) _season(LocalDate date) {
    if (date.month >= 3 && date.month <= 5) {
      return (ComparisonSeason.spring, date.year);
    }
    if (date.month >= 6 && date.month <= 8) {
      return (ComparisonSeason.summer, date.year);
    }
    if (date.month >= 9 && date.month <= 11) {
      return (ComparisonSeason.autumn, date.year);
    }
    return (
      ComparisonSeason.winter,
      date.month <= 2 ? date.year - 1 : date.year,
    );
  }

  PeriodAlignmentResult _result(
    ComparisonRequest request,
    LocalDateRange effectiveA,
    LocalDateRange effectiveB, [
    Iterable<ComparisonWarningCode> warnings =
        const <ComparisonWarningCode>[],
  ]) => PeriodAlignmentResult(
    requestedA: request.periodA,
    requestedB: request.periodB,
    effectiveA: effectiveA,
    effectiveB: effectiveB,
    warnings: Set<ComparisonWarningCode>.unmodifiable(warnings),
  );
}

/// Central policy for coverage and fair-comparison quality.
final class ComparisonQualityPolicy {
  const ComparisonQualityPolicy({
    this.comparableCoverageRatio = 0.8,
    this.referenceCoverageRatio = 0.5,
    this.minimumComparableDays = 14,
    this.maximumCoverageGap = 0.1,
    this.maximumWeekendShareGap = 0.12,
  }) : assert(comparableCoverageRatio >= 0 && comparableCoverageRatio <= 1),
       assert(referenceCoverageRatio >= 0 && referenceCoverageRatio <= 1),
       assert(referenceCoverageRatio <= comparableCoverageRatio),
       assert(minimumComparableDays >= 1),
       assert(maximumCoverageGap >= 0 && maximumCoverageGap <= 1),
       assert(maximumWeekendShareGap >= 0 && maximumWeekendShareGap <= 1);

  final double comparableCoverageRatio;
  final double referenceCoverageRatio;
  final int minimumComparableDays;
  final double maximumCoverageGap;
  final double maximumWeekendShareGap;

  ComparisonQualityResult evaluate({
    required LocalDateRange periodA,
    required LocalDateRange periodB,
    required PeriodCoverage coverageA,
    required PeriodCoverage coverageB,
  }) {
    final warnings = <ComparisonWarningCode>{};
    if (periodA.isEmpty || periodB.isEmpty) {
      warnings.add(ComparisonWarningCode.emptyPeriod);
      return ComparisonQualityResult(
        quality: ComparisonQuality.insufficient,
        warnings: warnings,
      );
    }

    final minRepresented = math.min(
      coverageA.representedDays,
      coverageB.representedDays,
    );
    if (minRepresented < minimumComparableDays) {
      warnings.add(ComparisonWarningCode.shortPeriod);
    }

    final ratioA = coverageA.representedDayRatio;
    final ratioB = coverageB.representedDayRatio;
    final coverageGap = (ratioA - ratioB).abs();
    if (coverageGap > maximumCoverageGap) {
      warnings.add(ComparisonWarningCode.coverageImbalance);
    }
    if (_weekendShareGap(periodA, periodB) > maximumWeekendShareGap) {
      warnings.add(ComparisonWarningCode.weekdayCompositionMismatch);
    }

    if (ratioA < referenceCoverageRatio ||
        ratioB < referenceCoverageRatio ||
        coverageA.reliableDays == 0 ||
        coverageB.reliableDays == 0) {
      warnings.add(ComparisonWarningCode.insufficientCoverage);
      return ComparisonQualityResult(
        quality: ComparisonQuality.insufficient,
        warnings: warnings,
      );
    }

    final comparable =
        ratioA >= comparableCoverageRatio &&
        ratioB >= comparableCoverageRatio &&
        minRepresented >= minimumComparableDays &&
        coverageGap <= maximumCoverageGap;
    return ComparisonQualityResult(
      quality: comparable
          ? ComparisonQuality.comparable
          : ComparisonQuality.referenceOnly,
      warnings: warnings,
    );
  }

  double _weekendShareGap(LocalDateRange a, LocalDateRange b) =>
      (_weekendShare(a) - _weekendShare(b)).abs();

  double _weekendShare(LocalDateRange range) {
    if (range.isEmpty) return 0;
    var weekendDays = 0;
    for (
      var date = range.startInclusive;
      date.compareTo(range.endExclusive) < 0;
      date = date.addDays(1)
    ) {
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        weekendDays++;
      }
    }
    return weekendDays / range.calendarDays;
  }
}

final class MetricComparator {
  const MetricComparator();

  MetricComparison compare({
    required ComparisonMetricId id,
    required MetricValue a,
    required MetricValue b,
    required ComparisonQuality periodQuality,
    required ComparisonEvidence evidence,
  }) {
    final rawDelta = _delta(a.raw, b.raw);
    final normalizedDelta = _delta(
      a.perRepresentedDay,
      b.perRepresentedDay,
    );
    final percentageBaseA = a.perRepresentedDay ?? a.raw;
    final percentageBaseB = b.perRepresentedDay ?? b.raw;
    final percentageDelta = _symmetricPercentage(
      percentageBaseA,
      percentageBaseB,
    );
    final unavailable = a.raw == null || b.raw == null;

    return MetricComparison(
      id: id,
      a: a,
      b: b,
      rawDelta: rawDelta,
      normalizedDelta: normalizedDelta,
      percentageDelta: percentageDelta,
      quality: unavailable
          ? ComparisonQuality.insufficient
          : periodQuality,
      evidence: evidence,
    );
  }

  double? _delta(double? a, double? b) =>
      a == null || b == null ? null : a - b;

  /// Uses the average absolute magnitude as denominator. Unlike baseline-only
  /// percentages, reversing A/B preserves magnitude and only changes sign.
  double? _symmetricPercentage(double? a, double? b) {
    if (a == null || b == null) return null;
    final denominator = (a.abs() + b.abs()) / 2;
    if (denominator == 0) return null;
    return (a - b) / denominator;
  }
}
