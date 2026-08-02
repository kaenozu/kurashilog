import 'package:drift/drift.dart';

import '../../application/models/persistence_models.dart';
import '../../application/repositories/kurashilog_repository.dart';
import '../../domain/models/distance_method.dart';
import '../../domain/models/lat_lng.dart';
import '../../domain/models/summaries.dart';
import 'app_database.dart';
import 'tables.dart';

class KurashilogRepositoryImpl implements KurashilogRepository {
  KurashilogRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  @override
  Future<ImportedFileRecord?> latestCompletedImport() async {
    final rows =
        await (_db.select(_db.timelineImports)
              ..where((table) => table.status.equals('completed'))
              ..orderBy([(table) => OrderingTerm.desc(table.id)])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : _importToDomain(rows.first);
  }

  @override
  Future<int> insertImport(ImportedFileRecord record) =>
      _db.into(_db.timelineImports).insert(_importInsertCompanion(record));

  @override
  Future<void> updateImport(ImportedFileRecord record) async {
    if (record.id <= 0) throw ArgumentError.value(record.id, 'record.id');
    final updated =
        await (_db.update(_db.timelineImports)
              ..where((table) => table.id.equals(record.id)))
            .write(_importUpdateCompanion(record));
    if (updated != 1) {
      throw StateError('Expected to update one import row, updated $updated');
    }
  }

  @override
  Future<int> countVisits() => _db.visits.count().getSingle();

  @override
  Future<int> countMovements() => _db.movements.count().getSingle();

  @override
  Future<DateTime?> latestActivityAt() async {
    final visitRow = await (_db.selectOnly(
      _db.visits,
    )..addColumns([_db.visits.endAtUtc.max()])).getSingle();
    final movementRow = await (_db.selectOnly(
      _db.movements,
    )..addColumns([_db.movements.endAtUtc.max()])).getSingle();
    final visit = visitRow.read(_db.visits.endAtUtc.max());
    final movement = movementRow.read(_db.movements.endAtUtc.max());
    if (visit == null) return movement;
    if (movement == null) return visit;
    return visit.isAfter(movement) ? visit : movement;
  }

  @override
  Future<DateTime?> earliestActivityAt() async {
    final visitRow = await (_db.selectOnly(
      _db.visits,
    )..addColumns([_db.visits.startAtUtc.min()])).getSingle();
    final movementRow = await (_db.selectOnly(
      _db.movements,
    )..addColumns([_db.movements.startAtUtc.min()])).getSingle();
    final visit = visitRow.read(_db.visits.startAtUtc.min());
    final movement = movementRow.read(_db.movements.startAtUtc.min());
    if (visit == null) return movement;
    if (movement == null) return visit;
    return visit.isBefore(movement) ? visit : movement;
  }

  @override
  Future<List<StoredVisit>> visitsInRange(
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final rows =
        await (_db.select(_db.visits)
              ..where(
                (table) =>
                    table.endAtUtc.isBiggerOrEqualValue(startUtc) &
                    table.startAtUtc.isSmallerThanValue(endUtc),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.startAtUtc)]))
            .get();
    return rows.map(_visitToDomain).toList();
  }

  @override
  Future<List<StoredMovement>> movementsInRange(
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final rows =
        await (_db.select(_db.movements)
              ..where(
                (table) =>
                    table.endAtUtc.isBiggerOrEqualValue(startUtc) &
                    table.startAtUtc.isSmallerThanValue(endUtc),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.startAtUtc)]))
            .get();
    return rows.map(_movementToDomain).toList();
  }

  @override
  Future<List<StoredVisit>> allVisits() async =>
      (await _db.select(_db.visits).get()).map(_visitToDomain).toList();

  @override
  Future<List<StoredMovement>> allMovements() async =>
      (await _db.select(_db.movements).get()).map(_movementToDomain).toList();

  @override
  Future<ImportDiffResult> insertNewRecords({
    required List<StoredVisit> visits,
    required List<StoredMovement> movements,
  }) {
    return _db.transaction(() async {
      final beforeVisits = await countVisits();
      final beforeMovements = await countMovements();
      await _db.batch((batch) {
        if (visits.isNotEmpty) {
          batch.insertAll(
            _db.visits,
            visits.map(_visitToDb).toList(),
            onConflict: DoNothing(target: [_db.visits.sourceKey]),
          );
        }
        if (movements.isNotEmpty) {
          batch.insertAll(
            _db.movements,
            movements.map(_movementToDb).toList(),
            onConflict: DoNothing(target: [_db.movements.sourceKey]),
          );
        }
      });
      return ImportDiffResult(
        addedVisits: await countVisits() - beforeVisits,
        addedMovements: await countMovements() - beforeMovements,
      );
    });
  }

  @override
  Future<void> assignVisitClusterIds(Map<int, int> clusterIdByVisitId) {
    return _db.transaction(() async {
      await _db.batch((batch) {
        for (final entry in clusterIdByVisitId.entries) {
          batch.update(
            _db.visits,
            VisitsCompanion(clusterId: Value(entry.value)),
            where: (table) => table.id.equals(entry.key),
          );
        }
      });
    });
  }

  @override
  Future<void> replaceAllClusters(List<StoredCluster> clusters) {
    return _db.transaction(() async {
      final existingRows = await _db.select(_db.placeClusters).get();
      final existingByKey = {
        for (final row in existingRows) row.stableKey: row,
      };

      await _db.delete(_db.placeClusters).go();
      if (clusters.isEmpty) return;

      final rows = clusters.map((cluster) {
        final existing = existingByKey[cluster.stableKey];
        return _clusterToDb(
          StoredCluster(
            id: cluster.id,
            stableKey: cluster.stableKey,
            centroidLatE7: cluster.centroidLatE7,
            centroidLngE7: cluster.centroidLngE7,
            radiusM: cluster.radiusM,
            visitCount: cluster.visitCount,
            dwellSeconds: cluster.dwellSeconds,
            firstAt: cluster.firstAt,
            lastAt: cluster.lastAt,
            labelId: existing?.labelId,
            excluded: existing?.excluded ?? false,
          ),
        );
      }).toList();
      await _db.batch((batch) => batch.insertAll(_db.placeClusters, rows));
    });
  }

  @override
  Future<List<StoredCluster>> allClusters() async {
    final query = _db.select(_db.placeClusters).join([
      leftOuterJoin(
        _db.placeLabels,
        _db.placeLabels.id.equalsExp(_db.placeClusters.labelId),
      ),
    ]);
    final rows = await query.get();
    return rows.map((row) {
      return _clusterToDomain(
        row.readTable(_db.placeClusters),
        label: row.readTableOrNull(_db.placeLabels),
      );
    }).toList();
  }

  @override
  Future<StoredCluster?> clusterById(int id) async {
    final query = _db.select(_db.placeClusters).join([
      leftOuterJoin(
        _db.placeLabels,
        _db.placeLabels.id.equalsExp(_db.placeClusters.labelId),
      ),
    ])..where(_db.placeClusters.id.equals(id));
    final rows = await query.get();
    if (rows.isEmpty) return null;
    return _clusterToDomain(
      rows.first.readTable(_db.placeClusters),
      label: rows.first.readTableOrNull(_db.placeLabels),
    );
  }

  @override
  Future<void> updateClusterLabel(int clusterId, int? labelId) async {
    final updated =
        await (_db.update(_db.placeClusters)
              ..where((table) => table.id.equals(clusterId)))
            .write(PlaceClustersCompanion(labelId: Value(labelId)));
    if (updated != 1) throw StateError('Cluster $clusterId was not found');
  }

  @override
  Future<void> setClusterExcluded(int clusterId, bool excluded) async {
    final updated =
        await (_db.update(_db.placeClusters)
              ..where((table) => table.id.equals(clusterId)))
            .write(PlaceClustersCompanion(excluded: Value(excluded)));
    if (updated != 1) throw StateError('Cluster $clusterId was not found');
  }

  @override
  Future<int> insertLabel(StoredLabel label) =>
      _db.into(_db.placeLabels).insert(_labelInsertCompanion(label));

  @override
  Future<void> updateLabel(StoredLabel label) async {
    if (label.id <= 0) throw ArgumentError.value(label.id, 'label.id');
    final updated =
        await (_db.update(_db.placeLabels)
              ..where((table) => table.id.equals(label.id)))
            .write(_labelUpdateCompanion(label));
    if (updated != 1) {
      throw StateError('Expected to update one label row, updated $updated');
    }
  }

  @override
  Future<List<StoredLabel>> allLabels() async =>
      (await _db.select(_db.placeLabels).get()).map(_labelToDomain).toList();

  @override
  Future<StoredLabel?> labelById(int id) async {
    final rows = await (_db.select(
      _db.placeLabels,
    )..where((table) => table.id.equals(id))).get();
    return rows.isEmpty ? null : _labelToDomain(rows.first);
  }

  @override
  Future<void> upsertDailySummaries(List<DailySummaryRecord> rows) async {
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.dailySummaries,
        rows.map(_dailyToDb).toList(),
      );
    });
  }

  @override
  Future<void> upsertMonthlySummaries(List<MonthlySummaryRecord> rows) async {
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.monthlySummaries,
        rows.map(_monthlyToDb).toList(),
      );
    });
  }

  @override
  Future<List<DailySummaryRecord>> dailySummariesBetween(
    String startDate,
    String endDate,
  ) async {
    final rows =
        await (_db.select(_db.dailySummaries)
              ..where(
                (table) =>
                    table.localDate.isBiggerOrEqualValue(startDate) &
                    table.localDate.isSmallerOrEqualValue(endDate),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.localDate)]))
            .get();
    return rows.map(_dailyToDomain).toList();
  }

  @override
  Future<MonthlySummaryRecord?> monthlySummary(String yearMonth) async {
    final rows = await (_db.select(
      _db.monthlySummaries,
    )..where((table) => table.yearMonth.equals(yearMonth))).get();
    return rows.isEmpty ? null : _monthlyToDomain(rows.first);
  }

  @override
  Future<List<MonthlySummaryRecord>> allMonthlySummaries() async =>
      (await _db.select(_db.monthlySummaries).get())
          .map(_monthlyToDomain)
          .toList();

  @override
  Future<void> invalidateSummariesAfter(String startDate) {
    return _db.transaction(() async {
      await (_db.delete(_db.dailySummaries)
            ..where((table) => table.localDate.isBiggerOrEqualValue(startDate)))
          .go();
      final month = startDate.length >= 7
          ? startDate.substring(0, 7)
          : startDate;
      await (_db.delete(
        _db.monthlySummaries,
      )..where((table) => table.yearMonth.isBiggerOrEqualValue(month))).go();
    });
  }

  @override
  Future<void> replaceInsightsForPeriod(
    String periodKey,
    List<StoredInsight> insights,
  ) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.insights,
      )..where((table) => table.periodKey.equals(periodKey))).go();
      if (insights.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.insights, insights.map(_insightToDb).toList());
        });
      }
    });
  }

  @override
  Future<List<StoredInsight>> insightsForPeriod(String periodKey) async {
    final rows =
        await (_db.select(_db.insights)
              ..where((table) => table.periodKey.equals(periodKey))
              ..orderBy([(table) => OrderingTerm.asc(table.id)]))
            .get();
    return rows.map(_insightToDomain).toList();
  }

  @override
  Future<AppSettingRecord?> getSetting(String key) async {
    final rows = await (_db.select(
      _db.appSettings,
    )..where((table) => table.key.equals(key))).get();
    if (rows.isEmpty) return null;
    final row = rows.first;
    return AppSettingRecord(
      key: row.key,
      value: row.value,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> setSetting(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: key,
          value: value,
          updatedAt: DateTime.now(),
        ),
      );

  @override
  Future<void> deleteAllUserData() {
    return _db.transaction(() async {
      await _db.delete(_db.insights).go();
      await _db.delete(_db.monthlySummaries).go();
      await _db.delete(_db.dailySummaries).go();
      await _db.delete(_db.placeClusters).go();
      await _db.delete(_db.placeLabels).go();
      await _db.delete(_db.movements).go();
      await _db.delete(_db.visits).go();
      await _db.delete(_db.timelineImports).go();
      await _db.delete(_db.appSettings).go();
    });
  }

  TimelineImportsCompanion _importInsertCompanion(ImportedFileRecord record) =>
      TimelineImportsCompanion.insert(
        fileHash: record.fileHash,
        schemaType: record.schemaType,
        startedAt: record.startedAt,
        completedAt: Value(record.completedAt),
        sourceMinAt: Value(record.sourceMinAt),
        sourceMaxAt: Value(record.sourceMaxAt),
        status: record.status,
        warningCount: Value(record.warningCount),
        addedVisits: Value(record.addedVisits),
        addedMovements: Value(record.addedMovements),
      );

  TimelineImportsCompanion _importUpdateCompanion(ImportedFileRecord record) =>
      TimelineImportsCompanion(
        fileHash: Value(record.fileHash),
        schemaType: Value(record.schemaType),
        startedAt: Value(record.startedAt),
        completedAt: Value(record.completedAt),
        sourceMinAt: Value(record.sourceMinAt),
        sourceMaxAt: Value(record.sourceMaxAt),
        status: Value(record.status),
        warningCount: Value(record.warningCount),
        addedVisits: Value(record.addedVisits),
        addedMovements: Value(record.addedMovements),
      );

  ImportedFileRecord _importToDomain(TimelineImportRow row) =>
      ImportedFileRecord(
        id: row.id,
        fileHash: row.fileHash,
        schemaType: row.schemaType,
        startedAt: row.startedAt,
        completedAt: row.completedAt,
        sourceMinAt: row.sourceMinAt,
        sourceMaxAt: row.sourceMaxAt,
        status: row.status,
        warningCount: row.warningCount,
        addedVisits: row.addedVisits,
        addedMovements: row.addedMovements,
      );

  VisitsCompanion _visitToDb(StoredVisit visit) => VisitsCompanion.insert(
    sourceKey: visit.sourceKey,
    startAtUtc: visit.startAtUtc,
    endAtUtc: visit.endAtUtc,
    latE7: visit.latE7,
    lngE7: visit.lngE7,
    accuracyM: Value(visit.accuracyM),
    sourceLabel: Value(visit.sourceLabel),
    clusterId: Value(visit.clusterId),
    confidence: Value(visit.confidence),
  );

  StoredVisit _visitToDomain(VisitRow row) => StoredVisit(
    id: row.id,
    sourceKey: row.sourceKey,
    startAtUtc: row.startAtUtc,
    endAtUtc: row.endAtUtc,
    latE7: row.latE7,
    lngE7: row.lngE7,
    accuracyM: row.accuracyM,
    sourceLabel: row.sourceLabel,
    clusterId: row.clusterId,
    confidence: row.confidence,
  );

  MovementsCompanion _movementToDb(StoredMovement movement) =>
      MovementsCompanion.insert(
        sourceKey: movement.sourceKey,
        startAtUtc: movement.startAtUtc,
        endAtUtc: movement.endAtUtc,
        startLatE7: Value(movement.startLatLng?.latE7),
        startLngE7: Value(movement.startLatLng?.lngE7),
        endLatE7: Value(movement.endLatLng?.latE7),
        endLngE7: Value(movement.endLatLng?.lngE7),
        distanceM: Value(movement.distanceM),
        distanceMethod: movement.distanceMethod.dbValue,
        activityType: Value(movement.activityType),
        confidence: Value(movement.confidence),
        pathJson: Value(_encodePath(movement.path)),
        validDistance: Value(movement.validDistance),
      );

  StoredMovement _movementToDomain(MovementRow row) => StoredMovement(
    id: row.id,
    sourceKey: row.sourceKey,
    startAtUtc: row.startAtUtc,
    endAtUtc: row.endAtUtc,
    distanceM: row.distanceM,
    distanceMethod: DistanceMethod.fromDb(row.distanceMethod),
    activityType: row.activityType,
    confidence: row.confidence,
    startLatLng: row.startLatE7 != null && row.startLngE7 != null
        ? LatLngE7(row.startLatE7!, row.startLngE7!)
        : null,
    endLatLng: row.endLatE7 != null && row.endLngE7 != null
        ? LatLngE7(row.endLatE7!, row.endLngE7!)
        : null,
    path: _decodePath(row.pathJson),
    validDistance: row.validDistance,
  );

  PlaceClustersCompanion _clusterToDb(StoredCluster cluster) =>
      PlaceClustersCompanion.insert(
        stableKey: cluster.stableKey,
        centroidLatE7: cluster.centroidLatE7,
        centroidLngE7: cluster.centroidLngE7,
        radiusM: cluster.radiusM,
        visitCount: cluster.visitCount,
        dwellSeconds: cluster.dwellSeconds,
        firstAt: cluster.firstAt,
        lastAt: cluster.lastAt,
        labelId: Value(cluster.labelId),
        excluded: Value(cluster.excluded),
      );

  StoredCluster _clusterToDomain(
    PlaceClusterRow cluster, {
    PlaceLabelRow? label,
  }) => StoredCluster(
    id: cluster.id,
    stableKey: cluster.stableKey,
    centroidLatE7: cluster.centroidLatE7,
    centroidLngE7: cluster.centroidLngE7,
    radiusM: cluster.radiusM,
    visitCount: cluster.visitCount,
    dwellSeconds: cluster.dwellSeconds,
    firstAt: cluster.firstAt,
    lastAt: cluster.lastAt,
    labelId: cluster.labelId,
    excluded: cluster.excluded,
    labelName: label?.displayName,
    category: label?.category,
    isBasePlace: label?.isBasePlace ?? false,
  );

  PlaceLabelsCompanion _labelInsertCompanion(StoredLabel label) =>
      PlaceLabelsCompanion.insert(
        displayName: label.displayName,
        category: Value(label.category),
        isBasePlace: Value(label.isBasePlace),
        createdAt: label.createdAt,
        updatedAt: label.updatedAt,
      );

  PlaceLabelsCompanion _labelUpdateCompanion(StoredLabel label) =>
      PlaceLabelsCompanion(
        displayName: Value(label.displayName),
        category: Value(label.category),
        isBasePlace: Value(label.isBasePlace),
        createdAt: Value(label.createdAt),
        updatedAt: Value(label.updatedAt),
      );

  StoredLabel _labelToDomain(PlaceLabelRow row) => StoredLabel(
    id: row.id,
    displayName: row.displayName,
    category: row.category,
    isBasePlace: row.isBasePlace,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  DailySummariesCompanion _dailyToDb(DailySummaryRecord summary) =>
      DailySummariesCompanion.insert(
        localDate: summary.localDate,
        outingFlag: summary.outingFlag,
        visitCount: summary.visitCount,
        clusterCount: summary.clusterCount,
        distanceM: summary.distanceM,
        distanceMethod: 'mixed',
        firstAt: Value(summary.firstAt),
        lastAt: Value(summary.lastAt),
        quality: 0,
      );

  DailySummaryRecord _dailyToDomain(DailySummaryRow row) => DailySummaryData(
    localDate: row.localDate,
    outingFlag: row.outingFlag,
    visitCount: row.visitCount,
    clusterCount: row.clusterCount,
    distanceM: row.distanceM,
    firstAt: row.firstAt,
    lastAt: row.lastAt,
  );

  MonthlySummariesCompanion _monthlyToDb(MonthlySummaryRecord summary) =>
      MonthlySummariesCompanion.insert(
        yearMonth: summary.yearMonth,
        outingDays: summary.outingDays,
        distanceM: summary.distanceM,
        uniqueClusters: summary.uniqueClusters,
        newClusters: summary.newClusters,
        maxDistanceDate: Value(summary.maxDistanceDate),
        calculatedAt: summary.calculatedAt,
        clusterIdsJson: Value(summary.clusterIds.join(',')),
      );

  MonthlySummaryRecord _monthlyToDomain(MonthlySummaryRow row) =>
      MonthlySummaryData(
        yearMonth: row.yearMonth,
        outingDays: row.outingDays,
        distanceM: row.distanceM,
        uniqueClusters: row.uniqueClusters,
        newClusters: row.newClusters,
        maxDistanceDate: row.maxDistanceDate,
        calculatedAt: row.calculatedAt,
        clusterIds: row.clusterIdsJson.isEmpty
            ? const {}
            : row.clusterIdsJson
                  .split(',')
                  .where((value) => value.isNotEmpty)
                  .map(int.parse)
                  .toSet(),
      );

  InsightsCompanion _insightToDb(StoredInsight insight) =>
      InsightsCompanion.insert(
        periodKey: insight.periodKey,
        ruleId: insight.ruleId,
        severity: insight.severity,
        title: insight.title,
        body: insight.body,
        metricJson: insight.metricJson,
        createdAt: insight.createdAt,
        dismissed: Value(insight.dismissed),
      );

  StoredInsight _insightToDomain(InsightRow row) => StoredInsight(
    id: row.id,
    periodKey: row.periodKey,
    ruleId: row.ruleId,
    severity: row.severity,
    title: row.title,
    body: row.body,
    metricJson: row.metricJson,
    createdAt: row.createdAt,
    dismissed: row.dismissed,
  );

  String _encodePath(List<LatLngE7> path) =>
      path.map((point) => '${point.latE7},${point.lngE7}').join(';');

  List<LatLngE7> _decodePath(String? value) {
    if (value == null || value.isEmpty) return const [];
    final path = <LatLngE7>[];
    for (final pair in value.split(';')) {
      final parts = pair.split(',');
      if (parts.length != 2) continue;
      final latitude = int.tryParse(parts[0]);
      final longitude = int.tryParse(parts[1]);
      if (latitude != null && longitude != null) {
        path.add(LatLngE7(latitude, longitude));
      }
    }
    return path;
  }
}
