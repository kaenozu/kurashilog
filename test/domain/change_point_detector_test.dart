import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/change_detection/change_point.dart';
import 'package:kurashilog/domain/change_detection/change_point_detector.dart';
import 'package:kurashilog/domain/models/comparison.dart';

void main() {
  const detector = ChangePointDetector();

  test('detects a durable change and explains the changed dimensions', () {
    final result = detector.detect(<LifeWindowSnapshot>[
      snapshot(1, places: const <String, double>{'a': 9, 'b': 1}),
      snapshot(2, places: const <String, double>{'a': 1, 'b': 9}),
      snapshot(3, places: const <String, double>{'a': 1, 'b': 9}),
    ]);

    expect(result, hasLength(1));
    expect(result.single.score, greaterThanOrEqualTo(0.3));
    expect(
      result.single.evidence.map((item) => item.dimension),
      contains(ChangeDimension.places),
    );
    expect(
      result.single.evidence.map((item) => item.description).join(' '),
      isNot(contains('引っ越し')),
    );
  });

  test('suppresses a one-window trip or vacation spike', () {
    final result = detector.detect(<LifeWindowSnapshot>[
      snapshot(1, places: const <String, double>{'home': 9, 'other': 1}),
      snapshot(2, places: const <String, double>{'home': 1, 'trip': 9}),
      snapshot(3, places: const <String, double>{'home': 9, 'other': 1}),
      snapshot(4, places: const <String, double>{'home': 9, 'other': 1}),
    ]);

    expect(result, isEmpty);
  });

  test('ignores gaps and low-coverage windows', () {
    final result = detector.detect(<LifeWindowSnapshot>[
      snapshot(1, places: const <String, double>{'a': 9, 'b': 1}),
      snapshot(
        2,
        coverage: 0.3,
        activeDays: 2,
        places: const <String, double>{'a': 1, 'b': 9},
      ),
      snapshot(3, places: const <String, double>{'a': 1, 'b': 9}),
      snapshot(4, places: const <String, double>{'a': 1, 'b': 9}),
    ]);

    expect(result, isEmpty);
  });

  test('nearby candidates are merged deterministically', () {
    const permissive = ChangePointDetector(
      policy: ChangePointPolicy(
        minimumPersistentWindows: 1,
        mergeDistanceDays: 40,
      ),
    );
    final result = permissive.detect(<LifeWindowSnapshot>[
      snapshot(1, places: const <String, double>{'a': 1}),
      snapshot(2, places: const <String, double>{'b': 1}),
      snapshot(3, places: const <String, double>{'c': 1}),
    ]);

    expect(result, hasLength(1));
    expect(result.single.after.startInclusive, LocalDate(2026, 2, 1));
  });

  test('milestone edits preserve identity and creation provenance', () {
    final original = LifeMilestone(
      id: 'milestone-1',
      title: '生活の節目',
      range: rangeForMonth(2),
      createdAt: DateTime.utc(2026, 4, 1),
      note: '確認済み',
      sourceCandidateKey: 'candidate-2026-02',
    );

    final edited = original.copyWith(title: '新しい節目', note: '編集後');

    expect(edited.id, original.id);
    expect(edited.createdAt, original.createdAt);
    expect(edited.sourceCandidateKey, original.sourceCandidateKey);
    expect(edited.title, '新しい節目');
    expect(edited.note, '編集後');
  });
}

LifeWindowSnapshot snapshot(
  int month, {
  double coverage = 0.9,
  int activeDays = 20,
  Map<String, double> places = const <String, double>{'a': 1},
  Map<String, double> weekdays = const <String, double>{'weekday': 4},
  Map<String, double> times = const <String, double>{'day': 4},
  double? radius = 10000,
}) =>
    LifeWindowSnapshot(
      range: rangeForMonth(month),
      coverageRatio: coverage,
      activeDays: activeDays,
      placeDistribution: places,
      weekdayDistribution: weekdays,
      timeOfDayDistribution: times,
      lifeRadiusM: radius,
    );

LocalDateRange rangeForMonth(int month) => LocalDateRange.month(
  year: 2026,
  month: month,
  timeZoneId: 'Asia/Tokyo',
);
