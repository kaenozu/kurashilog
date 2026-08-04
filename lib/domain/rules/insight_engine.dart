import '../models/data_quality.dart';
import '../models/insight.dart';

/// インサイト選定エンジン（設計書 6.4）。
class InsightEngine {
  const InsightEngine();

  static const int homeMaxInsights = 3;
  static const int monthStoryMaxInsights = 8;

  List<InsightData> selectForHome(InsightContext context) =>
      _select(context, homeMaxInsights);

  List<InsightData> selectForMonthStory(InsightContext context) =>
      _select(context, monthStoryMaxInsights);

  List<InsightData> _select(InsightContext context, int maximum) {
    // 現在傾向として信頼できない品質では、断定的な変化を生成しない。
    if (context.quality == DataQuality.quiteLow ||
        context.quality == DataQuality.historyOnly) {
      return const [];
    }

    final candidates = <InsightData>[
      ..._outingFrequency(context),
      ..._travelDistance(context),
      ..._newPlaces(context),
      ..._increasedPlaceVisits(context),
      ..._returnTime(context),
      ..._holidayRadius(context),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(maximum).toList();
  }

  List<InsightData> _outingFrequency(InsightContext context) {
    if (context.currentDayCount < 7 || context.previousDayCount < 7) {
      return const [];
    }
    if (context.previousOutingDays == 0) return const [];

    final ratio =
        (context.currentOutingDays - context.previousOutingDays) /
        context.previousOutingDays;
    if (ratio.abs() < 0.20) return const [];

    final delta = context.currentOutingDays - context.previousOutingDays;
    final direction = delta > 0 ? '増え' : '減り';
    return [
      InsightData(
        ruleId: 'IN-01',
        severity: ratio.abs() >= 0.30
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '外出の頻度が${ratio.abs() >= 0.30 ? '大きく' : ''}変化しました',
        body:
            '外出した日が前期間より${delta.abs()}日$directionました'
            '（${context.previousOutingDays}日→${context.currentOutingDays}日）。',
        score: 70 + (ratio.abs() * 100).round(),
        metricJson: {
          'previous': context.previousOutingDays,
          'current': context.currentOutingDays,
        },
      ),
    ];
  }

  List<InsightData> _travelDistance(InsightContext context) {
    if (context.currentDayCount < 7 || context.previousDayCount < 7) {
      return const [];
    }
    if (context.previousDistanceM <= 0) return const [];

    final ratio =
        (context.currentDistanceM - context.previousDistanceM) /
        context.previousDistanceM;
    if (ratio.abs() < 0.25) return const [];

    final direction = ratio > 0 ? '増え' : '減り';
    return [
      InsightData(
        ruleId: 'IN-02',
        severity: ratio.abs() >= 0.40
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '移動量が${ratio.abs() >= 0.40 ? '大きく' : ''}変化しました',
        body:
            '移動量が前期間より${(ratio.abs() * 100).round()}%$directionています'
            '（${(context.previousDistanceM / 1000).toStringAsFixed(0)}km→'
            '${(context.currentDistanceM / 1000).toStringAsFixed(0)}km）。',
        score: 60 + (ratio.abs() * 100).round(),
        metricJson: {
          'previousM': context.previousDistanceM,
          'currentM': context.currentDistanceM,
        },
      ),
    ];
  }

  List<InsightData> _newPlaces(InsightContext context) {
    if (context.newClusterCount < 3) return const [];
    return [
      InsightData(
        ruleId: 'IN-03',
        severity: InsightSeverity.information,
        title: '新しい場所への訪問がありました',
        body: '新しく訪れた地点が${context.newClusterCount}か所あります。',
        score: 50 + context.newClusterCount,
        metricJson: {'count': context.newClusterCount},
      ),
    ];
  }

  List<InsightData> _increasedPlaceVisits(InsightContext context) {
    InsightData? best;
    for (final entry in context.currentClusterVisits.entries) {
      final id = entry.key;
      final current = entry.value;
      final previous = context.previousClusterVisits[id] ?? 0;
      if (previous < 3 || current < 3 || current < previous * 1.5) continue;

      final label = context.clusterNames[id] ?? '地点${_clusterLabel(id)}';
      final candidate = InsightData(
        ruleId: 'IN-04',
        severity: InsightSeverity.information,
        title: '$label への訪問が増えています',
        body: '$label への訪問が増えています（$previous回→$current回）。',
        score: 40 + (current / previous * 100).round(),
        metricJson: {'clusterId': id},
      );
      if (best == null || candidate.score > best.score) best = candidate;
    }
    return best == null ? const [] : [best];
  }

  List<InsightData> _returnTime(InsightContext context) {
    final current = context.currentWeekdayReturnMinutes;
    final previous = context.previousWeekdayReturnMinutes;
    if (current == null || previous == null) return const [];

    final difference = current - previous;
    if (difference.abs() < 30) return const [];
    final direction = difference > 0 ? '遅く' : '早く';
    return [
      InsightData(
        ruleId: 'IN-05',
        severity: difference.abs() >= 60
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '平日の帰宅時間が変わりました',
        body: '平日の帰宅時刻の中央値が${difference.abs()}分$directionなっています。',
        score: 55 + difference.abs(),
        metricJson: {'previousMinutes': previous, 'currentMinutes': current},
      ),
    ];
  }

  List<InsightData> _holidayRadius(InsightContext context) {
    final current = context.currentHolidayRadiusM;
    final previous = context.previousHolidayRadiusM;
    if (current == null || previous == null || previous <= 0) return const [];

    final ratio = (current - previous) / previous;
    if (ratio.abs() < 0.25) return const [];
    final direction = ratio > 0 ? '広がり' : '狭まり';
    return [
      InsightData(
        ruleId: 'IN-06',
        severity: ratio.abs() >= 0.40
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '休日の行動範囲が変わりました',
        body:
            '休日の行動範囲が$directionました'
            '（約${_distance(previous)}→約${_distance(current)}）。',
        score: 45 + (ratio.abs() * 100).round(),
        metricJson: {'previousM': previous, 'currentM': current},
      ),
    ];
  }

  String _clusterLabel(int id) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letters[(id - 1).clamp(0, letters.length - 1).toInt()];
  }

  String _distance(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters}m';
}
