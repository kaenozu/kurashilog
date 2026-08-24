import 'dart:async';

import '../../domain/models/distance_method.dart';
import '../../domain/models/lat_lng.dart';
import '../../domain/models/normalized_record.dart';
import '../../domain/models/source_key.dart';
import '../../domain/services/distance_service.dart';
import 'json_event_parser.dart';
import 'timeline_parser.dart';

/// Records.json（Google マップ タイムラインの手動エクスポート）の
/// ストリーミングパーサー。
class RecordsTimelineParser implements TimelineParser {
  const RecordsTimelineParser({
    this.sourceKeyGenerator = const SourceKeyGenerator(
      schemaType: 'timeline-records',
    ),
    this.distanceService = const DistanceService(),
    this.legacyMaxPoints = defaultLegacyMaxPoints,
  });

  final SourceKeyGenerator sourceKeyGenerator;
  final DistanceService distanceService;

  static const double legacyStayRadiusM = 150.0;
  static const int legacyMinConsecutivePoints = 2;

  /// 旧形式 locations は滞在導出のため点列をバッファする。
  /// 数百万点でのメモリ枯渇を防ぐ安全弁として、この点数を超えた時点で
  /// IMP-006 により取込を中断する。
  static const int defaultLegacyMaxPoints = 2000000;
  static const String legacyLimitErrorCode = 'IMP-006';

  final int legacyMaxPoints;

  /// バッファ済み旧形式点列が上限を超えたら中断用エラーを投げる。
  void _ensureLegacyCapacity(int bufferedCount) {
    if (bufferedCount < legacyMaxPoints) return;
    throw ImportParseException(
      legacyLimitErrorCode,
      '旧形式（locations）の点数が上限 $legacyMaxPoints 点を超えたため'
      '取り込みを中断しました',
    );
  }

  @override
  String get schemaType => 'timeline-records';

  @override
  Future<PreviewResult> preview(
    Stream<List<int>> source,
    CancellationToken token,
  ) async {
    var count = 0;
    DateTime? minAt;
    DateTime? maxAt;
    final warnings = <String, ImportWarning>{};
    final legacyPoints = <_LegacyPoint>[];

    void warn(String code, String message) {
      final next = ImportWarning(code, message);
      warnings[code] = warnings[code]?.mergedWith(next) ?? next;
    }

    void mergeRange(DateTime? start, DateTime? end) {
      if (start != null && (minAt == null || start.isBefore(minAt!))) {
        minAt = start;
      }
      if (end != null && (maxAt == null || end.isAfter(maxAt!))) {
        maxAt = end;
      }
    }

    ImportParseException? parseError;
    try {
      await _scan(
        source,
        token,
        onSegment: (segment) {
          if (_segmentToRecord(segment, warn: warn) != null) count++;
          final (start, end) = _segmentRange(segment);
          mergeRange(start, end);
        },
        onLegacyPoint: (point) {
          _ensureLegacyCapacity(legacyPoints.length);
          count++;
          legacyPoints.add(point);
          mergeRange(point.at, point.at);
        },
        onUnsupportedSegment: () => warn('PAR-001', '未対応のセグメントを無視しました'),
        onError: (code, message) {
          parseError ??= ImportParseException(code, message);
        },
      );
    } on ImportParseException catch (error) {
      parseError ??= error;
    }

    if (token.isCancelled) {
      return const PreviewResult(
        schemaType: 'timeline-records',
        minAt: null,
        maxAt: null,
        approxRecordCount: 0,
        errorCode: 'IMP-005',
        errorMessage: 'キャンセルされました',
      );
    }
    if (parseError != null) {
      return PreviewResult(
        schemaType: schemaType,
        minAt: minAt,
        maxAt: maxAt,
        approxRecordCount: count,
        warnings: warnings.values.toList(),
        errorCode: parseError!.code,
        errorMessage: parseError!.message,
      );
    }

    if (legacyPoints.isNotEmpty) {
      final derived = _deriveLegacyRecords(legacyPoints);
      // 生の点列を個別カウントしていた分を導出レコード数へ置き換える。
      count = count - legacyPoints.length + derived.length;
      for (final record in derived) {
        mergeRange(record.startAtUtc, record.endAtUtc);
      }
    }

    return PreviewResult(
      schemaType: schemaType,
      minAt: minAt,
      maxAt: maxAt,
      approxRecordCount: count,
      warnings: warnings.values.toList(),
    );
  }

