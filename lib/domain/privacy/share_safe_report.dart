import 'place_privacy.dart';

/// A presentation-only report that is safe to hand to a future share/export
/// renderer.
///
/// This model deliberately has no source keys, cluster IDs, coordinates, or
/// detailed timestamps. Callers must resolve and redact those values before
/// constructing it; widgets and serializers should not repeat privacy rules.
class ShareSafeReport {
  const ShareSafeReport({
    required this.title,
    required this.periodLabel,
    required this.facts,
    this.places = const <PlaceShareProjection>[],
    this.evidence = const <ShareSafeEvidence>[],
  });

  final String title;
  final String periodLabel;
  final Map<String, String> facts;
  final List<PlaceShareProjection> places;
  final List<ShareSafeEvidence> evidence;

  Map<String, Object?> toJson() => <String, Object?>{
    'title': title,
    'period': periodLabel,
    'facts': facts,
    'places': places.map((place) => place.toJson()).toList(growable: false),
    'evidence': evidence.map((item) => item.toJson()).toList(growable: false),
  };
}

/// An evidence explanation suitable for sharing. The category and truth class
/// are intentionally coarse; the stable reference never crosses this boundary.
class ShareSafeEvidence {
  const ShareSafeEvidence({required this.category, required this.truthClass});

  final String category;
  final String truthClass;

  Map<String, Object?> toJson() => <String, Object?>{
    'category': category,
    'truthClass': truthClass,
  };
}
