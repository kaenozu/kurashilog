import '../../application/models/persistence_models.dart';
import '../../domain/models/lat_lng.dart';
import '../../domain/services/clustering_service.dart';
import '../../domain/services/distance_service.dart';
import 'app_database.dart';
import 'kurashilog_repository_impl.dart';

/// Ensures a previous correction is inherited by at most one rebuilt cluster.
class CorrectionPreservingRepository extends KurashilogRepositoryImpl {
  CorrectionPreservingRepository(AppDatabase database) : super(database);

  @override
  Future<void> replaceAllClusters(List<StoredCluster> clusters) async {
    final existing = await allClusters();
    final matches = _matchCorrections(existing, clusters);

    await super.replaceAllClusters(clusters);

    final rebuilt = await allClusters();
    for (final cluster in rebuilt) {
      final correction = matches[cluster.stableKey];
      await updateClusterLabel(cluster.id, correction?.labelId);
      await setClusterExcluded(cluster.id, correction?.excluded ?? false);
    }
  }

  Map<String, StoredCluster> _matchCorrections(
    List<StoredCluster> existing,
    List<StoredCluster> rebuilt,
  ) {
    final result = <String, StoredCluster>{};
    final unused = {for (final cluster in existing) cluster.id: cluster};

    // Reserve exact matches before proximity matching, so an earlier nearby
    // split cannot steal the correction from the exact stable-key match.
    for (final cluster in rebuilt) {
      final exact = existing
          .where((candidate) => candidate.stableKey == cluster.stableKey)
          .firstOrNull;
      if (exact == null || !unused.containsKey(exact.id)) continue;
      result[cluster.stableKey] = exact;
      unused.remove(exact.id);
    }

    for (final cluster in rebuilt) {
      if (result.containsKey(cluster.stableKey)) continue;
      final nearest = _nearestUnused(unused.values, cluster);
      if (nearest == null) continue;
      result[cluster.stableKey] = nearest;
      unused.remove(nearest.id);
    }
    return result;
  }

  StoredCluster? _nearestUnused(
    Iterable<StoredCluster> candidates,
    StoredCluster cluster,
  ) {
    final values = candidates.toList();
    if (values.isEmpty) return null;

    const distance = DistanceService();
    final point = LatLngE7(cluster.centroidLatE7, cluster.centroidLngE7);
    var best = values.first;
    var bestDistance = distance.haversineMeters(point, best.centroid);
    for (final candidate in values.skip(1)) {
      final candidateDistance = distance.haversineMeters(
        point,
        candidate.centroid,
      );
      if (candidateDistance < bestDistance) {
        best = candidate;
        bestDistance = candidateDistance;
      }
    }

    return bestDistance <= const ClusteringService().maxMergeDistanceM
        ? best
        : null;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
