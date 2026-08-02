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

/// 分析の再構築コーディネーター（設計書 M04 / M05 / M06 / 6.1〜6.5）。
///
/// インポート成功後に、影響範囲のクラスタ・日次/月次サマリー・
/// インサイトを再計算する。クラスタ計算は Isolate で実行し、
/// メイン UI を止めない（設計書 10.1）。
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

  /// インポート後に呼ぶ。全期間を再構築する（決定性・単純さを優先）。
  Future<void> rebuildAll() async {
    await _rebuildClusters();
    await _rebuildAllSummaries();
    await _rebuildInsights();
  }

  /// 地点ラベル・除外変更後に呼ぶ（クラスタは据え置き、集計のみ再計算）。
  Future<void> rebuildSummariesAndInsights() async {
    await _rebuildAllSummaries();
    await _rebuildInsights();
  }

  // --- クラスタ ---

  Future<void> _rebuildClusters() async {
    final visits = await repository.allVisits();
    if (visits.isEmpty) {
      await repository.replaceAllClusters(const []);
      return;
    }

    final samples = visits
        .map((v) => ClusteringService.VisitSample(
              coord: v.latLng,
              dwellSeconds: v.endAtUtc
                  .difference(v.startAtUtc)
                  .inSeconds
                  .clamp(0, 1 << 31),
              at: v.startAtUtc,
            ))
        .toList();

    // Isolate でクラスタ計算（純粋関数）。
    final clusters = await Isolate.run(() => clustering.cluster(samples));

    await repository.replaceAllClusters(clusters
        .map((c) => StoredCluster(
              id: 0,
              stableKey: c.stableKey,
              centroidLatE7: c.centroidLatE7,
              centroidLngE7: c.centroidLngE7,
              radiusM: c.radiusM,
              visitCount: c.visitCount,
              dwellSeconds: c.dwellSeconds,
              firstAt: c.firstAt,
              lastAt: c.lastAt,
            ))
        .toList());

    // 訪問ごとに最も近いクラスタを割り当てる。
    final stored = await repository.allClusters();
    if (stored.isEmpty) return;
    final assignments = <int, int>{};
    for (final v in visits) {
      var bestId = stored.first.id;
      var bestD = double.infinity;
      for (final c in stored) {
        final d = distance.haversineMeters(v.latLng, c.centroid);
        if (d < bestD) {
          bestD = d;
          bestId = c.id;
        }
      }
      assignments[v.id] = bestId;
    }
    await repository.assignVisitClusterIds(assignments);
  }

  // --- 日次・月次サマリー ---

  Future<void> _rebuildAllSummaries() async {
    final earliest = await repository.earliestActivityAt();
    final latest = await repository.latestActivityAt();
    if (earliest == null || latest == null) return;

    final firstMonth = DateTime(earliest.toLocal().year, earliest.toLocal().month);
    final lastMonth = DateTime(latest.toLocal().year, latest.toLocal().month);

    var m = firstMonth;
    while (!m.isAfter(lastMonth)) {
      await _rebuildMonth(m);
      m = DateTime(m.year, m.month + 1);
    }
  }

  Future<void> _rebuildMonth(DateTime monthLocal) async {
    final ym = SummaryService.yearMonthOf(monthLocal);
    final monthStartUtc = DateTime(monthLocal.year, monthLocal.month, 1).toUtc();
    final nextMonthStartUtc =
        DateTime(monthLocal.year, monthLocal.month + 1, 1).toUtc();

    final visits = await repository.visitsInRange(monthStartUtc, nextMonthStartUtc);
    final movements =
        await repository.movementsInRange(monthStartUtc, nextMonthStartUtc);

    // 基準地点（ユーザー確認済みラベル）を特定
    final labels = await repository.allLabels();
    final clusters = await repository.allClusters();
    final excludedIds =
        clusters.where((c) => c.excluded).map((c) => c.id).toSet();
    final baseLabel = labels.where((l) => l.isBasePlace).firstOrNull;
    int? baseClusterId;
    if (baseLabel != null) {
      baseClusterId =
          clusters.where((c) => c.labelId == baseLabel.id).firstOrNull?.id;
    }
    final hasBasePlace = baseClusterId != null;

    // ローカル日ごとにグループ化
    final byDate = <String, List<StoredVisit>>{};
    for (final v in visits) {
      final local = v.startAtUtc.toLocal();
      if (local.year != monthLocal.year || local.month != monthLocal.month) {
        continue;
      }
      byDate
          .putIfAbsent(SummaryService.localDateOf(local), () => [])
          .add(v);
    }
    final mByDate = <String, List<StoredMovement>>{};
    for (final mv in movements) {
      final local = mv.startAtUtc.toLocal();
      if (local.year != monthLocal.year || local.month != monthLocal.month) {
        continue;
      }
      mByDate.putIfAbsent(SummaryService.localDateOf(local), () => []).add(mv);
    }

    // 全ローカル日を列挙（記録が無い日も 0 サマリーを作る）
    final allDates = <String>{...byDate.keys, ...mByDate.keys};
    final daysInMonth = DateTime(monthLocal.year, monthLocal.month + 1, 0).day;
    for (var d = 1; d <= daysInMonth; d++) {
      allDates.add(SummaryService.localDateOf(
          DateTime(monthLocal.year, monthLocal.month, d)));
    }

    final daily = <DailySummaryData>[];
    for (final date in allDates.toList()..sort()) {
      final dayVisits = byDate[date] ?? const [];
      final dayMovements = mByDate[date] ?? const [];
      daily.add(summaries.computeDaily(
        localDate: date,
        visits: dayVisits
            .map((v) => DailyVisitInput(
                  startAtUtc: v.startAtUtc,
                  endAtUtc: v.endAtUtc,
                  clusterId: v.clusterId,
                  excluded:
                      v.clusterId != null && excludedIds.contains(v.clusterId!),
                  outsideBasePlace:
                      hasBasePlace && v.clusterId != baseClusterId,
                ))
            .toList(),
        movements: dayMovements
            .map((m) => DailyMovementInput(
                  startAtUtc: m.startAtUtc,
                  endAtUtc: m.endAtUtc,
                  distanceM: m.distanceM ?? 0,
                  isValidDistance: m.validDistance && m.distanceM != null,
                ))
            .toList(),
        hasBasePlace: hasBasePlace,
      ));
    }

    await repository.upsertDailySummaries(daily);

    // 前月のクラスタ集合
    final prev = await repository.monthlySummary(
        SummaryService.yearMonthOf(
            DateTime(monthLocal.year, monthLocal.month - 1)));
    final monthly = summaries.computeMonthly(
      yearMonth: ym,
      days: daily,
      previousClusterIds: prev?.clusterIds ?? const {},
      calculatedAt: DateTime.now(),
    );
    await repository.upsertMonthlySummaries([monthly]);
  }

  // --- インサイト ---

  Future<void> _rebuildInsights() async {
    final latest = await repository.latestActivityAt();
    if (latest == null) return;

    final window = computeComparisonWindow(latest.toLocal());

    final ctx = await _buildInsightContext(
      currentStart: window.currentStart,
      currentEnd: window.currentEnd,
      previousStart: window.previousStart,
      previousEnd: window.previousEnd,
      quality: freshness
          .evaluate(FreshnessInput(
            nowLocalDate: DateTime.now(),
            latestImportedAt: latest,
          ))
          .quality,
    );

    final selected = insights.selectForMonthStory(ctx);

    await repository.replaceInsightsForPeriod(
      window.periodKey,
      selected
          .map((i) => StoredInsight(
                id: 0,
                periodKey: window.periodKey,
                ruleId: i.ruleId,
                severity: i.severity.name,
                title: i.title,
                body: i.body,
                metricJson: _jsonEncode(i.metricJson),
                createdAt: DateTime.now(),
              ))
          .toList(),
    );
  }

  /// 月間ストーリー用: 選択月 vs 前月のインサイト（最大 8 件）。
  Future<List<InsightData>> insightsForMonth(String yearMonth) async {
    final parts = yearMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);
    final prevStart = DateTime(year, month - 1, 1);
    final prevEnd = monthStart;

    final latest = await repository.latestActivityAt();
    final quality = freshness
        .evaluate(FreshnessInput(
          nowLocalDate: DateTime.now(),
          latestImportedAt: latest,
        ))
        .quality;

    final ctx = await _buildInsightContext(
      currentStart: monthStart,
      currentEnd: monthEnd,
      previousStart: prevStart,
      previousEnd: prevEnd,
      quality: quality,
    );
    return insights.selectForMonthStory(ctx);
  }

  Future<InsightContext> _buildInsightContext({
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
    required DataQuality quality,
  }) async {
    final currentUtc = (currentStart.toUtc(), currentEnd.toUtc());
    final previousUtc = (previousStart.toUtc(), previousEnd.toUtc());

    final currentVisits =
        await repository.visitsInRange(currentUtc.$1, currentUtc.$2);
    final previousVisits =
        await repository.visitsInRange(previousUtc.$1, previousUtc.$2);
    final currentMovements =
        await repository.movementsInRange(currentUtc.$1, currentUtc.$2);
    final previousMovements =
        await repository.movementsInRange(previousUtc.$1, previousUtc.$2);

    final clusters = await repository.allClusters();
    final excludedIds = clusters.where((c) => c.excluded).map((c) => c.id).toSet();
    final labels = await repository.allLabels();
    final baseLabel = labels.where((l) => l.isBasePlace).firstOrNull;
    final baseCluster = baseLabel == null
        ? null
        : clusters.where((c) => c.labelId == baseLabel.id).firstOrNull;

    final currentDays = _toLocalDays(currentVisits, currentMovements, excludedIds);
    final previousDays =
        _toLocalDays(previousVisits, previousMovements, excludedIds);

    int sumDistance(List<StoredMovement> ms) => ms
        .where((m) => m.validDistance && m.distanceM != null)
        .fold(0, (a, m) => a + m.distanceM!);

    // クラスタ別訪問回数
    Map<int, int> clusterCounts(List<StoredVisit> vs) {
      final m = <int, int>{};
      for (final v in vs) {
        final id = v.clusterId;
        if (id == null || excludedIds.contains(id)) continue;
        m[id] = (m[id] ?? 0) + 1;
      }
      return m;
    }

    final currentCounts = clusterCounts(currentVisits);
    final previousCounts = clusterCounts(previousVisits);

    // 新規地点: 現期間に訪問があり、前期間に訪問がないクラスタ
    final newClusters =
        currentCounts.keys.where((id) => !previousCounts.containsKey(id)).length;

    // 平日の基準地点帰着時刻（中央値）
    int? medianReturn(List<StoredVisit> vs, {required bool weekdays}) {
      final perDay = <String, int>{};
      for (final v in vs) {
        final local = v.startAtUtc.toLocal();
        final isWeekday = local.weekday <= 5;
        if (isWeekday != weekdays) continue;
        if (baseCluster == null || v.clusterId != baseCluster.id) continue;
        final key = SummaryService.localDateOf(local);
        final minutes = local.hour * 60 + local.minute;
        final cur = perDay[key];
        if (cur == null || minutes > cur) perDay[key] = minutes;
      }
      if (perDay.length < 5) return null;
      final values = perDay.values.toList()..sort();
      return values[values.length ~/ 2];
    }

    // 休日の活動半径（基準地点からの中央距離）
    int? medianHolidayRadius(List<StoredVisit> vs, {required bool holidays}) {
      if (baseCluster == null) return null;
      final baseCoord = baseCluster.centroid;
      final dists = <int>[];
      for (final v in vs) {
        final local = v.startAtUtc.toLocal();
        final isHoliday = local.weekday == DateTime.saturday ||
            local.weekday == DateTime.sunday;
        if (isHoliday != holidays) continue;
        if (v.clusterId == baseCluster.id) continue;
        if (excludedIds.contains(v.clusterId)) continue;
        dists.add(distance.haversineMeters(v.latLng, baseCoord).round());
      }
      if (dists.length < 5) return null;
      dists.sort();
      return dists[dists.length ~/ 2];
    }

    final clusterNames = <int, String>{
      for (final c in clusters) c.id: c.displayName,
    };
    final clusterCentroids = <int, (int, int)>{
      for (final c in clusters) c.id: (c.centroidLatE7, c.centroidLngE7),
    };

    return InsightContext(
      quality: quality,
      currentDayCount: currentDays.length,
      previousDayCount: previousDays.length,
      currentOutingDays: currentDays.values.where((o) => o).length,
      previousOutingDays: previousDays.values.where((o) => o).length,
      currentDistanceM: sumDistance(currentMovements),
      previousDistanceM: sumDistance(previousMovements),
      newClusterCount: newClusters,
      currentClusterVisits: currentCounts,
      previousClusterVisits: previousCounts,
      baseClusterId: baseCluster?.id,
      baseCentroidLatE7: baseCluster?.centroidLatE7,
      baseCentroidLngE7: baseCluster?.centroidLngE7,
      clusterCentroids: clusterCentroids,
      clusterNames: clusterNames,
      currentWeekdayReturnMinutes: medianReturn(currentVisits, weekdays: true),
      previousWeekdayReturnMinutes:
          medianReturn(previousVisits, weekdays: true),
      currentHolidayRadiusM: medianHolidayRadius(currentVisits, holidays: true),
      previousHolidayRadiusM:
          medianHolidayRadius(previousVisits, holidays: true),
    );
  }

  /// ローカル日 → 外出フラグ のマップ。
  Map<String, bool> _toLocalDays(
    List<StoredVisit> visits,
    List<StoredMovement> movements,
    Set<int> excludedIds,
  ) {
    final days = <String, bool>{};
    for (final v in visits) {
      if (v.clusterId != null && excludedIds.contains(v.clusterId)) continue;
      final d = SummaryService.localDateOf(v.startAtUtc.toLocal());
      days[d] = true;
    }
    for (final m in movements) {
      if (!m.validDistance) continue;
      final d = SummaryService.localDateOf(m.startAtUtc.toLocal());
      days[d] = true;
    }
    return days;
  }

  String _jsonEncode(Map<String, Object?> m) {
    final buf = StringBuffer('{');
    var first = true;
    m.forEach((k, v) {
      if (!first) buf.write(',');
      first = false;
      buf.write('"$k":');
      if (v is String) {
        buf.write('"${v.replaceAll('"', r'\"')}"');
      } else {
        buf.write(v.toString());
      }
    });
    buf.write('}');
    return buf.toString();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
