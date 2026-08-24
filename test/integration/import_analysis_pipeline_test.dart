import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/analysis/window.dart';
import 'package:kurashilog/application/use_cases/import_use_case.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';
import 'package:kurashilog/infrastructure/platform/app_platform.dart';

void main() {
  test(
    'anonymous Timeline fixture survives preview, import, analysis, reimport and DB reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'kurashilog-import-analysis-',
      );
      final databaseFile = File(
        '${directory.path}${Platform.pathSeparator}kurashilog.sqlite',
      );
      final source = File(
        '${directory.path}${Platform.pathSeparator}timeline.json',
      );
      await File(
        'test/fixtures/timeline_records_anonymized.json',
      ).copy(source.path);

      AppDatabase? database;
      addTearDown(() async {
        await database?.close();
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      database = AppDatabase(NativeDatabase(databaseFile));
      var repository = KurashilogRepositoryImpl(database);
      var analysis = AnalysisCoordinator(repository: repository);
      var useCase = ImportUseCase(
        repository: repository,
        platform: AppPlatform(),
        analysis: analysis,
      );

      final preview = await useCase.previewFile(source.path);
      expect(preview.ok, isTrue);
      expect(preview.schemaType, 'timeline-records');
      expect(preview.recordCount, greaterThan(0));
      expect(preview.minAt, isNotNull);
      expect(preview.maxAt, isNotNull);

      final progress = <ImportStage>[];
      final first = await useCase.importFile(
        source.path,
        previewWarnings: preview.warnings,
        onProgress: (value) => progress.add(value.stage),
      );
      expect(first.ok, isTrue);
      expect(first.addedVisits, greaterThan(0));
      expect(first.addedMovements, greaterThan(0));
      expect(
        progress,
        containsAll(<ImportStage>[
          ImportStage.parsing,
          ImportStage.validating,
          ImportStage.clustering,
          ImportStage.insights,
        ]),
      );

      final visitCount = await repository.countVisits();
      final movementCount = await repository.countMovements();
      expect(visitCount, first.addedVisits);
      expect(movementCount, first.addedMovements);

      final visits = await repository.allVisits();
      expect(visits, isNotEmpty);
      expect(visits.every((visit) => visit.clusterId != null), isTrue);
      expect(await repository.allClusters(), isNotEmpty);
      expect(await repository.allMonthlySummaries(), isNotEmpty);

      final latest = await repository.latestActivityAt();
      expect(latest, isNotNull);
      final firstReport = await repository.insightsForPeriod(
        computeComparisonWindow(latest!.toLocal()).periodKey,
      );
      expect(firstReport.length, lessThanOrEqualTo(5));
      expect(
        firstReport.every(
          (insight) => jsonDecode(insight.metricJson)['evidence'] is List,
        ),
        isTrue,
      );

      final completed = await repository.latestCompletedImport();
      expect(completed, isNotNull);
      expect(completed!.status, 'completed');
      expect(completed.addedVisits, visitCount);
      expect(completed.addedMovements, movementCount);

      final second = await useCase.importFile(
        source.path,
        previewWarnings: preview.warnings,
      );
      expect(second.ok, isTrue);
      expect(second.addedVisits, 0);
      expect(second.addedMovements, 0);
      expect(second.updatedVisits, 0);
      expect(second.updatedMovements, 0);
      expect(await repository.countVisits(), visitCount);
      expect(await repository.countMovements(), movementCount);

      await database.close();
      database = AppDatabase(NativeDatabase(databaseFile));
      repository = KurashilogRepositoryImpl(database);
      analysis = AnalysisCoordinator(repository: repository);
      useCase = ImportUseCase(
        repository: repository,
        platform: AppPlatform(),
        analysis: analysis,
      );

      expect(await repository.countVisits(), visitCount);
      expect(await repository.countMovements(), movementCount);
      expect(await repository.allClusters(), isNotEmpty);
      expect(await repository.allMonthlySummaries(), isNotEmpty);
      expect((await repository.latestCompletedImport())?.status, 'completed');

      final afterReopen = await useCase.importFile(source.path);
      expect(afterReopen.ok, isTrue);
      expect(afterReopen.addedVisits, 0);
      expect(afterReopen.addedMovements, 0);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
