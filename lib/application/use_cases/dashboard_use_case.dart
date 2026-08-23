import 'dart:convert';

import '../../domain/models/data_quality.dart';
import '../../domain/models/insight.dart';
import '../../domain/models/summaries.dart';
import '../../domain/services/freshness_service.dart';
import '../../domain/services/summary_service.dart';
import '../analysis/analysis_coordinator.dart';
import '../display_preferences.dart';
import '../analysis/window.dart';
import '../repositories/kurashilog_repository.dart';
import 'settings_use_case.dart';

/// ホーム表示データ（設計書 7.4 DashboardViewModel）。
class DashboardData {
  const DashboardData({
    required this.hasData,
    required this.freshness,
    required this.selectedMonth,
    required this.metrics,
    required this.insights,
    required this.heatmap,
    required this.monthly,
    required this.previousMonthly,
  });

  final bool hasData;
  final FreshnessResult freshness;
  final String selectedMonth; // YYYY-MM
  final List<MetricCardData> metrics;
  final List<InsightData> insights;
  final Map<String, int> heatmap; // localDate → 外出フラグ or 移動量レベル
  final MonthlySummaryData? monthly;
  final MonthlySummaryData? previousMonthly;

  String get monthLabel => _formatMonth(selectedMonth);

  static String _formatMonth(String ym) {
    final parts = ym.split('-');
    return '${int.parse(parts[0])}年${int.parse(parts[1])}月';
  }
}

/// 月間ストーリー表示データ（設計書 SC-05）。
class MonthStoryData {
  const MonthStoryData({
    required this.yearMonth,
    required this.monthly,
    required this.previousMonthly,
    required this.insights,
    required this.newClusterNames,
  });

  final String yearMonth;
  final MonthlySummaryData? monthly;
  final MonthlySummaryData? previousMonthly;
  final List<InsightData> insights;
  final List<String> newClusterNames;
}

/// 日別詳細の 1 行。
class DayTimelineEntry {
  const DayTimelineEntry({
    required this.kind,
    required this.startsAt,
    required this.endsAt,
    this.placeName,
    this.dwellMinutes,
    this.distanceM,
    this.distanceLabel,
    this.activityType,
    this.latLng,
  });

  final String kind; // visit | movement
  final DateTime startsAt;
  final DateTime endsAt;
  final String? placeName;
  final int? dwellMinutes;
  final int? distanceM;
  final String? distanceLabel;
  final String? activityType;
  final (int, int)? latLng; // E7
}

class DayDetailData {
  const DayDetailData({
    required this.localDate,
    required this.entries,
    required this.totalDistanceM,
    required this.outing,
  });

  final String localDate;
  final List<DayTimelineEntry> entries;
  final int totalDistanceM;
  final bool outing;
}

/// ホーム・カレンダー・月間・日別の表示用ユースケース。
class DashboardUseCase {
  const DashboardUseCase({
    required this.repository,
    required this.analysis,
    required this.settings,
    this.freshness = const FreshnessService(),
    this.summaries = const SummaryService(),
  });

  final KurashilogRepository repository;
  final AnalysisCoordinator analysis;
  final SettingsUseCase settings;
  final FreshnessService freshness;
  final SummaryService summaries;

