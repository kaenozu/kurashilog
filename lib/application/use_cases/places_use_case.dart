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

  static const _previousLabelPrefix = 'places.merge.previous_label.v1.';
  static const _noPreviousLabel = 'none';

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
      // ラベル解除。統合済みラベルは共有されるため、この地点だけを
      // 外したい場合は splitPlace を先に使う。
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

    // 基準地点の設定は 1 つまで（他のラベルから解除）。同じ labelId を
    // 共有する手動統合地点はまとめて同じ基準地点として扱う。
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

  /// [secondaryClusterId] を [primaryClusterId] と同じ利用者確定地点として
  /// 扱う。DB schema は増やさず、既存 labelId の共有を統合契約に使う。
  ///
  /// 分離時に元ラベルへ戻せるよう、secondary の以前の labelId を settings
  /// に保存する。座標や場所名は settings key/value に保存しない。
  Future<bool> mergePlaces({
    required int primaryClusterId,
    required int secondaryClusterId,
  }) async {
    if (primaryClusterId == secondaryClusterId) return false;
    final primary = await repository.clusterById(primaryClusterId);
    final secondary = await repository.clusterById(secondaryClusterId);
    if (primary == null || secondary == null) return false;
    if (primary.excludedFromAnalysis || secondary.excludedFromAnalysis) {
      return false;
    }
    if (primary.privacyMode != secondary.privacyMode) return false;

    final now = DateTime.now();
    var primaryLabelId = primary.labelId;
    if (primaryLabelId == null) {
      primaryLabelId = await repository.insertLabel(
        StoredLabel(
          id: 0,
          displayName: primary.displayName,
          category: primary.category,
          isBasePlace: primary.isBasePlace,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repository.updateClusterLabel(primary.id, primaryLabelId);
    }
    if (secondary.labelId == primaryLabelId) return false;

    await repository.setSetting(
      '$_previousLabelPrefix${secondary.stableKey}',
      secondary.labelId?.toString() ?? _noPreviousLabel,
    );
    await repository.updateClusterLabel(secondary.id, primaryLabelId);
    await analysis.rebuildSummariesAndInsights();
    return true;
  }

  /// 手動統合した1地点を共有ラベルから分離する。
  ///
  /// mergePlaces が保存した元 labelId があれば復元し、元ラベルが無かった
  /// 地点はラベルなしへ戻す。古い/欠損設定の場合も共有ラベルの複製を作り、
  /// 他地点の名前を壊さず安全側に分離する。
  Future<bool> splitPlace(int clusterId) async {
    final cluster = await repository.clusterById(clusterId);
    if (cluster == null || cluster.labelId == null) return false;
    final all = await repository.allClusters();
    final shared = all.where((c) => c.labelId == cluster.labelId).toList();
    if (shared.length < 2) return false;

    final key = '$_previousLabelPrefix${cluster.stableKey}';
    final previous = await repository.getSetting(key);
    if (previous?.value == _noPreviousLabel) {
      await repository.updateClusterLabel(clusterId, null);
    } else {
      final previousId = int.tryParse(previous?.value ?? '');
      final previousLabel = previousId == null
          ? null
          : await repository.labelById(previousId);
      if (previousLabel != null) {
        await repository.updateClusterLabel(clusterId, previousLabel.id);
      } else {
        final current = await repository.labelById(cluster.labelId!);
        if (current == null) {
          await repository.updateClusterLabel(clusterId, null);
        } else {
          final now = DateTime.now();
          final copiedId = await repository.insertLabel(
            StoredLabel(
              id: 0,
              displayName: current.displayName,
              category: current.category,
              isBasePlace: false,
              createdAt: now,
              updatedAt: now,
            ),
          );
          await repository.updateClusterLabel(clusterId, copiedId);
        }
      }
    }
    await repository.setSetting(key, '');
    await analysis.rebuildSummariesAndInsights();
    return true;
  }

  /// 分析除外の切り替え（設計書 FR-071 / AC-07）。
  Future<void> setExcluded(int clusterId, bool excluded) => setPrivacyMode(
    clusterId,
    excluded ? PlacePrivacyMode.exclude : PlacePrivacyMode.visible,
  );

  Future<void> setPrivacyMode(
    int clusterId,
    PlacePrivacyMode privacyMode,
  ) async {
    final cluster = await repository.clusterById(clusterId);
    if (cluster == null) return;
    if (cluster.labelId == null) {
      await repository.setClusterPrivacyMode(clusterId, privacyMode);
    } else {
      // 手動統合した地点はprivacy境界も1地点として扱い、一部だけ名前や
      // 位置が露出する状態を作らない。
      final all = await repository.allClusters();
      for (final member in all.where((c) => c.labelId == cluster.labelId)) {
        await repository.setClusterPrivacyMode(member.id, privacyMode);
      }
    }
    await analysis.rebuildSummariesAndInsights();
  }
}
