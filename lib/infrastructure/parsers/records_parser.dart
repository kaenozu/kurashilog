import 'dart:async';

import '../../domain/models/distance_method.dart';
import '../../domain/models/lat_lng.dart';
import '../../domain/models/normalized_record.dart';
import '../../domain/models/source_key.dart';
import '../../domain/services/distance_service.dart';
import 'json_event_parser.dart';
import 'timeline_parser.dart';

/// Records.json（Google マップ タイムラインの手動エクスポート）のパーサー。
///
/// 対応形式:
/// - 現行: `semanticSegments`（visit / activity セグメント）… 優先
/// - 旧形式: `locations`（点列）＋ `activitySegments`
///
/// 設計書 5.1 のデータフローに従い、Isolate でストリーム解析し、
/// [NormalizedRecord] を小分けに返す。全文 String 化はしない。
class RecordsTimelineParser implements TimelineParser {
  const RecordsTimelineParser({
    this.sourceKeyGenerator = const SourceKeyGenerator(
        schemaType: 'timeline-records'),
    this.distanceService = const DistanceService(),
  });

  final SourceKeyGenerator sourceKeyGenerator;
  final DistanceService distanceService;

  /// 旧形式の点列を訪問へ変換する際の滞在半径（メートル）。
  static const double legacyStayRadiusM = 150.0;

  /// 旧形式の点列の最小間引き（連続点の同一滞在判定に使う）。
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

    void warn(String code, String message) {
      warnings[code] = (warnings[code] ?? ImportWarning(code, message))
          .mergedWith(ImportWarning(code, message));
    }

    final legacyPoints = <_LegacyPoint>[];

    await _scan(
      source,
      token,
      onSegment: (seg) {
        count++;
        final (s, e) = _segmentRange(seg);
        _mergeRange(s, e);
      },
      onLegacyPoint: (p) {
        count++;
        legacyPoints.add(p);
        _mergeRange(p.at, p.at);
      },
      onUnsupportedSegment: () => warn('IMP-002', '未対応のセグメントを無視しました'),
      onError: (code, message) => warn(code, message),
    );

    if (token.isCancelled) {
      return const PreviewResult(
        schemaType: 'timeline-records',
        approxRecordCount: 0,
        errorCode: 'IMP-005',
        errorMessage: 'キャンセルされました',
      );
    }

    if (legacyPoints.isNotEmpty) {
      // 点列から訪問・移動を導出した場合の件数・期間は導出後に確定
      final derived = _deriveLegacyRecords(legacyPoints);
      count = derived.length;
      for (final r in derived) {
        _mergeRange(r.startAtUtc, r.endAtUtc);
      }
    }

    return PreviewResult(
      schemaType: schemaType,
      minAt: minAt,
      maxAt: maxAt,
      approxRecordCount: count,
      warnings: warnings.values.toList(),
    );

