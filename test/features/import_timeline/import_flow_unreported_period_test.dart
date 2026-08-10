import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/providers.dart';
import 'package:kurashilog/application/use_cases/import_use_case.dart';
import 'package:kurashilog/features/import_timeline/import_flow_controller.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';
import 'package:kurashilog/infrastructure/platform/app_platform.dart';

void main() {
  test(
    'preview keeps the existing latest record date for unreported-period display (AC6)',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'kurashilog-unreported-',
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
      final repository = KurashilogRepositoryImpl(database);
      final analysis = AnalysisCoordinator(repository: repository);
      final useCase = ImportUseCase(
        repository: repository,
        platform: AppPlatform(),
        analysis: analysis,
      );

      // 初回取込（この時点では未反映期間なし）。
      final firstPreview = await useCase.previewFile(source.path);
      final firstImport = await useCase.importFile(
        source.path,
        previewWarnings: firstPreview.warnings,
      );
      expect(firstImport.ok, isTrue);
      final latestAfterFirst = await repository.latestActivityAt();
      expect(latestAfterFirst, isNotNull);

      // 同じファイルを再プレビュー → 既存最新日が state に保持される。
      final container = ProviderContainer(
        overrides: <Override>[
          repositoryProvider.overrideWithValue(repository),
          importUseCaseProvider.overrideWithValue(useCase),
          analysisCoordinatorProvider.overrideWithValue(analysis),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(importFlowProvider.notifier);
      await notifier.preview(source.path);

      final state = container.read(importFlowProvider);
      expect(state.phase, ImportPhase.previewReady);
      expect(state.preview, isNotNull);
      expect(state.existingLatestAt, latestAfterFirst);
    },
  );
}
