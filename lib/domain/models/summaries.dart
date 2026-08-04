/// 日次・月次集計のドメイン値（設計書 6.3 / 10.1 キャッシュ戦略）。
library;

/// 日次集計の入力（訪問）。
class DailyVisitInput {
  const DailyVisitInput({
    required this.startAtUtc,
    required this.endAtUtc,
    this.clusterId,
    this.excluded = false,
    this.outsideBasePlace = false,
  });

  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final int? clusterId;

  /// ユーザーが分析除外したクラスタ由来か。
  final bool excluded;

  /// 基準地点外の訪問か（基準地点未設定時は false）。
  final bool outsideBasePlace;
}

/// 日次集計の入力（移動）。
class DailyMovementInput {
  const DailyMovementInput({
    required this.startAtUtc,
    required this.endAtUtc,
    required this.distanceM,
    required this.isValidDistance,
  });

  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final int distanceM;

  /// 異常速度などで日常移動集計から除外するか（設計書 6.2）。
  final bool isValidDistance;
}

/// 日次集計結果。
class DailySummaryData {
  const DailySummaryData({
    required this.localDate,
    required this.outingFlag,
    required this.visitCount,
    required this.clusterCount,
    required this.distanceM,
    required this.firstAt,
    required this.lastAt,
    this.clusterIds = const {},
  });

  final String localDate; // YYYY-MM-DD
  final bool outingFlag;
  final int visitCount;
  final int clusterCount;
  final int distanceM;
  final DateTime? firstAt;
  final DateTime? lastAt;

  /// 当該日の訪問クラスタ集合（月次・新規地点算出用）。
  final Set<int> clusterIds;
}

/// 月次集計結果。
class MonthlySummaryData {
  const MonthlySummaryData({
    required this.yearMonth, // YYYY-MM
    required this.outingDays,
    required this.distanceM,
    required this.uniqueClusters,
    required this.newClusters,
    required this.maxDistanceDate,
    required this.calculatedAt,
    required this.clusterIds,
  });

  final String yearMonth;
  final int outingDays;
  final int distanceM;
  final int uniqueClusters;
  final int newClusters;
  final String? maxDistanceDate;
  final DateTime calculatedAt;
  final Set<int> clusterIds;

  /// 集計対象の月が 1 日も無い場合の空サマリー。
  factory MonthlySummaryData.empty(String yearMonth) => MonthlySummaryData(
    yearMonth: yearMonth,
    outingDays: 0,
    distanceM: 0,
    uniqueClusters: 0,
    newClusters: 0,
    maxDistanceDate: null,
    calculatedAt: DateTime.now(),
    clusterIds: const {},
  );
}

/// メトリクスカードのアイコン種別（ドメインは Flutter に依存しない）。
enum MetricIcon { walking, route, place, explore }

/// ホーム等で使う月間メトリクスの表示モデル。
class MetricCardData {
  const MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    this.deltaLabel,
    this.note,
  });

  final String label;
  final String value;
  final MetricIcon icon;
  final String? deltaLabel; // 前月比など
  final String? note; // 「推定」「一部データ不足」等
}
