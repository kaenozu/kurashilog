import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/display_preferences.dart';
import '../../application/providers.dart';
import '../../application/use_cases/settings_use_case.dart';
import '../../application/use_cases/dashboard_use_case.dart';
import '../../domain/models/lat_lng.dart';
import '../../shared/widgets.dart';

/// 日別タイムライン（設計書 SC-07 / FR-060 / US-03）。
class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.localDate});

  final String localDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_dayDetailProvider(localDate));
    final distanceUnit =
        ref.watch(appSettingsProvider).valueOrNull?.distanceUnit ??
        DistanceUnit.km;

    return Scaffold(
      appBar: AppBar(title: Text(_formatDate(localDate))),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (d) {
          if (d.entries.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: '記録がありません',
              message: 'この日の記録は見つかりませんでした。',
            );
          }
          return _TimelineBody(data: d, distanceUnit: distanceUnit);
        },
      ),
    );
  }
}

final _dayDetailProvider = FutureProvider.autoDispose
    .family<DayDetailData, String>(
      (ref, date) => ref.watch(dashboardUseCaseProvider).dayDetail(date),
    );

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({required this.data, required this.distanceUnit});

  final DayDetailData data;
  final DistanceUnit distanceUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat('HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.directions_walk, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '移動距離 合計 ${formatDistance(data.totalDistanceM, distanceUnit)}',
              style: theme.textTheme.titleSmall,
            ),
            const Spacer(),
            if (data.outing)
              Chip(
                label: const Text('外出あり'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 12),
        // 縦タイムライン（設計書 6.2「縦タイムラインで情報を視覚化」）
        for (var i = 0; i < data.entries.length; i++)
          _TimelineRow(
            entry: data.entries[i],
            timeFmt: timeFmt,
            isLast: i == data.entries.length - 1,
            distanceUnit: distanceUnit,
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  const _TimelineRow({
    required this.entry,
    required this.timeFmt,
    required this.isLast,
    required this.distanceUnit,
  });

  final DayTimelineEntry entry;
  final DateFormat timeFmt;
  final bool isLast;
  final DistanceUnit distanceUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isVisit = entry.kind == 'visit';
    final color = isVisit ? scheme.primary : scheme.tertiary;

    final time =
        '${timeFmt.format(entry.startsAt)}〜${timeFmt.format(entry.endsAt)}';
    final subtitle = isVisit
        ? (entry.dwellMinutes != null ? '滞在 ${entry.dwellMinutes!} 分' : '訪問')
        : [
            if (entry.distanceM != null)
              formatDistance(entry.distanceM!, distanceUnit),
            if (entry.activityType != null) _activityLabel(entry.activityType!),
            if (entry.distanceLabel != null) entry.distanceLabel!,
          ].join(' ・ ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  isVisit ? Icons.place : Icons.directions,
                  size: 18,
                  color: color,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: scheme.outlineVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isVisit ? (entry.placeName ?? '不明な地点') : '移動',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          if (isVisit && entry.latLng != null)
                            IconButton(
                              tooltip: '地図で開く',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.open_in_new, size: 18),
                              onPressed: () async {
                                final (lat, lng) = entry.latLng!;
                                final ok = await ref
                                    .read(externalMapOpenerProvider)
                                    .open(LatLngE7(lat, lng));
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('地図アプリが開けませんでした'),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                      Text(time, style: theme.textTheme.bodySmall),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _activityLabel(String type) => switch (type) {
    'IN_PASSENGER_VEHICLE' => '車',
    'IN_BUS' => 'バス',
    'IN_TRAIN' => '電車',
    'ON_FOOT' => '徒歩',
    'ON_BICYCLE' => '自転車',
    'IN_FLIGHT' => '飛行機',
    'STILL' => '停止',
    _ => '移動',
  };
}

String _formatDate(String localDate) {
  final parts = localDate.split('-');
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = int.parse(parts[2]);
  final weekday = [
    '月',
    '火',
    '水',
    '木',
    '金',
    '土',
    '日',
  ][DateTime(y, m, d).weekday - 1];
  return '$y年$m月$d日（$weekday）';
}