    void _mergeRange(DateTime? s, DateTime? e) {
      if (s != null && (minAt == null || s.isBefore(minAt!))) minAt = s;
      if (e != null && (maxAt == null || e.isAfter(maxAt!))) maxAt = e;
    }
  }

  @override
  Stream<NormalizedRecord> parse(
    Stream<List<int>> source,
    CancellationToken token,
  ) {
    // コールバックからは yield できないため、StreamController 経由で返す。
    final controller = StreamController<NormalizedRecord>();
    _runParse(source, token, controller);
    return controller.stream;
  }

  Future<void> _runParse(
    Stream<List<int>> source,
    CancellationToken token,
    StreamController<NormalizedRecord> controller,
  ) async {
    try {
      final legacyPoints = <_LegacyPoint>[];
      await _scan(
        source,
        token,
        onSegment: (seg) {
          final record = _segmentToRecord(seg);
          if (record != null) controller.add(record);
        },
        onLegacyPoint: (p) => legacyPoints.add(p),
        onUnsupportedSegment: () {
          // 未知フィールド・未対応セグメントは無視（警告はプレビュー側で計上）
        },
        onError: (code, message) {
          controller.addError(ImportParseException(code, message));
        },
      );

      if (token.isCancelled) {
        controller.addError(
            const ImportParseException('IMP-005', 'キャンセルされました'));
        return;
      }

      if (legacyPoints.isNotEmpty) {
        for (final record in _deriveLegacyRecords(legacyPoints)) {
          if (token.isCancelled) break;
          controller.add(record);
        }
      }
    } catch (e) {
      controller.addError(e);
    } finally {
      await controller.close();
    }
  }

  /// スキャン本体。セグメント / 点列 / エラーをコールバックで通知する。
  Future<void> _scan(
    Stream<List<int>> source,
    CancellationToken token,
    {
    required void Function(Map<String, Object?> seg) onSegment,
    required void Function(_LegacyPoint p) onLegacyPoint,
    required void Function() onUnsupportedSegment,
    required void Function(String code, String message) onError,
  }) async {
    final parser = JsonEventParser();
    final collector = _SegmentCollector();
    var rootDepth = 0;
    var targetArray = '';

    try {
      await for (final chunk in source) {
        if (token.isCancelled) return;
        for (final event in parser.addChunk(chunk)) {
          switch (event.type) {
            case JsonEventType.objectStart:
              rootDepth++;
              if (collector.active) {
                collector.handle(event);
              } else if (rootDepth == 2 && targetArray.isNotEmpty) {
                // ターゲット配列内のオブジェクトの開始 → 捕捉開始
                collector.handle(event);
              }
            case JsonEventType.objectEnd:
              if (collector.active) {
                collector.handle(event);
                if (!collector.active && collector.completed != null) {
                  final seg = collector.completed!;
                  collector.completed = null;
                  _dispatch(seg, targetArray,
                      onSegment: onSegment,
                      onLegacyPoint: onLegacyPoint,
                      onUnsupported: onUnsupportedSegment);
                }
              }
              if (rootDepth > 0) rootDepth--;
            case JsonEventType.arrayStart:
              if (collector.active) {
                collector.handle(event);
              }
            case JsonEventType.arrayEnd:
              if (collector.active) {
                collector.handle(event);
              } else if (rootDepth == 1 && targetArray.isNotEmpty) {
                targetArray = ''; // ルートレベルの配列が閉じた
              }
            case JsonEventType.key:
              if (collector.active) {
                collector.handle(event);
              } else if (rootDepth == 1) {
                final k = event.key ?? '';
                if (k == 'semanticSegments' ||
                    k == 'locations' ||
                    k == 'activitySegments') {
                  targetArray = k;
                }
              }
            case JsonEventType.value:
              if (collector.active) {
                collector.handle(event);
              }
          }
        }
      }
      parser.finish();
    } on JsonParseException catch (e) {
      onError('IMP-003', 'JSON の構文エラー: ${e.message}');
    } on FormatException catch (e) {
      onError('IMP-003', 'JSON のデコードエラー: $e');
    }
  }

  void _dispatch(
    Map<String, Object?> seg,
    String targetArray, {
    required void Function(Map<String, Object?>) onSegment,
    required void Function(_LegacyPoint) onLegacyPoint,
    required void Function() onUnsupported,
  }) {
    if (targetArray == 'semanticSegments' || targetArray == 'activitySegments') {
      onSegment(seg);
    } else if (targetArray == 'locations') {
      final p = _LegacyPoint.fromMap(seg);
      if (p != null) onLegacyPoint(p);
    } else {
      onUnsupported();
    }
  }

  // --- セグメント → 正規化レコード ---

  NormalizedRecord? _segmentToRecord(Map<String, Object?> seg) {
    final (start, end) = _segmentRange(seg);
    if (start == null || end == null) return null;

    final visit = seg['visit'];
    if (visit is Map<String, Object?>) {
      return _visitToRecord(visit, start, end);
    }

    final activity = seg['activity'];
    if (activity is Map<String, Object?>) {
      return _activityToRecord(activity, start, end, seg);
    }

    return null;
  }

  /// セグメントの開始・終了時刻を返す（semanticSegments は start/end、
  /// 旧 activitySegments は duration を使う）。
  (DateTime?, DateTime?) _segmentRange(Map<String, Object?> seg) {
    final start = _ts(seg['start']);
    final end = _ts(seg['end']);
    if (start != null || end != null) return (start, end);
    final duration = seg['duration'];
    if (duration is Map<String, Object?>) {
      return (
        _ts(duration['startTimestampMs']),
        _ts(duration['endTimestampMs']),
      );
    }
    return (null, null);
  }

  NormalizedVisit? _visitToRecord(
      Map<String, Object?> visit, DateTime start, DateTime end) {
    final loc = _visitLocation(visit);
    final lat = loc?['latitudeE7'];
    final lng = loc?['longitudeE7'];
    int? latE7;
    int? lngE7;
    if (lat is num && lng is num) {
      latE7 = lat.toInt();
      lngE7 = lng.toInt();
    }
    if (latE7 == null || lngE7 == null) return null;

    final placeId = (visit['topCandidate'] is Map<String, Object?>)
        ? (visit['topCandidate'] as Map<String, Object?>)['placeId']
        : null;
    final semanticType = (visit['topCandidate'] is Map<String, Object?>)
        ? (visit['topCandidate'] as Map<String, Object?>)['semanticType']
        : null;
    final confidence = visit['locationConfidence'];

    final key = placeId is String
        ? sourceKeyGenerator
            .fromStableId(recordType: 'visit', id: placeId)
        : sourceKeyGenerator.fingerprint(
            recordType: 'visit',
            startAtUtc: start,
            endAtUtc: end,
            latE7: latE7,
            lngE7: lngE7,
          );

    return NormalizedVisit(
      sourceKey: key,
      startAtUtc: start,
      endAtUtc: end,
      latLng: LatLngE7(latE7, lngE7),
      sourceLabel: semanticType is String ? semanticType : null,
      confidence: confidence is num ? confidence.toDouble() : null,
    );
  }

  NormalizedMovement _activityToRecord(Map<String, Object?> activity,
      DateTime start, DateTime end, Map<String, Object?> segment) {
    final activityType = activity['activityType'];
    final distance = activity['distance'];

    var path = _waypoints(activity['waypoints']);
    if (path.isEmpty) {
      path = _timelinePathCoords(segment['timelinePath']);
    }

    int? distanceM;
    DistanceMethod method;
    if (distance is num && distance > 0) {
      distanceM = distance.toInt();
      method = DistanceMethod.recorded;
    } else if (path.length >= 2) {
      distanceM = distanceService.pathMeters(path).round();
      method = DistanceMethod.estimatedPath;
    } else {
      distanceM = null;
      method = DistanceMethod.unknown;
    }

    final confidence = activity['confidence'];
    final startLatLng = path.isNotEmpty ? path.first : null;
    final endLatLng = path.isNotEmpty ? path.last : null;

    final key = sourceKeyGenerator.fingerprint(
      recordType: 'movement',
      startAtUtc: start,
      endAtUtc: end,
      latE7: startLatLng?.latE7,
      lngE7: startLatLng?.lngE7,
      normalizedActivity: activityType is String ? activityType : null,
    );

    return NormalizedMovement(
      sourceKey: key,
      startAtUtc: start,
      endAtUtc: end,
      distanceM: distanceM,
      distanceMethod: method,
      activityType: activityType is String ? activityType : null,
      confidence: confidence is num ? confidence.toDouble() : null,
      startLatLng: startLatLng,
      endLatLng: endLatLng,
      path: path,
    );
  }

  Map<String, Object?>? _visitLocation(Map<String, Object?> visit) {
    final top = visit['topCandidate'];
    if (top is Map<String, Object?>) {
      final l = top['location'];
      if (l is Map<String, Object?>) return l;
      return top;
    }
    final pl = visit['placeLocation'];
    if (pl is Map<String, Object?>) return pl;
    final cands = visit['candidates'];
    if (cands is List && cands.isNotEmpty) {
      final c0 = cands.first;
      if (c0 is Map<String, Object?>) {
        final l = c0['location'];
        if (l is Map<String, Object?>) return l;
        return c0;
      }
    }
    return null;
  }

  List<LatLngE7> _waypoints(Object? waypoints) {
    if (waypoints is! List) return const [];
    final out = <LatLngE7>[];
    for (final w in waypoints) {
      if (w is Map<String, Object?>) {
        final lat = w['latE7'];
        final lng = w['lngE7'];
        if (lat is num && lng is num) {
          out.add(LatLngE7(lat.toInt(), lng.toInt()));
        }
      }
    }
    return out;
  }

  List<LatLngE7> _timelinePathCoords(Object? tp) {
    if (tp is! List) return const [];
    final out = <LatLngE7>[];
    for (final e in tp) {
      if (e is Map<String, Object?>) {
        final p = e['point'];
        if (p is String) {
          final parts = p.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0].trim());
            final lng = double.tryParse(parts[1].trim());
            if (lat != null && lng != null) {
              out.add(LatLngE7((lat * 1e7).round(), (lng * 1e7).round()));
            }
          }
        }
      }
    }
    return out;
  }

  // --- 旧形式: 点列 → 訪問・移動 ---

  List<NormalizedRecord> _deriveLegacyRecords(List<_LegacyPoint> points) {
    if (points.isEmpty) return const [];
    points.sort((a, b) => a.at.compareTo(b.at));

    final visits = <NormalizedVisit>[];
    var i = 0;
    while (i < points.length) {
      final anchor = points[i];
      var j = i;
      var sumLat = 0.0;
      var sumLng = 0.0;
      var cnt = 0;
      while (j < points.length) {
        final d = distanceService.haversineMeters(anchor.coord, points[j].coord);
        if (d > legacyStayRadiusM) break;
        sumLat += points[j].coord.lat;
        sumLng += points[j].coord.lng;
        cnt++;
        j++;
      }
      if (cnt >= legacyMinConsecutivePoints) {
        final start = points[i].at;
        final end = points[j - 1].at;
        final centroid = LatLngE7(
            (sumLat / cnt * 1e7).round(), (sumLng / cnt * 1e7).round());
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
      i = j;
    }

    // 訪問間のギャップを移動として生成
    final records = <NormalizedRecord>[...visits];
    for (var k = 0; k + 1 < visits.length; k++) {
      final from = visits[k];
      final to = visits[k + 1];
      final distanceM =
          distanceService.haversineMeters(from.latLng, to.latLng).round();
      if (distanceM <= 5) continue; // ノイズ
      records.add(NormalizedMovement(
        sourceKey: sourceKeyGenerator.fingerprint(
          recordType: 'movement',
          startAtUtc: from.endAtUtc,
          endAtUtc: to.startAtUtc,
          latE7: from.latLng.latE7,
          lngE7: from.latLng.lngE7,
          normalizedActivity: null,
        ),
        startAtUtc: from.endAtUtc,
        endAtUtc: to.startAtUtc,
        distanceM: distanceM,
        distanceMethod: DistanceMethod.estimatedDirect,
        startLatLng: from.latLng,
        endLatLng: to.latLng,
      ));
    }
    return records;
  }

  DateTime? _ts(Object? v) {
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
    }
    if (v is String) {
      final ms = int.tryParse(v);
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      }
    }
    if (v is Map<String, Object?>) {
      // 稀に { "timestampMs": ... } の形
      return _ts(v['timestampMs']);
    }
    return null;
  }
}

