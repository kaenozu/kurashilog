/// インサイト生成の比較期間（現期間 vs 前期間）。
///
/// 設計書 7.2 の各ルールは「直近 30 日 vs 前 30 日」を基本とする。
class ComparisonWindow {
  const ComparisonWindow({
    required this.currentStart,
    required this.currentEnd,
    required this.previousStart,
    required this.previousEnd,
  });

  final DateTime currentStart;
  final DateTime currentEnd;
  final DateTime previousStart;
  final DateTime previousEnd;

  String get periodKey =>
      'win|${currentStart.toIso8601String()}|${currentEnd.toIso8601String()}';
}

/// 最新データ日を基準に 30 日ウィンドウを計算する。
///
/// 現在期間は [latestLocal] の翌 0 時を終端とする [days] 日間、
/// 前期間はその直前の [days] 日間。
ComparisonWindow computeComparisonWindow(
  DateTime latestLocal, {
  int days = 30,
}) {
  final end = DateTime(latestLocal.year, latestLocal.month, latestLocal.day)
      .add(const Duration(days: 1));
  final currentStart = end.subtract(Duration(days: days));
  final previousStart = currentStart.subtract(Duration(days: days));
  return ComparisonWindow(
    currentStart: currentStart,
    currentEnd: end,
    previousStart: previousStart,
    previousEnd: currentStart,
  );
}
