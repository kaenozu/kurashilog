import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/models/persistence_models.dart';
import '../../application/providers.dart';
import '../../domain/privacy/place_privacy.dart';
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
        error: (_, _) => const Center(child: Text('地点を読み込めませんでした')),
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
            if (cluster.category != null && !projectionNameHidden(cluster))
              _categoryLabel(cluster.category!),
            if (cluster.isBasePlace) '基準地点',
            _privacySummary(cluster.privacyMode),
          ].where((value) => value.isNotEmpty).join(' ・ '),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          tooltip: '地点の操作',
          enabled: !_busy,
          onSelected: (value) async {
            switch (value) {
              case 'label':
                await _editLabel(cluster);
              case 'privacy':
                await _editPrivacy(cluster);
              case 'map':
                await _openMap(cluster);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'label', child: Text('名前・カテゴリを編集')),
            PopupMenuItem(value: 'privacy', child: Text('プライバシー設定')),
            PopupMenuItem(value: 'map', child: Text('地図で開く')),
          ],
        ),
      ),
    );
  }

  bool projectionNameHidden(StoredCluster cluster) =>
      cluster.privacyMode == PlacePrivacyMode.hideName ||
      cluster.privacyMode == PlacePrivacyMode.exclude;

  String _privacySummary(PlacePrivacyMode mode) => switch (mode) {
    PlacePrivacyMode.visible => '',
    PlacePrivacyMode.hideName => '名前を非表示',
    PlacePrivacyMode.blurMap => '地図をぼかす',
    PlacePrivacyMode.exclude => '分析から除外',
  };

  String _categoryLabel(String category) => switch (category) {
    'home' => '住まい',
    'work' => '仕事',
    'school' => '学校',
    'leisure' => '娯楽・買い物',
    'hospital' => '医療',
    'private' => '非公開カテゴリ',
    _ => 'その他',
  };

  Future<void> _editLabel(StoredCluster cluster) async {
    final controller = TextEditingController(text: cluster.labelName ?? '');
    var category = cluster.category;
    var isBasePlace = cluster.isBasePlace;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('地点の名前・カテゴリ'),
          content: SingleChildScrollView(
            child: Column(
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
                    DropdownMenuItem(value: 'work', child: Text('仕事')),
                    DropdownMenuItem(value: 'school', child: Text('学校')),
                    DropdownMenuItem(value: 'leisure', child: Text('娯楽・買い物')),
                    DropdownMenuItem(value: 'hospital', child: Text('医療')),
                    DropdownMenuItem(value: 'private', child: Text('非公開カテゴリ')),
                    DropdownMenuItem(value: 'other', child: Text('その他')),
                  ],
                  onChanged: (value) => setDialogState(() => category = value),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('基準地点にする（自宅など）'),
                  subtitle: const Text('基準地点は1つだけ設定できます'),
                  value: isBasePlace,
                  onChanged: (value) =>
                      setDialogState(() => isBasePlace = value),
                ),
              ],
            ),
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

  Future<void> _editPrivacy(StoredCluster cluster) async {
    var selected = cluster.privacyMode;
    final result = await showDialog<PlacePrivacyMode>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('プライバシー設定'),
          content: SingleChildScrollView(
            child: RadioGroup<PlacePrivacyMode>(
              groupValue: selected,
              onChanged: (value) {
                if (value != null) setDialogState(() => selected = value);
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    value: PlacePrivacyMode.visible,
                    title: Text('通常表示'),
                    subtitle: Text('名前と位置をアプリ内で表示します'),
                  ),
                  RadioListTile(
                    value: PlacePrivacyMode.hideName,
                    title: Text('名前を非表示'),
                    subtitle: Text('地点名とカテゴリを「非公開の場所」に置き換えます'),
                  ),
                  RadioListTile(
                    value: PlacePrivacyMode.blurMap,
                    title: Text('地図をぼかす'),
                    subtitle: Text('アプリ内の地図位置をおおよその位置に丸めます'),
                  ),
                  RadioListTile(
                    value: PlacePrivacyMode.exclude,
                    title: Text('分析から除外'),
                    subtitle: Text('ランキング・集計・分析の対象から外します'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result == cluster.privacyMode || !mounted) return;

    await _runBusy(
      () => ref.read(placesUseCaseProvider).setPrivacyMode(cluster.id, result),
    );
  }

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
