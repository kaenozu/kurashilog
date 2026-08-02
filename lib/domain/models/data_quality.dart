/// データ鮮度・分析品質（設計書 7.3 鮮度と品質）。
///
/// UI 表示と将来の閾値変更を分離するため enum 整数で持つ。
enum DataQuality {
  /// 欠落日数 0〜7 日。通常表示。
  high('高', '最新のデータです'),

  /// 欠落日数 8〜14 日。最新データ未反映の補足を小さく表示。
  medium('中', '最新の記録が一部未反映です'),

  /// 欠落日数 15〜30 日。更新を推奨。
  low('低', 'データの更新をおすすめします'),

  /// 欠落日数 31〜60 日。現在傾向の精度低下を明示。
  quiteLow('かなり低い', '現在の傾向の精度が低下しています'),

  /// 欠落日数 61 日以上。過去記録として表示。
  historyOnly('履歴のみ', '現在の傾向ではなく過去の記録として表示しています');

  const DataQuality(this.label, this.description);

  final String label;
  final String description;

  int get dbValue => index;

  static DataQuality fromDb(int value) =>
      DataQuality.values[value.clamp(0, DataQuality.values.length - 1)];

  /// 欠落率 20% 以上の場合に 1 段階下げる（設計書 7.3 追加条件）。
  DataQuality downgrade([int steps = 1]) {
    final idx = (index + steps).clamp(0, DataQuality.values.length - 1);
    return DataQuality.values[idx];
  }
}

/// 鮮度判定の入力と結果（設計書 7.3 / 6.5 鮮度アルゴリズム）。
class FreshnessInput {
  const FreshnessInput({
    required this.nowLocalDate,
    required this.latestImportedAt,
    this.analysisWindowDays = 30,
  });

  final DateTime nowLocalDate;
  final DateTime? latestImportedAt;
  final int analysisWindowDays;
}

class FreshnessResult {
  const FreshnessResult({
    required this.staleDays,
    required this.missingRatio,
    required this.quality,
    required this.latestImportedAt,
  });

  final int staleDays;
  final double missingRatio;
  final DataQuality quality;
  final DateTime? latestImportedAt;

  bool get hasData => latestImportedAt != null;
}
