import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/models/data_quality.dart';
import 'package:kurashilog/domain/models/insight.dart';
import 'package:kurashilog/domain/rules/insight_engine.dart';

void main() {
  const engine = InsightEngine();

  test('first report selects up to five distinct card roles', () {
    final result = engine.selectForFirstReport(
      context(
        currentClusterVisits: const <int, int>{1: 12, 2: 8, 3: 0},
        previousClusterVisits: const <int, int>{1: 4, 2: 0, 3: 9},
        clusterNames: const <int, String>{
          1: '公園',
          2: '図書館',
          3: '商店街',
        },
        newClusterCount: 4,
      ),
    );

    expect(result.length, 5);
    expect(result.first.kind, InsightKind.coverage);
    expect(result.map((item) => item.kind).toSet().length, result.length);
    expect(result.any((item) => item.kind == InsightKind.topPlace), isTrue);
    expect(result.any((item) => item.kind == InsightKind.lapsedPlace), isTrue);
    expect(result.any((item) => item.kind == InsightKind.newPlace), isTrue);
    expect(result.every((item) => item.evidence.isNotEmpty), isTrue);
  });

  test('base private and excluded clusters never appear in place cards', () {
    final result = engine.selectForFirstReport(
      context(
        baseClusterId: 1,
        privateClusterIds: const <int>{2},
        excludedClusterIds: const <int>{3},
        currentClusterVisits: const <int, int>{1: 50, 2: 40, 3: 30, 4: 4},
        previousClusterVisits: const <int, int>{1: 5, 2: 5, 3: 20, 4: 2},
        clusterNames: const <int, String>{
          1: '自宅',
          2: '病院',
          3: '非公開地点',
          4: '公園',
        },
      ),
    );

    final copy = result.map((item) => '${item.title} ${item.body}').join(' ');
    expect(copy, isNot(contains('自宅')));
    expect(copy, isNot(contains('病院')));
    expect(copy, isNot(contains('非公開地点')));
    expect(copy, contains('公園'));
    expect(
      result.expand((item) => item.evidence).map((item) => item.reference),
      isNot(contains('cluster:1')),
    );
  });

  test('ties are deterministic and prefer the lower stable cluster id', () {
    final result = engine.selectForFirstReport(
      context(
        currentClusterVisits: const <int, int>{8: 6, 3: 6},
        previousClusterVisits: const <int, int>{8: 1, 3: 1},
        clusterNames: const <int, String>{8: '候補B', 3: '候補A'},
      ),
    );

    final top = result.singleWhere((item) => item.kind == InsightKind.topPlace);
    expect(top.metricJson['clusterId'], 3);
    expect(top.title, contains('候補A'));
  });

  test('low quality keeps factual cards but suppresses trend claims', () {
    final result = engine.selectForFirstReport(
      context(
        quality: DataQuality.historyOnly,
        currentClusterVisits: const <int, int>{4: 7},
        previousClusterVisits: const <int, int>{4: 2},
        clusterNames: const <int, String>{4: '公園'},
      ),
    );

    expect(result.map((item) => item.kind), contains(InsightKind.coverage));
    expect(result.map((item) => item.kind), contains(InsightKind.topPlace));
    expect(
      result.where((item) => item.kind == InsightKind.changedMetric),
      isEmpty,
    );
    expect(engine.selectForHome(context(quality: DataQuality.historyOnly)), isEmpty);
  });

  test('missing labels use a neutral name without exposing identifiers', () {
    final result = engine.selectForFirstReport(
      context(
        currentClusterVisits: const <int, int>{99: 5},
        previousClusterVisits: const <int, int>{99: 1},
      ),
    );

    final top = result.singleWhere((item) => item.kind == InsightKind.topPlace);
    expect(top.title, contains('名前未設定の場所'));
    expect(top.title, isNot(contains('99')));
  });
}

InsightContext context({
  DataQuality quality = DataQuality.high,
  int currentDayCount = 30,
  int previousDayCount = 30,
  int currentOutingDays = 20,
  int previousOutingDays = 10,
  int currentDistanceM = 200000,
  int previousDistanceM = 100000,
  int newClusterCount = 0,
  Map<int, int> currentClusterVisits = const <int, int>{},
  Map<int, int> previousClusterVisits = const <int, int>{},
  int? baseClusterId,
  Map<int, String> clusterNames = const <int, String>{},
  Set<int> privateClusterIds = const <int>{},
  Set<int> excludedClusterIds = const <int>{},
}) {
  return InsightContext(
    quality: quality,
    currentDayCount: currentDayCount,
    previousDayCount: previousDayCount,
    currentOutingDays: currentOutingDays,
    previousOutingDays: previousOutingDays,
    currentDistanceM: currentDistanceM,
    previousDistanceM: previousDistanceM,
    newClusterCount: newClusterCount,
    currentClusterVisits: currentClusterVisits,
    previousClusterVisits: previousClusterVisits,
    baseClusterId: baseClusterId,
    baseCentroidLatE7: null,
    baseCentroidLngE7: null,
    clusterCentroids: const <int, (int, int)>{},
    clusterNames: clusterNames,
    currentWeekdayReturnMinutes: 1140,
    previousWeekdayReturnMinutes: 1080,
    currentHolidayRadiusM: 20000,
    previousHolidayRadiusM: 10000,
    privateClusterIds: privateClusterIds,
    excludedClusterIds: excludedClusterIds,
  );
}
