import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/application/use_cases/places_use_case.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';

void main() {
  test('effectivePlaceIds groups clusters sharing a user label', () {
    final clusters = [
      _cluster(id: 7, stableKey: 'a', labelId: 11),
      _cluster(id: 3, stableKey: 'b', labelId: 11),
      _cluster(id: 9, stableKey: 'c'),
    ];

    final effective = AnalysisCoordinator.effectivePlaceIds(clusters);

    expect(effective[7], 3);
    expect(effective[3], 3);
    expect(effective[9], 9);
  });

  test('merge and split restore the secondary label without schema changes', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = KurashilogRepositoryImpl(database);
    final analysis = AnalysisCoordinator(repository: repository);
    final useCase = PlacesUseCase(repository: repository, analysis: analysis);

    await repository.replaceAllClusters([
      _cluster(id: 0, stableKey: 'place-primary', lat: 350000000),
      _cluster(id: 0, stableKey: 'place-secondary', lat: 350010000),
    ]);
    var clusters = await repository.allClusters();
    final primary = clusters.firstWhere((c) => c.stableKey == 'place-primary');
    final secondary = clusters.firstWhere(
      (c) => c.stableKey == 'place-secondary',
    );
    final secondaryLabel = await repository.insertLabel(
      StoredLabel(
        id: 0,
        displayName: '以前の地点名',
        category: 'work',
        createdAt: DateTime.utc(2026, 8, 25),
        updatedAt: DateTime.utc(2026, 8, 25),
      ),
    );
    await repository.updateClusterLabel(secondary.id, secondaryLabel);

    expect(
      await useCase.mergePlaces(
        primaryClusterId: primary.id,
        secondaryClusterId: secondary.id,
      ),
      isTrue,
    );
    clusters = await repository.allClusters();
    final mergedPrimary = clusters.firstWhere(
      (c) => c.stableKey == 'place-primary',
    );
    final mergedSecondary = clusters.firstWhere(
      (c) => c.stableKey == 'place-secondary',
    );
    expect(mergedPrimary.labelId, isNotNull);
    expect(mergedSecondary.labelId, mergedPrimary.labelId);

    expect(await useCase.splitPlace(mergedSecondary.id), isTrue);
    clusters = await repository.allClusters();
    final splitSecondary = clusters.firstWhere(
      (c) => c.stableKey == 'place-secondary',
    );
    expect(splitSecondary.labelId, secondaryLabel);
    expect(splitSecondary.displayName, '以前の地点名');
  });

  test('privacy updates propagate across a manually merged place', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = KurashilogRepositoryImpl(database);
    final useCase = PlacesUseCase(
      repository: repository,
      analysis: AnalysisCoordinator(repository: repository),
    );
    await repository.replaceAllClusters([
      _cluster(id: 0, stableKey: 'place-a', lat: 350000000),
      _cluster(id: 0, stableKey: 'place-b', lat: 350010000),
    ]);
    var clusters = await repository.allClusters();
    await useCase.mergePlaces(
      primaryClusterId: clusters[0].id,
      secondaryClusterId: clusters[1].id,
    );
    clusters = await repository.allClusters();

    await useCase.setPrivacyMode(
      clusters.first.id,
      PlacePrivacyMode.hideName,
    );

    clusters = await repository.allClusters();
    expect(
      clusters.map((c) => c.privacyMode),
      everyElement(PlacePrivacyMode.hideName),
    );
  });

  test('shared merge label survives cluster rebuild inheritance', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = KurashilogRepositoryImpl(database);
    final useCase = PlacesUseCase(
      repository: repository,
      analysis: AnalysisCoordinator(repository: repository),
    );
    await repository.replaceAllClusters([
      _cluster(id: 0, stableKey: 'stable-a', lat: 350000000),
      _cluster(id: 0, stableKey: 'stable-b', lat: 350010000),
    ]);
    var clusters = await repository.allClusters();
    await useCase.mergePlaces(
      primaryClusterId: clusters[0].id,
      secondaryClusterId: clusters[1].id,
    );
    clusters = await repository.allClusters();
    final sharedLabel = clusters.first.labelId;
    expect(sharedLabel, isNotNull);

    await repository.replaceAllClusters([
      _cluster(id: 0, stableKey: 'stable-a', lat: 350000100),
      _cluster(id: 0, stableKey: 'stable-b', lat: 350010100),
    ]);

    clusters = await repository.allClusters();
    expect(clusters, hasLength(2));
    expect(clusters.map((c) => c.labelId), everyElement(sharedLabel));
  });
}

StoredCluster _cluster({
  required int id,
  required String stableKey,
  int lat = 350000000,
  int? labelId,
}) => StoredCluster(
  id: id,
  stableKey: stableKey,
  centroidLatE7: lat,
  centroidLngE7: 1390000000,
  radiusM: 50,
  visitCount: 10,
  dwellSeconds: 3600,
  firstAt: DateTime.utc(2026, 1, 1),
  lastAt: DateTime.utc(2026, 8, 1),
  labelId: labelId,
);
