import 'dart:math' as math;

import '../models/lat_lng.dart';

/// クラスタリング結果の 1 地点。
class Cluster {
  const Cluster({
    required this.centroidLatE7,
    required this.centroidLngE7,
    required this.radiusM,
    required this.visitCount,
    required this.dwellSeconds,
    required this.firstAt,
    required this.lastAt,
    required this.stableKey,
  });

  final int centroidLatE7;
  final int centroidLngE7;
  final double radiusM;
  final int visitCount;
  final int dwellSeconds;
  final DateTime firstAt;
  final DateTime lastAt;
  final String stableKey;
}

/// クラスタリングの入力（訪問 1 件）。
class VisitSample {
  const VisitSample({
    required this.coord,
    required this.dwellSeconds,
    required this.at,
  });

  final LatLngE7 coord;
  final int dwellSeconds;
  final DateTime at;
}

/// 地点クラスタリング（設計書 6.1）。
///
/// MVP は決定的で軽量なグリッド方式を採用する。
/// 訪問座標を約 150m 相当のセルへ割り当て、隣接セルの重み付き重心が
/// 180m 以内なら Union-Find で統合する。重みは滞在秒数（上限付き）を使用。
class ClusteringService {
  const ClusteringService({
    this.cellSizeM = 150.0,
    this.maxMergeDistanceM = 180.0,
    this.maxDwellWeightSeconds = 12 * 60 * 60,
  });

  /// グリッド 1 セルの一辺（メートル）。
  final double cellSizeM;

  /// 隣接セルの重心を統合する距離閾値（メートル）。
  final double maxMergeDistanceM;

  /// 重み付き重心の重み上限（滞在秒数）。
  final int maxDwellWeightSeconds;

  /// WGS84 長半径（Web Mercator 変換用）。
  static const double wgs84SemiMajorAxis = 6378137.0;

  /// 入力が空なら空リストを返す。
  List<Cluster> cluster(List<VisitSample> samples) {
    if (samples.isEmpty) return const [];

    // 1. 座標を Web Mercator へ変換し、グリッドキーを算出する。
    final cells = <String, _CellAgg>{};
    for (final s in samples) {
      final (x, y) = _toMercator(s.coord);
      final key = _cellKey(x, y);
      cells.putIfAbsent(key, () => _CellAgg()).add(s);
    }

    // 2. 隣接 8 セルを探索し、重心距離 180m 以内のグループを Union-Find で統合。
    final uf = _UnionFind(cells.keys.toList());
    for (final key in cells.keys) {
      final agg = cells[key]!;
      final (cx, cy) = agg.cell;
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          final nk = _cellKey(cx + dx * cellSizeM, cy + dy * cellSizeM);
          final nagg = cells[nk];
          if (nagg == null) continue;
          final dist = _metersBetween(agg.centroid, nagg.centroid);
          if (dist <= maxMergeDistanceM) {
            uf.union(key, nk);
          }
        }
      }
    }

    // 3. 統合後の重心・半径・集計値を計算する。
    final groups = <String, List<_CellAgg>>{};
    for (final key in cells.keys) {
      groups.putIfAbsent(uf.find(key), () => []).add(cells[key]!);
    }

    final result = <Cluster>[];
    for (final group in groups.values) {
      result.add(_mergeGroup(group));
    }
    result.sort((a, b) => b.visitCount.compareTo(a.visitCount));
    return result;
  }

  Cluster _mergeGroup(List<_CellAgg> group) {
    var totalWeight = 0.0;
    var wLat = 0.0;
    var wLng = 0.0;
    var visitCount = 0;
    var dwell = 0;
    var firstAt = group.first.firstAt;
    var lastAt = group.first.lastAt;

    for (final agg in group) {
      final weight =
          math.min(agg.dwellSeconds, maxDwellWeightSeconds).toDouble().clamp(1.0, double.infinity);
      totalWeight += weight;
      wLat += agg.centroid.lat * weight;
      wLng += agg.centroid.lng * weight;
      visitCount += agg.visitCount;
      dwell += agg.dwellSeconds;
      if (agg.firstAt.isBefore(firstAt)) firstAt = agg.firstAt;
      if (agg.lastAt.isAfter(lastAt)) lastAt = agg.lastAt;
    }

    final cLat = wLat / totalWeight;
    final cLng = wLng / totalWeight;
    final centroid = LatLngE7((cLat * 1e7).round(), (cLng * 1e7).round());

    var maxRadius = 0.0;
    for (final agg in group) {
      final d = _metersBetween(centroid, agg.centroid);
      if (d > maxRadius) maxRadius = d;
    }
    // セル対角線の半分を半径に加算（セル内部の広がりを近似）。
    maxRadius += (cellSizeM * math.sqrt2) / 2;

    final rounded = centroid.roundForKey();
    final stableKey = 'cluster|${rounded.latE7}|${rounded.lngE7}';

    return Cluster(
      centroidLatE7: centroid.latE7,
      centroidLngE7: centroid.lngE7,
      radiusM: maxRadius,
      visitCount: visitCount,
      dwellSeconds: dwell,
      firstAt: firstAt,
      lastAt: lastAt,
      stableKey: stableKey,
    );
  }

  // --- Web Mercator ---

  (double, double) _toMercator(LatLngE7 c) {
    final latRad = c.lat * math.pi / 180;
    final x = c.lng * wgs84SemiMajorAxis * math.pi / 180;
    final y = wgs84SemiMajorAxis * math.log(math.tan(math.pi / 4 + latRad / 2));
    return (x, y);
  }

  double _metersBetween(LatLngE7 a, LatLngE7 b) {
    final dLat = (b.lat - a.lat) * math.pi / 180;
    final dLng = (b.lng - a.lng) * math.pi / 180;
    final lat1 = a.lat * math.pi / 180;
    final lat2 = b.lat * math.pi / 180;
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    return 2 * wgs84SemiMajorAxis * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  String _cellKey(double x, double y) {
    final cx = (x / cellSizeM).floor();
    final cy = (y / cellSizeM).floor();
    return '$cx,$cy';
  }
}

