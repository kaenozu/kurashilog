import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/models/persistence_models.dart';
import '../../domain/models/lat_lng.dart';
import '../../shared/widgets.dart';

/// 頻出地点（設計書 SC-08 / FR-070 / FR-071）。
class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dashboardRefreshProvider);
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
            itemBuilder: (context, i) => _PlaceTile(
              cluster: clusters[i],
              rank: i + 1,
            ),
          );
        },
      ),
    );
  }
}

final _placesProvider =
    FutureProvider.autoDispose<List<StoredCluster>>(
  (ref) => ref.watch(placesUseCaseProvider).listPlaces(),
);

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
    final c = widget.cluster;

    return Card(
      child: ListTile(
        enabled: !_busy,
        leading: CircleAvatar(
          backgroundColor: c.excluded
              ? scheme.surfaceContainerHighest
              : scheme.primaryContainer,
          child: Text(
            '${widget.rank}',
            style: TextStyle(
              color: c.excluded ? scheme.onSurfaceVariant : scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          c.displayName,
          style: c.excluded
              ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
              : null,
        ),
        subtitle: Text(
          [
            if (c.labelName != null && c.labelName!.isNotEmpty) 'ラベル: ${c.labelName}',
            '訪問 ${c.visitCount} 回',
            '滞在 ${_dwell(c.dwellSeconds)}',
            if (c.isBasePlace) '基準地点',
            if (c.excluded) '分析除外中',
          ].join(' ・ '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'label':
                await _editLabel(c);
              case 'exclude':
                await _toggleExclude(c);
              case 'map':
                await _openMap(c);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'label', child: Text('ラベルを編集')),
            PopupMenuItem(
              value: 'exclude',
              child: Text(c.excluded ? '分析除外を解除' : '分析から除外'),
            ),
            const PopupMenuItem(value: 'map', child: Text('地図で開く')),
          ],
        ),
      ),
    );
  }

  Future<void> _editLabel(StoredCluster c) async {
    final controller = TextEditingController(text: c.labelName ?? '');
    var category = c.category;
    var isBasePlace = c.isBasePlace;

    await showDialog<void>(
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
                value: category,
                decoration: const InputDecoration(labelText: 'カテゴリ'),
                items: const [
                  DropdownMenuItem(value: 'home', child: Text('住まい')),
                  DropdownMenuItem(value: 'work', child: Text('仕事・学校')),
                  DropdownMenuItem(value: 'leisure', child: Text('娯楽・買い物')),
                  DropdownMenuItem(value: 'other', child: Text('その他')),
                ],
                onChanged: (v) => setDialogState(() => category = v),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('基準地点にする（自宅など）'),
                value: isBasePlace,
                onChanged: (v) => setDialogState(() => isBasePlace = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => _busy = true);
                await ref.read(placesUseCaseProvider).saveLabel(
                      clusterId: c.id,
                      displayName: controller.text,
                      category: category,
                      isBasePlace: isBasePlace,
                    );
                if (mounted) {
                  setState(() => _busy = false);
                  ref.read(dashboardRefreshProvider.notifier).state++;
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _toggleExclude(StoredCluster c) async {
    setState(() => _busy = true);
    await ref
        .read(placesUseCaseProvider)
        .setExcluded(c.id, !c.excluded);
    if (mounted) {
      setState(() => _busy = false);
      ref.read(dashboardRefreshProvider.notifier).state++;
    }
  }

  Future<void> _openMap(StoredCluster c) async {
    final ok = await ref
        .read(externalMapOpenerProvider)
        .open(c.centroid, label: c.displayName);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('地図アプリが開けませんでした')));
    }
  }

  String _dwell(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h時間$m分';
    return '$m分';
  }
}
