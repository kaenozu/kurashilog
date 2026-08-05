import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/use_cases/import_use_case.dart';
import 'package:kurashilog/domain/models/lat_lng.dart';
import 'package:kurashilog/domain/models/normalized_record.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';
import 'package:kurashilog/infrastructure/parsers/records_parser.dart';
import 'package:kurashilog/infrastructure/parsers/timeline_parser.dart';
import 'package:kurashilog/infrastructure/platform/app_platform.dart';

void main() {
  test(
    'large synthetic import crosses batches without loss or duplication',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'kurashilog-batch-',
      );
      final source = File(
        '${directory.path}${Platform.pathSeparator}timeline.json',
      );
      await source.writeAsString('{}');
      final database = AppDatabase(NativeDatabase.memory());
      final repository = KurashilogRepositoryImpl(database);
      final useCase = ImportUseCase(
        repository: repository,
        platform: AppPlatform(),
        analysis: _NoopAnalysis(repository: repository),
        parser: const _ManyVisitParser(1201),
      );
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });

      final first = await useCase.importFile(source.path);
      expect(first.ok, isTrue);
      expect(first.addedVisits, 1201);
      expect(await repository.countVisits(), 1201);

      final second = await useCase.importFile(source.path);
      expect(second.ok, isTrue);
      expect(second.addedVisits, 0);
      expect(await repository.countVisits(), 1201);
    },
  );

  test(
    'parse failure after a committed-sized batch rolls everything back',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'kurashilog-rollback-',
      );
      final source = File(
        '${directory.path}${Platform.pathSeparator}timeline.json',
      );
      await source.writeAsString('{}');
      final database = AppDatabase(NativeDatabase.memory());
      final repository = KurashilogRepositoryImpl(database);
      final useCase = ImportUseCase(
        repository: repository,
        platform: AppPlatform(),
        analysis: _NoopAnalysis(repository: repository),
        parser: const _ThrowingVisitParser(),
      );
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });

      final result = await useCase.importFile(source.path);
      expect(result.ok, isFalse);
      expect(result.errorCode, 'PAR-001');
      expect(await repository.countVisits(), 0);
    },
  );
}

class _NoopAnalysis extends AnalysisCoordinator {
  _NoopAnalysis({required super.repository});

  @override
  Future<void> rebuildAll() async {}
}

class _ManyVisitParser extends RecordsTimelineParser {
  const _ManyVisitParser(this.count);

  final int count;

  @override
  String get schemaType => 'synthetic-batch';

  @override
  Stream<NormalizedRecord> parse(
    Stream<List<int>> source,
    CancellationToken token,
  ) async* {
    final base = DateTime.utc(2026, 1, 1);
    for (var index = 0; index < count; index++) {
      final start = base.add(Duration(minutes: index * 2));
      yield NormalizedVisit(
        sourceKey: 'synthetic-$index',
        startAtUtc: start,
        endAtUtc: start.add(const Duration(minutes: 1)),
        latLng: LatLngE7(350000000 + index, 1390000000 + index),
      );
    }
  }
}

class _ThrowingVisitParser extends _ManyVisitParser {
  const _ThrowingVisitParser() : super(600);

  @override
  Stream<NormalizedRecord> parse(
    Stream<List<int>> source,
    CancellationToken token,
  ) async* {
    await for (final record in super.parse(source, token)) {
      yield record;
    }
    throw const ImportParseException('PAR-001', 'synthetic failure');
  }
}
