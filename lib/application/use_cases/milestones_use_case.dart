import 'dart:convert';

import '../../domain/change_detection/change_point.dart';
import '../../domain/change_detection/change_point_detector.dart';
import '../../domain/models/comparison.dart';
import '../../domain/services/distance_service.dart';
import '../models/persistence_models.dart';
import '../repositories/kurashilog_repository.dart';

class MilestoneReviewData {
  const MilestoneReviewData({
    required this.candidates,
    required this.milestones,
  });

  final List<ChangePointCandidate> candidates;
  final List<LifeMilestone> milestones;
}

/// 生活変化候補の生成、無視、ユーザー確定節目のCRUDをまとめる。
///
/// 検出候補は再生成可能な派生データ、節目はユーザー固有データとして扱い、
/// 候補の再解析や追加Importで節目を削除・上書きしない。
class MilestonesUseCase {
  const MilestonesUseCase({
    required this.repository,
    this.detector = const ChangePointDetector(),
    this.windowDays = 28,
  });

  static const ignoredCandidatesSettingKey =
      'change_detection.ignored_candidates.v1';

  final KurashilogRepository repository;
  final ChangePointDetector detector;
  final int windowDays;

  Future<MilestoneReviewData> loadReview() async {
    final ignored = await _loadIgnoredCandidateKeys();
    final candidates = await _detectCandidates();
    final milestones = await repository.allMilestones();
    milestones.sort(
      (a, b) => b.range.startInclusive.compareTo(a.range.startInclusive),
    );
    return MilestoneReviewData(
      candidates: [
        for (final candidate in candidates)
          if (!ignored.contains(candidateKey(candidate))) candidate,
      ],
      milestones: List<LifeMilestone>.unmodifiable(milestones),
    );
  }

  String candidateKey(ChangePointCandidate candidate) =>
      '${candidate.before.startInclusive.toIso8601String()}|'
      '${candidate.before.endExclusive.toIso8601String()}|'
      '${candidate.after.startInclusive.toIso8601String()}|'
      '${candidate.after.endExclusive.toIso8601String()}';

  Future<void> ignoreCandidate(ChangePointCandidate candidate) async {
    final ignored = await _loadIgnoredCandidateKeys();
    ignored.add(candidateKey(candidate));
    final values = ignored.toList()..sort();
    await repository.setSetting(
      ignoredCandidatesSettingKey,
      jsonEncode(values),
    );
  }

  Future<LifeMilestone> createMilestone({
    required ChangePointCandidate candidate,
    required String title,
    LocalDateRange? range,
    String? note,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Must not be empty');
    }
    final boundary = candidate.after.startInclusive;
    final milestoneRange =
        range ??
        LocalDateRange(
          startInclusive: boundary,
          endExclusive: boundary.addDays(1),
          timeZoneId: candidate.after.timeZoneId,
        );
    final now = DateTime.now();
    final milestone = LifeMilestone(
      id: 'milestone-${now.microsecondsSinceEpoch}',
      title: trimmedTitle,
      range: milestoneRange,
      createdAt: now,
      note: _cleanOptional(note),
      sourceCandidateKey: candidateKey(candidate),
    );
    await repository.insertMilestone(milestone);
    return milestone;
  }

  Future<void> updateMilestone({
    required LifeMilestone milestone,
    required String title,
    required LocalDateRange range,
    String? note,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Must not be empty');
    }
    await repository.updateMilestone(
      LifeMilestone(
        id: milestone.id,
        title: trimmedTitle,
        range: range,
        createdAt: milestone.createdAt,
        note: _cleanOptional(note),
        sourceCandidateKey: milestone.sourceCandidateKey,
      ),
    );
  }

  Future<void> deleteMilestone(String id) => repository.deleteMilestone(id);

  /// 節目の日付を境界として前後同期間を比較画面へ渡す。
  ComparisonRequest comparisonRequestForMilestone(LifeMilestone milestone) {
    final boundary = milestone.range.startInclusive;
    return ComparisonRequest(
      periodA: LocalDateRange(
        startInclusive: boundary.addDays(-windowDays),
        endExclusive: boundary,
        timeZoneId: milestone.range.timeZoneId,
      ),
      periodB: LocalDateRange(
        startInclusive: boundary,
        endExclusive: boundary.addDays(windowDays),
        timeZoneId: milestone.range.timeZoneId,
      ),
      alignment: ComparisonAlignment.milestone,
      metrics: const {
        ComparisonMetricId.visitCount,
        ComparisonMetricId.uniquePlaces,
        ComparisonMetricId.dwellDuration,
        ComparisonMetricId.outsideHomeDays,
        ComparisonMetricId.movementDistance,
        ComparisonMetricId.movementDuration,
        ComparisonMetricId.recurringPlaceCount,
      },
    );
  }

