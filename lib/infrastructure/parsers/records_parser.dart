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
  });

  final SourceKeyGenerator sourceKeyGenerator;
  final DistanceService distanceService;

  static const double legacyStayRadiusM = 150.0;
  static const int legacyMinConsecutivePoints = 2;

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
      warnings[code] = (warnings[code] ?? ImportWarning(code, message))
          .mergedWith(ImportWarning(code, message));
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
    await _scan(
      source,
      token,
      onSegment: (segment) {
        count++;
        final (start, end) = _segmentRange(segment);
        mergeRange(start, end);
      },
      onLegacyPoint: (point) {
        count++;
        legacyPoints.add(point);
        mergeRange(point.at, point.at);
      },
      onUnsupportedSegment: () =>
          warn('PAR-001', '未対応のセグメントを無視しました'),
      onError: (code, message) {
        parseError ??= ImportParseException(code, message);
      },
    );

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
      count = derived.length;
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
        onLegacyPoint: legacyPoints.add,
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

  NormalizedRecord? _segmentToRecord(Map<String, Object?> segment) {
    final (start, end) = _segmentRange(segment);
    if (start == null || end == null) return null;

    final visit = segment['visit'];
    if (visit is Map<String, Object?>) {
      return _visitToRecord(visit, start, end);
    }

    final activity = segment['activity'];
    if (activity is Map<String, Object?>) {
      return _activityToRecord(activity, start, end, segment);
    }
    return null;
  }

  (DateTime?, DateTime?) _segmentRange(Map<String, Object?> segment) {
    final start = _timestamp(segment['start']) ??
        _timestamp(segment['startTime']) ??
        _timestamp(segment['startTimestamp']);
    final end = _timestamp(segment['end']) ??
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
    final candidateMap =
        candidate is Map<String, Object?> ? candidate : null;
    final coordinate = _coordinateFrom(_visitLocation(visit));
    if (coordinate == null) return null;

    final placeId = candidateMap?['placeId'];
    final semanticType = candidateMap?['semanticType'];
    final confidence = _number(visit['locationConfidence']) ??
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

  NormalizedMovement _activityToRecord(
    Map<String, Object?> activity,
    DateTime start,
    DateTime end,
    Map<String, Object?> segment,
  ) {
    final activityType = activity['activityType'];
    var path = _waypoints(activity['waypoints']);
    if (path.isEmpty) path = _timelinePathCoordinates(segment['timelinePath']);

    final recordedDistance = _number(activity['distance']);
    final int? distanceM;
    final DistanceMethod method;
    if (recordedDistance != null && recordedDistance > 0) {
      distanceM = recordedDistance.round();
      method = DistanceMethod.recorded;
    } else if (path.length >= 2) {
      distanceM = distanceService.pathMeters(path).round();
      method = DistanceMethod.estimatedPath;
    } else {
      distanceM = null;
      method = DistanceMethod.unknown;
    }

    final normalizedActivity =
        activityType is String ? activityType : null;
    final startCoordinate = path.isNotEmpty ? path.first : null;
    final endCoordinate = path.isNotEmpty ? path.last : null;
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

  LatLngE7? _coordinateFrom(Object? value) {
    if (value is Map<String, Object?>) {
      final lat = _number(value['latitudeE7'] ?? value['latE7']);
      final lng = _number(value['longitudeE7'] ?? value['lngE7']);
      if (lat != null && lng != null) {
        return LatLngE7(lat.round(), lng.round());
      }
      return _coordinateFrom(value['point']);
    }
    if (value is String) {
      final normalized = value.startsWith('geo:') ? value.substring(4) : value;
      final parts = normalized.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].split('?').first.trim());
        if (lat != null && lng != null) {
          return LatLngE7((lat * 1e7).round(), (lng * 1e7).round());
        }
      }
    }
    return null;
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
        visits.add(NormalizedVisit(
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
        ));
      }
      index = cursor == index ? index + 1 : cursor;
    }

    final records = <NormalizedRecord>[...visits];
    for (var i = 0; i + 1 < visits.length; i++) {
      final from = visits[i];
      final to = visits[i + 1];
      if (to.startAtUtc.isBefore(from.endAtUtc)) continue;
      final distance =
          distanceService.haversineMeters(from.latLng, to.latLng).round();
      if (distance <= 5) continue;
      records.add(NormalizedMovement(
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
      ));
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
