import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/models/lat_lng.dart';
import 'package:kurashilog/domain/services/clustering_service.dart';

void main() {
  test('nearby samples in adjacent cells merge deterministically', () {
    final at = DateTime.utc(2026, 7, 1);
    final samples = [
      VisitSample(
        coord: const LatLngE7(356812360, 1397671250),
        dwellSeconds: 3600,
        at: at,
      ),
      VisitSample(
        coord: const LatLngE7(356821000, 1397671250),
        dwellSeconds: 1800,
        at: at.add(const Duration(days: 1)),
      ),
    ];

    final first = const ClusteringService().cluster(samples);
    final second = const ClusteringService().cluster(samples.reversed.toList());

    expect(first, hasLength(1));
    expect(first.single.visitCount, 2);
    expect(second.single.stableKey, first.single.stableKey);
  });
}