  @override
  Stream<NormalizedRecord> parse(
    Stream<List<int>> source,
    CancellationToken token,
  ) {
    final controller = StreamController<NormalizedRecord>();
    unawaited(_runParse(source, token, controller));
    return controller.stream;
  }

  Future<void> _runParse(
    Stream<List<int>> source,
    CancellationToken token,
    StreamController<NormalizedRecord> controller,
  ) async {
    try {
      final legacyPoints = <_LegacyPoint>[];
      ImportParseException? parseError;
      await _scan(
        source,
        token,
        onSegment: (segment) {
          final record = _segmentToRecord(segment);
          if (record != null) controller.add(record);
        },
        onLegacyPoint: (point) {
          _ensureLegacyCapacity(legacyPoints.length);
          legacyPoints.add(point);
        },
        onUnsupportedSegment: () {},
        onError: (code, message) {
          parseError ??= ImportParseException(code, message);
        },
      );

      if (token.isCancelled) {
        throw const ImportParseException('IMP-005', 'キャンセルされました');
      }
      if (parseError != null) throw parseError!;

      for (final record in _deriveLegacyRecords(legacyPoints)) {
        if (token.isCancelled) {
          throw const ImportParseException('IMP-005', 'キャンセルされました');
        }
        controller.add(record);
      }
    } catch (error, stackTrace) {
      controller.addError(error, stackTrace);
    } finally {
      await controller.close();
    }
  }

  Future<void> _scan(
    Stream<List<int>> source,
    CancellationToken token, {
    required void Function(Map<String, Object?> segment) onSegment,
    required void Function(_LegacyPoint point) onLegacyPoint,
    required void Function() onUnsupportedSegment,
    required void Function(String code, String message) onError,
  }) async {
    final parser = JsonEventParser();
    final collector = _SegmentCollector();
    var objectDepth = 0;
    var targetArray = '';

    try {
      await for (final chunk in source) {
        if (token.isCancelled) return;
        for (final event in parser.addChunk(chunk)) {
          switch (event.type) {
            case JsonEventType.objectStart:
              objectDepth++;
              if (collector.active) {
                collector.handle(event);
              } else if (objectDepth == 2 && targetArray.isNotEmpty) {
                collector.handle(event);
              }
            case JsonEventType.objectEnd:
              if (collector.active) {
                collector.handle(event);
                final completed = collector.takeCompleted();
                if (completed != null) {
                  _dispatch(
                    completed,
                    targetArray,
                    onSegment: onSegment,
                    onLegacyPoint: onLegacyPoint,
                    onUnsupported: onUnsupportedSegment,
                  );
                }
              }
              if (objectDepth > 0) objectDepth--;
            case JsonEventType.arrayStart:
              if (collector.active) collector.handle(event);
            case JsonEventType.arrayEnd:
              if (collector.active) {
                collector.handle(event);
              } else if (objectDepth == 1 && targetArray.isNotEmpty) {
                targetArray = '';
              }
            case JsonEventType.key:
              if (collector.active) {
                collector.handle(event);
              } else if (objectDepth == 1) {
                final key = event.key ?? '';
                if (key == 'semanticSegments' ||
                    key == 'locations' ||
                    key == 'activitySegments') {
                  targetArray = key;
                }
              }
            case JsonEventType.value:
              if (collector.active) collector.handle(event);
          }
        }
      }
      parser.finish();
    } on JsonParseException catch (error) {
      onError('IMP-003', 'JSON の構文エラー: ${error.message}');
    } on FormatException catch (error) {
      onError('IMP-003', 'JSON のデコードエラー: $error');
    }
  }

  void _dispatch(
    Map<String, Object?> segment,
    String targetArray, {
    required void Function(Map<String, Object?>) onSegment,
    required void Function(_LegacyPoint) onLegacyPoint,
    required void Function() onUnsupported,
  }) {
    if (targetArray == 'semanticSegments' ||
        targetArray == 'activitySegments') {
      onSegment(segment);
      return;
    }
    if (targetArray == 'locations') {
      final point = _LegacyPoint.fromMap(segment);
      if (point != null) onLegacyPoint(point);
      return;
    }
    onUnsupported();
  }

