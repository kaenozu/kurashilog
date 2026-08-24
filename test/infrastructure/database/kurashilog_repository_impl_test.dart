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

  test(
    'reimport updates source fields while preserving user cluster override',
    () async {
      final at = DateTime.utc(2026, 7, 1);
      final original = StoredVisit(
        id: 0,
        sourceKey: 'visit-corrected-source-key',
        startAtUtc: at,
        endAtUtc: at.add(const Duration(hours: 1)),
        latE7: 351234560,
        lngE7: 1396543210,
      );
      final corrected = StoredVisit(
        id: 0,
        sourceKey: original.sourceKey,
        startAtUtc: original.startAtUtc,
        endAtUtc: original.endAtUtc,
        latE7: 351234561,
        lngE7: original.lngE7,
      );

      await repository.insertNewRecords(
        visits: [original],
        movements: const [],
      );
      final stored = (await repository.allVisits()).single;
      await repository.assignVisitClusterIds({stored.id: 7});

      final diff = await repository.insertNewRecords(
        visits: [corrected],
        movements: const [],
      );

      expect(diff.addedVisits, 0);
      expect(diff.updatedVisits, 1);
      final reread = (await repository.allVisits()).single;
      expect(reread.latE7, corrected.latE7);
      expect(reread.clusterId, 7);
    },
  );
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
