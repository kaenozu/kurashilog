import 'package:drift/drift.dart';

/// 取込単位（設計書 4.1 timeline_imports）。
@DataClassName('TimelineImportRow')
class TimelineImports extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileHash => text()();
  TextColumn get schemaType => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get sourceMinAt => dateTime().nullable()();
  DateTimeColumn get sourceMaxAt => dateTime().nullable()();
  TextColumn get status =>
      text()(); // processing | completed | failed | cancelled
  IntColumn get warningCount => integer().withDefault(const Constant(0))();
  IntColumn get addedVisits => integer().withDefault(const Constant(0))();
  IntColumn get addedMovements => integer().withDefault(const Constant(0))();
}

/// 訪問区間（設計書 4.1 visits）。
@DataClassName('VisitRow')
@TableIndex(name: 'visits_start_idx', columns: {#startAtUtc})
@TableIndex(name: 'visits_cluster_idx', columns: {#clusterId, #startAtUtc})
class Visits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceKey => text().unique()();
  DateTimeColumn get startAtUtc => dateTime()();
  DateTimeColumn get endAtUtc => dateTime()();
  IntColumn get latE7 => integer()();
  IntColumn get lngE7 => integer()();
  IntColumn get accuracyM => integer().nullable()();
  TextColumn get sourceLabel => text().nullable()();
  IntColumn get clusterId => integer().nullable()();
  RealColumn get confidence => real().nullable()();
}

/// 移動区間（設計書 4.1 movements）。
@DataClassName('MovementRow')
@TableIndex(name: 'movements_start_idx', columns: {#startAtUtc})
class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceKey => text().unique()();
  DateTimeColumn get startAtUtc => dateTime()();
  DateTimeColumn get endAtUtc => dateTime()();
  IntColumn get startLatE7 => integer().nullable()();
  IntColumn get startLngE7 => integer().nullable()();
  IntColumn get endLatE7 => integer().nullable()();
  IntColumn get endLngE7 => integer().nullable()();
  IntColumn get distanceM => integer().nullable()();
  TextColumn get distanceMethod => text()();
  TextColumn get activityType => text().nullable()();
  RealColumn get confidence => real().nullable()();

  /// 経路点列（"lat,lng;lat,lng" 形式）。距離の推定に使う。
  TextColumn get pathJson => text().nullable()();

  /// 日常移動集計から除外するか（異常速度など）。
  BoolColumn get validDistance => boolean().withDefault(const Constant(true))();
}

/// 頻出地点クラスタ（設計書 4.1 place_clusters）。
@DataClassName('PlaceClusterRow')
@TableIndex(name: 'clusters_stable_idx', columns: {#stableKey})
@TableIndex(name: 'clusters_last_idx', columns: {#lastAt})
class PlaceClusters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get stableKey => text().unique()();
  IntColumn get centroidLatE7 => integer()();
  IntColumn get centroidLngE7 => integer()();
  RealColumn get radiusM => real()();
  IntColumn get visitCount => integer()();
  IntColumn get dwellSeconds => integer()();
  DateTimeColumn get firstAt => dateTime()();
  DateTimeColumn get lastAt => dateTime()();
  IntColumn get labelId => integer().nullable()();
  BoolColumn get excluded => boolean().withDefault(const Constant(false))();
}

/// ユーザーラベル（設計書 4.1 place_labels）。
@DataClassName('PlaceLabelRow')
class PlaceLabels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text()();
  TextColumn get category => text().nullable()();
  BoolColumn get isBasePlace => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// 日次集計キャッシュ（設計書 4.1 daily_summaries）。
@DataClassName('DailySummaryRow')
class DailySummaries extends Table {
  TextColumn get localDate => text()(); // YYYY-MM-DD
  BoolColumn get outingFlag => boolean()();
  IntColumn get visitCount => integer()();
  IntColumn get clusterCount => integer()();
  IntColumn get distanceM => integer()();
  TextColumn get distanceMethod => text()();
  DateTimeColumn get firstAt => dateTime().nullable()();
  DateTimeColumn get lastAt => dateTime().nullable()();
  IntColumn get quality => integer()();

  @override
  Set<Column> get primaryKey => {localDate};
}

/// 月次集計キャッシュ（設計書 4.1 monthly_summaries）。
@DataClassName('MonthlySummaryRow')
class MonthlySummaries extends Table {
  TextColumn get yearMonth => text()(); // YYYY-MM
  IntColumn get outingDays => integer()();
  IntColumn get distanceM => integer()();
  IntColumn get uniqueClusters => integer()();
  IntColumn get newClusters => integer()();
  TextColumn get maxDistanceDate => text().nullable()();
  DateTimeColumn get calculatedAt => dateTime()();

  /// 当月に訪問のあったクラスタ ID 一覧（前月比の新規地点算出用）。
  TextColumn get clusterIdsJson => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {yearMonth};
}

/// 表示用インサイト（設計書 4.1 insights）。
@DataClassName('InsightRow')
@TableIndex(name: 'insights_period_idx', columns: {#periodKey, #ruleId})
class Insights extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get periodKey => text()();
  TextColumn get ruleId => text()();
  TextColumn get severity => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get metricJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {periodKey, ruleId},
  ];
}

/// アプリ設定（設計書 4.1 app_settings）。
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
