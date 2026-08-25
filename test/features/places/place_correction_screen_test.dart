import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/application/providers.dart';
import 'package:kurashilog/features/places/places_screen.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';

void main() {
  Future<({ProviderContainer container, KurashilogRepositoryImpl repository})>
  makeContainer() async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = KurashilogRepositoryImpl(database);
    final container = ProviderContainer(
      overrides: <Override>[repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });
    return (container: container, repository: repository);
  }

  StoredCluster cluster() {
    final now = DateTime.utc(2026, 8, 1);
    return StoredCluster(
      id: 1,
      stableKey: 'anonymous-place-1',
      centroidLatE7: 350000000,
      centroidLngE7: 1390000000,
      radiusM: 50,
      visitCount: 12,
      dwellSeconds: 7200,
      firstAt: now,
      lastAt: now.add(const Duration(days: 10)),
    );
  }

  Future<void> seedLabeledCluster(
    KurashilogRepositoryImpl repository, {
    PlacePrivacyMode privacyMode = PlacePrivacyMode.visible,
  }) async {
    await repository.replaceAllClusters([cluster()]);
    final now = DateTime.utc(2026, 8, 12);
    final labelId = await repository.insertLabel(
      StoredLabel(
        id: 0,
        displayName: 'テスト地点',
        category: 'leisure',
        isBasePlace: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.updateClusterLabel(1, labelId);
    await repository.setClusterPrivacyMode(1, privacyMode);
  }

  testWidgets(
    'privacy dialog persists hide-name and refreshes safe projection',
    (tester) async {
      final setup = await makeContainer();
      await seedLabeledCluster(setup.repository);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: setup.container,
          child: const MaterialApp(home: PlacesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('テスト地点'), findsWidgets);
      await tester.tap(find.byTooltip('地点の操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('プライバシー設定'));
      await tester.pumpAndSettle();

      expect(find.text('名前を非表示'), findsOneWidget);
      expect(find.textContaining('地点名とカテゴリ'), findsOneWidget);
      await tester.tap(find.text('名前を非表示'));
      await tester.pump();
      await tester.tap(find.text('適用'));
      await tester.pumpAndSettle();

      final persisted = await setup.repository.clusterById(1);
      expect(persisted?.privacyMode, PlacePrivacyMode.hideName);
      expect(find.text('非公開の場所'), findsOneWidget);
      expect(find.text('テスト地点'), findsNothing);
    },
  );

  testWidgets('excluded privacy mode can be restored to visible', (
    tester,
  ) async {
    final setup = await makeContainer();
    await seedLabeledCluster(
      setup.repository,
      privacyMode: PlacePrivacyMode.exclude,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: setup.container,
        child: const MaterialApp(home: PlacesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('分析から除外'), findsOneWidget);
    await tester.tap(find.byTooltip('地点の操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('プライバシー設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('通常表示'));
    await tester.pump();
    await tester.tap(find.text('適用'));
    await tester.pumpAndSettle();

    final persisted = await setup.repository.clusterById(1);
    expect(persisted?.privacyMode, PlacePrivacyMode.visible);
    expect(find.text('テスト地点'), findsWidgets);
  });
}