/// 旧形式の 1 点。
class _LegacyPoint {
  const _LegacyPoint({required this.at, required this.coord});

  final DateTime at;
  final LatLngE7 coord;

  static _LegacyPoint? fromMap(Map<String, Object?> m) {
    final ts = m['timestampMs'];
    final lat = m['latitudeE7'];
    final lng = m['longitudeE7'];
    if (ts is! num && ts is! String) return null;
    final at = ts is num
        ? DateTime.fromMillisecondsSinceEpoch(ts.toInt(), isUtc: true)
        : int.tryParse(ts as String)?.let(
            (ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true));
    if (at == null || lat is! num || lng is! num) return null;
    return _LegacyPoint(at: at, coord: LatLngE7(lat.toInt(), lng.toInt()));
  }
}

extension<T> on T {
  R? let<R>(R Function(T) f) => f(this);
}

/// ターゲット配列内の 1 オブジェクトを丸ごと捕捉するコレクタ。
class _SegmentCollector {
  bool active = false;
  Map<String, Object?>? completed;

  final List<Object> _containers = [];
  final List<String?> _keys = [];
  final List<bool> _isMap = [];
  int _depth = 0;

  void reset() {
    active = false;
    completed = null;
    _containers.clear();
    _keys.clear();
    _isMap.clear();
    _depth = 0;
  }

