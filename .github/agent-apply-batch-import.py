from pathlib import Path
import re

Path('lib/infrastructure/parsers/record_validator.dart').write_text(r'''import '../../domain/models/distance_method.dart';
import '../../domain/models/normalized_record.dart';
import '../../domain/services/distance_service.dart';
import '../../application/models/persistence_models.dart';
import 'timeline_parser.dart';

/// Complete validation result for small inputs and compatibility callers.
class ValidationResult {
  const ValidationResult({
    required this.visits,
    required this.movements,
    required this.warnings,
  });

  final List<StoredVisit> visits;
  final List<StoredMovement> movements;
  final List<ImportWarning> warnings;

  int get totalRecords => visits.length + movements.length;
}

/// A bounded validation batch. Warnings are cumulative so the final batch is
/// the authoritative warning snapshot even when it contains no records.
class ValidationBatch {
  const ValidationBatch({
    required this.visits,
    required this.movements,
    required this.warnings,
    required this.processedRecords,
    required this.isFinal,
  });

  final List<StoredVisit> visits;
  final List<StoredMovement> movements;
  final List<ImportWarning> warnings;
  final int processedRecords;
  final bool isFinal;

  int get totalRecords => visits.length + movements.length;
}

/// Record validation with a bounded-memory streaming API.
class RecordValidator {
  const RecordValidator({this.distanceService = const DistanceService()});

  final DistanceService distanceService;

  Future<ValidationResult> validate(
    Stream<NormalizedRecord> records,
    CancellationToken token,
  ) async {
    final visits = <StoredVisit>[];
    final movements = <StoredMovement>[];
    var warnings = const <ImportWarning>[];
    await for (final batch in validateBatches(records, token)) {
      visits.addAll(batch.visits);
      movements.addAll(batch.movements);
      warnings = batch.warnings;
    }
    return ValidationResult(
      visits: visits,
      movements: movements,
      warnings: warnings,
    );
  }

  Stream<ValidationBatch> validateBatches(
    Stream<NormalizedRecord> records,
    CancellationToken token, {
    int batchSize = 500,
  }) async* {
    if (batchSize < 1) {
      throw ArgumentError.value(batchSize, 'batchSize', 'must be positive');
    }

    final visits = <StoredVisit>[];
    final movements = <StoredMovement>[];
    final warningMap = <String, ImportWarning>{};
    var processedRecords = 0;

    void warn(String code, String message) {
      warningMap[code] = (warningMap[code] ?? ImportWarning(code, message))
          .mergedWith(ImportWarning(code, message));
    }

    ValidationBatch snapshot({required bool isFinal}) => ValidationBatch(
      visits: List.unmodifiable(visits),
      movements: List.unmodifiable(movements),
      warnings: List.unmodifiable(warningMap.values),
      processedRecords: processedRecords,
      isFinal: isFinal,
    );

    await for (final record in records) {
      if (token.isCancelled) {
        throw const ImportParseException('IMP-005', 'キャンセルされました');
      }
      processedRecords++;
      switch (record) {
        case NormalizedVisit():
          final visit = _validateVisit(record, warn);
          if (visit != null) visits.add(visit);
        case NormalizedMovement():
          final movement = _validateMovement(record, warn);
          if (movement != null) movements.add(movement);
      }

      if (visits.length + movements.length >= batchSize) {
        yield snapshot(isFinal: false);
        visits.clear();
        movements.clear();
      }
    }

    yield snapshot(isFinal: true);
  }

  StoredVisit? _validateVisit(
    NormalizedVisit visit,
    void Function(String code, String message) warn,
  ) {
    if (!visit.latLng.isValid) {
      warn('VAL-001', '座標が範囲外の訪問を破棄しました');
      return null;
    }
    if (visit.endAtUtc.isBefore(visit.startAtUtc)) {
      warn('VAL-002', '開始時刻が終了より後の訪問を破棄しました');
      return null;
    }
    if (visit.endAtUtc == visit.startAtUtc) {
      warn('VAL-003', '滞在時間が 0 の訪問を破棄しました');
      return null;
    }
    return StoredVisit(
      id: 0,
      sourceKey: visit.sourceKey,
      startAtUtc: visit.startAtUtc,
      endAtUtc: visit.endAtUtc,
      latE7: visit.latLng.latE7,
      lngE7: visit.latLng.lngE7,
      accuracyM: visit.accuracyM,
      sourceLabel: visit.sourceLabel,
      confidence: visit.confidence,
    );
  }

  StoredMovement? _validateMovement(
    NormalizedMovement movement,
    void Function(String code, String message) warn,
  ) {
    if (movement.endAtUtc.isBefore(movement.startAtUtc)) {
      warn('VAL-002', '開始時刻が終了より後の移動を破棄しました');
      return null;
    }
    if (movement.endAtUtc == movement.startAtUtc &&
        movement.effectiveDistanceM == 0) {
      warn('VAL-003', '滞在時間が 0 の移動を破棄しました');
      return null;
    }

    var validDistance =
        movement.distanceMethod != DistanceMethod.unknown &&
        movement.distanceM != null;
    if (validDistance &&
        distanceService.isAbsurdSpeed(
          distanceM: movement.distanceM!,
          start: movement.startAtUtc,
          end: movement.endAtUtc,
        )) {
      validDistance = false;
      warn('VAL-004', '異常速度の移動を日常集計から除外しました');
    }

    return StoredMovement(
      id: 0,
      sourceKey: movement.sourceKey,
      startAtUtc: movement.startAtUtc,
      endAtUtc: movement.endAtUtc,
      distanceM: movement.distanceM,
      distanceMethod: movement.distanceMethod,
      activityType: movement.activityType,
      confidence: movement.confidence,
      startLatLng: movement.startLatLng,
      endLatLng: movement.endLatLng,
      path: movement.path,
      validDistance: validDistance,
    );
  }
}
''', encoding='utf-8')

