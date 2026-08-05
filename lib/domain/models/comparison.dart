import 'dart:math' as math;

/// Calendar date without a time-of-day or implicit device time zone.
///
/// Repositories convert source instants to [LocalDate] with an explicit time
/// zone before using the comparison domain. Calendar arithmetic is performed
/// through UTC date components so DST never changes a day count.
final class LocalDate implements Comparable<LocalDate> {
  factory LocalDate(int year, int month, int day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError.value(
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
        'date',
        'Invalid calendar date',
      );
    }
    return LocalDate._(year, month, day);
  }

  const LocalDate._(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  int get weekday => _utc.weekday;

  LocalDate addDays(int days) {
    final value = _utc.add(Duration(days: days));
    return LocalDate(value.year, value.month, value.day);
  }

  int differenceInDays(LocalDate other) => _utc.difference(other._utc).inDays;

  /// Copies the month/day into [targetYear], clamping leap-day or month-end
  /// values to the last valid day in that month.
  LocalDate withYearClamped(int targetYear) {
    final lastDay = DateTime.utc(targetYear, month + 1, 0).day;
    return LocalDate(targetYear, month, math.min(day, lastDay));
  }

  String toIso8601String() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso8601String();
}

/// Date range using start-inclusive/end-exclusive semantics.
final class LocalDateRange {
  factory LocalDateRange({
    required LocalDate startInclusive,
    required LocalDate endExclusive,
    required String timeZoneId,
  }) {
    if (startInclusive.compareTo(endExclusive) > 0) {
      throw ArgumentError('startInclusive must not be after endExclusive');
    }
    final normalizedTimeZone = timeZoneId.trim();
    if (normalizedTimeZone.isEmpty) {
      throw ArgumentError.value(timeZoneId, 'timeZoneId', 'Must not be empty');
    }
    return LocalDateRange._(startInclusive, endExclusive, normalizedTimeZone);
  }

  const LocalDateRange._(
    this.startInclusive,
    this.endExclusive,
    this.timeZoneId,
  );

  factory LocalDateRange.month({
    required int year,
    required int month,
    required String timeZoneId,
  }) {
    final start = LocalDate(year, month, 1);
    final nextMonth = month == 12
        ? LocalDate(year + 1, 1, 1)
        : LocalDate(year, month + 1, 1);
    return LocalDateRange(
      startInclusive: start,
      endExclusive: nextMonth,
      timeZoneId: timeZoneId,
    );
  }

  factory LocalDateRange.season({
    required int seasonYear,
    required ComparisonSeason season,
    required String timeZoneId,
  }) {
    final (start, end) = switch (season) {
      ComparisonSeason.spring => (
        LocalDate(seasonYear, 3, 1),
        LocalDate(seasonYear, 6, 1),
      ),
      ComparisonSeason.summer => (
        LocalDate(seasonYear, 6, 1),
        LocalDate(seasonYear, 9, 1),
      ),
      ComparisonSeason.autumn => (
        LocalDate(seasonYear, 9, 1),
        LocalDate(seasonYear, 12, 1),
      ),
      ComparisonSeason.winter => (
        LocalDate(seasonYear, 12, 1),
        LocalDate(seasonYear + 1, 3, 1),
      ),
    };
    return LocalDateRange(
      startInclusive: start,
      endExclusive: end,
      timeZoneId: timeZoneId,
    );
  }

  final LocalDate startInclusive;
  final LocalDate endExclusive;
  final String timeZoneId;

  int get calendarDays => endExclusive.differenceInDays(startInclusive);
  bool get isEmpty => calendarDays == 0;

  bool contains(LocalDate date) =>
      date.compareTo(startInclusive) >= 0 && date.compareTo(endExclusive) < 0;

  LocalDateRange copyWith({
    LocalDate? startInclusive,
    LocalDate? endExclusive,
    String? timeZoneId,
  }) => LocalDateRange(
    startInclusive: startInclusive ?? this.startInclusive,
    endExclusive: endExclusive ?? this.endExclusive,
    timeZoneId: timeZoneId ?? this.timeZoneId,
  );

  @override
  bool operator ==(Object other) =>
      other is LocalDateRange &&
      startInclusive == other.startInclusive &&
      endExclusive == other.endExclusive &&
      timeZoneId == other.timeZoneId;

  @override
  int get hashCode => Object.hash(startInclusive, endExclusive, timeZoneId);

  @override
  String toString() =>
      '${startInclusive.toIso8601String()}..${endExclusive.toIso8601String()} '
      '[$timeZoneId]';
}

enum ComparisonPresetKind { year, month, season, custom, milestone }

enum ComparisonSeason { spring, summer, autumn, winter }

enum ComparisonAlignment {
  exact,
  sameElapsedDays,
  sameMonth,
  sameSeason,
  milestone,
}

enum ComparisonQuality { comparable, referenceOnly, insufficient }

enum MetricEvidenceLevel { fact, normalizedFact, weakInference }

enum ComparisonWarningCode {
  emptyPeriod,
  shortPeriod,
  insufficientCoverage,
  coverageImbalance,
  weekdayCompositionMismatch,
  leapDayClamped,
}

enum ComparisonMetricId {
  visitCount,
  uniquePlaces,
  dwellDuration,
  outsideHomeDays,
  movementDistance,
  movementDuration,
  recurringPlaceCount,
  categoryDistribution,
  weekdayDistribution,
  timeOfDayDistribution,
  activityRadius,
}

final class ComparisonRequest {
  factory ComparisonRequest({
    required LocalDateRange periodA,
    required LocalDateRange periodB,
    required ComparisonAlignment alignment,
    Set<ComparisonMetricId> metrics = const <ComparisonMetricId>{},
    Set<String> excludedClusterIds = const <String>{},
  }) => ComparisonRequest._(
    periodA,
    periodB,
    alignment,
    Set<ComparisonMetricId>.unmodifiable(metrics),
    Set<String>.unmodifiable(
      excludedClusterIds
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    ),
  );

