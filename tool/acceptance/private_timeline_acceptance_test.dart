import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/use_cases/import_use_case.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';
import 'package:kurashilog/infrastructure/platform/app_platform.dart';

const _inputPath = String.fromEnvironment('KURASHILOG_PRIVATE_TIMELINE');
const _reportPath = String.fromEnvironment('KURASHILOG_ACCEPTANCE_REPORT');

void main() {
  test(
    'private Timeline preview and import complete with privacy-safe evidence',
    () async {
      final input = File(_inputPath);
      expect(
        await input.exists(),
        isTrue,
        reason: 'private input does not exist',
      );
      final inputBytes = await input.length();
      expect(inputBytes, greaterThan(0));

      final tempDirectory = await Directory.systemTemp.createTemp(
        'kurashilog-private-acceptance-',
      );
      final database = await AppDatabase.openAtPath(
        '${tempDirectory.path}${Platform.pathSeparator}acceptance.sqlite',
      );
      final repository = KurashilogRepositoryImpl(database);
      final analysis = AnalysisCoordinator(repository: repository);
      final useCase = ImportUseCase(
        repository: repository,
        platform: AppPlatform(),
        analysis: analysis,
      );

      var peakRss = ProcessInfo.currentRss;
      final sampler = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final rss = ProcessInfo.currentRss;
        if (rss > peakRss) peakRss = rss;
      });

      final progress = <String>{};
      try {
        final previewWatch = Stopwatch()..start();
        final preview = await useCase.previewFile(_inputPath);
        previewWatch.stop();
        expect(
          preview.ok,
          isTrue,
          reason: 'preview failed: ${preview.errorCode}',
        );

        final importWatch = Stopwatch()..start();
        final imported = await useCase.importFile(
          _inputPath,
          previewWarnings: preview.warnings,
          onProgress: (value) => progress.add(value.stage.name),
        );
        importWatch.stop();
        expect(
          imported.ok,
          isTrue,
          reason: 'import failed: ${imported.errorCode}',
        );

        final visits = await repository.countVisits();
        final movements = await repository.countMovements();
        final storedMovements = await repository.allMovements();
        final pathPointCount = storedMovements.fold<int>(
          0,
          (sum, movement) => sum + movement.path.length,
        );

        final reimportWatch = Stopwatch()..start();
        final reimported = await useCase.importFile(
          _inputPath,
          previewWarnings: preview.warnings,
        );
        reimportWatch.stop();
        expect(
          reimported.ok,
          isTrue,
          reason: 'reimport failed: ${reimported.errorCode}',
        );
        expect(reimported.addedVisits, 0);
        expect(reimported.addedMovements, 0);
        expect(await repository.countVisits(), visits);
        expect(await repository.countMovements(), movements);

        final warningCounts = <String, int>{};
        for (final warning in imported.warnings) {
          warningCounts.update(
            warning.code,
            (count) => count + warning.count,
            ifAbsent: () => warning.count,
          );
        }

        final report = <String, Object?>{
          'result': 'PASS',
          'generatedAt': DateTime.now().toUtc().toIso8601String(),
          'inputBytes': inputBytes,
          'schemaType': preview.schemaType,
          'previewMilliseconds': previewWatch.elapsedMilliseconds,
          'importMilliseconds': importWatch.elapsedMilliseconds,
          'reimportMilliseconds': reimportWatch.elapsedMilliseconds,
          'peakRssBytes': peakRss,
          'previewRecordCount': preview.recordCount,
          'visitCount': visits,
          'movementCount': movements,
          'pathPointCount': pathPointCount,
          'addedVisits': imported.addedVisits,
          'addedMovements': imported.addedMovements,
          'reimportAddedVisits': reimported.addedVisits,
          'reimportAddedMovements': reimported.addedMovements,
          'warningCountsByCode': warningCounts,
          'progressStages': progress.toList()..sort(),
          'privacy': <String, Object?>{
            'inputPathIncluded': false,
            'fileHashIncluded': false,
            'coordinatesIncluded': false,
            'placeNamesIncluded': false,
            'exactSourceTimestampsIncluded': false,
          },
        };
        final encoded = const JsonEncoder.withIndent('  ').convert(report);
        if (_reportPath.isNotEmpty) {
          final output = File(_reportPath);
          await output.parent.create(recursive: true);
          await output.writeAsString(encoded);
        }
        // The prefix lets the wrapper find the report without printing the
        // private input path or any source record.
        // ignore: avoid_print
        print('KURASHILOG_ACCEPTANCE_JSON=$encoded');
      } finally {
        sampler.cancel();
        await database.close();
        await tempDirectory.delete(recursive: true);
      }
    },
    skip: _inputPath.isEmpty
        ? 'Set KURASHILOG_PRIVATE_TIMELINE with --dart-define.'
        : false,
    timeout: const Timeout(Duration(minutes: 90)),
  );
}