  void handle(JsonEvent e) {
    switch (e.type) {
      case JsonEventType.objectStart:
        _push(<String, Object?>{}, isMap: true);
      case JsonEventType.arrayStart:
        _push(<Object?>[], isMap: false);
      case JsonEventType.objectEnd:
      case JsonEventType.arrayEnd:
        _pop();
      case JsonEventType.key:
        if (_isMap.isNotEmpty && _isMap.last) {
          _keys[_keys.length - 1] = e.key;
        }
      case JsonEventType.value:
        _attach(e.value);
    }
  }

  void _push(Object container, {required bool isMap}) {
    if (_containers.isNotEmpty) {
      final parent = _containers.last;
      if (parent is Map<String, Object?>) {
        parent[_keys.last ?? ''] = container;
        _keys[_keys.length - 1] = null;
      } else {
        (parent as List<Object?>).add(container);
      }
    }
    _containers.add(container);
    _keys.add(null);
    _isMap.add(isMap);
    _depth++;
    if (_depth == 1) active = true;
  }

  void _pop() {
    if (_containers.isEmpty) return;
    final removed = _containers.removeLast();
    _keys.removeLast();
    _isMap.removeLast();
    _depth--;
    if (_depth == 0) {
      active = false;
      if (removed is Map<String, Object?>) completed = removed;
    }
  }

  void _attach(Object? v) {
    if (_containers.isEmpty) return;
    final top = _containers.last;
    if (top is Map<String, Object?>) {
      top[_keys.last ?? ''] = v;
      _keys[_keys.length - 1] = null;
    } else {
      (top as List<Object?>).add(v);
    }
  }
}