  Future<List<ChangePointCandidate>> _detectCandidates() async {
    final earliest = await repository.earliestActivityAt();
    final latest = await repository.latestActivityAt();
    if (earliest == null || latest == null || latest.isBefore(earliest)) {
      return const [];
    }

    final visits = await repository.allVisits();
    final movements = await repository.allMovements();
    final clusters = await repository.allClusters();
    final clusterById = {for (final cluster in clusters) cluster.id: cluster};
    final excludedIds = {
      for (final cluster in clusters)
        if (cluster.excludedFromAnalysis) cluster.id,
    };
    StoredCluster? baseCluster;
    for (final cluster in clusters) {
      if (cluster.isBasePlace) {
        baseCluster = cluster;
        break;
      }
    }

    final startLocal = earliest.toLocal();
    final endLocal = latest.toLocal();
    var start = LocalDate(startLocal.year, startLocal.month, startLocal.day);
    final last = LocalDate(
      endLocal.year,
      endLocal.month,
      endLocal.day,
    ).addDays(1);
    final timeZoneId = DateTime.now().timeZoneName;
    final snapshots = <LifeWindowSnapshot>[];

    while (start.addDays(windowDays).compareTo(last) <= 0) {
      final end = start.addDays(windowDays);
      final range = LocalDateRange(
        startInclusive: start,
        endExclusive: end,
        timeZoneId: timeZoneId,
      );
      snapshots.add(
        _snapshot(
          range: range,
          visits: visits,
          movements: movements,
          clusterById: clusterById,
          excludedIds: excludedIds,
          baseCluster: baseCluster,
        ),
      );
      start = end;
    }
    return detector.detect(snapshots);
  }

  LifeWindowSnapshot _snapshot({
    required LocalDateRange range,
    required List<StoredVisit> visits,
    required List<StoredMovement> movements,
    required Map<int, StoredCluster> clusterById,
    required Set<int> excludedIds,
    required StoredCluster? baseCluster,
  }) {
    final representedDays = <LocalDate>{};
    final placeDistribution = <String, double>{};
    final weekdayDistribution = <String, double>{};
    final timeOfDayDistribution = <String, double>{};
    double? lifeRadiusM;
    const distance = DistanceService();

    void recordTemporal(DateTime instant) {
      final local = instant.toLocal();
      final day = LocalDate(local.year, local.month, local.day);
      if (!range.contains(day)) return;
      representedDays.add(day);
      weekdayDistribution.update(
        '${local.weekday}',
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      final bucket = switch (local.hour) {
        < 6 => 'night',
        < 12 => 'morning',
        < 18 => 'daytime',
        < 22 => 'evening',
        _ => 'night',
      };
      timeOfDayDistribution.update(
        bucket,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    for (final visit in visits) {
      final local = visit.startAtUtc.toLocal();
      final day = LocalDate(local.year, local.month, local.day);
      if (!range.contains(day)) continue;
      if (visit.clusterId != null && excludedIds.contains(visit.clusterId)) {
        continue;
      }
      recordTemporal(visit.startAtUtc);
      final cluster = visit.clusterId == null
          ? null
          : clusterById[visit.clusterId];
      if (cluster != null) {
        placeDistribution.update(
          cluster.stableKey,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      if (baseCluster != null) {
        final radius = distance.haversineMeters(
          baseCluster.centroid,
          visit.latLng,
        );
        if (lifeRadiusM == null || radius > lifeRadiusM) lifeRadiusM = radius;
      }
    }
    for (final movement in movements) {
      final local = movement.startAtUtc.toLocal();
      final day = LocalDate(local.year, local.month, local.day);
      if (!range.contains(day)) continue;
      recordTemporal(movement.startAtUtc);
    }

    return LifeWindowSnapshot(
      range: range,
      coverageRatio: range.calendarDays == 0
          ? 0.0
          : (representedDays.length / range.calendarDays)
                .clamp(0.0, 1.0)
                .toDouble(),
      activeDays: representedDays.length,
      placeDistribution: Map.unmodifiable(placeDistribution),
      weekdayDistribution: Map.unmodifiable(weekdayDistribution),
      timeOfDayDistribution: Map.unmodifiable(timeOfDayDistribution),
      lifeRadiusM: lifeRadiusM,
    );
  }

  Future<Set<String>> _loadIgnoredCandidateKeys() async {
    final setting = await repository.getSetting(ignoredCandidatesSettingKey);
    if (setting == null) return <String>{};
    try {
      final decoded = jsonDecode(setting.value);
      if (decoded is! List) return <String>{};
      return {
        for (final value in decoded)
          if (value is String && value.isNotEmpty) value,
      };
    } on FormatException {
      return <String>{};
    }
  }

  String? _cleanOptional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
