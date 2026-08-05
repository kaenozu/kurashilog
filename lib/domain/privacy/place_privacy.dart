import '../../application/models/persistence_models.dart';
import '../models/lat_lng.dart';

class PlaceProjection {
  const PlaceProjection({
    required this.sourceClusterId,
    required this.displayName,
    required this.category,
    required this.mapPoint,
    required this.includedInAnalysis,
    required this.nameRedacted,
    required this.locationBlurred,
  });

  /// Internal traceability only. Sharing serializers must not emit this field.
  final int sourceClusterId;
  final String displayName;
  final String? category;
  final LatLngE7? mapPoint;
  final bool includedInAnalysis;
  final bool nameRedacted;
  final bool locationBlurred;
}

class PlaceShareProjection {
  const PlaceShareProjection({
    required this.displayName,
    required this.category,
    required this.locationLabel,
  });

  final String displayName;
  final String? category;
  final String locationLabel;

  Map<String, Object?> toJson() => <String, Object?>{
    'displayName': displayName,
    if (category != null) 'category': category,
    'locationLabel': locationLabel,
  };
}

/// Applies display/privacy rules without changing source records or clusters.
class PlacePrivacyProjector {
  const PlacePrivacyProjector({this.blurGridE7 = 100000});

  /// 0.01 degree, roughly 1 km in latitude. Exact coordinates are never used
  /// in a share projection.
  final int blurGridE7;

  PlaceProjection? forApp(StoredCluster cluster) {
    final mode = cluster.privacyMode;
    if (mode == PlacePrivacyMode.exclude) return null;
    final hideName = mode == PlacePrivacyMode.hideName;
    final blur = mode == PlacePrivacyMode.blurMap;
    return PlaceProjection(
      sourceClusterId: cluster.id,
      displayName: hideName ? '非公開の場所' : cluster.displayName,
      category: hideName ? null : cluster.category,
      mapPoint: blur ? _blur(cluster.centroid) : cluster.centroid,
      includedInAnalysis: true,
      nameRedacted: hideName,
      locationBlurred: blur,
    );
  }

  PlaceShareProjection? forSharing(StoredCluster cluster) {
    final mode = cluster.privacyMode;
    if (mode == PlacePrivacyMode.exclude) return null;
    final redact = mode == PlacePrivacyMode.hideName || cluster.isBasePlace;
    return PlaceShareProjection(
      displayName: redact ? '非公開の場所' : cluster.displayName,
      category: redact ? null : cluster.category,
      // Sharing is safe by default: no coordinates or stable keys leave the app.
      locationLabel: mode == PlacePrivacyMode.blurMap ? 'おおよその位置' : '位置情報は非公開',
    );
  }

  LatLngE7 _blur(LatLngE7 point) {
    int round(int value) => (value / blurGridE7).round() * blurGridE7;
    return LatLngE7(round(point.latE7), round(point.lngE7));
  }
}
