/// インサイト（気づき）のドメイン値（設計書 6.4 インサイト選定）。
library;

import 'data_quality.dart';

enum InsightSeverity {
  information('情報'),
  attention('注目');

  const InsightSeverity(this.label);
  final String label;
}

/// 1 件のインサイト表示データ。
class InsightData {
  const InsightData({
    required this.ruleId,
    required this.severity,
    required this.title,
    required this.body,
    required this.score,
    this.metricJson = const {},
  });

  final String ruleId;
  final InsightSeverity severity;
  final String title;
  final String body;

  /// 同じ意味のルールをグループ化し、高い 1 件だけ表示するためのスコア。
  final int score;

  /// 永続化用（periodKey ごとの重複防止・再表示）。
  final Map<String, Object?> metricJson;
}

/// インサイト生成時のコンテキスト（集計済みの値のみを渡す）。
class InsightContext {
  const InsightContext({
    required this.quality,
    required this.currentDayCount,
    required this.previousDayCount,
    required this.currentOutingDays,
    required this.previousOutingDays,
    required this.currentDistanceM,
    required this.previousDistanceM,
    required this.newClusterCount,
    required this.currentClusterVisits,
    required this.previousClusterVisits,
    required this.baseClusterId,
    required this.baseCentroidLatE7,
    required this.baseCentroidLngE7,
    required this.clusterCentroids,
    required this.clusterNames,
    required this.currentWeekdayReturnMinutes,
    required this.previousWeekdayReturnMinutes,
    required this.currentHolidayRadiusM,
    required this.previousHolidayRadiusM,
  });

  final DataQuality quality;

  final int currentDayCount;
  final int previousDayCount;
  final int currentOutingDays;
  final int previousOutingDays;
  final int currentDistanceM;
  final int previousDistanceM;
  final int newClusterCount;

  /// clusterId → 訪問回数（現期間 / 比較期間）。
  final Map<int, int> currentClusterVisits;
  final Map<int, int> previousClusterVisits;

  /// 基準地点（ユーザー確認済み）の clusterId。未設定は null。
  final int? baseClusterId;
  final int? baseCentroidLatE7;
  final int? baseCentroidLngE7;

  /// clusterId → 重心座標。
  final Map<int, (int, int)> clusterCentroids;

  /// clusterId → 表示名（ユーザーラベルまたは地点名）。
  final Map<int, String> clusterNames;

  /// 平日の基準地点帰着時刻の中央値（分）。サンプル不足は null。
  final int? currentWeekdayReturnMinutes;
  final int? previousWeekdayReturnMinutes;

  /// 休日の活動半径（基準地点からの中央距離・m）。
  final int? currentHolidayRadiusM;
  final int? previousHolidayRadiusM;
}
