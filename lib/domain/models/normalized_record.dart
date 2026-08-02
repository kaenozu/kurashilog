import 'distance_method.dart';
import 'lat_lng.dart';

/// パーサーが返す正規化レコードの基底型（設計書 5.2）。
///
/// 画面・DB モデルを直接生成せず、この DTO を介して共通化する。
sealed class NormalizedRecord {
  const NormalizedRecord({
    required this.sourceKey,
    required this.startAtUtc,
    required this.endAtUtc,
  });

  final String sourceKey;
  final DateTime startAtUtc;
  final DateTime endAtUtc;

  /// 解析時点の警告件数（1 レコード分）。
  final int warningCount = 0;

  bool get hasValidRange => !endAtUtc.isBefore(startAtUtc);
}

/// 訪問区間（設計書 4.1 visits）。
class NormalizedVisit extends NormalizedRecord {
  const NormalizedVisit({
    required super.sourceKey,
    required super.startAtUtc,
    required super.endAtUtc,
    required this.latLng,
    this.accuracyM,
    this.sourceLabel,
    this.confidence,
  });

  final LatLngE7 latLng;
  final int? accuracyM;

  /// Google 由来の semanticType（HOME 等）。永続的な施設 DB としては
  /// 再配布せず、表示上のヒントにのみ使う（BR-04）。
  final String? sourceLabel;
  final double? confidence;
}

/// 移動区間（設計書 4.1 movements）。
class NormalizedMovement extends NormalizedRecord {
  const NormalizedMovement({
    required super.sourceKey,
    required super.startAtUtc,
    required super.endAtUtc,
    required this.distanceMethod,
    this.distanceM,
    this.activityType,
    this.confidence,
    this.startLatLng,
    this.endLatLng,
    this.path = const [],
  });

  final DistanceMethod distanceMethod;
  final int? distanceM;
  final String? activityType;
  final double? confidence;
  final LatLngE7? startLatLng;
  final LatLngE7? endLatLng;

  /// 経路点列（waypoints / timelinePath）。距離の推定に使う。
  final List<LatLngE7> path;

  int get effectiveDistanceM => distanceM ?? 0;
}
