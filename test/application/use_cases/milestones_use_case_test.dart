import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/application/use_cases/milestones_use_case.dart';
import 'package:kurashilog/domain/models/comparison.dart';
import 'package:kurashilog/features/milestones/milestones_screen.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';

void main() {
  test('detects a durable synthetic change and supports ignore/milestone handoff', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = KurashilogRepositoryImpl(database);
    await _seedDurableChange(repository);
    final useCase = MilestonesUseCase(repository: repository);

    final initial = await useCase.loadReview();
    expect(initial.candidates, hasLength(1));
    final candidate = initial.candidates.single;
    expect(candidate.evidence.first.description, contains('場所'));

    final milestone = await useCase.createMilestone(
      candidate: candidate,
      title: '生活リズムの節目',
      note: '自分で確認したメモ',
    );
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
  });

  testWidgets('candidate card remains operable at 200% text on a small screen', (
    tester,
  ) async {
    final rangeA = LocalDateRange(
      startInclusive: LocalDate(2026, 1, 1),
      endExclusive: LocalDate(2026, 1, 29),
      timeZoneId: 'Asia/Tokyo',
    );
    final rangeB = LocalDateRange(
      startInclusive: LocalDate(2026, 1, 29),
      endExclusive: LocalDate(2026, 2, 26),
      timeZoneId: 'Asia/Tokyo',
    );
    final candidate = (await _candidateFromSyntheticRanges(rangeA, rangeB));

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

Future<dynamic> _candidateFromSyntheticRanges(
  LocalDateRange rangeA,
  LocalDateRange rangeB,
) async {
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