  /// セグメントを正規化レコードへ変換する。
  ///
  /// Preview と 本取込 の判定を共有するため、レコード化できないセグメントは
  /// [warn] を介して理由を報告する。呼び出し側が [warn] を渡さない場合は
  /// 警告を発しない（破棄理由の集計を Preview 側に任せる）。
  NormalizedRecord? _segmentToRecord(
    Map<String, Object?> segment, {
    void Function(String code, String message)? warn,
  }) {
    final (start, end) = _segmentRange(segment);
    if (start == null || end == null) {
      warn?.call('PAR-002', '時刻情報が不十分なセグメントを無視しました');
      return null;
    }

    final visit = segment['visit'];
    if (visit is Map<String, Object?>) {
      final record = _visitToRecord(visit, start, end);
      if (record == null) {
        warn?.call('PAR-003', '座標情報が無い訪問を無視しました');
      }
      return record;
    }

    final activity = segment['activity'];
    if (activity is Map<String, Object?>) {
      return _activityToRecord(activity, start, end, segment);
    }

    // 旧形式の activitySegments はセグメント直下に
    // activityType / distance を含むため、セグメント自身を activity として扱う。
    final legacyType = segment['activityType'];
    if (legacyType is String || _number(segment['distance']) != null) {
      return _activityToRecord(segment, start, end, segment);
    }

    // 実Android版エクスポートの timelinePath のみのセグメントは、経路点列を持つ
    // 移動として扱う。点が 2 点未満では距離を推定できないため warning に分類する。
    final timelinePath = segment['timelinePath'];
    if (timelinePath is List && timelinePath.isNotEmpty) {
      final path = _timelinePathCoordinates(timelinePath);
      if (path.length >= 2) {
        return _timelinePathToMovement(start, end, path);
      }
      warn?.call('PAR-004', '経路点が不足した移動セグメントを無視しました');
      return null;
    }
    // 既知の種別を持たないセグメントはレコード化せず warning に分類する。
    warn?.call('PAR-001', '未対応のセグメントを無視しました');
    return null;
  }

  NormalizedMovement _timelinePathToMovement(
    DateTime start,
    DateTime end,
    List<LatLngE7> path,
  ) {
    return NormalizedMovement(
      sourceKey: sourceKeyGenerator.fingerprint(
        recordType: 'movement',
        startAtUtc: start,
        endAtUtc: end,
        latE7: path.first.latE7,
        lngE7: path.first.lngE7,
      ),
      startAtUtc: start,
      endAtUtc: end,
      distanceM: distanceService.pathMeters(path).round(),
      distanceMethod: DistanceMethod.estimatedPath,
      startLatLng: path.first,
      endLatLng: path.last,
      path: path,
    );
  }

  (DateTime?, DateTime?) _segmentRange(Map<String, Object?> segment) {
    final start =
        _timestamp(segment['start']) ??
        _timestamp(segment['startTime']) ??
        _timestamp(segment['startTimestamp']);
    final end =
        _timestamp(segment['end']) ??
        _timestamp(segment['endTime']) ??
        _timestamp(segment['endTimestamp']);
    if (start != null || end != null) return (start, end);

    final duration = segment['duration'];
    if (duration is Map<String, Object?>) {
      return (
        _timestamp(duration['startTimestampMs']) ??
            _timestamp(duration['startTime']),
        _timestamp(duration['endTimestampMs']) ??
            _timestamp(duration['endTime']),
      );
    }
    return (null, null);
  }

  NormalizedVisit? _visitToRecord(
    Map<String, Object?> visit,
    DateTime start,
    DateTime end,
  ) {
    final candidate = visit['topCandidate'];
    final candidateMap = candidate is Map<String, Object?> ? candidate : null;
    final coordinate = _coordinateFrom(_visitLocation(visit));
    if (coordinate == null) return null;

    final placeId = candidateMap?['placeId'];
    final semanticType = candidateMap?['semanticType'];
    final confidence =
        _number(visit['locationConfidence']) ??
        _number(candidateMap?['probability']);

    // placeId は地点の ID であって訪問イベントの ID ではない。
    // 時刻と座標を含む指紋を使い、同じ場所への再訪を保持する。
    final key = sourceKeyGenerator.fingerprint(
      recordType: 'visit',
      startAtUtc: start,
      endAtUtc: end,
      latE7: coordinate.latE7,
      lngE7: coordinate.lngE7,
      normalizedActivity: placeId is String ? placeId : null,
    );

    return NormalizedVisit(
      sourceKey: key,
      startAtUtc: start,
      endAtUtc: end,
      latLng: coordinate,
      sourceLabel: semanticType is String ? semanticType : null,
      confidence: confidence,
    );
  }

