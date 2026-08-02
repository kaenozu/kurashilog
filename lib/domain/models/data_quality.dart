/// データ鮮度・分析品質（設計書 7.3 鮮度と品質）。
enum DataQuality {
  high('高', '最新のデータです'),
  medium('中', '最新の記録が一部未反映です'),
  low('低', 'データの更新をおすすめします'),
  quiteLow('かなり低い', '現在の傾向の精度が低下しています'),
  historyOnly('履歴のみ', '現在の傾向ではなく過去の記録として表示しています');

  const DataQuality(this.label, this.description);

  final String label;
  final String description;

  int get dbValue => index;

  static DataQuality fromDb(int value) {
    final safeIndex = value.clamp(0, DataQuality.values.length - 1).toInt();
    return DataQuality.values[safeIndex];
  }

  /// 欠落率が高い場合に指定段階だけ品質を下げる。
  DataQuality downgrade([int steps = 1]) {
    final safeIndex =
        (index + steps).clamp(0, DataQuality.values.length - 1).toInt();
    return DataQuality.values[safeIndex];
  }
}

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