path = Path('lib/application/use_cases/import_use_case.dart')
text = path.read_text(encoding='utf-8')
start = text.index("      final records = parser.parse(file.openRead(), cancellation);")
end_marker = "      onProgress?.call(\n        const ImportProgress(ImportStage.insights, percent: 100),\n      );\n"
end = text.index(end_marker, start)
replacement = r'''      DateTime? sourceMinAt;
      DateTime? sourceMaxAt;
      var addedVisits = 0;
      var addedMovements = 0;

      await repository.runInTransaction(() async {
        final records = parser.parse(file.openRead(), cancellation);
        await for (final batch in validator.validateBatches(
          records,
          cancellation,
          batchSize: 500,
        )) {
          warnings = mergeImportWarnings(previewWarnings, batch.warnings);
          if (cancellation.isCancelled) {
            throw const ImportParseException('IMP-005', 'キャンセルされました');
          }

          if (batch.totalRecords > 0) {
            final diff = await repository.insertNewRecords(
              visits: batch.visits,
              movements: batch.movements,
            );
            addedVisits += diff.addedVisits;
            addedMovements += diff.addedMovements;

            final batchMin = _minStart(batch.visits, batch.movements);
            if (batchMin != null &&
                (sourceMinAt == null || batchMin.isBefore(sourceMinAt!))) {
              sourceMinAt = batchMin;
            }
            final batchMax = _maxEnd(batch.visits, batch.movements);
            if (batchMax != null &&
                (sourceMaxAt == null || batchMax.isAfter(sourceMaxAt!))) {
              sourceMaxAt = batchMax;
            }
          }

          final validationPercent =
              (40 + batch.processedRecords ~/ 500).clamp(40, 60).toInt();
          onProgress?.call(
            ImportProgress(ImportStage.validating, percent: validationPercent),
          );
        }

        if (cancellation.isCancelled) {
          throw const ImportParseException('IMP-005', 'キャンセルされました');
        }

        onProgress?.call(
          const ImportProgress(ImportStage.clustering, percent: 75),
        );
        await analysis.rebuildAll();

        if (cancellation.isCancelled) {
          throw const ImportParseException('IMP-005', 'キャンセルされました');
        }

        onProgress?.call(
          const ImportProgress(ImportStage.insights, percent: 95),
        );
        await repository.updateImport(
          ImportedFileRecord(
            id: importId,
            fileHash: fileHash,
            schemaType: parser.schemaType,
            startedAt: startedAt,
            completedAt: DateTime.now(),
            sourceMinAt: sourceMinAt,
            sourceMaxAt: sourceMaxAt,
            status: 'completed',
            warningCount: importWarningCount(warnings),
            addedVisits: addedVisits,
            addedMovements: addedMovements,
          ),
        );
      });

'''
text = text[:start] + replacement + text[end:]
text = text.replace('        addedVisits: diff.addedVisits,\n        addedMovements: diff.addedMovements,', '        addedVisits: addedVisits,\n        addedMovements: addedMovements,', 1)
path.write_text(text, encoding='utf-8')

