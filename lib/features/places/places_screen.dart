import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/models/persistence_models.dart';
import '../../domain/privacy/place_privacy.dart';
import '../../application/providers.dart';
import '../../shared/widgets.dart';

/// 頻出地点（設計書 SC-08 / FR-070 / FR-071）。
class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(_placesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('頻出地点')),
      body: places.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (clusters) {
          if (clusters.isEmpty) {
            return const EmptyState(
              icon: Icons.place_outlined,
              title: '地点データがありません',
              message: 'タイムラインを取り込むと、よく訪れる場所が表示されます。',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: clusters.length,
            itemBuilder: (context, i) =>
                _PlaceTile(cluster: clusters[i], rank: i + 1),
          );
        },
      ),
    );
  }
}

final _placesProvider = FutureProvider.autoDispose<List<StoredCluster>>((ref) {
  ref.watch(dashboardRefreshProvider);
  return ref.watch(placesUseCaseProvider).listPlaces();
});

class _PlaceTile extends ConsumerStatefulWidget {
  const _PlaceTile({required this.cluster, required this.rank});

  final StoredCluster cluster;
  final int rank;

  @override
  ConsumerState<_PlaceTile> createState() => _PlaceTileState();
}

class _PlaceTileState extends ConsumerState<_PlaceTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cluster = widget.cluster;
    final projection = const PlacePrivacyProjector().forApp(cluster);
    final isExcluded = cluster.excludedFromAnalysis;

    return Card(
      child: ListTile(
        enabled: !_busy,
        leading: CircleAvatar(
          backgroundColor: isExcluded
              ? scheme.surfaceContainerHighest
              : scheme.primaryContainer,
          child: Text(
            '${widget.rank}',
            style: TextStyle(
              color: isExcluded
                  ? scheme.onSurfaceVariant
                  : scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          projection?.displayName ?? '非公開の場所',
          style: isExcluded
              ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
              : null,
        ),
        subtitle: Text(
          [
            if (projection != null &&
                !projection.nameRedacted &&
                cluster.labelName != null &&
                cluster.labelName!.isNotEmpty)
              'ラベル: ${projection.displayName}',
            '訪問 ${cluster.visitCount} 回',
            '滞在 ${_dwell(cluster.dwellSeconds)}',
            if (cluster.isBasePlace) '基準地点',
            if (isExcluded) '分析除外中',
          ].join(' ・ '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          enabled: !_busy,
          onSelected: (value) async {
            switch (value) {
              case 'label':
                await _editLabel(cluster);
              case 'exclude':
                await _toggleExclude(cluster);
              case 'map':
                await _openMap(cluster);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'label', child: Text('ラベルを編集')),
            PopupMenuItem(
              value: 'exclude',
              child: Text(cluster.excluded ? '分析除外を解除' : '分析から除外'),
            ),
            const PopupMenuItem(value: 'map', child: Text('地図で開く')),
          ],
        ),
      ),
    );
  }

  Future<void> _editLabel(StoredCluster cluster) async {
    final controller = TextEditingController(text: cluster.labelName ?? '');
    var category = cluster.category;
    var isBasePlace = cluster.isBasePlace;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('地点のラベル'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '名前（例: 自宅、会社、ジム）',
                  hintText: '空にするとラベルを解除',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'カテゴリ'),
                items: const [
                  DropdownMenuItem(value: 'home', child: Text('住まい')),
                  DropdownMenuItem(value: 'work', child: Text('仕事・学校')),
                  DropdownMenuItem(value: 'leisure', child: Text('娯楽・買い物')),
                  DropdownMenuItem(value: 'other', child: Text('その他')),
                ],
                onChanged: (value) => setDialogState(() => category = value),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('基準地点にする（自宅など）'),
                value: isBasePlace,
                onChanged: (value) => setDialogState(() => isBasePlace = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    final displayName = controller.text;
    controller.dispose();
    if (save != true || !mounted) return;

    await _runBusy(() async {
      await ref
          .read(placesUseCaseProvider)
          .saveLabel(
            clusterId: cluster.id,
            displayName: displayName,
            category: category,
            isBasePlace: isBasePlace,
          );
    });
  }

  Future<void> _toggleExclude(StoredCluster cluster) => _runBusy(() async {
    await ref
        .read(placesUseCaseProvider)
        .setExcluded(cluster.id, !cluster.excluded);
  });

  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.read(dashboardRefreshProvider.notifier).state++;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('地点の更新に失敗しました')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMap(StoredCluster cluster) async {
    final projection = const PlacePrivacyProjector().forApp(cluster);
    if (projection == null || projection.mapPoint == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('この地点は地図で表示できません')));
      }
      return;
    }
    final ok = await ref
        .read(externalMapOpenerProvider)
        .open(projection.mapPoint!, label: projection.displayName);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('地図アプリが開けませんでした')));
    }
  }

  String _dwell(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '$hours時間$minutes分';
    return '$minutes分';
  }
}
