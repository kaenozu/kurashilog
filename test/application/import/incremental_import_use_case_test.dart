import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/application/use_cases/import_use_case.dart';
import 'package:kurashilog/domain/models/normalized_record.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';
import 'package:kurashilog/infrastructure/parsers/record_validator.dart';
import 'package:kurashilog/infrastructure/parsers/records_parser.dart';
import 'package:kurashilog/infrastructure/parsers/timeline_parser.dart';
import 'package:kurashilog/infrastructure/platform/app_platform.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late KurashilogRepositoryImpl repository;
  late _CountingAnalysis analysis;
  late _CountingParser parser;
  late ImportUseCase useCase;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('incremental-import-');
    database = AppDatabase(NativeDatabase.memory());
    repository = KurashilogRepositoryImpl(database);
    analysis = _CountingAnalysis(repository: repository);
    parser = _CountingParser();
    useCase = ImportUseCase(
      repository: repository,
      platform: AppPlatform(),
      analysis: analysis,
      parser: parser,
      validator: const _SameRecordValidator(),
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'same completed file returns zero without parsing or analysis',
    () async {
      final file = File('${directory.path}/timeline.json');
      await file.writeAsString('{}');

      final first = await useCase.importFile(file.path);
      final second = await useCase.importFile(file.path);

      expect(first.ok, isTrue);
      expect(first.addedVisits, 1);
      expect(second.ok, isTrue);
      expect(second.addedVisits, 0);
      expect(second.addedMovements, 0);
      expect(parser.parseCount, 1);
      expect(analysis.rebuildCount, 1);
      expect(await repository.countVisits(), 1);
    },
  );

  test(
    'different overlapping file with no new source keys skips analysis',
    () async {
      final firstFile = File('${directory.path}/first.json');
      final secondFile = File('${directory.path}/second.json');
      await firstFile.writeAsString('{}');
      await secondFile.writeAsString('{"different":true}');

      final first = await useCase.importFile(firstFile.path);
      final second = await useCase.importFile(secondFile.path);

      expect(first.ok, isTrue);
      expect(second.ok, isTrue);
      expect(second.addedVisits, 0);
      expect(parser.parseCount, 2);
      expect(analysis.rebuildCount, 1);
      expect(await repository.countVisits(), 1);
    },
  );
}

class _CountingAnalysis extends AnalysisCoordinator {
  _CountingAnalysis({required super.repository});

  int rebuildCount = 0;

  @override
  Future<void> rebuildAll() async {
    rebuildCount += 1;
  }
}

class _CountingParser extends RecordsTimelineParser {
  int parseCount = 0;

  @override
  String get schemaType => 'test';

  @override
  Stream<NormalizedRecord> parse(
    Stream<List<int>> source,
    CancellationToken token,
  ) {
    parseCount += 1;
    return const Stream<NormalizedRecord>.empty();
  }

  @override
  Future<PreviewResult> preview(
    Stream<List<int>> source,
    CancellationToken token,
  ) async => PreviewResult(
    schemaType: schemaType,
    minAt: DateTime.utc(2026, 1, 1),
    maxAt: DateTime.utc(2026, 1, 2),
    approxRecordCount: 1,
  );
}

class _SameRecordValidator extends RecordValidator {
  const _SameRecordValidator();

  @override
  Stream<ValidationBatch> validateBatches(
    Stream<NormalizedRecord> records,
    CancellationToken token, {
    int batchSize = 500,
  }) async* {
    final start = DateTime.utc(2026, 1, 1, 8);
    yield ValidationBatch(
      visits: <StoredVisit>[
        StoredVisit(
          id: 0,
          sourceKey: 'stable-source-key',
          startAtUtc: start,
          endAtUtc: start.add(const Duration(hours: 1)),
          latE7: 350000000,
          lngE7: 1390000000,
        ),
      ],
      movements: const <StoredMovement>[],
      warnings: const <ImportWarning>[],
      processedRecords: 1,
      isFinal: true,
    );
  }
}
