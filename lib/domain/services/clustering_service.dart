import 'dart:math' as math;

import '../models/lat_lng.dart';

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

/// 訪問座標をグリッドへ割り当て、隣接セルの重心が近い場合に統合する。
class ClusteringService {
  const ClusteringService({
    this.cellSizeM = 150.0,
    this.maxMergeDistanceM = 180.0,
    this.maxDwellWeightSeconds = 12 * 60 * 60,
  });

  final double cellSizeM;
  final double maxMergeDistanceM;
  final int maxDwellWeightSeconds;

  static const double wgs84SemiMajorAxis = 6378137.0;
  static const double maxMercatorLatitude = 85.05112878;

  List<Cluster> cluster(List<VisitSample> samples) {
    if (samples.isEmpty) return const [];

    final cells = <(int, int), _CellAgg>{};
    for (final sample in samples) {
      final (x, y) = _toMercator(sample.coord);
      final key = ((x / cellSizeM).floor(), (y / cellSizeM).floor());
      cells.putIfAbsent(key, _CellAgg.new).add(sample);
    }

    final unionFind = _UnionFind(cells.keys);
    for (final entry in cells.entries) {
      final key = entry.key;
      final aggregate = entry.value;
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          final neighborKey = (key.$1 + dx, key.$2 + dy);
          final neighbor = cells[neighborKey];
          if (neighbor == null) continue;
          if (_metersBetween(aggregate.centroid, neighbor.centroid) <=
              maxMergeDistanceM) {
            unionFind.union(key, neighborKey);
          }
        }
      }
    }

    final groups = <(int, int), List<_CellAgg>>{};
    for (final entry in cells.entries) {
      groups
          .putIfAbsent(unionFind.find(entry.key), () => <_CellAgg>[])
          .add(entry.value);
    }

    final result = groups.values.map(_mergeGroup).toList()
      ..sort((a, b) {
        final byVisits = b.visitCount.compareTo(a.visitCount);
        if (byVisits != 0) return byVisits;
        return a.stableKey.compareTo(b.stableKey);
      });
    return result;
  }

  Cluster _mergeGroup(List<_CellAgg> group) {
    var totalWeight = 0.0;
    var weightedLat = 0.0;
    var weightedLng = 0.0;
    var visitCount = 0;
    var dwellSeconds = 0;
    var firstAt = group.first.firstAt;
    var lastAt = group.first.lastAt;

    for (final aggregate in group) {
      final weight = math
          .min(aggregate.dwellSeconds, maxDwellWeightSeconds)
          .toDouble()
          .clamp(1.0, double.infinity)
          .toDouble();
      totalWeight += weight;
      weightedLat += aggregate.centroid.lat * weight;
      weightedLng += aggregate.centroid.lng * weight;
      visitCount += aggregate.visitCount;
      dwellSeconds += aggregate.dwellSeconds;
      if (aggregate.firstAt.isBefore(firstAt)) firstAt = aggregate.firstAt;
      if (aggregate.lastAt.isAfter(lastAt)) lastAt = aggregate.lastAt;
    }

    final centroid = LatLngE7(
      (weightedLat / totalWeight * 1e7).round(),
      (weightedLng / totalWeight * 1e7).round(),
    );

    var radiusM = 0.0;
    for (final aggregate in group) {
      radiusM = math.max(
        radiusM,
        _metersBetween(centroid, aggregate.centroid),
      );
    }
    radiusM += (cellSizeM * math.sqrt2) / 2;

    final roundedLat = centroid.latE7 ~/ 100;
    final roundedLng = centroid.lngE7 ~/ 100;
    return Cluster(
      centroidLatE7: centroid.latE7,
      centroidLngE7: centroid.lngE7,
      radiusM: radiusM,
      visitCount: visitCount,
      dwellSeconds: dwellSeconds,
      firstAt: firstAt,
      lastAt: lastAt,
      stableKey: 'cluster|$roundedLat|$roundedLng',
    );
  }

  (double, double) _toMercator(LatLngE7 coordinate) {
    final latitude = coordinate.lat
        .clamp(-maxMercatorLatitude, maxMercatorLatitude)
        .toDouble();
    final latitudeRadians = latitude * math.pi / 180;
    final x = coordinate.lng * wgs84SemiMajorAxis * math.pi / 180;
    final y = wgs84SemiMajorAxis *
        math.log(math.tan(math.pi / 4 + latitudeRadians / 2));
    return (x, y);
  }

  double _metersBetween(LatLngE7 a, LatLngE7 b) {
    final deltaLat = (b.lat - a.lat) * math.pi / 180;
    final deltaLng = (b.lng - a.lng) * math.pi / 180;
    final lat1 = a.lat * math.pi / 180;
    final lat2 = b.lat * math.pi / 180;
    final h = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(deltaLng / 2), 2);
    return 2 *
        wgs84SemiMajorAxis *
        math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }
}

class _CellAgg {
  int visitCount = 0;
  int dwellSeconds = 0;
  double _latitudeSum = 0;
  double _longitudeSum = 0;
  DateTime? _firstAt;
  DateTime? _lastAt;

  LatLngE7 get centroid => LatLngE7(
        (_latitudeSum / visitCount * 1e7).round(),
        (_longitudeSum / visitCount * 1e7).round(),
      );

  DateTime get firstAt => _firstAt!;
  DateTime get lastAt => _lastAt!;

  void add(VisitSample sample) {
    visitCount++;
    dwellSeconds += sample.dwellSeconds;
    _latitudeSum += sample.coord.lat;
    _longitudeSum += sample.coord.lng;
    _firstAt ??= sample.at;
    _lastAt ??= sample.at;
    if (sample.at.isBefore(_firstAt!)) _firstAt = sample.at;
    if (sample.at.isAfter(_lastAt!)) _lastAt = sample.at;
  }
}

class _UnionFind {
  _UnionFind(Iterable<(int, int)> keys) {
    for (final key in keys) {
      _parent[key] = key;
      _rank[key] = 0;
    }
  }

  final Map<(int, int), (int, int)> _parent = {};
  final Map<(int, int), int> _rank = {};

  (int, int) find((int, int) key) {
    final parent = _parent[key]!;
    if (parent != key) _parent[key] = find(parent);
    return _parent[key]!;
  }

  void union((int, int) a, (int, int) b) {
    final rootA = find(a);
    final rootB = find(b);
    if (rootA == rootB) return;

    final rankA = _rank[rootA]!;
    final rankB = _rank[rootB]!;
    if (rankA < rankB) {
      _parent[rootA] = rootB;
    } else if (rankA > rankB) {
      _parent[rootB] = rootA;
    } else {
      _parent[rootB] = rootA;
      _rank[rootA] = rankA + 1;
    }
  }
}
