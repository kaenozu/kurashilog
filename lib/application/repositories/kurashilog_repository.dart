import '../models/persistence_models.dart';
import '../../domain/change_detection/change_point.dart';

/// 永続化の抽象リポジトリ。
abstract interface class KurashilogRepository {
  /// 複数の永続化・再集計操作を同じDBトランザクションで実行する。
  Future<T> runInTransaction<T>(Future<T> Function() action);

  Future<ImportedFileRecord?> latestCompletedImport();
  Future<ImportedFileRecord?> completedImportByHash(String fileHash);
  Future<int> insertImport(ImportedFileRecord record);
  Future<void> updateImport(ImportedFileRecord record);

  Future<int> countVisits();
  Future<int> countMovements();
  Future<DateTime?> latestActivityAt();
  Future<DateTime?> earliestActivityAt();
  Future<List<StoredVisit>> visitsInRange(DateTime startUtc, DateTime endUtc);
  Future<List<StoredMovement>> movementsInRange(
    DateTime startUtc,
    DateTime endUtc,
  );
  Future<List<StoredVisit>> allVisits();
  Future<List<StoredMovement>> allMovements();

  Future<ImportDiffResult> insertNewRecords({
    required List<StoredVisit> visits,
    required List<StoredMovement> movements,
  });

  Future<void> assignVisitClusterIds(Map<int, int> clusterIdByVisitId);

  Future<void> replaceAllClusters(List<StoredCluster> clusters);
  Future<List<StoredCluster>> allClusters();
  Future<StoredCluster?> clusterById(int id);
  Future<void> updateClusterLabel(int clusterId, int? labelId);
  Future<void> setClusterExcluded(int clusterId, bool excluded);
  Future<void> setClusterPrivacyMode(
    int clusterId,
    PlacePrivacyMode privacyMode,
  );
  Future<int> insertLabel(StoredLabel label);
  Future<void> updateLabel(StoredLabel label);
  Future<List<StoredLabel>> allLabels();
  Future<StoredLabel?> labelById(int id);

  Future<void> upsertDailySummaries(List<DailySummaryRecord> rows);
  Future<void> upsertMonthlySummaries(List<MonthlySummaryRecord> rows);
  Future<List<DailySummaryRecord>> dailySummariesBetween(
    String startDate,
    String endDate,
  );
  Future<MonthlySummaryRecord?> monthlySummary(String yearMonth);
  Future<List<MonthlySummaryRecord>> allMonthlySummaries();
  Future<void> invalidateSummariesAfter(String startDate);

  Future<void> replaceInsightsForPeriod(
    String periodKey,
    List<StoredInsight> insights,
  );
  Future<List<StoredInsight>> insightsForPeriod(String periodKey);

  Future<AppSettingRecord?> getSetting(String key);
  Future<void> setSetting(String key, String value);

  Future<void> insertMilestone(LifeMilestone milestone);
  Future<void> updateMilestone(LifeMilestone milestone);
  Future<List<LifeMilestone>> allMilestones();
  Future<void> deleteMilestone(String id);

  Future<void> deleteAllUserData();
}

class ImportDiffResult {
  const ImportDiffResult({
    required this.addedVisits,
    required this.addedMovements,
    this.updatedVisits = 0,
    this.updatedMovements = 0,
  });

  final int addedVisits;
  final int addedMovements;
  final int updatedVisits;
  final int updatedMovements;
}
