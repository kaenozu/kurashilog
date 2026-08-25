import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/import/import_reconciliation.dart';
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
      final minRangePreserved = second.sourceMinAt!.isAtSameMomentAs(
        first.sourceMinAt!,
      );
      final maxRangePreserved = second.sourceMaxAt!.isAtSameMomentAs(
        first.sourceMaxAt!,
      );

      expect(first.ok, isTrue);
      expect(first.addedVisits, 1);
      expect(second.ok, isTrue);
      expect(second.addedVisits, 0);
      expect(second.addedMovements, 0);
      expect(first.reconciliation.kind, ImportReconciliationKind.appendOnly);
      expect(second.reconciliation.kind, ImportReconciliationKind.noChanges);
      expect(minRangePreserved, isTrue);
      expect(maxRangePreserved, isTrue);
      expect(parser.parseCount, 1);
      expect(analysis.rebuildCount, 1);
      expect(await repository.countVisits(), 1);
    },
  );

  test(
    'different overlapping file with no material delta skips analysis',
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
      expect(second.updatedVisits, 0);
      expect(second.reconciliation.kind, ImportReconciliationKind.noChanges);
      expect(parser.parseCount, 2);
      expect(analysis.rebuildCount, 1);
      expect(await repository.countVisits(), 1);
    },
  );

  test(
    'new records inside existing history are classified as overlap',
    () async {
      final file1 = File('${directory.path}/append.json');
      final file2 = File('${directory.path}/overlap.json');
      await file1.writeAsString('{}');
      await file2.writeAsString('{"second":true}');
      final sequencedUseCase = ImportUseCase(
        repository: repository,
        platform: AppPlatform(),
        analysis: analysis,
        parser: parser,
        validator: _SequencedRecordValidator(),
      );

      final first = await sequencedUseCase.importFile(file1.path);
      final second = await sequencedUseCase.importFile(file2.path);

      expect(first.reconciliation.kind, ImportReconciliationKind.appendOnly);
      expect(second.addedVisits, 1);
      expect(second.reconciliation.kind, ImportReconciliationKind.overlap);
      expect(second.reconciliation.requiresFullReconciliation, isTrue);
      expect(analysis.rebuildCount, 2);
    },
  );

  test(
    'source correction without additions rebuilds analysis and is overlap',
    () async {
      final firstFile = File('${directory.path}/original.json');
      final correctedFile = File('${directory.path}/corrected.json');
      await firstFile.writeAsString('{}');
      await correctedFile.writeAsString('{"corrected":true}');
      final correctedUseCase = ImportUseCase(
        repository: repository,
        platform: AppPlatform(),
        analysis: analysis,
        parser: parser,
        validator: _CorrectedRecordValidator(),
      );

      final first = await correctedUseCase.importFile(firstFile.path);
      final second = await correctedUseCase.importFile(correctedFile.path);

      expect(first.ok, isTrue);
      expect(first.addedVisits, 1);
      expect(second.ok, isTrue);
      expect(second.addedVisits, 0);
      expect(second.updatedVisits, 1);
      expect(second.reconciliation.kind, ImportReconciliationKind.overlap);
      expect(second.reconciliation.requiresFullReconciliation, isTrue);
      expect(analysis.rebuildCount, 2);

      final visits = await repository.allVisits();
      expect(visits, hasLength(1));
      expect(visits.single.endAtUtc, DateTime.utc(2026, 1, 1, 10));
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

class _SequencedRecordValidator extends RecordValidator {
  int callCount = 0;

  @override
  Stream<ValidationBatch> validateBatches(
    Stream<NormalizedRecord> records,
    CancellationToken token, {
    int batchSize = 500,
  }) async* {
    final sequence = callCount++;
    final start = sequence == 0
        ? DateTime.utc(2026, 1, 10, 8)
        : DateTime.utc(2026, 1, 9, 8);
    yield ValidationBatch(
      visits: <StoredVisit>[
        StoredVisit(
          id: 0,
          sourceKey: 'sequenced-source-key-$sequence',
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

class _CorrectedRecordValidator extends RecordValidator {
  int callCount = 0;

  @override
  Stream<ValidationBatch> validateBatches(
    Stream<NormalizedRecord> records,
    CancellationToken token, {
    int batchSize = 500,
  }) async* {
    final corrected = callCount++ > 0;
    final start = DateTime.utc(2026, 1, 1, 8);
    yield ValidationBatch(
      visits: <StoredVisit>[
        StoredVisit(
          id: 0,
          sourceKey: 'corrected-source-key',
          startAtUtc: start,
          endAtUtc: corrected
              ? DateTime.utc(2026, 1, 1, 10)
              : DateTime.utc(2026, 1, 1, 9),
          latE7: corrected ? 350000100 : 350000000,
          lngE7: corrected ? 1390000100 : 1390000000,
        ),
      ],
      movements: const <StoredMovement>[],
      warnings: const <ImportWarning>[],
      processedRecords: 1,
      isFinal: true,
    );
  }
}
