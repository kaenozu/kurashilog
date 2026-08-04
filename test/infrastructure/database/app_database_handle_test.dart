import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/infrastructure/database/app_database_handle.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';
import 'package:kurashilog/infrastructure/database/resettable_kurashilog_repository.dart';

void main() {
  late Directory directory;
  late String databasePath;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kurashilog-reset-');
    databasePath =
        '${directory.path}${Platform.pathSeparator}kurashilog.sqlite';
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('physical reset replaces the database and is repeatable', () async {
    final handle = await AppDatabaseHandle.open(databasePath: databasePath);
    final repository = ResettableKurashilogRepository(handle);
    addTearDown(handle.close);

    await repository.insertNewRecords(
      visits: [_visit('before-reset')],
      movements: const [],
    );
    await repository.setSetting('sample', 'value');
    expect(await repository.countVisits(), 1);
    expect(await repository.getSetting('sample'), isNotNull);

    await repository.deleteAllUserData();

    expect(await repository.countVisits(), 0);
    expect(await repository.getSetting('sample'), isNull);
    await _expectResetArtifactsAbsent(databasePath);

    await repository.deleteAllUserData();
    expect(await repository.countVisits(), 0);
    await _expectResetArtifactsAbsent(databasePath);
  });

  test('startup completes an interrupted reset including sidecars', () async {
    final firstHandle = await AppDatabaseHandle.open(
      databasePath: databasePath,
    );
    final firstRepository = ResettableKurashilogRepository(firstHandle);
    await firstRepository.insertNewRecords(
      visits: [_visit('interrupted')],
      movements: const [],
    );
    await firstHandle.close();

    await File(
      '$databasePath${AppDatabaseHandle.resetMarkerSuffix}',
    ).writeAsString('pending\n');
    await File('$databasePath-wal').writeAsString('stale wal');
    await File('$databasePath-shm').writeAsString('stale shm');

    final recoveredHandle = await AppDatabaseHandle.open(
      databasePath: databasePath,
    );
    final recoveredRepository = ResettableKurashilogRepository(recoveredHandle);
    addTearDown(recoveredHandle.close);

    expect(await recoveredRepository.countVisits(), 0);
    await _expectResetArtifactsAbsent(databasePath);
  });

  test(
    'a deletion failure never reports success and remains recoverable',
    () async {
      var failNextStagedDelete = true;
      Future<void> deleteFile(File file) async {
        if (failNextStagedDelete &&
            file.path.endsWith(AppDatabaseHandle.stagedSuffix) &&
            await file.exists()) {
          failNextStagedDelete = false;
          throw const FileSystemException('injected delete failure');
        }
        if (await file.exists()) await file.delete();
      }

      final handle = await AppDatabaseHandle.open(
        databasePath: databasePath,
        deleteFile: deleteFile,
      );
      final repository = ResettableKurashilogRepository(handle);
      addTearDown(handle.close);

      await repository.insertNewRecords(
        visits: [_visit('failure')],
        movements: const [],
      );

      await expectLater(
        repository.deleteAllUserData(),
        throwsA(isA<DatabaseResetException>()),
      );

      expect(await repository.countVisits(), 0);
      await _expectResetArtifactsAbsent(databasePath);

      await repository.deleteAllUserData();
      expect(await repository.countVisits(), 0);
    },
  );

  test('reset drains prior work and blocks later work until reopen', () async {
    final handle = await AppDatabaseHandle.open(databasePath: databasePath);
    final repository = ResettableKurashilogRepository(handle);
    addTearDown(handle.close);

    final releaseFirstOperation = Completer<void>();
    final firstOperation = handle.run((database) async {
      await releaseFirstOperation.future;
      await KurashilogRepositoryImpl(database).insertNewRecords(
        visits: [_visit('queued-before-reset')],
        movements: const [],
      );
    });

    final reset = repository.deleteAllUserData();
    final countAfterReset = repository.countVisits();
    releaseFirstOperation.complete();

    await firstOperation;
    await reset;
    expect(await countAfterReset, 0);
  });

  test('transactional repository calls do not deadlock the handle', () async {
    final handle = await AppDatabaseHandle.open(databasePath: databasePath);
    final repository = ResettableKurashilogRepository(handle);
    addTearDown(handle.close);

    await repository.runInTransaction(() async {
      await repository.insertNewRecords(
        visits: [_visit('transaction')],
        movements: const [],
      );
      await repository.setSetting('transaction', 'complete');
    });

    expect(await repository.countVisits(), 1);
    expect((await repository.getSetting('transaction'))?.value, 'complete');
  });
}

StoredVisit _visit(String sourceKey) {
  final start = DateTime.utc(2026, 8, 4, 8);
  return StoredVisit(
    id: 0,
    sourceKey: sourceKey,
    startAtUtc: start,
    endAtUtc: start.add(const Duration(hours: 1)),
    latE7: 356812360,
    lngE7: 1397671250,
  );
}

Future<void> _expectResetArtifactsAbsent(String databasePath) async {
  final paths = <String>[
    '$databasePath${AppDatabaseHandle.resetMarkerSuffix}',
    '$databasePath${AppDatabaseHandle.stagedSuffix}',
    '$databasePath-wal${AppDatabaseHandle.stagedSuffix}',
    '$databasePath-shm${AppDatabaseHandle.stagedSuffix}',
  ];
  for (final path in paths) {
    expect(await File(path).exists(), isFalse, reason: path);
  }
}
