import 'dart:convert';

import 'package:collection/collection.dart';

import '../../domain/models/comparison.dart';
import '../../domain/services/comparison_service.dart';
import '../models/persistence_models.dart';
import '../repositories/kurashilog_repository.dart';

/// 比較リクエストの JSON 変換（保存・再表示用の安定したコードc）。
///
/// 保存するのはユーザーが選択した条件だけで、比較結果・正規化値・文章は
/// 保存せず、元データと条件から決定的に再計算する。
class ComparisonRequestCodec {
  const ComparisonRequestCodec();

  static const _alignmentNames = <ComparisonAlignment, String>{
    ComparisonAlignment.exact: 'exact',
    ComparisonAlignment.sameElapsedDays: 'sameElapsedDays',
    ComparisonAlignment.sameMonth: 'sameMonth',
    ComparisonAlignment.sameSeason: 'sameSeason',
    ComparisonAlignment.milestone: 'milestone',
  };

  String encode(ComparisonRequest request) {
    final alignment = _alignmentNames[request.alignment];
    if (alignment == null) {
      throw ArgumentError.value(
        request.alignment,
        'alignment',
        'Unsupported alignment',
      );
    }
    return jsonEncode({
      'periodA': _rangeJson(request.periodA),
      'periodB': _rangeJson(request.periodB),
      'alignment': alignment,
      'metrics': [for (final metric in request.metrics) metric.name],
      'excludedClusterIds': request.excludedClusterIds.toList(),
    });
  }

  ComparisonRequest decode(String json) {
    final map = _asMap(jsonDecode(json));
    final alignment = _alignmentNames.entries
        .firstWhere(
          (entry) => entry.value == map['alignment'],
          orElse: () =>
              throw FormatException('Unknown alignment: ${map['alignment']}'),
        )
        .key;
    return ComparisonRequest(
      periodA: _rangeFromJson(_asMap(map['periodA'])),
      periodB: _rangeFromJson(_asMap(map['periodB'])),
      alignment: alignment,
      metrics: {
        for (final name in _asStringList(map['metrics']))
          ComparisonMetricId.values.firstWhere(
            (metric) => metric.name == name,
            orElse: () => throw FormatException('Unknown metric: $name'),
          ),
      },
      excludedClusterIds: {
        for (final id in _asStringList(map['excludedClusterIds'])) id,
      },
    );
  }

  Map<String, Object?> _rangeJson(LocalDateRange range) => {
    'startInclusive': range.startInclusive.toIso8601String(),
    'endExclusive': range.endExclusive.toIso8601String(),
    'timeZoneId': range.timeZoneId,
  };

  LocalDateRange _rangeFromJson(Map<String, Object?> map) {
    final start = map['startInclusive'];
    final end = map['endExclusive'];
    final timeZoneId = map['timeZoneId'];
    if (start is! String || end is! String || timeZoneId is! String) {
      throw const FormatException('Invalid LocalDateRange JSON');
    }
    return LocalDateRange(
      startInclusive: _dateFromIso8601(start),
      endExclusive: _dateFromIso8601(end),
      timeZoneId: timeZoneId,
    );
  }

  LocalDate _dateFromIso8601(String value) {
    final parts = value.split('-');
    if (parts.length != 3) throw FormatException('Invalid date: $value');
    return LocalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Map<String, Object?> _asMap(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Expected a JSON object');
    }
    return value;
  }

  List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }
}