regression = Path('test/application/use_cases/import_use_case_regression_test.dart')
text = regression.read_text(encoding='utf-8')
old = r'''  @override
  Future<ValidationResult> validate(
    Stream<NormalizedRecord> records,
    CancellationToken token,
  ) async {
    final start = DateTime.utc(2026, 8, 4, 8);
    return ValidationResult(
      visits: [
        StoredVisit(
          id: 0,
          sourceKey: 'cancelled-during-analysis',
          startAtUtc: start,
          endAtUtc: start.add(const Duration(hours: 1)),
          latE7: 356812360,
          lngE7: 1397671250,
        ),
      ],
      movements: const [],
      warnings: const [ImportWarning('VAL-001', '本取込の警告')],
    );
  }
'''
new = r'''  @override
  Stream<ValidationBatch> validateBatches(
    Stream<NormalizedRecord> records,
    CancellationToken token, {
    int batchSize = 500,
  }) async* {
    final start = DateTime.utc(2026, 8, 4, 8);
    yield ValidationBatch(
      visits: [
        StoredVisit(
          id: 0,
          sourceKey: 'cancelled-during-analysis',
          startAtUtc: start,
          endAtUtc: start.add(const Duration(hours: 1)),
          latE7: 356812360,
          lngE7: 1397671250,
        ),
      ],
      movements: const [],
      warnings: const [ImportWarning('VAL-001', '本取込の警告')],
      processedRecords: 1,
      isFinal: true,
    );
  }
'''
if text.count(old) != 1:
    raise SystemExit(f'stub validator block count={text.count(old)}')
regression.write_text(text.replace(old, new, 1), encoding='utf-8')

Path('test/infrastructure/parsers/record_validator_batch_test.dart').write_text(r'''import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/models/lat_lng.dart';
import 'package:kurashilog/domain/models/normalized_record.dart';
import 'package:kurashilog/infrastructure/parsers/record_validator.dart';
import 'package:kurashilog/infrastructure/parsers/timeline_parser.dart';

void main() {
  test('validation emits bounded deterministic batches', () async {
    final base = DateTime.utc(2026, 1, 1);
    final records = Stream<NormalizedRecord>.fromIterable(
      List.generate(1201, (index) {
        final start = base.add(Duration(minutes: index * 2));
        return NormalizedVisit(
          sourceKey: 'visit-$index',
          startAtUtc: start,
          endAtUtc: start.add(const Duration(minutes: 1)),
          latLng: LatLngE7(350000000 + index, 1390000000 + index),
        );
      }),
    );

    final batches = await const RecordValidator()
        .validateBatches(records, CancellationToken(), batchSize: 500)
        .toList();

    expect(batches.map((batch) => batch.totalRecords), [500, 500, 201]);
    expect(batches.map((batch) => batch.isFinal), [false, false, true]);
    expect(batches.last.processedRecords, 1201);
    expect(batches.expand((batch) => batch.visits).map((visit) => visit.sourceKey), [
      for (var index = 0; index < 1201; index++) 'visit-$index',
    ]);
  });

  test('invalid batch size is rejected before consuming input', () async {
    expect(
      const RecordValidator()
          .validateBatches(
            const Stream<NormalizedRecord>.empty(),
            CancellationToken(),
            batchSize: 0,
          )
          .drain<void>(),
      throwsArgumentError,
    );
  });
}
''', encoding='utf-8')

Path('test/application/use_cases/import_batching_test.dart').write_text(r'''import 'dart:io';

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
  test('large synthetic import crosses batches without loss or duplication', () async {
    final directory = await Directory.systemTemp.createTemp('kurashilog-batch-');
    final source = File('${directory.path}${Platform.pathSeparator}timeline.json');
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
  });

  test('parse failure after a committed-sized batch rolls everything back', () async {
    final directory = await Directory.systemTemp.createTemp('kurashilog-rollback-');
    final source = File('${directory.path}${Platform.pathSeparator}timeline.json');
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
  });
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
''', encoding='utf-8')

Path('docs/import-performance.md').write_text(r'''# Import performance and privacy contract

The production import pipeline validates and inserts records in bounded batches of 500 while one database transaction remains open. A parser, validator, database, cancellation, or analysis failure rolls the complete import back; batches are not partial-success boundaries.

## Privacy-safe measurements

Only the following aggregate values may be recorded during private-export acceptance:

- input bytes
- elapsed preview and import time
- peak working set / RSS
- normalized visit and movement counts
- total path-point count
- added visit and movement counts
- warning codes and aggregate counts

Never record JSON fragments, coordinates, place IDs, place names, exact source timestamps, file paths, or hashes that can be linked to a private export.

## Automated acceptance

Synthetic tests cross multiple 500-record boundaries, verify source order and idempotency, and force a parser failure after a full batch to prove transaction rollback. The private 223 MB export remains an environment-only final measurement and must not be committed.
''', encoding='utf-8')

Path(__file__).unlink(missing_ok=True)
