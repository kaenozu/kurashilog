import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/domain/models/distance_method.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';

void main() {
  late AppDatabase database;
  late KurashilogRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = KurashilogRepositoryImpl(database);
  });

  tearDown(() => database.close());

  test('updates import and label rows by primary key', () async {
    final startedAt = DateTime.utc(2026, 7, 1);
    final importId = await repository.insertImport(
      ImportedFileRecord(
        id: 0,
        fileHash: 'hash',
        schemaType: 'timeline-records',
        startedAt: startedAt,
        status: 'processing',
      ),
    );

    await repository.updateImport(
      ImportedFileRecord(
        id: importId,
        fileHash: 'hash',
        schemaType: 'timeline-records',
        startedAt: startedAt,
        completedAt: startedAt.add(const Duration(minutes: 1)),
        status: 'completed',
        addedVisits: 2,
      ),
    );
    final latest = await repository.latestCompletedImport();
    expect(latest?.id, importId);
    expect(latest?.addedVisits, 2);

    final labelId = await repository.insertLabel(
      StoredLabel(
        id: 0,
        displayName: '旧名称',
        createdAt: startedAt,
        updatedAt: startedAt,
      ),
    );
    await repository.updateLabel(
      StoredLabel(
        id: labelId,
        displayName: '新名称',
        isBasePlace: true,
        createdAt: startedAt,
        updatedAt: startedAt.add(const Duration(minutes: 1)),
      ),
    );
    final label = await repository.labelById(labelId);
    expect(label?.displayName, '新名称');
    expect(label?.isBasePlace, isTrue);
  });

  test('cluster rebuild preserves label and exclusion by stable key', () async {
    final at = DateTime.utc(2026, 7, 1);
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
      _cluster(at, centroidLatE7: 356812360),
    ]);
    final first = (await repository.allClusters()).single;
    await repository.updateClusterLabel(first.id, labelId);
    await repository.setClusterExcluded(first.id, true);

    await repository.replaceAllClusters([
      _cluster(at, centroidLatE7: 356812361),
    ]);
    final rebuilt = (await repository.allClusters()).single;
    expect(rebuilt.labelId, labelId);
    expect(rebuilt.labelName, '自宅');
    expect(rebuilt.excluded, isTrue);
  });

  test('cluster rebuild keeps label and exclusion when centroid shifts '
      'across the stable key boundary', () async {
    final at = DateTime.utc(2026, 7, 1);
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
      _cluster(at, centroidLatE7: 356812360),
    ]);
    final first = (await repository.allClusters()).single;
    await repository.updateClusterLabel(first.id, labelId);
    await repository.setClusterExcluded(first.id, true);

    final shifted = _cluster(
      at,
      centroidLatE7: 356812400,
      stableKey: 'cluster|3568124|13976712',
    );
    await repository.replaceAllClusters([shifted]);
    final rebuilt = (await repository.allClusters()).single;
    expect(rebuilt.labelId, labelId);
    expect(rebuilt.labelName, '自宅');
    expect(rebuilt.excluded, isTrue);
  });

  test('cluster rebuild drops settings for a far-away cluster', () async {
    final at = DateTime.utc(2026, 7, 1);
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
      _cluster(at, centroidLatE7: 356812360),
    ]);
    final first = (await repository.allClusters()).single;
    await repository.updateClusterLabel(first.id, labelId);
    await repository.setClusterExcluded(first.id, true);

    final far = _cluster(
      at,
      centroidLatE7: 357512360,
      centroidLngE7: 1398671250,
      stableKey: 'cluster|3575123|13986712',
    );
    await repository.replaceAllClusters([far]);
    final rebuilt = (await repository.allClusters()).single;
    expect(rebuilt.labelId, isNull);
    expect(rebuilt.excluded, isFalse);
  });

  test('cluster split does not duplicate one correction', () async {
    final at = DateTime.utc(2026, 7, 1);
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
      _cluster(at, centroidLatE7: 356812360, stableKey: 'old-home'),
    ]);
    final existing = (await repository.allClusters()).single;
    await repository.updateClusterLabel(existing.id, labelId);
    await repository.setClusterExcluded(existing.id, true);

    await repository.replaceAllClusters([
      _cluster(at, centroidLatE7: 356812365, stableKey: 'split-near'),
      _cluster(at, centroidLatE7: 356812380, stableKey: 'split-far'),
    ]);

    final rebuilt = await repository.allClusters();
    final corrected = rebuilt.where((cluster) => cluster.labelId == labelId);
    expect(corrected, hasLength(1));
    expect(corrected.single.stableKey, 'split-near');
    expect(corrected.single.excluded, isTrue);
    expect(rebuilt.where((cluster) => cluster.isBasePlace), hasLength(1));
    final uncorrected = rebuilt.singleWhere(
      (cluster) => cluster.stableKey == 'split-far',
    );
    expect(uncorrected.labelId, isNull);
    expect(uncorrected.excluded, isFalse);
  });

  test('stable key match wins before a closer distance match', () async {
    final at = DateTime.utc(2026, 7, 1);
    final exactLabelId = await repository.insertLabel(
      StoredLabel(id: 0, displayName: '完全一致', createdAt: at, updatedAt: at),
    );
    final nearbyLabelId = await repository.insertLabel(
      StoredLabel(id: 0, displayName: '近傍', createdAt: at, updatedAt: at),
    );
    await repository.replaceAllClusters([
      _cluster(at, centroidLatE7: 356812300, stableKey: 'exact-key'),
      _cluster(at, centroidLatE7: 356812400, stableKey: 'near-key'),
    ]);
    final existing = await repository.allClusters();
    await repository.updateClusterLabel(
      existing.singleWhere((cluster) => cluster.stableKey == 'exact-key').id,
      exactLabelId,
    );
    await repository.updateClusterLabel(
      existing.singleWhere((cluster) => cluster.stableKey == 'near-key').id,
      nearbyLabelId,
    );

    await repository.replaceAllClusters([
      _cluster(at, centroidLatE7: 356812399, stableKey: 'exact-key'),
      _cluster(at, centroidLatE7: 356812401, stableKey: 'new-near'),
    ]);

    final rebuilt = await repository.allClusters();
    expect(
      rebuilt
          .singleWhere((cluster) => cluster.stableKey == 'exact-key')
          .labelId,
      exactLabelId,
    );
    expect(
      rebuilt.singleWhere((cluster) => cluster.stableKey == 'new-near').labelId,
      nearbyLabelId,
    );
  });

  test('cluster merge inherits only the closest correction', () async {
    final at = DateTime.utc(2026, 7, 1);
    final closeLabelId = await repository.insertLabel(
      StoredLabel(id: 0, displayName: '近い地点', createdAt: at, updatedAt: at),
    );
    final farLabelId = await repository.insertLabel(
      StoredLabel(id: 0, displayName: '遠い地点', createdAt: at, updatedAt: at),
    );
    await repository.replaceAllClusters([
      _cluster(at, centroidLatE7: 356812360, stableKey: 'old-close'),
      _cluster(at, centroidLatE7: 356812500, stableKey: 'old-far'),
    ]);
    final existing = await repository.allClusters();
    await repository.updateClusterLabel(
      existing.singleWhere((cluster) => cluster.stableKey == 'old-close').id,
      closeLabelId,
    );
    await repository.updateClusterLabel(
      existing.singleWhere((cluster) => cluster.stableKey == 'old-far').id,
      farLabelId,
    );

    await repository.replaceAllClusters([
      _cluster(at, centroidLatE7: 356812370, stableKey: 'merged'),
    ]);

    final rebuilt = (await repository.allClusters()).single;
    expect(rebuilt.labelId, closeLabelId);
  });

  test('equal-distance matching is deterministic by stable key', () async {
    final at = DateTime.utc(2026, 7, 1);
    final labelA = await repository.insertLabel(
      StoredLabel(id: 0, displayName: 'A', createdAt: at, updatedAt: at),
    );
    final labelB = await repository.insertLabel(
      StoredLabel(id: 0, displayName: 'B', createdAt: at, updatedAt: at),
    );
    await repository.replaceAllClusters([
      _cluster(at, centroidLatE7: 356812350, stableKey: 'a-existing'),
      _cluster(at, centroidLatE7: 356812370, stableKey: 'b-existing'),
    ]);
    final existing = await repository.allClusters();
    await repository.updateClusterLabel(
      existing.singleWhere((cluster) => cluster.stableKey == 'a-existing').id,
      labelA,
    );
    await repository.updateClusterLabel(
      existing.singleWhere((cluster) => cluster.stableKey == 'b-existing').id,
      labelB,
    );

    await repository.replaceAllClusters([
      _cluster(at, centroidLatE7: 356812360, stableKey: 'new-cluster'),
    ]);

    expect((await repository.allClusters()).single.labelId, labelA);
  });

  test('runInTransaction rolls raw records back on failure', () async {
    final at = DateTime.utc(2026, 7, 1);
    await expectLater(
      repository.runInTransaction(() async {
        await repository.insertNewRecords(
          visits: [
            StoredVisit(
              id: 0,
              sourceKey: 'visit-1',
              startAtUtc: at,
              endAtUtc: at.add(const Duration(hours: 1)),
              latE7: 356812360,
              lngE7: 1397671250,
            ),
          ],
          movements: const [],
        );
        throw StateError('force rollback');
      }),
      throwsStateError,
    );
    expect(await repository.countVisits(), 0);
  });

  test('inserting the same sourceKey twice does not increase counts', () async {
    final at = DateTime.utc(2026, 7, 1);
    final visit = StoredVisit(
      id: 0,
      sourceKey: 'visit-same-source-key',
      startAtUtc: at,
      endAtUtc: at.add(const Duration(hours: 1)),
      latE7: 351234560,
      lngE7: 1396543210,
    );
    final movement = StoredMovement(
      id: 0,
      sourceKey: 'movement-same-source-key',
      startAtUtc: at.add(const Duration(hours: 1)),
      endAtUtc: at.add(const Duration(hours: 2)),
      distanceMethod: DistanceMethod.recorded,
      distanceM: 1200,
    );

    final first = await repository.insertNewRecords(
      visits: [visit],
      movements: [movement],
    );
    expect(first.addedVisits, 1);
    expect(first.addedMovements, 1);

    final second = await repository.insertNewRecords(
      visits: [visit],
      movements: [movement],
    );
    expect(second.addedVisits, 0);
    expect(second.addedMovements, 0);
    expect(await repository.countVisits(), 1);
    expect(await repository.countMovements(), 1);
  });
}

StoredCluster _cluster(
  DateTime at, {
  required int centroidLatE7,
  int centroidLngE7 = 1397671250,
  String stableKey = 'cluster|3568123|13976712',
}) => StoredCluster(
  id: 0,
  stableKey: stableKey,
  centroidLatE7: centroidLatE7,
  centroidLngE7: centroidLngE7,
  radiusM: 100,
  visitCount: 1,
  dwellSeconds: 3600,
  firstAt: at,
  lastAt: at,
);
