import 'dart:convert';
import 'dart:isolate';

import '../../domain/models/data_quality.dart';
import '../../domain/models/insight.dart';
import '../../domain/models/summaries.dart';
import '../../domain/rules/insight_engine.dart';
import '../../domain/services/clustering_service.dart';
import '../../domain/services/distance_service.dart';
import '../../domain/services/freshness_service.dart';
import '../../domain/services/summary_service.dart';
import '../models/persistence_models.dart';
import '../repositories/kurashilog_repository.dart';
import 'window.dart';

class AnalysisCoordinator {
  const AnalysisCoordinator({
    required this.repository,
    this.clustering = const ClusteringService(),
    this.summaries = const SummaryService(),
    this.freshness = const FreshnessService(),
    this.insights = const InsightEngine(),
    this.distance = const DistanceService(),
  });

  final KurashilogRepository repository;
  final ClusteringService clustering;
  final SummaryService summaries;
  final FreshnessService freshness;
  final InsightEngine insights;
  final DistanceService distance;

  Future<void> rebuildAll() async {
    await _rebuildClusters();
    await _rebuildAllSummaries();
    await _rebuildInsights();
  }

  Future<void> rebuildSummariesAndInsights() async {
    await _rebuildAllSummaries();
    await _rebuildInsights();
  }

  Future<void> _rebuildClusters() async {
    final visits = await repository.allVisits();
    if (visits.isEmpty) {
      await repository.replaceAllClusters(const []);
      return;
    }

    final samples = visits
        .map(
          (visit) => VisitSample(
            coord: visit.latLng,
            dwellSeconds: visit.endAtUtc
                .difference(visit.startAtUtc)
                .inSeconds
                .clamp(0, 1 << 31)
                .toInt(),
            at: visit.startAtUtc,
          ),
        )
        .toList();
    final localClustering = clustering;
    final clusters = await Isolate.run(() => localClustering.cluster(samples));

    await repository.replaceAllClusters(
      clusters
          .map(
            (cluster) => StoredCluster(
              id: 0,
              stableKey: cluster.stableKey,
              centroidLatE7: cluster.centroidLatE7,
              centroidLngE7: cluster.centroidLngE7,
              radiusM: cluster.radiusM,
              visitCount: cluster.visitCount,
              dwellSeconds: cluster.dwellSeconds,
              firstAt: cluster.firstAt,
              lastAt: cluster.lastAt,
            ),
          )
          .toList(),
    );

    final stored = await repository.allClusters();
    if (stored.isEmpty) return;
    final assignments = <int, int>{};
    for (final visit in visits) {
      var best = stored.first;
      var bestDistance = distance.haversineMeters(visit.latLng, best.centroid);
      for (final cluster in stored.skip(1)) {
        final candidateDistance = distance.haversineMeters(
          visit.latLng,
          cluster.centroid,
        );
        if (candidateDistance < bestDistance) {
          best = cluster;
          bestDistance = candidateDistance;
        }
      }
      assignments[visit.id] = best.id;
    }
    await repository.assignVisitClusterIds(assignments);
  }

  Future<void> _rebuildAllSummaries() async {
    final earliest = await repository.earliestActivityAt();
    final latest = await repository.latestActivityAt();
    if (earliest == null || latest == null) return;

    var month = DateTime(earliest.toLocal().year, earliest.toLocal().month);
    final lastMonth = DateTime(latest.toLocal().year, latest.toLocal().month);
    while (!month.isAfter(lastMonth)) {
      await _rebuildMonth(month);
      month = DateTime(month.year, month.month + 1);
    }
  }

