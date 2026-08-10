import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/application/use_cases/comparison_use_case.dart';
import 'package:kurashilog/domain/models/comparison.dart';
import 'package:kurashilog/domain/models/distance_method.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';

void main() {
  // タイムゾーン非依存にするため、記録は UTC 正午に置く。
  DateTime noon(int year, int month, int day) =>
      DateTime.utc(year, month, day, 12);

  LocalDateRange range(int sy, int sm, int sd, int ey, int em, int ed) =>
      LocalDateRange(
        startInclusive: LocalDate(sy, sm, sd),
        endExclusive: LocalDate(ey, em, ed),
        timeZoneId: 'Asia/Tokyo',
      );

  late AppDatabase database;
  late KurashilogRepositoryImpl repository;
  late ComparisonUseCase useCase;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = KurashilogRepositoryImpl(database);
    useCase = ComparisonUseCase(repository: repository);
  });

  tearDown(() => database.close());

  Future<void> insertVisit(
    String key,
    DateTime start,
    DateTime end, {
    int? clusterId,
    int latE7 = 356812360,
    int lngE7 = 1397671250,
  }) async {
    await repository.insertNewRecords(
      visits: [
        StoredVisit(
          id: 0,
          sourceKey: key,
          startAtUtc: start,
          endAtUtc: end,
          latE7: latE7,
          lngE7: lngE7,
          clusterId: clusterId,
        ),
      ],
      movements: const [],
    );
  }

  Future<void> insertMovement(
    String key,
    DateTime start,
    DateTime end, {
    int distanceM = 1000,
  }) async {
    await repository.insertNewRecords(
      visits: const [],
      movements: [
        StoredMovement(
          id: 0,
          sourceKey: key,
          startAtUtc: start,
          endAtUtc: end,
          distanceMethod: DistanceMethod.estimatedDirect,
          distanceM: distanceM,
          validDistance: true,
        ),
      ],
    );
  }

  group('ComparisonUseCase aggregation', () {
    test('aggregates visit count, unique places, dwell and distance', () async {
      await insertVisit(
        'a-v1',
        noon(2026, 1, 2),
        noon(2026, 1, 2).add(const Duration(hours: 2)),
        clusterId: 1,
      );
      await insertVisit(
        'a-v2',
        noon(2026, 1, 3),
        noon(2026, 1, 3).add(const Duration(hours: 1)),
        clusterId: 2,
      );
      await insertMovement(
        'a-m1',
        noon(2026, 1, 4),
        noon(2026, 1, 4).add(const Duration(minutes: 30)),
        distanceM: 3000,
      );
      await insertVisit(
        'b-v1',
        noon(2025, 1, 2),
        noon(2025, 1, 2).add(const Duration(hours: 1)),
        clusterId: 1,
      );

      final comparison = await useCase.run(
        ComparisonRequest(
          periodA: range(2026, 1, 1, 2026, 2, 1),
          periodB: range(2025, 1, 1, 2025, 2, 1),
          alignment: ComparisonAlignment.exact,
          metrics: const {
            ComparisonMetricId.visitCount,
            ComparisonMetricId.uniquePlaces,
            ComparisonMetricId.dwellDuration,
            ComparisonMetricId.movementDistance,
          },
        ),
      );

      final visit = comparison.metrics.firstWhere(
        (m) => m.id == ComparisonMetricId.visitCount,
      );
      expect(visit.a.raw, 2);
      expect(visit.b.raw, 1);
      expect(visit.rawDelta, 1);

      final places = comparison.metrics.firstWhere(
        (m) => m.id == ComparisonMetricId.uniquePlaces,
      );
      expect(places.a.raw, 2);
      expect(places.b.raw, 1);

      final dwell = comparison.metrics.firstWhere(
        (m) => m.id == ComparisonMetricId.dwellDuration,
      );
      expect(dwell.a.raw, 180);

      final distance = comparison.metrics.firstWhere(
        (m) => m.id == ComparisonMetricId.movementDistance,
      );
      expect(distance.a.raw, 3000);
      expect(distance.b.raw, 0);
    });

    test('separates raw and per-represented-day values', () async {
      await insertVisit(
        'a-v1',
        noon(2026, 1, 2),
        noon(2026, 1, 2).add(const Duration(hours: 1)),
        clusterId: 1,
      );
      await insertVisit(
        'a-v2',
        noon(2026, 1, 4),
        noon(2026, 1, 4).add(const Duration(hours: 1)),
        clusterId: 1,
      );
      await insertVisit(
        'b-v1',
        noon(2025, 1, 2),
        noon(2025, 1, 2).add(const Duration(hours: 1)),
        clusterId: 1,
      );

      final comparison = await useCase.run(
        ComparisonRequest(
          periodA: range(2026, 1, 1, 2026, 2, 1),
          periodB: range(2025, 1, 1, 2025, 2, 1),
          alignment: ComparisonAlignment.exact,
          metrics: const {ComparisonMetricId.visitCount},
        ),
      );

      final visit = comparison.metrics.single;
      expect(visit.a.raw, 2);
      // 記録のある日は1/2と1/4の2日。
      expect(visit.a.perRepresentedDay, 1);
      expect(comparison.coverageA.representedDays, 2);
      // B側は1件: raw=1, perDay=1。
      expect(visit.b.raw, 1);
      expect(comparison.coverageB.representedDays, 1);
    });

    test('partial-year comparison aligns to same elapsed days', () async {
      // 2026年は1/1〜31日間、2025年も同様だが simulate は exact でなく
      // sameElapsedDays: 長い方を短い方へ合わせる。
      await insertVisit(
        'a-v1',
        noon(2026, 1, 2),
        noon(2026, 1, 2).add(const Duration(hours: 1)),
      );
      await insertVisit(
        'b-v1',
        noon(2025, 1, 2),
        noon(2025, 1, 2).add(const Duration(hours: 1)),
      );

      final request = ComparisonRequest(
        periodA: range(2026, 1, 1, 2026, 2, 1),
        periodB: range(2025, 1, 1, 2025, 6, 1),
        alignment: ComparisonAlignment.sameElapsedDays,
        metrics: const {ComparisonMetricId.visitCount},
      );
      final comparison = await useCase.run(request);

      // 31日間で一致するようBの終端が調整される。
      expect(comparison.alignment.effectiveA.calendarDays, 31);
      expect(comparison.alignment.effectiveB.calendarDays, 31);
      expect(comparison.coverageB.representedDays, 1);
    });

    test('excluded clusters are never counted', () async {
      await repository.replaceAllClusters([
        StoredCluster(
          id: 0,
          stableKey: 'cluster|35681236|13976712',
          centroidLatE7: 356812360,
          centroidLngE7: 1397671250,
          radiusM: 50,
          visitCount: 1,
          dwellSeconds: 3600,
          firstAt: noon(2026, 1, 2),
          lastAt: noon(2026, 1, 2),
        ),
      ]);
      final cluster = (await repository.allClusters()).single;
      await repository.setClusterExcluded(cluster.id, true);
      await insertVisit(
        'a-v1',
        noon(2026, 1, 2),
        noon(2026, 1, 2).add(const Duration(hours: 1)),
        clusterId: cluster.id,
      );

      final comparison = await useCase.run(
        ComparisonRequest(
          periodA: range(2026, 1, 1, 2026, 2, 1),
          periodB: range(2025, 1, 1, 2025, 2, 1),
          alignment: ComparisonAlignment.exact,
          metrics: const {ComparisonMetricId.visitCount},
        ),
      );

      expect(comparison.metrics.single.a.raw, 0);
      expect(comparison.coverageA.representedDays, 0);
    });

    test('reversed request negates deltas and keeps magnitude', () async {
      await insertVisit(
        'a-v1',
        noon(2026, 1, 2),
        noon(2026, 1, 2).add(const Duration(hours: 1)),
      );
      await insertVisit(
        'b-v1',
        noon(2025, 1, 2),
        noon(2025, 1, 2).add(const Duration(hours: 3)),
      );
      await insertVisit(
        'b-v2',
        noon(2025, 1, 3),
        noon(2025, 1, 3).add(const Duration(hours: 1)),
      );

      final request = ComparisonRequest(
        periodA: range(2026, 1, 1, 2026, 2, 1),
        periodB: range(2025, 1, 1, 2025, 2, 1),
        alignment: ComparisonAlignment.exact,
        metrics: const {ComparisonMetricId.visitCount},
      );
      final forward = await useCase.run(request);
      final reversed = await useCase.run(request.reversed());

      expect(forward.metrics.single.rawDelta, -1);
      expect(reversed.metrics.single.rawDelta, 1);
      final percentage = forward.metrics.single.percentageDelta;
      expect(
        reversed.metrics.single.percentageDelta,
        percentage == null ? null : -percentage,
      );
    });

    test('empty periods yield insufficient quality', () async {
      final comparison = await useCase.run(
        ComparisonRequest(
          periodA: range(2026, 1, 1, 2026, 1, 1),
          periodB: range(2025, 1, 1, 2025, 2, 1),
          alignment: ComparisonAlignment.exact,
          metrics: const {ComparisonMetricId.visitCount},
        ),
      );
      expect(comparison.overallQuality, ComparisonQuality.insufficient);
      expect(comparison.warnings, contains(ComparisonWarningCode.emptyPeriod));
    });
  });

  group('ComparisonRequestCodec', () {
    test('round-trips a request with ranges, alignment and metrics', () {
      const codec = ComparisonRequestCodec();
      final request = ComparisonRequest(
        periodA: range(2026, 1, 1, 2026, 2, 1),
        periodB: range(2025, 3, 1, 2025, 6, 1),
        alignment: ComparisonAlignment.sameElapsedDays,
        metrics: const {
          ComparisonMetricId.visitCount,
          ComparisonMetricId.movementDistance,
        },
        excludedClusterIds: const {'cluster-a'},
      );
      final decoded = codec.decode(codec.encode(request));
      expect(decoded.periodA, request.periodA);
      expect(decoded.periodB, request.periodB);
      expect(decoded.alignment, request.alignment);
      expect(decoded.metrics, request.metrics);
      expect(decoded.excludedClusterIds, request.excludedClusterIds);
    });
  });

  group('ComparisonUseCase presets', () {
    test('saves, loads and deletes a named preset', () async {
      final request = ComparisonRequest(
        periodA: range(2026, 1, 1, 2026, 2, 1),
        periodB: range(2025, 1, 1, 2025, 2, 1),
        alignment: ComparisonAlignment.exact,
        metrics: const {ComparisonMetricId.visitCount},
      );

      final saved = await useCase.savePreset(name: '冬の比較', request: request);
      final loaded = await useCase.loadPresets();
      expect(loaded, hasLength(1));
      expect(loaded.single.name, '冬の比較');
      expect(loaded.single.request.periodA, request.periodA);
      expect(loaded.single.request.periodB, request.periodB);
      expect(loaded.single.request.alignment, request.alignment);
      expect(loaded.single.request.metrics, request.metrics);

      await useCase.deletePreset(saved.id);
      expect(await useCase.loadPresets(), isEmpty);
    });

    test('updates an existing preset and keeps creation time', () async {
      final first = await useCase.savePreset(
        name: '比較1',
        request: ComparisonRequest(
          periodA: range(2026, 1, 1, 2026, 2, 1),
          periodB: range(2025, 1, 1, 2025, 2, 1),
          alignment: ComparisonAlignment.exact,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await useCase.savePreset(
        name: '比較1（改）',
        request: ComparisonRequest(
          periodA: range(2026, 2, 1, 2026, 3, 1),
          periodB: range(2025, 2, 1, 2025, 3, 1),
          alignment: ComparisonAlignment.exact,
        ),
        existingId: first.id,
      );

      final loaded = await useCase.loadPresets();
      expect(loaded, hasLength(1));
      expect(loaded.single.name, '比較1（改）');
      expect(loaded.single.createdAt, first.createdAt);
      expect(
        loaded.single.request.periodA.startInclusive,
        LocalDate(2026, 2, 1),
      );
    });

    test('loads an empty preset list when nothing was saved', () async {
      expect(await useCase.loadPresets(), isEmpty);
    });
  });
}
