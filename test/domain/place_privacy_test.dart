import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/domain/privacy/place_privacy.dart';

void main() {
  const projector = PlacePrivacyProjector();

  test(
    'visible app projection preserves traceability without changing source',
    () {
      final cluster = sample(privacyMode: PlacePrivacyMode.visible);
      final result = projector.forApp(cluster)!;

      expect(result.sourceClusterId, cluster.id);
      expect(result.displayName, '公園');
      expect(result.mapPoint, cluster.centroid);
      expect(result.nameRedacted, isFalse);
      expect(result.locationBlurred, isFalse);
    },
  );

  test('hide-name mode removes name and category but keeps app analysis', () {
    final result = projector.forApp(
      sample(privacyMode: PlacePrivacyMode.hideName),
    )!;

    expect(result.displayName, '非公開の場所');
    expect(result.category, isNull);
    expect(result.includedInAnalysis, isTrue);
    expect(result.nameRedacted, isTrue);
  });

  test('blur-map mode quantizes app coordinates', () {
    final cluster = sample(privacyMode: PlacePrivacyMode.blurMap);
    final result = projector.forApp(cluster)!;

    expect(result.locationBlurred, isTrue);
    expect(result.mapPoint, isNot(cluster.centroid));
    expect(result.mapPoint!.latE7 % 100000, 0);
    expect(result.mapPoint!.lngE7 % 100000, 0);
  });

  test('excluded places disappear from app and sharing projections', () {
    final cluster = sample(privacyMode: PlacePrivacyMode.exclude);
    expect(projector.forApp(cluster), isNull);
    expect(projector.forSharing(cluster), isNull);
    expect(cluster.excludedFromAnalysis, isTrue);
  });

  test('sharing is safe by default and base place names are redacted', () {
    final shared = projector.forSharing(
      sample(privacyMode: PlacePrivacyMode.visible, isBasePlace: true),
    )!;
    final encoded = shared.toJson().toString();

    expect(shared.displayName, '非公開の場所');
    expect(shared.category, isNull);
    expect(encoded, isNot(contains('cluster')));
    expect(encoded, isNot(contains('stable')));
    expect(encoded, isNot(contains('356812345')));
    expect(encoded, isNot(contains('1397671234')));
  });

  test('legacy exclusion is hidden from app and sharing projections', () {
    final cluster = sample(
      privacyMode: PlacePrivacyMode.visible,
      excluded: true,
    );

    expect(projector.forApp(cluster), isNull);
    expect(projector.forSharing(cluster), isNull);
  });

  test(
    'sensitive inferred categories are redacted from sharing by default',
    () {
      final shared = projector.forSharing(
        sample(privacyMode: PlacePrivacyMode.visible, category: 'hospital'),
      )!;

      expect(shared.displayName, '非公開の場所');
      expect(shared.category, isNull);
    },
  );

  test('legacy and unknown persisted values fail closed', () {
    expect(
      PlacePrivacyMode.parse('visible', legacyExcluded: true),
      PlacePrivacyMode.exclude,
    );

    final unknownMode = PlacePrivacyMode.parse('future-private-mode');
    expect(unknownMode, PlacePrivacyMode.exclude);

    final cluster = sample(privacyMode: unknownMode);
    expect(cluster.excludedFromAnalysis, isTrue);
    expect(projector.forApp(cluster), isNull);
    expect(projector.forSharing(cluster), isNull);
  });
}

StoredCluster sample({
  required PlacePrivacyMode privacyMode,
  bool isBasePlace = false,
  bool excluded = false,
  String? category = 'park',
}) => StoredCluster(
  id: 42,
  stableKey: 'anonymous-stable-key',
  centroidLatE7: 356812345,
  centroidLngE7: 1397671234,
  radiusM: 100,
  visitCount: 5,
  dwellSeconds: 3600,
  firstAt: DateTime.utc(2026, 1, 1),
  lastAt: DateTime.utc(2026, 2, 1),
  labelName: '公園',
  category: category,
  excluded: excluded,
  isBasePlace: isBasePlace,
  privacyMode: privacyMode,
);