  Future<void> _rebuildMonth(DateTime monthLocal) async {
    final yearMonth = SummaryService.yearMonthOf(monthLocal);
    final monthStartUtc = DateTime(
      monthLocal.year,
      monthLocal.month,
      1,
    ).toUtc();
    final nextMonthStartUtc = DateTime(
      monthLocal.year,
      monthLocal.month + 1,
      1,
    ).toUtc();

    final visits = await repository.visitsInRange(
      monthStartUtc,
      nextMonthStartUtc,
    );
    final movements = await repository.movementsInRange(
      monthStartUtc,
      nextMonthStartUtc,
    );

    final labels = await repository.allLabels();
    final clusters = await repository.allClusters();
    final excludedIds = clusters
        .where((cluster) => cluster.excluded)
        .map((c) => c.id)
        .toSet();
    final baseLabel = labels.where((label) => label.isBasePlace).firstOrNull;
    final baseCluster = baseLabel == null
        ? null
        : clusters
              .where((cluster) => cluster.labelId == baseLabel.id)
              .firstOrNull;

    final visitsByDate = <String, List<StoredVisit>>{};
    for (final visit in visits) {
      final local = visit.startAtUtc.toLocal();
      if (local.year != monthLocal.year || local.month != monthLocal.month) {
        continue;
      }
      visitsByDate
          .putIfAbsent(SummaryService.localDateOf(local), () => [])
          .add(visit);
    }

    final movementsByDate = <String, List<StoredMovement>>{};
    for (final movement in movements) {
      final local = movement.startAtUtc.toLocal();
      if (local.year != monthLocal.year || local.month != monthLocal.month) {
        continue;
      }
      movementsByDate
          .putIfAbsent(SummaryService.localDateOf(local), () => [])
          .add(movement);
    }

    // データの無い日を「在宅日」として生成しない。
    final recordedDates = <String>{
      ...visitsByDate.keys,
      ...movementsByDate.keys,
    }.toList()..sort();

    final daily = <DailySummaryData>[];
    for (final date in recordedDates) {
      final dayVisits = visitsByDate[date] ?? const [];
      final dayMovements = movementsByDate[date] ?? const [];
      daily.add(
        summaries.computeDaily(
          localDate: date,
          visits: dayVisits
              .map(
                (visit) => DailyVisitInput(
                  startAtUtc: visit.startAtUtc,
                  endAtUtc: visit.endAtUtc,
                  clusterId: visit.clusterId,
                  excluded:
                      visit.clusterId != null &&
                      excludedIds.contains(visit.clusterId),
                  outsideBasePlace:
                      baseCluster != null && visit.clusterId != baseCluster.id,
                ),
              )
              .toList(),
          movements: dayMovements
              .map(
                (movement) => DailyMovementInput(
                  startAtUtc: movement.startAtUtc,
                  endAtUtc: movement.endAtUtc,
                  distanceM: movement.distanceM ?? 0,
                  isValidDistance:
                      movement.validDistance && movement.distanceM != null,
                ),
              )
              .toList(),
          hasBasePlace: baseCluster != null,
        ),
      );
    }

    // 古い計算結果を残さない。
    await repository.invalidateSummariesAfter('$yearMonth-01');
    await repository.upsertDailySummaries(daily);

    final previousMonth = SummaryService.yearMonthOf(
      DateTime(monthLocal.year, monthLocal.month - 1),
    );
    final previous = await repository.monthlySummary(previousMonth);
    final monthly = summaries.computeMonthly(
      yearMonth: yearMonth,
      days: daily,
      previousClusterIds: previous?.clusterIds ?? const {},
      calculatedAt: DateTime.now(),
    );
    await repository.upsertMonthlySummaries([monthly]);
  }

  Future<void> _rebuildInsights() async {
    final latest = await repository.latestActivityAt();
    if (latest == null) return;
    final window = computeComparisonWindow(latest.toLocal());
    final context = await _buildInsightContext(
      currentStart: window.currentStart,
      currentEnd: window.currentEnd,
      previousStart: window.previousStart,
      previousEnd: window.previousEnd,
      quality: freshness
          .evaluate(
            FreshnessInput(
              nowLocalDate: DateTime.now(),
              latestImportedAt: latest,
            ),
          )
          .quality,
    );
    final selected = insights.selectForMonthStory(context);
    await repository.replaceInsightsForPeriod(
      window.periodKey,
      selected
          .map(
            (insight) => StoredInsight(
              id: 0,
              periodKey: window.periodKey,
              ruleId: insight.ruleId,
              severity: insight.severity.name,
              title: insight.title,
              body: insight.body,
              metricJson: jsonEncode(insight.metricJson),
              createdAt: DateTime.now(),
            ),
          )
          .toList(),
    );
  }

  Future<List<InsightData>> insightsForMonth(String yearMonth) async {
    final parts = yearMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final currentStart = DateTime(year, month);
    final currentEnd = DateTime(year, month + 1);
    final previousStart = DateTime(year, month - 1);
    final latest = await repository.latestActivityAt();
    final quality = freshness
        .evaluate(
          FreshnessInput(
            nowLocalDate: DateTime.now(),
            latestImportedAt: latest,
          ),
        )
        .quality;
    final context = await _buildInsightContext(
      currentStart: currentStart,
      currentEnd: currentEnd,
      previousStart: previousStart,
      previousEnd: currentStart,
      quality: quality,
    );
    return insights.selectForMonthStory(context);
  }

