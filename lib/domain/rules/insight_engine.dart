import '../models/data_quality.dart';
import '../models/insight.dart';

/// インサイト選定エンジン（設計書 6.4）。
class InsightEngine {
  const InsightEngine();

  static const int homeMaxInsights = 3;
  static const int firstReportMaxInsights = 5;
  static const int monthStoryMaxInsights = 8;

  List<InsightData> selectForHome(InsightContext context) =>
      _selectChanges(context, homeMaxInsights);

  /// 初回Import直後の「生活まとめ5枚」。
  ///
  /// 品質、よく行った場所、最も大きい変化、行かなくなった場所、新しい場所を
  /// 優先し、同じ役割のカードを重複させない。条件不足時は無理に5枚へ水増し
  /// しない。
  List<InsightData> selectForFirstReport(InsightContext context) {
    final coverage = _coverage(context);
    final topPlace = _topPlace(context);
    final lapsed = _lapsedPlace(context);
    final newPlaces = _newPlaces(context);
    final changes = _changeCandidates(context);

    final ordered = <InsightData>[
      ...coverage,
      ...topPlace,
      ...changes.take(1),
      ...lapsed,
      ...newPlaces,
      ...changes.skip(1),
    ];
    return _takeDistinct(ordered, firstReportMaxInsights, uniqueKinds: true);
  }

  List<InsightData> selectForMonthStory(InsightContext context) =>
      _selectChanges(context, monthStoryMaxInsights);

  List<InsightData> _selectChanges(InsightContext context, int maximum) {
    if (!_allowsTrendClaims(context.quality)) return const <InsightData>[];
    return _takeDistinct(_changeCandidates(context), maximum);
  }

  List<InsightData> _changeCandidates(InsightContext context) {
    if (!_allowsTrendClaims(context.quality)) return const <InsightData>[];
    final candidates = <InsightData>[
      ..._outingFrequency(context),
      ..._travelDistance(context),
      ..._newPlaces(context),
      ..._increasedPlaceVisits(context),
      ..._returnTime(context),
      ..._holidayRadius(context),
    ];
    candidates.sort(_compareCandidates);
    return candidates;
  }

  List<InsightData> _takeDistinct(
    Iterable<InsightData> candidates,
    int maximum, {
    bool uniqueKinds = false,
  }) {
    final selected = <InsightData>[];
    final groups = <String>{};
    final kinds = <InsightKind>{};
    for (final candidate in candidates) {
      if (!groups.add(candidate.semanticGroup)) continue;
      if (uniqueKinds && !kinds.add(candidate.kind)) continue;
      selected.add(candidate);
      if (selected.length == maximum) break;
    }
    return List<InsightData>.unmodifiable(selected);
  }

  int _compareCandidates(InsightData a, InsightData b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    return a.ruleId.compareTo(b.ruleId);
  }

  bool _allowsTrendClaims(DataQuality quality) =>
      quality != DataQuality.quiteLow && quality != DataQuality.historyOnly;

  List<InsightData> _coverage(InsightContext context) {
    if (context.currentDayCount <= 0) return const <InsightData>[];
    return <InsightData>[
      InsightData(
        ruleId: 'IN-00',
        kind: InsightKind.coverage,
        groupKey: 'coverage',
        severity: context.quality.index >= DataQuality.low.index
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '記録の状態を確認しました',
        body:
            '今回の集計は${context.currentDayCount}日分です。'
            'データ品質は「${context.quality.label}」です。${context.quality.description}。',
        score: 1000,
        evidence: <InsightEvidence>[
          InsightEvidence(
            type: 'analysis-window',
            reference: 'days:${context.currentDayCount}',
          ),
        ],
        metricJson: <String, Object?>{
          'currentDayCount': context.currentDayCount,
          'quality': context.quality.name,
        },
      ),
    ];
  }

