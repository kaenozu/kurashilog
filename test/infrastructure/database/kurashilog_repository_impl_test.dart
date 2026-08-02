import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
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
}

StoredCluster _cluster(DateTime at, {required int centroidLatE7}) =>
    StoredCluster(
      id: 0,
      stableKey: 'cluster|3568123|13976712',
      centroidLatE7: centroidLatE7,
      centroidLngE7: 1397671250,
      radiusM: 100,
      visitCount: 1,
      dwellSeconds: 3600,
      firstAt: at,
      lastAt: at,
    );