  Future<InsightContext> _buildInsightContext({
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
    required DataQuality quality,
  }) async {
    final currentVisits = await repository.visitsInRange(
      currentStart.toUtc(),
      currentEnd.toUtc(),
    );
    final previousVisits = await repository.visitsInRange(
      previousStart.toUtc(),
      previousEnd.toUtc(),
    );
    final currentMovements = await repository.movementsInRange(
      currentStart.toUtc(),
      currentEnd.toUtc(),
    );
    final previousMovements = await repository.movementsInRange(
      previousStart.toUtc(),
      previousEnd.toUtc(),
    );

    final clusters = await repository.allClusters();
    final excludedIds = clusters
        .where((cluster) => cluster.excluded)
        .map((c) => c.id)
        .toSet();
    final labels = await repository.allLabels();
    final baseLabel = labels.where((label) => label.isBasePlace).firstOrNull;
    final baseCluster = baseLabel == null
        ? null
        : clusters
              .where((cluster) => cluster.labelId == baseLabel.id)
              .firstOrNull;

    int sumDistance(List<StoredMovement> values) => values
        .where(
          (movement) => movement.validDistance && movement.distanceM != null,
        )
        .fold(0, (sum, movement) => sum + movement.distanceM!);

    Map<int, int> clusterCounts(List<StoredVisit> values) {
      final result = <int, int>{};
      for (final visit in values) {
        final id = visit.clusterId;
        if (id == null || excludedIds.contains(id)) continue;
        result[id] = (result[id] ?? 0) + 1;
      }
      return result;
    }

    final currentCounts = clusterCounts(currentVisits);
    final previousCounts = clusterCounts(previousVisits);
    final newClusters = currentCounts.keys
        .where((id) => !previousCounts.containsKey(id))
        .length;

    int? medianReturn(List<StoredVisit> values) {
      if (baseCluster == null) return null;
      final perDay = <String, int>{};
      for (final visit in values) {
        final local = visit.startAtUtc.toLocal();
        if (local.weekday > DateTime.friday ||
            visit.clusterId != baseCluster.id) {
          continue;
        }
        final key = SummaryService.localDateOf(local);
        final minutes = local.hour * 60 + local.minute;
        final previous = perDay[key];
        if (previous == null || minutes > previous) perDay[key] = minutes;
      }
      if (perDay.length < 5) return null;
      final sorted = perDay.values.toList()..sort();
      return sorted[sorted.length ~/ 2];
    }

    int? medianHolidayRadius(List<StoredVisit> values) {
      if (baseCluster == null) return null;
      final distances = <int>[];
      for (final visit in values) {
        final local = visit.startAtUtc.toLocal();
        final holiday =
            local.weekday == DateTime.saturday ||
            local.weekday == DateTime.sunday;
        if (!holiday ||
            visit.clusterId == baseCluster.id ||
            excludedIds.contains(visit.clusterId)) {
          continue;
        }
        distances.add(
          distance.haversineMeters(visit.latLng, baseCluster.centroid).round(),
        );
      }
      if (distances.length < 5) return null;
      distances.sort();
      return distances[distances.length ~/ 2];
    }

    final currentDays = _toLocalDays(
      currentVisits,
      currentMovements,
      excludedIds,
    );
    final previousDays = _toLocalDays(
      previousVisits,
      previousMovements,
      excludedIds,
    );

    return InsightContext(
      quality: quality,
      currentDayCount: currentEnd.difference(currentStart).inDays,
      previousDayCount: previousEnd.difference(previousStart).inDays,
      currentOutingDays: currentDays.values.where((value) => value).length,
      previousOutingDays: previousDays.values.where((value) => value).length,
      currentDistanceM: sumDistance(currentMovements),
      previousDistanceM: sumDistance(previousMovements),
      newClusterCount: newClusters,
      currentClusterVisits: currentCounts,
      previousClusterVisits: previousCounts,
      baseClusterId: baseCluster?.id,
      baseCentroidLatE7: baseCluster?.centroidLatE7,
      baseCentroidLngE7: baseCluster?.centroidLngE7,
      clusterCentroids: {
        for (final cluster in clusters)
          cluster.id: (cluster.centroidLatE7, cluster.centroidLngE7),
      },
      clusterNames: {
        for (final cluster in clusters) cluster.id: cluster.displayName,
      },
      currentWeekdayReturnMinutes: medianReturn(currentVisits),
      previousWeekdayReturnMinutes: medianReturn(previousVisits),
      currentHolidayRadiusM: medianHolidayRadius(currentVisits),
      previousHolidayRadiusM: medianHolidayRadius(previousVisits),
    );
  }

  Map<String, bool> _toLocalDays(
    List<StoredVisit> visits,
    List<StoredMovement> movements,
    Set<int> excludedIds,
  ) {
    final days = <String, bool>{};
    for (final visit in visits) {
      if (visit.clusterId != null && excludedIds.contains(visit.clusterId)) {
        continue;
      }
      days[SummaryService.localDateOf(visit.startAtUtc.toLocal())] = true;
    }
    for (final movement in movements) {
      if (!movement.validDistance) continue;
      days[SummaryService.localDateOf(movement.startAtUtc.toLocal())] = true;
    }
    return days;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