  List<InsightData> _topPlace(InsightContext context) {
    final candidates =
        context.currentClusterVisits.entries
            .where(
              (entry) =>
                  entry.value >= 2 && _isVisibleCluster(context, entry.key),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final visits = b.value.compareTo(a.value);
            return visits != 0 ? visits : a.key.compareTo(b.key);
          });
    if (candidates.isEmpty) return const <InsightData>[];
    final best = candidates.first;
    final label = _clusterLabel(context, best.key);
    return <InsightData>[
      InsightData(
        ruleId: 'IN-TOP-${best.key}',
        kind: InsightKind.topPlace,
        groupKey: 'top-place',
        severity: InsightSeverity.information,
        title: 'よく訪れた場所は「$label」です',
        body: '対象期間に$labelを${best.value}回訪れています。',
        score: 900 + best.value,
        evidence: <InsightEvidence>[
          InsightEvidence(type: 'cluster', reference: 'cluster:${best.key}'),
        ],
        metricJson: <String, Object?>{
          'clusterId': best.key,
          'visits': best.value,
        },
      ),
    ];
  }

  List<InsightData> _lapsedPlace(InsightContext context) {
    final candidates =
        context.previousClusterVisits.entries
            .where((entry) {
              if (entry.value < 3 || !_isVisibleCluster(context, entry.key)) {
                return false;
              }
              final current = context.currentClusterVisits[entry.key] ?? 0;
              return current * 3 <= entry.value;
            })
            .toList(growable: false)
          ..sort((a, b) {
            final aCurrent = context.currentClusterVisits[a.key] ?? 0;
            final bCurrent = context.currentClusterVisits[b.key] ?? 0;
            final delta = (b.value - bCurrent).compareTo(a.value - aCurrent);
            return delta != 0 ? delta : a.key.compareTo(b.key);
          });
    if (candidates.isEmpty) return const <InsightData>[];
    final best = candidates.first;
    final current = context.currentClusterVisits[best.key] ?? 0;
    final label = _clusterLabel(context, best.key);
    return <InsightData>[
      InsightData(
        ruleId: 'IN-LAPSED-${best.key}',
        kind: InsightKind.lapsedPlace,
        groupKey: 'lapsed-place',
        severity: InsightSeverity.information,
        title: '以前より訪れなくなった場所があります',
        body: '$labelへの訪問は${best.value}回から$current回になりました。',
        score: 700 + best.value - current,
        evidence: <InsightEvidence>[
          InsightEvidence(type: 'cluster', reference: 'cluster:${best.key}'),
        ],
        metricJson: <String, Object?>{
          'clusterId': best.key,
          'previous': best.value,
          'current': current,
        },
      ),
    ];
  }

  bool _isVisibleCluster(InsightContext context, int clusterId) =>
      clusterId != context.baseClusterId &&
      !context.privateClusterIds.contains(clusterId) &&
      !context.excludedClusterIds.contains(clusterId);

  String _clusterLabel(InsightContext context, int clusterId) {
    final label = context.clusterNames[clusterId]?.trim();
    return label == null || label.isEmpty ? '名前未設定の場所' : label;
  }

  List<InsightData> _outingFrequency(InsightContext context) {
    if (context.currentDayCount < 7 || context.previousDayCount < 7) {
      return const <InsightData>[];
    }
    if (context.previousOutingDays == 0) return const <InsightData>[];

    final ratio =
        (context.currentOutingDays - context.previousOutingDays) /
        context.previousOutingDays;
    if (ratio.abs() < 0.20) return const <InsightData>[];

    final delta = context.currentOutingDays - context.previousOutingDays;
    final direction = delta > 0 ? '増え' : '減り';
    return <InsightData>[
      InsightData(
        ruleId: 'IN-01',
        kind: InsightKind.changedMetric,
        groupKey: 'outing-frequency',
        severity: ratio.abs() >= 0.30
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '外出の頻度が${ratio.abs() >= 0.30 ? '大きく' : ''}変化しました',
        body:
            '外出した日が前期間より${delta.abs()}日$directionました'
            '（${context.previousOutingDays}日→${context.currentOutingDays}日）。',
        score: 70 + (ratio.abs() * 100).round(),
        evidence: const <InsightEvidence>[
          InsightEvidence(type: 'metric', reference: 'outing-days'),
        ],
        metricJson: <String, Object?>{
          'previous': context.previousOutingDays,
          'current': context.currentOutingDays,
        },
      ),
    ];
  }

  List<InsightData> _travelDistance(InsightContext context) {
    if (context.currentDayCount < 7 || context.previousDayCount < 7) {
      return const <InsightData>[];
    }
    if (context.previousDistanceM <= 0) return const <InsightData>[];

    final ratio =
        (context.currentDistanceM - context.previousDistanceM) /
        context.previousDistanceM;
    if (ratio.abs() < 0.25) return const <InsightData>[];

    final direction = ratio > 0 ? '増え' : '減り';
    return <InsightData>[
      InsightData(
        ruleId: 'IN-02',
        kind: InsightKind.changedMetric,
        groupKey: 'travel-distance',
        severity: ratio.abs() >= 0.40
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '移動量が${ratio.abs() >= 0.40 ? '大きく' : ''}変化しました',
        body:
            '移動量が前期間より${(ratio.abs() * 100).round()}%$directionています'
            '（${(context.previousDistanceM / 1000).toStringAsFixed(0)}km→'
            '${(context.currentDistanceM / 1000).toStringAsFixed(0)}km）。',
        score: 60 + (ratio.abs() * 100).round(),
        evidence: const <InsightEvidence>[
          InsightEvidence(type: 'metric', reference: 'travel-distance'),
        ],
        metricJson: <String, Object?>{
          'previousM': context.previousDistanceM,
          'currentM': context.currentDistanceM,
        },
      ),
    ];
  }

  List<InsightData> _newPlaces(InsightContext context) {
    if (context.newClusterCount < 3) return const <InsightData>[];
    return <InsightData>[
      InsightData(
        ruleId: 'IN-03',
        kind: InsightKind.newPlace,
        groupKey: 'new-places',
        severity: InsightSeverity.information,
        title: '新しい場所への訪問がありました',
        body: '新しく訪れた地点が${context.newClusterCount}か所あります。',
        score: 50 + context.newClusterCount,
        evidence: const <InsightEvidence>[
          InsightEvidence(type: 'metric', reference: 'new-cluster-count'),
        ],
        metricJson: <String, Object?>{'count': context.newClusterCount},
      ),
    ];
  }

  List<InsightData> _increasedPlaceVisits(InsightContext context) {
    InsightData? best;
    for (final entry in context.currentClusterVisits.entries) {
      final id = entry.key;
      if (!_isVisibleCluster(context, id)) continue;
      final current = entry.value;
      final previous = context.previousClusterVisits[id] ?? 0;
      if (previous < 3 || current < 3 || current < previous * 1.5) continue;

      final label = _clusterLabel(context, id);
      final candidate = InsightData(
        ruleId: 'IN-04-$id',
        kind: InsightKind.changedMetric,
        groupKey: 'increased-place-visits',
        severity: InsightSeverity.information,
        title: '$labelへの訪問が増えています',
        body: '$labelへの訪問が増えています（$previous回→$current回）。',
        score: 40 + (current / previous * 100).round(),
        evidence: <InsightEvidence>[
          InsightEvidence(type: 'cluster', reference: 'cluster:$id'),
        ],
        metricJson: <String, Object?>{'clusterId': id},
      );
      if (best == null || _compareCandidates(candidate, best) < 0) {
        best = candidate;
      }
    }
    return best == null ? const <InsightData>[] : <InsightData>[best];
  }

  List<InsightData> _returnTime(InsightContext context) {
    final current = context.currentWeekdayReturnMinutes;
    final previous = context.previousWeekdayReturnMinutes;
    if (current == null || previous == null) return const <InsightData>[];

    final difference = current - previous;
    if (difference.abs() < 30) return const <InsightData>[];
    final direction = difference > 0 ? '遅く' : '早く';
    return <InsightData>[
      InsightData(
        ruleId: 'IN-05',
        kind: InsightKind.routine,
        groupKey: 'weekday-return-time',
        severity: difference.abs() >= 60
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '平日の帰宅時間が変わりました',
        body: '平日の帰宅時刻の中央値が${difference.abs()}分$directionなっています。',
        score: 55 + difference.abs(),
        evidence: const <InsightEvidence>[
          InsightEvidence(type: 'metric', reference: 'weekday-return-time'),
        ],
        metricJson: <String, Object?>{
          'previousMinutes': previous,
          'currentMinutes': current,
        },
      ),
    ];
  }

  List<InsightData> _holidayRadius(InsightContext context) {
    final current = context.currentHolidayRadiusM;
    final previous = context.previousHolidayRadiusM;
    if (current == null || previous == null || previous <= 0) {
      return const <InsightData>[];
    }

    final ratio = (current - previous) / previous;
    if (ratio.abs() < 0.25) return const <InsightData>[];
    final direction = ratio > 0 ? '広がり' : '狭まり';
    return <InsightData>[
      InsightData(
        ruleId: 'IN-06',
        kind: InsightKind.routine,
        groupKey: 'holiday-radius',
        severity: ratio.abs() >= 0.40
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '休日の行動範囲が変わりました',
        body:
            '休日の行動範囲が$directionました'
            '（約${_distance(previous)}→約${_distance(current)}）。',
        score: 45 + (ratio.abs() * 100).round(),
        evidence: const <InsightEvidence>[
          InsightEvidence(type: 'metric', reference: 'holiday-radius'),
        ],
        metricJson: <String, Object?>{
          'previousM': previous,
          'currentM': current,
        },
      ),
    ];
  }

  String _distance(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters}m';
}