  /// ホームの表示データを組み立てる。
  Future<DashboardData> loadHome({String? selectedMonth}) async {
    final import = await repository.latestCompletedImport();
    final hasData = import != null && import.isCompleted;

    final latestActivity = await repository.latestActivityAt();
    final freshnessResult = freshness.evaluate(
      FreshnessInput(
        nowLocalDate: DateTime.now(),
        latestImportedAt: latestActivity,
      ),
    );

    if (!hasData || latestActivity == null) {
      return DashboardData(
        hasData: false,
        freshness: freshnessResult,
        selectedMonth:
            selectedMonth ?? SummaryService.yearMonthOf(DateTime.now()),
        metrics: const [],
        insights: const [],
        heatmap: const {},
        monthly: null,
        previousMonthly: null,
      );
    }

    final now = DateTime.now();
    final month = selectedMonth ?? SummaryService.yearMonthOf(now);
    final parts = month.split('-');
    final mYear = int.parse(parts[0]);
    final mMonth = int.parse(parts[1]);
    final prevMonth = SummaryService.yearMonthOf(
      DateTime(mYear, mMonth - 1, 1),
    );

    final monthly = await repository.monthlySummary(month);
    final previous = await repository.monthlySummary(prevMonth);

    final window = computeComparisonWindow(latestActivity.toLocal());
    final storedInsights = await repository.insightsForPeriod(window.periodKey);
    final insightData = storedInsights.where((i) => !i.dismissed).map((i) {
      final decoded = jsonDecode(i.metricJson);
      final metricJson = decoded is Map
          ? Map<String, Object?>.from(decoded)
          : const <String, Object?>{};
      final evidence =
          (metricJson['evidence'] is List
                  ? metricJson['evidence'] as List
                  : const <Object?>[])
              .whereType<Map>()
              .map(
                (item) => InsightEvidence(
                  type: item['type'] as String? ?? 'unknown',
                  reference: item['reference'] as String? ?? 'unknown',
                  level: InsightEvidenceLevel.values.firstWhere(
                    (level) => level.name == item['level'],
                    orElse: () => InsightEvidenceLevel.fact,
                  ),
                ),
              )
              .toList(growable: false);
      return InsightData(
        ruleId: i.ruleId,
        severity: i.severity == 'attention'
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: i.title,
        body: i.body,
        score: 0,
        kind: InsightKind.values.firstWhere(
          (kind) => kind.name == metricJson['kind'],
          orElse: () => InsightKind.changedMetric,
        ),
        evidence: evidence,
        metricJson: metricJson,
      );
    }).toList();

    // カレンダー用ヒートマップ（当月の外出有無）
    final daysInMonth = DateTime(mYear, mMonth + 1, 0).day;
    final startDate = '$month-01';
    final endDate = '$month-${daysInMonth.toString().padLeft(2, '0')}';
    final daily = await repository.dailySummariesBetween(startDate, endDate);
    final heatmap = <String, int>{
      for (final d in daily) d.localDate: d.outingFlag ? 1 : 0,
    };

    final displaySettings = await settings.load();
    final metrics = _buildHomeMetrics(
      monthly,
      previous,
      displaySettings.distanceUnit,
    );

    return DashboardData(
      hasData: true,
      freshness: freshnessResult,
      selectedMonth: month,
      metrics: metrics,
      insights: insightData.take(5).toList(),
      heatmap: heatmap,
      monthly: monthly,
      previousMonthly: previous,
    );
  }

  List<MetricCardData> _buildHomeMetrics(
    MonthlySummaryData? current,
    MonthlySummaryData? previous,
    DistanceUnit distanceUnit,
  ) {
    if (current == null) return const [];

    final prevOuting = previous?.outingDays ?? 0;
    final prevDistance = previous?.distanceM ?? 0;
    final prevPlaces = previous?.uniqueClusters ?? 0;

    return [
      MetricCardData(
        label: '外出日数',
        value: '${current.outingDays}日',
        icon: MetricIcon.walking,
        deltaLabel: prevOuting > 0
            ? _deltaLabel(current.outingDays - prevOuting, '前月比')
            : null,
      ),
      MetricCardData(
        label: '推定移動距離',
        value: formatDistance(current.distanceM, distanceUnit),
        icon: MetricIcon.route,
        deltaLabel: prevDistance > 0
            ? _deltaLabel(
                ((current.distanceM - prevDistance) / prevDistance * 100)
                    .round(),
                '前月比',
                percent: true,
              )
            : null,
        note: '推定を含みます',
      ),
      MetricCardData(
        label: '訪問地点数',
        value: '${current.uniqueClusters}か所',
        icon: MetricIcon.place,
        deltaLabel: prevPlaces > 0
            ? _deltaLabel(current.uniqueClusters - prevPlaces, '前月比')
            : null,
      ),
      MetricCardData(
        label: '新規地点',
        value: '${current.newClusters}か所',
        icon: MetricIcon.explore,
        note: '前月に訪れなかった場所',
      ),
    ];
  }

