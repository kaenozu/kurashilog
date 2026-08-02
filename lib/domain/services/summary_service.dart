import '../models/summaries.dart';

/// 日次・月次集計（設計書 6.3 日次・月次集計）。
///
/// 純粋関数として実装し、DB から読み出した行を入力として与える。
class SummaryService {
  const SummaryService();

  /// 1 日分の日次サマリーを計算する。
  ///
  /// [visits] / [movements] は対象ローカル日の範囲に含まれるものだけを渡す。
  DailySummaryData computeDaily({
    required String localDate,
    required List<DailyVisitInput> visits,
    required List<DailyMovementInput> movements,
    bool hasBasePlace = false,
  }) {
    final includedVisits = visits.where((v) => !v.excluded).toList();
    final clusterIds = <int>{};
    for (final v in includedVisits) {
      if (v.clusterId != null) clusterIds.add(v.clusterId!);
    }

    // 外出判定（設計書 7.2 指標「外出日数」）。
    // 基準地点未設定時は「記録のある日数」、設定時は基準地点外の訪問・移動が存在する日数。
    final outing = hasBasePlace
        ? includedVisits.any((v) => v.outsideBasePlace) ||
              movements.any((m) => m.isValidDistance)
        : includedVisits.isNotEmpty || movements.any((m) => m.isValidDistance);

    var distance = 0;
    for (final m in movements) {
      if (m.isValidDistance) distance += m.distanceM;
    }

    DateTime? firstAt;
    DateTime? lastAt;
    void mergeRange(DateTime s, DateTime e) {
      firstAt ??= s;
      lastAt ??= e;
      if (s.isBefore(firstAt!)) firstAt = s;
      if (e.isAfter(lastAt!)) lastAt = e;
    }

    for (final v in includedVisits) {
      mergeRange(v.startAtUtc, v.endAtUtc);
    }
    for (final m in movements) {
      mergeRange(m.startAtUtc, m.endAtUtc);
    }

    return DailySummaryData(
      localDate: localDate,
      outingFlag: outing,
      visitCount: includedVisits.length,
      clusterCount: clusterIds.length,
      distanceM: distance,
      firstAt: firstAt,
      lastAt: lastAt,
      clusterIds: clusterIds,
    );
  }

  /// 月次サマリーを計算する。
  ///
  /// [previousClusterIds] は比較期間（前月）に訪問のあったクラスタ集合。
  /// これに含まれず今月に現れたクラスタを「新規地点」とする。
  MonthlySummaryData computeMonthly({
    required String yearMonth,
    required List<DailySummaryData> days,
    required Set<int> previousClusterIds,
    required DateTime calculatedAt,
  }) {
    if (days.isEmpty) return MonthlySummaryData.empty(yearMonth);

    var outingDays = 0;
    var distanceM = 0;
    final clusterIds = <int>{};
    String? maxDistanceDate;
    var maxDistance = -1;

    for (final d in days) {
      if (d.outingFlag) outingDays++;
      distanceM += d.distanceM;
      clusterIds.addAll(d.clusterIds);
      if (d.distanceM > maxDistance) {
        maxDistance = d.distanceM;
        maxDistanceDate = d.localDate;
      }
    }

    final newClusters = clusterIds
        .where((id) => !previousClusterIds.contains(id))
        .toSet();

    return MonthlySummaryData(
      yearMonth: yearMonth,
      outingDays: outingDays,
      distanceM: distanceM,
      uniqueClusters: clusterIds.length,
      newClusters: newClusters.length,
      maxDistanceDate: maxDistanceDate,
      calculatedAt: calculatedAt,
      clusterIds: clusterIds,
    );
  }

  /// ローカル日付文字列（YYYY-MM-DD）。
  static String localDateOf(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';

  /// 年月文字列（YYYY-MM）。
  static String yearMonthOf(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}';
}
