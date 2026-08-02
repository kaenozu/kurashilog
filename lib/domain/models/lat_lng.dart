/// 緯度経度を E7（10^7 倍の整数）で保持する値オブジェクト。
///
/// 設計書 4.2「値の保存形式」に従い、浮動小数点の比較差を避けるため
/// 整数で保持する。
class LatLngE7 {
  const LatLngE7(this.latE7, this.lngE7);

  final int latE7;
  final int lngE7;

  double get lat => latE7 / 1e7;
  double get lng => lngE7 / 1e7;

  bool get isValid =>
      latE7 >= -900000000 &&
      latE7 <= 900000000 &&
      lngE7 >= -1800000000 &&
      lngE7 <= 1800000000;

  /// sourceKey 生成用に約 1m 精度（緯度経度 5 桁）へ丸める。
  ///
  /// E7 の下 2 桁を落とす（= 0.00001 度単位へ丸め）。
  LatLngE7 roundForKey() => LatLngE7(latE7 ~/ 100, lngE7 ~/ 100);

  @override
  bool operator ==(Object other) =>
      other is LatLngE7 && other.latE7 == latE7 && other.lngE7 == lngE7;

  @override
  int get hashCode => Object.hash(latE7, lngE7);

  @override
  String toString() => 'LatLngE7($latE7, $lngE7)';
}
