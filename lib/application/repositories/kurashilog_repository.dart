import '../models/persistence_models.dart';

/// 永続化の抽象リポジトリ。
///
/// 画面はこのインターフェースへ直接アクセスせず、ユースケース経由で操作する
/// （設計書 2.2 依存ルール）。実装は Infrastructure 層（Drift）。
abstract interface class KurashilogRepository {
  // --- インポート管理 ---
  Future<ImportedFileRecord?> latestCompletedImport();
  Future<int> insertImport(ImportedFileRecord record);
  Future<void> updateImport(ImportedFileRecord record);

  // --- 訪問・移動 ---
  Future<int> countVisits();
  Future<int> countMovements();
  Future<DateTime?> latestActivityAt();
  Future<DateTime?> earliestActivityAt();
  Future<List<StoredVisit>> visitsInRange(DateTime startUtc, DateTime endUtc);
  Future<List<StoredMovement>> movementsInRange(
      DateTime startUtc, DateTime endUtc);
  Future<List<StoredVisit>> allVisits();
  Future<List<StoredMovement>> allMovements();

  /// 差分インポート：sourceKey で照合し新規分だけ登録。成功時のみ確定。
  Future<ImportDiffResult> insertNewRecords({
    required List<StoredVisit> visits,
    required List<StoredMovement> movements,
  });

  /// クラスタ再計算後に visits.clusterId を一括更新。
  Future<void> assignVisitClusterIds(Map<int, int> clusterIdByVisitId);

  // --- クラスタ・ラベル ---
  Future<void> replaceAllClusters(List<StoredCluster> clusters);
  Future<List<StoredCluster>> allClusters();
  Future<StoredCluster?> clusterById(int id);
  Future<void> updateClusterLabel(int clusterId, int? labelId);
  Future<void> setClusterExcluded(int clusterId, bool excluded);
  Future<int> insertLabel(StoredLabel label);
  Future<void> updateLabel(StoredLabel label);
  Future<List<StoredLabel>> allLabels();
  Future<StoredLabel?> labelById(int id);

  // --- サマリー ---
  Future<void> upsertDailySummaries(List<DailySummaryRecord> rows);
  Future<void> upsertMonthlySummaries(List<MonthlySummaryRecord> rows);
  Future<List<DailySummaryRecord>> dailySummariesBetween(
      String startDate, String endDate);
  Future<MonthlySummaryRecord?> monthlySummary(String yearMonth);
  Future<List<MonthlySummaryRecord>> allMonthlySummaries();
  Future<void> invalidateSummariesAfter(String startDate);

  // --- インサイト ---
  Future<void> replaceInsightsForPeriod(
      String periodKey, List<StoredInsight> insights);
  Future<List<StoredInsight>> insightsForPeriod(String periodKey);

  // --- 設定 ---
  Future<AppSettingRecord?> getSetting(String key);
  Future<void> setSetting(String key, String value);

  // --- データ管理 ---
  Future<void> deleteAllUserData();
}

/// 差分インポートの結果。
class ImportDiffResult {
  const ImportDiffResult({
    required this.addedVisits,
    required this.addedMovements,
  });

  final int addedVisits;
  final int addedMovements;
}
