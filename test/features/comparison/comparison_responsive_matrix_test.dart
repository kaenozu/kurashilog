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

  Future<void> pumpComparison(
    WidgetTester tester,
    ProviderContainer container, {
    required Size size,
    required ThemeMode themeMode,
    double textScale = 2,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const ComparisonScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seedLargeComparisonData(KurashilogRepository repository) async {
    final now = DateTime.now();
    final visits = <StoredVisit>[];
    var id = 0;
    for (var yearOffset = 0; yearOffset < 2; yearOffset++) {
      final year = now.year - yearOffset;
      for (var day = 1; day <= 28; day++) {
        for (var visitIndex = 0; visitIndex < 6; visitIndex++) {
          final start = DateTime.utc(year, 1, day, 8 + visitIndex);
          visits.add(
            StoredVisit(
              id: 0,
              sourceKey: 'matrix-${id++}',
              startAtUtc: start,
              endAtUtc: start.add(const Duration(minutes: 45)),
              latE7: 356812360 + visitIndex,
              lngE7: 1397671250 + visitIndex,
            ),
          );
        }
      }
    }
    await repository.insertNewRecords(visits: visits, movements: const []);
  }

  Future<void> assertNoLayoutFailure(WidgetTester tester) async {
    await tester.pump();
    final exception = tester.takeException();
    expect(exception, isNull);
  }

  group('comparison responsive accessibility matrix', () {
    final cases = <({String name, Size size, ThemeMode themeMode})>[
      (
        name: '360 light',
        size: const Size(360, 800),
        themeMode: ThemeMode.light,
      ),
      (name: '360 dark', size: const Size(360, 800), themeMode: ThemeMode.dark),
      (
        name: '412 light',
        size: const Size(412, 915),
        themeMode: ThemeMode.light,
      ),
      (name: '412 dark', size: const Size(412, 915), themeMode: ThemeMode.dark),
      (
        name: 'tablet light',
        size: const Size(800, 1280),
        themeMode: ThemeMode.light,
      ),
      (
        name: 'tablet dark',
        size: const Size(800, 1280),
        themeMode: ThemeMode.dark,
      ),
    ];

    for (final testCase in cases) {
      testWidgets('${testCase.name} renders at 200% text without overflow', (
        tester,
      ) async {
        final container = await makeContainer();
        final useCase = container.read(comparisonUseCaseProvider);
        final now = DateTime.now();
        await useCase.savePreset(
          name: 'とても長い比較名でもレイアウトが壊れず内容を確認できることを検証する保存済み比較プリセット',
          request: ComparisonRequest(
            periodA: LocalDateRange(
              startInclusive: LocalDate(now.year, 1, 1),
              endExclusive: LocalDate(now.year, 1, 29),
              timeZoneId: now.timeZoneName,
            ),
            periodB: LocalDateRange(
              startInclusive: LocalDate(now.year - 1, 1, 1),
              endExclusive: LocalDate(now.year - 1, 1, 29),
              timeZoneId: now.timeZoneName,
            ),
            alignment: ComparisonAlignment.exact,
            metrics: ComparisonScreen.supportedMetrics.toSet(),
          ),
        );

        await pumpComparison(
          tester,
          container,
          size: testCase.size,
          themeMode: testCase.themeMode,
        );

        expect(find.text('期間比較'), findsOneWidget);
        expect(find.text('比較する'), findsOneWidget);
        await assertNoLayoutFailure(tester);

        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(find.textContaining('とても長い比較名'), findsOneWidget);
        await assertNoLayoutFailure(tester);
      });
    }

    testWidgets('360px result surface handles large values at 200% text', (
      tester,
    ) async {
      final container = await makeContainer();
      await seedLargeComparisonData(container.read(repositoryProvider));

      await pumpComparison(
        tester,
        container,
        size: const Size(360, 800),
        themeMode: ThemeMode.light,
      );

      await tester.tap(find.text('今年と去年（経過日数一致）'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('比較する'));
      await tester.pumpAndSettle();

      expect(find.text('比較のまとめ'), findsOneWidget);
      expect(find.text('指標の変化'), findsOneWidget);
      await assertNoLayoutFailure(tester);

      for (var i = 0; i < 5; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -700));
        await tester.pumpAndSettle();
        await assertNoLayoutFailure(tester);
      }
    });
  });
}
