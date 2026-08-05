import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/correction_preserving_repository.dart';

void main() {
  late AppDatabase database;
  late CorrectionPreservingRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = CorrectionPreservingRepository(database);
  });

  tearDown(() => database.close());

  test(
    'exact match keeps correction and nearby split does not duplicate it',
    () async {
      final at = DateTime.utc(2026, 8, 4);
      final labelId = await repository.insertLabel(
        StoredLabel(
          id: 0,
          displayName: '自宅',
          isBasePlace: true,
          createdAt: at,
          updatedAt: at,
        ),
      );

      await repository.replaceAllClusters([
        _cluster(at, stableKey: 'exact', centroidLatE7: 356812360),
      ]);
      final original = (await repository.allClusters()).single;
      await repository.updateClusterLabel(original.id, labelId);
      await repository.setClusterPrivacyMode(
        original.id,
        PlacePrivacyMode.hideName,
      );

      // Put the nearby split first to prove it cannot steal the exact match.
      await repository.replaceAllClusters([
        _cluster(at, stableKey: 'nearby', centroidLatE7: 356812361),
        _cluster(at, stableKey: 'exact', centroidLatE7: 356812360),
      ]);

      final rebuilt = {
        for (final cluster in await repository.allClusters())
          cluster.stableKey: cluster,
      };
      expect(rebuilt['exact']?.labelId, labelId);
      expect(rebuilt['exact']?.privacyMode, PlacePrivacyMode.hideName);
      expect(rebuilt['exact']?.excluded, isFalse);
      expect(rebuilt['nearby']?.labelId, isNull);
      expect(rebuilt['nearby']?.privacyMode, PlacePrivacyMode.visible);
    },
  );

  test('legacy exclusion remains an explicit exclusion after rebuild', () async {
    final at = DateTime.utc(2026, 8, 4);
    await repository.replaceAllClusters([
      _cluster(at, stableKey: 'legacy', centroidLatE7: 356812360),
    ]);
    final original = (await repository.allClusters()).single;
    await repository.setClusterExcluded(original.id, true);

    await repository.replaceAllClusters([
      _cluster(at, stableKey: 'legacy', centroidLatE7: 356812360),
    ]);

    final rebuilt = (await repository.allClusters()).single;
    expect(rebuilt.excluded, isTrue);
    expect(rebuilt.privacyMode, PlacePrivacyMode.exclude);
    expect(rebuilt.excludedFromAnalysis, isTrue);
  });
}

StoredCluster _cluster(
  DateTime at, {
  required String stableKey,
  required int centroidLatE7,
}) => StoredCluster(
  id: 0,
  stableKey: stableKey,
  centroidLatE7: centroidLatE7,
  centroidLngE7: 1397671250,
  radiusM: 100,
  visitCount: 1,
  dwellSeconds: 3600,
  firstAt: at,
  lastAt: at,
);
