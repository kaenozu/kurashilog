import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/providers.dart';
import 'package:kurashilog/application/use_cases/import_use_case.dart';
import 'package:kurashilog/features/import_timeline/import_flow_controller.dart';
import 'package:kurashilog/features/import_timeline/import_flow_screen.dart';
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

      final firstPreview = await useCase.previewFile(source.path);
      final firstImport = await useCase.importFile(
        source.path,
        previewWarnings: firstPreview.warnings,
      );
      expect(firstImport.ok, isTrue);
      final latestAfterFirst = await repository.latestActivityAt();
      expect(latestAfterFirst, isNotNull);

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

  testWidgets('first import display', _firstImportDisplay);
  testWidgets('equal latest hides row', _equalLatestHidesRow);
  testWidgets('newer existing hides row', _newerExistingHidesRow);
  testWidgets('same-day new data shows zero days', _sameDayShowsZeroDays);
  testWidgets('later dates show day difference', _laterDatesShowDifference);
  testWidgets('missing max hides row', _missingMaxHidesRow);
}

Future<void> _firstImportDisplay(WidgetTester tester) async {
  await _pumpPreview(
    tester,
    existingLatestAt: null,
    maxAt: DateTime(2026, 8, 10, 20),
  );
  expect(find.text('未反映期間'), findsOneWidget);
  expect(find.text('全期間（初回の取り込み）'), findsOneWidget);
}

Future<void> _equalLatestHidesRow(WidgetTester tester) async {
  final latest = DateTime(2026, 8, 10, 12);
  await _pumpPreview(tester, existingLatestAt: latest, maxAt: latest);
  expect(find.text('未反映期間'), findsNothing);
}

Future<void> _newerExistingHidesRow(WidgetTester tester) async {
  await _pumpPreview(
    tester,
    existingLatestAt: DateTime(2026, 8, 11),
    maxAt: DateTime(2026, 8, 10),
  );
  expect(find.text('未反映期間'), findsNothing);
}

Future<void> _sameDayShowsZeroDays(WidgetTester tester) async {
  await _pumpPreview(
    tester,
    existingLatestAt: DateTime(2026, 8, 10, 8),
    maxAt: DateTime(2026, 8, 10, 20),
  );
  expect(find.text('未反映期間'), findsOneWidget);
  expect(find.text('0 日'), findsOneWidget);
}

Future<void> _laterDatesShowDifference(WidgetTester tester) async {
  await _pumpPreview(
    tester,
    existingLatestAt: DateTime(2026, 8, 8, 23),
    maxAt: DateTime(2026, 8, 10, 1),
  );
  expect(find.text('未反映期間'), findsOneWidget);
  expect(find.text('2 日分（2026年8月8日 より後）'), findsOneWidget);
}

Future<void> _missingMaxHidesRow(WidgetTester tester) async {
  await _pumpPreview(
    tester,
    existingLatestAt: DateTime(2026, 8, 8),
    maxAt: null,
  );
  expect(find.text('未反映期間'), findsNothing);
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required DateTime? existingLatestAt,
  required DateTime? maxAt,
}) async {
  final preview = ImportPreview(
    ok: true,
    fileHash: 'hash',
    schemaType: 'records',
    minAt: DateTime(2026, 8, 1),
    maxAt: maxAt,
    recordCount: 10,
  );
  final state = ImportFlowState(
    phase: ImportPhase.previewReady,
    preview: preview,
    existingLatestAt: existingLatestAt,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        importFlowProvider.overrideWith(() => _PreviewStateNotifier(state)),
      ],
      child: const MaterialApp(home: ImportFlowScreen()),
    ),
  );
  await tester.pump();
}

class _PreviewStateNotifier extends ImportFlowNotifier {
  _PreviewStateNotifier(this.initialState);

  final ImportFlowState initialState;

  @override
  ImportFlowState build() => initialState;
}
