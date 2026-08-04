import '../analysis/analysis_coordinator.dart';
import '../models/persistence_models.dart';
import '../repositories/kurashilog_repository.dart';

/// 地点ラベル編集の結果。
class LabelSaveResult {
  const LabelSaveResult({required this.labelId, required this.isNew});

  final int labelId;
  final bool isNew;
}

/// 頻出地点・ラベル管理（設計書 FR-070 / FR-071）。
class PlacesUseCase {
  const PlacesUseCase({required this.repository, required this.analysis});

  final KurashilogRepository repository;
  final AnalysisCoordinator analysis;

  /// 訪問回数順の地点一覧。
  Future<List<StoredCluster>> listPlaces() async {
    final clusters = await repository.allClusters();
    clusters.sort((a, b) {
      final av = a.excluded ? -1 : a.visitCount;
      final bv = b.excluded ? -1 : b.visitCount;
      return bv.compareTo(av);
    });
    return clusters;
  }

  /// 地点にラベルを保存する（新規作成または既存ラベル更新）。
  ///
  /// [displayName] が空ならラベルを解除する。
  Future<LabelSaveResult?> saveLabel({
    required int clusterId,
    required String displayName,
    String? category,
    bool isBasePlace = false,
  }) async {
    final cluster = await repository.clusterById(clusterId);
    if (cluster == null) return null;

    final now = DateTime.now();
    if (displayName.trim().isEmpty) {
      // ラベル解除
      await repository.updateClusterLabel(clusterId, null);
      await analysis.rebuildSummariesAndInsights();
      return null;
    }

    int labelId;
    var isNew = false;
    if (cluster.labelId != null) {
      labelId = cluster.labelId!;
      final existing = await repository.labelById(labelId);
      if (existing != null) {
        await repository.updateLabel(
          StoredLabel(
            id: existing.id,
            displayName: displayName.trim(),
            category: category,
            isBasePlace: isBasePlace,
            createdAt: existing.createdAt,
            updatedAt: now,
          ),
        );
      } else {
        labelId = await repository.insertLabel(
          StoredLabel(
            id: 0,
            displayName: displayName.trim(),
            category: category,
            isBasePlace: isBasePlace,
            createdAt: now,
            updatedAt: now,
          ),
        );
        isNew = true;
      }
    } else {
      labelId = await repository.insertLabel(
        StoredLabel(
          id: 0,
          displayName: displayName.trim(),
          category: category,
          isBasePlace: isBasePlace,
          createdAt: now,
          updatedAt: now,
        ),
      );
      isNew = true;
    }

    await repository.updateClusterLabel(clusterId, labelId);

    // 基準地点の設定は 1 つまで（他のラベルから解除）
    if (isBasePlace) {
      final labels = await repository.allLabels();
      for (final l in labels) {
        if (l.id != labelId && l.isBasePlace) {
          await repository.updateLabel(
            StoredLabel(
              id: l.id,
              displayName: l.displayName,
              category: l.category,
              isBasePlace: false,
              createdAt: l.createdAt,
              updatedAt: now,
            ),
          );
        }
      }
    }

    await analysis.rebuildSummariesAndInsights();
    return LabelSaveResult(labelId: labelId, isNew: isNew);
  }

  /// 分析除外の切り替え（設計書 FR-071 / AC-07）。
  Future<void> setExcluded(int clusterId, bool excluded) async {
    await repository.setClusterExcluded(clusterId, excluded);
    await analysis.rebuildSummariesAndInsights();
  }
}
