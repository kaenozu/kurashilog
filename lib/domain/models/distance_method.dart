/// 移動距離の算出方法（設計書 6.2 距離算出・優先度表）。
enum DistanceMethod {
  /// ソースに区間距離があり、値が妥当なら使用。
  recorded,

  /// 経路点列がある場合、隣接点の Haversine 距離を合算。
  estimatedPath,

  /// 開始・終了座標の Haversine 直線距離。
  estimatedDirect,

  /// 座標不足または異常値。
  unknown;

  String get dbValue => name;

  static DistanceMethod fromDb(String value) =>
      DistanceMethod.values.firstWhere((m) => m.name == value,
          orElse: () => DistanceMethod.unknown);

  String get displayLabel => switch (this) {
        DistanceMethod.recorded => '記録値',
        DistanceMethod.estimatedPath => '推定（経路）',
        DistanceMethod.estimatedDirect => '推定（直線）',
        DistanceMethod.unknown => '不明',
      };
}
