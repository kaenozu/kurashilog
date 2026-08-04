import 'dart:async';

import '../../application/models/persistence_models.dart';
import '../../application/repositories/kurashilog_repository.dart';
import 'app_database_handle.dart';
import 'kurashilog_repository_impl.dart';

/// Routes every repository operation through the reset-aware database handle.
class ResettableKurashilogRepository implements KurashilogRepository {
  ResettableKurashilogRepository(this._handle);

  static final Object _transactionRepositoryKey = Object();

  final AppDatabaseHandle _handle;

  Future<T> _run<T>(
    Future<T> Function(KurashilogRepository repository) action,
  ) {
    final transactionRepository = Zone.current[_transactionRepositoryKey];
    if (transactionRepository is KurashilogRepository) {
      return action(transactionRepository);
    }
    return _handle.run(
      (database) => action(KurashilogRepositoryImpl(database)),
    );
  }

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) {
    final transactionRepository = Zone.current[_transactionRepositoryKey];
    if (transactionRepository is KurashilogRepository) {
      return transactionRepository.runInTransaction(action);
    }

    return _handle.run((database) {
      final repository = KurashilogRepositoryImpl(database);
      return repository.runInTransaction(
        () => runZoned<Future<T>>(
          action,
          zoneValues: {_transactionRepositoryKey: repository},
        ),
      );
    });
  }

  @override
  Future<ImportedFileRecord?> latestCompletedImport() =>
      _run((repository) => repository.latestCompletedImport());

  @override
  Future<int> insertImport(ImportedFileRecord record) =>
      _run((repository) => repository.insertImport(record));

  @override
  Future<void> updateImport(ImportedFileRecord record) =>
      _run((repository) => repository.updateImport(record));

  @override
  Future<int> countVisits() =>
      _run((repository) => repository.countVisits());

  @override
  Future<int> countMovements() =>
      _run((repository) => repository.countMovements());

  @override
  Future<DateTime?> latestActivityAt() =>
      _run((repository) => repository.latestActivityAt());

  @override
  Future<DateTime?> earliestActivityAt() =>
      _run((repository) => repository.earliestActivityAt());

  @override
  Future<List<StoredVisit>> visitsInRange(
    DateTime startUtc,
    DateTime endUtc,
  ) => _run(
    (repository) => repository.visitsInRange(startUtc, endUtc),
  );

  @override
  Future<List<StoredMovement>> movementsInRange(
    DateTime startUtc,
    DateTime endUtc,
  ) => _run(
    (repository) => repository.movementsInRange(startUtc, endUtc),
  );

  @override
  Future<List<StoredVisit>> allVisits() =>
      _run((repository) => repository.allVisits());

  @override
  Future<List<StoredMovement>> allMovements() =>
      _run((repository) => repository.allMovements());

  @override
  Future<ImportDiffResult> insertNewRecords({
    required List<StoredVisit> visits,
    required List<StoredMovement> movements,
  }) => _run(
    (repository) => repository.insertNewRecords(
      visits: visits,
      movements: movements,
    ),
  );

  @override
  Future<void> assignVisitClusterIds(Map<int, int> clusterIdByVisitId) =>
      _run(
        (repository) => repository.assignVisitClusterIds(clusterIdByVisitId),
      );

  @override
  Future<void> replaceAllClusters(List<StoredCluster> clusters) =>
      _run((repository) => repository.replaceAllClusters(clusters));

  @override
  Future<List<StoredCluster>> allClusters() =>
      _run((repository) => repository.allClusters());

  @override
  Future<StoredCluster?> clusterById(int id) =>
      _run((repository) => repository.clusterById(id));

  @override
  Future<void> updateClusterLabel(int clusterId, int? labelId) =>
      _run(
        (repository) => repository.updateClusterLabel(clusterId, labelId),
      );

  @override
  Future<void> setClusterExcluded(int clusterId, bool excluded) =>
      _run(
        (repository) => repository.setClusterExcluded(clusterId, excluded),
      );

  @override
  Future<int> insertLabel(StoredLabel label) =>
      _run((repository) => repository.insertLabel(label));

  @override
  Future<void> updateLabel(StoredLabel label) =>
      _run((repository) => repository.updateLabel(label));

  @override
  Future<List<StoredLabel>> allLabels() =>
      _run((repository) => repository.allLabels());

  @override
  Future<StoredLabel?> labelById(int id) =>
      _run((repository) => repository.labelById(id));

  @override
  Future<void> upsertDailySummaries(List<DailySummaryRecord> rows) =>
      _run((repository) => repository.upsertDailySummaries(rows));

  @override
  Future<void> upsertMonthlySummaries(List<MonthlySummaryRecord> rows) =>
      _run((repository) => repository.upsertMonthlySummaries(rows));

  @override
  Future<List<DailySummaryRecord>> dailySummariesBetween(
    String startDate,
    String endDate,
  ) => _run(
    (repository) => repository.dailySummariesBetween(startDate, endDate),
  );

  @override
  Future<MonthlySummaryRecord?> monthlySummary(String yearMonth) =>
      _run((repository) => repository.monthlySummary(yearMonth));

  @override
  Future<List<MonthlySummaryRecord>> allMonthlySummaries() =>
      _run((repository) => repository.allMonthlySummaries());

  @override
  Future<void> invalidateSummariesAfter(String startDate) =>
      _run((repository) => repository.invalidateSummariesAfter(startDate));

  @override
  Future<void> replaceInsightsForPeriod(
    String periodKey,
    List<StoredInsight> insights,
  ) => _run(
    (repository) => repository.replaceInsightsForPeriod(periodKey, insights),
  );

  @override
  Future<List<StoredInsight>> insightsForPeriod(String periodKey) =>
      _run((repository) => repository.insightsForPeriod(periodKey));

  @override
  Future<AppSettingRecord?> getSetting(String key) =>
      _run((repository) => repository.getSetting(key));

  @override
  Future<void> setSetting(String key, String value) =>
      _run((repository) => repository.setSetting(key, value));

  @override
  Future<void> deleteAllUserData() => _handle.reset();
}
