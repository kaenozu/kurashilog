import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/application/providers.dart';
import 'package:kurashilog/application/repositories/kurashilog_repository.dart';
import 'package:kurashilog/domain/models/comparison.dart';
import 'package:kurashilog/features/comparison/comparison_screen.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';

void main() {
  Future<ProviderContainer> makeContainer() async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = KurashilogRepositoryImpl(database);
    final container = ProviderContainer(
      overrides: <Override>[repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });
    return container;
  }

  Future<void> seedData(KurashilogRepository repository) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 今年1月〜今日と、去年1月〜同じ経過日の記録を入れる。
    final visits = <StoredVisit>[];
    var index = 0;
    for (final day in [2, 5, 9, 12, 18]) {
      final date = DateTime(now.year, 1, day);
      if (date.isAfter(today)) break;
      final start = DateTime.utc(date.year, date.month, date.day, 12);
      visits.add(
        StoredVisit(
          id: 0,
          sourceKey: 'v-${index++}',
          startAtUtc: start,
          endAtUtc: start.add(const Duration(hours: 1)),
          latE7: 356812360,
          lngE7: 1397671250,
        ),
      );
    }
    for (final day in [3, 8, 15]) {
      final date = DateTime(now.year - 1, 1, day);
      final start = DateTime.utc(date.year, date.month, date.day, 12);
      visits.add(
        StoredVisit(
          id: 0,
          sourceKey: 'v-${index++}',
          startAtUtc: start,
          endAtUtc: start.add(const Duration(hours: 1)),
          latE7: 356812360,
          lngE7: 1397671250,
        ),
      );
    }
    await repository.insertNewRecords(visits: visits, movements: const []);
  }

  testWidgets('comparison screen requires both periods before running', (
    tester,
  ) async {
    final container = await makeContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ComparisonScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('期間比較'), findsOneWidget);
    expect(find.text('保存済みの比較はありません'), findsOneWidget);

    await tester.tap(find.text('比較する'));
    await tester.pump();

    expect(find.text('期間A と期間B の両方を選択してください'), findsOneWidget);
  });

  testWidgets('quick preset runs a comparison and saves it', (tester) async {
    final container = await makeContainer();
    final repository = container.read(repositoryProvider);
    await seedData(repository);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ComparisonScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // クイックプリセット「今年と去年」で両期間が入る。
    await tester.tap(find.text('今年と去年（経過日数一致）'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('比較する'));
    await tester.pumpAndSettle();

    expect(find.text('比較のまとめ'), findsOneWidget);
    expect(find.text('指標の変化'), findsOneWidget);
    expect(find.text('比較結果'), findsOneWidget);
    expect(find.text('訪問回数'), findsOneWidget);
    // 今年側の訪問があるので訪問回数メトリックが表示される。
    expect(find.textContaining('回'), findsWidgets);

    // 保存して一覧に再表示される。
    await tester.ensureVisible(find.text('この比較を保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この比較を保存'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '年初の比較');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('年初の比較'), findsOneWidget);
  });

  testWidgets('reopening a saved preset restores the request', (tester) async {
    final container = await makeContainer();
    final repository = container.read(repositoryProvider);
    await seedData(repository);
    final useCase = container.read(comparisonUseCaseProvider);

    final now = DateTime.now();
    await useCase.savePreset(
      name: '保存済み1',
      request: ComparisonRequest(
        periodA: LocalDateRange(
          startInclusive: LocalDate(now.year, 1, 1),
          endExclusive: LocalDate(now.year, 1, 20),
          timeZoneId: now.timeZoneName,
        ),
        periodB: LocalDateRange(
          startInclusive: LocalDate(now.year - 1, 1, 1),
          endExclusive: LocalDate(now.year - 1, 1, 20),
          timeZoneId: now.timeZoneName,
        ),
        alignment: ComparisonAlignment.exact,
        metrics: const {
          ComparisonMetricId.visitCount,
          ComparisonMetricId.uniquePlaces,
          ComparisonMetricId.dwellDuration,
          ComparisonMetricId.outsideHomeDays,
          ComparisonMetricId.movementDistance,
          ComparisonMetricId.movementDuration,
          ComparisonMetricId.recurringPlaceCount,
        },
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ComparisonScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('保存済み1'), findsOneWidget);

    await tester.tap(find.text('保存済み1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('比較する'));
    await tester.pumpAndSettle();

    expect(find.text('比較結果'), findsOneWidget);
  });
}
