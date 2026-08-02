/// アプリケーション層で使う永続化データ型（Drift 非依存）。
///
/// Domain 層の純粋性を保つため、リポジトリ境界ではこれらの型をやりとりし、
/// 実装（Infrastructure）側で Drift 行へ変換する。
library;

import '../../domain/models/distance_method.dart';
import '../../domain/models/lat_lng.dart';
import '../../domain/models/summaries.dart';

class StoredVisit {
  const StoredVisit({
    required this.id,
    required this.sourceKey,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.latE7,
    required this.lngE7,
    this.accuracyM,
    this.sourceLabel,
    this.clusterId,
    this.confidence,
  });

  final int id;
  final String sourceKey;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final int latE7;
  final int lngE7;
  final int? accuracyM;
  final String? sourceLabel;
  final int? clusterId;
  final double? confidence;

  LatLngE7 get latLng => LatLngE7(latE7, lngE7);
}

class StoredMovement {
  const StoredMovement({
    required this.id,
    required this.sourceKey,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.distanceMethod,
    this.distanceM,
    this.activityType,
    this.confidence,
    this.startLatLng,
    this.endLatLng,
    this.path = const [],
    this.validDistance = true,
  });

  final int id;
  final String sourceKey;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final DistanceMethod distanceMethod;
  final int? distanceM;
  final String? activityType;
  final double? confidence;
  final LatLngE7? startLatLng;
  final LatLngE7? endLatLng;
  final List<LatLngE7> path;

  /// 異常速度などで日常移動集計から除外するか（設計書 6.2）。
  /// 距離自体は保持し、総移動には含められる。
  final bool validDistance;
}

class StoredCluster {
  const StoredCluster({
    required this.id,
    required this.stableKey,
    required this.centroidLatE7,
    required this.centroidLngE7,
    required this.radiusM,
    required this.visitCount,
    required this.dwellSeconds,
    required this.firstAt,
    required this.lastAt,
    this.labelId,
    this.excluded = false,
    this.labelName,
    this.category,
    this.isBasePlace = false,
  });

  final int id;
  final String stableKey;
  final int centroidLatE7;
  final int centroidLngE7;
  final double radiusM;
  final int visitCount;
  final int dwellSeconds;
  final DateTime firstAt;
  final DateTime lastAt;
  final int? labelId;
  final bool excluded;
  final String? labelName;
  final String? category;
  final bool isBasePlace;

  LatLngE7 get centroid => LatLngE7(centroidLatE7, centroidLngE7);

  String get displayName {
    if (labelName != null && labelName!.isNotEmpty) return labelName!;
    return '地点${_letterFor(id)}';
  }

  static String _letterFor(int id) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letters[(id - 1).clamp(0, letters.length - 1)];
  }
}

class StoredLabel {
  const StoredLabel({
    required this.id,
    required this.displayName,
    this.category,
    this.isBasePlace = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String displayName;
  final String? category;
  final bool isBasePlace;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class StoredInsight {
  const StoredInsight({
    required this.id,
    required this.periodKey,
    required this.ruleId,
    required this.severity,
    required this.title,
    required this.body,
    required this.metricJson,
    required this.createdAt,
    this.dismissed = false,
  });

  final int id;
  final String periodKey;
  final String ruleId;
  final String severity;
  final String title;
  final String body;
  final String metricJson;
  final DateTime createdAt;
  final bool dismissed;
}

class AppSettingRecord {
  const AppSettingRecord({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  final String key;
  final String value;
  final DateTime updatedAt;
}

class ImportedFileRecord {
  const ImportedFileRecord({
    required this.id,
    required this.fileHash,
    required this.schemaType,
    required this.startedAt,
    this.completedAt,
    this.sourceMinAt,
    this.sourceMaxAt,
    required this.status,
    this.warningCount = 0,
    this.addedVisits = 0,
    this.addedMovements = 0,
  });

  final int id;
  final String fileHash;
  final String schemaType;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? sourceMinAt;
  final DateTime? sourceMaxAt;
  final String status; // processing | completed | failed | cancelled
  final int warningCount;
  final int addedVisits;
  final int addedMovements;

  bool get isCompleted => status == 'completed';
}

/// 日次・月次サマリーの保存用レコード（ドメインモデルをそのまま使用）。
typedef DailySummaryRecord = DailySummaryData;
typedef MonthlySummaryRecord = MonthlySummaryData;