  /// 月間ストーリー。
  Future<MonthStoryData> monthStory(String yearMonth) async {
    final parts = yearMonth.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final prevMonth = SummaryService.yearMonthOf(DateTime(y, m - 1, 1));

    final monthly = await repository.monthlySummary(yearMonth);
    final previous = await repository.monthlySummary(prevMonth);
    final insights = await analysis.insightsForMonth(yearMonth);

    final clusters = await repository.allClusters();
    final newClusterNames = <String>[];
    if (monthly != null) {
      final prevIds = previous?.clusterIds ?? const <int>{};
      for (final id in monthly.clusterIds) {
        if (prevIds.contains(id)) continue;
        final c = clusters.where((c) => c.id == id).firstOrNull;
        if (c != null && !c.excluded) newClusterNames.add(c.displayName);
      }
    }

    return MonthStoryData(
      yearMonth: yearMonth,
      monthly: monthly,
      previousMonthly: previous,
      insights: insights,
      newClusterNames: newClusterNames,
    );
  }

  /// 日別詳細。
  Future<DayDetailData> dayDetail(String localDate) async {
    final parts = localDate.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);

    final startLocal = DateTime(y, m, d);
    final endLocal = DateTime(y, m, d + 1);
    final startUtc = startLocal.toUtc();
    final endUtc = endLocal.toUtc();

    final visits = await repository.visitsInRange(startUtc, endUtc);
    final movements = await repository.movementsInRange(startUtc, endUtc);
    final clusters = await repository.allClusters();
    final nameById = {for (final c in clusters) c.id: c.displayName};

    final entries = <DayTimelineEntry>[];
    var totalDistance = 0;

    for (final v in visits) {
      final local = v.startAtUtc.toLocal();
      if (local.year != y || local.month != m || local.day != d) continue;
      final dwell = v.endAtUtc.difference(v.startAtUtc).inMinutes;
      entries.add(
        DayTimelineEntry(
          kind: 'visit',
          startsAt: v.startAtUtc.toLocal(),
          endsAt: v.endAtUtc.toLocal(),
          placeName: v.clusterId != null ? nameById[v.clusterId] : null,
          dwellMinutes: dwell,
          latLng: (v.latE7, v.lngE7),
        ),
      );
    }
    for (final mv in movements) {
      final local = mv.startAtUtc.toLocal();
      if (local.year != y || local.month != m || local.day != d) continue;
      if (mv.validDistance && mv.distanceM != null) {
        totalDistance += mv.distanceM!;
      }
      entries.add(
        DayTimelineEntry(
          kind: 'movement',
          startsAt: mv.startAtUtc.toLocal(),
          endsAt: mv.endAtUtc.toLocal(),
          distanceM: mv.distanceM,
          distanceLabel: mv.distanceMethod.displayLabel,
          activityType: mv.activityType,
        ),
      );
    }

    entries.sort((a, b) => a.startsAt.compareTo(b.startsAt));

    final daily = await repository.dailySummariesBetween(localDate, localDate);

    return DayDetailData(
      localDate: localDate,
      entries: entries,
      totalDistanceM: totalDistance,
      outing: daily.isNotEmpty && daily.first.outingFlag,
    );
  }

  String _deltaLabel(int delta, String prefix, {bool percent = false}) {
    if (delta == 0) return '$prefix ±0';
    final sign = delta > 0 ? '+' : '';
    return '$prefix $sign$delta${percent ? '%' : ''}';
  }
}
