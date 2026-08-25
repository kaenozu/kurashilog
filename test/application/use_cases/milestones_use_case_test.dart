import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/application/use_cases/milestones_use_case.dart';
import 'package:kurashilog/domain/change_detection/change_point.dart';
import 'package:kurashilog/domain/models/comparison.dart';
import 'package:kurashilog/features/milestones/milestones_screen.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';

void main() {
  test(
    'detects a durable synthetic change and supports ignore/milestone handoff',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = KurashilogRepositoryImpl(database);
      await _seedDurableChange(repository);
      final useCase = MilestonesUseCase(repository: repository);

      final initial = await useCase.loadReview();
      expect(initial.candidates, hasLength(1));
      final candidate = initial.candidates.single;
      expect(candidate.evidence.first.description, contains('場所'));

      final customRange = LocalDateRange(
        startInclusive: candidate.after.startInclusive,
        endExclusive: candidate.after.startInclusive.addDays(3),
        timeZoneId: candidate.after.timeZoneId,
      );
      final milestone = await useCase.createMilestone(
        candidate: candidate,
        title: '生活リズムの節目',
        range: customRange,
        note: '自分で確認したメモ',
      );
      expect(milestone.range, customRange);

      final request = useCase.comparisonRequestForMilestone(milestone);
      expect(request.alignment, ComparisonAlignment.milestone);
      expect(request.periodA.calendarDays, 28);
      expect(request.periodB.calendarDays, 28);
      expect(request.periodA.endExclusive, request.periodB.startInclusive);

      await useCase.ignoreCandidate(candidate);
      final afterIgnore = await useCase.loadReview();
      expect(afterIgnore.candidates, isEmpty);
      expect(afterIgnore.milestones, hasLength(1));
      expect(afterIgnore.milestones.single.title, '生活リズムの節目');

      final editedRange = LocalDateRange(
        startInclusive: milestone.range.startInclusive.addDays(1),
        endExclusive: milestone.range.endExclusive.addDays(2),
        timeZoneId: milestone.range.timeZoneId,
      );
      await useCase.updateMilestone(
        milestone: milestone,
        title: '編集した節目',
        range: editedRange,
        note: null,
      );
      final edited = (await repository.allMilestones()).single;
      expect(edited.title, '編集した節目');
      expect(edited.range, editedRange);
      expect(edited.note, isNull);
      expect(edited.sourceCandidateKey, milestone.sourceCandidateKey);

      await useCase.deleteMilestone(milestone.id);
      expect(await repository.allMilestones(), isEmpty);
    },
  );

  test('milestone survives database reopen and additional analysis rebuild', () async {
    final directory = await Directory.systemTemp.createTemp(
      'kurashilog-milestone-restart-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final dbFile = File('${directory.path}${Platform.pathSeparator}app.sqlite');

    final firstDatabase = AppDatabase(NativeDatabase(dbFile));
    final firstRepository = KurashilogRepositoryImpl(firstDatabase);
    await _seedDurableChange(firstRepository);
    final firstUseCase = MilestonesUseCase(repository: firstRepository);
    final candidate = (await firstUseCase.loadReview()).candidates.single;
    final milestone = await firstUseCase.createMilestone(
      candidate: candidate,
      title: '再起動後も残る節目',
      note: 'ユーザー固有データ',
    );
    await firstDatabase.close();

    final reopenedDatabase = AppDatabase(NativeDatabase(dbFile));
    addTearDown(reopenedDatabase.close);
    final reopenedRepository = KurashilogRepositoryImpl(reopenedDatabase);
    final afterRestart = await reopenedRepository.allMilestones();
    expect(afterRestart, hasLength(1));
    expect(afterRestart.single.id, milestone.id);
    expect(afterRestart.single.title, '再起動後も残る節目');

    final additionalAt = DateTime.utc(2026, 4, 1, 12);
    await reopenedRepository.insertNewRecords(
      visits: [
        StoredVisit(
          id: 0,
          sourceKey: 'visit-additional-import',
          startAtUtc: additionalAt,
          endAtUtc: additionalAt.add(const Duration(hours: 1)),
          latE7: 352000000,
          lngE7: 1392000000,
        ),
      ],
      movements: const [],
    );
    await AnalysisCoordinator(repository: reopenedRepository).rebuildAll();

    final afterAdditionalAnalysis = await reopenedRepository.allMilestones();
    expect(afterAdditionalAnalysis, hasLength(1));
    expect(afterAdditionalAnalysis.single.id, milestone.id);
    expect(afterAdditionalAnalysis.single.title, '再起動後も残る節目');
    expect(afterAdditionalAnalysis.single.note, 'ユーザー固有データ');
  });

  testWidgets(
    'candidate card remains operable at 200% text on a small screen',
    (tester) async {
      final candidate = await _candidateFromSyntheticData();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ChangeCandidateCard(
                  candidate: candidate,
                  onCreateMilestone: () {},
                  onIgnore: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('確率ではありません'), findsOneWidget);
      expect(find.text('節目として記録'), findsOneWidget);
      expect(find.text('今回は無視'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('milestone editor enables save after entering a title', (
    tester,
  ) async {
    final range = LocalDateRange(
      startInclusive: LocalDate(2026, 1, 1),
      endExclusive: LocalDate(2026, 1, 2),
      timeZoneId: 'Asia/Tokyo',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<MilestoneEditorResult>(
                context: context,
                builder: (_) => MilestoneEditorDialog(initialRange: range),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    FilledButton saveButton = tester.widget(
      find.widgetWithText(FilledButton, '保存'),
    );
    expect(saveButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '新しい節目');
    await tester.pump();
    saveButton = tester.widget(find.widgetWithText(FilledButton, '保存'));
    expect(saveButton.onPressed, isNotNull);
  });
}

Future<void> _seedDurableChange(KurashilogRepositoryImpl repository) async {
  final start = DateTime.utc(2026, 1, 1, 12);
  await repository.replaceAllClusters([
    StoredCluster(
      id: 1,
      stableKey: 'cluster-a',
      centroidLatE7: 350000000,
      centroidLngE7: 1390000000,
      radiusM: 100,
      visitCount: 21,
      dwellSeconds: 3600,
      firstAt: start,
      lastAt: start.add(const Duration(days: 27)),
    ),
    StoredCluster(
      id: 2,
      stableKey: 'cluster-b',
      centroidLatE7: 351000000,
      centroidLngE7: 1391000000,
      radiusM: 100,
      visitCount: 42,
      dwellSeconds: 7200,
      firstAt: start.add(const Duration(days: 28)),
      lastAt: start.add(const Duration(days: 83)),
    ),
  ]);

  final visits = <StoredVisit>[];
  for (var window = 0; window < 3; window++) {
    final clusterId = window == 0 ? 1 : 2;
    final days = [...List<int>.generate(20, (index) => index), 27];
    for (final day in days) {
      final instant = start.add(Duration(days: window * 28 + day));
      visits.add(
        StoredVisit(
          id: 0,
          sourceKey: 'visit-$window-$day',
          startAtUtc: instant,
          endAtUtc: instant.add(const Duration(hours: 1)),
          latE7: clusterId == 1 ? 350000000 : 351000000,
          lngE7: clusterId == 1 ? 1390000000 : 1391000000,
          clusterId: clusterId,
        ),
      );
    }
  }
  await repository.insertNewRecords(visits: visits, movements: const []);
}

Future<ChangePointCandidate> _candidateFromSyntheticData() async {
  final database = AppDatabase(NativeDatabase.memory());
  final repository = KurashilogRepositoryImpl(database);
  try {
    await _seedDurableChange(repository);
    final review = await MilestonesUseCase(repository: repository).loadReview();
    return review.candidates.single;
  } finally {
    await database.close();
  }
}
