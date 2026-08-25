from pathlib import Path

path = Path('lib/application/analysis/analysis_coordinator.dart')
text = path.read_text()

helper_marker = "  Future<void> _rebuildAllSummaries() async {\n"
helper = """  /// Manual place merges share a labelId. Normalize all member clusters to
  /// the smallest concrete cluster id so summaries/evidence keep valid cluster
  /// references while counting the user-confirmed place only once.
  static Map<int, int> effectivePlaceIds(List<StoredCluster> clusters) {
    final primaryByLabel = <int, int>{};
    for (final cluster in clusters) {
      final labelId = cluster.labelId;
      if (labelId == null) continue;
      final current = primaryByLabel[labelId];
      if (current == null || cluster.id < current) {
        primaryByLabel[labelId] = cluster.id;
      }
    }
    return <int, int>{
      for (final cluster in clusters)
        cluster.id: cluster.labelId == null
            ? cluster.id
            : primaryByLabel[cluster.labelId!]!,
    };
  }

"""
if helper_marker not in text:
    raise SystemExit('helper insertion marker not found')
text = text.replace(helper_marker, helper + helper_marker, 1)

month_old = """    final labels = await repository.allLabels();
    final clusters = await repository.allClusters();
    final excludedIds = clusters
        .where((cluster) => cluster.excluded)
        .map((c) => c.id)
        .toSet();
    final baseLabel = labels.where((label) => label.isBasePlace).firstOrNull;
    final baseCluster = baseLabel == null
        ? null
        : clusters
              .where((cluster) => cluster.labelId == baseLabel.id)
              .firstOrNull;
"""
month_new = """    final labels = await repository.allLabels();
    final clusters = await repository.allClusters();
    final effectivePlaceIdByClusterId = effectivePlaceIds(clusters);
    final excludedIds = clusters
        .where((cluster) => cluster.excludedFromAnalysis)
        .map((c) => c.id)
        .toSet();
    final baseLabel = labels.where((label) => label.isBasePlace).firstOrNull;
    final baseCluster = baseLabel == null
        ? null
        : clusters
              .where((cluster) => cluster.labelId == baseLabel.id)
              .firstOrNull;
    final baseEffectivePlaceId = baseCluster == null
        ? null
        : effectivePlaceIdByClusterId[baseCluster.id];
"""
if month_old not in text:
    raise SystemExit('month place block not found')
text = text.replace(month_old, month_new, 1)

visit_old = """                (visit) => DailyVisitInput(
                  startAtUtc: visit.startAtUtc,
                  endAtUtc: visit.endAtUtc,
                  clusterId: visit.clusterId,
                  excluded:
                      visit.clusterId != null &&
                      excludedIds.contains(visit.clusterId),
                  outsideBasePlace:
                      baseCluster != null && visit.clusterId != baseCluster.id,
                ),
"""
visit_new = """                (visit) {
                  final rawClusterId = visit.clusterId;
                  final effectiveClusterId = rawClusterId == null
                      ? null
                      : effectivePlaceIdByClusterId[rawClusterId] ?? rawClusterId;
                  return DailyVisitInput(
                    startAtUtc: visit.startAtUtc,
                    endAtUtc: visit.endAtUtc,
                    clusterId: effectiveClusterId,
                    excluded:
                        rawClusterId != null && excludedIds.contains(rawClusterId),
                    outsideBasePlace:
                        baseEffectivePlaceId != null &&
                        effectiveClusterId != baseEffectivePlaceId,
                  );
                },
"""
if visit_old not in text:
    raise SystemExit('daily visit mapping not found')
text = text.replace(visit_old, visit_new, 1)

