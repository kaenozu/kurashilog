import 'dart:math' as math;

import '../models/data_quality.dart';
import '../models/insight.dart';

/// インサイト選定エンジン（設計書 6.4）。
///
/// - 各ルールは eligible / score / messageData を返す純粋関数。
/// - サンプル不足・品質低下・除外地点の影響を事前条件で判定する。
/// - 同じ意味のルールはグループ化し、score が高い 1 件だけ表示する。
/// - severity は情報・注目の 2 段階。警告色を常用しない。
/// - 文言はテンプレート化し、原因や健康状態を断定しない。
class InsightEngine {
  const InsightEngine();

  static const int homeMaxInsights = 3;
  static const int monthStoryMaxInsights = 8;

  /// ホーム表示用。同じ意味のルールは score が高い 1 件に絞る。
  List<InsightData> selectForHome(InsightContext ctx) =>
      _select(ctx, homeMaxInsights);

  /// 月間ストーリー表示用。
  List<InsightData> selectForMonthStory(InsightContext ctx) =>
      _select(ctx, monthStoryMaxInsights);

  List<InsightData> _select(InsightContext ctx, int max) {
    final candidates = <InsightData>[
      ..._rule01(ctx),
      ..._rule02(ctx),
      ..._rule03(ctx),
      ..._rule04(ctx),
      ..._rule05(ctx),
      ..._rule06(ctx),
    ];
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(max).toList();
  }

  /// ルールごとのグループ化（同じ意味は 1 件）。
  static const Map<String, String> _ruleGroup = {
    'IN-01': 'outings',
    'IN-02': 'distance',
    'IN-03': 'newPlaces',
    'IN-04': 'clusterVisits',
    'IN-05': 'returnTime',
    'IN-06': 'radius',
  };

  // --- IN-01 外出日数 ---
  List<InsightData> _rule01(InsightContext ctx) {
    if (ctx.currentDayCount < 7 || ctx.previousDayCount < 7) return const [];
    if (ctx.previousOutingDays == 0) return const [];

    final ratio =
        (ctx.currentOutingDays - ctx.previousOutingDays) /
        ctx.previousOutingDays;
    if (ratio.abs() < 0.20) return const [];

    final delta = ctx.currentOutingDays - ctx.previousOutingDays;
    final direction = delta > 0 ? '増え' : '減り';
    final body =
        '外出した日が前期間より${delta.abs()}日$directionました（${ctx.previousOutingDays}日→${ctx.currentOutingDays}日）。';
    return [
      InsightData(
        ruleId: 'IN-01',
        severity: ratio.abs() >= 0.30
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '外出の頻度が${ratio.abs() >= 0.30 ? '大きく' : ''}変化しました',
        body: body,
        score: 70 + (ratio.abs() * 100).round(),
        metricJson: {
          'previous': ctx.previousOutingDays,
          'current': ctx.currentOutingDays,
        },
      ),
    ];
  }

  // --- IN-02 推定移動距離 ---
  List<InsightData> _rule02(InsightContext ctx) {
    if (ctx.currentDayCount < 7 || ctx.previousDayCount < 7) return const [];
    if (ctx.previousDistanceM <= 0) return const [];

    final ratio =
        (ctx.currentDistanceM - ctx.previousDistanceM) / ctx.previousDistanceM;
    if (ratio.abs() < 0.25) return const [];

    final deltaKm = (ctx.currentDistanceM - ctx.previousDistanceM) / 1000;
    final direction = deltaKm > 0 ? '増え' : '減り';
    final body =
        '移動量が前期間より${(ratio.abs() * 100).round()}%$directionています'
        '（${(ctx.previousDistanceM / 1000).toStringAsFixed(0)}km→'
        '${(ctx.currentDistanceM / 1000).toStringAsFixed(0)}km）。';
    return [
      InsightData(
        ruleId: 'IN-02',
        severity: ratio.abs() >= 0.40
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '移動量が${ratio.abs() >= 0.40 ? '大きく' : ''}変化しました',
        body: body,
        score: 60 + (ratio.abs() * 100).round(),
        metricJson: {
          'previousM': ctx.previousDistanceM,
          'currentM': ctx.currentDistanceM,
        },
      ),
    ];
  }

  // --- IN-03 新規地点 ---
  List<InsightData> _rule03(InsightContext ctx) {
    if (ctx.newClusterCount < 3) return const [];

    final body = '新しく訪れた地点が${ctx.newClusterCount}か所あります。';
    return [
      InsightData(
        ruleId: 'IN-03',
        severity: InsightSeverity.information,
        title: '新しい場所への訪問がありました',
        body: body,
        score: 50 + ctx.newClusterCount,
        metricJson: {'count': ctx.newClusterCount},
      ),
    ];
  }

  // --- IN-04 特定クラスタの訪問回数増加 ---
  List<InsightData> _rule04(InsightContext ctx) {
    InsightData? best;
    for (final entry in ctx.currentClusterVisits.entries) {
      final id = entry.key;
      final current = entry.value;
      final previous = ctx.previousClusterVisits[id] ?? 0;
      if (previous < 3 || current < 3) continue;
      if (current < previous * 1.5) continue;
      final score = 40 + (current / previous * 100).round();
      final label = ctx.clusterNames[id] ?? '地点${_clusterLabel(id)}';
      final body =
          '$label への訪問が増えています'
          '（${previous}回→$current回）。';
      final candidate = InsightData(
        ruleId: 'IN-04',
        severity: InsightSeverity.information,
        title: '$label への訪問が増えています',
        body: body,
        score: score,
        metricJson: {'clusterId': id},
      );
      if (best == null || candidate.score > best.score) best = candidate;
    }
    return best == null ? const [] : [best];
  }

  // --- IN-05 平日の帰宅時刻変化 ---
  List<InsightData> _rule05(InsightContext ctx) {
    final current = ctx.currentWeekdayReturnMinutes;
    final previous = ctx.previousWeekdayReturnMinutes;
    if (current == null || previous == null) return const [];

    final diff = current - previous;
    if (diff.abs() < 30) return const [];

    final direction = diff > 0 ? '遅く' : '早く';
    final body = '平日の帰宅が平均${diff.abs()}分$directionなっています。';
    return [
      InsightData(
        ruleId: 'IN-05',
        severity: diff.abs() >= 60
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '平日の帰宅時間が変わりました',
        body: body,
        score: 55 + diff.abs(),
        metricJson: {'previousMinutes': previous, 'currentMinutes': current},
      ),
    ];
  }

  // --- IN-06 休日の活動半径 ---
  List<InsightData> _rule06(InsightContext ctx) {
    final current = ctx.currentHolidayRadiusM;
    final previous = ctx.previousHolidayRadiusM;
    if (current == null || previous == null || previous <= 0) return const [];

    final ratio = (current - previous) / previous;
    if (ratio.abs() < 0.25) return const [];

    final direction = ratio > 0 ? '広がり' : '狭まり';
    final body =
        '休日の行動範囲が${direction}ました'
        '（約${_km(previous)}→約${_km(current)}）。';
    return [
      InsightData(
        ruleId: 'IN-06',
        severity: ratio.abs() >= 0.40
            ? InsightSeverity.attention
            : InsightSeverity.information,
        title: '休日の行動範囲が変わりました',
        body: body,
        score: 45 + (ratio.abs() * 100).round(),
        metricJson: {'previousM': previous, 'currentM': current},
      ),
    ];
  }

  String _clusterLabel(int id) => 'B'; // 表示用プレースホルダ（地点名は UI 側で解決）

  String _km(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters}m';
}
