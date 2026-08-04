import 'dart:math' as math;

import '../models/lat_lng.dart';

/// 距離計算（設計書 6.2 距離算出）。
///
/// MVP は Haversine 式を採用。経路点列がある場合は隣接点の距離を合算する。
class DistanceService {
  const DistanceService();

  static const double earthRadiusM = 6371000.0;

  /// 2 地点間の Haversine 距離（メートル）。
  double haversineMeters(LatLngE7 a, LatLngE7 b) {
    final lat1 = a.lat * math.pi / 180;
    final lat2 = b.lat * math.pi / 180;
    final dLat = (b.lat - a.lat) * math.pi / 180;
    final dLng = (b.lng - a.lng) * math.pi / 180;

    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusM * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  /// 経路点列の合算距離（メートル）。点が 2 未満なら 0。
  double pathMeters(List<LatLngE7> path) {
    var total = 0.0;
    for (var i = 1; i < path.length; i++) {
      total += haversineMeters(path[i - 1], path[i]);
    }
    return total;
  }

  /// 移動の平均速度（m/s）。duration が 0 以下なら null。
  double? speedMps({
    required int distanceM,
    required DateTime start,
    required DateTime end,
  }) {
    final durationSec = end.difference(start).inSeconds;
    if (durationSec <= 0) return null;
    return distanceM / durationSec;
  }

  /// 日常移動集計から除外すべき「異常速度」か（設計書 6.2）。
  ///
  /// 閾値は実装定数としてここに 1 箇所で定義し、テストで調整する。
  /// 飛行機移動を誤って除外しないよう、距離自体は消さず
  /// 「日常移動集計から除外」フラグとして扱う。
  static const double absurdSpeedMps = 70.0; // 約 252 km/h 超

  bool isAbsurdSpeed({
    required int distanceM,
    required DateTime start,
    required DateTime end,
  }) {
    final speed = speedMps(distanceM: distanceM, start: start, end: end);
    if (speed == null) return false;
    return speed > absurdSpeedMps;
  }
}