  String? _activityTypeFrom(Map<String, Object?> activity) {
    final direct = activity['activityType'];
    if (direct is String && direct.isNotEmpty) return direct;
    if (direct is Map<String, Object?>) {
      final nested = direct['type'];
      if (nested is String && nested.isNotEmpty) return nested;
    }
    // 現行 Takeout の activity は start に種別（WALKING 等）を持つ。
    // 旧配列形式の start はタイムスタンプなので種別として扱わない。
    final start = activity['start'];
    if (start is String &&
        start.isNotEmpty &&
        DateTime.tryParse(start) == null) {
      return start;
    }
    final topCandidate = activity['topCandidate'];
    if (topCandidate is Map<String, Object?>) {
      final candidateType = topCandidate['type'];
      if (candidateType is String && candidateType.isNotEmpty) {
        return candidateType;
      }
    }
    return null;
  }

  NormalizedMovement _activityToRecord(
    Map<String, Object?> activity,
    DateTime start,
    DateTime end,
    Map<String, Object?> segment,
  ) {
    final activityType = _activityTypeFrom(activity);
    var path = _waypoints(activity['waypoints']);
    if (path.isEmpty) path = _timelinePathCoordinates(segment['timelinePath']);

    // 実 Android 版エクスポートは activity.start/end の latLng を持つ。
    // 単一点 path を理由に activity の異なる終点を捨てないため、
    // activity の座標が存在する場合は path より優先する。
    final activityStartCoordinate = _coordinateFrom(activity['start']);
    final activityEndCoordinate = _coordinateFrom(activity['end']);

    final startCoordinate =
        activityStartCoordinate ?? (path.isNotEmpty ? path.first : null);
    final endCoordinate =
        activityEndCoordinate ?? (path.isNotEmpty ? path.last : null);

    final recordedDistance =
        _number(activity['distance']) ?? _number(activity['distanceMeters']);
    final int? distanceM;
    final DistanceMethod method;
    if (recordedDistance != null && recordedDistance > 0) {
      distanceM = recordedDistance.round();
      method = DistanceMethod.recorded;
    } else if (path.length >= 2) {
      distanceM = distanceService.pathMeters(path).round();
      method = DistanceMethod.estimatedPath;
    } else if (startCoordinate != null && endCoordinate != null) {
      distanceM = distanceService
          .haversineMeters(startCoordinate, endCoordinate)
          .round();
      method = DistanceMethod.estimatedDirect;
    } else {
      distanceM = null;
      method = DistanceMethod.unknown;
    }

    final normalizedActivity = activityType is String ? activityType : null;
    final key = sourceKeyGenerator.fingerprint(
      recordType: 'movement',
      startAtUtc: start,
      endAtUtc: end,
      latE7: startCoordinate?.latE7,
      lngE7: startCoordinate?.lngE7,
      normalizedActivity: normalizedActivity,
    );

    return NormalizedMovement(
      sourceKey: key,
      startAtUtc: start,
      endAtUtc: end,
      distanceM: distanceM,
      distanceMethod: method,
      activityType: normalizedActivity,
      confidence: _number(activity['confidence']),
      startLatLng: startCoordinate,
      endLatLng: endCoordinate,
      path: path,
    );
  }

