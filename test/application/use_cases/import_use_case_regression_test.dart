import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/application/repositories/kurashilog_repository.dart';
import 'package:kurashilog/application/use_cases/import_use_case.dart';
import 'package:kurashilog/domain/models/normalized_record.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/correction_preserving_repository.dart';
import 'package:kurashilog/infrastructure/parsers/record_validator.dart';
import 'package:kurashilog/infrastructure/parsers/timeline_parser.dart';
import 'package:kurashilog/infrastructure/platform/app_platform.dart';

void main() {
  test('warning merge keeps preview-only warnings and avoids double count', () {
    final warnings = mergeImportWarnings(
      const [
        ImportWarning('PRE-001', 'プレビューだけの警告', count: 3),
        ImportWarning('DUP-001', '重複する警告'),
      ],
      const [ImportWarning('DUP-001', '重複する警告', count: 4)],
    );

    expect(warnings, hasLength(2));
    expect(
      warnings.singleWhere((warning) => warning.code == 'PRE-001').count,
      3,
    );
    expect(
      warnings.singleWhere((warning) => warning.code == 'DUP-001').count,
      4,
    );
    expect(importWarningCount(warnings), 7);
  });

  test(
    'cancellation requested during analysis rolls back imported rows',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'kurashilog-import-cancel-',
      );
      final source = File(
        '${directory.path}${Platform.pathSeparator}timeline.json',
      );
      await source.writeAsString('{}');

      final database = AppDatabase(NativeDatabase.memory());
      final repository = CorrectionPreservingRepository(database);
      final token = CancellationToken();
      final analysis = _CancellingAnalysis(
        repository: repository,
        token: token,
      );
      final useCase = ImportUseCase(
        repository: repository,
        platform: AppPlatform(),
        analysis: analysis,
        parser: const _EmptyParser(),
        validator: const _StubValidator(),
      );

      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });

      final result = await useCase.importFile(
        source.path,
        token: token,
        previewWarnings: const [
          ImportWarning('PRE-001', 'プレビューだけの警告', count: 2),
        ],
      );

      expect(result.ok, isFalse);
      expect(result.errorCode, 'IMP-005');
      expect(result.warnings.map((warning) => warning.code), [
        'PRE-001',
        'VAL-001',
      ]);
      expect(await repository.countVisits(), 0);
    },
  );
}

class _CancellingAnalysis extends AnalysisCoordinator {
  _CancellingAnalysis({
    required KurashilogRepository repository,
    required this.token,
  }) : super(repository: repository);

  final CancellationToken token;

  @override
  Future<void> rebuildAll() async {
    token.cancel();
  }
}

class _EmptyParser implements TimelineParser {
  const _EmptyParser();

  @override
  String get schemaType => 'test';

  @override
  Stream<NormalizedRecord> parse(
    Stream<List<int>> source,
    CancellationToken token,
  ) => const Stream.empty();

  @override
  Future<PreviewResult> preview(
    Stream<List<int>> source,
    CancellationToken token,
  ) async => const PreviewResult(
    schemaType: 'test',
    minAt: null,
    maxAt: null,
    approxRecordCount: 0,
  );
}

class _StubValidator extends RecordValidator {
  const _StubValidator();

  @override
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
}