context_old = """    final clusters = await repository.allClusters();
    final excludedIds = clusters
        .where((cluster) => cluster.excluded)
        .map((c) => c.id)
        .toSet();
    final labels = await repository.allLabels();
    final baseLabel = labels.where((label) => label.isBasePlace).firstOrNull;
    final baseCluster = baseLabel == null
        ? null
        : clusters
              .where((cluster) => cluster.labelId == baseLabel.id)
              .firstOrNull;
"""
context_new = """    final clusters = await repository.allClusters();
    final effectivePlaceIdByClusterId = effectivePlaceIds(clusters);
    final excludedIds = clusters
        .where((cluster) => cluster.excludedFromAnalysis)
        .map((c) => c.id)
        .toSet();
    final labels = await repository.allLabels();
    final baseLabel = labels.where((label) => label.isBasePlace).firstOrNull;
    final baseCluster = baseLabel == null
        ? null
        : clusters
              .where((cluster) => cluster.labelId == baseLabel.id)
              .firstOrNull;
    final baseEffectivePlaceId = baseCluster == null
        ? null
        : effectivePlaceIdByClusterId[baseCluster.id];
    final representativeByEffectiveId = <int, StoredCluster>{};
    for (final cluster in clusters) {
      final effectiveId = effectivePlaceIdByClusterId[cluster.id] ?? cluster.id;
      representativeByEffectiveId.putIfAbsent(effectiveId, () => cluster);
    }
"""
if context_old not in text:
    raise SystemExit('insight place block not found')
text = text.replace(context_old, context_new, 1)

counts_old = """        final id = visit.clusterId;
        if (id == null || excludedIds.contains(id)) continue;
        result[id] = (result[id] ?? 0) + 1;
"""
counts_new = """        final rawId = visit.clusterId;
        if (rawId == null || excludedIds.contains(rawId)) continue;
        final id = effectivePlaceIdByClusterId[rawId] ?? rawId;
        result[id] = (result[id] ?? 0) + 1;
"""
if counts_old not in text:
    raise SystemExit('cluster count block not found')
text = text.replace(counts_old, counts_new, 1)

median_return_old = """        if (local.weekday > DateTime.friday ||
            visit.clusterId != baseCluster.id) {
          continue;
        }
"""
median_return_new = """        final rawId = visit.clusterId;
        final effectiveId = rawId == null
            ? null
            : effectivePlaceIdByClusterId[rawId] ?? rawId;
        if (local.weekday > DateTime.friday ||
            effectiveId != baseEffectivePlaceId) {
          continue;
        }
"""
if median_return_old not in text:
    raise SystemExit('median return block not found')
text = text.replace(median_return_old, median_return_new, 1)

holiday_old = """        if (!holiday ||
            visit.clusterId == baseCluster.id ||
            excludedIds.contains(visit.clusterId)) {
          continue;
        }
"""
holiday_new = """        final rawId = visit.clusterId;
        final effectiveId = rawId == null
            ? null
            : effectivePlaceIdByClusterId[rawId] ?? rawId;
        if (!holiday ||
            effectiveId == baseEffectivePlaceId ||
            excludedIds.contains(rawId)) {
          continue;
        }
"""
if holiday_old not in text:
    raise SystemExit('holiday radius block not found')
text = text.replace(holiday_old, holiday_new, 1)

base_id_old = """      baseClusterId: baseCluster?.id,
"""
base_id_new = """      baseClusterId: baseEffectivePlaceId,
"""
if base_id_old not in text:
    raise SystemExit('base cluster id field not found')
text = text.replace(base_id_old, base_id_new, 1)

maps_old = """      clusterCentroids: {
        for (final cluster in clusters)
          cluster.id: (cluster.centroidLatE7, cluster.centroidLngE7),
      },
      clusterNames: {
        for (final cluster in clusters) cluster.id: cluster.displayName,
      },
"""
maps_new = """      clusterCentroids: {
        for (final entry in representativeByEffectiveId.entries)
          entry.key: (entry.value.centroidLatE7, entry.value.centroidLngE7),
      },
      clusterNames: {
        for (final entry in representativeByEffectiveId.entries)
          entry.key: entry.value.displayName,
      },
"""
if maps_old not in text:
    raise SystemExit('cluster evidence maps not found')
text = text.replace(maps_old, maps_new, 1)

path.write_text(text)