/// 1 グリッドセル分の集計。
class _CellAgg {
  _CellAgg();

  (double, double) cell = (0, 0);
  int visitCount = 0;
  int dwellSeconds = 0;
  var wLat = 0.0;
  var wLng = 0.0;
  DateTime? _firstAt;
  DateTime? _lastAt;

  LatLngE7 get centroid => LatLngE7(
        (wLat / visitCount * 1e7).round(),
        (wLng / visitCount * 1e7).round(),
      );

  DateTime get firstAt => _firstAt!;
  DateTime get lastAt => _lastAt!;

  void add(VisitSample s) {
    visitCount++;
    dwellSeconds += s.dwellSeconds;
    wLat += s.coord.lat;
    wLng += s.coord.lng;
    _firstAt ??= s.at;
    _lastAt ??= s.at;
    if (s.at.isBefore(_firstAt!)) _firstAt = s.at;
    if (s.at.isAfter(_lastAt!)) _lastAt = s.at;
  }
}

/// Union-Find（経路圧縮 + ランク）。
class _UnionFind {
  _UnionFind(List<String> keys) {
    for (final k in keys) {
      parent[k] = k;
      rank[k] = 0;
    }
  }

  final Map<String, String> parent = {};
  final Map<String, int> rank = {};

  String find(String x) {
    final p = parent[x]!;
    if (p != x) {
      parent[x] = find(p);
    }
    return parent[x]!;
  }

  void union(String a, String b) {
    final ra = find(a);
    final rb = find(b);
    if (ra == rb) return;
    final raRank = rank[ra]!;
    final rbRank = rank[rb]!;
    if (raRank < rbRank) {
      parent[ra] = rb;
    } else if (raRank > rbRank) {
      parent[rb] = ra;
    } else {
      parent[rb] = ra;
      rank[ra] = raRank + 1;
    }
  }
}
