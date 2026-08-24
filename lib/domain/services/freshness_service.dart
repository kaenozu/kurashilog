import '../models/data_quality.dart';

/// 鮮度判定（設計書 7.3 鮮度と品質 / 6.5 鮮度アルゴリズム）。
///
/// ```
/// staleDays = today - latestImportedTimestamp
/// missingRatio = missingDays / analysisWindowDays
/// quality = freshnessTable(staleDays)
/// if missingRatio >= 0.20: quality = downgrade(quality, 1)
/// ```
class FreshnessService {
  const FreshnessService();

  static const int analysisWindowDays = 30;
  static const double missingRatioThreshold = 0.20;

  /// 欠落日数 → 基本品質テーブル（設計書 7.3）。
  DataQuality rankByStaleDays(int staleDays) {
    if (staleDays <= 7) return DataQuality.high;
    if (staleDays <= 14) return DataQuality.medium;
    if (staleDays <= 30) return DataQuality.low;
    if (staleDays <= 60) return DataQuality.quiteLow;
    return DataQuality.historyOnly;
  }

  FreshnessResult evaluate(FreshnessInput input) {
    final latest = input.latestImportedAt;
    if (latest == null) {
      return FreshnessResult(
        staleDays: 0,
        missingRatio: 0,
        quality: DataQuality.historyOnly,
        latestImportedAt: null,
      );
    }

    final latestLocalDate = latest.toLocal();
    final today = input.nowLocalDate;

    final staleDays = _daysBetween(latestLocalDate, today);
    final missingRatio =
        staleDays.clamp(0, input.analysisWindowDays) / input.analysisWindowDays;

    var quality = rankByStaleDays(staleDays);
    if (missingRatio >= missingRatioThreshold) {
      quality = quality.downgrade(1);
    }

    return FreshnessResult(
      staleDays: staleDays,
      missingRatio: missingRatio,
      quality: quality,
      latestImportedAt: latest,
    );
  }

  /// 日付差（ローカル日ベース）。
  ///
  /// DST 遷移で 1 日が 23/25 時間になるのを避けるため、暦日を UTC 換算して
  /// 差分を取る。
  int _daysBetween(DateTime a, DateTime b) {
    final da = DateTime.utc(a.year, a.month, a.day);
    final db = DateTime.utc(b.year, b.month, b.day);
    return db.difference(da).inDays;
  }
}