  const ComparisonRequest._(
    this.periodA,
    this.periodB,
    this.alignment,
    this.metrics,
    this.excludedClusterIds,
  );

  final LocalDateRange periodA;
  final LocalDateRange periodB;
  final ComparisonAlignment alignment;
  final Set<ComparisonMetricId> metrics;
  final Set<String> excludedClusterIds;

  ComparisonRequest reversed() => ComparisonRequest(
    periodA: periodB,
    periodB: periodA,
    alignment: alignment,
    metrics: metrics,
    excludedClusterIds: excludedClusterIds,
  );
}

/// Coverage is based on represented local calendar days, not record count.
final class PeriodCoverage {
  factory PeriodCoverage({
    required int expectedDays,
    required int representedDays,
    required int reliableDays,
    required int activeDays,
    DateTime? firstRecordAt,
    DateTime? lastRecordAt,
  }) {
    if (expectedDays < 0 ||
        representedDays < 0 ||
        reliableDays < 0 ||
        activeDays < 0) {
      throw ArgumentError('Coverage day counts must not be negative');
    }
    if (representedDays > expectedDays || reliableDays > representedDays) {
      throw ArgumentError('Coverage day counts are inconsistent');
    }
    if (activeDays > representedDays) {
      throw ArgumentError('activeDays must not exceed representedDays');
    }
    return PeriodCoverage._(
      expectedDays,
      representedDays,
      reliableDays,
      activeDays,
      firstRecordAt,
      lastRecordAt,
    );
  }

  const PeriodCoverage._(
    this.expectedDays,
    this.representedDays,
    this.reliableDays,
    this.activeDays,
    this.firstRecordAt,
    this.lastRecordAt,
  );

  final int expectedDays;
  final int representedDays;
  final int reliableDays;
  final int activeDays;
  final DateTime? firstRecordAt;
  final DateTime? lastRecordAt;

  double get representedDayRatio =>
      expectedDays == 0 ? 0 : representedDays / expectedDays;

  double get reliableDayRatio =>
      expectedDays == 0 ? 0 : reliableDays / expectedDays;
}

final class MetricValue {
  const MetricValue({
    required this.raw,
    required this.perRepresentedDay,
    required this.unit,
    required this.contributingDays,
    required this.coverage,
  });

  /// Null means unavailable. It must never be converted to zero implicitly.
  final double? raw;
  final double? perRepresentedDay;
  final String unit;
  final int contributingDays;
  final PeriodCoverage coverage;
}

final class ComparisonEvidence {
  factory ComparisonEvidence({
    required MetricEvidenceLevel level,
    Iterable<String> sourceRefs = const <String>[],
    Iterable<String> placeRefs = const <String>[],
    Iterable<String> periodRefs = const <String>[],
  }) => ComparisonEvidence._(
    level,
    List<String>.unmodifiable(sourceRefs),
    List<String>.unmodifiable(placeRefs),
    List<String>.unmodifiable(periodRefs),
  );

  const ComparisonEvidence._(
    this.level,
    this.sourceRefs,
    this.placeRefs,
    this.periodRefs,
  );

  final MetricEvidenceLevel level;
  final List<String> sourceRefs;
  final List<String> placeRefs;
  final List<String> periodRefs;
}

final class MetricComparison {
  const MetricComparison({
    required this.id,
    required this.a,
    required this.b,
    required this.rawDelta,
    required this.normalizedDelta,
    required this.percentageDelta,
    required this.quality,
    required this.evidence,
  });

  final ComparisonMetricId id;
  final MetricValue a;
  final MetricValue b;

  /// A minus B. Reversing the comparison negates this value.
  final double? rawDelta;

  /// Per-represented-day A minus B.
  final double? normalizedDelta;

  /// Symmetric percentage difference. This preserves magnitude when A/B swap.
  final double? percentageDelta;
  final ComparisonQuality quality;
  final ComparisonEvidence evidence;

  MetricComparison reversed() => MetricComparison(
    id: id,
    a: b,
    b: a,
    rawDelta: rawDelta == null ? null : -rawDelta!,
    normalizedDelta: normalizedDelta == null ? null : -normalizedDelta!,
    percentageDelta: percentageDelta == null ? null : -percentageDelta!,
    quality: quality,
    evidence: evidence,
  );
}

final class PeriodAlignmentResult {
  const PeriodAlignmentResult({
    required this.requestedA,
    required this.requestedB,
    required this.effectiveA,
    required this.effectiveB,
    required this.warnings,
  });

  final LocalDateRange requestedA;
  final LocalDateRange requestedB;
  final LocalDateRange effectiveA;
  final LocalDateRange effectiveB;
  final Set<ComparisonWarningCode> warnings;

  PeriodAlignmentResult reversed() => PeriodAlignmentResult(
    requestedA: requestedB,
    requestedB: requestedA,
    effectiveA: effectiveB,
    effectiveB: effectiveA,
    warnings: warnings,
  );
}

final class PeriodComparison {
  const PeriodComparison({
    required this.request,
    required this.alignment,
    required this.coverageA,
    required this.coverageB,
    required this.overallQuality,
    required this.warnings,
    required this.metrics,
  });

  final ComparisonRequest request;
  final PeriodAlignmentResult alignment;
  final PeriodCoverage coverageA;
  final PeriodCoverage coverageB;
  final ComparisonQuality overallQuality;
  final Set<ComparisonWarningCode> warnings;
  final List<MetricComparison> metrics;
}
