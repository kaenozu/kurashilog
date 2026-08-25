from pathlib import Path

path = Path('lib/features/places/places_screen.dart')
text = path.read_text()

text = text.replace(
"""            itemBuilder: (context, i) =>
                _PlaceTile(cluster: clusters[i], rank: i + 1),
""",
"""            itemBuilder: (context, i) => _PlaceTile(
              cluster: clusters[i],
              rank: i + 1,
              allClusters: clusters,
            ),
""",
1,
)

text = text.replace(
"""class _PlaceTile extends ConsumerStatefulWidget {
  const _PlaceTile({required this.cluster, required this.rank});

  final StoredCluster cluster;
  final int rank;
""",
"""class _PlaceTile extends ConsumerStatefulWidget {
  const _PlaceTile({
    required this.cluster,
    required this.rank,
    required this.allClusters,
  });

  final StoredCluster cluster;
  final int rank;
  final List<StoredCluster> allClusters;
""",
1,
)

text = text.replace(
"""    final projection = const PlacePrivacyProjector().forApp(cluster);
    final isExcluded = cluster.excludedFromAnalysis;

    return Card(
""",
"""    final projection = const PlacePrivacyProjector().forApp(cluster);
    final isExcluded = cluster.excludedFromAnalysis;
    final mergedMembers = cluster.labelId == null
        ? const <StoredCluster>[]
        : widget.allClusters
              .where((candidate) => candidate.labelId == cluster.labelId)
              .toList(growable: false);
    final isMerged = mergedMembers.length > 1;
    final mergeCandidates = widget.allClusters
        .where(
          (candidate) =>
              candidate.id != cluster.id &&
              !candidate.excludedFromAnalysis &&
              candidate.privacyMode == cluster.privacyMode &&
              candidate.labelId != cluster.labelId,
        )
        .toList(growable: false);

    return Card(
""",
1,
)

text = text.replace(
"""            if (cluster.isBasePlace) '基準地点',
            _privacySummary(cluster.privacyMode),
""",
"""            if (cluster.isBasePlace) '基準地点',
            if (isMerged) '同じ場所として${mergedMembers.length}地点を統合',
            _privacySummary(cluster.privacyMode),
""",
1,
)

text = text.replace(
"""              case 'map':
                await _openMap(cluster);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'label', child: Text('名前・カテゴリを編集')),
            PopupMenuItem(value: 'privacy', child: Text('プライバシー設定')),
            PopupMenuItem(value: 'map', child: Text('地図で開く')),
          ],
""",
"""              case 'merge':
                await _mergePlace(cluster, mergeCandidates);
              case 'split':
                await _splitPlace(cluster);
              case 'map':
                await _openMap(cluster);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'label',
              child: Text('名前・カテゴリを編集'),
            ),
            const PopupMenuItem(
              value: 'privacy',
              child: Text('プライバシー設定'),
            ),
            if (mergeCandidates.isNotEmpty)
              const PopupMenuItem(
                value: 'merge',
                child: Text('同じ場所として統合'),
              ),
            if (isMerged)
              const PopupMenuItem(value: 'split', child: Text('統合を解除')),
            const PopupMenuItem(value: 'map', child: Text('地図で開く')),
          ],
""",
1,
)

insert_marker = """  Future<void> _runBusy(Future<void> Function() action) async {
"""
methods = """  Future<void> _mergePlace(
    StoredCluster cluster,
    List<StoredCluster> candidates,
  ) async {
    if (candidates.isEmpty) return;
    final targetId = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('同じ場所として統合'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('同じ場所だと確認できる地点を選んでください。'),
          ),
          for (final candidate in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(candidate.id),
              child: Text(
                '${candidate.displayName} ・ 訪問 ${candidate.visitCount} 回',
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
    if (targetId == null || !mounted) return;
    final target = candidates.firstWhere((candidate) => candidate.id == targetId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('地点を統合しますか？'),
        content: Text(
          '「${cluster.displayName}」と「${target.displayName}」を同じ場所として集計します。後から解除できます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('戻る'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('統合する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runBusy(() async {
      final changed = await ref
          .read(placesUseCaseProvider)
          .mergePlaces(
            primaryClusterId: cluster.id,
            secondaryClusterId: target.id,
          );
      if (!changed) throw StateError('place merge rejected');
    });
  }

  Future<void> _splitPlace(StoredCluster cluster) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('統合を解除しますか？'),
        content: const Text('この地点だけを別の場所として集計する状態へ戻します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('解除する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runBusy(() async {
      final changed = await ref.read(placesUseCaseProvider).splitPlace(cluster.id);
      if (!changed) throw StateError('place split rejected');
    });
  }

"""
if insert_marker not in text:
    raise SystemExit('busy method marker not found')
text = text.replace(insert_marker, methods + insert_marker, 1)

path.write_text(text)
