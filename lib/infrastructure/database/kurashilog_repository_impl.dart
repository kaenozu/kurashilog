import 'package:drift/drift.dart';

import '../../application/models/persistence_models.dart';
import '../../application/repositories/kurashilog_repository.dart';
import '../../domain/models/distance_method.dart';
import '../../domain/models/lat_lng.dart';
import '../../domain/models/summaries.dart';
import 'app_database.dart';
import 'tables.dart';

/// Drift による [KurashilogRepository] 実装。
///
/// トランザクション境界はユースケースが指定し、ここでは
/// 「全解析成功後に単一トランザクションで本テーブルへ反映」を実現する
/// プリミティブ（[insertNewRecords] 等）を提供する。
class KurashilogRepositoryImpl implements KurashilogRepository {
  KurashilogRepositoryImpl(this._db);

  final AppDatabase _db;

  // --- インポート管理 ---

  @override
  Future<ImportedFileRecord?> latestCompletedImport() async {
    final rows = await (_db.select(_db.timelineImports)
          ..where((t) => t.status.equals('completed'))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .get();
    if (rows.isEmpty) return null;
    return _importToDomain(rows.first);
  }

  @override
  Future<int> insertImport(ImportedFileRecord record) =>
      _db.into(_db.timelineImports).insert(_importToDb(record));

  @override
  Future<void> updateImport(ImportedFileRecord record) =>
      _db.update(_db.timelineImports).replace(_importToDb(record));

  // --- 訪問・移動 ---

  @override
  Future<int> countVisits() => _db.visits.count().getSingle();

  @override
  Future<int> countMovements() => _db.movements.count().getSingle();

  @override
  Future<DateTime?> latestActivityAt() async {
    final v = await (_db.selectOnly(_db.visits)
          ..addColumns([_db.visits.endAtUtc.max()]))
        .getSingle();
    final m = await (_db.selectOnly(_db.movements)
          ..addColumns([_db.movements.endAtUtc.max()]))
        .getSingle();
    final a = v.read(_db.visits.endAtUtc);
    final b = m.read(_db.movements.endAtUtc);
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  @override
  Future<DateTime?> earliestActivityAt() async {
    final v = await (_db.selectOnly(_db.visits)
          ..addColumns([_db.visits.startAtUtc.min()]))
        .getSingle();
    final m = await (_db.selectOnly(_db.movements)
          ..addColumns([_db.movements.startAtUtc.min()]))
        .getSingle();
    final a = v.read(_db.visits.startAtUtc);
    final b = m.read(_db.movements.startAtUtc);
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  @override
  Future<List<StoredVisit>> visitsInRange(
      DateTime startUtc, DateTime endUtc) async {
    final rows = await (_db.select(_db.visits)
          ..where((t) =>
              t.endAtUtc.isBiggerOrEqualValue(startUtc) &
              t.startAtUtc.isSmallerOrEqualValue(endUtc))
          ..orderBy([(t) => OrderingTerm.asc(t.startAtUtc)]))
        .get();
    return rows.map(_visitToDomain).toList();
  }

  @override
  Future<List<StoredMovement>> movementsInRange(
      DateTime startUtc, DateTime endUtc) async {
    final rows = await (_db.select(_db.movements)
          ..where((t) =>
              t.endAtUtc.isBiggerOrEqualValue(startUtc) &
              t.startAtUtc.isSmallerOrEqualValue(endUtc))
          ..orderBy([(t) => OrderingTerm.asc(t.startAtUtc)]))
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
      final beforeV = await countVisits();
      final beforeM = await countMovements();

      final vRows = visits.map(_visitToDb).toList();
      final mRows = movements.map(_movementToDb).toList();

      await _db.batch((b) {
        b.insertAll(_db.visits, vRows,
            onConflict: DoNothing(target: [_db.visits.sourceKey]));
        b.insertAll(_db.movements, mRows,
            onConflict: DoNothing(target: [_db.movements.sourceKey]));
      });

      final afterV = await countVisits();
      final afterM = await countMovements();
      return ImportDiffResult(
        addedVisits: afterV - beforeV,
        addedMovements: afterM - beforeM,
      );
    });
  }

  @override
  Future<void> assignVisitClusterIds(Map<int, int> clusterIdByVisitId) {
    return _db.transaction(() async {
      await _db.batch((b) {
        for (final entry in clusterIdByVisitId.entries) {
          b.update(
            _db.visits,
            VisitsCompanion(clusterId: Value(entry.value)),
            where: (t) => t.id.equals(entry.key),
          );
        }
      });
    });
  }

  // --- クラスタ・ラベル ---

  @override
  Future<void> replaceAllClusters(List<StoredCluster> clusters) {
    return _db.transaction(() async {
      await _db.delete(_db.placeClusters).go();
      await _db.batch((b) {
        b.insertAll(_db.placeClusters, clusters.map(_clusterToDb).toList());
      });
    });
  }

  @override
  Future<List<StoredCluster>> allClusters() async {
    final query = _db.select(_db.placeClusters).join([
      leftOuterJoin(_db.placeLabels,
          _db.placeLabels.id.equalsExp(_db.placeClusters.labelId)),
    ]);
    final rows = await query.get();
    return rows.map((r) {
      final c = r.readTable(_db.placeClusters);
      final l = r.readTableOrNull(_db.placeLabels);
      return _clusterToDomain(c, label: l);
    }).toList();
  }

  @override
  Future<StoredCluster?> clusterById(int id) async {
    final query = _db.select(_db.placeClusters).join([
      leftOuterJoin(_db.placeLabels,
          _db.placeLabels.id.equalsExp(_db.placeClusters.labelId)),
    ])
      ..where(_db.placeClusters.id.equals(id));
    final rows = await query.get();
    if (rows.isEmpty) return null;
    final r = rows.first;
    return _clusterToDomain(
      r.readTable(_db.placeClusters),
      label: r.readTableOrNull(_db.placeLabels),
    );
  }

  @override
  Future<void> updateClusterLabel(int clusterId, int? labelId) =>
      (_db.update(_db.placeClusters)..where((t) => t.id.equals(clusterId)))
          .write(PlaceClustersCompanion(labelId: Value(labelId)));

  @override
  Future<void> setClusterExcluded(int clusterId, bool excluded) =>
      (_db.update(_db.placeClusters)..where((t) => t.id.equals(clusterId)))
          .write(PlaceClustersCompanion(excluded: Value(excluded)));

  @override
  Future<int> insertLabel(StoredLabel label) =>
      _db.into(_db.placeLabels).insert(_labelToDb(label));

  @override
  Future<void> updateLabel(StoredLabel label) =>
      _db.update(_db.placeLabels).replace(_labelToDb(label));

  @override
  Future<List<StoredLabel>> allLabels() async =>
      (await _db.select(_db.placeLabels).get()).map(_labelToDomain).toList();

  @override
  Future<StoredLabel?> labelById(int id) async {
    final rows = await (_db.select(_db.placeLabels)
          ..where((t) => t.id.equals(id)))
        .get();
    return rows.isEmpty ? null : _labelToDomain(rows.first);
  }

  // --- サマリー ---

  @override
  Future<void> upsertDailySummaries(List<DailySummaryRecord> rows) {
    return _db.transaction(() async {
      await _db.batch((b) {
        b.insertAllOnConflictUpdate(
            _db.dailySummaries, rows.map(_dailyToDb).toList());
      });
    });
  }

  @override
  Future<void> upsertMonthlySummaries(List<MonthlySummaryRecord> rows) {
    return _db.transaction(() async {
      await _db.batch((b) {
        b.insertAllOnConflictUpdate(
            _db.monthlySummaries, rows.map(_monthlyToDb).toList());
      });
    });
  }

  @override
  Future<List<DailySummaryRecord>> dailySummariesBetween(
      String startDate, String endDate) async {
    final rows = await (_db.select(_db.dailySummaries)
          ..where((t) =>
              t.localDate.isBiggerOrEqualValue(startDate) &
              t.localDate.isSmallerOrEqualValue(endDate))
          ..orderBy([(t) => OrderingTerm.asc(t.localDate)]))
        .get();
    return rows.map(_dailyToDomain).toList();
  }

  @override
  Future<MonthlySummaryRecord?> monthlySummary(String yearMonth) async {
    final rows = await (_db.select(_db.monthlySummaries)
          ..where((t) => t.yearMonth.equals(yearMonth)))
        .get();
    if (rows.isEmpty) return null;
    return _monthlyToDomain(rows.first);
  }

  @override
  Future<List<MonthlySummaryRecord>> allMonthlySummaries() async =>
      (await _db.select(_db.monthlySummaries).get()).map(_monthlyToDomain).toList();

  @override
  Future<void> invalidateSummariesAfter(String startDate) async {
    await _db.transaction(() async {
      await (_db.delete(_db.dailySummaries)
            ..where((t) => t.localDate.isBiggerOrEqualValue(startDate)))
          .go();
      final ym = startDate.length >= 7 ? startDate.substring(0, 7) : startDate;
      await (_db.delete(_db.monthlySummaries)
            ..where((t) => t.yearMonth.isBiggerOrEqualValue(ym)))
          .go();
    });
  }

  // --- インサイト ---

  @override
  Future<void> replaceInsightsForPeriod(
      String periodKey, List<StoredInsight> insights) {
    return _db.transaction(() async {
      await (_db.delete(_db.insights)..where((t) => t.periodKey.equals(periodKey)))
          .go();
      await _db.batch((b) {
        b.insertAll(_db.insights, insights.map(_insightToDb).toList());
      });
    });
  }

  @override
  Future<List<StoredInsight>> insightsForPeriod(String periodKey) async {
    final rows = await (_db.select(_db.insights)
          ..where((t) => t.periodKey.equals(periodKey))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return rows.map(_insightToDomain).toList();
  }

  // --- 設定 ---

  @override
  Future<AppSettingRecord?> getSetting(String key) async {
    final rows = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(key)))
        .get();
    if (rows.isEmpty) return null;
    final r = rows.first;
    return AppSettingRecord(
      key: r.key,
      value: r.value,
      updatedAt: r.updatedAt,
    );
  }