  Object? _visitLocation(Map<String, Object?> visit) {
    final topCandidate = visit['topCandidate'];
    if (topCandidate is Map<String, Object?>) {
      return topCandidate['location'] ??
          topCandidate['placeLocation'] ??
          topCandidate;
    }
    final placeLocation = visit['placeLocation'];
    if (placeLocation != null) return placeLocation;
    final candidates = visit['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map<String, Object?>) {
        return first['location'] ?? first['placeLocation'] ?? first;
      }
    }
    return null;
  }

  /// 座標候補を [LatLngE7] へ変換する。
  ///
  /// 対応形式:
  /// - Map 内の `latLng`（度記号付き文字列など）
  /// - Map 内の `point`（geo: 形式文字列）
  /// - `latitudeE7` / `longitudeE7`
  /// - `latE7` / `lngE7`
  /// - `geo:lat,lng` 形式の文字列
  /// - `lat,lng` 形式の文字列
  /// - `lat\U+00B0, lng\U+00B0`（度記号付き）形式の文字列
  ///
  /// 不正な文字列、または度として解釈した座標が範囲外
  /// （緯度 ±90 / 経度 ±180）の場合は安全に null を返す。
  /// E7 整数の Map 形式は範囲検証なしで変換して返す
  /// （後段の validator が VAL-001 として破棄する）。
  LatLngE7? _coordinateFrom(Object? value) {
    if (value is Map<String, Object?>) {
      final latLng = value['latLng'] ?? value['point'];
      final fromLatLng = _coordinateFrom(latLng);
      if (fromLatLng != null) return fromLatLng;
      final lat = _number(value['latitudeE7'] ?? value['latE7']);
      final lng = _number(value['longitudeE7'] ?? value['lngE7']);
      if (lat != null && lng != null) {
        return LatLngE7(lat.round(), lng.round());
      }
      return null;
    }
    if (value is String) {
      var normalized = value.trim();
      if (normalized.startsWith('geo:')) normalized = normalized.substring(4);
      final rawParts = normalized.split(',');
      if (rawParts.length >= 2) {
        final lat = _coordinateDegree(rawParts.first.trim());
        final lng = _coordinateDegree(rawParts[1].split('?').first.trim());
        if (lat != null && lng != null) {
          if (!lat.isFinite ||
              !lng.isFinite ||
              lat < -90 ||
              lat > 90 ||
              lng < -180 ||
              lng > 180) {
            return null;
          }
          return LatLngE7((lat * 1e7).round(), (lng * 1e7).round());
        }
      }
    }
    return null;
  }

  /// 度記号（`\U+00B0`）や改行・空白を除去した度座標値を返す。
  double? _coordinateDegree(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final degreeStripped = value
        .replaceAll('\u00B0', '')
        .replaceAll(RegExp(r'\s'), '');
    if (degreeStripped.isEmpty) return null;
    return double.tryParse(degreeStripped);
  }

  List<LatLngE7> _waypoints(Object? value) {
    if (value is! List) return const [];
    return value.map(_coordinateFrom).whereType<LatLngE7>().toList();
  }

  List<LatLngE7> _timelinePathCoordinates(Object? value) {
    if (value is! List) return const [];
    final coordinates = <LatLngE7>[];
    for (final entry in value) {
      if (entry is Map<String, Object?>) {
        final coordinate = _coordinateFrom(entry['point'] ?? entry);
        if (coordinate != null) coordinates.add(coordinate);
      }
    }
    return coordinates;
  }

  List<NormalizedRecord> _deriveLegacyRecords(List<_LegacyPoint> points) {
    if (points.isEmpty) return const [];
    final ordered = [...points]..sort((a, b) => a.at.compareTo(b.at));

    final visits = <NormalizedVisit>[];
    var index = 0;
    while (index < ordered.length) {
      final anchor = ordered[index];
      var cursor = index;
      var latitudeSum = 0.0;
      var longitudeSum = 0.0;
      var count = 0;
      while (cursor < ordered.length) {
        final distance = distanceService.haversineMeters(
          anchor.coordinate,
          ordered[cursor].coordinate,
        );
        if (distance > legacyStayRadiusM) break;
        latitudeSum += ordered[cursor].coordinate.lat;
        longitudeSum += ordered[cursor].coordinate.lng;
        count++;
        cursor++;
      }
      if (count >= legacyMinConsecutivePoints) {
        final start = ordered[index].at;
        final end = ordered[cursor - 1].at;
        final centroid = LatLngE7(
          (latitudeSum / count * 1e7).round(),
          (longitudeSum / count * 1e7).round(),
        );
        visits.add(
          NormalizedVisit(
            sourceKey: sourceKeyGenerator.fingerprint(
              recordType: 'visit',
              startAtUtc: start,
              endAtUtc: end,
              latE7: centroid.latE7,
              lngE7: centroid.lngE7,
            ),
            startAtUtc: start,
            endAtUtc: end,
            latLng: centroid,
          ),
        );
      }
      index = cursor == index ? index + 1 : cursor;
    }

    final records = <NormalizedRecord>[...visits];
    for (var i = 0; i + 1 < visits.length; i++) {
      final from = visits[i];
      final to = visits[i + 1];
      if (to.startAtUtc.isBefore(from.endAtUtc)) continue;
      final distance = distanceService
          .haversineMeters(from.latLng, to.latLng)
          .round();
      if (distance <= 5) continue;
      records.add(
        NormalizedMovement(
          sourceKey: sourceKeyGenerator.fingerprint(
            recordType: 'movement',
            startAtUtc: from.endAtUtc,
            endAtUtc: to.startAtUtc,
            latE7: from.latLng.latE7,
            lngE7: from.latLng.lngE7,
          ),
          startAtUtc: from.endAtUtc,
          endAtUtc: to.startAtUtc,
          distanceM: distance,
          distanceMethod: DistanceMethod.estimatedDirect,
          startLatLng: from.latLng,
          endLatLng: to.latLng,
        ),
      );
    }
    return records;
  }

  DateTime? _timestamp(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    }
    if (value is String) {
      final milliseconds = int.tryParse(value);
      if (milliseconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
      }
      return DateTime.tryParse(value)?.toUtc();
    }
    if (value is Map<String, Object?>) {
      return _timestamp(value['timestampMs'] ?? value['time']);
    }
    return null;
  }

  double? _number(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class _LegacyPoint {
  const _LegacyPoint({required this.at, required this.coordinate});

  final DateTime at;
  final LatLngE7 coordinate;

  static _LegacyPoint? fromMap(Map<String, Object?> map) {
    final timestamp = map['timestampMs'];
    final latitude = map['latitudeE7'];
    final longitude = map['longitudeE7'];
    final milliseconds = timestamp is num
        ? timestamp.toInt()
        : timestamp is String
        ? int.tryParse(timestamp)
        : null;
    if (milliseconds == null || latitude is! num || longitude is! num) {
      return null;
    }
    return _LegacyPoint(
      at: DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true),
      coordinate: LatLngE7(latitude.toInt(), longitude.toInt()),
    );
  }
}