/// 保存された比較プリセット。
class SavedComparisonPreset {
  const SavedComparisonPreset({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.request,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ComparisonRequest request;
}

/// 比較リクエストの実行とプリセット保存・再表示を担うアプリケーション層。
///
/// DB schema は変更せず、既存の visits / movements / clusters / labels を
/// 読み取って純粋な [PeriodComparison] を組み立てる。UI が数値を独自に
/// 再計算することはない。
class ComparisonUseCase {
  const ComparisonUseCase({
    required this.repository,
    this.aligner = const ComparisonPeriodAligner(),
    this.policy = const ComparisonQualityPolicy(),
    this.codec = const ComparisonRequestCodec(),
  });

  static const presetSettingsKey = 'comparison.presets.v1';
  static const maxPresets = 20;

  final KurashilogRepository repository;
  final ComparisonPeriodAligner aligner;
  final ComparisonQualityPolicy policy;
  final ComparisonRequestCodec codec;

  /// アライメント適用後の実効期間で比較を実行する。
  ///
  /// 分析除外（excluded / privacyMode=exclude）のクラスタは常に除外し、
  /// プライバシー境界をアプリ層で強制する。
  Future<PeriodComparison> run(ComparisonRequest request) async {
    final alignment = aligner.align(request);
    final clusters = await repository.allClusters();
    final labels = await repository.allLabels();

    final excludedIds = <int>{
      for (final cluster in clusters)
        if (cluster.excludedFromAnalysis) cluster.id,
    };
    final baseLabel = labels.where((label) => label.isBasePlace).firstOrNull;
    final baseClusterId = baseLabel == null
        ? null
        : clusters
              .where((cluster) => cluster.labelId == baseLabel.id)
              .firstOrNull
              ?.id;

    final aVisits = await repository.visitsInRange(
      _rangeStartUtc(alignment.effectiveA),
      _rangeEndUtc(alignment.effectiveA),
    );
    final aMovements = await repository.movementsInRange(
      _rangeStartUtc(alignment.effectiveA),
      _rangeEndUtc(alignment.effectiveA),
    );
    final bVisits = await repository.visitsInRange(
      _rangeStartUtc(alignment.effectiveB),
      _rangeEndUtc(alignment.effectiveB),
    );
    final bMovements = await repository.movementsInRange(
      _rangeStartUtc(alignment.effectiveB),
      _rangeEndUtc(alignment.effectiveB),
    );

    final coverageA = _coverage(
      alignment.effectiveA,
      aVisits,
      aMovements,
      excludedIds,
      baseClusterId,
    );
    final coverageB = _coverage(
      alignment.effectiveB,
      bVisits,
      bMovements,
      excludedIds,
      baseClusterId,
    );

    final quality = policy.evaluate(
      periodA: alignment.effectiveA,
      periodB: alignment.effectiveB,
      coverageA: coverageA,
      coverageB: coverageB,
    );

    final metrics = _aggregateMetrics(
      request: request,
      alignment: alignment,
      aVisits: aVisits,
      aMovements: aMovements,
      bVisits: bVisits,
      bMovements: bMovements,
      excludedIds: excludedIds,
      baseClusterId: baseClusterId,
      coverageA: coverageA,
      coverageB: coverageB,
      periodQuality: quality.quality,
    );

    return PeriodComparison(
      request: request,
      alignment: alignment,
      coverageA: coverageA,
      coverageB: coverageB,
      overallQuality: quality.quality,
      warnings: quality.warnings,
      metrics: metrics,
    );
  }

  Future<PeriodComparison> runFromPreset(SavedComparisonPreset preset) =>
      run(preset.request);

  /// 名前付きプリセットを AppSettings へ保存する。
  Future<SavedComparisonPreset> savePreset({
    required String name,
    required ComparisonRequest request,
    String? existingId,
  }) async {
    final now = DateTime.now();
    final presets = await loadPresets();
    final id = existingId ?? _newId();
    final updated = SavedComparisonPreset(
      id: id,
      name: name,
      createdAt: existingId == null
          ? now
          : presets
                    .where((preset) => preset.id == id)
                    .map((preset) => preset.createdAt)
                    .firstOrNull ??
                now,
      updatedAt: now,
      request: request,
    );
    final next = [
      updated,
      for (final preset in presets)
        if (preset.id != id) preset,
    ].take(maxPresets).toList();
    await repository.setSetting(
      presetSettingsKey,
      jsonEncode([
        for (final preset in next)
          {
            'id': preset.id,
            'name': preset.name,
            'createdAt': preset.createdAt.toIso8601String(),
            'updatedAt': preset.updatedAt.toIso8601String(),
            'request': jsonDecode(codec.encode(preset.request)),
          },
      ]),
    );
    return updated;
  }

  Future<List<SavedComparisonPreset>> loadPresets() async {
    final setting = await repository.getSetting(presetSettingsKey);
    if (setting == null) return const [];
    final decoded = jsonDecode(setting.value);
    if (decoded is! List) return const [];
    final result = <SavedComparisonPreset>[];
    for (final item in decoded) {
      try {
        final map = item is Map<String, Object?> ? item : null;
        if (map == null) continue;
        final request = map['request'];
        if (request is! Map<String, Object?>) continue;
        result.add(
          SavedComparisonPreset(
            id: map['id'] as String? ?? '',
            name: map['name'] as String? ?? '',
            createdAt:
                DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
            updatedAt:
                DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
            request: codec.decode(jsonEncode(request)),
          ),
        );
      } on FormatException {
        // 壊れた1件は読み飛ばし、他は保持する。
      }
    }
    return result;
  }

  Future<void> deletePreset(String id) async {
    final presets = await loadPresets();
    await repository.setSetting(
      presetSettingsKey,
      jsonEncode([
        for (final preset in presets)
          if (preset.id != id)
            {
              'id': preset.id,
              'name': preset.name,
              'createdAt': preset.createdAt.toIso8601String(),
              'updatedAt': preset.updatedAt.toIso8601String(),
              'request': jsonDecode(codec.encode(preset.request)),
            },
      ]),
    );
  }

  PeriodCoverage _coverage(
    LocalDateRange range,
    List<StoredVisit> visits,
    List<StoredMovement> movements,
    Set<int> excludedIds,
    int? baseClusterId,
  ) {
    final represented = <LocalDate>{};
    final reliable = <LocalDate>{};
    final active = <LocalDate>{};

    for (final visit in visits) {
      final date = _localDateOf(visit.startAtUtc);
      if (!range.contains(date)) continue;
      final excluded =
          visit.clusterId != null && excludedIds.contains(visit.clusterId);
      // 分析除外クラスタは充足度・集計の両方から除く。
      if (excluded) continue;
      represented.add(date);
      reliable.add(date);
      if (baseClusterId == null || visit.clusterId != baseClusterId) {
        active.add(date);
      }
    }
    for (final movement in movements) {
      final date = _localDateOf(movement.startAtUtc);
      if (!range.contains(date)) continue;
      represented.add(date);
      if (movement.validDistance) {
        reliable.add(date);
        active.add(date);
      }
    }

    return PeriodCoverage(
      expectedDays: range.calendarDays,
      representedDays: represented.length,
      reliableDays: reliable.length,
      activeDays: active.length,
    );
  }

  List<MetricComparison> _aggregateMetrics({
    required ComparisonRequest request,
    required PeriodAlignmentResult alignment,
    required List<StoredVisit> aVisits,
    required List<StoredMovement> aMovements,
    required List<StoredVisit> bVisits,
    required List<StoredMovement> bMovements,
    required Set<int> excludedIds,
    required int? baseClusterId,
    required PeriodCoverage coverageA,
    required PeriodCoverage coverageB,
    required ComparisonQuality periodQuality,
  }) {
    final selected = request.metrics;
    if (selected.isEmpty) return const [];

    final a = _PeriodData(
      visits: _included(aVisits, alignment.effectiveA, excludedIds),
      movements: _includedMovements(aMovements, alignment.effectiveA),
      coverage: coverageA,
    );
    final b = _PeriodData(
      visits: _included(bVisits, alignment.effectiveB, excludedIds),
      movements: _includedMovements(bMovements, alignment.effectiveB),
      coverage: coverageB,
    );

    final comparator = const MetricComparator();
    final periodRefs = [
      _rangeKey(alignment.effectiveA),
      _rangeKey(alignment.effectiveB),
    ];

    final results = <MetricComparison>[];
    for (final metric in ComparisonMetricId.values) {
      if (!selected.contains(metric)) continue;
      final aValue = _metricValue(metric, a, baseClusterId: baseClusterId);
      final bValue = _metricValue(metric, b, baseClusterId: baseClusterId);
      if (aValue == null || bValue == null) continue;
      results.add(
        comparator.compare(
          id: metric,
          a: aValue,
          b: bValue,
          periodQuality: periodQuality,
          evidence: ComparisonEvidence(
            level: MetricEvidenceLevel.fact,
            periodRefs: periodRefs,
          ),
        ),
      );
    }
    return results;
  }

  MetricValue? _metricValue(
    ComparisonMetricId metric,
    _PeriodData period, {
    required int? baseClusterId,
  }) {
    final unit = switch (metric) {
      ComparisonMetricId.visitCount => '回',
      ComparisonMetricId.uniquePlaces => 'か所',
      ComparisonMetricId.dwellDuration => '分',
      ComparisonMetricId.outsideHomeDays => '日',
      ComparisonMetricId.movementDistance => 'm',
      ComparisonMetricId.movementDuration => '分',
      ComparisonMetricId.recurringPlaceCount => 'か所',
      ComparisonMetricId.categoryDistribution ||
      ComparisonMetricId.weekdayDistribution ||
      ComparisonMetricId.timeOfDayDistribution ||
      ComparisonMetricId.activityRadius => '回',
    };

    final double? raw = switch (metric) {
      ComparisonMetricId.visitCount => period.visits.length.toDouble(),
      ComparisonMetricId.uniquePlaces => _uniqueClusterCount(period.visits),
      ComparisonMetricId.dwellDuration => _dwellMinutes(period.visits),
      ComparisonMetricId.outsideHomeDays => _activeDays(period, baseClusterId),
      ComparisonMetricId.movementDistance =>
        period.movements
            .fold<int>(0, (sum, movement) => sum + (movement.distanceM ?? 0))
            .toDouble(),
      ComparisonMetricId.movementDuration => _movementMinutes(period.movements),
      ComparisonMetricId.recurringPlaceCount => _recurringPlaceCount(
        period.visits,
      ),
      ComparisonMetricId.categoryDistribution ||
      ComparisonMetricId.weekdayDistribution ||
      ComparisonMetricId.timeOfDayDistribution ||
      ComparisonMetricId.activityRadius => null,
    };

    if (raw == null) return null;
    final contributingDays = switch (metric) {
      ComparisonMetricId.dwellDuration => _dwellContributingDays(period.visits),
      ComparisonMetricId.movementDistance ||
      ComparisonMetricId.movementDuration => period.movements.length,
      ComparisonMetricId.outsideHomeDays => raw.toInt(),
      _ => period.visits.length,
    };

    return MetricValue(
      raw: raw,
      perRepresentedDay: period.coverage.representedDays == 0
          ? null
          : raw / period.coverage.representedDays,
      unit: unit,
      contributingDays: contributingDays,
      coverage: period.coverage,
    );
  }

  List<StoredVisit> _included(
    List<StoredVisit> visits,
    LocalDateRange range,
    Set<int> excludedIds,
  ) => [
    for (final visit in visits)
      if (_localDateOf(visit.startAtUtc).compareTo(range.startInclusive) >= 0 &&
          _localDateOf(visit.startAtUtc).compareTo(range.endExclusive) < 0 &&
          !(visit.clusterId != null && excludedIds.contains(visit.clusterId)))
        visit,
  ];

  List<StoredMovement> _includedMovements(
    List<StoredMovement> movements,
    LocalDateRange range,
  ) => [
    for (final movement in movements)
      if (_localDateOf(movement.startAtUtc).compareTo(range.startInclusive) >=
              0 &&
          _localDateOf(movement.startAtUtc).compareTo(range.endExclusive) < 0 &&
          movement.validDistance &&
          movement.distanceM != null)
        movement,
  ];

  double? _uniqueClusterCount(List<StoredVisit> visits) {
    final ids = <int>{};
    for (final visit in visits) {
      if (visit.clusterId != null) ids.add(visit.clusterId!);
    }
    return ids.length.toDouble();
  }

  double? _recurringPlaceCount(List<StoredVisit> visits) {
    final counts = <int, int>{};
    for (final visit in visits) {
      final id = visit.clusterId;
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts.values.where((count) => count >= 2).length.toDouble();
  }

  double? _dwellMinutes(List<StoredVisit> visits) {
    final totalSeconds = visits.fold<int>(
      0,
      (sum, visit) =>
          sum + visit.endAtUtc.difference(visit.startAtUtc).inSeconds,
    );
    return totalSeconds / 60;
  }

  int _dwellContributingDays(List<StoredVisit> visits) {
    final days = <LocalDate>{};
    for (final visit in visits) {
      days.add(_localDateOf(visit.startAtUtc));
    }
    return days.length;
  }

  double? _movementMinutes(List<StoredMovement> movements) =>
      movements.fold<int>(
        0,
        (sum, movement) =>
            sum + movement.endAtUtc.difference(movement.startAtUtc).inSeconds,
      ) /
      60;

  double? _activeDays(_PeriodData period, int? baseClusterId) {
    final days = <LocalDate>{};
    for (final visit in period.visits) {
      if (baseClusterId == null || visit.clusterId != baseClusterId) {
        days.add(_localDateOf(visit.startAtUtc));
      }
    }
    for (final movement in period.movements) {
      days.add(_localDateOf(movement.startAtUtc));
    }
    return days.length.toDouble();
  }

  DateTime _rangeStartUtc(LocalDateRange range) => DateTime(
    range.startInclusive.year,
    range.startInclusive.month,
    range.startInclusive.day,
  ).toUtc();

  DateTime _rangeEndUtc(LocalDateRange range) => DateTime(
    range.endExclusive.year,
    range.endExclusive.month,
    range.endExclusive.day,
  ).toUtc();

  LocalDate _localDateOf(DateTime utc) {
    final local = utc.toLocal();
    return LocalDate(local.year, local.month, local.day);
  }

  String _rangeKey(LocalDateRange range) =>
      '${range.startInclusive.toIso8601String()}..'
      '${range.endExclusive.toIso8601String()}';

  String _newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

class _PeriodData {
  const _PeriodData({
    required this.visits,
    required this.movements,
    required this.coverage,
  });

  final List<StoredVisit> visits;
  final List<StoredMovement> movements;
  final PeriodCoverage coverage;
}
