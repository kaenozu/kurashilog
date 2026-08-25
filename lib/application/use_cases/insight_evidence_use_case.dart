import '../../domain/models/insight.dart';
import '../../domain/services/summary_service.dart';
import '../analysis/analysis_coordinator.dart';
import '../models/persistence_models.dart';
import '../repositories/kurashilog_repository.dart';

class InsightEvidenceData {
  const InsightEvidenceData({
    required this.description,
    required this.localDates,
  });

  final String description;
  final List<String> localDates;
}

/// Resolves privacy-safe insight references into concrete recorded days.
///
/// The insight engine stores stable references (for example `cluster:12` or
/// `travel-distance`) rather than raw coordinates. This use case turns those
/// references back into dates that can be opened with the existing day-detail
/// screen, preserving source traceability without serializing private payloads.
class InsightEvidenceUseCase {
  const InsightEvidenceUseCase({required this.repository});

  final KurashilogRepository repository;

  Future<InsightEvidenceData> load({
    required String yearMonth,
    required InsightData insight,
  }) async {
    final range = _monthRange(yearMonth);
    final visits = await repository.visitsInRange(range.$1, range.$2);
    final movements = await repository.movementsInRange(range.$1, range.$2);
    final clusters = await repository.allClusters();
    final labels = await repository.allLabels();
    final effectiveIds = AnalysisCoordinator.effectivePlaceIds(clusters);
    final excludedIds = clusters
        .where((cluster) => cluster.excludedFromAnalysis)
        .map((cluster) => cluster.id)
        .toSet();

    final references = insight.evidence.isEmpty
        ? const <InsightEvidence>[]
        : insight.evidence;
    final dates = <String>{};
    var description = 'この気づきの計算対象になった記録日です。';

    for (final evidence in references) {
      if (evidence.type == 'cluster' &&
          evidence.reference.startsWith('cluster:')) {
        final targetId = int.tryParse(evidence.reference.substring(8));
        if (targetId == null) continue;
        final memberIds = clusters
            .where(
              (cluster) =>
                  !cluster.excludedFromAnalysis &&
                  effectiveIds[cluster.id] == targetId,
            )
            .map((cluster) => cluster.id)
            .toSet();
        for (final visit in visits) {
          final clusterId = visit.clusterId;
          if (clusterId != null && memberIds.contains(clusterId)) {
            dates.add(_localDate(visit.startAtUtc));
          }
        }
        description = 'この気づきに使われた地点への訪問日です。';
        continue;
      }

      if (evidence.type == 'analysis-window') {
        dates.addAll(await _recordedSummaryDates(yearMonth));
        description = 'この集計期間に記録があった日です。';
        continue;
      }

      if (evidence.type != 'metric') continue;
      switch (evidence.reference) {
        case 'outing-days':
          final daily = await _dailySummaries(yearMonth);
          dates.addAll(
            daily.where((row) => row.outingFlag).map((row) => row.localDate),
          );
          description = '外出ありと判定された記録日です。';
        case 'travel-distance':
          for (final movement in movements) {
            if (movement.validDistance && movement.distanceM != null) {
              dates.add(_localDate(movement.startAtUtc));
            }
          }
          description = '移動距離の集計に使われた記録日です。';
        case 'new-cluster-count':
          final current = await repository.monthlySummary(yearMonth);
          final previous = await repository.monthlySummary(
            _previousYearMonth(yearMonth),
          );
          final previousIds = previous?.clusterIds ?? const <int>{};
          final newIds = (current?.clusterIds ?? const <int>{})
              .where((id) => !previousIds.contains(id))
              .toSet();
          for (final visit in visits) {
            final clusterId = visit.clusterId;
            if (clusterId == null || excludedIds.contains(clusterId)) continue;
            final effectiveId = effectiveIds[clusterId] ?? clusterId;
            if (newIds.contains(effectiveId)) {
              dates.add(_localDate(visit.startAtUtc));
            }
          }
          description = '新しい地点として集計された訪問日です。';
        case 'weekday-return-time':
          final baseLabelId = labels
              .where((label) => label.isBasePlace)
              .map((label) => label.id)
              .firstOrNull;
          if (baseLabelId != null) {
            final baseIds = clusters
                .where(
                  (cluster) =>
                      cluster.labelId == baseLabelId &&
                      !cluster.excludedFromAnalysis,
                )
                .map((cluster) => cluster.id)
                .toSet();
            for (final visit in visits) {
              final local = visit.startAtUtc.toLocal();
              if (local.weekday <= DateTime.friday &&
                  visit.clusterId != null &&
                  baseIds.contains(visit.clusterId)) {
                dates.add(_localDate(visit.startAtUtc));
              }
            }
          }
          description = '平日の基準地点への帰着時刻に使われた記録日です。';
        case 'holiday-radius':
          for (final visit in visits) {
            final local = visit.startAtUtc.toLocal();
            final clusterId = visit.clusterId;
            if (local.weekday >= DateTime.saturday &&
                clusterId != null &&
                !excludedIds.contains(clusterId)) {
              dates.add(_localDate(visit.startAtUtc));
            }
          }
          description = '休日の活動半径に使われた記録日です。';
        default:
          // Unknown metrics stay traceable at the month level rather than
          // inventing a narrower relationship that the domain did not record.
          dates.addAll(await _recordedSummaryDates(yearMonth));
      }
    }

    if (references.isEmpty) {
      dates.addAll(await _recordedSummaryDates(yearMonth));
    }

    final sorted = dates.toList()..sort();
    return InsightEvidenceData(
      description: description,
      localDates: List.unmodifiable(sorted),
    );
  }

  Future<List<DailySummaryRecord>> _dailySummaries(String yearMonth) {
    final parts = yearMonth.split('-');
    final days = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 0).day;
    return repository.dailySummariesBetween(
      '$yearMonth-01',
      '$yearMonth-${days.toString().padLeft(2, '0')}',
    );
  }

  Future<Iterable<String>> _recordedSummaryDates(String yearMonth) async =>
      (await _dailySummaries(yearMonth)).map((row) => row.localDate);

  (DateTime, DateTime) _monthRange(String yearMonth) {
    final parts = yearMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return (DateTime(year, month, 1).toUtc(), DateTime(year, month + 1, 1).toUtc());
  }

  String _previousYearMonth(String yearMonth) {
    final parts = yearMonth.split('-');
    return SummaryService.yearMonthOf(
      DateTime(int.parse(parts[0]), int.parse(parts[1]) - 1, 1),
    );
  }

  String _localDate(DateTime utc) => SummaryService.localDateOf(utc.toLocal());
}