/// ターゲット配列内の1オブジェクトだけを構築する。
class _SegmentCollector {
  bool active = false;
  Map<String, Object?>? _completed;

  final List<Object> _containers = [];
  final List<String?> _keys = [];
  final List<bool> _maps = [];
  int _depth = 0;

  Map<String, Object?>? takeCompleted() {
    final value = _completed;
    _completed = null;
    return value;
  }

  void handle(JsonEvent event) {
    switch (event.type) {
      case JsonEventType.objectStart:
        _push(<String, Object?>{}, isMap: true);
      case JsonEventType.arrayStart:
        _push(<Object?>[], isMap: false);
      case JsonEventType.objectEnd:
      case JsonEventType.arrayEnd:
        _pop();
      case JsonEventType.key:
        if (_maps.isNotEmpty && _maps.last) {
          _keys[_keys.length - 1] = event.key;
        }
      case JsonEventType.value:
        _attach(event.value);
    }
  }

  void _push(Object container, {required bool isMap}) {
    if (_containers.isNotEmpty) _attach(container);
    _containers.add(container);
    _keys.add(null);
    _maps.add(isMap);
    _depth++;
    if (_depth == 1) active = true;
  }

  void _pop() {
    if (_containers.isEmpty) return;
    final removed = _containers.removeLast();
    _keys.removeLast();
    _maps.removeLast();
    _depth--;
    if (_depth == 0) {
      active = false;
      if (removed is Map<String, Object?>) _completed = removed;
    }
  }

  void _attach(Object? value) {
    if (_containers.isEmpty) return;
    final top = _containers.last;
    if (top is Map<String, Object?>) {
      final key = _keys.last;
      if (key == null) return;
      top[key] = value;
      _keys[_keys.length - 1] = null;
    } else {
      (top as List<Object?>).add(value);
    }
  }
}
