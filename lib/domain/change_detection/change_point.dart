library;

import '../models/comparison.dart';

/// 一定窓で集計した匿名の生活特徴。
class LifeWindowSnapshot {
  const LifeWindowSnapshot({
    required this.range,
    required this.coverageRatio,
    required this.activeDays,
    required this.placeDistribution,
    required this.weekdayDistribution,
    required this.timeOfDayDistribution,
    required this.lifeRadiusM,
  });

  final LocalDateRange range;
  final double coverageRatio;
  final int activeDays;
  final Map<String, double> placeDistribution;
  final Map<String, double> weekdayDistribution;
  final Map<String, double> timeOfDayDistribution;
  final double? lifeRadiusM;
}

enum ChangeDimension { places, weekdays, timeOfDay, lifeRadius }

class ChangeEvidence {
  const ChangeEvidence({
    required this.dimension,
    required this.score,
    required this.description,
  });

  final ChangeDimension dimension;
  final double score;
  final String description;
}

class ChangePointCandidate {
  const ChangePointCandidate({
    required this.before,
    required this.after,
    required this.score,
    required this.evidence,
  });

  final LocalDateRange before;
  final LocalDateRange after;
  final double score;
  final List<ChangeEvidence> evidence;
}

/// ユーザーが確定した節目。再解析候補とは別に永続化する。
class LifeMilestone {
  const LifeMilestone({
    required this.id,
    required this.title,
    required this.range,
    required this.createdAt,
    this.note,
    this.sourceCandidateKey,
  });

  final String id;
  final String title;
  final LocalDateRange range;
  final DateTime createdAt;
  final String? note;
  final String? sourceCandidateKey;

  LifeMilestone copyWith({
    String? title,
    LocalDateRange? range,
    String? note,
  }) => LifeMilestone(
    id: id,
    title: title ?? this.title,
    range: range ?? this.range,
    createdAt: createdAt,
    note: note ?? this.note,
    sourceCandidateKey: sourceCandidateKey,
  );
}
