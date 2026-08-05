import 'dart:math' as math;

import 'change_point.dart';

class ChangePointPolicy {
  const ChangePointPolicy({
    this.minimumCoverage = 0.65,
    this.minimumActiveDays = 5,
    this.minimumScore = 0.30,
    this.minimumPersistentWindows = 2,
    this.mergeDistanceDays = 21,
  });

  final double minimumCoverage;
  final int minimumActiveDays;
  final double minimumScore;
  final int minimumPersistentWindows;
  final int mergeDistanceDays;
}

/// 位置履歴から人生の理由を推測せず、分布の変化だけを候補化する。
class ChangePointDetector {
  const ChangePointDetector({this.policy = const ChangePointPolicy()});

  final ChangePointPolicy policy;

  List<ChangePointCandidate> detect(List<LifeWindowSnapshot> windows) {
    if (windows.length < policy.minimumPersistentWindows + 1) {
      return const <ChangePointCandidate>[];
    }

    final sorted = [...windows]
      ..sort((a, b) => a.range.startInclusive.compareTo(b.range.startInclusive));
    final raw = <ChangePointCandidate>[];

    for (var index = 1; index < sorted.length; index++) {
      final before = sorted[index - 1];
      final after = sorted[index];
      if (!_reliable(before) || !_reliable(after)) continue;
      final evidence = _evidence(before, after);
      if (evidence.isEmpty) continue;
      final score = evidence.first.score;
      if (score < policy.minimumScore) continue;

      // 単発旅行や一時的な休暇を恒常変化と誤判定しない。
      final persistentEnd = index + policy.minimumPersistentWindows;
      if (persistentEnd > sorted.length) continue;
      final persistent = sorted
          .sublist(index, persistentEnd)
          .every((window) => _similar(after, window));
      if (!persistent) continue;

      // 1 windowだけ外れ、その後に元の生活へ戻った境界は新しい変化ではない。
      if (index >= 2 && _similar(after, sorted[index - 2])) continue;

      raw.add(
        ChangePointCandidate(
          before: before.range,
          after: after.range,
          score: score,
          evidence: List<ChangeEvidence>.unmodifiable(evidence),
        ),
      );
    }

    return _mergeNearby(raw);
  }

  bool _reliable(LifeWindowSnapshot snapshot) =>
      snapshot.coverageRatio >= policy.minimumCoverage &&
      snapshot.activeDays >= policy.minimumActiveDays;

  List<ChangeEvidence> _evidence(
    LifeWindowSnapshot before,
    LifeWindowSnapshot after,
  ) {
    final result = <ChangeEvidence>[
      ChangeEvidence(
        dimension: ChangeDimension.places,
        score: _distributionDistance(
          before.placeDistribution,
          after.placeDistribution,
        ),
        description: 'よく訪れる場所の構成が変化しています',
      ),
      ChangeEvidence(
        dimension: ChangeDimension.weekdays,
        score: _distributionDistance(
          before.weekdayDistribution,
          after.weekdayDistribution,
        ),
        description: '曜日ごとの外出構成が変化しています',
      ),
      ChangeEvidence(
        dimension: ChangeDimension.timeOfDay,
        score: _distributionDistance(
          before.timeOfDayDistribution,
          after.timeOfDayDistribution,
        ),
        description: '時間帯ごとの行動構成が変化しています',
      ),
      if (before.lifeRadiusM != null && after.lifeRadiusM != null)
        ChangeEvidence(
          dimension: ChangeDimension.lifeRadius,
          score: _relativeDistance(before.lifeRadiusM!, after.lifeRadiusM!),
          description: '生活圏の広さが変化しています',
        ),
    ]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0
            ? byScore
            : a.dimension.index.compareTo(b.dimension.index);
      });
    return result.where((item) => item.score >= 0.12).toList(growable: false);
  }

  bool _similar(LifeWindowSnapshot baseline, LifeWindowSnapshot candidate) {
    if (!_reliable(candidate)) return false;
    final distance = <double>[
      _distributionDistance(
        baseline.placeDistribution,
        candidate.placeDistribution,
      ),
      _distributionDistance(
        baseline.weekdayDistribution,
        candidate.weekdayDistribution,
      ),
      _distributionDistance(
        baseline.timeOfDayDistribution,
        candidate.timeOfDayDistribution,
      ),
    ].reduce((a, b) => math.max(a, b).toDouble());
    return distance < policy.minimumScore / 2;
  }

  double _distributionDistance(Map<String, double> a, Map<String, double> b) {
    final keys = <String>{...a.keys, ...b.keys};
    if (keys.isEmpty) return 0;
    final aTotal = a.values.fold<double>(0, (sum, value) => sum + value.abs());
    final bTotal = b.values.fold<double>(0, (sum, value) => sum + value.abs());
    if (aTotal == 0 && bTotal == 0) return 0;
    var distance = 0.0;
    for (final key in keys) {
      final av = aTotal == 0 ? 0 : (a[key] ?? 0).abs() / aTotal;
      final bv = bTotal == 0 ? 0 : (b[key] ?? 0).abs() / bTotal;
      distance += (av - bv).abs();
    }
    return (distance / 2).clamp(0, 1).toDouble();
  }

  double _relativeDistance(double a, double b) {
    final denominator = math.max(a.abs(), b.abs());
    if (denominator == 0) return 0;
    return ((a - b).abs() / denominator).clamp(0, 1).toDouble();
  }

  List<ChangePointCandidate> _mergeNearby(List<ChangePointCandidate> raw) {
    if (raw.isEmpty) return const <ChangePointCandidate>[];
    final merged = <ChangePointCandidate>[];
    for (final candidate in raw) {
      if (merged.isEmpty) {
        merged.add(candidate);
        continue;
      }
      final previous = merged.last;
      final gap = candidate.after.startInclusive.differenceInDays(
        previous.after.startInclusive,
      );
      if (gap > policy.mergeDistanceDays) {
        merged.add(candidate);
        continue;
      }
      if (candidate.score > previous.score) {
        merged[merged.length - 1] = candidate;
      }
    }
    return List<ChangePointCandidate>.unmodifiable(merged);
  }
}