  @override
  Future<void> setSetting(String key, String value) =>
      _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(
        key: key,
        value: value,
        updatedAt: DateTime.now(),
      ));

  // --- データ管理 ---

  @override
  Future<void> deleteAllUserData() {
    return _db.transaction(() async {
      await _db.delete(_db.insights).go();
      await _db.delete(_db.monthlySummaries).go();
      await _db.delete(_db.dailySummaries).go();
      await _db.delete(_db.placeLabels).go();
      await _db.delete(_db.placeClusters).go();
      await _db.delete(_db.movements).go();
      await _db.delete(_db.visits).go();
      await _db.delete(_db.timelineImports).go();
      await _db.delete(_db.appSettings).go();
    });
  }

  // --- 変換 ---

  TimelineImportsCompanion _importToDb(ImportedFileRecord r) =>
      TimelineImportsCompanion.insert(
        fileHash: r.fileHash,
        schemaType: r.schemaType,
        startedAt: r.startedAt,
        completedAt: Value(r.completedAt),
        sourceMinAt: Value(r.sourceMinAt),
        sourceMaxAt: Value(r.sourceMaxAt),
        status: r.status,
        warningCount: Value(r.warningCount),
        addedVisits: Value(r.addedVisits),
        addedMovements: Value(r.addedMovements),
      );

  ImportedFileRecord _importToDomain(TimelineImportRow r) => ImportedFileRecord(
        id: r.id,
        fileHash: r.fileHash,
        schemaType: r.schemaType,
        startedAt: r.startedAt,
        completedAt: r.completedAt,
        sourceMinAt: r.sourceMinAt,
        sourceMaxAt: r.sourceMaxAt,
        status: r.status,
        warningCount: r.warningCount,
        addedVisits: r.addedVisits,
        addedMovements: r.addedMovements,
      );

  VisitsCompanion _visitToDb(StoredVisit v) => VisitsCompanion.insert(
        sourceKey: v.sourceKey,
        startAtUtc: v.startAtUtc,
        endAtUtc: v.endAtUtc,
        latE7: v.latE7,
        lngE7: v.lngE7,
        accuracyM: Value(v.accuracyM),
        sourceLabel: Value(v.sourceLabel),
        clusterId: Value(v.clusterId),
        confidence: Value(v.confidence),
      );

  StoredVisit _visitToDomain(VisitRow r) => StoredVisit(
        id: r.id,
        sourceKey: r.sourceKey,
        startAtUtc: r.startAtUtc,
        endAtUtc: r.endAtUtc,
        latE7: r.latE7,
        lngE7: r.lngE7,
        accuracyM: r.accuracyM,
        sourceLabel: r.sourceLabel,
        clusterId: r.clusterId,
        confidence: r.confidence,
      );

  MovementsCompanion _movementToDb(StoredMovement m) =>
      MovementsCompanion.insert(
        sourceKey: m.sourceKey,
        startAtUtc: m.startAtUtc,
        endAtUtc: m.endAtUtc,
        startLatE7: Value(m.startLatLng?.latE7),
        startLngE7: Value(m.startLatLng?.lngE7),
        endLatE7: Value(m.endLatLng?.latE7),
        endLngE7: Value(m.endLatLng?.lngE7),
        distanceM: Value(m.distanceM),
        distanceMethod: m.distanceMethod.dbValue,
        activityType: Value(m.activityType),
        confidence: Value(m.confidence),
        pathJson: Value(_encodePath(m.path)),
        validDistance: Value(m.validDistance),
      );

  StoredMovement _movementToDomain(MovementRow r) => StoredMovement(
        id: r.id,
        sourceKey: r.sourceKey,
        startAtUtc: r.startAtUtc,
        endAtUtc: r.endAtUtc,
        distanceM: r.distanceM,
        distanceMethod: DistanceMethod.fromDb(r.distanceMethod),
        activityType: r.activityType,
        confidence: r.confidence,
        startLatLng: r.startLatE7 != null && r.startLngE7 != null
            ? LatLngE7(r.startLatE7!, r.startLngE7!)
            : null,
        endLatLng: r.endLatE7 != null && r.endLngE7 != null
            ? LatLngE7(r.endLatE7!, r.endLngE7!)
            : null,
        path: _decodePath(r.pathJson),
        validDistance: r.validDistance,
      );

  PlaceClustersCompanion _clusterToDb(StoredCluster c) =>
      PlaceClustersCompanion.insert(
        stableKey: c.stableKey,
        centroidLatE7: c.centroidLatE7,
        centroidLngE7: c.centroidLngE7,
        radiusM: c.radiusM,
        visitCount: c.visitCount,
        dwellSeconds: c.dwellSeconds,
        firstAt: c.firstAt,
        lastAt: c.lastAt,
        labelId: Value(c.labelId),
        excluded: Value(c.excluded),
      );

  StoredCluster _clusterToDomain(PlaceClusterRow c, {PlaceLabelRow? label}) =>
      StoredCluster(
        id: c.id,
        stableKey: c.stableKey,
        centroidLatE7: c.centroidLatE7,
        centroidLngE7: c.centroidLngE7,
        radiusM: c.radiusM,
        visitCount: c.visitCount,
        dwellSeconds: c.dwellSeconds,
        firstAt: c.firstAt,
        lastAt: c.lastAt,
        labelId: c.labelId,
        excluded: c.excluded,
        labelName: label?.displayName,
        category: label?.category,
        isBasePlace: label?.isBasePlace ?? false,
      );

  PlaceLabelsCompanion _labelToDb(StoredLabel l) =>
      PlaceLabelsCompanion.insert(
        displayName: l.displayName,
        category: Value(l.category),
        isBasePlace: Value(l.isBasePlace),
        createdAt: l.createdAt,
        updatedAt: l.updatedAt,
      );

  StoredLabel _labelToDomain(PlaceLabelRow r) => StoredLabel(
        id: r.id,
        displayName: r.displayName,
        category: r.category,
        isBasePlace: r.isBasePlace,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  DailySummariesCompanion _dailyToDb(DailySummaryRecord d) =>
      DailySummariesCompanion.insert(
        localDate: d.localDate,
        outingFlag: d.outingFlag,
        visitCount: d.visitCount,
        clusterCount: d.clusterCount,
        distanceM: d.distanceM,
        distanceMethod: 'mixed',
        firstAt: Value(d.firstAt),
        lastAt: Value(d.lastAt),
        quality: 0,
      );

  DailySummaryRecord _dailyToDomain(DailySummaryRow r) => DailySummaryData(
        localDate: r.localDate,
        outingFlag: r.outingFlag,
        visitCount: r.visitCount,
        clusterCount: r.clusterCount,
        distanceM: r.distanceM,
        firstAt: r.firstAt,
        lastAt: r.lastAt,
      );

  MonthlySummariesCompanion _monthlyToDb(MonthlySummaryRecord m) =>
      MonthlySummariesCompanion.insert(
        yearMonth: m.yearMonth,
        outingDays: m.outingDays,
        distanceM: m.distanceM,
        uniqueClusters: m.uniqueClusters,
        newClusters: m.newClusters,
        maxDistanceDate: Value(m.maxDistanceDate),
        calculatedAt: m.calculatedAt,
        clusterIdsJson: Value(m.clusterIds.join(',')),
      );

  MonthlySummaryRecord _monthlyToDomain(MonthlySummaryRow r) =>
      MonthlySummaryData(
        yearMonth: r.yearMonth,
        outingDays: r.outingDays,
        distanceM: r.distanceM,
        uniqueClusters: r.uniqueClusters,
        newClusters: r.newClusters,
        maxDistanceDate: r.maxDistanceDate,
        calculatedAt: r.calculatedAt,
        clusterIds: r.clusterIdsJson.isEmpty
            ? const {}
            : r.clusterIdsJson
                .split(',')
                .where((s) => s.isNotEmpty)
                .map(int.parse)
                .toSet(),
      );

  InsightsCompanion _insightToDb(StoredInsight i) => InsightsCompanion.insert(
        periodKey: i.periodKey,
        ruleId: i.ruleId,
        severity: i.severity,
        title: i.title,
        body: i.body,
        metricJson: i.metricJson,
        createdAt: i.createdAt,
        dismissed: Value(i.dismissed),
      );

  StoredInsight _insightToDomain(InsightRow r) => StoredInsight(
        id: r.id,
        periodKey: r.periodKey,
        ruleId: r.ruleId,
        severity: r.severity,
        title: r.title,
        body: r.body,
        metricJson: r.metricJson,
        createdAt: r.createdAt,
        dismissed: r.dismissed,
      );

  String _encodePath(List<LatLngE7> path) => path
      .map((p) => '${p.latE7},${p.lngE7}')
      .join(';');

  List<LatLngE7> _decodePath(String? s) {
    if (s == null || s.isEmpty) return const [];
    final out = <LatLngE7>[];
    for (final pair in s.split(';')) {
      final parts = pair.split(',');
      if (parts.length == 2) {
        final lat = int.tryParse(parts[0]);
        final lng = int.tryParse(parts[1]);
        if (lat != null && lng != null) out.add(LatLngE7(lat, lng));
      }
    }
    return out;
  }
}
